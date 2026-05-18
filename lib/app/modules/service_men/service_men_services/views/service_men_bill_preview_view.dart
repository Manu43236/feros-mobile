import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../controllers/service_men_services_controller.dart';

class ServiceMenBillPreviewView extends StatefulWidget {
  final Map<String, dynamic> service;
  const ServiceMenBillPreviewView({super.key, required this.service});

  @override
  State<ServiceMenBillPreviewView> createState() =>
      _ServiceMenBillPreviewViewState();
}

class _ServiceMenBillPreviewViewState extends State<ServiceMenBillPreviewView> {
  final _ctrl        = Get.find<ServiceMenServicesController>();
  final _odoCtrl     = TextEditingController();
  final _labourCtrl  = TextEditingController();
  final _vendorAmtCtrl    = TextEditingController();
  final _vendorInvCtrl    = TextEditingController();
  bool _submitting = false;

  bool get _isInternal =>
      (widget.service['serviceType'] as String? ?? '') == 'INTERNAL';

  List<Map<String, dynamic>> get _tasks =>
      (widget.service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  double get _tasksTotal => _tasks.fold(
      0.0, (s, t) => s + ((t['cost'] as num?)?.toDouble() ?? 0.0));

  double get _labour =>
      double.tryParse(_labourCtrl.text.trim()) ?? 0.0;

  double get _subTotal => _tasksTotal + _labour;

  // 18% default; real value comes from server — shown on bill after completion
  double get _gstAmount => _subTotal * 0.18;

  double get _total => _subTotal + _gstAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('lbl_bill_preview'.tr,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            Text(
              widget.service['serviceNumber'] ?? '',
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'Inter', fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Service Info ──────────────────────────────────────────
                _Section(
                  title: 'lbl_service_info'.tr,
                  child: Column(
                    children: [
                      _InfoRow('lbl_vehicle'.tr,
                          widget.service['vehicleRegistrationNumber'] ?? '—'),
                      _InfoRow('lbl_type'.tr,
                          _isInternal ? 'lbl_service_internal'.tr : (widget.service['vendorName'] as String? ?? 'lbl_external_vendor'.tr)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Odometer ─────────────────────────────────────────────
                _Section(
                  title: 'lbl_completion_details'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('lbl_odometer_optional'.tr,
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.navy)),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _odoCtrl,
                        hint: 'e.g. 45000 km',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_isInternal) ...[
                  // ── Tasks ───────────────────────────────────────────────
                  if (_tasks.isNotEmpty)
                    _Section(
                      title: 'lbl_work_performed'.tr,
                      child: Column(
                        children: [
                          ..._tasks.map((t) {
                            final name = t['displayName'] ??
                                t['customName'] ?? '—';
                            final cost =
                                (t['cost'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(name,
                                          style: AppTextStyles.body)),
                                  Text(
                                      cost > 0
                                          ? '₹${cost.toStringAsFixed(0)}'
                                          : '—',
                                      style: AppTextStyles.body.copyWith(
                                          color: AppColors.mutedText)),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('lbl_tasks_total'.tr,
                                  style: AppTextStyles.bodyMedium),
                              Text('₹${_tasksTotal.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_tasks.isNotEmpty) const SizedBox(height: 12),

                  // ── Labour Charges ───────────────────────────────────────
                  _Section(
                    title: 'lbl_labour_charges'.tr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('lbl_labour_optional'.tr,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.navy)),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _labourCtrl,
                          hint: 'e.g. 500',
                          prefix: '₹ ',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Cost Summary ─────────────────────────────────────────
                  _Section(
                    title: 'lbl_cost_summary'.tr,
                    child: Column(
                      children: [
                        _SummaryRow('lbl_tasks_total'.tr,
                            '₹${_tasksTotal.toStringAsFixed(2)}'),
                        _SummaryRow('lbl_labour_charges'.tr,
                            '₹${_labour.toStringAsFixed(2)}'),
                        _SummaryRow('lbl_sub_total'.tr,
                            '₹${_subTotal.toStringAsFixed(2)}'),
                        _SummaryRow('lbl_gst_18'.tr,
                            '₹${_gstAmount.toStringAsFixed(2)}'),
                        const Divider(height: 12),
                        _SummaryRow(
                          'lbl_estimated_total'.tr,
                          '₹${_total.toStringAsFixed(2)}',
                          highlight: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'lbl_gst_note'.tr,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ── External Vendor Details ──────────────────────────────
                  _Section(
                    title: 'lbl_vendor_bill'.tr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('lbl_vendor_charged_optional'.tr,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.navy)),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _vendorAmtCtrl,
                          hint: 'e.g. 8500',
                          prefix: '₹ ',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: 12),
                        Text('lbl_vendor_invoice_no_optional'.tr,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.navy)),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _vendorInvCtrl,
                          hint: 'e.g. VND-2026-001',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'lbl_vendor_gst_note'.tr,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Sticky confirm button ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _confirm,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _submitting ? 'lbl_completing'.tr : 'btn_confirm_complete'.tr,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final odo   = int.tryParse(_odoCtrl.text.trim());
    final updated = await _ctrl.completeService(
      widget.service['id'] as int,
      completedDate: today,
      odometer: odo,
      labourCharges: _isInternal
          ? double.tryParse(_labourCtrl.text.trim())
          : null,
      vendorAmount: !_isInternal
          ? double.tryParse(_vendorAmtCtrl.text.trim())
          : null,
      vendorInvoiceNo: !_isInternal ? _vendorInvCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (updated != null) {
      // Pop back to detail with updated service
      Get.back(result: updated);
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle:
            AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.bodyText)),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: highlight
                  ? AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)
                  : AppTextStyles.body),
          Text(value,
              style: highlight
                  ? AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700)
                  : AppTextStyles.body
                      .copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
