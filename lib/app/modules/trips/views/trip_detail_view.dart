import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_dialog.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/info_row.dart';
import '../models/lr_model.dart';

class TripDetailView extends StatefulWidget {
  final LrModel lr;
  const TripDetailView({super.key, required this.lr});

  @override
  State<TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  bool _isUpdating = false;
  late String _lrStatus;
  late double? _loadedWeight;
  late double? _deliveredWeight;

  @override
  void initState() {
    super.initState();
    _lrStatus       = widget.lr.lrStatus;
    _loadedWeight   = widget.lr.loadedWeight;
    _deliveredWeight = widget.lr.deliveredWeight;
  }

  Future<void> _startTrip() async {
    final confirmed = await FerosDialog.confirm(
      title: 'Start Trip',
      message: 'Confirm you are starting the trip for LR ${widget.lr.lrNumber}?',
      confirmText: 'Start Trip',
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(widget.lr.id), data: {'lrStatus': 'IN_TRANSIT'});
      setState(() => _lrStatus = 'IN_TRANSIT');
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
            Text('Mark Delivered',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('Loaded: ${_loadedWeight?.toStringAsFixed(1) ?? widget.lr.allocatedWeight.toStringAsFixed(1)}T — enter actual delivered weight.',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
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
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;

    if (!confirmed) return;

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0) {
      FerosSnackbar.error('Please enter a valid delivered weight');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(widget.lr.id), data: {
        'lrStatus':       'DELIVERED',
        'deliveredWeight': weight,
        'deliveredAt':     DateTime.now().toIso8601String(),
      });
      setState(() {
        _lrStatus        = 'DELIVERED';
        _deliveredWeight = weight;
      });
      FerosSnackbar.success('Delivery confirmed');
    } catch (_) {
      FerosSnackbar.error('Failed to confirm delivery');
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
        title: Text(widget.lr.lrNumber,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Card ───────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LR Status',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                _LrStatusBadge(status: _lrStatus),

                if (_lrStatus == 'CREATED') ...[
                  const SizedBox(height: 12),
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
                        const Icon(Icons.hourglass_top_rounded, size: 16,
                            color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waiting for supervisor to record loading weight',
                            style: AppTextStyles.caption
                                .copyWith(color: const Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_lrStatus == 'WEIGHT_LOADED') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _startTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUpdating
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Start Trip',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],

                if (_lrStatus == 'IN_TRANSIT') ...[
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUpdating
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Mark Delivered',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Trip Info ─────────────────────────────────────────
          _SectionCard(
            title: 'Trip Details',
            child: Column(
              children: [
                InfoRow(label: 'Order', value: widget.lr.orderNumber),
                InfoRow(label: 'Client', value: widget.lr.clientName),
                InfoRow(label: 'From', value: widget.lr.fromCity),
                InfoRow(label: 'To', value: widget.lr.toCity),
                InfoRow(label: 'Vehicle', value: widget.lr.vehicleNumber),
                if (widget.lr.vehicleTypeName != null)
                  InfoRow(label: 'Type', value: widget.lr.vehicleTypeName!),
                InfoRow(label: 'LR Date', value: widget.lr.lrDate),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Weight Info ───────────────────────────────────────
          _SectionCard(
            title: 'Weight',
            child: Column(
              children: [
                InfoRow(
                  label: 'Allocated',
                  value: '${widget.lr.allocatedWeight.toStringAsFixed(1)} T',
                ),
                if (_loadedWeight != null)
                  InfoRow(
                    label: 'Loaded',
                    value: '${_loadedWeight!.toStringAsFixed(1)} T',
                  ),
                if (_deliveredWeight != null)
                  InfoRow(
                    label: 'Delivered',
                    value: '${_deliveredWeight!.toStringAsFixed(1)} T',
                    showDivider: false,
                  )
                else
                  InfoRow(
                    label: 'Delivered',
                    value: '—',
                    showDivider: false,
                  ),
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
      case 'CREATED':        bg = const Color(0xFFEFF6FF); fg = AppColors.navy;              label = 'LR Created';     break;
      case 'WEIGHT_LOADED':  bg = const Color(0xFFF5F3FF); fg = const Color(0xFF7C3AED);     label = 'Weight Loaded';  break;
      case 'IN_TRANSIT':     bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706);     label = 'In Transit';     break;
      case 'DELIVERED':      bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);     label = 'Delivered';      break;
      case 'CANCELLED':      bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626);     label = 'Cancelled';      break;
      default:               bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText;         label = status;           break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(
              color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
