import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Call this from anywhere to show the Mark Attendance bottom sheet.
/// [onMarked] is called after a successful mark so the caller can refresh.
Future<void> showMarkAttendanceSheet(
  BuildContext context, {
  VoidCallback? onMarked,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MarkAttendanceSheet(onMarked: onMarked),
  );
}

class _MarkAttendanceSheet extends StatefulWidget {
  final VoidCallback? onMarked;
  const _MarkAttendanceSheet({this.onMarked});

  @override
  State<_MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  Position? _position;
  bool _gettingLocation = false;
  bool _marking = false;
  File? _selfie;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _gettingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _position = pos);
    } catch (_) {
      // GPS unavailable — continue without
    }
    setState(() => _gettingLocation = false);
  }

  Future<void> _takeSelfie() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile != null && mounted) {
      setState(() => _selfie = File(xFile.path));
    }
  }

  Future<void> _mark() async {
    setState(() => _marking = true);
    try {
      String? selfieUrl;
      if (_selfie != null) {
        selfieUrl = await Get.find<UploadService>()
            .uploadFile(_selfie!, folder: 'attendance');
      }

      final api = Get.find<ApiClient>();
      await api.post(ApiEndpoints.attendanceMarkPresent, data: {
        if (_position != null) 'latitude': _position!.latitude,
        if (_position != null) 'longitude': _position!.longitude,
        'selfieUrl': selfieUrl,
      });
      FerosSnackbar.success('Attendance marked for today');
      if (mounted) Navigator.of(context).pop();
      widget.onMarked?.call();
    } catch (_) {
      FerosSnackbar.error('Failed to mark attendance');
    }
    if (mounted) setState(() => _marking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text('Mark Today\'s Attendance',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(
            _today(),
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),

          // GPS status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  _position != null
                      ? Icons.location_on_outlined
                      : Icons.location_searching_outlined,
                  size: 18,
                  color: _position != null
                      ? const Color(0xFF16A34A)
                      : AppColors.mutedText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gettingLocation
                        ? 'Fetching your location…'
                        : _position != null
                            ? 'Location captured successfully'
                            : 'Location not available — attendance will still be marked',
                    style: AppTextStyles.caption.copyWith(
                      color: _position != null
                          ? const Color(0xFF16A34A)
                          : AppColors.mutedText,
                    ),
                  ),
                ),
                if (_gettingLocation)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.mutedText),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selfie (optional)
          GestureDetector(
            onTap: _marking ? null : _takeSelfie,
            child: _selfie == null
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_front_outlined,
                            size: 20, color: AppColors.mutedText),
                        const SizedBox(width: 8),
                        Text('Take Selfie (Optional)',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.file(
                            _selfie!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _marking
                              ? null
                              : () => setState(() => _selfie = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _marking ? null : _takeSelfie,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Retake',
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Mark button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _marking ? null : _mark,
              icon: _marking
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _marking ? 'Marking…' : 'Mark Present',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
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

  String _today() {
    final d = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday'
    ];
    return '${days[d.weekday]}, ${d.day} ${months[d.month]} ${d.year}';
  }
}
