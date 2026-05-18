import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../../../../../core/utils/status_utils.dart';
import '../controllers/service_men_services_controller.dart';
import '../../service_men_breakdowns/controllers/service_men_breakdowns_controller.dart';
import 'service_men_service_detail_view.dart';

class ServiceMenServicesView extends StatefulWidget {
  const ServiceMenServicesView({super.key});

  @override
  State<ServiceMenServicesView> createState() => _ServiceMenServicesViewState();
}

class _ServiceMenServicesViewState extends State<ServiceMenServicesView> {
  String _subTab = 'services';

  @override
  Widget build(BuildContext context) {
    final svcCtrl = Get.find<ServiceMenServicesController>();
    final brkCtrl = Get.find<ServiceMenBreakdownsController>();

    return Obx(() {
      final openBreakdowns = brkCtrl.openCount;

      return Column(
        children: [
          // ── Sub-tab toggle ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _SubTabBtn(
                  label: 'lbl_services'.tr,
                  selected: _subTab == 'services',
                  onTap: () => setState(() => _subTab = 'services'),
                ),
                const SizedBox(width: 8),
                _SubTabBtn(
                  label: 'lbl_breakdowns'.tr,
                  badge: openBreakdowns,
                  selected: _subTab == 'breakdowns',
                  onTap: () => setState(() => _subTab = 'breakdowns'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Content ─────────────────────────────────────────────
          if (_subTab == 'services')
            Expanded(child: _ServicesBody(ctrl: svcCtrl))
          else
            Expanded(child: _BreakdownsBody(ctrl: brkCtrl)),
        ],
      );
    });
  }
}

// ── Sub-tab button ─────────────────────────────────────────────────────────────
class _SubTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _SubTabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.navy : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.bodyText,
                )),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Services body ──────────────────────────────────────────────────────────────
class _ServicesBody extends StatelessWidget {
  final ServiceMenServicesController ctrl;
  const _ServicesBody({required this.ctrl});

  static const _filters = ['ALL', 'OPEN', 'IN_PROGRESS', 'COMPLETED'];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = ctrl.filter.value == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ctrl.filter.value = f,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.navy
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel(f),
                            style: AppTextStyles.caption.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppColors.mutedText,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: ctrl.isLoading.value
                  ? const ShimmerList(count: 6)
                  : RefreshIndicator(
                      onRefresh: ctrl.fetchServices,
                      color: AppColors.navy,
                      child: ctrl.filteredServices.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(children: [
                                  const Icon(Icons.build_outlined,
                                      size: 48,
                                      color: AppColors.mutedText),
                                  const SizedBox(height: 12),
                                  Text('lbl_no_services_found'.tr,
                                      style: AppTextStyles.body.copyWith(
                                          color: AppColors.mutedText)),
                                ]),
                              ),
                            ])
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: ctrl.filteredServices.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final s = ctrl.filteredServices[i];
                                return _ServiceCard(
                                  service: s,
                                  onTap: () => Get.to(() =>
                                      ServiceMenServiceDetailView(
                                          service: s)),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ));
  }
}

// ── Breakdowns body ────────────────────────────────────────────────────────────
class _BreakdownsBody extends StatelessWidget {
  final ServiceMenBreakdownsController ctrl;
  const _BreakdownsBody({required this.ctrl});

