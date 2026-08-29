import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../vehicle_leases/controllers/vehicle_leases_controller.dart';
import '../../../../vehicle_leases/views/vehicle_lease_detail_view.dart';

// ponytail: thin tab wrapper — reuses VehicleLeasesController + VehicleLeaseDetailView
class EquipLeasesTab extends GetView<VehicleLeasesController> {
  const EquipLeasesTab({super.key});

  static const _statuses = ['ALL', 'DRAFT', 'ACTIVE', 'CLOSED'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Status filter chips ──────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _statuses.map((s) {
                    final active = controller.statusFilter.value == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => controller.onStatusChanged(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.equipSidebar
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.equipSidebar
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            s == 'ALL' ? 'All' : _statusLabel(s),
                            style: AppTextStyles.caption.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppColors.mutedText,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )),
        ),

        // ── List ────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.equipSidebar));
            }
            if (controller.leases.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key_off_outlined,
                        size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    Text('No leases found',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText)),
                  ],
                ),
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >=
                    n.metrics.maxScrollExtent - 200) {
                  controller.loadMore();
                }
                return false;
              },
              child: RefreshIndicator(
                color: AppColors.equipSidebar,
                onRefresh: controller.fetchLeases,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.leases.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == controller.leases.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.equipSidebar)),
                      );
                    }
                    final lease = controller.leases[i];
                    return _LeaseCard(
                      lease: lease,
                      onTap: () => Get.to(
                        () => const VehicleLeaseDetailView(),
                        arguments: lease['id'],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _statusLabel(String s) => switch (s) {
        'DRAFT'  => 'Draft',
        'ACTIVE' => 'Active',
        'CLOSED' => 'Closed',
        _        => s,
      };
}

// ── Lease Card (same as vehicle_leases_view but accent = equipSidebar) ────────
class _LeaseCard extends StatelessWidget {
  final Map<String, dynamic> lease;
  final VoidCallback onTap;
  const _LeaseCard({required this.lease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status       = lease['status'] as String? ?? '';
    final vehicleCount = (lease['vehicleCount'] as num?)?.toInt() ?? 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lease['leaseNumber'] as String? ?? '—',
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: AppColors.equipSidebar),
                  ),
                ),
                _StatusBadge(status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lease['clientName'] as String? ?? '—',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedText),
            ),
            if (lease['site'] != null &&
                (lease['site'] as String).isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                lease['site'] as String,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  '$vehicleCount vehicle${vehicleCount == 1 ? '' : 's'}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  FerosDateUtils.formatDate(
                      lease['startDate'] as String?),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
                if (lease['endDate'] != null)
                  Text(
                    ' – ${FerosDateUtils.formatDate(lease['endDate'] as String?)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'ACTIVE' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'DRAFT'  => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
      'CLOSED' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _        => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status[0] + status.substring(1).toLowerCase(),
        style: AppTextStyles.caption
            .copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
