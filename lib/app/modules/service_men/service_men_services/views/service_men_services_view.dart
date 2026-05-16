import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../controllers/service_men_services_controller.dart';
import 'service_men_service_detail_view.dart';

class ServiceMenServicesView extends GetView<ServiceMenServicesController> {
  const ServiceMenServicesView({super.key});

  static const _filters = ['ALL', 'OPEN', 'IN_PROGRESS', 'COMPLETED'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // ── Filter Chips ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final active = controller.filter.value == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.filter.value = f,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.navy : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f.replaceAll('_', ' '),
                          style: AppTextStyles.caption.copyWith(
                            color: active ? Colors.white : AppColors.mutedText,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: controller.isLoading.value
                ? const ShimmerList(count: 6)
                : RefreshIndicator(
                    onRefresh: controller.fetchServices,
                    color: AppColors.navy,
                    child: controller.filteredServices.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.build_outlined,
                                        size: 48,
                                        color: AppColors.mutedText),
                                    const SizedBox(height: 12),
                                    Text('No services found',
                                        style: AppTextStyles.body.copyWith(
                                            color: AppColors.mutedText)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.filteredServices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = controller.filteredServices[i];
                              return _ServiceCard(
                                service: s,
                                onTap: () => Get.to(() =>
                                    ServiceMenServiceDetailView(service: s)),
                              );
                            },
                          ),
                  ),
          ),
        ],
      );
    });
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
    final displayStatus = service['displayStatus'] as String? ?? status;
    final statusColor = _statusColor(displayStatus);
    final tasks = (service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final completedTasks = tasks.where((t) => t['status'] == 'COMPLETED').length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service['vehicleRegistrationNumber'] ?? '—',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayStatus.replaceAll('_', ' '),
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${service['serviceNumber'] ?? ''} · ${(service['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tasks.isEmpty ? 0 : completedTasks / tasks.length,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.success,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedTasks / ${tasks.length} tasks done',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'OVERDUE':
        return AppColors.error;
      case 'DUE_SOON':
        return const Color(0xFFF97316);
      default:
        return AppColors.info;
    }
  }
}
