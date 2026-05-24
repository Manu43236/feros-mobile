import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/services/auth_service.dart';
import '../controllers/office_attendance_controller.dart';
import '../../../supervisor/supervisor_my_attendance/controllers/supervisor_my_attendance_controller.dart';
import '../../../supervisor/supervisor_my_attendance/bindings/supervisor_my_attendance_binding.dart';

class OfficeAttendanceView extends StatefulWidget {
  const OfficeAttendanceView({super.key});

  @override
  State<OfficeAttendanceView> createState() => _OfficeAttendanceViewState();
}

class _OfficeAttendanceViewState extends State<OfficeAttendanceView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final OfficeAttendanceController _ctrl;
  late final bool _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = Get.find<AuthService>().user?.role == 'ADMIN';
    Get.lazyPut<OfficeAttendanceController>(() => OfficeAttendanceController());
    _ctrl = Get.find<OfficeAttendanceController>();
    SupervisorMyAttendanceBinding().dependencies();
    // ADMIN: Daily | My Attendance | Pending | Rejected  (4 tabs)
    // OFFICE_STAFF: Daily | My Attendance  (2 tabs)
    _tab = TabController(length: _isAdmin ? 4 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _isAdmin
              ? Obx(() {
                  final pc = _ctrl.pendingCount.value;
                  final rc = _ctrl.rejectedCount.value;
                  return TabBar(
                    controller: _tab,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                    labelStyle: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    tabs: [
                      const Tab(text: 'Daily'),
                      const Tab(text: 'My Attendance'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pending',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            if (pc > 0) ...[
                              const SizedBox(width: 4),
                              _Badge(count: pc, color: AppColors.warning),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Rejected',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            if (rc > 0) ...[
                              const SizedBox(width: 4),
                              _Badge(count: rc, color: AppColors.error),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                })
              : TabBar(
                  controller: _tab,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                  labelStyle: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'My Attendance'),
                  ],
                ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DailyTab(ctrl: _ctrl),
          const _MyAttendanceTab(),
          if (_isAdmin) ...[
            _PendingTab(ctrl: _ctrl),
            _RejectedTab(ctrl: _ctrl),
          ],
        ],
      ),
    );
  }
}

// ── My Attendance Tab ──────────────────────────────────────────────────────────
class _MyAttendanceTab extends StatelessWidget {
  const _MyAttendanceTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorMyAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (ctrl.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load attendance',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ctrl.fetchRecords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (ctrl.records.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 52, color: AppColors.mutedText),
              const SizedBox(height: 12),
              Text('No attendance records', style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              Text('Your attendance history will appear here.',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: ctrl.fetchRecords,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: ctrl.records.length,
          itemBuilder: (_, i) => _MyAttendanceCard(record: ctrl.records[i]),
        ),
      );
    });
  }
}

