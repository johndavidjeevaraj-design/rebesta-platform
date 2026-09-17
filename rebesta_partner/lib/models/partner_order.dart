class PartnerOrder {
  final String id;
  final double totalAmount;
  final String paymentStatus;
  final String orderStatus;
  final DateTime createdAt;
  final CustomerInfo? customer;
  final List<PartnerOrderItem> items;

  PartnerOrder({
    required this.id,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.customer,
    required this.items,
  });

  factory PartnerOrder.fromJson(
    Map<String, dynamic> json,
  ) {
    return PartnerOrder(
      id: json['id']?.toString() ?? '',
      totalAmount:
          double.tryParse(
            json['totalAmount']?.toString() ?? '0',
          ) ??
          0,
      paymentStatus:
          json['paymentStatus']?.toString() ??
          'pending',
      orderStatus:
          json['orderStatus']?.toString() ??
          'pending',
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      customer:
          json['customer'] is Map
              ? CustomerInfo.fromJson(
                  Map<String, dynamic>.from(
                    json['customer'],
                  ),
                )
              : null,
      items:
          (json['items'] as List?)
              ?.map(
                (item) =>
                    PartnerOrderItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          [],
    );
  }
}

class CustomerInfo {
  final String id;
  final String name;
  final String mobile;

  CustomerInfo({
    required this.id,
    required this.name,
    required this.mobile,
  });

  factory CustomerInfo.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Customer',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}

class PartnerOrderItem {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isVeg;
  final int quantity;
  final double price;
  final double subtotal;

  PartnerOrderItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isVeg,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory PartnerOrderItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final quantity =
        int.tryParse(
          json['quantity']?.toString() ?? '0',
        ) ??
        0;

    final price =
        double.tryParse(
          json['price']?.toString() ?? '0',
        ) ??
        0;

    return PartnerOrderItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item',
      description:
          json['description']?.toString(),
      imageUrl:
          json['imageUrl']?.toString(),
      isVeg:
          json['isVeg'] == true,
      quantity: quantity,
      price: price,
      subtotal:
          double.tryParse(
            json['subtotal']?.toString() ?? '',
          ) ??
          quantity * price,
    );
  }
}