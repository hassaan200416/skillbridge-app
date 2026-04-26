
// ---------------------------------------------------------------------------
// app_router.dart
//
// Purpose: Complete go_router navigation configuration for SkillBridge.
//
// Responsibilities:
//   - Define all 28 routes
//   - Role-based redirect guards (customer/provider/admin see different screens)
//   - Auth guard (unauthenticated users go to login)
//   - Suspension guard (suspended users are logged out)
//
// Architecture:
//   - Router is a Riverpod provider so it can read auth state
//   - Redirects react to authStateProvider changes
//   - ShellRoute provides bottom navigation for each role
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
import '../../presentation/screens/auth/profile_setup_screen.dart';
import '../../presentation/screens/shared/splash_screen.dart';
import '../../presentation/screens/shared/not_found_screen.dart';
import '../../presentation/screens/customer/home_screen.dart';
import '../../presentation/screens/customer/search_screen.dart';
import '../../presentation/screens/customer/service_detail_screen.dart';
import '../../presentation/screens/customer/provider_profile_screen.dart';
import '../../presentation/screens/customer/book_service_screen.dart';
import '../../presentation/screens/customer/booking_confirm_screen.dart';
import '../../presentation/screens/customer/my_bookings_screen.dart';
import '../../presentation/screens/customer/booking_detail_screen.dart';
import '../../presentation/screens/customer/write_review_screen.dart';
import '../../presentation/screens/customer/wishlist_screen.dart';
import '../../presentation/screens/customer/notifications_screen.dart';
import '../../presentation/screens/customer/customer_profile_screen.dart';
import '../../presentation/screens/shared/chat_list_screen.dart';
import '../../presentation/screens/shared/chat_detail_screen.dart';
import '../../presentation/screens/shared/announcements_screen.dart';
import '../../presentation/screens/provider/provider_home_screen.dart';
import '../../presentation/screens/provider/my_services_screen.dart';
import '../../presentation/screens/provider/add_edit_service_screen.dart';
import '../../presentation/screens/provider/incoming_bookings_screen.dart';
import '../../presentation/screens/provider/provider_booking_detail_screen.dart';
import '../../presentation/screens/provider/provider_analytics_screen.dart';
import '../../presentation/screens/provider/provider_reviews_screen.dart';
import '../../presentation/screens/provider/provider_notifications_screen.dart';
import '../../presentation/screens/provider/provider_profile_edit_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_user_detail_screen.dart';
import '../../presentation/screens/admin/admin_services_screen.dart';
import '../../presentation/screens/admin/admin_service_detail_screen.dart';
import '../../presentation/screens/admin/admin_bookings_screen.dart';
import '../../presentation/screens/admin/admin_booking_detail_screen.dart';
import '../../presentation/screens/admin/admin_reviews_screen.dart';
import '../../presentation/screens/admin/admin_notifications_screen.dart';
import '../../presentation/screens/admin/admin_settings_screen.dart';
import '../../presentation/screens/admin/admin_activity_screen.dart';
import '../../presentation/widgets/common/app_sidebar.dart';
import '../../presentation/widgets/common/app_top_bar.dart';
import 'route_names.dart';

// Navigator keys for shell routes — prevents GlobalKey conflicts
// when transitioning between shell and standalone routes
final _customerShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'customerShell');
final _providerShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'providerShell');
final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

