import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/popups/feros_dialog.dart';
import '../controllers/supervisor_meter_reading_controller.dart';

class SupervisorMeterReadingView extends GetView<SupervisorMeterReadingController> {
  const SupervisorMeterReadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meter Readings'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'meter_reading_fab',
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final r        = controller.readings();
        final total    = r.length;
        final vehicles = r.map((x) => x['vehicleId']).toSet().length;
        final alerts   = r.fold<int>(0, (s, x) => s + ((x['serviceAlerts'] as List?)?.length ?? 0));
        return RefreshIndicator(
          onRefresh: controller.fetchAll,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _StatsRow(total: total, vehicles: vehicles, alerts: alerts)),
              SliverToBoxAdapter(child: _FilterRow(ctrl: controller)),
              if (controller.readings.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed_outlined, size: 48, color: AppColors.mutedText),
                        SizedBox(height: 12),
                        Text('No readings found', style: TextStyle(color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReadingCard(
                      reading: controller.readings[index],
                      onDelete: () => _confirmDelete(context, controller.readings[index]),
                    ),
                    childCount: controller.readings.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> reading) async {
    final confirmed = await FerosDialog.confirm(
      title: 'Delete Reading',
      message: 'Remove ${reading['readingKm']} km reading for ${reading['vehicleRegistrationNumber']}?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed) controller.deleteReading(reading['id'] as int);
  }

  void _showAddSheet(BuildContext context) {
    if (!context.mounted) return;
    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReadingSheet(ctrl: controller),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int total, vehicles, alerts;
  const _StatsRow({required this.total, required this.vehicles, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatChip(label: 'Readings', value: '$total', color: AppColors.navy),
          _StatChip(label: 'Vehicles', value: '$vehicles', color: Colors.blue),
          _StatChip(
            label: 'Alerts',
            value: '$alerts',
            color: alerts > 0 ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.8), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final SupervisorMeterReadingController ctrl;
  const _FilterRow({required this.ctrl});

  static const _filters = [
    ('ALL', 'All'),
    ('TRIP_START', 'Trip Start'),
    ('TRIP_END', 'Trip End'),
    ('FUEL_FILL', 'Fuel Fill'),
    ('GENERAL', 'General'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.filterType.value;
      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final (value, label) = _filters[i];
            final isSelected = selected == value;
            return GestureDetector(
              onTap: () => ctrl.onFilterChanged(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.navy : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.bodyText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Reading Card ──────────────────────────────────────────────────────────────
class _ReadingCard extends StatelessWidget {
  final Map<String, dynamic> reading;
  final VoidCallback onDelete;
  const _ReadingCard({required this.reading, required this.onDelete});

  static const _typeColors = {
    'TRIP_START': Colors.green,
    'TRIP_END':   Colors.red,
    'FUEL_FILL':  Colors.orange,
    'GENERAL':    Colors.blueGrey,
  };

  static const _typeLabels = {
    'TRIP_START': 'Trip Start',
    'TRIP_END':   'Trip End',
    'FUEL_FILL':  'Fuel Fill',
    'GENERAL':    'General',
  };

  @override
  Widget build(BuildContext context) {
    final type   = reading['readingType'] as String? ?? 'GENERAL';
    final alerts = (reading['serviceAlerts'] as List? ?? []).cast<Map<String, dynamic>>();
    final km     = reading['readingKm'];
    final color  = _typeColors[type] ?? Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reading['vehicleRegistrationNumber'] as String? ?? '-',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _typeLabels[type] ?? type,
                    style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.speed_outlined, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  '$km km',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.person_outline, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reading['recordedByName'] as String? ?? '-',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (reading['recordedAt'] != null)
                  Text(
                    _formatDate(reading['recordedAt'] as String),
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
              ],
            ),
            if (reading['notes'] != null) ...[
              const SizedBox(height: 3),
              Text(
                reading['notes'] as String,
                style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
              ),
            ],
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: alerts.map((a) {
                  final overdue = a['status'] == 'OVERDUE';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: overdue ? AppColors.error.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: overdue ? AppColors.error.withValues(alpha: 0.4) : AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_outlined, size: 12,
                            color: overdue ? AppColors.error : AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${a['serviceType'] ?? 'Service'} — ${overdue ? 'Overdue' : 'Due soon'}',
                          style: AppTextStyles.caption.copyWith(
                            color: overdue ? AppColors.error : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (reading['photoUrl'] != null)
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(reading['photoUrl'] as String)),
                    icon: const Icon(Icons.photo_outlined, size: 17),
                    color: AppColors.navy,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 17),
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Add Reading Sheet ─────────────────────────────────────────────────────────
class _AddReadingSheet extends StatefulWidget {
  final SupervisorMeterReadingController ctrl;
  const _AddReadingSheet({required this.ctrl});

  @override
  State<_AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends State<_AddReadingSheet> {
  int?   _vehicleId;
  String _type     = 'GENERAL';
  File?  _photo;
  bool   _scanning = false;

  final _kmCtrl    = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _types = [
    ('GENERAL',    'General'),
    ('TRIP_START', 'Trip Start'),
    ('TRIP_END',   'Trip End'),
    ('FUEL_FILL',  'Fuel Fill'),
  ];

  @override
  void dispose() {
    _kmCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (xFile == null) return;
    setState(() { _photo = File(xFile.path); _scanning = true; });
    try {
      final inputImage = InputImage.fromFile(_photo!);
      final recognizer = TextRecognizer();
      final result     = await recognizer.processImage(inputImage);
      recognizer.close();
      final candidates = <int>{};
      RegExp(r'\d{4,7}').allMatches(result.text).forEach((m) {
        final v = int.tryParse(m.group(0)!);
        if (v != null) candidates.add(v);
      });
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final digits = line.elements.map((e) => e.text).join('').replaceAll(RegExp(r'[^\d]'), '');
          if (digits.length >= 4 && digits.length <= 7) {
            final v = int.tryParse(digits);
            if (v != null) candidates.add(v);
          }
        }
      }
      if (candidates.isNotEmpty) {
        final sorted = candidates.toList()..sort((a, b) => b.compareTo(a));
        _kmCtrl.text = sorted.first.toString();
      }
    } catch (_) {}
    setState(() => _scanning = false);
  }

  Future<void> _save() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a vehicle')),
      );
      return;
    }
    final km = double.tryParse(_kmCtrl.text.trim());
    if (km == null || km <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid km reading')),
      );
      return;
    }
    final ok = await widget.ctrl.addReading(
      vehicleId:  _vehicleId!,
      readingKm:  km,
      readingType: _type,
      photoFile:  _photo,
      notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.ctrl.vehicles;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Meter Reading', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 16),

            // Vehicle dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Vehicle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: DropdownButton<int>(
                value: _vehicleId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select Vehicle'),
                items: vehicles.map((v) {
                  return DropdownMenuItem<int>(
                    value: v['id'] as int,
                    child: Text(v['registrationNumber'] as String? ?? ''),
                  );
                }).toList(),
                onChanged: (id) => setState(() => _vehicleId = id),
              ),
            ),
            const SizedBox(height: 12),

            // Reading type chips
            Text('Type', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final (value, label) = t;
                final selected = _type == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = value),
                  selectedColor: AppColors.navy,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.bodyText,
                    fontSize: 13,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Photo + OCR
            GestureDetector(
              onTap: _scanning ? null : _takePhoto,
              child: Container(
                width: double.infinity,
                height: _photo != null ? 140 : 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: _photo != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(_photo!, width: double.infinity, height: 140, fit: BoxFit.cover),
                          ),
                          if (_scanning)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    SizedBox(height: 6),
                                    Text('Reading...', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Retake', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 24, color: AppColors.mutedText),
                          const SizedBox(height: 4),
                          Text('Tap to photo odometer (auto-reads)', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // KM input
            TextField(
              controller: _kmCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer Reading',
                suffixText: 'km',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.ctrl.isSaving.value ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: widget.ctrl.isSaving.value
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Reading'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
