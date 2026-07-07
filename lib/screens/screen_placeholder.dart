import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Branded standalone placeholder used by the scaffold until each screen's
/// dedicated task fills in its real UI. Renders on the fixed dark background
/// so `/screen/<id>` and deep links show something coherent immediately.
class ScreenPlaceholder extends StatelessWidget {
  const ScreenPlaceholder({
    super.key,
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SILLY SMILES',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'screen $id',
              style: const TextStyle(
                color: AppColors.surfaceMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
