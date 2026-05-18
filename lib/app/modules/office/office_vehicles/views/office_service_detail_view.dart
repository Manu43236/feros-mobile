import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/popups/feros_snackbar.dart';

String _fmtDate(dynamic d) {
  if (d == null) return '—';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
  } catch (_) {
    return '—';
  }
}

String _fmtDateTime(dynamic d) {
  if (d == null) return '—';
  try {
    return DateFormat(
      'dd MMM yyyy, h:mm a',
    ).format(DateTime.parse(d.toString()).toLocal());
  } catch (_) {
    return '—';
  }
}

class OfficeServiceDetailView extends StatefulWidget {
  final Map<String, dynamic> service;
  const OfficeServiceDetailView({super.key, required this.service});

  @override
  State<OfficeServiceDetailView> createState() =>
      _OfficeServiceDetailViewState();
}

class _OfficeServiceDetailViewState extends State<OfficeServiceDetailView> {
  final _api = Get.find<ApiClient>();

  late Map<String, dynamic> _service;
  List<Map<String, dynamic>> _parts = [];
  Map<String, dynamic>? _invoice;
  bool _loadingParts = true;
  bool _loadingInvoice = false;

  @override
  void initState() {
    super.initState();
    _service = Map<String, dynamic>.from(widget.service);
    _loadParts();
    if (_status == 'COMPLETED') {
      _loadingInvoice = true;
      _loadInvoice();
    }
  }

  String get _status => _service['status'] as String? ?? 'OPEN';

