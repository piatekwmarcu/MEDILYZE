import 'package:supabase_flutter/supabase_flutter.dart';

class PrzeciwwskazaniaService {
  final _supabase = Supabase.instance.client;

  Future<List<String>> sprawdzPrzeciwwskazania(
      String lekNazwa, List<String> chorobyPacjenta) async {
    if (chorobyPacjenta.isEmpty) return [];

    final filterString = chorobyPacjenta
        .map((c) => 'choroba.eq.${c.replaceAll(" ", "%20")}')
        .join(',');

    final response = await _supabase
        .from('leki_przeciwwskazania')
        .select('choroba')
        .eq('lek_nazwa', lekNazwa)
        .or(filterString);

    return (response as List).map((e) => e['choroba'] as String).toList();
  }

  Future<Map<String, List<String>>> pobierzLekiPrzeciwwskazaneDlaChorob(
      List<String> chorobyPacjenta) async {
    if (chorobyPacjenta.isEmpty) return {};

    final filterString = chorobyPacjenta
        .map((c) => 'choroba.eq.${c.replaceAll(" ", "%20")}')
        .join(',');

    final response = await _supabase
        .from('leki_przeciwwskazania')
        .select('lek_nazwa, choroba')
        .or(filterString);

    final Map<String, List<String>> wynik = {};
    for (var e in response as List) {
      final lek = e['lek_nazwa'] as String;
      final choroba = e['choroba'] as String;
      wynik.putIfAbsent(lek, () => []).add(choroba);
    }
    return wynik;
  }
}
