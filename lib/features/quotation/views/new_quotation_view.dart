import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/project.dart';
import '../../../models/quotation_config.dart';
import '../../../shared/widgets/neu_box.dart';

// Curated icon set for projects
const kProjectIcons = [
  Icons.folder,
  Icons.language,
  Icons.phone_iphone,
  Icons.dns,
  Icons.smart_toy,
  Icons.business_center,
  Icons.palette,
  Icons.code,
  Icons.rocket_launch,
  Icons.shopping_cart,
  Icons.health_and_safety,
  Icons.school,
  Icons.restaurant,
  Icons.local_shipping,
  Icons.credit_card,
  Icons.analytics,
  Icons.dashboard,
  Icons.camera_alt,
  Icons.music_note,
  Icons.sports_soccer,
  Icons.travel_explore,
  Icons.store,
  Icons.home_work,
  Icons.construction,
];

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

  bool get _isEditing => widget.editProjectId != null;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (_isEditing) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loadingEdit = true);
    final project =
        await DatabaseHelper.instance.getProject(widget.editProjectId!);
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
  double get _basePrice {
    if (_serviceType == ServiceType.custom) return _customPrice ?? 0;
    return _serviceType?.basePrice ?? 0;
  }

  double get _baseProject {
    double base = _basePrice * _platformTier.multiplier;
    if (_serviceType == ServiceType.app) base *= _mobilePlatform.multiplier;
    return base;
  }

  double get _featuresTotal => _features.fold(0.0, (s, f) => s + f.price);
  double get _extrasTotal => _extras.fold(0.0, (s, e) => s + e.price);
  double get _developmentTotal => _baseProject + _featuresTotal + _extrasTotal;

  double get _monthlyRecurring =>
      _platformTier.monthlyHosting +
      _userTier.monthlyPrice +
      _supportPlan.monthlyPrice;

  double get _monthlyWithDiscount =>
      _monthlyRecurring * _billingCycle.discount;

  double get _totalEstimate {
    if (_billingCycle == BillingCycle.annual) {
      return _developmentTotal + (_monthlyWithDiscount * 12);
    }
    return _developmentTotal + _monthlyRecurring;
  }

  // ── Navigation ─────────────────────────────────────────────────────
  void _goToStep(int step) {
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic);
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
    if (_currentStep < 6) _goToStep(_currentStep + 1);
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

    final config = QuotationConfig(
      serviceType: _serviceType!.name,
      customServiceName:
          _serviceType == ServiceType.custom ? _customName : null,
      customBasePrice:
          _serviceType == ServiceType.custom ? _customPrice : null,
      platformTier: _platformTier.name,
      billingCycle: _billingCycle.name,
      mobilePlatform:
          _serviceType == ServiceType.app ? _mobilePlatform.name : null,
      features: _features.map((f) => f.name).toList(),
      userTier: _userTier.name,
      extras: _extras.map((e) => e.name).toList(),
      supportPlan: _supportPlan.name,
    );

    if (_isEditing && _editProject != null) {
      final updated = _editProject!.copyWith(
        name: _nameCtrl.text.trim(),
        clientName: _clientCtrl.text.trim(),
        totalEstimate: _totalEstimate,
        multiplierUsed: _platformTier.multiplier,
        configJson: json.encode(config.toJson()),
        iconCode: _selectedIconCode,
      );
      await DatabaseHelper.instance.updateProject(updated);
      if (mounted) context.go('/project/${_editProject!.id}');
    } else {
      final project = Project(
        name: _nameCtrl.text.trim(),
        clientName: _clientCtrl.text.trim(),
        totalEstimate: _totalEstimate,
        multiplierUsed: _platformTier.multiplier,
        createdAt: DateTime.now(),
        configJson: json.encode(config.toJson()),
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
                totalSteps: 6,
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
                  _buildSummary(isDark, textColor, borderColor),
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
    final types =
        ServiceType.values.where((t) => t != ServiceType.custom).toList();

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
            ...types.map((type) => _ServiceCard(
                  type: type,
                  selected: _serviceType == type,
                  onTap: () => setState(() {
                    _serviceType = type;
                    _features.removeWhere(
                        (f) => !f.availableFor.contains(type));
                    _extras.removeWhere(
                        (e) => !e.availableFor.contains(type));
                  }),
                  isDark: isDark,
                )),
            _ServiceCard(
              type: ServiceType.custom,
              selected: _serviceType == ServiceType.custom,
              onTap: () async {
                final result =
                    await _showCustomServiceDialog(context, isDark);
                if (result != null) {
                  setState(() {
                    _serviceType = ServiceType.custom;
                    _customName = result.$1;
                    _customPrice = result.$2;
                  });
                }
              },
              isDark: isDark,
              customLabel:
                  _serviceType == ServiceType.custom ? _customName : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<(String, double)?> _showCustomServiceDialog(
      BuildContext ctx, bool isDark) async {
    final nameCtrl = TextEditingController(text: _customName);
    final priceCtrl = TextEditingController(
        text: _customPrice?.toStringAsFixed(0) ?? '');
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return showDialog<(String, double)>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: AppColors.borderWidth),
        ),
        title: const Text('Servicio Personalizado',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nombre del servicio'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Precio base (\$)', prefixText: '\$ '),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plan de Despliegue', textColor: textColor),
        const SizedBox(height: 12),
        ...PlatformTier.values.map((tier) => Padding(
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
            )),
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
                    left: cycle == BillingCycle.annual ? 6 : 0),
                child: NeuBox(
                  color: selected
                      ? AppColors.blue
                      : (isDark ? AppColors.grey800 : AppColors.grey100),
                  onTap: () => setState(() => _billingCycle = cycle),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
        if (_serviceType == ServiceType.app) ...[
          const SizedBox(height: 20),
          _StepTitle(label: 'Plataforma Móvil', textColor: textColor),
          const SizedBox(height: 12),
          ...MobilePlatform.values.map((mp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeuBox(
                  color: _mobilePlatform == mp
                      ? AppColors.blue.withAlpha(25)
                      : (isDark ? AppColors.grey800 : AppColors.white),
                  onTap: () => setState(() => _mobilePlatform = mp),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(mp.icon,
                          color: _mobilePlatform == mp
                              ? AppColors.blue
                              : textColor,
                          size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(mp.label,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: textColor)),
                      ),
                      if (mp == MobilePlatform.both)
                        Text('+50%',
                            style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      const SizedBox(width: 8),
                      _Radio(selected: _mobilePlatform == mp, isDark: isDark),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  // ── STEP 2: FUNCIONALIDADES ────────────────────────────────────────
  Widget _buildStepFeatures(bool isDark, Color textColor, Color borderColor) {
    final available = Feature.values
        .where((f) =>
            _serviceType == null ||
            _serviceType == ServiceType.custom ||
            f.availableFor.contains(_serviceType))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Funcionalidades', textColor: textColor),
        const SizedBox(height: 4),
        Text('Selecciona las funcionalidades que necesitas',
            style: TextStyle(color: textColor.withAlpha(160), fontSize: 13)),
        const SizedBox(height: 16),
        ...available.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CheckCard(
                title: feature.label,
                subtitle: '\$${feature.price.toStringAsFixed(0)}',
                icon: feature.icon,
                checked: _features.contains(feature),
                onTap: () => setState(() => _features.contains(feature)
                    ? _features.remove(feature)
                    : _features.add(feature)),
                isDark: isDark,
              ),
            )),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Usuarios Esperados / Mes', textColor: textColor),
        const SizedBox(height: 4),
        Text('Esto afecta los costos de infraestructura',
            style: TextStyle(color: textColor.withAlpha(160), fontSize: 13)),
        const SizedBox(height: 16),
        ...UserTier.values.map((tier) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NeuBox(
                color: _userTier == tier
                    ? AppColors.blue.withAlpha(25)
                    : (isDark ? AppColors.grey800 : AppColors.white),
                onTap: () => setState(() => _userTier = tier),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(tier.icon,
                        color:
                            _userTier == tier ? AppColors.blue : textColor,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tier.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: textColor)),
                    ),
                    Text(
                      tier.monthlyPrice == 0
                          ? 'Incluido'
                          : '+\$${tier.monthlyPrice.toStringAsFixed(0)}/mes',
                      style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _Radio(selected: _userTier == tier, isDark: isDark),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ── STEP 4: ADICIONALES ────────────────────────────────────────────
  Widget _buildStepExtras(bool isDark, Color textColor, Color borderColor) {
    final available = Extra.values
        .where((e) =>
            _serviceType == null ||
            _serviceType == ServiceType.custom ||
            e.availableFor.contains(_serviceType))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Servicios Adicionales', textColor: textColor),
        const SizedBox(height: 4),
        Text('Agrega módulos extra a tu proyecto',
            style: TextStyle(color: textColor.withAlpha(160), fontSize: 13)),
        const SizedBox(height: 16),
        ...available.map((extra) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CheckCard(
                title: extra.label,
                subtitle: '\$${extra.price.toStringAsFixed(0)}',
                icon: extra.icon,
                checked: _extras.contains(extra),
                onTap: () => setState(() => _extras.contains(extra)
                    ? _extras.remove(extra)
                    : _extras.add(extra)),
                isDark: isDark,
              ),
            )),
      ],
    );
  }

  // ── STEP 5: SOPORTE ────────────────────────────────────────────────
  Widget _buildStepSupport(bool isDark, Color textColor, Color borderColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _StepTitle(label: 'Plan de Soporte', textColor: textColor),
        const SizedBox(height: 4),
        Text('Elige un plan de soporte y mantenimiento',
            style: TextStyle(color: textColor.withAlpha(160), fontSize: 13)),
        const SizedBox(height: 16),
        ...SupportPlan.values.map((plan) => Padding(
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
            )),
      ],
    );
  }

  // ── SUMMARY ────────────────────────────────────────────────────────
  Widget _buildSummary(bool isDark, Color textColor, Color borderColor) {
    final serviceLabel = _serviceType == ServiceType.custom
        ? (_customName ?? 'Personalizado')
        : (_serviceType?.label ?? '');

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
              if (_selectedIconCode != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconData(_selectedIconCode!,
                        fontFamily: 'MaterialIcons'),
                    color: AppColors.blue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameCtrl.text,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    const SizedBox(height: 4),
                    Text('Cliente: ${_clientCtrl.text}',
                        style: TextStyle(
                            color: textColor.withAlpha(180))),
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
              Text('Desarrollo',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              const SizedBox(height: 12),
              _SummaryRow(
                label: '$serviceLabel (${_platformTier.label})',
                value: '\$${_baseProject.toStringAsFixed(2)}',
                textColor: textColor,
              ),
              if (_serviceType == ServiceType.app)
                _SummaryRow(
                  label: '  Plataforma: ${_mobilePlatform.label}',
                  value: _mobilePlatform == MobilePlatform.both ? '+50%' : '',
                  textColor: textColor,
                  isSubtle: true,
                ),
              ..._features.map((f) => _SummaryRow(
                    label: '+ ${f.label}',
                    value: '\$${f.price.toStringAsFixed(0)}',
                    textColor: textColor,
                  )),
              ..._extras.map((e) => _SummaryRow(
                    label: '+ ${e.label}',
                    value: '\$${e.price.toStringAsFixed(0)}',
                    textColor: textColor,
                  )),
              Container(
                  height: 1.5,
                  color: borderColor.withAlpha(60),
                  margin: const EdgeInsets.symmetric(vertical: 8)),
              _SummaryRow(
                label: 'Subtotal desarrollo',
                value: '\$${_developmentTotal.toStringAsFixed(2)}',
                textColor: textColor,
                isBold: true,
              ),
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
              Text('Costos Recurrentes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Hosting ${_platformTier.label}',
                value:
                    '\$${_platformTier.monthlyHosting.toStringAsFixed(0)}/mes',
                textColor: textColor,
              ),
              if (_userTier.monthlyPrice > 0)
                _SummaryRow(
                  label: 'Usuarios (${_userTier.label})',
                  value:
                      '\$${_userTier.monthlyPrice.toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
              if (_supportPlan.monthlyPrice > 0)
                _SummaryRow(
                  label: 'Soporte ${_supportPlan.label}',
                  value:
                      '\$${_supportPlan.monthlyPrice.toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
              Container(
                  height: 1.5,
                  color: borderColor.withAlpha(60),
                  margin: const EdgeInsets.symmetric(vertical: 8)),
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
                  value:
                      '\$${_monthlyWithDiscount.toStringAsFixed(2)}/mes',
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
                    Text('TOTAL ESTIMADO',
                        style: TextStyle(
                            color: AppColors.white.withAlpha(200),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _billingCycle == BillingCycle.annual
                          ? 'Desarrollo + primer año'
                          : 'Desarrollo + primer mes',
                      style: TextStyle(
                          color: AppColors.white.withAlpha(160),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${_totalEstimate.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(Color bgColor, Color borderColor, Color textColor) {
    final isSummary = _currentStep == 6;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
            top: BorderSide(
                color: borderColor, width: AppColors.borderWidth)),
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
                  Text('Estimado: ',
                      style: TextStyle(
                          color: textColor.withAlpha(160), fontSize: 13)),
                  Text('\$${_totalEstimate.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
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
                          : (_currentStep == 5 ? 'Ver Resumen' : 'Siguiente')),
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

  bool get isDark =>
      Theme.of(context).brightness == Brightness.dark;
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
                  ? const Icon(Icons.check,
                      size: 16, color: AppColors.white)
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
                      width: 2),
                ),
                child: Icon(Icons.close,
                    size: 20,
                    color: isNone
                        ? AppColors.white
                        : borderColor.withAlpha(120)),
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
                    width: 2),
              ),
              child: Icon(icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.white
                      : (isDark ? AppColors.white : AppColors.black)),
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
    return Text(label,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: textColor));
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(
              color: borderColor, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color:
                (isDark ? AppColors.white : AppColors.black).withAlpha(120),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ? accentColor.withAlpha(30)
          : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(type.icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            customLabel ?? type.label,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: textColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (type != ServiceType.custom)
            Text('\$${type.basePrice.toStringAsFixed(0)}',
                style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle, color: accentColor, size: 18),
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

    return NeuBox(
      color: selected
          ? AppColors.blue.withAlpha(25)
          : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (accentColor ?? AppColors.blue).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: selected ? AppColors.blue : textColor.withAlpha(180),
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(
                        color: textColor.withAlpha(150), fontSize: 12)),
              ],
            ),
          ),
          Text(price,
              style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.white : AppColors.black;

    return NeuBox(
      color: checked
          ? AppColors.blue.withAlpha(20)
          : (isDark ? AppColors.grey800 : AppColors.white),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? AppColors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: checked
                      ? AppColors.blue
                      : (isDark ? AppColors.white : AppColors.black),
                  width: 2),
            ),
            child: checked
                ? const Icon(Icons.check, size: 14, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Icon(icon,
              color: checked ? AppColors.blue : textColor.withAlpha(160),
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 14)),
          ),
          Text(subtitle,
              style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
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
            width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.blue, shape: BoxShape.circle),
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
                blurRadius: 0),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2),
                )
              : Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
        ),
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
            child: Text(label,
                style: TextStyle(
                  color: isSubtle ? textColor.withAlpha(140) : textColor,
                  fontWeight:
                      isBold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: isSubtle ? 12 : (isBold ? 15 : 13),
                )),
          ),
          Text(value,
              style: TextStyle(
                  color: valueColor ??
                      (isBold ? AppColors.blue : textColor),
                  fontWeight:
                      isBold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: isBold ? 15 : 13)),
        ],
      ),
    );
  }
}
