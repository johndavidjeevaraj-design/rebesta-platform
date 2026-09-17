import 'package:flutter/foundation.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isVeg;
  final String category;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.isVeg,
    required this.category,
  });

  factory MenuItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawImage =
        json['image_url'] ??
        json['imageUrl'];

    final imageUrl =
        rawImage?.toString().trim();

    debugPrint('================================');
    debugPrint('🍔 MENU ITEM: ${json['name']}');
    debugPrint('🖼️ IMAGE URL: $imageUrl');
    debugPrint('================================');

    return MenuItemModel(
      id: json['id']?.toString() ?? '',

      name:
          json['name']?.toString() ?? '',

      description:
          json['description']?.toString() ?? '',

      price:
          json['price'] is num
              ? (json['price'] as num).toDouble()
              : double.tryParse(
                    json['price']?.toString() ?? '',
                  ) ??
                  0.0,

      imageUrl:
          imageUrl != null &&
                  imageUrl.isNotEmpty &&
                  imageUrl != 'null'
              ? imageUrl
              : null,

      isVeg:
          json['is_veg'] ??
          json['isVeg'] ??
          false,

      category:
          json['category']?.toString() ??
          'Popular',
    );
  }
}