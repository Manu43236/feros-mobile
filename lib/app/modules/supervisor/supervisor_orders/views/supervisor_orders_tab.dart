import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/supervisor_orders_controller.dart';

class SupervisorOrdersTab extends GetView<SupervisorOrdersController> {
  const SupervisorOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.state.value == ViewState.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.navy));
            }
            if (controller.state.value == ViewState.error) {
              return _ErrorState(onRetry: controller.fetchOrders);
            }
            final list = controller.orders;
            if (list.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              color: AppColors.navy,
              onRefresh: controller.fetchOrders,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => _OrderCard(order: list[i]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final SupervisorOrdersController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Obx(() {
        final selected = controller.selectedFilter.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: SupervisorOrdersController.filters.map((f) {
              final isActive = f == selected;
              final label = SupervisorOrdersController.filterLabels[f] ?? f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.navy : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.navy : AppColors.border,
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
      }),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status     = order['orderStatus'] as String? ?? '';
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    final clientName   = order['clientName']         as String? ?? '—';
    final orderNumber  = order['orderNumber']         as String? ?? '—';
    final fromCity     = order['sourceCityName']      as String? ?? '—';
    final toCity       = order['destinationCityName'] as String? ?? '—';
    final material     = order['materialTypeName']    as String? ?? '—';
    final weight       = order['totalWeight'];
    final deliveryDate = order['expectedDeliveryDate'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: order number + status ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),

            // ── Client ──────────────────────────────────────────
            Text(
              clientName,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // ── Route ───────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.circle, size: 7, color: AppColors.navy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fromCity,
                    style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(width: 1, height: 10, color: AppColors.border),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.orange),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    toCity,
                    style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // ── Row 3: material + weight + ETA ──────────────────
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    weight != null ? '$material · ${weight}T' : material,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (deliveryDate != null) ...[
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    FerosDateUtils.formatDate(deliveryDate),
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':             return AppColors.orderPending;
      case 'PARTIALLY_ASSIGNED':  return AppColors.info;
      case 'FULLY_ASSIGNED':      return AppColors.lrLoaded;
      case 'IN_TRANSIT':          return AppColors.lrInTransit;
      case 'PARTIALLY_DELIVERED': return AppColors.warning;
      case 'DELIVERED':           return AppColors.orderCompleted;
      case 'CANCELLED':           return AppColors.orderCancelled;
      default:                    return AppColors.mutedText;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':             return 'Pending';
      case 'PARTIALLY_ASSIGNED':  return 'Part. Assigned';
      case 'FULLY_ASSIGNED':      return 'Assigned';
      case 'IN_TRANSIT':          return 'In Transit';
      case 'PARTIALLY_DELIVERED': return 'Part. Delivered';
      case 'DELIVERED':           return 'Delivered';
      case 'CANCELLED':           return 'Cancelled';
      default:                    return status;
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No orders found', style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Text('Try a different filter', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
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
          Text('Failed to load orders', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
