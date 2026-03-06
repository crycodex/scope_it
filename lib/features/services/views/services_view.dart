import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/category.dart';
import '../../../models/service_item.dart';
import '../../../shared/widgets/neu_box.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  List<Category> _categories = [];
  Map<int, List<ServiceItem>> _servicesByCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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

  Future<void> _addCategory() async {
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => const _CategoryDialog(),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertCategory(result);
      _load();
    }
  }

  Future<void> _editCategory(Category cat) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(category: cat),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateCategory(result);
      _load();
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('Eliminar "${cat.name}" y todos sus servicios?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && cat.id != null) {
      await DatabaseHelper.instance.deleteCategory(cat.id!);
      _load();
    }
  }

  Future<void> _addService(Category cat) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (_) => _ServiceDialog(categoryId: cat.id!),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertService(result);
      _load();
    }
  }

  Future<void> _editService(ServiceItem svc) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (_) => _ServiceDialog(service: svc, categoryId: svc.categoryId),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateService(result);
      _load();
    }
  }

  Future<void> _deleteService(ServiceItem svc) async {
    if (svc.id != null) {
      await DatabaseHelper.instance.deleteService(svc.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Servicios',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                _NeuBtn(
                  label: '+ Categoría',
                  onTap: _addCategory,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Container(height: AppColors.borderWidth, color: borderColor),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Text(
                          'Sin categorías. Agrega una.',
                          style: TextStyle(color: textColor.withAlpha(160)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final services =
                              _servicesByCategory[cat.id] ?? [];
                          return _CategorySection(
                            category: cat,
                            services: services,
                            onEditCat: () => _editCategory(cat),
                            onDeleteCat: () => _deleteCategory(cat),
                            onAddService: () => _addService(cat),
                            onEditService: _editService,
                            onDeleteService: _deleteService,
                            isDark: isDark,
                            borderColor: borderColor,
                            textColor: textColor,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _NeuBtn extends StatelessWidget {
  const _NeuBtn({
    required this.label,
    required this.onTap,
    required this.borderColor,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: AppColors.borderWidth),
          boxShadow: [
            BoxShadow(color: borderColor, offset: const Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.services,
    required this.onEditCat,
    required this.onDeleteCat,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteService,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
  });

  final Category category;
  final List<ServiceItem> services;
  final VoidCallback onEditCat;
  final VoidCallback onDeleteCat;
  final VoidCallback onAddService;
  final ValueChanged<ServiceItem> onEditService;
  final ValueChanged<ServiceItem> onDeleteService;
  final bool isDark;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final catColor = Color(category.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: NeuBox(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: catColor.withAlpha(30),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: textColor),
                    onSelected: (v) {
                      if (v == 'edit') onEditCat();
                      if (v == 'delete') onDeleteCat();
                      if (v == 'add') onAddService();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'add', child: Text('+ Servicio')),
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Services list
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sin servicios. Agrega uno desde el menú.',
                  style: TextStyle(
                    color: textColor.withAlpha(140),
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...services.asMap().entries.map((e) {
                final svc = e.value;
                final isLast = e.key == services.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
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
                                const SizedBox(height: 2),
                                Text(
                                  '\$${svc.basePrice.toStringAsFixed(2)} / ${svc.unit}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onEditService(svc),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: textColor.withAlpha(180),
                          ),
                          IconButton(
                            onPressed: () => onDeleteService(svc),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red.withAlpha(200),
                          ),
                        ],
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

// ── DIALOGS ───────────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  int _colorValue = 0xFF1B9CFC;

  static const _colorOptions = [
    0xFF1B9CFC,
    0xFF4CAF50,
    0xFFFF9800,
    0xFF9C27B0,
    0xFFF44336,
    0xFF00BCD4,
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _desc = TextEditingController(text: widget.category?.description ?? '');
    _colorValue = widget.category?.colorValue ?? 0xFF1B9CFC;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nueva categoría' : 'Editar categoría'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 16),
          Row(
            children: _colorOptions.map((c) {
              return GestureDetector(
                onTap: () => setState(() => _colorValue = c),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _colorValue == c ? Colors.black : Colors.grey,
                      width: _colorValue == c ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Category(
                id: widget.category?.id,
                name: _name.text.trim(),
                description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                colorValue: _colorValue,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({required this.categoryId, this.service});

  final int categoryId;
  final ServiceItem? service;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.service?.name ?? '');
    _desc = TextEditingController(text: widget.service?.description ?? '');
    _price = TextEditingController(
        text: widget.service?.basePrice.toStringAsFixed(2) ?? '');
    _unit = TextEditingController(text: widget.service?.unit ?? 'hora');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Nuevo servicio' : 'Editar servicio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio base *',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unit,
              decoration:
                  const InputDecoration(labelText: 'Unidad (ej: hora, pantalla)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(_price.text);
            if (_name.text.trim().isEmpty || price == null) return;
            Navigator.pop(
              context,
              ServiceItem(
                id: widget.service?.id,
                categoryId: widget.categoryId,
                name: _name.text.trim(),
                description:
                    _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                basePrice: price,
                unit: _unit.text.trim().isEmpty ? 'hora' : _unit.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
