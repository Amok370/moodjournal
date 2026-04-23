import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/coping_provider.dart';
import '../widgets/mood_slider.dart';
import '../widgets/coping_tile.dart';

class EditEntryScreen extends StatefulWidget {
  final JournalEntry entry;
  const EditEntryScreen({super.key, required this.entry});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late int _moodScore;
  late TextEditingController _triggerController;
  late TextEditingController _notesController;
  String? _selectedCoping;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _moodScore = widget.entry.moodScore;
    _triggerController = TextEditingController(text: widget.entry.trigger);
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _selectedCoping = widget.entry.copingStrategy;
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateEntry() async {
    if (_triggerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Lütfen tetikleyici olayı yazın'), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.entry.copyWith(
        moodScore: _moodScore,
        trigger: _triggerController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        copingStrategy: _selectedCoping,
      );
      await context.read<JournalProvider>().updateEntry(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✅ Kayıt güncellendi!'), backgroundColor: AppTheme.accentGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydı Düzenle'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duygu Durumu', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  MoodSlider(initialValue: _moodScore, onChanged: (val) => setState(() => _moodScore = val)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Tetikleyici Olay *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: _triggerController, decoration: const InputDecoration(hintText: 'Tetikleyici olay', prefixIcon: Icon(Icons.flash_on_rounded, color: AppTheme.accentOrange)), maxLines: 2),
            const SizedBox(height: 20),
            Text('Notlar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: _notesController, decoration: const InputDecoration(hintText: 'Ek düşünceler...', prefixIcon: Icon(Icons.note_rounded, color: AppTheme.primaryColor)), maxLines: 3),
            const SizedBox(height: 20),
            Text('Strateji', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Consumer<CopingProvider>(
              builder: (context, copingProvider, _) {
                return Column(
                  children: copingProvider.strategies.map((strategy) {
                    return CopingTile(
                      strategy: strategy,
                      isSelected: _selectedCoping == strategy.name,
                      onTap: () => setState(() => _selectedCoping = _selectedCoping == strategy.name ? null : strategy.name),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateEntry,
                child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Güncelle'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
