import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/journal_provider.dart';
import '../widgets/entry_card.dart';
import '../widgets/stat_card.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final recentEntries = provider.getRecentEntries(7);
        final streak = provider.currentStreak;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Başlık
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Merhaba 👋', style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 4),
                                Text('MoodJournal', style: theme.textTheme.headlineLarge),
                              ],
                            ),
                            // Streak badge
                            if (streak > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 4),
                                    Text('$streak gün', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bugün kayıt var mı?
                if (!provider.hasTodayEntry)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: GestureDetector(
                        onTap: () => _navigateToAddEntry(context),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bugün nasılsın?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Günlük kaydını ekle', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // İstatistik kartları
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: FutureBuilder<double>(
                      future: provider.getMonthlyAverage(),
                      builder: (context, snapshot) {
                        final avg = snapshot.data ?? 0.0;
                        return Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Bu Ay Ortalama',
                                value: avg > 0 ? avg.toStringAsFixed(1) : '-',
                                icon: Icons.trending_up_rounded,
                                color: avg > 0 ? AppTheme.getMoodColor(avg.round()) : AppTheme.primaryColor,
                                subtitle: avg > 0 ? AppTheme.getMoodLabel(avg.round()) : 'Veri yok',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Toplam Kayıt',
                                value: '${provider.allEntries.length}',
                                icon: Icons.edit_note_rounded,
                                color: AppTheme.secondaryColor,
                                subtitle: 'giriş yapıldı',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Son 7 gün başlığı
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Son 7 Gün', style: theme.textTheme.titleLarge),
                        Text('${recentEntries.length} kayıt', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),

                // Entry listesi
                if (recentEntries.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text('Henüz kayıt yok', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('İlk duygu kaydını ekleyerek başla!', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = recentEntries[index];
                          return EntryCard(
                            entry: entry,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry))),
                            onDelete: () => provider.deleteEntry(entry.id!),
                          );
                        },
                        childCount: recentEntries.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddEntry(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Kayıt'),
          ),
        );
      },
    );
  }

  void _navigateToAddEntry(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntryScreen()));
  }
}
