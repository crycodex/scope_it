import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/category.dart';
import '../../../models/project.dart';
import '../../../models/service_item.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/neu_box.dart';

class _QuoteLine {
  final ServiceItem service;
  final Category category;
  double quantity;

  _QuoteLine({
    required this.service,
    required this.category,
    this.quantity = 1,
  });
}

class NewQuotationView extends StatefulWidget {
  const NewQuotationView({super.key});

  @override
  State<NewQuotationView> createState() => _NewQuotationViewState();
}

class _NewQuotationViewState extends State<NewQuotationView> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Category> _categories = [];
  Map<int, List<ServiceItem>> _servicesByCategory = {};
  final List<_QuoteLine> _lines = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await DatabaseHelper.instance.getCategories();
    final map = <int, List<ServiceItem>>{};
    for (final cat in cats) {
      map[cat.id!] =
          await DatabaseHelper.instance.getServices(categoryId: cat.id);
    }
    setState(() {
      _categories = cats;
      _servicesByCategory = map;
      _loading = false;
    });
  }

  double _subtotal(double multiplier) {
    return _lines.fold(0, (sum, l) => sum + l.service.basePrice * l.quantity);
  }

  double _total(double multiplier) => _subtotal(multiplier) * multiplier;

  void _toggleService(ServiceItem svc, Category cat) {
    setState(() {
      final idx = _lines.indexWhere((l) => l.service.id == svc.id);
      if (idx >= 0) {
        _lines.removeAt(idx);
      } else {
        _lines.add(_QuoteLine(service: svc, category: cat, quantity: 1));
      }
    });
  }

  bool _isSelected(ServiceItem svc) =>
      _lines.any((l) => l.service.id == svc.id);

  void _updateQty(ServiceItem svc, double qty) {
    setState(() {
      final line = _lines.firstWhere((l) => l.service.id == svc.id);
      line.quantity = qty.clamp(0.5, 9999);
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _clientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y cliente son requeridos')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un servicio')),
      );
      return;
    }

    setState(() => _saving = true);
    final multiplier =
        context.read<SettingsProvider>().multiplier;
    final total = _total(multiplier);

    final projectLines = _lines
        .map((l) => ProjectLine(
              projectId: 0,
              serviceId: l.service.id!,
              serviceName: l.service.name,
              categoryName: l.category.name,
              quantity: l.quantity,
              unitPrice: l.service.basePrice,
              unit: l.service.unit,
            ))
        .toList();

    final project = Project(
      name: _nameCtrl.text.trim(),
      clientName: _clientCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      totalEstimate: total,
      multiplierUsed: multiplier,
      createdAt: DateTime.now(),
      lines: projectLines,
    );

    await DatabaseHelper.instance.insertProject(project);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final multiplier = context.watch<SettingsProvider>().multiplier;
    final companySize = context.watch<SettingsProvider>().companySize;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: Icon(Icons.arrow_back, color: textColor),
                  ),
                  Expanded(
                    child: Text(
                      'Nueva Cotización',
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      children: [
                        // Client info section
                        _SectionHeader(
                            label: 'Información del Proyecto', textColor: textColor),
                        const SizedBox(height: 12),
                        _NeuField(
                            controller: _nameCtrl,
                            hint: 'Nombre del proyecto *',
                            isDark: isDark,
                            borderColor: borderColor),
                        const SizedBox(height: 12),
                        _NeuField(
                            controller: _clientCtrl,
                            hint: 'Nombre del cliente *',
                            isDark: isDark,
                            borderColor: borderColor),
                        const SizedBox(height: 12),
                        _NeuField(
                            controller: _descCtrl,
                            hint: 'Descripción (opcional)',
                            maxLines: 3,
                            isDark: isDark,
                            borderColor: borderColor),
                        const SizedBox(height: 24),
                        // Company multiplier info
                        NeuBox(
                          color: AppColors.blue.withAlpha(20),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.business_outlined,
                                  color: AppColors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Factor ${companySize.label}: x${multiplier.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'Ajustar en Configuración',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Services selection
                        _SectionHeader(
                            label: 'Selecciona Servicios', textColor: textColor),
                        const SizedBox(height: 12),
                        if (_categories.isEmpty)
                          Text(
                            'No hay categorías. Crea una en la pestaña Servicios.',
                            style: TextStyle(
                                color: textColor.withAlpha(160), fontSize: 14),
                          )
                        else
                          ..._categories.map((cat) {
                            final services =
                                _servicesByCategory[cat.id] ?? [];
                            if (services.isEmpty) return const SizedBox.shrink();
                            return _CategoryServicesBlock(
                              category: cat,
                              services: services,
                              isSelected: _isSelected,
                              onToggle: (svc) => _toggleService(svc, cat),
                              selectedLines: _lines,
                              onQtyChanged: _updateQty,
                              isDark: isDark,
                              borderColor: borderColor,
                              textColor: textColor,
                            );
                          }),
                        const SizedBox(height: 24),
                        // Summary
                        if (_lines.isNotEmpty) ...[
                          _SectionHeader(
                              label: 'Resumen', textColor: textColor),
                          const SizedBox(height: 12),
                          NeuBox(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ..._lines.map((l) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${l.service.name} x${l.quantity.toStringAsFixed(l.quantity % 1 == 0 ? 0 : 1)}',
                                              style: TextStyle(
                                                  color: textColor, fontSize: 13),
                                            ),
                                          ),
                                          Text(
                                            '\$${(l.service.basePrice * l.quantity).toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )),
                                Container(
                                    height: 1.5,
                                    color: borderColor.withAlpha(80),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8)),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text('Subtotal',
                                            style:
                                                TextStyle(color: textColor))),
                                    Text(
                                      '\$${_subtotal(multiplier).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                            'Factor ${companySize.label} (x${multiplier.toStringAsFixed(1)})',
                                            style: TextStyle(
                                                color: textColor.withAlpha(180),
                                                fontSize: 12))),
                                    Text(
                                      '+\$${(_total(multiplier) - _subtotal(multiplier)).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                    height: 2,
                                    color: borderColor,
                                    margin:
                                        const EdgeInsets.only(bottom: 8)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'TOTAL',
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18),
                                      ),
                                    ),
                                    Text(
                                      '\$${_total(multiplier).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
              top: BorderSide(color: borderColor, width: AppColors.borderWidth)),
        ),
        child: GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: _saving ? AppColors.grey200 : AppColors.blue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: AppColors.borderWidth),
              boxShadow: [
                BoxShadow(
                    color: borderColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0),
              ],
            ),
            child: Center(
              child: _saving
                  ? const CircularProgressIndicator(color: AppColors.blue)
                  : const Text(
                      'Guardar Cotización',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.textColor});

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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color borderColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(color: borderColor, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: (isDark ? AppColors.white : AppColors.black).withAlpha(120),
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

class _CategoryServicesBlock extends StatelessWidget {
  const _CategoryServicesBlock({
    required this.category,
    required this.services,
    required this.isSelected,
    required this.onToggle,
    required this.selectedLines,
    required this.onQtyChanged,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
  });

  final Category category;
  final List<ServiceItem> services;
  final bool Function(ServiceItem) isSelected;
  final ValueChanged<ServiceItem> onToggle;
  final List<_QuoteLine> selectedLines;
  final void Function(ServiceItem, double) onQtyChanged;
  final bool isDark;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final catColor = Color(category.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeuBox(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: catColor.withAlpha(25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            ...services.asMap().entries.map((e) {
              final svc = e.value;
              final selected = isSelected(svc);
              final line = selected
                  ? selectedLines.firstWhere((l) => l.service.id == svc.id)
                  : null;
              final isLast = e.key == services.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => onToggle(svc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        selected ? AppColors.blue : borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(Icons.check,
                                        size: 14, color: AppColors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      svc.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '\$${svc.basePrice.toStringAsFixed(2)} / ${svc.unit}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (selected && line != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const SizedBox(width: 34),
                                Text(
                                  'Cantidad (${svc.unit}s):',
                                  style: TextStyle(
                                      fontSize: 12, color: textColor),
                                ),
                                const SizedBox(width: 12),
                                _QtyControl(
                                  qty: line.quantity,
                                  onChanged: (v) => onQtyChanged(svc, v),
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                ),
                                const Spacer(),
                                Text(
                                  '\$${(svc.basePrice * line.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: borderColor.withAlpha(40),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.qty,
    required this.onChanged,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
  });

  final double qty;
  final ValueChanged<double> onChanged;
  final bool isDark;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove,
          onTap: () => onChanged(qty - 1),
          borderColor: borderColor,
          isDark: isDark,
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: textColor, fontSize: 14),
          ),
        ),
        _QtyBtn(
          icon: Icons.add,
          onTap: () => onChanged(qty + 1),
          borderColor: borderColor,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.onTap,
    required this.borderColor,
    required this.isDark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : AppColors.grey100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: borderColor),
      ),
    );
  }
}
