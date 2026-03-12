import 'dart:convert';
import 'marketing_config.dart';
import 'quotation_config.dart';

enum ProjectStatus { pending, inProgress, completed, cancelled }

extension ProjectStatusExt on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.pending:
        return 'Pendiente';
      case ProjectStatus.inProgress:
        return 'En Progreso';
      case ProjectStatus.completed:
        return 'Completado';
      case ProjectStatus.cancelled:
        return 'Cancelado';
    }
  }

  int get colorValue {
    switch (this) {
      case ProjectStatus.pending:
        return 0xFFFFD700;
      case ProjectStatus.inProgress:
        return 0xFF1B9CFC;
      case ProjectStatus.completed:
        return 0xFF4CAF50;
      case ProjectStatus.cancelled:
        return 0xFFF44336;
    }
  }
}

class Project {
  final int? id;
  final String name;
  final String clientName;
  final String? description;
  final double totalEstimate;
  final double multiplierUsed;
  final ProjectStatus status;
  final DateTime createdAt;
  final List<ProjectLine> lines;
  final String? configJson;
  final String? marketingConfigJson;
  final int? iconCode;

  const Project({
    this.id,
    required this.name,
    required this.clientName,
    this.description,
    required this.totalEstimate,
    this.multiplierUsed = 1.0,
    this.status = ProjectStatus.pending,
    required this.createdAt,
    this.lines = const [],
    this.configJson,
    this.marketingConfigJson,
    this.iconCode,
  });

  QuotationConfig? get quotationConfig {
    if (configJson == null) return null;
    try {
      return QuotationConfig.fromJson(
          json.decode(configJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  MarketingConfig? get marketingConfig {
    if (marketingConfigJson == null) return null;
    try {
      return MarketingConfig.fromJson(
          json.decode(marketingConfigJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Project copyWith({
    int? id,
    String? name,
    String? clientName,
    String? description,
    double? totalEstimate,
    double? multiplierUsed,
    ProjectStatus? status,
    DateTime? createdAt,
    List<ProjectLine>? lines,
    String? configJson,
    String? marketingConfigJson,
    int? iconCode,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      multiplierUsed: multiplierUsed ?? this.multiplierUsed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lines: lines ?? this.lines,
      configJson: configJson ?? this.configJson,
      marketingConfigJson: marketingConfigJson ?? this.marketingConfigJson,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'clientName': clientName,
      'description': description,
      'totalEstimate': totalEstimate,
      'multiplierUsed': multiplierUsed,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'configJson': configJson,
      'marketingConfigJson': marketingConfigJson,
      'iconCode': iconCode,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      name: map['name'] as String,
      clientName: map['clientName'] as String,
      description: map['description'] as String?,
      totalEstimate: (map['totalEstimate'] as num).toDouble(),
      multiplierUsed: (map['multiplierUsed'] as num? ?? 1.0).toDouble(),
      status: ProjectStatus.values[map['status'] as int? ?? 0],
      createdAt: DateTime.parse(map['createdAt'] as String),
      lines: const [],
      configJson: map['configJson'] as String?,
      marketingConfigJson: map['marketingConfigJson'] as String?,
      iconCode: map['iconCode'] as int?,
    );
  }
}

class ProjectLine {
  final int? id;
  final int projectId;
  final int serviceId;
  final String serviceName;
  final String categoryName;
  final double quantity;
  final double unitPrice;
  final String unit;

  const ProjectLine({
    this.id,
    required this.projectId,
    required this.serviceId,
    required this.serviceName,
    required this.categoryName,
    required this.quantity,
    required this.unitPrice,
    this.unit = 'hora',
  });

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'categoryName': categoryName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit,
    };
  }

  factory ProjectLine.fromMap(Map<String, dynamic> map) {
    return ProjectLine(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      serviceId: map['serviceId'] as int,
      serviceName: map['serviceName'] as String,
      categoryName: map['categoryName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'hora',
    );
  }
}
