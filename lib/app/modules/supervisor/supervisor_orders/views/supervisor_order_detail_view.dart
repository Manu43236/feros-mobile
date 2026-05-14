import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/supervisor_order_detail_controller.dart';

class SupervisorOrderDetailView
    extends GetView<SupervisorOrderDetailController> {
  const SupervisorOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: Get.back,
        ),
        title: Obx(() {
          final o = controller.order.value;
          return Text(
            o != null ? o['orderNumber'] as String? ?? 'Order Detail' : 'Order Detail',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          );
        }),
      ),
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.navy));
        }
        if (controller.state.value == ViewState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load order',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchOrder,
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

        final o = controller.order.value!;
        return RefreshIndicator(
          color: AppColors.navy,
          onRefresh: controller.fetchOrder,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _StatusBanner(order: o),
              const SizedBox(height: 16),
              _OrderInfoSection(order: o),
              const SizedBox(height: 16),
              _RouteSection(order: o),
              const SizedBox(height: 16),
              _AllocationsSection(order: o),
              if (_hasNotes(o)) ...[
                const SizedBox(height: 16),
                _NotesSection(order: o),
              ],
            ],
          ),
        );
      }),
    );
  }

  bool _hasNotes(Map<String, dynamic> o) =>
      (o['specialInstructions'] as String?)?.isNotEmpty == true ||
      (o['remarks'] as String?)?.isNotEmpty == true ||
      (o['ewayBillNumber'] as String?)?.isNotEmpty == true;
}

// ── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Map<String, dynamic> order;
  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final status        = order['orderStatus']        as String? ?? '';
    final paymentStatus = order['orderPaymentStatus'] as String? ?? '';
    final color         = _orderColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Status',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 2),
                Text(_orderLabel(status),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Payment',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(_paymentLabel(paymentStatus),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _paymentColor(paymentStatus),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Color _orderColor(String s) {
    switch (s) {
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

  String _orderLabel(String s) {
    switch (s) {
      case 'PENDING':             return 'Pending';
      case 'PARTIALLY_ASSIGNED':  return 'Partially Assigned';
      case 'FULLY_ASSIGNED':      return 'Fully Assigned';
      case 'IN_TRANSIT':          return 'In Transit';
      case 'PARTIALLY_DELIVERED': return 'Partially Delivered';
      case 'DELIVERED':           return 'Delivered';
      case 'CANCELLED':           return 'Cancelled';
      default:                    return s;
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'PAID':         return AppColors.success;
      case 'PARTIAL':      return AppColors.warning;
      case 'UNPAID':       return AppColors.error;
      default:             return AppColors.mutedText;
    }
  }

  String _paymentLabel(String s) {
    switch (s) {
      case 'PAID':         return 'Paid';
      case 'PARTIAL':      return 'Partial';
      case 'UNPAID':       return 'Unpaid';
      default:             return s;
    }
  }
}

// ── Order Info Section ────────────────────────────────────────────────────────
class _OrderInfoSection extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderInfoSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final totalWeight     = order['totalWeight'];
    final weightFulfilled = order['totalWeightFulfilled'];
    final remaining       = order['remainingWeight'];

    return _Card(
      title: 'Order Information',
      children: [
        _InfoRow(label: 'Client',        value: order['clientName']           as String? ?? '—'),
        _InfoRow(label: 'Material',      value: order['materialTypeName']     as String? ?? '—'),
        _InfoRow(label: 'Order Date',    value: FerosDateUtils.formatDate(order['orderDate'] as String?)),
        _InfoRow(label: 'Expected ETA',  value: FerosDateUtils.formatDate(order['expectedDeliveryDate'] as String?)),
        if (totalWeight != null)
          _InfoRow(label: 'Total Weight', value: '${totalWeight}T'),
        if (weightFulfilled != null)
          _InfoRow(label: 'Fulfilled',    value: '${weightFulfilled}T'),
        if (remaining != null)
          _InfoRow(label: 'Remaining',    value: '${remaining}T'),
        _InfoRow(label: 'Created By',    value: order['createdByName']        as String? ?? '—'),
      ],
    );
  }
}

// ── Route Section ─────────────────────────────────────────────────────────────
class _RouteSection extends StatelessWidget {
  final Map<String, dynamic> order;
  const _RouteSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final fromCity    = order['sourceCityName']      as String? ?? '—';
    final fromState   = order['sourceStateName']     as String? ?? '';
    final fromAddr    = order['sourceAddress']       as String?;
    final toCity      = order['destinationCityName'] as String? ?? '—';
    final toState     = order['destinationStateName']as String? ?? '';
    final toAddr      = order['destinationAddress']  as String?;
    final routeName   = order['routeName']           as String?;

