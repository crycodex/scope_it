import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../models/business_info.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/neu_box.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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
                      'Configuración',
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
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Theme section
                  _SectionTitle(label: 'Apariencia', textColor: textColor),
                  const SizedBox(height: 12),
                  NeuBox(
                    padding: const EdgeInsets.all(0),
                    child: SwitchListTile(
                      title: Text(
                        'Modo Oscuro',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
                        style: TextStyle(
                          color: textColor.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: AppColors.blue,
                      ),
                      value: themeProvider.isDarkMode,
                      activeThumbColor: AppColors.blue,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Company size section
                  _SectionTitle(
                    label: 'Factor de Precio por Tipo de Cliente',
                    textColor: textColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajusta el multiplicador según el tamaño de la empresa del cliente.',
                    style: TextStyle(
                      color: textColor.withAlpha(160),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...CompanySize.values.map((size) {
                    final selected = settingsProvider.companySize == size;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => settingsProvider.setCompanySize(size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue
                                : (isDark
                                      ? AppColors.grey800
                                      : AppColors.grey100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: AppColors.borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: selected
                                    ? const Offset(2, 2)
                                    : const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected ? AppColors.white : borderColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  size.label,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.white
                                        : textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.white.withAlpha(30)
                                      : AppColors.blue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.blue,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'x${size.multiplier.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Current multiplier info
                  NeuBox(
                    color: AppColors.blue.withAlpha(20),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textColor, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Factor actual: ',
                                  style: TextStyle(
                                    color: textColor == AppColors.white
                                        ? AppColors.black
                                        : AppColors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'x${settingsProvider.multiplier.toStringAsFixed(1)} ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: textColor == AppColors.white
                                        ? AppColors.black
                                        : AppColors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '(${settingsProvider.companySize.label})',
                                  style: TextStyle(
                                    color: textColor == AppColors.white
                                        ? AppColors.black
                                        : AppColors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Business Info Section ──────────────────────────────
                  const SizedBox(height: 24),
                  _SectionTitle(
                    label: 'Información del Negocio',
                    textColor: textColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta información aparecerá en las notas de venta generadas.',
                    style: TextStyle(
                      color: textColor.withAlpha(160),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BusinessInfoForm(
                    initial: settingsProvider.businessInfo,
                    isDark: isDark,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Business Info Form ──────────────────────────────────────────────────────

class _BusinessInfoForm extends StatefulWidget {
  const _BusinessInfoForm({
    required this.initial,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
  });

  final BusinessInfo initial;
  final bool isDark;
  final Color textColor;
  final Color borderColor;

  @override
  State<_BusinessInfoForm> createState() => _BusinessInfoFormState();
}

class _BusinessInfoFormState extends State<_BusinessInfoForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _ivaCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.companyName);
    _emailCtrl = TextEditingController(text: widget.initial.email);
    _phoneCtrl = TextEditingController(text: widget.initial.phone);
    _addressCtrl = TextEditingController(text: widget.initial.address);
    _websiteCtrl = TextEditingController(text: widget.initial.website);
    _ivaCtrl = TextEditingController(
      text: widget.initial.ivaPercent == 0
          ? ''
          : widget.initial.ivaPercent.toStringAsFixed(
              widget.initial.ivaPercent % 1 == 0 ? 0 : 2,
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _ivaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final info = BusinessInfo(
      companyName: _nameCtrl.text.trim().isEmpty
          ? 'Ionos Hub'
          : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      ivaPercent: (int.tryParse(_ivaCtrl.text.trim()) ?? 0).toDouble(),
    );

    await context.read<SettingsProvider>().saveBusinessInfo(info);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Información guardada')));
    }
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final borderColor = widget.borderColor;
    final isDark = widget.isDark;

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
        controller: ctrl,
        keyboardType: keyboardType,
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

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(_nameCtrl, 'Nombre de la empresa (ej. Ionos Hub)'),
        const SizedBox(height: 10),
        _buildField(
          _emailCtrl,
          'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _buildField(_phoneCtrl, 'Teléfono', keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _buildField(_addressCtrl, 'Dirección'),
        const SizedBox(height: 10),
        _buildField(_websiteCtrl, 'Sitio web', keyboardType: TextInputType.url),
        const SizedBox(height: 10),
        _buildField(
          _ivaCtrl,
          'IVA % (0 = sin IVA)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _save,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: AppColors.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar Información',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }
}
