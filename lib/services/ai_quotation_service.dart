import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/marketing_config.dart';
import '../models/quotation_config.dart';

// ── Result & Exception ────────────────────────────────────────────────

class AiQuotationResult {
  final QuotationConfig config;
  final MarketingConfig? marketingConfig;
  final String suggestedProjectName;
  final String suggestedClientName;

  const AiQuotationResult({
    required this.config,
    this.marketingConfig,
    required this.suggestedProjectName,
    required this.suggestedClientName,
  });
}

class AiQuotationException implements Exception {
  final String message;
  const AiQuotationException(this.message);

  @override
  String toString() => message;
}

// ── Service ───────────────────────────────────────────────────────────

class AiQuotationService {
  AiQuotationService._();
  static final AiQuotationService instance = AiQuotationService._();

  GenerativeModel? _model;

  static const _systemPrompt = '''
Eres un asistente especializado en generar cotizaciones de proyectos de software y marketing digital.
El usuario describirá su idea de proyecto en lenguaje natural (español o inglés).
Tu tarea es devolver ÚNICAMENTE un objeto JSON válido — sin prosa, sin markdown, sin explicaciones.

Esquema JSON requerido:
{
  "projectName": "nombre corto descriptivo del proyecto (máximo 40 caracteres)",
  "clientName": "nombre del cliente si se menciona, de lo contrario usa 'Cliente'",
  "quotationConfig": {
    "serviceType": "uno de: web | app | backendApi | automationAi | marketing | custom",
    "customServiceName": "string o null (solo cuando serviceType sea custom)",
    "customBasePrice": null,
    "platformTier": "uno de: basic | professional | enterprise",
    "billingCycle": "uno de: monthly | annual",
    "mobilePlatform": "uno de: playStore | appStore | both | apkOnly | appBundleOnly (OBLIGATORIO si serviceType es app, de lo contrario null)",
    "features": ["lista de cero o más de: auth | roles | payments | analytics | emailNotifications | multiLanguage"],
    "userTier": "uno de: tier0 | tier1 | tier2 | tier3 | tier4",
    "extras": ["lista de cero o más de: realtimeChat | pushNotifications | adminDashboard | uxDesign | dataMigration | thirdPartyIntegration | testingQa"],
    "supportPlan": "uno de: none | basic | professional | enterprise"
  },
  "marketingConfig": null
}

Si el proyecto incluye servicios de marketing, reemplaza null por:
{
  "services": ["uno o más de: socialMedia | eventCoverage | digitalAds | contentCreation | emailMarketing"],
  "socialPlatforms": ["cero o más de: instagram | facebook | tiktok | twitter | linkedin | youtube"],
  "postFrequency": "uno de: daily | threePerWeek | weekly | biweekly",
  "eventType": "uno de: corporate | social | productLaunch | conference — o null si no aplica",
  "coverageDuration": "uno de: twoHours | fourHours | eightHours | fullDay — o null si no aplica",
  "eventQuantity": 1,
  "adPlatforms": ["cero o más de: googleAds | metaAds | tiktokAds"],
  "monthlyAdBudget": null,
  "contentPostsPerMonth": 0,
  "emailVolume": "uno de: small | medium | large — o null si no aplica"
}

Reglas estrictas:
- Usa EXACTAMENTE los valores camelCase indicados; son nombres de enum de Dart y deben coincidir al 100%.
- platformTier: basic=proyecto pequeño/personal, professional=negocio mediano, enterprise=alta escala/corporativo.
- userTier: tier0=0-100 usuarios, tier1=100-1K, tier2=1K-10K, tier3=10K-100K, tier4=100K+. Si no se menciona, usa tier0.
- billingCycle: usa annual si el cliente menciona contratos anuales o quiere descuento, de lo contrario monthly.
- Si no se menciona soporte técnico, usa supportPlan="none".
- Incluye solo las features y extras que sean claramente relevantes para el proyecto.
- Si el proyecto es solo marketing digital, usa serviceType="marketing" Y rellena marketingConfig.
- Para apps móviles (serviceType="app"), SIEMPRE establece mobilePlatform.
- Devuelve SOLO el objeto JSON, sin ningún texto adicional ni bloques de código.
''';

