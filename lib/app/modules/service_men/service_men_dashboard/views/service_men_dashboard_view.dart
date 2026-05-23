import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../../../../../core/utils/status_utils.dart';
import '../controllers/service_men_dashboard_controller.dart';
import '../../service_men_services/views/service_men_service_detail_view.dart';
import '../../../driver/driver_shell/controllers/driver_shell_controller.dart';

class ServiceMenDashboardView extends GetView<ServiceMenDashboardController> {
  const ServiceMenDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ShimmerList(count: 5);
      }
      return RefreshIndicator(
        onRefresh: controller.fetchAll,
        color: AppColors.navy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Stats Row ─────────────────────────────────────
            Row(
              children: [
                _StatCard(
                  label: 'status_open'.tr,
                  value: controller.openCount,
                  icon: Icons.build_outlined,
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'status_in_progress'.tr,
                  value: controller.inProgressCount,
                  icon: Icons.settings_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Active Service Card ───────────────────────────
            if (controller.activeService != null) ...[
              _SectionTitle('lbl_active_service'.tr),
              const SizedBox(height: 10),
              _ActiveServiceCard(
                service: controller.activeService!,
                onTap: () => Get.to(() => ServiceMenServiceDetailView(
                      service: controller.activeService!,
                    )),
              ),
              const SizedBox(height: 20),
            ],

            // ── Quick Actions ─────────────────────────────────
            _SectionTitle('lbl_quick_actions'.tr),
            const SizedBox(height: 10),
            Row(
              children: [
                _QuickAction(
                  label: 'lbl_services'.tr,
                  icon: Icons.build_outlined,
                  color: AppColors.navy,
                  onTap: () => Get.find<DriverShellController>().onTabTapped(1),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  label: 'lbl_tyre_work'.tr,
                  icon: Icons.tire_repair_outlined,
                  color: const Color(0xFF7C3AED),
                  onTap: () => Get.find<DriverShellController>().onTabTapped(2),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  label: 'lbl_breakdowns'.tr,
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.error,
                  onTap: () => Get.find<DriverShellController>().onTabTapped(3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── All Services Summary ──────────────────────────
            if (controller.services.isNotEmpty) ...[
              _SectionTitle('lbl_recent_services'.tr),
              const SizedBox(height: 10),
              ...controller.services.take(5).map((s) => _ServiceCard(
                    service: s,
                    onTap: () => Get.to(() => ServiceMenServiceDetailView(service: s)),
                  )),
            ] else
              _EmptyState(),
          ],
        ),
      );
    });
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.navy)),
                Text(label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Service Card ───────────────────────────────────────────────────────
class _ActiveServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _ActiveServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['vehicleRegistrationNumber'] ?? '—',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service['serviceNumber'] ?? ''} · ${(service['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('status_in_progress'.tr,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = service['status'] as String? ?? 'OPEN';
    final color = status == 'COMPLETED'
        ? AppColors.success
        : status == 'IN_PROGRESS'
            ? AppColors.warning
            : AppColors.info;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['vehicleRegistrationNumber'] ?? '—',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service['serviceNumber'] ?? ''} · ${(service['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel(status),
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.navy, fontWeight: FontWeight.w700));
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.build_outlined, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('lbl_no_services_assigned'.tr,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}
