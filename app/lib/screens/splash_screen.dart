import 'package:material_ui/material_ui.dart';

import '../services/app_updater.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_scaffold.dart';
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
    this.onReadyMusic,
  });

  final VoidCallback onStart;
  final VoidCallback onEditor;
  final Future<void> Function()? onReadyMusic;

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
    widget.onReadyMusic?.call();
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
        switch (check.result) {
          case UpdateCheckResult.upToDate:
            _status =
                'Актуальная версия (${check.localVersionCode ?? '?'})';
            _error = null;
          case UpdateCheckResult.failed:
            _status = 'Не удалось проверить обновление';
            _error = check.message;
          case UpdateCheckResult.skipped:
            _status = 'Обновление пропущено';
            _error = check.message;
          case UpdateCheckResult.available:
            _status = 'Обновление недоступно';
            _error = check.message;
        }
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
            _status =
                'Скачивание ${(p * 100).clamp(0, 100).toStringAsFixed(0)}%';
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
            _status =
                'Скачивание ${(p * 100).clamp(0, 100).toStringAsFixed(0)}%';
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
      showCharacters: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _HeroChar('assets/images/chars/poli.jpg'),
                    SizedBox(width: 14),
                    _HeroChar('assets/images/chars/roy.jpg'),
                    SizedBox(width: 14),
                    _HeroChar('assets/images/chars/amber.jpg'),
                    SizedBox(width: 14),
                    _HeroChar('assets/images/chars/helly.jpg'),
                  ],
                ),
                const SizedBox(height: 18),
                PixelPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  child: Column(
                    children: [
                      const Text(
                        'С ДНЕМ РОЖДЕНИЯ,\nСОНЯ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 28,
                          height: 1.55,
                          color: PoliColors.robocarRed,
                          shadows: [
                            Shadow(
                              color: PoliColors.amberYellow,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'пиксельные спасатели · город робокаров',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          color: PoliColors.inkSoft.withValues(alpha: 0.95),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          height: 1.7,
                          color: PoliColors.hellyBlue,
                        ),
                      ),
                      if (_gate == _SplashGate.downloading) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 420,
                          child: LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 10,
                            color: PoliColors.robocarRed,
                            backgroundColor: PoliColors.panelDeep,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 8,
                            height: 1.6,
                            color: PoliColors.robocarRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (_gate == _SplashGate.ready)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TvButton(
                              label: 'СТАРТ',
                              autofocus: true,
                              onPressed: widget.onStart,
                            ),
                            const SizedBox(width: 16),
                            TvButton(
                              label: 'РЕДАКТОР',
                              primary: false,
                              onPressed: widget.onEditor,
                            ),
                            const SizedBox(width: 16),
                            TvButton(
                              label:
                                  _pending != null ? 'ОБНОВИТЬ' : 'ПРОВЕРИТЬ',
                              primary: false,
                              onPressed: _pending != null
                                  ? _retryInstall
                                  : _runUpdateFlow,
                            ),
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
                            const SizedBox(width: 16),
                            TvButton(
                              label: 'ИГРАТЬ ТАК',
                              primary: false,
                              onPressed: () =>
                                  setState(() => _gate = _SplashGate.ready),
                            ),
                          ],
                        )
                      else if (busy)
                        const Text(
                          'Подождите…',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 9,
                            color: PoliColors.inkSoft,
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'Пульт: стрелки · OK · Back',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 8,
                          color: PoliColors.inkSoft,
                        ),
                      ),
                    ],
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

class _HeroChar extends StatelessWidget {
  const _HeroChar(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: PoliColors.robocarRed.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: PoliColors.panelDeep,
          child:
              Icon(Icons.directions_car, color: PoliColors.robocarRed, size: 48),
        ),
      ),
    );
  }
}
