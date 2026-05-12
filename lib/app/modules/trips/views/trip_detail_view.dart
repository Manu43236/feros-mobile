import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_dialog.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../core/widgets/info_row.dart';
import '../models/trip_model.dart';

class TripDetailView extends StatefulWidget {
  final TripModel trip;
  const TripDetailView({super.key, required this.trip});

  @override
  State<TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  bool _isUpdating = false;
  Map<String, dynamic>? _lrData;
  bool _loadingLr = true;

  @override
  void initState() {
    super.initState();
    _fetchLrDetail();
  }

  Future<void> _fetchLrDetail() async {
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiEndpoints.lrsByOrder(widget.trip.id));
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List?)?.cast<Map<String, dynamic>>();
      if (list != null && list.isNotEmpty) {
        final active = list.firstWhere(
          (lr) => lr['lrStatus'] != 'CANCELLED',
          orElse: () => list.last,
        );
        setState(() => _lrData = active);
      }
    } catch (_) {}
    setState(() => _loadingLr = false);
  }

  Future<void> _startTrip() async {
    final confirmed = await FerosDialog.confirm(
      title: 'Start Trip',
      message: 'Mark this LR as In Transit?',
      confirmText: 'Start Trip',
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(
        ApiEndpoints.lrById(_lrData!['id']),
        data: {'lrStatus': 'IN_TRANSIT'},
      );
      setState(() => _lrData = {..._lrData!, 'lrStatus': 'IN_TRANSIT'});
      FerosSnackbar.success('Trip started');
    } catch (_) {
      FerosSnackbar.error('Failed to start trip');
    }
    setState(() => _isUpdating = false);
  }

  Future<void> _markDelivered() async {
    final weightController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark Delivered', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('Enter the delivered weight to confirm delivery.',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: 'Delivered Weight (T)',
                labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                suffixText: 'T',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Confirm Delivery',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;

    if (!confirmed) return;

    final weightText = weightController.text.trim();
    if (weightText.isEmpty) {
      FerosSnackbar.error('Please enter delivered weight');
      return;
    }
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      FerosSnackbar.error('Invalid weight');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(
        ApiEndpoints.lrById(_lrData!['id']),
        data: {
          'lrStatus': 'DELIVERED',
          'deliveredWeight': weight,
          'deliveredAt': DateTime.now().toIso8601String(),
        },
      );
      setState(() => _lrData = {..._lrData!, 'lrStatus': 'DELIVERED', 'deliveredWeight': weight});
      FerosSnackbar.success('Delivery confirmed');
    } catch (_) {
      FerosSnackbar.error('Failed to confirm delivery');
    }
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final lrStatus = _lrData?['lrStatus'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          widget.trip.orderNumber,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Card ──────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LR Status',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                if (_loadingLr)
                  const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                  )
                else
                  _LrStatusBadge(status: lrStatus ?? 'NO_LR'),
                if (!_loadingLr && lrStatus == 'CREATED') ...[
                  const SizedBox(height: 12),
                  if (_lrData?['loadedWeight'] == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting for supervisor to load weight',
                              style: AppTextStyles.caption.copyWith(color: const Color(0xFFD97706)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _startTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isUpdating
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Start Trip',
                                style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
                if (!_loadingLr && lrStatus == 'IN_TRANSIT') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _markDelivered,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUpdating
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Mark Delivered',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Trip Info ────────────────────────────────────────
          _SectionCard(
            title: 'Trip Details',
            child: Column(
              children: [
                InfoRow(label: 'Client', value: widget.trip.clientName),
                InfoRow(label: 'From', value: widget.trip.fromLocation),
                InfoRow(label: 'To', value: widget.trip.toLocation),
                if (widget.trip.scheduledDate != null)
                  InfoRow(label: 'Date', value: FerosDateUtils.formatDate(widget.trip.scheduledDate!)),
                if (widget.trip.vehicleNumber != null)
                  InfoRow(label: 'Vehicle', value: widget.trip.vehicleNumber!),
                if (widget.trip.weight != null)
                  InfoRow(label: 'Weight', value: FerosNumberUtils.formatWeight(widget.trip.weight!)),
                if (widget.trip.materialType != null)
                  InfoRow(label: 'Material', value: widget.trip.materialType!, showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── LR Details ───────────────────────────────────────
          _SectionCard(
            title: 'LR Details',
            child: _loadingLr
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2),
                    ),
                  )
                : _lrData == null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('No LR found for this trip',
                            style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                      )
                    : Column(
                        children: [
                          InfoRow(label: 'LR Number', value: _lrData!['lrNumber']?.toString() ?? '—'),
                          InfoRow(label: 'Vehicle', value: _lrData!['vehicleRegistrationNumber']?.toString() ?? '—'),
                          if (_lrData!['loadedWeight'] != null)
                            InfoRow(label: 'Loaded', value: FerosNumberUtils.formatWeight(
                                (_lrData!['loadedWeight'] as num).toDouble())),
                          if (_lrData!['deliveredWeight'] != null)
                            InfoRow(label: 'Delivered', value: FerosNumberUtils.formatWeight(
                                (_lrData!['deliveredWeight'] as num).toDouble())),
                          InfoRow(label: 'LR Date', value: _lrData!['lrDate']?.toString() ?? '—', showDivider: false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class _LrStatusBadge extends StatelessWidget {
  final String status;
  const _LrStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status.toUpperCase()) {
      case 'CREATED':     bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706);     label = 'LR Created';  break;
      case 'IN_TRANSIT':  bg = const Color(0xFFEFF6FF); fg = AppColors.navy;              label = 'In Transit';  break;
      case 'DELIVERED':   bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);     label = 'Delivered';   break;
      case 'CANCELLED':   bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626);     label = 'Cancelled';   break;
      case 'NO_LR':       bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText;         label = 'No LR Yet';   break;
      default:            bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText;         label = status;        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
