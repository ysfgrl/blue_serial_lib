# blue_serial_lib — Serial API

[Uygulama rehberine dön](../README.md)

Pigeon-based serial port API for Flutter. Linux implements port enumeration,
connection management, binary writes, and read/connection event channels using
POSIX serial I/O. Android implements USB host serial discovery, permission
requests, connection management, binary writes, and both event streams. macOS
implements IOKit port discovery and POSIX serial I/O through the generated
Pigeon API. iOS registers the API and event channels but has no serial
transport; Windows native serial support remains unimplemented.
Web is implemented using the browser's Web Serial API and the same public Dart
models and streams, without native Pigeon channels.

```dart
import 'dart:typed_data';
import 'package:blue_serial_lib/blue_serial_lib.dart';

final serial = BlueSerialLib();
final ports = await serial.getSerialList();
if (ports.isEmpty) return;
final path = ports.first.path;

// Subscribe before opening a port to receive its first data and state changes.
final reads = serial.dataReceived.listen((event) {
  print('${event.path}: ${event.data}');
}, onError: (Object error) {
  print('Serial read error: $error');
});
final states = serial.connectionChanged.listen((event) {
  print('${event.path}: ${event.state}, ${event.error}');
});

try {
  await serial.connect(path, config: const SerialConfig(baudRate: 9600));
  final written = await serial.write(path, Uint8List.fromList([0x01, 0x02]));
  print('$written bytes written');
  print(await serial.getConnectedPorts());
  // Keep the subscriptions alive while receiving data.
} finally {
  try {
    await serial.disconnect(path);
  } finally {
    await reads.cancel();
    await states.cancel();
  }
}
```

Connections are addressed by their port path, so several ports can be opened at
once. Defaults are 115200 baud, 8 data bits, one stop bit, no parity, and no flow
control. Writes return the actual byte count, which may be smaller than the input
on timeout. Linux supports nonblocking writes with `timeoutMs: 0`; web and
Android USB require positive timeouts. Incoming bytes are raw
chunks, not complete text lines or protocol frames. Cancelling a stream
subscription does not close any connections.

The application's traffic records currently reflect read chunks, capped at
4096 bytes per record. Read boundaries and timing do not identify messages:
one sender write can be split across reads, and multiple messages can share a
read. Correct message framing requires delimiters or lengths defined by the
device protocol. The raw terminal stream is forwarded immediately.

## Generate bindings

```sh
dart run tool/generate_pigeon.dart
```

This generates Dart, Android Kotlin, iOS/macOS Swift, Windows C++, and Linux
GObject bindings from one definition. Linux and Windows output paths and options
are declared in `pigeon/messages.dart`. Pigeon has a single `swiftOut`, so the
script also copies the generated Apple bindings to `macosSwiftOut`, declared in
that same configuration file.

