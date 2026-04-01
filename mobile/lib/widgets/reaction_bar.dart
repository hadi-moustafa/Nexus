import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReactionBar extends StatelessWidget {
  final bool isDark;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const ReactionBar({
    super.key,
    required this.isDark,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _ReactionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: likes.toString(),
                isActive: isLiked,
                activeColor: Colors.red,
                colors: colors,
                onTap: onLike,
              ),
              const SizedBox(width: 20),
              _ReactionButton(
                icon: Icons.chat_bubble_outline,
                label: comments.toString(),
                colors: colors,
                onTap: onComment,
              ),
              const SizedBox(width: 20),
              _ReactionButton(
                icon: Icons.share_outlined,
                label: shares.toString(),
                colors: colors,
                onTap: onShare,
              ),
            ],
          ),
          GestureDetector(
            onTap: onBookmark,
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? NexusColors.amber : colors.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final DynamicColors colors;
  final VoidCallback? onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive 
        ? (activeColor ?? NexusColors.teal) 
        : colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
