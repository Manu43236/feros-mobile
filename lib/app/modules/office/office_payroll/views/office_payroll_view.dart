import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../controllers/office_payroll_controller.dart';

class OfficePayrollView extends StatelessWidget {
  const OfficePayrollView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<OfficePayrollController>(() => OfficePayrollController());
    final controller = Get.find<OfficePayrollController>();
    final isAdmin = Get.find<AuthService>().user?.role == 'ADMIN';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          title: const Text('Payroll',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              )),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
            labelStyle: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: const [
              Tab(text: 'Payrolls'),
              Tab(text: 'Advances'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PayrollsTab(controller: controller, isAdmin: isAdmin),
            _AdvancesTab(controller: controller, isAdmin: isAdmin),
          ],
        ),
      ),
    );
  }
}

// ── Payrolls Tab ───────────────────────────────────────────────────────────────
class _PayrollsTab extends StatelessWidget {
  final OfficePayrollController controller;
  final bool isAdmin;
  const _PayrollsTab({required this.controller, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Status filter chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Obx(() {
                final sel = controller.selectedStatus.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: OfficePayrollController.statuses.map((s) {
                      final active = s == sel;
                      final label = s == 'ALL'
                          ? 'All'
                          : s[0] + s.substring(1).toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => controller.setStatus(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.navy
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppColors.navy
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(label,
                                style: AppTextStyles.caption.copyWith(
                                  color: active
                                      ? Colors.white
                                      : AppColors.mutedText,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),

            Expanded(
              child: Obx(() {
                final s = controller.payrollState.value;
                if (s == ViewState.loading) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.navy));
                }
                if (s == ViewState.error) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load payrolls',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.mutedText)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchPayrolls,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }
                final list = controller.filteredPayrolls;
                if (list.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.payments_outlined,
                          size: 52, color: AppColors.mutedText),
                      SizedBox(height: 16),
                      Text('No payrolls found',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.mutedText)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: controller.fetchPayrolls,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _PayrollCard(
                      p: list[i],
                      isAdmin: isAdmin,
                      onApprove: () =>
                          _showApproveSheet(context, controller, list[i]),
                      onCancel: () =>
                          _handleCancel(context, controller, list[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),

        if (isAdmin)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Generate',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              onPressed: () =>
                  _showGenerateSheet(context, controller),
            ),
          ),
      ],
    );
  }

  void _showGenerateSheet(
      BuildContext context, OfficePayrollController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GeneratePayrollSheet(controller: controller),
    );
  }

  void _showApproveSheet(BuildContext context,
      OfficePayrollController controller, Map<String, dynamic> p) {
    final status = p['payrollStatus'] as String? ?? '';
    if (status != 'DRAFT') {
      FerosSnackbar.error('Only DRAFT payrolls can be approved');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ApprovePayrollSheet(controller: controller, payroll: p),
    );
  }

  Future<void> _handleCancel(BuildContext context,
      OfficePayrollController controller, Map<String, dynamic> p) async {
    final id = (p['id'] as num?)?.toInt() ?? 0;
    try {
      await controller.cancelPayroll(id);
      FerosSnackbar.success('Payroll cancelled');
    } catch (e) {
      FerosSnackbar.error('Failed to cancel payroll');
    }
  }
}

// ── Payroll Card ───────────────────────────────────────────────────────────────
class _PayrollCard extends StatelessWidget {
  final Map<String, dynamic> p;
  final bool isAdmin;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  const _PayrollCard(
      {required this.p,
      required this.isAdmin,
      required this.onApprove,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final name    = p['userName']         as String? ?? '—';
    final role    = p['roleName']         as String? ?? '';
    final from    = p['payCycleStartDate']as String? ?? '';
    final to      = p['payCycleEndDate']  as String? ?? '';
    final net     = p['netPay']           as num? ?? 0;
    final gross   = p['grossPay']         as num? ?? 0;
    final deduct  = p['totalDeductions']  as num? ?? 0;
    final status  = p['payrollStatus']    as String? ?? '';
    final present = (p['presentDays']     as num?)?.toInt() ?? 0;
    final total   = (p['totalDays']       as num?)?.toInt() ?? 0;

    final statusColor = switch (status) {
      'APPROVED' => AppColors.navy,
      'PAID'     => AppColors.success,
      'DRAFT'    => AppColors.warning,
      _          => AppColors.mutedText,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(role,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status,
                  style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('$from → $to',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText)),
          const Divider(height: 16),
          Row(children: [
            _amt('Gross', '₹${gross.toStringAsFixed(0)}',
                AppColors.bodyText),
            const SizedBox(width: 16),
            _amt('Deductions', '-₹${deduct.toStringAsFixed(0)}',
                AppColors.error),
            const SizedBox(width: 16),
            _amt('Net Pay', '₹${net.toStringAsFixed(0)}',
                AppColors.success),
            const Spacer(),
            Text('$present/$total days',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ]),
          if (isAdmin && status == 'DRAFT') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve & Pay',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _amt(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText, fontSize: 10)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Advances Tab ───────────────────────────────────────────────────────────────
class _AdvancesTab extends StatelessWidget {
  final OfficePayrollController controller;
  final bool isAdmin;
  const _AdvancesTab({required this.controller, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final s = controller.advanceState.value;
          if (s == ViewState.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (s == ViewState.error) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load advances',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchAdvances,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          final list = controller.advances;
          if (list.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.money_off_outlined,
                    size: 52, color: AppColors.mutedText),
                SizedBox(height: 16),
                Text('No salary advances',
                    style: TextStyle(
                        fontFamily: 'Inter', color: AppColors.mutedText)),
              ]),
            );
          }
          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: controller.fetchAdvances,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              itemBuilder: (_, i) => _AdvanceCard(a: list[i]),
            ),
          );
        }),

        if (isAdmin)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Advance',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              onPressed: () => _showAdvanceSheet(context, controller),
            ),
          ),
      ],
    );
  }

  void _showAdvanceSheet(
      BuildContext context, OfficePayrollController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvanceSheet(controller: controller),
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  final Map<String, dynamic> a;
  const _AdvanceCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final name     = a['userName']      as String? ?? '—';
    final date     = a['advanceDate']   as String? ?? '';
    final amount   = a['amount']        as num? ?? 0;
    final balance  = a['balanceAmount'] as num? ?? 0;
    final repaid   = a['totalRepaid']   as num? ?? 0;
    final isDone   = a['isFullyRepaid'] as bool? ?? false;
    final reason   = a['reason']        as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isDone ? 'Repaid' : 'Outstanding',
                  style: AppTextStyles.caption.copyWith(
                      color: isDone
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 10)),
            ),
          ]),
          const SizedBox(height: 4),
          if (date.isNotEmpty)
            Text(date,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          if (reason.isNotEmpty)
            Text(reason,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 8),
          Row(children: [
            _col('Amount', '₹${amount.toStringAsFixed(0)}',
                AppColors.bodyText),
            const SizedBox(width: 16),
            _col('Repaid', '₹${repaid.toStringAsFixed(0)}',
                AppColors.success),
            const SizedBox(width: 16),
            _col('Balance', '₹${balance.toStringAsFixed(0)}',
                isDone ? AppColors.mutedText : AppColors.error),
          ]),
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText, fontSize: 10)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Generate Payroll Sheet ─────────────────────────────────────────────────────
class _GeneratePayrollSheet extends StatefulWidget {
  final OfficePayrollController controller;
  const _GeneratePayrollSheet({required this.controller});

