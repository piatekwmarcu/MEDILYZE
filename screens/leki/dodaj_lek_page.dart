import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/leki_service.dart';
import '../../models/lek_model.dart';
import '../../services/przeciwwskazania_service.dart';
import '../../services/choroby_service.dart';

class DodajLekPage extends StatefulWidget {
  const DodajLekPage({super.key});

  @override
  State<DodajLekPage> createState() => _DodajLekPageState();
}

class _DodajLekPageState extends State<DodajLekPage> {
  final _formKey = GlobalKey<FormState>();
  final LekService _lekService = LekService();
  final ChorobyService _chorobyService = ChorobyService();
  final PrzeciwwskazaniaService _przeciwwskazaniaService = PrzeciwwskazaniaService();
  final supabase = Supabase.instance.client;

  final _nazwaController = TextEditingController();
  final _dawkowanieController = TextEditingController();
  final _dniController = TextEditingController();

  String? _selectedLekId;
  String? _pora;
  bool _wpiszRecznie = false;
  bool _pokazListe = false;
  int _iloscDziennie = 1; // 👈 dodane

  List<Map<String, dynamic>> _listaLekow = [];
  List<Map<String, dynamic>> _filtrowaneLeki = [];

  @override
  void initState() {
    super.initState();
    _zaladujListeLekow();
  }

  Future<void> _zaladujListeLekow() async {
    final response = await supabase.from('leki').select().order('nazwa');
    setState(() {
      _listaLekow = List<Map<String, dynamic>>.from(response);
      _filtrowaneLeki = _listaLekow;
    });
  }

  Future<void> _zapiszLek() async {
    if (!_formKey.currentState!.validate() || _pora == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final wybranyLek = !_wpiszRecznie && _selectedLekId != null
        ? _listaLekow.firstWhere((lek) => lek['id'].toString() == _selectedLekId)
        : null;

    final nazwa = _wpiszRecznie
        ? _nazwaController.text.trim()
        : wybranyLek?['nazwa'] ?? '';

    final dzialaniaNiepozadane =
    _wpiszRecznie ? null : wybranyLek?['dzialania_niepozadane'];

    final dni = int.tryParse(_dniController.text) ?? 0;
    final dataStart = DateTime.now();
    final dataKoniec = dataStart.add(Duration(days: dni));

    // 🔹 Sprawdzenie przeciwwskazań
    final chorobyPacjenta = (await _chorobyService.pobierzChoroby())
        .map((c) => c.nazwa)
        .toList();

    final konflikty = await _przeciwwskazaniaService
        .sprawdzPrzeciwwskazania(nazwa, chorobyPacjenta);

    if (konflikty.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⚠️ Ostrzeżenie"),
          content: Text(
            "Lek $nazwa może być przeciwwskazany przy chorobach:\n- ${konflikty.join('\n- ')}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA5668B)),
              onPressed: () async {
                Navigator.pop(context);
                await _dodajLekDoBazy(userId, nazwa, dzialaniaNiepozadane, dni, dataStart, dataKoniec);
              },
              child: const Text("Dodaj mimo to"),
            ),
          ],
        ),
      );
    } else {
      await _dodajLekDoBazy(userId, nazwa, dzialaniaNiepozadane, dni, dataStart, dataKoniec);
    }
  }

  Future<void> _dodajLekDoBazy(String userId, String nazwa, String? dzialaniaNiepozadane,
      int dni, DateTime dataStart, DateTime dataKoniec) async {
    final lek = Lek(
      id: '',
      userId: userId,
      lekId: _wpiszRecznie || _selectedLekId == null ? null : _selectedLekId,
      nazwa: nazwa,
      dawkowanie: _dawkowanieController.text,
      dzialaniaNiepozadane: dzialaniaNiepozadane,
      pora: _pora!,
      dniPrzyjmowania: dni,
      dataStart: dataStart,
      dataKoniec: dataKoniec,
      przyjete: [],
      iloscDziennie: _iloscDziennie,
      przyjeteDziennie: {},
    );

    await _lekService.dodajLek(lek);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lek $nazwa został dodany ✅")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dodaj lek"),
        backgroundColor: const Color(0xFFA5668B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text("Wpisz lek ręcznie"),
                  activeColor: const Color(0xFFA5668B),
                  value: _wpiszRecznie,
                  onChanged: (val) {
                    setState(() {
                      _wpiszRecznie = val;
                      if (val) {
                        _pokazListe = false;
                        _selectedLekId = null;
                        _nazwaController.clear();
                      }
                    });
                  },
                ),

                if (_wpiszRecznie)
                  TextFormField(
                    controller: _nazwaController,
                    decoration: const InputDecoration(labelText: "Nazwa leku"),
                    validator: (val) =>
                    val == null || val.isEmpty ? "Podaj nazwę leku" : null,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nazwaController,
                        onChanged: (query) {
                          setState(() {
                            _pokazListe = query.isNotEmpty;
                            _filtrowaneLeki = _listaLekow
                                .where((lek) => lek['nazwa']
                                .toString()
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFFA5668B)),
                          suffixIcon: _nazwaController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Color(0xFF312F2F)),
                            onPressed: () {
                              setState(() {
                                _nazwaController.clear();
                                _selectedLekId = null;
                                _pokazListe = false;
                              });
                            },
                          )
                              : null,
                          hintText: "Wyszukaj lek...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_pokazListe)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _filtrowaneLeki.length,
                            itemBuilder: (context, index) {
                              final lek = _filtrowaneLeki[index];
                              return ListTile(
                                title: Text(lek['nazwa']),
                                onTap: () {
                                  setState(() {
                                    _nazwaController.text = lek['nazwa'];
                                    _selectedLekId = lek['id'].toString();
                                    _pokazListe = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _dawkowanieController,
                  decoration: const InputDecoration(labelText: "Dawkowanie"),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Podaj dawkowanie" : null,
                ),

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration:
                  const InputDecoration(labelText: "Pora przyjmowania"),
                  value: _pora,
                  items: const [
                    DropdownMenuItem(value: "rano", child: Text("Rano")),
                    DropdownMenuItem(
                        value: "wieczorem", child: Text("Wieczorem")),
                    DropdownMenuItem(
                        value: "codziennie", child: Text("Codziennie")),
                  ],
                  onChanged: (val) => setState(() => _pora = val),
                  validator: (val) =>
                  val == null ? "Wybierz porę przyjmowania" : null,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Liczba dni przyjmowania"),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Podaj liczbę dni" : null,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Ile razy dziennie przyjmujesz ten lek?"),
                  onChanged: (val) {
                    setState(() {
                      _iloscDziennie = int.tryParse(val) ?? 1;
                    });
                  },
                  validator: (val) => val == null || val.isEmpty
                      ? "Podaj ile razy dziennie"
                      : null,
                ),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _zapiszLek,
                    icon: const Icon(Icons.save),
                    label: const Text("Zapisz"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
