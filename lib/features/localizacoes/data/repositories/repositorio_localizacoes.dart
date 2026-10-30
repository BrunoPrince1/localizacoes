import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

/// Centraliza o acesso aos registros de localização.
class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
    : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  /// Quantidade de registros exibidos na lista e no mapa.
  static const limiteConsulta = 100;

  /// Insere um registro e retorna o id gerado.
  Future<int> inserir(Localizacao localizacao) async {
    final db = await _banco.database;
    return db.insert(BancoLocalizacoes.tabela, localizacao.toMap());
  }

  /// Retorna os registros mais recentes primeiro. O limite vale só para a
  /// consulta: nenhum registro antigo é apagado.
  Future<List<Localizacao>> listarRecentes({
    int limite = limiteConsulta,
  }) async {
    final db = await _banco.database;
    final linhas = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  /// Remove todas as linhas da tabela, mantendo a estrutura e o arquivo do
  /// banco. Retorna a quantidade de registros excluídos.
  Future<int> excluirTodas() async {
    final db = await _banco.database;
    return db.delete(BancoLocalizacoes.tabela);
  }
}
