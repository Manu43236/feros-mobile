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

/// Create (vehicleId == null) or Edit (vehicleId != null) a vehicle.
/// ADMIN only.
class OfficeVehicleFormView extends StatefulWidget {
  final int? vehicleId;
  const OfficeVehicleFormView({super.key, this.vehicleId});

  bool get isEdit => vehicleId != null;

  @override
  State<OfficeVehicleFormView> createState() => _OfficeVehicleFormViewState();
}

class _OfficeVehicleFormViewState extends State<OfficeVehicleFormView> {
  final _api = Get.find<ApiClient>();

  // ── Loading ─────────────────────────────────────────────────────────────────
  bool _isLoadingForm = true;
  bool _isLoadingTypes = true;
  bool _isLoadingBrands = true;
  bool _isLoadingFuels = true;
  bool _isLoadingOwnership = true;
  bool _isLoadingStatuses = true;
  bool _isSubmitting = false;

  // ── Master data ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _vehicleTypes = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _fuelTypes = [];
  List<Map<String, dynamic>> _ownershipTypes = [];
  List<Map<String, dynamic>> _statuses = [];

  // ── Selections ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedBrand;
  Map<String, dynamic>? _selectedFuel;
  Map<String, dynamic>? _selectedOwnership;
  Map<String, dynamic>? _selectedStatus;

  // ── Date fields ──────────────────────────────────────────────────────────────
  DateTime? _agreementStart;
  DateTime? _agreementEnd;

  // ── Text controllers — Basic Info ────────────────────────────────────────────
  final _regCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _gvwCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _chassisCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _tankCapCtrl = TextEditingController();

  // ── Text controllers — Owner / Hired ─────────────────────────────────────────
  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _ownerPanCtrl = TextEditingController();
  final _ownerAddrCtrl = TextEditingController();
  final _agreementAmtCtrl = TextEditingController();

  // ── Finance ───────────────────────────────────────────────────────────────────
  bool _isFinanced = false;
  final _financerNameCtrl = TextEditingController();

  // ── Trip Scope ────────────────────────────────────────────────────────────────
  String? _selectedTripScope;

  // ── Extra Pay ─────────────────────────────────────────────────────────────────
  bool _extraPayEnabled = false;
  final _extraPayPerDayCtrl = TextEditingController();
  DateTime? _financeStart;
  DateTime? _financeEnd;

  // ── Text controllers — GPS ────────────────────────────────────────────────────
  final _gpsDeviceNumCtrl = TextEditingController();
  final _gpsImeiCtrl = TextEditingController();
  final _gpsProviderCtrl = TextEditingController();

