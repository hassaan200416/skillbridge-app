
import 'dart:math' as math;

/// ---------------------------------------------------------------------------
/// login_screen.dart
/// Premium split-screen login for SkillBridge web/desktop.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      final user = ref.read(currentUserProvider);
      if (user != null) _navigateToRoleHome(user.role);
    }
  }

  void _navigateToRoleHome(UserRole role) {
    final route = switch (role) {
      UserRole.provider => RouteNames.providerHome,
      UserRole.admin => RouteNames.adminDashboard,
      UserRole.customer => RouteNames.customerHome,
    };
    context.go(route);
  }

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid_credentials') ||
        lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    // Fallback: strip raw exception wrappers and keep only useful message.
    final cleaned = raw
        .replaceAll(RegExp(r'AuthApiException\(message:\s*'), '')
        .replaceAll(RegExp(r',\s*statusCode:.*$'), '')
        .replaceAll(')', '')
        .trim();
    return cleaned.isNotEmpty
        ? cleaned
        : 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyAuthError(next.error!.message)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.microtask(() {
          if (mounted) {
            ref.read(authNotifierProvider.notifier).clearError();
          }
        });
      }
    });

    final formContent = _FormContent(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      onTogglePassword: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onLogin: authState.isLoading ? null : _login,
      isLoading: authState.isLoading,
      onForgotPassword: () => _showForgotPassword(context),
      onRegister: () => context.go(RouteNames.register),
    );

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final viewportH = MediaQuery.sizeOf(context).height;
          return SizedBox(
            height: viewportH,
            child: isWide
                ? _WideLayout(formContent: formContent)
                : _NarrowLayout(formContent: formContent),
          );
        },
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Enter your email to receive a reset link.',
                style: GoogleFonts.inter(color: AppColors.grey500)),
            const SizedBox(height: 20),
            AppTextField(
              controller: emailController,
              label: 'Email address',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            Consumer(builder: (ctx, ref, _) {
              final state = ref.watch(authNotifierProvider);
              return AppButton(
                label: 'Send reset link',
                isLoading: state.isLoading,
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .sendPasswordReset(emailController.text.trim());
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Reset link sent! Check your email.'
                                  : 'Failed to send reset link.'),
                              backgroundColor:
                                  success ? AppColors.success : AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Wide layout: split 55/45, fixed viewport — content scales down when it
// would otherwise exceed height (no page scroll).
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.formContent});
  final Widget formContent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — 55%
        Expanded(
          flex: 55,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/professional_workspace.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              // Dark overlay
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0D1B2A).withValues(alpha: 0.72),
                ),
              ),
              // Content (uniform scale when shorter than viewport)
              Positioned.fill(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: c.maxWidth * 0.92,
                            height: c.maxHeight,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.handshake_outlined,
                                        color: AppColors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppStrings.appName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // Headline
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                      height: 1.15,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'Find trusted\nlocal '),
                                      TextSpan(
                                        text: 'services',
                                        style: GoogleFonts.poppins(
                                          fontSize: 46,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          height: 1.15,
                                        ),
                                      ),
                                      const TextSpan(text: '\nnear you.'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  'Connect with the top 1% of verified service\nproviders in your city. Seamless booking,\nguaranteed quality.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.white.withValues(alpha: 0.72),
                                    height: 1.65,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Category pills
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Home Repair',
                                    'Wellness',
                                    'Education',
                                    'Creative',
                                    'Technical',
                                    'Cleaning',
                                  ]
                                      .map((cat) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 7),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.22),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              cat,
                                              style: GoogleFonts.inter(
                                                color: AppColors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),

                                const Spacer(),

                                // Stats
                                Row(
                                  children: [
                                    _StatCard2(
                                        value: '500+', label: 'PROVIDERS'),
                                    const SizedBox(width: 10),
                                    _StatCard2(
                                        value: '10+', label: 'CATEGORIES'),
                                    const SizedBox(width: 10),
                                    _StatCard2(
                                        value: '4.9★', label: 'AVG. RATING'),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  'EMPOWERING LOCAL EXCELLENCE SINCE 2024',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.white.withValues(alpha: 0.4),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right panel — 45% (scale down only when needed; no upscaling past 1.0)
        Expanded(
          flex: 45,
          child: Container(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              child: LayoutBuilder(
                builder: (context, c) {
                  final contentW = math.max(200.0, math.min(440.0, c.maxWidth));
                  return Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentW,
                        child: formContent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.formContent});
  final Widget formContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: math.max(
                      200.0,
                      math.min(440.0, c.maxWidth - 48),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
                      child: formContent,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Shared form content
class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
    required this.isLoading,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback? onLogin;
  final bool isLoading;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small logo icon
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          Text(
            'Welcome back',
            style: GoogleFonts.poppins(
              fontSize: 31,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue to SkillBridge',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 28),

          // Email
          _PremiumTextField(
            controller: emailController,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 14),

          // Password with forgot link
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PremiumTextField(
                controller: passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffixIcon: obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onSuffixTap: onTogglePassword,
                validator: Validators.password,
                onFieldSubmitted: (_) => onLogin?.call(),
              ),
              TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Sign in button
          _PremiumButton(
            label: 'Sign in',
            isLoading: isLoading,
            onPressed: onLogin,
          ),

          const SizedBox(height: 18),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: GoogleFonts.inter(
                        color: AppColors.grey400, fontSize: 14)),
              ),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),

          const SizedBox(height: 18),

          // Google sign-in placeholder
          _SocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Continue with Google',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _SocialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onPressed: () {},
          ),

          const SizedBox(height: 24),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style:
                    GoogleFonts.inter(color: AppColors.grey500, fontSize: 15),
              ),
              _HoverSignUpLink(onTap: onRegister),
            ],
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Text(
              'By signing in you agree to our Terms of Service',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Premium text field with focus border glow
class _PremiumTextField extends StatefulWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.secondary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                color: AppColors.grey400,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: _isFocused ? AppColors.primary : AppColors.grey400,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(widget.suffixIcon,
                          size: 20, color: AppColors.grey400),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// Premium gradient button
class _PremiumButton extends StatefulWidget {
  const _PremiumButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return MouseRegion(
      onEnter: (_) {
        if (enabled) setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? null
                : const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF1F7A52),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.onPressed == null ? AppColors.grey300 : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _hover ? 0.45 : 0.3),
                      blurRadius: _hover ? 16 : 12,
                      offset: Offset(0, _hover ? 6 : 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _HoverSignUpLink extends StatefulWidget {
  const _HoverSignUpLink({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_HoverSignUpLink> createState() => _HoverSignUpLinkState();
}

class _HoverSignUpLinkState extends State<_HoverSignUpLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: _hover ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.primary,
          ),
          child: const Text('Sign up'),
        ),
      ),
    );
  }
}

// Social sign-in button
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppColors.secondary),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatCard2 extends StatelessWidget {
  const _StatCard2({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

