#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_audio_toolkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_audio_toolkit'
  s.version          = '0.3.8'
  s.summary          = 'A Flutter plugin for audio conversion, trimming, and waveform extraction using native platform APIs.'
  s.description      = <<-DESC
Audio plugin with native support for MP3/WAV/OGG to AAC/M4A conversion, precise trimming, and waveform extraction for visualization
                       DESC
  s.homepage         = 'https://github.com/Rameshwar-Amancha/flutter_audio_toolkit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'RameshwarAmancha' => 'rameshwar.amancha@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