class _MyAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _MyAttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date           = record['date']               as String? ?? '';
    final typeName       = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']     as String? ?? '';
    final remarks        = record['remarks']            as String?;
    final markedAt       = record['createdAt']          as String?;

    final typeColor  = _typeColor(typeName);
    final typeIcon   = _typeIcon(typeName);
    final approvalColor = _approvalColor(approvalStatus);
    final approvalLabel = _approvalLabel(approvalStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(_dayNum(date), style: AppTextStyles.heading3.copyWith(color: AppColors.navy, fontSize: 20)),
                Text(_monthShort(date), style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(typeName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyText)),
                    const Spacer(),
                    if (approvalStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: approvalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(approvalLabel,
                            style: AppTextStyles.caption.copyWith(color: approvalColor, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (markedAt != null) ...[
                  const SizedBox(height: 3),
                  Text('Marked at ${FerosDateUtils.formatDateTime(markedAt)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(remarks, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayNum(String iso) { try { return DateTime.parse(iso).day.toString().padLeft(2, '0'); } catch (_) { return '—'; } }
  String _monthShort(String iso) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    try { return m[DateTime.parse(iso).month - 1]; } catch (_) { return ''; }
  }
  Color _typeColor(String n) {
    final u = n.toUpperCase();
    if (u.contains('PRESENT') && !u.contains('HALF')) return AppColors.success;
    if (u.contains('ABSENT')) return AppColors.error;
    if (u.contains('HALF')) return AppColors.warning;
    if (u.contains('LEAVE')) return AppColors.info;
    return AppColors.mutedText;
  }
  IconData _typeIcon(String n) {
    final u = n.toUpperCase();
    if (u.contains('PRESENT') && !u.contains('HALF')) return Icons.check_circle_outline;
    if (u.contains('ABSENT')) return Icons.cancel_outlined;
    if (u.contains('HALF')) return Icons.timelapse_outlined;
    if (u.contains('LEAVE')) return Icons.beach_access_outlined;
    return Icons.event_note_outlined;
  }
  Color _approvalColor(String s) {
    switch (s) {
      case 'PENDING':  return AppColors.warning;
      case 'APPROVED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default:         return AppColors.mutedText;
    }
  }
  String _approvalLabel(String s) {
    switch (s) {
      case 'PENDING':  return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default:         return s;
    }
  }
}

// ── Daily Tab ──────────────────────────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  final OfficeAttendanceController ctrl;
  const _DailyTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date navigator
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Obx(() {
            final d = ctrl.selectedDate.value;
            final now = DateTime.now();
            final isToday =
                d.year == now.year && d.month == now.month && d.day == now.day;
            final label =
                '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
            return Row(
              children: [
                _NavBtn(
                  icon: Icons.arrow_back_ios,
                  onTap: () => ctrl.shiftDay(-1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.navy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _NavBtn(
                  icon: Icons.chevron_right,
                  onTap: isToday ? null : () => ctrl.shiftDay(1),
                ),
                if (!isToday) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: ctrl.goToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Today',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),

        // Stats bar
        Obx(() {
          final s = ctrl.stats;
          if (ctrl.allStaff.isEmpty && ctrl.records.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                _StatChip('Total', '${s['total']}', AppColors.bodyText),
                _StatChip('Present', '${s['present']}', AppColors.success),
                _StatChip('Absent', '${s['absent']}', AppColors.error),
                _StatChip('Half', '${s['half']}', AppColors.warning),
                _StatChip('Leave', '${s['leave']}', AppColors.navy),
                if ((s['unmarked'] ?? 0) > 0)
                  _StatChip(
                    'Unmarked',
                    '${s['unmarked']}',
                    AppColors.mutedText,
                  ),
              ],
            ),
          );
        }),

        // List
        Expanded(
          child: Obx(() {
            final state = ctrl.dailyState.value;
            if (state == ViewState.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              );
            }
            if (state == ViewState.error) {
              return _ErrorWidget(
                message: 'Failed to load attendance',
                onRetry: ctrl.fetchByDate,
              );
            }

            final rows = ctrl.mergedRows;

            if (rows.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      size: 52,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No staff or records found',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: ctrl.fetchAll,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.navy,
              onRefresh: ctrl.fetchAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final row = rows[i];
                  final isMarked = row['_type'] == 'marked';
                  return _AttendanceRow(
                    row: row,
                    isMarked: isMarked,
                    onTap: () => _showMarkSheet(
                      context,
                      ctrl,
                      isMarked ? row : null,
                      preUserId: isMarked
                          ? null
                          : (row['userId'] as num?)?.toInt(),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.fetchByDate(picked);
  }

  void _showMarkSheet(
    BuildContext context,
    OfficeAttendanceController ctrl,
    Map<String, dynamic>? record, {
    int? preUserId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkAttendanceSheet(
        ctrl: ctrl,
        record: record,
        preUserId: preUserId,
      ),
    );
  }

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

// ── Attendance Row ─────────────────────────────────────────────────────────────
class _AttendanceRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isMarked;
  final VoidCallback onTap;
  const _AttendanceRow({
    required this.row,
    required this.isMarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = row['userName'] as String? ?? '—';
    final role = row['roleName'] as String? ?? '';
    final type = row['attendanceTypeName'] as String?;
    final approval = row['approvalStatus'] as String?;
    final markedBy = row['markedByName'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMarked
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: isMarked ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isMarked ? AppColors.navy : AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isMarked
                          ? AppColors.bodyText
                          : AppColors.mutedText,
                    ),
                  ),
                  Text(
                    _roleLabel(role),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  if (markedBy != null)
                    Text(
                      'by $markedBy',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),

            // Status chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (type != null) _TypeChip(type: type) else _NotMarkedChip(),
                if (approval != null) ...[
                  const SizedBox(height: 4),
                  _ApprovalChip(status: approval),
                ],
              ],
            ),

            const SizedBox(width: 4),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'SERVICE_MEN' => 'Service Men',
    'STORE_KEEPER' => 'Store Keeper',
    'OFFICE_STAFF' => 'Office Staff',
    _ => role.isEmpty ? '' : role[0] + role.substring(1).toLowerCase(),
  };
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    final color = t.contains('present')
        ? AppColors.success
        : t.contains('absent')
        ? AppColors.error
        : t.contains('half')
        ? AppColors.warning
        : t.contains('leave')
        ? AppColors.navy
        : AppColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _NotMarkedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mutedText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Not marked',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ApprovalChip extends StatelessWidget {
  final String status;
  const _ApprovalChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'APPROVED' => 'Approved',
      'REJECTED' => 'Rejected',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ── Pending Tab ────────────────────────────────────────────────────────────────
class _PendingTab extends StatelessWidget {
  final OfficeAttendanceController ctrl;
  const _PendingTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = ctrl.pendingState.value;
      if (s == ViewState.loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        );
      }
      if (s == ViewState.error) {
        return _ErrorWidget(
          message: 'Failed to load pending',
          onRetry: ctrl.fetchPending,
        );
      }

      final list = ctrl.filteredPending;
      final hasFilter =
          ctrl.pendingFrom.value != null || ctrl.pendingTo.value != null;

      return Column(
        children: [
          _DateFilterBar(
            from: ctrl.pendingFrom.value,
            to: ctrl.pendingTo.value,
            onFromChanged: ctrl.setPendingFrom,
            onToChanged: ctrl.setPendingTo,
            onClear: hasFilter ? ctrl.clearPendingFilter : null,
            totalCount: ctrl.pendingList.length,
            filteredCount: list.length,
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 52,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasFilter
                              ? 'No records in this range'
                              : 'All caught up!',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.navy,
                          ),
                        ),
                        if (!hasFilter)
                          Text(
                            'No pending approvals',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.navy,
                    onRefresh: ctrl.fetchPending,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _PendingCard(
                        record: list[i],
                        onApprove: () => _handle(
                          context,
                          () => ctrl.approve((list[i]['id'] as num).toInt()),
                          'Attendance approved',
                        ),
                        onReject: () => _handle(
                          context,
                          () => ctrl.reject((list[i]['id'] as num).toInt()),
                          'Attendance rejected',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  Future<void> _handle(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      FerosSnackbar.success(success);
    } catch (_) {
      FerosSnackbar.error('Action failed. Try again.');
    }
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _PendingCard({
    required this.record,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name = record['userName'] as String? ?? '—';
    final role = record['roleName'] as String? ?? '';
    final date = record['attendanceDate'] as String? ?? '';
    final type = record['attendanceTypeName'] as String? ?? '—';
    final by = record['markedByName'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _TypeChip(type: type),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              if (by.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  'by $by',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rejected Tab ───────────────────────────────────────────────────────────────
class _RejectedTab extends StatelessWidget {
  final OfficeAttendanceController ctrl;
  const _RejectedTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = ctrl.rejectedState.value;
      if (s == ViewState.loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        );
      }
      if (s == ViewState.error) {
        return _ErrorWidget(
          message: 'Failed to load rejected',
          onRetry: ctrl.fetchRejected,
        );
      }

      final list = ctrl.filteredRejected;
      final hasFilter =
          ctrl.rejectedFrom.value != null || ctrl.rejectedTo.value != null;

      return Column(
        children: [
          _DateFilterBar(
            from: ctrl.rejectedFrom.value,
            to: ctrl.rejectedTo.value,
            onFromChanged: ctrl.setRejectedFrom,
            onToChanged: ctrl.setRejectedTo,
            onClear: hasFilter ? ctrl.clearRejectedFilter : null,
            totalCount: ctrl.rejectedList.length,
            filteredCount: list.length,
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 52,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasFilter
                              ? 'No records in this range'
                              : 'No rejected records',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.navy,
                    onRefresh: ctrl.fetchRejected,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _RejectedCard(
                        record: list[i],
                        onApprove: () async {
                          try {
                            await ctrl.approve((list[i]['id'] as num).toInt());
                            FerosSnackbar.success('Attendance approved');
                          } catch (_) {
                            FerosSnackbar.error('Failed to approve');
                          }
                        },
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _RejectedCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onApprove;
  const _RejectedCard({required this.record, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    final name = record['userName'] as String? ?? '—';
    final role = record['roleName'] as String? ?? '';
    final date = record['attendanceDate'] as String? ?? '';
    final type = record['attendanceTypeName'] as String? ?? '—';
    final by = record['approvedByName'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _TypeChip(type: type),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              if (by != null) ...[
                const SizedBox(width: 10),
                Text(
                  'rejected by $by',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onApprove,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Approve Anyway',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mark / Edit Attendance Sheet ───────────────────────────────────────────────
class _MarkAttendanceSheet extends StatefulWidget {
  final OfficeAttendanceController ctrl;
  final Map<String, dynamic>? record; // null = create, non-null = edit
  final int? preUserId; // pre-select unmarked staff

  const _MarkAttendanceSheet({required this.ctrl, this.record, this.preUserId});

  @override
  State<_MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  String? _userId;
  String? _typeId;
  String? _leaveTypeId;
  final _remarksCtr = TextEditingController();
  final _leaveRsnCtr = TextEditingController();
  bool _loading = false;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.record!;
      _userId = (r['userId'] as num?)?.toString();
      _typeId = (r['attendanceTypeId'] as num?)?.toString();
      _leaveTypeId = (r['leaveTypeId'] as num?)?.toString();
      _remarksCtr.text = r['remarks'] as String? ?? '';
      _leaveRsnCtr.text = r['leaveReason'] as String? ?? '';
    } else if (widget.preUserId != null) {
      _userId = widget.preUserId.toString();
    }
  }

  @override
  void dispose() {
    _remarksCtr.dispose();
    _leaveRsnCtr.dispose();
    super.dispose();
  }

  bool get _isLeave {
    if (_typeId == null) return false;
    final type = widget.ctrl.attendanceTypes.firstWhereOrNull(
      (t) => (t['id'] as num?)?.toString() == _typeId,
    );
    return (type?['name'] as String? ?? '').toLowerCase().contains('leave');
  }

  Future<void> _submit() async {
    if (_userId == null || _typeId == null) {
      FerosSnackbar.error('Select staff and attendance type');
      return;
    }
    setState(() => _loading = true);
    try {
      final d = widget.ctrl.selectedDate.value;
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final body = <String, dynamic>{
        'userId': int.parse(_userId!),
        'attendanceDate': dateStr,
        'attendanceTypeId': int.parse(_typeId!),
        if (_leaveTypeId != null) 'leaveTypeId': int.parse(_leaveTypeId!),
        if (_leaveRsnCtr.text.trim().isNotEmpty)
          'leaveReason': _leaveRsnCtr.text.trim(),
        if (_remarksCtr.text.trim().isNotEmpty)
          'remarks': _remarksCtr.text.trim(),
      };
      if (_isEdit) {
        final id = (widget.record!['id'] as num).toInt();
        await widget.ctrl.updateAttendance(id, body);
      } else {
        await widget.ctrl.markAttendance(body);
      }
      if (mounted) {
        Navigator.pop(context);
        FerosSnackbar.success(
          _isEdit ? 'Attendance updated' : 'Attendance marked',
        );
      }
    } catch (e) {
      FerosSnackbar.error('Failed to save attendance');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final staff = widget.ctrl.allStaff;
    final types = widget.ctrl.attendanceTypes;
    final leaves = widget.ctrl.leaveTypes;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isEdit ? 'Edit Attendance' : 'Mark Attendance',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.navy),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Staff picker (disabled in edit mode)
            _label('Staff *'),
            const SizedBox(height: 6),
            Obx(
              () => DropdownButtonFormField<String>(
                value: _userId,
                decoration: _inputDec('Select staff'),
                items: staff.map((u) {
                  final id = (u['id'] as num?)?.toString() ?? '';
                  final name = u['name'] as String? ?? '';
                  final role = u['role'] as String? ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(
                      '$name ($role)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isEdit ? null : (v) => setState(() => _userId = v),
              ),
            ),
            const SizedBox(height: 12),

            // Attendance type
            _label('Attendance Type *'),
            const SizedBox(height: 6),
            Obx(
              () => DropdownButtonFormField<String>(
                value: _typeId,
                decoration: _inputDec('Select type'),
                items: types.map((t) {
                  final id = (t['id'] as num?)?.toString() ?? '';
                  final name = t['name'] as String? ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() {
                  _typeId = v;
                  if (!_isLeave) _leaveTypeId = null;
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Leave type (only if leave)
            if (_isLeave) ...[
              _label('Leave Type'),
              const SizedBox(height: 6),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: _leaveTypeId,
                  decoration: _inputDec('Select leave type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ...leaves.map((t) {
                      final id = (t['id'] as num?)?.toString() ?? '';
                      final name = t['name'] as String? ?? '';
                      return DropdownMenuItem(value: id, child: Text(name));
                    }),
                  ],
                  onChanged: (v) => setState(() => _leaveTypeId = v),
                ),
              ),
              const SizedBox(height: 12),
              _label('Leave Reason'),
              const SizedBox(height: 6),
              _textField(_leaveRsnCtr, 'Optional reason'),
              const SizedBox(height: 12),
            ],

            // Remarks
            _label('Remarks'),
            const SizedBox(height: 6),
            _textField(_remarksCtr, 'Optional'),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Update' : 'Mark Attendance',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.bodyText,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _textField(TextEditingController ctr, String hint) =>
      TextField(controller: ctr, decoration: _inputDec(hint));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
    ),
  );
}

// ── Date Filter Bar (Pending / Rejected tabs) ──────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime?) onFromChanged;
  final void Function(DateTime?) onToChanged;
  final VoidCallback? onClear;
  final int totalCount;
  final int filteredCount;

  const _DateFilterBar({
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    required this.totalCount,
    required this.filteredCount,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = from != null || to != null;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterDateBtn(
              label: 'From',
              date: from,
              onPick: (d) => onFromChanged(d),
              onClear: from != null ? () => onFromChanged(null) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDateBtn(
              label: 'To',
              date: to,
              onPick: (d) => onToChanged(d),
              onClear: to != null ? () => onToChanged(null) : null,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Clear',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (hasFilter && filteredCount != totalCount) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$filteredCount / $totalCount',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDateBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final void Function(DateTime) onPick;
  final VoidCallback? onClear;
  const _FilterDateBtn({
    required this.label,
    required this.date,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? label
        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    final isSet = date != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.navy),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.navy.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSet ? AppColors.navy : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: isSet ? AppColors.navy : AppColors.mutedText,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: isSet ? AppColors.navy : AppColors.mutedText,
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSet && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.mutedText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.background
              : AppColors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.bodyText : AppColors.mutedText,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
