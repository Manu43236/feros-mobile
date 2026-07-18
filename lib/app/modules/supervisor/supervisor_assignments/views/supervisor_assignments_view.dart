import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/supervisor_assignments_controller.dart';

class SupervisorAssignmentsView extends StatefulWidget {
  const SupervisorAssignmentsView({super.key});

  @override
  State<SupervisorAssignmentsView> createState() => _SupervisorAssignmentsViewState();
}

class _SupervisorAssignmentsViewState extends State<SupervisorAssignmentsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final SupervisorAssignmentsController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.find<SupervisorAssignmentsController>();
    _tabs = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabs.index == 2) _c.fetchHistory();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assignments',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Vehicles'),
            Tab(text: 'Drivers'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar (hidden on History tab)
          if (_tabs.index != 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Obx(() => TextField(
                onChanged: (v) => _c.searchQuery.value = v,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search order, vehicle, name…',
                  hintStyle: AppTextStyles.hint,
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                  suffixIcon: _c.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: AppColors.mutedText),
                          onPressed: () => _c.searchQuery.value = '',
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
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
                ),
              )),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _VehicleTab(c: _c),
                _DriverTab(c: _c),
                _HistoryTab(c: _c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vehicle Assignments Tab ───────────────────────────────────────────────────
class _VehicleTab extends StatelessWidget {
  final SupervisorAssignmentsController c;
  const _VehicleTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.state.value == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (c.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.mutedText),
              const SizedBox(height: 8),
              const Text('Failed to load'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: c.fetchAssignments, child: const Text('Retry')),
            ],
          ),
        );
      }
      final rows = c.vehicleRows;
      if (rows.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.border),
              SizedBox(height: 8),
              Text('No vehicle assignments', style: TextStyle(color: AppColors.mutedText)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: c.fetchAssignments,
        color: AppColors.navy,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _VehicleRow(row: rows[i]),
        ),
      );
    });
  }
}

class _VehicleRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _VehicleRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final status = row['status'] as String;
    final driverCount = row['driverCount'] as int;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row['orderNumber'] as String,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
              ),
              _StatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(row['clientName'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.navy),
              const SizedBox(width: 4),
              Text(row['vehicle'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.scale_outlined, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('${row['weight']}T', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const Spacer(),
              driverCount > 0
                  ? _Chip('$driverCount driver${driverCount > 1 ? 's' : ''}', Colors.green)
                  : _Chip('No driver', Colors.amber),
            ],
          ),
          if (row['loadDate'] != null || row['assignedBy'] != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (row['loadDate'] != null) 'Load: ${row['loadDate']}',
                if (row['assignedBy'] != null) 'By: ${row['assignedBy']}',
              ].join('  ·  '),
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Driver Assignments Tab ────────────────────────────────────────────────────
class _DriverTab extends StatelessWidget {
  final SupervisorAssignmentsController c;
  const _DriverTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.state.value == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      final rows = c.driverRows;
      if (rows.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, size: 48, color: AppColors.border),
              SizedBox(height: 8),
              Text('No driver assignments', style: TextStyle(color: AppColors.mutedText)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: c.fetchAssignments,
        color: AppColors.navy,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _DriverRow(row: rows[i]),
        ),
      );
    });
  }
}

class _DriverRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _DriverRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final role = row['roleName'] as String;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  (row['staffName'] as String).isNotEmpty
                      ? (row['staffName'] as String)[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.caption.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['staffName'] as String,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      role,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              _StatusBadge(row['status'] as String),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(row['orderNumber'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.navy)),
              const SizedBox(width: 12),
              const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(row['vehicle'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
            ],
          ),
          if (row['assignedBy'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Assigned by: ${row['assignedBy']}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  final SupervisorAssignmentsController c;
  const _HistoryTab({required this.c});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  bool _showVehicle = true;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.c.historyState.value == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (widget.c.historyState.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.mutedText),
              const SizedBox(height: 8),
              const Text('Failed to load history'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () {
                widget.c.vehicleHistory.clear();
                widget.c.fetchHistory();
              }, child: const Text('Retry')),
            ],
          ),
        );
      }

      final items = _showVehicle ? widget.c.vehicleHistory : widget.c.staffHistory;
      return Column(
        children: [
          // Sub-tab toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _ToggleBtn(label: 'Vehicle', active: _showVehicle, onTap: () => setState(() => _showVehicle = true)),
                const SizedBox(width: 8),
                _ToggleBtn(label: 'Staff', active: !_showVehicle, onTap: () => setState(() => _showVehicle = false)),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.border),
                        SizedBox(height: 8),
                        Text('No history yet', style: TextStyle(color: AppColors.mutedText)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _showVehicle
                        ? _VehicleHistoryRow(row: items[i])
                        : _StaffHistoryRow(row: items[i]),
                  ),
          ),
        ],
      );
    });
  }
}

class _VehicleHistoryRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _VehicleHistoryRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final wasUnassigned = row['unassignedAt'] != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionBadge('Assigned', false),
              if (wasUnassigned) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 12, color: AppColors.mutedText),
                const SizedBox(width: 6),
                _ActionBadge('Unassigned', true),
              ],
              const Spacer(),
              Text(
                row['vehicleRegistrationNumber'] as String? ?? '—',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            row['orderNumber'] as String? ?? '—',
            style: AppTextStyles.caption.copyWith(color: AppColors.navy),
          ),
          Text(
            'By: ${row['assignedByName'] ?? '—'}  ·  ${_fmtDate(row['assignedAt'] as String?)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
          if (wasUnassigned)
            Text(
              'Removed by: ${row['unassignedByName'] ?? '—'}  ·  ${_fmtDate(row['unassignedAt'] as String?)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _StaffHistoryRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _StaffHistoryRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final wasUnassigned = row['unassignedAt'] != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionBadge('Assigned', false),
              if (wasUnassigned) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 12, color: AppColors.mutedText),
                const SizedBox(width: 6),
                _ActionBadge('Unassigned', true),
              ],
              const Spacer(),
              Text(
                '${row['userName'] ?? '—'} (${row['userRole'] ?? ''})',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            row['vehicleRegistrationNumber'] as String? ?? '—',
            style: AppTextStyles.caption.copyWith(color: AppColors.navy),
          ),
          Text(
            'By: ${row['assignedByName'] ?? '—'}  ·  ${_fmtDate(row['assignedAt'] as String?)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
          if (wasUnassigned)
            Text(
              'Removed by: ${row['unassignedByName'] ?? '—'}  ·  ${_fmtDate(row['unassignedAt'] as String?)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

String _fmtDate(String? iso) {
  if (iso == null) return '—';
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return iso.substring(0, 10);
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color {
    switch (status) {
      case 'ASSIGNED':    return Colors.blue;
      case 'IN_TRANSIT':  return Colors.amber.shade700;
      case 'DELIVERED':   return Colors.green;
      case 'PENDING':     return Colors.grey;
      default:            return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final String label;
  final bool isRemoved;
  const _ActionBadge(this.label, this.isRemoved);

  @override
  Widget build(BuildContext context) {
    final color = isRemoved ? AppColors.error : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}
