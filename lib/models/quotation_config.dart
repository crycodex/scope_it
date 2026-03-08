import 'package:flutter/material.dart';

// ── STEP 1: SERVICE TYPE ─────────────────────────────────────────────
enum ServiceType {
  web,
  app,
  backendApi,
  automationAi,
  custom;

  String get label {
    switch (this) {
      case ServiceType.web:
        return 'Web';
      case ServiceType.app:
        return 'App Móvil';
      case ServiceType.backendApi:
        return 'Backend / API';
      case ServiceType.automationAi:
        return 'Automatización IA';
      case ServiceType.custom:
        return 'Personalizado';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.web:
        return 'Sitio o aplicación web';
      case ServiceType.app:
        return 'App nativa o híbrida';
      case ServiceType.backendApi:
        return 'API REST, microservicios';
      case ServiceType.automationAi:
        return 'Flujos con IA';
      case ServiceType.custom:
        return 'Servicio personalizado';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.web:
        return Icons.language;
      case ServiceType.app:
        return Icons.phone_iphone;
      case ServiceType.backendApi:
        return Icons.dns;
      case ServiceType.automationAi:
        return Icons.smart_toy;
      case ServiceType.custom:
        return Icons.add_circle_outline;
    }
  }

  double get basePrice {
    switch (this) {
      case ServiceType.web:
        return 2500;
      case ServiceType.app:
        return 4000;
      case ServiceType.backendApi:
        return 2000;
      case ServiceType.automationAi:
        return 5000;
      case ServiceType.custom:
        return 0;
    }
  }

  int get colorValue {
    switch (this) {
      case ServiceType.web:
        return 0xFF1B9CFC;
      case ServiceType.app:
        return 0xFF4CAF50;
      case ServiceType.backendApi:
        return 0xFF9C27B0;
      case ServiceType.automationAi:
        return 0xFFFF9800;
      case ServiceType.custom:
        return 0xFF607D8B;
    }
  }
}

// ── STEP 2: PLATFORM / DEPLOYMENT ────────────────────────────────────
enum PlatformTier {
  basic,
  professional,
  enterprise;

  String get label {
    switch (this) {
      case PlatformTier.basic:
        return 'Básico';
      case PlatformTier.professional:
        return 'Profesional';
      case PlatformTier.enterprise:
        return 'Empresarial';
    }
  }

  String get description {
    switch (this) {
      case PlatformTier.basic:
        return 'Hosting compartido, SSL';
      case PlatformTier.professional:
        return 'VPS dedicado, CDN, backups';
      case PlatformTier.enterprise:
        return 'Cloud escalable, HA, DR';
    }
  }

  IconData get icon {
    switch (this) {
      case PlatformTier.basic:
        return Icons.cloud_outlined;
      case PlatformTier.professional:
        return Icons.cloud;
      case PlatformTier.enterprise:
        return Icons.cloud_done;
    }
  }

  double get multiplier {
    switch (this) {
      case PlatformTier.basic:
        return 1.0;
      case PlatformTier.professional:
        return 1.8;
      case PlatformTier.enterprise:
        return 3.0;
    }
  }

  double get monthlyHosting {
    switch (this) {
      case PlatformTier.basic:
        return 29;
      case PlatformTier.professional:
        return 79;
      case PlatformTier.enterprise:
        return 199;
    }
  }
}

enum BillingCycle {
  monthly,
  annual;

  String get label {
    switch (this) {
      case BillingCycle.monthly:
        return 'Mensual';
      case BillingCycle.annual:
        return 'Anual (-20%)';
    }
  }

  double get discount {
    switch (this) {
      case BillingCycle.monthly:
        return 1.0;
      case BillingCycle.annual:
        return 0.8;
    }
  }
}

enum MobilePlatform {
  playStore,
  appStore,
  both;

  String get label {
    switch (this) {
      case MobilePlatform.playStore:
        return 'Play Store';
      case MobilePlatform.appStore:
        return 'App Store';
      case MobilePlatform.both:
        return 'Ambas';
    }
  }

