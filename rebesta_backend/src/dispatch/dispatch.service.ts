import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';

import { supabase } from '../supabase';
import { SocketGateway } from '../socket/socket.gateway';

// ============================================================
// SWIGGY-STYLE DISPATCH
// ============================================================
//
// When an order becomes ready for delivery we do NOT broadcast
// it to every rider at once - that creates an unfair
// fastest-finger race where slow riders never win anything.
//
// Instead:
//
//   1. Pick the best available rider:
//        - fewest offers received today (fairness first)
//        - closest to the customer's address
//        - freshest GPS location
//      and never busy with an active delivery.
//
//   2. Send a personal "order-offer" to that rider only,
//      valid for OFFER_TTL_MS seconds.
//
//   3. If they decline or the offer expires, the next best
//      rider is offered automatically.
//
//   4. If there is nobody left to offer, fall back to the old
//      broadcast behaviour so the order is never stranded.
//
// Requires the delivery_offers table:
//   supabase/migrations/20260926_create_delivery_offers.sql
//
// If the table is missing, dispatch FAILS OPEN and the caller
// falls back to broadcasting, so the platform keeps working.
// ============================================================

const OFFER_TTL_MS = 20_000;

const SWEEP_INTERVAL_MS = 10_000;

@Injectable()
export class DispatchService implements OnModuleInit, OnModuleDestroy {

  private readonly logger = new Logger(DispatchService.name);

