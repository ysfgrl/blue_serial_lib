import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/input_mode.dart';
import '../models/serial_command.dart';

class CommandCard extends StatelessWidget {
  const CommandCard({
    super.key,
    required this.command,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final SerialCommand command;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final preview = command.text.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 30,
          horizontalTitleGap: 10,
          titleAlignment: ListTileTitleAlignment.center,
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              command.mode == InputMode.hex
                  ? Icons.code_rounded : Icons.text_fields_rounded,
              color: colors.onPrimaryContainer,
              size: 16,
            ),
          ),
          title: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                command.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              _commandTags(context),
            ],
          ),
          subtitle: preview == command.name ? null : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'UbuntuMono', fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          trailing: _commandActions(context),
          onTap: onTap ?? () => _showDetails(context),
        ),
      ),
    );
  }

  Widget? _commandActions(BuildContext context) {
    if (onEdit == null && onDelete == null) return null;
    if (MediaQuery.sizeOf(context).width < 600) {
      return PopupMenuButton<String>(
        key: ValueKey('command-actions-${command.name}'),
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onSelected: (action) {
          if (action == 'edit') onEdit?.call();
          if (action == 'delete') onDelete?.call();
        },
        itemBuilder: (context) => [
          if (onEdit != null)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(context.tr('global.edit')),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 20,
                    color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text(context.tr('global.delete'), style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  )),
                ],
              ),
            ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            key: ValueKey('edit-command-${command.name}'),
            tooltip: context.tr('global.edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        if (onDelete != null)
          IconButton(
            key: ValueKey('delete-command-${command.name}'),
            tooltip: context.tr('global.delete'),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: 18,
              color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _commandTags(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      _tag(context, context.tr(command.mode == InputMode.ascii
          ? 'global.ascii' : 'global.hex')),
      _tag(context, context.tr('global.cr'), enabled: command.cr),
      _tag(context, context.tr('global.lf'), enabled: command.lf),
    ],
  );

  Widget _tag(BuildContext context, String label, {bool? enabled}) {
    final colors = Theme.of(context).colorScheme;
    final active = enabled != false;
    final color = active ? colors.primary : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: .1)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled != null) ...[
            Icon(enabled ? Icons.check_rounded : Icons.close_rounded,
              size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Theme.of(dialogContext).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(command.name),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _commandTags(dialogContext),
              const SizedBox(height: 16),
              SelectableText(command.text,
                style: const TextStyle(fontFamily: 'UbuntuMono', fontSize: 14)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogContext.tr('global.close')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
