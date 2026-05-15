import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/feros_search_bar.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/store_keeper_dashboard_controller.dart';
import 'store_keeper_part_detail_view.dart';

class StoreKeeperDashboardView extends GetView<StoreKeeperDashboardController> {
  const StoreKeeperDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ShimmerList(count: 6);
      }
      return RefreshIndicator(
        onRefresh: controller.fetchAll,
        color: AppColors.navy,
        child: Obx(() {
          final items = controller.filteredItems;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Search bar ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.navy,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FerosSearchBar(
                              hint: 'Search by part name, number, category…',
                              onChanged: controller.onSearch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showAddPartSheet(context),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 18),
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

                  // ── Summary cards ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _SummaryCard(
                            label: 'Total Parts',
                            value: '${controller.totalItems}',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.navy,
                          ),
                          _SummaryCard(
                            label: 'In Stock',
                            value: '${controller.inStockCount}',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF16A34A),
                          ),
                          GestureDetector(
                            onTap: controller.toggleLowStockFilter,
                            child: _SummaryCard(
                              label: 'Low Stock',
                              value: '${controller.lowStockCount}',
                              icon: Icons.warning_amber_outlined,
                              color: const Color(0xFFDC2626),
                              isActive: controller.filterLow.value,
                            ),
                          ),
                          _SummaryCard(
                            label: 'Pending Requests',
                            value: '${controller.pendingCount.value}',
                            icon: Icons.pending_actions_outlined,
                            color: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Low stock banner ─────────────────────────────
                  if (controller.filterLow.value)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
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
                                onTap: controller.toggleLowStockFilter,
                                child: const Text('Clear',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFFDC2626),
                                        decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Stock list ───────────────────────────────────
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
                                    controller.filterLow.value
                                        ? 'No low stock items'
                                        : 'No stock records found',
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.mutedText),
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
                                  () => StoreKeeperPartDetailView(item: items[i]),
                                  transition: Transition.cupertino,
                                ),
                              ),
                              childCount: items.length,
                            ),
                          ),
                  ),
                ],
              ),

              // ── FAB ───────────────────────────────────────────────
              Positioned(
                right: 16,
                bottom: 24,
                child: FloatingActionButton.extended(
                  onPressed: () => _showStockInSheet(context),
                  backgroundColor: AppColors.navy,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Stock In',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        }),
      );
    });
  }

  void _showStockInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockInSheet(controller: controller),
    );
  }

  void _showAddPartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPartSheet(controller: controller),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color.withValues(alpha: 0.4)) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock Card ────────────────────────────────────────────────────────────────
class _StockCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _StockCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLow      = item['isLowStock'] == true;
    final qty        = (item['quantity'] as num? ?? 0).toInt();
    final minLevel   = (item['minStockLevel'] as num? ?? 0).toInt();
    final partName   = item['partName']   as String? ?? '—';
    final partNumber = item['partNumber'] as String?;
    final category   = item['category']  as String?;
    final unit       = item['unit']       as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLow ? const Color(0xFFFFF7F7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isLow
              ? Border.all(color: const Color(0xFFFECACA))
              : Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Part info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partName,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (partNumber != null) ...[
                        Flexible(
                          child: Text(partNumber,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: 6),
                          Container(width: 3, height: 3,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.border)),
                          const SizedBox(width: 6),
                        ],
                      ],
                      if (category != null)
                        Flexible(
                          child: Text(category,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Min: $minLevel $unit',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Qty + status
            SizedBox(
              width: 72,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('$qty',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isLow
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A))),
                ),
                Text(unit,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 11)),
                const SizedBox(height: 4),
                if (isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Low Stock',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626))),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('OK',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A))),
                  ),
              ],
            ),
            ), // SizedBox(width: 72)
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

// ── Stock In Sheet ────────────────────────────────────────────────────────────
class StockInSheet extends StatefulWidget {
  final StoreKeeperDashboardController controller;
  final Map<String, dynamic>? preSelectedPart;

  const StockInSheet({required this.controller, this.preSelectedPart});

  @override
  State<StockInSheet> createState() => StockInSheetState();
}

