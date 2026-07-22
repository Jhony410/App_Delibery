import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/notification_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(context),
          Expanded(
            child: uid == null
                ? const _EmptyState()
                : StreamBuilder<List<NotificationModel>>(
                    stream: DbService.streamUserNotifications(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) return const _EmptyState();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: items.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _tile(context, uid, items[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Notificaciones',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String uid, NotificationModel n) {
    return GestureDetector(
      onTap: n.read
          ? null
          : () async {
              try {
                await DbService.markNotificationRead(uid, n.id);
              } catch (_) {}
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.read ? AppColors.border : AppColors.primary,
            width: n.read ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: n.read ? AppColors.bg : AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.notifications_none,
                  size: 18,
                  color: n.read ? AppColors.textMuted : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.body,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.35)),
                  ],
                  if (n.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(_formatDate(n.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSubtle)),
                  ],
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text('Sin notificaciones',
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
