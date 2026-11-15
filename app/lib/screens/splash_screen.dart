import 'package:material_ui/material_ui.dart';

import '../services/app_updater.dart';
import '../theme/app_theme.dart';
import '../widgets/scanlines.dart';
import '../widgets/tv_button.dart';

enum _SplashGate {
  checking,
  downloading,
  installing,
  ready,
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onStart,
    required this.onEditor,
  });

  final VoidCallback onStart;
  final VoidCallback onEditor;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _updater = AppUpdater();
  _SplashGate _gate = _SplashGate.checking;
  String _status = 'Проверка обновлений…';
  double _progress = 0;
  UpdateManifest? _pending;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runUpdateFlow();
  }

  Future<void> _runUpdateFlow() async {
    setState(() {
      _gate = _SplashGate.checking;
      _status = 'Проверка обновлений…';
      _error = null;
    });

    final check = await _updater.check();
    if (!mounted) return;

    if (check.result != UpdateCheckResult.available || check.manifest == null) {
      setState(() {
        _gate = _SplashGate.ready;
        _status = check.result == UpdateCheckResult.upToDate
            ? 'Актуальная версия'
            : 'Обновление пропущено';
      });
      return;
    }

    final manifest = check.manifest!;
    setState(() {
      _pending = manifest;
      _gate = _SplashGate.downloading;
      _status =
          'Скачивание ${manifest.versionName} (${manifest.versionCode})…';
      _progress = 0;
    });

    try {
      await _updater.downloadAndInstall(
        manifest,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            _status = 'Скачивание ${(p * 100).clamp(0, 100).toStringAsFixed(0)}%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _gate = _SplashGate.installing;
        _status =
            'Установщик открыт — подтвердите установку пультом.\nПосле установки откройте игру снова.';
      });
    } catch (e) {
      debugPrint('OTA failed: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось обновить. Можно играть в текущей версии.';
        _gate = _SplashGate.ready;
        _status = 'Обновление не установлено';
      });
    }
  }

  Future<void> _retryInstall() async {
    final manifest = _pending;
    if (manifest == null) {
      await _runUpdateFlow();
      return;
    }
    setState(() {
      _gate = _SplashGate.downloading;
      _error = null;
      _progress = 0;
      _status = 'Повторная загрузка…';
    });
    try {
      await _updater.downloadAndInstall(
        manifest,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            _status = 'Скачивание ${(p * 100).clamp(0, 100).toStringAsFixed(0)}%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _gate = _SplashGate.installing;
        _status =
            'Установщик открыт — подтвердите установку пультом.\nПосле установки откройте игру снова.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _gate = _SplashGate.ready;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _gate == _SplashGate.checking ||
        _gate == _SplashGate.downloading ||
        _gate == _SplashGate.installing;

    return PixelScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'С ДНЕМ\nРОЖДЕНИЯ,\nСОНЯ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 36,
                    height: 1.55,
                    color: PoliColors.beaconYellow,
                    shadows: [
                      Shadow(color: PoliColors.robocarRed, offset: Offset(3, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'пиксельная вечеринка · робокар ретро',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: PoliColors.steel.withValues(alpha: 0.95),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    height: 1.7,
                    color: PoliColors.rescueBlue,
                  ),
                ),
                if (_gate == _SplashGate.downloading) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 420,
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      color: PoliColors.beaconYellow,
                      backgroundColor: PoliColors.road,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      height: 1.6,
                      color: PoliColors.robocarRed,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                if (_gate == _SplashGate.ready)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TvButton(
                        label: 'СТАРТ',
                        autofocus: true,
                        onPressed: widget.onStart,
                      ),
                      const SizedBox(width: 20),
                      TvButton(
                        label: 'РЕДАКТОР',
                        primary: false,
                        onPressed: widget.onEditor,
                      ),
                      if (_pending != null) ...[
                        const SizedBox(width: 20),
                        TvButton(
                          label: 'ОБНОВИТЬ',
                          primary: false,
                          onPressed: _retryInstall,
                        ),
                      ],
                    ],
                  )
                else if (_gate == _SplashGate.installing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TvButton(
                        label: 'ПОВТОРИТЬ',
                        autofocus: true,
                        onPressed: _retryInstall,
                      ),
                      const SizedBox(width: 20),
                      TvButton(
                        label: 'ИГРАТЬ ТАК',
                        primary: false,
                        onPressed: () => setState(() => _gate = _SplashGate.ready),
                      ),
                    ],
                  )
                else if (busy)
                  const Text(
                    'Подождите…',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: PoliColors.steel,
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Пульт: стрелки · OK · Back',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 9,
                    color: PoliColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
