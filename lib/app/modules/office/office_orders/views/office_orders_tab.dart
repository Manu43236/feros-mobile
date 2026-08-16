import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/office_orders_controller.dart';
import '../views/office_order_form_view.dart';

// Reuse supervisor order detail (assign/unassign/LR/PDF all work for office)
import '../../../supervisor/supervisor_orders/controllers/supervisor_order_detail_controller.dart';
import '../../../supervisor/supervisor_orders/views/supervisor_order_detail_view.dart';

class OfficeOrdersTab extends GetView<OfficeOrdersController> {
  const OfficeOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = ScrollController();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                _SearchBar(controller: controller),
                _FilterBar(controller: controller),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.state.value == ViewState.loading) {
                return const _OrderListSkeleton();
              }
              if (controller.state.value == ViewState.error) {
                return _ErrorState(
                    onRetry: () => controller.fetchOrders(reset: true));
              }
              final list = controller.orders;
              if (list.isEmpty) return const _EmptyState();
              return RefreshIndicator(
                color: AppColors.navy,
                onRefresh: () => controller.fetchOrders(reset: true),
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: list.length + (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == list.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.navy, strokeWidth: 2),
                        ),
                      );
                    }
                    return _OfficeOrderCard(order: list[i]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Order',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        onPressed: () => Get.to(() => const OfficeOrderFormView()),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final OfficeOrdersController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: controller.onSearch,
        style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
        decoration: InputDecoration(
          hintText: 'Search by order no., client, city...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.mutedText, size: 20),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Filter Bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final OfficeOrdersController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Obx(() {
        final selected = controller.selectedFilters;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: OfficeOrdersController.filters.map((f) {
              final isActive = selected.contains(f);
              final label   = OfficeOrdersController.filterLabels[f] ?? f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.toggleFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppColors.navy : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isActive ? AppColors.navy : AppColors.border,
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.mutedText,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
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

// ── Office Order Card ──────────────────────────────────────────────────────────
class _OfficeOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OfficeOrderCard({required this.order});

  void _openDetail() {
    final id = order['id'];
    if (id == null) return;
    Get.to(
      () => const SupervisorOrderDetailView(),
      binding: BindingsBuilder(() {
        Get.put(SupervisorOrderDetailController());
      }),
      arguments: id is int ? id : int.tryParse(id.toString()),
    );
  }

  void _openEdit() {
    final id = order['id'];
    if (id == null) return;
    Get.to(() => OfficeOrderFormView(
          editOrderId: id is int ? id : int.tryParse(id.toString()),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final status      = order['orderStatus']         as String? ?? '';
    final orderNumber = order['orderNumber']         as String? ?? '—';
    final clientName  = order['clientName']          as String? ?? '—';
    final fromCity    = order['sourceCityName']      as String? ?? '—';
    final toCity      = order['destinationCityName'] as String? ?? '—';
    final material    = order['materialTypeName']    as String? ?? '—';
    final weight      = order['totalWeight'];
    final deliveryDate= order['expectedDeliveryDate'] as String?;
    final isPending   = status == 'PENDING';

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order number + status + edit ────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      orderNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: status),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openEdit,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 15, color: AppColors.navy),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // ── Client ──────────────────────────────────────────
              Text(
                clientName,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedText),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Route ───────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.radio_button_checked,
                      size: 14, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(fromCity,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.bodyText),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      size: 14, color: AppColors.mutedText),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(toCity,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.bodyText),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // ── Material + weight + ETA ──────────────────────────
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      weight != null
                          ? '$material · ${weight}T'
                          : material,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (deliveryDate != null) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Text(
                      FerosDateUtils.formatDate(deliveryDate),
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
}

// ── Status Badge ───────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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
      case 'PENDING':             return const Color(0xFFF59E0B);
      case 'PARTIALLY_ASSIGNED':  return const Color(0xFF2563EB);
      case 'FULLY_ASSIGNED':      return const Color(0xFF7C3AED);
      case 'IN_TRANSIT':          return const Color(0xFFF97316);
      case 'PARTIALLY_DELIVERED': return const Color(0xFF0EA5E9);
      case 'DELIVERED':           return const Color(0xFF16A34A);
      case 'COMPLETED':           return const Color(0xFF059669);
      case 'CANCELLED':           return const Color(0xFFDC2626);
      default:                    return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'PENDING':             return 'Pending';
      case 'PARTIALLY_ASSIGNED':  return 'Part. Assigned';
      case 'FULLY_ASSIGNED':      return 'Assigned';
      case 'IN_TRANSIT':          return 'In Transit';
      case 'PARTIALLY_DELIVERED': return 'Part. Delivered';
      case 'DELIVERED':           return 'Delivered';
      case 'COMPLETED':           return 'Completed';
      case 'CANCELLED':           return 'Cancelled';
      default:                    return s;
    }
  }
}

// ── List Skeleton ──────────────────────────────────────────────────────────────
class _OrderListSkeleton extends StatelessWidget {
  const _OrderListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Container(height: 14, width: 120,
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(4)))),
              Container(height: 24, width: 80,
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
            ]),
            const SizedBox(height: 8),
            Container(height: 12, width: 160,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(height: 12, width: double.infinity,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 12, width: 200,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
          ]),
        ),
      ),
    );
  }
}

// ── Empty / Error States ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined,
              size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No orders found',
              style:
                  AppTextStyles.heading4.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Text('Try a different filter or search',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedText)),
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
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load orders',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
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
