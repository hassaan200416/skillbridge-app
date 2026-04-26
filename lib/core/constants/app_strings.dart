// ---------------------------------------------------------------------------
// app_strings.dart
//
// Purpose: All user-facing strings in one place.
// Never hardcode strings in widgets — always use AppStrings.
// This makes localization easy in the future.
//
// ---------------------------------------------------------------------------

class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'SkillBridge';
  static const String appTagline = 'Find trusted local services';

  // Auth screens
  static const String login = 'Login';
  static const String register = 'Create account';
  static const String email = 'Email address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm password';
  static const String fullName = 'Full name';
  static const String phoneNumber = 'Phone number';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign up';
  static const String signIn = 'Sign in';
  static const String logout = 'Logout';
  static const String logoutConfirm = 'Are you sure you want to logout?';

  // Role selection
  static const String selectRole = 'I want to...';
  static const String roleCustomer = 'Find Services';
  static const String roleProvider = 'Offer Services';
  static const String roleCustomerDesc = 'Browse and book local service providers';
  static const String roleProviderDesc = 'List your services and grow your business';

  // Email verification
  static const String verifyEmail = 'Verify your email';
  static const String verifyEmailBody =
      'We sent a verification link to your email. Please check your inbox and click the link to continue.';
  static const String resendEmail = 'Resend email';
  static const String checkEmail = 'Check your email';

  // Profile setup
  static const String setupProfile = 'Set up your profile';
  static const String setupProfileSubtitle = 'Help others know who you are';
  static const String city = 'City / Area';
  static const String bio = 'About you';
  static const String experienceYears = 'Years of experience';
  static const String serviceArea = 'Service area';
  static const String addPhoto = 'Add photo';
  static const String changePhoto = 'Change photo';
  static const String saveProfile = 'Save profile';
  static const String skipForNow = 'Skip for now';

  // Home screen
  static const String hello = 'Hello';
  static const String findService = 'What service do you need?';
  static const String featuredServices = 'Featured services';
  static const String recentlyAdded = 'Recently added';
  static const String forYou = 'For you';
  static const String seeAll = 'See all';
  static const String topRated = 'Top rated';
  static const String mostBooked = 'Most booked';

  // Categories
  static const String homeRepair = 'Home Repair';
  static const String tutoring = 'Tutoring';
  static const String cleaning = 'Cleaning';
  static const String electrician = 'Electrician';
  static const String plumber = 'Plumber';
  static const String mechanic = 'Mechanic';
  static const String beauty = 'Beauty';
  static const String graphicDesign = 'Graphic Design';
  static const String moving = 'Moving';
  static const String other = 'Other';

  // Search
  static const String search = 'Search services...';
  static const String searchHint = 'e.g. "fix my AC" or "math tutor"';
  static const String filters = 'Filters';
  static const String sortBy = 'Sort by';
  static const String priceRange = 'Price range';
  static const String minRating = 'Minimum rating';
  static const String applyFilters = 'Apply filters';
  static const String clearFilters = 'Clear filters';
  static const String searchResults = 'Search results';
  static const String noResults = 'No services found';
  static const String noResultsSubtitle = 'Try different keywords or filters';

  // Service detail
  static const String bookNow = 'Book now';
  static const String reviews = 'Reviews';
  static const String noReviews = 'No reviews yet';
  static const String aiSummary = 'AI review summary';
  static const String viewProvider = 'View provider profile';
  static const String shareService = 'Share';
  static const String saveService = 'Save';
  static const String savedService = 'Saved';
  static const String startingFrom = 'Starting from';
  static const String fixedPrice = 'Fixed price';

  // Booking
  static const String bookService = 'Book service';
  static const String selectDate = 'Select date';
  static const String selectTimeSlot = 'Select time slot';
  static const String morning = 'Morning';
  static const String afternoon = 'Afternoon';
  static const String evening = 'Evening';
  static const String morningTime = '8:00 AM – 12:00 PM';
  static const String afternoonTime = '12:00 PM – 5:00 PM';
  static const String eveningTime = '5:00 PM – 9:00 PM';
  static const String addNote = 'Add a note (optional)';
  static const String noteHint = 'Describe your requirements...';
  static const String confirmBooking = 'Confirm booking';
  static const String bookingConfirmed = 'Booking sent!';
  static const String bookingConfirmedBody =
      'Your booking request has been sent to the provider. You will be notified when they respond.';

  // Booking status
  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String disputed = 'Disputed';

  // My bookings
  static const String myBookings = 'My bookings';
  static const String allBookings = 'All';
  static const String cancelBooking = 'Cancel booking';
  static const String cancelBookingConfirm =
      'Are you sure you want to cancel this booking?';
  static const String rebookService = 'Book again';
  static const String writeReview = 'Write review';

  // Review
  static const String rateYourExperience = 'Rate your experience';
  static const String writeYourReview = 'Write your review (optional)';
  static const String reviewHint = 'How was the service?';
  static const String submitReview = 'Submit review';
  static const String reviewSubmitted = 'Review submitted!';
  static const String editReview = 'Edit review';

  // Provider dashboard
  static const String providerDashboard = 'Dashboard';
  static const String myServices = 'My services';
  static const String addService = 'Add service';
  static const String editService = 'Edit service';
  static const String incomingBookings = 'Incoming bookings';
  static const String acceptBooking = 'Accept';
  static const String rejectBooking = 'Reject';
  static const String markCompleted = 'Mark as completed';
  static const String rejectionReason = 'Reason for rejection (optional)';
  static const String earnings = 'Earnings';
  static const String thisMonth = 'This month';
  static const String lastMonth = 'Last month';
  static const String allTime = 'All time';
  static const String analytics = 'Analytics';

  // Service form
  static const String serviceTitle = 'Service title';
  static const String serviceTitleHint = 'e.g. Professional AC Repair';
  static const String serviceDescription = 'Description';
  static const String serviceDescriptionHint =
      'Describe your service in detail...';
  static const String category = 'Category';
  static const String price = 'Price (PKR)';
  static const String priceType = 'Price type';
  static const String addImages = 'Add images';
  static const String publishService = 'Publish service';
  static const String saveAsDraft = 'Save as draft';
  static const String deleteService = 'Delete service';
  static const String deleteServiceConfirm =
      'Are you sure? This cannot be undone.';

  // Admin
  static const String adminDashboard = 'Admin dashboard';
  static const String allUsers = 'All users';
  static const String suspendUser = 'Suspend account';
  static const String unsuspendUser = 'Unsuspend account';
  static const String grantVerified = 'Grant verified badge';
  static const String revokeVerified = 'Revoke verified badge';
  static const String deactivateService = 'Deactivate service';
  static const String deleteReview = 'Delete review';
  static const String platformAnnouncement = 'New announcement';

  // Notifications
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications yet';
  static const String markAllRead = 'Mark all as read';

  // Wishlist
  static const String wishlist = 'Saved services';
  static const String noSavedServices = 'No saved services yet';
  static const String noSavedServicesSubtitle =
      'Tap the heart icon on any service to save it';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'No internet connection. Check your network.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorNotFound = 'Not found.';
  static const String errorPermission =
      'You do not have permission to do this.';
  static const String errorAccountSuspended =
      'Your account has been suspended. Contact support.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordShort =
      'Password must be at least 8 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorNameShort = 'Name must be at least 2 characters.';
  static const String errorRequired = 'This field is required.';
  static const String errorPriceInvalid = 'Please enter a valid price.';

  // Success
  static const String successProfileUpdated = 'Profile updated successfully.';
  static const String successServiceCreated = 'Service published successfully.';
  static const String successServiceUpdated = 'Service updated successfully.';
  static const String successBookingCreated = 'Booking request sent.';
  static const String successReviewSubmitted = 'Review submitted. Thank you!';

  // Common actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String done = 'Done';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String pkr = 'PKR';
}
