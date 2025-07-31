import 'package:flutter/material.dart';
import '../../models/lek_model.dart';
import '../../services/leki_service.dart';
import 'edytuj_lek_page.dart';

class SzczegolyLekPage extends StatelessWidget {
  final Lek lek;
  final LekService _lekService = LekService();

  SzczegolyLekPage({super.key, required this.lek});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Szczegóły: ${lek.nazwa}"),
        backgroundColor: const Color(0xFFA5668B),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EdytujLekPage(lek: lek),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true); // wróć i odśwież listę
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final potwierdzenie = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Potwierdź usunięcie"),
                  content: Text(
                      "Czy na pewno chcesz usunąć lek \"${lek.nazwa}\" z listy?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Anuluj"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Usuń"),
                    ),
                  ],
                ),
              );

              if (potwierdzenie == true) {
                await _lekService.usunLek(lek.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lek \"${lek.nazwa}\" został usunięty ❌")),
                  );
                  Navigator.pop(context, true);
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _infoTile("Nazwa", lek.nazwa),
            _infoTile("Dawkowanie", lek.dawkowanie),
            _infoTile("Pora przyjmowania", lek.pora),
            _infoTile("Przyjmujesz do",
                lek.dataKoniec.toLocal().toString().split(' ')[0]),
            if (lek.dzialaniaNiepozadane != null &&
                lek.dzialaniaNiepozadane!.isNotEmpty)
              _infoTile("Działania niepożądane", lek.dzialaniaNiepozadane!),
            const SizedBox(height: 24),
            const Text(
              "Historia przyjęć",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF312F2F),
              ),
            ),
            const SizedBox(height: 12),
            if (lek.przyjete.isEmpty)
              const Text("Brak historii przyjęć."),
            if (lek.przyjete.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: lek.przyjete.map((data) {
                  return Chip(
                    label: Text(data,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF312F2F),
                        )),
                    backgroundColor: Colors.green.shade100,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E6E58),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Color(0xFF312F2F)),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
