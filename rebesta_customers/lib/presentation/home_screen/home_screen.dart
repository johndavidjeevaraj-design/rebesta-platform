import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/address.dart';
import '../../models/customer.dart';
import '../../models/restaurant.dart';
import './widgets/home_main_filters_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../services/restaurant_service.dart';
import './widgets/home_cravings_widget.dart';
import '../../theme/app_theme.dart';
import './widgets/home_promo_banner_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../models/menu_item.dart';
import './widgets/home_greeting_widget.dart';
import './widgets/home_food_banner_widget.dart';
import './widgets/order_again_widget.dart';
import './widgets/restaurant_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  final AddressService _addressService = AddressService();
  final RestaurantService _restaurantService = RestaurantService();

  int _selectedCategoryIndex = -1;
  int? _selectedMainFilterIndex = 0;

  bool _vegOnly = false;

  bool isLoading = true;
  bool loadingAddresses = true;
  bool loadingRestaurants = true;

  Customer? customer;
  String customerName = "there";

  List<Address> addresses = [];

  List<Restaurant> restaurants = [];

  // ============================================================
  // SEARCH + RECENT DELIVERED ORDERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  List<Map<String, dynamic>> _recentOrders = [];

  // Anchor for the banner CTAs ("Explore now") to scroll to

  final GlobalKey _cravingsKey = GlobalKey();
  List<MenuItemModel> _allMenuItems = [];

  List<String> get cravingCategories {
  final categories = _allMenuItems
      .map((item) => item.category.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();

  return categories;
}

Map<String, Set<String>> restaurantMenuCategories = {};

bool loadingMenuCategories = false;


  bool _categoryMatches(
  String menuCategory,
  String selectedCategory,
) {
  final menu = menuCategory
      .trim()
      .toLowerCase();

  final selected = selectedCategory
      .trim()
      .toLowerCase();

  if (menu == selected) {
    return true;
  }

  const aliases = {
    'biriyani': [
      'biryani',
      'biriyani',
    ],
    'pizzas': [
      'pizza',
      'pizzas',
    ],
    'ice cream': [
      'ice cream',
      'icecream',
    ],
    'cakes': [
      'cake',
      'cakes',
    ],
    'burgers': [
      'burger',
      'burgers',
    ],
    'rolls': [
      'roll',
      'rolls',
    ],
    'momos': [
      'momo',
      'momos',
    ],
    'noodles': [
      'noodle',
      'noodles',
    ],
    'shakes': [
      'shake',
      'shakes',
    ],
    'juices': [
      'juice',
      'juices',
    ],
    'desserts': [
      'dessert',
      'desserts',
    ],
    'paratha': [
      'paratha',
      'parathas',
    ],
    'mutton': [
      'mutton',
    ],
    'chicken': [
      'chicken',
    ],
  };

  final possibleMatches =
      aliases[selected];

  if (possibleMatches == null) {
    return menu == selected;
  }

  return possibleMatches.contains(menu);
}
  

  

  List<Restaurant> get filteredRestaurants {
  Iterable<Restaurant> result = restaurants;

  // ============================================================
  // SEARCH - match restaurant name or cuisine
  // ============================================================

  if (_searchQuery.isNotEmpty) {
    final query = _searchQuery.toLowerCase();

    result = result.where((restaurant) {
      final name = restaurant.name.toLowerCase();

      final cuisine =
          restaurant.cuisine?.toLowerCase() ?? '';

      return name.contains(query) ||
          cuisine.contains(query);
    });
  }

  // ============================================================
  // VEG MODE
  // ============================================================

  // Keep this disabled for now because Restaurant itself does not
  // contain vegetarian-menu information.
  //
  // We will connect this to menu_items.is_veg properly later.

  // ============================================================
  // CATEGORY
  // ============================================================
if (_selectedCategoryIndex >= 0) {
  final category =
      HomeCravingsWidget.categories[
        _selectedCategoryIndex
      ].name
      .trim()
      .toLowerCase();

  result = result.where((restaurant) {
    final restaurantCategories =
        restaurantMenuCategories[restaurant.id] ?? {};

    return restaurantCategories.any(
      (menuCategory) {
        return _categoryMatches(
          menuCategory,
          category,
        );
      },
    );
  });
}

  // ============================================================
  // MAIN FILTER
  // ============================================================

  switch (_selectedMainFilterIndex) {
    case 0:
      // POPULAR
      //
      // For now popularity is derived from rating + review count.
      result = result.where(
        (restaurant) =>
            restaurant.rating >= 4.0 &&
            restaurant.reviewCount >= 100,
      );
      break;

    case 1:
      // OFFERS
      //
      // Real promoLabel from backend.
      result = result.where(
        (restaurant) =>
            restaurant.promoLabel != null &&
            restaurant.promoLabel!.trim().isNotEmpty,
      );
      break;

    case 2:
      // FAST DELIVERY
      //
      // Uses actual deliveryTime returned by backend.
      result = result.where((restaurant) {
        final time = restaurant.deliveryTime;

        if (time == null || time.isEmpty) {
          return false;
        }

        final match = RegExp(r'(\d+)').firstMatch(time);

        if (match == null) {
          return false;
        }

        final minutes = int.tryParse(match.group(1)!);

        return minutes != null && minutes <= 30;
      });
      break;

    case 3:
      // TOP RATED
      result = result.where(
        (restaurant) => restaurant.rating >= 4.5,
      );
      break;
  }

  return result.toList();
}

  @override
  void initState() {
    super.initState();

    loadProfile();
    loadAddresses();
    loadRestaurants();
    _loadRecentOrders();
    
  }

  // ============================================================
  // SCROLL TO CRAVINGS CATEGORIES (used by banner CTAs)
  // ============================================================

  void _scrollToCravings() {
    final cravingsContext = _cravingsKey.currentContext;

    if (cravingsContext == null) return;

    Scrollable.ensureVisible(
      cravingsContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  // ============================================================
  // RECENT ORDERS for the real "Order Again" strip
  // ============================================================

  Future<void> _loadRecentOrders() async {
    try {
      final response = await OrderService().getMyOrders();

      final rawOrders = response['orders'];

      if (rawOrders is! List) return;

      final delivered = rawOrders
          .where(
            (order) =>
                order is Map &&
                order['order_status']?.toString() ==
                    'delivered',
          )
          .cast<Map<String, dynamic>>()
          .take(3)
          .toList();

      if (!mounted) return;

      setState(() {
        _recentOrders = delivered;
      });
    } catch (e) {
      debugPrint('RECENT ORDERS ERROR: $e');
    }
  }

  // ============================================================
  // REORDER - re-add every item, land in checkout
  // ============================================================

  Future<void> _reorder(Map<String, dynamic> order) async {
    final restaurantPartnerId =
        order['restaurant_partner_id']?.toString() ?? '';

    if (restaurantPartnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot reorder this order'),
        ),
      );

      return;
    }

    // Block input while the items are re-added
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final added =
          await CartService().reorderFromOrder(order);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (added == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Items from this order are no longer available',
            ),
          ),
        );

        return;
      }

      context.push(
        AppRoutes.checkoutScreen,
        extra: restaurantPartnerId,
      );
    } catch (e) {
      debugPrint('REORDER ERROR: $e');

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reorder failed - please try again'),
        ),
      );
    }
  }

