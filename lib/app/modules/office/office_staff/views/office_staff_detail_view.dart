import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class OfficeStaffDetailView extends StatefulWidget {
  final Map<String, dynamic> user;
  const OfficeStaffDetailView({super.key, required this.user});

  @override
  State<OfficeStaffDetailView> createState() => _OfficeStaffDetailViewState();
}

class _OfficeStaffDetailViewState extends State<OfficeStaffDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _api = Get.find<ApiClient>();

  // Attendance tab
  DateTime _attFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _attTo = DateTime.now();
  List<Map<String, dynamic>> _attRecords = [];
  bool _attLoading = false;

  // Payslip tab
  List<Map<String, dynamic>> _payrolls = [];
  bool _payLoading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && _attRecords.isEmpty && !_attLoading) {
        _fetchAttendance();
      }
      if (_tab.index == 2 && _payrolls.isEmpty && !_payLoading) {
        _fetchPayrolls();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _attLoading = true);
    try {
      final id = (widget.user['id'] as num?)?.toInt() ?? 0;
      final from = _fmt(_attFrom);
      final to = _fmt(_attTo);
      final res = await _api.get(
        ApiEndpoints.userAttendance(id),
        params: {'from': from, 'to': to},
      );
      setState(() {
        _attRecords = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _attLoading = false;
      });
    } catch (_) {
      setState(() => _attLoading = false);
    }
  }

  Future<void> _fetchPayrolls() async {
    setState(() => _payLoading = true);
    try {
      final id = (widget.user['id'] as num?)?.toInt() ?? 0;
      final res = await _api.get(ApiEndpoints.userPayroll(id));
      setState(() {
        _payrolls = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _payLoading = false;
      });
    } catch (_) {
      setState(() => _payLoading = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? '—';
    final role = widget.user['role'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              _roleLabel(role),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Inter',
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
          labelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Attendance'),
            Tab(text: 'Payslip'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ProfileTab(user: widget.user),
          _AttendanceTab(
            loading: _attLoading,
            records: _attRecords,
            from: _attFrom,
            to: _attTo,
            onDateChanged: (f, t) {
              setState(() {
                _attFrom = f;
                _attTo = t;
              });
              _fetchAttendance();
            },
          ),
          _PayslipTab(loading: _payLoading, payrolls: _payrolls),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'SERVICE_MEN' => 'Service Men',
    'STORE_KEEPER' => 'Store Keeper',
    'OFFICE_STAFF' => 'Office Staff',
    _ => role.isEmpty ? '' : role[0] + role.substring(1).toLowerCase(),
  };
}

// ── Profile Tab ────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic> user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Basic Info', [
          _row('Name', user['name']),
          _row('Phone', user['phone']),
          _row('Role', user['role']),
          _row('Employee #', user['userNumber']),
          _row('Status', (user['isActive'] == true) ? 'Active' : 'Inactive'),
        ]),
        if (user['designationName'] != null ||
            user['employmentType'] != null) ...[
          const SizedBox(height: 12),
          _section('Employment', [
            _row('Designation', user['designationName']),
            _row('Employment Type', user['employmentType']),
            _row('Joining Date', user['joiningDate']),
            _row('Date of Birth', user['dateOfBirth']),
          ]),
        ],
        if (user['licenseNumber'] != null) ...[
          const SizedBox(height: 12),
          _section('License', [
            _row('License No.', user['licenseNumber']),
            _row('Expiry Date', user['licenseExpiryDate']),
          ]),
        ],
        if (user['address'] != null) ...[
          const SizedBox(height: 12),
          _section('Address', [_row('Address', user['address'])]),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.where((r) => r is! SizedBox || true),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Tab ─────────────────────────────────────────────────────────────
class _AttendanceTab extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> records;
  final DateTime from;
  final DateTime to;
  final void Function(DateTime, DateTime) onDateChanged;

  const _AttendanceTab({
    required this.loading,
    required this.records,
    required this.from,
    required this.to,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date range picker bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _DateBtn(
                  label: 'From',
                  date: from,
                  onPick: (d) => onDateChanged(d, to),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateBtn(
                  label: 'To',
                  date: to,
                  onPick: (d) => onDateChanged(from, d),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.navy),
                )
              : records.isEmpty
              ? const Center(
                  child: Text(
                    'No attendance records',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.mutedText,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: records.length,
                  itemBuilder: (_, i) => _AttRow(record: records[i]),
                ),
        ),
      ],
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final void Function(DateTime) onPick;
  const _DateBtn({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.navy),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $text',
              style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record['attendanceDate'] as String? ?? '';
    final type = record['attendanceTypeName'] as String? ?? '—';
    final marked = record['markedByName'] as String? ?? '';
    final status = record['approvalStatus'] as String? ?? '';

    Color typeColor;
    if (type.toLowerCase().contains('present')) {
      typeColor = AppColors.success;
    } else if (type.toLowerCase().contains('absent')) {
      typeColor = AppColors.error;
    } else if (type.toLowerCase().contains('half')) {
      typeColor = AppColors.warning;
    } else {
      typeColor = AppColors.navy;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (marked.isNotEmpty)
                  Text(
                    'by $marked',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              type,
              style: AppTextStyles.caption.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (status == 'PENDING') ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pending',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payslip Tab ────────────────────────────────────────────────────────────────
class _PayslipTab extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> payrolls;
  const _PayslipTab({required this.loading, required this.payrolls});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }
    if (payrolls.isEmpty) {
      return const Center(
        child: Text(
          'No payslips found',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.mutedText),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: payrolls.length,
      itemBuilder: (_, i) => _PayslipCard(p: payrolls[i]),
    );
  }
}

class _PayslipCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _PayslipCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final from = p['payCycleStartDate'] as String? ?? '';
    final to = p['payCycleEndDate'] as String? ?? '';
    final net = p['netPay'] as num? ?? 0;
    final gross = p['grossPay'] as num? ?? 0;
    final deduct = p['totalDeductions'] as num? ?? 0;
    final status = p['payrollStatus'] as String? ?? '';
    final present = (p['presentDays'] as num?)?.toInt() ?? 0;
    final total = (p['totalDays'] as num?)?.toInt() ?? 0;

    final statusColor = switch (status) {
      'APPROVED' || 'PAID' => AppColors.success,
      'DRAFT' => AppColors.warning,
      'CANCELLED' => AppColors.error,
      _ => AppColors.mutedText,
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$from → $to',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _amt('Gross', '₹${gross.toStringAsFixed(0)}', AppColors.bodyText),
              const SizedBox(width: 16),
              _amt(
                'Deductions',
                '-₹${deduct.toStringAsFixed(0)}',
                AppColors.error,
              ),
              const SizedBox(width: 16),
              _amt('Net Pay', '₹${net.toStringAsFixed(0)}', AppColors.success),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$present / $total days present',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _amt(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          fontSize: 10,
        ),
      ),
      Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
