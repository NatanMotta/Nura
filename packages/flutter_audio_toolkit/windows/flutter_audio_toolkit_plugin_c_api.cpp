#include "include/flutter_audio_toolkit/flutter_audio_toolkit_plugin.h"

#include <flutter/plugin_registrar_windows.h>

void FlutterAudioToolkitPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_audio_toolkit::FlutterAudioToolkitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
