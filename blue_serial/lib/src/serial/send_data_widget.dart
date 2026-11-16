part of 'serial_monitor.dart';

class SendDataWidget extends StatefulWidget {
  const SendDataWidget({
    super.key,
    required this.isConnected,
    required this.isSending,
    required this.onSend,
    this.compact = false,
    this.keyboardOpen = false,
  });

  final bool compact;
  final bool keyboardOpen;
  final bool isConnected;
  final bool isSending;
  final Future<bool> Function(Uint8List bytes) onSend;

  @override
  State<SendDataWidget> createState() => _SendDataWidgetState();
}

class _SendDataWidgetState extends State<SendDataWidget>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _commandStore = SavedCommandStore();
  List<SerialCommand> _commands = [];
  bool _loadingCommands = true;
  bool _commandsLoadFailed = false;
  bool _commandDialogOpen = false;
  bool _savingCommand = false;
  InputMode _mode = InputMode.ascii;
  bool _cr = false;
  bool _lf = false;
  bool _keyboardRequested = false;
  bool _openingKeyboard = false;
  bool _keyboardWasVisible = false;
  bool _inputIsEmpty = true;
  String? _inputError;

  bool get _isSending => widget.isSending;
  bool get _canEditSendOptions => !_isSending && _inputIsEmpty;
  bool get _commandActionsEnabled =>
      !_isSending && !_savingCommand && !_commandDialogOpen && !_loadingCommands;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _input.addListener(_onInputChanged);
    _inputFocus.addListener(_onInputFocusChanged);
    unawaited(_loadCommands());
  }

  void _onInputChanged() {
    final isEmpty = _input.text.isEmpty;
    if (isEmpty != _inputIsEmpty) {
      setState(() => _inputIsEmpty = isEmpty);
    }
  }

  void _onInputFocusChanged() {
    if (!_openingKeyboard && !_inputFocus.hasFocus && _keyboardRequested) {
      setState(() => _keyboardRequested = false);
    }
  }

  void _hideKeyboard() {
    _openingKeyboard = false;
    setState(() => _keyboardRequested = false);
    _inputFocus.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  void _toggleKeyboard() {
    if (_isSending) return;
    if (_keyboardRequested) {
      _hideKeyboard();
      return;
    }
    // Discard the old inputType.none connection before attaching a text IME.
    _openingKeyboard = true;
    _inputFocus.unfocus();
    setState(() => _keyboardRequested = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _keyboardRequested && !_isSending) {
        _inputFocus.requestFocus();
      }
      _openingKeyboard = false;
    });
  }

  @override
  void didChangeMetrics() {
    final visible = View.of(context).viewInsets.bottom > 0;
    if (_keyboardWasVisible && !visible && _keyboardRequested) {
      _hideKeyboard();
    }
    _keyboardWasVisible = visible;
  }

  Future<void> _loadCommands() async {
    setState(() {
      _loadingCommands = true;
      _commandsLoadFailed = false;
    });
    try {
      final commands = await _commandStore.load();
      if (mounted) setState(() => _commands = commands);
    } catch (_) {
      if (mounted) setState(() => _commandsLoadFailed = true);
    } finally {
      if (mounted) setState(() => _loadingCommands = false);
    }
  }

  Future<void> _saveCommand() async {
    if (!_commandActionsEnabled || _inputIsEmpty) return;
    final text = _input.text;
    final mode = _mode;
    final cr = _cr;
    final lf = _lf;
    try {
      SerialHelper.encodeInput(text, mode);
    } on FormatException catch (error) {
      setState(() => _inputError = error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.message))),
      );
      return;
    }

    setState(() => _savingCommand = true);
    try {
      if (_commandsLoadFailed) {
        final commands = await _commandStore.load();
        if (!mounted) return;
        setState(() {
          _commands = commands;
          _commandsLoadFailed = false;
        });
      }
      final exists = _commands.any((command) =>
          command.text == text && command.mode == mode &&
          command.cr == cr && command.lf == lf);
      if (!exists) {
        final preview = text.replaceAll(RegExp(r'\s+'), ' ').trim();
        final baseName = preview.isEmpty
            ? mode.name.toUpperCase()
            : String.fromCharCodes(preview.runes.take(40));
        final names = _commands.map((command) => command.name.toLowerCase()).toSet();
        var name = baseName;
        for (var index = 2; names.contains(name.toLowerCase()); index++) {
          name = '$baseName ($index)';
        }
        final command = SerialCommand(
          name: name, text: text, mode: mode, cr: cr, lf: lf,
        );
        final updated = [..._commands, command];
        await _commandStore.save(updated);
        if (!mounted) return;
        setState(() => _commands = updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('serial.commandSaved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('serial.commandSaveFailed'))),
      );
    } finally {
      if (mounted) setState(() => _savingCommand = false);
    }
  }

  Future<void> _showCommands() async {
    if (!_commandActionsEnabled) return;
    _hideKeyboard();
    setState(() => _commandDialogOpen = true);
    try {
      final command = await _SelectSavedCommand.select(context);
      if (mounted && command != null) _selectCommand(command);
    } finally {
      if (mounted) setState(() => _commandDialogOpen = false);
    }
  }

  void _selectCommand(SerialCommand command) {
    if (_isSending) return;
    setState(() {
      _input.value = TextEditingValue(
        text: command.text,
        selection: TextSelection.collapsed(offset: command.text.length),
      );
      _mode = command.mode;
      _cr = command.cr;
      _lf = command.lf;
      _inputError = null;
    });
  }

  void _setMode(InputMode mode) {
    if (!_canEditSendOptions || mode == _mode) return;
    var text = _input.text;
    try {
      if (text.isNotEmpty) {
        final bytes = SerialHelper.encodeInput(text, _mode);
        if (mode == InputMode.ascii && bytes.any((byte) => byte > 127)) {
          throw const FormatException('serial.nonAsciiBytes');
        }
        text = mode == InputMode.hex
            ? SerialHelper.formatHex(bytes)
            : ascii.decode(bytes);
      }
      setState(() {
        _input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _mode = mode;
        _inputError = null;
      });
    } on FormatException catch (error) {
      setState(() => _inputError = error.message);
    }
  }

  Future<void> _send() async {
    if (!widget.isConnected || _isSending) return;
    final text = _input.text;
    late final Uint8List bytes;
    try {
      bytes = Uint8List.fromList([
        ...SerialHelper.encodeInput(text, _mode),
        if (_cr) 0x0D,
        if (_lf) 0x0A,
      ]);
    } on FormatException catch (error) {
      setState(() => _inputError = error.message);
      return;
    }
    if (_inputError != null) setState(() => _inputError = null);
    final success = await widget.onSend(bytes);
    if (!mounted) return;
    if (success && _input.text == text) _input.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocus.removeListener(_onInputFocusChanged);
    _inputFocus.dispose();
    _input.removeListener(_onInputChanged);
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.isConnected && !_isSending && !_inputIsEmpty;
    final compact = widget.compact;
    final platform = Theme.of(context).platform;
    final mobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return SizedBox(
      height: compact || _inputError == null ? 48 : null,
      child: TextField(
        key: const Key('send-input'),
        controller: _input,
        focusNode: _inputFocus,
        autofocus: false,
        keyboardType: !mobile || _keyboardRequested
            ? TextInputType.text
            : TextInputType.none,
        enabled: !_isSending,
        style: _mono.copyWith(fontSize: compact ? 14 : 12, height: 1.3),
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.send,
        onSubmitted: canSend ? (_) => _send() : null,
        onChanged: (_) {
          if (_inputError != null) setState(() => _inputError = null);
        },
        decoration:
        _controlDecoration(
          [
            context.tr(
              _mode == InputMode.ascii ? 'global.ascii' : 'global.hex',
            ),
            if (_cr) 'CR',
            if (_lf) 'LF',
          ].join(' · '),
        ).copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          labelStyle: const TextStyle(fontSize: 12),
          hintText: _mode == InputMode.ascii
              ? context.tr('global.enterText')
              : context.tr('serial.hexHint'),
          prefixIconConstraints: BoxConstraints.tightFor(
            width: (mobile ? 48.0 : 0.0) +
                (_inputIsEmpty ? 56.0 : 0.0),
            height: 48,
          ),
          prefixIcon: mobile || _inputIsEmpty
              ? TextFieldTapRegion(
            child: ExcludeFocus(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mobile) SizedBox(
                    width: 48,
                    child: IconButton(
                      key: const Key('send-keyboard-button'),
                      tooltip: context.tr(
                        _keyboardRequested
                            ? 'terminal.hideKeyboard'
                            : 'terminal.showKeyboard',
                      ),
                      isSelected: _keyboardRequested,
                      onPressed: _isSending ? null : _toggleKeyboard,
                      icon: const Icon(Icons.keyboard_outlined),
                      selectedIcon: const Icon(
                        Icons.keyboard_hide_outlined,
                      ),
                    ),
                  ),
                  if (_inputIsEmpty) SizedBox(
                    width: 56,
                    child: Tooltip(
                      message: context.tr(
                        _mode == InputMode.ascii
                            ? 'global.hex'
                            : 'global.ascii',
                      ),
                      child: TextButton(
                        key: const Key('send-mode-button'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(56, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _canEditSendOptions
                            ? () => _setMode(
                          _mode == InputMode.ascii
                              ? InputMode.hex
                              : InputMode.ascii,
                        )
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr(
                              _mode == InputMode.ascii
                                  ? 'global.ascii'
                                  : 'global.hex',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : null,
          suffixIconConstraints: BoxConstraints.tightFor(
            width: _inputIsEmpty ? 128 : 96,
            height: 48,
          ),
          suffixIcon: TextFieldTapRegion(
            child: ExcludeFocus(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_inputIsEmpty) ...[
                    _endingButton(
                      context.tr('global.cr'),
                      _cr,
                          (value) => setState(() => _cr = value),
                    ),
                    _endingButton(
                      context.tr('global.lf'),
                      _lf,
                          (value) => setState(() => _lf = value),
                    ),
                  ],
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      key: ValueKey(_inputIsEmpty
                          ? 'search-command-button' : 'save-command-button'),
                      tooltip: context.tr(_inputIsEmpty
                          ? 'serial.savedCommands' : 'serial.saveCommand'),
                      onPressed: !_commandActionsEnabled
                          ? null
                          : (_inputIsEmpty ? _showCommands : _saveCommand),
                      icon: _savingCommand
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_inputIsEmpty
                              ? Icons.search_rounded : Icons.save_outlined),
                    ),
                  ),
                  if (!_inputIsEmpty) SizedBox(
                    width: 48,
                    height: 42,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: IconButton.filled(
                        key: const Key('send-button'),
                        tooltip: context.tr('global.send'),
                        style: IconButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: canSend ? _send : null,
                        icon: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          errorText: compact || _inputError == null
              ? null
              : context.tr(_inputError!),
          errorMaxLines: 4,
        ),
      ),
    );
  }

  Widget _endingButton(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SizedBox(
    width: 40,
    height: 48,
    child: Semantics(
      toggled: value,
      child: TextButton(
        key: ValueKey('line-ending-${label.toLowerCase()}'),
        onPressed: _canEditSendOptions ? () => onChanged(!value) : null,
        style: TextButton.styleFrom(
          minimumSize: const Size(40, 48),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: value ? _rxColor : _muted,
          backgroundColor: value
              ? _rxColor.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    ),
  );
}
