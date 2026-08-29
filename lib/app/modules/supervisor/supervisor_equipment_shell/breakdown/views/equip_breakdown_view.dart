import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/widgets/feros_select_field.dart';
import '../controllers/equip_breakdown_controller.dart';

class EquipBreakdownView extends GetView<EquipBreakdownController> {
  const EquipBreakdownView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedEquipmentId = Rxn<int>();
    final reasonCtrl          = TextEditingController();
    final locationCtrl        = TextEditingController();
    final notesCtrl           = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.equipSidebar,
        foregroundColor: Colors.white,
        title: const Text(
          'Report Breakdown',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (!controller.machinesLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.equipSidebar),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Report a machine breakdown. The service team will be notified.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Machine selector ──────────────────────────────
              Obx(() {
                final machines = controller.machines;
                if (machines.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'No active machines found.\nMachines appear when a work order is IN_PROGRESS.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final idx = machines.indexWhere(
                    (a) => a['equipmentId'] == selectedEquipmentId.value);
                final sel = idx >= 0 ? machines[idx] : null;
                final display = sel == null
                    ? null
                    : () {
                        final s = sel['serialNumber'] as String? ?? '—';
                        final t = sel['equipmentTypeName'] as String? ?? '';
                        return t.isNotEmpty ? '$s · $t' : s;
                      }();
                return FerosSelectField<Map<String, dynamic>>(
                  label: 'Machine',
                  title: 'Select Machine',
                  hint: 'Select machine',
                  items: machines.toList(),
                  itemLabel: (a) {
                    final s = a['serialNumber'] as String? ?? '—';
                    final t = a['equipmentTypeName'] as String? ?? '';
                    return t.isNotEmpty ? '$s · $t' : s;
                  },
                  selectedDisplay: display,
                  onSelected: (a) =>
                      selectedEquipmentId.value = a['equipmentId'] as int,
                );
              }),
              const SizedBox(height: 18),

              // ── Reason (required) ────────────────────────────
              _Label('Reason *'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: AppTextStyles.body,
                decoration: _decor(hint: 'Describe what happened…'),
              ),
              const SizedBox(height: 18),

              // ── Location (optional) ──────────────────────────
              _Label('Location (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: locationCtrl,
                style: AppTextStyles.body,
                decoration:
                    _decor(hint: 'e.g. Site A – Block 3'),
              ),
              const SizedBox(height: 18),

              // ── Notes (optional) ─────────────────────────────
              _Label('Notes (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: AppTextStyles.body,
                decoration: _decor(hint: 'Any additional details…'),
              ),
              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────
              Obx(() {
                final loading = controller.submitting.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final equipId = selectedEquipmentId.value;
                            final reason  = reasonCtrl.text.trim();

                            if (equipId == null) {
                              FerosSnackbar.error('Select a machine');
                              return;
                            }
                            if (reason.isEmpty) {
                              FerosSnackbar.error('Reason is required');
                              return;
                            }

                            final ok = await controller.reportBreakdown(
                              equipmentId: equipId,
                              reason: reason,
                              location: locationCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                            );

                            if (ok) {
                              FerosSnackbar.success('Breakdown reported');
                              Get.back();
                            } else {
                              FerosSnackbar.error('Failed to report breakdown');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.error.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Report Breakdown',
                            style: AppTextStyles.bodySemiBold
                                .copyWith(color: Colors.white),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  InputDecoration _decor({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppColors.equipSidebar),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.bodyText,
          fontWeight: FontWeight.w600,
        ),
      );
}
