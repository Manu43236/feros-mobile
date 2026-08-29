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
    final id           = assignment['id'] as int;
    final serial       = assignment['serialNumber'] as String? ?? '—';
    final lastHmr      = assignment['lastLogEndHourMeter'];
    final operatorType = assignment['operatorType'] as String? ?? 'OWN_STAFF';
    final staffId      = assignment['operatorStaffId'] as int?;
    final hiredName    = assignment['hiredOperatorName'] as String?;

    final hmrCtrl = TextEditingController(
      text: lastHmr != null ? lastHmr.toString() : '',
    );

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
            operatorStaffId: operatorType == 'OWN_STAFF' ? staffId : null,
            hiredOperatorName: operatorType == 'HIRED' ? hiredName : null,
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
    final serial       = assignment['serialNumber']      as String? ?? '—';
    final typeName     = assignment['equipmentTypeName'] as String? ?? '—';
    final makeName     = assignment['makeName']          as String? ?? '';
    final modelName    = assignment['modelName']         as String? ?? '';
    final workStatus   = assignment['machineWorkStatus'] as String? ?? '';
    final divisionName = assignment['divisionName']      as String?;
    final operatorName = (assignment['operatorStaffName'] as String?)
        ?? (assignment['hiredOperatorName'] as String?);
    final lastHmr      = assignment['lastLogEndHourMeter'];
    final activeEntry  = assignment['activeWorkEntry'];
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
            // Session button
            Obx(() {
              final loading = controller.sessionLoading.value == assignmentId;
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
