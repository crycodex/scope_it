import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/project.dart';
import '../../../models/quotation_config.dart';
import '../../../providers/settings_provider.dart';
import '../../../constants/project_icons.dart';
import '../../../models/marketing_config.dart';
import '../../../services/pricing_service.dart';
import '../../../shared/widgets/neu_box.dart';

class NewQuotationView extends StatefulWidget {
  const NewQuotationView({super.key, this.editProjectId});
  final int? editProjectId;

  @override
  State<NewQuotationView> createState() => _NewQuotationViewState();
}

class _NewQuotationViewState extends State<NewQuotationView> {
  int _currentStep = 0;
  late final PageController _pageCtrl;
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  bool _saving = false;
  bool _loadingEdit = false;
  Project? _editProject;

  // Icon
  int? _selectedIconCode;

  // Step 1
  ServiceType? _serviceType;
  String? _customName;
  double? _customPrice;

  // Step 2
  PlatformTier _platformTier = PlatformTier.basic;
  BillingCycle _billingCycle = BillingCycle.monthly;
  MobilePlatform _mobilePlatform = MobilePlatform.playStore;

  // Step 3
  final Set<Feature> _features = {};

  // Step 4
  UserTier _userTier = UserTier.tier0;

  // Step 5
  final Set<Extra> _extras = {};

  // Step 6
  SupportPlan _supportPlan = SupportPlan.none;

  // Step 7 – Marketing (optional)
  bool _includeMarketing = false;
  final Set<MarketingService> _mktServices = {};
  final Set<SocialPlatform> _mktSocialPlatforms = {};
  PostFrequency _mktPostFrequency = PostFrequency.weekly;
  EventType? _mktEventType;
  CoverageDuration _mktCoverageDuration = CoverageDuration.fourHours;
  int _mktEventQuantity = 1;
  final Set<AdPlatform> _mktAdPlatforms = {};
  double? _mktMonthlyAdBudget;
  int _mktContentPostsPerMonth = 4;
  EmailVolume? _mktEmailVolume;

