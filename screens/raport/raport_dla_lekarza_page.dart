import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import '../../services/raport_service.dart';

class RaportDlaLekarzaPage extends StatefulWidget {
  const RaportDlaLekarzaPage({super.key});

  @override
  State<RaportDlaLekarzaPage> createState() => _RaportDlaLekarzaPageState();
}

class _RaportDlaLekarzaPageState extends State<RaportDlaLekarzaPage> {
  final _supabase = Supabase.instance.client;
  final RaportService _raportService = RaportService();

  bool _generowanie = false;

  Future<void> _generujRaport() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak zalogowanego użytkownika ❌')),
      );
      return;
    }

    try {
      setState(() => _generowanie = true);
      final raport = await _raportService.stworzRaport(userId);

      await Printing.layoutPdf(
        onLayout: (format) async => raport.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raport został wygenerowany ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd generowania raportu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generowanie = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6FDFF),
      appBar: AppBar(
        title: const Text('Raport dla lekarza 📄'),
        backgroundColor: const Color(0xFFA5668B),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Wygeneruj raport w formacie PDF zawierający:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.medication, color: Color(0xFFA5668B)),
              title: Text('Aktualne leki'),
            ),
            const ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Ostatnie działania niepożądane'),
            ),
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Historia przyjmowania leków'),
            ),
            const Spacer(),
            _generowanie
                ? const CircularProgressIndicator(color: Color(0xFFA5668B))
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5668B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Wygeneruj PDF',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: _generujRaport,
            ),
          ],
        ),
      ),
    );
  }
}
