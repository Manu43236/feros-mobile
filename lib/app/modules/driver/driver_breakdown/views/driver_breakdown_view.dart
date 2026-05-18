import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/driver_breakdown_controller.dart';

class DriverBreakdownView extends GetView<DriverBreakdownController> {
  const DriverBreakdownView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text('btn_report_breakdown'.tr,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() => ListView(
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
                    'lbl_supervisor_notified'.tr,
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
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breakdown Type
                Text('lbl_breakdown_type'.tr,
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: DriverBreakdownController.types.map((t) {
                    final selected = controller.breakdownType.value == t;
                    return GestureDetector(
                      onTap: () => controller.breakdownType.value = t,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.navy : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.replaceAll('_', ' '),
                          style: AppTextStyles.caption.copyWith(
                            color: selected ? Colors.white : AppColors.mutedText,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Duration
                Text('lbl_expected_duration'.tr,
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Row(
                  children: DriverBreakdownController.durations.map((d) {
                    final selected = controller.breakdownDuration.value == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.breakdownDuration.value = d,
                        child: Container(
                          margin: EdgeInsets.only(right: d == 'SHORT' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.navy : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              d == 'SHORT' ? 'lbl_short_duration'.tr : 'lbl_long_duration'.tr,
                              style: AppTextStyles.caption.copyWith(
                                color: selected ? Colors.white : AppColors.mutedText,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
                Text('${'lbl_reason'.tr} *',
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.reasonCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'lbl_describe_happened'.tr,
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                Text('lbl_additional_notes'.tr,
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.notesCtrl,
                  maxLines: 2,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'lbl_optional_hint'.tr,
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                GestureDetector(
                  onTap: controller.isGettingLocation.value
                      ? null
                      : controller.getLocation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.position.value != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: controller.position.value != null
                            ? const Color(0xFFBBF7D0)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.position.value != null
                              ? Icons.location_on_outlined
                              : Icons.my_location_outlined,
                          size: 20,
                          color: controller.position.value != null
                              ? const Color(0xFF16A34A)
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.isGettingLocation.value
                                ? 'lbl_getting_location'.tr
                                : controller.position.value != null
                                    ? '${controller.position.value!.latitude.toStringAsFixed(4)}, ${controller.position.value!.longitude.toStringAsFixed(4)}'
                                    : 'lbl_tap_location'.tr,
                            style: AppTextStyles.caption.copyWith(
                              color: controller.position.value != null
                                  ? const Color(0xFF16A34A)
                                  : AppColors.mutedText,
                            ),
                          ),
                        ),
                        if (controller.isGettingLocation.value)
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.mutedText),
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
              onPressed: controller.isSubmitting.value ? null : controller.submit,
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.report_problem_outlined, size: 20),
              label: Text(
                controller.isSubmitting.value ? 'lbl_submitting'.tr : 'btn_report_breakdown'.tr,
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
      )),
    );
  }
}
