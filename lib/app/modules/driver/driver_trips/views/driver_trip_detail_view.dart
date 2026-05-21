import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/info_row.dart';
import '../../../../../core/widgets/delivery_sheet.dart';
import '../../../../../core/widgets/odometer_sheet.dart';
import '../controllers/driver_trip_detail_controller.dart';
import '../../driver_breakdown/views/driver_breakdown_view.dart';
import '../../driver_breakdown/bindings/driver_breakdown_binding.dart';

class DriverTripDetailView extends GetView<DriverTripDetailController> {
  const DriverTripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
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
              fontSize: 15,
            ),
          ),
          leading: GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.navy,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status Card ───────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lbl_lr_status'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LrStatusBadge(status: controller.lrStatus.value),

                  if (controller.lr.startedByName != null) ...[
                    const SizedBox(height: 10),
                    _AuditRow(
                      icon: Icons.play_circle_outline,
                      label: 'lbl_started_by'.tr,
                      name: controller.lr.startedByName!,
                      role: controller.lr.startedByRole,
                    ),
                  ],
                  if (controller.lr.completedByName != null) ...[
                    const SizedBox(height: 6),
                    _AuditRow(
                      icon: Icons.check_circle_outline,
                      label: 'lbl_completed_by'.tr,
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
                      message: 'lbl_waiting_weight'.tr,
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isUpdating.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'btn_start_trip'.tr,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  if (controller.lrStatus.value == 'IN_TRANSIT') ...[
                    const SizedBox(height: 12),
                    if (controller.hasActiveBreakdown.value) ...[
                      // ── Breakdown active banner ───────────────────
                      GestureDetector(
                        onTap: controller.isCheckingBreakdown.value
                            ? null
                            : controller.checkBreakdown,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'lbl_breakdown_reported_waiting'.tr,
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'lbl_tap_to_refresh'.tr,
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFFDC2626)
                                            .withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              controller.isCheckingBreakdown.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFDC2626),
                                      ),
                                    )
                                  : const Icon(Icons.refresh,
                                      color: Color(0xFFDC2626), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // ── Mark Delivered ───────────────────────────
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: controller.isUpdating.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'btn_mark_delivered'.tr,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── Report Breakdown ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _onReportBreakdown(context, controller),
                          icon: const Icon(Icons.warning_amber_outlined,
                              size: 18, color: Color(0xFFDC2626)),
                          label: Text(
                            'btn_report_breakdown'.tr,
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Trip Info ─────────────────────────────────────────
            _SectionCard(
              title: 'lbl_trip_details'.tr,
              action: GestureDetector(
                onTap: controller.viewPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isPdfLoading.value)
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      else
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 15,
                          color: AppColors.navy,
                        ),
                      const SizedBox(width: 5),
                      Text(
                        controller.isPdfLoading.value ? 'lbl_loading_pdf'.tr : 'lbl_lr_pdf'.tr,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Column(
                children: [
                  InfoRow(label: 'lbl_order'.tr, value: controller.lr.orderNumber),
                  InfoRow(label: 'lbl_client'.tr, value: controller.lr.clientName),
                  InfoRow(label: 'lbl_from'.tr, value: controller.lr.fromCity),
                  InfoRow(label: 'lbl_to_label'.tr, value: controller.lr.toCity),
                  InfoRow(label: 'lbl_vehicle_label'.tr, value: controller.lr.vehicleNumber),
                  if (controller.lr.vehicleTypeName != null)
                    InfoRow(
                      label: 'lbl_type'.tr,
                      value: controller.lr.vehicleTypeName!,
                    ),
                  InfoRow(label: 'lbl_lr_date'.tr, value: controller.lr.lrDate),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Weight ────────────────────────────────────────────
            _SectionCard(
              title: 'lbl_weight_section'.tr,
              child: Column(
                children: [
                  InfoRow(
                    label: 'lbl_allocated'.tr,
                    value:
                        '${controller.lr.allocatedWeight.toStringAsFixed(1)} T',
                  ),
                  if (controller.loadedWeight.value != null)
                    InfoRow(
                      label: 'lbl_loaded_label'.tr,
                      value:
                          '${controller.loadedWeight.value!.toStringAsFixed(1)} T',
                    ),
                  controller.deliveredWeight.value != null
                      ? InfoRow(
                          label: 'lbl_delivered_label'.tr,
                          value:
                              '${controller.deliveredWeight.value!.toStringAsFixed(1)} T',
                          showDivider: false,
                        )
                      : InfoRow(
                          label: 'lbl_delivered_label'.tr,
                          value: '—',
                          showDivider: false,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Odometer ──────────────────────────────────────────
            _SectionCard(
              title: 'lbl_odometer_section'.tr,
              child: Column(
                children: [
                  InfoRow(
                    label: 'lbl_start_odm'.tr,
                    value: controller.startOdometer.value != null
                        ? '${controller.startOdometer.value!.toStringAsFixed(0)} km'
                        : '—',
                  ),
                  InfoRow(
                    label: 'lbl_end_odm'.tr,
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
                      label: 'lbl_distance'.tr,
                      value:
                          '${(controller.endOdometer.value! - controller.startOdometer.value!).toStringAsFixed(0)} km',
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
          ),  // close ListView
        ),    // close RefreshIndicator
      ),
    );
  }

  Future<void> _onReportBreakdown(
    BuildContext context,
    DriverTripDetailController controller,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 40),
            const SizedBox(height: 12),
            Text(
              'lbl_confirm_breakdown_title'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'lbl_confirm_breakdown_body'.tr,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('btn_cancel'.tr,
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('btn_yes_report'.tr,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await Get.to(
      () => const DriverBreakdownView(),
      binding: DriverBreakdownBinding(),
      transition: Transition.cupertino,
    );
    // Always re-check after returning — more reliable than result flag
    controller.onBreakdownReported();
  }

  // Sheets stay in the view (need BuildContext); results passed to controller.
  Future<void> _onStartTrip(
    BuildContext context,
    DriverTripDetailController controller,
  ) async {
    final result = await showOdometerSheet(
      context,
      title: 'Start Trip — Record ODM',
      hint: 'Start Odometer (km)',
      buttonLabel: 'Start Trip',
      buttonColor: AppColors.navy,
      instruction:
          'Take a photo of the odometer before departure.\n'
          'Start ODM must be ≥ last recorded reading.',
    );
    if (result == null) return;
    controller.startTrip(result);
  }

  Future<void> _onMarkDelivered(
    BuildContext context,
    DriverTripDetailController controller,
  ) async {
    final odmResult = await showOdometerSheet(
      context,
      title: 'End Trip — Record ODM',
      hint: 'End Odometer (km)',
      buttonLabel: 'Next',
      buttonColor: AppColors.navy,
      instruction:
          'Take a photo of the odometer on arrival.\n'
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
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
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
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
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
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.navy;
        label = 'lbl_lr_created'.tr;
        break;
      case 'WEIGHT_LOADED':
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        label = 'lbl_weight_loaded_chip'.tr;
        break;
      case 'IN_TRANSIT':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        label = 'status_in_transit'.tr;
        break;
      case 'DELIVERED':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        label = 'status_delivered'.tr;
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'status_cancelled'.tr;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.mutedText;
        label = status;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      case 'DRIVER':   return 'role_driver'.tr;
      case 'CLEANER':  return 'role_cleaner'.tr;
      default:         return r ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        ),
        Text(
          '$name${role != null ? ' (${_roleLabel(role)})' : ''}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
