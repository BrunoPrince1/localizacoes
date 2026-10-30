import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/localizacao.dart';

/// Exibe os dados de uma localização. Usado na lista, na tela de coleta e no
/// detalhe de um marcador do mapa.
class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.maisRecente = false,
  });

  final Localizacao localizacao;

  /// Destaca o registro mais recente em vermelho, como no mapa.
  final bool maisRecente;

  static final _formatoData = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final dataLocal = _formatoData.format(localizacao.instante.toLocal());
    final latitude = localizacao.latitude.toStringAsFixed(6);
    final longitude = localizacao.longitude.toStringAsFixed(6);
    final precisao = localizacao.precisao.toStringAsFixed(1);

    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: maisRecente ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(dataLocal),
      subtitle: Text(
        'Lat: $latitude  Lon: $longitude\nPrecisão: ± $precisao m',
      ),
      isThreeLine: true,
    );
  }
}
