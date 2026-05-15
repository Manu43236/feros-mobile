import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/pulsing_dot.dart';
import '../controllers/supervisor_active_trips_controller.dart';
import '../../supervisor_lrs/controllers/supervisor_lr_detail_controller.dart';
import '../../supervisor_lrs/views/supervisor_lr_detail_view.dart';

class SupervisorActiveTripsTab extends GetView<SupervisorActiveTripsController> {
  const SupervisorActiveTripsTab({super.key});

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
              Text('Failed to load active trips',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetchTrips,
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
      if (controller.lrs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 52, color: AppColors.mutedText),
              const SizedBox(height: 12),
              Text('No active trips',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              Text('In-transit LRs will appear here',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: controller.fetchTrips,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: controller.lrs.length,
          itemBuilder: (_, i) => _ActiveTripCard(
              lr: controller.lrs[i],
              onTap: () {
                final id = controller.lrs[i]['id'] as int?;
                if (id == null) return;
                Get.to(
                  () => const SupervisorLrDetailView(),
                  arguments: id,
                  binding: BindingsBuilder(() {
                    Get.put(SupervisorLrDetailController());
                  }),
                );
              }),
        ),
      );
    });
  }
}

// ── Active Trip Card ───────────────────────────────────────────────────────────
class _ActiveTripCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  final VoidCallback onTap;
  const _ActiveTripCard({required this.lr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lrNumber   = lr['lrNumber']                  as String? ?? '—';
    final vehicle    = lr['vehicleRegistrationNumber'] as String? ?? '—';
    final vehicleType= lr['vehicleTypeName']           as String?;
    final fromCity   = lr['fromCity']                  as String? ?? '—';
    final toCity     = lr['toCity']                    as String? ?? '—';
    final weight     = lr['allocatedWeight'];
    final driver     = lr['startedByName']             as String?;
    final lrDate     = lr['lrDate']                    as String?;
    final client     = lr['clientName']                as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping,
                        size: 17, color: AppColors.lrInTransit),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicle,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 6, right: 10, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lrInTransit.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.lrInTransit.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PulsingDot(
                              color: AppColors.lrInTransit, size: 6),
                          const SizedBox(width: 4),
                          Text('In Transit',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.lrInTransit,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (vehicleType != null) ...[
                  const SizedBox(height: 2),
                  Text(vehicleType,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                const SizedBox(height: 4),
                Text(
                  '#${lrNumber.toLowerCase()}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, letterSpacing: 0.4),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client
                if (client != null) ...[
                  Text(client,
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.mutedText),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                ],

                // Route
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 12, color: AppColors.navy),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(fromCity,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.bodyText),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,
                        size: 12, color: AppColors.mutedText),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(toCity,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.bodyText),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),

                // Footer row: meta
                Row(
                  children: [
                    if (weight != null) ...[
                      _Meta(Icons.scale_outlined, '${weight}T'),
                      const SizedBox(width: 12),
                    ],
                    if (driver != null) ...[
                      _Meta(Icons.person_outline, driver),
                      const SizedBox(width: 12),
                    ],
                    if (lrDate != null)
                      _Meta(Icons.calendar_today_outlined,
                          FerosDateUtils.formatDate(lrDate)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────
class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}
