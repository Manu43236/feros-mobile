import 'dart:io';
import 'package:feros/core/popups/feros_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/services/upload_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/widgets/pulsing_dot.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../controllers/supervisor_lr_detail_controller.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicle_detail_binding.dart';
import '../../supervisor_vehicles/views/supervisor_vehicle_detail_view.dart';

class SupervisorLrDetailView extends GetView<SupervisorLrDetailController> {
  const SupervisorLrDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Obx(() {
          final lrNum =
              controller.lr.value?['lrNumber'] as String? ?? 'LR Detail';
          return Text(
            lrNum,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          );
        }),
        actions: [
          Obx(() {
            final st = controller.lr.value?['lrStatus'] as String? ?? '';
            if (st == 'CANCELLED' || st.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _EditLrSheet(controller: controller),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          );
        }
        if (controller.state.value == ViewState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'lbl_failed_lr'.tr,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('btn_retry'.tr),
                ),
              ],
            ),
          );
        }

        final lr = controller.lr.value!;
        final status = lr['lrStatus'] as String? ?? '';

        return RefreshIndicator(
          color: AppColors.navy,
          onRefresh: controller.fetchAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Status Banner ──────────────────────────────────────────
              _StatusBanner(lr: lr),
              const SizedBox(height: 12),

              // ── Route + Details Card ───────────────────────────────────
              _InfoCard(lr: lr, controller: controller),
              const SizedBox(height: 12),

              // ── Driver Card ────────────────────────────────────────────
              _DriverCard(lr: lr),
              const SizedBox(height: 12),

              // ── Cleaner Card ───────────────────────────────────────────
              _DriverCard(
                lr: lr,
                nameKey: 'cleanerName',
                phoneKey: 'cleanerPhone',
                roleLabelKey: 'role_cleaner',
              ),
              if (lr['cleanerName'] != null) const SizedBox(height: 12),

              // ── Weight Stats Card ──────────────────────────────────────
              _WeightCard(lr: lr),
              const SizedBox(height: 12),

              // ── Action Buttons ─────────────────────────────────────────
              _ActionButtons(controller: controller, status: status),
              const SizedBox(height: 16),

              // ── Checkposts ─────────────────────────────────────────────
              _SectionHeader(
                title: 'lbl_checkposts'.tr,
                count: controller.checkposts.length,
                onAdd: () => _showAddCheckpostSheet(context),
              ),
              const SizedBox(height: 8),
              if (controller.checkposts.isEmpty)
                _EmptySection(label: 'lbl_no_checkposts'.tr)
              else
                ...controller.checkposts.map(
                  (c) => _CheckpostCard(checkpost: c, controller: controller),
                ),
              const SizedBox(height: 16),

              // ── Charges ────────────────────────────────────────────────
              _SectionHeader(
                title: 'lbl_charges'.tr,
                count: controller.charges.length,
                onAdd: () => _showAddChargeSheet(context),
              ),
              const SizedBox(height: 8),
              if (controller.charges.isEmpty)
                _EmptySection(label: 'lbl_no_charges'.tr)
              else
                ...controller.charges.map((c) => _ChargeCard(charge: c, controller: controller)),
              const SizedBox(height: 16),

              // ── Trip Proofs ─────────────────────────────────────────────
              _SectionHeader(
                title: 'lbl_trip_proofs'.tr,
                count: controller.proofs.length,
              ),
              const SizedBox(height: 8),
              if (controller.proofs.isEmpty)
                _EmptySection(label: 'lbl_no_proofs'.tr)
              else
                ...controller.proofs.map(
                  (p) => _ProofCard(proof: p, controller: controller),
                ),

              // ── Trip Expenses ────────────────────────────────────────────
              if (status != 'CANCELLED' && status.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TripExpenseSection(controller: controller),
              ],
            ],
          ),
        );
      }),
    );
  }

  void _showAddCheckpostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCheckpostSheet(controller: controller),
    );
  }

  void _showAddChargeSheet(BuildContext context) async {
    await controller.ensureChargeTypesLoaded();
    if (controller.chargeTypes.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not load charge types',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddChargeSheet(controller: controller),
    );
  }
}

// ── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Map<String, dynamic> lr;
  const _StatusBanner({required this.lr});

  @override
  Widget build(BuildContext context) {
    final status = lr['lrStatus'] as String? ?? '';
    final color = _lrColor(status);
    final label = _lrLabel(status);
    final isOverloaded = lr['isOverloaded'] as bool? ?? false;
    final isInvoiced = lr['isInvoiced'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (status == 'IN_TRANSIT')
            PulsingDot(color: color, size: 8)
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isOverloaded) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'lbl_overloaded'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isInvoiced
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isInvoiced
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Text(
              isInvoiced ? 'lbl_invoiced'.tr : 'lbl_not_invoiced'.tr,
              style: AppTextStyles.caption.copyWith(
                color: isInvoiced ? AppColors.success : AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  final SupervisorLrDetailController controller;
  const _InfoCard({required this.lr, required this.controller});

  @override
  Widget build(BuildContext context) {
    final vehicleId = lr['vehicleId'] as int?;
    final vehicle = lr['vehicleRegistrationNumber'] as String? ?? '—';
    final vehicleType = lr['vehicleTypeName'] as String?;
    final fromCity = lr['fromCity'] as String? ?? '—';
    final toCity = lr['toCity'] as String? ?? '—';
    final client = lr['clientName'] as String? ?? '—';
    final orderNum = lr['orderNumber'] as String?;
    final driver = lr['startedByName'] as String?;
    final lrDate = lr['lrDate'] as String?;
    final remarks = lr['remarks'] as String?;
    final ewayBillNumber = lr['ewayBillNumber'] as String?;
    final ewayBillDate = lr['ewayBillDate'] as String?;
    final ewayBillValidUpto = lr['ewayBillValidUpto'] as String?;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle + PDF button
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: vehicleId == null
                      ? null
                      : () => Get.to(
                          () => const SupervisorVehicleDetailView(),
                          binding: SupervisorVehicleDetailBinding(),
                          arguments: vehicleId,
                        ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (vehicleType != null)
                              Text(
                                vehicleType,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (vehicleId != null)
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.mutedText,
                        ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => GestureDetector(
                  onTap: controller.pdfLoading.value
                      ? null
                      : controller.viewPdf,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: controller.pdfLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          )
                        : const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                            color: AppColors.navy,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                size: 14,
                color: AppColors.navy,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fromCity,
                  style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.mutedText,
                ),
              ),
              const Icon(Icons.location_on, size: 14, color: AppColors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  toCity,
                  style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Meta grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (client.isNotEmpty) _MetaItem(label: 'lbl_client'.tr, value: client),
              if (orderNum != null) _MetaItem(label: 'lbl_order'.tr, value: orderNum),
              if (driver != null) _MetaItem(label: 'role_driver'.tr, value: driver),
              if (lrDate != null)
                _MetaItem(
                  label: 'lbl_lr_date'.tr,
                  value: FerosDateUtils.formatDate(lrDate),
                ),
            ],
          ),

          if (ewayBillNumber != null && ewayBillNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Text(
              'lbl_eway_bill'.tr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _MetaItem(label: 'lbl_eway_bill_no'.tr, value: ewayBillNumber),
            if (ewayBillDate != null)
              _MetaItem(
                label: 'lbl_date'.tr,
                value: FerosDateUtils.formatDate(ewayBillDate),
              ),
            if (ewayBillValidUpto != null)
              _MetaItem(
                label: 'lbl_valid_upto'.tr,
                value: FerosDateUtils.formatDate(ewayBillValidUpto),
              ),
          ],
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Text(
              'lbl_remarks'.tr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              remarks,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Driver Card ───────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  final String nameKey;
  final String phoneKey;
  final String roleLabelKey;
  const _DriverCard({
    required this.lr,
    this.nameKey = 'driverName',
    this.phoneKey = 'driverPhone',
    this.roleLabelKey = 'role_driver',
  });

  @override
  Widget build(BuildContext context) {
    final name = lr[nameKey] as String?;
    final phone = lr[phoneKey] as String?;

    if (name == null && phone == null) return const SizedBox.shrink();

    return _Card(
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              FerosStringUtils.initials(name ?? '?'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '—',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.bodyText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 13,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      roleLabelKey.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    if (phone != null) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Call button
          if (phone != null)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.call,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weight Card ───────────────────────────────────────────────────────────────
class _WeightCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  const _WeightCard({required this.lr});

  @override
  Widget build(BuildContext context) {
    final allocated = lr['allocatedWeight'];
    final loaded = lr['loadedWeight'];
    final delivered = lr['deliveredWeight'];
    final variance = lr['weightVariance'];

    return _Card(
      child: Row(
        children: [
          _WeightStat(label: 'lbl_allocated'.tr, value: allocated),
          _Divider(),
          _WeightStat(label: 'lbl_loaded'.tr, value: loaded),
          _Divider(),
          _WeightStat(label: 'lbl_delivered'.tr, value: delivered),
          if (variance != null) ...[
            _Divider(),
            _WeightStat(
              label: 'lbl_variance'.tr,
              value: variance,
              color: (variance as num) != 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color? color;
  const _WeightStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value != null ? '${value}T' : '—',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ── Action Buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final SupervisorLrDetailController controller;
  final String status;
  const _ActionButtons({required this.controller, required this.status});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isUpdating.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == 'WEIGHT_LOADED')
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'lbl_waiting_driver'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (status == 'CREATED')
                Expanded(
                  child: _ActionBtn(
                    label: 'btn_record_loading'.tr,
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.lrLoaded,
                    loading: busy,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          _RecordLoadingSheet(controller: controller),
                    ),
                  ),
                ),
              if (status == 'IN_TRANSIT') ...[
                Expanded(
                  child: controller.activeBreakdown.value?['status'] == 'REPORTED'
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Breakdown reported — resolve before marking delivered',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _ActionBtn(
                          label: 'btn_mark_delivered'.tr,
                          icon: Icons.check_circle_outline,
                          color: AppColors.lrDelivered,
                          loading: busy,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _MarkDeliveredSheet(controller: controller),
                          ),
                        ),
                ),
              ],
              if (status == 'CREATED') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'btn_cancel'.tr,
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    loading: busy,
                    onTap: () async {
                      final confirmed = await FerosDialog.confirm(
                        title: 'btn_cancel'.tr,
                        message: 'lbl_cancel_lr_confirm'.tr,
                        confirmText: 'btn_cancel'.tr,
                        isDestructive: true,
                      );
                      if (confirmed) controller.cancelLr();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: loading ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onAdd;
  const _SectionHeader({required this.title, required this.count, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'lbl_add'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Checkpost Card ────────────────────────────────────────────────────────────
class _CheckpostCard extends StatelessWidget {
  final Map<String, dynamic> checkpost;
  final SupervisorLrDetailController controller;
  const _CheckpostCard({required this.checkpost, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cpId = checkpost['id'] as int?;
    final name = checkpost['checkpostName'] as String? ?? '—';
    final location = checkpost['location'] as String?;
    final fine = checkpost['fineAmount'];
    final receipt = checkpost['fineReceiptNumber'] as String?;
    final remarks = checkpost['remarks'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.toll, size: 16, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.bodyText,
                  ),
                ),
              ),
              if (fine != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹$fine',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (cpId != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => controller.deleteCheckpost(cpId),
                  child: const Icon(Icons.delete_outline, size: 18, color: AppColors.mutedText),
                ),
              ],
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
          if (receipt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${'lbl_receipt'.tr}: $receipt',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              remarks,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Charge Card ───────────────────────────────────────────────────────────────
class _ChargeCard extends StatelessWidget {
  final Map<String, dynamic> charge;
  final SupervisorLrDetailController controller;
  const _ChargeCard({required this.charge, required this.controller});

  @override
  Widget build(BuildContext context) {
    final chargeId = charge['id'] as int?;
    final type = charge['chargeTypeName'] as String? ?? '—';
    final amount = charge['amount'];
    final remarks = charge['remarks'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, size: 16, color: AppColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                ),
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    remarks,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹$amount',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (chargeId != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => controller.deleteCharge(chargeId),
              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sheet: Record Loading ─────────────────────────────────────────────────────
class _RecordLoadingSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _RecordLoadingSheet({required this.controller});
  @override
  State<_RecordLoadingSheet> createState() => _RecordLoadingSheetState();
}

class _RecordLoadingSheetState extends State<_RecordLoadingSheet> {
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _loadedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    final aw = widget.controller.lr.value?['allocatedWeight'];
    if (aw != null) _weightCtrl.text = aw.toString();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = <String, dynamic>{'loadedAt': _loadedAt.toIso8601String()};
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w != null) data['loadedWeight'] = w;
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }
    final ok = await widget.controller.recordLoading(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'btn_record_loading'.tr,
      controller: widget.controller.isUpdating,
      onSubmit: _submit,
      submitLabel: 'btn_record_loading'.tr,
      children: [
        _SheetLabel('lbl_loaded_weight_tonnes'.tr),
        const SizedBox(height: 6),
        _SheetField(
          controller: _weightCtrl,
          hint: 'e.g. 12.5',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_remarks'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _remarksCtrl, hint: 'lbl_optional_hint'.tr, maxLines: 2),
      ],
    );
  }
}

// ── Sheet: Mark Delivered ─────────────────────────────────────────────────────
class _MarkDeliveredSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _MarkDeliveredSheet({required this.controller});
  @override
  State<_MarkDeliveredSheet> createState() => _MarkDeliveredSheetState();
}

class _MarkDeliveredSheetState extends State<_MarkDeliveredSheet> {
  final _weightCtrl = TextEditingController();
  final _odomCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _odomCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final odometer = double.tryParse(_odomCtrl.text.trim());
    if (odometer == null) {
      Get.snackbar(
        'Required',
        'Please enter the end odometer reading',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final data = <String, dynamic>{
      'endOdometer': odometer,
      'deliveredAt': DateTime.now().toIso8601String(),
    };
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w != null) data['deliveredWeight'] = w;
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }
    final ok = await widget.controller.markDelivered(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'lbl_mark_as_delivered'.tr,
      controller: widget.controller.isUpdating,
      onSubmit: _submit,
      submitLabel: 'btn_mark_delivered'.tr,
      children: [
        _SheetLabel('lbl_end_odometer'.tr),
        const SizedBox(height: 6),
        _SheetField(
          controller: _odomCtrl,
          hint: 'Current meter reading',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_delivered_weight_tonnes'.tr),
        const SizedBox(height: 6),
        _SheetField(
          controller: _weightCtrl,
          hint: 'e.g. 12.3',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_remarks'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _remarksCtrl, hint: 'lbl_optional_hint'.tr, maxLines: 2),
      ],
    );
  }
}

// ── Sheet: Add Checkpost ──────────────────────────────────────────────────────
class _AddCheckpostSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _AddCheckpostSheet({required this.controller});
  @override
  State<_AddCheckpostSheet> createState() => _AddCheckpostSheetState();
}

class _AddCheckpostSheetState extends State<_AddCheckpostSheet> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _fineCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _fineCtrl.dispose();
    _receiptCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter the checkpost name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final data = <String, dynamic>{'checkpostName': _nameCtrl.text.trim()};
    if (_locationCtrl.text.trim().isNotEmpty) {
      data['location'] = _locationCtrl.text.trim();
    }
    final fine = double.tryParse(_fineCtrl.text.trim());
    if (fine != null) data['fineAmount'] = fine;
    if (_receiptCtrl.text.trim().isNotEmpty) {
      data['fineReceiptNumber'] = _receiptCtrl.text.trim();
    }
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }
    final ok = await widget.controller.addCheckpost(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'btn_add_checkpost'.tr,
      controller: widget.controller.isAddingCheckpost,
      onSubmit: _submit,
      submitLabel: 'btn_add_checkpost'.tr,
      children: [
        _SheetLabel('lbl_checkpost_name'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _nameCtrl, hint: 'e.g. Walajah Checkpost'),
        const SizedBox(height: 16),
        _SheetLabel('lbl_location'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _locationCtrl, hint: 'lbl_optional_hint'.tr),
        const SizedBox(height: 16),
        _SheetLabel('lbl_fine_amount'.tr),
        const SizedBox(height: 6),
        _SheetField(
          controller: _fineCtrl,
          hint: 'Leave empty if no fine',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_fine_receipt'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _receiptCtrl, hint: 'Receipt no.'),
        const SizedBox(height: 16),
        _SheetLabel('lbl_remarks'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _remarksCtrl, hint: 'lbl_optional_hint'.tr, maxLines: 2),
      ],
    );
  }
}

// ── Sheet: Add Charge ─────────────────────────────────────────────────────────
class _AddChargeSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _AddChargeSheet({required this.controller});
  @override
  State<_AddChargeSheet> createState() => _AddChargeSheetState();
}

class _AddChargeSheetState extends State<_AddChargeSheet> {
  Map<String, dynamic>? _selectedType;
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      Get.snackbar(
        'Required',
        'Please select a charge type',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      Get.snackbar(
        'Required',
        'Please enter the amount',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final data = <String, dynamic>{
      'chargeTypeId': _selectedType!['id'],
      'amount': amount,
    };
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }
    final ok = await widget.controller.addCharge(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'btn_add_charge'.tr,
      controller: widget.controller.isAddingCharge,
      onSubmit: _submit,
      submitLabel: 'btn_add_charge'.tr,
      children: [
        _SheetLabel('lbl_charge_type'.tr),
        const SizedBox(height: 6),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedType,
          hint: Text(
            'lbl_select_type'.tr,
            style: AppTextStyles.body.copyWith(color: AppColors.hintText),
          ),
          isExpanded: true,
          decoration: _sheetInputDecoration(),
          items: widget.controller.chargeTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t['name'] as String? ?? '—',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedType = v),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_amount'.tr),
        const SizedBox(height: 6),
        _SheetField(
          controller: _amountCtrl,
          hint: 'e.g. 500',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_remarks'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _remarksCtrl, hint: 'lbl_optional_hint'.tr, maxLines: 2),
      ],
    );
  }
}

// ── Sheet: Edit LR ───────────────────────────────────────────────────────────
class _EditLrSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _EditLrSheet({required this.controller});
  @override
  State<_EditLrSheet> createState() => _EditLrSheetState();
}

class _EditLrSheetState extends State<_EditLrSheet> {
  final _weightCtrl   = TextEditingController();
  final _ewayNumCtrl  = TextEditingController();
  final _remarksCtrl  = TextEditingController();
  DateTime? _ewayDate;
  DateTime? _ewayValidUpto;
  late String _status;

  @override
  void initState() {
    super.initState();
    final lr = widget.controller.lr.value ?? {};
    _status = lr['lrStatus'] as String? ?? '';
    final weightKey = _status == 'DELIVERED' ? 'deliveredWeight' : 'loadedWeight';
    final w = lr[weightKey];
    if (w != null) _weightCtrl.text = w.toString();
    _ewayNumCtrl.text = lr['ewayBillNumber'] as String? ?? '';
    _remarksCtrl.text = lr['remarks'] as String? ?? '';
    final ed = lr['ewayBillDate'] as String?;
    final ev = lr['ewayBillValidUpto'] as String?;
    if (ed != null) _ewayDate = DateTime.tryParse(ed);
    if (ev != null) _ewayValidUpto = DateTime.tryParse(ev);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _ewayNumCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isValidUpto) async {
    final initial = (isValidUpto ? _ewayValidUpto : _ewayDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.navy),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isValidUpto) {
        _ewayValidUpto = picked;
      } else {
        _ewayDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final data = <String, dynamic>{};
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w != null) {
      data[_status == 'DELIVERED' ? 'deliveredWeight' : 'loadedWeight'] = w;
    }
    final ewayNum = _ewayNumCtrl.text.trim();
    if (ewayNum.isNotEmpty) data['ewayBillNumber'] = ewayNum;
    if (_ewayDate != null) {
      data['ewayBillDate'] = _ewayDate!.toIso8601String().substring(0, 10);
    }
    if (_ewayValidUpto != null) {
      data['ewayBillValidUpto'] = _ewayValidUpto!.toIso8601String().substring(0, 10);
    }
    final remarks = _remarksCtrl.text.trim();
    if (remarks.isNotEmpty) data['remarks'] = remarks;
    if (data.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await widget.controller.updateLr(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final weightLabel = _status == 'DELIVERED'
        ? 'lbl_delivered_weight_tonnes'.tr
        : 'lbl_loaded_weight_tonnes'.tr;
    return _SimpleSheet(
      title: 'btn_edit_lr'.tr,
      controller: widget.controller.isUpdating,
      onSubmit: _submit,
      submitLabel: 'btn_save'.tr,
      children: [
        _SheetLabel(weightLabel),
        const SizedBox(height: 6),
        _SheetField(
          controller: _weightCtrl,
          hint: 'e.g. 12.5',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_eway_bill_no'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _ewayNumCtrl, hint: 'lbl_optional_hint'.tr),
        const SizedBox(height: 16),
        _SheetLabel('lbl_eway_date'.tr),
        const SizedBox(height: 6),
        _DatePickerTile(
          date: _ewayDate,
          hint: 'lbl_tap_to_select'.tr,
          onTap: () => _pickDate(false),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_valid_upto'.tr),
        const SizedBox(height: 6),
        _DatePickerTile(
          date: _ewayValidUpto,
          hint: 'lbl_tap_to_select'.tr,
          onTap: () => _pickDate(true),
        ),
        const SizedBox(height: 16),
        _SheetLabel('lbl_remarks'.tr),
        const SizedBox(height: 6),
        _SheetField(controller: _remarksCtrl, hint: 'lbl_optional_hint'.tr, maxLines: 2),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;
  const _DatePickerTile({required this.date, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                    : hint,
                style: AppTextStyles.body.copyWith(
                  color: date != null ? AppColors.bodyText : AppColors.hintText,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

// ── Shared Sheet Wrapper ──────────────────────────────────────────────────────
class _SimpleSheet extends StatelessWidget {
  final String title;
  final RxBool controller;
  final VoidCallback onSubmit;
  final String submitLabel;
  final List<Widget> children;
  const _SimpleSheet({
    required this.title,
    required this.controller,
    required this.onSubmit,
    required this.submitLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.value ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          submitLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.mutedText,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboard;
  const _SheetField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
      decoration: _sheetInputDecoration().copyWith(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
      ),
    ],
  );
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      label,
      style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
    ),
  );
}

InputDecoration _sheetInputDecoration() => InputDecoration(
  filled: true,
  fillColor: AppColors.background,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
  ),
);

Color _lrColor(String s) {
  switch (s) {
    case 'CREATED':
      return AppColors.lrCreated;
    case 'WEIGHT_LOADED':
      return AppColors.lrLoaded;
    case 'IN_TRANSIT':
      return AppColors.lrInTransit;
    case 'DELIVERED':
      return AppColors.lrDelivered;
    case 'INVOICED':
      return AppColors.lrInvoiced;
    case 'CANCELLED':
      return AppColors.error;
    default:
      return AppColors.mutedText;
  }
}

String _lrLabel(String s) {
  switch (s) {
    case 'CREATED':       return 'lbl_lr_created'.tr;
    case 'WEIGHT_LOADED': return 'lbl_weight_loaded_chip'.tr;
    case 'IN_TRANSIT':    return 'status_in_transit'.tr;
    case 'DELIVERED':     return 'status_delivered'.tr;
    case 'INVOICED':      return 'status_invoiced'.tr;
    case 'CANCELLED':     return 'status_cancelled'.tr;
    default:              return s;
  }
}

// ── Proof Card ────────────────────────────────────────────────────────────────
class _ProofCard extends StatelessWidget {
  final Map<String, dynamic> proof;
  final SupervisorLrDetailController controller;
  const _ProofCard({required this.proof, required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = proof['id'] as int? ?? 0;
    final imageUrl = proof['imageUrl'] as String?;
    final userName = proof['userName'] as String? ?? '—';
    final capturedAt = proof['capturedAt'] as String?;
    final isReviewed = proof['isReviewed'] as bool? ?? false;
    final reviewedBy = proof['reviewedByName'] as String?;
    final remarks = proof['reviewRemarks'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.background,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.mutedText,
                    size: 40,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      userName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const Spacer(),
                    if (capturedAt != null)
                      Text(
                        FerosDateUtils.formatDateTime(capturedAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
                if (isReviewed) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reviewed by ${reviewedBy ?? '—'}${remarks != null && remarks.isNotEmpty ? ' · "$remarks"' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Obx(() {
                    final isLoading = controller.isReviewingId.value == id;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _showReviewSheet(context, id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Mark as Reviewed',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewSheet(BuildContext context, int proofId) {
    final remarksCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Proof',
                style: AppTextStyles.heading4.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksCtrl,
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await controller.reviewProof(
                      proofId,
                      remarks: remarksCtrl.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Confirm Review',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trip Expense Section ───────────────────────────────────────────────────────
class _TripExpenseSection extends StatelessWidget {
  final SupervisorLrDetailController controller;
  const _TripExpenseSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expense    = controller.tripExpense.value;
      final status     = expense?['status'] as String? ?? '';
      final lrStatus   = controller.lr.value?['lrStatus'] as String? ?? '';
      final isDelivered = lrStatus == 'DELIVERED';
      final isEditable  = status == 'DRAFT' || status == 'REJECTED';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(
                'Trip Expenses',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              if (status.isNotEmpty) _ExpenseStatusBadge(status: status),
              const Spacer(),
              // GAP-3: Delete sheet
              if (expense != null && isEditable)
                GestureDetector(
                  onTap: () async {
                    final confirmed = await FerosDialog.confirm(
                      title: 'Delete Sheet',
                      message: 'Delete this expense sheet and all items?',
                      confirmText: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed) controller.deleteTripExpenseSheet();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                  ),
                ),
              // GAP-1: Add only after delivery
              if (expense != null && isEditable && isDelivered)
                GestureDetector(
                  onTap: () => _showAddItemSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // GAP-1: Pre-delivery notice
          if (expense != null && isEditable && !isDelivered) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Advance recorded. Add expense items and submit once the LR is delivered.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // No sheet yet
          if (expense == null) ...[
            _Card(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.mutedText),
                  const SizedBox(height: 8),
                  Text(
                    'No expense sheet yet',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyText, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create one to record advance and trip expenses',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isTripExpenseBusy.value ? null : () => _showCreateSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Create Expense Sheet', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    )),
                  ),
                ],
              ),
            ),
          ]

          // Expense sheet exists
          else ...[
            // Advance & Batta card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fixed Allowances', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _ExpRow(label: 'Advance Issued', value: expense['advanceAmount']),
                  _ExpRow(label: 'Driver Batta (${expense['tripDays']} days)', value: expense['driverBatta'], muted: true),
                  if ((expense['cleanerBatta'] as num? ?? 0) > 0)
                    _ExpRow(label: 'Cleaner Batta', value: expense['cleanerBatta'], muted: true),
                  _ExpRow(label: 'Trip Mamulu', value: expense['tripMamulu'], muted: true),
                  const Divider(height: 20),
                  _ExpRow(label: 'Fixed Total', value: expense['totalFixedAmount'], bold: true),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Items card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expense Items', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if ((expense['items'] as List? ?? []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No items added yet', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                    )
                  else
                    ...(expense['items'] as List).cast<Map<String, dynamic>>().map((item) {
                      final amountChanged = item['amountChanged'] as bool? ?? false;
                      final receiptUrl    = item['receiptUrl'] as String?;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['description'] as String? ?? '—',
                                    style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                                  ),
                                  // GAP-5: receipt link
                                  if (receiptUrl != null)
                                    GestureDetector(
                                      onTap: () => launchUrl(Uri.parse(receiptUrl), mode: LaunchMode.externalApplication),
                                      child: Text(
                                        'View receipt',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.info, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(item['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              style: AppTextStyles.body.copyWith(
                                color: amountChanged ? AppColors.warning : AppColors.bodyText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isEditable) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => controller.removeTripExpenseItem(item['id'] as int),
                                child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 16),
                  _ExpRow(label: 'Total Submitted', value: expense['totalSubmittedAmount'], bold: true),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Settlement summary (after approved)
            if (status == 'APPROVED' || status == 'SETTLED') ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settlement', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _ExpRow(label: 'Total Approved', value: expense['totalApprovedAmount']),
                    _ExpRow(label: 'Advance Given', value: expense['advanceAmount']),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (expense['balanceAmount'] as num? ?? 0) >= 0 ? 'Driver Returns' : 'Company Pays Driver',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.bodyText),
                        ),
                        Text(
                          '₹${((expense['balanceAmount'] as num?)?.abs() ?? 0).toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: (expense['balanceAmount'] as num? ?? 0) >= 0 ? AppColors.info : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Settled note
            if (status == 'SETTLED' && expense['settlementNote'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expense['settlementNote'] as String,
                        style: AppTextStyles.caption.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Rejection banner
            if (status == 'REJECTED') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rejected by Admin', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
                          if ((expense['rejectionReason'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(expense['rejectionReason'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                          ],
                          if ((expense['rejectedByName'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text('By ${expense['rejectedByName']}', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                          ],
                          const SizedBox(height: 4),
                          Text('Please correct and resubmit.', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Submitted info
            if (status == 'SUBMITTED') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('Submitted — awaiting admin approval', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action buttons
            Obx(() {
              final busy = controller.isTripExpenseBusy.value;
              final items = (expense['items'] as List? ?? []);

              if (status == 'DRAFT' || status == 'REJECTED') {
                // GAP-1: only submit after delivery
                final lrSt = controller.lr.value?['lrStatus'] as String? ?? '';
                if (lrSt != 'DELIVERED') return const SizedBox.shrink();
                return Column(
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Add at least one expense before submitting',
                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (busy || items.isEmpty) ? null : () async {
                          final ok = await controller.submitTripExpense();
                          if (!ok) return;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(status == 'REJECTED' ? 'Resubmit for Approval' : 'Submit for Approval', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                );
              }

              if (status == 'APPROVED') {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _showSettleSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Record Settlement', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                );
              }

              return const SizedBox.shrink();
            }),
          ],
        ],
      );
    });
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateExpenseSheet(controller: controller),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseItemSheet(controller: controller),
    );
  }

  void _showSettleSheet(BuildContext context) {
    final expense = controller.tripExpense.value;
    if (expense == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettleExpenseSheet(
        controller: controller,
        balanceAmount:       (expense['balanceAmount'] as num?)?.toDouble() ?? 0,
        driverBankName:      expense['driverBankName'] as String?,
        driverAccountNumber: expense['driverAccountNumber'] as String?,
        driverIfscCode:      expense['driverIfscCode'] as String?,
      ),
    );
  }
}

// ── Expense Status Badge ───────────────────────────────────────────────────────
class _ExpenseStatusBadge extends StatelessWidget {
  final String status;
  const _ExpenseStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;
    switch (status) {
      case 'DRAFT':
        bg = AppColors.border; text = AppColors.mutedText; label = 'Draft'; break;
      case 'SUBMITTED':
        bg = AppColors.warningLight; text = AppColors.warning; label = 'Submitted'; break;
      case 'APPROVED':
        bg = AppColors.successLight; text = AppColors.success; label = 'Approved'; break;
      case 'SETTLED':
        bg = AppColors.infoLight; text = AppColors.info; label = 'Settled'; break;
      default:
        bg = AppColors.border; text = AppColors.mutedText; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: text, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Expense Row helper ─────────────────────────────────────────────────────────
class _ExpRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool bold;
  final bool muted;
  const _ExpRow({required this.label, required this.value, this.bold = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final formatted = '₹${(value as num?)?.toStringAsFixed(0) ?? '0'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: muted ? AppColors.hintText : AppColors.mutedText)),
          Text(formatted, style: AppTextStyles.caption.copyWith(color: AppColors.bodyText, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Sheet: Create Expense Sheet ────────────────────────────────────────────────
class _CreateExpenseSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _CreateExpenseSheet({required this.controller});
  @override
  State<_CreateExpenseSheet> createState() => _CreateExpenseSheetState();
}

class _CreateExpenseSheetState extends State<_CreateExpenseSheet> {
  final _advanceCtrl  = TextEditingController();
  final _tripDaysCtrl = TextEditingController();

  @override
  void dispose() {
    _advanceCtrl.dispose();
    _tripDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final advance  = double.tryParse(_advanceCtrl.text.trim()) ?? 0;
    final tripDays = int.tryParse(_tripDaysCtrl.text.trim());
    final ok = await widget.controller.createTripExpenseDraft(advance, tripDays);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'Create Expense Sheet',
      controller: widget.controller.isTripExpenseBusy,
      onSubmit: _submit,
      submitLabel: 'Create Sheet',
      children: [
        _SheetLabel('Advance Issued to Driver (₹)'),
        const SizedBox(height: 6),
        _SheetField(controller: _advanceCtrl, hint: 'e.g. 10000 (enter 0 if none)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 16),
        _SheetLabel('Trip Days (optional)'),
        const SizedBox(height: 6),
        _SheetField(controller: _tripDaysCtrl, hint: 'Auto-calculated from LR dates', keyboard: TextInputType.number),
      ],
    );
  }
}

// ── Sheet: Add Expense Item ────────────────────────────────────────────────────
class _AddExpenseItemSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  const _AddExpenseItemSheet({required this.controller});
  @override
  State<_AddExpenseItemSheet> createState() => _AddExpenseItemSheetState();
}

class _AddExpenseItemSheetState extends State<_AddExpenseItemSheet> {
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _receiptUrl;
  bool    _uploading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // GAP-4: pick image and upload
  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await Get.find<UploadService>().uploadFileGetPublicUrl(
        File(picked.path),
        folder: 'tenants/images/trip-expense-receipts',
      );
      setState(() { _receiptUrl = url; _uploading = false; });
      FerosSnackbar.success('Receipt uploaded');
    } catch (_) {
      setState(() => _uploading = false);
      FerosSnackbar.error('Failed to upload receipt');
    }
  }

  Future<void> _submit() async {
    final desc   = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (desc.isEmpty || amount == null || amount <= 0) {
      FerosSnackbar.error('Please enter description and a valid amount');
      return;
    }
    final ok = await widget.controller.addTripExpenseItem(desc, amount, receiptUrl: _receiptUrl);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSheet(
      title: 'Add Expense',
      controller: widget.controller.isTripExpenseBusy,
      onSubmit: _submit,
      submitLabel: 'Add Expense',
      children: [
        _SheetLabel('Description *'),
        const SizedBox(height: 6),
        _SheetField(controller: _descCtrl, hint: 'e.g. Toll, Hamali, Fuel, Food…'),
        const SizedBox(height: 16),
        _SheetLabel('Amount (₹) *'),
        const SizedBox(height: 6),
        _SheetField(controller: _amountCtrl, hint: 'e.g. 350', keyboard: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 16),
        // GAP-4: receipt upload
        _SheetLabel('Receipt (optional)'),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _uploading ? null : _pickReceipt,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _receiptUrl != null ? AppColors.successLight : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _receiptUrl != null ? AppColors.success.withValues(alpha: 0.4) : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_uploading)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy))
                    else
                      Icon(
                        _receiptUrl != null ? Icons.check_circle_outline : Icons.attach_file,
                        size: 15,
                        color: _receiptUrl != null ? AppColors.success : AppColors.mutedText,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _uploading ? 'Uploading…' : _receiptUrl != null ? 'Receipt attached ✓' : 'Attach from gallery',
                      style: AppTextStyles.caption.copyWith(
                        color: _receiptUrl != null ? AppColors.success : AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_receiptUrl != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _receiptUrl = null),
                child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Sheet: Record Settlement ───────────────────────────────────────────────────
class _SettleExpenseSheet extends StatefulWidget {
  final SupervisorLrDetailController controller;
  final double balanceAmount;
  final String? driverBankName;
  final String? driverAccountNumber;
  final String? driverIfscCode;
  const _SettleExpenseSheet({
    required this.controller,
    required this.balanceAmount,
    this.driverBankName,
    this.driverAccountNumber,
    this.driverIfscCode,
  });
  @override
  State<_SettleExpenseSheet> createState() => _SettleExpenseSheetState();
}

class _SettleExpenseSheetState extends State<_SettleExpenseSheet> {
  final _noteCtrl  = TextEditingController();
  String _payMode  = 'CASH';

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.controller.settleTripExpense(
      widget.balanceAmount.abs(),
      _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      _payMode,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final driverReturns = widget.balanceAmount >= 0;
    final showBank = !driverReturns && (_payMode == 'NEFT' || _payMode == 'UPI');
    final hasBankDetails = widget.driverAccountNumber != null || widget.driverIfscCode != null;

    return _SimpleSheet(
      title: 'Record Settlement',
      controller: widget.controller.isTripExpenseBusy,
      onSubmit: _submit,
      submitLabel: 'Mark Settled',
      children: [
        // Amount banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: driverReturns ? AppColors.infoLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: driverReturns ? AppColors.info.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                driverReturns ? 'Driver Returns' : 'Company Pays Driver',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: driverReturns ? AppColors.info : AppColors.warning),
              ),
              Text(
                '₹${widget.balanceAmount.abs().toStringAsFixed(0)}',
                style: AppTextStyles.heading4.copyWith(color: driverReturns ? AppColors.info : AppColors.warning),
              ),
            ],
          ),
        ),
        // GAP-2: Payment mode — only when company pays driver
        if (!driverReturns) ...[
          const SizedBox(height: 16),
          _SheetLabel('Payment Mode'),
          const SizedBox(height: 8),
          Row(
            children: ['CASH', 'NEFT', 'UPI'].map((mode) {
              final active = _payMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _payMode = mode),
                  child: Container(
                    margin: EdgeInsets.only(right: mode != 'UPI' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.navy : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? AppColors.navy : AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        mode,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Driver bank details for NEFT/UPI
          if (showBank) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: hasBankDetails ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Driver Bank Details', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (widget.driverAccountNumber != null)
                    _BankRow('Account No.', widget.driverAccountNumber!),
                  if (widget.driverIfscCode != null)
                    _BankRow('IFSC', widget.driverIfscCode!),
                  if (widget.driverBankName != null)
                    _BankRow('Bank', widget.driverBankName!),
                ],
              ) : Text(
                'No bank details on file for this driver.',
                style: AppTextStyles.caption.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        _SheetLabel('Note (optional)'),
        const SizedBox(height: 6),
        _SheetField(
          controller: _noteCtrl,
          hint: _payMode == 'CASH' ? 'e.g. Cash paid to driver on 15 Jan' : 'e.g. NEFT ref no. 12345',
          maxLines: 2,
        ),
      ],
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          Text(value, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.bodyText)),
        ],
      ),
    );
  }
}
