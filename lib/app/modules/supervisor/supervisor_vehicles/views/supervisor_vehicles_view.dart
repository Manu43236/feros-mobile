import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/supervisor_vehicles_controller.dart';
import '../bindings/supervisor_vehicle_detail_binding.dart';
import 'supervisor_vehicle_detail_view.dart';

class SupervisorVehiclesView extends GetView<SupervisorVehiclesController> {
  const SupervisorVehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          'lbl_vehicles'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: controller.onSearch,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'lbl_search_vehicles'.tr,
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.mutedText,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.mutedText,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  borderSide: const BorderSide(
                    color: AppColors.navy,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Status filter chips ─────────────────────────────────
          Obx(() {
            if (controller.state.value != ViewState.success) {
              return const SizedBox.shrink();
            }
            final options = ['ALL', ...controller.statusOptions];
            return Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: options.map((s) {
                    final isSelected = controller.selectedStatus.value == s;
                    return GestureDetector(
                      onTap: () => controller.onStatusFilter(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.navy
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          s == 'ALL' ? 'lbl_all'.tr : s,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.bodyText,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),

          const Divider(height: 1, color: AppColors.border),

          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: Obx(() {
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
                        'lbl_failed_vehicles'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchVehicles,
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

              final list = controller.vehicles;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.garage_outlined,
                        size: 52,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'lbl_no_vehicles_found'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.navy,
                onRefresh: controller.fetchVehicles,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _VehicleCard(vehicle: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Vehicle Card ──────────────────────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final id = vehicle['id'];
    final reg = vehicle['registrationNumber'] as String? ?? '—';
    final type = vehicle['vehicleTypeName'] as String?;
    final brand = vehicle['brandName'] as String?;
    final fuel = vehicle['fuelTypeName'] as String?;
    final ownership = vehicle['ownershipTypeName'] as String?;
    final statusName = vehicle['currentStatusName'] as String?;
    final statusType = vehicle['currentStatusType'] as String? ?? '';
    final capacity = vehicle['capacityInTons'];
    final isActive = vehicle['active'] as bool? ?? true;

    final rcExp = vehicle['rcExpiryDate'] as String?;
    final insExp = vehicle['insuranceExpiryDate'] as String?;
    final permitExp = vehicle['permitExpiryDate'] as String?;
    final fitnessExp = vehicle['fitnessExpiryDate'] as String?;
    final pucExp = vehicle['pollutionExpiryDate'] as String?;

    final (statusColor, statusBg) = _statusColors(statusType);
    final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;

    return GestureDetector(
      onTap: () => Get.to(
        () => const SupervisorVehicleDetailView(),
        binding: SupervisorVehicleDetailBinding(),
        arguments: intId,
        transition: Transition.cupertino,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 20,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reg,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (type != null || brand != null)
                          Text(
                            [brand, type].where((s) => s != null).join(' · '),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (statusName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statusName,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (!isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'lbl_inactive'.tr,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips row
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      if (capacity != null)
                        _InfoChip(Icons.scale_outlined, '${capacity}T'),
                      if (fuel != null)
                        _InfoChip(Icons.local_gas_station_outlined, fuel),
                      if (ownership != null)
                        _InfoChip(Icons.business_outlined, ownership),
                    ],
                  ),

                  // Expiry chips
                  if (_hasExpiry(
                    rcExp,
                    insExp,
                    permitExp,
                    fitnessExp,
                    pucExp,
                  )) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (rcExp != null)
                          _ExpiryChip(date: rcExp, label: 'RC'),
                        if (insExp != null)
                          _ExpiryChip(date: insExp, label: 'Insurance'),
                        if (permitExp != null)
                          _ExpiryChip(date: permitExp, label: 'Permit'),
                        if (fitnessExp != null)
                          _ExpiryChip(date: fitnessExp, label: 'Fitness'),
                        if (pucExp != null)
                          _ExpiryChip(date: pucExp, label: 'PUC'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ), // GestureDetector
    );
  }

  bool _hasExpiry(
    String? rc,
    String? ins,
    String? permit,
    String? fit,
    String? puc,
  ) =>
      rc != null || ins != null || permit != null || fit != null || puc != null;

  static (Color, Color) _statusColors(String type) {
    switch (type) {
      case 'AVAILABLE':
        return (const Color(0xFF16A34A), const Color(0xFFF0FDF4));
      case 'ASSIGNED':
        return (const Color(0xFF2563EB), const Color(0xFFEFF6FF));
      case 'ON_TRIP':
        return (const Color(0xFFEA580C), const Color(0xFFFFF7ED));
      case 'IN_REPAIR':
        return (const Color(0xFFD97706), const Color(0xFFFFFBEB));
      case 'BREAKDOWN':
        return (const Color(0xFFDC2626), const Color(0xFFFEF2F2));
      default:
        return (AppColors.mutedText, AppColors.background);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

// ── Expiry Chip ───────────────────────────────────────────────────────────────
class _ExpiryChip extends StatelessWidget {
  final String date;
  final String label;
  const _ExpiryChip({required this.date, required this.label});

  @override
  Widget build(BuildContext context) {
    final status = _expiryStatus(date);
    if (status == _Expiry.none) return const SizedBox.shrink();

    final (bg, fg, icon) = switch (status) {
      _Expiry.expired => (
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
        Icons.warning_amber_rounded,
      ),
      _Expiry.critical => (
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        Icons.warning_amber_rounded,
      ),
      _Expiry.warning => (
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
        Icons.schedule_outlined,
      ),
      _Expiry.ok => (
        const Color(0xFFF0FDF4),
        const Color(0xFF16A34A),
        Icons.check_circle_outline,
      ),
      _Expiry.none => (
        Colors.transparent,
        AppColors.mutedText,
        Icons.circle_outlined,
      ),
    };

    final days = _daysUntil(date);
    final text = status == _Expiry.expired
        ? '$label expired'
        : '$label ${days}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static _Expiry _expiryStatus(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0) return _Expiry.expired;
      if (days <= 7) return _Expiry.critical;
      if (days <= 30) return _Expiry.warning;
      return _Expiry.ok;
    } catch (_) {
      return _Expiry.none;
    }
  }

  static int _daysUntil(String dateStr) {
    try {
      return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }
}

enum _Expiry { expired, critical, warning, ok, none }
