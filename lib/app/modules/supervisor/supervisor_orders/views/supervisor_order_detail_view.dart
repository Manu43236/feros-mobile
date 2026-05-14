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
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.navy)),
          );
        }
        if (controller.state.value == ViewState.error) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load order',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchAll,
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
            ),
          );
        }

        final o = controller.order.value!;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: NestedScrollView(
              headerSliverBuilder: (context2, _) => [
                _OrderBannerSliver(order: o),
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(),
                ),
              ],
              body: TabBarView(
                children: [
                  _AssignmentsTab(order: o),
                  _LrsTab(controller: controller),
                  _InvoicesTab(controller: controller),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Banner Sliver ─────────────────────────────────────────────────────────────
class _OrderBannerSliver extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderBannerSliver({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderNumber   = order['orderNumber']          as String? ?? '—';
    final clientName    = order['clientName']           as String? ?? '—';
    final status        = order['orderStatus']          as String? ?? '';
    final payStatus     = order['orderPaymentStatus']   as String? ?? '';
    final fromCity      = order['sourceCityName']       as String? ?? '—';
    final toCity        = order['destinationCityName']  as String? ?? '—';
    final totalWeight   = order['totalWeight'];
    final weightFulfilled = order['totalWeightFulfilled'];
    final remaining     = order['remainingWeight'];
    final orderDate     = order['orderDate']            as String?;
    final eta           = order['expectedDeliveryDate'] as String?;

    final statusColor = _orderColor(status);

    return SliverToBoxAdapter(
      child: Container(
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
                // Back + order number row
                Row(
                  children: [
                    GestureDetector(
                      onTap: Get.back,
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5)),
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
                const SizedBox(height: 14),

                // Client name
                Text(
                  clientName,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Route
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 12, color: Color(0xFF93C5FD)),
                    const SizedBox(width: 6),
                    Text(fromCity,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7))),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        size: 12, color: Color(0xFF93C5FD)),
                    const SizedBox(width: 6),
                    const Icon(Icons.location_on,
                        size: 12, color: Color(0xFFFB923C)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(toCity,
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stat chips row
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
                      if (remaining != null && double.tryParse(remaining.toString())! > 0)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _orderColor(String s) {
    switch (s) {
      case 'PENDING':             return const Color(0xFFFBBF24);
      case 'PARTIALLY_ASSIGNED':  return const Color(0xFF60A5FA);
      case 'FULLY_ASSIGNED':      return const Color(0xFFA78BFA);
      case 'IN_TRANSIT':          return const Color(0xFFFB923C);
      case 'PARTIALLY_DELIVERED': return const Color(0xFFFCD34D);
      case 'DELIVERED':           return const Color(0xFF4ADE80);
      case 'CANCELLED':           return const Color(0xFFF87171);
      default:                    return Colors.white;
    }
  }

  String _orderLabel(String s) {
    switch (s) {
      case 'PENDING':             return 'Pending';
      case 'PARTIALLY_ASSIGNED':  return 'Part. Assigned';
      case 'FULLY_ASSIGNED':      return 'Assigned';
      case 'IN_TRANSIT':          return 'In Transit';
      case 'PARTIALLY_DELIVERED': return 'Part. Delivered';
      case 'DELIVERED':           return 'Delivered';
      case 'CANCELLED':           return 'Cancelled';
      default:                    return s;
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'PAID':    return const Color(0xFF4ADE80);
      case 'PARTIAL': return const Color(0xFFFCD34D);
      default:        return const Color(0xFFF87171);
    }
  }

  String _paymentLabel(String s) {
    switch (s) {
      case 'PAID':    return 'Paid';
      case 'PARTIAL': return 'Part. Paid';
      default:        return 'Unpaid';
    }
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color? color;
  const _BannerChip(
      {required this.icon, required this.label, this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.9);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: c, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub!,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar Delegate ──────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
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
          Tab(text: 'Assignments'),
          Tab(text: 'LRs'),
          Tab(text: 'Invoices'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

// ── Assignments Tab ───────────────────────────────────────────────────────────
class _AssignmentsTab extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AssignmentsTab({required this.order});

  @override
  Widget build(BuildContext context) {
    final allocations = (order['vehicleAllocations'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (allocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('No vehicles assigned',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: allocations.length,
      itemBuilder: (_, i) => _AllocationCard(allocation: allocations[i]),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final Map<String, dynamic> allocation;
  const _AllocationCard({required this.allocation});

  @override
  Widget build(BuildContext context) {
    final vehicle   = allocation['vehicleRegistrationNumber'] as String? ?? '—';
    final type      = allocation['vehicleTypeName']           as String?;
    final weight    = allocation['allocatedWeight'];
    final status    = allocation['allocationStatus']          as String? ?? '';
    final loadDate  = allocation['expectedLoadDate']          as String?;
    final delivDate = allocation['expectedDeliveryDate']      as String?;
    final staffList = (allocation['staffAllocations'] as List?)
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
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700)),
                      if (type != null)
                        Text(type,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(_statusLabel(status),
                      style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Body
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
                      _Chip(Icons.scale_outlined, '${weight}T'),
                    if (loadDate != null)
                      _Chip(Icons.upload_outlined,
                          'Load: ${FerosDateUtils.formatDate(loadDate)}'),
                    if (delivDate != null)
                      _Chip(Icons.download_outlined,
                          'ETA: ${FerosDateUtils.formatDate(delivDate)}'),
                  ],
                ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy, fontWeight: FontWeight.w700),
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
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('No LRs created yet',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: lrs.length,
      itemBuilder: (_, i) => _LrCard(lr: lrs[i]),
    );
  }
}

class _LrCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  const _LrCard({required this.lr});

  @override
  Widget build(BuildContext context) {
    final lrNumber  = lr['lrNumber']                  as String? ?? '—';
    final vehicle   = lr['vehicleRegistrationNumber'] as String? ?? '—';
    final status    = lr['lrStatus']                  as String? ?? '';
    final fromCity  = lr['fromCity']                  as String? ?? '—';
    final toCity    = lr['toCity']                    as String? ?? '—';
    final weight    = lr['allocatedWeight'];
    final lrDate    = lr['lrDate']                    as String?;

    final statusColor = _lrColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: Text(lrNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(_lrLabel(status),
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(vehicle,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  size: 12, color: AppColors.navy),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(fromCity,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.bodyText),
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 12, color: AppColors.mutedText),
              const SizedBox(width: 8),
              const Icon(Icons.location_on,
                  size: 12, color: AppColors.orange),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(toCity,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.bodyText),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              if (weight != null) ...[
                _Chip(Icons.scale_outlined, '${weight}T'),
                const SizedBox(width: 12),
              ],
              if (lrDate != null)
                _Chip(Icons.calendar_today_outlined,
                    FerosDateUtils.formatDate(lrDate)),
            ],
          ),
        ],
      ),
    );
  }

  Color _lrColor(String s) {
    switch (s) {
      case 'CREATED':       return AppColors.lrCreated;
      case 'WEIGHT_LOADED': return AppColors.lrLoaded;
      case 'IN_TRANSIT':    return AppColors.lrInTransit;
      case 'DELIVERED':     return AppColors.lrDelivered;
      case 'INVOICED':      return AppColors.lrInvoiced;
      default:              return AppColors.mutedText;
    }
  }

  String _lrLabel(String s) {
    switch (s) {
      case 'CREATED':       return 'Created';
      case 'WEIGHT_LOADED': return 'Loaded';
      case 'IN_TRANSIT':    return 'In Transit';
      case 'DELIVERED':     return 'Delivered';
      case 'INVOICED':      return 'Invoiced';
      default:              return s;
    }
  }
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────
class _InvoicesTab extends StatelessWidget {
  final SupervisorOrderDetailController controller;
  const _InvoicesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final invoices = controller.invoices;
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_outlined,
                size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('No invoices raised yet',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 4),
            Text('Invoices appear here once the order is billed',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: invoices.length,
      itemBuilder: (_, i) => _InvoiceCard(invoice: invoices[i]),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = invoice['invoiceNumber'] as String? ?? '—';
    final status        = invoice['invoiceStatus'] as String? ?? '';
    final invoiceDate   = invoice['invoiceDate']   as String?;
    final dueDate       = invoice['dueDate']        as String?;
    final totalAmount   = invoice['totalAmount'];
    final balanceDue    = invoice['balanceDue'];
    final amountPaid    = invoice['amountPaid'];

    final statusColor = _invoiceColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice number + status
          Row(
            children: [
              Expanded(
                child: Text(invoiceNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(_invoiceLabel(status),
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Amount row
          Row(
            children: [
              Expanded(
                child: _AmountCell(
                    label: 'Total', value: totalAmount, color: AppColors.navy),
              ),
              Expanded(
                child: _AmountCell(
                    label: 'Paid',
                    value: amountPaid,
                    color: AppColors.success),
              ),
              Expanded(
                child: _AmountCell(
                    label: 'Balance',
                    value: balanceDue,
                    color: balanceDue != null &&
                            double.tryParse(balanceDue.toString())! > 0
                        ? AppColors.error
                        : AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dates
          Row(
            children: [
              if (invoiceDate != null) ...[
                _Chip(Icons.calendar_today_outlined,
                    'Issued: ${FerosDateUtils.formatDate(invoiceDate)}'),
                const SizedBox(width: 12),
              ],
              if (dueDate != null)
                _Chip(Icons.event_outlined,
                    'Due: ${FerosDateUtils.formatDate(dueDate)}'),
            ],
          ),
        ],
      ),
    );
  }

  Color _invoiceColor(String s) {
    switch (s) {
      case 'DRAFT':          return AppColors.mutedText;
      case 'SENT':           return AppColors.info;
      case 'PARTIALLY_PAID': return AppColors.warning;
      case 'PAID':           return AppColors.success;
      case 'OVERDUE':        return AppColors.error;
      case 'CANCELLED':      return AppColors.error;
      default:               return AppColors.mutedText;
    }
  }

  String _invoiceLabel(String s) {
    switch (s) {
      case 'DRAFT':          return 'Draft';
      case 'SENT':           return 'Sent';
      case 'PARTIALLY_PAID': return 'Part. Paid';
      case 'PAID':           return 'Paid';
      case 'OVERDUE':        return 'Overdue';
      case 'CANCELLED':      return 'Cancelled';
      default:               return s;
    }
  }
}

class _AmountCell extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _AmountCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final amount = value != null
        ? '₹${double.tryParse(value.toString())?.toStringAsFixed(0) ?? value}'
        : '₹0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        const SizedBox(height: 2),
        Text(amount,
            style: AppTextStyles.bodyMedium
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}
