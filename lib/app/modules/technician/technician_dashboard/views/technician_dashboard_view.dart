import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../controllers/technician_dashboard_controller.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(dynamic d) {
  if (d == null) return '—';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
  } catch (_) {
    return d.toString();
  }
}

String _fmtDateTime(dynamic d) {
  if (d == null) return '—';
  try {
    return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(d.toString()));
  } catch (_) {
    return d.toString();
  }
}

Widget _taskChip(String status) {
  final cfg = <String, Map<String, dynamic>>{
    'ASSIGNED':        {'label': 'Assigned',  'color': AppColors.info},
    'IN_PROGRESS':     {'label': 'Working',   'color': AppColors.warning},
    'MECHANIC_CLOSED': {'label': 'Closed',    'color': const Color(0xFF7C3AED)},
    'COMPLETED':       {'label': 'Done',      'color': AppColors.success},
  };
  final c = cfg[status] ?? {'label': status, 'color': AppColors.mutedText};
  final color = c['color'] as Color;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      c['label'] as String,
      style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w600, fontSize: 11),
    ),
  );
}

// ── Main view ─────────────────────────────────────────────────────────────────

class TechnicianDashboardView extends GetView<TechnicianDashboardController> {
  const TechnicianDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerCard(height: 120),
          )),
        );
      }

      final tasks = controller.tasks;

      return RefreshIndicator(
        onRefresh: controller.fetchTasks,
        color: AppColors.navy,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _StatsRow(controller: controller)),
            if (tasks.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _TaskCard(task: tasks[i], controller: controller),
                    childCount: tasks.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TechnicianDashboardController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Obx(() => Row(
        children: [
          _StatCard(label: 'Assigned',  value: controller.assignedCount,   color: AppColors.info),
          const SizedBox(width: 10),
          _StatCard(label: 'Working',   value: controller.inProgressCount,  color: AppColors.warning),
          const SizedBox(width: 10),
          _StatCard(label: 'Closed',    value: controller.closedCount,      color: const Color(0xFF7C3AED)),
        ],
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text('$value', style: AppTextStyles.heading2.copyWith(color: color, fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final TechnicianDashboardController controller;
  const _TaskCard({required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    final status   = task['status'] as String? ?? '';
    final taskId   = task['taskId'] as int;
    final taskName = task['displayName'] as String? ?? 'Task';
    final vehicle  = task['vehicleRegNumber'] as String? ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(taskName,
                          style: AppTextStyles.bodySemiBold
                              .copyWith(color: AppColors.navy)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.directions_bus_outlined,
                            size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(vehicle,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ]),
                    ],
                  ),
                ),
                _taskChip(status),
              ],
            ),
          ),

          // ── Timing ──
          if (task['mechanicStartedAt'] != null || task['mechanicClosedAt'] != null) ...[
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(children: [
                if (task['mechanicStartedAt'] != null) ...[
                  const Icon(Icons.play_circle_outline, size: 13, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text('Started: ${_fmtDateTime(task['mechanicStartedAt'])}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                ],
                if (task['mechanicStartedAt'] != null && task['mechanicClosedAt'] != null)
                  const SizedBox(width: 12),
                if (task['mechanicClosedAt'] != null) ...[
                  const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text('Closed: ${_fmtDateTime(task['mechanicClosedAt'])}',
                      style: AppTextStyles.caption.copyWith(color: Color(0xFF7C3AED))),
                ],
              ]),
            ),
          ],

          // ── Parts ──
          if ((task['parts'] as List?)?.isNotEmpty == true) ...[
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parts', style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...(task['parts'] as List).cast<Map<String, dynamic>>().map((p) {
                    final pStatus = (p['status'] as String?) ?? '';
                    final statusColor = pStatus == 'APPROVED'
                        ? AppColors.success
                        : pStatus == 'REJECTED'
                            ? AppColors.error
                            : AppColors.warning;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${p['partName'] ?? '—'}${p['partNumber'] != null ? '  ${p['partNumber']}' : ''}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.navy, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('×${p['quantityRequested'] ?? 1}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(pStatus,
                                style: AppTextStyles.caption.copyWith(
                                    color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Actions ──
          if (status == 'ASSIGNED' || status == 'IN_PROGRESS') ...[
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  // Request Part
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRequestPartSheet(context, taskId),
                      icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                      label: const Text('Request Part'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Primary action
                  Expanded(
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isActing.value
                          ? null
                          : () async {
                              if (status == 'ASSIGNED') {
                                await controller.startTask(taskId);
                              } else {
                                await controller.closeTask(taskId);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'ASSIGNED'
                            ? AppColors.info
                            : AppColors.warning,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      child: controller.isActing.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(status == 'ASSIGNED' ? 'Start Task' : 'Close Task'),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRequestPartSheet(BuildContext context, int taskId) {
    final searchCtrl = TextEditingController();
    final qtyCtrl    = TextEditingController(text: '1');
    Map<String, dynamic>? selectedPart;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          final allParts = controller.spareParts;
          final q = searchCtrl.text.toLowerCase();
          final filtered = allParts.where((p) {
            final name = (p['name'] as String? ?? '').toLowerCase();
            final num  = (p['partNumber'] as String? ?? '').toLowerCase();
            return q.isEmpty || name.contains(q) || num.contains(q);
          }).toList();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Request Spare Part',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                  const Spacer(),
                  IconButton(onPressed: Get.back, icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDec('Search parts…').copyWith(
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.28,
                  ),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No parts found')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final isSelected = selectedPart?['id'] == p['id'];
                            return GestureDetector(
                              onTap: () => setState(() => selectedPart = p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.navy.withValues(alpha: 0.06)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? AppColors.navy : const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'] as String? ?? '—',
                                            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                                        if (p['partNumber'] != null)
                                          Text(p['partNumber'] as String,
                                              style: AppTextStyles.caption
                                                  .copyWith(color: AppColors.mutedText)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.navy, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDec('Quantity'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedPart == null ? null : () async {
                      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                      Get.back();
                      await controller.requestPart(
                          taskId: taskId,
                          sparePartId: selectedPart!['id'] as int,
                          quantity: qty);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit Request',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}

InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
    );

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build_circle_outlined, size: 56, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No tasks assigned',
              style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
          const SizedBox(height: 8),
          Text('You have no active tasks right now',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
