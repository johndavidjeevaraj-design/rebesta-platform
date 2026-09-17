class CartItem {
  final String id;
  final int quantity;
  final double price;
  final double subtotal;

  final String menuItemId;
  final String name;
  final String description;
  final String? imageUrl;
  final bool isVeg;

  CartItem({
    required this.id,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.menuItemId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.isVeg,
  });

  CartItem copyWith({
  int? quantity,
  double? subtotal,
}) {
  return CartItem(
    id: id,
    quantity: quantity ?? this.quantity,
    price: price,
    subtotal: subtotal ?? this.subtotal,
    menuItemId: menuItemId,
    name: name,
    description: description,
    imageUrl: imageUrl,
    isVeg: isVeg,
  );
}

  factory CartItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final menuItem =
        json['menuItem'] is Map
            ? Map<String, dynamic>.from(
                json['menuItem'],
              )
            : <String, dynamic>{};

    return CartItem(
      id: json['id']?.toString() ?? '',
      quantity:
          (json['quantity'] ?? 0) as int,
      price:
          (json['price'] as num?)?.toDouble() ?? 0,
      subtotal:
          (json['subtotal'] as num?)?.toDouble() ?? 0,
      menuItemId:
          menuItem['id']?.toString() ?? '',
      name:
          menuItem['name']?.toString() ?? '',
      description:
          menuItem['description']?.toString() ?? '',
      imageUrl:
          menuItem['imageUrl']?.toString(),
      isVeg:
          menuItem['isVeg'] ?? false,
    );
  }
}