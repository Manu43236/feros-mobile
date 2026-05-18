import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/widgets/feros_select_field.dart';

/// Handles both Create (clientId == null) and Edit (clientId != null).
class OfficeClientFormView extends StatefulWidget {
  final int? clientId;
  const OfficeClientFormView({super.key, this.clientId});

  bool get isEdit => clientId != null;

  @override
  State<OfficeClientFormView> createState() => _OfficeClientFormViewState();
}

class _OfficeClientFormViewState extends State<OfficeClientFormView> {
  final _api    = Get.find<ApiClient>();
  final _isAdmin = Get.find<AuthService>().user?.role == 'ADMIN';

  // ── Loading ─────────────────────────────────────────────────────────────
  bool _isLoadingForm       = true;
  bool _isLoadingTypes      = true;
  bool _isLoadingStates     = true;
  bool _isLoadingCities     = false;
  bool _isLoadingTerms      = true;
  bool _isSubmitting        = false;
  bool _isTogglingStatus    = false;

  // ── Master data ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _clientTypes   = [];
  List<Map<String, dynamic>> _states        = [];
  List<Map<String, dynamic>> _cities        = [];
  List<Map<String, dynamic>> _paymentTerms  = [];

  // ── Selections ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedState;
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedTerms;
  bool _isActive = true;

