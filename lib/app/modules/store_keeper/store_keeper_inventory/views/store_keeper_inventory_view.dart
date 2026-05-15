import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_search_bar.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../../store_keeper_dashboard/controllers/store_keeper_dashboard_controller.dart';
import '../../store_keeper_dashboard/views/store_keeper_dashboard_view.dart'
    show StockInSheet;
import '../../store_keeper_dashboard/views/store_keeper_part_detail_view.dart';
import '../../store_keeper_requests/controllers/store_keeper_requests_controller.dart';

class StoreKeeperInventoryView extends StatelessWidget {
  const StoreKeeperInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppColors.navy,
              unselectedLabelColor: AppColors.mutedText,
              indicatorColor: AppColors.navy,
              indicatorWeight: 2.5,
              labelStyle: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              tabs: const [
                Tab(text: 'Parts'),
                Tab(text: 'Requests'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _PartsTab(),
                _RequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parts Tab ──────────────────────────────────────────────────────────────────
class _PartsTab extends StatelessWidget {
  const _PartsTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StoreKeeperDashboardController>();
    return Obx(() {
      if (ctrl.isLoading.value) return const ShimmerList(count: 6);
      return RefreshIndicator(
        onRefresh: ctrl.fetchAll,
        color: AppColors.navy,
        child: Obx(() {
          final items = ctrl.filteredItems;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Search + New Part
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: FerosSearchBar(
                              hint: 'Search by part name, number, category…',
                              onChanged: ctrl.onSearch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showAddPartSheet(context, ctrl),
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 4),
                                  Text('New Part',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Low stock banner
                  if (ctrl.filterLow.value)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_outlined,
                                  size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Showing low stock items only',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFFDC2626))),
                              ),
                              GestureDetector(
                                onTap: ctrl.toggleLowStockFilter,
                                child: const Text('Clear',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFFDC2626),
                                        decoration:
                                            TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Parts list
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: items.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      size: 52, color: AppColors.border),
                                  const SizedBox(height: 12),
                                  Text(
                                    ctrl.filterLow.value
                                        ? 'No low stock items'
                                        : 'No stock records found',
                                    style: AppTextStyles.body.copyWith(
                                        color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _StockCard(
                                item: items[i],
                                onTap: () => Get.to(
                                  () => StoreKeeperPartDetailView(
                                      item: items[i]),
                                  transition: Transition.cupertino,
                                ),
                              ),
                              childCount: items.length,
                            ),
                          ),
                  ),
                ],
              ),

              // Stock In FAB
              Positioned(
                right: 16,
                bottom: 24,
                child: FloatingActionButton.extended(
                  onPressed: () => _showStockInSheet(context, ctrl),
                  backgroundColor: AppColors.navy,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Stock In',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        }),
      );
    });
  }

  void _showStockInSheet(
      BuildContext context, StoreKeeperDashboardController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockInSheet(controller: ctrl),
    );
  }

  void _showAddPartSheet(
      BuildContext context, StoreKeeperDashboardController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPartSheet(controller: ctrl),
    );
  }
}

// ── Stock Card ─────────────────────────────────────────────────────────────────
class _StockCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _StockCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final partName   = item['partName']   as String? ?? '—';
    final partNumber = item['partNumber'] as String? ?? '';
    final category   = item['category']  as String? ?? '';
    final quantity   = (item['quantity'] as num? ?? 0).toInt();
    final unit       = item['unit']      as String? ?? '';
    final isLow      = item['isLowStock'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLow
                ? const Color(0xFFFECACA)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Left — name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partName,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (partNumber.isNotEmpty || category.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (partNumber.isNotEmpty)
                          Flexible(
                            child: Text(partNumber,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        if (partNumber.isNotEmpty && category.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·',
                                style: TextStyle(
                                    color: AppColors.border, fontSize: 12)),
                          ),
                        if (category.isNotEmpty)
                          Flexible(
                            child: Text(category,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right — qty + badge
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$quantity',
                        style: AppTextStyles.heading3.copyWith(
                            color: isLow
                                ? const Color(0xFFDC2626)
                                : AppColors.navy)),
                  ),
                  Text(unit,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                  if (isLow)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Low',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626))),
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

// ── Add Part Sheet ─────────────────────────────────────────────────────────────
class _AddPartSheet extends StatefulWidget {
  final StoreKeeperDashboardController controller;
  const _AddPartSheet({required this.controller});

  @override
  State<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends State<_AddPartSheet> {
  final _nameCtrl       = TextEditingController();
  final _partNumCtrl    = TextEditingController();
  final _categoryCtrl   = TextEditingController();
  final _minStockCtrl   = TextEditingController(text: '1');
  String _unit          = 'PCS';
  bool _submitting      = false;
  String? _error;

  static const _units = ['PCS', 'LITRE', 'KG', 'METRE', 'SET', 'BOX', 'PAIR'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _partNumCtrl.dispose();
    _categoryCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Part name is required');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final ok = await widget.controller.submitNewPart(
      name: name,
      partNumber: _partNumCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      unit: _unit,
      minStockLevel: int.tryParse(_minStockCtrl.text.trim()) ?? 1,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar('Done', '$name added to inventory',
          backgroundColor: const Color(0xFF16A34A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
    } else {
      setState(() => _error = 'Failed to add part. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text('Add New Part',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.navy)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.mutedText, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFDC2626)))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _label('Part Name *'),
                    _field(_nameCtrl, 'e.g. Engine Oil Filter'),
                    const SizedBox(height: 14),
                    _label('Part Number'),
                    _field(_partNumCtrl, 'e.g. OF-2201'),
                    const SizedBox(height: 14),
                    _label('Category'),
                    _field(_categoryCtrl, 'e.g. Filters, Lubricants'),
                    const SizedBox(height: 14),
                    _label('Unit *'),
                    DropdownButtonFormField<String>(
                      value: _unit,
                      onChanged: (v) => setState(() => _unit = v!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.navy)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      items: _units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Min Stock Level'),
                    _field(_minStockCtrl, '1',
                        type: TextInputType.number),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text('Add Part',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: AppTextStyles.body.copyWith(color: AppColors.navy),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.navy)),
          filled: true,
          fillColor: AppColors.background,
        ),
      );
}

// ── Requests Tab ───────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StoreKeeperRequestsController>();
    return Obx(() {
      if (ctrl.isLoading.value) return const ShimmerList(count: 5);
      return RefreshIndicator(
        onRefresh: ctrl.fetchRequests,
        color: AppColors.navy,
        child: Obx(() {
          final items = ctrl.filteredRequests;
          return CustomScrollView(
            slivers: [
              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: FerosSearchBar(
                    hint: 'Search by part, requester, vehicle…',
                    onChanged: ctrl.onSearch,
                  ),
                ),
              ),

              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions_outlined,
                            size: 52, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text('No requests found',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final req = items[i];
                        final status =
                            req['status'] as String? ?? 'REQUESTED';
                        final isPending = status == 'REQUESTED';
                        return _RequestCard(
                          request: req,
                          onTap: isPending
                              ? () => _showActionSheet(context, req, ctrl)
                              : null,
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        }),
      );
    });
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> req,
      StoreKeeperRequestsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveRejectSheet(request: req, controller: ctrl),
    );
  }
}

// ── Request Card ───────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onTap;
  const _RequestCard({required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final partName     = request['partName']           as String? ?? '—';
    final requestedQty = (request['requestedQuantity'] as num? ?? 0).toInt();
    final requestedBy  = request['requestedByName']    as String?;
    final vehicleNo    = request['vehicleNumber']      as String?;
    final serviceName  = request['serviceTaskName']    as String?;
    final createdAt    = request['createdAt']          as String? ?? '';
    final status       = request['status']             as String? ?? 'REQUESTED';
    final approvedQty  = request['quantityApproved']   as num?;
    final rejReason    = request['rejectionReason']    as String?;

    final isPending  = status == 'REQUESTED';
    final isApproved = status == 'APPROVED';

    final Color headerBg;
    final Color borderColor;
    final Color badgeColor;
    final Color badgeText;
    final String badgeLabel;

    if (isPending) {
      headerBg    = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFED7AA);
      badgeColor  = const Color(0xFFFEF3C7);
      badgeText   = const Color(0xFFD97706);
      badgeLabel  = 'PENDING';
    } else if (isApproved) {
      headerBg    = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      badgeColor  = const Color(0xFFDCFCE7);
      badgeText   = const Color(0xFF16A34A);
      badgeLabel  = 'APPROVED';
    } else {
      headerBg    = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      badgeColor  = const Color(0xFFFEE2E2);
      badgeText   = const Color(0xFFDC2626);
      badgeLabel  = 'REJECTED';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badgeLabel,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeText)),
                  ),
                  const Spacer(),
                  Text(_formatDate(createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(partName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$requestedQty units',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (vehicleNo != null)
                    Row(
                      children: [
                        const Icon(Icons.directions_bus_outlined,
                            size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(vehicleNo,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                        if (serviceName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.border)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(serviceName,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mutedText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  if (requestedBy != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text('Requested by $requestedBy',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  ],

                  // Approved info
                  if (isApproved && approvedQty != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 13, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text('${approvedQty.toInt()} units issued',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  // Rejection reason
                  if (!isPending && !isApproved && rejReason != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined,
                            size: 13, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('Reason: $rejReason',
                              style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFDC2626)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],

                  // Pending action hint
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Spacer(),
                        Text('Tap to Approve / Reject',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios,
                            size: 10, color: AppColors.navy),
                      ],
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Approve / Reject Sheet ─────────────────────────────────────────────────────
class _ApproveRejectSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final StoreKeeperRequestsController controller;
  const _ApproveRejectSheet(
      {required this.request, required this.controller});

  @override
  State<_ApproveRejectSheet> createState() => _ApproveRejectSheetState();
}

class _ApproveRejectSheetState extends State<_ApproveRejectSheet> {
  bool _isApprove  = true;
  bool _submitting = false;
  String? _error;

  late final TextEditingController _qtyCtrl;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final requested =
        (widget.request['requestedQuantity'] as num? ?? 1).toInt();
    _qtyCtrl = TextEditingController(text: '$requested');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = widget.request['servicePartId'] as int? ?? 0;
    setState(() { _submitting = true; _error = null; });

    bool ok;
    String successMsg;

    if (_isApprove) {
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
      if (qty < 1) {
        setState(() {
          _submitting = false;
          _error = 'Quantity must be at least 1';
        });
        return;
      }
      ok = await widget.controller.approveRequest(id, qty);
      successMsg = 'Approved — $qty units issued';
    } else {
      final reason = _reasonCtrl.text.trim();
      if (reason.isEmpty) {
        setState(() {
          _submitting = false;
          _error = 'Please provide a rejection reason';
        });
        return;
      }
      ok = await widget.controller.rejectRequest(id, reason);
      successMsg = 'Request rejected';
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Done', successMsg,
        backgroundColor:
            _isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      setState(
          () => _error = 'Failed to process request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final partName = widget.request['partName'] as String? ?? '—';
    final requestedQty =
        (widget.request['requestedQuantity'] as num? ?? 0).toInt();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partName,
                            style: AppTextStyles.heading3
                                .copyWith(color: AppColors.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Requested: $requestedQty units',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.mutedText, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Approve / Reject toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () { _isApprove = true; _error = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isApprove
                                      ? const Color(0xFF16A34A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 16,
                                        color: _isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Approve',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                color: _isApprove
                                                    ? Colors.white
                                                    : AppColors.mutedText,
                                                fontWeight: _isApprove
                                                    ? FontWeight.w600
                                                    : FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () { _isApprove = false; _error = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isApprove
                                      ? const Color(0xFFDC2626)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cancel_outlined,
                                        size: 16,
                                        color: !_isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Reject',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                color: !_isApprove
                                                    ? Colors.white
                                                    : AppColors.mutedText,
                                                fontWeight: !_isApprove
                                                    ? FontWeight.w600
                                                    : FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isApprove) ...[
                      Text('Quantity to Approve',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: '$requestedQty',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.navy)),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],

                    if (!_isApprove) ...[
                      Text('Rejection Reason *',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Insufficient stock, please reorder first…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFDC2626))),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isApprove
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isApprove
                                    ? 'Confirm Approval'
                                    : 'Confirm Rejection',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
