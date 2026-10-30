import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

/// Carrega os registros e trata espera, erro e histórico vazio antes de
/// mostrar o mapa.
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = const [];
  MapCachingProvider? _cache;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // O cache é preparado antes de qualquer tile ser carregado.
      final cache = _cache ?? await CacheMapa.preparar();
      final itens = await _repositorio.listarRecentes();
      if (!mounted) return;
      setState(() {
        _cache = cache;
        _localizacoes = itens;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o mapa: $erro';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    final cache = _cache;
    final erro = _erro;

    if (_carregando && (cache == null || _localizacoes.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (erro != null) {
      return _Mensagem(
        icone: Icons.error_outline,
        texto: erro,
        rotuloBotao: 'Tentar novamente',
        aoPressionar: _carregar,
      );
    }
    if (cache == null || _localizacoes.isEmpty) {
      return _Mensagem(
        icone: Icons.location_off,
        texto: 'Nenhuma localização registrada ainda.',
        rotuloBotao: 'Atualizar',
        aoPressionar: _carregar,
      );
    }

    return Stack(
      children: [
        MapaLocalizacoes(localizacoes: _localizacoes, cache: cache),
        if (_carregando)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.icone,
    required this.texto,
    required this.rotuloBotao,
    required this.aoPressionar,
  });

  final IconData icone;
  final String texto;
  final String rotuloBotao;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48),
            const SizedBox(height: 16),
            Text(texto, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: aoPressionar, child: Text(rotuloBotao)),
          ],
        ),
      ),
    );
  }
}
