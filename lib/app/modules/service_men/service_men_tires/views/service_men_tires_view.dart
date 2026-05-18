import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../controllers/service_men_tires_controller.dart';

class ServiceMenTiresView extends StatefulWidget {
  const ServiceMenTiresView({super.key});

  @override
  State<ServiceMenTiresView> createState() => _ServiceMenTiresViewState();
}

class _ServiceMenTiresViewState extends State<ServiceMenTiresView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _ctrl = Get.find<ServiceMenTiresController>();

  static const _removalReasons = [
    'ROTATION', 'WORN', 'PUNCTURE', 'DAMAGE', 'RETREAD', 'SCRAP', 'OTHER'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab Bar ───────────────────────────────────────────
        Container(
          color: AppColors.navy,
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'lbl_tire_work'.tr),
              Tab(text: 'lbl_my_requests'.tr),
            ],
          ),
        ),
        // ── Body ─────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
          // ── Tab 1: Tire Work ───────────────────────────────
          Obx(() => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FerosSelectField<Map<String, dynamic>>(
                label: 'lbl_vehicle'.tr,
                title: 'lbl_select_vehicle'.tr,
                hint: 'lbl_search_reg_type'.tr,
                isRequired: true,
                selectedDisplay: _ctrl.selectedVehicle.value != null
                    ? _ctrl.selectedVehicle.value!['registrationNumber'] as String?
                    : null,
                items: _ctrl.vehicles,
                itemLabel: (v) =>
                    '${v['registrationNumber'] ?? ''}'
                    '${v['vehicleTypeName'] != null ? ' · ${v['vehicleTypeName']}' : ''}',
                onSelected: _ctrl.selectVehicle,
                isLoading: _ctrl.isLoadingVehicles.value,
                emptyMessage: 'lbl_no_active_vehicles'.tr,
              ),
              const SizedBox(height: 20),
              if (_ctrl.selectedVehicle.value != null) ...[
                if (_ctrl.isLoadingPositions.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  )
                else if (_ctrl.positions.isEmpty)
                  _EmptyPositions()
                else ...[
                  Text('lbl_tire_positions'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._ctrl.positions.map((pos) => _PositionCard(
                        position: pos,
                        controller: _ctrl,
                        removalReasons: _removalReasons,
                      )),
                ],
              ],
            ],
          )),

          // ── Tab 2: My Requests ─────────────────────────────
          _MyRequestsTab(controller: _ctrl),
        ],
      ),
        ),
      ],
    );
  }
}

// ── My Requests Tab ───────────────────────────────────────────────────────────
class _MyRequestsTab extends StatelessWidget {
  final ServiceMenTiresController controller;
  const _MyRequestsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMyRequests.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (controller.myTireRequests.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.fetchMyRequests,
          color: AppColors.navy,
          child: ListView(children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle_outlined,
                      size: 48, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text('lbl_no_tire_requests'.tr,
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.navy)),
                  const SizedBox(height: 6),
                  Text('lbl_submit_from_tire_tab'.tr,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
          ]),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.fetchMyRequests,
        color: AppColors.navy,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myTireRequests.length,
          itemBuilder: (ctx, i) =>
              _TireRequestCard(req: controller.myTireRequests[i]),
        ),
      );
    });
  }
}

