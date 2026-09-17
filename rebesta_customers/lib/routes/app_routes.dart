import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rebesta_customers/models/address.dart';

import '../presentation/orders_screen/orders_screen.dart';

import '../presentation/auth/login_screen/login_screen.dart';
import '../presentation/auth/signup_screen/signup_screen.dart';


import '../presentation/checkout_screen/checkout_screen.dart';

import '../presentation/address/address_list_screen/address_list_screen.dart';
import '../presentation/address/add_address_screen/add_address_screen.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/restaurant_menu_screen/restaurant_menu_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';

import '../widgets/app_scaffold.dart';

// ============================================================================
// APP ROUTES
// ============================================================================

class AppRoutes {
  // ==========================================================================
  // SPLASH
  // ==========================================================================

  static const String splashScreen =
      '/splash-screen';

  // ==========================================================================
  // MAIN
  // ==========================================================================
  
  static const String paymentSuccessScreen =
    '/payment-success';

static const String paymentFailedScreen =
    '/payment-failed';

static const String paymentCancelledScreen =
    '/payment-cancelled';

    
  static const String homeScreen =
      '/home-screen';

  static const String ordersScreen =
      '/orders';

  static const String restaurantMenuScreen =
      '/restaurant-menu-screen';

 
  static const String checkoutScreen =
      '/checkout';

  static const String orderTrackingScreen =
      '/order-tracking-screen';

  // ==========================================================================
  // AUTH
  // ==========================================================================

  static const String loginScreen =
      '/login-screen';

  static const String signupScreen =
      '/signup-screen';

  // ==========================================================================
  // ADDRESS
  // ==========================================================================

  static const String addressListScreen =
      '/address-list';

  static const String addAddressScreen =
      '/add-address';
}

// ============================================================================
// GO ROUTER
// ============================================================================

