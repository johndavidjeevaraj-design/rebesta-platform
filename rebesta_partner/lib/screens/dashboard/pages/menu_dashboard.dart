import 'package:flutter/material.dart';

import '../../../widgets/menu/menu_category_filter.dart';
import '../../menu/add_dish_screen.dart';
import '../../../core/services/partner_menu_service.dart';

class MenuDashboard extends StatefulWidget {
  const MenuDashboard({super.key});

  @override
  State<MenuDashboard> createState() =>
      _MenuDashboardState();
}

class _MenuDashboardState extends State<MenuDashboard> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _menu = [];

  @override
  void initState() {
    super.initState();

    _loadMenu();
  }

  // ============================================================
  // LOAD PARTNER MENU
  // ============================================================

  Future<void> _loadMenu() async {
    try {
      debugPrint('================================');
      debugPrint('🍽️ LOADING PARTNER MENU');
      debugPrint('================================');

      final menu =
          await PartnerMenuService.getPartnerMenu();

      if (!mounted) return;

      setState(() {
        _menu = menu;
        _loading = false;
        _error = null;
      });

      debugPrint('================================');
      debugPrint('✅ PARTNER MENU LOADED');
      debugPrint('Items: ${_menu.length}');
      debugPrint('================================');
    } catch (e) {
      debugPrint('================================');
      debugPrint('❌ PARTNER MENU ERROR');
      debugPrint('$e');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _loading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Menu Management",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadMenu,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          ),
        ],
      ),

      // ========================================================
      // ADD DISH
      // ========================================================

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffFF5A1F),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddDishScreen(),
            ),
          );
        },

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xffFF5A1F),
        ),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              const Text(
                'Unable to load menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loadMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xffFF5A1F),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // MENU
    // ----------------------------------------------------------

    return RefreshIndicator(
      color: const Color(0xffFF5A1F),

      onRefresh: _loadMenu,

      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const MenuCategoryFilter(),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // EMPTY MENU
          // ----------------------------------------------------

          if (_menu.isEmpty)
            _buildEmptyState(),

          // ----------------------------------------------------
          // REAL MENU ITEMS
          // ----------------------------------------------------

          ..._menu.map(
            (item) {
              return _MenuCard(
                name:
                    item['name']?.toString() ??
                        'Unnamed Item',

                price:
                    _formatPrice(
                  item['price'],
                ),

                category:
                    item['category']?.toString() ??
                        'Uncategorized',

                available:
                    item['isAvailable'] == true,

                imageUrl:
                    item['imageUrl']?.toString(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 60,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'No menu items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Add your first dish to start building your menu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICE FORMAT
  // ============================================================

  String _formatPrice(dynamic price) {
    if (price == null) {
      return '₹0.00';
    }

    final number = double.tryParse(
      price.toString(),
    );

    if (number == null) {
      return '₹$price';
    }

    return '₹${number.toStringAsFixed(2)}';
  }
}

// =================================================================
// MENU CARD
// =================================================================

class _MenuCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final bool available;
  final String? imageUrl;

  const _MenuCard({
    required this.name,
    required this.price,
    required this.category,
    required this.available,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.grey.withValues(alpha: .08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // IMAGE
          // ======================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),

            child: Container(
              width: 90,
              height: 90,
              color: Colors.orange.shade100,

              child:
                  imageUrl != null &&
                          imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,

                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.fastfood,
                              size: 42,
                              color:
                                  Color(0xffFF5A1F),
                            );
                          },
                        )
                      : const Icon(
                          Icons.fastfood,
                          size: 42,
                          color:
                              Color(0xffFF5A1F),
                        ),
            ),
          ),

          const SizedBox(width: 16),

          // ======================================================
          // DETAILS
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          fontFamily:
                              "Poppins",
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.orange.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: const Text(
                        "⭐ Bestseller",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  category,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  price,
                  style:
                      const TextStyle(
                    color:
                        Color(0xffFF5A1F),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      available
                          ? Icons.check_circle
                          : Icons.cancel,

                      color: available
                          ? Colors.green
                          : Colors.red,

                      size: 18,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      available
                          ? "Available"
                          : "Unavailable",
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {
                        // Edit dish
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        // Delete dish
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}