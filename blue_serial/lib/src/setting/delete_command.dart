part of 'setting.dart';

class _DeleteCommandDialog extends StatelessWidget {
  const _DeleteCommandDialog._({required this.command});

  final SerialCommand command;

  static Future<bool> show(
    BuildContext context, {
    required SerialCommand command,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteCommandDialog._(command: command),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('global.delete'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(command.name),
              const SizedBox(height: 20),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop<bool>(false),
                    child: Text(context.tr('global.cancel')),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () => Navigator.of(context).pop<bool>(true),
                    child: Text(context.tr('global.delete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