class _TireRequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  const _TireRequestCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final status   = req['status'] as String? ?? 'PENDING';
    final vehicle  = req['vehicleRegistrationNumber'] as String? ?? '—';
    final position = req['positionCode'] as String? ?? '—';
    final notes    = req['notes'] as String?;
    final tire     = req['issuedTireSerialNumber'] as String?;
    final reason   = req['rejectionReason'] as String?;
    final createdAt = req['createdAt'] as String? ?? '';

    final (Color bg, Color fg, String label) = switch (status) {
      'APPROVED' => (const Color(0xFFF0FDF4), const Color(0xFF16A34A), 'APPROVED'),
      'REJECTED' => (const Color(0xFFFEF2F2), const Color(0xFFDC2626), 'REJECTED'),
      _ =>          (const Color(0xFFFFFBEB), const Color(0xFFD97706), 'PENDING'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(label,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                ),
                const Spacer(),
                Text(_formatDate(createdAt),
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.directions_bus_outlined,
                      size: 14, color: AppColors.mutedText),
                  const SizedBox(width: 6),
                  Text(vehicle,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.navy)),
                  const SizedBox(width: 8),
                  Text('· $position',
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ]),
                if (notes != null) ...[
                  const SizedBox(height: 6),
                  Text('${'lbl_notes'.tr}: $notes',
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
                if (status == 'APPROVED' && tire != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text('${'lbl_issued'.tr}: $tire',
                          style: AppTextStyles.caption
                              .copyWith(color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
                if (status == 'REJECTED' && reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.cancel_outlined,
                          size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${'lbl_reason'.tr}: $reason',
                            style: AppTextStyles.caption
                                .copyWith(color: const Color(0xFFDC2626))),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final min = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day} ${months[d.month]}, $h:$min $ampm';
    } catch (_) {
      return iso;
    }
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
                  Text('lbl_empty_position'.tr,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),

          // Action button
          if (_isFitted)
            TextButton(
              onPressed: () => _showRemoveSheet(context),
              child: Text('btn_remove'.tr,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
            )
          else
            TextButton(
              onPressed: () => _showFitSheet(context),
              child: Text('btn_fit_tire'.tr,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.navy, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  void _showFitSheet(BuildContext context) {
    Map<String, dynamic>? selectedTire;
    final currentOdo = controller.selectedVehicle.value?['currentOdometerReading'];
    final notesCtrl = TextEditingController();
    final tires     = controller.availableTires;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final needApproval = controller.requireTireApproval.value;
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
              Text(
                needApproval
                    ? '${'lbl_request_tire'.tr} — ${position['positionCode']}'
                    : '${'btn_fit_tire'.tr} — ${position['positionCode']}',
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 20),

              // ── Scenario 1: No tires in stock ──────────────────────────────
              if (tires.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.do_not_disturb_alt_outlined,
                            size: 48, color: AppColors.mutedText),
                        const SizedBox(height: 12),
                        Text(
                          'lbl_no_tires_in_stock'.tr,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'lbl_contact_store_keeper'.tr,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('btn_close'.tr),
                  ),
                ),
              ]

              // ── Scenario 2: Tires available + approval required ────────────
              else if (needApproval) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'lbl_tire_approval_info'.tr,
                          style: AppTextStyles.caption
                              .copyWith(color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Available tires (informational)
                Text('${'lbl_available_in_stock'.tr} (${tires.length})',
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tires.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final t = tires[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.circle_outlined,
                                size: 16, color: AppColors.mutedText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${t['serialNumber'] ?? ''}'
                                '${t['brand'] != null ? ' · ${t['brand']}' : ''}'
                                '${t['size'] != null ? ' (${t['size']})' : ''}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.bodyText),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Notes (optional)
                Text('lbl_notes_optional'.tr,
                    style: AppTextStyles.label.copyWith(color: AppColors.navy)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. preferred tire or urgency…',
                    hintStyle:
                        AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await controller.requestTire(
                              vehicleId:  controller.selectedVehicle.value!['id'] as int,
                              positionId: position['id'] as int,
                              notes:      notesCtrl.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
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
                        : Text('btn_submit_request'.tr,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white)),
                  ),
                )),
              ]

              // ── Scenario 3: Tires available + direct fit ───────────────────
              else ...[
                if (currentOdo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_outlined,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Current odometer: ${currentOdo.toString().replaceAll('.0', '')} km — will be recorded as fitted km',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                FerosSelectField<Map<String, dynamic>>(
                  label: 'lbl_available_tire'.tr,
                  title: 'lbl_select_tire'.tr,
                  hint: 'lbl_search_serial_number'.tr,
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
                  emptyMessage: 'lbl_no_available_tires'.tr,
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
                              fittedAtKm: currentOdo?.toDouble(),
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
                        : Text('btn_confirm_fit'.tr,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white)),
                  ),
                )),
              ],
            ],
          ),
        );
        },
      ),
    );
  }

  void _showRemoveSheet(BuildContext context) {
    String selectedReason = removalReasons.first;
    final currentOdo = controller.selectedVehicle.value?['currentOdometerReading'];
    final kmCtrl = TextEditingController(
      text: currentOdo != null ? currentOdo.toString().replaceAll('.0', '') : '',
    );

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
              Text('${'lbl_remove_tire'.tr} — ${position['positionCode']}',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(
                '${_fitting?['tireSerialNumber'] ?? ''}'
                '${_fitting?['tireBrand'] != null ? ' · ${_fitting!['tireBrand']}' : ''}',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 20),

              // ── Current Odometer ─────────────────────────
              Text('lbl_current_odometer_km'.tr,
                  style: AppTextStyles.label.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              TextField(
                controller: kmCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                decoration: InputDecoration(
                  hintText: 'e.g. 45000',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  suffixText: 'km',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                ),
              ),
              if (_fitting?['fittedAtKm'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${'lbl_fitted_at_km'.tr} ${_fitting!['fittedAtKm']} km',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                ),
              ],
              const SizedBox(height: 16),

              // ── Removal Reason ───────────────────────────
              Text('lbl_removal_reason'.tr,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.navy : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r.replaceAll('_', ' '),
                        style: AppTextStyles.caption.copyWith(
                          color: active ? Colors.white : AppColors.mutedText,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
                          final kmText = kmCtrl.text.trim();
                          if (kmText.isEmpty) {
                            return;
                          }
                          final km = double.tryParse(kmText);
                          Navigator.pop(context);
                          await controller.removeTire(
                            fittingId: _fitting!['id'] as int,
                            vehicleId: controller.selectedVehicle.value!['id'] as int,
                            removalReason: selectedReason,
                            removedDate: DateTime.now().toIso8601String().substring(0, 10),
                            removedAtKm: km,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('btn_confirm_remove'.tr,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
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
            Text('lbl_no_tire_positions'.tr,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}
