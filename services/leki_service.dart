import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lek_model.dart';

class LekService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Lek>> pobierzMojeLeki(String userId) async {
    final response = await _supabase
        .from('user_leki')
        .select('''
        id,
        user_id,
        lek_id,
        nazwa,
        dawkowanie,
        pora,
        dni_przyjmowania,
        data_start,
        data_koniec,
        dzialania_niepozadane,
        ilosc_dziennie,
        przyjete_dziennie
      ''')
        .eq('user_id', userId);

    return (response as List).map((data) {
      final map = Map<String, dynamic>.from(data);

      final rawPrzyjete = map['przyjete_dziennie'];
      Map<String, int> przyjeteMap = {};
      if (rawPrzyjete is Map) {
        przyjeteMap = rawPrzyjete.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
      }

      return Lek.fromMap({
        ...map,
        'dni_przyjmowania': map['dni_przyjmowania'] ?? 0,
        'przyjete_dziennie': przyjeteMap,
      });
    }).toList();
  }

  Future<void> dodajLek(Lek lek) async {
    await _supabase.from('user_leki').insert({
      'user_id': lek.userId,
      'lek_id': (lek.lekId == null || lek.lekId!.isEmpty) ? null : lek.lekId,
      'nazwa': lek.nazwa,
      'dawkowanie': lek.dawkowanie,
      'pora': lek.pora,
      'dni_przyjmowania': lek.dniPrzyjmowania,
      'data_start': lek.dataStart.toIso8601String(),
      'data_koniec': lek.dataKoniec.toIso8601String(),
      'dzialania_niepozadane': lek.dzialaniaNiepozadane,
      'ilosc_dziennie': lek.iloscDziennie,
      'przyjete_dziennie': {}, // start pusty
    });
  }

  Future<void> zaktualizujLek(Lek lek) async {
    await _supabase.from('user_leki').update({
      'nazwa': lek.nazwa,
      'dawkowanie': lek.dawkowanie,
      'pora': lek.pora,
      'dni_przyjmowania': lek.dniPrzyjmowania,
      'data_koniec': lek.dataKoniec.toIso8601String(),
      'ilosc_dziennie': lek.iloscDziennie,
    }).eq('id', lek.id);
  }

  Future<void> oznaczPrzyjete(Lek lek) async {
    final dzis = DateTime.now().toIso8601String().substring(0, 10);

    final response = await _supabase
        .from('user_leki')
        .select('przyjete_dziennie')
        .eq('id', lek.id)
        .single();

    final Map<String, int> przyjeteMap =
        (response['przyjete_dziennie'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            {};

    int aktualne = przyjeteMap[dzis] ?? 0;

    if (aktualne < lek.iloscDziennie) {
      przyjeteMap[dzis] = aktualne + 1;

      await _supabase
          .from('user_leki')
          .update({'przyjete_dziennie': przyjeteMap})
          .eq('id', lek.id);
    }
  }

  Future<void> usunLek(String id) async {
    await _supabase.from('user_leki').delete().eq('id', id);
  }

  Future<void> zglosEfektUboczny(String userId, String lekId, String opis) async {
    await _supabase.from('dzialania').insert({
      'user_id': userId,
      'lek_id': lekId,
      'opis': opis,
    });
  }

}
