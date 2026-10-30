import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

/// Tela inicial: controla a coleta e dá acesso ao histórico e ao mapa.
///
/// A assinatura do stream pertence a esta tela. Como ela é a raiz da
/// navegação, continua viva enquanto o usuário abre as outras telas, e a
/// coleta segue ativa até o botão "Parar coleta".
class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _servico = ServicoLocalizacao();
  final _repositorio = RepositorioLocalizacoes();

  /// Compartilhado com a tela de histórico para o aviso da exclusão.
  final _coletando = ValueNotifier<bool>(false);

  StreamSubscription<void>? _assinatura;
  bool _processando = false;
  int _salvasNestaSessao = 0;
  Localizacao? _ultima;

  @override
  void dispose() {
    _assinatura?.cancel();
    _coletando.dispose();
    super.dispose();
  }

  Future<void> _iniciarColeta() async {
    // Impede assinaturas duplicadas (inclusive com toques repetidos).
    if (_assinatura != null || _processando) return;
    setState(() => _processando = true);

    try {
      final status = await _servico.verificarPermissao();
      if (!mounted) return;
      if (status != StatusPermissao.concedida) {
        await _orientarUsuario(status);
        return;
      }

      await _servico.solicitarPermissaoNotificacao();
      if (!mounted) return;

      // asyncMap só repassa a próxima posição depois que a gravação anterior
      // terminar, evitando gravações sobrepostas.
      _assinatura = _servico
          .streamLocalizacoes()
          .asyncMap(_salvar)
          .listen((_) {}, onError: _tratarErroStream);

      setState(() {
        _coletando.value = true;
        _salvasNestaSessao = 0;
      });
      _mostrarMensagem('Coleta iniciada.');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível iniciar a coleta: $erro');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (assinatura == null || _processando) return;
    setState(() => _processando = true);

    _assinatura = null;
    await assinatura.cancel();
    _coletando.value = false;

    if (!mounted) return;
    setState(() => _processando = false);
    _mostrarMensagem('Coleta interrompida.');
  }

  Future<void> _salvar(Localizacao localizacao) async {
    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _ultima = localizacao;
        _salvasNestaSessao++;
      });
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Falha ao salvar a localização: $erro');
    }
  }

  void _tratarErroStream(Object erro) {
    // Erros do stream (ex.: GPS desligado durante a coleta) encerram a coleta.
    _assinatura?.cancel();
    _assinatura = null;
    _coletando.value = false;
    if (!mounted) return;
    setState(() {});

    final mensagem = erro is LocationServiceDisabledException
        ? 'O GPS foi desligado. A coleta foi interrompida.'
        : erro is PermissionDeniedException
        ? 'A permissão de localização foi revogada. A coleta foi interrompida.'
        : 'Erro na coleta de localização: $erro';
    _mostrarMensagem(mensagem);
  }

  Future<void> _orientarUsuario(StatusPermissao status) async {
    switch (status) {
      case StatusPermissao.servicoDesabilitado:
        await _mostrarDialogo(
          titulo: 'Localização desligada',
          mensagem:
              'Ative o serviço de localização (GPS) do aparelho para iniciar '
              'a coleta.',
          rotuloAcao: 'Abrir configurações',
          acao: _servico.abrirConfiguracoesLocalizacao,
        );
      case StatusPermissao.negadaPermanentemente:
        await _mostrarDialogo(
          titulo: 'Permissão bloqueada',
          mensagem:
              'A permissão de localização foi negada permanentemente. Abra as '
              'configurações do aplicativo e permita o acesso à localização.',
          rotuloAcao: 'Abrir configurações',
          acao: _servico.abrirConfiguracoesApp,
        );
      case StatusPermissao.negada:
        _mostrarMensagem(
          'Permissão de localização negada. Toque em "Iniciar coleta" e '
          'permita o acesso para continuar.',
        );
      case StatusPermissao.concedida:
        break;
    }
  }

  Future<void> _mostrarDialogo({
    required String titulo,
    required String mensagem,
    required String rotuloAcao,
    required Future<bool> Function() acao,
  }) async {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(rotuloAcao),
          ),
        ],
      ),
    );
    if (abrir == true) await acao();
  }

  Future<void> _abrirConfiguracoesPermissao() async {
    final abriu = await _servico.abrirConfiguracoesApp();
    if (!mounted || abriu) return;
    _mostrarMensagem('Não foi possível abrir as configurações.');
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final coletando = _coletando.value;
    final ultima = _ultima;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localizações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(
                      coletando ? Icons.gps_fixed : Icons.gps_off,
                      color: coletando ? Colors.green : Colors.grey,
                    ),
                    title: Text(coletando ? 'Coleta ativa' : 'Coleta parada'),
                    subtitle: Text(
                      coletando
                          ? 'Registros salvos nesta coleta: $_salvasNestaSessao'
                          : 'Intervalo solicitado: '
                                '${ServicoLocalizacao.intervalo.inSeconds} s',
                    ),
                  ),
                  if (ultima != null) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Última posição salva'),
                    ),
                    ItemLocalizacao(localizacao: ultima, maisRecente: true),
                  ],
                ],
              ),
            ),
          ),
          if (_processando) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: !coletando && !_processando
                      ? _iniciarColeta
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar coleta'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: coletando && !_processando ? _pararColeta : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Parar coleta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _abrir(TelaLocalizacoes(coletaAtiva: _coletando)),
            icon: const Icon(Icons.history),
            label: const Text('Consultar histórico'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _abrir(const TelaMapa()),
            icon: const Icon(Icons.map),
            label: const Text('Ver mapa'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _abrirConfiguracoesPermissao,
            icon: const Icon(Icons.settings),
            label: const Text('Configurações de permissão'),
          ),
        ],
      ),
    );
  }
}
