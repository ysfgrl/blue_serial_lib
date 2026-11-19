part of 'serial_monitor.dart';

enum _TrafficDisplayMode {
  ascii('global.ascii'),
  hex('global.hex'),
  both('global.both');

  const _TrafficDisplayMode(this.label);

  final String label;
}

class TrafficPanel extends StatefulWidget {
  const TrafficPanel({
    super.key,
    required this.records,
    required this.rxBytes,
    required this.txBytes,
    required this.droppedRecords,
    required this.isConnected,
    required this.hasPorts,
    required this.onClear,
  });
  final List<TrafficRecord> records;
  final int rxBytes;
  final int txBytes;
  final int droppedRecords;
  final bool isConnected;
  final bool hasPorts;
  final VoidCallback onClear;

  @override
  State<TrafficPanel> createState() => _TrafficPanelState();
}

class _TrafficPanelState extends State<TrafficPanel> {
  final _scroll = ScrollController();
  bool _autoScroll = true;
  _TrafficDisplayMode _displayMode = _TrafficDisplayMode.ascii;
  bool _scrollScheduled = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.records.isNotEmpty) _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant TrafficPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && !identical(oldWidget.records, widget.records)) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (mounted && _autoScroll && _scroll.hasClients) {
        final end = _scroll.position.maxScrollExtent;
        if ((end - _scroll.offset).abs() > 0.5) _scroll.jumpTo(end);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _setDisplay({bool? ascii, bool? hex}) {
    final showAscii = ascii ?? _displayMode != _TrafficDisplayMode.hex;
    final showHex = hex ?? _displayMode != _TrafficDisplayMode.ascii;
    if (!showAscii && !showHex) return;
    final mode = showAscii && showHex
        ? _TrafficDisplayMode.both
        : showAscii
        ? _TrafficDisplayMode.ascii
        : _TrafficDisplayMode.hex;
    if (mode == _displayMode) return;
    setState(() => _displayMode = mode);
    if (_autoScroll) _scrollToEnd();
  }

  Future<void> _downloadLogs() async {
    if (_isDownloading || widget.records.isEmpty) return;
    setState(() => _isDownloading = true);
    try {
      final path = await TrafficLogExport.save(
        widget.records,
        droppedRecords: widget.droppedRecords,
      );
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('serial.logsDownloaded'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('serial.logDownloadFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Widget _downloadButton() => IconButton(
    key: const Key('traffic-download'),
    tooltip: context.tr('serial.downloadLogs'),
    onPressed: widget.records.isEmpty || _isDownloading ? null : _downloadLogs,
    icon: _isDownloading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_rounded, size: 20),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 600 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return Column(
          children: [
            if (constraints.maxHeight >= 80) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: 4,
                ),
                child: compact
                    ? _compactToolbar()
                    : Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          MergeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  key: const Key('traffic-ascii'),
                                  value:
                                      _displayMode != _TrafficDisplayMode.hex,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _setDisplay(ascii: value);
                                    }
                                  },
                                ),
                                Text(
                                  context.tr('global.ascii'),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          MergeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  key: const Key('traffic-hex'),
                                  value:
                                      _displayMode != _TrafficDisplayMode.ascii,
                                  onChanged: (value) {
                                    if (value != null) _setDisplay(hex: value);
                                  },
                                ),
                                Text(
                                  context.tr('global.hex'),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: SizedBox()),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                key: const Key('traffic-follow'),
                                value: _autoScroll,
                                onChanged: (value) {
                                  setState(() => _autoScroll = value!);
                                  if (_autoScroll) _scrollToEnd();
                                },
                              ),
                              Text(
                                context.tr('serial.follow'),
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),

                          IconButton(
                            tooltip: context.tr('serial.clearScreen'),
                            onPressed: widget.onClear,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                          ),
                          _downloadButton(),
                        ],
                      ),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: widget.records.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              size: 30,
                              color: _muted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('serial.waitingForData'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isConnected
                                  ? context.tr('serial.incomingOutgoingHint')
                                  : !widget.hasPorts
                                  ? context.tr(
                                      !kIsWeb &&
                                              defaultTargetPlatform ==
                                                  TargetPlatform.iOS
                                          ? 'serial.iosSerialUnsupported'
                                          : 'serial.connectDeviceHint',
                                    )
                                  : context.tr('serial.selectPortHint'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : NotificationListener<ScrollMetricsNotification>(
                      onNotification: (notification) {
                        if (_autoScroll &&
                            notification.depth == 0 &&
                            notification.metrics.pixels <
                                notification.metrics.maxScrollExtent - 0.5) {
                          _scrollToEnd();
                        }
                        return false;
                      },
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        child: ListView.builder(
                          key: const Key('traffic-list'),
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: widget.records.length,
                          itemBuilder: (_, index) => _TrafficRow(
                            key: ObjectKey(widget.records[index]),
                            record: widget.records[index],
                            displayMode: _displayMode,
                          ),
                        ),
                      ),
                    ),
            ),
            if (constraints.maxHeight >= 180) ...[
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 64),
                child: SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(
                              'serial.recordCount',
                              namedArgs: {
                                'count': widget.records.length.toString(),
                              },
                            ),
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                          if (compact) ...[
                            _counter(
                              'serial.rxCounter',
                              widget.rxBytes,
                              _rxColor,
                            ),
                            _counter(
                              'serial.txCounter',
                              widget.txBytes,
                              _txColor,
                            ),
                          ],
                          Text(
                            widget.droppedRecords > 0
                                ? context.tr(
                                    'serial.droppedRecordCount',
                                    namedArgs: {
                                      'count': widget.droppedRecords.toString(),
                                    },
                                  )
                                : _displayMode == _TrafficDisplayMode.both
                                ? context.tr('global.asciiHex')
                                : context.tr(_displayMode.label),
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _compactToolbar() => Row(
    children: [
      PopupMenuButton<_TrafficDisplayMode>(
        key: const Key('traffic-display'),
        tooltip: context.tr('serial.displayFormat'),
        initialValue: _displayMode,
        onSelected: (mode) {
          if (_displayMode == mode) return;
          setState(() => _displayMode = mode);
          if (_autoScroll) _scrollToEnd();
        },
        itemBuilder: (_) => [
          for (final mode in _TrafficDisplayMode.values)
            CheckedPopupMenuItem(
              value: mode,
              checked: mode == _displayMode,
              child: Text(context.tr(mode.label)),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(_displayMode.label),
                style: const TextStyle(fontSize: 12),
              ),
              const Icon(Icons.expand_more_rounded, size: 18),
            ],
          ),
        ),
      ),
      const Spacer(),
      IconButton(
        key: const Key('traffic-follow'),
        tooltip: context.tr('serial.follow'),
        isSelected: _autoScroll,
        onPressed: () {
          setState(() => _autoScroll = !_autoScroll);
          if (_autoScroll) _scrollToEnd();
        },
        icon: const Icon(Icons.sync_rounded),
        selectedIcon: const Icon(
          Icons.sync_rounded,
          color: _rxColor,
        ),
      ),
      IconButton(
        tooltip: context.tr('serial.clearScreen'),
        onPressed: widget.onClear,
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
      ),
      _downloadButton(),
    ],
  );

  Widget _counter(String label, int count, Color color) {
    return Text(
      context.tr(label, namedArgs: {'count': count.toString()}),
      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color),
    );
  }
}

