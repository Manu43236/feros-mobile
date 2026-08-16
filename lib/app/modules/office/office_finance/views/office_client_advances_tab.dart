import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/widgets/feros_select_field.dart';
import '../controllers/office_client_advances_controller.dart';

class OfficeClientAdvancesTab extends GetView<OfficeClientAdvancesController> {
  const OfficeClientAdvancesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      if (state == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (state == ViewState.error) {
        return _ErrorState(onRetry: controller.fetchAdvances);
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          final list = controller.advances;
          if (list.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: controller.fetchAdvances,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              itemBuilder: (_, i) => _AdvanceCard(advance: list[i]),
            ),
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Record Advance',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          onPressed: () async {
            await showModalBottomSheet(
        useSafeArea: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _RecordAdvanceSheet(
                  onSuccess: controller.fetchAdvances),
            );
          },
        ),
      );
    });
  }
}

// ── Advance Card ───────────────────────────────────────────────────────────────
class _AdvanceCard extends StatelessWidget {
  final Map<String, dynamic> advance;
  const _AdvanceCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final client = advance['clientName']      as String? ?? '—';
    final amount = (advance['amount']         as num?)?.toDouble() ?? 0;
    final mode   = advance['paymentMode']     as String? ?? '—';
    final date   = advance['receivedDate']    as String?;
    final ref    = advance['referenceNumber'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 20, color: AppColors.info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(client,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Text(mode,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              if (ref != null && ref.isNotEmpty) ...[
                Text(' · ',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                Expanded(
                  child: Text(ref,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
            if (date != null)
              Text(_fmtDate(date),
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ]),
        ),
        Text(_fmtRupee(amount),
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.info, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtDate(String iso) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

// ── Record Advance Sheet ───────────────────────────────────────────────────────
class _RecordAdvanceSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _RecordAdvanceSheet({required this.onSuccess});

  @override
  State<_RecordAdvanceSheet> createState() => _RecordAdvanceSheetState();
}

class _RecordAdvanceSheetState extends State<_RecordAdvanceSheet> {
  final _api = Get.find<ApiClient>();

  bool _isLoadingClients = true;
  bool _isSubmitting     = false;

  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic>? _selectedClient;

  String    _paymentMode = 'CASH';
  DateTime  _receivedDate = DateTime.now();

  final _amountCtrl  = TextEditingController();
  final _refCtrl     = TextEditingController();
  final _remarksCtrl = TextEditingController();

  static const _modes = ['CASH', 'CHEQUE', 'NEFT', 'UPI', 'RTGS'];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final res = await _api.get(ApiEndpoints.clients, params: {'size': 500});
      final data = (((res.data as Map)['data'] as Map)['content'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _clients = data; _isLoadingClients = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedClient == null) { FerosSnackbar.error('Select a client'); return; }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) { FerosSnackbar.error('Enter a valid amount'); return; }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'clientId':     _selectedClient!['id'],
        'amount':       amount,
        'paymentMode':  _paymentMode,
        'receivedDate': _receivedDate.toIso8601String().substring(0, 10),
      };
      if (_refCtrl.text.trim().isNotEmpty)     body['referenceNumber'] = _refCtrl.text.trim();
      if (_remarksCtrl.text.trim().isNotEmpty) body['remarks']         = _remarksCtrl.text.trim();

      await _api.post(ApiEndpoints.clientAdvances, data: body);
      Get.back();
      FerosSnackbar.success('Advance recorded');
      widget.onSuccess();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Record Advance',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const Spacer(),
              IconButton(onPressed: Get.back,
                  icon: const Icon(Icons.close, color: AppColors.mutedText)),
            ]),
            const SizedBox(height: 16),

            _isLoadingClients
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy))
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'Client *',
                    title: 'Select Client',
                    hint: 'Search client...',
                    items: _clients,
                    itemLabel: (c) => c['clientName'] as String? ?? '',
                    selectedDisplay: _selectedClient?['clientName'] as String?,
                    onSelected: (c) => setState(() => _selectedClient = c),
                  ),
            const SizedBox(height: 12),

            Text('Amount (₹) *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              decoration: _deco('e.g. 25000'),
            ),
            const SizedBox(height: 12),

            Text('Payment Mode *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _modes.map((m) {
                  final sel = m == _paymentMode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMode = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.navy : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.navy : AppColors.border),
                        ),
                        child: Text(m,
                            style: AppTextStyles.caption.copyWith(
                                color: sel ? Colors.white : AppColors.mutedText,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            Text('Received Date *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _receivedDate,
                  firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                    child: child!,
                  ),
                );
                if (p != null) setState(() => _receivedDate = p);
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Expanded(child: Text(_fmtDate(_receivedDate),
                      style: AppTextStyles.body.copyWith(color: AppColors.bodyText))),
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.mutedText),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            Text('Reference Number', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _refCtrl,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              decoration: _deco('Cheque/UTR/UPI ref (optional)'),
            ),
            const SizedBox(height: 12),

            Text('Remarks', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksCtrl,
              maxLines: 2,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              decoration: _deco('Optional remarks'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Record Advance',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
                            fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
        filled: true, fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No advances recorded',
              style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Text('Tap + to record an advance',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load advances',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Retry')),
        ]),
      );
}
