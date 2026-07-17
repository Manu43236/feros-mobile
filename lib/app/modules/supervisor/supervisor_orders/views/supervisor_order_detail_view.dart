import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/widgets/feros_select_field.dart';
import '../controllers/supervisor_order_detail_controller.dart';
import '../../supervisor_lrs/controllers/supervisor_lr_detail_controller.dart';
import '../../supervisor_lrs/views/supervisor_lr_detail_view.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicle_detail_binding.dart';
import '../../supervisor_vehicles/views/supervisor_vehicle_detail_view.dart';

class SupervisorOrderDetailView
    extends GetView<SupervisorOrderDetailController> {
  const SupervisorOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
          );
        }
        if (controller.state.value == ViewState.error) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
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
                    'Failed to load order',
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
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final o = controller.order.value!;
        final _orderStatus = o['orderStatus'] as String? ?? '';
        final _remaining = (o['remainingWeight'] as num?)?.toDouble() ?? 0.0;
        final _canAssignOrder = !const ['DELIVERED', 'CANCELLED', 'COMPLETED']
                .contains(_orderStatus) &&
            _remaining > 0;
        return DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) {
              final tabCtrl = DefaultTabController.of(tabContext);
              return AnimatedBuilder(
                animation: tabCtrl,
                builder: (_, __) => Scaffold(
                  backgroundColor: AppColors.background,
                  bottomNavigationBar: (_canAssignOrder && tabCtrl.index == 0)
                      ? Container(
                          padding: EdgeInsets.fromLTRB(
                            16, 12, 16,
                            12 + MediaQuery.of(tabContext).padding.bottom,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(top: BorderSide(color: AppColors.border)),
                          ),
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                controller.fetchVehicles();
                                showModalBottomSheet(
                                  context: tabContext,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _AssignVehicleSheet(
                                    controller: controller,
                                    remainingWeight: _remaining,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Assign Vehicle',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        )
                      : null,
                  body: Column(
              children: [
                // Sticky banner
                _OrderBanner(order: o, controller: controller),
                // Sticky tab bar
                Container(
                  color: AppColors.surface,
                  child: const TabBar(
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.mutedText,
                    indicatorColor: AppColors.navy,
                    indicatorWeight: 2.5,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Vehicles'),
                      Tab(text: 'LRs'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AssignmentsTab(order: o, controller: controller),
                      _LrsTab(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────
class _OrderBanner extends StatelessWidget {
  final Map<String, dynamic> order;
  final SupervisorOrderDetailController controller;
  const _OrderBanner({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final orderNumber = order['orderNumber'] as String? ?? '—';
    final clientName = order['clientName'] as String? ?? '—';
    final status = order['orderStatus'] as String? ?? '';
    final payStatus = order['orderPaymentStatus'] as String? ?? '';
    final fromCity = order['sourceCityName'] as String? ?? '—';
    final toCity = order['destinationCityName'] as String? ?? '—';
    final totalWeight = order['totalWeight'];
    final weightFulfilled = order['totalWeightFulfilled'];
    final remaining = order['remainingWeight'];
    final orderDate = order['orderDate'] as String?;
    final eta = order['expectedDeliveryDate'] as String?;

    final statusColor = _orderColor(status);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),

                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _orderLabel(status),
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => GestureDetector(
                    onTap: controller.isShareingPdf.value
                        ? null
                        : controller.shareOrderPdf,
                    child: controller.isShareingPdf.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                clientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '#${orderNumber.toLowerCase()}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    size: 12,
                    color: Color(0xFF93C5FD),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fromCity,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: Color(0xFF93C5FD),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: Color(0xFFFB923C),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      toCity,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (totalWeight != null)
                      _BannerChip(
                        icon: Icons.scale_outlined,
                        label: '${totalWeight}T total',
                        sub: weightFulfilled != null
                            ? '${weightFulfilled}T done'
                            : null,
                      ),
                    if (remaining != null &&
                        double.tryParse(remaining.toString())! > 0)
                      _BannerChip(
                        icon: Icons.pending_outlined,
                        label: '${remaining}T left',
                      ),
                    if (orderDate != null)
                      _BannerChip(
                        icon: Icons.calendar_today_outlined,
                        label: FerosDateUtils.formatDate(orderDate),
                        sub: 'Order date',
                      ),
                    if (eta != null)
                      _BannerChip(
                        icon: Icons.local_shipping_outlined,
                        label: FerosDateUtils.formatDate(eta),
                        sub: 'Expected ETA',
                      ),
                    _BannerChip(
                      icon: Icons.payments_outlined,
                      label: _paymentLabel(payStatus),
                      color: _paymentColor(payStatus),
                    ),
                  ],
                ),
              ),
              // ── Status action buttons ──────────────────────────
              Obx(() {
                final isLoading = controller.isUpdatingStatus.value;
                final nextStatuses = _nextStatuses(status);
                if (nextStatuses.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: nextStatuses.map((s) {
                      final isDestructive = s == 'CANCELLED';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: s == nextStatuses.last ? 0 : 8,
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => s == 'DELIVERED'
                                    ? controller.forceDeliver()
                                    : controller.updateStatus(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDestructive
                                  ? AppColors.error
                                  : AppColors.orange,
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
                                    _statusActionLabel(s),
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _nextStatuses(String s) {
    switch (s) {
      case 'IN_TRANSIT':
      case 'PARTIALLY_DELIVERED':
        return ['DELIVERED'];
      default:
        return [];
    }
  }

  String _statusActionLabel(String s) {
    switch (s) {
      case 'ACTIVE':
        return 'Activate';
      case 'DELIVERED':
        return 'Mark Delivered';
      case 'CANCELLED':
        return 'Cancel Order';
      default:
        return s;
    }
  }

  Color _orderColor(String s) {
    switch (s) {
      case 'PENDING':
        return const Color(0xFFFBBF24);
      case 'PARTIALLY_ASSIGNED':
        return const Color(0xFF60A5FA);
      case 'FULLY_ASSIGNED':
        return const Color(0xFFA78BFA);
      case 'IN_TRANSIT':
        return const Color(0xFFFB923C);
      case 'PARTIALLY_DELIVERED':
        return const Color(0xFFFCD34D);
      case 'DELIVERED':
        return const Color(0xFF4ADE80);
      case 'CANCELLED':
        return const Color(0xFFF87171);
      default:
        return Colors.white;
    }
  }

  String _orderLabel(String s) {
    switch (s) {
      case 'PENDING':
        return 'Pending';
      case 'PARTIALLY_ASSIGNED':
        return 'Part. Assigned';
      case 'FULLY_ASSIGNED':
        return 'Assigned';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'PARTIALLY_DELIVERED':
        return 'Part. Delivered';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'PAID':
        return const Color(0xFF4ADE80);
      case 'PARTIAL':
        return const Color(0xFFFCD34D);
      default:
        return const Color(0xFFF87171);
    }
  }

  String _paymentLabel(String s) {
    switch (s) {
      case 'PAID':
        return 'Paid';
      case 'PARTIAL':
        return 'Part. Paid';
      default:
        return 'Unpaid';
    }
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color? color;
  const _BannerChip({
    required this.icon,
    required this.label,
    this.sub,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.9);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Assignments Tab ───────────────────────────────────────────────────────────
class _AssignmentsTab extends StatelessWidget {
  final Map<String, dynamic> order;
  final SupervisorOrderDetailController controller;
  const _AssignmentsTab({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final allocations =
        (order['vehicleAllocations'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _OrderSummaryRow(order: order),
              const SizedBox(height: 4),
              if (allocations.isEmpty)
                SizedBox(height: 180, child: _buildEmpty()),
              ...allocations.map(
                (a) => _AllocationCard(allocation: a, controller: controller),
              ),
              _AdditionalDetailsCard(order: order),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: AppColors.mutedText,
          ),
          SizedBox(height: 12),
          Text(
            'No vehicles assigned',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Allocation Card ───────────────────────────────────────────────────────────
class _AllocationCard extends StatelessWidget {
  final Map<String, dynamic> allocation;
  final SupervisorOrderDetailController controller;
  const _AllocationCard({required this.allocation, required this.controller});

  @override
  Widget build(BuildContext context) {
    final allocationId = allocation['id'] as int? ?? 0;
    final vehicleId = allocation['vehicleId'] as int?;
    final vehicle = allocation['vehicleRegistrationNumber'] as String? ?? '—';
    final type = allocation['vehicleTypeName'] as String?;
    final weight = allocation['allocatedWeight'];
    final status = allocation['allocationStatus'] as String? ?? '';
    final loadDate = allocation['expectedLoadDate'] as String?;
    final delivDate = allocation['expectedDeliveryDate'] as String?;
    final driverId   = allocation['currentDriverId']   as int?;
    final driverName = allocation['currentDriverName'] as String?;
    final cleanerId  = allocation['currentCleanerId']  as int?;
    final cleanerName = allocation['currentCleanerName'] as String?;
    final isLocked = status == 'IN_TRANSIT' || status == 'DELIVERED';

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          GestureDetector(
            onTap: vehicleId == null
                ? null
                : () => Get.to(
                    () => const SupervisorVehicleDetailView(),
                    binding: SupervisorVehicleDetailBinding(),
                    arguments: vehicleId,
                  ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (type != null)
                          Text(
                            type,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (vehicleId != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                  // ── Unassign button (hidden when trip active) ────────
                  if (!isLocked) ...[
                    const SizedBox(width: 4),
                    Obx(() {
                      final isUnassigning =
                          controller.unassigningId.value == allocationId;
                      if (isUnassigning) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () async {
                          final confirmed = await FerosDialog.confirm(
                            title: 'Unassign Vehicle',
                            message: 'Remove $vehicle from this order?',
                            confirmText: 'Unassign',
                            isDestructive: true,
                          );
                          if (confirmed) {
                            controller.unassignVehicle(allocationId);
                          }
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // ── Breakdown banner ───────────────────────────────────────
          Obx(() {
            final bd = controller.breakdowns[allocationId];
            if (bd == null) return const SizedBox.shrink();
            return _BreakdownBanner(
              allocationId: allocationId,
              breakdown: bd,
              controller: controller,
              onReplace: () => _openReplaceVehicleSheet(context, allocationId, bd),
            );
          }),

          // ── Body ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (weight != null)
                      _InfoChip(Icons.scale_outlined, '${weight}T'),
                    if (loadDate != null)
                      _InfoChip(
                        Icons.upload_outlined,
                        'Load: ${FerosDateUtils.formatDate(loadDate)}',
                      ),
                    if (delivDate != null)
                      _InfoChip(
                        Icons.download_outlined,
                        'ETA: ${FerosDateUtils.formatDate(delivDate)}',
                      ),
                  ],
                ),
                if (driverId != null || cleanerId != null || !_isClosed(status)) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Staff',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!_isClosed(status)) ...[
                        _StaffButton(
                          label: driverId != null ? '↺ Driver' : '+ Driver',
                          onTap: () => _openAssignStaffSheet(
                            context,
                            vehicleId ?? 0,
                            'DRIVER',
                            'Driver',
                            isSwap: driverId != null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StaffButton(
                          label: cleanerId != null ? '↺ Cleaner' : '+ Cleaner',
                          onTap: () => _openAssignStaffSheet(
                            context,
                            vehicleId ?? 0,
                            'CLEANER',
                            'Cleaner',
                            isSwap: cleanerId != null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (driverId != null || cleanerId != null) ...[
                    const SizedBox(height: 8),
                    if (driverId != null)
                      _StaffRow(
                        name: driverName ?? '—',
                        role: 'DRIVER',
                        vehicleId: vehicleId ?? 0,
                        controller: controller,
                        locked: isLocked,
                      ),
                    if (cleanerId != null)
                      _StaffRow(
                        name: cleanerName ?? '—',
                        role: 'CLEANER',
                        vehicleId: vehicleId ?? 0,
                        controller: controller,
                        locked: isLocked,
                      ),
                  ],
                ],

                // ── Create LR button ──────────────────────────────────
                // Show when: driver assigned + no LR yet + not closed
                if (driverId != null && !_isClosed(status))
                  Obx(() {
                    final hasLr = controller.lrs.any((lr) {
                      final id = lr['vehicleAllocationId'];
                      final lrStatus = lr['lrStatus'] as String? ?? '';
                      return id != null &&
                          lrStatus != 'CANCELLED' &&
                          (id == allocationId ||
                              id.toString() == allocationId.toString());
                    });
                    if (hasLr) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openCreateLrSheet(context, allocationId),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Create LR',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.navy),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                // ── Report Breakdown button ────────────────────────────
                // Show when IN_TRANSIT and no active breakdown
                if (status == 'IN_TRANSIT')
                  Obx(() {
                    final hasBreakdown = controller.breakdowns[allocationId] != null;
                    if (hasBreakdown) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openReportBreakdownSheet(context, allocationId, vehicle),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          label: const Text(
                            'Report Breakdown',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReportBreakdownSheet(
      BuildContext context, int allocationId, String vehicleReg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportBreakdownSheet(
        controller: controller,
        allocationId: allocationId,
        vehicleReg: vehicleReg,
      ),
    );
  }

  void _openReplaceVehicleSheet(
      BuildContext context, int allocationId, Map<String, dynamic> breakdown) {
    controller.fetchVehicles();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplaceVehicleSheet(
        controller: controller,
        breakdown: breakdown,
      ),
    );
  }

  void _openCreateLrSheet(BuildContext context, int allocationId) {
    final allocWeight = allocation['allocatedWeight'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateLrSheet(
        allocationId: allocationId,
        controller: controller,
        allocatedWeight: allocWeight,
      ),
    );
  }

  bool _isClosed(String s) => s == 'DELIVERED' || s == 'CANCELLED';

  void _openAssignStaffSheet(
    BuildContext context,
    int vehicleId,
    String role,
    String roleLabel, {
    bool isSwap = false,
  }) {
    controller.fetchStaff();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignStaffSheet(
        controller: controller,
        vehicleId: vehicleId,
        role: role,
        roleLabel: roleLabel,
        isSwap: isSwap,
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':
        return AppColors.orderPending;
      case 'ASSIGNED':
        return AppColors.info;
      case 'IN_TRANSIT':
        return AppColors.lrInTransit;
      case 'DELIVERED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.mutedText;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING':
        return 'Pending';
      case 'ASSIGNED':
        return 'Assigned';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }
}

// ── Staff Row ─────────────────────────────────────────────────────────────────
class _StaffRow extends StatelessWidget {
  final String name;
  final String role;
  final int vehicleId;
  final SupervisorOrderDetailController controller;
  final bool locked;
  const _StaffRow({
    required this.name,
    required this.role,
    required this.vehicleId,
    required this.controller,
    this.locked = false,
  });

  String get _roleLabel => role == 'DRIVER' ? 'Driver' : 'Cleaner';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                ),
                Text(
                  _roleLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (!locked)
            Obx(() {
              final isUnassigning = role == 'DRIVER'
                  ? controller.isUnassigningDriver.value
                  : controller.isUnassigningCleaner.value;
              if (isUnassigning) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                );
              }
              return GestureDetector(
                onTap: () async {
                  final confirmed = await FerosDialog.confirm(
                    title: 'Unassign $_roleLabel',
                    message: 'Remove $name from this vehicle?',
                    confirmText: 'Unassign',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    if (role == 'DRIVER') {
                      controller.unassignDriver(vehicleId);
                    } else {
                      controller.unassignCleaner(vehicleId);
                    }
                  }
                },
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Staff chip button ─────────────────────────────────────────────────────────
class _StaffButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StaffButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Assign Vehicle Bottom Sheet ───────────────────────────────────────────────
class _AssignVehicleSheet extends StatefulWidget {
  final SupervisorOrderDetailController controller;
  final dynamic remainingWeight;
  const _AssignVehicleSheet({required this.controller, this.remainingWeight});

  @override
  State<_AssignVehicleSheet> createState() => _AssignVehicleSheetState();
}

class _AssignVehicleSheetState extends State<_AssignVehicleSheet> {
  Map<String, dynamic>? _selectedVehicle;
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime? _loadDate, _delivDate;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final rw = widget.remainingWeight;
    if (rw != null) {
      _weightCtrl.text = rw.toString();
      _weightCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _weightCtrl.text.length,
      );
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final e = <String, String>{};
    if (_selectedVehicle == null) e['vehicle'] = 'Select a vehicle';
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w == null || w <= 0) e['weight'] = 'Enter a valid weight';
    setState(() {
      _errors.clear();
      _errors.addAll(e);
    });
    return e.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final success = await widget.controller.assignVehicle(
      vehicleId: _selectedVehicle!['id'] as int,
      allocatedWeight: double.parse(_weightCtrl.text.trim()),
      expectedLoadDate: _loadDate?.toIso8601String().substring(0, 10),
      expectedDeliveryDate: _delivDate?.toIso8601String().substring(0, 10),
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  String _vehicleLabel(Map<String, dynamic> v) {
    final reg = v['registrationNumber'] as String? ?? '—';
    final type = v['vehicleTypeName'] as String?;
    final cap = v['capacityInTons'];
    return '$reg'
        '${type != null ? ' — $type' : ''}'
        '${cap != null ? ' (${cap}T)' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.navy,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Assign Vehicle',
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Vehicle selector ─────────────────────────────────────
          Obx(
            () => widget.controller.isLoadingVehicles.value
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'Vehicle',
                    title: 'Select Vehicle',
                    hint: 'Select available vehicle',
                    isRequired: true,
                    selectedDisplay: _selectedVehicle != null
                        ? _vehicleLabel(_selectedVehicle!)
                        : null,
                    items: widget.controller.vehicles,
                    itemLabel: _vehicleLabel,
                    onSelected: (v) => setState(() => _selectedVehicle = v),
                    errorText: _errors['vehicle'],
                    emptyMessage: 'No available vehicles',
                  ),
          ),
          const SizedBox(height: 16),

          // ── Allocated Weight ─────────────────────────────────────
          _SheetLabel('Allocated Weight (tons)', isRequired: true),
          const SizedBox(height: 6),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: AppTextStyles.body,
            decoration: _deco(hasError: _errors.containsKey('weight')).copyWith(
              hintText: '20.00',
              hintStyle: AppTextStyles.hint,
              suffixText: 'T',
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ),
          if (_errors.containsKey('weight'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errors['weight']!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(height: 16),

          // ── Load Date + Delivery Date ────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Load Date'),
                    const SizedBox(height: 6),
                    _SheetDateField(
                      value: _loadDate,
                      hint: 'Pick date',
                      onPicked: (d) => setState(() => _loadDate = d),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Delivery Date'),
                    const SizedBox(height: 6),
                    _SheetDateField(
                      value: _delivDate,
                      hint: 'Pick date',
                      onPicked: (d) => setState(() => _delivDate = d),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Remarks ──────────────────────────────────────────────
          const _SheetLabel('Remarks'),
          const SizedBox(height: 6),
          TextField(
            controller: _remarksCtrl,
            style: AppTextStyles.body,
            decoration: _deco().copyWith(
              hintText: 'Optional remarks...',
              hintStyle: AppTextStyles.hint,
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit ───────────────────────────────────────────────
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.controller.isAssigning.value ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: widget.controller.isAssigning.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Assign Vehicle',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco({bool hasError = false}) => InputDecoration(
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.border,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.navy,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}

// ── Assign Staff Bottom Sheet ─────────────────────────────────────────────────
class _AssignStaffSheet extends StatefulWidget {
  final SupervisorOrderDetailController controller;
  final int vehicleId;
  final String role;
  final String roleLabel;
  // Whether the vehicle already has this role filled (swap scenario)
  final bool isSwap;

  const _AssignStaffSheet({
    required this.controller,
    required this.vehicleId,
    required this.role,
    required this.roleLabel,
    this.isSwap = false,
  });

  @override
  State<_AssignStaffSheet> createState() => _AssignStaffSheetState();
}

class _AssignStaffSheetState extends State<_AssignStaffSheet> {
  Map<String, dynamic>? _selectedStaff;
  final Map<String, String> _errors = {};

  List<Map<String, dynamic>> get _staffList => widget.role == 'DRIVER'
      ? widget.controller.drivers
      : widget.controller.cleaners;

  bool _validate() {
    final e = <String, String>{};
    if (_selectedStaff == null)
      e['staff'] = 'Select a ${widget.roleLabel.toLowerCase()}';
    setState(() {
      _errors.clear();
      _errors.addAll(e);
    });
    return e.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final userId = _selectedStaff!['id'] as int;
    final success = widget.role == 'DRIVER'
        ? await widget.controller.assignDriver(
            vehicleId: widget.vehicleId,
            userId: userId,
          )
        : await widget.controller.assignCleaner(
            vehicleId: widget.vehicleId,
            userId: userId,
          );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final icon = widget.role == 'DRIVER'
        ? Icons.person_outlined
        : Icons.cleaning_services_outlined;
    final isLoading = widget.role == 'DRIVER'
        ? widget.controller.isAssigningDriver
        : widget.controller.isAssigningCleaner;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────
          Row(
            children: [
              Icon(icon, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Text(
                'Assign ${widget.roleLabel}',
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Swap warning ─────────────────────────────────────────
          if (widget.isSwap) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will replace the current ${widget.roleLabel.toLowerCase()} on this vehicle.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Staff selector ───────────────────────────────────────
          Obx(
            () => widget.controller.isLoadingStaff.value
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: widget.roleLabel,
                    title: 'Select ${widget.roleLabel}',
                    hint: 'Select ${widget.roleLabel.toLowerCase()}',
                    isRequired: true,
                    selectedDisplay: _selectedStaff?['name'] as String?,
                    items: _staffList,
                    itemLabel: (u) => u['name'] as String? ?? '—',
                    onSelected: (u) => setState(() => _selectedStaff = u),
                    errorText: _errors['staff'],
                    emptyMessage:
                        'No ${widget.roleLabel.toLowerCase()}s available',
                  ),
          ),
          const SizedBox(height: 24),

          // ── Submit ───────────────────────────────────────────────
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Assign ${widget.roleLabel}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LRs Tab ───────────────────────────────────────────────────────────────────
class _LrsTab extends StatelessWidget {
  final SupervisorOrderDetailController controller;
  const _LrsTab({required this.controller});

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailCreateLrSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lrs = controller.lrs;
      return Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'lbl_lrs'.tr,
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
                    '${lrs.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showCreateSheet(context),
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
                          'btn_create_lr'.tr,
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
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── List or empty ────────────────────────────────────────────
          if (lrs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    Text(
                      'No LRs created yet',
                      style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showCreateSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'btn_create_lr'.tr,
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
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: lrs.length,
                itemBuilder: (_, i) => _LrCard(lr: lrs[i], controller: controller),
              ),
            ),
        ],
      );
    });
  }
}

class _LrCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  final SupervisorOrderDetailController controller;
  const _LrCard({required this.lr, required this.controller});

  @override
  Widget build(BuildContext context) {
    final lrId = lr['id'];
    final lrNumber = lr['lrNumber'] as String? ?? '—';
    final vehicle = lr['vehicleRegistrationNumber'] as String? ?? '—';
    final status = lr['lrStatus'] as String? ?? '';
    final fromCity = lr['fromCity'] as String? ?? '—';
    final toCity = lr['toCity'] as String? ?? '—';
    final weight = lr['allocatedWeight'];
    final lrDate = lr['lrDate'] as String?;

    final statusColor = _lrColor(status);
    final intId = lrId is int ? lrId : int.tryParse(lrId.toString()) ?? 0;

    return InkWell(
      onTap: () => Get.to(
        () => const SupervisorLrDetailView(),
        binding: BindingsBuilder(() {
          Get.put(SupervisorLrDetailController());
        }),
        arguments: intId,
        transition: Transition.cupertino,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 17,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vehicle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _lrLabel(status),
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '#${lrNumber.toLowerCase()}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 12,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fromCity,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.bodyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          toCity,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.bodyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (weight != null) ...[
                        _InfoChip(Icons.scale_outlined, '${weight}T'),
                        const SizedBox(width: 12),
                      ],
                      if (lrDate != null)
                        _InfoChip(
                          Icons.calendar_today_outlined,
                          FerosDateUtils.formatDate(lrDate),
                        ),
                      const Spacer(),
                      Obx(() {
                        final isLoading =
                            controller.pdfLoadingId.value == intId;
                        return GestureDetector(
                          onTap: () => controller.viewLrPdf(
                            intId,
                            lrNumber,
                            '$fromCity → $toCity',
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navy,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 14,
                                  color: AppColors.navy,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                isLoading ? 'Loading…' : 'View PDF',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Container
    ); // InkWell
  }

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
      default:
        return AppColors.mutedText;
    }
  }

  String _lrLabel(String s) {
    switch (s) {
      case 'CREATED':
        return 'Created';
      case 'WEIGHT_LOADED':
        return 'Loaded';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'DELIVERED':
        return 'Delivered';
      case 'INVOICED':
        return 'Invoiced';
      default:
        return s;
    }
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────
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

// ── Order Summary Row (Material + Freight) ────────────────────────────────────
class _OrderSummaryRow extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderSummaryRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final material      = order['materialTypeName']  as String?;
    final rateType      = order['freightRateType']   as String?;
    final freightRate   = order['freightRate'];
    final totalFreight  = order['totalFreightAmount'];

    final rateLabel = rateType?.replaceAll('PER_', '') ?? '';
    final freightStr = freightRate != null
        ? '₹$freightRate${rateLabel.isNotEmpty ? ' / $rateLabel' : ''}'
        : null;
    final totalStr = totalFreight != null ? 'Total: ₹$totalFreight' : null;

    if (material == null && freightStr == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (material != null)
          Expanded(
            child: _SummaryChip(
              icon: Icons.inventory_2_outlined,
              label: 'Material',
              value: material,
              sub: rateLabel.isNotEmpty ? rateLabel : null,
            ),
          ),
        if (material != null && freightStr != null) const SizedBox(width: 8),
        if (freightStr != null)
          Expanded(
            child: _SummaryChip(
              icon: Icons.receipt_outlined,
              label: 'Freight',
              value: freightStr,
              sub: totalStr,
            ),
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  const _SummaryChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            if (sub != null)
              Text(sub!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText, fontSize: 10)),
          ],
        ),
      );
}

// ── Breakdown Banner ──────────────────────────────────────────────────────────
class _BreakdownBanner extends StatelessWidget {
  final int allocationId;
  final Map<String, dynamic> breakdown;
  final SupervisorOrderDetailController controller;
  final VoidCallback onReplace;
  const _BreakdownBanner({
    required this.allocationId,
    required this.breakdown,
    required this.controller,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final bdStatus = breakdown['status'] as String? ?? '';
    final bdId     = breakdown['id'] as int? ?? 0;
    final bdType   = (breakdown['breakdownType'] as String? ?? '').toLowerCase();
    final location = breakdown['location'] as String?;
    final reason   = breakdown['reason'] as String?;

    if (bdStatus == 'VEHICLE_REPLACED') {
      final replacement = breakdown['replacementVehicleRegistrationNumber'] as String? ?? '—';
      return _banner(
        color: AppColors.border,
        bgColor: const Color(0xFFF8FAFC),
        icon: Icons.info_outline,
        iconColor: AppColors.mutedText,
        child: Text(
          'Breakdown — goods transferred to $replacement',
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        ),
      );
    }

    if (bdStatus == 'RESOLVED') {
      return _banner(
        color: AppColors.success,
        bgColor: AppColors.successLight,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        child: Text(
          'Breakdown resolved — trip continues',
          style: AppTextStyles.caption.copyWith(color: AppColors.success),
        ),
      );
    }

    // REPORTED or IN_REPAIR — active breakdown
    final isActive = bdStatus == 'REPORTED' || bdStatus == 'IN_REPAIR';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 15, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breakdown Reported · ${bdType[0].toUpperCase()}${bdType.substring(1)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (location != null)
                      Text(location,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.warning)),
                    if (reason != null)
                      Text(reason,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                  ],
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _BdActionChip(
                  label: 'Assign Replacement',
                  icon: Icons.swap_horiz,
                  color: AppColors.navy,
                  onTap: onReplace,
                ),
                Obx(() => _BdActionChip(
                  label: controller.isResolvingBreakdown.value
                      ? 'Resolving…'
                      : 'Repaired — Continue',
                  icon: Icons.build_outlined,
                  color: AppColors.success,
                  onTap: controller.isResolvingBreakdown.value
                      ? null
                      : () async {
                          final ok = await FerosDialog.confirm(
                            title: 'Resolve Breakdown',
                            message:
                                'Mark breakdown as resolved? Trip will continue with the same vehicle.',
                            confirmText: 'Resolve',
                          );
                          if (ok) {
                            controller.resolveBreakdown(allocationId, bdId);
                          }
                        },
                )),
                if (bdStatus == 'REPORTED')
                  Obx(() => _BdActionChip(
                    label: controller.isCancellingBreakdown.value
                        ? 'Cancelling…'
                        : 'False Alarm',
                    icon: Icons.close,
                    color: AppColors.mutedText,
                    onTap: controller.isCancellingBreakdown.value
                        ? null
                        : () async {
                            final ok = await FerosDialog.confirm(
                              title: 'Cancel Breakdown Report',
                              message:
                                  'Cancel this breakdown report? Use only for false alarms.',
                              confirmText: 'Cancel Report',
                              isDestructive: true,
                            );
                            if (ok) {
                              controller.cancelBreakdown(allocationId, bdId);
                            }
                          },
                  )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _banner({
    required Color color,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      );
}

class _BdActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _BdActionChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Report Breakdown Sheet ────────────────────────────────────────────────────
class _ReportBreakdownSheet extends StatefulWidget {
  final SupervisorOrderDetailController controller;
  final int allocationId;
  final String vehicleReg;
  const _ReportBreakdownSheet(
      {required this.controller,
      required this.allocationId,
      required this.vehicleReg});

  @override
  State<_ReportBreakdownSheet> createState() => _ReportBreakdownSheetState();
}

class _ReportBreakdownSheetState extends State<_ReportBreakdownSheet> {
  String? _duration;
  String _type = 'MECHANICAL';
  final _reasonCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _breakdownAt = DateTime.now();
  bool _submitting = false;

  static const _types = [
    ('MECHANICAL', 'Mechanical'),
    ('TYRE', 'Tyre'),
    ('ENGINE', 'Engine'),
    ('ELECTRICAL', 'Electrical'),
    ('ACCIDENT', 'Accident'),
    ('OTHER', 'Other'),
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDt(DateTime d) {
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _breakdownAt,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_breakdownAt),
    );
    if (time == null) return;
    setState(() => _breakdownAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_duration == null) {
      FerosSnackbar.error('Select breakdown duration');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      FerosSnackbar.error('Reason is required');
      return;
    }
    setState(() => _submitting = true);
    final data = {
      'breakdownType': _type,
      'breakdownDuration': _duration,
      'breakdownDate': _breakdownAt.toUtc().toIso8601String(),
      'reason': _reasonCtrl.text.trim(),
      if (_locationCtrl.text.trim().isNotEmpty)
        'location': _locationCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    final ok =
        await widget.controller.reportBreakdown(widget.allocationId, data);
    if (ok && mounted) Navigator.of(context).pop();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report Breakdown',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.warning)),
                      Text(widget.vehicleReg,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Duration
                  _SheetLabel('Breakdown Duration', isRequired: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DurationCard(
                          value: 'SHORT',
                          label: 'Short',
                          sub: 'Minor · back in 1-2 days',
                          selected: _duration == 'SHORT',
                          onTap: () =>
                              setState(() => _duration = 'SHORT')),
                      const SizedBox(width: 10),
                      _DurationCard(
                          value: 'LONG',
                          label: 'Long',
                          sub: 'Major · extended downtime',
                          selected: _duration == 'LONG',
                          onTap: () => setState(() => _duration = 'LONG')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type
                  _SheetLabel('Breakdown Type', isRequired: true),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _type,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        borderRadius: BorderRadius.circular(8),
                        items: _types
                            .map((t) => DropdownMenuItem(
                                value: t.$1,
                                child: Text(t.$2,
                                    style: AppTextStyles.body)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _type = v ?? _type),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  _SheetLabel('Reason', isRequired: true),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(
                      hintText: 'What happened?',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: AppTextStyles.body,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Date/Time
                  _SheetLabel('Date & Time', isRequired: true),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppColors.mutedText),
                          const SizedBox(width: 8),
                          Text(_fmtDt(_breakdownAt),
                              style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location (optional)
                  const _SheetLabel('Location'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Nashik Highway, km 145',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  const _SheetLabel('Notes'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Additional notes…',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _submitting ? 'Reporting…' : 'Report Breakdown',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _DurationCard(
      {required this.value,
      required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isShort = value == 'SHORT';
    final activeColor = isShort ? AppColors.warning : AppColors.error;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? activeColor
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? activeColor : AppColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Replace Vehicle Sheet ─────────────────────────────────────────────────────
class _ReplaceVehicleSheet extends StatefulWidget {
  final SupervisorOrderDetailController controller;
  final Map<String, dynamic> breakdown;
  const _ReplaceVehicleSheet(
      {required this.controller, required this.breakdown});

  @override
  State<_ReplaceVehicleSheet> createState() => _ReplaceVehicleSheetState();
}

class _ReplaceVehicleSheetState extends State<_ReplaceVehicleSheet> {
  int? _selectedVehicleId;
  DateTime? _revisedDelivery;
  bool _transferStaff = true;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _submit() async {
    if (_selectedVehicleId == null) {
      FerosSnackbar.error('Select a replacement vehicle');
      return;
    }
    final breakdownId = widget.breakdown['id'] as int? ?? 0;
    final data = <String, dynamic>{
      'replacementVehicleId': _selectedVehicleId,
      'transferStaff': _transferStaff,
      if (_revisedDelivery != null)
        'expectedDeliveryDate': _revisedDelivery!.toIso8601String().split('T')[0],
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    final ok = await widget.controller.replaceVehicle(breakdownId, data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brokenReg =
        widget.breakdown['vehicleRegistrationNumber'] as String? ?? '—';
    final brokenId = widget.breakdown['vehicleId'] as int?;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.swap_horiz,
                        color: AppColors.navy, size: 20),
                    const SizedBox(width: 8),
                    Text('Assign Replacement Vehicle',
                        style: AppTextStyles.heading3),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    'Broken: $brokenReg · Same LR travels with goods',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final available = widget.controller.vehicles
                    .where((v) => v['id'] != brokenId)
                    .toList();
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Vehicle picker
                    const _SheetLabel('Replacement Vehicle', isRequired: true),
                    const SizedBox(height: 8),
                    if (widget.controller.isLoadingVehicles.value)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.navy, strokeWidth: 2))
                    else if (available.isEmpty)
                      Text('No available vehicles',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText))
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedVehicleId,
                            hint: Text('Select vehicle',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.hintText)),
                            isExpanded: true,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(8),
                            items: available
                                .map((v) => DropdownMenuItem<int>(
                                      value: v['id'] as int,
                                      child: Text(
                                        v['registrationNumber'] as String? ?? '—',
                                        style: AppTextStyles.body,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedVehicleId = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Revised delivery date
                    const _SheetLabel('Revised Delivery Date'),
                    const SizedBox(height: 8),
                    _SheetDateField(
                      value: _revisedDelivery,
                      hint: 'Pick date',
                      onPicked: (d) => setState(() => _revisedDelivery = d),
                    ),
                    const SizedBox(height: 16),

                    // Transfer staff toggle
                    const _SheetLabel('Driver & Cleaner'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _ToggleOption(
                            label: 'Transfer to replacement vehicle',
                            selected: _transferStaff,
                            onTap: () =>
                                setState(() => _transferStaff = true),
                          ),
                          const Divider(height: 1),
                          _ToggleOption(
                            label: 'Cancel — assign manually',
                            selected: !_transferStaff,
                            onTap: () =>
                                setState(() => _transferStaff = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const _SheetLabel('Notes'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Reason for replacement…',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),

                    Obx(() => SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: widget.controller.isReplacingVehicle.value
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          widget.controller.isReplacingVehicle.value
                              ? 'Assigning…'
                              : 'Assign Replacement',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.navy : AppColors.mutedText,
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.body.copyWith(
                        color: selected
                            ? AppColors.bodyText
                            : AppColors.mutedText,
                      ))),
            ],
          ),
        ),
      );
}

// ── Additional Details Card ───────────────────────────────────────────────────
class _AdditionalDetailsCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AdditionalDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final billingOn = (order['billingOn'] as String?)?.replaceAll('_', ' ');
    final routeName = order['routeName'] as String?;
    final specialInstructions = order['specialInstructions'] as String?;
    final remarks = order['remarks'] as String?;

    if (billingOn == null && routeName == null &&
        specialInstructions == null && remarks == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 12),
          if (billingOn != null) ...[
            _DetailRow(label: 'Bill On', value: billingOn),
            const SizedBox(height: 8),
          ],
          if (routeName != null) ...[
            _DetailRow(label: 'Route', value: routeName),
            const SizedBox(height: 8),
          ],
          if (specialInstructions != null) ...[
            _DetailRow(label: 'Special Instructions', value: specialInstructions),
            const SizedBox(height: 8),
          ],
          if (remarks != null)
            _DetailRow(label: 'Remarks', value: remarks),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          letterSpacing: 0.4,
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

// ── Sheet helpers (label, date field, shimmer) ────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _SheetLabel(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      text: text,
      style: AppTextStyles.label,
      children: isRequired
          ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          : [],
    ),
  );
}

class _SheetDateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final void Function(DateTime) onPicked;

  const _SheetDateField({
    required this.value,
    required this.hint,
    required this.onPicked,
  });

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 5),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.navy),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : hint,
                style: AppTextStyles.body.copyWith(
                  color: value != null
                      ? AppColors.bodyText
                      : AppColors.hintText,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create LR Bottom Sheet ────────────────────────────────────────────────────
class _CreateLrSheet extends StatefulWidget {
  final int allocationId;
  final SupervisorOrderDetailController controller;
  final dynamic allocatedWeight;

  const _CreateLrSheet({
    required this.allocationId,
    required this.controller,
    this.allocatedWeight,
  });

  @override
  State<_CreateLrSheet> createState() => _CreateLrSheetState();
}

class _CreateLrSheetState extends State<_CreateLrSheet> {
  DateTime _lrDate = DateTime.now();

  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final aw = widget.allocatedWeight;
    if (aw != null) {
      _weightCtrl.text = aw.toString();
      _weightCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _weightCtrl.text.length,
      );
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = <String, dynamic>{
      'vehicleAllocationId': widget.allocationId,
      'lrDate': _lrDate.toIso8601String().substring(0, 10),
    };
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w != null) data['loadedWeight'] = w;
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }
    final ok = await widget.controller.createLr(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  InputDecoration _inputDec({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Create LR',
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
            // Body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  // ── LR Date ───────────────────────────────────────────────
                  _SheetLabel('LR Date'),
                  const SizedBox(height: 6),
                  _SheetDateField(
                    value: _lrDate,
                    hint: 'Select date',
                    onPicked: (d) => setState(() => _lrDate = d),
                  ),
                  const SizedBox(height: 20),

                  // ── Loaded Weight ─────────────────────────────────────────
                  _SheetLabel('Loaded Weight (tonnes)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: AppTextStyles.body,
                    decoration: _inputDec(hint: 'e.g. 10.5'),
                  ),
                  const SizedBox(height: 20),

                  // ── Remarks ───────────────────────────────────────────────
                  _SheetLabel('Remarks'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarksCtrl,
                    maxLines: 3,
                    style: AppTextStyles.body,
                    decoration: _inputDec(hint: 'Optional notes…'),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit ────────────────────────────────────────────────
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.controller.isCreatingLr.value
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: widget.controller.isCreatingLr.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create LR',
                                style: TextStyle(
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
          ],
        ),
      ),
    );
  }
}

// ── Order-context Create LR Sheet (vehicle picker → create) ──────────────────
class _OrderDetailCreateLrSheet extends StatefulWidget {
  final SupervisorOrderDetailController controller;
  const _OrderDetailCreateLrSheet({required this.controller});
  @override
  State<_OrderDetailCreateLrSheet> createState() =>
      _OrderDetailCreateLrSheetState();
}

class _OrderDetailCreateLrSheetState
    extends State<_OrderDetailCreateLrSheet> {
  Map<String, dynamic>? _selectedAllocation;

  List<Map<String, dynamic>> get _eligibleAllocations {
    final allocs =
        (widget.controller.order.value?['vehicleAllocations'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    final activeLrAllocIds = widget.controller.lrs
        .where((lr) => (lr['lrStatus'] as String? ?? '') != 'CANCELLED')
        .map((lr) => lr['vehicleAllocationId'])
        .toSet();
    return allocs
        .where((a) =>
            (a['allocationStatus'] as String? ?? '') != 'CANCELLED' &&
            !activeLrAllocIds.contains(a['id']))
        .toList();
  }

  void _proceed() {
    final a = _selectedAllocation;
    if (a == null) return;
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateLrSheet(
        controller: widget.controller,
        allocationId: a['id'] as int,
        allocatedWeight: a['allocatedWeight'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligibles = _eligibleAllocations;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: eligibles.isEmpty ? 0.4 : 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Column(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Create LR',
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.navy),
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
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _SheetLabel('Select Vehicle *'),
                  const SizedBox(height: 8),
                  if (eligibles.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'All allocated vehicles already have active LRs.',
                        style: AppTextStyles.body
                            .copyWith(color: Colors.orange.shade800),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedAllocation,
                      hint: Text(
                        'Select a vehicle',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.hintText),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.navy, width: 1.5),
                        ),
                      ),
                      items: eligibles.map((a) {
                        final reg =
                            a['vehicleRegistrationNumber'] as String? ??
                                a['vehicleNumber'] as String? ??
                                '—';
                        final type = a['vehicleTypeName'] as String? ?? '';
                        return DropdownMenuItem(
                          value: a,
                          child: Text(
                            '$reg${type.isNotEmpty ? '  ·  $type' : ''}',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.bodyText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _selectedAllocation = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _selectedAllocation == null ? null : _proceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
