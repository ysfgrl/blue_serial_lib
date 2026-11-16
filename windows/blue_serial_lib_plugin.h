#ifndef FLUTTER_PLUGIN_BLUE_SERIAL_LIB_PLUGIN_H_
#define FLUTTER_PLUGIN_BLUE_SERIAL_LIB_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace blue_serial_lib {

class BlueSerialLibPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BlueSerialLibPlugin();

  virtual ~BlueSerialLibPlugin();

  // Disallow copy and assign.
  BlueSerialLibPlugin(const BlueSerialLibPlugin&) = delete;
  BlueSerialLibPlugin& operator=(const BlueSerialLibPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace blue_serial_lib

#endif  // FLUTTER_PLUGIN_BLUE_SERIAL_LIB_PLUGIN_H_
