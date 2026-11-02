#ifndef FLUTTER_PLUGIN_FLUTTER_AUDIO_TOOLKIT_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_AUDIO_TOOLKIT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_audio_toolkit {

class FlutterAudioToolkitPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterAudioToolkitPlugin();

  virtual ~FlutterAudioToolkitPlugin();

  // Disallow copy and assign.
  FlutterAudioToolkitPlugin(const FlutterAudioToolkitPlugin&) = delete;
  FlutterAudioToolkitPlugin& operator=(const FlutterAudioToolkitPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_audio_toolkit

#endif  // FLUTTER_PLUGIN_FLUTTER_AUDIO_TOOLKIT_PLUGIN_H_