final GoRouter appRouter = GoRouter(

  // ==========================================================================
  // INITIAL ROUTE
  // ==========================================================================

  initialLocation:
      AppRoutes.splashScreen,

  // ==========================================================================
  // ROUTES
  // ==========================================================================

  routes: [

    // ========================================================================
    // SPLASH
    // ========================================================================

    GoRoute(
      path: AppRoutes.splashScreen,
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // ========================================================================
    // LOGIN
    // ========================================================================

    GoRoute(
      path: AppRoutes.loginScreen,
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    // ========================================================================
    // SIGNUP
    // ========================================================================

    GoRoute(
      path: AppRoutes.signupScreen,
      builder: (context, state) {

        final extra = state.extra;

        // --------------------------------------------------------------------
        // Validate phone number
        // --------------------------------------------------------------------

        if (extra is! String ||
            extra.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid phone number',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return SignupScreen(
          phone: extra,
        );
      },
    ),

    // ========================================================================
    // MAIN APP SHELL
    // ========================================================================

    StatefulShellRoute.indexedStack(

      builder: (
        context,
        state,
        navigationShell,
      ) {
        return AppScaffold(
          navigationShell:
              navigationShell,
        );
      },

      // ======================================================================
      // SHELL BRANCHES
      // ======================================================================

      branches: [

        // ====================================================================
        // BRANCH 0 — HOME
        // ====================================================================

        StatefulShellBranch(
          routes: [

            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (
                context,
                state,
              ) {
                return const HomeScreen();
              },
            ),

          ],
        ),

        // ====================================================================
        // BRANCH 1 — ORDERS
        //
        // IMPORTANT:
        // This is the Orders bottom-navigation page.
        //
        // OrderTrackingScreen is NOT inside this branch.
        // It has its own standalone route below.
        // ====================================================================

        StatefulShellBranch(
          routes: [

            GoRoute(
              path: AppRoutes.ordersScreen,
              builder: (
                context,
                state,
              ) {
                return const OrdersScreen();
              },
            ),

          ],
        ),
      ],
    ),

    // ========================================================================
    // ORDER TRACKING
    //
    // IMPORTANT:
    // This is intentionally OUTSIDE the StatefulShellRoute.
    //
    // It can be opened from:
    //
    // 1. Checkout after successful payment
    // 2. OrdersScreen when user taps an order
    //
    // Example:
    //
    // context.go(
    //   AppRoutes.orderTrackingScreen,
    //   extra: orderId,
    // );
    //
    // ========================================================================

    GoRoute(
      path: AppRoutes.orderTrackingScreen,

      builder: (
        context,
        state,
      ) {

        final extra = state.extra;

        // --------------------------------------------------------------------
        // Validate order ID
        // --------------------------------------------------------------------

        if (extra is! String ||
            extra.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Order information is missing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------------------------
        // Open Order Tracking
        // --------------------------------------------------------------------

        return OrderTrackingScreen(
          orderId: extra,
        );
      },
    ),

    // ========================================================================
    // RESTAURANT MENU
    // ========================================================================

    GoRoute(
      path:
          AppRoutes.restaurantMenuScreen,

      builder: (
        context,
        state,
      ) {

        final extra = state.extra;

        // --------------------------------------------------------------------
        // Validate navigation data
        // --------------------------------------------------------------------

        if (extra
            is! Map<String, dynamic>) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid restaurant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------------------------
        // Restaurant ID
        // --------------------------------------------------------------------

        final restaurantId =
            extra['restaurantId']
                    ?.toString() ??
                '';

        // --------------------------------------------------------------------
        // Restaurant Partner ID
        // --------------------------------------------------------------------

        final restaurantPartnerId =
            extra['restaurantPartnerId']
                    ?.toString() ??
                '';

        // --------------------------------------------------------------------
        // Validate IDs
        // --------------------------------------------------------------------

        if (restaurantId.isEmpty ||
            restaurantPartnerId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid restaurant information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------------------------
        // Open restaurant menu
        // --------------------------------------------------------------------

        return RestaurantMenuScreen(
          restaurantId:
              restaurantId,
          restaurantPartnerId:
              restaurantPartnerId,
        );
      },
    ),

    // ========================================================================
    // CART
    // ========================================================================



    // ========================================================================
    // CHECKOUT
    // ========================================================================

// ========================================================================
// CHECKOUT
// ========================================================================

GoRoute(
  path: AppRoutes.checkoutScreen,

  builder: (
    context,
    state,
  ) {
    final extra = state.extra;

    // --------------------------------------------------------------------
    // Validate navigation data
    // --------------------------------------------------------------------

    if (extra is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Restaurant information is missing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // --------------------------------------------------------------------
    // Restaurant Partner ID
    // --------------------------------------------------------------------

    final restaurantPartnerId =
        extra['restaurantPartnerId']
                ?.toString() ??
            '';

    // --------------------------------------------------------------------
    // Restaurant Name
    // --------------------------------------------------------------------

    final restaurantName =
        extra['restaurantName']
                ?.toString() ??
            'Your order';

    // --------------------------------------------------------------------
    // Validate restaurant partner ID
    // --------------------------------------------------------------------

    if (restaurantPartnerId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Restaurant information is missing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // --------------------------------------------------------------------
    // Open checkout
    // --------------------------------------------------------------------

    return CheckoutScreen(
      restaurantPartnerId: restaurantPartnerId,
      restaurantName: restaurantName,
    );
  },
),

    // ========================================================================
    // ADDRESS LIST
    // ========================================================================

    GoRoute(
      path:
          AppRoutes.addressListScreen,

      builder: (
        context,
        state,
      ) {
        return const AddressListScreen();
      },
    ),

    // ========================================================================
    // ADD ADDRESS
    // ========================================================================

    GoRoute(
      path:
          AppRoutes.addAddressScreen,

      builder: (
        context,
        state,
      ) {

        final address =
            state.extra;

        return AddAddressScreen(
          address:
              address is Address
                  ? address
                  : null,
        );
      },
    ),
  ],

  // ==========================================================================
  // ERROR HANDLER
  // ==========================================================================

  errorBuilder: (
    context,
    state,
  ) {

    return Scaffold(
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              // ----------------------------------------------------------------
              // ERROR ICON
              // ----------------------------------------------------------------

              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(
                height: 16,
              ),

              // ----------------------------------------------------------------
              // TITLE
              // ----------------------------------------------------------------

              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ----------------------------------------------------------------
              // ERROR MESSAGE
              // ----------------------------------------------------------------

              Text(
                state.error?.toString() ??
                    'Unknown navigation error',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ----------------------------------------------------------------
              // GO HOME
              // ----------------------------------------------------------------

              ElevatedButton(
                onPressed: () {

                  context.go(
                    AppRoutes.homeScreen,
                  );

                },
                child:
                    const Text(
                  'Go Home',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);