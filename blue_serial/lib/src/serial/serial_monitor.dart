import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:blue_serial_lib/blue_serial_lib.dart' show SerialInfo;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../helper/command_card.dart';
import '../helper/serial.dart';
import '../helper/traffic_log_export.dart';
import '../store/serial.dart';
import '../models/serial_command.dart';
import '../models/input_mode.dart';
import '../bloc/serial_bloc/serial_bloc.dart';
import '../term/terminal_panel.dart';

part 'header.dart';
part 'port_selection_widget.dart';
part 'send_data_widget.dart';
part 'select_command.dart';
part 'traffic_panel.dart';

const _rxColor = Color(0xFF5EE0B5);
const _txColor = Color(0xFFFFC878);
const _muted = Color(0xFF94A4BA);
const _mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.6);

class SerialMonitor extends StatefulWidget {
  const SerialMonitor({super.key});

  @override
  State<SerialMonitor> createState() => _SerialMonitorState();
}

class _SerialMonitorState extends State<SerialMonitor> {
  int _baudRate = 115200;

  Future<bool> _send(SerialBloc monitor, Uint8List bytes) {
    if (monitor.isClosed) return Future.value(false);
    final event = SerialSendRequested(bytes, queueIfBusy: false);
    monitor.add(event);
    return event.result;
  }

  Widget _portControls(
    SerialState state,
    SerialBloc monitor, {
    ValueChanged<int>? onBaudRateChanged,
  }) => PortSelectionWidget(
    ports: state.ports,
    selectedPort: state.selectedPort,
    baudRate: _baudRate,
    onBaudRateChanged:
        onBaudRateChanged ?? (value) => setState(() => _baudRate = value),
    isConnected: state.isConnected,
    isBusy: state.isBusy,
    isRefreshing: state.isRefreshing,
    isSending: state.isSending,
    onPortChanged: (path) => monitor.add(SerialPortSelected(path)),
    onRefresh: () async => monitor.add(const SerialPortsRefreshRequested()),
    onRequestPort: kIsWeb ? monitor.requestPort : null,
    onConnect: (baudRate) async =>
        monitor.add(SerialConnectionRequested(baudRate)),
    onDisconnect: () async => monitor.add(const SerialDisconnectionRequested()),
  );

