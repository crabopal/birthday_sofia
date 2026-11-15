import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'controllers/game_controller.dart';
import 'models/game_state.dart';
import 'screens/demo_done_screen.dart';
import 'screens/editor/editor_home_screen.dart';
import 'screens/level_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wheel_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone + TV: allow portrait and landscape; layouts adapt per screen.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final controller = GameController();
  await controller.loadPack();

  runApp(SonyaBirthdayApp(controller: controller));
}

class SonyaBirthdayApp extends StatelessWidget {
  const SonyaBirthdayApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'С днем рождения, Соня',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: GameRoot(controller: controller),
    );
  }
}

/// Switches screens only when [GamePhase] changes, so lobby/wheel local
/// state is not wiped on every guest/answer update.
class GameRoot extends StatefulWidget {
  const GameRoot({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> with WidgetsBindingObserver {
  late GamePhase _phase;

  @override
  void initState() {
    super.initState();
    _phase = widget.controller.snapshot.phase;
    widget.controller.addListener(_onControllerTick);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant GameRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
      _phase = widget.controller.snapshot.phase;
    }
  }

  void _onControllerTick() {
    final next = widget.controller.snapshot.phase;
    if (next != _phase && mounted) {
      setState(() => _phase = next);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        widget.controller.music.pauseForLifecycle();
        widget.controller.voice.stopAll();
      case AppLifecycleState.resumed:
        widget.controller.music.resumeAfterLifecycle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case GamePhase.splash:
        return SplashScreen(
          onStart: widget.controller.goToLobby,
          onReadyMusic: widget.controller.ensureMusic,
          onEditor: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    EditorHomeScreen(controller: widget.controller),
              ),
            );
          },
        );
      case GamePhase.lobby:
        return LobbyScreen(controller: widget.controller);
      case GamePhase.progress:
        return ProgressScreen(controller: widget.controller);
      case GamePhase.wheel:
        return WheelScreen(controller: widget.controller);
      case GamePhase.level:
        return LevelScreen(
          key: ValueKey('level-${widget.controller.snapshot.currentLevelIndex}'),
          controller: widget.controller,
        );
      case GamePhase.demoDone:
        return DemoDoneScreen(controller: widget.controller);
    }
  }
}
