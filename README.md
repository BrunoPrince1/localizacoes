# Localizações — Coleta e visualização de localizações

Atividade 1 de **Programação para Dispositivos Móveis II** — Prof. Arley — FATEC Jacareí (DSM).

## Integrantes

- André Luis Alves Ramos Junior — RA 2581392423044
- _(nome da dupla, se houver)_

## O que o app faz

- **Coleta** a posição do aparelho por um *stream* do `geolocator` (alta precisão, intervalo solicitado de 20 s), rodando em **serviço em primeiro plano** no Android, com notificação fixa enquanto a coleta está ativa. A coleta continua ao trocar de tela e ao minimizar o app.
- **Salva** cada posição no SQLite (`localizacoes.db`, tabela `localizacoes`), com o instante em UTC no formato ISO 8601.
- **Histórico** com as últimas 100 localizações (mais recente primeiro), atualização por botão ou "puxar para baixo" e exclusão de todo o histórico com confirmação.
- **Mapa** do OpenStreetMap com um marcador por posição, a mais recente em vermelho, botão para enquadrar todos os pontos e botão para atualizar. Os tiles ficam em cache numa pasta privada do app.
- **Ícone próprio** (adaptativo no Android 8+), com a imagem original em `assets/icons/localizacoes.png`.

## Estrutura

```
lib/
├── main.dart                         # inicializa o Flutter
├── app.dart                          # MaterialApp e tela inicial
└── features/localizacoes/
    ├── models/localizacao.dart       # registro tipado + toMap/fromMap
    ├── data/
    │   ├── database/banco_localizacoes.dart        # abre/cria o banco, reutiliza a conexão
    │   └── repositories/repositorio_localizacoes.dart  # inserir, listar, excluir
    ├── services/
    │   ├── servico_localizacao.dart  # GPS, permissões, stream, configurações
    │   └── cache_mapa.dart           # pasta privada para o cache dos tiles
    └── presentation/
        ├── screens/ (tela_coleta, tela_localizacoes, tela_mapa)
        └── widgets/ (item_localizacao, mapa_localizacoes)
```

## Como executar

```bash
flutter pub get
flutter run
```

Na primeira coleta o app pede a permissão de localização e, no Android 13+, a de notificações (para a notificação da coleta aparecer).

## Atribuição do mapa

Dados do mapa © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), usados conforme a [política de uso de tiles](https://operations.osmfoundation.org/policies/tiles/). O app se identifica pelo `userAgentPackageName` e mantém os tiles em cache respeitando a validade informada pelo servidor.

## Privacidade

O banco com as coordenadas fica só no aparelho. O `.gitignore` bloqueia arquivos `*.db` para que nenhuma coordenada pessoal vá para o repositório.
