import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../controllers/service_men_equipment_services_controller.dart';

class ServiceMenEquipmentServiceDetailView extends StatefulWidget {
  final Map<String, dynamic> service;
  final ServiceMenEquipmentServicesController ctrl;
  const ServiceMenEquipmentServiceDetailView({super.key, required this.service, required this.ctrl});

  @override
  State<ServiceMenEquipmentServiceDetailView> createState() => _DetailState();
}

class _DetailState extends State<ServiceMenEquipmentServiceDetailView> {
  late Map<String, dynamic> _svc;
  List<Map<String, dynamic>> _parts = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _svc = widget.service;
    _loadParts();
  }

  ServiceMenEquipmentServicesController get ctrl => widget.ctrl;
  bool get _canManage => _svc['status'] != 'COMPLETED';

  Future<void> _loadParts() async {
    final p = await ctrl.fetchServiceParts(_svc);
    if (mounted) setState(() => _parts = p);
  }

  Future<void> _refresh() async {
    final fresh = await ctrl.refreshService(_svc['id'] as int);
    if (fresh != null && mounted) setState(() => _svc = fresh);
    await _loadParts();
  }

  Future<void> _wrap(Future<Object?> Function() fn) async {
    setState(() => _busy = true);
    await fn();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  List<Map<String, dynamic>> get _tasks =>
      (_svc['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    final status = _svc['status'] as String? ?? 'OPEN';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(_svc['serviceNumber']?.toString() ?? 'Service',
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _headerCard(status),
            const SizedBox(height: 12),
            _tasksCard(),
            const SizedBox(height: 12),
            _partsCard(),
            const SizedBox(height: 12),
            _costCard(),
            const SizedBox(height: 12),
            _vendorCard(),
            const SizedBox(height: 12),
            _attachmentsCard(),
            const SizedBox(height: 20),
            _actionButtons(status),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _headerCard(String status) {
    return _card(
      title: 'SERVICE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_svc['equipmentName']?.toString() ?? _svc['equipmentIdentifier']?.toString() ?? '',
              style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _pill(status.replaceAll('_', ' '), const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            _pill(_svc['triggeredBy']?.toString() ?? '', AppColors.background, AppColors.bodyText),
            _pill(_svc['serviceType']?.toString() ?? '', AppColors.background, AppColors.bodyText),
          ]),
          if (_svc['hmrAtService'] != null) ...[
            const SizedBox(height: 8),
            Text('HMR: ${_svc['hmrAtService']} hrs', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ],
      ),
    );
  }

  Widget _tasksCard() {
    return _card(
      title: 'TASKS',
      trailing: _canManage ? _linkBtn('+ Add', _onAddTask) : null,
      child: _tasks.isEmpty
          ? Text('No tasks yet', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
          : Column(
              children: _tasks.map((t) {
                final name = t['displayName'] ?? t['customName'] ?? t['taskTypeName'] ?? '—';
                final mech = t['assignedMechanicName'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text('$name', style: AppTextStyles.body.copyWith(color: AppColors.bodyText))),
                        if (t['cost'] != null && (t['cost'] as num) > 0)
                          Text('₹${(t['cost'] as num).toStringAsFixed(0)}', style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
                      ]),
                      if (mech != null)
                        Text('👤 $mech', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      if (_canManage)
                        Row(children: [
                          _linkBtn(t['assignedMechanicId'] != null ? 'Reassign' : 'Assign', () => _onAssign(t)),
                          const SizedBox(width: 16),
                          _linkBtn('Request Part', () => _onRequestPart(t)),
                        ]),
                      const Divider(height: 14, color: AppColors.border),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _partsCard() {
    return _card(
      title: 'PARTS USED',
      child: _parts.isEmpty
          ? Text('No parts', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
          : Column(
              children: _parts.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(p['sparePartName']?.toString() ?? '—', style: AppTextStyles.body.copyWith(color: AppColors.bodyText))),
                    Text('${p['quantityRequested'] ?? ''} ${p['unit'] ?? ''}  ', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                    _pill(p['status']?.toString() ?? '', AppColors.background, AppColors.bodyText),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _costCard() {
    final total = _svc['totalCost'];
    final completed = _svc['completedCost'];
    return _card(
      title: 'COST',
      trailing: _canManage ? _linkBtn('Edit est.', _onEditEstimate) : null,
      child: Row(children: [
        Expanded(child: _kv('Total (est.)', total != null ? '₹${(total as num).toStringAsFixed(0)}' : '—')),
        Expanded(child: _kv('Actual bill', completed != null ? '₹${(completed as num).toStringAsFixed(0)}' : '—')),
      ]),
    );
  }

  Widget _vendorCard() {
    final items = (_svc['vendorItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return _card(
      title: 'VENDOR / EXTERNAL ITEMS',
      trailing: _canManage ? _linkBtn('+ Add', _onAddVendor) : null,
      child: items.isEmpty
          ? Text('No items', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
          : Column(
              children: items.map((i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(i['description']?.toString() ?? '', style: AppTextStyles.body.copyWith(color: AppColors.bodyText))),
                    Text('₹${((i['cost'] ?? 0) as num).toStringAsFixed(0)}', style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
                    if (_canManage)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                        onPressed: _busy ? null : () => _wrap(() => ctrl.deleteVendorItem(_svc, i['id'] as int)),
                      ),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _attachmentsCard() {
    final est = (_svc['estimateAttachments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bill = (_svc['billAttachments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    Widget links(String label, List<Map<String, dynamic>> list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          if (list.isEmpty)
            Text('None', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
          else
            ...list.asMap().entries.map((e) => Text('📎 ${e.value['label'] ?? '$label ${e.key + 1}'}',
                style: AppTextStyles.body.copyWith(color: AppColors.navy))),
          const SizedBox(height: 6),
        ],
      );
    }

    return _card(
      title: 'DOCUMENTS',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [links('Estimate', est), links('Bill', bill)]),
    );
  }

  Widget _actionButtons(String status) {
    if (status == 'OPEN') {
      return _primaryBtn('Start Service', const Color(0xFFC2410C), () => _wrap(() => ctrl.startService(_svc)));
    }
    if (status == 'IN_PROGRESS') {
      return _primaryBtn('Complete Service', const Color(0xFF15803D), _onComplete);
    }
    return const SizedBox.shrink();
  }

  // ── Actions (bottom sheets) ─────────────────────────────────────────────────

  Future<void> _onAddTask() async {
    int? taskTypeId;
    final nameCtl = TextEditingController();
    final costCtl = TextEditingController();
    final ok = await _sheet('Add Task', [
      _dropdown<int>('Task type', taskTypeId, ctrl.taskTypes.map((t) => DropdownMenuItem<int>(value: t['id'] as int, child: Text(t['name']?.toString() ?? ''))).toList(), (v) => taskTypeId = v),
      _field('Or custom name', nameCtl),
      _field('Cost (₹)', costCtl, number: true),
    ]);
    if (ok == true) {
      await _wrap(() => ctrl.addTask(_svc, taskTypeId: taskTypeId, customName: nameCtl.text.trim(), cost: double.tryParse(costCtl.text)));
    }
  }

  Future<void> _onAssign(Map<String, dynamic> task) async {
    int? techId = task['assignedMechanicId'] as int?;
    final ok = await _sheet('Assign Technician', [
      _dropdown<int>('Technician', techId, ctrl.technicians.map((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text(m['name']?.toString() ?? ''))).toList(), (v) => techId = v),
    ]);
    if (ok == true && techId != null) {
      await _wrap(() => ctrl.assignTechnician(_svc, taskId: task['id'] as int, technicianId: techId!));
    }
  }

  Future<void> _onRequestPart(Map<String, dynamic> task) async {
    int? partId;
    final qtyCtl = TextEditingController(text: '1');
    final ok = await _sheet('Request Spare Part', [
      _dropdown<int>('Spare part', partId, ctrl.spareParts.map((p) => DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['name']?.toString() ?? ''))).toList(), (v) => partId = v),
      _field('Quantity', qtyCtl, number: true),
    ]);
    if (ok == true && partId != null) {
      await _wrap(() => ctrl.requestPart(_svc, sparePartId: partId!, quantity: int.tryParse(qtyCtl.text) ?? 1, taskId: task['id'] as int));
    }
  }

  Future<void> _onEditEstimate() async {
    final c = TextEditingController(text: _svc['estimatedCost']?.toString() ?? '');
    final ok = await _sheet('Estimated / Labour Cost', [_field('Amount (₹)', c, number: true)]);
    if (ok == true) {
      await _wrap(() => ctrl.updateCharges(_svc, c.text.trim().isEmpty ? null : double.tryParse(c.text)));
    }
  }

  Future<void> _onAddVendor() async {
    final descCtl = TextEditingController();
    final costCtl = TextEditingController();
    final ok = await _sheet('Add Vendor Item', [
      _field('Description', descCtl),
      _field('Cost (₹)', costCtl, number: true),
    ]);
    if (ok == true) {
      if (descCtl.text.trim().isEmpty) { FerosSnackbar.error('Enter a description'); return; }
      await _wrap(() => ctrl.addVendorItem(_svc, description: descCtl.text.trim(), cost: double.tryParse(costCtl.text)));
    }
  }

  Future<void> _onComplete() async {
    final hmrCtl = TextEditingController();
    final costCtl = TextEditingController();
    final ok = await _sheet('Complete Service', [
      _field('HMR at completion', hmrCtl, number: true),
      _field('Actual bill / completed cost (₹)', costCtl, number: true),
    ]);
    if (ok == true) {
      await _wrap(() => ctrl.completeService(_svc,
          completedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          completedHmr: double.tryParse(hmrCtl.text),
          completedCost: double.tryParse(costCtl.text)));
    }
  }

  // ── Small UI helpers ────────────────────────────────────────────────────────

  Future<bool?> _sheet(String title, List<Widget> fields) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 12),
            ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }

  Widget _dropdown<T>(String label, T? value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return StatefulBuilder(
      builder: (_, setSheet) => DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        items: items,
        onChanged: (v) { onChanged(v); setSheet(() => value = v); },
      ),
    );
  }

  Widget _linkBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _busy ? null : onTap,
          child: Text(label),
        ),
      );

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 2),
          Text(v, style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.bodyText)),
        ],
      );
}
