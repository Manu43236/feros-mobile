import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/feros_search_bar.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/driver_trips_controller.dart';
import '../models/lr_model.dart';
import 'driver_trip_detail_view.dart';
import '../bindings/driver_trip_detail_binding.dart';

class DriverTripsView extends GetView<DriverTripsController> {
  const DriverTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search ──────────────────────────────────────────
        Container(
          color: AppColors.navy,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FerosSearchBar(
            hint: 'lbl_search_trips'.tr,
            onChanged: controller.onSearch,
          ),
        ),
        _FilterChips(controller: controller),

        // ── List ────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (controller.state.value == ViewState.loading) {
              return const ShimmerList(count: 5);
            }
            if (controller.state.value == ViewState.error) {
              return ErrorState(
                message: 'lbl_failed_load_trips'.tr,
                onRetry: controller.fetchLrs,
              );
            }
            if (controller.filteredLrs.isEmpty) {
              return EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'lbl_no_trips_found'.tr,
                subtitle: 'lbl_no_trips_match'.tr,
              );
            }
            return RefreshIndicator(
              onRefresh: controller.fetchLrs,
              color: AppColors.navy,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: controller.filteredLrs.length,
                itemBuilder: (_, i) {
                  final lr = controller.filteredLrs[i];
                  return _LrCard(
                    lr: lr,
                    onTap: () => Get.to(
                      () => const DriverTripDetailView(),
                      arguments: lr,
                      transition: Transition.cupertino,
                      binding: DriverTripDetailBinding(),
                    ),
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

// ── Filter Chips ──────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final DriverTripsController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'All':           'lbl_all'.tr,
      'CREATED':       'lbl_lr_created'.tr,
      'WEIGHT_LOADED': 'lbl_weight_loaded_chip'.tr,
      'IN_TRANSIT':    'status_in_transit'.tr,
      'DELIVERED':     'status_delivered'.tr,
      'CANCELLED':     'status_cancelled'.tr,
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
                    border: Border.all(color: isActive ? AppColors.navy : AppColors.border),
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

// ── LR Card ───────────────────────────────────────────────────────────────────
class _LrCard extends StatelessWidget {
  final LrModel lr;
  final VoidCallback onTap;
  const _LrCard({required this.lr, required this.onTap});

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
            // LR number + status
            Row(
              children: [
                Expanded(
                  child: Text(lr.lrNumber,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _LrStatusChip(status: lr.lrStatus),
              ],
            ),
            const SizedBox(height: 6),

            // Client name
            Text(lr.clientName,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 8),

            // Route
            Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 12, color: AppColors.navy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(lr.fromCity,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 12, color: AppColors.mutedText),
                ),
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.navy),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(lr.toCity,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Date + vehicle + weight
            Row(
              children: [
                const Icon(Icons.directions_bus_outlined, size: 12, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(lr.vehicleNumber,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const Spacer(),
                const Icon(Icons.scale_outlined, size: 12, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  lr.loadedWeight != null
                      ? '${lr.loadedWeight!.toStringAsFixed(1)}T ${'lbl_t_loaded'.tr}'
                      : '${lr.allocatedWeight.toStringAsFixed(1)}T ${'lbl_t_allocated'.tr}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── LR Status Chip ────────────────────────────────────────────────────────────
class _LrStatusChip extends StatelessWidget {
  final String status;
  const _LrStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status.toUpperCase()) {
      case 'CREATED':       bg = const Color(0xFFEFF6FF); fg = AppColors.navy;              label = 'lbl_lr_created'.tr;         break;
      case 'WEIGHT_LOADED': bg = const Color(0xFFF5F3FF); fg = const Color(0xFF7C3AED);     label = 'lbl_weight_loaded_chip'.tr; break;
      case 'IN_TRANSIT':    bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706);     label = 'status_in_transit'.tr;      break;
      case 'DELIVERED':     bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);     label = 'status_delivered'.tr;       break;
      case 'CANCELLED':     bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626);     label = 'status_cancelled'.tr;       break;
      default:              bg = const Color(0xFFF1F5F9); fg = AppColors.mutedText;         label = status;                      break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
