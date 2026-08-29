import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: const _SplitBg()),
          Column(
        children: [
          // ── Top: split bg + logo ──────────────────────────────────
          Expanded(
            flex: 38,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.62,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Bottom: white card ───────────────────────────────────
          Expanded(
            flex: 62,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to your account',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Lockout Banner ───────────────────────────
                    Obx(() {
                      if (!controller.isLocked) return const SizedBox.shrink();
                      return _LockoutBanner(
                        secondsLeft: controller.secondsLeft.value,
                        isAskingAdmin: controller.isAskingAdmin.value,
                        onAskAdmin: controller.askPinReset,
                      );
                    }),

                    // ── Attempts Warning ─────────────────────────
                    Obx(() {
                      final n = controller.attemptsUsed.value;
                      if (n < 3 || controller.isLocked) return const SizedBox.shrink();
                      final remaining = 5 - n;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$n/5',
                              style: AppTextStyles.heading3.copyWith(
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incorrect PIN',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$remaining attempt${remaining != 1 ? 's' : ''} left before lockout',
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // ── Phone Number ─────────────────────────────
                    Text(
                      'Phone Number',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => _PhoneField(
                        controller: controller.phoneController,
                        error: controller.phoneError.value,
                        enabled: !controller.isLocked,
                        onChanged: controller.onPhoneChanged,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── PIN ──────────────────────────────────────
                    Text(
                      'PIN',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => _PinRow(
                        controllers: controller.pinControllers,
                        focusNodes: controller.pinFocusNodes,
                        error: controller.pinError.value,
                        enabled: !controller.isLocked,
                        onChanged: controller.onPinDigitEntered,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Forgot PIN ───────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPinDialog(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot PIN?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Login Button ─────────────────────────────
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              (controller.isLoading.value || controller.isLocked)
                              ? null
                              : controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.navy.withValues(
                              alpha: 0.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Login', style: AppTextStyles.buttonText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Footer links ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _footerLink('Support'),
                        _dot(),
                        _footerLink('Terms of Service'),
                        _dot(),
                        _footerLink('Privacy Policy'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  void _showForgotPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.lock_reset_outlined,
              color: AppColors.navy,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Forgot PIN?',
              style: AppTextStyles.heading4.copyWith(color: AppColors.navy),
            ),
          ],
        ),
        content: Text(
          'PIN reset is managed by your Admin.\n\nPlease contact your company Admin to get a new PIN assigned to your account.',
          style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
            child: Text(
              'Got it',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) => TextButton(
    onPressed: () {},
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
    ),
  );

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      '·',
      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
    ),
  );
}

// ── Phone Field ──────────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool enabled;
  final void Function(String) onChanged;

  const _PhoneField({
    required this.controller,
    required this.error,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? AppColors.error : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // +91 prefix
              Container(
                width: 56,
                alignment: Alignment.center,
                child: Text(
                  '+91',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.body.copyWith(color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    hintStyle: AppTextStyles.hint.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

// ── PIN Row ───────────────────────────────────────────────────────────────────
class _PinRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String? error;
  final bool enabled;
  final void Function(int index, String value) onChanged;

  const _PinRow({
    required this.controllers,
    required this.focusNodes,
    required this.error,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                child: _PinBox(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  hasError: error != null,
                  enabled: enabled,
                  onChanged: (v) => onChanged(i, v),
                ),
              ),
            );
          }),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

// ── Lockout Banner ────────────────────────────────────────────────────────────
class _LockoutBanner extends StatelessWidget {
  final int secondsLeft;
  final bool isAskingAdmin;
  final VoidCallback onAskAdmin;

  const _LockoutBanner({
    required this.secondsLeft,
    required this.isAskingAdmin,
    required this.onAskAdmin,
  });

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Account temporarily locked',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFB91C1C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Too many incorrect PIN attempts. Try again in',
            style: AppTextStyles.caption.copyWith(color: const Color(0xFFEF4444)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatCountdown(secondsLeft),
            style: AppTextStyles.heading2.copyWith(
              color: const Color(0xFFDC2626),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or ask your admin to reset your PIN',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: isAskingAdmin ? null : onAskAdmin,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isAskingAdmin ? 'Sending request…' : 'Ask admin to reset PIN',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFDC2626),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool enabled;
  final void Function(String) onChanged;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? AppColors.error : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        obscureText: true,
        obscuringCharacter: '●',
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}

class _SplitBg extends StatelessWidget {
  const _SplitBg();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sidebarBg, AppColors.equipSidebar],
        ),
      ),
    );
  }
}