Use this script instead of invoking Pigeon directly: it preserves all model and
enum codec tags while omitting event API declarations for the Linux and Windows
generators. Dart, Kotlin, and Swift still generate their event APIs. Linux
registers the two event channels using the same generated message codec. Windows
still needs its native backend and event-channel bridge. This handles
[Pigeon's event-channel generation limitation](https://github.com/flutter/packages/blob/main/packages/pigeon/README.md)
without changing the Dart API.
Generated bindings are internal; consumers should import
`package:blue_serial_lib/blue_serial_lib.dart`.

## Linux

Ports are discovered under `/sys/class/tty` and listed with their `/dev` paths.
Only character devices whose major/minor numbers belong to a kernel driver
classified as `serial` in `/proc/tty/drivers` are included. Console TTYs and
pseudoterminals are excluded. Unused UART slots reporting `PORT_UNKNOWN` in
their sysfs `type` attribute are also excluded. Discovery does not open devices,
so it preserves busy ports and does not toggle modem lines on attached hardware.
Connections use exclusive, nonblocking descriptors. Reads and queued writes are
processed with a bounded I/O budget every 10 ms on the GLib event loop; a write
timeout never sleeps on Flutter's platform thread. Device removal closes the
connection and emits a disconnected event with an error description.

Standard Linux baud rates from 50 through 4000000 are supported. Unsupported
rates and 1.5 stop bits return a configuration error. Port permissions are those
of the user running the application; open/configuration errors retain the OS
error message.

After changing native code, stop the app and run it again; hot reload does not
reload the native plugin:

```sh
cd blue_serial
flutter run -d linux
```

## Android

Android uses [usb-serial-for-android 3.11.0](https://github.com/mik3y/usb-serial-for-android)
through USB host/OTG. Discovery uses the driver's prober, so only supported
USB serial interfaces are listed, rather than every attached USB device or
every `/dev/tty` node. Paths identify both the USB device and its port number,
for example `usb:/dev/bus/usb/001/002:0`.

`connect()` requests Android USB permission when needed, then opens the selected
port and applies its settings. Permission denial and unsupported settings return
errors. USB I/O runs off the Flutter platform thread; events and method replies
are delivered on the main thread. Removing a device closes its ports and emits
disconnect events. Detaching the plugin unregisters all channels/receivers and
closes readers, writers, and USB connections.

The Android reader uses the driver's asynchronous `UsbRequest` path with
`readTimeout: 0`, matching the upstream terminal example. A positive timeout
selects a different `bulkTransfer` read path that can lose received bytes on
some Android USB stacks. Closing the port interrupts a pending read. Debug
builds log the configured reader mode and emit throttled `BlueSerialRX` /
`[SerialRX]` metadata logs to distinguish USB reads, event-channel dispatch,
and Dart receipt; command payloads are not logged.

The example declares USB host support and configures JitPack for the driver
dependency. Consuming applications must also add JitPack to their own Android
dependency repositories, since a plugin's repositories are not inherited by the
application's runtime dependency resolution. For the standard Flutter layout,
add this inside `allprojects.repositories` in `android/build.gradle.kts`:

```kotlin
maven(url = "https://jitpack.io") {
    content { includeGroup("com.github.mik3y") }
}
```

If repositories are centralized in `android/settings.gradle.kts`, add it inside
`dependencyResolutionManagement.repositories` there instead. Adding it only to
`pluginManagement.repositories` does not configure runtime dependencies.

Android USB write timeout zero means infinite in the underlying
driver, so this plugin rejects zero rather than treating it as nonblocking.
Partial write timeouts return the known byte count; unknown counts return an
error. On open, DTR is asserted when supported. RTS is also asserted when
supported, unless RTS/CTS hardware flow control manages it. These signals tell
devices that the host is ready; on some boards they may also affect reset/boot
pins.

After changing native Android code, stop the app and run it again. Hot reload
or hot restart does not replace the native plugin. The example's Gradle wrapper
and daemon enable native access for Gradle's JNI libraries on recent JDKs.

## Web

Run the example using `flutter run -d chrome`. Use HTTPS or localhost in a
browser supporting [Web Serial](https://developer.chrome.com/docs/capabilities/serial).
The application's **+** button in the port field requests device access. `getSerialList()`
only lists ports already authorized for the site; it does not open a chooser.

Call the web-only `requestPort()` directly from a button handler, before any
asynchronous work, then use the returned path with the regular API:

```dart
final selected = await serial.requestPort();
await serial.connect(selected.path);
```

The browser hides OS device paths. `SerialInfo.path` is a page-scoped ID such as
`web-serial-1`; do not persist it across reloads. Two devices with the same USB
vendor/product IDs still receive separate paths. Cancelling the device chooser
returns a `request-failed` error. Unsupported browsers and insecure contexts
return explicit platform errors.

Web supports 7/8 data bits, 1/2 stop bits, none/odd/even parity, and no flow
control or RTS/CTS. Other settings fail instead of being silently ignored.
Read and connection events use the existing `dataReceived` and
`connectionChanged` broadcast streams. Removing a device closes its connection
and emits a disconnected event with an error.

Recoverable read errors (for example parity, framing, or overflow errors) are
reported on `dataReceived` with code `read-error`. The reader releases the old
stream and resumes on the browser's replacement stream. Fatal errors close the
connection. Attach an `onError` handler when listening to the stream.

Some devices also require DTR or RTS. Web callers can explicitly change those
lines on an open port:

```dart
await serial.setSignals(path, dataTerminalReady: true);
// Set RTS separately only if required by the device and hardware flow control
// is disabled. Omitted signals keep their current state.
await serial.setSignals(path, requestToSend: false);
```

DTR/RTS controls are available through the library API; the application does not
currently expose them in its interface. Output signals are left at browser
defaults until explicitly changed; some boards wire
these lines to reset/boot pins. RTS cannot be set manually with RTS/CTS enabled.
`setSignals()` is currently web-only.

Writes are serialized per port. Successful writes return the input byte count;
a request that expires while queued returns zero without submitting any bytes.
Web cannot perform nonblocking writes with a byte count, so `timeoutMs: 0` is
unsupported. If an in-flight write times out, the connection is closed and a
`write-timeout` error is returned: the browser does not expose the partial byte
count. Disconnecting aborts pending writes and releases stream locks.

## macOS

Ports are discovered through IOKit's `IOSerialBSDClient` services and listed
using their `/dev/cu.*` callout paths, without opening the devices. The plugin
registers the generated Pigeon host API and both generated event stream handlers.
Connections use exclusive, nonblocking descriptors. Reads and queued writes
have a bounded I/O budget every 10 ms on the main dispatch queue. Writes return
the actual byte count on timeout; zero requests one nonblocking attempt.
Device removal closes the port and emits a disconnected event with an error.

Baud rates are applied through `IOSSIOSPEED`; support depends on the device
driver. Data bits 5–8, one/two stop bits, none/odd/even parity, and none/RTS-CTS/
XON-XOFF flow control are supported. Unsupported settings return an error.
Sandboxed consuming apps must enable serial device access in both
`macos/Runner/DebugProfile.entitlements` (Debug/Profile) and
`macos/Runner/Release.entitlements` (Release):

```xml
<key>com.apple.security.device.serial</key>
<true/>
```

The bundled `blue_serial` app includes this entitlement. Without it, ports can
still be listed, but opening them can fail with `Operation not permitted`.
See Apple's [App Sandbox entitlement reference](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html).
App Sandbox must be disabled in the consuming app for local shell access.
After changing native code or entitlements, stop the app completely, rebuild,
and run it again; hot reload and hot restart do not update signed entitlements.

## iOS

The plugin registers every Pigeon host method and both event channels. Port
lists are empty, disconnect is idempotent, and connect/write return
`ios-serial-unsupported`. Listening to either event stream is supported, but no
serial events are produced without a transport backend. The app displays this
limitation in Turkish and English rather than a missing-channel error.

Desktop-style `/dev/cu.*` access is not an iOS transport. The simulator also
does not forward the Mac's serial ports. Generic CH340/CP210x/FTDI USB adapters
cannot be supported simply by adding a permission key.

A future MFi transport must use Apple's
[External Accessory framework](https://developer.apple.com/documentation/externalaccessory/)
and the manufacturer's protocol specification. The app must declare the real
protocol names in
[`UISupportedExternalAccessoryProtocols`](https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedexternalaccessoryprotocols).
BLE serial requires a separate Core Bluetooth backend and the device's GATT
service/characteristic definitions; BLE serial is not a universal protocol.
No placeholder accessory protocols or unused Bluetooth permissions are declared.

Stop and rebuild the app after changing the native plugin. Hot reload and hot
restart cannot register new native channels.

## Native backend contract

Windows still contains the original platform-version scaffolding. The iOS
API reports its transport limitation explicitly. Neither enumerates serial
devices yet; generated bindings alone do not implement device discovery.

For additional platforms, implement `BlueSerialLibApi` and register both stream handlers.
Do blocking I/O off the UI thread. Open ports for reading and writing, apply all
settings, and reject duplicate connections without replacing the existing one.
Keep one reader per connection and attach its path to every data event. Emit
connection changes after successful opens/closes and on unexpected disconnects,
including an error description for I/O failures. Explicitly closing an already
closed port is a no-op. Close readers and ports when the plugin detaches.

The API shape is informed by
[flutter_libserialport](https://github.com/jpnurmi/flutter_libserialport),
including raw byte writes and serial connection settings. It is not a runtime
dependency.
