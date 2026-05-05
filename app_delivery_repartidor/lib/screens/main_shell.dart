import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'orders_history_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    OrdersHistoryScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _CourierTabBar(
        active: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _CourierTabBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onTap;

  const _CourierTabBar({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Inicio', Icons.home_outlined, Icons.home_rounded),
      ('Pedidos', Icons.list_alt_outlined, Icons.list_alt_rounded),
      ('Billetera', Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded),
      ('Perfil', Icons.person_outline_rounded, Icons.person_rounded),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: CourierColors.surface,
        border: Border(
          top: BorderSide(color: CourierColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: 18 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == active;
          final (label, off, on) = tabs[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? on : off,
                    size: 26,
                    color: isActive
                        ? CourierColors.primary
                        : CourierColors.textSubtle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? CourierColors.primary
                          : CourierColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