Future<void> loadProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Load locally saved name immediately
    final savedName = prefs.getString('customerName');

    if (mounted &&
        savedName != null &&
        savedName.trim().isNotEmpty) {
      setState(() {
        customerName = savedName.trim();
      });
    }

    // Fetch latest profile
    final profile = await ProfileService().getProfile();

    if (!mounted) return;

    setState(() {
      customer = profile;

      if (profile.name.trim().isNotEmpty) {
        customerName = profile.name.trim();
      }

      isLoading = false;
    });

    // Keep local name synchronized
    if (profile.name.trim().isNotEmpty) {
      await prefs.setString(
        'customerName',
        profile.name.trim(),
      );
    }
  } catch (e) {
    debugPrint('PROFILE ERROR: $e');

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> loadAddresses() async {
    try {
      final data = await _addressService.getAddresses();

      setState(() {
        addresses = data;
        loadingAddresses = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        loadingAddresses = false;
      });
    }
  }

  Future<void> loadRestaurantMenuCategories() async {
  if (restaurants.isEmpty) return;

  setState(() {
    loadingMenuCategories = true;
  });

  final Map<String, Set<String>> result = {};

  for (final restaurant in restaurants) {
    try {
      final menu =
          await _restaurantService.getRestaurantMenu(
        restaurant.id,
      );

      final categories = menu
          .map(
            (item) => item.category.trim().toLowerCase(),
          )
          .where(
            (category) => category.isNotEmpty,
          )
          .toSet();

      result[restaurant.id] = categories;
    } catch (e) {
      debugPrint(
        'MENU CATEGORY ERROR ${restaurant.id}: $e',
      );

      result[restaurant.id] = {};
    }
  }

  if (!mounted) return;

  setState(() {
    restaurantMenuCategories = result;
    loadingMenuCategories = false;
  });
}

  Future<void> loadRestaurants() async {
  try {
    final data = await _restaurantService.getRestaurants();

    if (!mounted) return;

    setState(() {
      restaurants = data;
      loadingRestaurants = false;
    });

    // Load menu items after restaurants are available
    final menuItems =
        await _restaurantService.getAllMenuItems(data);

    if (!mounted) return;

    setState(() {
      _allMenuItems = menuItems;
    });
  } catch (e) {
    debugPrint('RESTAURANTS LOAD ERROR: $e');

    if (!mounted) return;

    setState(() {
      loadingRestaurants = false;
    });
  }
}
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _buildAppBar(context),
            ),

            SliverToBoxAdapter(
              child: HomeGreetingWidget(
                customerName: customerName,
                vegOnly: _vegOnly,
                onVegChanged: (value) {
                  setState(() {
                    _vegOnly = value;
                  });
                },
                  //  customer?.name?.trim().isNotEmpty == true
                    
                    //: "there",
              ),
            ),
           

SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.only(
      top: 12,
      bottom: 4,
    ),
    child: HomeMainFiltersWidget(
      selectedIndex: _selectedMainFilterIndex ?? -1,
      onSelected: (index) {
        setState(() {
          // Tap selected filter again = clear filter
          _selectedMainFilterIndex =
              _selectedMainFilterIndex == index ? null : index;
        });
      },
    ),
  ),
),

SliverToBoxAdapter(
  child: HomeFoodBannerWidget(
    title: 'Craving something delicious?',
    subtitle: 'Discover your next favorite meal.',
    buttonText: 'Explore now',
    imageUrl: null,
    onTap: _scrollToCravings,
  ),
),




  // =====================================================
  // SEARCH BAR
  // =====================================================

  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppTheme.mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search restaurants or cuisines',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Icon(
                  Icons.close,
                  color: AppTheme.mutedText,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    ),
  ),

  // =====================================================
  // ORDER AGAIN - real recent delivered orders
  // =====================================================

  SliverToBoxAdapter(
    child: OrderAgainWidget(
      orders: _recentOrders,
      onReorder: _reorder,
    ),
            ),


SliverToBoxAdapter(
  child: HomeCravingsWidget(
    key: _cravingsKey,
    selectedIndex: _selectedCategoryIndex,
    onSelected: (index) {
      setState(() {
        _selectedCategoryIndex = 
          _selectedCategoryIndex == index
            ? -1 
            : index;
      });
    },
  ),
),

SliverToBoxAdapter(
  child: HomePromoBannerWidget(
    onCtaTap: _scrollToCravings,
  ),
),
           

            
            

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  10,
                ),
                child: Row(
                  children: [
                    Text(
                      "Nearby Restaurants",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      "${filteredRestaurants.length} places",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),
            ),

                       if (loadingRestaurants)

              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            else if (isTablet)

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  100,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final restaurant =
                          filteredRestaurants[index];

                      return RestaurantCardWidget(
                        restaurant: restaurant,
                        onTap: () {
                          context.push(
                            AppRoutes.restaurantMenuScreen,
                            extra:{
                              'restaurantId': restaurant.id,
                              'restaurantPartnerId': restaurant.restaurantPartnerId,
                            },
                          );
                        },
                      );
                    },
                    childCount:
                        filteredRestaurants.length,
                  ),
                ),
              )

            else

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final restaurant =
                          filteredRestaurants[index];

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: RestaurantCardWidget(
                          restaurant: restaurant,
                          onTap: () {
                            context.push(
                              AppRoutes.restaurantMenuScreen,
                              extra: {
                                'restaurantId': restaurant.id,
                                'restaurantPartnerId': restaurant.restaurantPartnerId,
                              },
                            );
                          },
                        ),
                      );
                    },
                    childCount:
                        filteredRestaurants.length,
                  ),
                ),
              ),

           
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
               final selectedAddress = await context.push(
  AppRoutes.addressListScreen,
);

if (selectedAddress is Address) {
  setState(() {
    addresses = [
      selectedAddress,
      ...addresses.where(
        (a) => a.id != selectedAddress.id,
      ),
    ];
  });
} else {
  loadAddresses();
}
              },
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName:
                        'location_on_rounded',
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivering to",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loadingAddresses
                                    ? "Loading..."
                                    : addresses.isEmpty
                                        ? "Add Address"
                                        : addresses
                                            .first.address,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppTheme
                                              .headlineText,
                                        ),
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            CustomIconWidget(
                              iconName:
                                  'keyboard_arrow_down_rounded',
                              color: AppTheme
                                  .headlineText,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: () {
              context.push(
                AppRoutes.profileScreen,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                color: AppTheme.primary,
                boxShadow:
                    AppTheme.cardShadow,
              ),
              child: Center(
                child: Text(
                  customerName.trim().isNotEmpty
                      ? customerName
                          .trim()[0]
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}