import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/store_keeper_dashboard_controller.dart';
import 'store_keeper_dashboard_view.dart' show StockInSheet, StockOutSheet;

class StoreKeeperPartDetailView extends StatefulWidget {
  final Map<String, dynamic> item;
  const StoreKeeperPartDetailView({super.key, required this.item});

  @override
  State<StoreKeeperPartDetailView> createState() => _StoreKeeperPartDetailViewState();
}

class _StoreKeeperPartDetailViewState extends State<StoreKeeperPartDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _controller = Get.find<StoreKeeperDashboardController>();

  final _transactions    = <Map<String, dynamic>>[];
  bool _loadingTx        = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final id = widget.item['sparePartId'] as int? ?? widget.item['id'] as int? ?? 0;
    final list = await _controller.fetchTransactions(id);
    if (mounted) {
      setState(() {
        _transactions
          ..clear()
          ..addAll(list);
        _loadingTx = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partName   = widget.item['partName']   as String? ?? '—';
    final isLow      = widget.item['isLowStock'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(partName,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16),
            overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(
            item: widget.item,
            isLow: isLow,
            onStockIn: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => StockInSheet(
                  controller: _controller,
                  preSelectedPart: {
                    'id': widget.item['sparePartId'] ?? widget.item['id'],
                    'name': widget.item['partName'],
                    'partNumber': widget.item['partNumber'],
                  },
                ),
              ).then((_) => _loadTransactions());
            },
            onStockOut: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => StockOutSheet(
                  controller: _controller,
                  preSelectedPart: {
                    'id': widget.item['sparePartId'] ?? widget.item['id'],
                    'name': widget.item['partName'],
                    'partNumber': widget.item['partNumber'],
                  },
                ),
              ).then((_) => _loadTransactions());
            },
          ),
          _TransactionsTab(
            transactions: _transactions,
            isLoading: _loadingTx,
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLow;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;
  const _OverviewTab({required this.item, required this.isLow, required this.onStockIn, required this.onStockOut});

  @override
  Widget build(BuildContext context) {
    final qty      = (item['quantity']      as num? ?? 0).toInt();
    final minLevel = (item['minStockLevel'] as num? ?? 0).toInt();
    final unit     = item['unit']       as String? ?? '';
    final category = item['category']   as String?;
    final partNum  = item['partNumber'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Current stock card ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '$qty',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: isLow
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A)),
                ),
                Text(unit,
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLow
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLow ? 'Low Stock' : 'In Stock',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLow
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Details card ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                if (partNum != null) ...[
                  _DetailRow(label: 'Part Number', value: partNum),
                  const Divider(height: 1, indent: 16),
                ],
                if (category != null) ...[
                  _DetailRow(label: 'Category', value: category),
                  const Divider(height: 1, indent: 16),
                ],
                _DetailRow(label: 'Unit', value: unit.isEmpty ? '—' : unit),
                const Divider(height: 1, indent: 16),
                _DetailRow(label: 'Min Stock Level', value: '$minLevel $unit'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stock In / Write-off buttons ──────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStockIn,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Stock In',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStockOut,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: Text('Write-off',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        ],
      ),
    );
  }
}

// ── Transactions Tab ──────────────────────────────────────────────────────────
class _TransactionsTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  const _TransactionsTab({required this.transactions, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text('No transactions yet',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TxCard(tx: transactions[i]),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type     = tx['transactionType'] as String? ?? '';
    final isIn     = type == 'IN';
    final qty      = (tx['quantity'] as num? ?? 0).toInt();
    final date     = tx['transactionDate'] as String? ?? tx['createdAt'] as String? ?? '';
    final supplier = tx['supplierName'] as String?;
    final notes    = tx['notes'] as String?;
    final unitCost = tx['unitCost'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isIn
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: isIn
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isIn ? 'Stock In' : 'Stock Out',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: isIn
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626))),
                    const Spacer(),
                    Text(_formatDate(date),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                ),
                if (supplier != null) ...[
                  const SizedBox(height: 2),
                  Text('Supplier: $supplier',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (unitCost != null) ...[
                  const SizedBox(height: 2),
                  Text('Unit cost: ₹$unitCost',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (notes != null) ...[
                  const SizedBox(height: 2),
                  Text(notes,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Qty badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}$qty',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isIn
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
