import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  bool _isLoading = true;
  bool _isMarking = false;
  Map<String, dynamic>? _todayRecord;

  File? _selfie;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _fetchTodayStatus();
  }

  Future<void> _fetchTodayStatus() async {
    setState(() => _isLoading = true);
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiEndpoints.attendanceTodayStatus);
      final data = (res.data as Map<String, dynamic>)['data'];
      setState(() => _todayRecord = data as Map<String, dynamic>?);
    } catch (_) {
      setState(() => _todayRecord = null);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _selfie = File(picked.path));
  }

  Future<void> _captureLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _position = pos);
    } catch (_) {
      // GPS unavailable — optional, continue
    }
  }

  Future<void> _markAttendance() async {
    setState(() => _isMarking = true);

    // Try GPS (optional)
    await _captureLocation();

    try {
      final api = Get.find<ApiClient>();

      // Build request body
      final Map<String, dynamic> body = {};
      if (_position != null) {
        body['latitude'] = _position!.latitude;
        body['longitude'] = _position!.longitude;
      }
      // TODO: upload selfie to S3 and include selfieUrl if _selfie != null

      await api.post(ApiEndpoints.attendanceMarkPresent, data: body);
      FerosSnackbar.success('Attendance marked for today');
      await _fetchTodayStatus();
    } catch (e) {
      final msg = e.toString().contains('already marked')
          ? 'Already marked for today'
          : 'Failed to mark attendance';
      FerosSnackbar.error(msg);
    }

    setState(() => _isMarking = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().user;
    final today = DateTime.now();
    final dateStr =
        '${today.day} ${_monthName(today.month)} ${today.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Attendance',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTodayStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _fetchTodayStatus,
              color: AppColors.navy,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Date + User ──────────────────────────────────
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.navy,
                          child: Text(
                            _initials(user?.name ?? ''),
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? '—',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.navy)),
                            Text(dateStr,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Status ───────────────────────────────────────
                  if (_todayRecord != null) ...[
                    _MarkedCard(record: _todayRecord!),
                  ] else ...[
                    // ── Selfie preview ───────────────────────────
                    GestureDetector(
                      onTap: _takeSelfie,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _selfie != null
                            ? Stack(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(_selfie!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.navy,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Retake',
                                        style: AppTextStyles.caption
                                            .copyWith(color: Colors.white)),
                                  ),
                                ),
                              ])
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_front_outlined,
                                      size: 36, color: AppColors.mutedText),
                                  const SizedBox(height: 8),
                                  Text('Tap to take selfie (optional)',
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.mutedText)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── GPS status ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _position != null
                                ? Icons.location_on_outlined
                                : Icons.location_off_outlined,
                            size: 20,
                            color: _position != null
                                ? const Color(0xFF16A34A)
                                : AppColors.mutedText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _position != null
                                  ? 'Location: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                  : 'Location will be captured when you mark attendance (optional)',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Mark Present Button ──────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isMarking ? null : _markAttendance,
                        icon: _isMarking
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isMarking ? 'Marking…' : 'Mark Present',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
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
                ],
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Already Marked Card ───────────────────────────────────────────────────────
class _MarkedCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _MarkedCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final type = record['attendanceTypeName'] as String? ?? 'PRESENT';
    final status = record['approvalStatus'] as String? ?? 'PENDING';
    final markedAt = record['markedAt'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          Text('Attendance Marked',
              style: AppTextStyles.heading3
                  .copyWith(color: const Color(0xFF16A34A))),
          const SizedBox(height: 4),
          Text(type,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedText)),
          if (markedAt != null) ...[
            const SizedBox(height: 4),
            Text('at ${_formatTime(markedAt)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ],
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'APPROVED'
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status == 'APPROVED' ? 'Approved' : 'Pending Approval',
              style: AppTextStyles.caption.copyWith(
                color: status == 'APPROVED'
                    ? AppColors.navy
                    : const Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return iso;
    }
  }
}
