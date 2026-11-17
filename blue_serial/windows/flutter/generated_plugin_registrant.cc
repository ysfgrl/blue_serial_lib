//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <blue_serial_lib/blue_serial_lib_plugin_c_api.h>
#include <file_saver/file_saver_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  BlueSerialLibPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BlueSerialLibPluginCApi"));
  FileSaverPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSaverPlugin"));
}
