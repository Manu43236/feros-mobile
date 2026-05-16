import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../controllers/service_men_services_controller.dart';

// ── Date helpers ──────────────────────────────────────────────────────────────
String? _fmtDate(dynamic d) {
  if (d == null) return null;
  try {
    final s = d.toString();
    // handles both "yyyy-MM-dd" and full ISO datetime
    final dt = DateTime.parse(s);
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return null;
  }
}

String? _fmtDateTime(dynamic d) {
  if (d == null) return null;
  try {
    final dt = DateTime.parse(d.toString()).toLocal();
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  } catch (_) {
    return null;
  }
}

// ── Status / chip helpers ─────────────────────────────────────────────────────
Widget _statusChip(String status) {
  final map = {
    'OPEN':        (_chipBg(0xFFEFF6FF), _chipFg(0xFF1D4ED8), 'Open'),
    'IN_PROGRESS': (_chipBg(0xFFFFF7ED), _chipFg(0xFFC2410C), 'In Progress'),
    'COMPLETED':   (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D), 'Completed'),
    'OVERDUE':     (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C), 'Overdue'),
  };
  final entry = map[status];
  if (entry == null) return const SizedBox.shrink();
  return _Chip(label: entry.$3, bg: entry.$1, fg: entry.$2);
}

Widget _triggeredChip(String t) {
  final map = {
    'SCHEDULED':  (_chipBg(0xFFF5F3FF), _chipFg(0xFF6D28D9), 'Scheduled'),
    'BREAKDOWN':  (_chipBg(0xFFFFF7ED), _chipFg(0xFFC2410C), 'Breakdown'),
    'ACCIDENT':   (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C), 'Accident'),
    'COMPLIANCE': (_chipBg(0xFFEFF6FF), _chipFg(0xFF1D4ED8), 'Compliance'),
    'WARRANTY':   (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D), 'Warranty'),
  };
  final entry = map[t];
  if (entry == null) return const SizedBox.shrink();
  return _Chip(label: entry.$3, bg: entry.$1, fg: entry.$2);
}

Widget _partStatusChip(String s) {
  final map = {
    'REQUESTED': (_chipBg(0xFFFFFBEB), _chipFg(0xFFB45309), 'Requested'),
    'APPROVED':  (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D), 'Approved'),
    'REJECTED':  (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C), 'Rejected'),
  };
  final entry = map[s];
  if (entry == null) return const SizedBox.shrink();
  return _Chip(label: entry.$3, bg: entry.$1, fg: entry.$2);
}

Color _chipBg(int hex) => Color(hex);
Color _chipFg(int hex) => Color(hex);

String _payerLabel(String p) {
  switch (p) {
    case 'WARRANTY_OEM': return 'OEM Warranty';
    case 'WARRANTY_ANC': return 'ANC Warranty';
    case 'INSURANCE':    return 'Insurance';
    case 'AMC':          return 'AMC Contract';
    default:             return p;
  }
}

String _serviceTypeLabel(String t, String? vendor) {
  if (t == 'INTERNAL')   return 'Internal (Self)';
  if (t == 'OEM_CENTER') return 'OEM: ${vendor ?? "Service Center"}';
  return vendor ?? '3rd Party';
}

// ── Main view ─────────────────────────────────────────────────────────────────
class ServiceMenServiceDetailView extends StatefulWidget {
  final Map<String, dynamic> service;
  const ServiceMenServiceDetailView({super.key, required this.service});

  @override
  State<ServiceMenServiceDetailView> createState() =>
      _ServiceMenServiceDetailViewState();
}

