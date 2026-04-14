import 'dart:io';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import 'home/views/home_view.dart';
import 'services/views/services_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ── PAGES (slide entre tabs) ─────────────────────────
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: const [
              _KeepAlive(child: HomeView()),
              _KeepAlive(child: ServicesView()),
            ],
          ),

          // ── FLOATING NAV BAR ─────────────────────────────────
          if (Platform.isAndroid)
            _AndroidNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTap,
              onAdd: () => context.go('/quotation'),
              onAiAdd: () => context.go('/ai-quotation'),
            )
          else
            Positioned(
              left: 0,
              right: 16,
              bottom: 12,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const btnWidth = 50.0;
                  const gap = 116.0;
                  final tabBarWidth = constraints.maxWidth - (btnWidth * 2) - 8 - gap;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: tabBarWidth,
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
                          currentIndex: _currentIndex,
                          onTap: _onTabTap,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: btnWidth,
                        child: CNButton.icon(
                          icon: const CNSymbol('sparkles'),
                          onPressed: () => context.go('/ai-quotation'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: btnWidth,
                        child: CNButton.icon(
                          icon: const CNSymbol('plus'),
                          onPressed: () => context.go('/quotation'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Android floating nav bar ─────────────────────────────────────────────────

class _AndroidNavBar extends StatelessWidget {
  const _AndroidNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
    required this.onAiAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  final VoidCallback onAiAdd;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.grid_view_rounded, label: 'Tarifas'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.grey800 : AppColors.white;
    final border = isDark ? AppColors.white : AppColors.black;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tab bar
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: AppColors.borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: border,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final selected = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: selected ? AppColors.blue : border.withAlpha(140),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.blue : border.withAlpha(140),
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
          const SizedBox(width: 12),
          // FAB IA (sparkle)
          GestureDetector(
            onTap: onAiAdd,
            child: Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: AppColors.borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: border,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.black, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // FAB +
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: AppColors.borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: border,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preserva el estado de cada tab cuando se desliza entre páginas.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
