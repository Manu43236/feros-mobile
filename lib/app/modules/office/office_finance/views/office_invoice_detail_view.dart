import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class OfficeInvoiceDetailView extends StatefulWidget {
  final int invoiceId;
  const OfficeInvoiceDetailView({super.key, required this.invoiceId});

  @override
  State<OfficeInvoiceDetailView> createState() =>
      _OfficeInvoiceDetailViewState();
}

class _OfficeInvoiceDetailViewState extends State<OfficeInvoiceDetailView> {
  final _api = Get.find<ApiClient>();

  bool _isLoading = true;
  bool _hasError  = false;
  Map<String, dynamic>? _invoice;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final res = await _api.get(ApiEndpoints.invoiceById(widget.invoiceId));
      if (mounted) {
        setState(() {
          _invoice   = (res.data as Map)['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  // ── Record Payment ──────────────────────────────────────────────────────────
  void _showRecordPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(
        invoiceId: widget.invoiceId,
        onSuccess: _loadInvoice,
      ),
    );
  }

  // ── Update Status ───────────────────────────────────────────────────────────
  void _showUpdateStatus() {
    final current = _invoice?['invoiceStatus'] as String? ?? '';
    const statuses = ['DRAFT', 'SENT', 'PARTIALLY_PAID', 'OVERDUE', 'PAID'];
    showModalBottomSheet(
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
            ...statuses.map((s) {
              final isSelected = s == current;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.navy : AppColors.mutedText,
                ),
                title: Text(s, style: AppTextStyles.body),
                onTap: () async {
                  Get.back();
                  await _updateStatus(s);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _api.put(ApiEndpoints.invoiceStatus(widget.invoiceId),
          data: {'status': status});
      FerosSnackbar.success('Status updated');
      _loadInvoice();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }
    if (_hasError || _invoice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy, elevation: 0,
          leading: IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back, color: Colors.white)),
          title: const Text('Invoice',
              style: TextStyle(color: Colors.white, fontFamily: 'Inter',
                  fontWeight: FontWeight.w600)),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load invoice',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadInvoice,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Retry')),
          ]),
        ),
      );
    }

    final inv         = _invoice!;
    final invNo       = inv['invoiceNumber']  as String? ?? '—';
    final client      = inv['clientName']     as String? ?? '—';
    final status      = inv['invoiceStatus']  as String? ?? '';
    final total       = (inv['totalAmount']   as num?)?.toDouble() ?? 0;
    final subtotal    = (inv['subtotal']      as num?)?.toDouble() ?? 0;
    final cgst        = (inv['cgstAmount']    as num?)?.toDouble() ?? 0;
    final sgst        = (inv['sgstAmount']    as num?)?.toDouble() ?? 0;
    final cgstPct     = (inv['cgstPercentage']as num?)?.toDouble() ?? 0;
    final sgstPct     = (inv['sgstPercentage']as num?)?.toDouble() ?? 0;
    final advAdj      = (inv['advanceAdjusted']     as num?)?.toDouble() ?? 0;
    final cnAdj       = (inv['creditNoteAdjusted']  as num?)?.toDouble() ?? 0;
    final amtPaid     = (inv['amountPaid']    as num?)?.toDouble() ?? 0;
    final balance     = (inv['balanceDue']    as num?)?.toDouble() ?? 0;
    final invoiceDate = inv['invoiceDate']    as String?;
    final dueDate     = inv['dueDate']        as String?;
    final remarks     = inv['remarks']        as String?;
    final lrItems     = (inv['lrItems']       as List? ?? []).cast<Map<String, dynamic>>();
    final payments    = (inv['payments']      as List? ?? []).cast<Map<String, dynamic>>();
    final isPaid      = status == 'PAID';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invNo, style: const TextStyle(
                color: Colors.white, fontFamily: 'Inter',
                fontWeight: FontWeight.w600, fontSize: 15)),
            Text(client, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Inter', fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _showUpdateStatus,
            tooltip: 'Update Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoice,
        color: AppColors.navy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          children: [

            // ── Status + dates ─────────────────────────────────────────
            _Card(children: [
              Row(children: [
                Expanded(child: Text('Status',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))),
                _InvoiceStatusChip(status: status),
              ]),
              const SizedBox(height: 10),
              if (invoiceDate != null) _InfoRow('Invoice Date', _fmtDate(invoiceDate)),
              if (dueDate != null)     _InfoRow('Due Date',     _fmtDate(dueDate)),
              if (remarks != null && remarks.isNotEmpty)
                _InfoRow('Remarks', remarks),
            ]),
            const SizedBox(height: 14),

            // ── Financial Summary ──────────────────────────────────────
            _SectionHeader(title: 'Financial Summary'),
            const SizedBox(height: 8),
            _Card(children: [
              _AmountRow('Subtotal',          subtotal),
              if (cgstPct > 0) _AmountRow('CGST ($cgstPct%)', cgst),
              if (sgstPct > 0) _AmountRow('SGST ($sgstPct%)', sgst),
              const Divider(height: 20, color: AppColors.border),
              _AmountRow('Total',             total,   bold: true),
              if (advAdj > 0) _AmountRow('Advance Adjusted', -advAdj, color: AppColors.success),
              if (cnAdj > 0)  _AmountRow('Credit Note Adj.', -cnAdj,  color: AppColors.success),
              if (amtPaid > 0) _AmountRow('Amount Paid',     -amtPaid, color: AppColors.success),
              const Divider(height: 20, color: AppColors.border),
              _AmountRow('Balance Due',       balance, bold: true,
                  color: balance > 0 ? AppColors.error : AppColors.success),
            ]),
            const SizedBox(height: 14),

            // ── LR Items ───────────────────────────────────────────────
            _SectionHeader(title: 'LR Items (${lrItems.length})'),
            const SizedBox(height: 8),
            if (lrItems.isEmpty)
              _Card(children: [
                Text('No LR items', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ])
            else
              ...lrItems.map((lr) {
                final lrNo    = lr['lrNumber']  as String? ?? '—';
                final from    = lr['fromCity']  as String? ?? '—';
                final to      = lr['toCity']    as String? ?? '—';
                final freight = (lr['freightAmount'] as num?)?.toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lrNo, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('$from → $to',
                            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      ],
                    )),
                    if (freight != null)
                      Text(_fmtRupee(freight),
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
            const SizedBox(height: 14),

            // ── Payments ───────────────────────────────────────────────
            _SectionHeader(title: 'Payment History (${payments.length})'),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              _Card(children: [
                Text('No payments recorded',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ])
            else
              ...payments.map((p) {
                final amount  = (p['amount']      as num?)?.toDouble() ?? 0;
                final mode    = p['paymentMode']  as String? ?? '—';
                final date    = p['paymentDate']  as String?;
                final ref     = p['referenceNumber'] as String?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payments_outlined,
                          size: 16, color: AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        if (ref != null && ref.isNotEmpty)
                          Text(ref, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                        if (date != null)
                          Text(_fmtDate(date),
                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      ],
                    )),
                    Text(_fmtRupee(amount),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w700)),
                  ]),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: isPaid ? null : Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _showRecordPayment,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Record Payment',
                style: TextStyle(fontFamily: 'Inter',
                    fontWeight: FontWeight.w600, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ── Record Payment Sheet ───────────────────────────────────────────────────────
class _RecordPaymentSheet extends StatefulWidget {
  final int invoiceId;
  final VoidCallback onSuccess;
  const _RecordPaymentSheet(
      {required this.invoiceId, required this.onSuccess});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _api = Get.find<ApiClient>();

  final _amountCtrl = TextEditingController();
  final _refCtrl    = TextEditingController();
  final _remarksCtrl= TextEditingController();

  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  static const _modes = ['CASH', 'CHEQUE', 'NEFT', 'UPI', 'RTGS'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      FerosSnackbar.error('Enter a valid amount');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'amount':      amount,
        'paymentMode': _paymentMode,
        'paymentDate': _paymentDate.toIso8601String().substring(0, 10),
      };
      if (_refCtrl.text.trim().isNotEmpty)     body['referenceNumber'] = _refCtrl.text.trim();
      if (_remarksCtrl.text.trim().isNotEmpty) body['remarks']         = _remarksCtrl.text.trim();

      await _api.post(ApiEndpoints.invoicePayments(widget.invoiceId), data: body);
      Get.back();
      FerosSnackbar.success('Payment recorded');
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Record Payment',
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const Spacer(),
            IconButton(onPressed: Get.back,
                icon: const Icon(Icons.close, color: AppColors.mutedText)),
          ]),
          const SizedBox(height: 16),

          // Amount
          Text('Amount (₹) *', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
            decoration: _deco('e.g. 50000'),
          ),
          const SizedBox(height: 12),

          // Payment Mode
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.navy : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.navy : AppColors.border),
                      ),
                      child: Text(m,
                          style: AppTextStyles.caption.copyWith(
                              color: sel ? Colors.white : AppColors.mutedText,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Payment Date
          Text('Payment Date', style: AppTextStyles.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: AppColors.navy)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _paymentDate = picked);
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
                Expanded(
                    child: Text(_fmtDate(_paymentDate),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.bodyText))),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.mutedText),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Reference
          Text('Reference Number', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: _refCtrl,
            style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
            decoration: _deco('Cheque/UTR/UPI ref (optional)'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Payment',
                      style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600,
                          fontSize: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

// ── Small helpers ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText))),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.bodyText, fontWeight: FontWeight.w500)),
        ]),
      );
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  final Color? color;
  const _AmountRow(this.label, this.amount, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.bodyText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: bold
                    ? AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: effectiveColor)
                    : AppTextStyles.body.copyWith(color: AppColors.mutedText))),
        Text(_fmtRupee(amount.abs()),
            style: bold
                ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700, color: effectiveColor)
                : AppTextStyles.body.copyWith(color: effectiveColor)),
      ]),
    );
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(2)}K';
    return '₹${v.toStringAsFixed(2)}';
  }
}

class _InvoiceStatusChip extends StatelessWidget {
  final String status;
  const _InvoiceStatusChip({required this.status});

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
      child: Text(_label(status),
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'DRAFT':         return AppColors.mutedText;
      case 'SENT':          return const Color(0xFF2563EB);
      case 'PARTIALLY_PAID':return const Color(0xFFF59E0B);
      case 'OVERDUE':       return AppColors.error;
      case 'PAID':          return AppColors.success;
      default:              return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'DRAFT':         return 'Draft';
      case 'SENT':          return 'Sent';
      case 'PARTIALLY_PAID':return 'Part. Paid';
      case 'OVERDUE':       return 'Overdue';
      case 'PAID':          return 'Paid';
      default:              return s;
    }
  }
}