  static const _filters = ['ALL', 'OPEN', 'IN_REPAIR', 'RESOLVED'];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Stack(
          children: [
            Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = ctrl.filter.value == f;
                        final count = f == 'ALL'
                            ? ctrl.breakdowns.length
                            : f == 'OPEN'
                                ? ctrl.openCount
                                : ctrl.breakdowns
                                    .where((b) => b['status'] == f)
                                    .length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => ctrl.filter.value = f,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.navy
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(statusLabel(f),
                                      style: AppTextStyles.caption.copyWith(
                                        color: active
                                            ? Colors.white
                                            : AppColors.mutedText,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      )),
                                  if (count > 0 &&
                                      (f == 'OPEN' || f == 'IN_REPAIR')) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                                .withValues(alpha: 0.25)
                                            : AppColors.error
                                                .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('$count',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                              color: active
                                                  ? Colors.white
                                                  : AppColors.error,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            )),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: ctrl.isLoading.value
                      ? const ShimmerList(count: 6)
                      : RefreshIndicator(
                          onRefresh: ctrl.fetchBreakdowns,
                          color: AppColors.navy,
                          child: ctrl.filtered.isEmpty
                              ? ListView(children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Column(children: [
                                      const Icon(
                                          Icons.warning_amber_outlined,
                                          size: 48,
                                          color: AppColors.mutedText),
                                      const SizedBox(height: 12),
                                      Text('lbl_no_breakdowns_found'.tr,
                                          style: AppTextStyles.body.copyWith(
                                              color: AppColors.mutedText)),
                                    ]),
                                  ),
                                ])
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: ctrl.filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final b = ctrl.filtered[i];
                                    return _BreakdownCard(
                                      breakdown: b,
                                      onLogService: () =>
                                          _showLogServiceSheet(context, b),
                                      onViewService: () =>
                                          _navigateToLinkedService(b),
                                      onResolve: () =>
                                          _showResolveConfirm(context, b),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'report_breakdown_fab',
                onPressed: () => _showReportBreakdownSheet(context),
                backgroundColor: AppColors.navy,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('btn_report'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ));
  }

  void _showReportBreakdownSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportBreakdownSheet(controller: ctrl),
    );
  }

  void _showResolveConfirm(BuildContext context, Map<String, dynamic> b) {
    final vehicleId   = b['vehicleId'] as int?;
    final breakdownId = b['id']        as int?;
    if (vehicleId == null || breakdownId == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${'btn_resolve_breakdown'.tr}?'),
        content: Text('lbl_resolve_breakdown_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('btn_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ctrl.resolveBreakdown(vehicleId, breakdownId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text('btn_resolve'.tr),
          ),
        ],
      ),
    );
  }

  void _showLogServiceSheet(BuildContext context, Map<String, dynamic> b) {
    final vehicleId   = b['vehicleId'] as int?;
    final breakdownId = b['id']        as int?;
    if (vehicleId == null || breakdownId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogServiceSheet(
        vehicleReg:  b['vehicleRegistrationNumber'] as String? ?? '',
        vehicleId:   vehicleId,
        breakdownId: breakdownId,
        controller:  ctrl,
      ),
    );
  }

  void _navigateToLinkedService(Map<String, dynamic> b) {
    final svcCtrl    = Get.find<ServiceMenServicesController>();
    final vehicleReg = b['vehicleRegistrationNumber'] as String?;
    final linked = svcCtrl.services.firstWhereOrNull(
      (s) =>
          s['triggeredBy'] == 'BREAKDOWN' &&
          s['vehicleRegistrationNumber'] == vehicleReg &&
          s['status'] != 'COMPLETED',
    );
    if (linked != null) {
      Get.to(() => ServiceMenServiceDetailView(service: linked));
    } else {
      svcCtrl.fetchServices().then((_) {
        final fresh = svcCtrl.services.firstWhereOrNull(
          (s) =>
              s['triggeredBy'] == 'BREAKDOWN' &&
              s['vehicleRegistrationNumber'] == vehicleReg &&
              s['status'] != 'COMPLETED',
        );
        if (fresh != null) {
          Get.to(() => ServiceMenServiceDetailView(service: fresh));
        }
      });
    }
  }
}

