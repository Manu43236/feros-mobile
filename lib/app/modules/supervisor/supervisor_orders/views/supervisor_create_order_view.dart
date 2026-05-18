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
import '../controllers/supervisor_orders_controller.dart';

class SupervisorCreateOrderView extends StatefulWidget {
  const SupervisorCreateOrderView({super.key});

  @override
  State<SupervisorCreateOrderView> createState() =>
      _SupervisorCreateOrderViewState();
}

class _SupervisorCreateOrderViewState extends State<SupervisorCreateOrderView> {
  final _api = Get.find<ApiClient>();

  // ── Loading ────────────────────────────────────────────────────────────────
  bool _isLoadingClients = true;
  bool _isLoadingMaterials = true;
  bool _isLoadingStates = true;
  bool _isLoadingSrcCities = false;
  bool _isLoadingDstCities = false;
  bool _isSubmitting = false;

  // ── Master data ────────────────────────────────────────────────────────────
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

  // ── Selected values ────────────────────────────────────────────────────────
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

  // ── Text controllers ───────────────────────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _freightRateCtrl = TextEditingController();
  final _srcAddressCtrl = TextEditingController();
  final _dstAddressCtrl = TextEditingController();
  final _customMaterialCtrl = TextEditingController();
  final _specialInstCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _ewayBillNoCtrl = TextEditingController();

