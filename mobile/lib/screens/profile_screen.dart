import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final bool isDark;

  const ProfileScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: colors.background,
            elevation: 0,
            title: Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),

          // Profile Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: NexusColors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NexusColors.teal,
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'JD',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: NexusColors.teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'John Doe',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@johndoe',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Premium Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NexusColors.teal, NexusColors.amber],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Premium Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Articles Read',
                      value: '248',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.border,
                    ),
                    _StatItem(
                      label: 'Quiz Score',
                      value: '1,240',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.border,
                    ),
                    _StatItem(
                      label: 'Day Streak',
                      value: '15',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Badges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _BadgeItem(
                          icon: Icons.local_fire_department,
                          label: 'Hot Streak',
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                        _BadgeItem(
                          icon: Icons.quiz,
                          label: 'Quiz Master',
                          color: NexusColors.teal,
                          isDark: isDark,
                        ),
                        _BadgeItem(
                          icon: Icons.auto_stories,
                          label: 'Bookworm',
                          color: NexusColors.amber,
                          isDark: isDark,
                        ),
                        _BadgeItem(
                          icon: Icons.public,
                          label: 'World Explorer',
                          color: Colors.blue,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Saved Articles Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Articles',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: NexusColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Saved Articles List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final articles = [
                    {
                      'title': 'The Future of Renewable Energy',
                      'source': 'Scientific American',
                      'saved': '2 days ago',
                    },
                    {
                      'title': 'Global Economic Outlook 2024',
                      'source': 'The Economist',
                      'saved': '5 days ago',
                    },
                    {
                      'title': 'Advances in Quantum Computing',
                      'source': 'Nature',
                      'saved': '1 week ago',
                    },
                  ];

                  if (index >= articles.length) return null;
                  final article = articles[index];

                  return _SavedArticleItem(
                    title: article['title']!,
                    source: article['source']!,
                    saved: article['saved']!,
                    isDark: isDark,
                  );
                },
                childCount: 3,
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: NexusColors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedArticleItem extends StatelessWidget {
  final String title;
  final String source;
  final String saved;
  final bool isDark;

  const _SavedArticleItem({
    required this.title,
    required this.source,
    required this.saved,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.article,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        source,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saved $saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.bookmark,
            color: NexusColors.amber,
          ),
        ],
      ),
    );
  }
}
