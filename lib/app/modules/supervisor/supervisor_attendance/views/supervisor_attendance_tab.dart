import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/supervisor_attendance_controller.dart';

class SupervisorAttendanceTab extends GetView<SupervisorAttendanceController> {
  const SupervisorAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.state.value == ViewState.loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        );
      }
      if (controller.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load attendance data',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetchAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
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

      return Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          _SearchBar(controller: controller),
          const Divider(height: 1, color: AppColors.border),

          // ── Date + Stats row ─────────────────────────────────────────
          _DateStatsBar(controller: controller),
          const Divider(height: 1, color: AppColors.border),

          // ── Staff list ───────────────────────────────────────────────
          Expanded(
            child: _StaffList(controller: controller),
          ),

          // ── Submit button (sticky) ───────────────────────────────────
          Obx(() {
            final count    = controller.pendingCount;
            final submitting = controller.isSubmitting.value;
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (count > 0 && !submitting)
                        ? controller.submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      disabledBackgroundColor:
                          AppColors.navy.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            count > 0
                                ? 'Submit Attendance ($count)'
                                : 'Submit Attendance',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final SupervisorAttendanceController controller;
  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _textCtrl = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    widget.controller.searchQuery.value = v;
    final has = v.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _clear() {
    _textCtrl.clear();
    widget.controller.searchQuery.value = '';
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: _textCtrl,
        onChanged: _onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search driver or cleaner…',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mutedText),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.mutedText),
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Date + Stats Bar (combined row) ───────────────────────────────────────────
class _DateStatsBar extends StatelessWidget {
  final SupervisorAttendanceController controller;
  const _DateStatsBar({required this.controller});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: Colors.white,
            onSurface: AppColors.bodyText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.changeDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total   = controller.staff.length;
      final marked  = controller.existing.length;
      final pending = controller.pendingCount;

      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            // Date picker (left)
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 15, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Text(
                    controller.dateLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: AppColors.navy),
                ],
              ),
            ),
            const Spacer(),
            // Stats (right)
            _StatPill(label: 'Total',     value: total,          color: AppColors.navy),
            const SizedBox(width: 12),
            _StatPill(label: 'Marked',    value: marked,         color: AppColors.success),
            const SizedBox(width: 12),
            _StatPill(label: 'Remaining', value: total - marked, color: AppColors.mutedText),
            if (pending > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$pending unsaved',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Staff List ────────────────────────────────────────────────────────────────
class _StaffList extends StatelessWidget {
  final SupervisorAttendanceController controller;
  const _StaffList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.filteredStaff;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.searchQuery.value.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.badge_outlined,
                size: 48,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: 12),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No staff found'
                    : 'No drivers or cleaners found',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: list.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, i) => _StaffRow(staff: list[i]),
      );
    });
  }
}

// ── Staff Row ─────────────────────────────────────────────────────────────────
class _StaffRow extends StatelessWidget {
  final Map<String, dynamic> staff;
  const _StaffRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    final ctrl       = Get.find<SupervisorAttendanceController>();
    final name       = staff['name'] as String? ?? '—';
    final role       = staff['role'] as String? ?? '';
    final userIdRaw  = staff['id'];
    final userId = userIdRaw is int
        ? userIdRaw
        : int.tryParse(userIdRaw.toString()) ?? 0;

    final initial    = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDriver   = role == 'DRIVER';

    final avatarBg   = isDriver
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF374151);
    final roleColor  = isDriver
        ? AppColors.info
        : AppColors.mutedText;
    final roleLabel  = isDriver ? 'Driver' : 'Cleaner';
    final roleBg     = isDriver
        ? AppColors.infoLight
        : const Color(0xFFF3F4F6);

    return Obx(() {
      final isMarked  = ctrl.isMarked(userId);
      final typeName  = ctrl.markedTypeName(userId);
      final selected  = ctrl.selections[userId];

      return Opacity(
        opacity: isMarked ? 0.65 : 1.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + role + type selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.bodyText,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(roleLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Already marked ──────────────────────────────
                    if (isMarked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _typeColor(typeName ?? '').withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeName != null
                              ? _typeLabel(typeName)
                              : 'Marked',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _typeColor(typeName ?? ''),
                          ),
                        ),
                      )
                    // ── Type selector chips ─────────────────────────
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ctrl.attendanceTypes.map((t) {
                            final tid   = t['id'];
                            final tName = t['name'] as String? ?? '';
                            final typeId = tid is int
                                ? tid
                                : int.tryParse(tid.toString()) ?? 0;
                            final isSelected = selected == typeId;
                            final color = _typeColor(tName);
                            return GestureDetector(
                              onTap: () => ctrl.setSelection(
                                userId,
                                isSelected ? null : typeId,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _typeLabel(tName),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.bodyText,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _typeColor(String name) {
    switch (name) {
      case 'PRESENT':    return AppColors.attPresent;
      case 'ABSENT':     return AppColors.attAbsent;
      case 'HALF_DAY':   return AppColors.attHalfDay;
      case 'LEAVE':      return AppColors.attLeave;
      case 'HOLIDAY':    return AppColors.attHoliday;
      case 'WEEKLY_OFF': return AppColors.attWeeklyOff;
      default:           return AppColors.mutedText;
    }
  }

  String _typeLabel(String name) {
    switch (name) {
      case 'PRESENT':    return 'Present';
      case 'ABSENT':     return 'Absent';
      case 'HALF_DAY':   return 'Half Day';
      case 'LEAVE':      return 'Leave';
      case 'HOLIDAY':    return 'Holiday';
      case 'WEEKLY_OFF': return 'Weekly Off';
      default:
        return name
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join(' ');
    }
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 10)),
      ],
    );
  }
}
