import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/main_shell.dart';
import '../features/quotation/views/new_quotation_view.dart';
import '../features/settings/views/settings_view.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: MainShell(),
      ),
    ),
    GoRoute(
      path: '/quotation',
      name: 'newQuotation',
      pageBuilder: (context, state) => _slideRight(
        state: state,
        child: const NewQuotationView(),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _slideRight(
        state: state,
        child: const SettingsView(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _slideRight({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      ));
      final slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.25, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOutCubic,
      ));
      return SlideTransition(
        position: slideOut,
        child: SlideTransition(position: slideIn, child: child),
      );
    },
  );
}
