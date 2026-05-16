import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../controllers/service_men_services_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _service = Map<String, dynamic>.from(widget.service);
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
    if (updated != null && mounted) {
      setState(() => _service = updated);
    }
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
    final odoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete Service',
                style:
                    AppTextStyles.heading3.copyWith(color: AppColors.navy)),
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
                hintStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
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
                hintStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
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
                  Navigator.pop(context);
                  final today = DateTime.now()
                      .toIso8601String()
                      .substring(0, 10);
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
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white)),
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

    // Load spare parts
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
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Spare Part',
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 20),

                FerosSelectField<Map<String, dynamic>>(
                  label: 'Spare Part',
                  title: 'Select Spare Part',
                  hint: 'Search parts…',
                  isRequired: true,
                  selectedDisplay: selectedPart != null
                      ? selectedPart!['name'] as String
                      : null,
                  items: spareParts,
                  itemLabel: (p) => p['name'] as String? ?? '',
                  onSelected: (p) {
                    setSheetState(() => selectedPart = p);
                  },
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
                      await _ctrl.requestPart(
                        serviceId: _service['id'] as int,
                        sparePartId: selectedPart!['id'] as int,
                        quantity: qty,
                      );
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          _service['serviceNumber'] ?? 'Service Detail',
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vehicle Info ──────────────────────────────────
          _Section(
            title: 'Vehicle',
            child: Column(
              children: [
                _InfoRow('Registration',
                    _service['vehicleRegistrationNumber'] ?? '—'),
                _InfoRow('Service No', _service['serviceNumber'] ?? '—'),
                _InfoRow('Type',
                    (_service['serviceType'] ?? '').toString().replaceAll('_', ' ')),
                if (_service['vendorName'] != null)
                  _InfoRow('Vendor', _service['vendorName']),
                if (_service['location'] != null)
                  _InfoRow('Location', _service['location']),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tasks ─────────────────────────────────────────
          if (_tasks.isNotEmpty)
            _Section(
              title: 'Tasks',
              child: Column(
                children: _tasks.map((task) {
                  final done = task['status'] == 'COMPLETED';
                  return InkWell(
                    onTap: _status == 'COMPLETED' ? null : () => _toggleTask(task),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: done ? AppColors.success : AppColors.mutedText,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task['displayName'] ?? task['customName'] ?? '—',
                              style: AppTextStyles.body.copyWith(
                                color: done
                                    ? AppColors.mutedText
                                    : AppColors.bodyText,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (task['cost'] != null)
                            Text(
                              '₹${task['cost']}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),

          // ── Notes ─────────────────────────────────────────
          if (_service['notes'] != null)
            _Section(
              title: 'Notes',
              child: Text(
                _service['notes'],
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedText),
              ),
            ),
          const SizedBox(height: 12),

          // ── Request Part Button ───────────────────────────
          if (_status != 'COMPLETED')
            OutlinedButton.icon(
              onPressed: _showRequestPartSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Request Spare Part'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(height: 12),

          // ── Action Button ─────────────────────────────────
          if (_status == 'OPEN')
            SizedBox(
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else if (_status == 'IN_PROGRESS')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCompleteSheet,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text('Complete Service',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Container(
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

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
          Text(title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
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
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
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
