import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  final Widget child;
  final int currentIndex;

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/services');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          child,
          // ── FLOATING BOTTOM BAR ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Native Liquid Glass tab bar
                Expanded(
                  child: CNTabBar(
                    items: const [
                      CNTabBarItem(
                        label: 'Inicio',
                        icon: CNSymbol('house.fill'),
                      ),
                      CNTabBarItem(
                        label: 'Servicios',
                        icon: CNSymbol('square.grid.2x2.fill'),
                      ),
                    ],
                    currentIndex: currentIndex,
                    onTap: (i) => _onNavTap(context, i),
                  ),
                ),
                const SizedBox(width: 12),
                // Native Liquid Glass FAB circle
                CNButton.icon(
                  size: 60,
                  icon: const CNSymbol('plus'),
                  onPressed: () => context.go('/quotation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
