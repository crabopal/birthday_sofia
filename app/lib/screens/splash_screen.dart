import 'package:material_ui/material_ui.dart';

import '../services/app_updater.dart';
import '../theme/app_theme.dart';
import '../widgets/char_portrait_frame.dart';
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
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 520 || size.width < 700;
    final heroSize = compact ? 56.0 : 92.0;
    final titleSize = compact ? 18.0 : 28.0;

    return PixelScaffold(
      showCharacters: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 28,
              vertical: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: compact ? 8 : 14,
                  children: [
                    _HeroChar('assets/images/chars/poli.jpg', size: heroSize),
                    _HeroChar('assets/images/chars/roy.jpg', size: heroSize),
                    _HeroChar('assets/images/chars/amber.jpg', size: heroSize),
                    _HeroChar('assets/images/chars/helly.jpg', size: heroSize),
                  ],
                ),
                SizedBox(height: compact ? 10 : 18),
                PixelPanel(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 28,
                    vertical: compact ? 14 : 22,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'С ДНЕМ РОЖДЕНИЯ,\nСОНЯ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: titleSize,
                          height: 1.55,
                          color: PoliColors.robocarRed,
                          shadows: const [
                            Shadow(
                              color: PoliColors.amberYellow,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 14),
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
                      SizedBox(height: compact ? 10 : 18),
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
                          width: compact ? 240 : 420,
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
                      SizedBox(height: compact ? 14 : 22),
                      if (_gate == _SplashGate.ready)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TvButton(
                              label: 'СТАРТ',
                              autofocus: true,
                              compact: compact,
                              onPressed: widget.onStart,
                            ),
                            TvButton(
                              label: 'РЕДАКТОР',
                              primary: false,
                              compact: compact,
                              onPressed: widget.onEditor,
                            ),
                            TvButton(
                              label:
                                  _pending != null ? 'ОБНОВИТЬ' : 'ПРОВЕРИТЬ',
                              primary: false,
                              compact: compact,
                              onPressed: _pending != null
                                  ? _retryInstall
                                  : _runUpdateFlow,
                            ),
                          ],
                        )
                      else if (_gate == _SplashGate.installing)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TvButton(
                              label: 'ПОВТОРИТЬ',
                              autofocus: true,
                              compact: compact,
                              onPressed: _retryInstall,
                            ),
                            TvButton(
                              label: 'ИГРАТЬ ТАК',
                              primary: false,
                              compact: compact,
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
                        'Пульт / касание',
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
  const _HeroChar(this.path, {this.size = 92});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CharPortraitFrame(
      size: size,
      borderWidth: 4,
      radiusFactor: 0.17,
      shadowColor: PoliColors.robocarRed,
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
