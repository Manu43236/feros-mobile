import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../office_clients/views/office_clients_view.dart';
import '../../office_finance/views/office_finance_view.dart';
import '../../office_staff/views/office_staff_view.dart';
import '../../office_attendance/views/office_attendance_view.dart';
import '../../office_payroll/views/office_payroll_view.dart';
import '../../office_inventory/views/office_inventory_view.dart';
import '../../office_subscription/views/office_subscription_view.dart';
import '../../../supervisor/supervisor_fuel_log/bindings/supervisor_fuel_log_binding.dart';
import '../../../supervisor/supervisor_fuel_log/views/supervisor_fuel_log_view.dart';
import '../../../supervisor/supervisor_meter_reading/bindings/supervisor_meter_reading_binding.dart';
import '../../../supervisor/supervisor_meter_reading/views/supervisor_meter_reading_view.dart';

class OfficeMoreTab extends StatelessWidget {
  const OfficeMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Get.find<AuthService>().user?.role ?? '';
    final isAdmin = role == 'ADMIN';

    final modules = [
      _Module(Icons.receipt_long_outlined,    'Invoices',   AppColors.navy,      () => Get.to(() => const OfficeFinanceView())),
      _Module(Icons.business_outlined,         'Clients',    const Color(0xFF0284C7), () => Get.to(() => const OfficeClientsView())),
      _Module(Icons.badge_outlined,            'Staff',      const Color(0xFF7C3AED), () => Get.to(() => const OfficeStaffView())),
      _Module(Icons.inventory_2_outlined,      'Inventory',  AppColors.orange,    () => Get.to(() => const OfficeInventoryView())),
      _Module(Icons.fact_check_outlined,       'Attendance', AppColors.success,   () => Get.to(() => const OfficeAttendanceView())),
      _Module(Icons.payments_outlined,         'Payroll',    const Color(0xFF0891B2), () => Get.to(() => const OfficePayrollView())),
      _Module(Icons.local_gas_station_outlined, 'Fuel Log',  const Color(0xFF0F766E), () =>
        Get.to(() => const SupervisorFuelLogView(), binding: SupervisorFuelLogBinding())),
      _Module(Icons.speed_outlined, 'Meter Reading', const Color(0xFF7C3AED), () =>
        Get.to(() => const SupervisorMeterReadingView(), binding: SupervisorMeterReadingBinding())),
      if (isAdmin)
        _Module(Icons.workspace_premium_outlined, 'Subscription', AppColors.warning, () => Get.to(() => const OfficeSubscriptionView())),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
      children: [
        Text('Modules',
            style: AppTextStyles.heading3.copyWith(color: AppColors.bodyText)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: modules.map((m) => _ModuleCard(module: m)).toList(),
        ),
      ],
    );
  }

}

class _Module {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Module(this.icon, this.label, this.color, this.onTap);
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(module.icon, size: 20, color: module.color),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(module.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.mutedText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
