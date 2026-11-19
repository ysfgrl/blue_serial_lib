import Flutter
import XCTest
@testable import blue_serial_lib

class RunnerTests: XCTestCase {
  func testIOSHasNoDesktopSerialPorts() throws {
    let plugin = BlueSerialLibPlugin()
    var listed = false
    plugin.getSerialList { result in
      listed = true
      XCTAssertTrue((try? result.get().isEmpty) == true)
    }
    XCTAssertTrue(listed)
    plugin.getConnectedPorts { result in
      XCTAssertTrue((try? result.get().isEmpty) == true)
    }
  }

  func testUnsupportedOperationsReturnPlatformError() {
    let plugin = BlueSerialLibPlugin()
    let config = SerialConfigMessage(
      baudRate: 115200, dataBits: 8, stopBits: .one,
      parity: .none, flowControl: .none)
    plugin.connect(path: "/dev/cu.usbserial", config: config) { result in
      guard case .failure(let error) = result else {
        return XCTFail("iOS must not pretend to open a desktop serial port")
      }
      XCTAssertEqual((error as? PigeonError)?.code, "ios-serial-unsupported")
    }
    plugin.write(path: "/dev/cu.usbserial",
                 data: FlutterStandardTypedData(bytes: Data([65])), timeoutMs: 1000) { result in
      guard case .failure(let error) = result else {
        return XCTFail("iOS must not report bytes written without a transport")
      }
      XCTAssertEqual((error as? PigeonError)?.code, "ios-serial-unsupported")
    }
  }

  func testDisconnectIsIdempotent() {
    let plugin = BlueSerialLibPlugin()
    for _ in 0..<2 {
      plugin.disconnect(path: "/dev/cu.usbserial") { result in
        if case .failure(let error) = result { XCTFail("Disconnect failed: \(error)") }
      }
    }
  }
}
