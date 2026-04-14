import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'database/database_helper.dart';
import 'firebase_options.dart';
import 'models/business_info.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/marketing_pricing_service.dart';
import 'services/pricing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final db = DatabaseHelper.instance;
  await PricingService.instance.load();
  await MarketingPricingService.instance.load();
  final themeModeIndex =
      int.tryParse(await db.getSetting('theme_mode') ?? '') ?? 0;
  final companySizeIndex =
      int.tryParse(await db.getSetting('company_size') ?? '') ?? 1;
  const defaultInfo = BusinessInfo();
  final bizName = await db.getSetting('biz_name') ?? defaultInfo.companyName;
  final bizEmail = await db.getSetting('biz_email') ?? defaultInfo.email;
  final bizPhone = await db.getSetting('biz_phone') ?? defaultInfo.phone;
  final bizAddress = await db.getSetting('biz_address') ?? defaultInfo.address;
  final bizWebsite = await db.getSetting('biz_website') ?? defaultInfo.website;
  final bizIva = double.tryParse(await db.getSetting('biz_iva') ?? '') ?? defaultInfo.ivaPercent;
  runApp(
    ScopeItApp(
      initialThemeMode: ThemeMode
          .values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
      initialCompanySize: CompanySize
          .values[companySizeIndex.clamp(0, CompanySize.values.length - 1)],
      initialBusinessInfo: BusinessInfo(
        companyName: bizName,
        email: bizEmail,
        phone: bizPhone,
        address: bizAddress,
        website: bizWebsite,
        ivaPercent: bizIva,
      ),
    ),
  );
}

class ScopeItApp extends StatelessWidget {
  const ScopeItApp({
    super.key,
    required this.initialThemeMode,
    required this.initialCompanySize,
    required this.initialBusinessInfo,
  });

  final ThemeMode initialThemeMode;
  final CompanySize initialCompanySize;
  final BusinessInfo initialBusinessInfo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initial: initialThemeMode),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            initial: initialCompanySize,
            initialBusinessInfo: initialBusinessInfo,
          ),
        ),
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
