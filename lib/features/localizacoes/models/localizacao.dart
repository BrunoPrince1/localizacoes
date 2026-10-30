/// Um registro de posição salvo no banco.
///
/// O [instante] é sempre mantido em UTC; a conversão para o horário local
/// fica a cargo da apresentação.
class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  final int? id;
  final double latitude;
  final double longitude;

  /// Precisão estimada, em metros.
  final double precisao;

  /// Data e hora em UTC.
  final DateTime instante;

  /// Cria o objeto a partir de uma linha retornada pelo SQLite.
  factory Localizacao.fromMap(Map<String, Object?> mapa) {
    return Localizacao(
      id: mapa['id'] as int?,
      latitude: (mapa['latitude'] as num).toDouble(),
      longitude: (mapa['longitude'] as num).toDouble(),
      precisao: (mapa['precisao'] as num).toDouble(),
      instante: DateTime.parse(mapa['instante'] as String).toUtc(),
    );
  }

  /// Converte para o mapa usado na gravação. O instante é salvo em ISO 8601 UTC.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }
}
