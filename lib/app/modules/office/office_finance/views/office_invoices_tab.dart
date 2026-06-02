import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/office_invoices_controller.dart';
import 'office_create_invoice_view.dart';
import 'office_invoice_detail_view.dart';

class OfficeInvoicesTab extends GetView<OfficeInvoicesController> {
  const OfficeInvoicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      if (state == ViewState.loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      }
      if (state == ViewState.error) {
        return _ErrorState(onRetry: controller.fetchInvoices);
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _StatusFilter(controller: controller),
            Expanded(
              child: Obx(() {
                final list = controller.filtered;
                if (list.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: controller.fetchInvoices,
                  child: Obx(() {
                    final loadingMore = controller.isLoadingMore.value;
                    return ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: list.length + (loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == list.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.navy,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        return _InvoiceCard(invoice: list[i]);
                      },
                    );
                  }),
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New Invoice',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          onPressed: () async {
            await Get.to(() => const OfficeCreateInvoiceView());
            controller.fetchInvoices();
          },
        ),
      );
    });
  }
}

// ── Status Filter ──────────────────────────────────────────────────────────────
class _StatusFilter extends StatelessWidget {
  final OfficeInvoicesController controller;
  const _StatusFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
      child: Obx(() {
        final sel = controller.selectedStatus.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: OfficeInvoicesController.statuses.map((s) {
              final active = s == sel;
              final label  = OfficeInvoicesController.statusLabels[s] ?? s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setStatus(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.navy : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? AppColors.navy : AppColors.border),
                    ),
                    child: Text(label,
                        style: AppTextStyles.caption.copyWith(
                          color: active ? Colors.white : AppColors.mutedText,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

// ── Invoice Card ───────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final invNo      = invoice['invoiceNumber'] as String? ?? '—';
    final client     = invoice['clientName']    as String? ?? '—';
    final status     = invoice['invoiceStatus'] as String? ?? '';
    final total      = (invoice['totalAmount']  as num?)?.toDouble() ?? 0;
    final balance    = (invoice['balanceDue']   as num?)?.toDouble() ?? 0;
    final dueDate    = invoice['dueDate']        as String?;
    final id         = invoice['id'];

    return GestureDetector(
      onTap: () => Get.to(
        () => OfficeInvoiceDetailView(invoiceId: id is int ? id : int.tryParse(id.toString()) ?? 0),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(invNo,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w700)),
                ),
                _InvoiceStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Text(client,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      const SizedBox(height: 2),
                      Text(_fmtRupee(total),
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance Due',
                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      const SizedBox(height: 2),
                      Text(_fmtRupee(balance),
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: balance > 0 ? AppColors.error : AppColors.success)),
                    ],
                  ),
                ),
                if (dueDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Due', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                      const SizedBox(height: 2),
                      Text(_fmtDate(dueDate),
                          style: AppTextStyles.caption.copyWith(
                              color: _isDueOverdue(dueDate, status)
                                  ? AppColors.error
                                  : AppColors.bodyText,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isDueOverdue(String iso, String status) {
    if (status == 'PAID') return false;
    try {
      return DateTime.parse(iso).isBefore(DateTime.now());
    } catch (_) { return false; }
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtDate(String iso) {
    try { return DateFormat('dd MMM yy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }
}

// ── Invoice Status Chip ────────────────────────────────────────────────────────
class _InvoiceStatusChip extends StatelessWidget {
  final String status;
  const _InvoiceStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(_label(status),
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'DRAFT':         return AppColors.mutedText;
      case 'SENT':          return const Color(0xFF2563EB);
      case 'PARTIALLY_PAID':return const Color(0xFFF59E0B);
      case 'OVERDUE':       return AppColors.error;
      case 'PAID':          return AppColors.success;
      default:              return AppColors.mutedText;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'DRAFT':         return 'Draft';
      case 'SENT':          return 'Sent';
      case 'PARTIALLY_PAID':return 'Part. Paid';
      case 'OVERDUE':       return 'Overdue';
      case 'PAID':          return 'Paid';
      default:              return s;
    }
  }
}

// ── Empty / Error ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text('No invoices found',
              style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),
          Text('Tap + to create an invoice',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load invoices',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ]),
      );
}
