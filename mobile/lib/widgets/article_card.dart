import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArticleCard extends StatelessWidget {
  final String title;
  final String source;
  final String timeAgo;
  final String? imageUrl;
  final String category;
  final bool isBreaking;
  final bool isDark;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.title,
    required this.source,
    required this.timeAgo,
    this.imageUrl,
    required this.category,
    this.isBreaking = false,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 160,
                              color: colors.muted,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: NexusColors.teal,
                                  strokeWidth: 2,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: colors.muted,
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 36, color: colors.textSecondary),
                      ),
                    ),
                    // Category badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Badge(text: category, color: NexusColors.teal),
                    ),
                    if (isBreaking)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _Badge(
                          text: 'BREAKING',
                          color: Colors.red,
                          icon: Icons.bolt,
                        ),
                      ),
                  ],
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl == null || imageUrl!.isEmpty) ...[
                    _Badge(text: category, color: NexusColors.teal),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.newspaper,
                            size: 12, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          source,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timeAgo,
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary)),
                    ],
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

class CompactArticleCard extends StatelessWidget {
  final String title;
  final String source;
  final String timeAgo;
  final String? imageUrl;
  final bool isDark;
  final VoidCallback? onTap;

  const CompactArticleCard({
    super.key,
    required this.title,
    required this.source,
    required this.timeAgo,
    this.imageUrl,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(source,
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary)),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(timeAgo,
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ImagePlaceholder(colors: colors),
                    )
                  : _ImagePlaceholder(colors: colors),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final DynamicColors colors;
  const _ImagePlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: colors.muted,
        child: Icon(Icons.image_outlined, color: colors.textSecondary, size: 28),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _Badge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
