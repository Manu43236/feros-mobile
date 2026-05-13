import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/view_state.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _api = Get.find<ApiClient>();
  ViewState _state = ViewState.loading;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = ViewState.loading);
    try {
      final res = await _api.get(ApiEndpoints.notifications);
      final list = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      setState(() {
        _notifications = list.cast<Map<String, dynamic>>();
        _state = ViewState.success;
      });
      // Auto mark all read
      if (_notifications.any((n) => n['isRead'] == false)) {
        _markAllRead(silent: true);
      }
    } catch (_) {
      setState(() => _state = ViewState.error);
    }
  }

  Future<void> _markAllRead({bool silent = false}) async {
    try {
      await _api.patch(ApiEndpoints.notifMarkAllRead);
      if (!silent) {
        setState(() {
          _notifications = _notifications
              .map((n) => {...n, 'isRead': true})
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: () => _markAllRead(),
              child: Text(
                'Mark all read',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text('Failed to load notifications',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 64, color: AppColors.mutedText.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.navy,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, i) => _NotifTile(n: _notifications[i]),
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
    final isRead = n['isRead'] as bool? ?? true;
    final type = (n['type'] as String? ?? 'SYSTEM');
    final title = n['title'] as String? ?? '';
    final message = n['message'] as String? ?? '';
    final createdAt = n['createdAt'] as String?;

    return Container(
      color: isRead ? Colors.white : const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg(type),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(type), size: 20, color: _iconColor(type)),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.navy,
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(createdAt),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 11),
                  ),
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
      case 'ATTENDANCE':          return Icons.fact_check_outlined;
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return Icons.warning_amber_outlined;
      case 'SUBSCRIPTION_ACTIVATED': return Icons.check_circle_outline;
      case 'BROADCAST':           return Icons.campaign_outlined;
      case 'TYRE_FITTED':
      case 'TYRE_ROTATION':
      case 'TYRE_EXPIRY':
      case 'TYRE_ROTATION_DUE':  return Icons.tire_repair_outlined;
      default:                    return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'ATTENDANCE':          return const Color(0xFFEFF6FF);
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return const Color(0xFFFFF7ED);
      case 'SUBSCRIPTION_ACTIVATED': return const Color(0xFFF0FDF4);
      case 'BROADCAST':           return const Color(0xFFF5F3FF);
      default:                    return const Color(0xFFF3F4F6);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'ATTENDANCE':          return AppColors.info;
      case 'SUBSCRIPTION_EXPIRY':
      case 'TRIAL_ENDING':
      case 'SUBSCRIPTION_SUSPENDED': return AppColors.warning;
      case 'SUBSCRIPTION_ACTIVATED': return AppColors.success;
      case 'BROADCAST':           return const Color(0xFF7C3AED);
      default:                    return AppColors.mutedText;
    }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}
