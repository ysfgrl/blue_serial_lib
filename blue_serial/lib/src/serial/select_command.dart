part of 'serial_monitor.dart';

class _SelectSavedCommand extends StatelessWidget {
  const _SelectSavedCommand._({required this.commands});

  final List<SerialCommand> commands;

  static Future<SerialCommand?> select(BuildContext context) async {
    final List<SerialCommand> commands;
    try {
      commands = await SavedCommandStore().load();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('serial.commandsLoadFailed'))),
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    return showDialog<SerialCommand>(
      context: context,
      builder: (_) => _SelectSavedCommand._(commands: commands),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('serial.savedCommands'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('global.close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            if (commands.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(context.tr('serial.noSavedCommands'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: min(360.0, MediaQuery.sizeOf(context).height * .6),
                  ),
                  child: ListView.builder(
                    key: const Key('command-picker-list'),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: commands.length,
                    itemBuilder: (_, index) {
                      final command = commands[index];
                      return CommandCard(
                        key: ValueKey('pick-command-${command.name}'),
                        command: command,
                        onTap: () => Navigator.of(context).pop<SerialCommand>(command),
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
