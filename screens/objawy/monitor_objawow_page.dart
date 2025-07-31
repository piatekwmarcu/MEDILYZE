import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/objawy_service.dart';
import '../../models/objaw_model.dart';
import 'package:fl_chart/fl_chart.dart';

class MonitorObjawowPage extends StatefulWidget {
  const MonitorObjawowPage({super.key});

  @override
  State<MonitorObjawowPage> createState() => _MonitorObjawowPageState();
}

class _MonitorObjawowPageState extends State<MonitorObjawowPage> {
  final ObjawyService _objawyService = ObjawyService();
  final supabase = Supabase.instance.client;
  List<Objaw> objawy = [];

  @override
  void initState() {
    super.initState();
    _zaladujObjawy();
  }

  Future<void> _zaladujObjawy() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final lista = await _objawyService.pobierzObjawy(userId);
    setState(() => objawy = lista);
  }

  Future<void> _dodajObjawDialog({Objaw? doEdycji}) async {
    String? samopoczucie = doEdycji?.samopoczucie;
    final notatkaController = TextEditingController(text: doEdycji?.notatka ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doEdycji == null ? 'Dodaj wpis' : 'Edytuj wpis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Samopoczucie"),
              value: samopoczucie,
              items: const [
                DropdownMenuItem(value: "😀", child: Text("😀 Dobre")),
                DropdownMenuItem(value: "😐", child: Text("😐 Średnie")),
                DropdownMenuItem(value: "😣", child: Text("😣 Złe")),
              ],
              onChanged: (val) => samopoczucie = val,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notatkaController,
              decoration: const InputDecoration(
                labelText: "Notatka",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              final userId = supabase.auth.currentUser?.id;
              if (userId == null || samopoczucie == null) return;

              final objaw = Objaw(
                id: doEdycji?.id,
                userId: userId,
                data: doEdycji?.data ?? DateTime.now(),
                samopoczucie: samopoczucie!,
                notatka: notatkaController.text,
              );

              if (doEdycji == null) {
                await _objawyService.dodajObjaw(objaw);
              } else {
                await _objawyService.edytujObjaw(objaw);
              }

              if (context.mounted) {
                Navigator.pop(context);
                _zaladujObjawy();
              }
            },
            child: Text(doEdycji == null ? 'Dodaj' : 'Zapisz zmiany'),
          ),
        ],
      ),
    );
  }

  Future<void> _usunObjaw(String id) async {
    await _objawyService.usunObjaw(id);
    _zaladujObjawy();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wpis został usunięty 🗑️')),
      );
    }
  }

  Widget _buildTrendChart() {
    if (objawy.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Brak danych do wyświetlenia 📊"),
      );
    }

    final data = objawy.reversed.map((e) {
      int value;
      switch (e.samopoczucie) {
        case "😀":
          value = 3;
          break;
        case "😐":
          value = 2;
          break;
        case "😣":
          value = 1;
          break;
        default:
          value = 2;
      }
      return FlSpot(
        e.data.millisecondsSinceEpoch.toDouble(),
        value.toDouble(),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: const Color(0xFFA5668B),
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA5668B), // kolor różowo-fioletowy
        title: const Text(
          'Monitor objawów 📊',
          style: TextStyle(
            color: Colors.white, // biała czcionka
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // białe ikony w AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTrendChart(),
            const Divider(),
            objawy.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Brak wpisów. Kliknij + aby dodać.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: objawy.length,
              itemBuilder: (context, index) {
                final objaw = objawy[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  color: const Color(0xFFA5668B),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Text(
                      objaw.samopoczucie,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      objaw.data.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      objaw.notatka.isEmpty
                          ? 'Brak notatki'
                          : objaw.notatka,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () =>
                              _dodajObjawDialog(doEdycji: objaw),
                        ),
                        IconButton(
                          icon:
                          const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _usunObjaw(objaw.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA5668B),
        onPressed: () => _dodajObjawDialog(),
        child: const Icon(Icons.add, color: Colors.white), // biała ikona "+"
      ),
    );
  }
}
