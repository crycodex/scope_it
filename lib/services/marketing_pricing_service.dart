import '../database/database_helper.dart';
import '../models/marketing_config.dart';

/// Singleton that stores editable marketing prices in SQLite.
/// Falls back to enum defaults when no custom value has been saved.
class MarketingPricingService {
  static final MarketingPricingService instance = MarketingPricingService._();
  MarketingPricingService._();

  final Map<String, double> _cache = {};
  bool _loaded = false;

  // ── Key helpers ──────────────────────────────────────────────────────
  static String _socialKey(SocialPlatform p) => 'mkt_social_${p.name}';
  static String _eventKey(EventType t) => 'mkt_event_${t.name}';
  static String _adSetupKey(AdPlatform p) => 'mkt_ad_setup_${p.name}';
  static const String _adMgmtRateKey = 'mkt_ad_mgmt_rate';
  static const String _contentPerPostKey = 'mkt_content_per_post';
  static String _emailKey(EmailVolume v) => 'mkt_email_${v.name}';
  static String _coverageMultKey(CoverageDuration d) =>
      'mkt_coverage_mult_${d.name}';

  // ── Init ─────────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    final db = DatabaseHelper.instance;

    Future<void> read(String key) async {
      final v = await db.getSetting(key);
      if (v != null) _cache[key] = double.tryParse(v) ?? 0;
    }

    for (final p in SocialPlatform.values) {
      await read(_socialKey(p));
    }
    for (final t in EventType.values) {
      await read(_eventKey(t));
    }
    for (final p in AdPlatform.values) {
      await read(_adSetupKey(p));
    }
    await read(_adMgmtRateKey);
    await read(_contentPerPostKey);
    for (final v in EmailVolume.values) {
      await read(_emailKey(v));
    }
    for (final d in CoverageDuration.values) {
      await read(_coverageMultKey(d));
    }

    _loaded = true;
  }

  // ── Getters ──────────────────────────────────────────────────────────
  double socialPlatformMonthly(SocialPlatform p) =>
      _cache[_socialKey(p)] ?? p.monthlyBase;

  double eventBasePrice(EventType t) => _cache[_eventKey(t)] ?? t.basePrice;

  double adSetupFee(AdPlatform p) => _cache[_adSetupKey(p)] ?? p.setupFee;

  double get adMgmtRate => _cache[_adMgmtRateKey] ?? 15.0;

  double get contentPricePerPost => _cache[_contentPerPostKey] ?? 25.0;

  double emailMonthlyPrice(EmailVolume v) =>
      _cache[_emailKey(v)] ?? v.monthlyPrice;

  double coverageMultiplier(CoverageDuration d) =>
      _cache[_coverageMultKey(d)] ?? d.multiplier;

  // ── Setters ──────────────────────────────────────────────────────────
  Future<void> setSocialPlatformMonthly(SocialPlatform p, double v) =>
      _set(_socialKey(p), v);

  Future<void> setEventBasePrice(EventType t, double v) =>
      _set(_eventKey(t), v);

  Future<void> setAdSetupFee(AdPlatform p, double v) =>
      _set(_adSetupKey(p), v);

  Future<void> setAdMgmtRate(double v) => _set(_adMgmtRateKey, v);

  Future<void> setContentPricePerPost(double v) =>
      _set(_contentPerPostKey, v);

  Future<void> setEmailMonthlyPrice(EmailVolume v, double price) =>
      _set(_emailKey(v), price);

  Future<void> setCoverageMultiplier(CoverageDuration d, double v) =>
      _set(_coverageMultKey(d), v);

  Future<void> _set(String key, double value) async {
    _cache[key] = value;
    await DatabaseHelper.instance.setSetting(key, value.toString());
  }
}
