import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/journal_provider.dart';
import '../widgets/entry_card.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final entries = provider.entries;

        // Tarihe göre grupla
        final Map<String, List<dynamic>> grouped = {};
        for (final entry in entries) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);

          String label;
          if (entryDate == today) {
            label = 'Bugün';
          } else if (entryDate == yesterday) {
            label = 'Dün';
          } else if (now.difference(entryDate).inDays < 7) {
            label = 'Bu Hafta';
          } else if (entry.date.month == now.month && entry.date.year == now.year) {
            label = 'Bu Ay';
          } else {
            label = entry.formattedDate;
          }

          grouped.putIfAbsent(label, () => []);
          grouped[label]!.add(entry);
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve Arama
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isSearching)
                        Text('Geçmiş', style: theme.textTheme.headlineLarge),
                      if (_isSearching)
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Ara... (tetikleyici, not)',
                              border: InputBorder.none,
                              hintStyle: theme.textTheme.bodyLarge,
                            ),
                            onChanged: (q) => provider.search(q),
                          ),
                        ),
                      IconButton(
                        icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
                        onPressed: () {
                          setState(() => _isSearching = !_isSearching);
                          if (!_isSearching) {
                            _searchController.clear();
                            provider.clearSearch();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('${entries.length} kayıt', style: theme.textTheme.bodySmall),
                ),
                const SizedBox(height: 12),

                // Liste
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: 16),
                              Text(_isSearching ? 'Sonuç bulunamadı' : 'Henüz kayıt yok', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, sectionIndex) {
                            final label = grouped.keys.elementAt(sectionIndex);
                            final sectionEntries = grouped[label]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                                ),
                                ...sectionEntries.map((entry) => EntryCard(
                                      entry: entry,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry))),
                                      onDelete: () => provider.deleteEntry(entry.id!),
                                    )),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
