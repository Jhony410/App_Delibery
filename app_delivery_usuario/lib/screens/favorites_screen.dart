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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(context),
          Expanded(
            child: uid == null
                ? const _EmptyState()
                : StreamBuilder<List<FavoriteModel>>(
                    stream: DbService.streamUserFavorites(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      final favs = snap.data ?? [];
                      if (favs.isEmpty) return const _EmptyState();
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
            child: Text('Favoritos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ImgPlaceholder(
              label: fav.storeName.isEmpty
                  ? ''
                  : fav.storeName.split(' ')[0],
              height: 56,
              width: 56,
              radius: 10,
              assetPath: assetForKey(fav.storeId),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fav.storeName.isEmpty ? 'Comercio' : fav.storeName,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                try {
                  await DbService.toggleFavorite(
                      uid, fav.storeId, fav.storeName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${fav.storeName} quitado de favoritos'),
                      duration: const Duration(seconds: 1),
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No se pudo quitar de favoritos'),
                      backgroundColor: AppColors.danger,
                    ));
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.favorite, size: 20, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
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
          Icon(Icons.favorite_border, size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text('Sin favoritos aún',
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Toca el corazón de un comercio para guardarlo',
              style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
        ],
      ),
    );
  }
}
