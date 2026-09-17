import '../core/network/api_client.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import 'package:flutter/foundation.dart';

class RestaurantService {
  // ===========================
  // GET ALL RESTAURANTS
  // ===========================

  Future<List<Restaurant>> getRestaurants() async {
    final response = await ApiClient.dio.get(
      '/restaurants',
    );

    final List restaurants =
        response.data['restaurants'];

    return restaurants
        .map(
          (e) => Restaurant.fromJson(e),
        )
        .toList();
  }

  // ===========================
  // GET SINGLE RESTAURANT
  // ===========================

  Future<Restaurant> getRestaurant(
    String id,
  ) async {
    final response =
        await ApiClient.dio.get(
      '/restaurants/$id',
    );

    return Restaurant.fromJson(
      response.data['restaurant'],
    );
  }

  // ===========================
  // GET RESTAURANT MENU
  // ===========================

  Future<List<MenuItemModel>> getRestaurantMenu(
    String id,
  ) async {
    final response =
        await ApiClient.dio.get(
      '/restaurants/$id/menu',
    );

    final List menu =
        response.data['menu'];

    return menu
        .map(
          (e) => MenuItemModel.fromJson(e),
        )
        .toList();
  }Future<List<MenuItemModel>> getAllMenuItems(
  List<Restaurant> restaurants,
) async {
  final List<MenuItemModel> allItems = [];

  for (final restaurant in restaurants) {
    try {
      final items = await getRestaurantMenu(
        restaurant.id,
      );

      allItems.addAll(items);
    } catch (e) {
      debugPrint(
        'MENU LOAD ERROR ${restaurant.name}: $e',
      );
    }
  }

  return allItems;
}


}