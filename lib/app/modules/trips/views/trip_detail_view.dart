import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
    final result = await _showOdometerSheet(
      title: 'Start Trip — Record ODM',
      hint: 'Start Odometer (km)',
      buttonLabel: 'Start Trip',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer before departure.\n'
          'Start ODM must be ≥ last recorded reading.',
      lastOdometer: null,
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
    final odmResult = await _showOdometerSheet(
      title: 'End Trip — Record ODM',
      hint: 'End Odometer (km)',
      buttonLabel: 'Next',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer on arrival.\n'
          'End ODM must be > ${_startOdometer?.toStringAsFixed(0) ?? 'start'} km.',
      lastOdometer: _startOdometer,
    );
    if (odmResult == null) return;

    // Step 2: Delivered weight + optional delivery photo
    final deliveryResult = await _showDeliverySheet(odmResult.odometer);
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

  // ── ODM Bottom Sheet ────────────────────────────────────────────────────────
  Future<_OdometerResult?> _showOdometerSheet({
    required String title,
    required String hint,
    required String buttonLabel,
    required Color buttonColor,
    required String instruction,
    double? lastOdometer,
  }) async {
    File? capturedImage;
    final odometerController = TextEditingController();
    bool isProcessing = false;

    return await showModalBottomSheet<_OdometerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(instruction,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),

              // Photo capture area
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (picked == null) return;

                  setSheetState(() {
                    capturedImage = File(picked.path);
                    isProcessing = true;
                  });

                  // Run OCR
                  try {
                    final inputImage = InputImage.fromFile(capturedImage!);
                    final recognizer = TextRecognizer();
                    final result = await recognizer.processImage(inputImage);
                    recognizer.close();

                    // Extract largest numeric sequence (odometer value)
                    final numbers = RegExp(r'\d{4,7}')
                        .allMatches(result.text)
                        .map((m) => int.parse(m.group(0)!))
                        .toList();
                    if (numbers.isNotEmpty) {
                      numbers.sort((a, b) => b.compareTo(a));
                      odometerController.text = numbers.first.toString();
                    }
                  } catch (_) {
                    // OCR failed — let user enter manually
                  }

                  setSheetState(() => isProcessing = false);
                },
                child: Container(
                  width: double.infinity,
                  height: capturedImage != null ? 160 : 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: capturedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(capturedImage!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover),
                            ),
                            if (isProcessing)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                      SizedBox(height: 8),
                                      Text('Reading ODM…',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(20)),
                                child: Text('Retake',
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                size: 28, color: AppColors.mutedText),
                            const SizedBox(height: 6),
                            Text('Tap to take ODM photo',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ODM text field
              TextField(
                controller: odometerController,
                keyboardType: TextInputType.number,
                autofocus: capturedImage == null,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: hint,
                  labelStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  suffixText: 'km',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  onPressed: () {
                    final val = double.tryParse(odometerController.text.trim());
                    if (val == null || val <= 0) {
                      FerosSnackbar.error('Enter a valid odometer reading');
                      return;
                    }
                    Navigator.of(ctx).pop(_OdometerResult(
                      odometer: val,
                      photoUrl: null, // S3 upload handled separately if needed
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(buttonLabel,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delivery Sheet (weight + optional photo) ────────────────────────────────
  Future<_DeliveryResult?> _showDeliverySheet(double endOdometer) async {
    final weightController = TextEditingController();

    return await showModalBottomSheet<_DeliveryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Confirm Delivery',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(
              'End ODM: ${endOdometer.toStringAsFixed(0)} km   •   '
              'Loaded: ${_loadedWeight?.toStringAsFixed(1) ?? widget.lr.allocatedWeight.toStringAsFixed(1)}T',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: 'Delivered Weight (T)',
                labelStyle:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                suffixText: 'T',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                onPressed: () {
                  final weight =
                      double.tryParse(weightController.text.trim());
                  if (weight == null || weight <= 0) {
                    FerosSnackbar.error('Enter a valid delivered weight');
                    return;
                  }
                  Navigator.of(ctx).pop(_DeliveryResult(weight: weight));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Confirm Delivery',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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
        title: Text(widget.lr.lrNumber,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
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

// ── Result Models ─────────────────────────────────────────────────────────────
class _OdometerResult {
  final double odometer;
  final String? photoUrl;
  _OdometerResult({required this.odometer, this.photoUrl});
}

class _DeliveryResult {
  final double weight;
  _DeliveryResult({required this.weight});
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
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
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
