import 'dart:io';

import 'package:blue_serial_lib/src/models/serial_config.dart';
import 'package:blue_serial_lib/src/models/serial_flow_control.dart';
import 'package:blue_serial_lib/src/models/serial_parity.dart';
import 'package:blue_serial_lib/src/models/serial_stop_bits.dart';
import 'package:blue_serial_lib/src/platform_interface/blue_serial_lib_messages.g.dart'
    as messages;
import 'package:blue_serial_lib/src/platform_interface/pigeon_blue_serial_lib.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const prefix = 'dev.flutter.pigeon.blue_serial_lib.BlueSerialLibApi';

  test('port discovery uses the renamed native API channel', () async {
    const channel = BasicMessageChannel<Object?>(
      '$prefix.getSerialList',
      messages.BlueSerialLibApi.pigeonChannelCodec,
    );
    messenger.setMockDecodedMessageHandler(channel, (message) async {
      expect(message, isNull);
      return [
        [messages.SerialInfoMessage(name: 'USB serial', path: '/dev/ttyUSB0')],
      ];
    });
    addTearDown(() => messenger.setMockDecodedMessageHandler(channel, null));

    final ports = await PigeonBlueSerialLib().getSerialList();
    expect(ports.single.name, 'USB serial');
    expect(ports.single.path, '/dev/ttyUSB0');
  });

  test(
    'connection config crosses the renamed channel with its enums',
    () async {
      const channel = BasicMessageChannel<Object?>(
        '$prefix.connect',
        messages.BlueSerialLibApi.pigeonChannelCodec,
      );
      var called = false;
      messenger.setMockDecodedMessageHandler(channel, (message) async {
        called = true;
        final arguments = message! as List<Object?>;
        expect(arguments.first, '/dev/ttyUSB0');
        final config = arguments[1]! as messages.SerialConfigMessage;
        expect(config.baudRate, 9600);
        expect(config.dataBits, 7);
        expect(config.parity, messages.SerialParity.even);
        expect(config.stopBits, messages.SerialStopBits.two);
        expect(config.flowControl, messages.SerialFlowControl.rtsCts);
        return [null];
      });
      addTearDown(() => messenger.setMockDecodedMessageHandler(channel, null));

      await PigeonBlueSerialLib().connect(
        '/dev/ttyUSB0',
        const SerialConfig(
          baudRate: 9600,
          dataBits: 7,
          parity: SerialParity.even,
          stopBits: SerialStopBits.two,
          flowControl: SerialFlowControl.rtsCts,
        ),
      );
      expect(called, isTrue);
    },
  );

  test('Dart codec agrees with Linux native event and model type tags', () {
    final header = File('linux/message_types.g.h').readAsStringSync();
    final values = <String, Object>{
      'SerialParity': messages.SerialParity.even,
      'SerialStopBits': messages.SerialStopBits.two,
      'SerialFlowControl': messages.SerialFlowControl.rtsCts,
      'SerialConnectionState': messages.SerialConnectionState.connected,
      'SerialConfigMessage': messages.SerialConfigMessage(
        baudRate: 9600,
        dataBits: 8,
        stopBits: messages.SerialStopBits.one,
        parity: messages.SerialParity.none,
        flowControl: messages.SerialFlowControl.none,
      ),
      'SerialInfoMessage': messages.SerialInfoMessage(
        name: 'USB',
        path: 'usb:1',
      ),
      'SerialDataMessage': messages.SerialDataMessage(
        path: 'usb:1',
        data: Uint8List.fromList([0, 128, 255]),
      ),
      'SerialConnectionMessage': messages.SerialConnectionMessage(
        path: 'usb:1',
        state: messages.SerialConnectionState.disconnected,
        error: 'unplugged',
      ),
    };
    for (final entry in values.entries) {
      final match = RegExp('k${entry.key}Type = (\\d+);').firstMatch(header)!;
      final encoded = messages.BlueSerialLibApi.pigeonChannelCodec
          .encodeMessage(entry.value)!;
      expect(encoded.getUint8(0), int.parse(match[1]!), reason: entry.key);
    }
  });
}
