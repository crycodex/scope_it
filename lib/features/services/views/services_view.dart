import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../models/quotation_config.dart';
import '../../../services/pricing_service.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  final _px = PricingService.instance;

  static const _tabs = [
    'Servicios',
    'Despliegue',
    'Funciones',
    'Extras',
    'Soporte',
  ];

  Future<void> _editPrice({
    required String label,
    required double current,
    required Future<void> Function(double) onSave,
    String suffix = '',
    String hint = 'Precio',
  }) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: hint,
            prefixText: suffix.isEmpty ? '\$ ' : null,
            suffixText: suffix.isNotEmpty ? suffix : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v >= 0) Navigator.pop(ctx, v);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (result != null) {
      await onSave(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return DefaultTabController(
      length: _tabs.length,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Tarifas',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            Container(height: AppColors.borderWidth, color: borderColor),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
            Container(height: AppColors.borderWidth, color: borderColor),
            Expanded(
              child: TabBarView(
                children: [
                  _ServiciosTab(px: _px, isDark: isDark, textColor: textColor,
                      borderColor: borderColor, onEdit: _editPrice,
                      onRefresh: () => setState(() {})),
                  _DespliegueTab(px: _px, isDark: isDark, textColor: textColor,
                      borderColor: borderColor, onEdit: _editPrice,
                      onRefresh: () => setState(() {})),
                  _FuncionesTab(px: _px, isDark: isDark, textColor: textColor,
                      borderColor: borderColor, onEdit: _editPrice,
                      onRefresh: () => setState(() {})),
                  _ExtrasTab(px: _px, isDark: isDark, textColor: textColor,
                      borderColor: borderColor, onEdit: _editPrice,
                      onRefresh: () => setState(() {})),
                  _SoporteTab(px: _px, isDark: isDark, textColor: textColor,
                      borderColor: borderColor, onEdit: _editPrice,
                      onRefresh: () => setState(() {})),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared types ─────────────────────────────────────────────────────────────

typedef EditPriceFn = Future<void> Function({
  required String label,
  required double current,
  required Future<void> Function(double) onSave,
  String suffix,
  String hint,
});

// ── Tab: Servicios base ───────────────────────────────────────────────────────

class _ServiciosTab extends StatelessWidget {
  const _ServiciosTab({
    required this.px,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.onEdit,
    required this.onRefresh,
  });

  final PricingService px;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final EditPriceFn onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final editables = ServiceType.values
        .where((t) => t != ServiceType.custom)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionHint(
          text: 'Precio base de desarrollo por tipo de proyecto.',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...editables.map(
          (t) => _PriceRow(
            icon: t.icon,
            iconColor: Color(t.colorValue),
            label: t.label,
            sublabel: t.description,
            value: px.serviceBasePrice(t),
            format: _fmt,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: t.label,
              current: px.serviceBasePrice(t),
              onSave: (v) async {
                await px.setServiceBasePrice(t, v);
                onRefresh();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Despliegue ───────────────────────────────────────────────────────────

class _DespliegueTab extends StatelessWidget {
  const _DespliegueTab({
    required this.px,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.onEdit,
    required this.onRefresh,
  });

  final PricingService px;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final EditPriceFn onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionHint(
          text: 'Hosting mensual y multiplicador por plan (web/backend).',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...PlatformTier.values.expand((t) => [
          _PriceRow(
            icon: t.icon,
            iconColor: AppColors.blue,
            label: '${t.label} — Hosting',
            sublabel: t.description,
            value: px.platformHosting(t),
            format: (v) => '\$${v.toStringAsFixed(0)}/mes',
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: '${t.label} — Hosting mensual',
              current: px.platformHosting(t),
              onSave: (v) async {
                await px.setPlatformHosting(t, v);
                onRefresh();
              },
            ),
          ),
          _PriceRow(
            icon: Icons.close,
            iconColor: AppColors.blue.withAlpha(160),
            label: '${t.label} — Multiplicador',
            sublabel: 'Aplica al precio base del proyecto',
            value: px.platformMultiplier(t),
            format: (v) => '×${v.toStringAsFixed(2)}',
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: '${t.label} — Multiplicador',
              current: px.platformMultiplier(t),
              hint: 'Multiplicador (ej: 1.8)',
              suffix: '×',
              onSave: (v) async {
                await px.setPlatformMultiplier(t, v);
                onRefresh();
              },
            ),
          ),
          const SizedBox(height: 8),
        ]),
        const SizedBox(height: 12),
        _SectionHint(
          text: 'Multiplicador por plataforma móvil (app).',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...MobilePlatform.values.map(
          (m) => _PriceRow(
            icon: m.icon,
            iconColor: AppColors.blue,
            label: m.label,
            sublabel: m.description,
            value: px.mobilePlatformMultiplier(m),
            format: (v) => '×${v.toStringAsFixed(2)}',
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: '${m.label} — Multiplicador',
              current: px.mobilePlatformMultiplier(m),
              hint: 'Multiplicador (ej: 1.5)',
              suffix: '×',
              onSave: (v) async {
                await px.setMobilePlatformMultiplier(m, v);
                onRefresh();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Funcionalidades ──────────────────────────────────────────────────────

class _FuncionesTab extends StatelessWidget {
  const _FuncionesTab({
    required this.px,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.onEdit,
    required this.onRefresh,
  });

  final PricingService px;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final EditPriceFn onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionHint(
          text: 'Precio fijo por funcionalidad incluida en el proyecto.',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...Feature.values.map(
          (f) => _PriceRow(
            icon: f.icon,
            iconColor: AppColors.blue,
            label: f.label,
            sublabel:
                'Para: ${f.availableFor.map((t) => t.label).join(', ')}',
            value: px.featurePrice(f),
            format: _fmt,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: f.label,
              current: px.featurePrice(f),
              onSave: (v) async {
                await px.setFeaturePrice(f, v);
                onRefresh();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Extras ───────────────────────────────────────────────────────────────

class _ExtrasTab extends StatelessWidget {
  const _ExtrasTab({
    required this.px,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.onEdit,
    required this.onRefresh,
  });

  final PricingService px;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final EditPriceFn onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionHint(
          text: 'Precio fijo por extra añadido al proyecto.',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...Extra.values.map(
          (e) => _PriceRow(
            icon: e.icon,
            iconColor: AppColors.blue,
            label: e.label,
            sublabel:
                'Para: ${e.availableFor.map((t) => t.label).join(', ')}',
            value: px.extraPrice(e),
            format: _fmt,
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: () => onEdit(
              label: e.label,
              current: px.extraPrice(e),
              onSave: (v) async {
                await px.setExtraPrice(e, v);
                onRefresh();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Soporte ──────────────────────────────────────────────────────────────

class _SoporteTab extends StatelessWidget {
  const _SoporteTab({
    required this.px,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    required this.onEdit,
    required this.onRefresh,
  });

  final PricingService px;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final EditPriceFn onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionHint(
          text: 'Precio mensual por plan de soporte técnico.',
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        ...SupportPlan.values.map(
          (s) => _PriceRow(
            icon: s.icon,
            iconColor: AppColors.blue,
            label: s.label,
            sublabel: s.description,
            value: px.supportMonthly(s),
            format: (v) => v == 0 ? 'Gratis' : '\$${v.toStringAsFixed(0)}/mes',
            isDark: isDark,
            textColor: textColor,
            borderColor: borderColor,
            onTap: s == SupportPlan.none
                ? null
                : () => onEdit(
                      label: '${s.label} — Soporte mensual',
                      current: px.supportMonthly(s),
                      onSave: (v) async {
                        await px.setSupportMonthly(s, v);
                        onRefresh();
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

String _fmt(double v) => '\$${v.toStringAsFixed(0)}';

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.text, required this.textColor});
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: textColor.withAlpha(140),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.format,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final double value;
  final String Function(double) format;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: borderColor, width: AppColors.borderWidth),
            boxShadow: [
              BoxShadow(
                color: borderColor,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withAlpha(140),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                format(value),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: textColor.withAlpha(120),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
