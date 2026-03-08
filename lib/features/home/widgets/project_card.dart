import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/project.dart';
import '../../../shared/widgets/neu_box.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
    this.onStatusChange,
  });

  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<ProjectStatus>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final cardBg = isDark ? AppColors.grey800 : AppColors.white;
    final statusColor = Color(project.status.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeuBox(
        color: cardBg,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.white : AppColors.black,
                      width: 2,
                    ),
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
                // Options menu
                _OptionsMenu(
                  project: project,
                  onDelete: onDelete,
                  onStatusChange: onStatusChange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: project.iconCode != null
                        ? AppColors.blue.withAlpha(20)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.white : AppColors.black,
                      width: 2,
                    ),
                  ),
                  child: project.iconCode != null
                      ? Icon(
                          IconData(project.iconCode!,
                              fontFamily: 'MaterialIcons'),
                          size: 36,
                          color: AppColors.blue,
                        )
                      : Icon(
                          Icons.folder_outlined,
                          size: 36,
                          color: isDark ? AppColors.white : AppColors.grey800,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        label: 'Cliente',
                        value: project.clientName,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 2),
                      _InfoRow(
                        label: 'Estimado',
                        value: '\$${project.totalEstimate.toStringAsFixed(2)}',
                        textColor: textColor,
                        valueColor: AppColors.blue,
                      ),
                      if (project.multiplierUsed != 1.0) ...[
                        const SizedBox(height: 2),
                        _InfoRow(
                          label: 'Factor',
                          value: 'x${project.multiplierUsed.toStringAsFixed(1)}',
                          textColor: textColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: textColor),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  const _OptionsMenu({
    required this.project,
    this.onDelete,
    this.onStatusChange,
  });

  final Project project;
  final VoidCallback? onDelete;
  final ValueChanged<ProjectStatus>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white
              : AppColors.black,
          width: 2,
        ),
      ),
      onSelected: (value) {
        if (value == 'delete') {
          onDelete?.call();
        } else {
          final status = ProjectStatus.values.firstWhere((s) => s.name == value);
          onStatusChange?.call(status);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'inProgress', child: Text('En Progreso')),
        const PopupMenuItem(value: 'completed', child: Text('Completado')),
        const PopupMenuItem(value: 'cancelled', child: Text('Cancelado')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
