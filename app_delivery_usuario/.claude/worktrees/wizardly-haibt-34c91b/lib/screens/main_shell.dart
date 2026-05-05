import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _AppBottomNavBar(
        activeIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
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
