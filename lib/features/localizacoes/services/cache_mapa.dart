import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Prepara o cache local das imagens (tiles) do mapa.
///
/// Os tiles ficam numa pasta privada do aplicativo (Application Support), e
/// não na pasta de cache temporário, que o sistema pode limpar a qualquer
/// momento. O cache embutido do flutter_map respeita os cabeçalhos HTTP de
/// validade, como exige a política de uso dos tiles do OpenStreetMap.
class CacheMapa {
  CacheMapa._();

  static const _nomePasta = 'cache_mapa';
  static const _tamanhoMaximo = 200 * 1024 * 1024; // 200 MB

  static BuiltInMapCachingProvider? _provedor;

  /// Cria a pasta (se preciso) e retorna o provedor de cache configurado.
  /// Deve ser chamado antes de exibir o mapa.
  static Future<BuiltInMapCachingProvider> preparar() async {
    final existente = _provedor;
    if (existente != null) return existente;

    final base = await getApplicationSupportDirectory();
    final pasta = Directory(p.join(base.path, _nomePasta));
    await pasta.create(recursive: true);

    return _provedor = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: pasta.path,
      maxCacheSize: _tamanhoMaximo,
    );
  }
}
