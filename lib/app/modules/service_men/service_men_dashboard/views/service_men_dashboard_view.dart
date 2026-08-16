import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../controllers/service_men_dashboard_controller.dart';

// ── Date helpers ───────────────────────────────────────────────────────────────
String _fmtDate(dynamic d) {
  if (d == null) return '—';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
  } catch (_) {
    return d.toString();
  }
}

// ── Task status chip ───────────────────────────────────────────────────────────
Widget _taskChip(String status) {
  final cfg = <String, Map<String, dynamic>>{
    'PENDING':         {'label': 'Pending',   'color': const Color(0xFF6B7280)},
    'ASSIGNED':        {'label': 'Assigned',  'color': AppColors.info},
    'IN_PROGRESS':     {'label': 'Working',   'color': AppColors.warning},
    'MECHANIC_CLOSED': {'label': 'Closed',    'color': const Color(0xFF7C3AED)},
    'COMPLETED':       {'label': 'Done',      'color': AppColors.success},
  };
  final c = cfg[status] ?? {'label': status, 'color': AppColors.mutedText};
  final color = c['color'] as Color;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      c['label'] as String,
      style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w600, fontSize: 11),
    ),
  );
}

// ── Service status chip ────────────────────────────────────────────────────────
Widget _serviceChip(String status) {
  final color = status == 'COMPLETED'
      ? AppColors.success
      : status == 'IN_PROGRESS'
          ? AppColors.warning
          : AppColors.info;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: AppTextStyles.caption
          .copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
    );

// ── Main View ─────────────────────────────────────────────────────────────────
class ServiceMenDashboardView extends GetView<ServiceMenDashboardController> {
  const ServiceMenDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ShimmerList(count: 5);
      }
      return RefreshIndicator(
        onRefresh: controller.fetchAll,
        color: AppColors.navy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Stats Row ────────────────────────────────────
            Row(children: [
              _StatCard(
                label: 'Breakdowns',
                value: controller.breakdownCount,
                icon: Icons.warning_amber_outlined,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Services',
                value: controller.serviceCount,
                icon: Icons.build_outlined,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Technicians',
                value: controller.technicianCount,
                icon: Icons.person_outline,
                color: AppColors.success,
              ),
            ]),

            const SizedBox(height: 24),

            // ── Breakdowns Section ───────────────────────────
            if (controller.breakdowns.isNotEmpty) ...[
              _SectionHeader(
                title: 'Breakdowns',
                icon: Icons.warning_amber_outlined,
                color: AppColors.error,
              ),
              const SizedBox(height: 10),
              ...controller.breakdowns.map((bd) => _BreakdownCard(
                    breakdown: bd,
                    controller: controller,
                  )),
              const SizedBox(height: 20),
            ],

            // ── General Services Section ─────────────────────
            if (controller.generalServices.isNotEmpty) ...[
              _SectionHeader(
                title: 'General Services',
                icon: Icons.build_outlined,
                color: AppColors.info,
              ),
              const SizedBox(height: 10),
              ...controller.generalServices.map((svc) => _ServiceCard(
                    service: svc,
                    controller: controller,
                  )),
            ],

            if (controller.breakdowns.isEmpty &&
                controller.generalServices.isEmpty)
              _EmptyState(),
          ],
        ),
      );
    });
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text('$value',
                style: AppTextStyles.heading2.copyWith(color: AppColors.navy)),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(title,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ── Breakdown Card ─────────────────────────────────────────────────────────────
class _BreakdownCard extends StatefulWidget {
  final Map<String, dynamic> breakdown;
  final ServiceMenDashboardController controller;
  const _BreakdownCard({required this.breakdown, required this.controller});

  @override
  State<_BreakdownCard> createState() => _BreakdownCardState();
}

class _BreakdownCardState extends State<_BreakdownCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final bd = widget.breakdown;
    final service = bd['service'] as Map<String, dynamic>?;

    final bdStatusColor = <String, Color>{
      'REPORTED':         AppColors.error,
      'IN_REPAIR':        AppColors.warning,
      'RESOLVED':         AppColors.success,
      'VEHICLE_REPLACED': AppColors.mutedText,
    }[bd['status'] as String? ?? ''] ?? AppColors.mutedText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_outlined,
                        color: AppColors.error, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bd['vehicleRegistrationNumber'] ?? '—',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.navy),
                        ),
                        Text(
                          '${(bd['breakdownType'] ?? '').toString().replaceAll('_', ' ')} · ${_fmtDate(bd['breakdownDate'])}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
                        if (bd['location'] != null)
                          Text(
                            '@ ${bd['location']}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bdStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (bd['status'] ?? '').toString().replaceAll('_', ' '),
                      style: AppTextStyles.caption.copyWith(
                          color: bdStatusColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.mutedText,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            service != null
                ? _LinkedService(
                    service: service, controller: widget.controller)
                : const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      'No service linked yet',
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12),
                    ),
                  ),
        ],
      ),
    );
  }
}

// ── Linked Service (inside breakdown card) ─────────────────────────────────────
class _LinkedService extends StatelessWidget {
  final Map<String, dynamic> service;
  final ServiceMenDashboardController controller;
  const _LinkedService({required this.service, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.build_outlined,
                size: 14, color: AppColors.navy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${service['serviceNumber'] ?? ''} · ${(service['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.navy, fontSize: 13),
              ),
            ),
            _serviceChip(service['serviceStatus'] ?? 'OPEN'),
          ]),
          const SizedBox(height: 8),
          _TaskList(service: service, controller: controller),
          if ((service['serviceStatus'] ?? '') != 'COMPLETED')
            _CompleteButton(service: service, controller: controller),
        ],
      ),
    );
  }
}

