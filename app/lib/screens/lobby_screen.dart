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
  final _listScroll = ScrollController();

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
    _listScroll.dispose();
    super.dispose();
  }

  bool get _canStart =>
      widget.controller.snapshot.guests.length >= 2 &&
      widget.controller.playableLevels.isNotEmpty;

  void _add() {
    widget.controller.addGuest(_nameController.text);
    _nameController.clear();
    _nameFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_canStart) {
        _startFocus.requestFocus();
      } else {
        _addFocus.requestFocus();
      }
      if (_listScroll.hasClients) {
        _listScroll.animateTo(
          _listScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addDemoGuests() {
    for (final name in const ['Аня', 'Боря', 'Вика']) {
      widget.controller.addGuest(name);
    }
    _nameFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final guests = List<String>.from(widget.controller.snapshot.guests);
    final size = MediaQuery.sizeOf(context);
    // Phone landscape is wide but short; stack vertically so buttons stay on screen.
    final useStacked = size.height < 520 || size.width < 700;

    return PixelScaffold(
      title: 'ГОСТИ',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useStacked ? 12 : 28,
          vertical: 4,
        ),
        child: useStacked
            ? _stackedLayout(guests)
            : _wideLayout(guests),
      ),
    );
  }

  Widget _controls({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          const Text(
            'Введите имя и нажмите Добавить',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 10,
              height: 1.7,
              color: PoliColors.ink,
            ),
          ),
        if (!compact) const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: compact ? 12 : 14,
            color: PoliColors.ink,
          ),
          decoration: const InputDecoration(
            hintText: 'Имя гостя',
            isDense: true,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        // Buttons stay in this fixed block — never scroll off-screen.
        FocusTraversalGroup(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TvButton(
                label: 'ДОБАВИТЬ',
                autofocus: true,
                focusNode: _addFocus,
                compact: compact,
                onPressed: _add,
              ),
              TvButton(
                label: 'НАЧАТЬ',
                primary: true,
                focusNode: _startFocus,
                compact: compact,
                enabled: _canStart,
                onPressed:
                    _canStart ? () => widget.controller.startGame() : null,
              ),
              TvButton(
                label: 'ДЕМО',
                primary: false,
                compact: compact,
                onPressed: _addDemoGuests,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          _statusText(),
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: compact ? 8 : 9,
            color: PoliColors.inkSoft,
          ),
        ),
      ],
    );
  }

  String _statusText() {
    final guests = widget.controller.snapshot.guests;
    final ready = widget.controller.playableLevels.length;
    if (guests.length < 2) return 'Нужно минимум 2 гостя';
    if (ready == 0) return 'Нет уровней «в игре» — откройте РЕДАКТОР';
    return 'Готово: ${guests.length} · уровней: $ready';
  }

  Widget _guestList({required bool compact}) {
    final guests = widget.controller.snapshot.guests;
    if (guests.isEmpty) {
      return const Center(
        child: Text(
          'Список пуст',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 12,
            color: PoliColors.inkSoft,
          ),
        ),
      );
    }
    return ExcludeFocus(
      child: ListView.separated(
        controller: _listScroll,
        itemCount: guests.length,
        separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 10),
        itemBuilder: (context, index) {
          final name = guests[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.controller.removeGuest(name),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 8 : 12,
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
                      character:
                          widget.controller.characterForGuest(name),
                      size: compact ? 36 : 48,
                    ),
                    SizedBox(width: compact ? 8 : 12),
                    Expanded(
                      child: Text(
                        widget.controller.labelForGuest(name),
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: compact ? 9 : 10,
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
            ),
          );
        },
      ),
    );
  }

  /// Phone / short landscape: controls on top, guest list below.
  Widget _stackedLayout(List<String> guests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelPanel(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: _controls(compact: true),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PixelPanel(
            padding: const EdgeInsets.all(10),
            color: PoliColors.softWhite,
            child: _guestList(compact: true),
          ),
        ),
      ],
    );
  }

  /// TV / wide: controls left, list right — buttons not inside a scroll view.
  Widget _wideLayout(List<String> guests) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: PixelPanel(
            child: _controls(compact: false),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: PixelPanel(
            color: PoliColors.softWhite,
            child: _guestList(compact: false),
          ),
        ),
      ],
    );
  }
}
