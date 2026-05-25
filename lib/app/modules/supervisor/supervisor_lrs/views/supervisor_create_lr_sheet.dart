import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/supervisor_lrs_controller.dart';

class SupervisorCreateLrSheet extends StatefulWidget {
  final SupervisorLrsController controller;
  const SupervisorCreateLrSheet({super.key, required this.controller});

  @override
  State<SupervisorCreateLrSheet> createState() =>
      _SupervisorCreateLrSheetState();
}

class _SupervisorCreateLrSheetState extends State<SupervisorCreateLrSheet> {
  Map<String, dynamic>? _selectedOrder;
  Map<String, dynamic>? _selectedAllocation;
  DateTime _lrDate = DateTime.now();

  final _weightCtrl      = TextEditingController();
  final _ewayBillNoCtrl  = TextEditingController();
  final _remarksCtrl     = TextEditingController();
  DateTime? _ewayBillDate, _ewayBillValidUpto;

  List<Map<String, dynamic>> get _allocations {
    if (_selectedOrder == null) return [];
    final raw = _selectedOrder!['vehicleAllocations'];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _ewayBillNoCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lrDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lrDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedAllocation == null) {
      Get.snackbar('Required', 'Please select a vehicle',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final allocationId = _selectedAllocation!['id'];
    final data = <String, dynamic>{
      'vehicleAllocationId': allocationId,
      'lrDate': _lrDate.toIso8601String().substring(0, 10),
    };
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w != null) data['loadedWeight'] = w;
    if (_ewayBillNoCtrl.text.trim().isNotEmpty)
      data['ewayBillNumber'] = _ewayBillNoCtrl.text.trim();
    if (_ewayBillDate != null)
      data['ewayBillDate'] = _ewayBillDate!.toIso8601String().substring(0, 10);
    if (_ewayBillValidUpto != null)
      data['ewayBillValidUpto'] = _ewayBillValidUpto!.toIso8601String().substring(0, 10);
    if (_remarksCtrl.text.trim().isNotEmpty) {
      data['remarks'] = _remarksCtrl.text.trim();
    }

    final ok = await widget.controller.createLr(data);
    if (ok && mounted) Navigator.of(context).pop();
  }

  String _dateLabel(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.controller.orders;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('btn_create_lr'.tr,
                      style: AppTextStyles.heading4
                          .copyWith(color: AppColors.navy)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // ── Order ─────────────────────────────────────────
                  _Label('${'lbl_order'.tr} *'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedOrder,
                    hint: Text('lbl_select_order'.tr,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.hintText)),
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: orders.map((o) {
                      final num = o['orderNumber'] as String? ?? '—';
                      final client = o['clientName'] as String? ?? '';
                      return DropdownMenuItem(
                        value: o,
                        child: Text(
                          '$num  ·  $client',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.bodyText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _selectedOrder = v;
                      _selectedAllocation = null;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Vehicle allocation ────────────────────────────
                  _Label('${'lbl_vehicle'.tr} *'),
                  const SizedBox(height: 6),
                  if (_selectedOrder == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('lbl_select_order_first'.tr,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.hintText)),
                    )
                  else if (_allocations.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                          'lbl_no_vehicles_assigned'.tr,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.warning)),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedAllocation,
                      hint: Text('lbl_select_vehicle_hint'.tr,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.hintText)),
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: _allocations.map((a) {
                        final reg = a['vehicleRegistrationNumber'] as String? ??
                            a['vehicleNumber'] as String? ?? '—';
                        final type = a['vehicleTypeName'] as String? ?? '';
                        return DropdownMenuItem(
                          value: a,
                          child: Text(
                            '$reg${type.isNotEmpty ? '  ·  $type' : ''}',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.bodyText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedAllocation = v);
                        if (v != null) {
                          final aw = v['allocatedWeight'];
                          if (aw != null) _weightCtrl.text = aw.toString();
                        }
                      },
                    ),
                  const SizedBox(height: 16),

                  // ── LR Date ───────────────────────────────────────
                  _Label('lbl_lr_date'.tr),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.mutedText),
                          const SizedBox(width: 10),
                          Text(_dateLabel(_lrDate),
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.bodyText)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Loaded weight ─────────────────────────────────
                  _Label('lbl_loaded_weight_tonnes'.tr),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.bodyText),
                    decoration: _inputDecoration().copyWith(
                      hintText: 'e.g. 10.5',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.hintText),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── E-way Bill ────────────────────────────────────
                  _Label('lbl_eway_bill'.tr + ' (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ewayBillNoCtrl,
                    style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                    decoration: _inputDecoration().copyWith(
                      hintText: 'EWB123456789',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('lbl_date'.tr),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _ewayBillDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setState(() => _ewayBillDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  _ewayBillDate != null ? _dateLabel(_ewayBillDate!) : 'Pick date',
                                  style: AppTextStyles.body.copyWith(
                                    color: _ewayBillDate != null ? AppColors.bodyText : AppColors.hintText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('lbl_valid_upto'.tr),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _ewayBillValidUpto ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.navy)),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setState(() => _ewayBillValidUpto = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  _ewayBillValidUpto != null ? _dateLabel(_ewayBillValidUpto!) : 'Pick date',
                                  style: AppTextStyles.body.copyWith(
                                    color: _ewayBillValidUpto != null ? AppColors.bodyText : AppColors.hintText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Remarks ───────────────────────────────────────
                  _Label('lbl_remarks'.tr),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarksCtrl,
                    maxLines: 3,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.bodyText),
                    decoration: _inputDecoration().copyWith(
                      hintText: 'lbl_optional_notes'.tr,
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.hintText),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit ────────────────────────────────────────
                  Obx(() => ElevatedButton(
                    onPressed: widget.controller.isCreating.value
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: widget.controller.isCreating.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'btn_create_lr'.tr,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
      );
}
