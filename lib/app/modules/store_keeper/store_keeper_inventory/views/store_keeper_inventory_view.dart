import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/feros_search_bar.dart';
import '../../../../../core/widgets/feros_select_field.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../office/office_inventory/controllers/office_inventory_controller.dart';

class StoreKeeperInventoryView extends StatefulWidget {
  const StoreKeeperInventoryView({super.key});

  @override
  State<StoreKeeperInventoryView> createState() =>
      _StoreKeeperInventoryViewState();
}

class _StoreKeeperInventoryViewState extends State<StoreKeeperInventoryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final OfficeInventoryController _ctrl;

  bool get _isAdmin =>
      Get.find<AuthService>().user?.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _ctrl = Get.put(OfficeInventoryController());
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab Bar ──────────────────────────────────────────────────────────
        Obx(() => Container(
          color: AppColors.navy,
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'lbl_stock'.tr),
              Tab(text: 'lbl_parts'.tr),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('lbl_requests'.tr),
                    if (_ctrl.pendingPartCount + _ctrl.pendingTyreCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(_ctrl.pendingPartCount + _ctrl.pendingTyreCount),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tab,
                children: [
                  _StockTab(ctrl: _ctrl),
                  _PartsTab(ctrl: _ctrl),
                  _RequestsTab(ctrl: _ctrl),
                ],
              ),
              // FAB overlay
              if (_tab.index == 0)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showStockInSheet(context, _ctrl),
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: Text('btn_add_stock'.tr),
                  ),
                ),
              if (_tab.index == 1 && _isAdmin)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showPartSheet(context, _ctrl),
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: Text('btn_add_part'.tr),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

// ─── Stat Mini Card ───────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool active;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.orange : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTextStyles.heading3.copyWith(
                      color: valueColor ?? AppColors.bodyText,
                      fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — STOCK
