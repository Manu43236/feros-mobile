import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../controllers/service_men_services_controller.dart';
import 'service_men_bill_preview_view.dart';

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
  final labels = {
    'OPEN':        'status_open'.tr,
    'IN_PROGRESS': 'status_in_progress'.tr,
    'COMPLETED':   'status_completed'.tr,
    'OVERDUE':     'status_overdue'.tr,
  };
  final colors = {
    'OPEN':        (_chipBg(0xFFEFF6FF), _chipFg(0xFF1D4ED8)),
    'IN_PROGRESS': (_chipBg(0xFFFFF7ED), _chipFg(0xFFC2410C)),
    'COMPLETED':   (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D)),
    'OVERDUE':     (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C)),
  };
  final label = labels[status];
  final color = colors[status];
  if (label == null || color == null) return const SizedBox.shrink();
  return _Chip(label: label, bg: color.$1, fg: color.$2);
}

Widget _triggeredChip(String t) {
  final labels = {
    'SCHEDULED':  'lbl_trigger_scheduled'.tr,
    'BREAKDOWN':  'lbl_trigger_breakdown'.tr,
    'ACCIDENT':   'lbl_trigger_accident'.tr,
    'COMPLIANCE': 'lbl_trigger_compliance'.tr,
    'WARRANTY':   'lbl_trigger_warranty'.tr,
  };
  final colors = {
    'SCHEDULED':  (_chipBg(0xFFF5F3FF), _chipFg(0xFF6D28D9)),
    'BREAKDOWN':  (_chipBg(0xFFFFF7ED), _chipFg(0xFFC2410C)),
    'ACCIDENT':   (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C)),
    'COMPLIANCE': (_chipBg(0xFFEFF6FF), _chipFg(0xFF1D4ED8)),
    'WARRANTY':   (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D)),
  };
  final label = labels[t];
  final color = colors[t];
  if (label == null || color == null) return const SizedBox.shrink();
  return _Chip(label: label, bg: color.$1, fg: color.$2);
}

Widget _partStatusChip(String s) {
  final labels = {
    'REQUESTED': 'status_requested'.tr,
    'APPROVED':  'status_approved'.tr,
    'REJECTED':  'status_rejected'.tr,
  };
  final colors = {
    'REQUESTED': (_chipBg(0xFFFFFBEB), _chipFg(0xFFB45309)),
    'APPROVED':  (_chipBg(0xFFF0FDF4), _chipFg(0xFF15803D)),
    'REJECTED':  (_chipBg(0xFFFEF2F2), _chipFg(0xFFB91C1C)),
  };
  final label = labels[s];
  final color = colors[s];
  if (label == null || color == null) return const SizedBox.shrink();
  return _Chip(label: label, bg: color.$1, fg: color.$2);
}

Color _chipBg(int hex) => Color(hex);
Color _chipFg(int hex) => Color(hex);

String _payerLabel(String p) {
  switch (p) {
    case 'WARRANTY_OEM': return 'lbl_payer_oem_warranty'.tr;
    case 'WARRANTY_ANC': return 'lbl_payer_anc_warranty'.tr;
    case 'INSURANCE':    return 'lbl_payer_insurance'.tr;
    case 'AMC':          return 'lbl_payer_amc'.tr;
    default:             return p;
  }
}

