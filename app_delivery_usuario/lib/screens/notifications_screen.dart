import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(context),
          Expanded(
            child: uid == null
                ? const AppStateView(
                    icon: Icons.login_rounded,
                    title: 'Inicia sesión para ver tus notificaciones',
                  )
                : StreamBuilder<List<NotificationModel>>(
                    stream: DbService.streamUserNotifications(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              AppSkeleton(height: 94),
                              SizedBox(height: 10),
                              AppSkeleton(height: 94),
                            ],
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return const AppStateView(
                          icon: Icons.cloud_off_rounded,
                          title: 'No pudimos cargar tus notificaciones',
                          message:
                              'Revisa tu conexión. Se actualizarán automáticamente.',
                        );
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return const AppStateView(
                          icon: Icons.notifications_none_rounded,
                          title: 'No tienes notificaciones',
                          message:
                              'Aquí aparecerán las novedades de tus pedidos.',
                        );
                      }
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
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
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo marcar como leída'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.read
                ? Theme.of(context).colorScheme.outlineVariant
                : AppColors.primary,
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
                color: n.read
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 18,
                color: n.read
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (n.body.isNotEmpty) ...[
                    SizedBox(height: 3),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (n.createdAt != null) ...[
                    SizedBox(height: 6),
                    Text(
                      _formatDate(n.createdAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 4),
                decoration: BoxDecoration(
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
