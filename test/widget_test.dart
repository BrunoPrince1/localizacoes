import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

void main() {
  test('Localizacao converte para mapa e de volta mantendo o UTC', () {
    final original = Localizacao(
      latitude: -23.305123,
      longitude: -45.965432,
      precisao: 4.7,
      instante: DateTime.utc(2026, 11, 4, 13, 30, 15),
    );

    final mapa = original.toMap();
    expect(mapa.containsKey('id'), isFalse);
    expect(mapa['instante'], '2026-11-04T13:30:15.000Z');

    final convertida = Localizacao.fromMap({...mapa, 'id': 1});
    expect(convertida.id, 1);
    expect(convertida.latitude, original.latitude);
    expect(convertida.longitude, original.longitude);
    expect(convertida.precisao, original.precisao);
    expect(convertida.instante, original.instante);
    expect(convertida.instante.isUtc, isTrue);
  });
}
