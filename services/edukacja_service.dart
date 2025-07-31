import 'package:supabase_flutter/supabase_flutter.dart';

class EdukacjaService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> pobierzArtykuly() async {
    final response = await _supabase
        .from('artykuly')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> pobierzQuizy(String artykulId) async {
    final response = await _supabase
        .from('quizy')
        .select()
        .eq('artykul_id', artykulId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
}
