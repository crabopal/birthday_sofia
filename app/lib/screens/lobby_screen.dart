import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_scaffold.dart';
import '../widgets/robocar_avatar.dart';
import '../widgets/tv_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _addFocus = FocusNode();
  final _startFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onGameChanged);
    _nameController.dispose();
    _nameFocus.dispose();
    _addFocus.dispose();
    _startFocus.dispose();
    super.dispose();
  }

  bool get _canStart =>
      widget.controller.snapshot.guests.length >= 2 &&
      widget.controller.playableLevels.isNotEmpty;

  void _add() {
    widget.controller.addGuest(_nameController.text);
    _nameController.clear();
    // Leave the text field so D-pad / taps hit action buttons again.
    _nameFocus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_canStart) {
        _startFocus.requestFocus();
      } else {
        _addFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guests = List<String>.from(widget.controller.snapshot.guests);

    return PixelScaffold(
      title: 'ГОСТИ',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: PixelPanel(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Введите имя и нажмите Добавить\n(экранная клавиатура пульта)',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 10,
                          height: 1.7,
                          color: PoliColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                          color: PoliColors.ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Имя гостя',
                        ),
                      ),
                      const SizedBox(height: 14),
                      FocusTraversalGroup(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            TvButton(
                              label: 'ДОБАВИТЬ',
                              autofocus: true,
                              focusNode: _addFocus,
                              onPressed: _add,
                            ),
                            TvButton(
                              label: 'НАЧАТЬ',
                              primary: true,
                              focusNode: _startFocus,
                              enabled: _canStart,
                              onPressed: _canStart
                                  ? () => widget.controller.startGame()
                                  : null,
                            ),
                            TvButton(
                              label: 'ДЕМО ГОСТИ',
                              primary: false,
                              onPressed: () {
                                for (final name in const [
                                  'Аня',
                                  'Боря',
                                  'Вика',
                                ]) {
                                  widget.controller.addGuest(name);
                                }
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) _startFocus.requestFocus();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        () {
                          final ready =
                              widget.controller.playableLevels.length;
                          if (guests.length < 2) {
                            return 'Нужно минимум 2 гостя';
                          }
                          if (ready == 0) {
                            return 'Нет уровней «в игре» — откройте РЕДАКТОР';
                          }
                          return 'Готово: ${guests.length} · уровней: $ready';
                        }(),
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          color: PoliColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: PixelPanel(
                color: PoliColors.softWhite,
                child: guests.isEmpty
                    ? const Center(
                        child: Text(
                          'Список пуст',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 12,
                            color: PoliColors.inkSoft,
                          ),
                        ),
                      )
                    // Guest rows must not steal D-pad focus from buttons.
                    : ExcludeFocus(
                        child: ListView.separated(
                          itemCount: guests.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final name = guests[index];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  widget.controller.removeGuest(name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: PoliColors.robocarRed,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    RobocarAvatar(
                                      character: widget.controller
                                          .characterForGuest(name),
                                      size: 48,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.controller
                                            .labelForGuest(name),
                                        style: const TextStyle(
                                          fontFamily: 'PressStart2P',
                                          fontSize: 10,
                                          height: 1.4,
                                          color: PoliColors.ink,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '×',
                                      style: TextStyle(
                                        fontFamily: 'PressStart2P',
                                        fontSize: 14,
                                        color: PoliColors.robocarRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
