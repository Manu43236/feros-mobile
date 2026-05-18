import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/feros_pin_input.dart';

class ChangePinView extends StatefulWidget {
  const ChangePinView({super.key});

  @override
  State<ChangePinView> createState() => _ChangePinViewState();
}

class _ChangePinViewState extends State<ChangePinView> {
  final _api = Get.find<ApiClient>();

  String _currentPin = '';
  String _newPin     = '';
  String _confirmPin = '';
  bool   _loading    = false;

  bool get _canSubmit =>
      _currentPin.length == 4 &&
      _newPin.length == 4 &&
      _confirmPin.length == 4;

  Future<void> _submit() async {
    if (_newPin != _confirmPin) {
      FerosSnackbar.error('New PIN and confirm PIN do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.patch(ApiEndpoints.changePin, data: {
        'currentPin': _currentPin,
        'newPin':     _newPin,
      });
      FerosSnackbar.success('PIN changed successfully');
      Get.back();
    } catch (_) {
      FerosSnackbar.error('Failed to change PIN. Check your current PIN.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: const Text(
          'Change PIN',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PinField(
                  label: 'Current PIN',
                  onChanged: (v) => setState(() => _currentPin = v),
                ),
                const SizedBox(height: 24),
                _PinField(
                  label: 'New PIN',
                  onChanged: (v) => setState(() => _newPin = v),
                ),
                const SizedBox(height: 24),
                _PinField(
                  label: 'Confirm New PIN',
                  onChanged: (v) => setState(() => _confirmPin = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_canSubmit && !_loading) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Change PIN',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  const _PinField({required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        FerosPinInput(onCompleted: onChanged),
      ],
    );
  }
}