  // ── Text controllers — Operations & Notes ────────────────────────────────────
  final _odometerCtrl = TextEditingController();
  final _fuelLevelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool get _isHired {
    final name = _selectedOwnership?['name'] as String? ?? '';
    return name.isNotEmpty && !name.toUpperCase().contains('OWN');
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    for (final c in [
      _regCtrl,
      _modelCtrl,
      _capacityCtrl,
      _gvwCtrl,
      _yearCtrl,
      _colorCtrl,
      _chassisCtrl,
      _engineCtrl,
      _tankCapCtrl,
      _ownerNameCtrl,
      _ownerPhoneCtrl,
      _ownerPanCtrl,
      _ownerAddrCtrl,
      _agreementAmtCtrl,
      _gpsDeviceNumCtrl,
      _gpsImeiCtrl,
      _gpsProviderCtrl,
      _odometerCtrl,
      _fuelLevelCtrl,
      _notesCtrl,
      _financerNameCtrl,
      _extraPayPerDayCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoadingForm = true);
    try {
      final futures = await Future.wait([
        _api.get(ApiEndpoints.vehicleTypes),
        _api.get(ApiEndpoints.vehicleBrands),
        _api.get(ApiEndpoints.fuelTypes),
        _api.get(ApiEndpoints.ownershipTypes),
        _api.get(ApiEndpoints.vehicleStatuses),
        if (widget.isEdit)
          _api.get(ApiEndpoints.vehicleById(widget.vehicleId!)),
      ]);

      final types = _list(futures[0]);
      final brands = _list(futures[1]);
      final fuels = _list(futures[2]);
      final ownerships = _list(futures[3]);
      final statuses = _list(futures[4]);

      if (mounted) {
        setState(() {
          _vehicleTypes = types;
          _brands = brands;
          _fuelTypes = fuels;
          _ownershipTypes = ownerships;
          _statuses = statuses;
          _isLoadingTypes = false;
          _isLoadingBrands = false;
          _isLoadingFuels = false;
          _isLoadingOwnership = false;
          _isLoadingStatuses = false;
        });
      }

      if (widget.isEdit && futures.length == 6) {
        _prefill(
          (futures[5].data as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
        );
      }
    } catch (e) {
      FerosSnackbar.error('Failed to load form data');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  List<Map<String, dynamic>> _list(dynamic res) =>
      ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();

  void _prefill(Map<String, dynamic> v) {
    _regCtrl.text = v['registrationNumber'] as String? ?? '';
    _modelCtrl.text = v['model'] as String? ?? '';
    _capacityCtrl.text = v['capacityInTons']?.toString() ?? '';
    _gvwCtrl.text = v['grossVehicleWeight']?.toString() ?? '';
    _yearCtrl.text = v['manufactureYear']?.toString() ?? '';
    _colorCtrl.text = v['color'] as String? ?? '';
    _chassisCtrl.text = v['chassisNumber'] as String? ?? '';
    _engineCtrl.text = v['engineNumber'] as String? ?? '';
    _tankCapCtrl.text = v['fuelTankCapacity']?.toString() ?? '';

    _ownerNameCtrl.text = v['ownerName'] as String? ?? '';
    _ownerPhoneCtrl.text = v['ownerPhone'] as String? ?? '';
    _ownerPanCtrl.text = v['ownerPan'] as String? ?? '';
    _ownerAddrCtrl.text = v['ownerAddress'] as String? ?? '';
    _agreementAmtCtrl.text = v['agreementAmount']?.toString() ?? '';

    _gpsDeviceNumCtrl.text = v['gpsDeviceNumber'] as String? ?? '';
    _gpsImeiCtrl.text = v['gpsDeviceImei'] as String? ?? '';
    _gpsProviderCtrl.text = v['gpsProvider'] as String? ?? '';

    _odometerCtrl.text = v['currentOdometerReading']?.toString() ?? '';
    _fuelLevelCtrl.text = v['currentFuelLevel']?.toString() ?? '';
    _notesCtrl.text = v['notes'] as String? ?? '';

    // Match selections by id
    final vtId = v['vehicleTypeId'];
    final brId = v['brandId'];
    final ftId = v['fuelTypeId'];
    final owId = v['ownershipTypeId'];
    final stId = v['currentStatusId'];

    setState(() {
      _selectedType = _vehicleTypes.firstWhereOrNull((t) => t['id'] == vtId);
      _selectedBrand = _brands.firstWhereOrNull((b) => b['id'] == brId);
      _selectedFuel = _fuelTypes.firstWhereOrNull((f) => f['id'] == ftId);
      _selectedOwnership = _ownershipTypes.firstWhereOrNull(
        (o) => o['id'] == owId,
      );
      _selectedStatus = _statuses.firstWhereOrNull((s) => s['id'] == stId);

      _agreementStart = _parseDate(v['agreementStartDate']);
      _agreementEnd = _parseDate(v['agreementEndDate']);
      _isFinanced = (v['isFinanced'] as bool?) ?? false;
      _financerNameCtrl.text = v['financerName'] as String? ?? '';
      _financeStart = _parseDate(v['financeStartDate']);
      _financeEnd = _parseDate(v['financeEndDate']);
      _extraPayEnabled = (v['extraPayEnabled'] as bool?) ?? false;
      _extraPayPerDayCtrl.text = v['extraPayPerDay']?.toString() ?? '';
      _selectedTripScope = v['tripScope'] as String?;
    });
  }

  DateTime? _parseDate(dynamic d) {
    if (d == null) return null;
    try {
      return DateTime.parse(d as String);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final reg = _regCtrl.text.trim();
    if (reg.isEmpty) {
      FerosSnackbar.error('Registration number is required');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{'registrationNumber': reg};

      if (_selectedType != null) body['vehicleTypeId'] = _selectedType!['id'];
      if (_selectedBrand != null) body['brandId'] = _selectedBrand!['id'];
      if (_selectedFuel != null) body['fuelTypeId'] = _selectedFuel!['id'];
      if (_selectedOwnership != null)
        body['ownershipTypeId'] = _selectedOwnership!['id'];
      if (_selectedStatus != null)
        body['currentStatusId'] = _selectedStatus!['id'];

      if (_modelCtrl.text.trim().isNotEmpty)
        body['model'] = _modelCtrl.text.trim();
      final cap = double.tryParse(_capacityCtrl.text.trim());
      if (cap != null) body['capacityInTons'] = cap;
      final gvw = double.tryParse(_gvwCtrl.text.trim());
      if (gvw != null) body['grossVehicleWeight'] = gvw;
      final yr = int.tryParse(_yearCtrl.text.trim());
      if (yr != null) body['manufactureYear'] = yr;
      if (_colorCtrl.text.trim().isNotEmpty)
        body['color'] = _colorCtrl.text.trim();
      if (_chassisCtrl.text.trim().isNotEmpty)
        body['chassisNumber'] = _chassisCtrl.text.trim();
      if (_engineCtrl.text.trim().isNotEmpty)
        body['engineNumber'] = _engineCtrl.text.trim();
      final tank = double.tryParse(_tankCapCtrl.text.trim());
      if (tank != null) body['fuelTankCapacity'] = tank;

      final fuelCheck = double.tryParse(_fuelLevelCtrl.text.trim());
      if (tank != null && fuelCheck != null && fuelCheck > tank) {
        FerosSnackbar.error('Current fuel cannot exceed tank capacity ($tank L)');
        setState(() => _isSubmitting = false);
        return;
      }

      // Owner / Hired
      if (_isHired) {
        if (_ownerNameCtrl.text.trim().isNotEmpty)
          body['ownerName'] = _ownerNameCtrl.text.trim();
        if (_ownerPhoneCtrl.text.trim().isNotEmpty)
          body['ownerPhone'] = _ownerPhoneCtrl.text.trim();
        if (_ownerPanCtrl.text.trim().isNotEmpty)
          body['ownerPan'] = _ownerPanCtrl.text.trim();
        if (_ownerAddrCtrl.text.trim().isNotEmpty)
          body['ownerAddress'] = _ownerAddrCtrl.text.trim();
        if (_agreementStart != null)
          body['agreementStartDate'] = _formatDate(_agreementStart!);
        if (_agreementEnd != null)
          body['agreementEndDate'] = _formatDate(_agreementEnd!);
        final amt = double.tryParse(_agreementAmtCtrl.text.trim());
        if (amt != null) body['agreementAmount'] = amt;
      }

      // GPS
      if (_gpsDeviceNumCtrl.text.trim().isNotEmpty)
        body['gpsDeviceNumber'] = _gpsDeviceNumCtrl.text.trim();
      if (_gpsImeiCtrl.text.trim().isNotEmpty)
        body['gpsDeviceImei'] = _gpsImeiCtrl.text.trim();
      if (_gpsProviderCtrl.text.trim().isNotEmpty)
        body['gpsProvider'] = _gpsProviderCtrl.text.trim();

      // Operations
      final odo = double.tryParse(_odometerCtrl.text.trim());
      if (odo != null) body['currentOdometerReading'] = odo;
      final fuel = double.tryParse(_fuelLevelCtrl.text.trim());
      if (fuel != null) body['currentFuelLevel'] = fuel;

      // Finance
      body['isFinanced'] = _isFinanced;
      if (_isFinanced) {
        if (_financerNameCtrl.text.trim().isNotEmpty)
          body['financerName'] = _financerNameCtrl.text.trim();
        if (_financeStart != null)
          body['financeStartDate'] = _formatDate(_financeStart!);
        if (_financeEnd != null)
          body['financeEndDate'] = _formatDate(_financeEnd!);
      }

      // Extra Pay
      body['extraPayEnabled'] = _extraPayEnabled;
      if (_extraPayEnabled) {
        final epd = double.tryParse(_extraPayPerDayCtrl.text.trim());
        if (epd != null) body['extraPayPerDay'] = epd;
      }

      // Trip Scope
      if (_selectedTripScope != null) body['tripScope'] = _selectedTripScope;

      // Notes
      if (_notesCtrl.text.trim().isNotEmpty)
        body['notes'] = _notesCtrl.text.trim();

      if (widget.isEdit) {
        await _api.put(ApiEndpoints.vehicleById(widget.vehicleId!), data: body);
      } else {
        await _api.post(ApiEndpoints.vehicles, data: body);
      }

      Get.back(result: true);
      FerosSnackbar.success(
        widget.isEdit ? 'Vehicle updated' : 'Vehicle added',
      );
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
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Text(
          widget.isEdit ? 'Edit Vehicle' : 'New Vehicle',
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
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Basic Info ────────────────────────────────────────
                      _Section(
                        'BASIC INFO',
                        children: [
                          _field(
                            'Registration Number *',
                            _regCtrl,
                            'e.g. MH-12-AB-1234',
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9\-]'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingTypes
                              ? const _FieldShimmer()
                              : FerosSelectField<Map<String, dynamic>>(
                                  label: 'Vehicle Type',
                                  title: 'Select Vehicle Type',
                                  hint: 'Search type…',
                                  items: _vehicleTypes,
                                  itemLabel: (t) => t['name'] as String? ?? '',
                                  selectedDisplay:
                                      _selectedType?['name'] as String?,
                                  onSelected: (t) =>
                                      setState(() => _selectedType = t),
                                ),
                          const SizedBox(height: 12),
                          _isLoadingBrands
                              ? const _FieldShimmer()
                              : FerosSelectField<Map<String, dynamic>>(
                                  label: 'Brand',
                                  title: 'Select Brand',
                                  hint: 'Search brand…',
                                  items: _brands,
                                  itemLabel: (b) => b['name'] as String? ?? '',
                                  selectedDisplay:
                                      _selectedBrand?['name'] as String?,
                                  onSelected: (b) =>
                                      setState(() => _selectedBrand = b),
                                ),
                          const SizedBox(height: 12),
                          _field(
                            'Model',
                            _modelCtrl,
                            'e.g. 407, Prima 4940, BS4',
                          ),
                          const SizedBox(height: 12),
                          _isLoadingFuels
                              ? const _FieldShimmer()
                              : FerosSelectField<Map<String, dynamic>>(
                                  label: 'Fuel Type',
                                  title: 'Select Fuel Type',
                                  hint: 'Search fuel type…',
                                  items: _fuelTypes,
                                  itemLabel: (f) => f['name'] as String? ?? '',
                                  selectedDisplay:
                                      _selectedFuel?['name'] as String?,
                                  onSelected: (f) =>
                                      setState(() => _selectedFuel = f),
                                ),
                          const SizedBox(height: 12),
                          _isLoadingOwnership
                              ? const _FieldShimmer()
                              : FerosSelectField<Map<String, dynamic>>(
                                  label: 'Ownership Type',
                                  title: 'Select Ownership',
                                  hint: 'Search ownership…',
                                  items: _ownershipTypes,
                                  itemLabel: (o) => o['name'] as String? ?? '',
                                  selectedDisplay:
                                      _selectedOwnership?['name'] as String?,
                                  onSelected: (o) =>
                                      setState(() => _selectedOwnership = o),
                                ),
                          const SizedBox(height: 12),
                          _isLoadingStatuses
                              ? const _FieldShimmer()
                              : FerosSelectField<Map<String, dynamic>>(
                                  label: 'Current Status',
                                  title: 'Select Status',
                                  hint: 'Search status…',
                                  items: _statuses,
                                  itemLabel: (s) => s['name'] as String? ?? '',
                                  selectedDisplay:
                                      _selectedStatus?['name'] as String?,
                                  onSelected: (s) =>
                                      setState(() => _selectedStatus = s),
                                ),
                          const SizedBox(height: 12),
                          // ── Trip Scope ──────────────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Scope',
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _TripScopeChip(
                                    label: 'Intra-State',
                                    value: 'INTRA_STATE',
                                    selected: _selectedTripScope == 'INTRA_STATE',
                                    onTap: () => setState(() =>
                                        _selectedTripScope = _selectedTripScope == 'INTRA_STATE' ? null : 'INTRA_STATE'),
                                  ),
                                  const SizedBox(width: 8),
                                  _TripScopeChip(
                                    label: 'Inter-State',
                                    value: 'INTER_STATE',
                                    selected: _selectedTripScope == 'INTER_STATE',
                                    onTap: () => setState(() =>
                                        _selectedTripScope = _selectedTripScope == 'INTER_STATE' ? null : 'INTER_STATE'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'Capacity (Tons)',
                                  _capacityCtrl,
                                  'e.g. 20',
                                  inputType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  'GVW (Tons)',
                                  _gvwCtrl,
                                  'e.g. 49',
                                  inputType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'Mfg. Year',
                                  _yearCtrl,
                                  'e.g. 2020',
                                  inputType: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'Color',
                                  _colorCtrl,
                                  'e.g. White',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  'Tank Capacity (L)',
                                  _tankCapCtrl,
                                  'e.g. 400',
                                  inputType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Chassis Number',
                            _chassisCtrl,
                            'e.g. MA1VC2HVXL1234567',
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Engine Number',
                            _engineCtrl,
                            'e.g. K9K892T1234567',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 2. Owner / Hired Info (conditional) ──────────────────
                      if (_isHired) ...[
                        _Section(
                          'OWNER / HIRED INFO',
                          children: [
                            _field(
                              'Owner Name',
                              _ownerNameCtrl,
                              'Enter owner name',
                            ),
                            const SizedBox(height: 12),
                            _field(
                              'Phone',
                              _ownerPhoneCtrl,
                              'Enter owner phone',
                              inputType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              'PAN Number',
                              _ownerPanCtrl,
                              'e.g. ABCDE1234F',
                            ),
                            const SizedBox(height: 12),
                            _field(
                              'Address',
                              _ownerAddrCtrl,
                              'Enter owner address',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _DatePickerField(
                                    label: 'Agreement Start',
                                    value: _agreementStart,
                                    hint: 'Select date',
                                    onPicked: (d) =>
                                        setState(() => _agreementStart = d),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DatePickerField(
                                    label: 'Agreement End',
                                    value: _agreementEnd,
                                    hint: 'Select date',
                                    onPicked: (d) =>
                                        setState(() => _agreementEnd = d),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field(
                              'Agreement Amount (₹)',
                              _agreementAmtCtrl,
                              'e.g. 50000',
                              inputType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 3. Finance ────────────────────────────────────────────
                      _Section(
                        'FINANCE',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Vehicle is financed',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              Switch(
                                value: _isFinanced,
                                onChanged: (v) =>
                                    setState(() => _isFinanced = v),
                                activeColor: AppColors.navy,
                              ),
                            ],
                          ),
                          if (_isFinanced) ...[
                            const SizedBox(height: 12),
                            _field(
                              'Financer Name (Bank / NBFC)',
                              _financerNameCtrl,
                              'e.g. HDFC Bank, Shriram Finance',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _DatePickerField(
                                    label: 'Finance From',
                                    value: _financeStart,
                                    hint: 'Select date',
                                    onPicked: (d) =>
                                        setState(() => _financeStart = d),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DatePickerField(
                                    label: 'Finance To',
                                    value: _financeEnd,
                                    hint: 'Select date',
                                    onPicked: (d) =>
                                        setState(() => _financeEnd = d),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 4. Extra Pay ──────────────────────────────────────────
                      _Section(
                        'DRIVER EXTRA PAY',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enable extra pay',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Additional pay for driver assigned to this vehicle',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _extraPayEnabled,
                                onChanged: (v) =>
                                    setState(() => _extraPayEnabled = v),
                                activeColor: AppColors.navy,
                              ),
                            ],
                          ),
                          if (_extraPayEnabled) ...[
                            const SizedBox(height: 12),
                            _field(
                              'Extra Pay Per Day (₹)',
                              _extraPayPerDayCtrl,
                              'e.g. 100',
                              inputType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 5. GPS ────────────────────────────────────────────────
                      _Section(
                        'GPS & TRACKING',
                        children: [
                          _field(
                            'Device Number',
                            _gpsDeviceNumCtrl,
                            'Enter GPS device number',
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'IMEI',
                            _gpsImeiCtrl,
                            'Enter IMEI number',
                            inputType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Provider',
                            _gpsProviderCtrl,
                            'e.g. Tata, Jio',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 5. Operations ─────────────────────────────────────────
                      _Section(
                        'OPERATIONS',
                        children: [
                          _field(
                            'Odometer (km)',
                            _odometerCtrl,
                            'e.g. 45000',
                            inputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Current Fuel Level (L)',
                            _fuelLevelCtrl,
                            'e.g. 250',
                            inputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 6. Notes ──────────────────────────────────────────────
                      _Section(
                        'NOTES',
                        children: [
                          _field(
                            'Notes',
                            _notesCtrl,
                            'Optional notes about this vehicle',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Sticky footer button ───────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isEdit ? 'Save Changes' : 'Add Vehicle',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: AppTextStyles.caption.copyWith(
      color: AppColors.mutedText,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      fontSize: 11,
    ),
  );
}

// ── Section wrapper ─────────────────────────────────────────────────────────────
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
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Trip Scope chip ───────────────────────────────────────────────────────────
class _TripScopeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TripScopeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          border: Border.all(
            color: selected ? AppColors.navy : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ── Date picker field ────────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPicked;
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onPicked,
  });

  String _format(DateTime d) {
    const months = [
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2040),
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
        ),
      ],
    );
  }
}

// ── Field shimmer ────────────────────────────────────────────────────────────────
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
    );
  }
}

// ── Form skeleton ────────────────────────────────────────────────────────────────
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
            _skeletonSection(fields: 8),
            const SizedBox(height: 16),
            _skeletonSection(fields: 6),
            const SizedBox(height: 16),
            _skeletonSection(fields: 3),
            const SizedBox(height: 16),
            _skeletonSection(fields: 2),
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
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            fields,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
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
