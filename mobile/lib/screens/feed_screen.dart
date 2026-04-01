import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../widgets/category_chip.dart';

class FeedScreen extends StatefulWidget {
  final bool isDark;

  const FeedScreen({super.key, required this.isDark});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCategory = 'For You';

  final List<String> _categories = [
    'For You',
    'World',
    'Technology',
    'Business',
    'Science',
    'Health',
    'Sports',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

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
              'Your Feed',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: colors.textPrimary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.tune, color: colors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CategoryChipList(
                categories: _categories,
                selectedCategory: _selectedCategory,
                isDark: widget.isDark,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),
          ),

          // Lebanese Spotlight Section
          SliverToBoxAdapter(
            child: _SpotlightSection(isDark: widget.isDark),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Stories',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Articles List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final articles = [
                    {
                      'title': 'Artificial Intelligence Reshapes Healthcare Diagnostics',
                      'source': 'MIT Technology Review',
                      'time': '15m ago',
                      'category': 'Technology',
                    },
                    {
                      'title': 'Sustainable Energy Investments Hit Record High in Q3',
                      'source': 'Bloomberg',
                      'time': '1h ago',
                      'category': 'Business',
                    },
                    {
                      'title': 'New Archaeological Discovery Rewrites Ancient History',
                      'source': 'National Geographic',
                      'time': '2h ago',
                      'category': 'Science',
                    },
                    {
                      'title': 'Global Education Summit Addresses Digital Divide',
                      'source': 'The Guardian',
                      'time': '3h ago',
                      'category': 'World',
                    },
                    {
                      'title': 'Mental Health Apps See Surge in Adoption',
                      'source': 'Health Today',
                      'time': '4h ago',
                      'category': 'Health',
                    },
                  ];

                  if (index >= articles.length) return null;
                  final article = articles[index];

                  return ArticleCard(
                    title: article['title'] as String,
                    source: article['source'] as String,
                    timeAgo: article['time'] as String,
                    category: article['category'] as String,
                    isDark: widget.isDark,
                    imageUrl: 'placeholder',
                  );
                },
                childCount: 5,
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

class _SpotlightSection extends StatelessWidget {
  final bool isDark;

  const _SpotlightSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusColors.amber.withOpacity(0.15),
            NexusColors.teal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NexusColors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NexusColors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lebanese Spotlight',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? NexusColors.darkBg : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Beirut Tech Week Showcases Regional Innovation',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Annual technology conference brings together startups, investors, and industry leaders from across the MENA region.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'L\'Orient Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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
              Text(
                '30 min ago',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
