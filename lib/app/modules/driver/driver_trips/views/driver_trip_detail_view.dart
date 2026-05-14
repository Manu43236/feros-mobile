import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/info_row.dart';
import '../../../../../core/widgets/delivery_sheet.dart';
import '../../../../../core/widgets/odometer_sheet.dart';
import '../controllers/driver_trip_detail_controller.dart';

class DriverTripDetailView extends GetView<DriverTripDetailController> {
  const DriverTripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          title: Text(
            '${controller.lr.fromCity} → ${controller.lr.toCity}',
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: Get.back,
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
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                  const SizedBox(height: 8),
                  _LrStatusBadge(status: controller.lrStatus.value),

                  if (controller.lr.startedByName != null) ...[
                    const SizedBox(height: 10),
                    _AuditRow(
                      icon: Icons.play_circle_outline,
                      label: 'Started by',
                      name: controller.lr.startedByName!,
                      role: controller.lr.startedByRole,
                    ),
                  ],
                  if (controller.lr.completedByName != null) ...[
                    const SizedBox(height: 6),
                    _AuditRow(
                      icon: Icons.check_circle_outline,
                      label: 'Completed by',
                      name: controller.lr.completedByName!,
                      role: controller.lr.completedByRole,
                    ),
                  ],

                  if (controller.lrStatus.value == 'CREATED') ...[
                    const SizedBox(height: 12),
                    _InfoBanner(
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                      border: const Color(0xFFFDE68A),
                      message:
                          'Waiting for supervisor to record loading weight',
                    ),
                  ],

                  if (controller.lrStatus.value == 'WEIGHT_LOADED') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isUpdating.value
                            ? null
                            : () => _onStartTrip(context, controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isUpdating.value
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

                  if (controller.lrStatus.value == 'IN_TRANSIT') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isUpdating.value
                            ? null
                            : () => _onMarkDelivered(context, controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isUpdating.value
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

            // ── Trip Info ─────────────────────────────────────────
            _SectionCard(
              title: 'Trip Details',
              action: GestureDetector(
                onTap: controller.viewPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isPdfLoading.value)
                        const SizedBox(
                          width: 13, height: 13,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.navy),
                        )
                      else
                        const Icon(Icons.picture_as_pdf_outlined,
                            size: 15, color: AppColors.navy),
                      const SizedBox(width: 5),
                      Text(
                        controller.isPdfLoading.value ? 'Loading…' : 'LR PDF',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              child: Column(
                children: [
                  InfoRow(label: 'Order',   value: controller.lr.orderNumber),
                  InfoRow(label: 'Client',  value: controller.lr.clientName),
                  InfoRow(label: 'From',    value: controller.lr.fromCity),
                  InfoRow(label: 'To',      value: controller.lr.toCity),
                  InfoRow(label: 'Vehicle', value: controller.lr.vehicleNumber),
                  if (controller.lr.vehicleTypeName != null)
                    InfoRow(label: 'Type',  value: controller.lr.vehicleTypeName!),
                  InfoRow(label: 'LR Date', value: controller.lr.lrDate),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Weight ────────────────────────────────────────────
            _SectionCard(
              title: 'Weight',
              child: Column(
                children: [
                  InfoRow(
                    label: 'Allocated',
                    value:
                        '${controller.lr.allocatedWeight.toStringAsFixed(1)} T',
                  ),
                  if (controller.loadedWeight.value != null)
                    InfoRow(
                      label: 'Loaded',
                      value:
                          '${controller.loadedWeight.value!.toStringAsFixed(1)} T',
                    ),
                  controller.deliveredWeight.value != null
                      ? InfoRow(
                          label: 'Delivered',
                          value:
                              '${controller.deliveredWeight.value!.toStringAsFixed(1)} T',
                          showDivider: false,
                        )
                      : const InfoRow(
                          label: 'Delivered',
                          value: '—',
                          showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Odometer ──────────────────────────────────────────
            _SectionCard(
              title: 'Odometer',
              child: Column(
                children: [
                  InfoRow(
                    label: 'Start ODM',
                    value: controller.startOdometer.value != null
                        ? '${controller.startOdometer.value!.toStringAsFixed(0)} km'
                        : '—',
                  ),
                  InfoRow(
                    label: 'End ODM',
                    value: controller.endOdometer.value != null
                        ? '${controller.endOdometer.value!.toStringAsFixed(0)} km'
                        : '—',
                    showDivider: false,
                  ),
                  if (controller.startOdometer.value != null &&
                      controller.endOdometer.value != null) ...[
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    InfoRow(
                      label: 'Distance',
                      value:
                          '${(controller.endOdometer.value! - controller.startOdometer.value!).toStringAsFixed(0)} km',
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    ));
  }

  // Sheets stay in the view (need BuildContext); results passed to controller.
  Future<void> _onStartTrip(
      BuildContext context, DriverTripDetailController controller) async {
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
    controller.startTrip(result);
  }

  Future<void> _onMarkDelivered(
      BuildContext context, DriverTripDetailController controller) async {
    final odmResult = await showOdometerSheet(
      context,
      title: 'End Trip — Record ODM',
      hint: 'End Odometer (km)',
      buttonLabel: 'Next',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer on arrival.\n'
          'End ODM must be > ${controller.startOdometer.value?.toStringAsFixed(0) ?? 'start'} km.',
    );
    if (odmResult == null) return;

    final deliveryResult = await showDeliverySheet(
      context,
      endOdometer: odmResult.odometer,
      loadedWeight:
          controller.loadedWeight.value ?? controller.lr.allocatedWeight,
    );
    if (deliveryResult == null) return;
    controller.markDelivered(odmResult, deliveryResult);
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
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
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
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.message,
  });

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
