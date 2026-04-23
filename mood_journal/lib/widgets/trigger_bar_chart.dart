import 'package:flutter/material.dart';

import '../app_theme.dart';

class TriggerBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> triggers;

  const TriggerBarChart({super.key, required this.triggers});

  static const List<Color> _barColors = [
    AppTheme.primaryColor, AppTheme.secondaryColor,
    AppTheme.accentPink, AppTheme.accentOrange, AppTheme.accentGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (triggers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Henüz tetikleyici verisi yok', style: theme.textTheme.titleMedium),
          ]),
        ),
      );
    }

    final maxCount = triggers.map((t) => t['count'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En Sık Tetikleyiciler', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          ...triggers.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final trigger = data['trigger'] as String;
            final count = data['count'] as int;
            final color = _barColors[index % _barColors.length];
            final ratio = count / maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(trigger, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('$count kez', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio),
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft, widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