  IconData get icon {
    switch (this) {
      case MobilePlatform.playStore:
        return Icons.shop;
      case MobilePlatform.appStore:
        return Icons.apple;
      case MobilePlatform.both:
        return Icons.devices;
    }
  }

  double get multiplier {
    switch (this) {
      case MobilePlatform.playStore:
        return 1.0;
      case MobilePlatform.appStore:
        return 1.0;
      case MobilePlatform.both:
        return 1.5;
    }
  }
}

// ── STEP 3: FEATURES ─────────────────────────────────────────────────
enum Feature {
  auth,
  roles,
  payments,
  analytics,
  emailNotifications,
  multiLanguage;

  String get label {
    switch (this) {
      case Feature.auth:
        return 'Autenticación';
      case Feature.roles:
        return 'Roles y Permisos';
      case Feature.payments:
        return 'Pagos Integrados';
      case Feature.analytics:
        return 'Analytics';
      case Feature.emailNotifications:
        return 'Notificaciones Email';
      case Feature.multiLanguage:
        return 'Multi-idioma';
    }
  }

  IconData get icon {
    switch (this) {
      case Feature.auth:
        return Icons.lock_outline;
      case Feature.roles:
        return Icons.admin_panel_settings_outlined;
      case Feature.payments:
        return Icons.payment;
      case Feature.analytics:
        return Icons.analytics_outlined;
      case Feature.emailNotifications:
        return Icons.email_outlined;
      case Feature.multiLanguage:
        return Icons.translate;
    }
  }

  double get price {
    switch (this) {
      case Feature.auth:
        return 300;
      case Feature.roles:
        return 250;
      case Feature.payments:
        return 500;
      case Feature.analytics:
        return 200;
      case Feature.emailNotifications:
        return 150;
      case Feature.multiLanguage:
        return 350;
    }
  }

  List<ServiceType> get availableFor {
    switch (this) {
      case Feature.auth:
      case Feature.roles:
      case Feature.analytics:
      case Feature.emailNotifications:
        return ServiceType.values;
      case Feature.payments:
        return [ServiceType.web, ServiceType.app, ServiceType.backendApi];
      case Feature.multiLanguage:
        return [ServiceType.web, ServiceType.app];
    }
  }
}

// ── STEP 4: EXPECTED USERS ───────────────────────────────────────────
enum UserTier {
  tier0,
  tier1,
  tier2,
  tier3,
  tier4;

  String get label {
    switch (this) {
      case UserTier.tier0:
        return '0 – 100';
      case UserTier.tier1:
        return '100 – 1,000';
      case UserTier.tier2:
        return '1,000 – 10,000';
      case UserTier.tier3:
        return '10,000 – 100,000';
      case UserTier.tier4:
        return '100,000+';
    }
  }

  double get monthlyPrice {
    switch (this) {
      case UserTier.tier0:
        return 0;
      case UserTier.tier1:
        return 15;
      case UserTier.tier2:
        return 45;
      case UserTier.tier3:
        return 120;
      case UserTier.tier4:
        return 300;
    }
  }

  IconData get icon {
    switch (this) {
      case UserTier.tier0:
        return Icons.person;
      case UserTier.tier1:
        return Icons.people;
      case UserTier.tier2:
        return Icons.groups;
      case UserTier.tier3:
        return Icons.groups_3;
      case UserTier.tier4:
        return Icons.public;
    }
  }
}

// ── STEP 5: EXTRAS ───────────────────────────────────────────────────
enum Extra {
  realtimeChat,
  pushNotifications,
  adminDashboard,
  uxDesign,
  dataMigration,
  thirdPartyIntegration,
  testingQa;

