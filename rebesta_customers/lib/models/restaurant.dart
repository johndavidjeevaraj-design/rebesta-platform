class Restaurant {
  final String id;
  final String? restaurantPartnerId;
  final String name;
  final String? cuisine;

  final double rating;
  final int reviewCount;

  final String? deliveryTime;
  final double deliveryFee;
  final double minOrder;

  // Restaurant/card image
  final String? imageUrl;
  

  // Dedicated restaurant menu banner
  final String? bannerImageUrl;

  final String? semanticLabel;

  final bool isFavorite;
  final bool isOpen;

  final String? promoLabel;
  final String? category;

  Restaurant({
    required this.id,
    this.restaurantPartnerId,
    required this.name,
    this.cuisine,
    required this.rating,
    required this.reviewCount,
    this.deliveryTime,
    
    required this.deliveryFee,
    required this.minOrder,
    this.imageUrl,
    this.bannerImageUrl,
    this.semanticLabel,
    required this.isFavorite,
    required this.isOpen,
    this.promoLabel,
    this.category,
  });

  factory Restaurant.fromJson(
    Map<String, dynamic> json,
  ) {
    return Restaurant(
      id: json['id']?.toString() ?? '',

      restaurantPartnerId:
            json['restaurantPartnerId']?.toString(),

      name: json['name']?.toString() ?? '',
      cuisine: json['cuisine']?.toString(),

      rating: (json['rating'] ?? 0).toDouble(),

      reviewCount:
          (json['reviewCount'] ?? 0).toInt(),

      deliveryTime:
          json['deliveryTime']?.toString(),

      deliveryFee:
          (json['deliveryFee'] ?? 0).toDouble(),

      minOrder:
          (json['minOrder'] ?? 0).toDouble(),

      imageUrl:
          json['imageUrl']?.toString(),

      

      // NEW
      bannerImageUrl:
          json['bannerImageUrl']?.toString(),

      semanticLabel:
          json['semanticLabel']?.toString(),

      isFavorite:
          json['isFavorite'] ?? false,

      isOpen:
          json['isOpen'] ?? false,

      promoLabel:
          json['promoLabel']?.toString(),

      category:
          json['category']?.toString(),
    );
  }
}