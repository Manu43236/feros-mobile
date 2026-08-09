import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../popups/feros_snackbar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DeliveryResult {
  final double weight;
  DeliveryResult({required this.weight});
}

Future<DeliveryResult?> showDeliverySheet(
  BuildContext context, {
  required double endOdometer,
  double? loadedWeight,
}) async {
  final weightController = TextEditingController(
    text: loadedWeight != null ? loadedWeight.toStringAsFixed(1) : '',
  );

  return await showModalBottomSheet<DeliveryResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom + 24,
      ),
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
          Text('btn_confirm_delivery'.tr,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(
            'End ODM: ${endOdometer.toStringAsFixed(0)} km'
            '${loadedWeight != null ? '   •   Loaded: ${loadedWeight.toStringAsFixed(1)} T' : ''}',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              labelText: 'lbl_delivered_weight_t'.tr,
              labelStyle:
                  AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              suffixText: 'T',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.navy),
              ),
            ),
          ),
          if (loadedWeight != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'lbl_delivery_loaded_ref'.trParams({'value': loadedWeight.toStringAsFixed(1)}),
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text.trim());
                if (weight == null || weight <= 0) {
                  FerosSnackbar.error('err_invalid_delivery_weight'.tr);
                  return;
                }
                Navigator.of(ctx).pop(DeliveryResult(weight: weight));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('btn_confirm_delivery'.tr,
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
