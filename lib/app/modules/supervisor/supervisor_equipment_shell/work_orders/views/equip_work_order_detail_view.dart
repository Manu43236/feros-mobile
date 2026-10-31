import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/view_state.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../controllers/equip_work_order_detail_controller.dart';
import 'equip_wo_logs_tab.dart';

class EquipWorkOrderDetailView
    extends GetView<EquipWorkOrderDetailController> {
  const EquipWorkOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.equipSidebar,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Obx(() {
            final num = controller.wo.value?['woNumber'] as String?;
            return Text(
              num ?? 'Work Order',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            );
          }),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: controller.fetchDetail,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13),
            tabs: [
              Tab(text: 'Machines'),
              Tab(text: 'Daily Logs'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.state.value == ViewState.loading) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.equipSidebar),
            );
          }
          if (controller.state.value == ViewState.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load work order',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.equipSidebar,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final wo          = controller.wo.value!;
          final assignments = controller.assignments;

          return TabBarView(
            children: [
              // ── Machines tab ──
              RefreshIndicator(
                color: AppColors.equipSidebar,
                onRefresh: controller.fetchDetail,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _WoHeaderCard(wo: wo),
                    const SizedBox(height: 20),
                    _SectionTitle(
                        label: 'Machines (${assignments.length})'),
                    const SizedBox(height: 10),
                    if (assignments.isEmpty)
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No machines assigned yet',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.mutedText),
                          ),
                        ),
                      )
                    else
                      ...assignments.map((a) => _MachineCard(
                            assignment: a,
                            onStart: (ctx) => _showStartSheet(ctx, a),
                            onStop: (ctx) => _showStopSheet(ctx, a),
                          )),
                  ],
                ),
              ),
              // ── Daily Logs tab ──
              const EquipWoLogsTab(),
            ],
          );
        }),
      ),
    );
  }
  void _showStartSheet(BuildContext context, Map<String, dynamic> assignment) {
    final id        = assignment['id'] as int;
    final serial    = assignment['serialNumber'] as String? ?? '—';
    final lastHmr   = assignment['lastLogEndHourMeter'];
    final rawOpType = assignment['operatorType'] as String?;
    final staffId   = assignment['operatorStaffId'] as int?;
    final hiredName = assignment['hiredOperatorName'] as String?;

    // Standing own-staff operator.
    if (rawOpType == 'OWN_STAFF' && staffId != null) {
      _openHmrStart(context, id, serial, lastHmr,
          operatorType: 'OWN_STAFF', operatorStaffId: staffId);
      return;
    }
    // Standing client's operator (name optional).
    if (rawOpType == 'CLIENT_PROVIDED' || rawOpType == 'HIRED') {
      _openHmrStart(context, id, serial, lastHmr,
          operatorType: 'CLIENT_PROVIDED', hiredName: hiredName);
      return;
    }
    // Shift-duty WO: derive the operator from the shift covering now (own staff, else client's).
    final shiftDuty = assignment['shiftDuty'] as bool? ?? false;
    if (shiftDuty) {
      final shiftOp = controller.currentShiftOperator(id);
      if (shiftOp != null && shiftOp['operatorStaffId'] != null) {
        _openHmrStart(context, id, serial, lastHmr,
            operatorType: 'OWN_STAFF', operatorStaffId: shiftOp['operatorStaffId'] as int?);
      } else {
        // Client's own operator or no assignment — CLIENT_PROVIDED, no staff ID needed.
        _openHmrStart(context, id, serial, lastHmr, operatorType: 'CLIENT_PROVIDED');
      }
      return;
    }
    // No operator — the greyed Start button should prevent reaching here.
    FerosSnackbar.error('Assign an operator before starting the session.');
  }

  void _openHmrStart(BuildContext context, int id, String serial, dynamic lastHmr,
      {required String operatorType, int? operatorStaffId, String? hiredName}) {
    final hmrCtrl = TextEditingController(text: lastHmr != null ? lastHmr.toString() : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HmrBottomSheet(
        title: 'Start Session',
        machineLabel: serial,
        hmrCtrl: hmrCtrl,
        hmrLabel: 'Start Hour Meter (HMR)',
        actionLabel: 'Start',
        accentColor: AppColors.equipSidebar,
        onSubmit: () async {
          final meter = double.tryParse(hmrCtrl.text.trim());
          if (meter == null) {
            FerosSnackbar.error('Enter a valid HMR reading');
            return;
          }
          final ok = await controller.startSession(
            id,
            startMeter: meter,
            operatorType: operatorType,
            operatorStaffId: operatorType == 'OWN_STAFF' ? operatorStaffId : null,
            // Client's operator — name optional, no payroll.
            hiredOperatorName: operatorType != 'OWN_STAFF' ? hiredName : null,
          );
          if (ok && context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showStopSheet(BuildContext context, Map<String, dynamic> assignment) {
    final id      = assignment['id'] as int;
    final serial  = assignment['serialNumber'] as String? ?? '—';
    final active  = assignment['activeWorkEntry'] as Map<String, dynamic>?;
    final startM  = active?['startMeter'];

    final hmrCtrl   = TextEditingController(
      text: startM != null ? startM.toString() : '',
    );
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HmrBottomSheet(
        title: 'Stop Session',
        machineLabel: serial,
        hmrCtrl: hmrCtrl,
        hmrLabel: 'End Hour Meter (HMR)',
        actionLabel: 'Stop',
        accentColor: AppColors.error,
        notesCtrl: notesCtrl,
        onSubmit: () async {
          final meter = double.tryParse(hmrCtrl.text.trim());
          if (meter == null) {
            FerosSnackbar.error('Enter a valid HMR reading');
            return;
          }
          final ok = await controller.stopSession(
            id,
            endMeter: meter,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
          if (ok && context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── WO Header Card ────────────────────────────────────────────────────────────
class _WoHeaderCard extends StatelessWidget {
  final Map<String, dynamic> wo;
  const _WoHeaderCard({required this.wo});

  @override
  Widget build(BuildContext context) {
    final clientName = wo['clientName'] as String? ?? '—';
    final site       = wo['site']       as String? ?? '—';
    final status     = wo['status']     as String? ?? '';
    final woType     = wo['workOrderType'] as String? ?? '';
    final startDate  = wo['startDate']  as String?;
    final endDate    = wo['endDate']    as String?;
    final notes      = wo['notes']      as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clientName,
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: AppColors.bodyText),
                  ),
                ),
                _WoStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    site,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.business_center_outlined,
                  label: woType == 'RENTAL' ? 'Rental' : woType == 'JOB' ? 'Job Work' : woType,
                ),
                const SizedBox(width: 8),
                if (startDate != null)
                  _InfoChip(
                    icon: Icons.date_range_outlined,
                    label: '${FerosDateUtils.formatShortDate(startDate)} – ${FerosDateUtils.formatShortDate(endDate)}',
                  ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                notes,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Machine Card ──────────────────────────────────────────────────────────────
class _MachineCard extends GetView<EquipWorkOrderDetailController> {
  final Map<String, dynamic> assignment;
  final void Function(BuildContext) onStart;
  final void Function(BuildContext) onStop;
  const _MachineCard({
    required this.assignment,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final assignmentId = assignment['id'] as int;
    final serial       = assignment['registrationNumber'] as String?
        ?? assignment['serialNumber'] as String? ?? '—';
    final typeName     = assignment['equipmentTypeName'] as String? ?? '—';
    final makeName     = assignment['makeName']          as String? ?? '';
    final modelName    = assignment['modelName']         as String? ?? '';
    final workStatus   = assignment['machineWorkStatus'] as String? ?? '';
    final divisionName = assignment['divisionName']      as String?;
    final rawOpType    = assignment['operatorType'] as String?;
    final operatorName = (assignment['operatorStaffName'] as String?)
        ?? (assignment['hiredOperatorName'] as String?)
        ?? ((rawOpType == 'CLIENT_PROVIDED' || rawOpType == 'HIRED') ? "Client's operator" : null);
    final cleanerName = (assignment['cleanerStaffName'] as String?)
        ?? (assignment['clientCleanerName'] as String?);
    final lastHmr      = assignment['lastLogEndHourMeter'];
    final activeEntry  = assignment['activeWorkEntry'];
    final shiftDuty    = (controller.wo.value?['shiftDuty'] as bool?) ?? false;
    final shifts       = ((controller.wo.value?['shifts'] as List?) ?? []).cast<Map<String, dynamic>>();
    final isActive     = activeEntry != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.equipSidebar.withValues(alpha: 0.4))
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Serial + work status
            Row(
              children: [
                const Icon(Icons.construction,
                    size: 16, color: AppColors.equipSidebar),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    serial,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.equipSidebar,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _WorkStatusChip(status: workStatus),
              ],
            ),
            const SizedBox(height: 4),
            // Type + make/model
            Text(
              [typeName, if (makeName.isNotEmpty) '$makeName $modelName']
                  .join(' · '),
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 10),
            // Shift-duty WOs carry crew per shift (not on the assignment) — show that roster,
            // so the card matches the Manage Shifts sheet / web. Non-shift shows the standing crew.
            if (shiftDuty)
              _shiftCrewSummary(controller, assignmentId, shifts, divisionName)
            else ...[
              // Operator + division row
              Row(
                children: [
                  if (operatorName != null) ...[
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        operatorName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.bodyText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Text('No operator assigned',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.mutedText,
                          )),
                    ),
                  if (divisionName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        divisionName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.info, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
              if (cleanerName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.cleaning_services_outlined,
                        size: 13, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cleanerName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.bodyText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Shift-duty WOs assign crew per shift, not at machine level
                if (shiftDuty)
                  _crewLink('Manage Shifts', () =>
                      _showShiftAssignSheet(context, controller, assignmentId, shifts))
                else ...[
                  _crewLink(operatorName != null ? 'Change Operator' : 'Assign Operator', () =>
                      _showAssignOperatorSheet(context, controller, assignmentId,
                          showRemove: operatorName != null)),
                  _crewLink(cleanerName != null ? 'Change Cleaner' : 'Assign Cleaner', () =>
                      _showAssignCleanerSheet(context, controller, assignmentId,
                          showRemove: cleanerName != null)),
                ],
                _crewLink(divisionName != null ? 'Change Division' : 'Assign Division', () =>
                    _showDivisionPicker(context, controller, assignmentId)),
              ],
            ),
            if (lastHmr != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.speed_outlined,
                      size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    'Last HMR: $lastHmr hrs',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Session button — supervisor starts on behalf of the operator
            Obx(() {
              final loading = controller.sessionLoading.value == assignmentId;
              // A session can only start once an operator is assigned — standing operator,
              // or (shift-duty) the operator on the shift covering now.
              // Shift-duty: supervisor can always start — client's own or no operator assigned is fine.
              final hasOperator = operatorName != null || shiftDuty;
              // Not running and no operator → grey out Start and tell the supervisor to assign one.
              if (!isActive && !hasOperator) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.play_circle_outline,
                            size: 18, color: AppColors.mutedText),
                        label: Text(
                          'Start Session',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.mutedText.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Operator not assigned — assign an operator to start the session.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning, fontSize: 11),
                    ),
                  ],
                );
              }
              final btnColor =
                  isActive ? AppColors.error : AppColors.equipSidebar;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => isActive
                          ? onStop(context)
                          : onStart(context),
                  icon: loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: btnColor,
                          ),
                        )
                      : Icon(
                          isActive
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                          size: 18,
                          color: btnColor,
                        ),
                  label: Text(
                    isActive ? 'Stop Session' : 'Start Session',
                    style: AppTextStyles.caption.copyWith(
                      color: btnColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: btnColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Work Status Chip ──────────────────────────────────────────────────────────
class _WorkStatusChip extends StatelessWidget {
  final String status;
  const _WorkStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final label = _label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'AVAILABLE':  return AppColors.success;
      case 'ASSIGNED':   return AppColors.info;
      case 'BUSY':       return const Color(0xFFF97316);
      case 'BREAKDOWN':  return AppColors.error;
      case 'IN_REPAIR':  return AppColors.warning;
      default:           return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'AVAILABLE':  return 'Available';
      case 'ASSIGNED':   return 'Assigned';
      case 'BUSY':       return 'Busy';
      case 'BREAKDOWN':  return 'Breakdown';
      case 'IN_REPAIR':  return 'In Repair';
      default:           return s;
    }
  }
}

// ── WO Status Badge (reuse same colors as list) ───────────────────────────────
class _WoStatusBadge extends StatelessWidget {
  final String status;
  const _WoStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final label = _label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'DRAFT':       return const Color(0xFF94A3B8);
      case 'CONFIRMED':   return const Color(0xFF2563EB);
      case 'IN_PROGRESS': return const Color(0xFFF97316);
      case 'COMPLETED':   return const Color(0xFF16A34A);
      case 'INVOICED':    return const Color(0xFF7C3AED);
      case 'CANCELLED':   return const Color(0xFFDC2626);
      default:            return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'DRAFT':       return 'Draft';
      case 'CONFIRMED':   return 'Confirmed';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED':   return 'Completed';
      case 'INVOICED':    return 'Invoiced';
      case 'CANCELLED':   return 'Cancelled';
      default:            return s;
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.bodyText,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedText),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
          ),
        ],
      ),
    );
  }
}

// ── HMR Bottom Sheet (shared by start + stop) ─────────────────────────────────
class _HmrBottomSheet extends StatelessWidget {
  final String title;
  final String machineLabel;
  final TextEditingController hmrCtrl;
  final String hmrLabel;
  final String actionLabel;
  final Color accentColor;
  final TextEditingController? notesCtrl;
  final Future<void> Function() onSubmit;

  const _HmrBottomSheet({
    required this.title,
    required this.machineLabel,
    required this.hmrCtrl,
    required this.hmrLabel,
    required this.actionLabel,
    required this.accentColor,
    required this.onSubmit,
    this.notesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isSubmitting = false.obs;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Title + machine ──
            Text(title,
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.bodyText)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.construction,
                    size: 13, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(machineLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
            const SizedBox(height: 20),
            // ── HMR input ──
            Text(hmrLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.bodyText,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            TextField(
              controller: hmrCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 1248.5',
                hintStyle: AppTextStyles.body
                    .copyWith(color: AppColors.hintText),
                suffixText: 'hrs',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            // ── Notes (stop only) ──
            if (notesCtrl != null) ...[
              const SizedBox(height: 14),
              Text('Notes (optional)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any remarks for this session…',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.hintText),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // ── Submit button ──
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting.value
                        ? null
                        : () async {
                            isSubmitting.value = true;
                            await onSubmit();
                            isSubmitting.value = false;
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(actionLabel,
                            style: AppTextStyles.bodySemiBold
                                .copyWith(color: Colors.white)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// Chip-style button used inside the shift roster sheet (shows the picked name).
Widget _crewChip(String label, IconData icon, VoidCallback onTap, {bool active = false}) {
  return Expanded(
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : AppColors.equipSidebar,
        backgroundColor: active ? AppColors.equipSidebar : null,
        side: BorderSide(color: active ? AppColors.equipSidebar : const Color(0x33000000)),
        padding: const EdgeInsets.symmetric(vertical: 6),
        minimumSize: const Size(0, 34),
      ),
    ),
  );
}

// ── Crew assign link + picker (operator / cleaner / division) — lease pattern ───
Widget _crewLink(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.equipSidebar,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

void _showDivisionPicker(
  BuildContext context,
  EquipWorkOrderDetailController controller,
  int assignmentId,
) {
  final divisions = controller.divisions;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Division', style: AppTextStyles.heading4),
          const SizedBox(height: 10),
          ListTile(
            dense: true,
            leading: const Icon(Icons.close, size: 20),
            title: const Text('No division'),
            onTap: () async { Navigator.pop(ctx); await controller.assignDivision(assignmentId, null); },
          ),
          if (divisions.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No divisions for this client', style: TextStyle(color: AppColors.mutedText))))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: divisions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = divisions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city_outlined, size: 20),
                    title: Text(d['name'] as String? ?? '—'),
                    onTap: () async { Navigator.pop(ctx); await controller.assignDivision(assignmentId, d['id'] as int); },
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}

// Per-shift crew summary on a shift-duty machine card — reads today's roster reactively so
// the card shows who's on each shift (own staff or the client's own), matching web.
Widget _shiftCrewSummary(EquipWorkOrderDetailController controller, int assignmentId,
    List<Map<String, dynamic>> shifts, String? divisionName) {
  final today = DateTime.now().toIso8601String().split('T').first;
  Map<String, dynamic>? todayRowFor(int sid) {
    for (final r in controller.shiftToday) {
      if (r['assignmentId'] == assignmentId && r['shiftId'] == sid && r['workDate'] == today) return r;
    }
    return null;
  }
  String opLabel(Map<String, dynamic>? row) {
    if (row == null) return '—';
    if (row['operatorStaffId'] != null) return row['operatorName'] as String? ?? 'Operator';
    final n = row['clientOperatorName'] as String?;
    return (n != null && n.isNotEmpty) ? '$n (Client)' : "Client's operator";
  }
  String? clLabel(Map<String, dynamic>? row) {
    if (row == null) return null;
    if (row['cleanerStaffId'] != null) return row['cleanerName'] as String? ?? 'Cleaner';
    final n = row['clientCleanerName'] as String?;
    return (n != null && n.isNotEmpty) ? '$n (Client)' : null;
  }
  String crewLine(Map<String, dynamic>? row) {
    final cl = clLabel(row);
    return '${opLabel(row)}${cl != null ? ' · Cleaner $cl' : ''}';
  }
  return Obx(() {
    final cs = controller.currentShift(assignmentId);
    final csShift = cs?['shift'] as Map<String, dynamic>?;
    final csRow = cs?['row'] as Map<String, dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current shift running now (overnight shifts resolve to yesterday in the early morning).
        Row(children: [
          const Icon(Icons.schedule, size: 13, color: AppColors.equipSidebar),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              csShift == null
                  ? 'No active shift right now'
                  : 'Now · Shift ${csShift['shiftNumber']}: ${crewLine(csRow)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.bodyText, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (divisionName != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
              child: Text(divisionName,
                  style: AppTextStyles.caption.copyWith(color: AppColors.info, fontSize: 11)),
            ),
          ],
        ]),
        const SizedBox(height: 6),
        // Today's roster (all shifts) for context.
        ...shifts.map((sh) {
          final row = todayRowFor(sh['id'] as int);
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Shift ${sh['shiftNumber']}: ${crewLine(row)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
    );
  });
}

void _showShiftAssignSheet(
  BuildContext context,
  EquipWorkOrderDetailController controller,
  int assignmentId,
  List<Map<String, dynamic>> shifts,
) {
  final workDate = DateTime.now().toIso8601String().split('T').first;
  // shiftId -> {opId?, opName?, opClient(bool), opClientName?, clId?, clName?, clClient(bool), clClientName?}
  final sel = <int, Map<String, dynamic>>{};
  // Text controllers for optional client names — keyed by "$shiftId-op" / "$shiftId-cl"
  final nameCtrl = <String, TextEditingController>{};

  // Pre-fill from today's saved roster so current crew (incl. client names) shows — like web.
  // A saved row with no own-staff id = client's own (mirrors the web shift grid). The roster
  // holds yesterday+today, so match this sheet's workDate (today).
  for (final sh in shifts) {
    final sid = sh['id'] as int;
    Map<String, dynamic>? row;
    for (final r in controller.shiftToday) {
      if (r['assignmentId'] == assignmentId && r['shiftId'] == sid && r['workDate'] == workDate) { row = r; break; }
    }
    if (row == null) continue;
    final opStaffId = row['operatorStaffId'] as int?;
    final clStaffId = row['cleanerStaffId'] as int?;
    sel[sid] = {
      'opId': opStaffId, 'opName': row['operatorName'], 'opClient': opStaffId == null,
      'clId': clStaffId, 'clName': row['cleanerName'], 'clClient': clStaffId == null,
    };
    if (opStaffId == null) {
      nameCtrl['$sid-op'] = TextEditingController(text: row['clientOperatorName'] as String? ?? '');
    }
    if (clStaffId == null) {
      nameCtrl['$sid-cl'] = TextEditingController(text: row['clientCleanerName'] as String? ?? '');
    }
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shift Crew · $workDate', style: AppTextStyles.heading4),
            const SizedBox(height: 4),
            const Text('Assign operator & cleaner per shift for today.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
            const SizedBox(height: 10),
            if (shifts.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No shifts defined on this work order.',
                      style: TextStyle(color: AppColors.mutedText)))
            else
              ...shifts.map((sh) {
                final sid = sh['id'] as int;
                final s = sel[sid] ?? {};
                final opClient = s['opClient'] as bool? ?? false;
                final clClient = s['clClient'] as bool? ?? false;
                final opNameCtrl = nameCtrl.putIfAbsent('$sid-op', () => TextEditingController());
                final clNameCtrl = nameCtrl.putIfAbsent('$sid-cl', () => TextEditingController());
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Shift ${sh['shiftNumber']} · ${sh['startTime']}–${sh['endTime']}',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (controller.shiftToday.any((r) => r['assignmentId'] == assignmentId
                            && r['shiftId'] == sid && r['workDate'] == workDate))
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              await controller.clearShift(assignmentId, sid, workDate);
                            },
                            child: Text('Clear',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Operator row
                    Row(children: [
                      _crewChip(
                        opClient ? "Client's own" : (s['opName'] as String? ?? 'Operator'),
                        Icons.person_add_alt,
                        () => _showCrewPicker(ctx, controller, 'Select Operator', controller.operators,
                            (uid) async {
                          setSheet(() => sel[sid] = {...s, 'opId': uid, 'opClient': false,
                              'opName': controller.operators.firstWhere((u) => u['id'] == uid)['name']});
                          return true;
                        }),
                        active: s['opId'] != null,
                      ),
                      const SizedBox(width: 8),
                      _crewChip("Client's own", Icons.business_center, () {
                        setSheet(() {
                          sel[sid] = {...s, 'opId': null, 'opName': null, 'opClient': !opClient};
                          if (!opClient) opNameCtrl.clear();
                        });
                      }, active: opClient),
                    ]),
                    if (opClient) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: opNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Operator name (optional)',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Cleaner row
                    Row(children: [
                      _crewChip(
                        clClient ? "Client's own" : (s['clName'] as String? ?? 'Cleaner'),
                        Icons.cleaning_services,
                        () => _showCrewPicker(ctx, controller, 'Select Cleaner', controller.cleaners,
                            (uid) async {
                          setSheet(() => sel[sid] = {...s, 'clId': uid, 'clClient': false,
                              'clName': controller.cleaners.firstWhere((u) => u['id'] == uid)['name']});
                          return true;
                        }),
                        active: s['clId'] != null,
                      ),
                      const SizedBox(width: 8),
                      _crewChip("Client's own", Icons.business_center, () {
                        setSheet(() {
                          sel[sid] = {...s, 'clId': null, 'clName': null, 'clClient': !clClient};
                          if (!clClient) clNameCtrl.clear();
                        });
                      }, active: clClient),
                    ]),
                    if (clClient) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: clNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cleaner name (optional)',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: (s['opId'] == null && !opClient && s['clId'] == null && !clClient) ? null : () async {
                        Navigator.pop(ctx);
                        await controller.assignShift(assignmentId,
                            shiftId: sid, workDate: workDate,
                            operatorStaffId: s['opId'] as int?,
                            clientOperatorName: opClient ? opNameCtrl.text.trim() : null,
                            cleanerStaffId: s['clId'] as int?,
                            clientCleanerName: clClient ? clNameCtrl.text.trim() : null);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.equipSidebar, foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36)),
                      child: const Text('Assign this shift', style: TextStyle(fontSize: 13)),
                    )),
                  ]),
                );
              }),
          ],
        ),
      );
    }),
  );
}