  @override
  State<_GeneratePayrollSheet> createState() => _GeneratePayrollSheetState();
}

class _GeneratePayrollSheetState extends State<_GeneratePayrollSheet> {
  final _userIdCtr    = TextEditingController();
  final _rateCtr      = TextEditingController();
  final _remarksCtr   = TextEditingController();
  DateTime _from      = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to        = DateTime.now();
  bool _loading       = false;

  @override
  void dispose() {
    _userIdCtr.dispose();
    _rateCtr.dispose();
    _remarksCtr.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final userId = int.tryParse(_userIdCtr.text.trim());
    final rate   = double.tryParse(_rateCtr.text.trim());
    if (userId == null || rate == null) {
      FerosSnackbar.error('Fill in all required fields correctly');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.controller.generatePayroll({
        'userId': userId,
        'payCycleStartDate': _fmt(_from),
        'payCycleEndDate': _fmt(_to),
        'dailyRate': rate,
        if (_remarksCtr.text.trim().isNotEmpty)
          'remarks': _remarksCtr.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        FerosSnackbar.success('Payroll generated');
      }
    } catch (e) {
      FerosSnackbar.error('Failed to generate payroll');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Generate Payroll',
                  style: AppTextStyles.heading4
                      .copyWith(color: AppColors.navy)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 16),

            _label('Staff ID *'),
            const SizedBox(height: 6),
            _field(_userIdCtr, 'Enter user ID',
                type: TextInputType.number),
            const SizedBox(height: 12),

            _label('Pay Cycle'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: _datePicker(
                    context, 'From', _from, (d) => setState(() => _from = d)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _datePicker(
                    context, 'To', _to, (d) => setState(() => _to = d)),
              ),
            ]),
            const SizedBox(height: 12),

            _label('Daily Rate (₹) *'),
            const SizedBox(height: 6),
            _field(_rateCtr, 'e.g. 500',
                type: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),

            _label('Remarks'),
            const SizedBox(height: 6),
            _field(_remarksCtr, 'Optional'),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Generate',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext context, String label, DateTime date,
      void Function(DateTime) onPick) {
    final text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.navy),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: AppColors.mutedText),
          const SizedBox(width: 6),
          Flexible(
            child: Text('$label: $text',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.bodyText),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.bodyText, fontWeight: FontWeight.w600));

  Widget _field(TextEditingController ctr, String hint,
      {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctr,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide:
                const BorderSide(color: AppColors.navy, width: 1.5),
          ),
        ),
      );
}

