import 'package:flutter/material.dart';

// ── MARKETING SERVICES ───────────────────────────────────────────────
enum MarketingService {
  socialMedia,
  eventCoverage,
  digitalAds,
  contentCreation,
  emailMarketing;

  String get label {
    switch (this) {
      case MarketingService.socialMedia:
        return 'Redes Sociales';
      case MarketingService.eventCoverage:
        return 'Cobertura de Eventos';
      case MarketingService.digitalAds:
        return 'Publicidad Digital';
      case MarketingService.contentCreation:
        return 'Creación de Contenido';
      case MarketingService.emailMarketing:
        return 'Email Marketing';
    }
  }

  String get description {
    switch (this) {
      case MarketingService.socialMedia:
        return 'Gestión de publicaciones y comunidad';
      case MarketingService.eventCoverage:
        return 'Fotografía y video de eventos';
      case MarketingService.digitalAds:
        return 'Campañas en plataformas digitales';
      case MarketingService.contentCreation:
        return 'Diseño gráfico y redacción';
      case MarketingService.emailMarketing:
        return 'Campañas por correo electrónico';
    }
  }

  IconData get icon {
    switch (this) {
      case MarketingService.socialMedia:
        return Icons.share_outlined;
      case MarketingService.eventCoverage:
        return Icons.camera_alt_outlined;
      case MarketingService.digitalAds:
        return Icons.ads_click;
      case MarketingService.contentCreation:
        return Icons.draw_outlined;
      case MarketingService.emailMarketing:
        return Icons.mark_email_read_outlined;
    }
  }

  int get colorValue {
    switch (this) {
      case MarketingService.socialMedia:
        return 0xFFE91E63;
      case MarketingService.eventCoverage:
        return 0xFF9C27B0;
      case MarketingService.digitalAds:
        return 0xFF2196F3;
      case MarketingService.contentCreation:
        return 0xFF4CAF50;
      case MarketingService.emailMarketing:
        return 0xFFFF9800;
    }
  }
}

// ── SOCIAL PLATFORMS ─────────────────────────────────────────────────
enum SocialPlatform {
  instagram,
  facebook,
  tiktok,
  twitter,
  linkedin,
  youtube;

  String get label {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.twitter:
        return 'X / Twitter';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.youtube:
        return 'YouTube';
    }
  }

  IconData get icon {
    switch (this) {
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.tiktok:
        return Icons.music_note;
      case SocialPlatform.twitter:
        return Icons.tag;
      case SocialPlatform.linkedin:
        return Icons.work_outline;
      case SocialPlatform.youtube:
        return Icons.play_circle_outline;
    }
  }

  double get monthlyBase {
    switch (this) {
      case SocialPlatform.instagram:
        return 150;
      case SocialPlatform.facebook:
        return 120;
      case SocialPlatform.tiktok:
        return 180;
      case SocialPlatform.twitter:
        return 100;
      case SocialPlatform.linkedin:
        return 200;
      case SocialPlatform.youtube:
        return 250;
    }
  }
}

// ── POST FREQUENCY ───────────────────────────────────────────────────
enum PostFrequency {
  daily,
  threePerWeek,
  weekly,
  biweekly;

  String get label {
    switch (this) {
      case PostFrequency.daily:
        return 'Diario (30/mes)';
      case PostFrequency.threePerWeek:
        return '3x semana (12/mes)';
      case PostFrequency.weekly:
        return 'Semanal (4/mes)';
      case PostFrequency.biweekly:
        return 'Quincenal (2/mes)';
    }
  }

  int get postsPerMonth {
    switch (this) {
      case PostFrequency.daily:
        return 30;
      case PostFrequency.threePerWeek:
        return 12;
      case PostFrequency.weekly:
        return 4;
      case PostFrequency.biweekly:
        return 2;
    }
  }

  double get multiplier {
    switch (this) {
      case PostFrequency.daily:
        return 2.5;
      case PostFrequency.threePerWeek:
        return 1.5;
      case PostFrequency.weekly:
        return 1.0;
      case PostFrequency.biweekly:
        return 0.6;
    }
  }
}

// ── EVENT TYPE ───────────────────────────────────────────────────────
enum EventType {
  corporate,
  social,
  productLaunch,
  conference;

