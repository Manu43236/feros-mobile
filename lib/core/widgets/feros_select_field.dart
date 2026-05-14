import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// A reusable searchable select field for the entire FEROS app.
///
/// Renders as a tappable form field. On tap, opens a dialog with:
/// - Navy header + title + close button
/// - Search box
/// - Shimmer rows while [isLoading] is true
/// - "No [emptyMessage] found" when [items] is empty and not loading
/// - Filtered list of selectable items
///
/// Usage:
/// ```dart
/// FerosSelectField<Map<String, dynamic>>(
///   label: 'Client',
///   title: 'Select Client',
///   hint: 'Select client',
///   isRequired: true,
///   selectedDisplay: selectedClient?['clientName'],
///   items: _clients,
///   itemLabel: (c) => c['clientName'] as String,
///   onSelected: (c) => setState(() => selectedClient = c),
///   isLoading: _isLoadingClients,
///   errorText: _errors['client'],
/// )
/// ```
class FerosSelectField<T> extends StatelessWidget {
  final String label;
  final String title;
  final String hint;
  final bool isRequired;
  final String? selectedDisplay;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onSelected;
  final bool isLoading;
  final String? errorText;
  final String? emptyMessage;
  final bool enabled;

  const FerosSelectField({
    super.key,
    required this.label,
    required this.title,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.isRequired = false,
    this.selectedDisplay,
    this.isLoading = false,
    this.errorText,
    this.emptyMessage,
    this.enabled = true,
  });

  void _open(BuildContext context) {
    if (!enabled) return;
    showDialog<T>(
      context: context,
      builder: (_) => _FerosSelectDialog<T>(
        title: title,
        items: items,
        itemLabel: itemLabel,
        isLoading: isLoading,
        emptyMessage: emptyMessage ?? 'No ${title.toLowerCase()} found',
      ),
    ).then((selected) {
      if (selected != null) onSelected(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError  = errorText != null && errorText!.isNotEmpty;
    final isSelected = selectedDisplay != null && selectedDisplay!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────────────────────
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.label.copyWith(
              color: enabled ? AppColors.bodyText : AppColors.mutedText,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),

        // ── Tappable field ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.background : AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius + 2),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : enabled
                        ? AppColors.border
                        : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSelected ? selectedDisplay! : hint,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected
                          ? (enabled ? AppColors.bodyText : AppColors.mutedText)
                          : AppColors.hintText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: enabled ? AppColors.mutedText : AppColors.hintText,
                ),
              ],
            ),
          ),
        ),

        // ── Error text ─────────────────────────────────────────────────────
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

// ── Dialog ─────────────────────────────────────────────────────────────────────
class _FerosSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final bool isLoading;
  final String emptyMessage;

  const _FerosSelectDialog({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.isLoading,
    required this.emptyMessage,
  });

  @override
  State<_FerosSelectDialog<T>> createState() => _FerosSelectDialogState<T>();
}

class _FerosSelectDialogState<T> extends State<_FerosSelectDialog<T>> {
  final _searchCtrl   = TextEditingController();
  final _searchFocus  = FocusNode();
  List<T> _filtered   = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    // Auto-focus search after dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(_FerosSelectDialog<T> old) {
    super.didUpdateWidget(old);
    // Items arrived while dialog was open (shimmer → list)
    if (old.isLoading && !widget.isLoading) {
      _applyFilter(_searchCtrl.text);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(widget.items)
          : widget.items
              .where((item) =>
                  widget.itemLabel(item).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenH * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Navy Header ──────────────────────────────────────────────
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Search Box ───────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: _applyFilter,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                  hintStyle: AppTextStyles.hint,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (_, val, __) => val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: AppColors.mutedText),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter('');
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── List / Shimmer / Empty ───────────────────────────────────
            Flexible(
              child: widget.isLoading
                  ? _ShimmerList()
                  : _filtered.isEmpty
                      ? _EmptyState(message: widget.emptyMessage)
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final item  = _filtered[i];
                            final label = widget.itemLabel(item);
                            final query = _searchCtrl.text.trim().toLowerCase();
                            return _SelectItem(
                              label: label,
                              query: query,
                              onTap: () => Navigator.of(context).pop(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List Item with highlight ───────────────────────────────────────────────────
class _SelectItem extends StatelessWidget {
  final String label;
  final String query;
  final VoidCallback onTap;

  const _SelectItem({
    required this.label,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: query.isEmpty
            ? Text(label, style: AppTextStyles.body)
            : _HighlightedText(label: label, query: query),
      ),
    );
  }
}

// ── Highlight matching query in label ─────────────────────────────────────────
class _HighlightedText extends StatelessWidget {
  final String label;
  final String query;

  const _HighlightedText({required this.label, required this.query});

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final start = lower.indexOf(query);
    if (start == -1) return Text(label, style: AppTextStyles.body);

    final end = start + query.length;
    return RichText(
      text: TextSpan(
        style: AppTextStyles.body,
        children: [
          if (start > 0) TextSpan(text: label.substring(0, start)),
          TextSpan(
            text: label.substring(start, end),
            style: AppTextStyles.body.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              backgroundColor: AppColors.navy.withValues(alpha: 0.08),
            ),
          ),
          if (end < label.length) TextSpan(text: label.substring(end)),
        ],
      ),
    );
  }
}

// ── Shimmer rows ──────────────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 40, color: AppColors.mutedText),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