class _TrafficRow extends StatelessWidget {
  const _TrafficRow({
    super.key,
    required this.record,
    required this.displayMode,
  });

  final TrafficRecord record;
  final _TrafficDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    final rx = record.direction == TrafficDirection.rx;
    final color = rx ? _rxColor : _txColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 2),
          bottom: const BorderSide(color: Color(0xFF1E2938)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metadataWidth = min(
            constraints.maxWidth * 0.28,
            constraints.maxWidth < 600 ? 80.0 : 104.0,
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: metadataWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        rx ? 'serial.rxMetadata' : 'serial.txMetadata',
                        namedArgs: {'count': record.bytes.length.toString()},
                      ),
                      style: _mono.copyWith(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF283343))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (displayMode != _TrafficDisplayMode.hex)
                        _data(
                          context,
                          context.tr('global.ascii'),
                          SerialHelper.formatAscii(record.bytes),
                          () => SerialHelper.asciiClipboardText(record.bytes),
                        ),
                      if (displayMode == _TrafficDisplayMode.both)
                        const SizedBox(height: 4),
                      if (displayMode != _TrafficDisplayMode.ascii)
                        _data(
                          context,
                          context.tr('global.hex'),
                          SerialHelper.formatHex(record.bytes),
                          () => SerialHelper.formatHex(record.bytes),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _data(
    BuildContext context,
    String label,
    String value,
    String Function() clipboardText,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      IconButton(
        key: ValueKey('copy-${label.toLowerCase()}'),
        constraints: const BoxConstraints.tightFor(width: 21, height: 21),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: context.tr('global.copyLabel', namedArgs: {'label': label}),
        onPressed: () => _copy(context, label, clipboardText()),
        icon: const Icon(Icons.content_copy_rounded, size: 18),
      ),

      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label= ',
                  style: const TextStyle(color: _muted),
                ),
                TextSpan(text: value),
              ],
            ),
            style: _mono,
            maxLines: 1,
          ),
        ),
      ),
    ],
  );

  Future<void> _copy(BuildContext context, String label, String text) async {
    var message = 'global.copiedLabel';
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      message = 'global.copyFailedLabel';
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(message, namedArgs: {'label': label})),
          duration: const Duration(seconds: 1),
        ),
      );
  }
}
