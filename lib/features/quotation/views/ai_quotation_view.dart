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
import '../../../services/ai_quotation_service.dart';

class AiQuotationView extends StatefulWidget {
  const AiQuotationView({super.key});

  @override
  State<AiQuotationView> createState() => _AiQuotationViewState();
}

class _AiQuotationViewState extends State<AiQuotationView> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await AiQuotationService.instance.generateQuotation(prompt);
      if (!mounted) return;

      final settingsProvider = context.read<SettingsProvider>();
      final globalMult = settingsProvider.multiplier;
      final config = result.config;
      final mktCfg = result.marketingConfig;

      final adjustedDev = config.developmentTotal * globalMult;
      final monthlyPart = config.billingCycleEnum == BillingCycle.annual
          ? config.monthlyWithDiscount * 12
          : config.monthlyRecurring;
      final marketingTotal = mktCfg?.totalEstimate ?? 0.0;
      final finalTotal = adjustedDev + monthlyPart + marketingTotal;

      final project = Project(
        name: result.suggestedProjectName,
        clientName: result.suggestedClientName,
        totalEstimate: finalTotal,
        multiplierUsed: globalMult,
        createdAt: DateTime.now(),
        configJson: json.encode(config.toJson()),
        marketingConfigJson:
            mktCfg != null ? json.encode(mktCfg.toJson()) : null,
      );

      final projectId = await DatabaseHelper.instance.insertProject(project);
      if (!mounted) return;

      context.go('/project/$projectId');
    } on AiQuotationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado. Intenta de nuevo.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.grey900 : AppColors.white;
    final border = isDark ? AppColors.white : AppColors.black;
    final cardBg = isDark ? AppColors.grey800 : AppColors.grey100;
    final textColor = isDark ? AppColors.white : AppColors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border, width: AppColors.borderWidth),
                        boxShadow: [
                          BoxShadow(
                            color: border,
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cotización con IA',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.black),
                        const SizedBox(width: 4),
                        Text(
                          'Gemini',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hint box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border, width: AppColors.borderWidth),
                        boxShadow: [
                          BoxShadow(
                            color: border,
                            offset: const Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: border, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Describe tu proyecto',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cuéntame qué quieres construir: tipo de app, plataforma, funciones, usuarios esperados, etc. La IA generará la cotización automáticamente.',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withAlpha(180),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text field
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border, width: AppColors.borderWidth),
                        boxShadow: [
                          BoxShadow(
                            color: border,
                            offset: const Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _promptCtrl,
                        maxLines: 8,
                        enabled: !_loading,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Ej: Quiero una app móvil para Android de delivery de comida, con pagos integrados, notificaciones push y dashboard para administradores. Esperamos unos 5,000 usuarios activos...',
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: textColor.withAlpha(100),
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3D1515)
                              : const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE53935),
                            width: AppColors.borderWidth,
                          ),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0xFFE53935),
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFE53935),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _loading
                  ? _buildLoadingButton(border, cardBg, textColor)
                  : _buildGenerateButton(border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(Color border) {
    return GestureDetector(
      onTap: _generate,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: AppColors.borderWidth),
          boxShadow: [
            BoxShadow(
              color: border,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.black, size: 22),
            const SizedBox(width: 10),
            Text(
              'Generar Cotización',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton(Color border, Color cardBg, Color textColor) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(
            color: border,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analizando tu proyecto...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
