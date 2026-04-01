import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AISummaryCard extends StatelessWidget {
  final String summary;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const AISummaryCard({
    super.key,
    required this.summary,
    required this.isDark,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusColors.teal.withOpacity(0.1),
            NexusColors.amber.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NexusColors.teal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NexusColors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: NexusColors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Summary',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NexusColors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEXUS AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NexusColors.teal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              height: 1.5,
            ),
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (onToggle != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onToggle,
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NexusColors.teal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: NexusColors.teal,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
