import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
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
        final _assignableStatuses = const [
          'PENDING',
          'PARTIALLY_ASSIGNED',
          'PARTIALLY_DELIVERED',
        ];
        final _orderStatus = o['orderStatus'] as String? ?? '';
        final _canAssignOrder = _assignableStatuses.contains(_orderStatus);
        final _remaining = o['remainingWeight'];
        return DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) {
              final tabCtrl = DefaultTabController.of(tabContext);
              return AnimatedBuilder(
                animation: tabCtrl,
                builder: (_, __) => Scaffold(
                  backgroundColor: AppColors.background,
                  floatingActionButton: (_canAssignOrder && tabCtrl.index == 0)
                      ? FloatingActionButton.extended(
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
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Assign Vehicle',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
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
                                : () => controller.updateStatus(s),
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
      case 'PENDING':
        return ['ACTIVE', 'CANCELLED'];
      case 'ACTIVE':
      case 'PARTIALLY_ASSIGNED':
      case 'FULLY_ASSIGNED':
        return ['COMPLETED', 'CANCELLED'];
      case 'IN_TRANSIT':
      case 'PARTIALLY_DELIVERED':
        return ['COMPLETED'];
      default:
        return [];
    }
  }

  String _statusActionLabel(String s) {
    switch (s) {
      case 'ACTIVE':
        return 'Activate';
      case 'COMPLETED':
        return 'Mark Complete';
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
          child: allocations.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: allocations.length,
                  itemBuilder: (_, i) => _AllocationCard(
                    allocation: allocations[i],
                    controller: controller,
                  ),
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
    final staffList =
        (allocation['staffAllocations'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
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
                if (staffList.isNotEmpty || !_isClosed(status)) ...[
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
                        if (!staffList.any((s) => s['roleName'] == 'DRIVER'))
                          _StaffButton(
                            label: '+ Driver',
                            onTap: () => _openAssignStaffSheet(
                              context,
                              allocationId,
                              'DRIVER',
                              'Driver',
                            ),
                          ),
                        if (!staffList.any((s) => s['roleName'] == 'DRIVER') &&
                            !staffList.any((s) => s['roleName'] == 'CLEANER'))
                          const SizedBox(width: 8),
                        if (!staffList.any((s) => s['roleName'] == 'CLEANER'))
                          _StaffButton(
                            label: '+ Cleaner',
                            onTap: () => _openAssignStaffSheet(
                              context,
                              allocationId,
                              'CLEANER',
                              'Cleaner',
                            ),
                          ),
                      ],
                    ],
                  ),
                  if (staffList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...staffList.map(
                      (s) => _StaffRow(
                        staff: s,
                        controller: controller,
                        locked: isLocked,
                      ),
                    ),
                  ],
                ],

                // ── Create LR button ──────────────────────────────────
                // Show when: driver assigned + no LR yet + not closed
                if (staffList.any((s) => s['roleName'] == 'DRIVER') &&
                    !_isClosed(status))
                  Obx(() {
                    final hasLr = controller.lrs.any((lr) {
                      final id = lr['vehicleAllocationId'];
                      return id != null &&
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
              ],
            ),
          ),
        ],
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
    int allocationId,
    String role,
    String roleLabel,
  ) {
    controller.fetchStaff();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignStaffSheet(
        controller: controller,
        allocationId: allocationId,
        role: role,
        roleLabel: roleLabel,
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
  final Map<String, dynamic> staff;
  final SupervisorOrderDetailController controller;
  final bool locked;
  const _StaffRow({
    required this.staff,
    required this.controller,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final staffAllocationId = staff['id'] as int? ?? 0;
    final name = staff['userName'] as String? ?? '—';
    final role = staff['roleName'] as String? ?? '';

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
                if (role.isNotEmpty)
                  Text(
                    _roleLabel(role),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          if (!locked)
            Obx(() {
              final isUnassigning =
                  controller.unassigningStaffId.value == staffAllocationId;
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
                    title: 'Unassign ${_roleLabel(role)}',
                    message: 'Remove $name from this vehicle?',
                    confirmText: 'Unassign',
                    isDestructive: true,
                  );
                  if (confirmed) controller.unassignStaff(staffAllocationId);
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

  String _roleLabel(String r) {
    switch (r) {
      case 'DRIVER':
        return 'Driver';
      case 'CLEANER':
        return 'Cleaner';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'SERVICE_MEN':
        return 'Service Men';
      default:
        return r;
    }
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
  final int allocationId;
  final String role;
  final String roleLabel;

  const _AssignStaffSheet({
    required this.controller,
    required this.allocationId,
    required this.role,
    required this.roleLabel,
  });

  @override
  State<_AssignStaffSheet> createState() => _AssignStaffSheetState();
}

class _AssignStaffSheetState extends State<_AssignStaffSheet> {
  Map<String, dynamic>? _selectedStaff;
  final _remarksCtrl = TextEditingController();
  DateTime? _startDate, _endDate;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

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
    final success = await widget.controller.assignStaff(
      vehicleAllocationId: widget.allocationId,
      userId: _selectedStaff!['id'] as int,
      expectedStartDate: _startDate?.toIso8601String().substring(0, 10),
      expectedEndDate: _endDate?.toIso8601String().substring(0, 10),
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final icon = widget.role == 'DRIVER'
        ? Icons.person_outlined
        : Icons.cleaning_services_outlined;

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
          const SizedBox(height: 20),

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
          const SizedBox(height: 16),

          // ── Start Date + End Date ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('Start Date'),
                    const SizedBox(height: 6),
                    _SheetDateField(
                      value: _startDate,
                      hint: 'Pick date',
                      onPicked: (d) => setState(() => _startDate = d),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetLabel('End Date'),
                    const SizedBox(height: 6),
                    _SheetDateField(
                      value: _endDate,
                      hint: 'Pick date',
                      onPicked: (d) => setState(() => _endDate = d),
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
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Optional remarks...',
              hintStyle: AppTextStyles.hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
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
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit ───────────────────────────────────────────────
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.controller.isAssigningStaff.value
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: widget.controller.isAssigningStaff.value
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

  @override
  Widget build(BuildContext context) {
    final lrs = controller.lrs;
    if (lrs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              'No LRs created yet',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: lrs.length,
      itemBuilder: (_, i) => _LrCard(lr: lrs[i], controller: controller),
    );
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
