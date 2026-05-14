import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/supervisor_crew_controller.dart';

class SupervisorCrewView extends GetView<SupervisorCrewController> {
  const SupervisorCrewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Drivers & Cleaners',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: Get.back,
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: controller.onSearch,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search by name or phone…',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.mutedText, size: 20),
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
                  borderSide:
                      const BorderSide(color: AppColors.navy, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Role + Status filter chips ────────────────────────────
          Obx(() {
            if (controller.state.value != ViewState.success) {
              return const SizedBox.shrink();
            }
            final roleOptions = [
              _RF('ALL',     'All',      null),
              _RF('DRIVER',  'Drivers',  controller.driverCount),
              _RF('CLEANER', 'Cleaners', controller.cleanerCount),
            ];
            final statusOptions = [
              _RF('ALL',       'All',       null),
              _RF('AVAILABLE', 'Available', controller.availableCount),
              _RF('ON_TRIP',   'On Trip',   controller.onTripCount),
              _RF('INACTIVE',  'Inactive',  null),
            ];
            return Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: roleOptions
                          .map((opt) => _FilterChip(
                                opt: opt,
                                selected:
                                    controller.roleFilter.value == opt.key,
                                onTap: () =>
                                    controller.onRoleFilter(opt.key),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: statusOptions
                          .map((opt) => _FilterChip(
                                opt: opt,
                                selected:
                                    controller.statusFilter.value == opt.key,
                                onTap: () =>
                                    controller.onStatusFilter(opt.key),
                                activeColor: _statusChipColor(opt.key),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 1, color: AppColors.border),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
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
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load staff',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.mutedText)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchCrew,
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

              final list = controller.crew;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 52, color: AppColors.mutedText),
                      const SizedBox(height: 12),
                      Text('No staff found',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.mutedText)),
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
                  itemBuilder: (_, i) => _CrewCard(member: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RF {
  final String key, label;
  final int? count;
  const _RF(this.key, this.label, this.count);
}

Color _statusChipColor(String key) {
  switch (key) {
    case 'AVAILABLE': return const Color(0xFF16A34A);
    case 'ON_TRIP':   return const Color(0xFFEA580C);
    case 'INACTIVE':  return const Color(0xFF9CA3AF);
    default:          return AppColors.navy;
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
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (opt.count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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

// ── Crew Card ─────────────────────────────────────────────────────────────────
class _CrewCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _CrewCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final name        = member['name']             as String? ?? '—';
    final phone       = member['phone']            as String? ?? '';
    final role        = member['role']             as String? ?? '';
    final designation = member['designationName']  as String?;
    final isActive    = member['isActive']         as bool?   ?? true;
    final isAssigned  = member['isAssigned']       as bool?   ?? false;
    final orderNum    = member['activeOrderNumber'] as String?;
    final trips       = member['completedTripsCount'] ?? 0;

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final (avatarBg, roleBg, roleText, roleColor) = role == 'DRIVER'
        ? (
            const Color(0xFF1E3A5F),
            const Color(0xFFEFF6FF),
            'Driver',
            const Color(0xFF2563EB),
          )
        : (
            const Color(0xFF374151),
            const Color(0xFFF3F4F6),
            'Cleaner',
            const Color(0xFF6B7280),
          );

    final (statusBg, statusColor, statusLabel) = !isActive
        ? (
            const Color(0xFFF3F4F6),
            const Color(0xFF9CA3AF),
            'Inactive',
          )
        : isAssigned
            ? (
                const Color(0xFFFFF7ED),
                const Color(0xFFEA580C),
                'On Trip',
              )
            : (
                const Color(0xFFF0FDF4),
                const Color(0xFF16A34A),
                'Available',
              );

    return Container(
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
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
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
                              horizontal: 8, vertical: 2),
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
                        const Icon(Icons.phone_outlined,
                            size: 11, color: AppColors.mutedText),
                        const SizedBox(width: 3),
                        Text(phone,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                        if (designation != null) ...[
                          const SizedBox(width: 8),
                          const Text('·',
                              style: TextStyle(
                                  color: AppColors.mutedText, fontSize: 10)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(designation,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status + trips count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                        if (isAssigned && orderNum != null) ...[
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
                        const Spacer(),
                        const Icon(Icons.route_outlined,
                            size: 12, color: AppColors.mutedText),
                        const SizedBox(width: 3),
                        Text(
                          '$trips trip${trips != 1 ? 's' : ''}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
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
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.call,
                        color: AppColors.success, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
