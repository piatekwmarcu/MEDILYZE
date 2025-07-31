import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/leki/moje_leki_page.dart';
import '../../screens/leki/dodaj_lek_page.dart';
import '../../screens/leki/interakcje_page.dart';
import '../../services/leki_service.dart';
import '../../screens/choroby/moje_choroby_page.dart';
import '../../screens/objawy/monitor_objawow_page.dart';
import '../../screens/karta_zdrowia/karta_zdrowia_page.dart';
import '../../screens/raport/raport_dla_lekarza_page.dart';
import '../../screens/edukacja/edukacja_pacjenta_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String? userName;
  final LekService _lekService = LekService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();

      setState(() {
        userName = response['name'];
      });
    }
  }

  Future<Map<String, int>> _pobierzStatusDzienny() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {'przyjete': 0, 'planowane': 0};

    final leki = await _lekService.pobierzMojeLeki(userId);
    final dzis = DateTime.now().toIso8601String().substring(0, 10);

    int przyjete = 0;
    int planowane = 0;

    for (var lek in leki) {
      planowane += lek.iloscDziennie;
      przyjete += lek.przyjeteDziennie[dzis] ?? 0;
    }

    return {'przyjete': przyjete, 'planowane': planowane};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6FDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6FDFF),
        elevation: 0,
        leading: const SizedBox.shrink(),
        centerTitle: true,
        title: SizedBox(
          height: 50,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            width: 140,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFA5668B)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Witaj, ${userName ?? '...'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF312F2F),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 Widget statusu dziennego
            FutureBuilder<Map<String, int>>(
              future: _pobierzStatusDzienny(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return const Text("Brak danych o lekach");
                }

                final data = snapshot.data!;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Status dzienny",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dziś przyjęto ${data['przyjete']} / ${data['planowane']} leków",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF312F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            Wrap(
              spacing: 40,
              runSpacing: 30,
              alignment: WrapAlignment.center,
              children: [
                _circleButton('Moje leki', Icons.medication, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MojeLekiPage()),
                  );
                }),
                _circleButton('Dodaj lek', Icons.add, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DodajLekPage()),
                  );
                }),
                _circleButton('Interakcje', Icons.search, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InterakcjePage()),
                  );
                }),
                _circleButton('Moje choroby', Icons.local_hospital, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MojeChorobyPage()),
                  );
                }),
                _circleButton('Monitor objawów', Icons.bar_chart, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MonitorObjawowPage()),
                  );
                }),
                _circleButton('Karta zdrowia', Icons.favorite, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KartaZdrowiaPage()),
                  );
                }),
                _circleButton('Raport dla lekarza', Icons.picture_as_pdf, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RaportDlaLekarzaPage()),
                  );
                }),
                _circleButton('Edukacja pacjenta', Icons.menu_book, () {  // 📚 NOWY KAFEL
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EdukacjaPacjentaPage()),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(String label, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFA5668B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF312F2F),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
