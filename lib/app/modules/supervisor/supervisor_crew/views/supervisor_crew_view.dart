import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/avatar_widget.dart';
import '../controllers/supervisor_crew_controller.dart';
import 'supervisor_crew_detail_view.dart';
import '../../../../../core/widgets/shimmer_card.dart';

class SupervisorCrewView extends GetView<SupervisorCrewController> {
  final bool embedded;
  final bool watchlistOnly;
  const SupervisorCrewView({super.key, this.embedded = false, this.watchlistOnly = false});

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          'lbl_drivers_cleaners'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
        children: [
          // ── Search + Filter button ──────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearch,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'lbl_search_crew'.tr,
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                        borderSide: const BorderSide(
                          color: AppColors.navy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final active = controller.roleFilter.value != 'ALL' ||
                      controller.statusFilter.value != 'ALL';
                  return GestureDetector(
                    onTap: () => _showFilterSheet(controller),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.navy
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? AppColors.navy
                                  : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: active ? Colors.white : AppColors.mutedText,
                          ),
                        ),
                        if (active)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF97316),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.state.value == ViewState.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ShimmerList(count: 6, itemHeight: 72),
                );
              }
              if (controller.state.value == ViewState.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'lbl_failed_staff'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchCrew,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('btn_retry'.tr),
                      ),
                    ],
                  ),
                );
              }

              final list = watchlistOnly
                  ? controller.watchlistCrew
                  : controller.crew;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        watchlistOnly
                            ? Icons.star_border_rounded
                            : Icons.badge_outlined,
                        size: 52,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        watchlistOnly
                            ? 'No drivers or cleaners in watchlist'
                            : 'lbl_no_staff_found'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      if (watchlistOnly) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add staff',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.navy,
                onRefresh: controller.fetchCrew,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final uid = list[i]['id'] as int?;
                    return _CrewCard(
                      member: list[i],
                      controller: controller,
                      attendanceStatus: uid != null
                          ? controller.attendanceStatus[uid]
                          : null,
                    );
                  },
                ),
              );
            }),
          ),
        ],
    );
  }
}

void _showFilterSheet(SupervisorCrewController c) {
  Get.bottomSheet(
    Obx(() {
      final roleOpts = [
        _RF('ALL', 'All', null),
        _RF('DRIVER', 'Drivers', c.driverCount),
        _RF('CLEANER', 'Cleaners', c.cleanerCount),
      ];
      final statusOpts = [
        _RF('ALL', 'All', null),
        _RF('AVAILABLE', 'Available', c.availableCount),
        _RF('ON_TRIP', 'On Trip', c.onTripCount),
        _RF('INACTIVE', 'Inactive', null),
      ];
      final hasFilter = c.roleFilter.value != 'ALL' || c.statusFilter.value != 'ALL';

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (hasFilter)
                  GestureDetector(
                    onTap: () {
                      c.onRoleFilter('ALL');
                      c.onStatusFilter('ALL');
                    },
                    child: Text(
                      'Clear all',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Role
            Text(
              'Role',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roleOpts
                  .map((opt) => _FilterChip(
                        opt: opt,
                        selected: c.roleFilter.value == opt.key,
                        onTap: () => c.onRoleFilter(opt.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Status
            Text(
              'Status',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusOpts
                  .map((opt) => _FilterChip(
                        opt: opt,
                        selected: c.statusFilter.value == opt.key,
                        onTap: () => c.onStatusFilter(opt.key),
                        activeColor: _statusChipColor(opt.key),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _RF {
  final String key, label;
  final int? count;
  const _RF(this.key, this.label, this.count);
}

Color _statusChipColor(String key) {
  switch (key) {
    case 'AVAILABLE':
      return const Color(0xFF16A34A);
    case 'ON_TRIP':
      return const Color(0xFFEA580C);
    case 'INACTIVE':
      return const Color(0xFF9CA3AF);
    default:
      return AppColors.navy;
  }
}

class _FilterChip extends StatelessWidget {
  final _RF opt;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;
  const _FilterChip({
    required this.opt,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.navy;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              opt.label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.bodyText,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (opt.count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${opt.count}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.bodyText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _attendanceBorderColor(String? s) => switch (s) {
  'APPROVED' => const Color(0xFF16A34A),
  'PENDING'  => const Color(0xFFF59E0B),
  'REJECTED' => const Color(0xFFEF4444),
  _          => const Color(0xFFD1D5DB),
};

// ── Crew Card ─────────────────────────────────────────────────────────────────
class _CrewCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final SupervisorCrewController controller;
  final String? attendanceStatus;
  const _CrewCard({required this.member, required this.controller, this.attendanceStatus});

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '—';
    final phone = member['phone'] as String? ?? '';
    final role = member['role'] as String? ?? '';
    final designation = member['designationName'] as String?;
    final isActive = member['isActive'] as bool? ?? true;
    final isAssigned = member['isAssigned'] as bool? ?? false;
    final assignmentType = member['assignmentType'] as String?;
    final orderNum = member['activeOrderNumber'] as String?;
    final leaseNum = member['activeLeaseNumber'] as String?;
    final trips = member['completedTripsCount'] ?? 0;

    final photoUrl = member['profilePhotoUrl'] as String?;

    final (avatarBg, roleBg, roleText, roleColor) = role == 'DRIVER'
        ? (
            const Color(0xFF1E3A5F),
            const Color(0xFFEFF6FF),
            'role_driver'.tr,
            const Color(0xFF2563EB),
          )
        : (
            const Color(0xFF374151),
            const Color(0xFFF3F4F6),
            'role_cleaner'.tr,
            const Color(0xFF6B7280),
          );

    final (statusBg, statusColor, statusLabel) = !isActive
        ? (const Color(0xFFF3F4F6), const Color(0xFF9CA3AF), 'lbl_inactive'.tr)
        : isAssigned && assignmentType == 'LEASE'
        ? (const Color(0xFFF5F3FF), const Color(0xFF7C3AED), 'On Lease')
        : isAssigned
        ? (const Color(0xFFFFF7ED), const Color(0xFFEA580C), 'lbl_on_trip_chip'.tr)
        : (const Color(0xFFF0FDF4), const Color(0xFF16A34A), 'lbl_available'.tr);

    return GestureDetector(
      onTap: () => Get.to(
        () => SupervisorCrewDetailView(member: member),
        transition: Transition.cupertino,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarWidget(
                name: name,
                imageUrl: photoUrl,
                size: 44,
                bgColor: avatarBg,
                borderColor: _attendanceBorderColor(attendanceStatus),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + role badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Phone + designation
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 11,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          phone,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        if (designation != null) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '·',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              designation,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Trips count
                    Row(
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          size: 12,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (trips == 1
                              ? 'lbl_trips_count'
                              : 'lbl_trips_count_plural')
                              .trParams({'count': '$trips'}),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (isAssigned && assignmentType == 'LEASE' && leaseNum != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              leaseNum,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else if (isAssigned && orderNum != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              orderNum,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Call button
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.call,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                ),
              ],
              // Star button
              const SizedBox(width: 8),
              Obx(() {
                final intId = member['id'] is int
                    ? member['id'] as int
                    : int.tryParse(member['id'].toString()) ?? 0;
                final inWl = controller.watchlistedIds.contains(intId);
                return GestureDetector(
                  onTap: () => controller.toggleWatchlist(intId),
                  child: Icon(
                    inWl ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: inWl ? const Color(0xFFFBBF24) : AppColors.mutedText,
                    size: 22,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    )); // GestureDetector + Container
  }
}
