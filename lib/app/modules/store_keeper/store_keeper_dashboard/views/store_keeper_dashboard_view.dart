import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/store_keeper_dashboard_controller.dart';
import '../../../driver/driver_attendance/controllers/driver_attendance_controller.dart';
import '../../../driver/driver_attendance/views/driver_attendance_sheet.dart';
import '../../../driver/driver_shell/controllers/driver_shell_controller.dart';
import '../../store_keeper_inventory/controllers/store_keeper_inventory_controller.dart';
import '../../store_keeper_inventory/controllers/store_keeper_inventory_controller.dart';
import '../../store_keeper_requests/controllers/store_keeper_requests_controller.dart';

class StoreKeeperDashboardView extends GetView<StoreKeeperDashboardController> {
  const StoreKeeperDashboardView({super.key});

  void _goToInventory({int tab = 0}) {
    Get.find<StoreKeeperInventoryController>().selectedTab.value = tab;
    Get.find<DriverShellController>().onTabTapped(1);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ShimmerList(count: 6);
      }
      return RefreshIndicator(
        onRefresh: controller.fetchAll,
        color: AppColors.navy,
        child: CustomScrollView(
          slivers: [
            // ── Attendance banner ────────────────────────────
            SliverToBoxAdapter(
              child: Obx(() {
                final attCtrl = Get.find<DriverAttendanceController>();
                if (!attCtrl.isCurrentMonth || attCtrl.todayMarked) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => showMarkAttendanceSheet(
                    context,
                    onMarked: attCtrl.fetch,
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text("Mark Today's Attendance",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              }),
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
                    GestureDetector(
                      onTap: () => _goToInventory(tab: 0),
                      child: _SummaryCard(
                        label: 'Total Parts',
                        value: '${controller.totalItems}',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.navy,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goToInventory(tab: 0),
                      child: _SummaryCard(
                        label: 'In Stock',
                        value: '${controller.inStockCount}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goToInventory(tab: 0),
                      child: _SummaryCard(
                        label: 'Low Stock',
                        value: '${controller.lowStockCount}',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goToInventory(tab: 1),
                      child: _SummaryCard(
                        label: 'Pending Requests',
                        value: '${controller.pendingCount.value}',
                        icon: Icons.pending_actions_outlined,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Actions ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_box_outlined,
                        label: 'Stock In',
                        color: AppColors.navy,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              StockInSheet(controller: controller),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'New Part',
                        color: const Color(0xFF0891B2),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _AddNewPartSheet(controller: controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent Requests ──────────────────────────────
            SliverToBoxAdapter(
              child: _RecentRequests(onViewAll: () => _goToInventory(tab: 1)),
            ),

            // ── Low Stock Alerts ─────────────────────────────
            SliverToBoxAdapter(
              child: _LowStockAlerts(
                controller: controller,
                onViewAll: () => _goToInventory(tab: 0),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      );
    });
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

// ── Quick Action Button ────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Recent Requests ────────────────────────────────────────────────────────────
class _RecentRequests extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RecentRequests({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final reqCtrl = Get.find<StoreKeeperRequestsController>();
    return Obx(() {
      if (reqCtrl.isLoading.value) return const SizedBox.shrink();
      final recent = reqCtrl.requests.take(3).toList();
      if (recent.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions_outlined,
                    size: 16, color: AppColors.navy),
                const SizedBox(width: 6),
                Text('Recent Requests',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: onViewAll,
                  child: Text('View All',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...recent.map((req) => _RecentRequestTile(
                  request: req,
                  onViewAll: onViewAll,
                  reqCtrl: reqCtrl,
                )),
          ],
        ),
      );
    });
  }
}

class _RecentRequestTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onViewAll;
  final StoreKeeperRequestsController reqCtrl;
  const _RecentRequestTile({
    required this.request,
    required this.onViewAll,
    required this.reqCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final partName = request['partName']           as String? ?? '—';
    final qty      = (request['requestedQuantity'] as num? ?? 0).toInt();
    final by       = request['requestedByName']    as String?;
    final status   = request['status']             as String? ?? 'REQUESTED';
    final isPending = status == 'REQUESTED';
    final isApproved = status == 'APPROVED';

    final Color badgeColor;
    final Color badgeText;
    final String badgeLabel;
    if (isPending) {
      badgeColor = const Color(0xFFFEF3C7);
      badgeText  = const Color(0xFFD97706);
      badgeLabel = 'Pending';
    } else if (isApproved) {
      badgeColor = const Color(0xFFDCFCE7);
      badgeText  = const Color(0xFF16A34A);
      badgeLabel = 'Approved';
    } else {
      badgeColor = const Color(0xFFFEE2E2);
      badgeText  = const Color(0xFFDC2626);
      badgeLabel = 'Rejected';
    }

    return GestureDetector(
      onTap: () {
        if (isPending) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ApproveRejectSheet(
              request: request,
              controller: reqCtrl,
            ),
          );
        } else {
          onViewAll();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partName,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (by != null) ...[
                    const SizedBox(height: 2),
                    Text(by,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeLabel,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeText)),
                ),
                const SizedBox(height: 4),
                Text('$qty units',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              isPending ? Icons.touch_app_outlined : Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Approve / Reject Sheet (inline for home page) ─────────────────────────────
class _ApproveRejectSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final StoreKeeperRequestsController controller;
  const _ApproveRejectSheet({required this.request, required this.controller});

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
    String msg;
    if (_isApprove) {
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
      if (qty < 1) {
        setState(() { _submitting = false; _error = 'Quantity must be at least 1'; });
        return;
      }
      ok  = await widget.controller.approveRequest(id, qty);
      msg = 'Approved — $qty units issued';
    } else {
      final reason = _reasonCtrl.text.trim();
      if (reason.isEmpty) {
        setState(() { _submitting = false; _error = 'Please provide a reason'; });
        return;
      }
      ok  = await widget.controller.rejectRequest(id, reason);
      msg = 'Request rejected';
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar('Done', msg,
          backgroundColor:
              _isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
    } else {
      setState(() => _error = 'Failed to process. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final partName    = widget.request['partName']           as String? ?? '—';
    final requestedQty = (widget.request['requestedQuantity'] as num? ?? 0).toInt();
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () { _isApprove = true; _error = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isApprove
                                      ? const Color(0xFF16A34A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 16,
                                        color: _isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Approve',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                            color: _isApprove
                                                ? Colors.white
                                                : AppColors.mutedText)),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isApprove
                                      ? const Color(0xFFDC2626)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cancel_outlined,
                                        size: 16,
                                        color: !_isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Reject',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                            color: !_isApprove
                                                ? Colors.white
                                                : AppColors.mutedText)),
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
                        style: AppTextStyles.body.copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: '$requestedQty',
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
                        style: AppTextStyles.body.copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: 'e.g. Insufficient stock…',
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

// ── Low Stock Alerts section ───────────────────────────────────────────────────
class _LowStockAlerts extends StatelessWidget {
  final StoreKeeperDashboardController controller;
  final VoidCallback onViewAll;
  const _LowStockAlerts({required this.controller, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final lowItems = controller.stockItems
        .where((i) => i['isLowStock'] == true)
        .take(5)
        .toList();

    if (lowItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Text('Low Stock Alerts',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Text('View All',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lowItems.map((item) {
            final name = item['partName'] as String? ?? '—';
            final qty  = (item['quantity'] as num? ?? 0).toInt();
            final min  = (item['minStockLevel'] as num? ?? 0).toInt();
            final unit = item['unit'] as String? ?? '';
            return GestureDetector(
              onTap: onViewAll,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.navy),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('$qty / $min $unit',
                        style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 10, color: Color(0xFFDC2626)),
                  ],
                ),
              ),
            );
          }),
          if (controller.lowStockCount > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '+${controller.lowStockCount - 5} more low stock items',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add New Part Sheet (for Quick Action on home) ─────────────────────────────
class _AddNewPartSheet extends StatefulWidget {
  final StoreKeeperDashboardController controller;
  const _AddNewPartSheet({required this.controller});

  @override
  State<_AddNewPartSheet> createState() => _AddNewPartSheetState();
}

class _AddNewPartSheetState extends State<_AddNewPartSheet> {
  final _nameCtrl     = TextEditingController();
  final _partNumCtrl  = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _minCtrl      = TextEditingController(text: '1');
  String _unit        = 'PCS';
  bool _submitting    = false;
  String? _error;

  static const _units = ['PCS', 'LITRE', 'KG', 'METRE', 'SET', 'BOX', 'PAIR'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _partNumCtrl.dispose();
    _categoryCtrl.dispose();
    _minCtrl.dispose();
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
      minStockLevel: int.tryParse(_minCtrl.text.trim()) ?? 1,
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
                    _field(_categoryCtrl, 'e.g. Filters'),
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
                    _field(_minCtrl, '1', type: TextInputType.number),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController c, String hint,
          {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: c,
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
