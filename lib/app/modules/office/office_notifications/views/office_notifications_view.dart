import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/office_notifications_controller.dart';

class OfficeNotificationsView extends GetView<OfficeNotificationsController> {
  const OfficeNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          leading: GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
          title: Text(
            'lbl_notifications'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (controller.hasUnread)
              TextButton(
                onPressed: controller.markAllRead,
                child: Text('btn_mark_all_read'.tr,
                    style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ),
          ],
        ),
        body: _buildBody(controller),
      ));
  }

  Widget _buildBody(OfficeNotificationsController c) {
    if (c.state.value == ViewState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (c.state.value == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('lbl_failed_load_notifications'.tr,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 12),
            TextButton(onPressed: c.load, child: Text('btn_retry'.tr)),
          ],
        ),
      );
    }
    if (c.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 64, color: AppColors.mutedText.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('lbl_no_notifications_yet'.tr,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: c.load,
      color: AppColors.navy,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: c.notifications.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (_, i) => _NotifTile(n: c.notifications[i]),
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> n;
  const _NotifTile({required this.n});

  @override
  Widget build(BuildContext context) {
    final isRead    = n['isRead']    as bool?   ?? true;
    final type      = n['type']      as String? ?? 'SYSTEM';
    final title     = n['title']     as String? ?? '';
    final message   = n['message']   as String? ?? '';
    final createdAt = n['createdAt'] as String?;

    return Container(
      color: isRead ? Colors.white : const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _iconBg(type), shape: BoxShape.circle),
            child: Icon(_iconFor(type), size: 20, color: _iconColor(type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                          )),
                    ),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.info, shape: BoxShape.circle),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(_formatTime(createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'ATTENDANCE':              return Icons.fact_check_outlined;
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return Icons.warning_amber_outlined;
      case 'SUBSCRIPTION_ACTIVATED': return Icons.check_circle_outline;
      case 'BROADCAST':              return Icons.campaign_outlined;
      case 'TYRE_FITTED':
      case 'TYRE_ROTATION':
      case 'TYRE_EXPIRY':
      case 'TYRE_ROTATION_DUE':      return Icons.tire_repair_outlined;
      default:                        return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'ATTENDANCE':              return const Color(0xFFEFF6FF);
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return const Color(0xFFFFF7ED);
      case 'SUBSCRIPTION_ACTIVATED': return const Color(0xFFF0FDF4);
      case 'BROADCAST':              return const Color(0xFFF5F3FF);
      default:                        return const Color(0xFFF3F4F6);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'ATTENDANCE':              return AppColors.info;
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return AppColors.warning;
      case 'SUBSCRIPTION_ACTIVATED': return AppColors.success;
      case 'BROADCAST':              return const Color(0xFF7C3AED);
      default:                        return AppColors.mutedText;
    }
  }

  String _formatTime(String raw) {
    try {
      final dt   = DateTime.parse(raw).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'lbl_just_now'.tr;
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays == 1)    return 'lbl_yesterday'.tr;
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) { return ''; }
  }
}
