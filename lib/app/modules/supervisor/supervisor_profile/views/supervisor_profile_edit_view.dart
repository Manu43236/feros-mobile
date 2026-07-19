import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../controllers/supervisor_profile_controller.dart';

class SupervisorProfileEditView extends StatefulWidget {
  const SupervisorProfileEditView({super.key});

  @override
  State<SupervisorProfileEditView> createState() => _State();
}

class _State extends State<SupervisorProfileEditView> {
  final _ctrl = Get.find<SupervisorProfileController>();
  final _api  = Get.find<ApiClient>();

  // form state
  int?    _designationId;
  int?    _employmentTypeId;
  String  _dob          = '';
  String  _joiningDate  = '';
  String  _address      = '';
  int?    _stateId;
  int?    _cityId;
  String  _pincode      = '';
  String  _emergencyName  = '';
  String  _emergencyPhone = '';
  String  _bankName       = '';
  String  _accountNumber  = '';
  String  _ifscCode       = '';
  String  _accountHolder  = '';
  String  _licenseNumber  = '';
  String  _licenseExpiry  = '';

  // masters
  List<Map<String, dynamic>> _designations   = [];
  List<Map<String, dynamic>> _empTypes       = [];
  List<Map<String, dynamic>> _states         = [];
  List<Map<String, dynamic>> _cities         = [];
  bool _loadingMasters = true;

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadMasters();
  }

  void _prefill() {
    final p = _ctrl.profile.value;
    if (p == null) return;
    _designationId    = p['designationId'] as int?;
    _employmentTypeId = p['employmentTypeId'] as int?;
    _dob              = p['dateOfBirth']  as String? ?? '';
    _joiningDate      = p['joiningDate']  as String? ?? '';
    _address          = p['address']      as String? ?? '';
    _stateId          = p['stateId']      as int?;
    _cityId           = p['cityId']       as int?;
    _pincode          = p['pincode']      as String? ?? '';
    _emergencyName    = p['emergencyContactName']  as String? ?? '';
    _emergencyPhone   = p['emergencyContactPhone'] as String? ?? '';
    _bankName         = p['bankName']         as String? ?? '';
    _accountNumber    = p['accountNumber']    as String? ?? '';
    _ifscCode         = p['ifscCode']         as String? ?? '';
    _accountHolder    = p['accountHolderName'] as String? ?? '';
    _licenseNumber    = p['licenseNumber']    as String? ?? '';
    _licenseExpiry    = p['licenseExpiryDate'] as String? ?? '';
  }

  Future<void> _loadMasters() async {
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.designations),
        _api.get(ApiEndpoints.employmentTypes),
        _api.get(ApiEndpoints.states),
        _api.get(ApiEndpoints.cities),
      ]);
      setState(() {
        _designations = _list(results[0]);
        _empTypes     = _list(results[1]);
        _states       = _list(results[2]);
        _cities       = _list(results[3]);
        _loadingMasters = false;
      });
    } catch (_) {
      setState(() => _loadingMasters = false);
    }
  }

  List<Map<String, dynamic>> _list(dynamic res) =>
      ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();

  Future<void> _save() async {
    await _ctrl.saveProfile({
      if (_designationId != null)    'designationId':         _designationId,
      if (_employmentTypeId != null) 'employmentTypeId':      _employmentTypeId,
      if (_dob.isNotEmpty)           'dateOfBirth':           _dob,
      if (_joiningDate.isNotEmpty)   'joiningDate':           _joiningDate,
      if (_address.isNotEmpty)       'address':               _address,
      if (_stateId != null)          'stateId':               _stateId,
      if (_cityId != null)           'cityId':                _cityId,
      if (_pincode.isNotEmpty)       'pincode':               _pincode,
      if (_emergencyName.isNotEmpty) 'emergencyContactName':  _emergencyName,
      if (_emergencyPhone.isNotEmpty)'emergencyContactPhone': _emergencyPhone,
      if (_bankName.isNotEmpty)      'bankName':              _bankName,
      if (_accountNumber.isNotEmpty) 'accountNumber':         _accountNumber,
      if (_ifscCode.isNotEmpty)      'ifscCode':              _ifscCode,
      if (_accountHolder.isNotEmpty) 'accountHolderName':     _accountHolder,
      if (_licenseNumber.isNotEmpty) 'licenseNumber':         _licenseNumber,
      if (_licenseExpiry.isNotEmpty) 'licenseExpiryDate':     _licenseExpiry,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter',
                fontWeight: FontWeight.w600, fontSize: 16)),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        actions: [
          Obx(() => _ctrl.isSavingProfile.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(color: Colors.white, fontFamily: 'Inter',
                          fontWeight: FontWeight.w600, fontSize: 15)),
                )),
        ],
      ),
      body: _loadingMasters
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Role & Employment', [
                    _dropdown('Designation', _designations,
                        value: _designationId,
                        onChanged: (v) => setState(() => _designationId = v)),
                    _dropdown('Employment Type', _empTypes,
                        value: _employmentTypeId,
                        onChanged: (v) => setState(() => _employmentTypeId = v)),
                    _datePicker('Date of Birth', _dob,
                        onChanged: (v) => setState(() => _dob = v)),
                    _datePicker('Joining Date', _joiningDate,
                        onChanged: (v) => setState(() => _joiningDate = v)),
                  ]),
                  const SizedBox(height: 12),
                  _section('Address', [
                    _textField('Street Address', _address,
                        onChanged: (v) => _address = v),
                    _dropdown('State', _states,
                        value: _stateId,
                        onChanged: (v) => setState(() { _stateId = v; _cityId = null; })),
                    _dropdown('City', _cities
                        .where((c) => _stateId == null || c['stateId'] == _stateId).toList(),
                        value: _cityId,
                        onChanged: (v) => setState(() => _cityId = v)),
                    _textField('Pincode', _pincode, keyboardType: TextInputType.number,
                        onChanged: (v) => _pincode = v),
                  ]),
                  const SizedBox(height: 12),
                  _section('Emergency Contact', [
                    _textField('Name', _emergencyName,
                        onChanged: (v) => _emergencyName = v),
                    _textField('Phone', _emergencyPhone,
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => _emergencyPhone = v),
                  ]),
                  const SizedBox(height: 12),
                  _section('Bank Details', [
                    _textField('Bank Name', _bankName,
                        onChanged: (v) => _bankName = v),
                    _textField('Account Number', _accountNumber,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _accountNumber = v),
                    _textField('IFSC Code', _ifscCode,
                        onChanged: (v) => _ifscCode = v),
                    _textField('Account Holder Name', _accountHolder,
                        onChanged: (v) => _accountHolder = v),
                  ]),
                  const SizedBox(height: 12),
                  _section('License', [
                    _textField('License Number', _licenseNumber,
                        onChanged: (v) => _licenseNumber = v),
                    _datePicker('Expiry Date', _licenseExpiry,
                        onChanged: (v) => setState(() => _licenseExpiry = v)),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Text(title,
            style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.navy,
                letterSpacing: 0.4)),
      ),
      const Divider(height: 1, color: AppColors.border),
      ...children,
    ]),
  );

  Widget _textField(String label, String initial,
      {TextInputType? keyboardType, required ValueChanged<String> onChanged}) =>
      _FieldPad(child: TextField(
        controller: TextEditingController(text: initial)
          ..selection = TextSelection.collapsed(offset: initial.length),
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ));

  Widget _dropdown(String label, List<Map<String, dynamic>> items,
      {int? value, required ValueChanged<int?> onChanged}) =>
      _FieldPad(child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          isDense: true,
        ),
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          hint: const Text('Select', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
          items: items.map((m) => DropdownMenuItem<int>(
            value: m['id'] as int?,
            child: Text(m['name'] as String? ?? '',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
        ),
      ));

  Widget _datePicker(String label, String value,
      {required ValueChanged<String> onChanged}) =>
      _FieldPad(child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value.isNotEmpty
                ? DateTime.tryParse(value) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(d.toIso8601String().substring(0, 10));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
          ),
          child: Text(value.isEmpty ? '—' : value,
              style: AppTextStyles.body.copyWith(
                  color: value.isEmpty ? AppColors.mutedText : AppColors.bodyText)),
        ),
      ));
}

class _FieldPad extends StatelessWidget {
  final Widget child;
  const _FieldPad({required this.child});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), child: child);
}
