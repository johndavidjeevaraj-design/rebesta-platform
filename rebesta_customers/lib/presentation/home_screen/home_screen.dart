import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/address.dart';
import '../../models/customer.dart';
import '../../models/restaurant.dart';
import './widgets/home_main_filters_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/address_service.dart';
import '../../services/profile_service.dart';
import '../../services/restaurant_service.dart';
import './widgets/home_cravings_widget.dart';
import '../../theme/app_theme.dart';
import './widgets/home_promo_banner_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/custom_image_widget.dart';
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

  final List<String> _categories = [
  'All',
  'Burgers',
  'Pizza',
  'Sushi',
  'Thai',
  'Salads',
  'Desserts',
];

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
    onTap: () {
      // We'll connect this to real category data.
    },
  ),
),




  SliverToBoxAdapter(
              child: OrderAgainWidget(
                onOrderTap: () {
                  context.push(
                    AppRoutes.orderTrackingScreen,
                  );
                },
              ),
            ),


SliverToBoxAdapter(
  child: HomeCravingsWidget(
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
  child: const HomePromoBannerWidget(),
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

          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  boxShadow:
                      AppTheme.cardShadow,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName:
                        'notifications_outlined',
                    color: AppTheme
                        .headlineText,
                    size: 22,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.errorColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(12),
              boxShadow:
                  AppTheme.cardShadow,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),
              child: const CustomImageWidget(
                imageUrl:
                    "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200",
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                semanticLabel:
                    "Profile Image",
              ),
            ),
          ),
        ],
      ),
    );
  }
}