  Future<void> _showConnectionSettings(SerialBloc monitor) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => BlocProvider.value(
        value: monitor,
        child: BlocConsumer<SerialBloc, SerialState>(
          listenWhen: (previous, current) =>
              !previous.isConnected && current.isConnected,
          listener: (_, _) => Navigator.of(sheetContext).pop(),
          builder: (context, state) => StatefulBuilder(
            builder: (context, updateSheet) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                key: const Key('connection-settings-sheet'),
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('serial.connectionSettings'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('global.close'),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _portControls(
                      state,
                      monitor,
                      onBaudRateChanged: (value) {
                        setState(() => _baudRate = value);
                        updateSheet(() {});
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      _errorBanner(
                        context,
                        state.error!,
                        () => monitor.add(const SerialErrorDismissed()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _connectionSummary(
    SerialState state,
    SerialBloc monitor, {
    bool showModeMenu = false,
  }) {
    final status = context.tr(switch (state.status) {
      ConnectionStatus.connected => 'serial.connected',
      ConnectionStatus.connecting => 'global.connecting',
      ConnectionStatus.disconnecting => 'serial.disconnecting',
      ConnectionStatus.disconnected => 'serial.disconnected',
    });
    final canAct = !state.isBusy && !state.isSending && !state.isRefreshing;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF283343)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (showModeMenu)
            PopupMenuButton<MonitorType>(
              key: const Key('compact-monitor-type'),
              tooltip: context.tr('serial.monitorMode'),
              enabled: state.status == ConnectionStatus.disconnected,
              initialValue: state.type,
              onSelected: (type) {
                FocusManager.instance.primaryFocus?.unfocus();
                monitor.add(SerialTypeChanged(type));
              },
              itemBuilder: (_) => [
                for (final type in MonitorType.values)
                  CheckedPopupMenuItem(
                    value: type,
                    checked: state.type == type,
                    child: Text(
                      context.tr(
                        type == MonitorType.normal
                            ? 'global.normal'
                            : 'global.terminal',
                      ),
                    ),
                  ),
              ],
              icon: Icon(
                state.type == MonitorType.normal
                    ? Icons.list_alt_rounded
                    : Icons.terminal_rounded,
              ),
            ),
          Expanded(
            child: InkWell(
              key: const Key('connection-settings-button'),
              onTap: () => _showConnectionSettings(monitor),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    if (state.isBusy)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: state.isConnected ? _rxColor : _muted,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.selectedPort ??
                                context.tr('serial.connectionSettings'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$status · $_baudRate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.tune_rounded, size: 20, color: _muted),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('quick-connect-button'),
            tooltip: context.tr(
              state.isConnected ? 'global.disconnect' : 'global.connect',
            ),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: state.isConnected ? _txColor : _rxColor,
            onPressed: !canAct
                ? null
                : () {
                    if (state.isConnected) {
                      monitor.add(const SerialDisconnectionRequested());
                    } else if (state.selectedPort == null) {
                      _showConnectionSettings(monitor);
                    } else {
                      monitor.add(SerialConnectionRequested(_baudRate));
                    }
                  },
            icon: Icon(
              state.isConnected
                  ? Icons.link_off_rounded
                  : Icons.power_settings_new_rounded,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 700 || constraints.maxHeight < 500;
            final hideChrome =
                constraints.maxHeight < 260 ||
                (keyboardOpen && constraints.maxHeight < 400);
            final hideHeader = hideChrome || constraints.maxHeight < 420;
            final gap = compact ? 6.0 : 12.0;
            return BlocBuilder<SerialBloc, SerialState>(
              builder: (context, state) {
                final monitor = context.read<SerialBloc>();
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Visibility(
                        visible: !hideHeader,
                        maintainState: true,
                        child: MonitorHeader(
                          compact: compact,
                          type: state.type,
                          onTypeChanged:
                              state.status == ConnectionStatus.disconnected
                              ? (type) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  monitor.add(SerialTypeChanged(type));
                                }
                              : null,
                        ),
                      ),
                      Visibility(
                        visible: !hideChrome,
                        maintainState: true,
                        child: Padding(
                          padding: EdgeInsets.only(top: gap, bottom: gap),
                          child: compact
                              ? _connectionSummary(
                                  state,
                                  monitor,
                                  showModeMenu: hideHeader,
                                )
                              : _portControls(state, monitor),
                        ),
                      ),
                      if (state.error != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: min(80, constraints.maxHeight * .25),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: gap),
                              child: _errorBanner(
                                context,
                                state.error!,
                                () => monitor.add(const SerialErrorDismissed()),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        key: const Key('monitor-workspace'),
                        child: _panel(
                          context,
                          child: IndexedStack(
                            index: state.type.index,
                            sizing: StackFit.expand,
                            children: [
                              ExcludeFocus(
                                excluding: state.type != MonitorType.normal,
                                child: TrafficPanel(
                                  records: state.records,
                                  rxBytes: state.rxBytes,
                                  txBytes: state.txBytes,
                                  droppedRecords: state.droppedRecords,
                                  isConnected: state.isConnected,
                                  hasPorts: state.ports.isNotEmpty,
                                  onClear: () =>
                                      monitor.add(const SerialHistoryCleared()),
                                ),
                              ),
                              TerminalPanel(
                                incoming: monitor.incomingBytes,
                                isConnected: state.isConnected,
                                onOutput: (bytes) {
                                  if (!monitor.isClosed) {
                                    monitor.add(SerialSendRequested(bytes));
                                  }
                                },
                                active: state.type == MonitorType.terminal,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ExcludeFocus(
                        excluding: state.type != MonitorType.normal,
                        child: Visibility(
                          visible: state.type == MonitorType.normal,
                          maintainState: true,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: gap,
                              bottom: compact ? 4 : 0,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: max(
                                  56,
                                  min(
                                    240,
                                    constraints.maxHeight *
                                        (hideChrome ? .45 : .35),
                                  ),
                                ),
                              ),
                              child: SendDataWidget(
                                compact: compact,
                                keyboardOpen: keyboardOpen,
                                isConnected: state.isConnected,
                                isSending: state.isSending,
                                onSend: (bytes) => _send(monitor, bytes),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283343)),
      ),
      child: child,
    );
  }

  Widget _errorBanner(
    BuildContext context,
    String message,
    VoidCallback onDismiss,
  ) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 64),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('global.dismissNotification'),
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

InputDecoration _controlDecoration(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);
