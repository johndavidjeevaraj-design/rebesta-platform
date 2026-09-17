import '../models/menu_item.dart';
import '../services/restaurant_service.dart';

class MenuService {
  final RestaurantService _restaurantService = RestaurantService();

  Future<List<MenuItemModel>> getMenu(
    String restaurantId,
  ) async {
    return await _restaurantService.getRestaurantMenu(
      restaurantId,
    );
  }
}