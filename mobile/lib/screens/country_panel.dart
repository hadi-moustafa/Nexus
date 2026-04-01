import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';

class CountryPanel extends StatefulWidget {
  final String country;
  final bool isDark;
  final VoidCallback onClose;

  const CountryPanel({
    super.key,
    required this.country,
    required this.isDark,
    required this.onClose,
  });

  @override
  State<CountryPanel> createState() => _CountryPanelState();
}

class _CountryPanelState extends State<CountryPanel> {
  String _selectedPerspective = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '🌍',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.country,
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '24 stories today',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Perspective Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['All', 'Local', 'Global'].map((perspective) {
                      final isSelected = _selectedPerspective == perspective;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPerspective = perspective),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                perspective,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Articles List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final articles = [
                      {
                        'title': 'Regional Economic Summit Concludes with Historic Trade Deal',
                        'source': 'Local Daily',
                        'time': '1h ago',
                      },
                      {
                        'title': 'Infrastructure Investment Plan Receives Parliamentary Approval',
                        'source': 'National Press',
                        'time': '3h ago',
                      },
                      {
                        'title': 'Cultural Festival Draws Record International Attendance',
                        'source': 'Arts Weekly',
                        'time': '5h ago',
                      },
                      {
                        'title': 'Tech Startup Ecosystem Shows Strong Q3 Growth',
                        'source': 'Business Insider',
                        'time': '7h ago',
                      },
                      {
                        'title': 'Education Reform Bill Advances to Final Vote',
                        'source': 'Policy Journal',
                        'time': '9h ago',
                      },
                    ];

                    final article = articles[index];
                    return CompactArticleCard(
                      title: article['title']!,
                      source: article['source']!,
                      timeAgo: article['time']!,
                      isDark: widget.isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
