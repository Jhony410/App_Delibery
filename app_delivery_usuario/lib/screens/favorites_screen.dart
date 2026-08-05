import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/favorite_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
                    title: 'Inicia sesión para ver tus favoritos',
                  )
                : StreamBuilder<List<FavoriteModel>>(
                    stream: DbService.streamUserFavorites(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              AppSkeleton(height: 78),
                              SizedBox(height: 10),
                              AppSkeleton(height: 78),
                            ],
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return const AppStateView(
                          icon: Icons.cloud_off_rounded,
                          title: 'No pudimos cargar tus favoritos',
                          message: 'Revisa tu conexión e inténtalo nuevamente.',
                        );
                      }
                      final favs = snap.data ?? [];
                      if (favs.isEmpty) {
                        return const AppStateView(
                          icon: Icons.favorite_border_rounded,
                          title: 'Aún no tienes favoritos',
                          message:
                              'Toca el corazón de un comercio para guardarlo.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: favs.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _tile(context, uid, favs[i]),
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
              'Favoritos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String uid, FavoriteModel fav) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/store', arguments: fav.storeId),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            ImgPlaceholder(
              label: fav.storeName.isEmpty ? '' : fav.storeName.split(' ')[0],
              height: 56,
              width: 56,
              radius: 10,
              assetPath: assetForKey(fav.storeId),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fav.storeName.isEmpty ? 'Comercio' : fav.storeName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Quitar de favoritos',
              onPressed: () async {
                try {
                  await DbService.toggleFavorite(
                    uid,
                    fav.storeId,
                    fav.storeName,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${fav.storeName} quitado de favoritos'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo quitar de favoritos'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.favorite, size: 20, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
