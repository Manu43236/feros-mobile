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
import '../controllers/office_credit_notes_controller.dart';

class OfficeCreditNotesTab extends GetView<OfficeCreditNotesController> {
  const OfficeCreditNotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      if (state == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (state == ViewState.error) {
        return _ErrorState(onRetry: controller.fetchCreditNotes);
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _StatusFilter(controller: controller),
            Expanded(
              child: Obx(() {
                final list = controller.filtered;
                if (list.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: controller.fetchCreditNotes,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _CreditNoteCard(
                      cn: list[i],
                      onStatusChanged: controller.fetchCreditNotes,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Credit Note',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          onPressed: () async {
            await showModalBottomSheet(
        useSafeArea: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CreateCreditNoteSheet(
                  onSuccess: controller.fetchCreditNotes),
            );
          },
        ),
      );
    });
  }
}

// ── Status Filter ──────────────────────────────────────────────────────────────
class _StatusFilter extends StatelessWidget {
  final OfficeCreditNotesController controller;
  const _StatusFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
      child: Obx(() {
        final sel = controller.selectedStatus.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: OfficeCreditNotesController.statuses.map((s) {
              final active = s == sel;
              final label  = OfficeCreditNotesController.statusLabels[s] ?? s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setStatus(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.navy : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? AppColors.navy : AppColors.border),
                    ),
                    child: Text(label,
                        style: AppTextStyles.caption.copyWith(
                          color: active ? Colors.white : AppColors.mutedText,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

// ── Credit Note Card ───────────────────────────────────────────────────────────
class _CreditNoteCard extends StatelessWidget {
  final Map<String, dynamic> cn;
  final VoidCallback onStatusChanged;
  const _CreditNoteCard({required this.cn, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final cnNo    = cn['creditNoteNumber'] as String? ?? '—';
    final client  = cn['clientName']       as String? ?? '—';
    final amount  = (cn['amount']          as num?)?.toDouble() ?? 0;
    final status  = cn['status']           as String? ?? '';
    final reason  = cn['reason']           as String? ?? '';
    final date    = cn['creditNoteDate']   as String?;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(cnNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy, fontWeight: FontWeight.w700))),
            _CnStatusChip(status: status),
          ]),
          const SizedBox(height: 4),
          Text(client,
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              overflow: TextOverflow.ellipsis),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reason,
                style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(children: [
            Text(_fmtRupee(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (date != null)
              Text(_fmtDate(date),
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            if (status == 'DRAFT') ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _updateStatus(context, cn['id'], status),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Update',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, dynamic id, String currentStatus) {
    const nextStatuses = ['DRAFT', 'APPROVED', 'ADJUSTED'];
    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status',
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 16),
            ...nextStatuses.map((s) => ListTile(
              leading: Icon(
                s == currentStatus
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: s == currentStatus ? AppColors.navy : AppColors.mutedText,
              ),
              title: Text(s, style: AppTextStyles.body),
              onTap: () async {
                Get.back();
                try {
                  await Get.find<ApiClient>().put(
                      '${ApiEndpoints.creditNoteStatus(id)}?status=$s',
                      data: {});
                  FerosSnackbar.success('Status updated');
                  onStatusChanged();
                } catch (e) {
                  FerosSnackbar.error(e.toString());
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtDate(String iso) {
    try { return DateFormat('dd MMM yy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

// ── CN Status Chip ─────────────────────────────────────────────────────────────
class _CnStatusChip extends StatelessWidget {
  final String status;
  const _CnStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'DRAFT':    return AppColors.mutedText;
      case 'APPROVED': return AppColors.success;
      case 'ADJUSTED': return const Color(0xFF7C3AED);
      default:         return AppColors.mutedText;
    }
  }
}

// ── Create Credit Note Sheet ───────────────────────────────────────────────────
class _CreateCreditNoteSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CreateCreditNoteSheet({required this.onSuccess});

  @override
  State<_CreateCreditNoteSheet> createState() => _CreateCreditNoteSheetState();
}

class _CreateCreditNoteSheetState extends State<_CreateCreditNoteSheet> {
  final _api = Get.find<ApiClient>();

  bool _isLoadingClients   = true;
  bool _isLoadingInvoices  = false;
  bool _isSubmitting       = false;

  List<Map<String, dynamic>> _clients  = [];
  List<Map<String, dynamic>> _invoices = [];

  Map<String, dynamic>? _selectedClient;
  Map<String, dynamic>? _selectedInvoice;

  DateTime _cnDate = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _remarksCtrl= TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
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

  Future<void> _loadInvoicesForClient(int clientId) async {
    setState(() { _isLoadingInvoices = true; _invoices = []; _selectedInvoice = null; });
    try {
      final res = await _api.get(ApiEndpoints.invoicesByClient(clientId));
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _invoices = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingInvoices = false);
  }

  Future<void> _submit() async {
    if (_selectedClient == null)         { FerosSnackbar.error('Select a client'); return; }
    if (_reasonCtrl.text.trim().isEmpty) { FerosSnackbar.error('Enter reason'); return; }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0)   { FerosSnackbar.error('Enter a valid amount'); return; }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'clientId':      _selectedClient!['id'],
        'amount':        amount,
        'reason':        _reasonCtrl.text.trim(),
        'creditNoteDate':_cnDate.toIso8601String().substring(0, 10),
      };
      if (_selectedInvoice != null) body['invoiceId'] = _selectedInvoice!['id'];
      if (_remarksCtrl.text.trim().isNotEmpty) body['remarks'] = _remarksCtrl.text.trim();

      await _api.post(ApiEndpoints.creditNotes, data: body);
      Get.back();
      FerosSnackbar.success('Credit note created');
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
              Text('New Credit Note',
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
                    onSelected: (c) {
                      setState(() { _selectedClient = c; _selectedInvoice = null; });
                      final cid = (c['id'] as num?)?.toInt();
                      if (cid != null) _loadInvoicesForClient(cid);
                    },
                  ),
            const SizedBox(height: 12),

            _isLoadingInvoices
                ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy)))
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'Invoice (optional)',
                    title: 'Link to Invoice',
                    hint: 'Search invoice...',
                    items: _invoices,
                    itemLabel: (inv) => inv['invoiceNumber'] as String? ?? '',
                    selectedDisplay: _selectedInvoice?['invoiceNumber'] as String?,
                    onSelected: (inv) => setState(() => _selectedInvoice = inv),
                    enabled: _selectedClient != null && !_isLoadingInvoices,
                  ),
            const SizedBox(height: 12),

            Text('Credit Note Date *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _cnDate,
                  firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                    child: child!,
                  ),
                );
                if (p != null) setState(() => _cnDate = p);
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Expanded(child: Text(_fmtDate(_cnDate),
                      style: AppTextStyles.body.copyWith(color: AppColors.bodyText))),
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.mutedText),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            Text('Amount (₹) *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              decoration: _deco('e.g. 5000'),
            ),
            const SizedBox(height: 12),

            Text('Reason *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonCtrl,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
              decoration: _deco('Reason for credit note'),
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
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Credit Note',
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.note_outlined, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No credit notes', style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Text('Tap + to create one',
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
          Text('Failed to load credit notes',
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
