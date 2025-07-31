import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterakcjePage extends StatefulWidget {
  const InterakcjePage({super.key});

  @override
  State<InterakcjePage> createState() => _InterakcjePageState();
}

class _InterakcjePageState extends State<InterakcjePage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _wyniki = [];

  Future<void> _wyszukajInterakcje(String query) async {
    if (query.isEmpty) {
      setState(() => _wyniki = []);
      return;
    }

    try {
      final response = await supabase
          .from('interakcje')
          .select()
          .or('lek1.ilike.%$query%,lek2.ilike.%$query%')
          .order('lek1');

      print("DEBUG: znaleziono ${response.length} interakcji dla $query");

      setState(() {
        _wyniki = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("ERROR Supabase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Błąd podczas wyszukiwania interakcji")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sprawdź interakcje"),
        backgroundColor: const Color(0xFFA5668B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _wyszukajInterakcje,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA5668B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF312F2F)),
                  onPressed: () {
                    _searchController.clear();
                    _wyszukajInterakcje('');
                  },
                )
                    : null,
                hintText: "Wpisz nazwę leku...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _wyniki.isEmpty
                  ? const Center(child: Text("Brak wyników"))
                  : ListView.builder(
                itemCount: _wyniki.length,
                itemBuilder: (context, index) {
                  final interakcja = _wyniki[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.warning,
                          color: Colors.red),
                      title: Text(
                        "${interakcja['lek1']} + ${interakcja['lek2']}",
                        style:
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(interakcja['opis']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
