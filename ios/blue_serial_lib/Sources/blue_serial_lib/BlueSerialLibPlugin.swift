import Flutter
import UIKit

/// iOS does not expose desktop-style serial device nodes to applications.
/// Register the complete API so callers receive a platform error instead of a
/// missing-channel error. A hardware-specific transport needs its own backend.
public class BlueSerialLibPlugin: NSObject, FlutterPlugin, BlueSerialLibApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = BlueSerialLibPlugin()
    let messenger = registrar.messenger()
    BlueSerialLibApiSetup.setUp(binaryMessenger: messenger, api: instance)
    SerialDataReceivedStreamHandler.register(
      with: messenger, streamHandler: SerialDataReceivedStreamHandler())
    SerialConnectionChangedStreamHandler.register(
      with: messenger, streamHandler: SerialConnectionChangedStreamHandler())
    registrar.publish(instance)
  }

  func getSerialList(completion: @escaping (Result<[SerialInfoMessage], Error>) -> Void) {
    completion(.success([]))
  }

  func getConnectedPorts(completion: @escaping (Result<[SerialInfoMessage], Error>) -> Void) {
    completion(.success([]))
  }

  func connect(path: String, config: SerialConfigMessage,
               completion: @escaping (Result<Void, Error>) -> Void) {
    completion(.failure(unsupported()))
  }

  func disconnect(path: String, completion: @escaping (Result<Void, Error>) -> Void) {
    // There are no open ports. Match the API's idempotent disconnect contract.
    completion(.success(()))
  }

  func write(path: String, data: FlutterStandardTypedData, timeoutMs: Int64,
             completion: @escaping (Result<Int64, Error>) -> Void) {
    completion(.failure(unsupported()))
  }

  private func unsupported() -> PigeonError {
    PigeonError(
      code: "ios-serial-unsupported",
      message: "Generic USB serial ports are not available on iOS. This plugin does not yet implement an MFi or BLE transport. The iOS simulator cannot access the Mac's serial ports.",
      details: nil)
  }
}
