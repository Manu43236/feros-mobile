import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

enum UploadStatus { idle, uploading, done, error }

class FerosFileUploadTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final String? uploadedUrl;
  final UploadStatus status;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isRequired;

  const FerosFileUploadTile({
    super.key,
    required this.label,
    required this.onTap,
    this.fileName,
    this.uploadedUrl,
    this.status = UploadStatus.idle,
    this.progress,
    this.onRemove,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.label,
            children: isRequired
                ? [const TextSpan(text: ' *', style: TextStyle(color: AppColors.error))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: status == UploadStatus.uploading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: status == UploadStatus.done
                  ? AppColors.successLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(
                color: status == UploadStatus.error
                    ? AppColors.error
                    : status == UploadStatus.done
                        ? AppColors.success
                        : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                _buildLeadingIcon(),
                const SizedBox(width: 12),
                Expanded(child: _buildContent()),
                if (status == UploadStatus.done && onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close, size: 18, color: AppColors.mutedText),
                  ),
              ],
            ),
          ),
        ),
        if (status == UploadStatus.uploading && progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
          ),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    switch (status) {
      case UploadStatus.idle:
        return const Icon(Icons.upload_file_outlined, size: 20, color: AppColors.mutedText);
      case UploadStatus.uploading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
        );
      case UploadStatus.done:
        return const Icon(Icons.check_circle_outline, size: 20, color: AppColors.success);
      case UploadStatus.error:
        return const Icon(Icons.error_outline, size: 20, color: AppColors.error);
    }
  }

  Widget _buildContent() {
    if (status == UploadStatus.idle) {
      return Text('Tap to upload', style: AppTextStyles.hint);
    }
    if (status == UploadStatus.uploading) {
      return Text('Uploading…', style: AppTextStyles.hint);
    }
    if (status == UploadStatus.error) {
      return Text('Upload failed — tap to retry', style: AppTextStyles.hint.copyWith(color: AppColors.error));
    }
    return Text(
      fileName ?? 'Uploaded',
      style: AppTextStyles.body,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
