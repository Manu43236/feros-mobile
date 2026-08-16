import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_fuel_log_controller.dart';

class SupervisorFuelLogView extends GetView<SupervisorFuelLogController> {
  const SupervisorFuelLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        heroTag: 'fuel_log_fab',
        onPressed: () => _showFuelSheet(context),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const ShimmerList(count: 4);
        return RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.navy,
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              // ── Stats row ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatsRow(controller: controller),
              ),

              // ── Search + Filter ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: controller.searchCtrl,
                        onSubmitted: controller.onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Search vehicle, station…',
                          hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    controller.searchCtrl.clear();
                                    controller.onSearchChanged('');
                                  },
                                  child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                                )
                              : const SizedBox.shrink()),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.navy),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Filter chips
                      Obx(() => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filterOptions.map((opt) {
                            final selected = controller.filterMode.value == opt.$1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => controller.onFilterChanged(opt.$1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.navy : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: selected ? AppColors.navy : AppColors.border),
                                  ),
                                  child: Text(
                                    opt.$2,
                                    style: AppTextStyles.caption.copyWith(
                                      color: selected ? Colors.white : AppColors.bodyText,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              // ── List ────────────────────────────────────────────────────────
              controller.logs.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.local_gas_station_outlined,
                        title: 'lbl_no_fuel_logs'.tr,
                        subtitle: 'lbl_tap_add_fuel'.tr,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: Obx(() {
                        final loadingMore = controller.isLoadingMore.value;
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
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
                                child: _FuelLogCard(
                                  log: controller.logs[i],
                                  onEdit: (log) => _showFuelSheet(context, log: log),
                                  onDelete: (id) => _confirmDelete(context, id),
                                ),
                              );
                            },
                            childCount: controller.logs.length + (loadingMore ? 1 : 0),
                          ),
                        );
                      }),
                    ),
            ],
          ),
        );
      }),
    );
  }

  static const _filterOptions = [
    ('ALL',             'All'),
    ('FULL_TANK',       'Full Tank'),
    ('CASH',            'Cash'),
    ('COMPANY_ACCOUNT', 'Company A/C'),
    ('REIMBURSEMENT',   'Reimbursement'),
  ];

  Future<void> _showFuelSheet(BuildContext context, {Map<String, dynamic>? log}) async {
    if (log != null) {
      controller.prepareForEdit(log);
    } else {
      controller.resetForm();
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FuelSheet(controller: controller, ctx: ctx),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Fuel Log',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('This fuel log will be permanently deleted.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteLog(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final SupervisorFuelLogController controller;
  const _StatsRow({required this.controller});

  String _fmtRupee(double v) =>
      '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final mileage = controller.avgMileage;
    final stats = [
      (Icons.receipt_long_outlined,  const Color(0xFFF97316), 'Entries',      '${controller.totalCount.value}'),
      (Icons.local_gas_station,      const Color(0xFF3B82F6), 'Total Litres', '${controller.totalLitres.toStringAsFixed(0)} L'),
      (Icons.currency_rupee,         const Color(0xFF16A34A), 'Total Spent',  _fmtRupee(controller.totalSpent)),
      (Icons.speed_outlined,         const Color(0xFF8B5CF6), 'Avg Mileage',  mileage != null ? '${mileage.toStringAsFixed(1)} km/L' : '—'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(s.$1, size: 16, color: s.$2),
                  const SizedBox(height: 4),
                  Text(s.$4,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12, color: AppColors.navy, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(s.$3,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 9, color: AppColors.mutedText),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Fuel Log Card ──────────────────────────────────────────────────────────────
class _FuelLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;
  const _FuelLogCard({required this.log, required this.onEdit, required this.onDelete});

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw as String);
      final d  = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  Color _paymentColor(String? mode) {
    switch (mode) {
      case 'COMPANY_ACCOUNT': return const Color(0xFF3B82F6);
      case 'REIMBURSEMENT':   return const Color(0xFF8B5CF6);
      default:                return const Color(0xFF16A34A);
    }
  }

  String _paymentLabel(String? mode) {
    switch (mode) {
      case 'COMPANY_ACCOUNT': return 'Co. A/C';
      case 'REIMBURSEMENT':   return 'Reimburse';
      default:                return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    final litres    = (log['litresFilled']       as num?)?.toDouble();
    final cost      = (log['totalCost']          as num?)?.toDouble();
    final odm       = (log['odometerReading']    as num?)?.toDouble();
    final mileage   = (log['mileageKmPerLitre']  as num?)?.toDouble();
    final station   = log['fuelStationName']     as String?;
    final city      = log['fuelStationCity']     as String?;
    final isFullT   = log['isFullTank']          as bool? ?? false;
    final payment   = log['paymentMode']         as String?;
    final receipt   = log['receiptUrl']          as String?;
    final id        = (log['id']                 as num?)?.toInt() ?? 0;
    final payColor  = _paymentColor(payment);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          _badge('Full', const Color(0xFF166534), const Color(0xFFDCFCE7)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _badge(_paymentLabel(payment), payColor, payColor.withValues(alpha: 0.1)),
                        if (mileage != null) ...[
                          const SizedBox(width: 6),
                          Text('${mileage.toStringAsFixed(1)} km/L',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (station != null && station.isNotEmpty)
                      Text(
                        city != null && city.isNotEmpty ? '$station, $city' : station,
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      ),
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

          // ── Action row ──────────────────────────────────────────────────────
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (receipt != null && receipt.isNotEmpty)
                _actionBtn(
                  icon: Icons.receipt_outlined,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'View receipt',
                  onTap: () => launchUrl(Uri.parse(receipt),
                      mode: LaunchMode.externalApplication),
                ),
              _actionBtn(
                icon: Icons.edit_outlined,
                color: AppColors.navy,
                tooltip: 'Edit',
                onTap: () => onEdit(log),
              ),
              _actionBtn(
                icon: Icons.delete_outline,
                color: AppColors.error,
                tooltip: 'Delete',
                onTap: () => onDelete(id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ── Add / Edit Sheet ───────────────────────────────────────────────────────────
class _FuelSheet extends StatelessWidget {
  final SupervisorFuelLogController controller;
  final BuildContext ctx;
  const _FuelSheet({required this.controller, required this.ctx});

  static const _paymentModes = [
    ('CASH',            'Cash'),
    ('COMPANY_ACCOUNT', 'Company A/C'),
    ('REIMBURSEMENT',   'Reimbursement'),
  ];

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
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.editingId.value != null ? 'Edit Fuel Log' : 'btn_add_fuel_log'.tr,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 16),

            // Vehicle
            _SectionLabel('Vehicle *'),
            _VehicleDropdown(controller: controller),
            const SizedBox(height: 8),

            if (controller.selectedVehicleId.value != null && controller.tankCapacity != null)
              _TankInfoCard(
                tankCapacity: controller.tankCapacity!,
                currentFuel: controller.currentFuel ?? 0,
                maxFillable: controller.maxFillable!,
              ),
            const SizedBox(height: 12),

            // Date & Time
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
                if (date == null || !ctx.mounted) return;
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

            // Litres
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

            // Cost / litre
            _SectionLabel('Cost / Litre (₹) *'),
            _Field(
              ctrl: controller.costPerLitreCtrl,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              prefix: '₹',
              hint: 'e.g. 96.50',
              onChanged: (_) => controller.recalcTotal(),
            ),
            const SizedBox(height: 12),

            // Total cost + Odometer
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Total Cost (₹)'),
                      _Field(
                        ctrl: controller.totalCostCtrl,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                        prefix: '₹',
                        hint: 'Auto-calculated',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Odometer (km)'),
                      _Field(
                        ctrl: controller.odmCtrl,
                        keyboard: TextInputType.number,
                        suffix: 'km',
                        hint: 'e.g. 45820',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full tank toggle
            _FullTankToggle(controller: controller),
            const SizedBox(height: 12),

            // Payment mode
            _SectionLabel('Payment Mode'),
            Wrap(
              spacing: 8,
              children: _paymentModes.map((m) {
                final selected = controller.paymentMode.value == m.$1;
                return GestureDetector(
                  onTap: () => controller.paymentMode.value = m.$1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.navy : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(m.$2,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.navy : AppColors.bodyText,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Station name + City
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Fuel Station'),
                      _Field(
                        ctrl: controller.stationCtrl,
                        keyboard: TextInputType.text,
                        hint: 'e.g. HP Petrol Pump',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('City'),
                      _Field(
                        ctrl: controller.cityCtrl,
                        keyboard: TextInputType.text,
                        hint: 'e.g. Vizianagaram',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            _SectionLabel('Notes (Optional)'),
            TextField(
              controller: controller.notesCtrl,
              maxLines: 2,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Any additional notes…',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),

            // Receipt upload
            _SectionLabel('Receipt'),
            GestureDetector(
              onTap: controller.isUploadingReceipt.value
                  ? null
                  : controller.pickAndUploadReceipt,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.receiptUrl.value.isNotEmpty
                        ? AppColors.navy
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.receiptUrl.value.isNotEmpty
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      size: 18,
                      color: controller.receiptUrl.value.isNotEmpty
                          ? AppColors.navy
                          : AppColors.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: controller.isUploadingReceipt.value
                          ? Text('Uploading…',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
                          : controller.receiptUrl.value.isNotEmpty
                              ? Text('Receipt uploaded — tap to replace',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.navy))
                              : Text('Tap to upload receipt photo',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                    ),
                    if (controller.isUploadingReceipt.value)
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.navy),
                      ),
                    if (controller.receiptUrl.value.isNotEmpty &&
                        !controller.isUploadingReceipt.value)
                      GestureDetector(
                        onTap: () => controller.receiptUrl.value = '',
                        child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save / Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isAdding.value
                    ? null
                    : () async {
                        final ok = await controller.saveLog();
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
                    : Text(
                        controller.editingId.value != null ? 'Update' : 'btn_save'.tr,
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
  final SupervisorFuelLogController controller;
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
        hint: Text('Select vehicle',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
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
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return '$d  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
  final SupervisorFuelLogController controller;
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