  String get label {
    switch (this) {
      case EventType.corporate:
        return 'Corporativo';
      case EventType.social:
        return 'Social / Fiesta';
      case EventType.productLaunch:
        return 'Lanzamiento de Producto';
      case EventType.conference:
        return 'Conferencia / Expo';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.corporate:
        return Icons.business_center_outlined;
      case EventType.social:
        return Icons.celebration_outlined;
      case EventType.productLaunch:
        return Icons.rocket_launch_outlined;
      case EventType.conference:
        return Icons.groups_outlined;
    }
  }

  double get basePrice {
    switch (this) {
      case EventType.corporate:
        return 300;
      case EventType.social:
        return 200;
      case EventType.productLaunch:
        return 500;
      case EventType.conference:
        return 400;
    }
  }
}

// ── COVERAGE DURATION ────────────────────────────────────────────────
enum CoverageDuration {
  twoHours,
  fourHours,
  eightHours,
  fullDay;

  String get label {
    switch (this) {
      case CoverageDuration.twoHours:
        return '2 horas';
      case CoverageDuration.fourHours:
        return '4 horas';
      case CoverageDuration.eightHours:
        return '8 horas';
      case CoverageDuration.fullDay:
        return 'Día completo';
    }
  }

  double get multiplier {
    switch (this) {
      case CoverageDuration.twoHours:
        return 1.0;
      case CoverageDuration.fourHours:
        return 1.8;
      case CoverageDuration.eightHours:
        return 3.0;
      case CoverageDuration.fullDay:
        return 4.0;
    }
  }
}

// ── AD PLATFORM ──────────────────────────────────────────────────────
enum AdPlatform {
  googleAds,
  metaAds,
  tiktokAds;

  String get label {
    switch (this) {
      case AdPlatform.googleAds:
        return 'Google Ads';
      case AdPlatform.metaAds:
        return 'Meta Ads (FB/IG)';
      case AdPlatform.tiktokAds:
        return 'TikTok Ads';
    }
  }

  IconData get icon {
    switch (this) {
      case AdPlatform.googleAds:
        return Icons.search;
      case AdPlatform.metaAds:
        return Icons.thumb_up_outlined;
      case AdPlatform.tiktokAds:
        return Icons.video_library_outlined;
    }
  }

  double get setupFee {
    switch (this) {
      case AdPlatform.googleAds:
        return 200;
      case AdPlatform.metaAds:
        return 150;
      case AdPlatform.tiktokAds:
        return 180;
    }
  }
}

// ── EMAIL VOLUME ─────────────────────────────────────────────────────
enum EmailVolume {
  small,
  medium,
  large;

  String get label {
    switch (this) {
      case EmailVolume.small:
        return 'Hasta 1,000 contactos';
      case EmailVolume.medium:
        return '1,000 – 10,000 contactos';
      case EmailVolume.large:
        return 'Más de 10,000 contactos';
    }
  }

  double get monthlyPrice {
    switch (this) {
      case EmailVolume.small:
        return 80;
      case EmailVolume.medium:
        return 200;
      case EmailVolume.large:
        return 400;
    }
  }
}

// ── MARKETING CONFIG ─────────────────────────────────────────────────
class MarketingConfig {
  final List<String> services;
  final List<String> socialPlatforms;
  final String postFrequency;
  final String? eventType;
  final String? coverageDuration;
  final int eventQuantity;
  final List<String> adPlatforms;
  final double? monthlyAdBudget;
  final int contentPostsPerMonth;
  final String? emailVolume;

  const MarketingConfig({
    required this.services,
    this.socialPlatforms = const [],
    this.postFrequency = 'weekly',
    this.eventType,
    this.coverageDuration,
    this.eventQuantity = 1,
    this.adPlatforms = const [],
    this.monthlyAdBudget,
    this.contentPostsPerMonth = 0,
    this.emailVolume,
  });

  Map<String, dynamic> toJson() => {
    'services': services,
    'socialPlatforms': socialPlatforms,
    'postFrequency': postFrequency,
    if (eventType != null) 'eventType': eventType,
    if (coverageDuration != null) 'coverageDuration': coverageDuration,
    'eventQuantity': eventQuantity,
    'adPlatforms': adPlatforms,
    if (monthlyAdBudget != null) 'monthlyAdBudget': monthlyAdBudget,
    'contentPostsPerMonth': contentPostsPerMonth,
    if (emailVolume != null) 'emailVolume': emailVolume,
  };

