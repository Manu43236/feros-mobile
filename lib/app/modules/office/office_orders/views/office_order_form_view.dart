import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/widgets/feros_select_field.dart';
import '../controllers/office_orders_controller.dart';

/// Handles both Create (editOrderId == null) and Edit (editOrderId != null).
/// In edit mode, loads the full order then pre-fills all fields.
class OfficeOrderFormView extends StatefulWidget {
  final int? editOrderId;
  const OfficeOrderFormView({super.key, this.editOrderId});

  bool get isEdit => editOrderId != null;

  @override
  State<OfficeOrderFormView> createState() => _OfficeOrderFormViewState();
}

class _OfficeOrderFormViewState extends State<OfficeOrderFormView> {
  final _api = Get.find<ApiClient>();

  // ── Loading ──────────────────────────────────────────────────────────────
  bool _isLoadingForm =
      true; // true while loading master data (+ order in edit)
  bool _isLoadingClients = true;
  bool _isLoadingMaterials = true;
  bool _isLoadingStates = true;
  bool _isLoadingSrcCities = false;
  bool _isLoadingDstCities = false;
  bool _isSubmitting = false;

  // ── Master data ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _srcCities = [];
  List<Map<String, dynamic>> _dstCities = [];

  static final _rateTypes = <Map<String, dynamic>>[
    {'id': 'PER_TON', 'name': 'Per Ton'},
    {'id': 'PER_TRIP', 'name': 'Per Trip'},
    {'id': 'PER_KM', 'name': 'Per KM'},
  ];

  static final _billingOptions = <Map<String, dynamic>>[
    {'id': 'LOADED_WEIGHT', 'name': 'Loaded Weight'},
    {'id': 'DELIVERED_WEIGHT', 'name': 'Delivered Weight'},
  ];

  // ── Selected values ──────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedClient;
  Map<String, dynamic>? _selectedMaterial;
  Map<String, dynamic>? _srcState;
  Map<String, dynamic>? _srcCity;
  Map<String, dynamic>? _dstState;
  Map<String, dynamic>? _dstCity;
  Map<String, dynamic> _selectedRateType = _rateTypes[0];
  Map<String, dynamic> _selectedBillingOn = _billingOptions[0];
  DateTime? _orderDate, _expectedDeliveryDate;
  DateTime? _ewayBillDate, _ewayBillValidUpto;
  bool _clientAutoFilled = false;

