
// ---------------------------------------------------------------------------
// write_review_screen.dart
//
// Purpose: Submit a rating + comment for a completed booking.
// Uses existing reviewActionProvider — no sub-ratings, no loyalty points.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  static const _ratingLabels = {
    1: ('Poor', Color(0xFFDC2626)),
    2: ('Fair', Color(0xFFF97316)),
    3: ('Good', Color(0xFFEAB308)),
    4: ('Very Good', Color(0xFF3B82F6)),
    5: ('Excellent', Color(0xFF16A34A)),
  };

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final reviewState = ref.watch(reviewActionProvider);
    final showSidebar = MediaQuery.sizeOf(context).width >= 800;

    ref.listen(reviewActionProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go(RouteNames.myBookings);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: showSidebar ? null : const _CustomerBottomNavBar(),
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(role: UserRole.customer, currentRoute: '/review'),
          Expanded(
            child: bookingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (booking) => Column(
                children: [
                  if (showSidebar) const AppTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: showSidebar ? 24 : 16,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Column(
                            children: [
                              _Breadcrumb(),
                              const SizedBox(height: 20),
                              Text(
                                booking.serviceName ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.grey500,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Service Provider:  '),
                                    TextSpan(
                                      text: booking.providerName ?? 'Provider',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Main review card
                              Container(
                                padding: EdgeInsets.all(showSidebar ? 28 : 18),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Overall experience
                                    Text(
                                      'Overall Experience',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Star rating
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 2,
                                      runSpacing: 2,
                                      children: List.generate(5, (i) {
                                        final starNumber = i + 1;
                                        final isSelected = starNumber <= _rating;
                                        return IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: reviewState.isLoading
                                              ? null
                                              : () => setState(
                                                  () => _rating = starNumber),
                                          icon: Icon(
                                            isSelected
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: showSidebar ? 40 : 34,
                                            color: isSelected
                                                ? const Color(0xFFF59E0B)
                                                : AppColors.grey300,
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),

                                    // Rating label
                                    if (_rating > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: _ratingLabels[_rating]!
                                              .$2
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _ratingLabels[_rating]!.$1,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _ratingLabels[_rating]!.$2,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 28),

                                    // Feedback heading
                                    LayoutBuilder(builder: (context, c) {
                                      final narrow = c.maxWidth < 420;
                                      final counter =
                                          '${_commentController.text.length} / 500 characters';
                                      if (narrow) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'YOUR DETAILED FEEDBACK',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.grey500,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              counter,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.grey400,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'YOUR DETAILED FEEDBACK',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.grey500,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          Text(
                                            counter,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    const SizedBox(height: 10),

                                    // Textarea
                                    TextField(
                                      controller: _commentController,
                                      maxLines: 6,
                                      maxLength: 500,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.secondary),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Tell others about the quality of work, professionalism, and turnaround time...',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.grey400,
                                        ),
                                        counterText: '',
                                        filled: true,
                                        fillColor: AppColors.grey50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.all(
                                            showSidebar ? 14 : 12),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Submit button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _rating == 0 ||
                                                reviewState.isLoading
                                            ? null
                                            : () => _submit(booking),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              AppColors.grey200,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: reviewState.isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Submit Review',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.send,
                                                      size: 16),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Disclaimer
                                    Text.rich(
                                      TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.grey400,
                                        ),
                                        children: const [
                                          TextSpan(
                                              text:
                                                  'By submitting, you confirm this feedback is based on a genuine service experience.'),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Verified transaction callout
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified_user,
                                          size: 18, color: Color(0xFF1E40AF)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Verified Transaction',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E40AF),
                                              )),
                                          Text(
                                            'Your review will be marked as verified since this service was booked through SkillBridge.',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF1E40AF),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(dynamic booking) {
    final user = ref.read(currentUserProvider);
    if (user == null || _rating == 0) return;

    ref.read(reviewActionProvider.notifier).submitReview(
          bookingId: widget.bookingId,
          serviceId: booking.serviceId,
          customerId: user.id,
          providerId: booking.providerId,
          serviceName: booking.serviceName ?? '',
          rating: _rating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.go(RouteNames.myBookings),
          child: Text('My Bookings',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
        ),
        Text('Write Review',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey500)),
      ],
    );
  }
}

class _CustomerBottomNavBar extends StatelessWidget {
  const _CustomerBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.customerHome);
          case 1:
            context.go(RouteNames.search);
          case 2:
            context.go(RouteNames.myBookings);
          case 3:
            _openMore(context);
          case 4:
            context.go(RouteNames.customerProfile);
        }
      },
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
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _openMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Saved'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go(RouteNames.wishlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chats'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go('/chats');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Announcements'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go('/announcements');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go(RouteNames.customerNotifications);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

