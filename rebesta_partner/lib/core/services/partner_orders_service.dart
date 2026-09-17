import '../../api/partner_orders_api.dart';
import '../../models/partner_order.dart';

class PartnerOrdersService {
  final PartnerOrdersApi _api = PartnerOrdersApi();

  Future<List<PartnerOrder>> getOrders() async {
    final data = await _api.getOrders();

    return data
        .map(
          (json) => PartnerOrder.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  Future<PartnerOrder> getOrder(
    String orderId,
  ) async {
    final data = await _api.getOrder(orderId);

    return PartnerOrder.fromJson(data);
  }

 Future<PartnerOrder> updateStatus({
  required String orderId,
  required String status,
}) async {
  // 1. Update status on backend
  await _api.updateStatus(
    orderId: orderId,
    status: status,
  );

  // 2. Fetch fresh orders from backend
  final orders = await getOrders();

  // 3. Find the updated order
  for (final order in orders) {
    if (order.id == orderId) {
      return order;
    }
  }

  // 4. Safety fallback
  throw Exception(
    'Order updated successfully, but updated order was not found.',
  );
}
}