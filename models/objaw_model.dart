class Objaw {
  final String? id; // może być null, bo Supabase samo wygeneruje UUID
  final String userId;
  final DateTime data;
  final String samopoczucie; // 😀 / 😐 / 😣
  final String notatka;

  Objaw({
    this.id,
    required this.userId,
    required this.data,
    required this.samopoczucie,
    required this.notatka,
  });

  factory Objaw.fromMap(Map<String, dynamic> map) {
    return Objaw(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      data: DateTime.parse(map['data'] as String),
      samopoczucie: map['samopoczucie'] as String,
      notatka: map['notatka'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'data': data.toIso8601String(),
      'samopoczucie': samopoczucie,
      'notatka': notatka,
    };
  }
}