    return _Card(
      title: 'Route',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side — icons + line
            Column(
              children: [
                const Icon(Icons.radio_button_checked, size: 16, color: AppColors.navy),
                Container(width: 2, height: 36, color: AppColors.border),
                const Icon(Icons.location_on, size: 16, color: AppColors.orange),
              ],
            ),
            const SizedBox(width: 12),
            // Right side — from / to
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$fromCity${fromState.isNotEmpty ? ', $fromState' : ''}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyText)),
                  if (fromAddr != null && fromAddr.isNotEmpty)
                    Text(fromAddr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  const SizedBox(height: 28),
                  Text('$toCity${toState.isNotEmpty ? ', $toState' : ''}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyText)),
                  if (toAddr != null && toAddr.isNotEmpty)
                    Text(toAddr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
          ],
        ),
        if (routeName != null && routeName.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 8),
              Text(routeName,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Allocations Section ───────────────────────────────────────────────────────
class _AllocationsSection extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AllocationsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final allocations = (order['vehicleAllocations'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (allocations.isEmpty) {
      return _Card(
        title: 'Vehicle Allocations',
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No vehicles assigned yet',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Vehicle Allocations',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
        ),
        ...allocations.map((a) => _AllocationCard(allocation: a)),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final Map<String, dynamic> allocation;
  const _AllocationCard({required this.allocation});

  @override
  Widget build(BuildContext context) {
    final vehicle    = allocation['vehicleRegistrationNumber'] as String? ?? '—';
    final type       = allocation['vehicleTypeName']           as String?;
    final weight     = allocation['allocatedWeight'];
    final status     = allocation['allocationStatus']          as String? ?? '';
    final loadDate   = allocation['expectedLoadDate']          as String?;
    final delivDate  = allocation['expectedDeliveryDate']      as String?;
    final staffList  = (allocation['staffAllocations'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

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
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
                      if (type != null)
                        Text(type,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (weight != null) ...[
                      _Chip(Icons.scale_outlined, '${weight}T'),
                      const SizedBox(width: 8),
                    ],
                    if (loadDate != null)
                      _Chip(Icons.upload_outlined,
                          'Load: ${FerosDateUtils.formatDate(loadDate)}'),
                  ],
                ),
                if (delivDate != null) ...[
                  const SizedBox(height: 6),
                  _Chip(Icons.download_outlined,
                      'ETA: ${FerosDateUtils.formatDate(delivDate)}'),
                ],

                if (staffList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text('Staff',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...staffList.map((s) => _StaffRow(staff: s)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':    return AppColors.orderPending;
      case 'ASSIGNED':   return AppColors.info;
      case 'IN_TRANSIT': return AppColors.lrInTransit;
      case 'DELIVERED':  return AppColors.success;
      case 'CANCELLED':  return AppColors.error;
      default:           return AppColors.mutedText;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING':    return 'Pending';
      case 'ASSIGNED':   return 'Assigned';
      case 'IN_TRANSIT': return 'In Transit';
      case 'DELIVERED':  return 'Delivered';
      case 'CANCELLED':  return 'Cancelled';
      default:           return s;
    }
  }
}

class _StaffRow extends StatelessWidget {
  final Map<String, dynamic> staff;
  const _StaffRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    final name = staff['userName'] as String? ?? '—';
    final role = staff['roleName'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                Text(name,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.bodyText)),
                if (role.isNotEmpty)
                  Text(_roleLabel(role),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'DRIVER':      return 'Driver';
      case 'CLEANER':     return 'Cleaner';
      case 'SUPERVISOR':  return 'Supervisor';
      case 'SERVICE_MEN': return 'Service Men';
      default:            return r;
    }
  }
}

// ── Notes Section ─────────────────────────────────────────────────────────────
class _NotesSection extends StatelessWidget {
  final Map<String, dynamic> order;
  const _NotesSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final instructions = order['specialInstructions'] as String?;
    final remarks      = order['remarks']             as String?;
    final eWayNumber   = order['ewayBillNumber']      as String?;
    final eWayDate     = order['ewayBillDate']        as String?;
    final eWayExpiry   = order['ewayBillValidUpto']   as String?;

    return _Card(
      title: 'Notes & eWay Bill',
      children: [
        if (instructions != null && instructions.isNotEmpty)
          _InfoRow(label: 'Special Instructions', value: instructions),
        if (remarks != null && remarks.isNotEmpty)
          _InfoRow(label: 'Remarks', value: remarks),
        if (eWayNumber != null && eWayNumber.isNotEmpty) ...[
          _InfoRow(label: 'eWay Bill No.', value: eWayNumber),
          if (eWayDate != null)
            _InfoRow(label: 'eWay Date',   value: FerosDateUtils.formatDate(eWayDate)),
          if (eWayExpiry != null)
            _InfoRow(label: 'Valid Upto',  value: FerosDateUtils.formatDate(eWayExpiry)),
        ],
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.bodyText, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}