  // ── Text controllers ─────────────────────────────────────────────────────
  final _nameCtrl              = TextEditingController();
  final _phoneCtrl             = TextEditingController();
  final _emailCtrl             = TextEditingController();
  final _addressCtrl           = TextEditingController();
  final _pincodeCtrl           = TextEditingController();
  final _gstinCtrl             = TextEditingController();
  final _panCtrl               = TextEditingController();
  final _cpNameCtrl            = TextEditingController();
  final _cpPhoneCtrl           = TextEditingController();
  final _cpEmailCtrl           = TextEditingController();
  final _creditLimitCtrl       = TextEditingController();
  final _openingBalanceCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _cpNameCtrl.dispose();
    _cpPhoneCtrl.dispose();
    _cpEmailCtrl.dispose();
    _creditLimitCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMasters() async {
    setState(() => _isLoadingForm = true);
    try {
      final futures = await Future.wait([
        _api.get(ApiEndpoints.clientTypes),
        _api.get(ApiEndpoints.states),
        _api.get(ApiEndpoints.paymentTerms),
        if (widget.isEdit) _api.get(ApiEndpoints.clientById(widget.clientId!)),
      ]);

      final types = ((futures[0].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final states = ((futures[1].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final terms = ((futures[2].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _clientTypes  = types;
        _states       = states;
        _paymentTerms = terms;
        _isLoadingTypes  = false;
        _isLoadingStates = false;
        _isLoadingTerms  = false;
      });

      if (widget.isEdit && futures.length == 4) {
        final client = (futures[3].data as Map)['data'] as Map<String, dynamic>;
        _prefillFromClient(client, states, types, terms);
      }
    } catch (e) {
      FerosSnackbar.error('Failed to load form data');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _prefillFromClient(
    Map<String, dynamic> c,
    List<Map<String, dynamic>> states,
    List<Map<String, dynamic>> types,
    List<Map<String, dynamic>> terms,
  ) async {
    _nameCtrl.text           = c['clientName']           as String? ?? '';
    _phoneCtrl.text          = c['phone']                as String? ?? '';
    _emailCtrl.text          = c['email']                as String? ?? '';
    _addressCtrl.text        = c['address']              as String? ?? '';
    _pincodeCtrl.text        = c['pincode']              as String? ?? '';
    _gstinCtrl.text          = c['gstin']                as String? ?? '';
    _panCtrl.text            = c['panNumber']            as String? ?? '';
    _cpNameCtrl.text         = c['contactPersonName']    as String? ?? '';
    _cpPhoneCtrl.text        = c['contactPersonPhone']   as String? ?? '';
    _cpEmailCtrl.text        = c['contactPersonEmail']   as String? ?? '';
    _creditLimitCtrl.text    = _fmtDecimal(c['creditLimit']);
    _openingBalanceCtrl.text = _fmtDecimal(c['openingBalance']);
    _isActive                = c['isActive']             as bool? ?? true;

    final typeId  = (c['clientTypeId']    as num?)?.toInt();
    final stateId = (c['stateId']         as num?)?.toInt();
    final cityId  = (c['cityId']          as num?)?.toInt();
    final termsId = (c['paymentTermsId']  as num?)?.toInt();

    Map<String, dynamic>? selState;
    if (typeId  != null) _selectedType  = types.firstWhereOrNull((t) => t['id'] == typeId);
    if (stateId != null) selState       = states.firstWhereOrNull((s) => s['id'] == stateId);
    if (termsId != null) _selectedTerms = terms.firstWhereOrNull((t) => t['id'] == termsId);

    if (selState != null) {
      _selectedState = selState;
      setState(() => _isLoadingCities = true);
      try {
        final res = await _api.get(ApiEndpoints.cities,
            params: {'stateId': selState['id']});
        final cities = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        if (!mounted) return;
        setState(() {
          _cities = cities;
          _selectedCity = cityId != null
              ? cities.firstWhereOrNull((c) => c['id'] == cityId)
              : null;
          _isLoadingCities = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isLoadingCities = false);
      }
    }

    if (mounted) setState(() {});
  }

  String _fmtDecimal(dynamic v) {
    if (v == null) return '';
    final d = (v as num).toDouble();
    return d == 0 ? '' : d.toStringAsFixed(d == d.truncateToDouble() ? 0 : 2);
  }

  Future<void> _onStateSelected(Map<String, dynamic> state) async {
    setState(() {
      _selectedState   = state;
      _selectedCity    = null;
      _cities          = [];
      _isLoadingCities = true;
    });
    try {
      final res = await _api.get(ApiEndpoints.cities,
          params: {'stateId': state['id']});
      final cities = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _cities = cities; _isLoadingCities = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { FerosSnackbar.error('Client name is required'); return; }
    if (_selectedType == null) { FerosSnackbar.error('Select a client type'); return; }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'clientName':   name,
        'clientTypeId': _selectedType!['id'],
      };
      if (_phoneCtrl.text.trim().isNotEmpty)       body['phone']               = _phoneCtrl.text.trim();
      if (_emailCtrl.text.trim().isNotEmpty)        body['email']               = _emailCtrl.text.trim();
      if (_addressCtrl.text.trim().isNotEmpty)      body['address']             = _addressCtrl.text.trim();
      if (_selectedState != null)                   body['stateId']             = _selectedState!['id'];
      if (_selectedCity  != null)                   body['cityId']              = _selectedCity!['id'];
      if (_pincodeCtrl.text.trim().isNotEmpty)      body['pincode']             = _pincodeCtrl.text.trim();
      if (_gstinCtrl.text.trim().isNotEmpty)        body['gstin']               = _gstinCtrl.text.trim();
      if (_panCtrl.text.trim().isNotEmpty)          body['panNumber']           = _panCtrl.text.trim();
      if (_cpNameCtrl.text.trim().isNotEmpty)       body['contactPersonName']   = _cpNameCtrl.text.trim();
      if (_cpPhoneCtrl.text.trim().isNotEmpty)      body['contactPersonPhone']  = _cpPhoneCtrl.text.trim();
      if (_cpEmailCtrl.text.trim().isNotEmpty)      body['contactPersonEmail']  = _cpEmailCtrl.text.trim();
      if (_selectedTerms != null)                   body['paymentTermsId']      = _selectedTerms!['id'];
      final cl = double.tryParse(_creditLimitCtrl.text.trim());
      if (cl != null) body['creditLimit'] = cl;
      final ob = double.tryParse(_openingBalanceCtrl.text.trim());
      if (ob != null) body['openingBalance'] = ob;

      if (widget.isEdit) {
        await _api.put(ApiEndpoints.clientById(widget.clientId!), data: body);
      } else {
        await _api.post(ApiEndpoints.clients, data: body);
      }

      Get.back();
      FerosSnackbar.success(
          widget.isEdit ? 'Client updated' : 'Client created');
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleStatus() async {
    if (!_isAdmin) return;
    setState(() => _isTogglingStatus = true);
    try {
      await _api.put(ApiEndpoints.clientStatus(widget.clientId!));
      setState(() => _isActive = !_isActive);
      FerosSnackbar.success(_isActive ? 'Client activated' : 'Client deactivated');
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
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
        title: Text(
          widget.isEdit ? 'Edit Client' : 'New Client',
          style: const TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600,
            fontSize: 16, color: Colors.white,
          ),
        ),
        actions: [
          if (widget.isEdit && _isAdmin)
            _isTogglingStatus
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))))
                : TextButton(
                    onPressed: _toggleStatus,
                    child: Text(
                      _isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                        color: _isActive ? Colors.red[200] : Colors.green[200],
                        fontFamily: 'Inter', fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
        ],
      ),
      body: (_isLoadingForm && widget.isEdit)
          ? _FormSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section('BASIC INFO', children: [
                    _field('Client Name *', _nameCtrl, 'Enter client name'),
                    const SizedBox(height: 12),
                    _isLoadingTypes
                        ? const _FieldShimmer()
                        : FerosSelectField<Map<String, dynamic>>(
                            label: 'Client Type *',
                            title: 'Select Client Type',
                            hint: 'Search type...',
                            items: _clientTypes,
                            itemLabel: (t) => t['name'] as String? ?? '',
                            selectedDisplay: _selectedType?['name'] as String?,
                            onSelected: (t) => setState(() => _selectedType = t),
                          ),
                    const SizedBox(height: 12),
                    _field('Phone', _phoneCtrl, 'e.g. 9876543210',
                        inputType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field('Email', _emailCtrl, 'e.g. client@company.com',
                        inputType: TextInputType.emailAddress),
                  ]),
                  const SizedBox(height: 16),

                  _Section('ADDRESS', children: [
                    _field('Street / Address', _addressCtrl, 'Enter address',
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _isLoadingStates
                        ? const _FieldShimmer()
                        : FerosSelectField<Map<String, dynamic>>(
                            label: 'State',
                            title: 'Select State',
                            hint: 'Search state...',
                            items: _states,
                            itemLabel: (s) => s['name'] as String? ?? '',
                            selectedDisplay: _selectedState?['name'] as String?,
                            onSelected: _onStateSelected,
                          ),
                    const SizedBox(height: 12),
                    _isLoadingCities
                        ? const _FieldShimmer()
                        : FerosSelectField<Map<String, dynamic>>(
                            label: 'City',
                            title: 'Select City',
                            hint: 'Search city...',
                            items: _cities,
                            itemLabel: (c) => c['name'] as String? ?? '',
                            selectedDisplay: _selectedCity?['name'] as String?,
                            onSelected: (c) => setState(() => _selectedCity = c),
                            enabled: _selectedState != null,
                            emptyMessage: _selectedState == null
                                ? 'Select a state first'
                                : 'No cities found',
                          ),
                    const SizedBox(height: 12),
                    _field('Pincode', _pincodeCtrl, 'e.g. 400001',
                        inputType: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly]),
                  ]),
                  const SizedBox(height: 16),

                  _Section('TAX DETAILS', children: [
                    _field('GSTIN', _gstinCtrl, 'e.g. 27ABCDE1234F1Z5'),
                    const SizedBox(height: 12),
                    _field('PAN Number', _panCtrl, 'e.g. ABCDE1234F'),
                  ]),
                  const SizedBox(height: 16),

                  _Section('CONTACT PERSON', children: [
                    _field('Name', _cpNameCtrl, 'Contact person name'),
                    const SizedBox(height: 12),
                    _field('Phone', _cpPhoneCtrl, 'e.g. 9876543210',
                        inputType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field('Email', _cpEmailCtrl, 'e.g. contact@company.com',
                        inputType: TextInputType.emailAddress),
                  ]),
                  const SizedBox(height: 16),

                  _Section('CREDIT SETTINGS', children: [
                    _isLoadingTerms
                        ? const _FieldShimmer()
                        : FerosSelectField<Map<String, dynamic>>(
                            label: 'Payment Terms',
                            title: 'Select Payment Terms',
                            hint: 'Search terms...',
                            items: _paymentTerms,
                            itemLabel: (t) => t['name'] as String? ?? '',
                            selectedDisplay: _selectedTerms?['name'] as String?,
                            onSelected: (t) => setState(() => _selectedTerms = t),
                          ),
                    const SizedBox(height: 12),
                    _field('Credit Limit (₹)', _creditLimitCtrl, 'e.g. 100000',
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                    const SizedBox(height: 12),
                    _field('Opening Balance (₹)', _openingBalanceCtrl, 'e.g. 0',
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                  ]),
                ],
              ),
            ),
      bottomNavigationBar: _isLoadingForm
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.isEdit ? 'Update Client' : 'Create Client',
                            style: const TextStyle(
                              fontFamily: 'Inter', fontWeight: FontWeight.w600,
                              fontSize: 15, color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? inputType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        inputFormatters: formatters,
        maxLines: maxLines,
        style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
        decoration: InputDecoration(
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
              borderSide:
                  const BorderSide(color: AppColors.navy, width: 1.5)),
        ),
      ),
    ]);
  }
}

// ── Section wrapper ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, {required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}

// ── Field shimmer placeholder ──────────────────────────────────────────────────
class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 100, height: 13,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 6),
        Container(height: 48,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(8))),
      ]),
    );
  }
}

// ── Form skeleton ──────────────────────────────────────────────────────────────
class _FormSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(children: [
          _skeletonSection(fields: 4),
          const SizedBox(height: 16),
          _skeletonSection(fields: 4),
          const SizedBox(height: 16),
          _skeletonSection(fields: 2),
          const SizedBox(height: 16),
          _skeletonSection(fields: 3),
          const SizedBox(height: 16),
          _skeletonSection(fields: 3),
        ]),
      ),
    );
  }

  Widget _skeletonSection({required int fields}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 80, height: 11,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 14),
        ...List.generate(fields, (i) => Padding(
          padding: EdgeInsets.only(bottom: i < fields - 1 ? 12 : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 100, height: 13,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 48,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
          ]),
        )),
      ]),
    );
  }
}
