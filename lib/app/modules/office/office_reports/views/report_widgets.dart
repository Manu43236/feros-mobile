import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

// ── Date presets ──────────────────────────────────────────────────────────────

const _presets = [
  {'id': 'week',      'label': 'This Week'},
  {'id': 'month',     'label': 'This Month'},
  {'id': 'lastMonth', 'label': 'Last Month'},
  {'id': 'custom',    'label': 'Custom'},
];

(DateTime, DateTime) presetDates(String preset) {
  final now = DateTime.now();
  switch (preset) {
    case 'week':
      return (now.subtract(Duration(days: now.weekday - 1)), now);
    case 'lastMonth':
      return (
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0),
      );
    default: // 'month'
      return (DateTime(now.year, now.month, 1), now);
  }
}

// ── Shared date filter bar ────────────────────────────────────────────────────

class ReportDateBar extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final String preset;
  final ValueChanged<String> onPreset;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const ReportDateBar({
    super.key,
    required this.from,
    required this.to,
    required this.preset,
    required this.onPreset,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((p) {
                final id      = p['id']!;
                final label   = p['label']!;
                final selected = preset == id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onPreset(id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.navy
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.navy
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.bodyText,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Date pickers (shown always so user can see range)
          const SizedBox(height: 8),
          Row(
            children: [
              _DateChip(
                label: _fmt(from),
                onTap: onPickFrom,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 14, color: AppColors.mutedText),
              ),
              _DateChip(
                label: _fmt(to),
                onTap: onPickTo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);
}

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: AppColors.navy),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Summary strip ─────────────────────────────────────────────────────────────

class ReportSummaryStrip extends StatelessWidget {
  final List<({String label, String value, Color? color})> items;
  const ReportSummaryStrip({super.key, required this.items});

  factory ReportSummaryStrip.items(
          List<({String label, String value, Color? color})> items) =>
      ReportSummaryStrip(items: items);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: items
            .expand((item) => [
                  Expanded(child: _SummaryItem(label: item.label, value: item.value, color: item.color)),
                  if (item != items.last)
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.2)),
                ])
            .toList(),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryItem(
      {required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontFamily: 'Inter',
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class ReportLoadingList extends StatelessWidget {
  const ReportLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const _Shimmer(),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class ReportEmptyState extends StatelessWidget {
  final String message;
  const ReportEmptyState({super.key, this.message = 'No data for this period'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 52, color: AppColors.mutedText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

class ReportErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const ReportErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load report',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Status chip helper ────────────────────────────────────────────────────────

class ReportStatusChip extends StatelessWidget {
  final String status;
  final Map<String, Color> colorMap;
  final Map<String, String>? labelMap;

  const ReportStatusChip({
    super.key,
    required this.status,
    required this.colorMap,
    this.labelMap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorMap[status] ?? AppColors.mutedText;
    final label = labelMap?[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const ReportCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: child,
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class ReportSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const ReportSearchBar(
      {super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.body.copyWith(color: AppColors.mutedText),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ── Date helper ───────────────────────────────────────────────────────────────

String fmtApiDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(2020),
      lastDate: last ?? DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

// ── Section shell (AppBar + tile list) ────────────────────────────────────────

class ReportSectionShell extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<ReportTile> tiles;

  const ReportSectionShell({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ReportTileCard(tile: tiles[i], accentColor: color),
      ),
    );
  }
}

class ReportTile {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  const ReportTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });
}

class _ReportTileCard extends StatelessWidget {
  final ReportTile tile;
  final Color accentColor;
  const _ReportTileCard({required this.tile, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x07000000), blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tile.icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.label,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(tile.description,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        maxLines: 2),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
