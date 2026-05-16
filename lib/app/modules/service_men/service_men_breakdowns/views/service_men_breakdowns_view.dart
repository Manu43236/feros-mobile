import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/shimmer_card.dart';
import '../controllers/service_men_breakdowns_controller.dart';
import '../../service_men_services/controllers/service_men_services_controller.dart';
import '../../service_men_services/views/service_men_service_detail_view.dart';

class ServiceMenBreakdownsView
    extends GetView<ServiceMenBreakdownsController> {
  const ServiceMenBreakdownsView({super.key});

  static const _filters = ['ALL', 'OPEN', 'IN_REPAIR', 'RESOLVED'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // ── Filter Chips ────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final active = controller.filter.value == f;
                  final count = f == 'ALL'
                      ? controller.breakdowns.length
                      : f == 'OPEN'
                          ? controller.openCount
                          : controller.breakdowns
                              .where((b) => b['status'] == f)
                              .length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.filter.value = f,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.navy
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filterLabel(f),
                              style: AppTextStyles.caption.copyWith(
                                color: active
                                    ? Colors.white
                                    : AppColors.mutedText,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (count > 0 && (f == 'OPEN' || f == 'IN_REPAIR')) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : AppColors.error.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$count',
                                    style: AppTextStyles.caption.copyWith(
                                      color: active
                                          ? Colors.white
                                          : AppColors.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────
          Expanded(
            child: controller.isLoading.value
                ? const ShimmerList(count: 6)
                : RefreshIndicator(
                    onRefresh: controller.fetchBreakdowns,
                    color: AppColors.navy,
                    child: controller.filtered.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.warning_amber_outlined,
                                        size: 48,
                                        color: AppColors.mutedText),
                                    const SizedBox(height: 12),
                                    Text('No breakdowns found',
                                        style: AppTextStyles.body.copyWith(
                                            color: AppColors.mutedText)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.filtered.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final b = controller.filtered[i];
                              return _BreakdownCard(
                                breakdown: b,
                                onLogService: () =>
                                    _showLogServiceSheet(context, b),
                                onViewService: () =>
                                    _navigateToLinkedService(b),
                              );
                            },
                          ),
                  ),
          ),
        ],
      );
    });
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'IN_REPAIR': return 'In Repair';
      case 'RESOLVED':  return 'Resolved';
      default:          return f[0] + f.substring(1).toLowerCase();
    }
  }

  void _navigateToLinkedService(Map<String, dynamic> b) {
    final svcCtrl = Get.find<ServiceMenServicesController>();
    final vehicleReg = b['vehicleRegistrationNumber'] as String?;

    // Find the active breakdown-triggered service for this vehicle
    final linked = svcCtrl.services.firstWhereOrNull(
      (s) =>
          s['triggeredBy'] == 'BREAKDOWN' &&
          s['vehicleRegistrationNumber'] == vehicleReg &&
          s['status'] != 'COMPLETED',
    );

    if (linked != null) {
      Get.to(() => ServiceMenServiceDetailView(service: linked));
    } else {
      // Services not cached yet — refresh and retry
      svcCtrl.fetchServices().then((_) {
        final fresh = svcCtrl.services.firstWhereOrNull(
          (s) =>
              s['triggeredBy'] == 'BREAKDOWN' &&
              s['vehicleRegistrationNumber'] == vehicleReg &&
              s['status'] != 'COMPLETED',
        );
        if (fresh != null) {
          Get.to(() => ServiceMenServiceDetailView(service: fresh));
        }
      });
    }
  }

  void _showLogServiceSheet(
      BuildContext context, Map<String, dynamic> b) {
    final vehicleId   = b['vehicleId']   as int?;
    final breakdownId = b['id']          as int?;
    if (vehicleId == null || breakdownId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogServiceSheet(
        vehicleReg:  b['vehicleRegistrationNumber'] as String? ?? '',
        vehicleId:   vehicleId,
        breakdownId: breakdownId,
        controller:  controller,
      ),
    );
  }
}

