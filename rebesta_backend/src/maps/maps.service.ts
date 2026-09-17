import { Injectable } from '@nestjs/common';
import axios from 'axios';

// ============================================================
// DELIVERY FEE MODEL (Swiggy-style)
// Everything downstream reads from here — tune freely.
// ============================================================

const FEE_CONFIG = {
  baseFee: 20,
  includedKm: 3,
  perKmRate: 10,
  maxFee: 99,

  peakSurcharge: 10,
  weatherSurcharge: 20,

  lowOrderThreshold: 149,
  lowOrderSurcharge: 10,
};

@Injectable()
export class MapsService {
  // ============================================================
  // DELIVERY FEE
  // ============================================================

  /**
   * Pure fee calculation from a known road distance.
   *
   * Base:
   *   ₹20 for first 3 km
   *
   * Beyond 3 km:
   *   ₹10/km
   *   Rounded to nearest ₹5
   *
   * Additional:
   *   Peak surcharge
   *   Low-order surcharge
   *
   * Hard cap:
   *   ₹99
   */
  calculateDeliveryFee(
    distanceKm: number,
    options?: {
      subtotal?: number;
    },
  ): number {
    const extraKm = Math.max(
      0,
      distanceKm - FEE_CONFIG.includedKm,
    );

    let fee =
      FEE_CONFIG.baseFee +
      Math.round(
        (extraKm * FEE_CONFIG.perKmRate) / 5,
      ) *
        5;

    // ----------------------------------------------------------
    // PEAK HOUR SURCHARGE
    // ----------------------------------------------------------

    if (this.isPeakHourIST()) {
      fee += FEE_CONFIG.peakSurcharge;
    }

    // ----------------------------------------------------------
    // LOW ORDER SURCHARGE
    // ----------------------------------------------------------

    const subtotal =
      options?.subtotal ?? 0;

    if (
      subtotal > 0 &&
      subtotal < FEE_CONFIG.lowOrderThreshold
    ) {
      fee +=
        FEE_CONFIG.lowOrderSurcharge;
    }

    // ----------------------------------------------------------
    // HARD CAP
    // ----------------------------------------------------------

    return (
      Math.round(
        Math.min(
          fee,
          FEE_CONFIG.maxFee,
        ) * 100,
      ) / 100
    );
  }

  // ============================================================
  // PEAK HOURS
  // ============================================================

  /**
   * Peak hours in IST.
   *
   * Lunch:
   *   12:00 PM – 3:00 PM
   *
   * Dinner:
   *   7:00 PM – 10:00 PM
   */
  isPeakHourIST(): boolean {
    const ist = new Date(
      new Date().toLocaleString(
        'en-US',
        {
          timeZone: 'Asia/Kolkata',
        },
      ),
    );

    const hour = ist.getHours();

    return (
      (hour >= 12 && hour < 15) ||
      (hour >= 19 && hour < 22)
    );
  }

  // ============================================================
  // WEATHER SURCHARGE
  // ============================================================

  /**
   * Rain check via Open-Meteo.
   *
   * Open-Meteo is free and does not require
   * an API key.
   *
   * If weather lookup fails:
   *   surcharge = ₹0
   *
   * Timeout:
   *   3 seconds
   */
  async getWeatherSurcharge(
    lat: number,
    lng: number,
  ): Promise<number> {
    try {
      const response =
        await axios.get(
          'https://api.open-meteo.com/v1/forecast',
          {
            params: {
              latitude: lat,
              longitude: lng,

              current:
                'precipitation,weather_code',

              timezone:
                'Asia/Kolkata',
            },

            timeout: 3000,
          },
        );

      const current =
        response.data?.current ?? {};

      const precipitation =
        Number(
          current.precipitation,
        ) || 0;

      const weatherCode =
        Number(
          current.weather_code,
        ) || 0;

      const raining =
        precipitation > 0.5 ||
        (weatherCode >= 51 &&
          weatherCode <= 99);

      return raining
        ? FEE_CONFIG.weatherSurcharge
        : 0;
    } catch {
      // Weather should NEVER block checkout.
      return 0;
    }
  }

