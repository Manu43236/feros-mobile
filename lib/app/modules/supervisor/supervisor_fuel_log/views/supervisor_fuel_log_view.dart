import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_fuel_log_controller.dart';

class SupervisorFuelLogView extends GetView<SupervisorFuelLogController> {
  const SupervisorFuelLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text('lbl_fuel_log'.tr,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: controller.isLoading.value
          ? const ShimmerList(count: 4)
          : RefreshIndicator(
              onRefresh: controller.fetch,
              color: AppColors.navy,
              child: controller.logs.isEmpty
                  ? EmptyState(
                      icon: Icons.local_gas_station_outlined,
                      title: 'lbl_no_fuel_logs'.tr,
                      subtitle: 'lbl_tap_add_fuel'.tr,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FuelLogCard(log: controller.logs[i]),
                    ),
            ),
    ));
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('btn_add_fuel_log'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
              const SizedBox(height: 16),
              _Field(label: 'lbl_litres_filled'.tr, ctrl: controller.litresCtrl,
                  keyboard: const TextInputType.numberWithOptions(decimal: true), suffix: 'L'),
              const SizedBox(height: 12),
              _Field(label: 'lbl_total_cost'.tr, ctrl: controller.costCtrl,
                  keyboard: const TextInputType.numberWithOptions(decimal: true), prefix: '₹'),
              const SizedBox(height: 12),
              _Field(label: 'lbl_odometer_reading'.tr, ctrl: controller.odmCtrl,
                  keyboard: TextInputType.number, suffix: 'km'),
              const SizedBox(height: 12),
              _Field(label: 'lbl_fuel_station'.tr, ctrl: controller.stationCtrl,
                  keyboard: TextInputType.text),
              const SizedBox(height: 20),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isAdding.value
                      ? null
                      : () async {
                          final ok = await controller.addLog();
                          if (ok && ctx.mounted) Navigator.of(ctx).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isAdding.value
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('btn_save'.tr,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fuel Log Card ──────────────────────────────────────────────────────────────
class _FuelLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _FuelLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final litres  = (log['litresFilled']    as num?)?.toDouble();
    final cost    = (log['totalCost']       as num?)?.toDouble();
    final odm     = (log['odometerReading'] as num?)?.toDouble();
    final station = log['fuelStationName']  as String?;
    final date    = log['fillDate']         as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_gas_station_outlined,
                color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${litres?.toStringAsFixed(1) ?? '—'} L  •  ₹${cost?.toStringAsFixed(0) ?? '—'}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                ),
                if (station != null && station.isNotEmpty)
                  Text(station,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                Text(date,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          if (odm != null)
            Text('${odm.toStringAsFixed(0)} km',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

// ── Field Helper ───────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final String? suffix;
  final String? prefix;
  const _Field({
    required this.label,
    required this.ctrl,
    required this.keyboard,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        suffixText: suffix,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      ),
    );
  }
}
