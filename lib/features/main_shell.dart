import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
          Positioned(
            left: 0,
            right: 16,
            bottom: bottomPadding + 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Deja 52px para el botón + y 12px de gap
                const btnWidth = 50.0;
                const gap = 100.0;
                final tabBarWidth = constraints.maxWidth - btnWidth - gap;

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
