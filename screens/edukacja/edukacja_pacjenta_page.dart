import 'package:flutter/material.dart';
import '../../services/edukacja_service.dart';

class EdukacjaPacjentaPage extends StatefulWidget {
  const EdukacjaPacjentaPage({super.key});

  @override
  State<EdukacjaPacjentaPage> createState() => _EdukacjaPacjentaPageState();
}

class _EdukacjaPacjentaPageState extends State<EdukacjaPacjentaPage> {
  final EdukacjaService _service = EdukacjaService();
  List<Map<String, dynamic>> artykuly = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _zaladujArtykuly();
  }

  Future<void> _zaladujArtykuly() async {
    final lista = await _service.pobierzArtykuly();
    setState(() {
      artykuly = lista;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edukacja pacjenta 📚"),
        backgroundColor: const Color(0xFFA5668B),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: artykuly.length,
        itemBuilder: (context, index) {
          final art = artykuly[index];
          return Card(
            margin: const EdgeInsets.all(12),
            color: const Color(0xFFA5668B),
            child: ListTile(
              title: Text(
                art['tytul'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                art['opis'],
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SzczegolyArtykuluPage(
                      artykulId: art['id'],
                      tytul: art['tytul'],
                      tresc: art['tresc'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SzczegolyArtykuluPage extends StatefulWidget {
  final String artykulId;
  final String tytul;
  final String tresc;

  const SzczegolyArtykuluPage({
    super.key,
    required this.artykulId,
    required this.tytul,
    required this.tresc,
  });

  @override
  State<SzczegolyArtykuluPage> createState() => _SzczegolyArtykuluPageState();
}

class _SzczegolyArtykuluPageState extends State<SzczegolyArtykuluPage> {
  final EdukacjaService _service = EdukacjaService();
  List<Map<String, dynamic>> quiz = [];
  bool loading = true;
  int currentQuestion = 0;
  int correctAnswers = 0;
  bool quizFinished = false;

  @override
  void initState() {
    super.initState();
    _zaladujQuiz();
  }

  Future<void> _zaladujQuiz() async {
    final lista = await _service.pobierzQuizy(widget.artykulId);
    setState(() {
      quiz = lista;
      loading = false;
    });
  }

  void _odpowiedzNaPytanie(int index) {
    final poprawna = quiz[currentQuestion]['poprawna'] as int;
    final wyjasnienie = quiz[currentQuestion]['wyjasnienie'] ?? "";

    if (index == poprawna) {
      correctAnswers++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Poprawna odpowiedź!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Błędna odpowiedź. $wyjasnienie")),
      );
    }

    setState(() {
      if (currentQuestion < quiz.length - 1) {
        currentQuestion++;
      } else {
        quizFinished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tytul),
        backgroundColor: const Color(0xFFA5668B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.tresc, style: const TextStyle(fontSize: 16)),
            const Divider(),
            loading
                ? const CircularProgressIndicator()
                : quiz.isEmpty
                ? const Text("Brak quizu dla tego artykułu")
                : quizFinished
                ? Text("Twój wynik: $correctAnswers / ${quiz.length}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz[currentQuestion]['pytanie'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...(quiz[currentQuestion]['odpowiedzi'] as List<dynamic>)
                    .asMap()
                    .entries
                    .map((entry) {
                  final idx = entry.key;
                  final odp = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA5668B),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _odpowiedzNaPytanie(idx),
                      child: Text(odp),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
