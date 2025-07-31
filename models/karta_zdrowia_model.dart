class KartaZdrowia {
  final String? id;
  final String userId;
  final DateTime data;
  final double? waga;
  final int? cisnienieSkurczowe;
  final int? cisnienieRozkurczowe;
  final int? tetno;
  final double? cukier;
  final int? saturacja;

  KartaZdrowia({
    this.id,
    required this.userId,
    required this.data,
    this.waga,
    this.cisnienieSkurczowe,
    this.cisnienieRozkurczowe,
    this.tetno,
    this.cukier,
    this.saturacja,
  });

  factory KartaZdrowia.fromMap(Map<String, dynamic> map) {
    return KartaZdrowia(
      id: map['id'],
      userId: map['user_id'],
      data: DateTime.parse(map['data']),
      waga: (map['waga'] as num?)?.toDouble(),
      cisnienieSkurczowe: map['cisnienie_skurczowe'],
      cisnienieRozkurczowe: map['cisnienie_rozkurczowe'],
      tetno: map['tetno'],
      cukier: (map['cukier'] as num?)?.toDouble(),
      saturacja: map['saturacja'],
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'data': data.toIso8601String(),
      'waga': waga,
      'cisnienie_skurczowe': cisnienieSkurczowe,
      'cisnienie_rozkurczowe': cisnienieRozkurczowe,
      'tetno': tetno,
      'cukier': cukier,
      'saturacja': saturacja,
    };
  }
}
