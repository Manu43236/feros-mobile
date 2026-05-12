import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BreakdownView extends StatefulWidget {
  const BreakdownView({super.key});

  @override
  State<BreakdownView> createState() => _BreakdownViewState();
}

class _BreakdownViewState extends State<BreakdownView> {
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _breakdownType = 'MECHANICAL';
  String _breakdownDuration = 'SHORT';
  Position? _position;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  static const _types = ['MECHANICAL', 'ELECTRICAL', 'TYRE', 'ACCIDENT', 'OTHER'];
  static const _durations = ['SHORT', 'LONG'];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        FerosSnackbar.error('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _position = pos);
      FerosSnackbar.success('Location captured');
    } catch (_) {
      FerosSnackbar.error('Could not get location');
    }
    setState(() => _isGettingLocation = false);
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      FerosSnackbar.error('Please describe the breakdown reason');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = Get.find<ApiClient>();
      await api.post(ApiEndpoints.myBreakdown, data: {
        'breakdownType': _breakdownType,
        'breakdownDuration': _breakdownDuration,
        'breakdownDate': DateTime.now().toIso8601String(),
        'reason': _reasonCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        if (_position != null)
          'location':
              '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
      });
      FerosSnackbar.success('Breakdown reported');
      _reasonCtrl.clear();
      _notesCtrl.clear();
      setState(() => _position = null);
    } catch (_) {
      FerosSnackbar.error('Failed to report breakdown');
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Report Breakdown',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Alert Banner ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your supervisor will be notified immediately upon submission.',
                    style: AppTextStyles.caption
                        .copyWith(color: const Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Form Card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breakdown Type
                Text('Breakdown Type',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final selected = _breakdownType == t;
                    return GestureDetector(
                      onTap: () => setState(() => _breakdownType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.navy
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.replaceAll('_', ' '),
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.mutedText,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Duration
                Text('Expected Duration',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Row(
                  children: _durations.map((d) {
                    final selected = _breakdownDuration == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _breakdownDuration = d),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: d == 'SHORT' ? 8 : 0),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.navy
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              d == 'SHORT'
                                  ? 'Short (< 2 hrs)'
                                  : 'Long (> 2 hrs)',
                              style: AppTextStyles.caption.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.mutedText,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Reason
                Text('Reason *',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened…',
                    hintStyle: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.navy),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                Text('Additional Notes',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Optional…',
                    hintStyle: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.navy),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                GestureDetector(
                  onTap: _isGettingLocation ? null : _getLocation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _position != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _position != null
                            ? const Color(0xFFBBF7D0)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _position != null
                              ? Icons.location_on_outlined
                              : Icons.my_location_outlined,
                          size: 20,
                          color: _position != null
                              ? const Color(0xFF16A34A)
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isGettingLocation
                                ? 'Getting location…'
                                : _position != null
                                    ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                    : 'Tap to capture current location (optional)',
                            style: AppTextStyles.caption.copyWith(
                              color: _position != null
                                  ? const Color(0xFF16A34A)
                                  : AppColors.mutedText,
                            ),
                          ),
                        ),
                        if (_isGettingLocation)
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.mutedText),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.report_problem_outlined, size: 20),
              label: Text(
                _isSubmitting ? 'Submitting…' : 'Report Breakdown',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
