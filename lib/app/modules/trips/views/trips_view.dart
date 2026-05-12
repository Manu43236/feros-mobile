import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/feros_search_bar.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/utils/date_utils.dart';
import '../controllers/trips_controller.dart';
import '../models/trip_model.dart';
import 'trip_detail_view.dart';

class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripsController>(
      init: TripsController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('My Trips',
              style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // ── Search + Filters ───────────────────────────────
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FerosSearchBar(
                hint: 'Search by order, client, route…',
                onChanged: controller.onSearch,
              ),
            ),
            _FilterChips(controller: controller),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.state.value == ViewState.loading) {
                  return const ShimmerList(count: 5);
                }
                if (controller.state.value == ViewState.error) {
                  return ErrorState(
                    message: 'Failed to load trips',
                    onRetry: controller.fetchTrips,
                  );
                }
                if (controller.filteredTrips.isEmpty) {
                  return const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No trips found',
                    subtitle: 'No trips match your search or filter',
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.fetchTrips,
                  color: AppColors.navy,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: controller.filteredTrips.length,
                    itemBuilder: (_, i) => _TripCard(
                      trip: controller.filteredTrips[i],
                      onTap: () => Get.to(
                        () => TripDetailView(trip: controller.filteredTrips[i]),
                        transition: Transition.cupertino,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final TripsController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'All': 'All',
      'PENDING': 'Pending',
      'IN_TRANSIT': 'In Transit',
      'DELIVERED': 'Delivered',
      'CANCELLED': 'Cancelled',
    };
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(() => Row(
          children: controller.filters.map((f) {
            final isActive = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.navy : AppColors.border,
                    ),
                  ),
                  child: Text(
                    labels[f] ?? f,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? Colors.white : AppColors.mutedText,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trip.orderNumber,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                _StatusChip(status: trip.status),
              ],
            ),
            const SizedBox(height: 8),

            // Client name
            Text(trip.clientName,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 8),

            // Route
            Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 12, color: AppColors.navy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(trip.fromLocation,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 12, color: AppColors.mutedText),
                ),
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.navy),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(trip.toLocation,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),

            if (trip.scheduledDate != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(
                    FerosDateUtils.formatDate(trip.scheduledDate!),
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                  if (trip.vehicleNumber != null) ...[
                    const Spacer(),
                    const Icon(Icons.directions_bus_outlined, size: 12, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Text(trip.vehicleNumber!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'IN_TRANSIT':
        bg = const Color(0xFFEFF6FF); fg = AppColors.navy; label = 'In Transit'; break;
      case 'DELIVERED':
        bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A); label = 'Delivered'; break;
      case 'PENDING':
        bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706); label = 'Pending'; break;
      case 'CANCELLED':
        bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626); label = 'Cancelled'; break;
      default:
        bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText; label = status; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
