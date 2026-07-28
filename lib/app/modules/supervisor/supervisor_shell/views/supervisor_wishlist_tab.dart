import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicles_binding.dart';
import '../../supervisor_vehicles/controllers/supervisor_vehicles_controller.dart';
import '../../supervisor_vehicles/views/supervisor_vehicles_view.dart';
import '../../supervisor_crew/bindings/supervisor_crew_binding.dart';
import '../../supervisor_crew/controllers/supervisor_crew_controller.dart';
import '../../supervisor_crew/views/supervisor_crew_view.dart';

class SupervisorWishlistTab extends StatefulWidget {
  const SupervisorWishlistTab({super.key});

  @override
  State<SupervisorWishlistTab> createState() => _SupervisorWishlistTabState();
}

class _SupervisorWishlistTabState extends State<SupervisorWishlistTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final SupervisorVehiclesController _vc;
  late final SupervisorCrewController _cc;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    SupervisorVehiclesBinding().dependencies();
    SupervisorCrewBinding().dependencies();
    _vc = Get.find<SupervisorVehiclesController>();
    _cc = Get.find<SupervisorCrewController>();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _onFabTap() {
    if (_tab.index == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _VehiclePickerSheet(controller: _vc),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CrewPickerSheet(controller: _cc),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // ── Tab bar ──────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  TabBar(
                    controller: _tab,
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.mutedText,
                    indicatorColor: AppColors.navy,
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Vehicles'),
                      Tab(text: 'Drivers & Cleaners'),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                ],
              ),
            ),

            // ── Full embedded views (watchlist mode) ─────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  SupervisorVehiclesView(embedded: true, watchlistOnly: true),
                  SupervisorCrewView(embedded: true, watchlistOnly: true),
                ],
              ),
            ),
          ],
        ),

        // ── FAB ──────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            onPressed: _onFabTap,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── Vehicle Picker Sheet (reg number only, no assignments) ───────────────────
class _VehiclePickerSheet extends StatefulWidget {
  final SupervisorVehiclesController controller;
  const _VehiclePickerSheet({required this.controller});

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _available {
    final notWishlisted = widget.controller.allVehicles.where((v) {
      final id = v['id'];
      final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      return !widget.controller.watchlistedIds.contains(intId);
    }).toList();
    if (_query.isEmpty) return notWishlisted;
    final q = _query.toLowerCase();
    return notWishlisted
        .where((v) => (v['registrationNumber'] as String? ?? '')
            .toLowerCase()
            .contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _available;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Add Vehicles to Watchlist',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.mutedText,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search by reg number…',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                    borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'All vehicles are already in your watchlist'
                            : 'No results for "$_query"',
                        style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 56, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final v = list[i];
                        final id = v['id'];
                        final intId =
                            id is int ? id : int.tryParse(id.toString()) ?? 0;
                        final reg = v['registrationNumber'] as String? ?? '—';

                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: AppColors.navy,
                            ),
                          ),
                          title: Text(
                            reg,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(
                            Icons.star_border_rounded,
                            color: AppColors.mutedText,
                            size: 20,
                          ),
                          onTap: () {
                            widget.controller.toggleWatchlist(intId);
                            setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crew Picker Sheet (name + role only, no assignments) ─────────────────────
class _CrewPickerSheet extends StatefulWidget {
  final SupervisorCrewController controller;
  const _CrewPickerSheet({required this.controller});

  @override
  State<_CrewPickerSheet> createState() => _CrewPickerSheetState();
}

class _CrewPickerSheetState extends State<_CrewPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _available {
    final notWishlisted = widget.controller.allCrew.where((u) {
      final id = u['id'];
      final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      return !widget.controller.watchlistedIds.contains(intId);
    }).toList();
    if (_query.isEmpty) return notWishlisted;
    final q = _query.toLowerCase();
    return notWishlisted
        .where((u) =>
            (u['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _available;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Add Staff to Watchlist',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.mutedText,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                    borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'All staff are already in your watchlist'
                            : 'No results for "$_query"',
                        style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 56, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final u = list[i];
                        final id = u['id'];
                        final intId =
                            id is int ? id : int.tryParse(id.toString()) ?? 0;
                        final name = u['name'] as String? ?? '—';
                        final role = u['role'] as String? ?? '';
                        final isDriver = role == 'DRIVER';

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: AppTextStyles.label.copyWith(color: AppColors.navy),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDriver
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isDriver ? 'Driver' : 'Cleaner',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDriver
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.star_border_rounded,
                            color: AppColors.mutedText,
                            size: 20,
                          ),
                          onTap: () {
                            widget.controller.toggleWatchlist(intId);
                            setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
