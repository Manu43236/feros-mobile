import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../controllers/equip_work_order_detail_controller.dart';

class EquipWoLogsTab extends GetView<EquipWorkOrderDetailController> {
  const EquipWoLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.equipSidebar,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Log',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        onPressed: () => _showAddLogSheet(context),
      ),
      body: Obx(() {
        final list = controller.logs;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 52, color: AppColors.mutedText),
                const SizedBox(height: 16),
                Text('No daily logs yet',
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.equipSidebar)),
                const SizedBox(height: 6),
                Text('Tap + to add today\'s log',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _LogCard(log: list[i]),
        );
      }),
    );
  }

  void _showAddLogSheet(BuildContext context) {
    final assignments = controller.assignments;
    if (assignments.isEmpty) {
      FerosSnackbar.error('No machines assigned to this work order');
      return;
    }

    final selectedAssignmentId = Rxn<int>(assignments.first['id'] as int);
    final selectedStatus       = 'WORKING'.obs;
    final workingHoursCtrl     = TextEditingController();
    final notesCtrl            = TextEditingController();

    const statuses = ['WORKING', 'STANDBY', 'IDLE', 'BREAKDOWN', 'NO_MACHINE'];
    const statusLabels = {
      'WORKING':    'Working',
      'STANDBY':    'Standby',
      'IDLE':       'Idle',
      'BREAKDOWN':  'Breakdown',
      'NO_MACHINE': 'No Machine',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Add Daily Log',
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.bodyText)),
              const SizedBox(height: 20),

              // ── Machine selector ──
              Obx(() {
                final idx = assignments
                    .indexWhere((a) => a['id'] == selectedAssignmentId.value);
                final sel =
                    idx >= 0 ? assignments[idx] : null;
                final display = sel == null
                    ? null
                    : () {
                        final s = sel['serialNumber'] as String? ?? '—';
                        final t = sel['equipmentTypeName'] as String? ?? '';
                        return t.isNotEmpty ? '$s · $t' : s;
                      }();
                return FerosSelectField<Map<String, dynamic>>(
                  label: 'Machine',
                  title: 'Select Machine',
                  hint: 'Select a machine',
                  items: assignments.toList(),
                  itemLabel: (a) {
                    final s = a['serialNumber'] as String? ?? '—';
                    final t = a['equipmentTypeName'] as String? ?? '';
                    return t.isNotEmpty ? '$s · $t' : s;
                  },
                  selectedDisplay: display,
                  onSelected: (a) =>
                      selectedAssignmentId.value = a['id'] as int,
                );
              }),
              const SizedBox(height: 14),

              // ── Status ──
              _SheetLabel('Status'),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((s) {
                      final active = selectedStatus.value == s;
                      return GestureDetector(
                        onTap: () => selectedStatus.value = s,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.equipSidebar
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: active
                                    ? AppColors.equipSidebar
                                    : AppColors.border),
                          ),
                          child: Text(
                            statusLabels[s] ?? s,
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  active ? Colors.white : AppColors.bodyText,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 14),

              // ── Working hours ──
              _SheetLabel('Working Hours'),
              const SizedBox(height: 6),
              TextField(
                controller: workingHoursCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecor(hint: 'e.g. 8.5', suffix: 'hrs'),
              ),
              const SizedBox(height: 14),

              // ── Notes ──
              _SheetLabel('Notes (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: _inputDecor(hint: 'Any remarks…'),
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              Obx(() {
                final loading = controller.isAddingLog.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final aId = selectedAssignmentId.value;
                            if (aId == null) {
                              FerosSnackbar.error('Select a machine');
                              return;
                            }
                            final hrs = workingHoursCtrl.text.trim();
                            final body = <String, dynamic>{
                              'machineAssignmentId': aId,
                              'logDate': FerosDateUtils.formatDateInput(
                                  DateTime.now()),
                              'status': selectedStatus.value,
                              if (hrs.isNotEmpty)
                                'workingHours': double.tryParse(hrs),
                              if (notesCtrl.text.trim().isNotEmpty)
                                'notes': notesCtrl.text.trim(),
                            };
                            final ok = await controller.addLog(body);
                            if (ok && context.mounted) Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.equipSidebar,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Save Log',
                            style: AppTextStyles.bodySemiBold
                                .copyWith(color: Colors.white)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor({String? hint, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.equipSidebar),
        ),
      );
}

// ── Log Card ──────────────────────────────────────────────────────────────────
class _LogCard extends GetView<EquipWorkOrderDetailController> {
  final Map<String, dynamic> log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final logId       = log['id'] as int;
    final logDate     = log['logDate']          as String?;
    final status      = log['status']           as String? ?? '';
    final serial      = log['serialNumber']     as String? ?? '—';
    final hoursWorked = log['hoursWorked'];
    final startHmr    = log['startHourMeter'];
    final endHmr      = log['endHourMeter'];
    final notes       = log['notes']            as String?;
    final slipUrl     = log['signedSlipPhotoUrl'] as String?;
    final hasSlip     = slipUrl != null && slipUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: hasSlip
            ? Border.all(color: AppColors.success.withValues(alpha: 0.4))
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date + status + signed badge ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    FerosDateUtils.formatDate(logDate),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.equipSidebar,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasSlip) ...[
                  const Icon(Icons.verified_outlined,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('Signed',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
                  const SizedBox(width: 8),
                ],
                _LogStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 6),

            // ── Machine serial ──
            Row(
              children: [
                const Icon(Icons.construction_outlined,
                    size: 13, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(serial,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),

            // ── HMR range + hours ──
            Row(
              children: [
                if (startHmr != null) ...[
                  const Icon(Icons.speed_outlined,
                      size: 12, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    endHmr != null
                        ? '$startHmr – $endHmr hrs'
                        : 'Start: $startHmr hrs',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
                const Spacer(),
                if (hoursWorked != null) ...[
                  const Icon(Icons.timer_outlined,
                      size: 12, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    '$hoursWorked hrs worked',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.bodyText,
                            fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),

            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notes,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),

            // ── Signed slip action ──
            Obx(() {
              final uploading =
                  controller.uploadingLogId.value == logId;
              return GestureDetector(
                onTap: uploading
                    ? null
                    : () => controller.pickAndUploadSlip(logId),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (uploading) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.equipSidebar),
                      ),
                      const SizedBox(width: 6),
                      Text('Uploading…',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ] else if (hasSlip) ...[
                      const Icon(Icons.camera_alt_outlined,
                          size: 14, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text('Replace signed slip',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          )),
                    ] else ...[
                      const Icon(Icons.camera_alt_outlined,
                          size: 14, color: AppColors.equipSidebar),
                      const SizedBox(width: 4),
                      Text('Upload signed slip',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.equipSidebar,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          )),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Log Status Chip ───────────────────────────────────────────────────────────
class _LogStatusChip extends StatelessWidget {
  final String status;
  const _LogStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final label = _label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontSize: 10,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'WORKING':    return AppColors.success;
      case 'STANDBY':    return AppColors.warning;
      case 'IDLE':       return AppColors.info;
      case 'BREAKDOWN':  return AppColors.error;
      case 'NO_MACHINE': return AppColors.mutedText;
      default:           return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'WORKING':    return 'Working';
      case 'STANDBY':    return 'Standby';
      case 'IDLE':       return 'Idle';
      case 'BREAKDOWN':  return 'Breakdown';
      case 'NO_MACHINE': return 'No Machine';
      default:           return s;
    }
  }
}

// ── Sheet label helper ────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.bodyText,
          fontWeight: FontWeight.w600,
        ),
      );
}
