import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import 'edit_entry_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final JournalEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late JournalEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final moodColor = AppTheme.getMoodColor(_entry.moodScore);
    final moodEmoji = AppTheme.getMoodEmoji(_entry.moodScore);
    final moodLabel = AppTheme.getMoodLabel(_entry.moodScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push<JournalEntry>(context, MaterialPageRoute(builder: (_) => EditEntryScreen(entry: _entry)));
              if (result != null) setState(() => _entry = result);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Kaydı Sil'),
                  content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil')),
                  ],
                ),
              );
              if (confirmed == true) {
                if (!context.mounted) return;
                await context.read<JournalProvider>().deleteEntry(_entry.id!);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mood kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [moodColor.withValues(alpha: 0.15), moodColor.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: moodColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(moodEmoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 8),
                  Text('${_entry.moodScore}/10', style: theme.textTheme.headlineLarge?.copyWith(color: moodColor, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(moodLabel, style: theme.textTheme.titleMedium?.copyWith(color: moodColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarih ve saat
            _buildInfoCard(context, Icons.calendar_today_rounded, 'Tarih', _entry.formattedDate, AppTheme.primaryColor),
            const SizedBox(height: 10),
            _buildInfoCard(context, Icons.access_time_rounded, 'Saat', _entry.formattedTime, AppTheme.secondaryColor),
            const SizedBox(height: 10),
            _buildInfoCard(context, Icons.flash_on_rounded, 'Tetikleyici', _entry.trigger, AppTheme.accentOrange),

            if (_entry.notes != null && _entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(context, Icons.note_rounded, 'Notlar', _entry.notes!, AppTheme.primaryColor),
            ],

            if (_entry.copingStrategy != null && _entry.copingStrategy!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(context, Icons.spa_rounded, 'Kullanılan Strateji', _entry.copingStrategy!, AppTheme.accentGreen),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