// ── Service Card ───────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status        = service['status']        as String? ?? 'OPEN';
    final displayStatus = service['displayStatus'] as String? ?? status;
    final statusColor   = _statusColor(displayStatus);
    final tasks =
        (service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final completedTasks =
        tasks.where((t) => t['status'] == 'COMPLETED').length;
    final triggeredBy = service['triggeredBy'] as String? ?? '';
    final isBreakdown = triggeredBy == 'BREAKDOWN';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isBreakdown
              ? Border.all(color: const Color(0xFFFECACA), width: 1.2)
              : null,
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service['vehicleRegistrationNumber'] ?? '—',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy),
                  ),
                ),
                if (isBreakdown)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('⚡ ${'lbl_trigger_breakdown'.tr}',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel(displayStatus),
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${service['serviceNumber'] ?? ''} · ${(service['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tasks.isEmpty ? 0 : completedTasks / tasks.length,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.success,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text('lbl_tasks_done'.trParams({'completed': '$completedTasks', 'total': '${tasks.length}'}),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'COMPLETED':   return AppColors.success;
      case 'IN_PROGRESS': return AppColors.warning;
      case 'OVERDUE':     return AppColors.error;
      case 'DUE_SOON':    return const Color(0xFFF97316);
      default:            return AppColors.info;
    }
  }
}

// ── Breakdown Card ─────────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  final VoidCallback onLogService;
  final VoidCallback onViewService;
  final VoidCallback onResolve;
  const _BreakdownCard({
    required this.breakdown,
    required this.onLogService,
    required this.onViewService,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final status     = breakdown['status']             as String? ?? 'REPORTED';
    final type       = breakdown['breakdownType']      as String? ?? '';
    final duration   = breakdown['breakdownDuration']  as String? ?? '';
    final reason     = breakdown['reason']             as String? ?? '—';
    final notes      = breakdown['notes']              as String?;
    final location   = breakdown['location']           as String?;
    final orderNo    = breakdown['orderNumber']        as String?;
    final vehicleReg = breakdown['vehicleRegistrationNumber'] as String? ?? '—';
    final dateRaw    = breakdown['breakdownDate']      as String?;

    final isOpen     = status != 'RESOLVED' && status != 'VEHICLE_REPLACED';
    final isInRepair = status == 'IN_REPAIR';
    final isResolved = status == 'RESOLVED' || status == 'VEHICLE_REPLACED';

    final statusColor = isInRepair
        ? const Color(0xFFC2410C)
        : isResolved ? AppColors.success : AppColors.error;
    final statusBg = isInRepair
        ? const Color(0xFFFFF7ED)
        : isResolved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusText = statusLabel(status);

    String? fmtDate;
    if (dateRaw != null) {
      try {
        fmtDate = DateFormat('dd MMM yyyy, h:mm a')
            .format(DateTime.parse(dateRaw).toLocal());
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOpen
            ? Border.all(
                color: isInRepair
                    ? const Color(0xFFFED7AA)
                    : const Color(0xFFFECACA),
                width: 1.2)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(vehicleReg,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusText,
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (type.isNotEmpty)
                _SmChip(
                    label: type.replaceAll('_', ' '),
                    bg: const Color(0xFFF1F5F9),
                    fg: AppColors.bodyText),
              _SmChip(
                  label: duration == 'SHORT' ? 'lbl_minor'.tr : 'lbl_major'.tr,
                  bg: duration == 'SHORT'
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  fg: duration == 'SHORT' ? AppColors.success : AppColors.error),
            ],
          ),
          const SizedBox(height: 10),
          Text(reason,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText)),
          if (notes != null) ...[
            const SizedBox(height: 4),
            Text(notes,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (fmtDate != null)
                _MetaItem(
                    icon: Icons.calendar_today_outlined, text: fmtDate),
              if (location != null)
                _MetaItem(icon: Icons.location_on_outlined, text: location),
              if (orderNo != null)
                _MetaItem(icon: Icons.assignment_outlined, text: orderNo),
            ],
          ),
          if (!isResolved) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (isInRepair)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewService,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text('btn_view_service'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF7ED),
                    foregroundColor: const Color(0xFFC2410C),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLogService,
                      icon: const Icon(Icons.build_outlined, size: 16),
                      label: Text('btn_log_service'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text('btn_resolve'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ── Report Breakdown Sheet ─────────────────────────────────────────────────────
class _ReportBreakdownSheet extends StatefulWidget {
  final ServiceMenBreakdownsController controller;
  const _ReportBreakdownSheet({required this.controller});

  @override
  State<_ReportBreakdownSheet> createState() =>
      _ReportBreakdownSheetState();
}

class _ReportBreakdownSheetState extends State<_ReportBreakdownSheet> {
  final _api = Get.find<ApiClient>();

  List<Map<String, dynamic>> _vehicles       = [];
  bool                       _loadingVehicles = true;
  Map<String, dynamic>?      _selectedVehicle;

  String _type     = 'MECHANICAL';
  String _duration = 'SHORT';
  final  _reasonCtrl   = TextEditingController();
  final  _locationCtrl = TextEditingController();
  final  _notesCtrl    = TextEditingController();
  bool   _submitting   = false;
  String? _error;

  static const _types = [
    ('MECHANICAL', 'Mechanical'),
    ('TYRE',       'Tyre'),
    ('ENGINE',     'Engine'),
    ('ELECTRICAL', 'Electrical'),
    ('ACCIDENT',   'Accident'),
    ('OTHER',      'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final res  = await _api.get(ApiEndpoints.vehicles);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _vehicles = list; _loadingVehicles = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedVehicle == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final ok = await widget.controller.reportBreakdown(
      vehicleId:         _selectedVehicle!['id'] as int,
      breakdownType:     _type,
      breakdownDuration: _duration,
      reason:            _reasonCtrl.text.trim(),
      location:          _locationCtrl.text.trim(),
      notes:             _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text('btn_report_breakdown'.tr,
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.navy)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('lbl_vehicle'.tr,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    _loadingVehicles
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.navy, strokeWidth: 2))
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedVehicle,
                            hint: Text('lbl_select_vehicle_hint'.tr,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText)),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.navy),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: _vehicles.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                    v['registrationNumber'] as String? ?? '—',
                                    style: AppTextStyles.body),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedVehicle = v),
                          ),
                    const SizedBox(height: 16),
                    Text('lbl_breakdown_type'.tr,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _types.map((t) {
                        final sel = _type == t.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _type = t.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.navy
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.navy
                                      : AppColors.border),
                            ),
                            child: Text(t.$2,
                                style: AppTextStyles.caption.copyWith(
                                  color: sel ? Colors.white : AppColors.bodyText,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('lbl_severity'.tr,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _DurChip(
                          label: 'lbl_minor_short'.tr,
                          selected: _duration == 'SHORT',
                          onTap: () => setState(() => _duration = 'SHORT'),
                        ),
                        const SizedBox(width: 8),
                        _DurChip(
                          label: 'lbl_major_long'.tr,
                          selected: _duration == 'LONG',
                          onTap: () => setState(() => _duration = 'LONG'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${'lbl_reason'.tr} *',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'lbl_describe_breakdown'.tr,
                        hintStyle: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.navy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('lbl_location_optional'.tr,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Workshop Bay 3',
                        hintStyle: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.navy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('lbl_notes_optional'.tr,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'lbl_additional_details'.tr,
                        hintStyle: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.navy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.warning_amber_rounded,
                                size: 20),
                        label: Text(
                          _submitting ? 'lbl_reporting'.tr : 'btn_report_breakdown'.tr,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log Service Sheet ──────────────────────────────────────────────────────────
class _LogServiceSheet extends StatefulWidget {
  final String vehicleReg;
  final int vehicleId;
  final int breakdownId;
  final ServiceMenBreakdownsController controller;

  const _LogServiceSheet({
    required this.vehicleReg,
    required this.vehicleId,
    required this.breakdownId,
    required this.controller,
  });

  @override
  State<_LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends State<_LogServiceSheet> {
  String _serviceType = 'INTERNAL';
  final _notesCtrl    = TextEditingController();
  bool _submitting    = false;

  static const _serviceTypes = [
    ('INTERNAL',    'Internal (Self)'),
    ('OEM_CENTER',  'OEM Center'),
    ('THIRD_PARTY', '3rd Party'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final newService = await widget.controller.createServiceFromBreakdown(
      vehicleId:   widget.vehicleId,
      breakdownId: widget.breakdownId,
      serviceType: _serviceType,
      serviceDate: today,
      notes:       _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (newService != null) {
      if (Get.isRegistered<ServiceMenServicesController>()) {
        Get.find<ServiceMenServicesController>().fetchServices();
      }
      Navigator.pop(context);
      Get.to(() => ServiceMenServiceDetailView(service: newService));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_outlined,
                  color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('btn_log_service'.tr,
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              '${'lbl_vehicle'.tr}: ${widget.vehicleReg} · ${'lbl_triggered_by_breakdown'.tr}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 20),
          Text('lbl_service_type'.tr,
              style:
                  AppTextStyles.label.copyWith(color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _serviceTypes.map((t) {
              final selected = _serviceType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _serviceType = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.navy
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppColors.navy
                            : AppColors.border),
                  ),
                  child: Text(t.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : AppColors.bodyText,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('lbl_notes_optional'.tr,
              style:
                  AppTextStyles.label.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'lbl_describe_repair'.tr,
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
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.build_circle_outlined, size: 20),
              label: Text(
                _submitting ? 'lbl_creating'.tr : 'btn_create_service_record'.tr,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────
class _SmChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SmChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: fg, fontWeight: FontWeight.w500)),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(text,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}

class _DurChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DurChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Center(
            child: Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? Colors.white : AppColors.bodyText,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        ),
      ),
    );
  }
}
