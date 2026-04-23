
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/journal_entry.dart';
import '../app_theme.dart';

class PdfService {
  /// PDF rapor oluştur ve paylaş
  Future<void> generateAndShareReport({
    required List<JournalEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
    required double averageMood,
    required List<Map<String, dynamic>> topTriggers,
  }) async {
    final pdf = await _buildPdf(
      entries: entries,
      startDate: startDate,
      endDate: endDate,
      averageMood: averageMood,
      topTriggers: topTriggers,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'MoodJournal_Rapor_${_formatDateShort(startDate)}_${_formatDateShort(endDate)}.pdf',
    );
  }

  /// PDF oluştur (yazdırma için)
  Future<void> printReport({
    required List<JournalEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
    required double averageMood,
    required List<Map<String, dynamic>> topTriggers,
  }) async {
    final pdf = await _buildPdf(
      entries: entries,
      startDate: startDate,
      endDate: endDate,
      averageMood: averageMood,
      topTriggers: topTriggers,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// PDF dokümanını oluştur
  Future<pw.Document> _buildPdf({
    required List<JournalEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
    required double averageMood,
    required List<Map<String, dynamic>> topTriggers,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      ),
    );

    final primaryColor = PdfColor.fromHex('#7C83FD');
    final darkColor = PdfColor.fromHex('#1A1A2E');
    final lightGrey = PdfColor.fromHex('#F5F5F5');

    // ─── Kapak Sayfası ───
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Başlık
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MoodJournal',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Duygusal Sağlık Raporu',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.white.shade(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Tarih Aralığı
              _buildInfoRow('Tarih Aralığı',
                  '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
              pw.SizedBox(height: 10),
              _buildInfoRow('Toplam Kayıt', '${entries.length} giriş'),
              pw.SizedBox(height: 10),
              _buildInfoRow('Ortalama Duygu Skoru',
                  '${averageMood.toStringAsFixed(1)} / 10'),
              pw.SizedBox(height: 10),
              _buildInfoRow('Rapor Tarihi', _formatDate(DateTime.now())),

              pw.SizedBox(height: 40),

              // Özet Kutusu
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'İstatistiksel Özet',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'Ortalama Duygu Skoru: ${averageMood.toStringAsFixed(1)}/10 '
                      '(${AppTheme.getMoodLabel(averageMood.round())})',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'En Yüksek Skor: ${entries.isNotEmpty ? entries.map((e) => e.moodScore).reduce((a, b) => a > b ? a : b) : "N/A"}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'En Düşük Skor: ${entries.isNotEmpty ? entries.map((e) => e.moodScore).reduce((a, b) => a < b ? a : b) : "N/A"}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // En Sık Tetikleyiciler
              if (topTriggers.isNotEmpty) ...[
                pw.Text(
                  'En Sık Tetikleyiciler',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...topTriggers.map((t) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text(
                              '${t['trigger']} (${t['count']} kez)',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );

    // ─── Detay Sayfaları (Entry'ler) ───
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Her sayfaya 6 entry sığdır
    for (int i = 0; i < sortedEntries.length; i += 6) {
      final pageEntries = sortedEntries.skip(i).take(6).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Günlük Kayıtları',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Sayfa ${(i ~/ 6) + 2}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
                pw.SizedBox(height: 15),
                ...pageEntries.map((entry) => _buildEntryBlock(entry, primaryColor)),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildEntryBlock(JournalEntry entry, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${entry.formattedDate} - ${entry.formattedTime}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  'Duygu: ${entry.moodScore}/10',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tetikleyici: ${entry.trigger}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Not: ${entry.notes}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
          if (entry.copingStrategy != null && entry.copingStrategy!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Strateji: ${entry.copingStrategy}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.green800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 160,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}_${date.month.toString().padLeft(2, '0')}_${date.year}';
  }
}