  void _ensureInit() {
    if (_model != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw const AiQuotationException(
        'GEMINI_API_KEY no configurada en .env',
      );
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  Future<AiQuotationResult> generateQuotation(String userPrompt) async {
    _ensureInit();
    try {
      final response = await _model!
          .generateContent([Content.text(userPrompt)]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const AiQuotationException(
          'Tiempo de espera agotado. Verifica tu conexión e intenta de nuevo.',
        ),
      );
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AiQuotationException(
          'No se recibió respuesta del modelo. Intenta de nuevo.',
        );
      }
      return _parse(text);
    } on AiQuotationException {
      rethrow;
    } catch (e) {
      throw AiQuotationException(
        'Error al generar la cotización: ${e.toString().split('\n').first}',
      );
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────

  AiQuotationResult _parse(String jsonText) {
    final cleaned = jsonText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    late Map<String, dynamic> root;
    try {
      root = json.decode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw const AiQuotationException(
        'La respuesta no tiene formato JSON válido. Intenta de nuevo.',
      );
    }

    final configMap = root['quotationConfig'] as Map<String, dynamic>?;
    if (configMap == null) {
      throw const AiQuotationException(
        'La respuesta no contiene los datos de cotización. Intenta de nuevo.',
      );
    }

    final config = _coerceQuotationConfig(configMap);
    final mktMap = root['marketingConfig'] as Map<String, dynamic>?;
    final mktConfig = mktMap != null ? _coerceMarketingConfig(mktMap) : null;

    final rawName = root['projectName'] as String?;
    final rawClient = root['clientName'] as String?;

    return AiQuotationResult(
      config: config,
      marketingConfig: mktConfig,
      suggestedProjectName:
          (rawName != null && rawName.trim().isNotEmpty) ? rawName.trim() : 'Proyecto',
      suggestedClientName:
          (rawClient != null && rawClient.trim().isNotEmpty) ? rawClient.trim() : 'Cliente',
    );
  }

  QuotationConfig _coerceQuotationConfig(Map<String, dynamic> m) {
    final validServiceTypes = ServiceType.values.map((e) => e.name).toList();
    final validPlatformTiers = PlatformTier.values.map((e) => e.name).toList();
    final validBillingCycles = BillingCycle.values.map((e) => e.name).toList();
    final validMobilePlatforms = MobilePlatform.values.map((e) => e.name).toList();
    final validFeatures = Feature.values.map((e) => e.name).toList();
    final validUserTiers = UserTier.values.map((e) => e.name).toList();
    final validExtras = Extra.values.map((e) => e.name).toList();
    final validSupportPlans = SupportPlan.values.map((e) => e.name).toList();

    final serviceType = _pickEnum(
      m['serviceType'] as String?,
      validServiceTypes,
      ServiceType.web.name,
    );
    final mobilePlatformRaw = m['mobilePlatform'] as String?;
    final mobilePlatform = mobilePlatformRaw != null
        ? _pickEnum(mobilePlatformRaw, validMobilePlatforms, MobilePlatform.both.name)
        : null;

    return QuotationConfig(
      serviceType: serviceType,
      customServiceName: m['customServiceName'] as String?,
      customBasePrice: (m['customBasePrice'] as num?)?.toDouble(),
      platformTier: _pickEnum(
          m['platformTier'] as String?, validPlatformTiers, PlatformTier.basic.name),
      billingCycle: _pickEnum(
          m['billingCycle'] as String?, validBillingCycles, BillingCycle.monthly.name),
      mobilePlatform: mobilePlatform,
      features: _pickEnumList(m['features'], validFeatures),
      userTier: _pickEnum(
          m['userTier'] as String?, validUserTiers, UserTier.tier0.name),
      extras: _pickEnumList(m['extras'], validExtras),
      supportPlan: _pickEnum(
          m['supportPlan'] as String?, validSupportPlans, SupportPlan.none.name),
    );
  }

  MarketingConfig _coerceMarketingConfig(Map<String, dynamic> m) {
    final validServices = MarketingService.values.map((e) => e.name).toList();
    final validPlatforms = SocialPlatform.values.map((e) => e.name).toList();
    final validFrequencies = PostFrequency.values.map((e) => e.name).toList();
    final validEventTypes = EventType.values.map((e) => e.name).toList();
    final validDurations = CoverageDuration.values.map((e) => e.name).toList();
    final validAdPlatforms = AdPlatform.values.map((e) => e.name).toList();
    final validEmailVolumes = EmailVolume.values.map((e) => e.name).toList();

    final services = _pickEnumList(m['services'], validServices);
    if (services.isEmpty) {
      return const MarketingConfig(services: ['socialMedia']);
    }

    final eventTypeRaw = m['eventType'] as String?;
    final coverageDurationRaw = m['coverageDuration'] as String?;
    final emailVolumeRaw = m['emailVolume'] as String?;

    return MarketingConfig(
      services: services,
      socialPlatforms: _pickEnumList(m['socialPlatforms'], validPlatforms),
      postFrequency: _pickEnum(
          m['postFrequency'] as String?, validFrequencies, PostFrequency.weekly.name),
      eventType: eventTypeRaw != null
          ? _pickEnum(eventTypeRaw, validEventTypes, EventType.corporate.name)
          : null,
      coverageDuration: coverageDurationRaw != null
          ? _pickEnum(coverageDurationRaw, validDurations, CoverageDuration.fourHours.name)
          : null,
      eventQuantity: (m['eventQuantity'] as num?)?.toInt() ?? 1,
      adPlatforms: _pickEnumList(m['adPlatforms'], validAdPlatforms),
      monthlyAdBudget: (m['monthlyAdBudget'] as num?)?.toDouble(),
      contentPostsPerMonth: (m['contentPostsPerMonth'] as num?)?.toInt() ?? 0,
      emailVolume: emailVolumeRaw != null
          ? _pickEnum(emailVolumeRaw, validEmailVolumes, EmailVolume.small.name)
          : null,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String _pickEnum(String? raw, List<String> validValues, String fallback) {
    if (raw == null) return fallback;
    return validValues.contains(raw) ? raw : fallback;
  }

  List<String> _pickEnumList(dynamic raw, List<String> validValues) {
    if (raw is! List) return [];
    return raw.whereType<String>().where(validValues.contains).toList();
  }
}
