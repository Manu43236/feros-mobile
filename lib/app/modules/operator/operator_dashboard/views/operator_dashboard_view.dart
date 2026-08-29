import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/operator_dashboard_controller.dart';
import '../../../driver/driver_attendance/views/driver_attendance_sheet.dart';
import 'log_session_sheet.dart';

class OperatorDashboardView extends GetView<OperatorDashboardController> {
  const OperatorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.state.value == ViewState.loading) {
        return const ShimmerList(count: 3);
      }
      if (controller.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.mutedText),
              const SizedBox(height: 12),
              Text('Could not load data',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.fetch,
        color: AppColors.navy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AttendanceBanner(ctrl: controller),
            const SizedBox(height: 16),
            _MachineCard(ctrl: controller),
            const SizedBox(height: 16),
            _SessionsSection(ctrl: controller),
          ],
        ),
      );
    });
  }
}

// ── Attendance Banner ─────────────────────────────────────────────────────────
class _AttendanceBanner extends StatelessWidget {
  final OperatorDashboardController ctrl;
  const _AttendanceBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isAttendanceIn.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Text('Attendance marked — you\'re in',
                  style: AppTextStyles.body.copyWith(color: const Color(0xFF15803D))),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark Attendance',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('You haven\'t marked in yet today',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => showMarkAttendanceSheet(
                  context,
                  onMarked: ctrl.fetchAttendanceStatus,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Machine Card ──────────────────────────────────────────────────────────────
class _MachineCard extends StatelessWidget {
  final OperatorDashboardController ctrl;
  const _MachineCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final a = ctrl.assignment.value;
      if (a == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.construction_outlined, size: 40, color: AppColors.mutedText),
              const SizedBox(height: 8),
              Text('No machine assigned today',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedText)),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.construction, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${a['equipmentType'] ?? ''} · ${a['equipmentNumber'] ?? ''}',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Active',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${a['clientName'] ?? ''}',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if ((a['siteName'] as String?) != null && (a['siteName'] as String).isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(a['siteName'] as String,
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ],
            if (ctrl.totalHmrToday.value != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Today: ${ctrl.totalHmrToday.value!.toStringAsFixed(1)} hrs',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Sessions Section ──────────────────────────────────────────────────────────
class _SessionsSection extends StatelessWidget {
  final OperatorDashboardController ctrl;
  const _SessionsSection({required this.ctrl});

  void _openSheet(BuildContext context) {
    final open = ctrl.openSession;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => open != null
          ? LogSessionSheet(sessionId: (open['id'] as num?)?.toInt())
          : LogSessionSheet(prefillStartHmr: ctrl.lastKnownHmr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sessions = ctrl.sessions;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Sessions",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
              Text('${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text('No sessions logged yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ),
            )
          else
            ...sessions.map((s) => _SessionCard(session: s, ctrl: ctrl)),
          const SizedBox(height: 12),
          if (ctrl.assignment.value != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _openSheet(context),
                icon: Icon(
                  ctrl.hasOpenSession ? Icons.stop_circle_outlined : Icons.add_circle_outline,
                  size: 20,
                ),
                label: Text(ctrl.hasOpenSession ? 'Close Open Session' : '+ Log New Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ctrl.hasOpenSession ? AppColors.orange : AppColors.navy,
                  side: BorderSide(
                      color: ctrl.hasOpenSession ? AppColors.orange : AppColors.navy),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final OperatorDashboardController ctrl;

  const _SessionCard({required this.session, required this.ctrl});

  String _time(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isOpen  = session['isOpen'] == true;
    final delta   = (session['hmrDelta'] as num?)?.toDouble();
    final startHmr = (session['startHmr'] as num?)?.toStringAsFixed(1) ?? '—';
    final endHmr   = (session['endHmr'] as num?)?.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOpen ? AppColors.orange.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_time(session['startTime'] as String?)} → '
                  '${isOpen ? 'ongoing' : _time(session['endTime'] as String?)}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  '$startHmr hrs → ${endHmr ?? '—'} hrs'
                  '${delta != null ? '  (Δ${delta.toStringAsFixed(1)})' : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                ),
                if (session['fuelConsumed'] != null) ...[
                  const SizedBox(height: 2),
                  Text('Fuel: ${session['fuelConsumed']} L',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
              ],
            ),
          ),
          if (isOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('OPEN',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.orange, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
