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
  late String _currentStatus;
  Map<String, dynamic>? _lrData;
  bool _loadingLr = true;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.trip.status;
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

  Future<void> _updateStatus(String newStatus) async {
    final confirmed = await FerosDialog.confirm(
      title: 'Update Status',
      message: 'Mark this trip as $newStatus?',
      confirmText: 'Yes, Update',
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.patch(
        ApiEndpoints.orderStatus(widget.trip.id),
        queryParameters: {'status': newStatus},
      );
      setState(() => _currentStatus = newStatus);
      FerosSnackbar.success('Status updated to $newStatus');
    } catch (_) {
      FerosSnackbar.error('Failed to update status');
    }
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Current Status',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                _StatusBadge(status: _currentStatus),
                if (_currentStatus == 'IN_TRANSIT') ...[
                  const SizedBox(height: 12),
                  _isUpdating
                      ? const Center(child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                        ))
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _updateStatus('DELIVERED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Mark Delivered', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                ],
                if (_currentStatus == 'PENDING') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _updateStatus('IN_TRANSIT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Start Trip', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
                          InfoRow(label: 'Client', value: _lrData!['clientName']?.toString() ?? '—'),
                          InfoRow(label: 'Vehicle', value: _lrData!['vehicleRegistrationNumber']?.toString() ?? '—'),
                          InfoRow(label: 'LR Status', value: _lrData!['lrStatus']?.toString() ?? '—', showDivider: false),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status.toUpperCase()) {
      case 'IN_TRANSIT':  bg = const Color(0xFFEFF6FF); fg = AppColors.navy;              label = 'In Transit'; break;
      case 'DELIVERED':   bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);     label = 'Delivered';  break;
      case 'PENDING':     bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706);     label = 'Pending';    break;
      case 'CANCELLED':   bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626);     label = 'Cancelled';  break;
      default:            bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText;         label = status;       break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