/// The router provider — reads auth state for redirects
final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state for router refresh
  final authNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) => authNotifier._redirect(state),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ── Customer Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _customerShellKey,
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.customerHome,
            name: 'customer-home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.search,
            name: 'search',
            builder: (context, state) => SearchScreen(
              initialCategory: state.uri.queryParameters['category'],
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: RouteNames.myBookings,
            name: 'my-bookings',
            builder: (context, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: RouteNames.wishlist,
            name: 'wishlist',
            builder: (context, state) => const WishlistScreen(),
          ),
          GoRoute(
            path: '/chats',
            name: 'customer-chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: RouteNames.customerProfile,
            name: 'customer-profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
          GoRoute(
            path: '/announcements',
            name: 'customer-announcements',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: RouteNames.customerNotifications,
            name: 'customer-notifications',
            builder: (context, state) => const CustomerNotificationsScreen(),
          ),
        ],
      ),

      // ── Customer Detail Routes (no bottom nav) ───────────────────────────
      GoRoute(
        path: RouteNames.addService,
        name: 'add-service',
        builder: (context, state) => const AddEditServiceScreen(),
      ),
      GoRoute(
        path: '/service/edit/:id',
        name: 'edit-service',
        builder: (context, state) => AddEditServiceScreen(
          serviceId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/service/:id',
        name: 'service-detail',
        builder: (context, state) => ServiceDetailScreen(
          serviceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/provider/:id',
        name: 'provider-profile',
        builder: (context, state) => ProviderProfileScreen(
          providerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.bookingConfirm,
        name: 'booking-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingConfirmScreen(bookingData: extra ?? {});
        },
      ),
      GoRoute(
        path: '/book/:id',
        name: 'book-service',
        builder: (context, state) => BookServiceScreen(
          serviceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'booking-detail',
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/review/:id',
        name: 'write-review',
        builder: (context, state) => WriteReviewScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat-detail',
        builder: (context, state) => ChatDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      // ── Provider Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _providerShellKey,
        builder: (context, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.providerHome,
            name: 'provider-home',
            builder: (context, state) => const ProviderHomeScreen(),
          ),
          GoRoute(
            path: RouteNames.myServices,
            name: 'my-services',
            builder: (context, state) => MyServicesScreen(
              searchQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: RouteNames.incomingBookings,
            name: 'incoming-bookings',
            builder: (context, state) => const IncomingBookingsScreen(),
          ),
          GoRoute(
            path: RouteNames.providerAnalytics,
            name: 'provider-analytics',
            builder: (context, state) => const ProviderAnalyticsScreen(),
          ),
          GoRoute(
            path: '/p/chats',
            name: 'provider-chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/p/announcements',
            name: 'provider-announcements',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
        ],
      ),

      // ── Provider Detail Routes (no bottom nav) ───────────────────────────
      GoRoute(
        path: '/provider-booking/:id',
        name: 'provider-booking-detail',
        builder: (context, state) => ProviderBookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/p/booking/:id',
        name: 'provider-booking-detail-short',
        builder: (context, state) => ProviderBookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.providerReviews,
        name: 'provider-reviews',
        builder: (context, state) => const ProviderReviewsScreen(),
      ),
      GoRoute(
        path: RouteNames.providerNotifications,
        name: 'provider-notifications',
        builder: (context, state) => const ProviderNotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.providerProfileEdit,
        name: 'provider-profile-edit',
        builder: (context, state) => const ProviderProfileEditScreen(),
      ),

      // ── Admin Shell ──────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.adminUsers,
            name: 'admin-users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: RouteNames.adminServices,
            name: 'admin-services',
            builder: (context, state) => const AdminServicesScreen(),
          ),
          GoRoute(
            path: RouteNames.adminBookings,
            name: 'admin-bookings',
            builder: (context, state) => const AdminBookingsScreen(),
          ),
          GoRoute(
            path: RouteNames.adminReviews,
            name: 'admin-reviews',
            builder: (context, state) => const AdminReviewsScreen(),
          ),
          GoRoute(
            path: RouteNames.adminActivity,
            name: 'admin-activity',
            builder: (context, state) => const AdminActivityScreen(),
          ),
          GoRoute(
            path: RouteNames.adminNotifications,
            name: 'admin-notifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: RouteNames.adminSettings,
            name: 'admin-settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/service/:id',
            name: 'admin-service-detail',
            builder: (context, state) => AdminServiceDetailScreen(
              serviceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/booking/:id',
            name: 'admin-booking-detail',
            builder: (context, state) => AdminBookingDetailScreen(
              bookingId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ── Admin Detail Routes (no bottom nav) ──────────────────────────────
      GoRoute(
        path: '/admin/user/:id',
        name: 'admin-user-detail',
        builder: (context, state) => AdminUserDetailScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

// ── Router Notifier ────────────────────────────────────────────────────────

/// Listens to auth state changes and notifies the router to re-evaluate redirects
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? _redirect(GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final currentUser = _ref.read(currentUserProvider);
    final location = state.matchedLocation;

    // While auth is loading, stay on splash
    if (authState.isLoading) {
      if (location != RouteNames.splash) return RouteNames.splash;
      return null;
    }

    final isLoggedIn = authState.valueOrNull?.session != null;

    // Auth routes: login, register, verify, profile-setup
    final isAuthRoute = location == RouteNames.login ||
        location == RouteNames.register ||
        location == RouteNames.verifyEmail ||
        location == RouteNames.profileSetup ||
        location == RouteNames.splash;

    // Not logged in — redirect to login
    if (!isLoggedIn) {
      if (!isAuthRoute) {
        return RouteNames.login;
      }
      return null;
    }

    // Logged in but no user profile loaded yet
    if (isLoggedIn && currentUser == null) {
      if (location != RouteNames.splash) return RouteNames.splash;
      return null;
    }

    // Logged in with profile
    if (currentUser != null) {
      // If on auth route, redirect to role-appropriate home
      if (isAuthRoute) {
        return _getRoleHome(currentUser.role);
      }

      // Enforce role-based access
      final isCustomerRoute = location.startsWith('/home') ||
          location.startsWith('/search') ||
          location.startsWith('/service') ||
          location.startsWith('/book') ||
          location.startsWith('/booking') ||
          location.startsWith('/review') ||
          location.startsWith('/saved') ||
          location.startsWith('/notifications') ||
          location.startsWith('/profile') ||
          location.startsWith('/provider/');

      final isProviderRoute = location.startsWith('/provider-home') ||
          location.startsWith('/my-services') ||
          location.startsWith('/incoming') ||
          location.startsWith('/p/analytics') ||
          location.startsWith('/p/reviews') ||
          location.startsWith('/provider-notifications') ||
          location.startsWith('/p/profile') ||
          location.startsWith('/provider-booking');

      final isAdminRoute = location.startsWith('/admin');

      if (isAdminRoute && currentUser.role != UserRole.admin) {
        return _getRoleHome(currentUser.role);
      }
      if (isProviderRoute && currentUser.role != UserRole.provider) {
        return _getRoleHome(currentUser.role);
      }
      if (isCustomerRoute && currentUser.role == UserRole.provider) {
        // Providers can view service/provider detail pages
        final isViewOnly = location.startsWith('/service/') ||
            location.startsWith('/provider/');
        if (!isViewOnly) {
          return _getRoleHome(currentUser.role);
        }
      }
    }

    return null;
  }

  String _getRoleHome(UserRole role) {
    switch (role) {
      case UserRole.provider:
        return RouteNames.providerHome;
      case UserRole.admin:
        return RouteNames.adminDashboard;
      case UserRole.customer:
        return RouteNames.customerHome;
    }
  }
}

// ── Shell Widgets ──────────────────────────────────────────────────────────

/// Unified shell for customer role — sidebar on web, bottom nav on mobile.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (showSidebar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Row(
          children: [
            AppSidebar(
              role: UserRole.customer,
              currentRoute: currentRoute,
            ),
            Expanded(
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF5F7FA),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: child,
      bottomNavigationBar: _CustomerBottomNav(),
    );
  }
}

class _CustomerBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndex(location);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _navigate(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Saved',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/bookings')) return 2;
    if (location.startsWith('/saved')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.customerHome);
      case 1:
        context.go(RouteNames.search);
      case 2:
        context.go(RouteNames.myBookings);
      case 3:
        context.go(RouteNames.wishlist);
      case 4:
        context.go(RouteNames.customerProfile);
    }
  }
}

