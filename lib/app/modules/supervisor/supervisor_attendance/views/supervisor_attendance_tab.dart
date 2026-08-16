import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/avatar_widget.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_attendance_controller.dart';
import '../../supervisor_my_attendance/controllers/supervisor_my_attendance_controller.dart';
import '../../supervisor_my_attendance/bindings/supervisor_my_attendance_binding.dart';

// ── Root Tab Widget ────────────────────────────────────────────────────────────
class SupervisorAttendanceTab extends StatefulWidget {
  const SupervisorAttendanceTab({super.key});

  @override
  State<SupervisorAttendanceTab> createState() =>
      _SupervisorAttendanceTabState();
}

class _SupervisorAttendanceTabState extends State<SupervisorAttendanceTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    SupervisorMyAttendanceBinding().dependencies();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.navy,
          child: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "Today's"),
              Tab(text: 'Present'),
              Tab(text: 'Duty Times'),
              Tab(text: 'My Attendance'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _TodayTab(),
              _PresentTab(),
              _DutyTimesTab(),
              _MyAttendanceSelfTab(tab: _tab),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab 1: Today's Attendance ─────────────────────────────────────────────────
class _TodayTab extends StatefulWidget {
  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  final _searchCtrl = TextEditingController();
  String _search      = '';
  bool _showWatchlist = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 48),
            SizedBox(height: 8),
            ShimmerCard(height: 64),
            SizedBox(height: 8),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
          ],
        );
      }
      if (ctrl.state.value == ViewState.error) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load attendance',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ctrl.fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ]),
        );
      }

      final baseCrew = _showWatchlist ? ctrl.watchlistCrew : ctrl.crew.toList();
      final filteredCrew = _search.isEmpty
          ? baseCrew
          : baseCrew
              .where((u) => (u['name'] as String? ?? '')
                  .toLowerCase()
                  .contains(_search))
              .toList();

      return Column(
        children: [
          // ── All / My Watchlist tab bar ──────────────────────
          _WatchlistTabBar(
            isWatchlist: _showWatchlist,
            onAll: () => setState(() { _showWatchlist = false; _searchCtrl.clear(); _search = ''; }),
            onWatchlist: () => setState(() { _showWatchlist = true; _searchCtrl.clear(); _search = ''; }),
          ),

          Expanded(child: RefreshIndicator(
            color: AppColors.navy,
            onRefresh: ctrl.fetchAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
            // ── Today banner ────────────────────────────────────
            _TodayDateBanner(label: ctrl.dateLabel),
            const SizedBox(height: 12),

            // ── Stats row ───────────────────────────────────────
            _TodayStatsRow(ctrl: ctrl),
            const SizedBox(height: 12),

            // ── Search bar ──────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search by name…',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Section header + Bulk mark ──────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    _showWatchlist
                        ? 'Watchlist · ${baseCrew.length}'
                        : 'Drivers & Cleaners · ${ctrl.crew.length}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!_showWatchlist && ctrl.unmarkedCrew.isNotEmpty)
                  Obx(() => TextButton.icon(
                        onPressed: ctrl.bulkLoading.value
                            ? null
                            : () => _showBulkMarkConfirm(context, ctrl),
                        icon: ctrl.bulkLoading.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.navy),
                              )
                            : const Icon(Icons.checklist_outlined, size: 16),
                        label: Text(
                          'Bulk Mark (${ctrl.unmarkedCrew.length})',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.navy),
                      )),
              ],
            ),
            const SizedBox(height: 8),

            // ── Crew list ───────────────────────────────────────
            if (filteredCrew.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    _search.isNotEmpty
                        ? 'No results for "$_search"'
                        : _showWatchlist
                            ? 'No watchlist staff found.\nAdd staff from the Crew tab.'
                            : 'No drivers or cleaners found',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...filteredCrew.map((u) => _CrewRow(user: u, ctrl: ctrl)),
          ],
        ),
      )),
        ],
      );
    });
  }
}

