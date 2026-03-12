import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/business_info.dart';
import '../models/marketing_config.dart';
import '../models/project.dart';
import '../models/quotation_config.dart';

class PdfService {
  static Future<Uint8List> generateSalesNote({
    required Project project,
    required QuotationConfig config,
    required BusinessInfo businessInfo,
    MarketingConfig? marketingConfig,
  }) async {
    final pdf = pw.Document();

    final blue = PdfColor.fromHex('#1B9CFC');
    final lightGrey = PdfColor.fromHex('#F5F5F5');
    final darkGrey = PdfColor.fromHex('#666666');
    final black = PdfColor.fromHex('#000000');
    final white = PdfColor.fromHex('#FFFFFF');

    final fontNormal = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final ivaAmount = project.totalEstimate * businessInfo.ivaPercent / 100;
    final totalWithIva = project.totalEstimate + ivaAmount;

    final serviceType = config.serviceTypeEnum;
    final serviceLabel = config.serviceLabel;
    final isApp = serviceType == ServiceType.app;

    // Determine platform label for base row
    String basePlatformLabel;
    if (isApp && config.mobilePlatformEnum != null) {
      basePlatformLabel = config.mobilePlatformEnum!.label;
    } else {
      basePlatformLabel = config.platformTierEnum.label;
    }

    // Build development rows
    final List<_PdfTableRow> devRows = [];

    // Base development
    devRows.add(_PdfTableRow(
      label: '$serviceLabel ($basePlatformLabel)',
      value: '\$${config.baseProject.toStringAsFixed(2)}',
      isBold: false,
      isSmall: false,
    ));

    // Features
    for (final feature in config.featureEnums) {
      devRows.add(_PdfTableRow(
        label: '+ ${feature.label}',
        value: '\$${feature.price.toStringAsFixed(2)}',
        isBold: false,
        isSmall: false,
      ));
    }

    // Extras
    for (final extra in config.extraEnums) {
      devRows.add(_PdfTableRow(
        label: '+ ${extra.label}',
        value: '\$${extra.price.toStringAsFixed(2)}',
        isBold: false,
        isSmall: false,
      ));
    }

    // Subtotal desarrollo
    devRows.add(_PdfTableRow(
      label: 'Subtotal desarrollo',
      value: '\$${config.developmentTotal.toStringAsFixed(2)}',
      isBold: true,
      isSmall: false,
      isSeparatorBefore: true,
    ));

    // Multiplier
    final mult = project.multiplierUsed;
    if (mult != 1.0) {
      devRows.add(_PdfTableRow(
        label: '  Factor cliente (×${mult.toStringAsFixed(1)})',
        value: '×${mult.toStringAsFixed(1)}',
        isBold: false,
        isSmall: true,
      ));
      final adjustedDev = config.developmentTotal * mult;
      devRows.add(_PdfTableRow(
        label: 'Desarrollo ajustado',
        value: '\$${adjustedDev.toStringAsFixed(2)}',
        isBold: true,
        isSmall: false,
      ));
    }

    // Build recurring rows
    final List<_PdfTableRow> recurringRows = [];
    final hasRecurring = !isApp ||
        config.userTierEnum.monthlyPrice > 0 ||
        config.supportPlanEnum != SupportPlan.none;

    if (!isApp) {
      recurringRows.add(_PdfTableRow(
        label: 'Hosting ${config.platformTierEnum.label}',
        value: '\$${config.platformTierEnum.monthlyHosting.toStringAsFixed(2)}/mes',
        isBold: false,
        isSmall: false,
      ));
    }
    if (config.userTierEnum.monthlyPrice > 0) {
      recurringRows.add(_PdfTableRow(
        label: 'Usuarios (${config.userTierEnum.label})',
        value: '\$${config.userTierEnum.monthlyPrice.toStringAsFixed(2)}/mes',
        isBold: false,
        isSmall: false,
      ));
    }
    if (config.supportPlanEnum != SupportPlan.none) {
      recurringRows.add(_PdfTableRow(
        label: 'Soporte ${config.supportPlanEnum.label}',
        value: '\$${config.supportPlanEnum.monthlyPrice.toStringAsFixed(2)}/mes',
        isBold: false,
        isSmall: false,
      ));
    }
    if (recurringRows.isNotEmpty) {
      recurringRows.add(_PdfTableRow(
        label: 'Total mensual',
        value: '\$${config.monthlyRecurring.toStringAsFixed(2)}/mes',
        isBold: true,
        isSmall: false,
        isSeparatorBefore: true,
      ));
      if (config.billingCycleEnum == BillingCycle.annual) {
        recurringRows.add(_PdfTableRow(
          label: 'Con descuento anual (-20%)',
          value: '\$${config.monthlyWithDiscount.toStringAsFixed(2)}/mes',
          isBold: false,
          isSmall: false,
        ));
        recurringRows.add(_PdfTableRow(
          label: 'Total período (12 meses)',
          value: '\$${(config.monthlyWithDiscount * 12).toStringAsFixed(2)}/año',
          isBold: false,
          isSmall: false,
        ));
      }
    }

    // Build marketing rows
    final List<_PdfTableRow> marketingRows = [];
    final mkt = marketingConfig;
    if (mkt != null && mkt.services.isNotEmpty) {
      for (final svc in mkt.serviceEnums) {
        double svcTotal = 0;
        switch (svc) {
          case MarketingService.socialMedia:
            svcTotal = mkt.socialMediaMonthly;
            break;
          case MarketingService.eventCoverage:
            svcTotal = mkt.eventCoverageTotal;
            break;
          case MarketingService.digitalAds:
            svcTotal = mkt.digitalAdsSetup + mkt.digitalAdsMgmtMonthly;
            break;
          case MarketingService.contentCreation:
            svcTotal = mkt.contentCreationMonthly;
            break;
          case MarketingService.emailMarketing:
            svcTotal = mkt.emailMarketingMonthly;
            break;
        }
        marketingRows.add(_PdfTableRow(
          label: svc.label,
          value: '\$${svcTotal.toStringAsFixed(2)}',
          isBold: false,
          isSmall: false,
        ));
      }
      marketingRows.add(_PdfTableRow(
        label: 'Total Marketing',
        value: '\$${mkt.totalEstimate.toStringAsFixed(2)}',
        isBold: true,
        isSmall: false,
        isSeparatorBefore: true,
      ));
    }

    pw.Widget buildTableRow(
      _PdfTableRow row,
      pw.Font fNormal,
      pw.Font fBold,
      PdfColor dGrey,
      PdfColor blueC,
    ) {
      final labelFont = row.isBold ? fBold : fNormal;
      final valueFont = row.isBold ? fBold : fNormal;
      final fontSize = row.isSmall ? 8.0 : 10.0;
      final labelColor = row.isSmall ? dGrey : black;

      return pw.Column(
        children: [
          if (row.isSeparatorBefore)
            pw.Container(
              height: 0.5,
              color: PdfColor.fromHex('#CCCCCC'),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
            ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  row.label,
                  style: pw.TextStyle(
                    font: labelFont,
                    fontSize: fontSize,
                    color: labelColor,
                  ),
                ),
              ),
              pw.Text(
                row.value,
                style: pw.TextStyle(
                  font: valueFont,
                  fontSize: fontSize,
                  color: row.isBold ? blueC : labelColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(56.69), // ~2cm
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. Blue header band ─────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: pw.BoxDecoration(
                  color: blue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: company info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            businessInfo.companyName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 22,
                              color: white,
                            ),
                          ),
                          if (businessInfo.email.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              businessInfo.email,
                              style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 9,
                                color: white,
                              ),
                            ),
                          ],
                          if (businessInfo.phone.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              businessInfo.phone,
                              style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 9,
                                color: white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Right: document title
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'NOTA DE VENTA',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                        if (businessInfo.website.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            businessInfo.website,
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 9,
                              color: white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // ── 2. Document meta row ─────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'No. NV-${(project.id ?? 0).toString().padLeft(4, '0')}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: darkGrey,
                    ),
                  ),
                  pw.Expanded(child: pw.SizedBox()),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Fecha: $dateStr',
                        style: pw.TextStyle(
                          font: fontNormal,
                          fontSize: 10,
                          color: darkGrey,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Válida por 30 días',
                        style: pw.TextStyle(
                          font: fontNormal,
                          fontSize: 9,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── 3. Info box ──────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Cliente',
                                style: pw.TextStyle(
                                  font: fontNormal,
                                  fontSize: 9,
                                  color: darkGrey,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                project.clientName,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 13,
                                  color: black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Proyecto',
                                style: pw.TextStyle(
                                  font: fontNormal,
                                  fontSize: 9,
                                  color: darkGrey,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                project.name,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 13,
                                  color: black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Servicio: $serviceLabel',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: black,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Plan: ${config.platformTierEnum.label}  ·  Facturación: ${config.billingCycleEnum.label}'
                      '${config.mobilePlatformEnum != null ? '  ·  Plataforma: ${config.mobilePlatformEnum!.label}' : ''}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ── 4. Section title ─────────────────────────────────────
              pw.Text(
                'Desglose de Precios',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: black,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 1,
                color: blue,
              ),
              pw.SizedBox(height: 8),

              // ── 5. Development table ─────────────────────────────────
              ...devRows.map(
                (row) => buildTableRow(row, fontNormal, fontBold, darkGrey, blue),
              ),

              // ── 6. Recurring costs ───────────────────────────────────
              if (marketingRows.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Marketing Digital',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColor.fromHex('#E91E63'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 1,
                  color: PdfColor.fromHex('#E91E63'),
                ),
                pw.SizedBox(height: 8),
                ...marketingRows.map(
                  (row) =>
                      buildTableRow(row, fontNormal, fontBold, darkGrey, blue),
                ),
              ],
              if (recurringRows.isNotEmpty && hasRecurring) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Costos Recurrentes',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: black,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 1,
                  color: blue,
                ),
                pw.SizedBox(height: 8),
                ...recurringRows.map(
                  (row) =>
                      buildTableRow(row, fontNormal, fontBold, darkGrey, blue),
                ),
              ],

              pw.SizedBox(height: 16),

              // ── 7. Totals section ────────────────────────────────────
              pw.Row(
                children: [
                  pw.Expanded(child: pw.SizedBox()),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Subtotal
                      pw.Row(
                        children: [
                          pw.Text(
                            'Subtotal',
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 10,
                              color: black,
                            ),
                          ),
                          pw.SizedBox(width: 24),
                          pw.Text(
                            '\$${project.totalEstimate.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 10,
                              color: black,
                            ),
                          ),
                        ],
                      ),

                      // IVA row
                      if (businessInfo.ivaPercent > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text(
                              'IVA ${businessInfo.ivaPercent.toStringAsFixed(0)}%',
                              style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 10,
                                color: blue,
                              ),
                            ),
                            pw.SizedBox(width: 24),
                            pw.Text(
                              '\$${ivaAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 10,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ],

                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 2.5,
                        width: 200,
                        color: blue,
                      ),
                      pw.SizedBox(height: 6),

                      // TOTAL
                      pw.Row(
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: blue,
                            ),
                          ),
                          pw.SizedBox(width: 24),
                          pw.Text(
                            '\$${(businessInfo.ivaPercent > 0 ? totalWithIva : project.totalEstimate).toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Expanded(child: pw.SizedBox()),

              // ── 8. Footer ────────────────────────────────────────────
              pw.Container(
                height: 0.75,
                color: PdfColor.fromHex('#CCCCCC'),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '${businessInfo.companyName} · Generado el $dateStr',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 9,
                    color: darkGrey,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Este documento es una estimación. Los precios finales pueden variar.',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 8,
                    color: darkGrey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

class _PdfTableRow {
  final String label;
  final String value;
  final bool isBold;
  final bool isSmall;
  final bool isSeparatorBefore;

  const _PdfTableRow({
    required this.label,
    required this.value,
    required this.isBold,
    required this.isSmall,
    this.isSeparatorBefore = false,
  });
}
