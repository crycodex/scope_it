import 'package:go_router/go_router.dart';
import '../features/home/views/home_view.dart';
import '../features/services/views/services_view.dart';
import '../features/quotation/views/new_quotation_view.dart';
import '../features/settings/views/settings_view.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (_, _) => const HomeView(),
    ),
    GoRoute(
      path: '/services',
      name: 'services',
      builder: (_, _) => const ServicesView(),
    ),
    GoRoute(
      path: '/quotation',
      name: 'newQuotation',
      builder: (_, _) => const NewQuotationView(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (_, _) => const SettingsView(),
    ),
  ],
);
