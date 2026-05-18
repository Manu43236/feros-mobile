import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/widgets/feros_select_field.dart';

class OfficeCreateInvoiceView extends StatefulWidget {
  const OfficeCreateInvoiceView({super.key});

  @override
  State<OfficeCreateInvoiceView> createState() =>
      _OfficeCreateInvoiceViewState();
}

class _OfficeCreateInvoiceViewState extends State<OfficeCreateInvoiceView> {
  final _api = Get.find<ApiClient>();

  bool _isLoadingClients  = true;
  bool _isLoadingLrs      = false;
  bool _isSubmitting      = false;

  List<Map<String, dynamic>> _clients        = [];
  List<Map<String, dynamic>> _availableLrs   = [];
  final Set<int> _selectedLrIds = {};

  Map<String, dynamic>? _selectedClient;

  DateTime? _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  final _cgstCtrl    = TextEditingController(text: '0');
  final _sgstCtrl    = TextEditingController(text: '0');
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _cgstCtrl.dispose();
    _sgstCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final res  = await _api.get(ApiEndpoints.clients);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _clients = data; _isLoadingClients = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingClients = false);
      FerosSnackbar.error('Failed to load clients');
    }
  }

  Future<void> _loadLrsForClient(int clientId) async {
    setState(() { _isLoadingLrs = true; _availableLrs = []; _selectedLrIds.clear(); });
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.lrs),
        _api.get('${ApiEndpoints.invoices}/invoiced-lr-ids'),
      ]);

      final allLrs = ((results[0].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final invoicedIds = ((results[1].data as Map)['data'] as List? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? -1)
          .toSet();

      final available = allLrs.where((lr) {
        final lrClientId = (lr['clientId'] as num?)?.toInt();
        final status     = lr['lrStatus'] as String? ?? '';
        final lrId       = (lr['id'] as num?)?.toInt() ?? -1;
        return lrClientId == clientId &&
            status == 'DELIVERED' &&
            !invoicedIds.contains(lrId);
      }).toList();

      if (mounted) setState(() => _availableLrs = available);
    } catch (_) {
      FerosSnackbar.error('Failed to load LRs');
    } finally {
      if (mounted) setState(() => _isLoadingLrs = false);
    }
  }

  void _onClientSelected(Map<String, dynamic> client) {
    setState(() {
      _selectedClient = client;
      _availableLrs   = [];
      _selectedLrIds.clear();
    });
    final id = (client['id'] as num?)?.toInt();
    if (id != null) _loadLrsForClient(id);
  }

  void _toggleLr(int lrId) {
    setState(() {
      if (_selectedLrIds.contains(lrId)) {
        _selectedLrIds.remove(lrId);
      } else {
        _selectedLrIds.add(lrId);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedClient == null) { FerosSnackbar.error('Select a client'); return; }
    if (_selectedLrIds.isEmpty)  { FerosSnackbar.error('Select at least one LR'); return; }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'clientId': _selectedClient!['id'],
        'lrIds':    _selectedLrIds.toList(),
      };
      final cgst = double.tryParse(_cgstCtrl.text.trim());
      final sgst = double.tryParse(_sgstCtrl.text.trim());
      if (cgst != null) body['cgstPercentage'] = cgst;
      if (sgst != null) body['sgstPercentage'] = sgst;
      if (_invoiceDate != null) body['invoiceDate'] = _invoiceDate!.toIso8601String().substring(0, 10);
      if (_dueDate != null)     body['dueDate']     = _dueDate!.toIso8601String().substring(0, 10);
      if (_remarksCtrl.text.trim().isNotEmpty) body['remarks'] = _remarksCtrl.text.trim();

      await _api.post(ApiEndpoints.invoices, data: body);
      Get.back();
      FerosSnackbar.success('Invoice created successfully');
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text('New Invoice',
            style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600,
              fontSize: 16, color: Colors.white,
            )),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // ── Client ────────────────────────────────────────────
                  _Section(
                    title: 'Client',
                    children: [
                      _isLoadingClients
                          ? const _FieldShimmer()
                          : FerosSelectField<Map<String, dynamic>>(
                              label: 'Client *',
                              title: 'Select Client',
                              hint: 'Search client...',
                              items: _clients,
                              itemLabel: (c) => c['clientName'] as String? ?? '',
                              selectedDisplay: _selectedClient?['clientName'] as String?,
                              onSelected: _onClientSelected,
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── LR Selection ─────────────────────────────────────
                  _Section(
                    title: 'Select LRs',
                    badge: _selectedLrIds.isEmpty
                        ? null
                        : '${_selectedLrIds.length} selected',
                    children: [
                      if (_selectedClient == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Select a client to see available LRs',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mutedText)),
                        )
                      else if (_isLoadingLrs)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.navy, strokeWidth: 2)),
                        )
                      else if (_availableLrs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('No un-invoiced delivered LRs for this client',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mutedText)),
                        )
                      else
                        ..._availableLrs.map((lr) {
                          final lrId   = (lr['id'] as num?)?.toInt() ?? -1;
                          final lrNo   = lr['lrNumber']  as String? ?? '—';
                          final from   = lr['fromCity']  as String? ?? '—';
                          final to     = lr['toCity']    as String? ?? '—';
                          final weight = lr['deliveredWeight'] ?? lr['loadedWeight'];
                          final sel    = _selectedLrIds.contains(lrId);
                          return InkWell(
                            onTap: () => _toggleLr(lrId),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.navy.withValues(alpha: 0.06)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel ? AppColors.navy : AppColors.border,
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    sel
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 20,
                                    color: sel
                                        ? AppColors.navy
                                        : AppColors.mutedText,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(lrNo,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('$from → $to',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color:
                                                        AppColors.mutedText)),
                                      ],
                                    ),
                                  ),
                                  if (weight != null)
                                    Text('${weight}T',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.mutedText)),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Tax + Dates ──────────────────────────────────────
                  _Section(
                    title: 'Tax & Dates',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LabelledField(
                              label: 'CGST %',
                              child: TextField(
                                controller: _cgstCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'))
                                ],
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.bodyText),
                                decoration: _inputDeco('e.g. 9'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabelledField(
                              label: 'SGST %',
                              child: TextField(
                                controller: _sgstCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'))
                                ],
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.bodyText),
                                decoration: _inputDeco('e.g. 9'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LabelledField(
                        label: 'Invoice Date',
                        child: _DateField(
                          value: _invoiceDate,
                          hint: 'Select date',
                          onPicked: (d) =>
                              setState(() => _invoiceDate = d),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabelledField(
                        label: 'Due Date',
                        child: _DateField(
                          value: _dueDate,
                          hint: 'Select date',
                          onPicked: (d) => setState(() => _dueDate = d),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabelledField(
                        label: 'Remarks',
                        child: TextField(
                          controller: _remarksCtrl,
                          maxLines: 2,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.bodyText),
                          decoration: _inputDeco('Optional remarks'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Submit footer ────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor:
                      AppColors.orange.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Invoice',
                        style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600,
                          fontSize: 15, color: Colors.white,
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
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

// ── Reusable widgets (local) ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? badge;
  final List<Widget> children;
  const _Section({required this.title, this.badge, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.orange, fontSize: 10)),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabelledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPicked;
  const _DateField(
      {required this.value, required this.hint, required this.onPicked});

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColors.navy)),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : hint,
                style: AppTextStyles.body.copyWith(
                    color: value != null
                        ? AppColors.bodyText
                        : AppColors.hintText),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
