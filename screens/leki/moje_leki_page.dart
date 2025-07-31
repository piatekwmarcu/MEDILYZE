import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/leki_service.dart';
import '../../models/lek_model.dart';

class MojeLekiPage extends StatefulWidget {
  const MojeLekiPage({super.key});

  @override
  State<MojeLekiPage> createState() => _MojeLekiPageState();
}

class _MojeLekiPageState extends State<MojeLekiPage> {
  final LekService _lekService = LekService();
  final supabase = Supabase.instance.client;

  List<Lek> _leki = [];
  List<Lek> _filtrowaneLeki = [];
  String _filter = "wszystkie";
  DateTime _dzisiaj = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sprawdzResetDnia();
  }

  Future<void> _sprawdzResetDnia() async {
    final box = await Hive.openBox('ustawienia');
    final dzis = DateTime.now().toIso8601String().substring(0, 10);
    final ostatniaData = box.get('ostatniaData') as String?;

    if (ostatniaData != dzis) {
      await _resetujPrzyjecia();
      await box.put('ostatniaData', dzis);
    }

    _zaladujLeki();
  }

  Future<void> _resetujPrzyjecia() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final leki = await _lekService.pobierzMojeLeki(userId);
    final dzis = _dzisiaj.toIso8601String().substring(0, 10);

    for (var lek in leki) {
      final nowePrzyjete = {
        dzis: 0,
      };
      await supabase
          .from('user_leki')
          .update({'przyjete_dziennie': nowePrzyjete})
          .eq('id', lek.id);
    }
  }

  Future<void> _zaladujLeki() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final leki = await _lekService.pobierzMojeLeki(userId);

    setState(() {
      _leki = leki;
      _filtrowaneLeki = leki;
    });
  }

  void _filtrujLeki(String query) {
    setState(() {
      final baza = _filter == "wszystkie"
          ? _leki
          : _leki.where((lek) => lek.pora == _filter).toList();

      _filtrowaneLeki = baza
          .where((lek) => lek.nazwa.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _oznaczPrzyjete(Lek lek) async {
    await _lekService.oznaczPrzyjete(lek);
    await _zaladujLeki();
  }

  int _ilePrzyjeteDzis(Lek lek) {
    final dzis = _dzisiaj.toIso8601String().substring(0, 10);
    return lek.przyjeteDziennie[dzis] ?? 0;
  }

  bool _czyWszystkieDzis(Lek lek) {
    return _ilePrzyjeteDzis(lek) >= lek.iloscDziennie;
  }

  Future<void> _zglosEfektUboczny(Lek lek, String opis) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('dzialania').insert({
        'user_id': userId,
        'lek_id': lek.id,
        'opis': opis,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Zgłoszenie zapisane")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd przy zapisie: $e")),
        );
      }
    }
  }

  Future<String?> _pokazDialogZgloszenia() async {
    String opis = "";
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Zgłoś działanie niepożądane"),
        content: TextField(
          onChanged: (val) => opis = val,
          decoration: const InputDecoration(hintText: "Opisz objawy..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Anuluj"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, opis),
            child: const Text("Zapisz"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje leki"),
        backgroundColor: const Color(0xFFA5668B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _zaladujLeki,
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: _filter,
              decoration: const InputDecoration(labelText: "Filtruj wg pory dnia"),
              items: const [
                DropdownMenuItem(value: "wszystkie", child: Text("Wszystkie")),
                DropdownMenuItem(value: "rano", child: Text("Rano")),
                DropdownMenuItem(value: "wieczorem", child: Text("Wieczorem")),
                DropdownMenuItem(value: "codziennie", child: Text("Codziennie")),
              ],
              onChanged: (val) {
                setState(() => _filter = val!);
                _filtrujLeki(_searchController.text);
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrujLeki,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA5668B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF312F2F)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filtrujLeki('');
                    });
                  },
                )
                    : null,
                hintText: "Wyszukaj w moich lekach...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filtrowaneLeki.isEmpty
                ? const Center(child: Text("Brak wyników"))
                : ListView.builder(
              itemCount: _filtrowaneLeki.length,
              itemBuilder: (context, index) {
                final lek = _filtrowaneLeki[index];
                final ilePrzyjete = _ilePrzyjeteDzis(lek);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 4,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: _czyWszystkieDzis(lek)
                        ? Colors.green.shade50
                        : Colors.white,
                    leading: Checkbox(
                      value: _czyWszystkieDzis(lek),
                      activeColor: const Color(0xFFA5668B),
                      onChanged: (val) {
                        if (ilePrzyjete < lek.iloscDziennie) {
                          _oznaczPrzyjete(lek);
                        }
                      },
                    ),
                    title: Text(
                      lek.nazwa,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _czyWszystkieDzis(lek)
                            ? Colors.green.shade700
                            : const Color(0xFF312F2F),
                      ),
                    ),
                    subtitle: Text("Dzisiaj: $ilePrzyjete / ${lek.iloscDziennie}"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (lek.sklad != null) Text("Skład: ${lek.sklad}"),
                            Text("Twoja dawka: ${lek.dawkowanie}"),
                            if (lek.zalecaneDawkowanie != null)
                              Text("Zalecane dawkowanie: ${lek.zalecaneDawkowanie}"),
                            if (lek.dzialaniaNiepozadane != null &&
                                lek.dzialaniaNiepozadane!.isNotEmpty)
                              Text("⚠️ ${lek.dzialaniaNiepozadane!}",
                                  style: const TextStyle(color: Colors.red)),
                            if (lek.interakcje.isNotEmpty)
                              Text(
                                "Interakcje: ${lek.interakcje.join('; ')}",
                                style: const TextStyle(color: Colors.orange),
                              ),
                            Text(
                              "Przyjmujesz do: ${lek.dataKoniec.toLocal().toString().split(' ')[0]}",
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  label: const Text("Brak efektów"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade100,
                                    foregroundColor: Colors.green.shade800,
                                  ),
                                  onPressed: () {
                                    _zglosEfektUboczny(lek, "brak");
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.warning, color: Colors.red),
                                  label: const Text("⚠️ Zgłoś"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade800,
                                  ),
                                  onPressed: () async {
                                    final opis = await _pokazDialogZgloszenia();
                                    if (opis != null && opis.isNotEmpty) {
                                      _zglosEfektUboczny(lek, opis);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