// ── All / Watchlist Tab Bar (same pattern as Crew module) ─────────────────────
class _WatchlistTabBar extends StatelessWidget {
  final bool isWatchlist;
  final VoidCallback onAll;
  final VoidCallback onWatchlist;
  const _WatchlistTabBar({
    required this.isWatchlist,
    required this.onAll,
    required this.onWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              _AttTab(label: 'All', selected: !isWatchlist, onTap: onAll),
              _AttTab(
                label: 'My Watchlist',
                selected: isWatchlist,
                icon: Icons.star_rounded,
                onTap: onWatchlist,
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _AttTab extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _AttTab({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14,
                        color: selected ? AppColors.navy : AppColors.mutedText),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.navy : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              color: selected ? AppColors.navy : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today Date Banner ─────────────────────────────────────────────────────────
class _TodayDateBanner extends StatelessWidget {
  final String label;
  const _TodayDateBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.today_outlined, size: 15, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today Stats Row ───────────────────────────────────────────────────────────
class _TodayStatsRow extends StatelessWidget {
  final SupervisorAttendanceController ctrl;
  const _TodayStatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Present',  ctrl.present,  AppColors.success),
      ('Absent',   ctrl.absent,   AppColors.error),
      ('Half Day', ctrl.halfDay,  AppColors.warning),
      ('Unmarked', ctrl.unmarked, AppColors.mutedText),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final e = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: e.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('${e.$2}',
                    style: AppTextStyles.heading4
                        .copyWith(color: e.$3, fontSize: 18)),
                const SizedBox(height: 2),
                Text(e.$1,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText, fontSize: 9),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Crew Row (driver or cleaner with mark/status) ─────────────────────────────
class _CrewRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final SupervisorAttendanceController ctrl;
  const _CrewRow({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final record   = ctrl.recordForUser(user['id']);
    final marked   = record != null;
    final name     = user['name'] as String? ?? '—';
    final role     = (user['role'] as String? ?? '').toLowerCase();
    final isDriver = role == 'driver';
    final photoUrl    = user['profilePhotoUrl'] as String?;
    final avatarColor = isDriver ? AppColors.navy : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: name, imageUrl: photoUrl, size: 36, bgColor: avatarColor),
          const SizedBox(width: 10),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  isDriver ? 'Driver' : 'Cleaner',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),

          // Marked: show type badge | Unmarked: show Mark button
          if (marked)
            _TypeBadge(type: record['attendanceTypeName'] as String? ?? '—')
          else
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () =>
                    _showMarkCrewBottomSheet(context, ctrl, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Mark',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab 2: Present ────────────────────────────────────────────────────────────
class _PresentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
          ],
        );
      }

      final present = ctrl.presentCrew;
      if (present.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.group_off_outlined,
                size: 40, color: AppColors.border),
            const SizedBox(height: 12),
            Text('No one present yet',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ]),
        );
      }

      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: ctrl.fetchAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              '${present.length} Present Today',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...present.map((r) => _PresentRecord(record: r)),
          ],
        ),
      );
    });
  }
}

class _PresentRecord extends StatelessWidget {
  final Map<String, dynamic> record;
  const _PresentRecord({required this.record});

  @override
  Widget build(BuildContext context) {
    final name      = record['userName'] as String? ?? '—';
    final roleName  = record['roleName'] as String? ?? '';
    final markedBy  = record['markedByName'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: name, size: 36, bgColor: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (roleName.isNotEmpty)
                  Text(roleName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                if (markedBy != null && markedBy.isNotEmpty)
                  Text('Marked by $markedBy',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

// ── Tab 3: Duty Times ─────────────────────────────────────────────────────────
class _DutyTimesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 48),
            SizedBox(height: 8),
            ShimmerCard(height: 64),
            ShimmerCard(height: 64),
            ShimmerCard(height: 64),
            ShimmerCard(height: 64),
          ],
        );
      }
      if (ctrl.state.value == ViewState.error) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load attendance',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ctrl.fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ]),
        );
      }

      final records   = ctrl.crewRecords;
      final markedOut = records.where((r) => r['markedOutAt'] != null).length;
      final notYetOut = records.length - markedOut;

      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: ctrl.fetchAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _TodayDateBanner(label: ctrl.dateLabel),
            const SizedBox(height: 12),

            // ── Summary row ─────────────────────────────────────
            Row(
              children: [
                _DutySummaryChip(
                  label: 'Marked Out',
                  count: markedOut,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _DutySummaryChip(
                  label: 'Still On Duty',
                  count: notYetOut,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Section header ──────────────────────────────────
            Text(
              'Duty Times · ${records.length} Present',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No attendance records for today',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.mutedText),
                  ),
                ),
              )
            else
              ...records.map((r) => _DutyTimesRecord(record: r)),
          ],
        ),
      );
    });
  }
}

