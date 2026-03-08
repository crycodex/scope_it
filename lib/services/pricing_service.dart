import '../database/database_helper.dart';
import '../models/quotation_config.dart';

/// Singleton that stores editable prices for all stepper items in SQLite.
/// Falls back to enum defaults when no custom value has been saved.
class PricingService {
  static final PricingService instance = PricingService._();
  PricingService._();

  final Map<String, double> _cache = {};
  bool _loaded = false;

  // ── Key helpers ──────────────────────────────────────────────────────
  static String _svcKey(ServiceType t) => 'price_svc_${t.name}';
  static String _featKey(Feature f) => 'price_feat_${f.name}';
  static String _extraKey(Extra e) => 'price_extra_${e.name}';
  static String _supportKey(SupportPlan s) => 'price_support_${s.name}';
  static String _platformHostingKey(PlatformTier t) =>
      'price_platform_hosting_${t.name}';
  static String _platformMultKey(PlatformTier t) =>
      'price_platform_mult_${t.name}';
  static String _mobileMultKey(MobilePlatform m) =>
      'price_mobile_mult_${m.name}';

  // ── Init ─────────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    final db = DatabaseHelper.instance;

    Future<void> read(String key) async {
      final v = await db.getSetting(key);
      if (v != null) _cache[key] = double.tryParse(v) ?? 0;
    }

    for (final t in ServiceType.values) { await read(_svcKey(t)); }
    for (final f in Feature.values) { await read(_featKey(f)); }
    for (final e in Extra.values) { await read(_extraKey(e)); }
    for (final s in SupportPlan.values) { await read(_supportKey(s)); }
    for (final t in PlatformTier.values) {
      await read(_platformHostingKey(t));
      await read(_platformMultKey(t));
    }
    for (final m in MobilePlatform.values) { await read(_mobileMultKey(m)); }

    _loaded = true;
  }

  // ── Getters ──────────────────────────────────────────────────────────
  double serviceBasePrice(ServiceType t) =>
      _cache[_svcKey(t)] ?? t.basePrice;

  double featurePrice(Feature f) =>
      _cache[_featKey(f)] ?? f.price;

  double extraPrice(Extra e) =>
      _cache[_extraKey(e)] ?? e.price;

  double supportMonthly(SupportPlan s) =>
      _cache[_supportKey(s)] ?? s.monthlyPrice;

  double platformHosting(PlatformTier t) =>
      _cache[_platformHostingKey(t)] ?? t.monthlyHosting;

  double platformMultiplier(PlatformTier t) =>
      _cache[_platformMultKey(t)] ?? t.multiplier;

  double mobilePlatformMultiplier(MobilePlatform m) =>
      _cache[_mobileMultKey(m)] ?? m.multiplier;

  // ── Setters ──────────────────────────────────────────────────────────
  Future<void> setServiceBasePrice(ServiceType t, double v) =>
      _set(_svcKey(t), v);
  Future<void> setFeaturePrice(Feature f, double v) => _set(_featKey(f), v);
  Future<void> setExtraPrice(Extra e, double v) => _set(_extraKey(e), v);
  Future<void> setSupportMonthly(SupportPlan s, double v) =>
      _set(_supportKey(s), v);
  Future<void> setPlatformHosting(PlatformTier t, double v) =>
      _set(_platformHostingKey(t), v);
  Future<void> setPlatformMultiplier(PlatformTier t, double v) =>
      _set(_platformMultKey(t), v);
  Future<void> setMobilePlatformMultiplier(MobilePlatform m, double v) =>
      _set(_mobileMultKey(m), v);

  Future<void> _set(String key, double value) async {
    _cache[key] = value;
    await DatabaseHelper.instance.setSetting(key, value.toString());
  }
}