// ── Approve Payroll Sheet ──────────────────────────────────────────────────────
class _ApprovePayrollSheet extends StatefulWidget {
  final OfficePayrollController controller;
  final Map<String, dynamic> payroll;
  const _ApprovePayrollSheet(
      {required this.controller, required this.payroll});

  @override
  State<_ApprovePayrollSheet> createState() => _ApprovePayrollSheetState();
}

class _ApprovePayrollSheetState extends State<_ApprovePayrollSheet> {
  static const _modes = ['CASH', 'CHEQUE', 'NEFT', 'UPI', 'RTGS'];
  String  _mode    = 'CASH';
  final   _refCtr  = TextEditingController();
  bool    _loading = false;

  @override
  void dispose() {
    _refCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final id = (widget.payroll['id'] as num?)?.toInt() ?? 0;
      await widget.controller.approvePayroll(id, {
        'paymentMode': _mode,
        if (_refCtr.text.trim().isNotEmpty)
          'referenceNumber': _refCtr.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        FerosSnackbar.success('Payroll approved & paid');
      }
    } catch (e) {
      FerosSnackbar.error('Failed to approve payroll');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final name   = widget.payroll['userName']  as String? ?? '—';
    final net    = widget.payroll['netPay']     as num? ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Approve & Pay',
                style: AppTextStyles.heading4
                    .copyWith(color: AppColors.navy)),
            const Spacer(),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 4),
          Text('$name — ₹${net.toStringAsFixed(0)}',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),

          _label('Payment Mode'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: _inputDec(''),
            items: _modes.map((m) {
              final label = m[0] + m.substring(1).toLowerCase();
              return DropdownMenuItem(value: m, child: Text(label));
            }).toList(),
            onChanged: (v) => setState(() => _mode = v!),
          ),
          const SizedBox(height: 12),

          _label('Reference Number (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _refCtr,
            decoration: _inputDec('Cheque no. / UTR / ref'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Payment',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.bodyText, fontWeight: FontWeight.w600));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
              const BorderSide(color: AppColors.navy, width: 1.5),
        ),
      );
}

// ── Advance Sheet ──────────────────────────────────────────────────────────────
class _AdvanceSheet extends StatefulWidget {
  final OfficePayrollController controller;
  const _AdvanceSheet({required this.controller});

  @override
  State<_AdvanceSheet> createState() => _AdvanceSheetState();
}

class _AdvanceSheetState extends State<_AdvanceSheet> {
  final _idCtr     = TextEditingController();
  final _amtCtr    = TextEditingController();
  final _reasonCtr = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _idCtr.dispose();
    _amtCtr.dispose();
    _reasonCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = int.tryParse(_idCtr.text.trim());
    final amount = double.tryParse(_amtCtr.text.trim());
    if (userId == null || amount == null) {
      FerosSnackbar.error('Enter valid staff ID and amount');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.controller.createAdvance({
        'userId': userId,
        'amount': amount,
        if (_reasonCtr.text.trim().isNotEmpty)
          'reason': _reasonCtr.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        FerosSnackbar.success('Advance recorded');
      }
    } catch (e) {
      FerosSnackbar.error('Failed to record advance');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('New Salary Advance',
                style: AppTextStyles.heading4
                    .copyWith(color: AppColors.navy)),
            const Spacer(),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 16),

          _label('Staff ID *'),
          const SizedBox(height: 6),
          _field(_idCtr, 'Enter user ID',
              type: TextInputType.number),
          const SizedBox(height: 12),

          _label('Amount (₹) *'),
          const SizedBox(height: 6),
          _field(_amtCtr, 'e.g. 2000',
              type: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),

          _label('Reason'),
          const SizedBox(height: 6),
          _field(_reasonCtr, 'Optional'),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Record Advance',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.bodyText, fontWeight: FontWeight.w600));

  Widget _field(TextEditingController ctr, String hint,
          {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctr,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide:
                const BorderSide(color: AppColors.navy, width: 1.5),
          ),
        ),
      );
}
