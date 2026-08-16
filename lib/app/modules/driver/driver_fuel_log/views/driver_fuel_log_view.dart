import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/driver_fuel_log_controller.dart';

class DriverFuelLogView extends GetView<DriverFuelLogController> {
  const DriverFuelLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Text('lbl_fuel_log'.tr,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: controller.isLoading.value
          ? const ShimmerList(count: 4)
          : RefreshIndicator(
              onRefresh: controller.fetchAll,
              color: AppColors.navy,
              child: controller.logs.isEmpty
                  ? EmptyState(
                      icon: Icons.local_gas_station_outlined,
                      title: 'lbl_no_fuel_logs'.tr,
                      subtitle: 'lbl_tap_add_fuel'.tr,
                    )
                  : Obx(() {
                      final loadingMore = controller.isLoadingMore.value;
                      return ListView.builder(
                        controller: controller.scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: controller.logs.length + (loadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == controller.logs.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.navy, strokeWidth: 2),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FuelLogCard(log: controller.logs[i]),
                          );
                        },
                      );
                    }),
            ),
    ));
  }

  Future<void> _showAddSheet(BuildContext context) async {
    await showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFuelSheet(controller: controller, ctx: ctx),
    );
  }
}

// ── Add Sheet ──────────────────────────────────────────────────────────────────
class _AddFuelSheet extends StatelessWidget {
  final DriverFuelLogController controller;
  final BuildContext ctx;
  const _AddFuelSheet({required this.controller, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
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

            // ── Vehicle selector ──────────────────────────────────────────
            _SectionLabel('Vehicle *'),
            _VehicleDropdown(controller: controller),
            const SizedBox(height: 8),

            // ── Tank info hint ────────────────────────────────────────────
            if (controller.selectedVehicleId.value != null && controller.tankCapacity != null)
              _TankInfoCard(
                tankCapacity: controller.tankCapacity!,
                currentFuel: controller.currentFuel ?? 0,
                maxFillable: controller.maxFillable!,
              ),

            const SizedBox(height: 12),

            // ── Date & Time ───────────────────────────────────────────────
            _SectionLabel('Fill Date & Time *'),
            _DateTimePickerRow(
              selected: controller.selectedDateTime.value,
              onTap: () async {
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: controller.selectedDateTime.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                    child: child!),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(controller.selectedDateTime.value),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                    child: child!),
                );
                if (time == null) return;
                controller.selectedDateTime.value = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute);
              },
            ),
            const SizedBox(height: 12),

            // ── Litres ────────────────────────────────────────────────────
            _SectionLabel(controller.maxFillable != null
                ? 'Litres Filled * (max ${controller.maxFillable!.toStringAsFixed(1)} L)'
                : 'Litres Filled *'),
            _Field(
              ctrl: controller.litresCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'L',
              hint: controller.maxFillable != null
                  ? 'Max ${controller.maxFillable!.toStringAsFixed(1)} L'
                  : 'e.g. 50',
              onChanged: (_) => controller.recalcTotal(),
            ),
            const SizedBox(height: 12),

            // ── Cost per litre ────────────────────────────────────────────
            _SectionLabel('Cost / Litre (₹) *'),
            _Field(
              ctrl: controller.costPerLitreCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              prefix: '₹',
              hint: 'e.g. 96.50',
              onChanged: (_) => controller.recalcTotal(),
            ),
            const SizedBox(height: 12),

            // ── Total Cost (auto-calculated) ──────────────────────────────
            _SectionLabel('Total Cost (₹)'),
            _Field(
              ctrl: controller.totalCostCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              prefix: '₹',
              hint: 'Auto-calculated',
            ),
            const SizedBox(height: 12),

            // ── Odometer ──────────────────────────────────────────────────
            _SectionLabel('Odometer (km)'),
            _Field(
              ctrl: controller.odmCtrl,
              keyboard: TextInputType.number,
              suffix: 'km',
              hint: 'e.g. 45820',
            ),
            const SizedBox(height: 12),

            // ── Full Tank toggle ──────────────────────────────────────────
            _FullTankToggle(controller: controller),
            const SizedBox(height: 12),

            // ── Station ───────────────────────────────────────────────────
            _SectionLabel('Fuel Station'),
            _Field(
              ctrl: controller.stationCtrl,
              keyboard: TextInputType.text,
              hint: 'e.g. HP Petrol Pump',
            ),
            const SizedBox(height: 20),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
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
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
        style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedText, fontWeight: FontWeight.w500)),
  );
}

class _VehicleDropdown extends StatelessWidget {
  final DriverFuelLogController controller;
  const _VehicleDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.vehicles
          .map((v) => DropdownMenuItem<int>(
                value: v['id'] as int,
                child: Text(v['registrationNumber'] as String? ?? '—',
                    style: AppTextStyles.body),
              ))
          .toList();

      return DropdownButtonFormField<int>(
        value: controller.selectedVehicleId.value,
        hint: Text('Select vehicle', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        items: options,
        onChanged: controller.onVehicleSelected,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.navy),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        isExpanded: true,
      );
    });
  }
}

class _TankInfoCard extends StatelessWidget {
  final double tankCapacity, currentFuel, maxFillable;
  const _TankInfoCard({
    required this.tankCapacity,
    required this.currentFuel,
    required this.maxFillable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_gas_station, size: 16, color: AppColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tank: ${tankCapacity.toStringAsFixed(0)} L  ·  Current: ${currentFuel.toStringAsFixed(0)} L  ·  Max: ${maxFillable.toStringAsFixed(1)} L',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimePickerRow extends StatelessWidget {
  final DateTime selected;
  final VoidCallback onTap;
  const _DateTimePickerRow({required this.selected, required this.onTap});

  String _fmt(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.mutedText),
            const SizedBox(width: 10),
            Text(_fmt(selected), style: AppTextStyles.body),
            const Spacer(),
            const Icon(Icons.edit, size: 14, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _FullTankToggle extends StatelessWidget {
  final DriverFuelLogController controller;
  const _FullTankToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: () => controller.onFullTankChanged(!controller.isFullTank.value),
      child: Row(
        children: [
          Checkbox(
            value: controller.isFullTank.value,
            onChanged: (v) => controller.onFullTankChanged(v ?? false),
            activeColor: AppColors.navy,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Text('Full Tank',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyText)),
          const SizedBox(width: 6),
          Text('(auto-fills max litres)',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        ],
      ),
    ));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final String? suffix;
  final String? prefix;
  final String? hint;
  final void Function(String)? onChanged;

  const _Field({
    required this.ctrl,
    required this.keyboard,
    this.suffix,
    this.prefix,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        suffixText: suffix,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// ── Fuel Log Card ──────────────────────────────────────────────────────────────
class _FuelLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _FuelLogCard({required this.log});

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw as String);
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  $h:$mi';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final litres   = (log['litresFilled']    as num?)?.toDouble();
    final cost     = (log['totalCost']       as num?)?.toDouble();
    final odm      = (log['odometerReading'] as num?)?.toDouble();
    final station  = log['fuelStationName']  as String?;
    final isFullT  = log['isFullTank']       as bool? ?? false;

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
                Row(
                  children: [
                    Text(
                      '${litres?.toStringAsFixed(1) ?? '—'} L  ·  ₹${cost?.toStringAsFixed(0) ?? '—'}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                    ),
                    if (isFullT) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Full', style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF166534), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                if (station != null && station.isNotEmpty)
                  Text(station,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                Text(_fmtDate(log['fillDate']),
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
