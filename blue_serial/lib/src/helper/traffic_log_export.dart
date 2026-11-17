import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

import '../bloc/serial_bloc/serial_bloc.dart';
import 'serial.dart';

class TrafficLogExport {
  static String format(List<TrafficRecord> records, {int droppedRecords = 0}) {
    final text = StringBuffer('Blue Serial traffic log\n')
      ..writeln('Records: ${records.length}')
      ..writeln('Dropped records: $droppedRecords')
      ..writeln();
    for (final record in records) {
      text
        ..writeln(
          '[${record.timestamp.toIso8601String()}] '
          '${record.direction.name.toUpperCase()} (${record.bytes.length} B)',
        )
        ..writeln('ASCII: ${SerialHelper.formatAscii(record.bytes)}')
        ..writeln('HEX: ${SerialHelper.formatHex(record.bytes)}')
        ..writeln();
    }
    return text.toString();
  }

  static Future<String?> save(
    List<TrafficRecord> records, {
    int droppedRecords = 0,
  }) {
    final name = 'blue_serial_logs_${DateTime.now().toIso8601String()}'
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final bytes = Uint8List.fromList(
      utf8.encode(format(records, droppedRecords: droppedRecords)),
    );
    final saver = FileSaver.instance;
    // This plugin version has no Linux save dialog; save to Downloads there.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      return saver.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: 'txt',
        mimeType: MimeType.text,
      );
    }
    return saver.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: 'txt',
      mimeType: MimeType.text,
    );
  }
}
