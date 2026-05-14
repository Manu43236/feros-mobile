import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/pulsing_dot.dart';
import '../controllers/supervisor_active_trips_controller.dart';

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
          itemBuilder: (_, i) => _ActiveTripCard(lr: controller.lrs[i]),
        ),
      );
    });
  }
}

// ── Active Trip Card ───────────────────────────────────────────────────────────
class _ActiveTripCard extends StatefulWidget {
  final Map<String, dynamic> lr;
  const _ActiveTripCard({required this.lr});

  @override
  State<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends State<_ActiveTripCard> {
  bool _expanded = false;

  SupervisorActiveTripsController get _ctrl =>
      Get.find<SupervisorActiveTripsController>();

  @override
  Widget build(BuildContext context) {
    final lrNumber   = widget.lr['lrNumber']                  as String? ?? '—';
    final vehicle    = widget.lr['vehicleRegistrationNumber'] as String? ?? '—';
    final vehicleType= widget.lr['vehicleTypeName']           as String?;
    final fromCity   = widget.lr['fromCity']                  as String? ?? '—';
    final toCity     = widget.lr['toCity']                    as String? ?? '—';
    final weight     = widget.lr['allocatedWeight'];
    final driver     = widget.lr['startedByName']             as String?;
    final lrDate     = widget.lr['lrDate']                    as String?;
    final client     = widget.lr['clientName']                as String?;
    final lrIdRaw    = widget.lr['id'];
    final lrId = lrIdRaw is int ? lrIdRaw : int.tryParse(lrIdRaw.toString()) ?? 0;

    return Container(
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

                // Footer row: meta + "Proofs" toggle
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
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (!_expanded) _ctrl.loadProofs(lrId);
                        setState(() => _expanded = !_expanded);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Photos',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Proofs section (expanded) ────────────────────────
                if (_expanded)
                  Obx(() {
                    _ctrl.proofsRefresher.value; // reactive dependency
                    if (_ctrl.isProofsLoading(lrId)) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.navy),
                          ),
                        ),
                      );
                    }
                    final proofs = _ctrl.proofsFor(lrId);
                    if (proofs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('No photos yet',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),
                        Text(
                          'Photos (${proofs.length})',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...proofs.map((p) => _ProofItem(proof: p)),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proof Item ────────────────────────────────────────────────────────────────
class _ProofItem extends StatelessWidget {
  final Map<String, dynamic> proof;
  const _ProofItem({required this.proof});

  @override
  Widget build(BuildContext context) {
    final imageUrl   = proof['imageUrl']       as String?;
    final userName   = proof['userName']       as String? ?? '—';
    final capturedAt = proof['capturedAt']     as String?;
    final isReviewed = proof['isReviewed']     as bool?   ?? false;
    final reviewedBy = proof['reviewedByName'] as String?;
    final remarks    = proof['reviewRemarks']  as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _ThumbPlaceholder(Icons.image_outlined),
                    errorWidget: (context, url, error) =>
                        _ThumbPlaceholder(Icons.broken_image_outlined),
                  )
                : _ThumbPlaceholder(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(userName,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.bodyText,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isReviewed
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isReviewed ? 'Checked' : 'Not Checked',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isReviewed
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                if (capturedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(FerosDateUtils.formatDateTime(capturedAt),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
                ],
                if (isReviewed && reviewedBy != null) ...[
                  const SizedBox(height: 2),
                  Text('By $reviewedBy',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(remarks,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  final IconData icon;
  const _ThumbPlaceholder(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.border,
      child: Icon(icon, size: 20, color: AppColors.mutedText),
    );
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
