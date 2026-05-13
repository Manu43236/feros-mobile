import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/pdf_viewer_view.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/delivery_sheet.dart';
import '../../../../core/widgets/odometer_sheet.dart';
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
  late double? _startOdometer;
  late double? _endOdometer;

  @override
  void initState() {
    super.initState();
    _lrStatus        = widget.lr.lrStatus;
    _loadedWeight    = widget.lr.loadedWeight;
    _deliveredWeight = widget.lr.deliveredWeight;
    _startOdometer   = widget.lr.startOdometer;
    _endOdometer     = widget.lr.endOdometer;
  }

  // ── Start Trip ──────────────────────────────────────────────────────────────
  Future<void> _startTrip() async {
    final result = await showOdometerSheet(
      context,
      title: 'Start Trip — Record ODM',
      hint: 'Start Odometer (km)',
      buttonLabel: 'Start Trip',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer before departure.\n'
          'Start ODM must be ≥ last recorded reading.',
    );
    if (result == null) return;

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(widget.lr.id), data: {
        'lrStatus': 'IN_TRANSIT',
        'startOdometer': result.odometer,
        if (result.photoUrl != null) 'startOdometerPhotoUrl': result.photoUrl,
      });
      setState(() {
        _lrStatus      = 'IN_TRANSIT';
        _startOdometer = result.odometer;
      });
      FerosSnackbar.success('Trip started');
    } catch (e) {
      FerosSnackbar.error(e.toString().contains('odometer')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to start trip');
    }
    setState(() => _isUpdating = false);
  }

  // ── Mark Delivered ──────────────────────────────────────────────────────────
  Future<void> _markDelivered() async {
    // Step 1: End ODM
    final odmResult = await showOdometerSheet(
      context,
      title: 'End Trip — Record ODM',
      hint: 'End Odometer (km)',
      buttonLabel: 'Next',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer on arrival.\n'
          'End ODM must be > ${_startOdometer?.toStringAsFixed(0) ?? 'start'} km.',
    );
    if (odmResult == null) return;

    // Step 2: Delivered weight
    final deliveryResult = await showDeliverySheet(
      context,
      endOdometer: odmResult.odometer,
      loadedWeight: _loadedWeight ?? widget.lr.allocatedWeight,
    );
    if (deliveryResult == null) return;

    setState(() => _isUpdating = true);
    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(widget.lr.id), data: {
        'lrStatus':       'DELIVERED',
        'deliveredWeight': deliveryResult.weight,
        'deliveredAt':     DateTime.now().toIso8601String(),
        'endOdometer':     odmResult.odometer,
        if (odmResult.photoUrl != null) 'endOdometerPhotoUrl': odmResult.photoUrl,
      });
      setState(() {
        _lrStatus        = 'DELIVERED';
        _deliveredWeight = deliveryResult.weight;
        _endOdometer     = odmResult.odometer;
      });
      FerosSnackbar.success('Delivery confirmed');
    } catch (e) {
      FerosSnackbar.error(e.toString().contains('odometer')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to confirm delivery');
    }
    setState(() => _isUpdating = false);
  }

  // ── View LR PDF ─────────────────────────────────────────────────────────────
  Future<void> _viewPdf() async {
    try {
      final api = Get.find<ApiClient>();
      final bytes = await api.getBytes(ApiEndpoints.lrPdf(widget.lr.id));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.lr.lrNumber}.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => PdfViewerView(
          file: file,
          title: '${widget.lr.fromCity} → ${widget.lr.toCity}',
          subtitle: widget.lr.lrNumber,
        ),
        transition: Transition.cupertino,
      );
    } catch (e) {
      FerosSnackbar.error('Failed to load PDF');
    }
  }

  Future<void> _showPdfBottomSheet() async {
    bool loading = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              const SizedBox(height: 20),
              // Icon + title
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined,
                        color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LR Document',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.lr.lrNumber,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'View and share the official lorry receipt document.',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              // Open button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          setSheetState(() => loading = true);
                          await _viewPdf();
                          setSheetState(() => loading = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.open_in_new, size: 18),
                  label: Text(loading ? 'Preparing PDF…' : 'Open LR PDF',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          '${widget.lr.fromCity} → ${widget.lr.toCity}',
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Card ─────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LR Status',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                _LrStatusBadge(status: _lrStatus),

                // Audit trail
                if (widget.lr.startedByName != null) ...[
                  const SizedBox(height: 10),
                  _AuditRow(
                    icon: Icons.play_circle_outline,
                    label: 'Started by',
                    name: widget.lr.startedByName!,
                    role: widget.lr.startedByRole,
                  ),
                ],
                if (widget.lr.completedByName != null) ...[
                  const SizedBox(height: 6),
                  _AuditRow(
                    icon: Icons.check_circle_outline,
                    label: 'Completed by',
                    name: widget.lr.completedByName!,
                    role: widget.lr.completedByRole,
                  ),
                ],

                if (_lrStatus == 'CREATED') ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                    message: 'Waiting for supervisor to record loading weight',
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
                          ? const SizedBox(
                              width: 18, height: 18,
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
                          ? const SizedBox(
                              width: 18, height: 18,
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

          // ── Trip Info ───────────────────────────────────────────
          _SectionCard(
            title: 'Trip Details',
            action: GestureDetector(
              onTap: _showPdfBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        size: 15, color: AppColors.navy),
                    const SizedBox(width: 5),
                    Text('LR PDF',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            child: Column(
              children: [
                InfoRow(label: 'Order',   value: widget.lr.orderNumber),
                InfoRow(label: 'Client',  value: widget.lr.clientName),
                InfoRow(label: 'From',    value: widget.lr.fromCity),
                InfoRow(label: 'To',      value: widget.lr.toCity),
                InfoRow(label: 'Vehicle', value: widget.lr.vehicleNumber),
                if (widget.lr.vehicleTypeName != null)
                  InfoRow(label: 'Type',  value: widget.lr.vehicleTypeName!),
                InfoRow(label: 'LR Date', value: widget.lr.lrDate),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Weight ──────────────────────────────────────────────
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
                  InfoRow(label: 'Delivered', value: '—', showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Odometer ────────────────────────────────────────────
          _SectionCard(
            title: 'Odometer',
            child: Column(
              children: [
                InfoRow(
                  label: 'Start ODM',
                  value: _startOdometer != null
                      ? '${_startOdometer!.toStringAsFixed(0)} km'
                      : '—',
                ),
                InfoRow(
                  label: 'End ODM',
                  value: _endOdometer != null
                      ? '${_endOdometer!.toStringAsFixed(0)} km'
                      : '—',
                  showDivider: false,
                ),
                if (_startOdometer != null && _endOdometer != null) ...[
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  InfoRow(
                    label: 'Distance',
                    value: '${(_endOdometer! - _startOdometer!).toStringAsFixed(0)} km',
                    showDivider: false,
                  ),
                ],
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
  final Widget? action;
  final Widget child;
  const _SectionCard({this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(title!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.navy)),
                ),
                ?action,
              ],
            ),
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

// ── Info Banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color, bg, border;
  final String message;
  const _InfoBanner(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.border,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

// ── LR Status Badge ───────────────────────────────────────────────────────────
class _LrStatusBadge extends StatelessWidget {
  final String status;
  const _LrStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status.toUpperCase()) {
      case 'CREATED':
        bg = const Color(0xFFEFF6FF); fg = AppColors.navy; label = 'LR Created'; break;
      case 'WEIGHT_LOADED':
        bg = const Color(0xFFF5F3FF); fg = const Color(0xFF7C3AED); label = 'Weight Loaded'; break;
      case 'IN_TRANSIT':
        bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706); label = 'In Transit'; break;
      case 'DELIVERED':
        bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A); label = 'Delivered'; break;
      case 'CANCELLED':
        bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626); label = 'Cancelled'; break;
      default:
        bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText; label = status; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.bodyMedium
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Audit Row ─────────────────────────────────────────────────────────────────
class _AuditRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final String? role;
  const _AuditRow({
    required this.icon,
    required this.label,
    required this.name,
    this.role,
  });

  String _roleLabel(String? r) {
    switch (r) {
      case 'DRIVER':  return 'Driver';
      case 'CLEANER': return 'Cleaner';
      default:        return r ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 6),
        Text('$label: ',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        Text(
          '$name${role != null ? ' (${_roleLabel(role)})' : ''}',
          style: AppTextStyles.caption.copyWith(
              color: AppColors.navy, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