// ── Breakdown Card ─────────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  final VoidCallback onLogService;
  final VoidCallback onViewService;
  const _BreakdownCard({
    required this.breakdown,
    required this.onLogService,
    required this.onViewService,
  });

  @override
  Widget build(BuildContext context) {
    final status      = breakdown['status']    as String? ?? 'REPORTED';
    final type        = breakdown['breakdownType']     as String? ?? '';
    final duration    = breakdown['breakdownDuration'] as String? ?? '';
    final reason      = breakdown['reason']    as String? ?? '—';
    final notes       = breakdown['notes']     as String?;
    final location    = breakdown['location']  as String?;
    final orderNo     = breakdown['orderNumber'] as String?;
    final vehicleReg  = breakdown['vehicleRegistrationNumber'] as String? ?? '—';
    final dateRaw     = breakdown['breakdownDate'] as String?;

    final isOpen     = status != 'RESOLVED' && status != 'VEHICLE_REPLACED';
    final isInRepair = status == 'IN_REPAIR';
    final isResolved = status == 'RESOLVED' || status == 'VEHICLE_REPLACED';

    final statusColor = isInRepair
        ? const Color(0xFFC2410C)
        : isResolved
            ? AppColors.success
            : AppColors.error;
    final statusBg = isInRepair
        ? const Color(0xFFFFF7ED)
        : isResolved
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2);
    final statusLabel = isInRepair
        ? 'In Repair'
        : isResolved
            ? 'Resolved'
            : 'Open';

    String? fmtDate;
    if (dateRaw != null) {
      try {
        fmtDate = DateFormat('dd MMM yyyy, h:mm a')
            .format(DateTime.parse(dateRaw).toLocal());
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOpen
            ? Border.all(
                color: isInRepair
                    ? const Color(0xFFFED7AA)
                    : const Color(0xFFFECACA),
                width: 1.2)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  vehicleReg,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.navy),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Chips row ────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (type.isNotEmpty)
                _SmallChip(
                    label: type.replaceAll('_', ' '),
                    bg: const Color(0xFFF1F5F9),
                    fg: AppColors.bodyText),
              _SmallChip(
                  label: duration == 'SHORT' ? 'Minor' : 'Major',
                  bg: duration == 'SHORT'
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  fg: duration == 'SHORT'
                      ? AppColors.success
                      : AppColors.error),
            ],
          ),
          const SizedBox(height: 10),

          // ── Reason ───────────────────────────────────────────
          Text(reason,
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText)),
          if (notes != null) ...[
            const SizedBox(height: 4),
            Text(notes,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],

          // ── Meta row ─────────────────────────────────────────
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (fmtDate != null)
                _MetaItem(icon: Icons.calendar_today_outlined, text: fmtDate),
              if (location != null)
                _MetaItem(icon: Icons.location_on_outlined, text: location),
              if (orderNo != null)
                _MetaItem(icon: Icons.assignment_outlined, text: orderNo),
            ],
          ),

          // ── Action buttons ────────────────────────────────────
          if (!isResolved) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isInRepair
                  ? ElevatedButton.icon(
                      onPressed: onViewService,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          size: 16),
                      label: const Text('View Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF7ED),
                        foregroundColor: const Color(0xFFC2410C),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onLogService,
                      icon: const Icon(Icons.build_outlined, size: 16),
                      label: const Text('Log Service'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Log Service Bottom Sheet ───────────────────────────────────────────────────
class _LogServiceSheet extends StatefulWidget {
  final String vehicleReg;
  final int vehicleId;
  final int breakdownId;
  final ServiceMenBreakdownsController controller;

  const _LogServiceSheet({
    required this.vehicleReg,
    required this.vehicleId,
    required this.breakdownId,
    required this.controller,
  });

  @override
  State<_LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends State<_LogServiceSheet> {
  String _serviceType = 'INTERNAL';
  final _notesCtrl    = TextEditingController();
  bool _submitting    = false;

  static const _serviceTypes = [
    ('INTERNAL',    'Internal (Self)'),
    ('OEM_CENTER',  'OEM Center'),
    ('THIRD_PARTY', '3rd Party'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.build_outlined,
                  color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Log Service',
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Vehicle: ${widget.vehicleReg} · Triggered by breakdown',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 20),

          // Service Type
          Text('Service Type',
              style: AppTextStyles.label.copyWith(color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _serviceTypes.map((t) {
              final selected = _serviceType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _serviceType = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.navy
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppColors.navy
                            : AppColors.border),
                  ),
                  child: Text(t.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : AppColors.bodyText,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Notes
          Text('Notes (optional)',
              style: AppTextStyles.label.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the repair work planned…',
              hintStyle:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.navy),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.build_circle_outlined, size: 20),
              label: Text(
                _submitting ? 'Creating…' : 'Create Service Record',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
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
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final newService = await widget.controller.createServiceFromBreakdown(
      vehicleId:   widget.vehicleId,
      breakdownId: widget.breakdownId,
      serviceType: _serviceType,
      serviceDate: today,
      notes:       _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (newService != null) {
      // Refresh the services list so the new service appears there too
      if (Get.isRegistered<ServiceMenServicesController>()) {
        Get.find<ServiceMenServicesController>().fetchServices();
      }
      // Dismiss sheet then navigate to new service so they can start it
      Navigator.pop(context);
      Get.to(() => ServiceMenServiceDetailView(service: newService));
    }
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────
class _SmallChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SmallChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: fg, fontWeight: FontWeight.w500)),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(text,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}
