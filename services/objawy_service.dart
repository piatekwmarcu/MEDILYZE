import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/objaw_model.dart';

class ObjawyService {
  final _supabase = Supabase.instance.client;
  final String tabela = 'objawy';

  Future<void> dodajObjaw(Objaw objaw) async {
    try {
      await _supabase
          .from(tabela)
          .insert(objaw.toMap());
    } catch (e) {
      print("Błąd przy dodawaniu objawu: $e");
      rethrow;
    }
  }

  Future<List<Objaw>> pobierzObjawy(String userId) async {
    try {
      final response = await _supabase
          .from(tabela)
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false);

      return (response as List)
          .map((e) => Objaw.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("Błąd przy pobieraniu objawów: $e");
      return [];
    }
  }

  /// (opcjonalnie) Usuwanie wpisu objawu
  Future<void> usunObjaw(String id) async {
    try {
      await _supabase
          .from(tabela)
          .delete()
          .eq('id', id);
    } catch (e) {
      print("Błąd przy usuwaniu objawu: $e");
      rethrow;
    }
  }

  Future<void> edytujObjaw(Objaw objaw) async {
    if (objaw.id == null) return; // brak ID → nie edytujemy
    try {
      await _supabase
          .from(tabela)
          .update(objaw.toMap())
          .eq('id', objaw.id!);
    } catch (e) {
      print("Błąd edycji objawu: $e");
      rethrow;
    }
  }
}
