import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'database/database_helper.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/pricing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper.instance;
  await PricingService.instance.load();
  final themeModeIndex =
      int.tryParse(await db.getSetting('theme_mode') ?? '') ?? 0;
  final companySizeIndex =
      int.tryParse(await db.getSetting('company_size') ?? '') ?? 1;
  runApp(
    ScopeItApp(
      initialThemeMode: ThemeMode
          .values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
      initialCompanySize: CompanySize
          .values[companySizeIndex.clamp(0, CompanySize.values.length - 1)],
    ),
  );
}

class ScopeItApp extends StatelessWidget {
  const ScopeItApp({
    super.key,
    required this.initialThemeMode,
    required this.initialCompanySize,
  });

  final ThemeMode initialThemeMode;
  final CompanySize initialCompanySize;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initial: initialThemeMode),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Scope IT',
            debugShowCheckedModeBanner: false,
            theme: neuLightTheme(),
            darkTheme: neuDarkTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
