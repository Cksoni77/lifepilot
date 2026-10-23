import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({required this.message, this.onTap, super.key});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentPurpleTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentPurpleTint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.auto_awesome, color: AppColors.accentPurple),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI SUGGESTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accentPurple,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.accentPurple,
              tooltip: 'Open suggestion',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );

    return onTap == null
        ? card
        : Semantics(
            button: true,
            label: 'AI suggestion',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: card,
            ),
          );
  }
}
