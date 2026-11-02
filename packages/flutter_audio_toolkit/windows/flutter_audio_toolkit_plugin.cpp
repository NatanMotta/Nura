#include "include/flutter_audio_toolkit/flutter_audio_toolkit_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

namespace flutter_audio_toolkit {

// static
void FlutterAudioToolkitPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_audio_toolkit",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterAudioToolkitPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterAudioToolkitPlugin::FlutterAudioToolkitPlugin() {}

FlutterAudioToolkitPlugin::~FlutterAudioToolkitPlugin() {}

void FlutterAudioToolkitPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string &method_name = method_call.method_name();
  
  if (method_name.compare("convertAudio") == 0) {
    // Windows audio conversion would require Windows Media Foundation or DirectShow
    // This is a complex implementation that would need additional dependencies
    result->Error("PLATFORM_NOT_SUPPORTED", 
                  "Audio conversion not implemented on Windows. "
                  "Consider using Windows Media Foundation or FFmpeg for audio processing.");
  } else if (method_name.compare("trimAudio") == 0) {
    result->Error("PLATFORM_NOT_SUPPORTED", 
                  "Audio trimming not implemented on Windows. "
                  "Consider using Windows Media Foundation or FFmpeg for audio processing.");
  } else if (method_name.compare("extractWaveformData") == 0) {
    result->Error("PLATFORM_NOT_SUPPORTED", 
                  "Waveform extraction not implemented on Windows. "
                  "Consider using Windows Media Foundation or FFmpeg for audio processing.");
  } else if (method_name.compare("isAudioFormatSupported") == 0) {
    // We can provide basic format support information
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Missing arguments");
      return;
    }
    
    auto format_it = arguments->find(flutter::EncodableValue("format"));
    if (format_it == arguments->end() || !std::holds_alternative<std::string>(format_it->second)) {
      result->Error("INVALID_ARGUMENTS", "Missing format argument");
      return;
    }
    
    std::string format = std::get<std::string>(format_it->second);
    
    // Basic supported formats (would need external libraries for actual processing)
    bool supported = (format == "mp3" || format == "wav" || format == "ogg" || 
                     format == "aac" || format == "m4a");
    
    flutter::EncodableMap response;
    response[flutter::EncodableValue("supported")] = flutter::EncodableValue(supported);
    response[flutter::EncodableValue("format")] = flutter::EncodableValue(format);
    
    result->Success(flutter::EncodableValue(response));
  } else if (method_name.compare("getAudioFileInfo") == 0) {
    result->Error("PLATFORM_NOT_SUPPORTED", 
                  "Audio file info extraction not implemented on Windows. "
                  "Consider using Windows Media Foundation or FFmpeg for audio analysis.");
  } else if (method_name.compare("configureAudioSession") == 0) {
    // Audio session configuration is not needed on Windows in the same way as iOS
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(true);
    response[flutter::EncodableValue("message")] = 
        flutter::EncodableValue("Audio session configuration not required on Windows");
    
    result->Success(flutter::EncodableValue(response));
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_audio_toolkit
