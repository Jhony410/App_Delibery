import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// Lets the bottom-tab screens drive the shell: switch tabs and open the
/// Buscar tab pre-filtered by a category. Exposed via an [InheritedWidget] so
/// children reach it with `MainShellScope.of(context)`.
class MainShellScope extends InheritedWidget {
  final void Function(int index) goToTab;

  /// Category slug the Buscar tab should filter by. `null` means "no filter"
  /// (show every store). Home writes to it and switches to the Buscar tab.
  final ValueNotifier<String?> searchCategory;

  const MainShellScope({
    super.key,
    required this.goToTab,
    required this.searchCategory,
    required super.child,
  });

  /// Opens the Buscar tab (index 1 in the bottom nav) applying [slug], or
  /// clearing the filter when null.
  void openSearch(String? slug) {
    searchCategory.value = slug;
    goToTab(1);
  }

  static MainShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final _searchCategory = ValueNotifier<String?>(null);

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _searchCategory.dispose();
    super.dispose();
  }

  void _goToTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      goToTab: _goToTab,
      searchCategory: _searchCategory,
      child: Scaffold(
        body: IndexedStack(index: _tab, children: _screens),
        bottomNavigationBar: _AppBottomNavBar(
          activeIndex: _tab,
          onTap: _goToTab,
        ),
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNavBar({
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('Inicio', Icons.home_rounded, Icons.home_outlined),
      ('Buscar', Icons.search_rounded, Icons.search),
      ('Pedidos', Icons.shopping_bag_rounded, Icons.shopping_bag_outlined),
      ('Perfil', Icons.person_rounded, Icons.person_outline),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = i == activeIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? tabs[i].$2 : tabs[i].$3,
                        size: 24,
                        color: isActive ? AppColors.primary : AppColors.textSubtle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isActive ? AppColors.primary : AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
