import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/leki_service.dart';
import '../../models/lek_model.dart';

class EdytujLekPage extends StatefulWidget {
  final Lek lek;

  const EdytujLekPage({super.key, required this.lek});

  @override
  State<EdytujLekPage> createState() => _EdytujLekPageState();
}

class _EdytujLekPageState extends State<EdytujLekPage> {
  final _formKey = GlobalKey<FormState>();
  final LekService _lekService = LekService();
  final supabase = Supabase.instance.client;

  // kontrolery
  late TextEditingController _nazwaController;
  late TextEditingController _dawkowanieController;
  late TextEditingController _dniController;

  String? _pora;
  bool _wpiszRecznie = false;

  @override
  void initState() {
    super.initState();
    _nazwaController = TextEditingController(text: widget.lek.nazwa);
    _dawkowanieController = TextEditingController(text: widget.lek.dawkowanie);
    _dniController =
        TextEditingController(text: widget.lek.dniPrzyjmowania.toString());
    _pora = widget.lek.pora;
    _wpiszRecznie = widget.lek.lekId == null;
  }

  Future<void> _zapiszZmiany() async {
    if (!_formKey.currentState!.validate() || _pora == null) return;

    final dni = int.tryParse(_dniController.text) ?? 0;
    final dataStart = widget.lek.dataStart;
    final dataKoniec = dataStart.add(Duration(days: dni));

    final zaktualizowanyLek = widget.lek.copyWith(
      nazwa: _nazwaController.text,
      dawkowanie: _dawkowanieController.text,
      pora: _pora!,
      dniPrzyjmowania: dni,
      dataKoniec: dataKoniec,
    );

    await _lekService.zaktualizujLek(zaktualizowanyLek);

    if (context.mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lek został zaktualizowany ✅")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj lek"),
        backgroundColor: const Color(0xFFA5668B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nazwaController,
                  decoration: const InputDecoration(labelText: "Nazwa leku"),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Podaj nazwę leku" : null,
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
                  value: _pora,
                  decoration: const InputDecoration(labelText: "Pora przyjmowania"),
                  items: const [
                    DropdownMenuItem(value: "rano", child: Text("Rano")),
                    DropdownMenuItem(value: "wieczorem", child: Text("Wieczorem")),
                    DropdownMenuItem(value: "codziennie", child: Text("Codziennie")),
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _zapiszZmiany,
                  icon: const Icon(Icons.save),
                  label: const Text("Zapisz zmiany"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
