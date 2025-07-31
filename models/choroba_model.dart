class Choroba {
  final String id;
  final String nazwa;
  final String opis;

  Choroba({
    required this.id,
    required this.nazwa,
    required this.opis,
  });

  factory Choroba.fromMap(Map<String, dynamic> map) {
    return Choroba(
      id: map['id'],
      nazwa: map['nazwa'],
      opis: map['opis'] ?? '',
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'nazwa': nazwa,
      'opis': opis,
    };
  }
}
