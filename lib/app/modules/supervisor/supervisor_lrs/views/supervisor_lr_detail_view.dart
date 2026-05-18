import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/widgets/pulsing_dot.dart';
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
                  (c) => _CheckpostCard(checkpost: c),
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
                ...controller.charges.map((c) => _ChargeCard(charge: c)),
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
  const _DriverCard({required this.lr});

  @override
  Widget build(BuildContext context) {
    final name = lr['driverName'] as String?;
    final phone = lr['driverPhone'] as String?;

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
                      'role_driver'.tr,
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
                  child: _ActionBtn(
                    label: 'btn_mark_delivered'.tr,
                    icon: Icons.check_circle_outline,
                    color: AppColors.lrDelivered,
                    loading: busy,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          _MarkDeliveredSheet(controller: controller),
                    ),
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
  const _CheckpostCard({required this.checkpost});

  @override
  Widget build(BuildContext context) {
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
  const _ChargeCard({required this.charge});

  @override
  Widget build(BuildContext context) {
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
