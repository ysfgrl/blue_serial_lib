part of 'setting.dart';

class _SavedCommandsSection extends StatefulWidget {
  const _SavedCommandsSection();

  @override
  State<_SavedCommandsSection> createState() => _SavedCommandsSectionState();
}

class _SavedCommandsSectionState extends State<_SavedCommandsSection> {
  final _store = SavedCommandStore();
  late Future<List<SerialCommand>> _commands = _store.load();

  void _reload() {
    setState(() {
      _commands = _store.load();
    });
  }

  void _setCommands(List<SerialCommand> commands) {
    if (!mounted) return;
    setState(() {
      _commands = Future.value(commands);
    });
  }

  void _showMessage(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(key))),
    );
  }

  Future<void> _addCommand() => _openCommandDialog();

  Future<void> _editCommand(SerialCommand command) =>
      _openCommandDialog(command: command);

  Future<void> _openCommandDialog({SerialCommand? command}) async {
    bool? saved;
    try {
      saved = await _EditSavedCommandDialog.show(context, command: command);
    } catch (_) {
      _showMessage('serial.commandSaveFailed');
    }
    if (!mounted || saved != true) return;
    _reload();
    _showMessage('serial.commandSaved');
  }

  Future<void> _deleteCommand(SerialCommand command) async {
    try {
      final confirmed = await _DeleteCommandDialog.show(context, command: command);
      if (!confirmed || !mounted) return;
      final commands = await _store.load();
      if (!mounted) return;
      final index = commands.indexWhere((item) => item.name == command.name);
      if (index < 0) {
        _setCommands(commands);
        _showMessage('serial.commandNotFound');
        return;
      }
      final updated = List<SerialCommand>.of(commands)..removeAt(index);
      await _store.save(updated);
      _setCommands(updated);
    } catch (_) {
      _showMessage('serial.commandDeleteFailed');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SerialCommand>>(
    future: _commands,
    builder: (context, snapshot) {
      final loading = snapshot.connectionState == ConnectionState.waiting;
      final commands = snapshot.data ?? const <SerialCommand>[];
      return Column(
        key: const Key('setting-saved-commands'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('serial.savedCommands'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.tr('global.refresh'),
                onPressed: loading ? null : _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                key: const Key('add-saved-command-button'),
                tooltip: context.tr('serial.saveCommand'),
                onPressed: loading ? null : _addCommand,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot.hasError)
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('serial.commandsLoadFailed')),
            )
          else if (commands.isEmpty)
            Text(context.tr('serial.noSavedCommands'))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 250,
              ),
              child: ListView(
                primary: false,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final command in commands)
                    CommandCard(
                      key: ValueKey('setting-command-${command.name}'),
                      command: command,
                      onEdit: () => _editCommand(command),
                      onDelete: () => _deleteCommand(command),
                    ),
                ],
              ),
            )
        ],
      );
    },
  );
}