// ── Service Card (standalone general service) ──────────────────────────────────
class _ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final ServiceMenDashboardController controller;
  const _ServiceCard({required this.service, required this.controller});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_outlined,
                      color: AppColors.navy, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        svc['vehicleRegistrationNumber'] ?? '—',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.navy),
                      ),
                      Text(
                        '${svc['serviceNumber'] ?? ''} · ${(svc['serviceType'] ?? '').toString().replaceAll('_', ' ')}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                _serviceChip(svc['serviceStatus'] ?? 'OPEN'),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.mutedText,
                  size: 18,
                ),
              ]),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  _TaskList(service: svc, controller: widget.controller),
                  if ((svc['serviceStatus'] ?? '') != 'COMPLETED')
                    _CompleteButton(
                        service: svc, controller: widget.controller),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Task List ──────────────────────────────────────────────────────────────────
class _TaskList extends StatelessWidget {
  final Map<String, dynamic> service;
  final ServiceMenDashboardController controller;
  const _TaskList({required this.service, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksOf(service);
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('No tasks',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedText)),
      );
    }
    return Column(
      children: tasks
          .map((task) => _TaskRow(
                task: task,
                serviceId: service['serviceId'] as int,
                controller: controller,
              ))
          .toList(),
    );
  }
}

// ── Task Row ───────────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final Map<String, dynamic> task;
  final int serviceId;
  final ServiceMenDashboardController controller;
  const _TaskRow(
      {required this.task,
      required this.serviceId,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] as String? ?? 'PENDING';
    final mechanic = task['assignedMechanicName'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['displayName'] ?? '—',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                ),
                if (mechanic != null)
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 11, color: AppColors.mutedText),
                    const SizedBox(width: 2),
                    Text(mechanic,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ]),
              ],
            ),
          ),
          _taskChip(status),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAssignSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                mechanic != null ? 'Reassign' : 'Assign',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.navy, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    if (controller.technicians.isEmpty) {
      FerosSnackbar.error('No technicians available');
      return;
    }
    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AssignTechnicianSheet(
        task: task,
        serviceId: serviceId,
        technicians: controller.technicians,
        controller: controller,
      ),
    );
  }
}

// ── Assign Technician Bottom Sheet ────────────────────────────────────────────
class _AssignTechnicianSheet extends StatefulWidget {
  final Map<String, dynamic> task;
  final int serviceId;
  final List<Map<String, dynamic>> technicians;
  final ServiceMenDashboardController controller;
  const _AssignTechnicianSheet(
      {required this.task,
      required this.serviceId,
      required this.technicians,
      required this.controller});

  @override
  State<_AssignTechnicianSheet> createState() => _AssignTechnicianSheetState();
}

class _AssignTechnicianSheetState extends State<_AssignTechnicianSheet> {
  int? _selectedId;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.task['assignedMechanicId'] as int?;
    _filtered = widget.technicians;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.technicians.where((m) {
        final name = (m['name'] as String? ?? '').toLowerCase();
        final desig = (m['designation'] as String? ?? '').toLowerCase();
        return name.contains(q) || desig.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Assign Technician',
              style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(
            'Task: ${widget.task['displayName'] ?? ''}',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or designation…',
              hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No results',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ),
                  )
                : ListView.separated(
              shrinkWrap: true,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = _filtered[i];
                final id = m['id'] as int;
                final isSelected = id == _selectedId;
                final designation = m['designation'] as String?;
                return GestureDetector(
                  onTap: () => setState(() => _selectedId = id),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.navy.withValues(alpha: 0.06)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navy
                            : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.navy.withValues(alpha: 0.1),
                        child: Text(
                          (m['name'] as String? ?? '?')[0].toUpperCase(),
                          style: AppTextStyles.bodySemiBold
                              .copyWith(color: AppColors.navy, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'] ?? '—',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontSize: 14)),
                            if (designation != null && designation.isNotEmpty)
                              Text(
                                designation,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.navy, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.controller.isAssigning.value ||
                          _selectedId == null
                      ? null
                      : () async {
                          final ok =
                              await widget.controller.assignTechnician(
                            serviceId: widget.serviceId,
                            taskId: widget.task['taskId'] as int,
                            technicianId: _selectedId!,
                          );
                          if (ok && context.mounted) Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: widget.controller.isAssigning.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Assign',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Complete Service Button ────────────────────────────────────────────────────
class _CompleteButton extends StatelessWidget {
  final Map<String, dynamic> service;
  final ServiceMenDashboardController controller;
  const _CompleteButton({required this.service, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksOf(service);
    final allClosed = tasks.isNotEmpty &&
        tasks.every((t) =>
            t['status'] == 'MECHANIC_CLOSED' || t['status'] == 'COMPLETED');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Mark Complete'),
          onPressed: () => _showCompleteSheet(context),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                allClosed ? AppColors.success : AppColors.navy,
            side: BorderSide(
                color: allClosed
                    ? AppColors.success
                    : AppColors.navy.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  void _showCompleteSheet(BuildContext context) {
    final dateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);
    final odoCtrl = TextEditingController();

    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Mark Service Complete',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.navy)),
            const SizedBox(height: 16),
            const Text('Completed Date',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: dateCtrl,
              decoration: _inputDec('YYYY-MM-DD'),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            const Text('Odometer (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: odoCtrl,
              decoration: _inputDec('km'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await controller.completeService(
                    serviceId: service['serviceId'] as int,
                    completedDate: dateCtrl.text.trim(),
                    odometer: odoCtrl.text.isNotEmpty
                        ? int.tryParse(odoCtrl.text)
                        : null,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Complete',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                size: 52, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              'No active breakdowns or services',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