/// Unified shell for provider role — sidebar on web, bottom nav on mobile.
class ProviderShell extends ConsumerWidget {
  const ProviderShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (showSidebar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Row(
          children: [
            AppSidebar(
              role: UserRole.provider,
              currentRoute: currentRoute,
            ),
            Expanded(
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF5F7FA),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: child,
      bottomNavigationBar: _ProviderBottomNav(),
    );
  }
}

class _ProviderBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndex(location);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _navigate(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/provider-home')) return 0;
    if (location.startsWith('/my-services')) return 1;
    if (location.startsWith('/incoming')) return 2;
    if (location.startsWith('/p/analytics') ||
        location.startsWith('/analytics')) {
      return 3;
    }
    if (location.startsWith('/p/profile') ||
        location.startsWith('/provider-profile')) {
      return 4;
    }
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.providerHome);
      case 1:
        context.go(RouteNames.myServices);
      case 2:
        context.go(RouteNames.incomingBookings);
      case 3:
        context.go(RouteNames.providerAnalytics);
      case 4:
        context.go(RouteNames.providerProfileEdit);
    }
  }
}

/// Unified shell for admin role — sidebar on web.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          if (showSidebar)
            AppSidebar(
              role: UserRole.admin,
              currentRoute: currentRoute,
            ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