  // ============================================================
  // THE ONE DELIVERY FEE ENGINE
  // ============================================================

  /**
   * Central delivery-fee engine.
   *
   * Used by:
   *   - Cart estimate
   *   - COD checkout
   *   - Online checkout
   *   - Orders
   *
   * This keeps all checkout flows consistent.
   *
   * Distance:
   *   ORS road distance
   *
   * Fallback:
   *   Haversine straight-line distance
   *
   * Missing coordinates:
   *   Base fee
   */
  async calculateOrderDeliveryFee(
    params: {
      restaurantLat: number | null;
      restaurantLng: number | null;

      addressLat: number | null;
      addressLng: number | null;

      subtotal: number;

      orderType?:
        | 'delivery'
        | 'pickup';

      includeWeather?: boolean;
    },
  ): Promise<{
    fee: number;
    distanceKm: number;
    breakdown: Record<string, any>;
  }> {
    const {
      restaurantLat,
      restaurantLng,
      addressLat,
      addressLng,
      subtotal,

      orderType = 'delivery',

      includeWeather = true,
    } = params;

    // ----------------------------------------------------------
    // PICKUP
    // ----------------------------------------------------------

    if (
      orderType === 'pickup'
    ) {
      return {
        fee: 0,
        distanceKm: 0,

        breakdown: {
          reason: 'pickup',
        },
      };
    }

   
    // ----------------------------------------------------------
    // COORDINATE VALIDATION
    // ----------------------------------------------------------

    const valid = (
      lat: number | null,
      lng: number | null,
    ): boolean =>
      lat != null &&
      lng != null &&
      !(lat === 0 && lng === 0) &&
      Math.abs(lat) <= 90 &&
      Math.abs(lng) <= 180;

    const hasCoords =
      valid(
        restaurantLat,
        restaurantLng,
      ) &&
      valid(
        addressLat,
        addressLng,
      );

    // ----------------------------------------------------------
    // MISSING COORDINATES
    // ----------------------------------------------------------

    if (!hasCoords) {
      return {
        fee: FEE_CONFIG.baseFee,

        distanceKm: 0,

        breakdown: {
          reason:
            'missing_coordinates',

          base:
            FEE_CONFIG.baseFee,
        },
      };
    }

    // All four are guaranteed valid numbers past this point
const restaurantLatValue = restaurantLat as number;
const restaurantLngValue = restaurantLng as number;
const addressLatValue = addressLat as number;
const addressLngValue = addressLng as number;

    

    // ----------------------------------------------------------
    // ROAD DISTANCE
    // ----------------------------------------------------------

    let distanceKm: number;

    try {
      const eta =
  await this.getETA(
    restaurantLatValue,
    restaurantLngValue,
    addressLatValue,
    addressLngValue,
  );

distanceKm =
  Number(eta?.distance) ||
  this.calculateStraightLineDistance(
    restaurantLatValue,
    restaurantLngValue,
    addressLatValue,
    addressLngValue,
  );
    } catch {
    distanceKm =
  this.calculateStraightLineDistance(
    restaurantLatValue,
    restaurantLngValue,
    addressLatValue,
    addressLngValue,
  );
    }

    // Keep distance to one decimal place
    distanceKm =
      Math.round(
        distanceKm * 10,
      ) / 10;

    // ----------------------------------------------------------
    // BASE + DISTANCE + PEAK + LOW ORDER
    // ----------------------------------------------------------

    const baseFee =
      this.calculateDeliveryFee(
        distanceKm,
        {
          subtotal,
        },
      );

    // ----------------------------------------------------------
    // WEATHER
    // ----------------------------------------------------------

    let weather = 0;

    if (includeWeather) {
      weather =
        await this.getWeatherSurcharge(
          addressLatValue,
          addressLngValue,
        );
    }

    // ----------------------------------------------------------
    // FINAL FEE
    // ----------------------------------------------------------

    const fee =
      Math.min(
        baseFee + weather,
        FEE_CONFIG.maxFee,
      ) || 0;

    // ----------------------------------------------------------
    // RESULT
    // ----------------------------------------------------------

    return {
      fee,

      distanceKm,

      breakdown: {
        distanceKm,

        base: baseFee,

        weather,
      },
    };
  }

