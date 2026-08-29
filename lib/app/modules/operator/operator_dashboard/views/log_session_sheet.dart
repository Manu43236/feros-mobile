import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/operator_dashboard_controller.dart';

/// Bottom sheet for starting or closing a machine session.
/// [sessionId] is null when starting a new session; non-null when closing an open one.
class LogSessionSheet extends StatefulWidget {
  final int? sessionId;
  final double? prefillStartHmr;

  const LogSessionSheet({super.key, this.sessionId, this.prefillStartHmr});

  @override
  State<LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends State<LogSessionSheet> {
  final _startHmrCtrl = TextEditingController();
  final _endHmrCtrl   = TextEditingController();
  final _fuelCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _submitting    = false;

  bool get _isClose => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    if (!_isClose && widget.prefillStartHmr != null) {
      _startHmrCtrl.text = widget.prefillStartHmr!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _startHmrCtrl.dispose();
    _endHmrCtrl.dispose();
    _fuelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ctrl = Get.find<OperatorDashboardController>();

    if (!_isClose && _startHmrCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Start HMR is required',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (_isClose && _endHmrCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'End HMR is required',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Validate numeric fields before hitting the API
    if (!_isClose) {
      final startHmr = double.tryParse(_startHmrCtrl.text.trim());
      if (startHmr == null) {
        Get.snackbar('Error', 'Enter a valid number for Start HMR',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    } else {
      final endHmr = double.tryParse(_endHmrCtrl.text.trim());
      if (endHmr == null) {
        Get.snackbar('Error', 'Enter a valid number for End HMR',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (_fuelCtrl.text.trim().isNotEmpty &&
          double.tryParse(_fuelCtrl.text.trim()) == null) {
        Get.snackbar('Error', 'Enter a valid number for Fuel Consumed',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    setState(() => _submitting = true);
    final bool success;
    if (_isClose) {
      success = await ctrl.closeSession(widget.sessionId!, {
        'endHmr': double.parse(_endHmrCtrl.text.trim()),
        if (_fuelCtrl.text.trim().isNotEmpty)
          'fuelConsumed': double.parse(_fuelCtrl.text.trim()),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
    } else {
      success = await ctrl.startSession({
        'startHmr': double.parse(_startHmrCtrl.text.trim()),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
    }
    setState(() => _submitting = false);
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isClose ? 'Close Session' : 'Start Session',
            style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 20),

          if (!_isClose) ...[
            _HmrField(label: 'Start HMR (hours)', ctrl: _startHmrCtrl),
            const SizedBox(height: 16),
          ] else ...[
            _HmrField(label: 'End HMR (hours)', ctrl: _endHmrCtrl),
            const SizedBox(height: 16),
            _HmrField(label: 'Fuel Consumed (litres)', ctrl: _fuelCtrl, required: false),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _notesCtrl,
            decoration: _inputDecor('Notes (optional)'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isClose ? AppColors.orange : AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isClose ? 'Close Session' : 'Start Session',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HmrField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool required;

  const _HmrField({required this.label, required this.ctrl, this.required = true});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
      decoration: _inputDecor(label),
    );
  }
}

InputDecoration _inputDecor(String label) => InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
    );
