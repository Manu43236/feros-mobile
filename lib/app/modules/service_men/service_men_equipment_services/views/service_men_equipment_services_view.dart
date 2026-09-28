import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../controllers/service_men_equipment_services_controller.dart';
import 'service_men_equipment_service_detail_view.dart';

class ServiceMenEquipmentServicesView extends StatelessWidget {
  const ServiceMenEquipmentServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ServiceMenEquipmentServicesController>();
    const filters = ['ALL', 'OPEN', 'IN_PROGRESS', 'COMPLETED'];
    const filterLabels = {'ALL': 'All', 'OPEN': 'Open', 'IN_PROGRESS': 'In Progress', 'COMPLETED': 'Completed'};

    return Obx(() {
      return Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final selected = ctrl.filter.value == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ctrl.filter.value = f,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.navy : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.navy : AppColors.border),
                        ),
                        child: Text(
                          filterLabels[f]!,
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.bodyText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ctrl.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: ctrl.fetchServices,
                    child: ctrl.filteredServices.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Icon(Icons.build_outlined, size: 48, color: AppColors.mutedText.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Center(child: Text('No equipment services', style: AppTextStyles.body.copyWith(color: AppColors.mutedText))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: ctrl.filteredServices.length,
                            itemBuilder: (_, i) => _ServiceCard(service: ctrl.filteredServices[i], ctrl: ctrl),
                          ),
                  ),
          ),
        ],
      );
    });
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final ServiceMenEquipmentServicesController ctrl;
  const _ServiceCard({required this.service, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final status = service['status'] as String? ?? 'OPEN';
    final tasks = (service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = service['totalCost'];
    return GestureDetector(
      onTap: () => Get.to(() => ServiceMenEquipmentServiceDetailView(service: service, ctrl: ctrl)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(service['serviceNumber']?.toString() ?? '—',
                      style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.navy)),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 4),
            Text(service['equipmentName']?.toString() ?? service['equipmentIdentifier']?.toString() ?? '',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: tasks.take(4).map((t) {
                  final name = t['displayName'] ?? t['customName'] ?? t['taskTypeName'] ?? '—';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Text('$name', style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
                  );
                }).toList(),
              ),
            ],
            if (total != null && (total as num) > 0) ...[
              const SizedBox(height: 8),
              Text('₹${(total).toStringAsFixed(0)}',
                  style: AppTextStyles.bodySemiBold.copyWith(color: const Color(0xFF15803D))),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _statusChip(String status) {
  final map = {
    'OPEN': (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), 'Open'),
    'IN_PROGRESS': (const Color(0xFFFFF7ED), const Color(0xFFC2410C), 'In Progress'),
    'COMPLETED': (const Color(0xFFF0FDF4), const Color(0xFF15803D), 'Completed'),
  };
  final c = map[status] ?? (AppColors.background, AppColors.mutedText, status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(c.$3, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: c.$2)),
  );
}
