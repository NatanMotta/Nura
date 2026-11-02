#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_audio_toolkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_audio_toolkit'
  s.version          = '0.3.8'
  s.summary          = 'A Flutter plugin for audio conversion and waveform extraction.'
  s.description      = <<-DESC
A Flutter plugin that provides native audio conversion and waveform extraction capabilities.
Supports converting audio files (mp3, wav, ogg) to AAC/M4A formats and extracting waveform data for visualization.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_audio_toolkit/Sources/flutter_audio_toolkit/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Add required frameworks
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'CoreMedia', 'Accelerate'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy manifest for audio processing
  s.resource_bundles = {'flutter_audio_toolkit_privacy' => ['flutter_audio_toolkit/Sources/flutter_audio_toolkit/PrivacyInfo.xcprivacy']}
end
