import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
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
                      textColor: textColor),
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
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue
                                : (isDark
                                    ? AppColors.grey800
                                    : AppColors.grey100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: borderColor, width: AppColors.borderWidth),
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
                                color:
                                    selected ? AppColors.white : borderColor,
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
                                    horizontal: 10, vertical: 4),
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
                        const Icon(Icons.info_outline, color: AppColors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textColor, fontSize: 14),
                              children: [
                                const TextSpan(text: 'Factor actual: '),
                                TextSpan(
                                  text:
                                      'x${settingsProvider.multiplier.toStringAsFixed(1)} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '(${settingsProvider.companySize.label})',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
