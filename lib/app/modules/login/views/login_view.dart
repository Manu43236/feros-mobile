import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _ctrl;

  final _phoneCtrl    = TextEditingController();
  final _pinCtrls     = List.generate(4, (_) => TextEditingController());
  final _pinNodes     = List.generate(4, (_) => FocusNode());

  String get _pin => _pinCtrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<LoginController>();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _pinCtrls)  c.dispose();
    for (final f in _pinNodes)  f.dispose();
    super.dispose();
  }

  void _onPinDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) _pinNodes[index + 1].requestFocus();
    if (value.isEmpty   && index > 0)  _pinNodes[index - 1].requestFocus();
    _ctrl.pinError.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Top: navy bg + logo ──────────────────────────────────
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
                    Text('Welcome Back',
                        style: AppTextStyles.heading2.copyWith(color: AppColors.navy)),
                    const SizedBox(height: 4),
                    Text('Sign in to your account',
                        style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                    const SizedBox(height: 28),

                    // ── Phone Number ─────────────────────────────
                    Text('Phone Number',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.navy, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Obx(() => _PhoneField(
                          controller: _phoneCtrl,
                          error: _ctrl.phoneError.value,
                          onChanged: (_) => _ctrl.phoneError.value = null,
                        )),
                    const SizedBox(height: 20),

                    // ── PIN ──────────────────────────────────────
                    Text('PIN',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.navy, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Obx(() => _PinRow(
                          controllers: _pinCtrls,
                          focusNodes: _pinNodes,
                          error: _ctrl.pinError.value,
                          onChanged: _onPinDigitEntered,
                        )),
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
                        child: Text('Forgot PIN?',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.mutedText)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Login Button ─────────────────────────────
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _ctrl.isLoading.value
                                ? null
                                : () => _ctrl.login(
                                      phone: _phoneCtrl.text.trim(),
                                      pin: _pin,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.navy.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _ctrl.isLoading.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Login',
                                    style: AppTextStyles.buttonText),
                          ),
                        )),
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
    );
  }

  void _showForgotPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_outlined, color: AppColors.navy, size: 22),
            const SizedBox(width: 8),
            Text('Forgot PIN?', style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
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
            child: Text('Got it', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
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
        child: Text(text,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      );

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text('·',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      );
}

// ── Phone Field ──────────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final void Function(String) onChanged;

  const _PhoneField({
    required this.controller,
    required this.error,
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
              color: error != null
                  ? AppColors.error
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // +91 prefix
              Container(
                width: 56,
                alignment: Alignment.center,
                child: Text('+91',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy)),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.body.copyWith(color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    hintStyle:
                        AppTextStyles.hint.copyWith(color: const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
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
  final void Function(int index, String value) onChanged;

  const _PinRow({
    required this.controllers,
    required this.focusNodes,
    required this.error,
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
                  onChanged: (v) => onChanged(i, v),
                ),
              ),
            );
          }),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final void Function(String) onChanged;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
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
