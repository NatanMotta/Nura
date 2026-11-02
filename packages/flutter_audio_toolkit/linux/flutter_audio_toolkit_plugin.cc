#include "include/flutter_audio_toolkit/flutter_audio_toolkit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <memory>
#include <string>

#define FLUTTER_AUDIO_TOOLKIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_audio_toolkit_plugin_get_type(), \
                               FlutterAudioToolkitPlugin))

struct _FlutterAudioToolkitPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterAudioToolkitPlugin, flutter_audio_toolkit_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void flutter_audio_toolkit_plugin_handle_method_call(
    FlutterAudioToolkitPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "convertAudio") == 0) {
    // For Linux, we'll return a "not implemented" error since we need external libraries
    // like FFmpeg or GStreamer for audio processing, which would require additional setup
    response = fl_method_response_new_error("PLATFORM_NOT_SUPPORTED",
                                          "Audio conversion not implemented on Linux. "
                                          "Consider using FFmpeg or GStreamer for audio processing.",
                                          nullptr);
  } else if (strcmp(method, "trimAudio") == 0) {
    response = fl_method_response_new_error("PLATFORM_NOT_SUPPORTED",
                                          "Audio trimming not implemented on Linux. "
                                          "Consider using FFmpeg or GStreamer for audio processing.",
                                          nullptr);
  } else if (strcmp(method, "extractWaveformData") == 0) {
    response = fl_method_response_new_error("PLATFORM_NOT_SUPPORTED",
                                          "Waveform extraction not implemented on Linux. "
                                          "Consider using FFmpeg or GStreamer for audio processing.",
                                          nullptr);
  } else if (strcmp(method, "isAudioFormatSupported") == 0) {
    // We can provide basic format support information
    FlValue* format_value = fl_value_lookup_string(args, "format");
    if (format_value != nullptr && fl_value_get_type(format_value) == FL_VALUE_TYPE_STRING) {
      const gchar* format = fl_value_get_string(format_value);
      
      // Basic supported formats (would need external libraries for actual processing)
      bool supported = (strcmp(format, "mp3") == 0 || 
                       strcmp(format, "wav") == 0 || 
                       strcmp(format, "ogg") == 0 ||
                       strcmp(format, "aac") == 0 ||
                       strcmp(format, "m4a") == 0);
      
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "supported", fl_value_new_bool(supported));
      fl_value_set_string_take(result, "format", fl_value_new_string(format));
      response = fl_method_response_new_success(result);
    } else {
      response = fl_method_response_new_error("INVALID_ARGUMENTS", 
                                            "Missing format argument", 
                                            nullptr);
    }
  } else if (strcmp(method, "getAudioFileInfo") == 0) {
    response = fl_method_response_new_error("PLATFORM_NOT_SUPPORTED",
                                          "Audio file info extraction not implemented on Linux. "
                                          "Consider using FFmpeg or GStreamer for audio analysis.",
                                          nullptr);
  } else if (strcmp(method, "configureAudioSession") == 0) {
    // Audio session configuration is not needed on Linux
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "success", fl_value_new_bool(TRUE));
    fl_value_set_string_take(result, "message", 
                           fl_value_new_string("Audio session configuration not required on Linux"));
    response = fl_method_response_new_success(result);
  } else {
    response = fl_method_response_new_not_implemented();
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_audio_toolkit_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_audio_toolkit_plugin_parent_class)->dispose(object);
}

static void flutter_audio_toolkit_plugin_class_init(FlutterAudioToolkitPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_audio_toolkit_plugin_dispose;
}

static void flutter_audio_toolkit_plugin_init(FlutterAudioToolkitPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  FlutterAudioToolkitPlugin* plugin = FLUTTER_AUDIO_TOOLKIT_PLUGIN(user_data);
  flutter_audio_toolkit_plugin_handle_method_call(plugin, method_call);
}

void flutter_audio_toolkit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterAudioToolkitPlugin* plugin = FLUTTER_AUDIO_TOOLKIT_PLUGIN(
      g_object_new(flutter_audio_toolkit_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_audio_toolkit",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
