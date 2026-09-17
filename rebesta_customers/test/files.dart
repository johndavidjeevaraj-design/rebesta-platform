//lib/models/address.dart 

class Address {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  const Address({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Address',
      address: json['address']?.toString() ?? '',
      latitude: double.tryParse(
            json['latitude']?.toString() ?? '',
          ) ??
          0.0,
      longitude: double.tryParse(
            json['longitude']?.toString() ?? '',
          ) ??
          0.0,
    );
  }
}

//lib/models/restaurant.dart

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

//lib/services/geocoding_service.dart
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<String> getAddress(
    double latitude,
    double longitude,
  ) async {
    List<Placemark> places = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (places.isEmpty) {
      return "Unknown Location";
    }

    final p = places.first;

    return [
      p.name,
      p.street,
      p.locality,
      p.administrativeArea,
    ].where((e) => e != null && e.isNotEmpty).join(", ");
  }
}