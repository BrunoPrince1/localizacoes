import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

/// Histórico com as últimas localizações e a opção de limpar tudo.
class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  /// Indica se a coleta continua ativa (usado no aviso da exclusão).
  final ValueNotifier<bool> coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = const [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Recarrega do banco. Não interfere na coleta, que roda em outra tela.
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _repositorio.listarRecentes();
      if (!mounted) return;
      setState(() {
        _localizacoes = itens;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o histórico: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _confirmarLimpeza() async {
    final aviso = StringBuffer(
      'Todos os registros serão excluídos, inclusive os anteriores aos '
      '${RepositorioLocalizacoes.limiteConsulta} exibidos. '
      'Esta operação é permanente.',
    );
    if (widget.coletaAtiva.value) {
      aviso.write(
        '\n\nA coleta está ativa: novos registros continuarão sendo salvos.',
      );
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(aviso.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      final excluidos = await _repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _mostrarMensagem('Histórico limpo ($excluidos registros excluídos).');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao limpar o histórico: $erro');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando ? null : _confirmarLimpeza,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    if (_carregando && _localizacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final erro = _erro;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _localizacoes.isEmpty ? 1 : _localizacoes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, indice) {
          if (_localizacoes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                erro ?? 'Nenhuma localização registrada.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ItemLocalizacao(
            localizacao: _localizacoes[indice],
            maisRecente: indice == 0,
          );
        },
      ),
    );
  }
}
