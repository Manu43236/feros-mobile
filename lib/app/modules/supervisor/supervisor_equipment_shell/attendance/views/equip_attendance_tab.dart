import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/view_state.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../controllers/equip_attendance_controller.dart';
import '../../../supervisor_my_attendance/controllers/supervisor_my_attendance_controller.dart';

// ── Root Tab Widget ────────────────────────────────────────────────────────────
class EquipAttendanceTab extends StatefulWidget {
  const EquipAttendanceTab({super.key});

  @override
  State<EquipAttendanceTab> createState() => _EquipAttendanceTabState();
}

class _EquipAttendanceTabState extends State<EquipAttendanceTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final List<_StaffTabSpec> _staffTabs;

  @override
  void initState() {
    super.initState();
    _staffTabs = _buildStaffTabs(Get.find<EquipAttendanceController>());
    _tab = TabController(length: _staffTabs.length + 1, vsync: this);
    if (!Get.isRegistered<SupervisorMyAttendanceController>()) {
      Get.put(SupervisorMyAttendanceController());
    }
  }

  // Lease access → drivers + cleaners; equipment access → operators.
  // Both → separate Drivers / Cleaners / Operators tabs.
  // Lease only → one combined list (mirrors the vehicle-shell attendance).
  List<_StaffTabSpec> _buildStaffTabs(EquipAttendanceController ctrl) {
    if (ctrl.bothEnabled) {
      return const [
        _StaffTabSpec(
            label: 'Drivers', roles: ['DRIVER'],
            showFavorites: true, allowBulk: false, emptyNoun: 'drivers'),
        _StaffTabSpec(
            label: 'Cleaners', roles: ['CLEANER'],
            showFavorites: true, allowBulk: false, emptyNoun: 'cleaners'),
        _StaffTabSpec(
            label: 'Operators', roles: ['OPERATOR'],
            showFavorites: false, allowBulk: true, emptyNoun: 'operators'),
      ];
    }
    if (ctrl.canAccessEquipment) {
      return const [
        _StaffTabSpec(
            label: 'Operators', roles: ['OPERATOR'],
            showFavorites: false, allowBulk: true, emptyNoun: 'operators'),
      ];
    }
    return const [
      _StaffTabSpec(
          label: 'Drivers & Cleaners', roles: ['DRIVER', 'CLEANER'],
          showFavorites: true, allowBulk: false, emptyNoun: 'drivers or cleaners'),
    ];
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selfIndex = _staffTabs.length;
    return Column(
      children: [
        Container(
          color: AppColors.equipSidebar,
          child: TabBar(
            controller: _tab,
            isScrollable: _staffTabs.length > 2,
            tabAlignment:
                _staffTabs.length > 2 ? TabAlignment.start : TabAlignment.fill,
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
            tabs: [
              for (final s in _staffTabs) Tab(text: s.label),
              const Tab(text: 'My Attendance'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              for (final s in _staffTabs) _StaffAttendanceList(spec: s),
              _MyAttendanceSelfTab(tab: _tab, selfIndex: selfIndex),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Staff tab spec ─────────────────────────────────────────────────────────────
class _StaffTabSpec {
  final String label;
  final List<String> roles;
  final bool showFavorites;
  final bool allowBulk; // supervisor bulk-marks + re-marks (operators only)
  final String emptyNoun;
  const _StaffTabSpec({
    required this.label,
    required this.roles,
    required this.showFavorites,
    required this.allowBulk,
    required this.emptyNoun,
  });
}

// ── Staff attendance list (drivers / cleaners / operators) ──────────────────────
class _StaffAttendanceList extends StatefulWidget {
  final _StaffTabSpec spec;
  const _StaffAttendanceList({required this.spec});

  @override
  State<_StaffAttendanceList> createState() => _StaffAttendanceListState();
}

class _StaffAttendanceListState extends State<_StaffAttendanceList> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _showWatchlist = false;

  EquipAttendanceController get ctrl => Get.find<EquipAttendanceController>();
  _StaffTabSpec get spec => widget.spec;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.equipSidebar),
        );
      }
      if (ctrl.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load attendance',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ctrl.fetchAll,
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

      final roleCrew = ctrl.crewForRoles(spec.roles);
      final baseCrew = (spec.showFavorites && _showWatchlist)
          ? roleCrew.where((u) => ctrl.isWatchlisted(u['id'])).toList()
          : roleCrew;
      final filtered = _search.isEmpty
          ? baseCrew
          : baseCrew
              .where((u) => (u['name'] as String? ?? '')
                  .toLowerCase()
                  .contains(_search))
              .toList();

      return Column(
        children: [
          if (spec.showFavorites)
            _FavoritesToggle(
              showWatchlist: _showWatchlist,
              onAll: () => setState(() {
                _showWatchlist = false;
                _searchCtrl.clear();
                _search = '';
              }),
              onFavorites: () => setState(() {
                _showWatchlist = true;
                _searchCtrl.clear();
                _search = '';
              }),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.equipSidebar,
              onRefresh: ctrl.fetchAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Date banner ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.equipSidebar,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          ctrl.dateLabel,
                          style: AppTextStyles.bodySemiBold
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Stats row (scoped to this tab) ───────────────
                  Row(
                    children: [
                      _StatCard(
                        label: 'Present',
                        value: ctrl.presentIn(roleCrew),
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        label: 'Absent',
                        value: ctrl.absentIn(roleCrew),
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        label: 'Unmarked',
                        value: ctrl.unmarkedIn(roleCrew),
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Search bar ───────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _search = v.trim().toLowerCase()),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search by name…',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.mutedText),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
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
                        borderSide:
                            const BorderSide(color: AppColors.equipSidebar),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Section header + bulk mark ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${spec.label} · ${baseCrew.length}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (spec.allowBulk &&
                          !_showWatchlist &&
                          ctrl.unmarkedCrewIn(roleCrew).isNotEmpty)
                        Obx(() => TextButton.icon(
                              onPressed: ctrl.bulkLoading.value
                                  ? null
                                  : () => _showBulkConfirm(
                                      context, ctrl, roleCrew),
                              icon: ctrl.bulkLoading.value
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.equipSidebar),
                                    )
                                  : const Icon(Icons.checklist_outlined,
                                      size: 16),
                              label: Text(
                                'Bulk Mark (${ctrl.unmarkedCrewIn(roleCrew).length})',
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.equipSidebar),
                            )),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── List ─────────────────────────────────────────
                  if (baseCrew.isEmpty)
                    _emptyCard(_showWatchlist
                        ? 'No favourites yet.\nMark some as favourite from the crew list.'
                        : 'No ${spec.emptyNoun} found.')
                  else if (filtered.isEmpty)
                    _emptyCard('No results for "$_search"')
                  else
                    ...filtered.map((u) => _StaffRow(
                        user: u, ctrl: ctrl, editable: spec.allowBulk)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _emptyCard(String message) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

// ── All / Favorites toggle ──────────────────────────────────────────────────────
class _FavoritesToggle extends StatelessWidget {
  final bool showWatchlist;
  final VoidCallback onAll;
  final VoidCallback onFavorites;
  const _FavoritesToggle({
    required this.showWatchlist,
    required this.onAll,
    required this.onFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              _seg(label: 'All', selected: !showWatchlist, onTap: onAll),
              _seg(
                  label: 'Favorites',
                  icon: Icons.star_rounded,
                  selected: showWatchlist,
                  onTap: onFavorites),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _seg({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
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
                    Icon(icon,
                        size: 14,
                        color: selected
                            ? AppColors.equipSidebar
                            : AppColors.mutedText),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.equipSidebar
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              color: selected ? AppColors.equipSidebar : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk mark confirmation ──────────────────────────────────────────────────────
void _showBulkConfirm(BuildContext context, EquipAttendanceController ctrl,
    List<Map<String, dynamic>> subset) {
  final types = ctrl.attendanceTypes;
  final presentType = types.firstWhereOrNull((t) =>
      (t['name'] as String? ?? '').toLowerCase().contains('present') &&
      !(t['name'] as String? ?? '').toLowerCase().contains('half'));

  if (presentType == null) {
    FerosSnackbar.error('Attendance types not loaded');
    return;
  }

  final count = ctrl.unmarkedCrewIn(subset).length;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Bulk Mark Present',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      content: Text(
        'Mark all $count unmarked as Present?',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(
                  fontFamily: 'Inter', color: AppColors.mutedText)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok =
                await ctrl.markBulkPresent(presentType['id'] as int, subset);
            if (ok) {
              FerosSnackbar.success('$count marked present');
            } else {
              FerosSnackbar.error('Bulk mark failed');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.equipSidebar,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child:
              const Text('Mark Present', style: TextStyle(fontFamily: 'Inter')),
        ),
      ],
    ),
  );
}

// ── Tab 2: My Attendance ──────────────────────────────────────────────────────
class _MyAttendanceSelfTab extends StatefulWidget {
  final TabController tab;
  final int selfIndex;
  const _MyAttendanceSelfTab({required this.tab, required this.selfIndex});

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
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ctrl.fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.equipSidebar,
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
            color: AppColors.equipSidebar,
            onRefresh: ctrl.fetchAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                _buildTodayCard(context, ctrl, marked, todayRecord, dayStr),
                const SizedBox(height: 14),
                _buildStatsRow(ctrl),
                const SizedBox(height: 14),
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

          // ── FAB: mark own attendance ─────────────────────────
          if (_currentTab == widget.selfIndex && !marked)
            Positioned(
              bottom: 16,
              right: 16,
              child: Obx(() => FloatingActionButton.extended(
                    onPressed: ctrl.markLoading.value
                        ? null
                        : () => _showMarkBottomSheet(context, ctrl),
                    backgroundColor: AppColors.equipSidebar,
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
    final color  = marked ? AppColors.success : AppColors.warning;
    final bg     = color.withValues(alpha: 0.08);
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
                        type: todayRecord!['attendanceTypeName'] as String? ?? ''),
                    _ApprovalBadge(
                        status: todayRecord['approvalStatus'] as String? ?? ''),
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
      ('Leave',   ctrl.leave,   AppColors.equipSidebar),
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
                Text("Mark Today's Attendance",
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.equipSidebar)),
                const SizedBox(height: 4),
                Text(
                  _todayLabel(),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                _SelfieBox(
                    selfieFile: selfieFile,
                    disabled: ctrl.markLoading.value),
                const SizedBox(height: 12),
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
                            final presentType =
                                ctrl.attendanceTypes.firstWhereOrNull((t) {
                              final n =
                                  (t['name'] as String? ?? '').toLowerCase();
                              return n.contains('present') &&
                                  !n.contains('half');
                            });
                            if (presentType == null) return;
                            final ok = await ctrl.markAttendance(
                              typeId: presentType['id'] as int,
                              selfieFile: selfieFile.value,
                              remarks: remarks.text,
                            );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                              Get.snackbar('Success', 'Attendance marked',
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM);
                            } else if (!ok && context.mounted) {
                              Get.snackbar('Error', 'Failed to mark attendance',
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM);
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

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff Row (driver / cleaner / operator) ─────────────────────────────────────
class _StaffRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final EquipAttendanceController ctrl;
  final bool editable; // supervisor may (re)mark — operators only
  const _StaffRow(
      {required this.user, required this.ctrl, required this.editable});

  @override
  Widget build(BuildContext context) {
    final userId = user['id'];
    final name   = user['name'] as String? ?? '—';
    final phone  = user['phone'] as String? ?? '';

    return Obx(() {
      final record   = ctrl.recordForUser(userId);
      final typeName = record != null
          ? (record['attendanceTypeName'] as String? ?? '')
          : null;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: record != null
                ? _statusColor(typeName ?? '').withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.equipSidebar.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.bodySemiBold.copyWith(
                    color: AppColors.equipSidebar, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyMedium),
                  if (phone.isNotEmpty)
                    Text(phone,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            if (record != null)
              _StatusChip(
                  label: typeName ?? '',
                  onTap: editable
                      ? () => _showMarkSheet(context, userId as int, name)
                      : null)
            else
              Obx(() => ctrl.markLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.equipSidebar))
                  : GestureDetector(
                      onTap: () =>
                          _showMarkSheet(context, userId as int, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.equipSidebar,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Mark',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )),
          ],
        ),
      );
    });
  }

  Color _statusColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('present') && !n.contains('half')) return AppColors.success;
    if (n.contains('absent')) return AppColors.error;
    if (n.contains('half')) return AppColors.warning;
    if (n.contains('leave')) return AppColors.info;
    return AppColors.mutedText;
  }

  void _showMarkSheet(BuildContext context, int userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkSheet(
        userId: userId,
        userName: userName,
        ctrl: ctrl,
      ),
    );
  }
}

// ── Status chip (read-only, or tappable to re-mark when onTap given) ──────────
class _StatusChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _StatusChip({required this.label, this.onTap});

  Color _color(String name) {
    final n = name.toLowerCase();
    if (n.contains('present') && !n.contains('half')) return AppColors.success;
    if (n.contains('absent')) return AppColors.error;
    if (n.contains('half')) return AppColors.warning;
    if (n.contains('leave')) return AppColors.info;
    return AppColors.mutedText;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(label);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                  color: c, fontWeight: FontWeight.w600, fontSize: 11),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 10, color: c),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mark Sheet (operator) ─────────────────────────────────────────────────────
class _MarkSheet extends StatefulWidget {
  final int userId;
  final String userName;
  final EquipAttendanceController ctrl;
  const _MarkSheet(
      {required this.userId, required this.userName, required this.ctrl});

  @override
  State<_MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<_MarkSheet> {
  int? _selectedTypeId;
  int? _selectedLeaveTypeId;
  final _remarksCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types      = widget.ctrl.attendanceTypes;
    final leaveTypes = widget.ctrl.leaveTypes;
    final selectedTypeName = types
        .firstWhereOrNull((t) => t['id'] == _selectedTypeId)?['name']
        as String?;
    final isLeave = selectedTypeName != null &&
        selectedTypeName.toLowerCase().contains('leave');

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text('Mark Attendance',
                style:
                    AppTextStyles.bodyBold.copyWith(color: AppColors.bodyText)),
            const SizedBox(height: 4),
            Text(widget.userName,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 20),
            Text('Status',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.bodyText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                final id       = t['id'] as int;
                final name     = t['name'] as String? ?? '';
                final isActive = _selectedTypeId == id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTypeId = id;
                    if (!name.toLowerCase().contains('leave')) {
                      _selectedLeaveTypeId = null;
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.equipSidebar
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.equipSidebar
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      name,
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? Colors.white : AppColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (isLeave && leaveTypes.isNotEmpty) ...[
              const SizedBox(height: 14),
              FerosSelectField<Map<String, dynamic>>(
                label: 'Leave Type',
                title: 'Select Leave Type',
                hint: 'Select leave type',
                items: leaveTypes.toList(),
                itemLabel: (lt) => lt['name'] as String? ?? '',
                selectedDisplay: _selectedLeaveTypeId == null
                    ? null
                    : leaveTypes
                        .firstWhereOrNull(
                            (lt) => lt['id'] == _selectedLeaveTypeId)
                        ?['name'] as String?,
                onSelected: (lt) =>
                    setState(() => _selectedLeaveTypeId = lt['id'] as int),
              ),
            ],
            const SizedBox(height: 14),
            Text('Remarks (optional)',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.bodyText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksCtrl,
              maxLines: 2,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Any notes…',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.hintText),
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
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting || _selectedTypeId == null
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        final ok = await widget.ctrl.markForUser(
                          userId: widget.userId,
                          attendanceTypeId: _selectedTypeId!,
                          leaveTypeId: _selectedLeaveTypeId,
                          remarks: _remarksCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (ok) {
                            FerosSnackbar.success('Attendance marked');
                          } else {
                            FerosSnackbar.error('Failed to mark attendance');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.equipSidebar,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.equipSidebar.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save',
                        style: AppTextStyles.bodySemiBold
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Monthly record card (My Attendance tab) ───────────────────────────────────
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
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.equipSidebar.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(_dayNum(date),
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.equipSidebar, fontSize: 20)),
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
    try { return DateTime.parse(iso).day.toString().padLeft(2, '0'); }
    catch (_) { return '—'; }
  }

  String _monthShort(String iso) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    try { return m[DateTime.parse(iso).month - 1]; }
    catch (_) { return ''; }
  }
}

// ── Type / Approval badges ────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final c = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(type,
          style: AppTextStyles.caption
              .copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

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
    return Obx(() => GestureDetector(
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
                          onTap: disabled
                              ? null
                              : () => selfieFile.value = null,
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
                    ],
                  ),
          ),
        ));
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
  if (n.contains('LEAVE'))                           return AppColors.equipSidebar;
  return AppColors.mutedText;
}

(Color, IconData) _typeStyle(String name) {
  final n = name.toUpperCase();
  if (n.contains('PRESENT') && !n.contains('HALF')) {
    return (AppColors.success, Icons.check_circle_outline);
  }
  if (n.contains('ABSENT'))  return (AppColors.error,        Icons.cancel_outlined);
  if (n.contains('HALF'))    return (AppColors.warning,      Icons.timelapse_outlined);
  if (n.contains('LEAVE'))   return (AppColors.equipSidebar, Icons.beach_access_outlined);
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