  String get label {
    switch (this) {
      case Extra.realtimeChat:
        return 'Chat en Tiempo Real';
      case Extra.pushNotifications:
        return 'Notificaciones Push';
      case Extra.adminDashboard:
        return 'Dashboard Admin';
      case Extra.uxDesign:
        return 'Diseño UX/UI';
      case Extra.dataMigration:
        return 'Migración de Datos';
      case Extra.thirdPartyIntegration:
        return 'Integración Terceros';
      case Extra.testingQa:
        return 'Testing / QA';
    }
  }

  IconData get icon {
    switch (this) {
      case Extra.realtimeChat:
        return Icons.chat_bubble_outline;
      case Extra.pushNotifications:
        return Icons.notifications_active_outlined;
      case Extra.adminDashboard:
        return Icons.dashboard_outlined;
      case Extra.uxDesign:
        return Icons.palette_outlined;
      case Extra.dataMigration:
        return Icons.swap_horiz;
      case Extra.thirdPartyIntegration:
        return Icons.extension_outlined;
      case Extra.testingQa:
        return Icons.bug_report_outlined;
    }
  }

  double get price {
    switch (this) {
      case Extra.realtimeChat:
        return 800;
      case Extra.pushNotifications:
        return 400;
      case Extra.adminDashboard:
        return 600;
      case Extra.uxDesign:
        return 1200;
      case Extra.dataMigration:
        return 500;
      case Extra.thirdPartyIntegration:
        return 450;
      case Extra.testingQa:
        return 350;
    }
  }

  List<ServiceType> get availableFor {
    switch (this) {
      case Extra.realtimeChat:
        return [ServiceType.web, ServiceType.app];
      case Extra.pushNotifications:
        return [ServiceType.app];
      case Extra.adminDashboard:
      case Extra.dataMigration:
      case Extra.thirdPartyIntegration:
      case Extra.testingQa:
        return ServiceType.values;
      case Extra.uxDesign:
        return [ServiceType.web, ServiceType.app];
    }
  }
}

// ── STEP 6: SUPPORT ──────────────────────────────────────────────────
enum SupportPlan {
  none,
  basic,
  professional,
  enterprise;

  String get label {
    switch (this) {
      case SupportPlan.none:
        return 'Sin Soporte';
      case SupportPlan.basic:
        return 'Básico';
      case SupportPlan.professional:
        return 'Profesional';
      case SupportPlan.enterprise:
        return 'Empresarial';
    }
  }

  String get description {
    switch (this) {
      case SupportPlan.none:
        return 'Sin soporte técnico';
      case SupportPlan.basic:
        return 'Email, respuesta 48h';
      case SupportPlan.professional:
        return 'Email + Chat, respuesta 12h';
      case SupportPlan.enterprise:
        return '24/7, SLA garantizado';
    }
  }

  IconData get icon {
    switch (this) {
      case SupportPlan.none:
        return Icons.do_not_disturb_outlined;
      case SupportPlan.basic:
        return Icons.email_outlined;
      case SupportPlan.professional:
        return Icons.headset_mic_outlined;
      case SupportPlan.enterprise:
        return Icons.support_agent;
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SupportPlan.none:
        return 0;
      case SupportPlan.basic:
        return 49;
      case SupportPlan.professional:
        return 129;
      case SupportPlan.enterprise:
        return 299;
    }
  }
}

// ── QUOTATION CONFIG (JSON-serializable) ─────────────────────────────
class QuotationConfig {
  final String serviceType;
  final String? customServiceName;
  final double? customBasePrice;
  final String platformTier;
  final String billingCycle;
  final String? mobilePlatform;
  final List<String> features;
  final String userTier;
  final List<String> extras;
  final String supportPlan;

  const QuotationConfig({
    required this.serviceType,
    this.customServiceName,
    this.customBasePrice,
    required this.platformTier,
    required this.billingCycle,
    this.mobilePlatform,
    required this.features,
    required this.userTier,
    required this.extras,
    required this.supportPlan,
  });

