import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/coping_provider.dart';
import '../widgets/mood_slider.dart';
import '../widgets/coping_tile.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  int _moodScore = 5;
  final _triggerController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCoping;
  bool _isSaving = false;

  @override
  void dispose() {
    _triggerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_triggerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen tetikleyici olayı yazın'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = JournalEntry(
        date: DateTime.now(),
        moodScore: _moodScore,
        trigger: _triggerController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        copingStrategy: _selectedCoping,
      );

      await context.read<JournalProvider>().addEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Text('✅ '),
              const Text('Kayıt başarıyla eklendi!'),
            ]),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('Yeni Kayıt'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Slider
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nasıl hissediyorsun?', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  MoodSlider(initialValue: _moodScore, onChanged: (val) => setState(() => _moodScore = val)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tetikleyici
            Text('Tetikleyici Olay *', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _triggerController,
              decoration: const InputDecoration(
                hintText: 'Örn: İş toplantısında kalabalık vardı',
                prefixIcon: Icon(Icons.flash_on_rounded, color: AppTheme.accentOrange),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // Notlar
            Text('Notlar (opsiyonel)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Ek düşünceler, detaylar...',
                prefixIcon: Icon(Icons.note_rounded, color: AppTheme.primaryColor),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // Coping Stratejisi
            Text('Kullandığın Strateji', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Bir başa çıkma yöntemi seçin', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),

            Consumer<CopingProvider>(
              builder: (context, copingProvider, _) {
                return Column(
                  children: copingProvider.strategies.map((strategy) {
                    return CopingTile(
                      strategy: strategy,
                      isSelected: _selectedCoping == strategy.name,
                      onTap: () {
                        setState(() {
                          _selectedCoping = _selectedCoping == strategy.name ? null : strategy.name;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Kaydet'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
