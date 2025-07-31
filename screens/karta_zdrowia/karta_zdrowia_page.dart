import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/karta_zdrowia_service.dart';
import '../../models/karta_zdrowia_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum WidokZdrowia { wykresy, lista, oba }

class KartaZdrowiaPage extends StatefulWidget {
  const KartaZdrowiaPage({super.key});

  @override
  State<KartaZdrowiaPage> createState() => _KartaZdrowiaPageState();
}

class _KartaZdrowiaPageState extends State<KartaZdrowiaPage> {
  final KartaZdrowiaService _service = KartaZdrowiaService();
  final supabase = Supabase.instance.client;
  List<KartaZdrowia> wpisy = [];
  WidokZdrowia _trybWidoku = WidokZdrowia.oba;

  @override
  void initState() {
    super.initState();
    _zaladujWpisy();
  }

  Future<void> _zaladujWpisy() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final lista = await _service.pobierzWpisy(userId);
    setState(() => wpisy = lista);
  }

  Future<void> _generujPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "Karta zdrowia pacjenta ❤️",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          if (wpisy.isEmpty)
            pw.Text("Brak danych do wyświetlenia"),
          if (wpisy.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                "Data",
                "Waga (kg)",
                "Ciśnienie",
                "Tętno",
                "Cukier",
                "Saturacja (%)"
              ],
              data: wpisy.map((w) {
                return [
                  w.data.toLocal().toString().split(' ')[0],
                  w.waga?.toString() ?? "-",
                  "${w.cisnienieSkurczowe ?? '-'}/${w.cisnienieRozkurczowe ?? '-'}",
                  w.tetno?.toString() ?? "-",
                  w.cukier?.toString() ?? "-",
                  w.saturacja?.toString() ?? "-",
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> _dodajWpisDialog() async {
    final wagaController = TextEditingController();
    final cisSkurczController = TextEditingController();
    final cisRozkurczController = TextEditingController();
    final tetnoController = TextEditingController();
    final cukierController = TextEditingController();
    final saturacjaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dodaj dane zdrowotne ❤️'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(wagaController, "Waga (kg)"),
              const SizedBox(height: 8),
              _buildTextField(cisSkurczController, "Ciśnienie skurczowe"),
              _buildTextField(cisRozkurczController, "Ciśnienie rozkurczowe"),
              _buildTextField(tetnoController, "Tętno"),
              _buildTextField(cukierController, "Cukier (mmol/L)"),
              _buildTextField(saturacjaController, "Saturacja (%)"),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5668B)),
            onPressed: () async {
              final userId = supabase.auth.currentUser?.id;
              if (userId == null) return;

              final wpis = KartaZdrowia(
                userId: userId,
                data: DateTime.now(),
                waga: double.tryParse(wagaController.text),
                cisnienieSkurczowe: int.tryParse(cisSkurczController.text),
                cisnienieRozkurczowe: int.tryParse(cisRozkurczController.text),
                tetno: int.tryParse(tetnoController.text),
                cukier: double.tryParse(cukierController.text),
                saturacja: int.tryParse(saturacjaController.text),
              );

              await _service.dodajWpis(wpis);
              if (context.mounted) {
                Navigator.pop(context);
                _zaladujWpisy();
              }
            },
            child: const Text("Dodaj",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildAllCharts() {
    if (wpisy.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Brak danych do wyświetlenia 📈"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        children: [
          _buildSingleChart(
              "Waga (kg)",
              wpisy
                  .map((e) => e.waga != null
                  ? FlSpot(e.data.millisecondsSinceEpoch.toDouble(),
                  e.waga!)
                  : null)
                  .whereType<FlSpot>()
                  .toList()),
          _buildSingleChart(
              "Ciśnienie",
              wpisy
                  .map((e) => e.cisnienieSkurczowe != null
                  ? FlSpot(e.data.millisecondsSinceEpoch.toDouble(),
                  e.cisnienieSkurczowe!.toDouble())
                  : null)
                  .whereType<FlSpot>()
                  .toList()),
          _buildSingleChart(
              "Tętno",
              wpisy
                  .map((e) => e.tetno != null
                  ? FlSpot(e.data.millisecondsSinceEpoch.toDouble(),
                  e.tetno!.toDouble())
                  : null)
                  .whereType<FlSpot>()
                  .toList()),
          _buildSingleChart(
              "Cukier (mmol/L)",
              wpisy
                  .map((e) => e.cukier != null
                  ? FlSpot(e.data.millisecondsSinceEpoch.toDouble(),
                  e.cukier!)
                  : null)
                  .whereType<FlSpot>()
                  .toList()),
          _buildSingleChart(
              "Saturacja (%)",
              wpisy
                  .map((e) => e.saturacja != null
                  ? FlSpot(e.data.millisecondsSinceEpoch.toDouble(),
                  e.saturacja!.toDouble())
                  : null)
                  .whereType<FlSpot>()
                  .toList()),
        ],
      ),
    );
  }

  Widget _buildSingleChart(String tytul, List<FlSpot> data) {
    if (data.isEmpty) {
      return Card(
        color: const Color(0xFFA5668B),
        child: Center(
          child: Text("$tytul\nBrak danych",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return Card(
      color: const Color(0xFFA5668B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(tytul,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: Colors.white,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
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
        backgroundColor: const Color(0xFFA5668B),
        title: const Text('Karta zdrowia ❤️',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Eksportuj do PDF",
            onPressed: _generujPdf,
          ),
          PopupMenuButton<WidokZdrowia>(
            icon: const Icon(Icons.view_comfy, color: Colors.white),
            onSelected: (val) {
              setState(() => _trybWidoku = val);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: WidokZdrowia.wykresy, child: Text("Tylko wykresy 📊")),
              PopupMenuItem(value: WidokZdrowia.lista, child: Text("Tylko lista 📋")),
              PopupMenuItem(value: WidokZdrowia.oba, child: Text("Wykresy + lista 🔀")),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_trybWidoku == WidokZdrowia.wykresy ||
                _trybWidoku == WidokZdrowia.oba)
              _buildAllCharts(),
            const Divider(),
            if (_trybWidoku == WidokZdrowia.lista ||
                _trybWidoku == WidokZdrowia.oba)
              wpisy.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Brak wpisów. Kliknij + aby dodać."),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wpisy.length,
                itemBuilder: (context, index) {
                  final wpis = wpisy[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    color: const Color(0xFFA5668B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        wpis.data
                            .toLocal()
                            .toString()
                            .split(' ')[0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Waga: ${wpis.waga ?? '-'} kg\n"
                            "Ciśnienie: ${wpis.cisnienieSkurczowe ?? '-'} / ${wpis.cisnienieRozkurczowe ?? '-'}\n"
                            "Tętno: ${wpis.tetno ?? '-'}\n"
                            "Cukier: ${wpis.cukier ?? '-'}\n"
                            "Saturacja: ${wpis.saturacja ?? '-'}%",
                        style: const TextStyle(color: Colors.white70),
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
        onPressed: _dodajWpisDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
