import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../controllers/office_subscription_controller.dart';

class OfficeSubscriptionView extends StatelessWidget {
  const OfficeSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OfficeSubscriptionController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: const Text('Subscription'),
      ),
      body: Obx(() {
        final state = ctrl.state.value;
        if (state == ViewState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          );
        }
        if (state == ViewState.error || ctrl.sub == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 56, color: Colors.black12),
                const SizedBox(height: 12),
                Text('No active subscription found.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 4),
                Text('Please contact FEROS support.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: ctrl.fetchAll,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.fetchAll,
          color: AppColors.navy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _StatusCard(ctrl: ctrl),
              const SizedBox(height: 16),
              _UsageCard(ctrl: ctrl),
              const SizedBox(height: 16),
              _FeaturesCard(ctrl: ctrl),
              const SizedBox(height: 16),
              _BillingHistoryCard(ctrl: ctrl),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Status colours ───────────────────────────────────────────────────────────
Map<String, Color> _statusColor(String status) {
  switch (status) {
    case 'ACTIVE':    return {'bg': const Color(0xFFF0FDF4), 'border': const Color(0xFFBBF7D0), 'text': const Color(0xFF15803D)};
    case 'TRIAL':     return {'bg': const Color(0xFFEFF6FF), 'border': const Color(0xFFBFDBFE), 'text': const Color(0xFF1D4ED8)};
    case 'EXPIRED':   return {'bg': const Color(0xFFFFF1F2), 'border': const Color(0xFFFFCDD5), 'text': const Color(0xFFBE123C)};
    case 'SUSPENDED': return {'bg': const Color(0xFFFFFBEB), 'border': const Color(0xFFFDE68A), 'text': const Color(0xFFB45309)};
    default:          return {'bg': const Color(0xFFF9FAFB), 'border': const Color(0xFFE5E7EB), 'text': const Color(0xFF374151)};
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'ACTIVE':    return Icons.check_circle_outline;
    case 'TRIAL':     return Icons.access_time_outlined;
    case 'EXPIRED':   return Icons.warning_amber_outlined;
    case 'SUSPENDED': return Icons.pause_circle_outline;
    default:          return Icons.info_outline;
  }
}

// ─── 1. Status Card ───────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final OfficeSubscriptionController ctrl;
  const _StatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final sub    = ctrl.sub!;
    final status = ctrl.status;
    final colors = _statusColor(status);
    final days   = ctrl.daysLeft;

    final planName = sub['planName'] as String? ?? 'Free';
    final isTrial  = status == 'TRIAL';
    final pricePerV= (sub['pricePerVehicle'] as num? ?? 0).toDouble();
    final vCount   = (sub['vehicleCount'] as num? ?? 0).toInt();
    final endDate  = sub['endDate'] as String?;
    final cycle    = sub['billingCycle'] as String?;

    final cycleLabel = {
      'MONTHLY': 'Monthly', 'THREE_MONTHS': '3-Month',
      'SIX_MONTHS': '6-Month', 'YEARLY': 'Annual',
    }[cycle] ?? cycle;

    Color daysColor = AppColors.bodyText;
    if (days != null) {
      if (days <= 7) {
        daysColor = AppColors.error;
      } else if (days <= 30) {
        daysColor = AppColors.warning;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors['border']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: colors['text'], size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planName,
                        style: AppTextStyles.heading3
                            .copyWith(color: colors['text'])),
                    Text(status,
                        style: AppTextStyles.caption
                            .copyWith(color: colors['text']!.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pricePerV > 0 && vCount > 0) ...[
            _MetaRow(Icons.trending_up_outlined,
                '$vCount vehicles × ₹${pricePerV.toStringAsFixed(0)}/vehicle'),
          ],
          if (isTrial)
            _MetaRow(Icons.access_time_outlined, 'Trial Period — Full Access',
                color: colors['text']),
          if (cycleLabel != null)
            _MetaRow(Icons.credit_card_outlined, '$cycleLabel billing'),
          if (endDate != null)
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.black45),
                const SizedBox(width: 6),
                Text(
                  '${isTrial ? 'Trial ends' : 'Renews'}: $endDate',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.bodyText),
                ),
                if (days != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    days > 0 ? '(${days}d left)' : '(Expired)',
                    style: AppTextStyles.caption.copyWith(
                        color: daysColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          if (endDate == null && !isTrial)
            _MetaRow(Icons.calendar_today_outlined, 'Never expires',
                color: AppColors.success),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaRow(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color ?? Colors.black45),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption
                    .copyWith(color: color ?? AppColors.bodyText)),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Usage Card ────────────────────────────────────────────────────────────
class _UsageCard extends StatelessWidget {
  final OfficeSubscriptionController ctrl;
  const _UsageCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final vLimit = ctrl.vehicleLimit;
    final uLimit = ctrl.userLimit;
    final vCount = ctrl.vehicleCount.value;
    final uCount = ctrl.userCount.value;

    return _Card(
      title: 'Plan Usage',
      child: Column(
        children: [
          _UsageBar(
            label: 'Vehicles',
            icon: Icons.directions_bus_outlined,
            current: vCount,
            max: vLimit,
          ),
          const SizedBox(height: 16),
          _UsageBar(
            label: 'Users',
            icon: Icons.people_outline,
            current: uCount,
            max: uLimit,
          ),
          if (vLimit > 0 && vCount >= vLimit) ...[
            const SizedBox(height: 12),
            _WarningBanner(
              color: AppColors.error,
              title: 'Vehicle limit reached',
              message:
                  'You\'ve used all $vLimit vehicle slots. Contact FEROS support to add more.',
            ),
          ],
          if (uLimit != -1 && uCount >= uLimit) ...[
            const SizedBox(height: 8),
            _WarningBanner(
              color: AppColors.warning,
              title: 'User limit reached',
              message: 'Upgrade to a paid plan for unlimited users.',
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int current;
  final int max;
  const _UsageBar(
      {required this.label,
      required this.icon,
      required this.current,
      required this.max});

  @override
  Widget build(BuildContext context) {
    final unlimited = max == -1;
    final pct = unlimited ? 0.0 : (current / max).clamp(0.0, 1.0);
    final near = !unlimited && pct >= 0.8;
    final full = !unlimited && pct >= 1.0;

    final barColor = full
        ? AppColors.error
        : near
            ? AppColors.warning
            : AppColors.navy;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.mutedText),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '$current / ${unlimited ? '∞' : max}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: full
                    ? AppColors.error
                    : near
                        ? AppColors.warning
                        : AppColors.bodyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!unlimited) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ] else
          Text('Unlimited',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final Color color;
  final String title;
  final String message;
  const _WarningBanner(
      {required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.caption.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(message,
                    style:
                        AppTextStyles.caption.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Features Card ─────────────────────────────────────────────────────────
class _FeaturesCard extends StatelessWidget {
  final OfficeSubscriptionController ctrl;
  const _FeaturesCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'label': 'Clients & Orders',   'enabled': true},
      {'label': 'LR Register',        'enabled': true},
      {'label': 'Invoices',           'enabled': true},
      {'label': 'Credit Notes',       'enabled': ctrl.hasCreditNotes},
      {'label': 'Fuel Logs',          'enabled': ctrl.hasFuelLogs},
      {'label': 'Meter Readings',     'enabled': ctrl.hasMeterReadings},
      {'label': 'Vehicle Services',   'enabled': ctrl.hasVehicleServices},
      {'label': 'Attendance',         'enabled': ctrl.hasAttendance},
      {'label': 'Payroll',            'enabled': ctrl.hasPayroll},
      {'label': 'Inventory',          'enabled': ctrl.hasInventory},
      {'label': 'Reports',            'enabled': ctrl.hasReports},
    ];

    return _Card(
      title: 'Included Features',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: features
            .map((f) => _FeatureChip(
                  label: f['label'] as String,
                  enabled: f['enabled'] as bool,
                ))
            .toList(),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final bool enabled;
  const _FeatureChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppColors.success.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.lock_outline,
            size: 12,
            color: enabled ? AppColors.success : AppColors.mutedText,
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: enabled ? AppColors.success : AppColors.mutedText,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ─── 4. Billing History Card ──────────────────────────────────────────────────
class _BillingHistoryCard extends StatelessWidget {
  final OfficeSubscriptionController ctrl;
  const _BillingHistoryCard({required this.ctrl});

  String _fmt(double? v) {
    if (v == null) return '—';
    return '₹${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ctrl.invoices;

    return _Card(
      title: 'Billing History',
      titleTrailing: Text('${invoices.length} invoice${invoices.length != 1 ? 's' : ''}',
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      child: invoices.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No invoices yet',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ),
            )
          : Column(
              children: invoices
                  .map((inv) => _InvoiceRow(inv: inv, fmt: _fmt))
                  .toList(),
            ),
    );
  }
}

class _InvoiceRow extends StatefulWidget {
  final Map<String, dynamic> inv;
  final String Function(double?) fmt;
  const _InvoiceRow({required this.inv, required this.fmt});

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _pdfLoading = false;

  Future<void> _viewPdf() async {
    final id = widget.inv['id'];
    if (id == null || _pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      final invNo = widget.inv['invoiceNumber'] as String? ?? 'invoice-$id';
      final api   = Get.find<ApiClient>();
      final bytes = await api.getBytes(ApiEndpoints.mySubscriptionInvoicePdf(id));
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/$invNo.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {
          'file': file,
          'title': invNo,
          'subtitle': widget.inv['planName'] as String? ?? '',
        },
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('Failed to load invoice PDF');
    }
    if (mounted) setState(() => _pdfLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final inv    = widget.inv;
    final fmt    = widget.fmt;
    final invNo  = inv['invoiceNumber'] as String? ?? '—';
    final plan   = inv['planName']      as String? ?? '—';
    final vCount = inv['vehicleCount']  as num?;
    final price  = (inv['pricePerVehicle'] as num?)?.toDouble();
    final start  = inv['periodStart']   as String? ?? '—';
    final end    = inv['periodEnd']     as String?;
    final amount = (inv['amount']       as num?)?.toDouble();
    final gst    = (inv['gstAmount']    as num?)?.toDouble();
    final total  = (inv['totalAmount']  as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(invNo,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
              const Spacer(),
              Text(fmt(total),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(plan,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.bodyText)),
          if (vCount != null && price != null)
            Text('${vCount.toInt()} vehicles × ₹${price.toStringAsFixed(0)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          Text('$start → ${end ?? '∞'}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Base: ${fmt(amount)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
              const SizedBox(width: 12),
              Text('GST: ${fmt(gst)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
              const Spacer(),
              GestureDetector(
                onTap: _viewPdf,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pdfLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.navy),
                      )
                    else
                      const Icon(Icons.picture_as_pdf_outlined,
                          size: 14, color: AppColors.navy),
                    const SizedBox(width: 4),
                    Text('View',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Card wrapper ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final Widget? titleTrailing;
  final Widget child;
  const _Card(
      {required this.title,
      required this.child,
      this.titleIcon,
      this.titleTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 16, color: AppColors.navy),
                  const SizedBox(width: 6),
                ],
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (titleTrailing != null) ...[
                  const Spacer(),
                  titleTrailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
