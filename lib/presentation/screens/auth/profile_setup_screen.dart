// ---------------------------------------------------------------------------
// profile_setup_screen.dart
//
// First-time profile setup after email verification.
// Required fields differ by role: providers need bio, experience, service area.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
          userId: user.id,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          experienceYears: _experienceController.text.trim().isEmpty
              ? null
              : int.tryParse(_experienceController.text.trim()),
          serviceArea: _serviceAreaController.text.trim().isEmpty
              ? null
              : _serviceAreaController.text.trim(),
        );

    if (!mounted) return;
    if (success) _navigateToHome();
  }

  void _navigateToHome() {
    final user = ref.read(currentUserProvider);
    switch (user?.role) {
      case UserRole.provider:
        context.go(RouteNames.providerHome);
      case UserRole.admin:
        context.go(RouteNames.adminDashboard);
      default:
        context.go(RouteNames.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final isProvider = user?.role == UserRole.provider;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header
                Text(AppStrings.setupProfile,
                    style: AppTextStyles.displaySmall),
                const SizedBox(height: 4),
                Text(AppStrings.setupProfileSubtitle,
                    style: AppTextStyles.bodyMedium),

                const SizedBox(height: 8),

                // Progress indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text('Email verified!',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.success)),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Role badge
                if (user != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isProvider
                          ? AppColors.providerColor.withValues(alpha: 0.1)
                          : AppColors.customerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isProvider
                          ? 'Setting up as Service Provider'
                          : 'Setting up as Customer',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isProvider
                            ? AppColors.providerColor
                            : AppColors.customerColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Phone
                AppTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneNumber,
                  hint: '+92 300 1234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // City
                AppTextField(
                  controller: _cityController,
                  label: AppStrings.city,
                  hint: 'Karachi, Lahore, Islamabad...',
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                ),

                // Provider-only fields
                if (isProvider) ...[
                  const SizedBox(height: 24),
                  Text('Provider details', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _bioController,
                    label: AppStrings.bio,
                    hint: 'Tell customers about yourself...',
                    prefixIcon: Icons.info_outline,
                    maxLines: 3,
                    validator: (val) =>
                        isProvider ? Validators.required(val, 'Bio') : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _experienceController,
                    label: AppStrings.experienceYears,
                    hint: '5',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.work_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _serviceAreaController,
                    label: AppStrings.serviceArea,
                    hint: 'DHA, Gulshan, F-7...',
                    prefixIcon: Icons.map_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                ],

                const SizedBox(height: 32),

                AppButton(
                  label: AppStrings.saveProfile,
                  onPressed: authState.isLoading ? null : _saveProfile,
                  isLoading: authState.isLoading,
                ),

                const SizedBox(height: 12),

                AppButton(
                  label: AppStrings.skipForNow,
                  onPressed: _navigateToHome,
                  variant: AppButtonVariant.text,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

