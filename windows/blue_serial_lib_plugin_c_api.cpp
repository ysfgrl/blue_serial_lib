#include "include/blue_serial_lib/blue_serial_lib_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "blue_serial_lib_plugin.h"

void BlueSerialLibPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  blue_serial_lib::BlueSerialLibPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
