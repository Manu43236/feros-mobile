import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../supervisor_lrs/controllers/supervisor_lr_detail_controller.dart';
import '../../supervisor_lrs/views/supervisor_lr_detail_view.dart';
import '../controllers/supervisor_trip_expenses_controller.dart';
import '../../../../../core/widgets/shimmer_card.dart';

class SupervisorTripExpensesView extends GetView<SupervisorTripExpensesController> {
  const SupervisorTripExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trip Expenses',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Obx(() {
            final activeFilter = controller.activeFilter.value;
            return SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: SupervisorTripExpensesController.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = SupervisorTripExpensesController.filters[i];
                final active = activeFilter == f;
                return GestureDetector(
                  onTap: () => controller.setFilter(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.navy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.navy : AppColors.border),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.mutedText,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
          }),
          Expanded(
            child: Obx(() {
              if (controller.state.value == ViewState.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ShimmerList(count: 5),
                );
              }
              if (controller.state.value == ViewState.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.mutedText),
                      const SizedBox(height: 8),
                      const Text('Failed to load expenses'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: controller.fetchExpenses,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (controller.expenses.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.border),
                      SizedBox(height: 8),
                      Text('No expense sheets found', style: TextStyle(color: AppColors.mutedText)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchExpenses,
                color: AppColors.navy,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: controller.expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ExpenseCard(
                    expense: controller.expenses[i],
                    onTap: () {
                      final lrId = controller.expenses[i]['lrId'] as int?;
                      if (lrId == null) return;
                      Get.to(
                        () => const SupervisorLrDetailView(),
                        arguments: lrId,
                        binding: BindingsBuilder(() => Get.put(SupervisorLrDetailController())),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onTap;
  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status       = expense['status'] as String? ?? '';
    final lrNumber     = expense['lrNumber'] as String? ?? '—';
    final driverName   = expense['driverName'] as String?;
    final cleanerName  = expense['cleanerName'] as String?;
    final advance      = (expense['advanceAmount'] as num?)?.toStringAsFixed(0) ?? '0';
    final submitted    = (expense['totalSubmittedAmount'] as num?)?.toStringAsFixed(0) ?? '0';
    final approved     = (expense['totalApprovedAmount'] as num?)?.toStringAsFixed(0);
    final balance      = expense['balanceAmount'] as num?;
    final hasBalance   = status == 'APPROVED' || status == 'SETTLED';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  lrNumber,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _StatusBadge(status),
              ],
            ),
            if (driverName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(driverName, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  if (cleanerName != null) ...[
                    const SizedBox(width: 8),
                    Text('· $cleanerName', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat('Advance', '₹$advance'),
                const SizedBox(width: 16),
                _Stat('Submitted', '₹$submitted'),
                if (hasBalance && approved != null) ...[
                  const SizedBox(width: 16),
                  _Stat('Approved', '₹$approved', color: AppColors.success),
                ],
                if (hasBalance && balance != null) ...[
                  const Spacer(),
                  Text(
                    balance >= 0 ? 'Returns ₹${balance.abs().toStringAsFixed(0)}' : 'Pays ₹${balance.abs().toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                      color: balance >= 0 ? AppColors.info : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (status == 'REJECTED') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Tap to view rejection reason and resubmit', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontSize: 10)),
        Text(value, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: color ?? AppColors.bodyText)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color {
    switch (status) {
      case 'DRAFT':     return AppColors.mutedText;
      case 'SUBMITTED': return AppColors.warning;
      case 'APPROVED':  return AppColors.success;
      case 'SETTLED':   return AppColors.info;
      case 'REJECTED':  return AppColors.error;
      default:          return AppColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
