import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../theme/app_theme.dart';
import '../wheel/wheel_widget.dart';
import '../widgets/pixel_scaffold.dart';
import '../widgets/robocar_avatar.dart';
import '../widgets/tv_button.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final ValueNotifier<double> _turns = ValueNotifier(0);
  bool _spinning = false;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _anim.dispose();
    _turns.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _winner = null;
    });

    final result = await widget.controller.prepareSpin();
    final names = widget.controller.wheelNames;
    await animateWheelToIndex(
      controller: _anim,
      turns: _turns,
      targetIndex: result.index,
      segmentCount: names.length,
    );
    widget.controller.finishSpin(result.winner);
    setState(() {
      _winner = result.winner;
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.controller.wheelNames.isNotEmpty
        ? widget.controller.wheelNames
        : widget.controller.snapshot.guests;

    return PixelScaffold(
      title: 'КТО ИГРАЕТ?',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: ValueListenableBuilder<double>(
                valueListenable: _turns,
                builder: (context, turns, _) {
                  return ParticipantWheel(
                    names: names,
                    labels: [
                      for (final n in names)
                        widget.controller.characterForGuest(n)?.displayNameRu ??
                            n,
                    ],
                    rotationTurns: turns,
                    winner: _winner == null
                        ? null
                        : widget.controller.labelForGuest(_winner!),
                    winnerAvatar:
                        widget.controller.characterForGuest(_winner),
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PixelPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_winner == null)
                          TvButton(
                            label: _spinning ? 'КРУТИТСЯ...' : 'КРУТИТЬ',
                            autofocus: true,
                            enabled: !_spinning,
                            onPressed: _spinning ? null : _spin,
                          )
                        else ...[
                          Row(
                            children: [
                              RobocarAvatar(
                                character: widget.controller
                                    .characterForGuest(_winner),
                                size: 56,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ход:\n${widget.controller.labelForGuest(_winner!)}',
                                  style: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    fontSize: 12,
                                    color: PoliColors.robocarRed,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TvButton(
                            label: 'К УРОВНЮ',
                            autofocus: true,
                            onPressed: () => widget.controller.openLevel(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
