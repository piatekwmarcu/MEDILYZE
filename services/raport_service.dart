import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class RaportService {
  final _supabase = Supabase.instance.client;

  Future<pw.Document> stworzRaport(String userId) async {
    final pdf = pw.Document();

    final kolorAkcentu = PdfColors.purple600;

    // Pobierz leki
    final leki = await _supabase
        .from('user_leki')
        .select('nazwa, dawkowanie, data_start, data_koniec')
        .eq('user_id', userId);

    // Pobierz objawy
    final objawy = await _supabase
        .from('objawy')
        .select()
        .eq('user_id', userId)
        .order('data', ascending: false)
        .limit(5);

    // Pobierz adherencję (jeśli istnieje tabela)
    List adherencja = [];
    try {
      adherencja = await _supabase
          .from('przyjmowanie_lekow') // zmień nazwę jeśli w DB jest inna!
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false)
          .limit(10);
    } catch (e) {
      // fallback, jeśli tabela nie istnieje
      adherencja = [];
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "Raport zdrowotny pacjenta",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: kolorAkcentu,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Sekcja: Aktualne leki
          pw.Text("Aktualne leki", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          (leki as List).isEmpty
              ? pw.Text("Brak zapisanych leków")
              : pw.TableHelper.fromTextArray(
            headers: ["Nazwa", "Dawkowanie", "Data start", "Data koniec"],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: kolorAkcentu),
            data: leki.map((l) => [
              l['nazwa'] ?? '-',
              l['dawkowanie'] ?? '-',
              (l['data_start'] ?? '').toString().split('T')[0],
              (l['data_koniec'] ?? '').toString().split('T')[0],
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          // Sekcja: Ostatnie działania niepożądane
          pw.Text("Ostatnie działania niepożądane", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          (objawy as List).isEmpty
              ? pw.Text("Brak zgłoszonych objawów")
              : pw.TableHelper.fromTextArray(
            headers: ["Data", "Samopoczucie", "Notatka"],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: kolorAkcentu),
            data: objawy.map((o) => [
              (o['data'] ?? '').toString().split('T')[0],
              o['samopoczucie'] ?? '-',
              o['notatka'] ?? '-',
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          // Sekcja: Historia adherencji
          pw.Text("Historia przyjmowania leków", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          adherencja.isEmpty
              ? pw.Text("Brak danych")
              : pw.TableHelper.fromTextArray(
            headers: ["Data", "Lek", "Status"],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: kolorAkcentu),
            data: adherencja.map((a) => [
              (a['data'] ?? '').toString().split('T')[0],
              a['lek'] ?? '-',
              a['status'] ?? 'brak',
            ]).toList(),
          ),
        ],
        footer: (context) => pw.Center(
          child: pw.Text(
            "Wygenerowano automatycznie w aplikacji MediLyze",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
      ),
    );

    return pdf;
  }
}