  bool get _isEditing => widget.editProjectId != null;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (_isEditing) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loadingEdit = true);
    final project = await DatabaseHelper.instance.getProject(
      widget.editProjectId!,
    );
    if (project == null || !mounted) return;

    _editProject = project;
    _nameCtrl.text = project.name;
    _clientCtrl.text = project.clientName;
    _selectedIconCode = project.iconCode;

    final config = project.quotationConfig;
    if (config != null) {
      _serviceType = config.serviceTypeEnum ?? ServiceType.web;
      _customName = config.customServiceName;
      _customPrice = config.customBasePrice;
      _platformTier = config.platformTierEnum;
      _billingCycle = config.billingCycleEnum;
      if (config.mobilePlatformEnum != null) {
        _mobilePlatform = config.mobilePlatformEnum!;
      }
      _features
        ..clear()
        ..addAll(config.featureEnums);
      _userTier = config.userTierEnum;
      _extras
        ..clear()
        ..addAll(config.extraEnums);
      _supportPlan = config.supportPlanEnum;
    }

    final mktConfig = project.marketingConfig;
    if (mktConfig != null) {
      _includeMarketing = true;
      _mktServices
        ..clear()
        ..addAll(mktConfig.serviceEnums);
      _mktSocialPlatforms
        ..clear()
        ..addAll(mktConfig.socialPlatformEnums);
      _mktPostFrequency = mktConfig.postFrequencyEnum;
      _mktEventType = mktConfig.eventTypeEnum;
      if (mktConfig.coverageDurationEnum != null) {
        _mktCoverageDuration = mktConfig.coverageDurationEnum!;
      }
      _mktEventQuantity = mktConfig.eventQuantity;
      _mktAdPlatforms
        ..clear()
        ..addAll(mktConfig.adPlatformEnums);
      _mktMonthlyAdBudget = mktConfig.monthlyAdBudget;
      _mktContentPostsPerMonth = mktConfig.contentPostsPerMonth;
      _mktEmailVolume = mktConfig.emailVolumeEnum;
    }

    setState(() => _loadingEdit = false);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  // ── Calculations ───────────────────────────────────────────────────
  final _px = PricingService.instance;

  double get _basePrice {
    if (_serviceType == ServiceType.custom) return _customPrice ?? 0;
    if (_serviceType == null) return 0;
    return _px.serviceBasePrice(_serviceType!);
  }

  double get _baseProject {
    if (_serviceType == ServiceType.app) {
      return _basePrice * _px.mobilePlatformMultiplier(_mobilePlatform);
    }
    return _basePrice * _px.platformMultiplier(_platformTier);
  }

  double get _featuresTotal =>
      _features.fold(0.0, (s, f) => s + _px.featurePrice(f));
  double get _extrasTotal => _extras.fold(0.0, (s, e) => s + _px.extraPrice(e));
  double get _developmentTotal => _baseProject + _featuresTotal + _extrasTotal;

  double get _monthlyRecurring {
    final hosting = _serviceType == ServiceType.app
        ? 0.0
        : _px.platformHosting(_platformTier);
    return hosting + _userTier.monthlyPrice + _px.supportMonthly(_supportPlan);
  }

  double get _monthlyWithDiscount => _monthlyRecurring * _billingCycle.discount;

  MarketingConfig? get _marketingConfig {
    if (!_includeMarketing || _mktServices.isEmpty) return null;
    return MarketingConfig(
      services: _mktServices.map((s) => s.name).toList(),
      socialPlatforms: _mktSocialPlatforms.map((p) => p.name).toList(),
      postFrequency: _mktPostFrequency.name,
      eventType: _mktEventType?.name,
      coverageDuration: _mktServices.contains(MarketingService.eventCoverage)
          ? _mktCoverageDuration.name
          : null,
      eventQuantity: _mktEventQuantity,
      adPlatforms: _mktAdPlatforms.map((p) => p.name).toList(),
      monthlyAdBudget: _mktMonthlyAdBudget,
      contentPostsPerMonth: _mktContentPostsPerMonth,
      emailVolume: _mktEmailVolume?.name,
    );
  }

  double get _marketingTotal => _marketingConfig?.totalEstimate ?? 0;

  double get _totalEstimate {
    final devPart = _billingCycle == BillingCycle.annual
        ? _developmentTotal + (_monthlyWithDiscount * 12)
        : _developmentTotal + _monthlyRecurring;
    return devPart + _marketingTotal;
  }

  // ── Navigation ─────────────────────────────────────────────────────
  void _goToStep(int step) {
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = step);
  }

  bool _canNext() {
    if (_currentStep == 0) {
      return _nameCtrl.text.trim().isNotEmpty &&
          _clientCtrl.text.trim().isNotEmpty &&
          _serviceType != null &&
          (_serviceType != ServiceType.custom ||
              (_customName != null &&
                  _customName!.isNotEmpty &&
                  _customPrice != null &&
                  _customPrice! > 0));
    }
    return true;
  }

  void _next() {
    if (!_canNext()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos requeridos')),
      );
      return;
    }
    if (_currentStep < 7) _goToStep(_currentStep + 1);
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      if (_isEditing) {
        context.go('/project/${widget.editProjectId}');
      } else {
        context.go('/');
      }
    }
  }

  // ── Save / Update ──────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);

    final globalMult = context.read<SettingsProvider>().multiplier;
    final adjustedDevTotal = _developmentTotal * globalMult;
    final monthlyPart = _billingCycle == BillingCycle.annual
        ? _monthlyWithDiscount * 12
        : _monthlyRecurring;
    final finalTotal = adjustedDevTotal + monthlyPart + _marketingTotal;

    final config = QuotationConfig(
      serviceType: _serviceType!.name,
      customServiceName: _serviceType == ServiceType.custom
          ? _customName
          : null,
      customBasePrice: _serviceType == ServiceType.custom ? _customPrice : null,
      platformTier: _platformTier.name,
      billingCycle: _billingCycle.name,
      mobilePlatform: _serviceType == ServiceType.app
          ? _mobilePlatform.name
          : null,
      features: _features.map((f) => f.name).toList(),
      userTier: _userTier.name,
      extras: _extras.map((e) => e.name).toList(),
      supportPlan: _supportPlan.name,
    );

    final mktCfg = _marketingConfig;
    final mktJson = mktCfg != null ? json.encode(mktCfg.toJson()) : null;

    if (_isEditing && _editProject != null) {
      final updated = _editProject!.copyWith(
        name: _nameCtrl.text.trim(),
        clientName: _clientCtrl.text.trim(),
        totalEstimate: finalTotal,
        multiplierUsed: globalMult,
        configJson: json.encode(config.toJson()),
        marketingConfigJson: mktJson,
        iconCode: _selectedIconCode,
      );
      await DatabaseHelper.instance.updateProject(updated);
      if (mounted) context.go('/project/${_editProject!.id}');
    } else {
      final project = Project(
        name: _nameCtrl.text.trim(),
        clientName: _clientCtrl.text.trim(),
        totalEstimate: finalTotal,
        multiplierUsed: globalMult,
        createdAt: DateTime.now(),
        configJson: json.encode(config.toJson()),
        marketingConfigJson: mktJson,
        iconCode: _selectedIconCode,
      );
      final projectId = await DatabaseHelper.instance.insertProject(project);
      if (mounted) context.go('/project/$projectId');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final settingsProvider = context.watch<SettingsProvider>();
    final globalMult = settingsProvider.multiplier;

    if (_loadingEdit) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: Icon(Icons.arrow_back, color: textColor),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Cotización' : 'Nueva Cotización',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: AppColors.borderWidth, color: borderColor),

            // ── Step Indicator ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _StepIndicator(
                currentStep: _currentStep,
                totalSteps: 7,
                isDark: isDark,
                onStepTap: _goToStep,
              ),
            ),

            // ── Step Content ──
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepService(isDark, textColor, borderColor),
                  _buildStepPlatform(isDark, textColor, borderColor),
                  _buildStepFeatures(isDark, textColor, borderColor),
                  _buildStepUsers(isDark, textColor, borderColor),
                  _buildStepExtras(isDark, textColor, borderColor),
                  _buildStepSupport(isDark, textColor, borderColor),
                  _buildStepMarketing(isDark, textColor, borderColor),
                  _buildSummary(isDark, textColor, borderColor, globalMult),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bgColor, borderColor, textColor),
    );
  }

  // ── STEP 0: SERVICIO ───────────────────────────────────────────────
  Widget _buildStepService(bool isDark, Color textColor, Color borderColor) {
    final types = ServiceType.values
        .where((t) => t != ServiceType.custom)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Información del Proyecto', textColor: textColor),
        const SizedBox(height: 12),
        _NeuField(
          controller: _nameCtrl,
          hint: 'Nombre del proyecto *',
          isDark: isDark,
          borderColor: borderColor,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _NeuField(
          controller: _clientCtrl,
          hint: 'Nombre del cliente *',
          isDark: isDark,
          borderColor: borderColor,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // ── Icon picker ──
        _StepTitle(label: 'Ícono del Proyecto', textColor: textColor),
        const SizedBox(height: 10),
        _IconPicker(
          icons: kProjectIcons,
          selectedCode: _selectedIconCode,
          onSelected: (code) => setState(() => _selectedIconCode = code),
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // ── Service type ──
        _StepTitle(label: 'Tipo de Servicio', textColor: textColor),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            ...types.map(
              (type) => _ServiceCard(
                type: type,
                selected: _serviceType == type,
                onTap: () => setState(() {
                  _serviceType = type;
                  _features.removeWhere((f) => !f.availableFor.contains(type));
                  _extras.removeWhere((e) => !e.availableFor.contains(type));
                  // Auto-activate marketing when marketing type selected
                  if (type == ServiceType.marketing) {
                    _includeMarketing = true;
                  } else {
                    _includeMarketing = false;
                  }
                }),
                isDark: isDark,
              ),
            ),
            _ServiceCard(
              type: ServiceType.custom,
              selected: _serviceType == ServiceType.custom,
              onTap: () async {
                final result = await _showCustomServiceDialog(context, isDark);
                if (result != null) {
                  setState(() {
                    _serviceType = ServiceType.custom;
                    _customName = result.$1;
                    _customPrice = result.$2;
                    _includeMarketing = false;
                  });
                }
              },
              isDark: isDark,
              customLabel: _serviceType == ServiceType.custom
                  ? _customName
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<(String, double)?> _showCustomServiceDialog(
    BuildContext ctx,
    bool isDark,
  ) async {
    final nameCtrl = TextEditingController(text: _customName);
    final priceCtrl = TextEditingController(
      text: _customPrice?.toStringAsFixed(0) ?? '',
    );
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return showDialog<(String, double)>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: AppColors.borderWidth),
        ),
        title: const Text(
          'Servicio Personalizado',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio base (\$)',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isNotEmpty && price != null && price > 0) {
                Navigator.pop(ctx, (name, price));
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: PLATAFORMA ─────────────────────────────────────────────
  Widget _buildStepPlatform(bool isDark, Color textColor, Color borderColor) {
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep1Services(isDark, textColor, borderColor);
    }
    if (_serviceType == ServiceType.app) {
      return _buildMobilePlatformStep(isDark, textColor);
    }
    return _buildDeploymentStep(isDark, textColor);
  }

  Widget _buildMobilePlatformStep(bool isDark, Color textColor) {
    String priceTag(MobilePlatform mp) {
      switch (mp) {
        case MobilePlatform.both:
          return '+50%';
        case MobilePlatform.appStore:
          return '+10%';
        case MobilePlatform.apkOnly:
        case MobilePlatform.appBundleOnly:
          return '-15%';
        default:
          return '';
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plataforma de Distribución', textColor: textColor),
        const SizedBox(height: 12),
        ...MobilePlatform.values.map((mp) {
          final tag = priceTag(mp);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NeuBox(
              color: _mobilePlatform == mp
                  ? AppColors.blue
                  : (isDark ? AppColors.grey800 : AppColors.white),
              onTap: () => setState(() => _mobilePlatform = mp),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    mp.icon,
                    color: _mobilePlatform == mp ? AppColors.white : textColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mp.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _mobilePlatform == mp
                                ? AppColors.white
                                : textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mp.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mobilePlatform == mp
                                ? AppColors.white.withAlpha(200)
                                : textColor.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tag.isNotEmpty) ...[
                    Text(
                      tag,
                      style: TextStyle(
                        color: _mobilePlatform == mp
                            ? AppColors.white
                            : (tag.startsWith('-')
                                  ? Colors.green
                                  : AppColors.blue),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _Radio(selected: _mobilePlatform == mp, isDark: isDark),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeploymentStep(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plan de Despliegue', textColor: textColor),
        const SizedBox(height: 12),
        ...PlatformTier.values.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TierCard(
              title: tier.label,
              subtitle: tier.description,
              price: '\$${tier.monthlyHosting.toStringAsFixed(0)}/mes',
              icon: tier.icon,
              selected: _platformTier == tier,
              onTap: () => setState(() => _platformTier = tier),
              isDark: isDark,
              accentColor: tier == PlatformTier.professional
                  ? AppColors.blue
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _StepTitle(label: 'Ciclo de Facturación', textColor: textColor),
        const SizedBox(height: 12),
        Row(
          children: BillingCycle.values.map((cycle) {
            final selected = _billingCycle == cycle;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cycle == BillingCycle.monthly ? 6 : 0,
                  left: cycle == BillingCycle.annual ? 6 : 0,
                ),
                child: NeuBox(
                  color: selected
                      ? AppColors.blue
                      : (isDark ? AppColors.grey800 : AppColors.grey100),
                  onTap: () => setState(() => _billingCycle = cycle),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Center(
                    child: Text(
                      cycle.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 2: FUNCIONALIDADES ────────────────────────────────────────
  Widget _buildStepFeatures(bool isDark, Color textColor, Color borderColor) {
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep2Social(isDark, textColor, borderColor);
    }
    final available = Feature.values
        .where(
          (f) =>
              _serviceType == null ||
              _serviceType == ServiceType.custom ||
              f.availableFor.contains(_serviceType),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Funcionalidades', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Selecciona las funcionalidades que necesitas',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...available.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CheckCard(
              title: feature.label,
              subtitle: '\$${feature.price.toStringAsFixed(0)}',
              icon: feature.icon,
              checked: _features.contains(feature),
              onTap: () => setState(
                () => _features.contains(feature)
                    ? _features.remove(feature)
                    : _features.add(feature),
              ),
              isDark: isDark,
            ),
          ),
        ),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'No hay funcionalidades para este tipo de servicio.',
              style: TextStyle(color: textColor.withAlpha(140)),
            ),
          ),
      ],
    );
  }

  // ── STEP 3: USUARIOS ───────────────────────────────────────────────
  Widget _buildStepUsers(bool isDark, Color textColor, Color borderColor) {
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep3Events(isDark, textColor, borderColor);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Usuarios Esperados / Mes', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Esto afecta los costos de infraestructura',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...UserTier.values.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NeuBox(
              color: _userTier == tier
                  ? AppColors.blue
                  : (isDark ? AppColors.grey800 : AppColors.white),
              onTap: () => setState(() => _userTier = tier),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    tier.icon,
                    color: _userTier == tier ? AppColors.white : textColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tier.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _userTier == tier ? AppColors.white : textColor,
                      ),
                    ),
                  ),
                  Text(
                    tier.monthlyPrice == 0
                        ? 'Incluido'
                        : '+\$${tier.monthlyPrice.toStringAsFixed(0)}/mes',
                    style: TextStyle(
                      color: _userTier == tier
                          ? AppColors.white
                          : AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: _userTier == tier, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 4: ADICIONALES ────────────────────────────────────────────
  Widget _buildStepExtras(bool isDark, Color textColor, Color borderColor) {
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep4Ads(isDark, textColor, borderColor);
    }
    final available = Extra.values
        .where(
          (e) =>
              _serviceType == null ||
              _serviceType == ServiceType.custom ||
              e.availableFor.contains(_serviceType),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Servicios Adicionales', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Agrega módulos extra a tu proyecto',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...available.map(
          (extra) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CheckCard(
              title: extra.label,
              subtitle: '\$${extra.price.toStringAsFixed(0)}',
              icon: extra.icon,
              checked: _extras.contains(extra),
              onTap: () => setState(
                () => _extras.contains(extra)
                    ? _extras.remove(extra)
                    : _extras.add(extra),
              ),
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 5: SOPORTE ────────────────────────────────────────────────
  Widget _buildStepSupport(bool isDark, Color textColor, Color borderColor) {
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep5ContentEmail(isDark, textColor, borderColor);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plan de Soporte', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Elige un plan de soporte y mantenimiento',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...SupportPlan.values.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TierCard(
              title: plan.label,
              subtitle: plan.description,
              price: plan.monthlyPrice == 0
                  ? 'Gratis'
                  : '\$${plan.monthlyPrice.toStringAsFixed(0)}/mes',
              icon: plan.icon,
              selected: _supportPlan == plan,
              onTap: () => setState(() => _supportPlan = plan),
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 6: MARKETING (add-on for non-marketing service types) ──────
  Widget _buildStepMarketing(bool isDark, Color textColor, Color borderColor) {
    // If marketing is the main service type, this step shows a summary/review
    if (_serviceType == ServiceType.marketing) {
      return _buildMktStep6Review(isDark, textColor, borderColor);
    }

    final mktColor = const Color(0xFFE91E63);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Marketing Digital (Opcional)', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Agrega servicios de marketing a esta cotización',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Toggle incluir marketing
        NeuBox(
          color: _includeMarketing
              ? mktColor
              : (isDark ? AppColors.grey800 : AppColors.white),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => setState(() {
            _includeMarketing = !_includeMarketing;
            if (!_includeMarketing) _mktServices.clear();
          }),
          child: Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                color: _includeMarketing ? AppColors.white : textColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incluir Marketing en la Cotización',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _includeMarketing ? AppColors.white : textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activa para agregar servicios de marketing',
                      style: TextStyle(
                        fontSize: 12,
                        color: _includeMarketing
                            ? AppColors.white.withAlpha(200)
                            : textColor.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _includeMarketing,
                activeThumbColor: AppColors.white,
                activeTrackColor: mktColor.withAlpha(180),
                onChanged: (v) => setState(() {
                  _includeMarketing = v;
                  if (!v) _mktServices.clear();
                }),
              ),
            ],
          ),
        ),

        if (_includeMarketing) ...[
          const SizedBox(height: 20),
          _StepTitle(label: 'Servicios de Marketing', textColor: textColor),
          const SizedBox(height: 12),
          ..._buildMktServiceCheckboxes(isDark, textColor, mktColor),
          if (_mktServices.isNotEmpty) ...[
            const SizedBox(height: 20),
            NeuBox(
              color: mktColor.withAlpha(20),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign,
                    color: Color(0xFFE91E63),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total Marketing estimado',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    '\$${_marketingTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── Shared helper: marketing service checkboxes ─────────────────────
  List<Widget> _buildMktServiceCheckboxes(
    bool isDark,
    Color textColor,
    Color mktColor,
  ) {
    return MarketingService.values.map((svc) {
      final selected = _mktServices.contains(svc);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _CheckCard(
          title: svc.label,
          subtitle: svc.description,
          icon: svc.icon,
          checked: selected,
          onTap: () => setState(() {
            selected ? _mktServices.remove(svc) : _mktServices.add(svc);
          }),
          isDark: isDark,
          accentColor: Color(svc.colorValue),
          subtitleBelow: true,
        ),
      );
    }).toList();
  }

  // ── MARKETING STEPS (when marketing is the main service type) ───────

  Widget _buildMktStep1Services(
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    const mktColor = Color(0xFFE91E63);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Servicios de Marketing', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Selecciona los servicios que incluirás',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._buildMktServiceCheckboxes(isDark, textColor, mktColor),
        if (_mktServices.isNotEmpty) ...[
          const SizedBox(height: 20),
          NeuBox(
            color: mktColor.withAlpha(15),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFE91E63),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configura cada servicio en los pasos siguientes',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor == AppColors.white
                          ? AppColors.black
                          : AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMktStep2Social(bool isDark, Color textColor, Color borderColor) {
    const mktColor = Color(0xFFE91E63);
    final hasSocial = _mktServices.contains(MarketingService.socialMedia);

    if (!hasSocial) {
      return _buildMktSkipStep(
        'Redes Sociales',
        'No seleccionaste este servicio',
        Icons.share_outlined,
        textColor,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(
          label: 'Plataformas de Redes Sociales',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...SocialPlatform.values.map((p) {
          final selected = _mktSocialPlatforms.contains(p);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeuBox(
              color: selected
                  ? mktColor
                  : (isDark ? AppColors.grey800 : AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(
                () => selected
                    ? _mktSocialPlatforms.remove(p)
                    : _mktSocialPlatforms.add(p),
              ),
              child: Row(
                children: [
                  Icon(
                    p.icon,
                    color: selected ? AppColors.white : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : textColor,
                      ),
                    ),
                  ),
                  Text(
                    '\$${p.monthlyBase.toStringAsFixed(0)}/mes',
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: selected, isDark: isDark),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        _StepTitle(label: 'Frecuencia de Publicación', textColor: textColor),
        const SizedBox(height: 12),
        ...PostFrequency.values.map((freq) {
          final selected = _mktPostFrequency == freq;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeuBox(
              color: selected
                  ? mktColor
                  : (isDark ? AppColors.grey800 : AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(() => _mktPostFrequency = freq),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: selected ? AppColors.white : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          freq.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.white : textColor,
                          ),
                        ),
                        Text(
                          '${freq.postsPerMonth} publicaciones/mes',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.white.withAlpha(200)
                                : textColor.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '×${freq.multiplier.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: selected, isDark: isDark),
                ],
              ),
            ),
          );
        }),
        if (_mktSocialPlatforms.isNotEmpty) ...[
          const SizedBox(height: 16),
          _MktPricePreview(
            label: 'Redes Sociales / mes',
            amount: _marketingConfig?.socialMediaMonthly ?? 0,
            textColor: textColor,
          ),
        ],
      ],
    );
  }

  Widget _buildMktStep3Events(bool isDark, Color textColor, Color borderColor) {
    const mktColor = Color(0xFFE91E63);
    final hasEvents = _mktServices.contains(MarketingService.eventCoverage);

    if (!hasEvents) {
      return _buildMktSkipStep(
        'Cobertura de Eventos',
        'No seleccionaste este servicio',
        Icons.camera_alt_outlined,
        textColor,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Tipo de Evento', textColor: textColor),
        const SizedBox(height: 12),
        ...EventType.values.map((t) {
          final selected = _mktEventType == t;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeuBox(
              color: selected
                  ? mktColor
                  : (isDark ? AppColors.grey800 : AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(() => _mktEventType = t),
              child: Row(
                children: [
                  Icon(
                    t.icon,
                    color: selected ? AppColors.white : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : textColor,
                      ),
                    ),
                  ),
                  Text(
                    '\$${t.basePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: selected, isDark: isDark),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        _StepTitle(label: 'Duración de Cobertura', textColor: textColor),
        const SizedBox(height: 12),
        ...CoverageDuration.values.map((d) {
          final selected = _mktCoverageDuration == d;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeuBox(
              color: selected
                  ? mktColor
                  : (isDark ? AppColors.grey800 : AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(() => _mktCoverageDuration = d),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    color: selected ? AppColors.white : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : textColor,
                      ),
                    ),
                  ),
                  Text(
                    '×${d.multiplier.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: selected, isDark: isDark),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        _StepTitle(label: 'Eventos por Mes', textColor: textColor),
        const SizedBox(height: 12),
        NeuBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: Color(0xFFE91E63),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_mktEventQuantity evento(s) por mes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: _mktEventQuantity > 1
                    ? mktColor
                    : textColor.withAlpha(80),
                onPressed: _mktEventQuantity > 1
                    ? () => setState(() => _mktEventQuantity--)
                    : null,
              ),
              Text(
                '$_mktEventQuantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: mktColor,
                onPressed: () => setState(() => _mktEventQuantity++),
              ),
            ],
          ),
        ),
        if (_mktEventType != null) ...[
          const SizedBox(height: 16),
          _MktPricePreview(
            label: 'Cobertura de Eventos',
            amount: _marketingConfig?.eventCoverageTotal ?? 0,
            textColor: textColor,
          ),
        ],
      ],
    );
  }

  Widget _buildMktStep4Ads(bool isDark, Color textColor, Color borderColor) {
    const mktColor = Color(0xFFE91E63);
    final hasAds = _mktServices.contains(MarketingService.digitalAds);

    if (!hasAds) {
      return _buildMktSkipStep(
        'Publicidad Digital',
        'No seleccionaste este servicio',
        Icons.ads_click,
        textColor,
      );
    }

    final adBudgetCtrl = TextEditingController(
      text: _mktMonthlyAdBudget?.toStringAsFixed(0) ?? '',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plataformas de Publicidad', textColor: textColor),
        const SizedBox(height: 12),
        ...AdPlatform.values.map((p) {
          final selected = _mktAdPlatforms.contains(p);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeuBox(
              color: selected
                  ? mktColor
                  : (isDark ? AppColors.grey800 : AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(
                () => selected
                    ? _mktAdPlatforms.remove(p)
                    : _mktAdPlatforms.add(p),
              ),
              child: Row(
                children: [
                  Icon(
                    p.icon,
                    color: selected ? AppColors.white : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.white : textColor,
                          ),
                        ),
                        Text(
                          'Setup: \$${p.setupFee.toStringAsFixed(0)} + 15% gestión',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.white.withAlpha(200)
                                : textColor.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Radio(selected: selected, isDark: isDark),
                ],
              ),
            ),
          );
        }),
        if (_mktAdPlatforms.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StepTitle(
            label: 'Presupuesto Mensual de Anuncios',
            textColor: textColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Se cobrará el 15% como fee de gestión',
            style: TextStyle(fontSize: 12, color: textColor.withAlpha(150)),
          ),
          const SizedBox(height: 12),
          _NeuField(
            controller: adBudgetCtrl,
            hint: 'Presupuesto mensual en \$ (ej: 500)',
            isDark: isDark,
            borderColor: isDark ? AppColors.white : AppColors.black,
            onChanged: (v) {
              _mktMonthlyAdBudget = double.tryParse(v);
            },
          ),
          const SizedBox(height: 16),
          _MktPricePreview(
            label: 'Publicidad Digital (setup + gestión)',
            amount:
                (_marketingConfig?.digitalAdsSetup ?? 0) +
                (_marketingConfig?.digitalAdsMgmtMonthly ?? 0),
            textColor: textColor,
          ),
        ],
      ],
    );
  }

  Widget _buildMktStep5ContentEmail(
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    const mktColor = Color(0xFFE91E63);
    final hasContent = _mktServices.contains(MarketingService.contentCreation);
    final hasEmail = _mktServices.contains(MarketingService.emailMarketing);

    if (!hasContent && !hasEmail) {
      return _buildMktSkipStep(
        'Contenido y Email',
        'No seleccionaste estos servicios',
        Icons.draw_outlined,
        textColor,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (hasContent) ...[
          _StepTitle(label: 'Creación de Contenido', textColor: textColor),
          const SizedBox(height: 12),
          NeuBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_mktContentPostsPerMonth piezas / mes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '\$25 por pieza de contenido',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: _mktContentPostsPerMonth > 1
                      ? mktColor
                      : textColor.withAlpha(80),
                  onPressed: _mktContentPostsPerMonth > 1
                      ? () => setState(() => _mktContentPostsPerMonth--)
                      : null,
                ),
                Text(
                  '$_mktContentPostsPerMonth',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: mktColor,
                  onPressed: () => setState(() => _mktContentPostsPerMonth++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _MktPricePreview(
            label: 'Contenido / mes',
            amount: _marketingConfig?.contentCreationMonthly ?? 0,
            textColor: textColor,
          ),
        ],

        if (hasContent && hasEmail) const SizedBox(height: 24),

        if (hasEmail) ...[
          _StepTitle(label: 'Email Marketing — Volumen', textColor: textColor),
          const SizedBox(height: 12),
          ...EmailVolume.values.map((v) {
            final selected = _mktEmailVolume == v;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeuBox(
                color: selected
                    ? mktColor
                    : (isDark ? AppColors.grey800 : AppColors.white),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                onTap: () => setState(() => _mktEmailVolume = v),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: selected ? AppColors.white : textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        v.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.white : textColor,
                        ),
                      ),
                    ),
                    Text(
                      '\$${v.monthlyPrice.toStringAsFixed(0)}/mes',
                      style: TextStyle(
                        color: selected ? AppColors.white : AppColors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Radio(selected: selected, isDark: isDark),
                  ],
                ),
              ),
            );
          }),
          if (_mktEmailVolume != null) ...[
            const SizedBox(height: 8),
            _MktPricePreview(
              label: 'Email Marketing / mes',
              amount: _marketingConfig?.emailMarketingMonthly ?? 0,
              textColor: textColor,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMktStep6Review(bool isDark, Color textColor, Color borderColor) {
    const mktColor = Color(0xFFE91E63);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Revisión de Servicios', textColor: textColor),
        const SizedBox(height: 4),
        Text(
          'Resumen de lo que configuraste',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_mktServices.isEmpty)
          NeuBox(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: textColor.withAlpha(120),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin servicios seleccionados',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regresa al paso 1 para seleccionar servicios de marketing',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withAlpha(150),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          ..._mktServices.map((svc) {
            double svcTotal = 0;
            final cfg = _marketingConfig;
            if (cfg != null) {
              switch (svc) {
                case MarketingService.socialMedia:
                  svcTotal = cfg.socialMediaMonthly;
                  break;
                case MarketingService.eventCoverage:
                  svcTotal = cfg.eventCoverageTotal;
                  break;
                case MarketingService.digitalAds:
                  svcTotal = cfg.digitalAdsSetup + cfg.digitalAdsMgmtMonthly;
                  break;
                case MarketingService.contentCreation:
                  svcTotal = cfg.contentCreationMonthly;
                  break;
                case MarketingService.emailMarketing:
                  svcTotal = cfg.emailMarketingMonthly;
                  break;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NeuBox(
                color: Color(svc.colorValue).withAlpha(15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(svc.colorValue).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        svc.icon,
                        color: Color(svc.colorValue),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textColor == AppColors.white
                                  ? AppColors.black
                                  : AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            svc.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor == AppColors.white
                                  ? AppColors.black
                                  : AppColors.white.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${svcTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Color(svc.colorValue),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          NeuBox(
            color: mktColor.withAlpha(20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: Color(0xFFE91E63), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TOTAL MARKETING',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor == AppColors.white
                          ? AppColors.black
                          : AppColors.white,
                    ),
                  ),
                ),
                Text(
                  '\$${_marketingTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMktSkipStep(
    String title,
    String message,
    IconData icon,
    Color textColor,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: title, textColor: textColor),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Icon(icon, size: 56, color: textColor.withAlpha(60)),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: textColor.withAlpha(120), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Continúa al siguiente paso →',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SUMMARY ────────────────────────────────────────────────────────
  Widget _buildSummary(
    bool isDark,
    Color textColor,
    Color borderColor,
    double globalMult,
  ) {
    final serviceLabel = _serviceType == ServiceType.custom
        ? (_customName ?? 'Personalizado')
        : (_serviceType?.label ?? '');
    final selectedIcon = _selectedIconCode != null
        ? iconDataFromCode(_selectedIconCode!)
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Resumen de Cotización', textColor: textColor),
        const SizedBox(height: 16),

        // Project info + icon
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectedIcon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(selectedIcon, color: AppColors.blue, size: 26),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${_clientCtrl.text}',
                      style: TextStyle(color: textColor.withAlpha(180)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Development breakdown
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desarrollo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: _serviceType == ServiceType.app
                    ? serviceLabel
                    : '$serviceLabel (${_platformTier.label})',
                value: '\$${_baseProject.toStringAsFixed(2)}',
                textColor: textColor,
              ),
              if (_serviceType == ServiceType.app)
                _SummaryRow(
                  label: '  Distribución: ${_mobilePlatform.label}',
                  value: _mobilePlatform.multiplier != 1.0
                      ? '×${_mobilePlatform.multiplier.toStringAsFixed(2)}'
                      : '',
                  textColor: textColor,
                  isSubtle: true,
                ),
              ..._features.map(
                (f) => _SummaryRow(
                  label: '+ ${f.label}',
                  value: '\$${_px.featurePrice(f).toStringAsFixed(0)}',
                  textColor: textColor,
                ),
              ),
              ..._extras.map(
                (e) => _SummaryRow(
                  label: '+ ${e.label}',
                  value: '\$${_px.extraPrice(e).toStringAsFixed(0)}',
                  textColor: textColor,
                ),
              ),
              Container(
                height: 1.5,
                color: borderColor.withAlpha(60),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              _SummaryRow(
                label: 'Subtotal desarrollo',
                value: '\$${_developmentTotal.toStringAsFixed(2)}',
                textColor: textColor,
                isBold: true,
              ),
              if (globalMult != 1.0) ...[
                const SizedBox(height: 4),
                _SummaryRow(
                  label:
                      '  Factor cliente (${context.read<SettingsProvider>().companySize.label})',
                  value: '×${globalMult.toStringAsFixed(1)}',
                  textColor: textColor,
                  valueColor: AppColors.blue,
                  isSubtle: true,
                ),
                _SummaryRow(
                  label: 'Desarrollo ajustado',
                  value:
                      '\$${(_developmentTotal * globalMult).toStringAsFixed(2)}',
                  textColor: textColor,
                  isBold: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Monthly costs
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Costos Recurrentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              if (_serviceType != ServiceType.app)
                _SummaryRow(
                  label: 'Hosting ${_platformTier.label}',
                  value:
                      '\$${_px.platformHosting(_platformTier).toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
              if (_userTier.monthlyPrice > 0)
                _SummaryRow(
                  label: 'Usuarios (${_userTier.label})',
                  value: '\$${_userTier.monthlyPrice.toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
              if (_px.supportMonthly(_supportPlan) > 0)
                _SummaryRow(
                  label: 'Soporte ${_supportPlan.label}',
                  value:
                      '\$${_px.supportMonthly(_supportPlan).toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
              Container(
                height: 1.5,
                color: borderColor.withAlpha(60),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              _SummaryRow(
                label: 'Total mensual',
                value: '\$${_monthlyRecurring.toStringAsFixed(2)}/mes',
                textColor: textColor,
                isBold: true,
              ),
              if (_billingCycle == BillingCycle.annual) ...[
                const SizedBox(height: 4),
                _SummaryRow(
                  label: 'Descuento anual (-20%)',
                  value: '\$${_monthlyWithDiscount.toStringAsFixed(2)}/mes',
                  textColor: textColor,
                  valueColor: AppColors.blue,
                  isSubtle: true,
                ),
                _SummaryRow(
                  label: 'Total anual',
                  value:
                      '\$${(_monthlyWithDiscount * 12).toStringAsFixed(2)}/año',
                  textColor: textColor,
                  isBold: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Marketing summary
        if (_includeMarketing && _mktServices.isNotEmpty) ...[
          NeuBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFFE91E63),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Marketing Digital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._mktServices.map((svc) {
                  double svcTotal = 0;
                  switch (svc) {
                    case MarketingService.socialMedia:
                      svcTotal = _marketingConfig?.socialMediaMonthly ?? 0;
                      break;
                    case MarketingService.eventCoverage:
                      svcTotal = _marketingConfig?.eventCoverageTotal ?? 0;
                      break;
                    case MarketingService.digitalAds:
                      svcTotal =
                          (_marketingConfig?.digitalAdsSetup ?? 0) +
                          (_marketingConfig?.digitalAdsMgmtMonthly ?? 0);
                      break;
                    case MarketingService.contentCreation:
                      svcTotal = _marketingConfig?.contentCreationMonthly ?? 0;
                      break;
                    case MarketingService.emailMarketing:
                      svcTotal = _marketingConfig?.emailMarketingMonthly ?? 0;
                      break;
                  }
                  return _SummaryRow(
                    label: svc.label,
                    value: '\$${svcTotal.toStringAsFixed(2)}',
                    textColor: textColor,
                  );
                }),
                Container(
                  height: 1.5,
                  color: borderColor.withAlpha(60),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                _SummaryRow(
                  label: 'Total Marketing',
                  value: '\$${_marketingTotal.toStringAsFixed(2)}',
                  textColor: textColor,
                  isBold: true,
                  valueColor: const Color(0xFFE91E63),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Grand total
        NeuBox(
          color: AppColors.blue,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ESTIMADO',
                      style: TextStyle(
                        color: AppColors.white.withAlpha(200),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _billingCycle == BillingCycle.annual
                          ? 'Desarrollo + primer año'
                          : 'Desarrollo + primer mes',
                      style: TextStyle(
                        color: AppColors.white.withAlpha(160),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${(_developmentTotal * globalMult + (_billingCycle == BillingCycle.annual ? _monthlyWithDiscount * 12 : _monthlyRecurring)).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(Color bgColor, Color borderColor, Color textColor) {
    final isSummary = _currentStep == 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: AppColors.borderWidth),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSummary && _serviceType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Estimado: ',
                    style: TextStyle(
                      color: textColor.withAlpha(160),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '\$${_totalEstimate.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: _NavBtn(
                    label: 'Atrás',
                    onTap: _back,
                    filled: false,
                    borderColor: borderColor,
                    textColor: textColor,
                    bgColor: isDark ? AppColors.grey800 : AppColors.grey100,
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: _NavBtn(
                  label: _saving
                      ? ''
                      : (isSummary
                            ? (_isEditing
                                  ? 'Guardar Cambios'
                                  : 'Guardar Cotización')
                            : (_currentStep == 6
                                  ? 'Ver Resumen'
                                  : 'Siguiente')),
                  onTap: _saving ? null : (isSummary ? _save : _next),
                  filled: true,
                  borderColor: borderColor,
                  textColor: AppColors.white,
                  bgColor: _saving ? AppColors.grey200 : AppColors.blue,
                  loading: _saving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
    required this.onStepTap,
  });

  final int currentStep;
  final int totalSteps;
  final bool isDark;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = i ~/ 2;
          final done = currentStep > stepBefore;
          return Expanded(
            child: Container(
              height: 2.5,
              color: done ? AppColors.blue : borderColor.withAlpha(50),
            ),
          );
        }
        final step = i ~/ 2;
        final isActive = step == currentStep;
        final isDone = step < currentStep;

        return GestureDetector(
          onTap: isDone ? () => onStepTap(step) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.blue
                  : (isActive
                        ? AppColors.blue.withAlpha(20)
                        : Colors.transparent),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone || isActive
                    ? AppColors.blue
                    : borderColor.withAlpha(80),
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? AppColors.blue
                            : borderColor.withAlpha(120),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.icons,
    required this.selectedCode,
    required this.onSelected,
    required this.isDark,
  });

  final List<IconData> icons;
  final int? selectedCode;
  final ValueChanged<int?> onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: icons.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          // First item = "none" option
          if (i == 0) {
            final isNone = selectedCode == null;
            return GestureDetector(
              onTap: () => onSelected(null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isNone
                      ? AppColors.blue
                      : (isDark ? AppColors.grey800 : AppColors.grey100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNone ? AppColors.blue : borderColor.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isNone ? AppColors.white : borderColor.withAlpha(120),
                ),
              ),
            );
          }
          final icon = icons[i - 1];
          final isSelected = selectedCode == icon.codePoint;
          return GestureDetector(
            onTap: () => onSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.blue
                    : (isDark ? AppColors.grey800 : AppColors.grey100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.blue
                      : borderColor.withAlpha(80),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.white
                    : (isDark ? AppColors.white : AppColors.black),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.label, required this.textColor});
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }
}

class _NeuField extends StatelessWidget {
  const _NeuField({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.borderColor,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color borderColor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        border: Border.all(color: borderColor, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: (isDark ? AppColors.white : AppColors.black).withAlpha(120),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.type,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.customLabel,
  });

  final ServiceType type;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(type.colorValue);
    final textColor = isDark ? AppColors.white : AppColors.black;

    return NeuBox(
      color: selected
          ? accentColor
          : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.white.withAlpha(30)
                  : accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type.icon,
              color: selected ? AppColors.white : accentColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customLabel ?? type.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? AppColors.white : textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (type != ServiceType.custom && type != ServiceType.marketing)
            Text(
              '\$${type.basePrice.toStringAsFixed(0)}',
              style: TextStyle(
                color: selected
                    ? AppColors.white.withAlpha(220)
                    : AppColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          if (type == ServiceType.marketing)
            Text(
              'Variable',
              style: TextStyle(
                color: selected
                    ? AppColors.white.withAlpha(220)
                    : const Color(0xFFE91E63),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle, color: AppColors.white, size: 18),
            ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.white : AppColors.black;
    final selectedTextColor = AppColors.white;

    return NeuBox(
      color: selected
          ? AppColors.blue
          : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.white.withAlpha(30)
                  : (accentColor ?? AppColors.blue).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.white : textColor.withAlpha(180),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? selectedTextColor : textColor,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: selected
                        ? AppColors.white.withAlpha(200)
                        : textColor.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.blue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          _Radio(selected: selected, isDark: isDark),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.checked,
    required this.onTap,
    required this.isDark,
    this.accentColor,
    this.subtitleBelow = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;
  final bool isDark;
  final Color? accentColor;
  final bool subtitleBelow;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.white : AppColors.black;
    final accent = accentColor ?? AppColors.blue;

    final onAccent = AppColors.white;

    return NeuBox(
      color: checked ? accent : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked
                    ? AppColors.white
                    : (isDark ? AppColors.white : AppColors.black),
                width: 2,
              ),
            ),
            child: checked ? Icon(Icons.check, size: 14, color: accent) : null,
          ),
          const SizedBox(width: 14),
          Icon(
            icon,
            color: checked ? onAccent : textColor.withAlpha(160),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: subtitleBelow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: checked ? onAccent : textColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: checked
                              ? AppColors.white.withAlpha(200)
                              : accent.withAlpha(200),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: checked ? onAccent : textColor,
                      fontSize: 14,
                    ),
                  ),
          ),
          if (!subtitleBelow)
            Text(
              subtitle,
              style: TextStyle(
                color: checked ? AppColors.white.withAlpha(220) : accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.isDark});
  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.white : AppColors.black;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.blue : borderColor.withAlpha(100),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.borderColor,
    required this.textColor,
    required this.bgColor,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final Color borderColor;
  final Color textColor;
  final Color bgColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: AppColors.borderWidth),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MktPricePreview extends StatelessWidget {
  const _MktPricePreview({
    required this.label,
    required this.amount,
    required this.textColor,
  });

  final String label;
  final double amount;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            color: Color(0xFFE91E63),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: textColor.withAlpha(180)),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.isBold = false,
    this.isSubtle = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final bool isBold;
  final bool isSubtle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSubtle ? textColor.withAlpha(140) : textColor,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                fontSize: isSubtle ? 12 : (isBold ? 15 : 13),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isBold ? AppColors.blue : textColor),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
