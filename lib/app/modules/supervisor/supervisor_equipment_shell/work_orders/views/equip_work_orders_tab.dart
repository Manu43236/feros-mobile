import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/view_state.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../controllers/equip_work_orders_controller.dart';
import '../controllers/equip_work_order_detail_controller.dart';
import 'equip_work_order_detail_view.dart';

class EquipWorkOrdersTab extends GetView<EquipWorkOrdersController> {
  const EquipWorkOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: _StatusFilterBar(controller: controller),
        ),
        Expanded(
          child: Obx(() {
            if (controller.state.value == ViewState.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.equipSidebar),
              );
            }
            if (controller.state.value == ViewState.error) {
              return _ErrorState(onRetry: controller.fetchAll);
            }
            final list = controller.workOrders;
            if (list.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              color: AppColors.equipSidebar,
              onRefresh: controller.fetchAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => _WoCard(wo: list[i]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Status Filter Bar ─────────────────────────────────────────────────────────
class _StatusFilterBar extends StatelessWidget {
  final EquipWorkOrdersController controller;
  const _StatusFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedStatus.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: EquipWorkOrdersController.statuses.map((s) {
            final isActive = s == selected;
            final label = EquipWorkOrdersController.statusLabels[s] ?? s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.selectStatus(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.equipSidebar : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.equipSidebar : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? Colors.white : AppColors.mutedText,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

// ── WO Card ───────────────────────────────────────────────────────────────────
class _WoCard extends StatelessWidget {
  final Map<String, dynamic> wo;
  const _WoCard({required this.wo});

  void _openDetail() {
    final id = wo['id'];
    if (id == null) return;
    Get.to(
      () => const EquipWorkOrderDetailView(),
      binding: BindingsBuilder(
          () { Get.put(EquipWorkOrderDetailController()); }),
      arguments: id is int ? id : int.tryParse(id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final woNumber     = wo['woNumber']     as String? ?? '—';
    final clientName   = wo['clientName']   as String? ?? '—';
    final site         = wo['site']         as String? ?? '';
    final status       = wo['status']       as String? ?? '';
    final machineCount = wo['machineCount'] as int?    ?? 0;
    final startDate    = wo['startDate']    as String?;
    final endDate      = wo['endDate']      as String?;
    final woType       = wo['workOrderType'] as String? ?? '';

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WO number + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      woNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.equipSidebar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _WoStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 4),
              // Client + site
              Text(
                site.isNotEmpty ? '$clientName · $site' : clientName,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              // Machine count + type + dates
              Row(
                children: [
                  const Icon(Icons.construction_outlined,
                      size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    '$machineCount machine${machineCount == 1 ? '' : 's'}${woType.isNotEmpty ? '  ·  ${_woTypeLabel(woType)}' : ''}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                  const Spacer(),
                  if (startDate != null) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Text(
                      '${FerosDateUtils.formatShortDate(startDate)} – ${FerosDateUtils.formatShortDate(endDate)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _woTypeLabel(String t) {
    switch (t) {
      case 'RENTAL': return 'Rental';
      case 'JOB':    return 'Job';
      default:       return t;
    }
  }
}

// ── WO Status Badge ───────────────────────────────────────────────────────────
class _WoStatusBadge extends StatelessWidget {
  final String status;
  const _WoStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final label = _label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'DRAFT':       return const Color(0xFF94A3B8); // slate
      case 'CONFIRMED':   return const Color(0xFF2563EB); // blue
      case 'IN_PROGRESS': return const Color(0xFFF97316); // orange
      case 'COMPLETED':   return const Color(0xFF16A34A); // green
      case 'INVOICED':    return const Color(0xFF7C3AED); // purple
      case 'CANCELLED':   return const Color(0xFFDC2626); // red
      default:            return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'DRAFT':       return 'Draft';
      case 'CONFIRMED':   return 'Confirmed';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED':   return 'Completed';
      case 'INVOICED':    return 'Invoiced';
      case 'CANCELLED':   return 'Cancelled';
      default:            return s;
    }
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined,
              size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No work orders found',
              style:
                  AppTextStyles.heading4.copyWith(color: AppColors.equipSidebar)),
          const SizedBox(height: 6),
          Text('Try a different status filter',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load work orders',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.equipSidebar,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