  Future<void> _loadParts() async {
    try {
      final res = await _api.get(
        ApiEndpoints.servicePartsByService(_service['id'] as int),
      );
      final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _parts = data.cast<Map<String, dynamic>>();
          _loadingParts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingParts = false);
    }
  }

  Future<void> _loadInvoice() async {
    try {
      final res = await _api.get(
        ApiEndpoints.serviceInvoiceByService(_service['id'] as int),
      );
      final data = (res.data as Map<String, dynamic>)['data'];
      if (mounted) {
        setState(() {
          _invoice = data as Map<String, dynamic>?;
          _loadingInvoice = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  Future<void> _viewPdf(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'] as int?;
    if (invoiceId == null) return;
    try {
      final bytes = await _api.getBytes(
        ApiEndpoints.serviceInvoicePdf(invoiceId),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/service_invoice_$invoiceId.pdf');
      await file.writeAsBytes(bytes);
      Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {'filePath': file.path, 'title': 'Service Invoice'},
      );
    } catch (e) {
      FerosSnackbar.error('Could not load PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    final num = _service['serviceNumber'] as String? ?? '—';
    final status = _service['displayStatus'] as String? ?? _status;
    final triggeredBy = _service['triggeredBy'] as String?;
    final serviceType = _service['serviceType'] as String?;
    final vendor = _service['vendorName'] as String?;
    final location = _service['location'] as String?;
    final serviceDate = _service['serviceDate'] as String?;
    final startedAt = _service['startedAt'] as String?;
    final completedAt = _service['completedAt'] as String?;
    final odometer = _service['odometer'];
    final dueAt = _service['dueAtOdometer'];
    final totalCost = _service['totalCost'];
    final notes = _service['notes'] as String?;
    final tasks =
        (_service['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final (statusColor, statusBg, statusLabel) = _statusStyle(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          num,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Status + Chips ──────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Chip(label: statusLabel, bg: statusBg, fg: statusColor),
                    if (triggeredBy != null) ...[
                      const SizedBox(width: 6),
                      _Chip(
                        label: _triggerLabel(triggeredBy),
                        bg: const Color(0xFFF5F3FF),
                        fg: const Color(0xFF6D28D9),
                      ),
                    ],
                    if (serviceType != null) ...[
                      const SizedBox(width: 6),
                      _Chip(
                        label: _typeLabel(serviceType, vendor),
                        bg: AppColors.background,
                        fg: AppColors.mutedText,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow('Service No', num),
                if (serviceDate != null)
                  _InfoRow('Service Date', _fmtDate(serviceDate)),
                if (startedAt != null)
                  _InfoRow('Started', _fmtDateTime(startedAt)),
                if (completedAt != null)
                  _InfoRow('Completed', _fmtDateTime(completedAt)),
                if (odometer != null) _InfoRow('Odometer', '$odometer km'),
                if (dueAt != null) _InfoRow('Due at', '$dueAt km'),
                if (location != null) _InfoRow('Location', location),
                if (totalCost != null)
                  _InfoRow(
                    'Total Cost',
                    '₹$totalCost',
                    valueColor: AppColors.success,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tasks ────────────────────────────────────────────────────────
          if (tasks.isNotEmpty) ...[
            _SectionTitle('Tasks'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: tasks.asMap().entries.map((e) {
                  final task = e.value;
                  final isLast = e.key == tasks.length - 1;
                  final tName =
                      task['taskTypeName'] as String? ??
                      task['customName'] as String? ??
                      '—';
                  final tStatus = task['status'] as String? ?? 'PENDING';
                  final recurring = task['isRecurring'] as bool? ?? false;
                  final freqKm = task['frequencyKm'];
                  final isDone = tStatus == 'COMPLETED';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isDone
                              ? AppColors.success
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDone
                                      ? AppColors.mutedText
                                      : AppColors.bodyText,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (recurring && freqKm != null)
                                Text(
                                  'Every ${freqKm}km',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _Chip(
                          label: isDone ? 'Done' : 'Pending',
                          bg: isDone
                              ? const Color(0xFFF0FDF4)
                              : AppColors.background,
                          fg: isDone ? AppColors.success : AppColors.mutedText,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Spare Parts ──────────────────────────────────────────────────
          _SectionTitle('Spare Parts'),
          const SizedBox(height: 8),
          if (_loadingParts)
            const _LoadingCard()
          else if (_parts.isEmpty)
            _Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No parts requested',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            )
          else
            _Card(
              child: Column(
                children: _parts.asMap().entries.map((e) {
                  final part = e.value;
                  final isLast = e.key == _parts.length - 1;
                  final pName = part['partName'] as String? ?? '—';
                  final pStatus = part['status'] as String? ?? '';
                  final qty = part['quantity'];
                  final unit = part['unit'] as String?;
                  final (pColor, pBg, pLabel) = _partStatusStyle(pStatus);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.bodyText,
                                ),
                              ),
                              if (qty != null)
                                Text(
                                  'Qty: $qty${unit != null ? " $unit" : ""}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _Chip(label: pLabel, bg: pBg, fg: pColor),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),

          // ── Invoice ──────────────────────────────────────────────────────
          if (_status == 'COMPLETED') ...[
            _SectionTitle('Service Invoice'),
            const SizedBox(height: 8),
            if (_loadingInvoice)
              const _LoadingCard()
            else if (_invoice == null)
              _Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No invoice generated',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
              )
            else
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      'Invoice No',
                      _invoice!['invoiceNumber'] as String? ?? '—',
                    ),
                    _InfoRow('Status', _invoice!['status'] as String? ?? '—'),
                    if (_invoice!['totalAmount'] != null)
                      _InfoRow(
                        'Amount',
                        '₹${_invoice!['totalAmount']}',
                        valueColor: AppColors.success,
                      ),
                    if (_invoice!['invoiceDate'] != null)
                      _InfoRow('Date', _fmtDate(_invoice!['invoiceDate'])),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _viewPdf(_invoice!),
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 16,
                        ),
                        label: const Text('View Invoice PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.navy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],

          // ── Notes ────────────────────────────────────────────────────────
          if (notes != null && notes.isNotEmpty) ...[
            _SectionTitle('Notes'),
            const SizedBox(height: 8),
            _Card(
              child: Text(
                notes,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static (Color, Color, String) _statusStyle(String s) {
    switch (s) {
      case 'OPEN':
        return (const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), 'Open');
      case 'IN_PROGRESS':
        return (
          const Color(0xFFC2410C),
          const Color(0xFFFFF7ED),
          'In Progress',
        );
      case 'COMPLETED':
        return (const Color(0xFF15803D), const Color(0xFFF0FDF4), 'Completed');
      case 'OVERDUE':
        return (const Color(0xFFB91C1C), const Color(0xFFFEF2F2), 'Overdue');
      case 'DUE_SOON':
        return (const Color(0xFFB45309), const Color(0xFFFFFBEB), 'Due Soon');
      default:
        return (AppColors.mutedText, AppColors.background, s);
    }
  }

  static (Color, Color, String) _partStatusStyle(String s) {
    switch (s) {
      case 'REQUESTED':
        return (const Color(0xFFB45309), const Color(0xFFFFFBEB), 'Requested');
      case 'APPROVED':
        return (const Color(0xFF15803D), const Color(0xFFF0FDF4), 'Approved');
      case 'REJECTED':
        return (const Color(0xFFB91C1C), const Color(0xFFFEF2F2), 'Rejected');
      default:
        return (AppColors.mutedText, AppColors.background, s);
    }
  }

  static String _triggerLabel(String t) {
    const m = {
      'SCHEDULED': 'Scheduled',
      'BREAKDOWN': 'Breakdown',
      'ACCIDENT': 'Accident',
      'COMPLIANCE': 'Compliance',
      'WARRANTY': 'Warranty',
    };
    return m[t] ?? t;
  }

  static String _typeLabel(String t, String? vendor) {
    if (t == 'INTERNAL') return 'Internal';
    if (t == 'OEM_CENTER') return 'OEM${vendor != null ? ": $vendor" : ""}';
    return vendor ?? '3rd Party';
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.mutedText,
        fontSize: 13,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: valueColor ?? AppColors.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2),
      ),
    );
  }
}