class _DutySummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _DutySummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: AppTextStyles.heading4
                    .copyWith(color: color, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DutyTimesRecord extends StatelessWidget {
  final Map<String, dynamic> record;
  const _DutyTimesRecord({required this.record});

  @override
  Widget build(BuildContext context) {
    final name       = record['userName']  as String? ?? '—';
    final roleName   = record['roleName']  as String? ?? '';
    final markedAt   = record['markedAt']  as String?;
    final markedOutAt = record['markedOutAt'] as String?;
    final dutyLabel  = record['dutyLabel'] as String? ?? 'Full Day';
    final isOut = markedOutAt != null;
    final dutyColor = isOut ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: name, size: 36, bgColor: AppColors.navy),
          const SizedBox(width: 10),

          // Name + role + times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (roleName.isNotEmpty)
                  Text(roleName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login_outlined,
                        size: 12, color: AppColors.success),
                    const SizedBox(width: 3),
                    Text(
                      markedAt != null
                          ? FerosDateUtils.formatDateTime(markedAt)
                          : '—',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.logout_outlined,
                        size: 12,
                        color: isOut
                            ? AppColors.error
                            : AppColors.mutedText),
                    const SizedBox(width: 3),
                    Text(
                      markedOutAt != null
                          ? FerosDateUtils.formatDateTime(markedOutAt)
                          : '—',
                      style: AppTextStyles.caption.copyWith(
                          color: isOut
                              ? AppColors.error
                              : AppColors.mutedText),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duty label badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dutyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: dutyColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              dutyLabel,
              style: AppTextStyles.caption.copyWith(
                  color: dutyColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 4: My Attendance ──────────────────────────────────────────────────────
class _MyAttendanceSelfTab extends StatefulWidget {
  final TabController tab;
  const _MyAttendanceSelfTab({required this.tab});

  @override
  State<_MyAttendanceSelfTab> createState() => _MyAttendanceSelfTabState();
}

class _MyAttendanceSelfTabState extends State<_MyAttendanceSelfTab> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.tab.index;
    widget.tab.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (mounted) setState(() => _currentTab = widget.tab.index);
  }

  @override
  void dispose() {
    widget.tab.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorMyAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 80),
            ShimmerCard(height: 56),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
          ],
        );
      }
      if (ctrl.state.value == ViewState.error) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load attendance',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ctrl.fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ]),
        );
      }

      final records     = ctrl.records.toList();
      final todayRecord = ctrl.todayRecord;
      final marked      = todayRecord != null;
      final now         = DateTime.now();
      final dayStr =
          '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} ${_month(now.month)} ${now.year}';

      return Stack(
        children: [
          RefreshIndicator(
            color: AppColors.navy,
            onRefresh: ctrl.fetchAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                // ── Today card ─────────────────────────────
                _buildTodayCard(context, ctrl, marked, todayRecord, dayStr),
                const SizedBox(height: 14),

                // ── Stats row ──────────────────────────────
                _buildStatsRow(ctrl),
                const SizedBox(height: 14),

                // ── Monthly records ────────────────────────
                Text(
                  "This Month's Records — ${_month(now.month)} ${now.year}",
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No attendance records this month',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ),
                  )
                else
                  ...records.map((r) => _AttendanceRecordCard(record: r)),
              ],
            ),
          ),

          // ── FAB: mark own attendance ─────────────────────
          if (_currentTab == 3 && !marked)
            Positioned(
              bottom: 16,
              right: 16,
              child: Obx(() => FloatingActionButton.extended(
                    onPressed: ctrl.markLoading.value
                        ? null
                        : () => _showMarkBottomSheet(context, ctrl),
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    icon: ctrl.markLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.how_to_reg_outlined),
                    label: const Text(
                      'Mark Attendance',
                      style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    ),
                  )),
            ),
        ],
      );
    });
  }

  Widget _buildTodayCard(
    BuildContext context,
    SupervisorMyAttendanceController ctrl,
    bool marked,
    Map<String, dynamic>? todayRecord,
    String dayStr,
  ) {
    final color = marked ? AppColors.success : AppColors.warning;
    final bg    = color.withValues(alpha: 0.08);
    final border = color.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.calendar_today_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today — $dayStr',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (marked)
                  Wrap(spacing: 6, children: [
                    _TypeBadge(
                        type: todayRecord!['attendanceTypeName']
                                as String? ??
                            ''),
                    _ApprovalBadge(
                        status:
                            todayRecord['approvalStatus'] as String? ?? ''),
                  ])
                else
                  Text('Not marked yet',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SupervisorMyAttendanceController ctrl) {
    final items = [
      ('Present', ctrl.present, AppColors.success),
      ('Absent',  ctrl.absent,  AppColors.error),
      ('Half',    ctrl.half,    AppColors.warning),
      ('Leave',   ctrl.leave,   AppColors.navy),
      ('Pending', ctrl.pending, AppColors.mutedText),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final e = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 5 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: e.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('${e.$2}',
                    style: AppTextStyles.heading4
                        .copyWith(color: e.$3, fontSize: 16)),
                Text(e.$1,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText, fontSize: 9),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Mark Crew Bottom Sheet (supervisor marks for a driver/cleaner) ─────────────
void _showMarkCrewBottomSheet(
  BuildContext context,
  SupervisorAttendanceController ctrl,
  Map<String, dynamic> user,
) {
  final selectedTypeId      = Rxn<int>();
  final selectedLeaveTypeId = Rxn<int>();
  final remarksCtrl         = TextEditingController();

  showModalBottomSheet(
        useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Obx(() {
        // Resolve leave flag from selected type
        final selectedType = selectedTypeId.value != null
            ? _findType(ctrl.attendanceTypes, selectedTypeId.value!)
            : null;
        final isLeave = selectedType != null &&
            (selectedType['name'] as String? ?? '')
                .toLowerCase()
                .contains('leave');

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text('Mark Attendance',
                  style:
                      AppTextStyles.heading4.copyWith(color: AppColors.navy)),
              Text(
                user['name'] as String? ?? '—',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),

              // Attendance type chips
              Text('Attendance Type *',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.attendanceTypes.map((t) {
                  final id       = t['id'] as int;
                  final typeName = t['name'] as String? ?? '';
                  final selected = selectedTypeId.value == id;
                  final color    = _typeColor(typeName);
                  return GestureDetector(
                    onTap: () {
                      selectedTypeId.value = id;
                      if (!typeName.toLowerCase().contains('leave')) {
                        selectedLeaveTypeId.value = null;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.12)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        typeName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                          color: selected ? color : AppColors.bodyText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Leave type dropdown (only when leave type selected)
              if (isLeave) ...[
                const SizedBox(height: 12),
                Text('Leave Type',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedLeaveTypeId.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Select leave type'),
                  items: ctrl.leaveTypes
                      .map((lt) => DropdownMenuItem<int>(
                            value: lt['id'] as int,
                            child:
                                Text(lt['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => selectedLeaveTypeId.value = v,
                ),
              ],

              // Remarks
              const SizedBox(height: 12),
              Text('Remarks (Optional)',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 4),
              TextField(
                controller: remarksCtrl,
                decoration: InputDecoration(
                  hintText: 'Optional',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (selectedTypeId.value == null || ctrl.markLoading.value)
                          ? null
                          : () async {
                              final ok = await ctrl.markForUser(
                                userId: user['id'] as int,
                                attendanceTypeId: selectedTypeId.value!,
                                leaveTypeId: selectedLeaveTypeId.value,
                                remarks: remarksCtrl.text,
                              );
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                                Get.snackbar(
                                  'Marked',
                                  '${user['name']} marked successfully',
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } else if (!ok && context.mounted) {
                                Get.snackbar(
                                  'Error',
                                  'Failed to mark attendance',
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
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
                  child: ctrl.markLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Mark',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}

// ── Bulk Mark Confirmation Dialog ─────────────────────────────────────────────
void _showBulkMarkConfirm(
    BuildContext context, SupervisorAttendanceController ctrl) {
  final selectedTypeId = Rxn<int>();
  // Pre-select "Present" so the default behaviour is unchanged
  for (final t in ctrl.attendanceTypes) {
    final n = (t['name'] as String? ?? '').toLowerCase();
    if (n.contains('present') && !n.contains('half')) {
      selectedTypeId.value = t['id'] as int?;
      break;
    }
  }

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Bulk Mark Crew',
        style: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: Obx(() {
        final count = ctrl.unmarkedCrew.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark $count unmarked crew member${count == 1 ? '' : 's'} as:',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ctrl.attendanceTypes.map((t) {
                final id       = t['id'] as int;
                final typeName = t['name'] as String? ?? '';
                final selected = selectedTypeId.value == id;
                final color    = _typeColor(typeName);
                return GestureDetector(
                  onTap: () => selectedTypeId.value = id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.12)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      typeName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                        color: selected ? color : AppColors.bodyText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
              onPressed: (ctrl.bulkLoading.value || selectedTypeId.value == null)
                  ? null
                  : () async {
                      final typeName = (ctrl.attendanceTypes.firstWhere(
                        (t) => t['id'] == selectedTypeId.value,
                        orElse: () => {'name': 'Marked'},
                      )['name'] as String? ?? 'Marked');
                      final ok = await ctrl.markBulkPresent(selectedTypeId.value!);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (ok) {
                        Get.snackbar(
                          'Done',
                          'All marked as $typeName',
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'Failed to bulk mark',
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: ctrl.bulkLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm',
                      style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            )),
      ],
    ),
  );
}

// ── Self-mark Bottom Sheet (My Attendance tab) ────────────────────────────────
void _showMarkBottomSheet(
    BuildContext context, SupervisorMyAttendanceController ctrl) {
  final remarks    = TextEditingController();
  final selfieFile = Rxn<File>();

  showModalBottomSheet(
        useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Obx(() => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Mark Today\'s Attendance',
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(
                  _todayLabel(),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),

                // Selfie
                _SelfieBox(
                    selfieFile: selfieFile,
                    disabled: ctrl.markLoading.value),
                const SizedBox(height: 12),

                // Remarks
                Text('Remarks (Optional)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 4),
                TextField(
                  controller: remarks,
                  decoration: InputDecoration(
                    hintText: 'Optional',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Attendance will be reviewed and approved by admin.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.markLoading.value
                        ? null
                        : () async {
                            final presentType = ctrl.attendanceTypes.firstWhereOrNull(
                              (t) {
                                final n = (t['name'] as String? ?? '').toLowerCase();
                                return n.contains('present') && !n.contains('half');
                              },
                            );
                            if (presentType == null) return;
                            final ok = await ctrl.markAttendance(
                              typeId: presentType['id'] as int,
                              selfieFile: selfieFile.value,
                              remarks: remarks.text,
                            );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                              Get.snackbar(
                                'Success',
                                'Attendance marked',
                                backgroundColor: AppColors.success,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } else if (!ok && context.mounted) {
                              Get.snackbar(
                                'Error',
                                'Failed to mark attendance',
                                backgroundColor: AppColors.error,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                    icon: ctrl.markLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      ctrl.markLoading.value ? 'Marking…' : 'Mark Present',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
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
          )),
    ),
  );
}

// ── Selfie Box ────────────────────────────────────────────────────────────────
class _SelfieBox extends StatelessWidget {
  final Rxn<File> selfieFile;
  final bool disabled;
  const _SelfieBox({required this.selfieFile, required this.disabled});

  Future<void> _pick() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile != null) selfieFile.value = File(xFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : _pick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: selfieFile.value == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_front_outlined,
                      size: 32, color: AppColors.mutedText),
                  const SizedBox(height: 8),
                  Text('Tap to take selfie (Optional)',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(selfieFile.value!, fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap:
                          disabled ? null : () => selfieFile.value = null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: disabled ? null : _pick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Retake',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Attendance Record Card (monthly history in My Attendance tab) ──────────────
class _AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date           = record['attendanceDate']     as String? ?? '';
    final typeName       = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']     as String? ?? '';
    final leaveTypeName  = record['leaveTypeName']      as String?;
    final approvedByName = record['approvedByName']     as String?;
    final remarks        = record['remarks']            as String?;
    final markedAt       = record['markedAt']           as String?;

    final (typeColor, typeIcon) = _typeStyle(typeName);
    final (approvalColor, approvalLabel) = _approvalStyle(approvalStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(_dayNum(date),
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy, fontSize: 20)),
                Text(_monthShort(date),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
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
                    Text(typeName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.bodyText)),
                    const Spacer(),
                    if (approvalStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: approvalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(approvalLabel,
                            style: AppTextStyles.caption.copyWith(
                                color: approvalColor,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (leaveTypeName != null && leaveTypeName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Leave: $leaveTypeName',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (approvedByName != null && approvedByName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Approved by $approvedByName',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (markedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                      'Marked at ${FerosDateUtils.formatDateTime(markedAt)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(remarks,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayNum(String iso) {
    try {
      return DateTime.parse(iso).day.toString().padLeft(2, '0');
    } catch (_) {
      return '—';
    }
  }

  String _monthShort(String iso) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    try {
      return months[DateTime.parse(iso).month - 1];
    } catch (_) {
      return '';
    }
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(type,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Approval Badge ────────────────────────────────────────────────────────────
class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _approvalStyle(status);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _weekday(int w) =>
    const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];

String _month(int m) => const [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][m];

String _todayLabel() {
  final d = DateTime.now();
  return '${_weekday(d.weekday)}, ${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
}

Color _typeColor(String name) {
  final n = name.toUpperCase();
  if (n.contains('PRESENT') && !n.contains('HALF')) return AppColors.success;
  if (n.contains('ABSENT'))                          return AppColors.error;
  if (n.contains('HALF'))                            return AppColors.warning;
  if (n.contains('LEAVE'))                           return AppColors.navy;
  return AppColors.mutedText;
}

(Color, IconData) _typeStyle(String name) {
  final n = name.toUpperCase();
  if (n.contains('PRESENT') && !n.contains('HALF')) {
    return (AppColors.success, Icons.check_circle_outline);
  }
  if (n.contains('ABSENT'))  return (AppColors.error,     Icons.cancel_outlined);
  if (n.contains('HALF'))    return (AppColors.warning,   Icons.timelapse_outlined);
  if (n.contains('LEAVE'))   return (AppColors.navy,      Icons.beach_access_outlined);
  if (n.contains('WEEKLY') || n.contains('OFF')) {
    return (AppColors.mutedText, Icons.weekend_outlined);
  }
  return (AppColors.mutedText, Icons.event_note_outlined);
}

(Color, String) _approvalStyle(String status) {
  switch (status) {
    case 'PENDING':  return (AppColors.warning, 'Pending');
    case 'APPROVED': return (AppColors.success, 'Approved');
    case 'REJECTED': return (AppColors.error,   'Rejected');
    default:         return (AppColors.mutedText, status);
  }
}

Map<String, dynamic>? _findType(List<Map<String, dynamic>> types, int id) {
  for (final t in types) {
    if (t['id'] == id) return t;
  }
  return null;
}
