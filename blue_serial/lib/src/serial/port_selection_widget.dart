part of 'serial_monitor.dart';

class PortSelectionWidget extends StatelessWidget {
  const PortSelectionWidget({
    super.key,
    required this.ports,
    required this.selectedPort,
    required this.baudRate,
    required this.onBaudRateChanged,
    required this.isConnected,
    required this.isBusy,
    required this.isRefreshing,
    required this.isSending,
    required this.onPortChanged,
    required this.onRefresh,
    required this.onConnect,
    required this.onDisconnect,
    this.onRequestPort,
  });

  final List<SerialInfo> ports;
  final String? selectedPort;
  final int baudRate;
  final ValueChanged<int> onBaudRateChanged;
  final bool isConnected;
  final bool isBusy;
  final bool isRefreshing;
  final bool isSending;
  final ValueChanged<String?> onPortChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int baudRate) onConnect;
  final Future<void> Function() onDisconnect;
  final VoidCallback? onRequestPort;

  @override
  Widget build(BuildContext context) {
    final locked = isConnected || isBusy;
    final canConnect =
        !isBusy && !isSending && !isRefreshing && selectedPort != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 480 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final available = max(0.0, constraints.maxWidth - 64);
        return Wrap(
          spacing: 8,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: stacked ? constraints.maxWidth : available * 4 / 7,
              child: DropdownButtonFormField<String>(
                key: ValueKey('port-$selectedPort'),
                initialValue: selectedPort,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: _controlDecoration(context.tr('global.port'))
                    .copyWith(
                      suffixIcon: onRequestPort == null
                          ? null
                          : IconButton(
                              key: const Key('request-port-button'),
                              tooltip: context.tr('serial.authorizePort'),
                              onPressed: locked || isRefreshing
                                  ? null
                                  : onRequestPort,
                              icon: const Icon(Icons.add, size: 20),
                            ),
                    ),
                hint: Text(
                  isRefreshing
                      ? context.tr('serial.scanningPorts')
                      : onRequestPort != null
                      ? context.tr('serial.selectPort')
                      : context.tr('serial.noPorts'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                items: [
                  ...ports.map((port) {
                    return DropdownMenuItem(
                      value: port.path,
                      child: Text(
                        onRequestPort != null && port.name.isNotEmpty
                            ? port.name
                            : port.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  DropdownMenuItem(
                    value: "refresh",
                    child: Text(
                      context.tr('global.refresh'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: locked || isRefreshing
                    ? null
                    : (value) {
                        if (value == "refresh") {
                          onRefresh();
                          return;
                        }
                        onPortChanged(value);
                      },
              ),
            ),
            SizedBox(
              width: stacked
                  ? max(0.0, constraints.maxWidth - 56)
                  : available * 3 / 7,
              child: DropdownButtonFormField<int>(
                key: const Key('baud-dropdown'),
                initialValue: baudRate,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: _controlDecoration(context.tr('global.baudRate')),
                items: [
                  for (final rate in [
                    1200,
                    2400,
                    4800,
                    9600,
                    19200,
                    38400,
                    57600,
                    115200,
                    230400,
                    460800,
                    921600,
                    1500000,
                  ])
                    DropdownMenuItem(
                      value: rate,
                      child: Text(
                        '$rate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: locked
                    ? null
                    : (value) {
                        if (value != null) onBaudRateChanged(value);
                      },
              ),
            ),
            IconButton(
              key: const Key('connect-button'),
              tooltip: isConnected
                  ? context.tr('global.disconnect')
                  : context.tr('global.connect'),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: isConnected
                    ? const Color(0xFF3D2C27)
                    : const Color(0xFF347129),
                foregroundColor: isConnected ? _txColor : null,
              ),
              onPressed: canConnect
                  ? () {
                      if (isConnected) {
                        onDisconnect();
                      } else {
                        onConnect(baudRate);
                      }
                    }
                  : null,
              icon: Icon(
                isConnected ? Icons.link_off : Icons.power_settings_new,
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }
}