  // ── Validation errors ──────────────────────────────────────────────────────
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _orderDate = DateTime.now();
    _loadMasterData();
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

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadMasterData() async {
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.clients),
        _api.get(ApiEndpoints.materialTypes),
        _api.get(ApiEndpoints.states),
      ]);
      final clientsData = ((results[0].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final materialsData = ((results[1].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final statesData = ((results[2].data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) {
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
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
          _isLoadingMaterials = false;
          _isLoadingStates = false;
        });
      }
      FerosSnackbar.error('Failed to load form data');
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoadingClients = true;
      _isLoadingMaterials = true;
      _isLoadingStates = true;
    });
    final futures = <Future<void>>[_loadMasterData()];
    if (_srcState != null) futures.add(_loadSrcCities(_srcState!['id'] as int));
    if (_dstState != null) futures.add(_loadDstCities(_dstState!['id'] as int));
    await Future.wait(futures);
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

  // ── Client auto-fill ───────────────────────────────────────────────────────
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

  // ── Validation ─────────────────────────────────────────────────────────────
  bool _validate() {
    final e = <String, String>{};

    if (_selectedClient == null) e['client'] = 'Select a client';
    if (_selectedMaterial == null) e['material'] = 'Select material type';
    if (_selectedMaterial?['id'] == -1 &&
        _customMaterialCtrl.text.trim().isEmpty)
      e['material'] = 'Enter material name';
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

  // ── Submit ─────────────────────────────────────────────────────────────────
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

      await _api.post(ApiEndpoints.orders, data: body);

      if (Get.isRegistered<SupervisorOrdersController>()) {
        Get.find<SupervisorOrdersController>().fetchOrders(reset: true);
      }
      Get.back();
      FerosSnackbar.success('Order created successfully');
    } catch (e) {
      FerosSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
          'lbl_new_order'.tr,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navy,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    _Section(title: 'lbl_basic_info'.tr, children: _buildBasicInfo()),
                    const SizedBox(height: 16),
                    _Section(title: 'lbl_source_from'.tr, children: _buildSource()),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'lbl_destination_to'.tr,
                      badge: _clientAutoFilled
                          ? 'lbl_auto_filled_client'.tr
                          : null,
                      children: _buildDestination(),
                    ),
                    const SizedBox(height: 16),
                    _Section(title: 'lbl_freight'.tr, children: _buildFreight()),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'lbl_additional_info'.tr,
                      children: _buildAdditional(),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'lbl_eway_bill'.tr,
                      isOptional: true,
                      children: _buildEwayBill(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Sticky footer ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'btn_create_order'.tr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  List<Widget> _buildBasicInfo() {
    final isOther = _selectedMaterial?['id'] == -1;
    return [
      // Client
      _isLoadingClients
          ? const _FieldShimmer()
          : FerosSelectField<Map<String, dynamic>>(
              label: 'lbl_client'.tr,
              title: 'lbl_select_client'.tr,
              hint: 'lbl_select_client'.tr,
              isRequired: true,
              selectedDisplay: _selectedClient?['clientName'] as String?,
              items: _clients.where((c) => c['isActive'] == true).toList(),
              itemLabel: (c) => c['clientName'] as String? ?? '—',
              onSelected: _onClientSelected,
              errorText: _errors['client'],
              emptyMessage: 'lbl_no_clients_found'.tr,
            ),
      const SizedBox(height: 16),

      // Material Type
      _isLoadingMaterials
          ? const _FieldShimmer()
          : FerosSelectField<Map<String, dynamic>>(
              label: 'lbl_material_type'.tr,
              title: 'lbl_select_material'.tr,
              hint: 'lbl_select_material'.tr,
              isRequired: true,
              selectedDisplay: _selectedMaterial?['name'] as String?,
              items: _materials,
              itemLabel: (m) => m['name'] as String? ?? '—',
              onSelected: (m) => setState(() => _selectedMaterial = m),
              errorText: _errors['material'],
              emptyMessage: 'lbl_no_materials_found'.tr,
            ),
      if (isOther) ...[
        const SizedBox(height: 8),
        TextField(
          controller: _customMaterialCtrl,
          style: AppTextStyles.body,
          decoration: _deco().copyWith(
            hintText: 'Type material name...',
            hintStyle: AppTextStyles.hint,
          ),
        ),
      ],
      const SizedBox(height: 16),

      // Weight + Order Date
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_total_weight_tons'.tr, isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: AppTextStyles.body,
                  decoration: _deco(hasError: _errors.containsKey('weight'))
                      .copyWith(
                        hintText: '25.00',
                        hintStyle: AppTextStyles.hint,
                        suffixText: 'T',
                        suffixStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                ),
                if (_errors.containsKey('weight')) _Err(_errors['weight']!),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_order_date'.tr),
                const SizedBox(height: 6),
                _DateField(
                  value: _orderDate,
                  hint: 'Today',
                  onPicked: (d) => setState(() => _orderDate = d),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Label('lbl_expected_delivery'.tr),
      const SizedBox(height: 6),
      _DateField(
        value: _expectedDeliveryDate,
        hint: 'Select date',
        firstDate: DateTime.now(),
        onPicked: (d) => setState(() => _expectedDeliveryDate = d),
      ),
    ];
  }

  List<Widget> _buildSource() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isLoadingStates
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'lbl_state'.tr,
                    title: 'lbl_select_state'.tr,
                    hint: 'lbl_select_state'.tr,
                    isRequired: true,
                    selectedDisplay: _srcState?['name'] as String?,
                    items: _states,
                    itemLabel: (s) => s['name'] as String? ?? '—',
                    onSelected: (s) {
                      setState(() {
                        _srcState = s;
                        _srcCity = null;
                        _srcCities = [];
                      });
                      _loadSrcCities(s['id'] as int);
                    },
                    errorText: _errors['srcState'],
                    emptyMessage: 'lbl_no_states_found'.tr,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingSrcCities
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'lbl_city'.tr,
                    title: 'lbl_select_city'.tr,
                    hint: _srcState == null
                        ? 'lbl_select_state'.tr
                        : 'lbl_select_city'.tr,
                    isRequired: true,
                    selectedDisplay: _srcCity?['name'] as String?,
                    items: _srcCities,
                    itemLabel: (c) => c['name'] as String? ?? '—',
                    onSelected: (c) => setState(() => _srcCity = c),
                    enabled: _srcState != null,
                    errorText: _errors['srcCity'],
                    emptyMessage: 'lbl_no_cities_found'.tr,
                  ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Label('lbl_loading_address'.tr),
      const SizedBox(height: 6),
      TextField(
        controller: _srcAddressCtrl,
        style: AppTextStyles.body,
        decoration: _deco().copyWith(
          hintText: 'Depot / Loading point',
          hintStyle: AppTextStyles.hint,
        ),
      ),
    ];
  }

  List<Widget> _buildDestination() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isLoadingStates
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'lbl_state'.tr,
                    title: 'lbl_select_state'.tr,
                    hint: 'lbl_select_state'.tr,
                    isRequired: true,
                    selectedDisplay: _dstState?['name'] as String?,
                    items: _states,
                    itemLabel: (s) => s['name'] as String? ?? '—',
                    onSelected: (s) {
                      setState(() {
                        _dstState = s;
                        _dstCity = null;
                        _dstCities = [];
                      });
                      _loadDstCities(s['id'] as int);
                    },
                    errorText: _errors['dstState'],
                    emptyMessage: 'lbl_no_states_found'.tr,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingDstCities
                ? const _FieldShimmer()
                : FerosSelectField<Map<String, dynamic>>(
                    label: 'lbl_city'.tr,
                    title: 'lbl_select_city'.tr,
                    hint: _dstState == null
                        ? 'lbl_select_state'.tr
                        : 'lbl_select_city'.tr,
                    isRequired: true,
                    selectedDisplay: _dstCity?['name'] as String?,
                    items: _dstCities,
                    itemLabel: (c) => c['name'] as String? ?? '—',
                    onSelected: (c) => setState(() => _dstCity = c),
                    enabled: _dstState != null,
                    errorText: _errors['dstCity'],
                    emptyMessage: 'lbl_no_cities_found'.tr,
                  ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Label('lbl_delivery_address'.tr),
      const SizedBox(height: 6),
      TextField(
        controller: _dstAddressCtrl,
        style: AppTextStyles.body,
        decoration: _deco().copyWith(
          hintText: 'Delivery point',
          hintStyle: AppTextStyles.hint,
        ),
      ),
    ];
  }

  List<Widget> _buildFreight() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FerosSelectField<Map<String, dynamic>>(
              label: 'lbl_rate_type'.tr,
              title: 'lbl_rate_type'.tr,
              hint: 'lbl_rate_type'.tr,
              isRequired: true,
              selectedDisplay: _selectedRateType['name'] as String?,
              items: _rateTypes,
              itemLabel: (t) => t['name'] as String,
              onSelected: (t) => setState(() => _selectedRateType = t),
              emptyMessage: 'lbl_no_options'.tr,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_rate'.tr, isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _freightRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: AppTextStyles.body,
                  decoration:
                      _deco(
                        hasError: _errors.containsKey('freightRate'),
                      ).copyWith(
                        hintText: '1500.00',
                        hintStyle: AppTextStyles.hint,
                        prefixText: '₹ ',
                        prefixStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                ),
                if (_errors.containsKey('freightRate'))
                  _Err(_errors['freightRate']!),
              ],
            ),
          ),
        ],
      ),
      if (_selectedRateType['id'] == 'PER_TON') ...[
        const SizedBox(height: 16),
        FerosSelectField<Map<String, dynamic>>(
          label: 'lbl_bill_on'.tr,
          title: 'lbl_bill_on'.tr,
          hint: 'lbl_bill_on'.tr,
          selectedDisplay: _selectedBillingOn['name'] as String?,
          items: _billingOptions,
          itemLabel: (b) => b['name'] as String,
          onSelected: (b) => setState(() => _selectedBillingOn = b),
          emptyMessage: 'lbl_no_options'.tr,
        ),
      ],
    ];
  }

  List<Widget> _buildAdditional() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_special_instructions'.tr),
                const SizedBox(height: 6),
                TextField(
                  controller: _specialInstCtrl,
                  style: AppTextStyles.body,
                  decoration: _deco().copyWith(
                    hintText: 'Handle with care…',
                    hintStyle: AppTextStyles.hint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_remarks'.tr),
                const SizedBox(height: 6),
                TextField(
                  controller: _remarksCtrl,
                  style: AppTextStyles.body,
                  decoration: _deco().copyWith(
                    hintText: 'Internal notes…',
                    hintStyle: AppTextStyles.hint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildEwayBill() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_eway_bill_no'.tr),
                const SizedBox(height: 6),
                TextField(
                  controller: _ewayBillNoCtrl,
                  style: AppTextStyles.body,
                  decoration: _deco().copyWith(
                    hintText: 'EWB123456789',
                    hintStyle: AppTextStyles.hint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_date'.tr),
                const SizedBox(height: 6),
                _DateField(
                  value: _ewayBillDate,
                  hint: 'Pick',
                  onPicked: (d) => setState(() => _ewayBillDate = d),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('lbl_valid_upto'.tr),
                const SizedBox(height: 6),
                _DateField(
                  value: _ewayBillValidUpto,
                  hint: 'Pick',
                  onPicked: (d) => setState(() => _ewayBillValidUpto = d),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _deco({bool hasError = false}) => InputDecoration(
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.border,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.navy,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}

// ── Field-level shimmer (label + field box) ────────────────────────────────────
class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section container ──────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final String? badge;
  final bool isOptional;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
    this.badge,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                  letterSpacing: 0.6,
                  fontSize: 11,
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 6),
                Text(
                  'lbl_optional_section'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Label ──────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _Label(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      text: text,
      style: AppTextStyles.label,
      children: isRequired
          ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          : [],
    ),
  );
}

// ── Error text ─────────────────────────────────────────────────────────────────
class _Err extends StatelessWidget {
  final String text;
  const _Err(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.error),
    ),
  );
}

// ── Date picker field ──────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final void Function(DateTime) onPicked;
  final DateTime? firstDate;

  const _DateField({
    required this.value,
    required this.hint,
    required this.onPicked,
    this.firstDate,
  });

  String _fmt(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: DateTime(now.year + 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : hint,
                style: AppTextStyles.body.copyWith(
                  color: value != null
                      ? AppColors.bodyText
                      : AppColors.hintText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
