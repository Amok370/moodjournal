import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/journal_provider.dart';
import '../widgets/mood_chart.dart';
import '../widgets/trigger_bar_chart.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<JournalProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İstatistikler', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Duygusal sağlık analizlerin', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 20),

              // Zaman aralığı seçimi
              Row(
                children: [
                  _buildPeriodChip('7 Gün', 7),
                  const SizedBox(width: 8),
                  _buildPeriodChip('14 Gün', 14),
                  const SizedBox(width: 8),
                  _buildPeriodChip('30 Gün', 30),
                ],
              ),
              const SizedBox(height: 20),

              // Özet kartları
              FutureBuilder<double>(
                future: provider.getMonthlyAverage(),
                builder: (context, avgSnapshot) {
                  return FutureBuilder<int>(
                    future: provider.getTotalCount(),
                    builder: (context, countSnapshot) {
                      final avg = avgSnapshot.data ?? 0.0;
                      final count = countSnapshot.data ?? 0;
                      final streak = provider.currentStreak;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: StatCard(
                                title: 'Ortalama Skor',
                                value: avg > 0 ? avg.toStringAsFixed(1) : '-',
                                icon: Icons.analytics_rounded,
                                color: avg > 0 ? AppTheme.getMoodColor(avg.round()) : AppTheme.primaryColor,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: StatCard(
                                title: 'Seri',
                                value: '$streak gün',
                                icon: Icons.local_fire_department_rounded,
                                color: AppTheme.accentOrange,
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: StatCard(
                                title: 'Toplam Kayıt',
                                value: '$count',
                                icon: Icons.edit_note_rounded,
                                color: AppTheme.secondaryColor,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: StatCard(
                                title: 'Duygu',
                                value: avg > 0 ? AppTheme.getMoodEmoji(avg.round()) : '❓',
                                icon: Icons.mood_rounded,
                                color: AppTheme.accentPink,
                              )),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Duygu trend grafiği
              FutureBuilder<List<Map<String, dynamic>>>(
                future: provider.getDailyAverages(_selectedDays),
                builder: (context, snapshot) {
                  return MoodChart(
                    dailyData: snapshot.data ?? [],
                    title: 'Duygu Trendi ($_selectedDays Gün)',
                  );
                },
              ),
              const SizedBox(height: 20),

              // Tetikleyiciler
              FutureBuilder<List<Map<String, dynamic>>>(
                future: provider.getTopTriggers(limit: 5),
                builder: (context, snapshot) {
                  return TriggerBarChart(triggers: snapshot.data ?? []);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