  // ============================================================
  // STRAIGHT-LINE DISTANCE
  // ============================================================

  /**
   * Haversine formula for straight-line distance.
   *
   * Used as fallback when ORS routing fails.
   */
  calculateStraightLineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371;

    const dLat =
      this.toRad(
        lat2 - lat1,
      );

    const dLon =
      this.toRad(
        lon2 - lon1,
      );

    const a =
      Math.sin(dLat / 2) *
        Math.sin(dLat / 2) +
      Math.cos(
        this.toRad(lat1),
      ) *
        Math.cos(
          this.toRad(lat2),
        ) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c =
      2 *
      Math.atan2(
        Math.sqrt(a),
        Math.sqrt(1 - a),
      );

    const distance =
      R * c;

    return (
      Math.round(
        distance * 100,
      ) / 100
    );
  }

  // ============================================================
  // DEGREE → RADIAN
  // ============================================================

  private toRad(
    degrees: number,
  ): number {
    return (
      degrees *
      (Math.PI / 180)
    );
  }

  // ============================================================
  // ROAD ROUTE / ETA
  // ============================================================

  /**
   * Get road distance, ETA and route
   * using OpenRouteService.
   *
   * ORS returns coordinates as:
   *
   *   [longitude, latitude]
   *
   * We convert them to:
   *
   *   { latitude, longitude }
   */
  async getETA(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ) {
    try {
      console.log(
        '====================================',
      );

      console.log(
        '🗺️ MAPS SERVICE - ROAD ROUTE',
      );

      console.log(
        'Origin:',
        originLat,
        originLng,
      );

      console.log(
        'Destination:',
        destLat,
        destLng,
      );

      console.log(
        'API Key Exists:',
        !!process.env.ORS_API_KEY,
      );

      console.log(
        '====================================',
      );

      const response =
        await axios.post(
          'https://api.openrouteservice.org/v2/directions/driving-car',

          {
            coordinates: [
              [
                originLng,
                originLat,
              ],
              [
                destLng,
                destLat,
              ],
            ],

            // Ask ORS for GeoJSON coordinates
            geometry_format:
              'geojson',
          },

          {
            headers: {
              Authorization:
                process.env.ORS_API_KEY as string,

              'Content-Type':
                'application/json',
            },
          },
        );

      console.log(
        '✅ ORS RESPONSE RECEIVED',
      );

      const route =
        response.data?.routes?.[0];

      if (!route) {
        throw new Error(
          'ORS returned no route',
        );
      }

      const summary =
        route.summary;

      // --------------------------------------------------------
      // GEOJSON ROAD COORDINATES
      // --------------------------------------------------------

      const coordinates =
        route.geometry
          ?.coordinates ?? [];

      const polyline =
        coordinates.map(
          (
            point: number[],
          ) => ({
            latitude:
              Number(point[1]),

            longitude:
              Number(point[0]),
          }),
        );

      // --------------------------------------------------------
      // RESULT
      // --------------------------------------------------------

      const result = {
        distance:
          Number(
            (
              summary.distance /
              1000
            ).toFixed(2),
          ),

        duration:
          Math.ceil(
            summary.duration /
              60,
          ),

        polyline,
      };

      console.log(
        '====================================',
      );

      console.log(
        '🛣️ ROAD ROUTE RESULT',
      );

      console.log(
        'Route points:',
        polyline.length,
      );

      console.log(
        'Distance:',
        result.distance,
        'km',
      );

      console.log(
        'Duration:',
        result.duration,
        'minutes',
      );

      console.log(
        '====================================',
      );

      return result;
    } catch (error: any) {
      console.log(
        '========== ORS ERROR ==========',
      );

      if (error.response) {
        console.log(
          'Status:',
          error.response.status,
        );

        console.log(
          'Data:',
          error.response.data,
        );
      } else {
        console.log(
          error.message,
        );
      }

      console.log(
        '==============================',
      );

      // --------------------------------------------------------
      // STRAIGHT-LINE FALLBACK
      // --------------------------------------------------------

      const straightLineDistance =
        this.calculateStraightLineDistance(
          originLat,
          originLng,
          destLat,
          destLng,
        );

      const estimatedDuration =
        Math.ceil(
          straightLineDistance * 3,
        );

      return {
        distance:
          straightLineDistance,

        duration:
          estimatedDuration,

        // Straight-line fallback route
        polyline: [
          {
            latitude:
              originLat,

            longitude:
              originLng,
          },

          {
            latitude:
              destLat,

            longitude:
              destLng,
          },
        ],
      };
    }
  }

  // ============================================================
  // GEOCODE ADDRESS
  // ============================================================

  /**
   * Convert a full address into latitude/longitude.
   *
   * Uses the current HEIGIT/Pelias geocoder.
   *
   * Returns:
   *
   *   {
   *     latitude,
   *     longitude,
   *     label
   *   }
   *
   * Returns null when geocoding fails.
   */
  async geocodeAddress(
    addressText: string,
  ): Promise<{
    latitude: number;
    longitude: number;
    label?: string;
  } | null> {
    const address =
      addressText.trim();

    if (!address) {
      console.warn(
        '⚠️ Cannot geocode empty address',
      );

      return null;
    }

    try {
      console.log(
        '====================================',
      );

      console.log(
        '📍 GEOCODING ADDRESS',
      );

      console.log(
        'Address:',
        address,
      );

      console.log(
        'API Key Exists:',
        !!process.env.ORS_API_KEY,
      );

      console.log(
        '====================================',
      );

      const response =
        await axios.get(
          'https://api.heigit.org/pelias/v1/search',
          {
            params: {
              text: address,
              size: 1,
            },

            headers: {
              Authorization:
                process.env.ORS_API_KEY as string,
            },

            timeout: 5000,
          },
        );

      const feature =
        response.data
          ?.features?.[0];

      const coordinates =
        feature?.geometry
          ?.coordinates;

      if (
        !Array.isArray(
          coordinates,
        ) ||
        coordinates.length < 2
      ) {
        console.warn(
          '⚠️ Geocoder returned no coordinates',
        );

        return null;
      }

      // Pelias returns:
      //
      // [longitude, latitude]
      //
      const longitude =
        Number(coordinates[0]);

      const latitude =
        Number(coordinates[1]);

      if (
        !Number.isFinite(
          latitude,
        ) ||
        !Number.isFinite(
          longitude,
        )
      ) {
        console.warn(
          '⚠️ Geocoder returned invalid coordinates',
        );

        return null;
      }

      const result = {
        latitude,
        longitude,

        label:
          feature.properties
            ?.label ??
          feature.properties
            ?.name ??
          address,
      };

      console.log(
        '✅ GEOCODING SUCCESS',
      );

      console.log(
        'Latitude:',
        result.latitude,
      );

      console.log(
        'Longitude:',
        result.longitude,
      );

      console.log(
        'Label:',
        result.label,
      );

      console.log(
        '====================================',
      );

      return result;
    } catch (error: any) {
      console.error(
        '❌ Geocoding failed:',
        error?.response?.status ??
          error?.message ??
          error,
      );

      if (error?.response?.data) {
        console.error(
          'Geocoding response:',
          error.response.data,
        );
      }

      return null;
    }
  }
}