class _ServiceMenServiceDetailViewState
    extends State<ServiceMenServiceDetailView> {
  late Map<String, dynamic> _service;
  final _ctrl = Get.find<ServiceMenServicesController>();

  List<Map<String, dynamic>> _parts = [];
  bool _loadingParts = true;

  @override
  void initState() {
    super.initState();
    _service = Map<String, dynamic>.from(widget.service);
    _loadParts();
  }

  Future<void> _loadParts() async {
    final parts = await _ctrl.fetchServiceParts(_service['id'] as int);
    if (mounted) setState(() { _parts = parts; _loadingParts = false; });
  }

  List<Map<String, dynamic>> get _tasks =>
      (_service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  String get _status => _service['status'] as String? ?? 'OPEN';

  Future<void> _toggleTask(Map<String, dynamic> task) async {
    if (task['status'] == 'COMPLETED') return;
    final updated = await _ctrl.completeTask(
      _service['id'] as int,
      task['id'] as int,
    );
    if (updated != null && mounted) setState(() => _service = updated);
  }

  void _showStartConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Service',
            style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
        content: Text(
          'Start working on ${_service['serviceNumber']}?',
          style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await _ctrl.startService(_service['id'] as int);
              if (ok && mounted) {
                final updated = _ctrl.services
                    .firstWhereOrNull((s) => s['id'] == _service['id']);
                if (updated != null) setState(() => _service = updated);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompleteSheet() {
    final notesCtrl = TextEditingController();
    final odoCtrl   = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete Service',
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 20),
            Text('Odometer Reading (optional)',
                style: AppTextStyles.label.copyWith(color: AppColors.navy)),
            const SizedBox(height: 6),
            TextField(
              controller: odoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'e.g. 45000',
                hintStyle:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Completion Notes (optional)',
                style: AppTextStyles.label.copyWith(color: AppColors.navy)),
            const SizedBox(height: 6),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any remarks about the service…',
                hintStyle:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final today =
                      DateTime.now().toIso8601String().substring(0, 10);
                  final odo = int.tryParse(odoCtrl.text.trim());
                  final ok = await _ctrl.completeService(
                    _service['id'] as int,
                    completedDate: today,
                    odometer: odo,
                  );
                  if (ok && mounted) {
                    final updated = _ctrl.services
                        .firstWhereOrNull((s) => s['id'] == _service['id']);
                    if (updated != null) setState(() => _service = updated);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Mark Complete',
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    Map<String, dynamic>? selectedType;
    List<Map<String, dynamic>> taskTypes = [];
    bool loadingTypes = true;

    final api = Get.find<ApiClient>();
    api.get(ApiEndpoints.serviceTaskTypes).then((res) {
      taskTypes = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      loadingTypes = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Task',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 20),
              FerosSelectField<Map<String, dynamic>>(
                label: 'Task Type (optional)',
                title: 'Select Task Type',
                hint: 'Search task types…',
                selectedDisplay:
                    selectedType != null ? selectedType!['name'] as String : null,
                items: taskTypes,
                itemLabel: (t) => t['name'] as String? ?? '',
                onSelected: (t) => setSheetState(() {
                  selectedType = t;
                  nameCtrl.clear();
                }),
                isLoading: loadingTypes,
                emptyMessage: 'No task types found',
              ),
              if (selectedType == null) ...[
                const SizedBox(height: 16),
                Text('Custom Name',
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Replace brake pads',
                    hintStyle:
                        AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Cost (optional)',
                  style: AppTextStyles.label.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              TextField(
                controller: costCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: '₹ ',
                  hintStyle:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (selectedType == null && name.isEmpty) {
                      FerosSnackbar.error('Enter a task type or custom name');
                      return;
                    }
                    final cost = double.tryParse(costCtrl.text.trim());
                    Navigator.pop(context);
                    final updated = await _ctrl.addTask(
                      _service['id'] as int,
                      taskTypeId: selectedType?['id'] as int?,
                      customName: selectedType == null ? name : null,
                      cost: cost,
                    );
                    if (updated != null && mounted) {
                      setState(() => _service = updated);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Add Task',
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestPartSheet() {
    final qtyCtrl = TextEditingController(text: '1');
    Map<String, dynamic>? selectedPart;
    List<Map<String, dynamic>> spareParts = [];
    bool isLoadingParts = true;

    final api = Get.find<ApiClient>();
    api.get(ApiEndpoints.spareParts).then((res) {
      spareParts = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      isLoadingParts = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Spare Part',
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 20),
              FerosSelectField<Map<String, dynamic>>(
                label: 'Spare Part',
                title: 'Select Spare Part',
                hint: 'Search parts…',
                isRequired: true,
                selectedDisplay:
                    selectedPart != null ? selectedPart!['name'] as String : null,
                items: spareParts,
                itemLabel: (p) => p['name'] as String? ?? '',
                onSelected: (p) => setSheetState(() => selectedPart = p),
                isLoading: isLoadingParts,
                emptyMessage: 'No spare parts found',
              ),
              const SizedBox(height: 16),
              Text('Quantity',
                  style: AppTextStyles.label.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '1',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedPart == null) return;
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                    Navigator.pop(context);
                    final ok = await _ctrl.requestPart(
                      serviceId:   _service['id'] as int,
                      sparePartId: selectedPart!['id'] as int,
                      quantity:    qty,
                    );
                    if (ok && mounted) _loadParts();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Submit Request',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final triggeredBy = _service['triggeredBy'] as String?;
    final payerType   = _service['payerType']   as String?;
    final isEscalated = _service['isEscalated'] == true;
    final serviceType = _service['serviceType'] as String? ?? '';
    final vendorName  = _service['vendorName']  as String?;
    final location    = _service['location']    as String?;
    final serviceDate = _fmtDate(_service['serviceDate']);
    final odometer    = _service['odometer'];
    final dueAtOdo    = _service['dueAtOdometer'];
    final notes       = _service['notes']       as String?;

    // Insurance
    final isInsurance   = payerType == 'INSURANCE';
    final claimNo       = _service['insuranceClaimNo']  as String?;
    final claimAmt      = _service['insuranceClaimAmt'];

    // Compliance
    final isCompliance  = triggeredBy == 'COMPLIANCE';
    final certNo        = _service['certificateNumber']   as String?;
    final certValidUntil = _fmtDate(_service['certificateValidUntil']);

    // Timeline
    final createdAt   = _fmtDateTime(_service['createdAt']);
    final startedAt   = _fmtDateTime(_service['startedAt']);
    final completedAt = _fmtDate(_service['completedDate']);

    // Cost
    final taskCost = _tasks.fold<double>(
        0, (s, t) => s + ((t['cost'] as num?)?.toDouble() ?? 0.0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _service['serviceNumber'] ?? 'Service Detail',
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            Text(
              _service['vehicleRegistrationNumber'] ?? '',
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'Inter', fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Status chips row ─────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _statusChip(_status),
                    if (triggeredBy != null) _triggeredChip(triggeredBy),
                    if (isEscalated)
                      _Chip(
                        label: 'Escalated',
                        bg: const Color(0xFFFFFBEB),
                        fg: const Color(0xFFB45309),
                      ),
                    if (payerType != null && payerType != 'OWN_EXPENSE')
                      _Chip(
                        label: _payerLabel(payerType),
                        bg: const Color(0xFFF0FDF4),
                        fg: const Color(0xFF15803D),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Service Info ─────────────────────────────────────────
                _Section(
                  title: 'Service Info',
                  child: Column(
                    children: [
                      _InfoRow('Vehicle',
                          _service['vehicleRegistrationNumber'] ?? '—'),
                      _InfoRow('Service No', _service['serviceNumber'] ?? '—'),
                      _InfoRow('Type',
                          _serviceTypeLabel(serviceType, vendorName)),
                      if (serviceDate != null)
                        _InfoRow('Service Date', serviceDate),
                      if (odometer != null)
                        _InfoRow('Odometer',
                            '${(odometer as num).toStringAsFixed(0)} km'),
                      if (dueAtOdo != null)
                        _InfoRow('Due At',
                            '${(dueAtOdo as num).toStringAsFixed(0)} km'),
                      if (location != null) _InfoRow('Location', location),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Insurance Details ─────────────────────────────────────
                if (isInsurance && (claimNo != null || claimAmt != null))
                  _ColoredSection(
                    bg: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFBFDBFE),
                    title: 'Insurance Claim',
                    titleColor: const Color(0xFF1D4ED8),
                    child: Column(
                      children: [
                        if (claimNo != null)
                          _InfoRow('Claim No', claimNo),
                        if (claimAmt != null)
                          _InfoRow('Claim Amount',
                              '₹${(claimAmt as num).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                if (isInsurance && (claimNo != null || claimAmt != null))
                  const SizedBox(height: 12),

                // ── Compliance Certificate ────────────────────────────────
                if (isCompliance && (certNo != null || certValidUntil != null))
                  _ColoredSection(
                    bg: const Color(0xFFF5F3FF),
                    borderColor: const Color(0xFFDDD6FE),
                    title: 'Compliance Certificate',
                    titleColor: const Color(0xFF6D28D9),
                    child: Column(
                      children: [
                        if (certNo != null)
                          _InfoRow('Certificate No', certNo),
                        if (certValidUntil != null)
                          _InfoRow('Valid Until', certValidUntil),
                      ],
                    ),
                  ),
                if (isCompliance && (certNo != null || certValidUntil != null))
                  const SizedBox(height: 12),

                // ── Timeline ─────────────────────────────────────────────
                _Section(
                  title: 'Timeline',
                  child: _Timeline(events: [
                    _TimelineEvent(
                      label: 'Service Created',
                      sub: createdAt,
                      done: true,
                    ),
                    _TimelineEvent(
                      label: 'Work Started',
                      sub: startedAt,
                      done: _status == 'IN_PROGRESS' ||
                          _status == 'COMPLETED',
                      active: _status == 'IN_PROGRESS',
                    ),
                    _TimelineEvent(
                      label: 'Completed',
                      sub: completedAt,
                      done: _status == 'COMPLETED',
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Tasks ────────────────────────────────────────────────
                _Section(
                  title: 'Tasks',
                  trailing: _status != 'COMPLETED'
                      ? GestureDetector(
                          onTap: _showAddTaskSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Add Task',
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : null,
                  child: _tasks.isEmpty
                      ? Text('No tasks yet — tap Add Task to log work',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText))
                      : Column(
                          children: [
                            ..._tasks.map((task) {
                              final done = task['status'] == 'COMPLETED';
                              final cost = (task['cost'] as num?)?.toDouble();
                              final isRecurring = task['isRecurring'] == true;
                              final freqKm = task['frequencyKm'];
                              return InkWell(
                                onTap: _status == 'COMPLETED'
                                    ? null
                                    : () => _toggleTask(task),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        done
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: done
                                            ? AppColors.success
                                            : AppColors.mutedText,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['displayName'] ??
                                                  task['customName'] ??
                                                  '—',
                                              style: AppTextStyles.body.copyWith(
                                                color: done
                                                    ? AppColors.mutedText
                                                    : AppColors.bodyText,
                                                decoration: done
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (isRecurring && freqKm != null)
                                              Text(
                                                'Every ${freqKm.toString()} km',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        color: AppColors.mutedText),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (cost != null && cost > 0)
                                        Text(
                                          '₹${cost.toStringAsFixed(0)}',
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.mutedText),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (taskCost > 0) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Cost',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(color: AppColors.navy)),
                                    Text(
                                      '₹${taskCost.toStringAsFixed(0)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 12),

                // ── Parts Used ───────────────────────────────────────────
                _Section(
                  title: 'Parts Used',
                  trailing: _status == 'IN_PROGRESS'
                      ? GestureDetector(
                          onTap: _showRequestPartSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Add Part',
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : null,
                  child: _loadingParts
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.navy),
                            ),
                          ),
                        )
                      : _parts.isEmpty
                          ? Text('No parts requested yet',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText))
                          : Column(
                              children: _parts.map((p) {
                                final partStatus =
                                    p['status'] as String? ?? 'REQUESTED';
                                final rejection =
                                    p['rejectionReason'] as String?;
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['partName'] as String? ?? '—',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                      color:
                                                          AppColors.bodyText),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${p['quantityRequested']} ${p['unit'] ?? ''}',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color:
                                                        AppColors.mutedText),
                                          ),
                                          const SizedBox(width: 8),
                                          _partStatusChip(partStatus),
                                        ],
                                      ),
                                      if (partStatus == 'REJECTED' &&
                                          rejection != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            rejection,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: AppColors.error),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                ),
                const SizedBox(height: 12),

                // ── Notes ────────────────────────────────────────────────
                if (notes != null)
                  _Section(
                    title: 'Notes',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notes,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ),
                  ),
                if (notes != null) const SizedBox(height: 12),

                const SizedBox(height: 80), // space for sticky button
              ],
            ),
          ),

          // ── Sticky action button ─────────────────────────────────────
          if (_status != 'COMPLETED')
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ],
              ),
              child: _status == 'OPEN'
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showStartConfirm,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: Text('Start Service',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCompleteSheet,
                        icon: const Icon(Icons.check_circle_outline,
                            size: 20),
                        label: Text('Complete Service',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
            )
          else
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Service Completed',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.success)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Timeline widget ────────────────────────────────────────────────────────────
class _TimelineEvent {
  final String label;
  final String? sub;
  final bool done;
  final bool active;
  const _TimelineEvent(
      {required this.label, this.sub, required this.done, this.active = false});
}

class _Timeline extends StatelessWidget {
  final List<_TimelineEvent> events;
  const _Timeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isLast = i == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // dot + line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: e.done && !e.active
                            ? AppColors.success
                            : e.active
                                ? const Color(0xFFF97316)
                                : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: e.done && !e.active
                          ? const Icon(Icons.check,
                              size: 11, color: AppColors.success)
                          : e.active
                              ? const Icon(Icons.access_time,
                                  size: 11, color: Color(0xFFF97316))
                              : null,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 36,
                      color: AppColors.border,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: e.done
                            ? AppColors.bodyText
                            : AppColors.mutedText,
                      ),
                    ),
                    if (e.sub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(e.sub!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section(
      {required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColoredSection extends StatelessWidget {
  final Color bg;
  final Color borderColor;
  final String title;
  final Color titleColor;
  final Widget child;
  const _ColoredSection({
    required this.bg,
    required this.borderColor,
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body.copyWith(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
