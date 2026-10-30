import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre e mantém a conexão com o banco `localizacoes.db`.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  /// Instância única: todas as camadas reutilizam a mesma conexão.
  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const nomeArquivo = 'localizacoes.db';
  static const tabela = 'localizacoes';
  static const _versao = 1;

  Future<Database>? _abertura;

  /// Retorna a conexão aberta. Se a abertura falhar, o erro é repassado e a
  /// próxima chamada tenta abrir o banco novamente.
  Future<Database> get database async {
    _abertura ??= _abrir();
    try {
      return await _abertura!;
    } catch (_) {
      _abertura = null;
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final caminho = p.join(await getDatabasesPath(), nomeArquivo);
    return openDatabase(caminho, version: _versao, onCreate: _criarTabelas);
  }

  Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE $tabela (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        precisao REAL NOT NULL,
        instante TEXT NOT NULL
      )
    ''');
  }
}
