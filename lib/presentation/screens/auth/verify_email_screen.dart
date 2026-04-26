
// verify_email_screen.dart
//
// Purpose: Instructs the user to check their email and verify their account.
// Responsibilities:
//   - Display confirmation that a verification email was sent.
//   - Provide a "Resend email" action with cooldown to prevent spam.
//   - Poll or listen to auth state and navigate to [profileSetup] once verified.
//   - All display strings sourced from [AppStrings].
// Dependencies:
//   - presentation/providers/auth_provider.dart
//   - core/constants/app_strings.dart, app_colors.dart

// ---------------------------------------------------------------------------
// verify_email_screen.dart
//
// Purpose: Shown after registration. User must verify email before proceeding.
// Polls auth state and auto-navigates when email is verified.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../services/supabase_service.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollingTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Check email verification status every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await SupabaseService.instance.auth.refreshSession();
        final user = SupabaseService.instance.currentUser;
        if (user?.emailConfirmedAt != null && mounted) {
          _pollingTimer?.cancel();
          _navigateAfterVerification();
        }
      } catch (_) {}
    });
  }

  Future<void> _navigateAfterVerification() async {
    final profile = await AuthRepository.instance.getCurrentUser();
    if (!mounted) return;
    if (profile != null) {
      ref.read(currentUserProvider.notifier).state = profile;
      // New user — go to profile setup
      context.go(RouteNames.profileSetup);
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      final email = SupabaseService.instance.currentUser?.email ?? '';
      await SupabaseService.instance.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      setState(() {
        _resendCooldown = 60;
        _isResending = false;
      });
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendCooldown <= 0) {
          t.cancel();
        } else {
          if (mounted) setState(() => _resendCooldown--);
        }
      });
    } catch (_) {
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 44,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 28),
              Text(AppStrings.verifyEmail,
                  style: AppTextStyles.displaySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in the email to continue.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Polling indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Waiting for verification...',
                      style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 40),
              AppButton(
                label: _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : AppStrings.resendEmail,
                onPressed: (_resendCooldown > 0 || _isResending)
                    ? null
                    : _resendEmail,
                isLoading: _isResending,
                variant: AppButtonVariant.outlined,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go(RouteNames.login);
                },
                child: Text('Use a different account',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

