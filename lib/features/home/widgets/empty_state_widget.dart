import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/neu_box.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuBox(
              color: AppColors.blue.withAlpha(20),
              borderRadius: 24,
              padding: const EdgeInsets.all(32),
              child: Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin proyectos aun',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera cotizacion\nusando el boton +',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textColor.withAlpha(160),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.go('/quotation'),
              child: NeuBox(
                color: AppColors.blue,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Nueva Cotizacion',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
