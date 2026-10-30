import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/localizacao.dart';

/// Resultado da verificação feita antes de iniciar a coleta.
enum StatusPermissao {
  concedida,
  servicoDesabilitado,
  negada,
  negadaPermanentemente,
}

/// Encapsula o GPS, as permissões e o stream de posições.
class ServicoLocalizacao {
  /// Intervalo solicitado ao sistema. O Android pode entregar com variação.
  static const intervalo = Duration(seconds: 20);

  /// Verifica se o GPS está ligado e solicita a permissão quando necessário.
  Future<StatusPermissao> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return StatusPermissao.servicoDesabilitado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    return switch (permissao) {
      LocationPermission.always ||
      LocationPermission.whileInUse => StatusPermissao.concedida,
      LocationPermission.deniedForever => StatusPermissao.negadaPermanentemente,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => StatusPermissao.negada,
    };
  }

  /// No Android 13+ a notificação do serviço em primeiro plano só aparece na
  /// gaveta se esta permissão for concedida. A coleta funciona mesmo sem ela.
  Future<void> solicitarPermissaoNotificacao() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Permission.notification.request();
    } catch (_) {
      // Falha ao pedir a permissão de notificação não impede a coleta.
    }
  }

  /// Stream contínuo de posições convertidas em [Localizacao].
  Stream<Localizacao> streamLocalizacoes() {
    return Geolocator.getPositionStream(
      locationSettings: _configuracoes(),
    ).map(_paraLocalizacao);
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();

  LocationSettings _configuracoes() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // O ForegroundNotificationConfig faz o geolocator rodar a coleta em um
      // serviço em primeiro plano, com notificação fixa enquanto estiver ativa.
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: intervalo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'Registrando a posição do aparelho a cada 20 s.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  Localizacao _paraLocalizacao(Position posicao) {
    return Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );
  }
}
