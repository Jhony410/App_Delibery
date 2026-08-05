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

  void _goToTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return MainTabBackHandler(
      activeIndex: _tab,
      onBackToHome: () => _goToTab(0),
      child: MainShellScope(
        goToTab: _goToTab,
        searchCategory: _searchCategory,
        child: Scaffold(
          body: IndexedStack(index: _tab, children: _screens),
          bottomNavigationBar: AppBottomNavBar(
            activeIndex: _tab,
            onTap: _goToTab,
          ),
        ),
      ),
    );
  }
}

class MainTabBackHandler extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onBackToHome;
  final Widget child;

  const MainTabBackHandler({
    super.key,
    required this.activeIndex,
    required this.onBackToHome,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: activeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && activeIndex != 0) onBackToHome();
      },
      child: child,
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        boxShadow: context.isDark ? null : AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = i == activeIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: tabs[i].$1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? context.colors.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? tabs[i].$2 : tabs[i].$3,
                            size: 23,
                            color: isActive
                                ? context.colors.primary
                                : context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tabs[i].$1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isActive
                                  ? context.colors.primary
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
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
