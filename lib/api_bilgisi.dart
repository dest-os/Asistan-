import 'dart:convert';

class ApiBilgisi {
  final String id;
  final String apiAdresi;
  final String firmaAdi;

  ApiBilgisi({
    this.id = 'default_id',
    required this.apiAdresi,
    this.firmaAdi = 'Varsayılan Firma',
  });

  ApiBilgisi copyWith({
    String? id,
    String? apiAdresi,
    String? firmaAdi,
  }) {
    return ApiBilgisi(
      id: id ?? this.id,
      apiAdresi: apiAdresi ?? this.apiAdresi,
      firmaAdi: firmaAdi ?? this.firmaAdi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'apiAdresi': apiAdresi,
      'firmaAdi': firmaAdi,
    };
  }

  factory ApiBilgisi.fromMap(Map<String, dynamic> map) {
    return ApiBilgisi(
      id: map['id'] as String? ?? 'default_id',
      apiAdresi: map['apiAdresi'] as String? ?? '',
      firmaAdi: map['firmaAdi'] as String? ?? 'Varsayılan Firma',
    );
  }

  String toJson() => json.encode(toMap());

  factory ApiBilgisi.fromJson(String source) =>
      ApiBilgisi.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ApiBilgisi(id: $id, apiAdresi: $apiAdresi, firmaAdi: $firmaAdi)';

  @override
  bool operator ==(covariant ApiBilgisi other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.apiAdresi == apiAdresi &&
        other.firmaAdi == firmaAdi;
  }

  @override
  int get hashCode => id.hashCode ^ apiAdresi.hashCode ^ firmaAdi.hashCode;
}
