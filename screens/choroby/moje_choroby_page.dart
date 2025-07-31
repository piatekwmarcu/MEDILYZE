import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/choroby_service.dart';
import '../../services/przeciwwskazania_service.dart';
import '../../models/choroba_model.dart';

class MojeChorobyPage extends StatefulWidget {
  const MojeChorobyPage({super.key});

  @override
  State<MojeChorobyPage> createState() => _MojeChorobyPageState();
}

class _MojeChorobyPageState extends State<MojeChorobyPage> {
  final ChorobyService _chorobyService = ChorobyService();
  final PrzeciwwskazaniaService _przeciwwskazaniaService = PrzeciwwskazaniaService();
  final supabase = Supabase.instance.client;

  List<Choroba> choroby = [];
  List<String> wszystkieChoroby = [];
  List<String> filtrowaneChoroby = [];
  bool pokazListe = false;
  bool ladowanieChorob = true;

  @override
  void initState() {
    super.initState();
    _zaladujChoroby();
    _zaladujListeChorob();
  }

  Future<void> _zaladujChoroby() async {
    final lista = await _chorobyService.pobierzChoroby();
    setState(() {
      choroby = lista;
    });
  }

  Future<void> _zaladujListeChorob() async {
    try {
      final response = await supabase
          .from('leki_przeciwwskazania')
          .select('choroba');

      final chorobySet = (response as List)
          .map((e) => e['choroba'] as String)
          .toSet();

      setState(() {
        wszystkieChoroby = chorobySet.toList()..sort();
        ladowanieChorob = false;
      });
    } catch (e) {
      print("Błąd ładowania chorób: $e");
      setState(() => ladowanieChorob = false);
    }
  }

  Future<void> _dodajChorobeDialog() async {
    final nazwaController = TextEditingController();
    final opisController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Dodaj chorobę 🏥'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nazwaController,
                  onChanged: (query) {
                    setStateDialog(() {
                      pokazListe = query.isNotEmpty;
                      filtrowaneChoroby = wszystkieChoroby
                          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Wyszukaj chorobę',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (pokazListe)
                  ladowanieChorob
                      ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                      : filtrowaneChoroby.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Brak wyników"),
                  )
                      : SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        children: filtrowaneChoroby.map((choroba) {
                          return ListTile(
                            title: Text(choroba),
                            onTap: () {
                              nazwaController.text = choroba;
                              setStateDialog(() => pokazListe = false);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: opisController,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcjonalnie)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA5668B),
                ),
                onPressed: () async {
                  if (nazwaController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Podaj nazwę choroby')),
                    );
                    return;
                  }
                  await _chorobyService.dodajChorobe(
                    nazwaController.text.trim(),
                    opisController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Choroba została dodana')),
                    );
                    _zaladujChoroby();
                  }
                },
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pokazPrzeciwwskazaneLeki() async {
    final chorobyPacjenta = choroby.map((c) => c.nazwa).toList();
    final konflikty = await _przeciwwskazaniaService
        .pobierzLekiPrzeciwwskazaneDlaChorob(chorobyPacjenta);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leki przeciwwskazane ⚠️'),
        content: konflikty.isEmpty
            ? const Text('Brak przeciwwskazań dla Twoich chorób 🎉')
            : SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: konflikty.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: Text('Przeciwwskazania: ${entry.value.join(", ")}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6FDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6FDFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF312F2F)),
        title: const Text(
          'Moje choroby',
          style: TextStyle(color: Color(0xFF312F2F)),
        ),
      ),
      body: choroby.isEmpty
          ? const Center(
        child: Text(
          'Brak dodanych chorób.\nKliknij + aby dodać.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: choroby.length,
        itemBuilder: (context, index) {
          final choroba = choroby[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.redAccent),
              title: Text(
                choroba.nazwa,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(choroba.opis),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _chorobyService.usunChorobe(choroba.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Choroba została usunięta')),
                    );
                    _zaladujChoroby();
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xFFA5668B),
            heroTag: "dodaj",
            onPressed: _dodajChorobeDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.orange,
            heroTag: "sprawdz",
            onPressed: _pokazPrzeciwwskazaneLeki,
            child: const Icon(Icons.warning, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