  private sweepTimer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly socketGateway: SocketGateway,
  ) {}

  // ============================================================
  // LIFECYCLE
  // ============================================================

  onModuleInit() {
    // Safety net: if the process restarts, in-memory timers are
    // lost. This sweep claims expired offers straight from the DB.

    this.sweepTimer = setInterval(
      () => {
        this.sweepExpiredOffers().catch((error) => {
          this.logger.error(`Offer sweep failed: ${error}`);
        });
      },
      SWEEP_INTERVAL_MS,
    );
  }

  onModuleDestroy() {
    if (this.sweepTimer) {
      clearInterval(this.sweepTimer);
    }
  }

  // ============================================================
  // DISPATCH ONE ORDER TO THE BEST AVAILABLE RIDER
  //
  // Returns true when a personal offer was sent, false when
  // there was nobody left to offer to (caller should
  // broadcast as a fallback).
  // ============================================================

  async dispatchOrder(
    orderId: string,
  ): Promise<boolean> {
    try {
      // --------------------------------------------------------
      // 1. The order must still be in the delivery pool
      // --------------------------------------------------------

      const { data: order, error: orderError } = await supabase
        .from('orders')
        .select(`
          id,
          order_status,
          delivery_partner_id,
          total_amount,
          created_at,

          customers(
            name
          ),

          addresses(
            title,
            address,
            landmark,
            city,
            state,
            pincode,
            latitude,
            longitude
          ),

          restaurant_partners(
            restaurant_name
          )
        `)
        .eq('id', orderId)
        .single();

      if (orderError || !order) {
        this.logger.warn(
          `Dispatch skipped - order not found: ${orderId}`,
        );
        return false;
      }

      if (
        order.order_status !== 'ready' ||
        order.delivery_partner_id
      ) {
        return false;
      }

      // --------------------------------------------------------
      // 2. Online riders
      // --------------------------------------------------------

      const { data: partners, error: partnersError } =
        await supabase
          .from('delivery_partners')
          .select(`
            id,
            name,
            current_latitude,
            current_longitude,
            last_location_updated_at
          `)
          .eq('is_online', true);

      if (partnersError || !partners || partners.length === 0) {
        return false;
      }

      // --------------------------------------------------------
      // 3. Riders already busy with an active delivery
      // --------------------------------------------------------

      const { data: busyOrders } = await supabase
        .from('orders')
        .select('delivery_partner_id')
        .not('delivery_partner_id', 'is', null)
        .in('order_status', [
          'accepted_for_delivery',
          'arrived_at_restaurant',
          'picked_up',
          'out_for_delivery',
          'arrived_at_customer',
        ]);

      const busyIds = new Set(
        (busyOrders ?? []).map(
          (o) => o.delivery_partner_id as string,
        ),
      );

      // --------------------------------------------------------
      // 4. Riders already offered THIS order
      // (pending / accepted / declined / expired / superseded)
      // --------------------------------------------------------

      const { data: priorOffers } = await supabase
        .from('delivery_offers')
        .select('delivery_partner_id')
        .eq('order_id', orderId);

      const offeredIds = new Set(
        (priorOffers ?? []).map(
          (o) => o.delivery_partner_id as string,
        ),
      );

      // --------------------------------------------------------
      // 5. Fairness: how many offers each rider got today
      // --------------------------------------------------------

      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);

      const { data: todaysOffers } = await supabase
        .from('delivery_offers')
        .select('delivery_partner_id')
        .gte('offered_at', startOfDay.toISOString());

      const offerCounts = new Map<string, number>();

      for (const o of todaysOffers ?? []) {
        const id = o.delivery_partner_id as string;
        offerCounts.set(id, (offerCounts.get(id) ?? 0) + 1);
      }

      // --------------------------------------------------------
      // 6. Rank the candidates
      //    (fairness first, then distance, then GPS freshness)
      // --------------------------------------------------------

      const rawAddress = order.addresses;

      const address: any = Array.isArray(rawAddress)
        ? rawAddress[0]
        : rawAddress;

      const candidates = (partners as any[])
        .filter(
          (p) =>
            p.id &&
            !busyIds.has(p.id) &&
            !offeredIds.has(p.id),
        )
        .map((p) => ({
          ...p,
          distanceKm: haversineKm(
            p.current_latitude,
            p.current_longitude,
            address?.latitude,
            address?.longitude,
          ),
          offersToday: offerCounts.get(p.id) ?? 0,
          locationAgeMs: p.last_location_updated_at
            ? Date.now() -
              new Date(
                p.last_location_updated_at,
              ).getTime()
            : Number.MAX_SAFE_INTEGER,
        }))
        .sort((a, b) => {
          if (a.offersToday !== b.offersToday) {
            return a.offersToday - b.offersToday;
          }

          if (a.distanceKm !== b.distanceKm) {
            return a.distanceKm - b.distanceKm;
          }

          return a.locationAgeMs - b.locationAgeMs;
        });

      if (candidates.length === 0) {
        return false;
      }

      const rider = candidates[0];

      // --------------------------------------------------------
      // 7. Create the offer
      // --------------------------------------------------------

      const expiresAt = new Date(
        Date.now() + OFFER_TTL_MS,
      ).toISOString();

      const { data: offer, error: offerError } = await supabase
        .from('delivery_offers')
        .insert({
          order_id: orderId,
          delivery_partner_id: rider.id,
          expires_at: expiresAt,
        })
        .select()
        .single();

      if (offerError || !offer) {
        this.logger.error(
          `Could not create delivery offer: ${offerError?.message}`,
        );
        return false;
      }

      // --------------------------------------------------------
      // 8. Personal notification to the chosen rider
      // --------------------------------------------------------

      this.socketGateway.emitToDelivery(
        rider.id,
        'order-offer',
        {
          ...order,
          offer_id: offer.id,
          expires_at: expiresAt,
          ttl_seconds: Math.round(OFFER_TTL_MS / 1000),
        },
      );

      this.logger.log(
        `Order ${orderId} offered to rider ${rider.id} ` +
        `(${rider.offersToday} offers today, ` +
        `${rider.distanceKm.toFixed(1)} km away)`,
      );

      // --------------------------------------------------------
      // 9. Fast-path expiry timer
      //    (the sweep is the safety net)
      // --------------------------------------------------------

      const offerId = offer.id as string;

      setTimeout(
        () => {
          this.handleExpiredOffer(offerId).catch((error) => {
            this.logger.error(`Offer expiry failed: ${error}`);
          });
        },
        OFFER_TTL_MS + 500,
      );

      return true;
    } catch (error) {
      // Fail open - the caller falls back to broadcasting.

      this.logger.error(`Dispatch failed: ${error}`);
      return false;
    }
  }

  // ============================================================
  // FALLBACK: broadcast an order to every connected rider
  // ============================================================

  async broadcastOrderToFeed(
    orderId: string,
  ): Promise<void> {
    try {
      const { data: order } = await supabase
        .from('orders')
        .select(`
          id,
          total_amount,
          order_status,
          created_at,

          customers(
            name
          ),

          addresses(
            title,
            address,
            landmark,
            city,
            state,
            pincode,
            latitude,
            longitude
          )
        `)
        .eq('id', orderId)
        .single();

      if (!order) {
        return;
      }

      this.socketGateway.emitToAllDelivery(
        'new-order',
        order,
      );
    } catch (error) {
      this.logger.error(`Broadcast failed: ${error}`);
    }
  }

  // ============================================================
  // EXPIRE ONE OFFER (atomic claim) + REASSIGN
  // ============================================================

  async handleExpiredOffer(
    offerId: string,
  ): Promise<void> {
    const { data: offer } = await supabase
      .from('delivery_offers')
      .update({ status: 'expired' })
      .eq('id', offerId)
      .eq('status', 'pending')
      .lt('expires_at', new Date().toISOString())
      .select()
      .single();

    // Already accepted / declined / handled by another worker.

    if (!offer) {
      return;
    }

    // Let the rider's app close the offer dialog.

    this.socketGateway.emitToDelivery(
      offer.delivery_partner_id,
      'offer-expired',
      {
        orderId: offer.order_id,
        reason: 'expired',
      },
    );

    // Offer the order to the next best rider.

    const dispatched = await this.dispatchOrder(
      offer.order_id,
    );

    if (!dispatched) {
      await this.broadcastOrderToFeed(offer.order_id);
    }
  }

  // ============================================================
  // SWEEP: catch offers the in-memory timers missed
  // (server restarts, crashes, clock drift)
  // ============================================================

  async sweepExpiredOffers(): Promise<void> {
    const { data: expired, error } = await supabase
      .from('delivery_offers')
      .update({ status: 'expired' })
      .eq('status', 'pending')
      .lt('expires_at', new Date().toISOString())
      .select();

    if (error || !expired || expired.length === 0) {
      return;
    }

    this.logger.log(
      `Sweep expired ${expired.length} offer(s)`,
    );

    for (const offer of expired) {
      this.socketGateway.emitToDelivery(
        offer.delivery_partner_id,
        'offer-expired',
        {
          orderId: offer.order_id,
          reason: 'expired',
        },
      );

      const dispatched = await this.dispatchOrder(
        offer.order_id,
      );

      if (!dispatched) {
        await this.broadcastOrderToFeed(
          offer.order_id,
        );
      }
    }
  }
}

// ============================================================
// Distance between two points (km). Unknown coordinates rank
// last (9999 km) so located riders are always preferred.
// ============================================================

function haversineKm(
  lat1: number | null,
  lon1: number | null,
  lat2: number | null,
  lon2: number | null,
): number {
  if (
    lat1 == null ||
    lon1 == null ||
    lat2 == null ||
    lon2 == null
  ) {
    return 9999;
  }

  const toRad = (value: number) =>
    (value * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return (
    6371 *
    2 *
    Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  );
}
