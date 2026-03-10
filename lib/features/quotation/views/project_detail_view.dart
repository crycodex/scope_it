import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/project.dart';
import '../../../models/quotation_config.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/neu_box.dart';

class ProjectDetailView extends StatefulWidget {
  const ProjectDetailView({super.key, required this.projectId});
  final int projectId;

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  Project? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final project = await DatabaseHelper.instance.getProject(widget.projectId);
    setState(() {
      _project = project;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: Icon(Icons.arrow_back, color: textColor),
                  ),
                  Expanded(
                    child: Text(
                      'Detalle del Proyecto',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  // Edit button
                  GestureDetector(
                    onTap: () =>
                        context.go('/quotation', extra: widget.projectId),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.grey800 : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
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
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sales note button
                  GestureDetector(
                    onTap: () => _showSalesNoteOptions(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(12),
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
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                        color: AppColors.white,
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
                  : _project == null
                  ? Center(
                      child: Text(
                        'Proyecto no encontrado',
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : _buildContent(isDark, textColor, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalesNoteOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;

    final project = _project;
    if (project == null) return;

    final config = project.quotationConfig;
    final settings = context.read<SettingsProvider>();
    final ivaPercent = settings.ivaPercent;
    final ivaAmount = project.totalEstimate * ivaPercent / 100;
    final totalWithIva = project.totalEstimate + ivaAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: borderColor, width: AppColors.borderWidth),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nota de Venta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              if (config == null) ...[
                Text(
                  'Este proyecto no tiene una cotización configurada.',
                  style: TextStyle(color: textColor.withAlpha(160)),
                ),
              ] else ...[
                // Totals preview
                _BottomSheetRow(
                  label: 'Subtotal',
                  value: '\$${project.totalEstimate.toStringAsFixed(2)}',
                  textColor: textColor,
                ),
                if (ivaPercent > 0) ...[
                  _BottomSheetRow(
                    label: 'IVA ${ivaPercent.toStringAsFixed(0)}%',
                    value: '\$${ivaAmount.toStringAsFixed(2)}',
                    textColor: AppColors.blue,
                    valueColor: AppColors.blue,
                  ),
                  Container(
                    height: 1.5,
                    color: borderColor.withAlpha(60),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  _BottomSheetRow(
                    label: 'TOTAL con IVA',
                    value: '\$${totalWithIva.toStringAsFixed(2)}',
                    textColor: textColor,
                    isBold: true,
                    valueColor: AppColors.blue,
                  ),
                ],
                const SizedBox(height: 16),
                // Ver / Compartir PDF button
                GestureDetector(
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _generateAndSharePdf(context);
                  },
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
                    child: const Center(
                      child: Text(
                        'Ver / Compartir PDF',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Enviar por Correo button
                GestureDetector(
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _sendEmail(context);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
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
                      child: Text(
                        'Enviar por Correo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndSharePdf(BuildContext context) async {
    final project = _project;
    if (project == null) return;
    final config = project.quotationConfig;
    if (config == null) return;

    final settings = context.read<SettingsProvider>();
    final businessInfo = settings.businessInfo;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final pdfBytes = await PdfService.generateSalesNote(
        project: project,
        config: config,
        businessInfo: businessInfo,
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'nota_venta_${project.name}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final project = _project;
    if (project == null) return;

    final settings = context.read<SettingsProvider>();
    final ivaPercent = settings.ivaPercent;
    final ivaAmount = project.totalEstimate * ivaPercent / 100;
    final totalWithIva = project.totalEstimate + ivaAmount;

    final subject = Uri.encodeComponent('Nota de Venta - ${project.name}');

    final buffer = StringBuffer();
    buffer.writeln('Estimado cliente,');
    buffer.writeln();
    buffer.writeln('Proyecto: ${project.name}');
    buffer.writeln('Cliente: ${project.clientName}');
    buffer.writeln();
    buffer.writeln('Subtotal: \$${project.totalEstimate.toStringAsFixed(2)}');
    if (ivaPercent > 0) {
      buffer.writeln(
        'IVA ${ivaPercent.toStringAsFixed(0)}%: \$${ivaAmount.toStringAsFixed(2)}',
      );
      buffer.writeln('Total con IVA: \$${totalWithIva.toStringAsFixed(2)}');
    }
    buffer.writeln();
    buffer.writeln(
      'Este documento es una estimación. Los precios finales pueden variar.',
    );
    buffer.writeln();
    buffer.writeln('Atentamente,');
    buffer.writeln(settings.businessInfo.companyName);

    final body = Uri.encodeComponent(buffer.toString());
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el correo: $e')),
        );
      }
    }
  }

  Widget _buildContent(bool isDark, Color textColor, Color borderColor) {
    final project = _project!;
    final config = project.quotationConfig;
    final statusColor = Color(project.status.colorValue);
    final settings = context.read<SettingsProvider>();
    final ivaPercent = settings.ivaPercent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Project info + status ──
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Text(
                      project.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: project.status == ProjectStatus.pending
                            ? AppColors.black
                            : AppColors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(project.createdAt),
                    style: TextStyle(
                      color: textColor.withAlpha(140),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                project.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cliente: ${project.clientName}',
                style: TextStyle(color: textColor.withAlpha(180), fontSize: 14),
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: TextStyle(
                    color: textColor.withAlpha(160),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Config-based detail OR legacy line items ──
        if (config != null)
          _buildConfigDetail(
            config,
            project,
            ivaPercent,
            isDark,
            textColor,
            borderColor,
          )
        else
          _buildLegacyDetail(project, isDark, textColor, borderColor),
      ],
    );
  }

  // ── New quotation config detail ─────────────────────────────────────
  Widget _buildConfigDetail(
    QuotationConfig config,
    Project project,
    double ivaPercent,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    final serviceType = config.serviceTypeEnum;
    final serviceLabel = config.serviceLabel;
    final serviceColor = serviceType != null
        ? Color(serviceType.colorValue)
        : AppColors.blue;

    final ivaAmount = project.totalEstimate * ivaPercent / 100;
    final totalWithIva = project.totalEstimate + ivaAmount;

    return Column(
      children: [
        // Service type
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: serviceColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  serviceType?.icon ?? Icons.code,
                  color: serviceColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Servicio',
                      style: TextStyle(
                        color: textColor.withAlpha(150),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      serviceLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                config.platformTierEnum.label,
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Platform & billing info
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plataforma y Facturación',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.cloud,
                label: 'Plan',
                value:
                    '${config.platformTierEnum.label} (\$${config.platformTierEnum.monthlyHosting.toStringAsFixed(0)}/mes)',
                textColor: textColor,
              ),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Ciclo',
                value: config.billingCycleEnum.label,
                textColor: textColor,
              ),
              if (config.mobilePlatformEnum != null)
                _DetailRow(
                  icon: Icons.phone_iphone,
                  label: 'Plataforma',
                  value: config.mobilePlatformEnum!.label,
                  textColor: textColor,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Features
        if (config.featureEnums.isNotEmpty) ...[
          NeuBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Funcionalidades',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...config.featureEnums.map(
                  (f) => _DetailRow(
                    icon: f.icon,
                    label: f.label,
                    value: '\$${f.price.toStringAsFixed(0)}',
                    textColor: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Users
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: _DetailRow(
            icon: config.userTierEnum.icon,
            label: 'Usuarios esperados',
            value:
                '${config.userTierEnum.label} (${config.userTierEnum.monthlyPrice == 0 ? "incluido" : "+\$${config.userTierEnum.monthlyPrice.toStringAsFixed(0)}/mes"})',
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Extras
        if (config.extraEnums.isNotEmpty) ...[
          NeuBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionales',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...config.extraEnums.map(
                  (e) => _DetailRow(
                    icon: e.icon,
                    label: e.label,
                    value: '\$${e.price.toStringAsFixed(0)}',
                    textColor: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Support
        if (config.supportPlanEnum != SupportPlan.none) ...[
          NeuBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soporte',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: config.supportPlanEnum.icon,
                  label: config.supportPlanEnum.label,
                  value:
                      '\$${config.supportPlanEnum.monthlyPrice.toStringAsFixed(0)}/mes',
                  textColor: textColor,
                ),
                Text(
                  config.supportPlanEnum.description,
                  style: TextStyle(
                    color: textColor.withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Price breakdown
        const SizedBox(height: 4),
        NeuBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desglose de Precios',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              _PriceRow(
                label: 'Desarrollo base',
                value: '\$${config.baseProject.toStringAsFixed(2)}',
                textColor: textColor,
              ),
              if (config.featuresTotal > 0)
                _PriceRow(
                  label: 'Funcionalidades',
                  value: '\$${config.featuresTotal.toStringAsFixed(2)}',
                  textColor: textColor,
                ),
              if (config.extrasTotal > 0)
                _PriceRow(
                  label: 'Adicionales',
                  value: '\$${config.extrasTotal.toStringAsFixed(2)}',
                  textColor: textColor,
                ),
              Container(
                height: 1,
                color: borderColor.withAlpha(40),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              _PriceRow(
                label: 'Subtotal desarrollo',
                value: '\$${config.developmentTotal.toStringAsFixed(2)}',
                textColor: textColor,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _PriceRow(
                label: 'Costo mensual',
                value: '\$${config.monthlyRecurring.toStringAsFixed(2)}/mes',
                textColor: textColor,
              ),
              if (config.billingCycleEnum == BillingCycle.annual)
                _PriceRow(
                  label: 'Con descuento anual',
                  value:
                      '\$${config.monthlyWithDiscount.toStringAsFixed(2)}/mes',
                  textColor: textColor,
                  valueColor: AppColors.blue,
                ),
              Container(
                height: 2,
                color: borderColor,
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Subtotal (= project.totalEstimate with multiplier)
              _PriceRow(
                label: 'Subtotal',
                value: '\$${project.totalEstimate.toStringAsFixed(2)}',
                textColor: textColor,
                isBold: true,
              ),

              // IVA rows
              if (ivaPercent > 0) ...[
                const SizedBox(height: 4),
                _PriceRow(
                  label: 'IVA ${ivaPercent.toStringAsFixed(0)}%',
                  value: '\$${ivaAmount.toStringAsFixed(2)}',
                  textColor: AppColors.blue,
                  valueColor: AppColors.blue,
                ),
                Container(
                  height: 2,
                  color: AppColors.blue,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
              ],

              // TOTAL
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    '\$${(ivaPercent > 0 ? totalWithIva : project.totalEstimate).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Legacy line-item detail ─────────────────────────────────────────
  Widget _buildLegacyDetail(
    Project project,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        if (project.lines.isNotEmpty)
          NeuBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servicios',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                ...project.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.serviceName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${line.categoryName} - ${line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 1)} ${line.unit}(s)',
                                style: TextStyle(
                                  color: textColor.withAlpha(150),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${line.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 2,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (project.multiplierUsed != 1.0)
                            Text(
                              'Factor: x${project.multiplierUsed.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: textColor.withAlpha(150),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${project.totalEstimate.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          NeuBox(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '\$${project.totalEstimate.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _BottomSheetRow extends StatelessWidget {
  const _BottomSheetRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                fontSize: isBold ? 15 : 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textColor,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor.withAlpha(180),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                fontSize: isBold ? 15 : 13,
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