  factory MarketingConfig.fromJson(Map<String, dynamic> json) {
    return MarketingConfig(
      services: List<String>.from(json['services'] as List),
      socialPlatforms:
          List<String>.from(json['socialPlatforms'] as List? ?? []),
      postFrequency: json['postFrequency'] as String? ?? 'weekly',
      eventType: json['eventType'] as String?,
      coverageDuration: json['coverageDuration'] as String?,
      eventQuantity: json['eventQuantity'] as int? ?? 1,
      adPlatforms: List<String>.from(json['adPlatforms'] as List? ?? []),
      monthlyAdBudget: (json['monthlyAdBudget'] as num?)?.toDouble(),
      contentPostsPerMonth: json['contentPostsPerMonth'] as int? ?? 0,
      emailVolume: json['emailVolume'] as String?,
    );
  }

  // ── Parsed accessors ──────────────────────────────────────────────
  List<MarketingService> get serviceEnums => services
      .map((s) => MarketingService.values.where((e) => e.name == s).firstOrNull)
      .whereType<MarketingService>()
      .toList();

  List<SocialPlatform> get socialPlatformEnums => socialPlatforms
      .map((s) => SocialPlatform.values.where((e) => e.name == s).firstOrNull)
      .whereType<SocialPlatform>()
      .toList();

  PostFrequency get postFrequencyEnum => PostFrequency.values.firstWhere(
    (e) => e.name == postFrequency,
    orElse: () => PostFrequency.weekly,
  );

  EventType? get eventTypeEnum => eventType == null
      ? null
      : EventType.values.firstWhere(
          (e) => e.name == eventType,
          orElse: () => EventType.corporate,
        );

  CoverageDuration? get coverageDurationEnum => coverageDuration == null
      ? null
      : CoverageDuration.values.firstWhere(
          (e) => e.name == coverageDuration,
          orElse: () => CoverageDuration.fourHours,
        );

  List<AdPlatform> get adPlatformEnums => adPlatforms
      .map((s) => AdPlatform.values.where((e) => e.name == s).firstOrNull)
      .whereType<AdPlatform>()
      .toList();

  EmailVolume? get emailVolumeEnum => emailVolume == null
      ? null
      : EmailVolume.values.firstWhere(
          (e) => e.name == emailVolume,
          orElse: () => EmailVolume.small,
        );

  bool get hasSocialMedia =>
      services.contains(MarketingService.socialMedia.name);
  bool get hasEventCoverage =>
      services.contains(MarketingService.eventCoverage.name);
  bool get hasDigitalAds =>
      services.contains(MarketingService.digitalAds.name);
  bool get hasContentCreation =>
      services.contains(MarketingService.contentCreation.name);
  bool get hasEmailMarketing =>
      services.contains(MarketingService.emailMarketing.name);

  // ── Price calculations (use defaults from enums directly) ─────────
  double get socialMediaMonthly {
    if (!hasSocialMedia || socialPlatformEnums.isEmpty) return 0;
    final platformsTotal = socialPlatformEnums.fold(
      0.0,
      (s, p) => s + p.monthlyBase,
    );
    return platformsTotal * postFrequencyEnum.multiplier;
  }

  double get eventCoverageTotal {
    if (!hasEventCoverage || eventTypeEnum == null || coverageDurationEnum == null) {
      return 0;
    }
    return eventTypeEnum!.basePrice *
        coverageDurationEnum!.multiplier *
        eventQuantity;
  }

  double get digitalAdsSetup {
    if (!hasDigitalAds) return 0;
    return adPlatformEnums.fold(0.0, (s, p) => s + p.setupFee);
  }

  double get digitalAdsMgmtMonthly {
    if (!hasDigitalAds || monthlyAdBudget == null || adPlatformEnums.isEmpty) {
      return 0;
    }
    return monthlyAdBudget! * 0.15; // 15% management fee by default
  }

  double get contentCreationMonthly {
    if (!hasContentCreation || contentPostsPerMonth == 0) return 0;
    return contentPostsPerMonth * 25.0; // $25 per post default
  }

  double get emailMarketingMonthly {
    if (!hasEmailMarketing || emailVolumeEnum == null) return 0;
    return emailVolumeEnum!.monthlyPrice;
  }

  /// One-time costs (setup fees + event coverage)
  double get oneTimeTotal => digitalAdsSetup + eventCoverageTotal;

  /// Monthly recurring marketing costs
  double get monthlyTotal =>
      socialMediaMonthly +
      digitalAdsMgmtMonthly +
      contentCreationMonthly +
      emailMarketingMonthly;

  /// Total marketing estimate (one-time + monthly)
  double get totalEstimate => oneTimeTotal + monthlyTotal;
}
