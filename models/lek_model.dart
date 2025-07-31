class Lek {
  final String id;
  final String userId;
  final String? lekId;
  final String nazwa;
  final String dawkowanie; // dawka ustawiona przez użytkownika
  final String? dzialaniaNiepozadane;
  final String pora;
  final int dniPrzyjmowania;
  final DateTime dataStart;
  final DateTime dataKoniec;
  final List<String> przyjete;
  final String? sklad; // z tabeli leki
  final String? zalecaneDawkowanie; // z tabeli leki
  final List<String> interakcje; // z tabeli interakcje
  final int iloscDziennie; // np. 2 = dwa razy dziennie
  final Map<String, int> przyjeteDziennie; // { "2025-07-28": 2 }

  Lek({
    required this.id,
    required this.userId,
    this.lekId,
    required this.nazwa,
    required this.dawkowanie,
    this.dzialaniaNiepozadane,
    required this.pora,
    required this.dniPrzyjmowania,
    required this.dataStart,
    required this.dataKoniec,
    required this.przyjete,
    this.sklad,
    this.zalecaneDawkowanie,
    this.interakcje = const [],
    this.iloscDziennie = 1,
    Map<String, int>? przyjeteDziennie,
  }) : przyjeteDziennie = przyjeteDziennie ?? {};

  factory Lek.fromMap(Map<String, dynamic> map) {
    return Lek(
      id: map['id'],
      userId: map['user_id'],
      lekId: map['lek_id'],
      nazwa: map['nazwa'],
      dawkowanie: map['dawkowanie'],
      dzialaniaNiepozadane: map['dzialania_niepozadane'],
      pora: map['pora'],
      dniPrzyjmowania: map['dni_przyjmowania'] ?? 0,
      dataStart: DateTime.parse(map['data_start']),
      dataKoniec: DateTime.parse(map['data_koniec']),
      przyjete: List<String>.from(map['przyjete'] ?? []),
      sklad: map['sklad'],
      zalecaneDawkowanie: map['zalecane_dawkowanie'],
      interakcje: List<String>.from(map['interakcje'] ?? []),
      iloscDziennie: map['ilosc_dziennie'] ?? 1,
      przyjeteDziennie: Map<String, int>.from(map['przyjete_dziennie'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lek_id': lekId,
      'nazwa': nazwa,
      'dawkowanie': dawkowanie,
      'dzialania_niepozadane': dzialaniaNiepozadane,
      'pora': pora,
      'dni_przyjmowania': dniPrzyjmowania,
      'data_start': dataStart.toIso8601String(),
      'data_koniec': dataKoniec.toIso8601String(),
      'przyjete': przyjete,
      'sklad': sklad,
      'zalecane_dawkowanie': zalecaneDawkowanie,
      'interakcje': interakcje,
      'ilosc_dziennie': iloscDziennie,
      'przyjete_dziennie': przyjeteDziennie,
    };
  }

  Lek copyWith({
    String? nazwa,
    String? dawkowanie,
    String? pora,
    int? dniPrzyjmowania,
    DateTime? dataKoniec,
    String? sklad,
    String? zalecaneDawkowanie,
    List<String>? interakcje,
    int? iloscDziennie,
    Map<String, int>? przyjeteDziennie,
  }) {
    return Lek(
      id: id,
      userId: userId,
      lekId: lekId,
      nazwa: nazwa ?? this.nazwa,
      dawkowanie: dawkowanie ?? this.dawkowanie,
      dzialaniaNiepozadane: dzialaniaNiepozadane,
      pora: pora ?? this.pora,
      dniPrzyjmowania: dniPrzyjmowania ?? this.dniPrzyjmowania,
      dataStart: dataStart,
      dataKoniec: dataKoniec ?? this.dataKoniec,
      przyjete: przyjete,
      sklad: sklad ?? this.sklad,
      zalecaneDawkowanie: zalecaneDawkowanie ?? this.zalecaneDawkowanie,
      interakcje: interakcje ?? this.interakcje,
      iloscDziennie: iloscDziennie ?? this.iloscDziennie,
      przyjeteDziennie: przyjeteDziennie ?? this.przyjeteDziennie,
    );
  }
}
