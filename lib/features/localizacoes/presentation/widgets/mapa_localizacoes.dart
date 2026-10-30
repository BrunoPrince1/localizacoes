import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa com a camada de ruas do OpenStreetMap e um marcador por localização.
///
/// A lista deve vir ordenada da mais recente para a mais antiga; o primeiro
/// item é destacado em vermelho.
class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
  });

  final List<Localizacao> localizacoes;
  final MapCachingProvider cache;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controlador = MapController();

  List<LatLng> get _pontos =>
      widget.localizacoes.map((l) => LatLng(l.latitude, l.longitude)).toList();

  CameraFit get _enquadramento => CameraFit.coordinates(
    coordinates: _pontos,
    padding: const EdgeInsets.all(56),
    maxZoom: 17,
  );

  @override
  void didUpdateWidget(covariant MapaLocalizacoes antigo) {
    super.didUpdateWidget(antigo);
    // Ao atualizar os registros, enquadra os novos pontos.
    if (antigo.localizacoes != widget.localizacoes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enquadrar() => _controlador.fitCamera(_enquadramento);

  void _mostrarDetalhes(Localizacao localizacao, bool maisRecente) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                maisRecente ? 'Localização mais recente' : 'Localização',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ItemLocalizacao(localizacao: localizacao, maisRecente: maisRecente),
          ],
        ),
      ),
    );
  }

  List<Marker> _marcadores() {
    final marcadores = <Marker>[];
    // Percorre da mais antiga para a mais recente, para que o marcador
    // vermelho seja desenhado por cima dos demais.
    for (var i = widget.localizacoes.length - 1; i >= 0; i--) {
      final localizacao = widget.localizacoes[i];
      final maisRecente = i == 0;
      marcadores.add(
        Marker(
          point: LatLng(localizacao.latitude, localizacao.longitude),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _mostrarDetalhes(localizacao, maisRecente),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: maisRecente ? Colors.red : Colors.blue.shade700,
            ),
          ),
        ),
      );
    }
    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCameraFit: _enquadramento,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.fatec.localizacoes',
              maxNativeZoom: 19,
              tileProvider: NetworkTileProvider(cachingProvider: widget.cache),
            ),
            MarkerLayer(markers: _marcadores()),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 56,
          child: FloatingActionButton.small(
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrar,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
