import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../controllers/service_men_tires_controller.dart';

class ServiceMenTiresView extends GetView<ServiceMenTiresController> {
  const ServiceMenTiresView({super.key});

  static const _removalReasons = [
    'ROTATION', 'WORN', 'PUNCTURE', 'DAMAGE', 'RETREAD', 'SCRAP', 'OTHER'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Tire Work',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vehicle Picker ────────────────────────────────
          FerosSelectField<Map<String, dynamic>>(
            label: 'Vehicle',
            title: 'Select Vehicle',
            hint: 'Search by registration…',
            isRequired: true,
            selectedDisplay: controller.selectedVehicle.value != null
                ? controller.selectedVehicle.value!['registrationNumber'] as String?
                : null,
            items: controller.vehicles,
            itemLabel: (v) =>
                '${v['registrationNumber'] ?? ''}'
                '${v['vehicleTypeName'] != null ? ' · ${v['vehicleTypeName']}' : ''}',
            onSelected: controller.selectVehicle,
            isLoading: controller.isLoadingVehicles.value,
            emptyMessage: 'No active vehicles found',
          ),
          const SizedBox(height: 20),

          // ── Positions ──────────────────────────────────────
          if (controller.selectedVehicle.value != null) ...[
            if (controller.isLoadingPositions.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.navy),
                ),
              )
            else if (controller.positions.isEmpty)
              _EmptyPositions()
            else ...[
              Text('Tire Positions',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.navy, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...controller.positions.map((pos) =>
                  _PositionCard(
                    position: pos,
                    controller: controller,
                    removalReasons: _removalReasons,
                  )),
            ],
          ],
        ],
      )),
    );
  }
}

// ── Position Card ─────────────────────────────────────────────────────────────
class _PositionCard extends StatelessWidget {
  final Map<String, dynamic> position;
  final ServiceMenTiresController controller;
  final List<String> removalReasons;

  const _PositionCard({
    required this.position,
    required this.controller,
    required this.removalReasons,
  });

  Map<String, dynamic>? get _fitting =>
      position['currentFitting'] as Map<String, dynamic>?;

  bool get _isFitted => _fitting != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Position icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isFitted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.circle_outlined,
              color: _isFitted ? AppColors.success : AppColors.mutedText,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Position info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position['positionCode'] ?? '—',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                if (_isFitted) ...[
                  Text(
                    _fitting!['tireSerialNumber'] ?? '—',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                  if (_fitting!['tireBrand'] != null)
                    Text(
                      _fitting!['tireBrand'],
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                    ),
                ] else
                  Text('Empty',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),

          // Action button
          if (_isFitted)
            TextButton(
              onPressed: () => _showRemoveSheet(context),
              child: Text('Remove',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
            )
          else
            TextButton(
              onPressed: () => _showFitSheet(context),
              child: Text('Fit Tire',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.navy, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  void _showFitSheet(BuildContext context) {
    Map<String, dynamic>? selectedTire;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              Text('Fit Tire — ${position['positionCode']}',
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 20),

              FerosSelectField<Map<String, dynamic>>(
                label: 'Available Tire',
                title: 'Select Tire',
                hint: 'Search by serial number…',
                isRequired: true,
                selectedDisplay: selectedTire != null
                    ? '${selectedTire!['serialNumber']} · ${selectedTire!['brand'] ?? ''}'
                    : null,
                items: controller.availableTires,
                itemLabel: (t) =>
                    '${t['serialNumber'] ?? ''}'
                    '${t['brand'] != null ? ' · ${t['brand']}' : ''}'
                    '${t['size'] != null ? ' (${t['size']})' : ''}',
                onSelected: (t) => setSheet(() => selectedTire = t),
                isLoading: controller.isLoadingTires.value,
                emptyMessage: 'No available tires in stock',
              ),
              const SizedBox(height: 20),

              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value || selectedTire == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await controller.fitTire(
                            vehicleId: controller.selectedVehicle.value!['id'] as int,
                            tireId: selectedTire!['id'] as int,
                            positionId: position['id'] as int,
                            fittedDate: DateTime.now().toIso8601String().substring(0, 10),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Confirm Fit',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveSheet(BuildContext context) {
    String selectedReason = removalReasons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              Text('Remove Tire — ${position['positionCode']}',
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              Text(
                _fitting?['tireSerialNumber'] ?? '',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 20),

              Text('Removal Reason',
                  style: AppTextStyles.label.copyWith(color: AppColors.navy)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: removalReasons.map((r) {
                  final active = selectedReason == r;
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedReason = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.navy
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r.replaceAll('_', ' '),
                        style: AppTextStyles.caption.copyWith(
                          color:
                              active ? Colors.white : AppColors.mutedText,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await controller.removeTire(
                            fittingId: _fitting!['id'] as int,
                            vehicleId:
                                controller.selectedVehicle.value!['id'] as int,
                            removalReason: selectedReason,
                            removedDate: DateTime.now()
                                .toIso8601String()
                                .substring(0, 10),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Confirm Remove',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPositions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.circle_outlined,
                size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('No tire positions configured for this vehicle',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}
