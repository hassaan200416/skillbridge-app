# SkillBridge Architecture & File Reference

A comprehensive guide explaining every file's role in the SkillBridge marketplace application.

---

## Table of Contents

1. [Core Layer](#core-layer)
2. [Data Layer](#data-layer)
3. [Domain Layer](#domain-layer)
4. [Services Layer](#services-layer)
5. [Presentation Layer](#presentation-layer)
6. [Project Root](#project-root)

---

## Core Layer

The core layer contains shared constants, configuration, and utilities used across the entire application.

### `lib/core/constants/`

#### **route_names.dart**

- **Purpose:** Central registry of all route path constants
- **Contains:** 28 named routes across 3 user roles (Customer, Provider, Admin)
- **Usage:** Referenced by `app_router.dart` to define navigation flow
- **Key Routes:**
  - Authentication: `/login`, `/register`, `/verify-email`, `/profile-setup`
  - Customer: `/home`, `/search`, `/my-bookings`, `/write-review`, `/chat`
  - Provider: `/provider-home`, `/my-services`, `/add-service`, `/provider-bookings`, `/provider-analytics`
  - Admin: `/admin-dashboard`, `/admin-users`, `/admin-services`, `/admin-bookings`, `/admin-reviews`, `/admin-activity`

#### **app_router.dart**

- **Purpose:** Complete navigation configuration for the entire application
- **Responsibilities:**
  - Defines route structure with shell routes (layout containers)
  - Implements role-based authentication guards (redirects unauthenticated users to login)
  - Enforces suspension checks (banned providers/users cannot access app)
  - Maps routes to screens with proper nesting
- **Key Logic:**
  - `_redirect()` method checks auth state and user status before allowing navigation
  - Separate navigation stacks for Customer, Provider, and Admin roles
  - Shell routes wrap screens with AppSidebar + AppTopBar on web
- **Dependencies:** Requires `AuthProvider` to determine user role and auth status
- **Note:** Used as `final appRouter = AppRouter.router()` in main.dart

#### **route_names.dart**

- **Purpose:** Route path constants to avoid magic strings throughout app
- **Usage:** Keep routes DRY and centralized for easy refactoring
- **Example:** `static const String homeScreen = '/home'`

#### **app_colors.dart**

- **Purpose:** Define all colors used in the UI
- **Contains:** Primary (green), secondary (navy), success/error/warning states, text colors, backgrounds
- **Usage:** Referenced in `app_text_styles.dart` and individual widgets
- **Design Token:** Consistent branding throughout app (green-navy-white theme)

#### **app_text_styles.dart**

- **Purpose:** Typography system defining all text styles
- **Contains:** Heading styles (h1-h6), body text, button text, caption styles
- **Font:** Uses Poppins (marketing/auth UI) and Inter (general app)
- **Usage:** Ensures consistent text hierarchy across screens
- **Example:** `AppTextStyles.h1` for main titles, `AppTextStyles.bodyLarge` for descriptions

#### **app_strings.dart**

- **Purpose:** Internationalization strings (currently English only)
- **Contains:** All user-facing text messages, labels, buttons, validation messages
- **Usage:** Eliminates hardcoded strings from widgets
- **Benefit:** Single point of change for copy updates

#### **app_breakpoints.dart**

- **Purpose:** Responsive design breakpoints
- **Contains:**
  - `compact` < 600px (mobile phones)
  - `medium` 600px–800px (tablets)
  - `expanded` ≥ 800px (desktop web)
- **Provides:** Helper methods like `isMobile()`, `isTablet()`, `isDesktop()`
- **Usage:** UI adapts sidebar/top-bar layout based on screen size

#### **exceptions.dart**

- **Purpose:** Custom exception hierarchy for error handling
- **Exceptions:**
  - `AppException`: Base exception with message
  - `AuthException`: Authentication/authorization failures
  - `NetworkException`: Network connectivity issues
  - `ServerException`: Backend 500 errors
  - `StorageException`: File upload/download failures
  - `NotFoundException`: Resource not found (404)
  - `PermissionException`: User lacks permission for action
- **Usage:** Thrown by repositories, caught by providers and handled at UI layer
- **Benefits:** Specific error handling per exception type

#### **failures.dart**

- **Purpose:** Enum for representing errors at the UI layer
- **Contains:** `noInternetFailure`, `serverFailure`, `notFoundFailure`, etc.
- **Pattern:** Result<T> type (Either<Failure, T> pattern for functional error handling)
- **Usage:** Providers convert exceptions to failures for safe UI display

---

## Data Layer

The data layer handles all backend communication, caching, and persistence. It includes models, repositories, and remote data sources.

### `lib/data/models/`

#### **user_model.dart**

- **Purpose:** Represents a user profile in the system
- **Fields:**
  - `id`, `email`, `name` (basic identity)
  - `role`: Customer, Provider, or Admin
  - `verified`: Email verification status
  - `suspended`: Account suspension flag (accounts banned by admin)
  - `profile_picture_url`: Avatar image (optional)
  - Role-specific fields: `experience_years` (provider), `service_area` (provider), `location` (customer)
- **Usage:** User state throughout app (stored in AuthProvider)
- **Serialization:** fromJson/toJson for Supabase deserialization

#### **booking_model.dart**

- **Purpose:** Represents a service booking transaction
- **Fields:**
  - `id`, `customer_id`, `provider_id`: Identity references
  - `service_id`: Which service is being booked
  - `booking_date`: The date of service
  - `time_slot`: Morning/Afternoon/Evening (3-slot system)
  - `status`: pending → confirmed → completed → cancelled (lifecycle)
  - `price_at_booking`: **Immutable snapshot** of price at time of booking (protects customer from price changes)
  - `created_at`, `updated_at`: Timestamps
- **Key Design:** `price_at_booking` is frozen at creation so prices can change without affecting past bookings
- **Usage:** Referenced by BookingProvider for state management
- **Database Schema:** Booking has RLS policies for customer/provider visibility

#### **service_model.dart**

- **Purpose:** Represents a service listing in the marketplace
- **Fields:**
  - `id`, `provider_id`: Service identity and owner
  - `title`, `description`: Service details
  - `category`: Home Cleaning, Plumbing, etc. (for filtering)
  - `price`: Current hourly/per-booking rate
  - `images`: List of up to 5 image URLs (stored in Supabase Storage)
  - `rating`: Average star rating (computed from reviews)
  - `is_active`: Soft-delete flag (service hidden from search if false)
  - `ai_summary`: Cached AI-generated summary (refreshed if >24 hours old)
- **Usage:** Displayed in home feed, search results, and detail pages
- **Key Logic:** Hard deletion is prevented to preserve booking history; use soft-delete instead

#### **review_model.dart**

- **Purpose:** Represents a customer review of a completed booking
- **Fields:**
  - `id`, `service_id`, `booking_id`, `customer_id`, `provider_id`: Relationships
  - `rating`: 1–5 stars
  - `comment`: Review text (optional)
  - `flagged`: Admin moderation flag
  - `provider_response`: Provider's reply to review (optional)
  - `created_at`: Timestamp
- **Usage:** Displayed on service detail page and provider profile
- **Key Logic:** One review per booking to prevent duplicate reviews

#### **chat_message_model.dart**

- **Purpose:** Individual chat message within a conversation
- **Fields:**
  - `id`, `conversation_id`: Message identity and parent thread
  - `sender_id`: User who sent the message
  - `text`: Message content
  - `created_at`: Timestamp
  - `is_bot`: Flag indicating SkillBot message vs. human message
- **Usage:** Chat panel streams messages in real-time
- **Immutability:** Model is immutable to prevent accidental state mutations

#### **chat_model.dart**

- **Purpose:** Represents a conversation thread
- **Fields:**
  - `id`: Unique thread identifier
  - `customer_id`, `provider_id`: The two participants
  - `last_message`: Most recent message text (for preview in list)
  - `unread_count`: Number of unread messages for current user
  - `updated_at`: Last activity timestamp
- **Usage:** Chat list shows one card per conversation
- **Key Logic:** Messages are real-time subscribed via Supabase; unread count auto-updates

#### **notification_model.dart**

- **Purpose:** In-app notification alert
- **Fields:**
  - `id`, `user_id`: Notification identity and recipient
  - `type`: booking_confirmed, booking_cancelled, new_review, announcement, etc.
  - `title`, `message`: Notification content
  - `related_id`: ID of booking/review/service that triggered notification
  - `read`: Boolean flag for read/unread state
  - `created_at`: Timestamp
- **Usage:** Notification bell shows unread count; clicking shows latest 3 + "View All"
- **Broadcasting:** When a booking status changes, system creates notifications for both customer and provider

#### **time_slot_model.dart**

- **Purpose:** Booking time slot with availability
- **Fields:**
  - `slot`: Morning, Afternoon, or Evening
  - `available`: Boolean indicating if slot is free on selected date
  - `displayName`: "9 AM - 12 PM" (formatted for UI)
- **Usage:** Time slot picker shows 3 options with enabled/disabled state
- **Formatting:** Helper method `displayName` converts slot enum to user-friendly string

### `lib/data/repositories/`

#### **auth_repository.dart**

- **Purpose:** Handles all authentication operations with Supabase Auth
- **Key Methods:**
  - `register()`: Create account with email/password/name/role
  - `login()`: Sign in with email/password
  - `logout()`: Sign out (clears session)
  - `verifyEmail()`: Check if email is confirmed (polling method)
  - `resendVerificationEmail()`: Send confirmation link
  - `completeProfileSetup()`: Store role-specific fields (experience_years for provider, location for customer)
  - `getUser()`: Fetch current authenticated user
  - `refreshSession()`: Refresh auth token
  - Admin methods: `suspendUser()`, `unsuspendUser()`, `listAllUsers()`
- **Error Handling:** Throws AuthException for invalid credentials, network errors, or server issues
- **Usage:** Called by AuthProvider to manage login/logout state

#### **booking_repository.dart**

- **Purpose:** Manages booking lifecycle from creation to completion
- **Key Methods:**
  - `createBooking()`: Create new booking with **two-step availability check** (date validation + customer-owns-service check)
  - `getCustomerBookings()`: Fetch all bookings where user is customer (filtered by status)
  - `getProviderBookings()`: Fetch all bookings where user is provider
  - `updateBookingStatus()`: Change booking status (pending → confirmed, or → completed/cancelled)
  - `getAvailableSlots()`: Determine which time slots are free on a given date
  - `getBookingDetail()`: Fetch single booking with provider/service details
  - `cancelBooking()`: Customer cancels a pending booking
  - `acceptBooking()`: Provider accepts a pending booking → confirmed
  - `rejectBooking()`: Provider rejects a booking (moved to cancelled)
  - Real-time methods: `watchCustomerBookings()`, `watchProviderBookings()` (stream subscriptions)
- **Key Design:**
  - `price_at_booking` is immutable snapshot at creation
  - `provider_id` is denormalized in booking table for RLS (Row-Level Security) performance
  - Soft-delete via status (no hard deletes to preserve history)
- **Usage:** Referenced by BookingProvider for all booking CRUD operations

#### **service_repository.dart**

- **Purpose:** Service discovery, filtering, and management
- **Key Methods:**
  - `getFeaturedServices()`: Curated list of top-rated/popular services
  - `getRecentServices()`: Services added in last 7 days
  - `searchServices()`: Advanced multi-filter search (category, price range, rating, text search)
    - AI-powered search: Uses Groq to extract search intent from natural language
    - Fallback: Regex matching on category names if AI extraction fails
  - `getServiceDetail()`: Fetch single service with provider info
  - `getProviderServices()`: Services owned by specific provider
  - `createService()`: Add new service (with image upload via StorageService)
  - `updateService()`: Edit service details
  - `deleteService()`: Soft-delete (set `is_active=false`)
  - `getServiceImages()`: List images for service (stored in Supabase Storage)
  - `cacheAiSummary()`: Store/refresh AI summary (cached for 24 hours to save API costs)
- **Key Design:**
  - Soft-delete via `is_active` flag (hard delete prevented to maintain booking history)
  - Image management delegated to StorageService
  - AI summary caching reduces Groq API calls
- **Usage:** Provides search results, featured feeds, and service detail pages

#### **chat_repository.dart**

- **Purpose:** Conversation management and real-time messaging
- **Key Methods:**
  - `createConversation()`: Start new thread (customer + provider)
  - `reuseConversation()`: Return existing conversation if one already exists
  - `getConversations()`: List all conversations for current user
  - `getMessages()`: Fetch messages for a specific conversation (paginated)
  - `sendMessage()`: Create new message in thread
  - `markAsRead()`: Update unread count when user views messages
  - `deleteConversation()`: Archive/delete thread
  - Real-time methods: `watchConversations()`, `watchMessages()` (stream subscriptions)
- **Real-time Flow:**
  - Uses Supabase Realtime subscriptions (PostgreSQL LISTEN/NOTIFY)
  - ChatDetailScreen subscribes to messages; auto-scrolls to bottom on new message
  - Auto-marks messages as read when user loads thread
- **Usage:** Chat list shows all conversations; chat detail streams live messages

#### **notification_repository.dart**

- **Purpose:** Notification creation, retrieval, and management
- **Key Methods:**
  - `createNotification()`: Insert notification (called by system when events occur)
  - `getUserNotifications()`: Fetch all notifications for current user (paginated)
  - `markAsRead()`: Toggle read flag
  - `deleteNotification()`: Remove notification
  - Real-time method: `watchUserNotifications()` (subscribes to INSERT events on user's notifications)
- **Real-time Flow:**
  - Supabase subscription callback on INSERT → triggers full list refresh (instead of incremental update, for simplicity)
  - Unread count provider uses subscription data to update badge
- **Error Handling:** Graceful degradation — if notification creation fails, booking still completes
- **Usage:** Notification bell and notification list

#### **user_repository.dart**

- **Purpose:** User profile operations (stub file — defines interface for future implementation)
- **Key Methods (Interface):**
  - `getUser()`: Fetch user profile by ID
  - `updateUser()`: Edit user details
  - `listUsers()`: Get all users (admin function)
  - `getProvidersByCity()`: Filter providers by service area
  - `suspendUser()`: Admin action to ban user
- **Current Status:** Currently throws UnimplementedError (actual implementation delegated to auth_repository for now)
- **Purpose:** Placeholder for future user management refactoring

#### **storage_repository_impl.dart**

- **Purpose:** File operations (upload/download images to Supabase Storage)
- **Key Methods:**
  - `uploadFile()`: Upload image to Supabase Storage bucket
  - `downloadFile()`: Retrieve image from bucket
  - `deleteFile()`: Remove image from storage
  - `getPublicUrl()`: Generate shareable URL for image
- **Bucket Structure:** `{bucket_name}/{userId}/{filename}` (organized by user for RLS)
- **Error Handling:** Throws StorageException if upload fails
- **Usage:** Image carousel, service add/edit, profile picture uploads

---

## Domain Layer

The domain layer contains business logic entities and abstract repository contracts (currently minimal in this project as logic is pushed to data layer for simplicity).

### `lib/domain/`

_Note: This project uses a simplified domain layer. Complex business logic is in repositories or providers rather than domain entities._

- **entities/**: Would contain pure Dart objects representing business domain concepts (User, Booking, Service, etc.)
- **repositories/**: Abstract interfaces that data repositories implement
- **usecases/**: Would encapsulate specific business workflows (GetServicesByCategory, CreateBooking, etc.)

_Currently, this layer is sparse because the app prioritizes pragmatism over strict layering. Consider expanding this layer if business logic becomes more complex._

---

## Services Layer

The services layer contains singleton services that integrate external APIs and cross-cutting concerns.

### `lib/services/`

#### **supabase_service.dart**

- **Purpose:** Singleton wrapper for Supabase client initialization
- **Responsibilities:**
  - Initializes Supabase connection with project URL and anon key
  - Provides centralized access to `supabaseClient` throughout app
  - Manages session lifecycle (login/logout affects this client)
- **Usage:** Imported by repositories to execute SQL queries and auth operations
- **Security:** Uses anon key (safe for client-side) with RLS policies on backend

#### **ai_service.dart**

- **Purpose:** AI-powered features via Groq API (llama-3.1-8b-instant model)
- **Key Methods:**
  - `sendSkillBotMessage()`: Customer/provider chat with AI assistant
    - Enforces **dual-layer scope checking** to keep SkillBot on-topic:
      1. **Fast local filter**: Regex patterns catch obvious off-topic requests (phone numbers, personal data requests)
      2. **Groq classifier**: Asks model to judge if request is about SkillBridge services
    - Returns refusal message: _"I can only help with SkillBridge questions. For that, please use a general search engine or assistant."_
  - `extractSearchIntent()`: Parses natural language search query into structured form (category, price range, rating)
    - Example: _"affordable plumber under 3000"_ → `{ category: "Plumbing", maxPrice: 3000 }`
    - Falls back to keyword matching if extraction fails
  - `summarizeReview()`: Generates AI summary from review text (cached for 24 hours)
  - System prompts: Role-specific context for customer, provider, and admin bots
- **API Configuration:** Groq OpenAI-compatible endpoint with API key from `app.env`
- **Error Handling:** Catches API errors and returns empty response (graceful degradation)
- **Usage:** SkillBot widget, search screen, service model caching

#### **notification_service.dart**

- **Purpose:** Trigger notifications for booking and review events
- **Key Methods:**
  - `notifyBookingConfirmed()`: Send notification when booking is confirmed
  - `notifyBookingCancelled()`: Notify both parties of cancellation
  - `notifyNewReview()`: Notify provider of new review
  - `notifyReviewResponse()`: Notify customer when provider replies to review
  - `sendSystemAnnouncement()`: Admin broadcast message to all users
- **Error Handling:** Graceful degradation — if notification creation fails, the main action (booking, review) still succeeds
- **Usage:** Called by booking/review repositories after status updates
- **Note:** Currently non-critical notifications (failures don't block main operations)

#### **storage_service.dart**

- **Purpose:** Image picking and upload to Supabase Storage
- **Key Methods:**
  - `pickImages()`: Open device file picker (multi-select)
  - `uploadImage()`: Upload single image to Supabase Storage bucket
  - `uploadMultipleImages()`: Upload batch (with progress tracking)
  - `deleteImage()`: Remove image from storage
- **Permissions:** Requests camera/gallery permissions on Android/iOS
- **Progress Tracking:** Callback for upload progress bar UI
- **Error Handling:** Throws StorageException on failure
- **Usage:** Add/edit service screen (image carousel), profile picture uploads

---

## Presentation Layer

The presentation layer contains screens, widgets, and state management providers. It's organized by feature and shared components.

### State Management: `lib/presentation/providers/`

#### **auth_provider.dart**

- **Purpose:** Global authentication state
- **Providers:**
  - `authStateProvider`: Current authenticated user (User model)
  - `isAuthenticatedProvider`: Boolean flag (true if logged in)
  - `userRoleProvider`: User's role (customer/provider/admin)
- **Actions:**
  - `login()`: Email/password authentication
  - `register()`: Create account with role
  - `logout()`: Sign out
  - `completeProfileSetup()`: Store role-specific fields
- **Usage:** Referenced by `app_router.dart` for auth guards; used by screens to fetch current user

#### **booking_provider.dart**

- **Purpose:** Booking state and lifecycle management
- **Providers:**
  - `customerBookingsProvider`: Stream of current user's bookings (as customer)
  - `providerBookingsProvider`: Stream of current user's bookings (as provider)
  - `bookingDetailProvider`: Single booking detail with provider/service info
  - `availableSlotsProvider`: Time slots available for a given date
  - Real-time streams: Auto-refresh when bookings change on backend
- **Actions:**
  - `createBooking()`: Create new booking → auto-invalidates customer bookings stream
  - `cancelBooking()`: Customer cancels
  - `acceptBooking()`: Provider accepts
  - `rejectBooking()`: Provider rejects
  - `updateBookingStatus()`: Generic status change
- **Key Logic:**
  - Automatic provider invalidation after mutations (ensures fresh data)
  - Availability calculation: Exclude already-booked time slots
- **Usage:** Booking list screens, booking detail, book service form

#### **service_provider.dart**

- **Purpose:** Service discovery and search
- **Providers:**
  - `featuredServicesProvider`: Top-rated/popular services
  - `recentServicesProvider`: Recently added services
  - `searchResultsProvider`: Filtered search results
  - `serviceDetailProvider`: Single service with reviews/ratings
  - `providerServicesProvider`: Services owned by specific provider
- **Actions:**
  - `searchServices()`: Execute multi-filter search (calls ServiceRepository)
  - `createService()`: Add new service with images
  - `updateService()`: Edit service
  - `deleteService()`: Soft-delete service
- **Key Logic:** AI search extraction delegates to AiService; fallback to regex if AI fails
- **Usage:** Home feed, search screen, service detail page, provider's service list

#### **notification_provider.dart**

- **Purpose:** Real-time notification management
- **Providers:**
  - `userNotificationsProvider`: Stream of all notifications (real-time subscription)
  - `unreadNotificationCountProvider`: Unread count for bell badge
  - `userNotificationDetailsProvider`: Single notification detail
- **Actions:**
  - `markNotificationAsRead()`: Toggle read flag
  - `deleteNotification()`: Remove notification
- **Real-time Flow:**
  - Supabase subscription on INSERT event → StreamController emits updated list
  - UI bell badge automatically updates when new notification arrives
  - Chat messages auto-update unread count when viewed
- **Usage:** Notification bell, notification list/detail screens

#### **review_provider.dart**

- **Purpose:** Review submission and moderation
- **Providers:**
  - `reviewsByServiceProvider`: Fetch reviews for service
  - `reviewsByCustomerProvider`: Customer's own reviews
  - `reviewsByProviderProvider`: Reviews provider has received
  - `flaggedReviewsProvider`: Admin view of flagged reviews
- **Actions:**
  - `submitReview()`: Create review after booking completion
  - `editReview()`: Customer edits existing review
  - `deleteReview()`: Remove review
  - `addProviderResponse()`: Provider replies to review
  - `flagReview()`: Mark review as inappropriate (admin flag)
  - `approveReview()` / `rejectReview()`: Admin moderation
- **Usage:** Write review screen, service reviews list, admin moderation screen

#### **chat_provider.dart**

- **Purpose:** Real-time chat state
- **Providers:**
  - `conversationsProvider`: List of all user's conversations
  - `messagesProvider`: Messages in specific conversation (real-time stream)
  - `conversationDetailProvider`: Single conversation with metadata
  - `unreadMessagesCountProvider`: Total unread messages
- **Actions:**
  - `createConversation()`: Start new thread with provider/customer
  - `sendMessage()`: Send chat message
  - `markConversationAsRead()`: Clear unread count
  - `deleteConversation()`: Archive conversation
- **Real-time Flow:**
  - Messages stream auto-updates when new message inserted
  - Auto-scroll to bottom in ChatDetailScreen
  - Unread count updates on subscription callback
- **Usage:** Chat list, chat detail screen

#### **skillbot_provider.dart**

- **Purpose:** Customer SkillBot AI assistant state
- **Providers:**
  - `skillbotMessagesProvider`: Chat history (user messages + AI responses)
  - `skillbotLoadingProvider`: Loading state during API call
  - `skillbotErrorProvider`: Error message if request fails
- **Actions:**
  - `sendSkillBotMessage()`: Send customer query → get AI response via AiService
  - `clearSkillBotChat()`: Reset conversation history
- **System Prompt:** Scoped to customer service discovery and booking help
- **Usage:** SkillBot floating widget on customer screens

#### **provider_skillbot_provider.dart**

- **Purpose:** Provider SkillBot AI assistant state (mirrors customer but with provider context)
- **System Prompt:** Scoped to provider booking management, earnings, and customer communication
- **Usage:** SkillBot widget on provider screens

#### **customer_layout_provider.dart**

- **Purpose:** UI state for customer dashboard
- **Providers:**
  - `sidebarCollapseProvider`: Sidebar toggle state (persisted in SharedPreferences)
- **Actions:**
  - `toggleSidebar()`: Open/close sidebar
  - `setSidebarState()`: Explicitly set state
- **Usage:** App sidebar responsiveness; persists layout preference across sessions

### Screens: `lib/presentation/screens/`

#### **Authentication Screens** (`lib/presentation/screens/auth/`)

##### **login_screen.dart**

- **UI:** Email input, password input, login button, register link
- **Logic:**
  - Form validation (email format, password required)
  - Calls `AuthProvider.login()`
  - On success: Navigate to role-specific home screen
  - On error: Show snackbar with error message
- **Usage:** Entry point for returning users

##### **register_screen.dart**

- **UI:** Name, email, password, password confirmation, role selector (Customer/Provider/Admin)
- **Logic:**
  - Form validation
  - Calls `AuthProvider.register()`
  - On success: Navigate to profile setup screen
  - On error: Show error message
- **Usage:** New user onboarding

##### **verify_email_screen.dart**

- **UI:** Message "Verification link sent", countdown timer (60s), resend button
- **Logic:**
  - Polls `AuthProvider.verifyEmail()` every 2 seconds to check if email is confirmed
  - On verified: Auto-navigate to profile setup
  - Resend button disabled during 60s cooldown
- **Key Design:** Simplified UX (no email link click required; app just polls server)
- **Usage:** Between register and profile setup

##### **profile_setup_screen.dart**

- **UI:** Role-specific forms (provider: experience_years + service_area; customer: location)
- **Logic:**
  - Calls `AuthProvider.completeProfileSetup()`
  - On success: Navigate to home screen
- **Usage:** Final step before accessing app

#### **Customer Screens** (`lib/presentation/screens/customer/`)

##### **customer_home_screen.dart**

- **UI:** Top bar, sidebar, featured services carousel, recent services list, bottom navigation (mobile)
- **Logic:**
  - Fetches `ServiceProvider.featuredServicesProvider` and `ServiceProvider.recentServicesProvider`
  - Tap service → navigate to service detail
  - Search button → navigate to search screen
- **Usage:** Customer entry point after login

##### **search_screen.dart**

- **UI:**
  - Search input field
  - AI extraction banner (shows when natural language is detected)
  - Category chip scroller
  - Filter panel (sort, price range, rating minimum)
  - Search results list
- **Logic:**
  - On input: Calls `AiService.extractSearchIntent()` for natural language parsing
  - Builds filter parameters from UI selections
  - Calls `ServiceRepository.searchServices()` with filters
  - Shows results with provider info, rating, price
- **Key Feature:** AI natural language search ("affordable plumber under 3000" → auto-fills category/price)
- **Fallback:** If AI extraction fails, uses keyword matching on category names
- **Usage:** Primary discovery method for customers

##### **service_details_screen.dart**

- **UI:**
  - Service image carousel (hero animation)
  - Service title, category, price, rating
  - Provider profile card (tap to view provider)
  - Service description
  - Review list (newest first)
  - Book button
  - Wishlist toggle
- **Logic:**
  - Fetches `ServiceProvider.serviceDetailProvider`
  - Tap Book → navigate to book_service_screen
  - Fetches reviews from `ReviewProvider`
- **Usage:** Before booking

##### **book_service_screen.dart**

- **UI:**
  - Date picker (calendar)
  - Time slot selector (Morning/Afternoon/Evening)
  - Price display (price_at_booking snapshot)
  - Confirm booking button
- **Logic:**
  - Validates date is in future and slots are available
  - Calls `BookingProvider.createBooking()`
  - On success: Navigate to my_bookings_screen
- **Key Logic:** Uses `BookingProvider.availableSlotsProvider` to show only free slots
- **Usage:** Booking creation

##### **my_bookings_screen.dart**

- **UI:**
  - Status filter tabs (Pending, Confirmed, Completed, Cancelled)
  - Booking list (date, service name, provider name, status badge, price)
- **Logic:**
  - Filters bookings by selected status
  - Tap booking → show detail (modal or new screen)
  - If completed: Show "Write Review" button
- **Usage:** View booking history

##### **write_review_screen.dart**

- **UI:**
  - Star rating selector (1-5)
  - Comment textarea
  - Submit button
- **Logic:**
  - Calls `ReviewProvider.submitReview()`
  - Optimistic UI update (show review immediately before confirmation)
  - On success: Navigate back to my_bookings
- **Usage:** After booking completion

##### **profile_screen.dart**

- **UI:** Customer name, email, location, edit button, profile picture
- **Logic:**
  - Fetches current user from `AuthProvider`
  - Edit button → opens edit form
  - On save: Calls auth_repository.updateUserProfile()
- **Usage:** Customer settings/profile view

#### **Provider Screens** (`lib/presentation/screens/provider/`)

##### **provider_home_screen.dart**

- **UI:**
  - Welcome message with provider name
  - Metric cards: total revenue, completed bookings, avg rating, completion rate
  - Incoming bookings list (pending status only)
  - Quick stats
- **Logic:**
  - Aggregates `BookingProvider.providerBookingsProvider` to calculate metrics
  - Shows pending bookings with accept/reject buttons
- **Usage:** Provider dashboard entry point

##### **my_services_screen.dart**

- **UI:**
  - Service list (title, category, price, image, active/draft toggle)
  - Search/filter
  - Add service button (FAB)
- **Logic:**
  - Fetches `ServiceProvider.providerServicesProvider`
  - Toggle switches between active/draft mode
  - Tap service → navigate to edit_service_screen
  - Add button → navigate to add_service_screen
- **Usage:** Manage service listings

##### **add_edit_service_screen.dart**

- **UI:**
  - Title input
  - Category dropdown
  - Price input
  - Description textarea
  - Image picker (multi-select, up to 5)
  - Submit button
- **Logic:**
  - Calls `ServiceProvider.createService()` or `ServiceProvider.updateService()`
  - Images uploaded via `StorageService`
  - On success: Navigate back to my_services_screen
- **Usage:** Service creation and editing

##### **incoming_bookings_screen.dart**

- **UI:**
  - Pending bookings list (customer name, service, date, time slot)
  - Accept / Reject buttons per booking
- **Logic:**
  - Fetches `BookingProvider.providerBookingsProvider` filtered to pending
  - Accept → calls `BookingProvider.acceptBooking()` (status → confirmed)
  - Reject → calls `BookingProvider.rejectBooking()` (status → cancelled)
  - System auto-creates notifications for both parties
- **Usage:** Accept/reject incoming service requests

##### **provider_analytics_screen.dart**

- **UI:**
  - Metric cards (revenue, completed count, avg rating, completion rate)
  - Earnings line chart with time filter (1 month daily, 6 months monthly, 12 months monthly)
  - Bookings donut chart (pending/confirmed/completed/cancelled breakdown)
  - Top services bar chart (revenue by service)
- **Key Logic:**
  - Revenue: Sum of `price_at_booking` for completed bookings only
  - Earnings chart: Aggregates completed bookings by date (bucketing logic: daily for <30 days, monthly for longer)
  - Completion rate: (completed / total) \* 100
  - Top services: Bar chart sorted by revenue descending
- **UI Interactions:** Tap donut slice to see count; hover on chart bars for values
- **Usage:** Provider business insights

##### **provider_reviews_screen.dart**

- **UI:** Reviews received with star rating, customer name, comment, date
- **Logic:**
  - Fetches `ReviewProvider.reviewsByProviderProvider`
  - Shows provider response if exists
  - Reply button (edit response)
- **Usage:** View and respond to customer reviews

##### **profile_screen.dart**

- **UI:** Provider name, email, experience years, service area, profile picture, edit button
- **Logic:**
  - Fetches current provider from `AuthProvider`
  - Edit → opens form
  - On save: Updates profile via auth_repository
- **Usage:** Provider settings/profile view

#### **Admin Screens** (`lib/presentation/screens/admin/`)

##### **admin_dashboard_screen.dart**

- **UI:**
  - KPI cards (total revenue all-time, active users count, pending disputes/issues)
  - Quick action buttons
  - Recent activity feed
- **Logic:**
  - Aggregates data from repositories
  - Tap card → navigate to detailed screen (users, bookings, etc.)
- **Usage:** Admin overview

##### **admin_users_management_screen.dart**

- **UI:**
  - User table (name, email, role, status, suspension toggle)
  - Search by name/email
  - Filter by role (Customer, Provider, Admin)
- **Logic:**
  - Fetches `UserProvider.listAllUsersProvider()` (or auth_repository direct call)
  - Toggle suspension → calls `AuthRepository.suspendUser()` / `unsuspendUser()`
  - Suspended users cannot log in; redirected after auth check
- **Usage:** User moderation

##### **admin_services_management_screen.dart**

- **UI:**
  - Service table (title, provider, category, price, active toggle)
  - Search by service name
  - Delete button
- **Logic:**
  - Fetches all services (admin view)
  - Toggle active/inactive (soft delete)
  - Delete button → hard delete with confirmation
- **Usage:** Service moderation

##### **admin_bookings_management_screen.dart**

- **UI:**
  - Booking table (customer, provider, service, date, status)
  - Filter by status
  - Export button (optional)
- **Logic:**
  - Fetches all bookings from BookingRepository
  - Admin can see all bookings across platform
- **Usage:** Booking oversight

##### **admin_reviews_management_screen.dart**

- **UI:**
  - Review table (service, customer, rating, comment)
  - Flagged filter (show only flagged reviews)
  - Approve / Delete buttons
- **Logic:**
  - Fetches `ReviewProvider.flaggedReviewsProvider()`
  - Approve → unflag review
  - Delete → remove review permanently
- **Usage:** Content moderation

##### **admin_activity_screen.dart**

- **UI:**
  - User breakdown pie chart (customers, providers, admins)
  - Booking distribution pie chart (pending, confirmed, completed, cancelled)
  - Services by category bar chart (count by category)
  - Monthly booking trend line chart (last 12 months)
  - Top providers leaderboard (name, completed bookings, revenue)
- **Key Logic:**
  - User breakdown: Count users per role from UserRepository
  - Booking distribution: Group bookings by status, calculate percentages
  - Services by category: Group services by category value, sum counts
  - Monthly trend: Aggregate bookings by month, plot completed count
  - Top providers: Sort providers by revenue (sum completed booking prices) descending
- **Usage:** Platform analytics and insights

#### **Shared Screens** (`lib/presentation/screens/shared/`)

##### **chat_detail_screen.dart**

- **UI:**
  - Top bar with conversation participant name
  - Message list (bubbles, right-aligned for user, left-aligned for other party)
  - Input field with send button
  - Delete conversation button
- **Logic:**
  - Subscribes to `ChatProvider.messagesProvider` (real-time stream)
  - On new message: Auto-scroll-to-bottom using Flutter.bindingInstance callback
  - On screen load: Calls `ChatProvider.markConversationAsRead()` to clear unread badge
  - Send message: Calls `ChatProvider.sendMessage()`
  - Delete: Confirmation dialog → calls `ChatProvider.deleteConversation()`
- **Responsive Layout:**
  - Web (expanded): Sidebar left + top-bar top + messages right
  - Mobile (compact): Full-screen messages with top bar
- **Usage:** Live conversation between customer and provider

##### **chat_list_screen.dart**

- **UI:**
  - List of conversations (other party name, last message preview, unread badge)
  - Tap conversation → open chat_detail_screen
  - Pull-to-refresh
- **Logic:**
  - Fetches `ChatProvider.conversationsProvider` (real-time stream)
  - Unread badge shows count from `ChatProvider.unreadMessagesCountProvider`
  - Pull-to-refresh calls `ChatRepository.reloadConversations()`
- **Usage:** Chat inbox

##### **splash_screen.dart**

- **UI:** SkillBridge logo, loading spinner
- **Logic:**
  - On init: Polls `AuthProvider.getUser()` to check if session exists
  - If authenticated: Auto-navigate to role-specific home (customer_home, provider_home, or admin_dashboard)
  - If not authenticated after 2s timeout: Navigate to login_screen
- **Usage:** App launch entry point (before router redirect)

### Widgets: `lib/presentation/widgets/`

#### **app_top_bar.dart**

- **Purpose:** Consistent top navigation across all screens
- **Contains:**
  - Hamburger icon (toggles `CustomerLayoutProvider.sidebarCollapseProvider`)
  - Search button (navigates to `/search` with query param for customer; `/my-services` for provider)
  - Notification bell with unread badge count
  - Profile dropdown (email display, "Profile" link, "Sign Out" button)
- **Responsive:** Full width on all breakpoints; adapts for mobile
- **Design Tokens:** Primary green for active states, secondary navy for text
- **Usage:** Header on every screen (wrapped by shell route in app_router.dart)

#### **app_sidebar.dart**

- **Purpose:** Role-specific navigation menu
- **Customer Routes:**
  - Home → `/home`
  - Search → `/search`
  - My Bookings → `/my-bookings`
  - Chat → `/chat`
  - More (submenu)
  - Profile → `/profile`
- **Provider Routes:**
  - Dashboard → `/provider-home`
  - My Services → `/my-services`
  - Incoming Bookings → `/provider-bookings`
  - Analytics → `/provider-analytics`
  - More (submenu)
  - Profile → `/provider-profile`
- **Admin Routes:**
  - Dashboard → `/admin-dashboard`
  - Users → `/admin-users`
  - Services → `/admin-services`
  - Bookings → `/admin-bookings`
  - Reviews → `/admin-reviews`
  - Activity → `/admin-activity`
  - Settings → `/admin-settings`
- **Responsive:** Collapses to icon-only on medium breakpoints; hides on mobile (hamburger in top-bar)
- **Persistence:** Collapse state persists via `customer_layout_provider.dart`
- **Usage:** Left sidebar on web layouts

#### **service_image_carousel.dart**

- **Purpose:** Display service images with swipe navigation
- **Features:**
  - PageView-based horizontal swipe
  - Dot indicator with active highlight animation
  - Image counter ("1 / 5")
  - Loading spinner while fetching image
  - Error state with icon + fallback text
  - Placeholder when no images provided
  - Hero animation for smooth detail view transition
- **Props:** `images` (List<String>), `onImageTap` callback
- **Usage:** Service detail page, service list cards

#### **skillbot_widget.dart**

- **Purpose:** Floating chat button for customer SkillBot AI assistant
- **Features:**
  - Floating action button (FAB) with SkillBot icon
  - Tap FAB → opens chat panel (overlay)
  - Chat panel shows message history, input field, suggested prompts
  - Real-time message streaming with typing indicator
  - Auto-scroll to latest message
  - Refusal messages for out-of-scope questions
  - Clear chat button
- **State:** Uses `SkillBotProvider` for messages, loading, error
- **Usage:** Visible on customer screens (home, search, service detail, etc.)

#### **provider_skillbot_widget.dart**

- **Purpose:** Floating chat button for provider SkillBot AI assistant
- **Features:** Same as skillbot_widget.dart but with provider-specific system prompt
- **State:** Uses `ProviderSkillBotProvider`
- **Usage:** Visible on provider screens (dashboard, services, analytics, etc.)

#### **app_button.dart**

- **Purpose:** Reusable button component with consistent styling
- **Props:**
  - `label`: Button text
  - `onPressed`: Callback function
  - `variant`: filled, outlined, ghost
  - `disabled`: Boolean to disable button
  - `loading`: Show spinner during async operation
  - `icon`: Optional icon to left of text
- **Styling:** Uses `AppColors` and `AppTextStyles`
- **Usage:** CTA buttons across all screens

#### **app_text_field_widget.dart**

- **Purpose:** Reusable text input component
- **Props:**
  - `label`: Input label
  - `hint`: Placeholder text
  - `value`: Current value
  - `onChanged`: Callback on text change
  - `validator`: Function to validate input
  - `obscureText`: For password fields
  - `error`: Show error message below input
- **Styling:** Material Design text field with error state highlighting
- **Usage:** Forms throughout app (login, register, profile, service add/edit)

#### **rating_widget.dart**

- **Purpose:** Display or select star ratings
- **Modes:**
  - Read-only: Display 1-5 stars (frozen)
  - Interactive: Allow user to tap stars to select rating
- **Features:**
  - Half-star support (for display, e.g., 4.5 stars)
  - Color-coded (gold for stars, grey for empty)
  - Animated selection feedback
- **Props:** `rating`, `onRatingChanged` (for interactive mode)
- **Usage:** Service detail (display rating), write review screen (select rating)

#### **user_avatar_widget.dart**

- **Purpose:** User profile picture display
- **Features:**
  - Circular avatar
  - If image URL provided: NetworkImage with caching
  - If no image: Show initials (first letter of name) on colored background
  - Fallback to default icon if initials unavailable
- **Props:** `name`, `imageUrl`, `size`
- **Usage:** Top bar (current user), chat messages (participant avatar), provider profile card

---

## Project Root

### Configuration Files

#### **pubspec.yaml**

- **Purpose:** Flutter project manifest and dependency declaration
- **Key Sections:**
  - `environment`: Dart SDK version (≥3.4.0)
  - `dependencies`: All pub.dev packages (Supabase, Riverpod, GoRouter, etc.)
  - `dev_dependencies`: Build tools (build_runner for Riverpod code generation, flutter_test, flutter_lints)
  - `flutter`: Asset configuration (loads `assets/app.env`)
- **Build Commands:** `flutter pub get` to install dependencies

#### **analysis_options.yaml**

- **Purpose:** Dart analyzer configuration and linting rules
- **Contains:** Custom linter rules to enforce code quality (naming conventions, avoid deprecated APIs, etc.)
- **Usage:** Run `flutter analyze` to check for violations

#### **app.env** (in `assets/`)

- **Purpose:** Environment variables for backend configuration
- **Contains:**
  - Supabase project URL
  - Supabase anon key
  - Groq API key (for SkillBot AI)
  - Backend URLs (if using custom server)
- **Security:** File is gitignored (not committed to repo); developers copy example to local
- **Usage:** Loaded by `flutter_dotenv` in main.dart

#### **main.dart**

- **Purpose:** Application entry point
- **Key Functions:**
  - Loads environment variables from `assets/app.env`
  - Initializes Supabase client via `SupabaseService.initialize()`
  - Sets up Riverpod state management
  - Configures GoRouter for navigation
  - Renders `MyApp` widget with Material design and theme
- **Error Handling:** Error boundary for uncaught exceptions
- **Usage:** Run `flutter run` to start app

#### **README.md**

- **Purpose:** Project documentation and setup guide
- **Contains:** Overview, features, tech stack, database schema, getting started, deployment instructions, design system, test accounts
- **Usage:** First reference for developers onboarding to project

#### **vercel.json**

- **Purpose:** Deployment configuration for Vercel (web hosting)
- **Contains:** Build command, output directory, environment variables
- **Usage:** Automatic CI/CD on git push to main branch

#### **build.sh**

- **Purpose:** Build script for generating release builds
- **Platforms:** Android (APK/AAB), iOS (IPA), Web, Windows, Linux, macOS
- **Usage:** Run `./build.sh android` to build Android release

### Build Artifacts

#### **build/** directory

- **Purpose:** Generated build outputs and intermediate files
- **Contains:** Compiled Dart, Kotlin, iOS/macOS frameworks, JavaScript bundles
- **Note:** Gitignored; regenerated on `flutter clean && flutter build`

#### **.iml files** (skillbridge.iml, android/skillbridge_android.iml)

- **Purpose:** IntelliJ IDEA module files
- **Usage:** Android Studio project configuration
- **Note:** Auto-generated; safe to ignore

---

## Summary

This architecture implements **Clean Architecture** with role-based access control, real-time updates via Supabase, and AI-powered features:

- **Separation of Concerns:** Core (constants) → Data (API/DB) → Domain (business logic) → Services (cross-cutting) → Presentation (UI)
- **State Management:** Riverpod for reactive, composable state
- **Real-time Sync:** Supabase subscriptions for live chat, bookings, notifications
- **AI Integration:** Groq LLM for search intent extraction and SkillBot assistant
- **Role-Based UI:** Customer, Provider, Admin screens with specific workflows
- **Responsive Design:** Mobile-first with tablet/desktop support

Every file serves a specific purpose in this layered architecture. Understanding the separation between repositories (data access), providers (state), and screens (UI) is key to extending the codebase.
