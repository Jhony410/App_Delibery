import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../services/db_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<StoreModel> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await DbService.searchStores(q.trim());
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 19, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            autofocus: true,
                            onChanged: _search,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'Busca tiendas o productos…',
                              hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSubtle,
                                  fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() => _results = []);
                            },
                            child: const Icon(Icons.close,
                                size: 18, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.bg,
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _ctrl.text.isEmpty
                      ? const Center(
                          child: Text('Escribe para buscar tiendas',
                              style: TextStyle(color: AppColors.textMuted)))
                      : _results.isEmpty
                          ? const Center(
                              child: Text('Sin resultados',
                                  style:
                                      TextStyle(color: AppColors.textMuted)))
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const Text('COMERCIOS',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                        letterSpacing: 0.06)),
                                const SizedBox(height: 10),
                                ..._results.map((store) => GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                          context, '/store',
                                          arguments: store.id),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            ImgPlaceholder(
                                              label: store.name.split(' ')[0],
                                              height: 56,
                                              width: 56,
                                              tone: store.tone,
                                              radius: 10,
                                              assetPath: assetForKey(store.id),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(store.name,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  const SizedBox(height: 2),
                                                  Text(store.category,
                                                      style: const TextStyle(
                                                          fontSize: 11.5,
                                                          color: AppColors
                                                              .textMuted)),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.star_rounded,
                                                          size: 11,
                                                          color: AppColors.star),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                          store.rating
                                                              .toStringAsFixed(
                                                                  1),
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                      Text(
                                                          ' · ${store.deliveryTime} min',
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppColors
                                                                  .textMuted)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right,
                                                size: 18,
                                                color: AppColors.textSubtle),
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
