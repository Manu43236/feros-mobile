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
import '../controllers/office_inventory_controller.dart';

class OfficeInventoryView extends StatefulWidget {
  const OfficeInventoryView({super.key});

  @override
  State<OfficeInventoryView> createState() => _OfficeInventoryViewState();
}

class _OfficeInventoryViewState extends State<OfficeInventoryView>
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Obx(() => TabBar(
            controller: _tab,
            indicatorColor: AppColors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Stock'),
              const Tab(text: 'Parts'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (_ctrl.pendingPartCount + _ctrl.pendingTyreCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(_ctrl.pendingPartCount + _ctrl.pendingTyreCount),
                    ],
                  ],
                ),
              ),
            ],
          )),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _StockTab(ctrl: _ctrl),
          _PartsTab(ctrl: _ctrl),
          _RequestsTab(ctrl: _ctrl),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: () => _showStockInSheet(context, _ctrl),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      );
    }
    if (_tab.index == 1 && _isAdmin) {
      return FloatingActionButton.extended(
        onPressed: () => _showPartSheet(context, _ctrl),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Part'),
      );
    }
    return null;
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
                    // Stat row
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Items',
                          value: '${ctrl.stockItems.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'In Stock',
                          value: '${ctrl.inStockCount}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'Low Stock',
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
                            Text('Showing low stock only',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                            const Spacer(),
                            GestureDetector(
                              onTap: ctrl.toggleLowStock,
                              child: Text('Clear',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.error,
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ),
                    FerosSearchBar(
                      hint: 'Search stock…',
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
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.black26),
                      SizedBox(height: 8),
                      Text('No stock records',
                          style: TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
    final isLow   = item['isLowStock'] == true;
    final qty     = (item['quantity'] as num? ?? 0).toInt();
    final minQty  = (item['minStockLevel'] as num? ?? 0).toInt();
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
                  isLow ? 'Low' : 'OK',
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
                          label: 'Total Parts',
                          value: '${ctrl.spareParts.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'Active',
                          value: '${ctrl.activeParts}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'Categories',
                          value: '${ctrl.categoryCount}',
                          valueColor: AppColors.navy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FerosSearchBar(
                      hint: 'Search parts…',
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
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build_outlined,
                          size: 48, color: Colors.black26),
                      SizedBox(height: 8),
                      Text('No spare parts found',
                          style: TextStyle(color: Colors.black45)),
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
                      isAdmin: Get.find<AuthService>().user?.role == 'ADMIN',
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
                        isActive ? 'Active' : 'Inactive',
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
                    Text('$unit · min $minStock',
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
                    const Text('Part Requests'),
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
                    const Text('Tyre Requests'),
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

// Part requests list
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
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.black26),
                    SizedBox(height: 8),
                    Text('No pending part requests',
                        style: TextStyle(color: Colors.black45)),
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
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
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
              label: const Text('Process'),
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

// Tyre requests list
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
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tire_repair_outlined,
                        size: 48, color: Colors.black26),
                    SizedBox(height: 8),
                    Text('No pending tyre requests',
                        style: TextStyle(color: Colors.black45)),
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
          _InfoRow(Icons.location_on_outlined, 'Position: $position'),
          _InfoRow(Icons.person_outline, reqBy),
          if (notes != null && notes.isNotEmpty)
            _InfoRow(Icons.notes_outlined, notes),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showTyreReqSheet(context, ctrl, id, request),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Process'),
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
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
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
void _showStockInSheet(BuildContext context, OfficeInventoryController ctrl) {
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
      if (mounted) {
        FerosSnackbar.error('Failed to add stock');
      }
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
            // Handle
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
                  Text('Add Stock (Stock In)',
                      style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
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
                      label: 'Spare Part',
                      title: 'Select Spare Part',
                      hint: 'Select part',
                      isRequired: true,
                      items: widget.ctrl.spareParts,
                      itemLabel: (p) => p['name'] as String? ?? '',
                      selectedDisplay: _selectedPart != null
                          ? (_selectedPart!['name'] as String? ?? '')
                          : null,
                      onSelected: (p) => setState(() => _selectedPart = p),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field(
                          'Quantity *',
                          _qtyCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _field(
                          'Unit Cost (₹)',
                          _costCtrl,
                          hint: 'Optional',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field('Supplier Name', _supplierCtrl, hint: 'Optional'),
                    const SizedBox(height: 16),
                    _field('Notes', _notesCtrl, hint: 'Optional'),
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
                    onPressed: (_loading || _selectedPart == null) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Add Stock',
                            style: TextStyle(fontWeight: FontWeight.w600)),
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
      _minStockCtrl.text = '${(widget.part!['minStockLevel'] as num? ?? 0).toInt()}';
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
      if (_partNoCtrl.text.trim().isNotEmpty) 'partNumber': _partNoCtrl.text.trim(),
      if (_categoryCtrl.text.trim().isNotEmpty) 'category': _categoryCtrl.text.trim(),
      'unit': _unit,
      'minStockLevel': int.tryParse(_minStockCtrl.text.trim()) ?? 0,
    };

    try {
      if (_isEdit) {
        final id = (widget.part!['id'] as num).toInt();
        await widget.ctrl.editPart(id, body);
      } else {
        await widget.ctrl.createPart(body);
      }
      if (mounted) {
        Get.back();
        FerosSnackbar.success(_isEdit ? 'Part updated' : 'Part created');
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
                  Text(_isEdit ? 'Edit Spare Part' : 'Add Spare Part',
                      style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
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
                    _field('Name *', _nameCtrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field('Part Number', _partNoCtrl, hint: 'Optional')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Category', _categoryCtrl, hint: 'e.g. Engine')),
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
                              Text('Unit *',
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.bodyText)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _unit,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: AppColors.border),
                                  ),
                                ),
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _unit = v ?? _unit),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'Min Stock Alert',
                            _minStockCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
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
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Update' : 'Create',
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
void _showPartReqSheet(
    BuildContext context, OfficeInventoryController ctrl, int id, int qtyReq) {
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
    _qtyCtrl = TextEditingController(text: '${widget.qtyRequested}');
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
        final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
        await widget.ctrl.approvePartRequest(widget.id, qty);
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Container(
                alignment: Alignment.center,
                child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Process Part Request', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            // Approve / Reject toggle
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
                        child: Text('✓ Approve',
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
                          color:
                              !_approve ? AppColors.error : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✗ Reject',
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
              _field('Quantity to Approve *', _qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly])
            else
              _field('Rejection Reason *', _reasonCtrl,
                  hint: 'Reason for rejection…'),
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
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _approve
                            ? 'Approve & Deduct Stock'
                            : 'Reject Request',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final vehicle  = widget.request['vehicleRegistrationNumber'] as String? ?? '';
    final position = widget.request['positionCode'] as String? ?? '';

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
            Container(
                alignment: Alignment.center,
                child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Process Tyre Request', style: AppTextStyles.heading3),
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
                  _InfoRow(Icons.location_on_outlined, 'Position: $position'),
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
                        color: _approve ? AppColors.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _approve ? AppColors.success : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✓ Approve',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: _approve ? Colors.white : AppColors.bodyText,
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
                        color: !_approve ? AppColors.error : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_approve ? AppColors.error : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text('✗ Reject',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: !_approve ? Colors.white : AppColors.bodyText,
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
                label: 'Select Tyre to Issue *',
                title: 'Available Tyres',
                hint: 'Search by serial number…',
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
              _field('Fitted at Km', _kmCtrl,
                  hint: 'Optional',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ] else
              _field('Rejection Reason *', _reasonCtrl,
                  hint: 'Reason for rejection…'),
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
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _approve
                            ? 'Approve & Issue Tyre'
                            : 'Reject Request',
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
          style: AppTextStyles.label
              .copyWith(color: AppColors.bodyText)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
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
