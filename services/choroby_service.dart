import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/choroba_model.dart';

class ChorobyService {
  final _supabase = Supabase.instance.client;

  Future<void> dodajChorobe(String nazwa, String opis) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('choroby').insert({
      'user_id': userId,
      'nazwa': nazwa,
      'opis': opis,
    });
  }

  Future<List<Choroba>> pobierzChoroby() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _supabase
        .from('choroby')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((data) => Choroba.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<void> usunChorobe(String id) async {
    await _supabase.from('choroby').delete().eq('id', id);
  }
}