String _serviceTypeLabel(String t, String? vendor) {
  if (t == 'INTERNAL')   return 'lbl_service_internal'.tr;
  if (t == 'OEM_CENTER') return 'lbl_service_oem'.trParams({'vendor': vendor ?? 'Service Center'});
  return vendor ?? 'lbl_service_third_party'.tr;
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
  List<Map<String, dynamic>> _vendorItems = [];
  Map<String, dynamic>? _invoice;

  @override
  void initState() {
    super.initState();
    _service = Map<String, dynamic>.from(widget.service);
    _vendorItems = (_service['vendorItems'] as List?)
            ?.cast<Map<String, dynamic>>() ?? [];
    _loadParts();
    if (_status == 'COMPLETED') _loadInvoice();
  }

  Future<void> _loadParts() async {
    final parts = await _ctrl.fetchServiceParts(_service['id'] as int);
    if (mounted) setState(() { _parts = parts; _loadingParts = false; });
  }

  Future<void> _loadInvoice() async {
    final inv = await _ctrl.fetchInvoice(_service['id'] as int);
    if (mounted) setState(() => _invoice = inv);
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
        title: Text('btn_start_service'.tr,
            style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
        content: Text(
          'lbl_start_service_confirm'.trParams({'num': _service['serviceNumber'] as String? ?? ''}),
          style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('btn_cancel'.tr,
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
            child: Text('btn_start'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBillPreview() async {
    final result = await Get.to(
        () => ServiceMenBillPreviewView(service: _service));
    if (result != null && result is Map<String, dynamic> && mounted) {
      setState(() => _service = result);
      _loadInvoice(); // fetch the newly created invoice
    }
  }

  Future<void> _viewPdf(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'] as int?;
    if (invoiceId == null) return;
    final bytes = await _ctrl.downloadInvoicePdf(invoiceId);
    if (bytes == null || !mounted) return;
    try {
      final dir  = await getTemporaryDirectory();
      final name = invoice['invoiceNumber'] as String? ?? 'invoice';
      final file = File('${dir.path}/$name.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {
          'file':     file,
          'title':    name,
          'subtitle': invoice['vehicleRegistrationNumber'] as String?,
        },
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('Could not open PDF');
    }
  }

  void _showAddTaskSheet() {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    Map<String, dynamic>? selectedType;
    List<Map<String, dynamic>> taskTypes = [];
    bool loadingTypes = true;
    bool fetchStarted = false;

    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Trigger fetch once on first build
          if (!fetchStarted) {
            fetchStarted = true;
            Get.find<ApiClient>().get(ApiEndpoints.serviceTaskTypes).then((res) {
              final list = ((res.data as Map<String, dynamic>)['data'] as List)
                  .cast<Map<String, dynamic>>();
              setSheetState(() {
                taskTypes = list;
                loadingTypes = false;
              });
            }).catchError((_) {
              setSheetState(() => loadingTypes = false);
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('btn_add_task'.tr,
                    style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                const SizedBox(height: 20),
                FerosSelectField<Map<String, dynamic>>(
                  label: 'lbl_task_type_optional'.tr,
                  title: 'lbl_select_task_type'.tr,
                  hint: 'lbl_search_task_types'.tr,
                  selectedDisplay:
                      selectedType != null ? selectedType!['name'] as String : null,
                  items: taskTypes,
                  itemLabel: (t) => t['name'] as String? ?? '',
                  onSelected: (t) => setSheetState(() {
                    selectedType = t;
                    nameCtrl.clear();
                  }),
                  isLoading: loadingTypes,
                  emptyMessage: 'lbl_no_task_types_found'.tr,
                ),
                if (selectedType == null) ...[
                  const SizedBox(height: 16),
                  Text('lbl_custom_name'.tr,
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
                Text('lbl_cost_optional'.tr,
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
                      final serviceId = _service['id'] as int;
                      Navigator.pop(context);
                      await _ctrl.addTask(
                        serviceId,
                        taskTypeId: selectedType?['id'] as int?,
                        customName: selectedType == null ? name : null,
                        cost: cost,
                      );
                      // Re-fetch to guarantee UI shows latest tasks
                      final refreshed = await _ctrl.fetchServiceById(serviceId);
                      if (refreshed != null && mounted) {
                        setState(() => _service = refreshed);
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
                    child: Text('btn_add_task'.tr,
                        style:
                            AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddVendorItemSheet() {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showModalBottomSheet(
      useSafeArea: true,
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
            Text('btn_add_part'.tr,
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 20),
            Text('lbl_part_name'.tr,
                style: AppTextStyles.label.copyWith(color: AppColors.navy)),
            const SizedBox(height: 6),
            TextField(
              controller: descCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Brake pad, Engine oil',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('lbl_cost_optional'.tr,
                style: AppTextStyles.label.copyWith(color: AppColors.navy)),
            const SizedBox(height: 6),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 500',
                prefixText: '₹ ',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  final desc = descCtrl.text.trim();
                  if (desc.isEmpty) {
                    FerosSnackbar.error('Enter a part name');
                    return;
                  }
                  final cost = double.tryParse(costCtrl.text.trim());
                  Navigator.pop(context);
                  final added = await _ctrl.addVendorItem(
                    _service['id'] as int,
                    description: desc,
                    cost: cost,
                  );
                  if (added != null && mounted) {
                    setState(() => _vendorItems.add(added));
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
                child: Text('btn_add_part'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
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
        useSafeArea: true,
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
              Text('lbl_request_spare_part'.tr,
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 20),
              FerosSelectField<Map<String, dynamic>>(
                label: 'lbl_spare_part'.tr,
                title: 'lbl_select_spare_part'.tr,
                hint: 'lbl_search_parts'.tr,
                isRequired: true,
                selectedDisplay:
                    selectedPart != null ? selectedPart!['name'] as String : null,
                items: spareParts,
                itemLabel: (p) => p['name'] as String? ?? '',
                onSelected: (p) => setSheetState(() => selectedPart = p),
                isLoading: isLoadingParts,
                emptyMessage: 'lbl_no_spare_parts_found'.tr,
              ),
              const SizedBox(height: 16),
              Text('lbl_quantity'.tr,
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
                  child: Text('btn_submit_request'.tr,
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
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
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
                        label: 'lbl_escalated'.tr,
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
                  title: 'lbl_service_info'.tr,
                  child: Column(
                    children: [
                      _InfoRow('lbl_vehicle'.tr,
                          _service['vehicleRegistrationNumber'] ?? '—'),
                      _InfoRow('lbl_service_no'.tr, _service['serviceNumber'] ?? '—'),
                      _InfoRow('lbl_type'.tr,
                          _serviceTypeLabel(serviceType, vendorName)),
                      if (serviceDate != null)
                        _InfoRow('lbl_service_date'.tr, serviceDate),
                      if (odometer != null)
                        _InfoRow('lbl_odometer'.tr,
                            '${(odometer as num).toStringAsFixed(0)} km'),
                      if (dueAtOdo != null)
                        _InfoRow('lbl_due_at'.tr,
                            '${(dueAtOdo as num).toStringAsFixed(0)} km'),
                      if (location != null) _InfoRow('lbl_location'.tr, location),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Insurance Details ─────────────────────────────────────
                if (isInsurance && (claimNo != null || claimAmt != null))
                  _ColoredSection(
                    bg: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFBFDBFE),
                    title: 'lbl_insurance_claim'.tr,
                    titleColor: const Color(0xFF1D4ED8),
                    child: Column(
                      children: [
                        if (claimNo != null)
                          _InfoRow('lbl_claim_no'.tr, claimNo),
                        if (claimAmt != null)
                          _InfoRow('lbl_claim_amount'.tr,
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
                    title: 'lbl_compliance_cert'.tr,
                    titleColor: const Color(0xFF6D28D9),
                    child: Column(
                      children: [
                        if (certNo != null)
                          _InfoRow('lbl_cert_no'.tr, certNo),
                        if (certValidUntil != null)
                          _InfoRow('lbl_valid_until'.tr, certValidUntil),
                      ],
                    ),
                  ),
                if (isCompliance && (certNo != null || certValidUntil != null))
                  const SizedBox(height: 12),

                // ── Timeline ─────────────────────────────────────────────
                _Section(
                  title: 'lbl_timeline'.tr,
                  child: _Timeline(events: [
                    _TimelineEvent(
                      label: 'lbl_service_created'.tr,
                      sub: createdAt,
                      done: true,
                    ),
                    _TimelineEvent(
                      label: 'lbl_work_started'.tr,
                      sub: startedAt,
                      done: _status == 'IN_PROGRESS' ||
                          _status == 'COMPLETED',
                      active: _status == 'IN_PROGRESS',
                    ),
                    _TimelineEvent(
                      label: 'status_completed'.tr,
                      sub: completedAt,
                      done: _status == 'COMPLETED',
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Tasks ────────────────────────────────────────────────
                _Section(
                  title: 'lbl_tasks'.tr,
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
                                Text('btn_add_task'.tr,
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : null,
                  child: _tasks.isEmpty
                      ? Text('lbl_no_tasks_yet'.tr,
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
                                                'lbl_every_km'.trParams({'km': freqKm.toString()}),
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
                                    Text('lbl_total_cost'.tr,
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

                // ── Vendor Items (3rd Party / OEM only) ──────────────────
                if (serviceType == 'THIRD_PARTY' || serviceType == 'OEM_CENTER') ...[
                  _Section(
                    title: 'lbl_parts_items_vendor'.tr,
                    trailing: _status != 'COMPLETED'
                        ? GestureDetector(
                            onTap: _showAddVendorItemSheet,
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
                                  Text('btn_add_part'.tr,
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        : null,
                    child: _vendorItems.isEmpty
                        ? Text('lbl_no_vendor_items_yet'.tr,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText))
                        : Column(
                            children: _vendorItems.map((item) {
                              final cost = (item['cost'] as num?)?.toDouble();
                              final itemId = item['id'] as int;
                              return Dismissible(
                                key: Key('vendor-$itemId'),
                                direction: _status == 'COMPLETED'
                                    ? DismissDirection.none
                                    : DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      color: AppColors.error, size: 20),
                                ),
                                confirmDismiss: (_) async {
                                  final ok = await _ctrl.deleteVendorItem(
                                      _service['id'] as int, itemId);
                                  return ok;
                                },
                                onDismissed: (_) {
                                  setState(() => _vendorItems
                                      .removeWhere((v) => v['id'] == itemId));
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['description'] as String? ?? '—',
                                          style: AppTextStyles.body.copyWith(
                                              color: AppColors.bodyText),
                                        ),
                                      ),
                                      if (cost != null)
                                        Text(
                                          '₹${cost.toStringAsFixed(0)}',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                  color: AppColors.navy,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Parts Used ───────────────────────────────────────────
                _Section(
                  title: 'lbl_parts_used'.tr,
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
                                Text('btn_add_part'.tr,
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
                          ? Text('lbl_no_parts_yet'.tr,
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
                    title: 'lbl_notes'.tr,
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

                // ── Invoice ──────────────────────────────────────────────
                if (_status == 'COMPLETED') ...[
                  _Section(
                    title: 'lbl_service_invoice'.tr,
                    child: _invoice == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.navy),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              _InfoRow('lbl_invoice_no'.tr,
                                  _invoice!['invoiceNumber'] as String? ?? '—'),
                              _InfoRow(
                                'lbl_type'.tr,
                                (_invoice!['invoiceType'] as String?) == 'INTERNAL'
                                    ? 'lbl_internal_invoice'.tr
                                    : 'lbl_external_vendor'.tr,
                              ),
                              if (_invoice!['totalAmount'] != null)
                                _InfoRow(
                                  'lbl_total_amount'.tr,
                                  '₹${(_invoice!['totalAmount'] as num).toStringAsFixed(2)}',
                                ),
                              if (_invoice!['vendorAmount'] != null &&
                                  _invoice!['invoiceType'] == 'EXTERNAL')
                                _InfoRow(
                                  'lbl_vendor_amount'.tr,
                                  '₹${(_invoice!['vendorAmount'] as num).toStringAsFixed(2)}',
                                ),
                              if (_invoice!['gstAmount'] != null &&
                                  _invoice!['invoiceType'] == 'INTERNAL')
                                _InfoRow(
                                  'lbl_gst'.tr,
                                  '₹${(_invoice!['gstAmount'] as num).toStringAsFixed(2)}',
                                ),
                              _InfoRow(
                                'lbl_payment'.tr,
                                (_invoice!['paymentStatus'] as String?) == 'PAID'
                                    ? 'lbl_paid'.tr
                                    : 'lbl_pending_payment'.tr,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _viewPdf(_invoice!),
                                  icon: const Icon(Icons.picture_as_pdf,
                                      size: 18),
                                  label: Text('btn_view_share_pdf'.tr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    side: const BorderSide(
                                        color: AppColors.navy),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                ],

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
              // OPEN + INTERNAL → Start Service
              // OPEN + OEM/3rd Party → skip start, go straight to Complete
              // IN_PROGRESS → Complete Service
              child: _status == 'OPEN' && serviceType == 'INTERNAL'
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showStartConfirm,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: Text('btn_start_service'.tr,
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
                        onPressed: _openBillPreview,
                        icon: const Icon(Icons.check_circle_outline,
                            size: 20),
                        label: Text('btn_complete_service'.tr,
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
                    Text('lbl_service_completed_banner'.tr,
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