// ═══════════════════════════════════════════════════════════════════════════════
class _StockTab extends StatelessWidget {
  final OfficeInventoryController ctrl;
  const _StockTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = ctrl.stockState.value;
      return RefreshIndicator(
        onRefresh: ctrl.fetchStock,
        color: AppColors.navy,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'lbl_total_items'.tr,
                          value: '${ctrl.stockItems.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'lbl_in_stock'.tr,
                          value: '${ctrl.inStockCount}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'lbl_low_stock'.tr,
                          value: '${ctrl.lowStockCount}',
                          valueColor: AppColors.error,
                          onTap: ctrl.toggleLowStock,
                          active: ctrl.stockLowOnly.value,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (ctrl.stockLowOnly.value)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: AppColors.error),
                            const SizedBox(width: 6),
                            Text('lbl_showing_low_stock'.tr,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                            const Spacer(),
                            GestureDetector(
                              onTap: ctrl.toggleLowStock,
                              child: Text('lbl_clear'.tr,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.error,
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ),
                    FerosSearchBar(
                      hint: 'lbl_search_stock'.tr,
                      onChanged: ctrl.setStockSearch,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state == ViewState.loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerCard()),
                    childCount: 6,
                  ),
                ),
              )
            else if (ctrl.filteredStock.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 8),
                      Text('lbl_no_stock_records'.tr,
                          style: const TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _StockRow(item: ctrl.filteredStock[i]),
                    childCount: ctrl.filteredStock.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StockRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _StockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLow    = item['isLowStock'] == true;
    final qty      = (item['quantity'] as num? ?? 0).toInt();
    final minQty   = (item['minStockLevel'] as num? ?? 0).toInt();
    final partName = item['partName'] as String? ?? '';
    final partNo   = item['partNumber'] as String?;
    final category = item['category'] as String?;
    final unit     = item['unit'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLow
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (partNo != null || category != null)
                  Text(
                    [partNo, category]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$qty',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLow ? AppColors.error : AppColors.bodyText,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: ' / $minQty $unit',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLow
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLow ? 'lbl_low'.tr : 'lbl_ok'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: isLow ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — SPARE PARTS
// ═══════════════════════════════════════════════════════════════════════════════
class _PartsTab extends StatelessWidget {
  final OfficeInventoryController ctrl;
  const _PartsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = ctrl.partsState.value;
      return RefreshIndicator(
        onRefresh: ctrl.fetchParts,
        color: AppColors.navy,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'lbl_total_parts'.tr,
                          value: '${ctrl.spareParts.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'lbl_active'.tr,
                          value: '${ctrl.activeParts}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'lbl_categories'.tr,
                          value: '${ctrl.categoryCount}',
                          valueColor: AppColors.navy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FerosSearchBar(
                      hint: 'lbl_search_parts'.tr,
                      onChanged: ctrl.setPartsSearch,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state == ViewState.loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerCard()),
                    childCount: 6,
                  ),
                ),
              )
            else if (ctrl.filteredParts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_outlined,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 8),
                      Text('lbl_no_spare_parts_found'.tr,
                          style: const TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PartRow(
                      part: ctrl.filteredParts[i],
                      isAdmin:
                          Get.find<AuthService>().user?.role == 'ADMIN',
                      onEdit: (p) =>
                          _showPartSheet(context, ctrl, part: p),
                    ),
                    childCount: ctrl.filteredParts.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _PartRow extends StatelessWidget {
  final Map<String, dynamic> part;
  final bool isAdmin;
  final void Function(Map<String, dynamic>) onEdit;
  const _PartRow(
      {required this.part, required this.isAdmin, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isActive = part['isActive'] as bool? ?? true;
    final name     = part['name'] as String? ?? '';
    final partNo   = part['partNumber'] as String?;
    final category = part['category'] as String?;
    final unit     = part['unit'] as String? ?? '';
    final minStock = (part['minStockLevel'] as num? ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'lbl_active'.tr : 'lbl_inactive'.tr,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? AppColors.success
                              : AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (partNo != null && partNo.isNotEmpty)
                      Text(partNo,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    if (category != null && category.isNotEmpty)
                      Text(category,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    Text('$unit · ${'lbl_min'.tr} $minStock',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.navy,
              onPressed: () => onEdit(part),
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — REQUESTS
// ═══════════════════════════════════════════════════════════════════════════════
class _RequestsTab extends StatefulWidget {
  final OfficeInventoryController ctrl;
  const _RequestsTab({required this.ctrl});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && widget.ctrl.availableTyres.isEmpty) {
        widget.ctrl.fetchAvailableTyres();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.orange,
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.mutedText,
            labelStyle: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('lbl_part_requests'.tr),
                    if (widget.ctrl.pendingPartCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(widget.ctrl.pendingPartCount),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('lbl_tyre_requests'.tr),
                    if (widget.ctrl.pendingTyreCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(widget.ctrl.pendingTyreCount),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _PartRequestsList(ctrl: widget.ctrl),
              _TyreRequestsList(ctrl: widget.ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartRequestsList extends StatelessWidget {
  final OfficeInventoryController ctrl;
  const _PartRequestsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state    = ctrl.requestsState.value;
      final requests = ctrl.pendingPartRequests;

      if (state == ViewState.loading) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10), child: ShimmerCard()),
        );
      }

      return RefreshIndicator(
        onRefresh: ctrl.fetchPartRequests,
        color: AppColors.navy,
        child: requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.black26),
                    const SizedBox(height: 8),
                    Text('lbl_no_pending_part_requests'.tr,
                        style: const TextStyle(color: Colors.black45)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (_, i) => _PartReqCard(
                  request: requests[i],
                  ctrl: ctrl,
                ),
              ),
      );
    });
  }
}

class _PartReqCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final OfficeInventoryController ctrl;
  const _PartReqCard({required this.request, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final partName  = request['partName']    as String? ?? '';
    final partNo    = request['partNumber']  as String?;
    final serviceNo = request['serviceNumber'] as String? ?? '';
    final vehicle   = request['vehicleRegistrationNumber'] as String? ?? '';
    final reqBy     = request['requestedByName'] as String? ?? '';
    final qtyReq    = (request['quantityRequested'] as num? ?? 0).toInt();
    final unit      = request['unit'] as String? ?? '';
    final id        = (request['id'] as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(partName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$qtyReq $unit',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (partNo != null && partNo.isNotEmpty)
            Text(partNo,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 8),
          _InfoRow(Icons.build_circle_outlined, serviceNo),
          _InfoRow(Icons.directions_car_outlined, vehicle),
          _InfoRow(Icons.person_outline, reqBy),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPartReqSheet(context, ctrl, id, qtyReq),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: Text('btn_process'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.navy.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TyreRequestsList extends StatelessWidget {
  final OfficeInventoryController ctrl;
  const _TyreRequestsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state    = ctrl.tyreReqState.value;
      final requests = ctrl.tyreRequests;

      if (state == ViewState.loading) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10), child: ShimmerCard()),
        );
      }

      return RefreshIndicator(
        onRefresh: ctrl.fetchTyreRequests,
        color: AppColors.navy,
        child: requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tire_repair_outlined,
                        size: 48, color: Colors.black26),
                    const SizedBox(height: 8),
                    Text('lbl_no_pending_tyre_requests'.tr,
                        style: const TextStyle(color: Colors.black45)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (_, i) => _TyreReqCard(
                  request: requests[i],
                  ctrl: ctrl,
                ),
              ),
      );
    });
  }
}

class _TyreReqCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final OfficeInventoryController ctrl;
  const _TyreReqCard({required this.request, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final vehicle  = request['vehicleRegistrationNumber'] as String? ?? '';
    final position = request['positionCode']  as String? ?? '';
    final reqBy    = request['requestedByName'] as String? ?? '';
    final notes    = request['notes'] as String?;
    final id       = (request['id'] as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tire_repair_outlined,
                  size: 18, color: Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: Text(vehicle,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(Icons.location_on_outlined, '${'lbl_position'.tr}: $position'),
          _InfoRow(Icons.person_outline, reqBy),
          if (notes != null && notes.isNotEmpty)
            _InfoRow(Icons.notes_outlined, notes),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showTyreReqSheet(context, ctrl, id, request),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: Text('btn_process'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.navy.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row helper ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.mutedText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.bodyText)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Stock In Sheet ────────────────────────────────────────────────────────────
void _showStockInSheet(
    BuildContext context, OfficeInventoryController ctrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockInSheet(ctrl: ctrl),
  );
}

class _StockInSheet extends StatefulWidget {
  final OfficeInventoryController ctrl;
  const _StockInSheet({required this.ctrl});

  @override
  State<_StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends State<_StockInSheet> {
  Map<String, dynamic>? _selectedPart;
  final _qtyCtrl      = TextEditingController(text: '1');
  final _costCtrl     = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPart == null) return;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty < 1) return;

    setState(() => _loading = true);
    try {
      await widget.ctrl.stockIn({
        'sparePartId': (_selectedPart!['id'] as num).toInt(),
        'quantity': qty,
        if (_costCtrl.text.trim().isNotEmpty)
          'unitCost': double.tryParse(_costCtrl.text.trim()),
        if (_supplierCtrl.text.trim().isNotEmpty)
          'supplierName': _supplierCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        Get.back();
        FerosSnackbar.success('Stock added successfully');
      }
    } catch (e) {
      if (mounted) FerosSnackbar.error('Failed to add stock');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('lbl_add_stock_in'.tr,
                      style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FerosSelectField<Map<String, dynamic>>(
                      label: 'lbl_spare_part'.tr,
                      title: 'lbl_select_spare_part_title'.tr,
                      hint: 'lbl_select_part'.tr,
                      isRequired: true,
                      items: widget.ctrl.spareParts,
                      itemLabel: (p) => p['name'] as String? ?? '',
                      selectedDisplay: _selectedPart != null
                          ? (_selectedPart!['name'] as String? ?? '')
                          : null,
                      onSelected: (p) =>
                          setState(() => _selectedPart = p),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field('${'lbl_quantity'.tr} *', _qtyCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ])),
                        const SizedBox(width: 12),
                        Expanded(child: _field('lbl_unit_cost'.tr, _costCtrl,
                            hint: 'lbl_optional'.tr,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field('lbl_supplier_name'.tr, _supplierCtrl,
                        hint: 'lbl_optional'.tr),
                    const SizedBox(height: 16),
                    _field('lbl_notes'.tr, _notesCtrl, hint: 'lbl_optional'.tr),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_loading || _selectedPart == null)
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('btn_add_stock'.tr,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spare Part Create / Edit Sheet ────────────────────────────────────────────
void _showPartSheet(
    BuildContext context, OfficeInventoryController ctrl,
    {Map<String, dynamic>? part}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SparePartSheet(ctrl: ctrl, part: part),
  );
}

class _SparePartSheet extends StatefulWidget {
  final OfficeInventoryController ctrl;
  final Map<String, dynamic>? part;
  const _SparePartSheet({required this.ctrl, this.part});

  @override
  State<_SparePartSheet> createState() => _SparePartSheetState();
}

class _SparePartSheetState extends State<_SparePartSheet> {
  final _nameCtrl     = TextEditingController();
  final _partNoCtrl   = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController(text: '0');
  String _unit = 'Pieces';
  bool _loading = false;

  static const _units = ['Pieces', 'Litres', 'Kg', 'Metres', 'Sets', 'Pairs'];
  bool get _isEdit => widget.part != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text     = widget.part!['name'] as String? ?? '';
      _partNoCtrl.text   = widget.part!['partNumber'] as String? ?? '';
      _categoryCtrl.text = widget.part!['category'] as String? ?? '';
      _unit              = widget.part!['unit'] as String? ?? 'Pieces';
      _minStockCtrl.text =
          '${(widget.part!['minStockLevel'] as num? ?? 0).toInt()}';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _partNoCtrl.dispose();
    _categoryCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final body = {
      'name': name,
      if (_partNoCtrl.text.trim().isNotEmpty)
        'partNumber': _partNoCtrl.text.trim(),
      if (_categoryCtrl.text.trim().isNotEmpty)
        'category': _categoryCtrl.text.trim(),
      'unit': _unit,
      'minStockLevel':
          int.tryParse(_minStockCtrl.text.trim()) ?? 0,
    };
    try {
      if (_isEdit) {
        await widget.ctrl
            .editPart((widget.part!['id'] as num).toInt(), body);
      } else {
        await widget.ctrl.createPart(body);
      }
      if (mounted) {
        Get.back();
        FerosSnackbar.success(
            _isEdit ? 'Part updated' : 'Part created');
      }
    } catch (e) {
      if (mounted) FerosSnackbar.error('Failed to save part');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(_isEdit ? 'lbl_edit_spare_part'.tr : 'lbl_add_spare_part'.tr,
                      style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('${'lbl_name'.tr} *', _nameCtrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field('lbl_part_number'.tr,
                            _partNoCtrl, hint: 'lbl_optional'.tr)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('lbl_category'.tr,
                            _categoryCtrl, hint: 'e.g. Engine')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${'lbl_unit'.tr} *',
                                  style: AppTextStyles.label.copyWith(
                                      color: AppColors.bodyText)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _unit,
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => _unit = v ?? _unit),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field('lbl_min_stock_alert'.tr, _minStockCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'btn_update'.tr : 'btn_create'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Part Request Process Sheet ────────────────────────────────────────────────
void _showPartReqSheet(BuildContext context, OfficeInventoryController ctrl,
    int id, int qtyReq) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PartReqSheet(ctrl: ctrl, id: id, qtyRequested: qtyReq),
  );
}

class _PartReqSheet extends StatefulWidget {
  final OfficeInventoryController ctrl;
  final int id;
  final int qtyRequested;
  const _PartReqSheet(
      {required this.ctrl, required this.id, required this.qtyRequested});

  @override
  State<_PartReqSheet> createState() => _PartReqSheetState();
}

class _PartReqSheetState extends State<_PartReqSheet> {
  bool _approve = true;
  late final TextEditingController _qtyCtrl;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl =
        TextEditingController(text: '${widget.qtyRequested}');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_approve) {
        await widget.ctrl.approvePartRequest(
            widget.id, int.tryParse(_qtyCtrl.text.trim()) ?? 1);
        if (mounted) {
          Get.back();
          FerosSnackbar.success('Part approved, stock deducted');
        }
      } else {
        final reason = _reasonCtrl.text.trim();
        if (reason.isEmpty) {
          setState(() => _loading = false);
          return;
        }
        await widget.ctrl.rejectPartRequest(widget.id, reason);
        if (mounted) {
          Get.back();
          FerosSnackbar.success('Request rejected');
        }
      }
    } catch (e) {
      if (mounted) FerosSnackbar.error('Failed to process request');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('lbl_process_part_request'.tr,
                style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _approve = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _approve
                            ? AppColors.success
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _approve
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✓ ${'btn_approve'.tr}',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: _approve
                                    ? Colors.white
                                    : AppColors.bodyText,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _approve = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_approve
                            ? AppColors.error
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_approve
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✗ ${'btn_reject'.tr}',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: !_approve
                                    ? Colors.white
                                    : AppColors.bodyText,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_approve)
              _field('${'lbl_qty_to_approve'.tr} *', _qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ])
            else
              _field('${'lbl_rejection_reason'.tr} *', _reasonCtrl,
                  hint: 'lbl_reason_for_rejection'.tr),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _approve ? AppColors.success : AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _approve
                            ? 'btn_approve_deduct_stock'.tr
                            : 'btn_reject_request'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Tyre Request Process Sheet ────────────────────────────────────────────────
void _showTyreReqSheet(BuildContext context, OfficeInventoryController ctrl,
    int id, Map<String, dynamic> request) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _TyreReqSheet(ctrl: ctrl, id: id, request: request),
  );
}

class _TyreReqSheet extends StatefulWidget {
  final OfficeInventoryController ctrl;
  final int id;
  final Map<String, dynamic> request;
  const _TyreReqSheet(
      {required this.ctrl, required this.id, required this.request});

  @override
  State<_TyreReqSheet> createState() => _TyreReqSheetState();
}

class _TyreReqSheetState extends State<_TyreReqSheet> {
  bool _approve = true;
  Map<String, dynamic>? _selectedTyre;
  final _kmCtrl     = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _kmCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_approve) {
        if (_selectedTyre == null) {
          setState(() => _loading = false);
          return;
        }
        await widget.ctrl.approveTyreRequest(widget.id, {
          'tyreId': (_selectedTyre!['id'] as num).toInt(),
          if (_kmCtrl.text.trim().isNotEmpty)
            'fittedAtKm': int.tryParse(_kmCtrl.text.trim()),
        });
        if (mounted) {
          Get.back();
          FerosSnackbar.success('Tyre issued and fitted');
        }
      } else {
        final reason = _reasonCtrl.text.trim();
        if (reason.isEmpty) {
          setState(() => _loading = false);
          return;
        }
        await widget.ctrl.rejectTyreRequest(widget.id, reason);
        if (mounted) {
          Get.back();
          FerosSnackbar.success('Tyre request rejected');
        }
      }
    } catch (e) {
      if (mounted) FerosSnackbar.error('Failed to process request');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle  =
        widget.request['vehicleRegistrationNumber'] as String? ?? '';
    final position =
        widget.request['positionCode'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('lbl_process_tyre_request'.tr,
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _InfoRow(Icons.directions_car_outlined, vehicle),
                  _InfoRow(Icons.location_on_outlined,
                      '${'lbl_position'.tr}: $position'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _approve = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _approve
                            ? AppColors.success
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _approve
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✓ ${'btn_approve'.tr}',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: _approve
                                    ? Colors.white
                                    : AppColors.bodyText,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _approve = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_approve
                            ? AppColors.error
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_approve
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✗ ${'btn_reject'.tr}',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: !_approve
                                    ? Colors.white
                                    : AppColors.bodyText,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_approve) ...[
              Obx(() => FerosSelectField<Map<String, dynamic>>(
                label: '${'lbl_select_tyre_to_issue'.tr} *',
                title: 'lbl_available_tyres'.tr,
                hint: 'lbl_search_by_serial'.tr,
                isRequired: true,
                items: widget.ctrl.availableTyres,
                itemLabel: (t) {
                  final serial = t['serialNumber'] as String? ?? '';
                  final brand  = t['brand'] as String? ?? '';
                  final size   = t['size'] as String? ?? '';
                  return '$serial${brand.isNotEmpty ? ' · $brand' : ''}${size.isNotEmpty ? ' ($size)' : ''}';
                },
                selectedDisplay: _selectedTyre != null
                    ? (_selectedTyre!['serialNumber'] as String? ?? '')
                    : null,
                onSelected: (t) => setState(() => _selectedTyre = t),
              )),
              const SizedBox(height: 12),
              _field('lbl_fitted_at_km'.tr, _kmCtrl,
                  hint: 'lbl_optional'.tr,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ]),
            ] else
              _field('${'lbl_rejection_reason'.tr} *', _reasonCtrl,
                  hint: 'lbl_reason_for_rejection'.tr),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _approve ? AppColors.success : AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _approve
                            ? 'btn_approve_issue_tyre'.tr
                            : 'btn_reject_request'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Shared field builder ─────────────────────────────────────────────────────
Widget _field(
  String label,
  TextEditingController ctrl, {
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: AppTextStyles.label.copyWith(color: AppColors.bodyText)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.navy, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