class StockInSheetState extends State<StockInSheet> {
  Map<String, dynamic>? _selectedPart;
  final _qtyCtrl      = TextEditingController(text: '1');
  final _costCtrl     = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _submitting    = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedPart != null) {
      _selectedPart = widget.preSelectedPart;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (_selectedPart == null) {
      setState(() => _error = 'Please select a spare part');
      return;
    }
    if (qty < 1) {
      setState(() => _error = 'Quantity must be at least 1');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final cost = double.tryParse(_costCtrl.text.trim());
    final ok = await widget.controller.submitStockIn(
      sparePartId: _selectedPart!['id'] as int,
      quantity: qty,
      unitCost: cost,
      supplierName: _supplierCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar('Success', 'Stock added successfully',
          backgroundColor: const Color(0xFF16A34A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
    } else {
      setState(() => _error = 'Failed to add stock. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.controller.spareParts;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.add_box_outlined, color: AppColors.navy, size: 20),
                  const SizedBox(width: 8),
                  Text('Add Stock (Stock In)',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                ],
              ),
            ),
            const Divider(height: 1),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                  style: AppTextStyles.caption
                                      .copyWith(color: const Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Spare Part
                    _SheetLabel('Spare Part *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showPartPicker(context, parts.toList()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedPart != null
                                    ? '${_selectedPart!['name']}'
                                        '${_selectedPart!['partNumber'] != null ? ' (${_selectedPart!['partNumber']})' : ''}'
                                    : 'Select spare part…',
                                style: AppTextStyles.body.copyWith(
                                    color: _selectedPart != null
                                        ? AppColors.navy
                                        : AppColors.mutedText),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: AppColors.mutedText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Qty + Cost
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetLabel('Quantity *'),
                              const SizedBox(height: 6),
                              _SheetTextField(
                                controller: _qtyCtrl,
                                hint: '1',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetLabel('Unit Cost (₹)'),
                              const SizedBox(height: 6),
                              _SheetTextField(
                                controller: _costCtrl,
                                hint: 'Optional',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Supplier
                    _SheetLabel('Supplier Name'),
                    const SizedBox(height: 6),
                    _SheetTextField(
                        controller: _supplierCtrl, hint: 'Optional'),
                    const SizedBox(height: 16),

                    // Notes
                    _SheetLabel('Notes'),
                    const SizedBox(height: 6),
                    _SheetTextField(
                        controller: _notesCtrl, hint: 'Optional', maxLines: 2),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Add Stock',
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

  void _showPartPicker(BuildContext context, List<Map<String, dynamic>> parts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PartPickerSheet(
        parts: parts,
        onSelected: (p) {
          setState(() => _selectedPart = p);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Part Picker Sheet ─────────────────────────────────────────────────────────
class _PartPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> parts;
  final void Function(Map<String, dynamic>) onSelected;
  const _PartPickerSheet({required this.parts, required this.onSelected});

  @override
  State<_PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends State<_PartPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.parts.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      final num  = (p['partNumber'] as String? ?? '').toLowerCase();
      return name.contains(_q) || num.contains(_q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text('Select Spare Part',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search parts…',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No parts found',
                        style: AppTextStyles.body.copyWith(color: AppColors.mutedText)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ListTile(
                        title: Text(p['name'] as String? ?? '—',
                            style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                        subtitle: p['partNumber'] != null
                            ? Text(p['partNumber'] as String,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText))
                            : null,
                        onTap: () => widget.onSelected(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText, fontWeight: FontWeight.w600));
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  const _SheetTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(color: AppColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
}

// ── Add New Part Sheet ────────────────────────────────────────────────────────
class _AddPartSheet extends StatefulWidget {
  final StoreKeeperDashboardController controller;
  const _AddPartSheet({required this.controller});

  @override
  State<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends State<_AddPartSheet> {
  final _nameCtrl     = TextEditingController();
  final _partNumCtrl  = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _unitCtrl     = TextEditingController();
  final _minCtrl      = TextEditingController(text: '1');
  bool _submitting    = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _partNumCtrl.dispose();
    _categoryCtrl.dispose();
    _unitCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final unit = _unitCtrl.text.trim();
    final min  = int.tryParse(_minCtrl.text.trim()) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Part name is required');
      return;
    }
    if (unit.isEmpty) {
      setState(() => _error = 'Unit is required (e.g. Pieces, Litres)');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final ok = await widget.controller.submitNewPart(
      name: name,
      partNumber: _partNumCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      unit: unit,
      minStockLevel: min,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar('Part Added', '$name added to inventory',
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.navy, size: 20),
                  const SizedBox(width: 8),
                  Text('Add New Part',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                              style: AppTextStyles.caption.copyWith(color: const Color(0xFFDC2626)))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SheetLabel('Part Name *'),
                    const SizedBox(height: 6),
                    _SheetTextField(controller: _nameCtrl, hint: 'e.g. Engine Oil Filter'),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SheetLabel('Part Number'),
                        const SizedBox(height: 6),
                        _SheetTextField(controller: _partNumCtrl, hint: 'Optional'),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SheetLabel('Category'),
                        const SizedBox(height: 6),
                        _SheetTextField(controller: _categoryCtrl, hint: 'e.g. Engine'),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SheetLabel('Unit *'),
                        const SizedBox(height: 6),
                        _SheetTextField(controller: _unitCtrl, hint: 'e.g. Pieces'),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SheetLabel('Min Stock Level'),
                        const SizedBox(height: 6),
                        _SheetTextField(controller: _minCtrl, hint: '1',
                            keyboardType: TextInputType.number),
                      ])),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Add Part',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white, fontWeight: FontWeight.w600)),
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