  Map<String, dynamic> toJson() => {
        'serviceType': serviceType,
        if (customServiceName != null) 'customServiceName': customServiceName,
        if (customBasePrice != null) 'customBasePrice': customBasePrice,
        'platformTier': platformTier,
        'billingCycle': billingCycle,
        if (mobilePlatform != null) 'mobilePlatform': mobilePlatform,
        'features': features,
        'userTier': userTier,
        'extras': extras,
        'supportPlan': supportPlan,
      };

  factory QuotationConfig.fromJson(Map<String, dynamic> json) {
    return QuotationConfig(
      serviceType: json['serviceType'] as String,
      customServiceName: json['customServiceName'] as String?,
      customBasePrice: (json['customBasePrice'] as num?)?.toDouble(),
      platformTier: json['platformTier'] as String,
      billingCycle: json['billingCycle'] as String,
      mobilePlatform: json['mobilePlatform'] as String?,
      features: List<String>.from(json['features'] as List),
      userTier: json['userTier'] as String,
      extras: List<String>.from(json['extras'] as List),
      supportPlan: json['supportPlan'] as String,
    );
  }

  // ── Parsed accessors ──────────────────────────────────────────────
  ServiceType? get serviceTypeEnum =>
      ServiceType.values.where((e) => e.name == serviceType).firstOrNull;

  PlatformTier get platformTierEnum =>
      PlatformTier.values.firstWhere((e) => e.name == platformTier,
          orElse: () => PlatformTier.basic);

  BillingCycle get billingCycleEnum =>
      BillingCycle.values.firstWhere((e) => e.name == billingCycle,
          orElse: () => BillingCycle.monthly);

  MobilePlatform? get mobilePlatformEnum => mobilePlatform == null
      ? null
      : MobilePlatform.values.firstWhere((e) => e.name == mobilePlatform,
          orElse: () => MobilePlatform.playStore);

  List<Feature> get featureEnums => features
      .map((f) => Feature.values.where((e) => e.name == f).firstOrNull)
      .whereType<Feature>()
      .toList();

  UserTier get userTierEnum => UserTier.values
      .firstWhere((e) => e.name == userTier, orElse: () => UserTier.tier0);

  List<Extra> get extraEnums => extras
      .map((x) => Extra.values.where((e) => e.name == x).firstOrNull)
      .whereType<Extra>()
      .toList();

  SupportPlan get supportPlanEnum => SupportPlan.values
      .firstWhere((e) => e.name == supportPlan,
          orElse: () => SupportPlan.none);

  // ── Price calculations ────────────────────────────────────────────
  double get serviceBasePrice {
    final sType = serviceTypeEnum;
    if (sType == null || sType == ServiceType.custom) {
      return customBasePrice ?? 0;
    }
    return sType.basePrice;
  }

  String get serviceLabel {
    final sType = serviceTypeEnum;
    if (sType == ServiceType.custom && customServiceName != null) {
      return customServiceName!;
    }
    return sType?.label ?? serviceType;
  }

  double get baseProject {
    double base = serviceBasePrice * platformTierEnum.multiplier;
    final mp = mobilePlatformEnum;
    if (serviceTypeEnum == ServiceType.app && mp != null) {
      base *= mp.multiplier;
    }
    return base;
  }

  double get featuresTotal =>
      featureEnums.fold(0.0, (s, f) => s + f.price);

  double get extrasTotal =>
      extraEnums.fold(0.0, (s, e) => s + e.price);

  double get developmentTotal => baseProject + featuresTotal + extrasTotal;

  double get monthlyRecurring =>
      platformTierEnum.monthlyHosting +
      userTierEnum.monthlyPrice +
      supportPlanEnum.monthlyPrice;

  double get monthlyWithDiscount =>
      monthlyRecurring * billingCycleEnum.discount;

  double get totalEstimate {
    if (billingCycleEnum == BillingCycle.annual) {
      return developmentTotal + (monthlyWithDiscount * 12);
    }
    return developmentTotal + monthlyRecurring;
  }
}
