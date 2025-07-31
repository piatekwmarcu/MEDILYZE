import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/karta_zdrowia_model.dart';

class KartaZdrowiaService {
  final _supabase = Supabase.instance.client;
  final String tabela = 'karta_zdrowia';

  Future<void> dodajWpis(KartaZdrowia wpis) async {
    await _supabase.from(tabela).insert(wpis.toMap(wpis.userId));
  }

  Future<List<KartaZdrowia>> pobierzWpisy(String userId) async {
    final response = await _supabase
        .from(tabela)
        .select()
        .eq('user_id', userId)
        .order('data', ascending: false);

    return (response as List)
        .map((e) => KartaZdrowia.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> usunWpis(String id) async {
    await _supabase.from(tabela).delete().eq('id', id);
  }
}
