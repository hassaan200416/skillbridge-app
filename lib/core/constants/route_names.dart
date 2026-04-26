// ---------------------------------------------------------------------------
// route_names.dart
//
// Purpose: All route path constants for go_router navigation.
// Never hardcode route strings in widgets — use RouteNames constants.
//
// ---------------------------------------------------------------------------

class RouteNames {
  RouteNames._();

  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String profileSetup = '/profile-setup';

  // Customer routes
  static const String customerHome = '/home';
  static const String search = '/search';
  static const String serviceDetail = '/service/:id';
  static const String providerProfile = '/provider/:id';
  static const String bookService = '/book/:id';
  static const String bookingConfirm = '/book/confirm';
  static const String myBookings = '/bookings';
  static const String bookingDetail = '/booking/:id';
  static const String writeReview = '/review/:id';
  static const String wishlist = '/saved';
  static const String customerNotifications = '/notifications';
  static const String customerProfile = '/profile';

  // Provider routes
  static const String providerHome = '/provider-home';
  static const String myServices = '/my-services';
  static const String addService = '/service/add';
  static const String editService = '/service/edit/:id';
  static const String incomingBookings = '/incoming-bookings';
  static const String providerCalendar = '/calendar';
  static const String providerBookingDetail = '/provider-booking/:id';
  static const String providerAnalytics = '/p/analytics';
  static const String providerReviews = '/p/reviews';
  static const String providerNotifications = '/provider-notifications';
  static const String providerProfileEdit = '/p/profile';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/user/:id';
  static const String adminServices = '/admin/services';
  static const String adminBookings = '/admin/bookings';
  static const String adminReviews = '/admin/reviews';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';
  static const String adminActivity = '/admin/activity';

  // Shared
  static const String notFound = '/404';

  // Helper: build routes with parameters
  static String serviceDetailPath(String id) => '/service/$id';
  static String providerProfilePath(String id) => '/provider/$id';
  static String bookServicePath(String id) => '/book/$id';
  static String bookingDetailPath(String id) => '/booking/$id';
  static String writeReviewPath(String id) => '/review/$id';
  static String adminUserDetailPath(String id) => '/admin/user/$id';
  static String editServicePath(String id) => '/service/edit/$id';
  static String providerBookingDetailPath(String id) => '/provider-booking/$id';
}
