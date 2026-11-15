import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/scanlines.dart';
import '../widgets/tv_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

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
    _focusNode.dispose();
    super.dispose();
  }

  void _add() {
    widget.controller.addGuest(_nameController.text);
    _nameController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final guests = List<String>.from(widget.controller.snapshot.guests);

    return PixelScaffold(
      title: 'ГОСТИ',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Введите имя и нажмите Добавить\n(экранная клавиатура пульта)',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      height: 1.7,
                      color: PoliColors.cream,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 14,
                      color: PoliColors.cream,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Имя гостя',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TvButton(label: 'ДОБАВИТЬ', onPressed: _add),
                      const SizedBox(width: 16),
                      TvButton(
                        label: 'НАЧАТЬ',
                        primary: true,
                        enabled: guests.length >= 2,
                        onPressed: guests.length >= 2
                            ? () => widget.controller.startGame()
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TvButton(
                    label: 'ДЕМО ГОСТИ',
                    primary: false,
                    onPressed: () {
                      for (final name in const ['Аня', 'Боря', 'Вика']) {
                        widget.controller.addGuest(name);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guests.length < 2
                        ? 'Нужно минимум 2 гостя'
                        : 'Готово: ${guests.length}',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: PoliColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PoliColors.road.withValues(alpha: 0.8),
                  border: Border.all(color: PoliColors.steel, width: 2),
                ),
                child: guests.isEmpty
                    ? const Center(
                        child: Text(
                          'Список пуст',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 12,
                            color: PoliColors.steel,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: guests.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final name = guests[index];
                          return Focus(
                            child: Builder(
                              builder: (context) {
                                final focused = Focus.of(context).hasFocus;
                                return InkWell(
                                  onTap: () =>
                                      widget.controller.removeGuest(name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: focused
                                            ? PoliColors.focus
                                            : PoliColors.robocarRed,
                                        width: focused ? 3 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontFamily: 'PressStart2P',
                                              fontSize: 12,
                                              color: PoliColors.cream,
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
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