  // ── Text controllers ─────────────────────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _freightRateCtrl = TextEditingController();
  final _srcAddressCtrl = TextEditingController();
  final _dstAddressCtrl = TextEditingController();
  final _customMaterialCtrl = TextEditingController();
  final _specialInstCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _ewayBillNoCtrl = TextEditingController();

  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _orderDate = DateTime.now();
    _loadAll();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _freightRateCtrl.dispose();
    _srcAddressCtrl.dispose();
    _dstAddressCtrl.dispose();
    _customMaterialCtrl.dispose();
    _specialInstCtrl.dispose();
    _remarksCtrl.dispose();
    _ewayBillNoCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    try {
      final futures = <Future>[
        _api.get(ApiEndpoints.clients),
        _api.get(ApiEndpoints.materialTypes),
        _api.get(ApiEndpoints.states),
        if (widget.isEdit)
          _api.get(ApiEndpoints.orderById(widget.editOrderId!)),
      ];

      final results = await Future.wait(futures);

      final clientsData = ((results[0].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final materialsData = ((results[1].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final statesData = ((results[2].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _clients = clientsData;
        _isLoadingClients = false;
        _materials = [
          ...materialsData,
          {'id': -1, 'name': 'Other (specify manually)'},
        ];
        _isLoadingMaterials = false;
        _states = statesData;
        _isLoadingStates = false;
      });

      if (widget.isEdit && results.length == 4) {
        final order = (results[3].data as Map)['data'] as Map<String, dynamic>;
        await _prefillFromOrder(order, statesData);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
          _isLoadingMaterials = false;
          _isLoadingStates = false;
        });
        FerosSnackbar.error('Failed to load form data');
      }
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _prefillFromOrder(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> statesData,
  ) async {
    // ── Client ──────────────────────────────────────────────────────────
    final clientId = order['clientId'] as int?;
    if (clientId != null) {
      final match = _clients.where((c) => c['id'] == clientId);
      if (match.isNotEmpty && mounted)
        setState(() => _selectedClient = match.first);
    }

    // ── Material ─────────────────────────────────────────────────────────
    final materialId = order['materialTypeId'] as int?;
    final customMat = order['customMaterialName'] as String?;
    if (materialId != null) {
      final match = _materials.where((m) => m['id'] == materialId);
      if (match.isNotEmpty && mounted)
        setState(() => _selectedMaterial = match.first);
    } else if (customMat != null && customMat.isNotEmpty) {
      if (mounted) {
        setState(
          () => _selectedMaterial = {
            'id': -1,
            'name': 'Other (specify manually)',
          },
        );
        _customMaterialCtrl.text = customMat;
      }
    }

    // ── Weight, rate, addresses ───────────────────────────────────────────
    _weightCtrl.text = (order['totalWeight'] as num?)?.toString() ?? '';
    _freightRateCtrl.text = (order['freightRate'] as num?)?.toString() ?? '';
    _srcAddressCtrl.text = order['sourceAddress'] as String? ?? '';
    _dstAddressCtrl.text = order['destinationAddress'] as String? ?? '';
    _specialInstCtrl.text = order['specialInstructions'] as String? ?? '';
    _remarksCtrl.text = order['remarks'] as String? ?? '';
    _ewayBillNoCtrl.text = order['ewayBillNumber'] as String? ?? '';

    // ── Rate type + billing ───────────────────────────────────────────────
    final rateType = order['freightRateType'] as String?;
    if (rateType != null) {
      final match = _rateTypes.where((r) => r['id'] == rateType);
      if (match.isNotEmpty && mounted)
        setState(() => _selectedRateType = match.first);
    }
    final billingOn = order['billingOn'] as String?;
    if (billingOn != null) {
      final match = _billingOptions.where((b) => b['id'] == billingOn);
      if (match.isNotEmpty && mounted)
        setState(() => _selectedBillingOn = match.first);
    }

    // ── Dates ─────────────────────────────────────────────────────────────
    final od = order['orderDate'] as String?;
    final edd = order['expectedDeliveryDate'] as String?;
    final ebd = order['ewayBillDate'] as String?;
    final ebv = order['ewayBillValidUpto'] as String?;
    if (mounted) {
      setState(() {
        if (od != null) _orderDate = DateTime.tryParse(od);
        if (edd != null) _expectedDeliveryDate = DateTime.tryParse(edd);
        if (ebd != null) _ewayBillDate = DateTime.tryParse(ebd);
        if (ebv != null) _ewayBillValidUpto = DateTime.tryParse(ebv);
      });
    }

    // ── Source state + city ───────────────────────────────────────────────
    final srcStateId = order['sourceStateId'] as int?;
    final srcCityId = order['sourceCityId'] as int?;
    if (srcStateId != null) {
      final stMatch = statesData.where((s) => s['id'] == srcStateId);
      if (stMatch.isNotEmpty && mounted)
        setState(() => _srcState = stMatch.first);
      await _loadSrcCities(srcStateId);
      if (srcCityId != null && mounted) {
        final cMatch = _srcCities.where((c) => c['id'] == srcCityId);
        if (cMatch.isNotEmpty) setState(() => _srcCity = cMatch.first);
      }
    }

    // ── Destination state + city ──────────────────────────────────────────
    final dstStateId = order['destinationStateId'] as int?;
    final dstCityId = order['destinationCityId'] as int?;
    if (dstStateId != null) {
      final stMatch = statesData.where((s) => s['id'] == dstStateId);
      if (stMatch.isNotEmpty && mounted)
        setState(() => _dstState = stMatch.first);
      await _loadDstCities(dstStateId);
      if (dstCityId != null && mounted) {
        final cMatch = _dstCities.where((c) => c['id'] == dstCityId);
        if (cMatch.isNotEmpty) setState(() => _dstCity = cMatch.first);
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoadingClients = true;
      _isLoadingMaterials = true;
      _isLoadingStates = true;
      _isLoadingForm = true;
    });
    await _loadAll();
  }

  Future<void> _loadSrcCities(int stateId) async {
    setState(() {
      _isLoadingSrcCities = true;
      _srcCities = [];
    });
    try {
      final res = await _api.get(
        ApiEndpoints.cities,
        params: {'stateId': stateId},
      );
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _srcCities = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSrcCities = false);
  }

  Future<void> _loadDstCities(int stateId) async {
    setState(() {
      _isLoadingDstCities = true;
      _dstCities = [];
    });
    try {
      final res = await _api.get(
        ApiEndpoints.cities,
        params: {'stateId': stateId},
      );
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _dstCities = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDstCities = false);
  }

  // ── Client auto-fill ─────────────────────────────────────────────────────
  void _onClientSelected(Map<String, dynamic> client) {
    setState(() {
      _selectedClient = client;
      _clientAutoFilled = false;
    });
    final stateId = client['stateId'] as int?;
    final cityId = client['cityId'] as int?;
    final address = client['address'] as String?;

    if (stateId != null) {
      final stateMatches = _states.where((s) => s['id'] == stateId);
      setState(() {
        _dstState = stateMatches.isEmpty ? null : stateMatches.first;
        _dstCity = null;
        _dstCities = [];
      });
      _loadDstCities(stateId).then((_) {
        if (cityId != null && mounted) {
          final cityMatches = _dstCities.where((c) => c['id'] == cityId);
          setState(
            () => _dstCity = cityMatches.isEmpty ? null : cityMatches.first,
          );
        }
      });
    }
    if (address != null && address.isNotEmpty) _dstAddressCtrl.text = address;
    if (stateId != null || (address != null && address.isNotEmpty)) {
      setState(() => _clientAutoFilled = true);
    }
  }

  // ── Validation ───────────────────────────────────────────────────────────
  bool _validate() {
    final e = <String, String>{};
    if (_selectedClient == null) e['client'] = 'Select a client';
    if (_selectedMaterial == null) e['material'] = 'Select material type';
    if (_selectedMaterial?['id'] == -1 &&
        _customMaterialCtrl.text.trim().isEmpty) {
      e['material'] = 'Enter material name';
    }
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w == null || w <= 0) e['weight'] = 'Enter a valid weight';
    if (_srcState == null) e['srcState'] = 'Select source state';
    if (_srcCity == null) e['srcCity'] = 'Select source city';
    if (_dstState == null) e['dstState'] = 'Select destination state';
    if (_dstCity == null) e['dstCity'] = 'Select destination city';
    final r = double.tryParse(_freightRateCtrl.text.trim());
    if (r == null || r <= 0) e['freightRate'] = 'Enter freight rate';

    setState(() {
      _errors.clear();
      _errors.addAll(e);
    });
    return e.isEmpty;
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'clientId': _selectedClient!['id'],
        'totalWeight': double.parse(_weightCtrl.text.trim()),
        'sourceStateId': _srcState!['id'],
        'sourceCityId': _srcCity!['id'],
        'destinationStateId': _dstState!['id'],
        'destinationCityId': _dstCity!['id'],
        'freightRateType': _selectedRateType['id'],
        'freightRate': double.parse(_freightRateCtrl.text.trim()),
      };

      if (_selectedMaterial?['id'] == -1) {
        body['customMaterialName'] = _customMaterialCtrl.text.trim();
      } else if (_selectedMaterial != null) {
        body['materialTypeId'] = _selectedMaterial!['id'];
      }
      if (_srcAddressCtrl.text.trim().isNotEmpty)
        body['sourceAddress'] = _srcAddressCtrl.text.trim();
      if (_dstAddressCtrl.text.trim().isNotEmpty)
        body['destinationAddress'] = _dstAddressCtrl.text.trim();
      if (_selectedRateType['id'] == 'PER_TON')
        body['billingOn'] = _selectedBillingOn['id'];
      if (_specialInstCtrl.text.trim().isNotEmpty)
        body['specialInstructions'] = _specialInstCtrl.text.trim();
      if (_remarksCtrl.text.trim().isNotEmpty)
        body['remarks'] = _remarksCtrl.text.trim();
      if (_orderDate != null)
        body['orderDate'] = _orderDate!.toIso8601String().substring(0, 10);
      if (_expectedDeliveryDate != null)
        body['expectedDeliveryDate'] = _expectedDeliveryDate!
            .toIso8601String()
            .substring(0, 10);
      if (_ewayBillNoCtrl.text.trim().isNotEmpty)
        body['ewayBillNumber'] = _ewayBillNoCtrl.text.trim();
      if (_ewayBillDate != null)
        body['ewayBillDate'] = _ewayBillDate!.toIso8601String().substring(
          0,
          10,
        );
      if (_ewayBillValidUpto != null)
        body['ewayBillValidUpto'] = _ewayBillValidUpto!
            .toIso8601String()
            .substring(0, 10);

      if (widget.isEdit) {
        await _api.put(ApiEndpoints.orderById(widget.editOrderId!), data: body);
      } else {
        await _api.post(ApiEndpoints.orders, data: body);
      }

      if (Get.isRegistered<OfficeOrdersController>()) {
        Get.find<OfficeOrdersController>().fetchOrders(reset: true);
      }
      Get.back();
      FerosSnackbar.success(
        widget.isEdit
            ? 'Order updated successfully'
            : 'Order created successfully',
      );
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Text(
          widget.isEdit ? 'Edit Order' : 'New Order',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: (_isLoadingForm && widget.isEdit)
          ? const _FormSkeleton()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.navy,
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        children: [
                          _Section(
                            title: 'Basic Info',
                            children: _buildBasicInfo(),
                          ),
                          const SizedBox(height: 16),
                          _Section(
                            title: 'Source (From)',
                            children: _buildSource(),
                          ),
                          const SizedBox(height: 16),
                          _Section(
                            title: 'Destination (To)',
                            badge: _clientAutoFilled
                                ? 'Auto-filled from client'
                                : null,
                            children: _buildDestination(),
                          ),
                          const SizedBox(height: 16),
                          _Section(title: 'Freight', children: _buildFreight()),
                          const SizedBox(height: 16),
                          _Section(
                            title: 'Additional Info',
                            children: _buildAdditional(),
                          ),
                          const SizedBox(height: 16),
                          _Section(
                            title: 'E-way Bill',
                            children: _buildEwayBill(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _SubmitFooter(
                  isSubmitting: _isSubmitting,
                  label: widget.isEdit ? 'Update Order' : 'Create Order',
                  onTap: _submit,
                ),
              ],
            ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────
  List<Widget> _buildBasicInfo() => [
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
            errorText: _errors['client'],
          ),
    const SizedBox(height: 12),
    _isLoadingMaterials
        ? const _FieldShimmer()
        : FerosSelectField<Map<String, dynamic>>(
            label: 'Material Type *',
            title: 'Select Material',
            hint: 'Search material...',
            items: _materials,
            itemLabel: (m) => m['name'] as String? ?? '',
            selectedDisplay: _selectedMaterial?['name'] as String?,
            onSelected: (m) => setState(() => _selectedMaterial = m),
            errorText: _errors['material'],
          ),
    if (_selectedMaterial?['id'] == -1) ...[
      const SizedBox(height: 12),
      _LabelledField(
        label: 'Custom Material Name *',
        child: _buildTextField(_customMaterialCtrl, 'Enter material name'),
      ),
    ],
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Total Weight (tons) *',
      child: TextField(
        controller: _weightCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
        decoration: _inputDecoration('e.g. 10.5', errorText: _errors['weight']),
      ),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Order Date',
      child: _DatePickerField(
        value: _orderDate,
        hint: 'Select date',
        onPicked: (d) => setState(() => _orderDate = d),
      ),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Expected Delivery Date',
      child: _DatePickerField(
        value: _expectedDeliveryDate,
        hint: 'Select date',
        onPicked: (d) => setState(() => _expectedDeliveryDate = d),
      ),
    ),
  ];

  List<Widget> _buildSource() => [
    _isLoadingStates
        ? const _FieldShimmer()
        : FerosSelectField<Map<String, dynamic>>(
            label: 'State *',
            title: 'Select Source State',
            hint: 'Search state...',
            items: _states,
            itemLabel: (s) => s['name'] as String? ?? '',
            selectedDisplay: _srcState?['name'] as String?,
            onSelected: (s) {
              setState(() {
                _srcState = s;
                _srcCity = null;
                _srcCities = [];
              });
              _loadSrcCities(s['id'] as int);
            },
            errorText: _errors['srcState'],
          ),
    const SizedBox(height: 12),
    _isLoadingSrcCities
        ? const _FieldShimmer()
        : FerosSelectField<Map<String, dynamic>>(
            label: 'City *',
            title: 'Select Source City',
            hint: 'Search city...',
            items: _srcCities,
            itemLabel: (c) => c['name'] as String? ?? '',
            selectedDisplay: _srcCity?['name'] as String?,
            onSelected: (c) => setState(() => _srcCity = c),
            enabled: _srcState != null,
            errorText: _errors['srcCity'],
          ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Address',
      child: _buildTextField(
        _srcAddressCtrl,
        'Street / area (optional)',
        maxLines: 2,
      ),
    ),
  ];

  List<Widget> _buildDestination() => [
    _isLoadingStates
        ? const _FieldShimmer()
        : FerosSelectField<Map<String, dynamic>>(
            label: 'State *',
            title: 'Select Destination State',
            hint: 'Search state...',
            items: _states,
            itemLabel: (s) => s['name'] as String? ?? '',
            selectedDisplay: _dstState?['name'] as String?,
            onSelected: (s) {
              setState(() {
                _dstState = s;
                _dstCity = null;
                _dstCities = [];
              });
              _loadDstCities(s['id'] as int);
            },
            errorText: _errors['dstState'],
          ),
    const SizedBox(height: 12),
    _isLoadingDstCities
        ? const _FieldShimmer()
        : FerosSelectField<Map<String, dynamic>>(
            label: 'City *',
            title: 'Select Destination City',
            hint: 'Search city...',
            items: _dstCities,
            itemLabel: (c) => c['name'] as String? ?? '',
            selectedDisplay: _dstCity?['name'] as String?,
            onSelected: (c) => setState(() => _dstCity = c),
            enabled: _dstState != null,
            errorText: _errors['dstCity'],
          ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Delivery Address',
      child: _buildTextField(
        _dstAddressCtrl,
        'Street / area (optional)',
        maxLines: 2,
      ),
    ),
  ];

  List<Widget> _buildFreight() => [
    FerosSelectField<Map<String, dynamic>>(
      label: 'Rate Type *',
      title: 'Select Rate Type',
      hint: '',
      items: _rateTypes,
      itemLabel: (r) => r['name'] as String? ?? '',
      selectedDisplay: _selectedRateType['name'] as String?,
      onSelected: (r) => setState(() => _selectedRateType = r),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Freight Rate (₹) *',
      child: TextField(
        controller: _freightRateCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
        decoration: _inputDecoration(
          'e.g. 1500',
          errorText: _errors['freightRate'],
        ),
      ),
    ),
    if (_selectedRateType['id'] == 'PER_TON') ...[
      const SizedBox(height: 12),
      FerosSelectField<Map<String, dynamic>>(
        label: 'Bill On',
        title: 'Select Billing Basis',
        hint: '',
        items: _billingOptions,
        itemLabel: (b) => b['name'] as String? ?? '',
        selectedDisplay: _selectedBillingOn['name'] as String?,
        onSelected: (b) => setState(() => _selectedBillingOn = b),
      ),
    ],
  ];

  List<Widget> _buildAdditional() => [
    _LabelledField(
      label: 'Special Instructions',
      child: _buildTextField(
        _specialInstCtrl,
        'Any special handling notes...',
        maxLines: 2,
      ),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Remarks',
      child: _buildTextField(
        _remarksCtrl,
        'Internal remarks (optional)',
        maxLines: 2,
      ),
    ),
  ];

  List<Widget> _buildEwayBill() => [
    _LabelledField(
      label: 'E-way Bill Number',
      child: _buildTextField(_ewayBillNoCtrl, 'e.g. 231234567890'),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'E-way Bill Date',
      child: _DatePickerField(
        value: _ewayBillDate,
        hint: 'Select date',
        onPicked: (d) => setState(() => _ewayBillDate = d),
      ),
    ),
    const SizedBox(height: 12),
    _LabelledField(
      label: 'Valid Upto',
      child: _DatePickerField(
        value: _ewayBillValidUpto,
        hint: 'Select date',
        onPicked: (d) => setState(() => _ewayBillValidUpto = d),
      ),
    ),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      errorText: errorText,
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    String? errorText,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
      decoration: _inputDecoration(hint, errorText: errorText),
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────
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
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Form skeleton ──────────────────────────────────────────────────────────────
class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _skeletonSection(fields: 4), // Basic
            const SizedBox(height: 16),
            _skeletonSection(fields: 5), // Source
            const SizedBox(height: 16),
            _skeletonSection(fields: 5), // Destination
            const SizedBox(height: 16),
            _skeletonSection(fields: 3), // Freight
            const SizedBox(height: 16),
            _skeletonSection(fields: 2), // E-way
            const SizedBox(height: 16),
            _skeletonSection(fields: 2), // Remarks
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            fields,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < fields - 1 ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field shimmer ──────────────────────────────────────────────────────────────
class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Labelled field ─────────────────────────────────────────────────────────────
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

// ── Date picker field ──────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPicked;
  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onPicked,
  });

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

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
              colorScheme: const ColorScheme.light(primary: AppColors.navy),
            ),
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
                value != null ? _format(value!) : hint,
                style: AppTextStyles.body.copyWith(
                  color: value != null
                      ? AppColors.bodyText
                      : AppColors.hintText,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submit footer ──────────────────────────────────────────────────────────────
class _SubmitFooter extends StatelessWidget {
  final bool isSubmitting;
  final String label;
  final VoidCallback onTap;
  const _SubmitFooter({
    required this.isSubmitting,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