// Operator assign chooser: our own staff, the client's own operator (name optional),
// or remove the operator entirely (when one is assigned).
void _showAssignOperatorSheet(
    BuildContext context, EquipWorkOrderDetailController controller, int assignmentId,
    {bool showRemove = false}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.badge_outlined, color: AppColors.equipSidebar),
            title: const Text('Own Staff'),
            subtitle: const Text('Assign one of our operators'),
            onTap: () {
              Navigator.pop(ctx);
              _showCrewPicker(context, controller, 'Select Operator', controller.operators,
                  (userId) => controller.assignOperator(assignmentId,
                      operatorType: 'OWN_STAFF', operatorStaffId: userId, swap: false));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_pin_outlined, color: AppColors.equipSidebar),
            title: const Text("Client's Operator"),
            subtitle: const Text('Client runs the machine (name optional)'),
            onTap: () {
              Navigator.pop(ctx);
              _showClientOperatorNameSheet(context, controller, assignmentId);
            },
          ),
          if (showRemove)
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: Text('Remove operator',
                  style: AppTextStyles.body.copyWith(color: AppColors.error)),
              subtitle: const Text('Leave the machine with no operator'),
              onTap: () {
                Navigator.pop(ctx);
                controller.removeOperator(assignmentId);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// Cleaner assign chooser: our own staff, or remove the cleaner entirely.
void _showAssignCleanerSheet(
    BuildContext context, EquipWorkOrderDetailController controller, int assignmentId,
    {bool showRemove = false}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.equipSidebar),
            title: const Text('Own Staff'),
            subtitle: const Text('Assign one of our cleaners'),
            onTap: () {
              Navigator.pop(ctx);
              _showCrewPicker(context, controller, 'Select Cleaner', controller.cleaners,
                  (userId) => controller.assignCleaner(assignmentId,
                      cleanerStaffId: userId, swap: false));
            },
          ),
          if (showRemove)
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: Text('Remove cleaner',
                  style: AppTextStyles.body.copyWith(color: AppColors.error)),
              subtitle: const Text('Leave the machine with no cleaner'),
              onTap: () {
                Navigator.pop(ctx);
                controller.removeCleaner(assignmentId);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _showClientOperatorNameSheet(
    BuildContext context, EquipWorkOrderDetailController controller, int assignmentId) {
  final nameCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Client's Operator", style: AppTextStyles.heading4),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Operator name (optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.equipSidebar,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final ok = await controller.assignOperator(assignmentId,
                    operatorType: 'CLIENT_PROVIDED',
                    hiredOperatorName: nameCtrl.text.trim(),
                    swap: false);
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Assign'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showCrewPicker(
  BuildContext context,
  EquipWorkOrderDetailController controller,
  String title,
  List<Map<String, dynamic>> staff,
  Future<bool> Function(int userId) onPick,
) {
  final search = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        final q = search.text.trim().toLowerCase();
        final list = q.isEmpty
            ? staff
            : staff.where((u) => (u['name'] as String? ?? '').toLowerCase().contains(q)).toList();
        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading4),
              const SizedBox(height: 10),
              TextField(
                controller: search,
                onChanged: (_) => setSheet(() {}),
                decoration: InputDecoration(
                  hintText: 'Search staff…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No staff found', style: TextStyle(color: AppColors.mutedText))),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline, size: 20),
                        title: Text(u['name'] as String? ?? '—'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await onPick(u['id'] as int);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      });
    },
  );
}
