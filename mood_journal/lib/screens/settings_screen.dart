import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../main.dart';
import '../providers/journal_provider.dart';
import '../services/pdf_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isGeneratingPdf = false;

  // PDF tarih aralığı
  DateTime _pdfStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _pdfEndDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ayarlar', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 24),

              // ─── Tema ───
              _buildSectionTitle(context, '🎨 Görünüm'),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildThemeOption(context, 'Sistem', ThemeMode.system, Icons.phone_android_rounded),
                    const Divider(height: 1),
                    _buildThemeOption(context, 'Açık Tema', ThemeMode.light, Icons.light_mode_rounded),
                    const Divider(height: 1),
                    _buildThemeOption(context, 'Koyu Tema', ThemeMode.dark, Icons.dark_mode_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Hatırlatıcı ───
              _buildSectionTitle(context, '🔔 Hatırlatıcılar'),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Günlük Hatırlatıcı'),
                      subtitle: Text('Her gün ${_reminderTime.format(context)}'),
                      value: _remindersEnabled,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5), activeThumbColor: AppTheme.primaryColor,
                      onChanged: (val) async {
                        setState(() => _remindersEnabled = val);
                        if (val) {
                          await NotificationService().requestPermission();
                          await NotificationService().scheduleDailyReminder(hour: _reminderTime.hour, minute: _reminderTime.minute);
                          if (!context.mounted) return;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('✅ Hatırlatıcı ayarlandı!'), backgroundColor: AppTheme.accentGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            );
                          }
                        } else {
                          await NotificationService().cancelAllReminders();
                        }
                      },
                    ),
                    if (_remindersEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Hatırlatıcı Saati'),
                        trailing: Text(_reminderTime.format(context), style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: _reminderTime);
                          if (time != null) {
                            setState(() => _reminderTime = time);
                            await NotificationService().scheduleDailyReminder(hour: time.hour, minute: time.minute);
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Test Bildirimi'),
                        trailing: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                        onTap: () => NotificationService().showTestNotification(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── PDF Rapor ───
              _buildSectionTitle(context, '📄 PDF Rapor'),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Başlangıç Tarihi'),
                      trailing: Text('${_pdfStartDate.day}/${_pdfStartDate.month}/${_pdfStartDate.year}', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _pdfStartDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (date != null) setState(() => _pdfStartDate = date);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Bitiş Tarihi'),
                      trailing: Text('${_pdfEndDate.day}/${_pdfEndDate.month}/${_pdfEndDate.year}', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _pdfEndDate, firstDate: _pdfStartDate, lastDate: DateTime.now());
                        if (date != null) setState(() => _pdfEndDate = date);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingPdf ? null : _generatePdf,
                          icon: _isGeneratingPdf ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_rounded),
                          label: Text(_isGeneratingPdf ? 'Oluşturuluyor...' : 'Rapor Oluştur'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Hakkında ───
              _buildSectionTitle(context, 'ℹ️ Hakkında'),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Column(
                  children: [
                    const ListTile(title: Text('Uygulama'), trailing: Text('MoodJournal v1.0.0')),
                    const Divider(height: 1),
                    const ListTile(title: Text('Açıklama'), subtitle: Text('Psikiyatrik rahatsızlıkları olan bireyler için duygusal sağlık takip uygulaması.')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Çıkış ───
              _buildSectionTitle(context, '🚪 Hesap'),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  subtitle: Text(AuthService().currentUser?.email ?? ''),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await AuthService().signOut();
                    }
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final provider = context.read<JournalProvider>();
      final entries = await provider.getEntriesByDateRange(_pdfStartDate, _pdfEndDate);
      final topTriggers = await provider.getTopTriggers(limit: 5);

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Bu tarih aralığında kayıt bulunamadı'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          );
        }
        return;
      }

      final avgMood = entries.map((e) => e.moodScore).reduce((a, b) => a + b) / entries.length;

      await PdfService().generateAndShareReport(entries: entries, startDate: _pdfStartDate, endDate: _pdfEndDate, averageMood: avgMood, topTriggers: topTriggers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, ThemeMode mode, IconData icon) {
    final currentMode = MoodJournalApp.themeNotifier.value;
    final isSelected = currentMode == mode;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : null),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
      onTap: () {
        MoodJournalApp.themeNotifier.value = mode;
        setState(() {});
      },
    );
  }
}
