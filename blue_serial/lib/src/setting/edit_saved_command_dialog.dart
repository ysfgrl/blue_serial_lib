part of 'setting.dart';

class _EditSavedCommandDialog extends StatefulWidget {
  const _EditSavedCommandDialog._({this.command});

  final SerialCommand? command;
  bool get isNew => command == null;

  static Future<bool?> show(
    BuildContext context, {
    SerialCommand? command,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditSavedCommandDialog._(command: command),
    );
  }

  @override
  State<_EditSavedCommandDialog> createState() => _EditSavedCommandDialogState();
}

class _EditSavedCommandDialogState extends State<_EditSavedCommandDialog> {
  final _form = GlobalKey<FormState>();
  final _store = SavedCommandStore();
  late final _name = TextEditingController(text: widget.command?.name ?? '');
  late final _text = TextEditingController(text: widget.command?.text ?? '');
  late InputMode _mode = widget.command?.mode ?? InputMode.ascii;
  late bool _cr = widget.command?.cr ?? false;
  late bool _lf = widget.command?.lf ?? false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final command = SerialCommand(
      name: _name.text.trim(),
      text: _text.text,
      mode: _mode,
      cr: _cr,
      lf: _lf,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final commands = await _store.load();
      final original = widget.command;
      final index = original == null
          ? -1
          : commands.indexWhere((item) => item.name == original.name);
      if (original != null && index < 0) {
        throw const FormatException('serial.commandNotFound');
      }
      if (commands.asMap().entries.any((entry) =>
          entry.key != index &&
          entry.value.name.toLowerCase() == command.name.toLowerCase())) {
        throw const FormatException('serial.commandNameExists');
      }
      if (index < 0) {
        commands.add(command);
      } else {
        commands[index] = command;
      }
      await _store.save(commands);
    } catch (error, st) {
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is FormatException
            ? error.message
            : 'serial.commandSaveFailed';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop<bool>(true);
  }

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<bool>(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr(widget.isNew
                            ? 'serial.saveCommand' : 'serial.editCommand'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildForm(context),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  overflowSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null : () => Navigator.of(context).pop<bool>(false),
                      child: Text(context.tr('global.cancel')),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.tr('global.save')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('edit-saved-command-name'),
            controller: _name,
            enabled: !_saving,
            autofocus: false,
            style: theme.textTheme.bodyMedium,
            textInputAction: TextInputAction.next,
            scrollPadding: const EdgeInsets.all(16),
            decoration: _fieldDecoration(context.tr('serial.commandName')),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) {
                return context.tr('serial.commandNameRequired');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('edit-saved-command-text'),
            controller: _text,
            enabled: !_saving,
            minLines: 2,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            scrollPadding: const EdgeInsets.all(16),
            style: const TextStyle(
              fontFamily: 'UbuntuMono', fontSize: 14, height: 1.35,
            ),
            decoration: _fieldDecoration(context.tr(_mode == InputMode.ascii
                ? 'serial.asciiCommand' : 'serial.hexCommand')),
            validator: (value) {
              try {
                SerialHelper.encodeInput(value ?? '', _mode);
                return null;
              } on FormatException catch (error) {
                return context.tr(error.message);
              }
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 156,
                child: SegmentedButton<InputMode>(
                  key: const Key('edit-saved-command-mode'),
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    ButtonSegment(
                      value: InputMode.ascii,
                      label: Text(context.tr('global.ascii')),
                    ),
                    ButtonSegment(
                      value: InputMode.hex,
                      label: Text(context.tr('global.hex')),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onSelectionChanged: _saving ? null : (selection) {
                    setState(() {
                      _mode = selection.single;
                      _error = null;
                    });
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _endingChoice(
                    context.tr('global.cr'), _cr,
                    (value) => setState(() => _cr = value),
                  ),
                  const SizedBox(width: 6),
                  _endingChoice(
                    context.tr('global.lf'), _lf,
                    (value) => setState(() => _lf = value),
                  ),
                ],
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.tr(_error!),
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    errorMaxLines: 3,
  );

  Widget _endingChoice(String label, bool value, ValueChanged<bool> onChanged) =>
      FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: value,
        onSelected: _saving ? null : onChanged,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
}
