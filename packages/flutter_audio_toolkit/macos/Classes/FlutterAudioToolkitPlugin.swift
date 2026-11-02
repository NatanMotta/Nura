import Cocoa
import FlutterMacOS
import AVFoundation

public class FlutterAudioToolkitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_audio_toolkit", binaryMessenger: registrar.messenger)
        let instance = FlutterAudioToolkitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        
        switch call.method {
        case "convertAudio":
            convertAudio(arguments: arguments, result: result)
        case "trimAudio":
            trimAudio(arguments: arguments, result: result)
        case "extractWaveformData":
            extractWaveformData(arguments: arguments, result: result)
        case "isAudioFormatSupported":
            isAudioFormatSupported(arguments: arguments, result: result)
        case "getAudioFileInfo":
            getAudioFileInfo(arguments: arguments, result: result)
        case "configureAudioSession":
            configureAudioSession(arguments: arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func convertAudio(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let outputFormat = args["outputFormat"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }
        
        let quality = args["quality"] as? Double ?? 0.8
        let bitrate = args["bitrate"] as? Int ?? 128000
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let inputURL = URL(fileURLWithPath: inputPath)
                let outputURL = URL(fileURLWithPath: outputPath)
                
                let asset = AVURLAsset(url: inputURL)
                
                // Ensure output directory exists
                let outputDirectory = outputURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Remove existing output file if it exists
                if FileManager.default.fileExists(atPath: outputPath) {
                    try FileManager.default.removeItem(at: outputURL)
                }
                
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXPORT_SESSION_ERROR", message: "Failed to create export session", details: nil))
                    }
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = self.getAVFileType(for: outputFormat)
                exportSession.shouldOptimizeForNetworkUse = true
                
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            result([
                                "success": true,
                                "outputPath": outputPath,
                                "message": "Audio conversion completed successfully"
                            ])
                        case .failed:
                            result(FlutterError(
                                code: "CONVERSION_FAILED",
                                message: exportSession.error?.localizedDescription ?? "Unknown conversion error",
                                details: nil
                            ))
                        case .cancelled:
                            result(FlutterError(code: "CONVERSION_CANCELLED", message: "Conversion was cancelled", details: nil))
                        default:
                            result(FlutterError(code: "CONVERSION_UNKNOWN", message: "Unknown conversion status", details: nil))
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "CONVERSION_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func trimAudio(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let startTime = args["startTime"] as? Double,
              let endTime = args["endTime"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let inputURL = URL(fileURLWithPath: inputPath)
                let outputURL = URL(fileURLWithPath: outputPath)
                
                let asset = AVURLAsset(url: inputURL)
                
                // Ensure output directory exists
                let outputDirectory = outputURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Remove existing output file if it exists
                if FileManager.default.fileExists(atPath: outputPath) {
                    try FileManager.default.removeItem(at: outputURL)
                }
                
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXPORT_SESSION_ERROR", message: "Failed to create export session", details: nil))
                    }
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                exportSession.shouldOptimizeForNetworkUse = true
                
                // Set time range for trimming
                let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
                let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
                let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
                exportSession.timeRange = timeRange
                
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            result([
                                "success": true,
                                "outputPath": outputPath,
                                "message": "Audio trimming completed successfully"
                            ])
                        case .failed:
                            result(FlutterError(
                                code: "TRIMMING_FAILED",
                                message: exportSession.error?.localizedDescription ?? "Unknown trimming error",
                                details: nil
                            ))
                        case .cancelled:
                            result(FlutterError(code: "TRIMMING_CANCELLED", message: "Trimming was cancelled", details: nil))
                        default:
                            result(FlutterError(code: "TRIMMING_UNKNOWN", message: "Unknown trimming status", details: nil))
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "TRIMMING_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func extractWaveformData(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let audioPath = args["audioPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing audioPath argument", details: nil))
            return
        }
        
        let samplesPerSecond = args["samplesPerSecond"] as? Int ?? 100
        let normalize = args["normalize"] as? Bool ?? true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioURL = URL(fileURLWithPath: audioPath)
                let audioFile = try AVAudioFile(forReading: audioURL)
                
                let format = audioFile.processingFormat
                let frameCount = AVAudioFrameCount(audioFile.length)
                
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "BUFFER_ERROR", message: "Failed to create audio buffer", details: nil))
                    }
                    return
                }
                
                try audioFile.read(into: buffer)
                
                guard let floatData = buffer.floatChannelData else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "DATA_ERROR", message: "Failed to get float channel data", details: nil))
                    }
                    return
                }
                
                let channelCount = Int(buffer.format.channelCount)
                let frameLength = Int(buffer.frameLength)
                let sampleRate = buffer.format.sampleRate
                
                // Calculate samples per chunk for desired samplesPerSecond
                let samplesPerChunk = max(1, Int(sampleRate) / samplesPerSecond)
                let numberOfSamples = frameLength / samplesPerChunk
                
                var waveformData: [Double] = []
                
                for i in 0..<numberOfSamples {
                    let startIndex = i * samplesPerChunk
                    let endIndex = min(startIndex + samplesPerChunk, frameLength)
                    
                    var maxAmplitude: Float = 0.0
                    
                    // Process all channels and find max amplitude
                    for channel in 0..<channelCount {
                        for j in startIndex..<endIndex {
                            let amplitude = abs(floatData[channel][j])
                            maxAmplitude = max(maxAmplitude, amplitude)
                        }
                    }
                    
                    waveformData.append(Double(maxAmplitude))
                }
                
                // Normalize if requested
                if normalize && !waveformData.isEmpty {
                    let maxValue = waveformData.max() ?? 1.0
                    if maxValue > 0 {
                        waveformData = waveformData.map { $0 / maxValue }
                    }
                }
                
                DispatchQueue.main.async {
                    result([
                        "success": true,
                        "waveformData": waveformData,
                        "sampleRate": sampleRate,
                        "duration": Double(frameLength) / sampleRate,
                        "samplesCount": waveformData.count
                    ])
                }
                
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "WAVEFORM_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func isAudioFormatSupported(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let format = args["format"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing format argument", details: nil))
            return
        }
        
        let supportedFormats = ["mp3", "wav", "aac", "m4a", "ogg"]
        let isSupported = supportedFormats.contains(format.lowercased())
        
        result([
            "supported": isSupported,
            "format": format
        ])
    }
    
    private func getAudioFileInfo(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let audioPath = args["audioPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing audioPath argument", details: nil))
            return
        }
        
        do {
            let audioURL = URL(fileURLWithPath: audioPath)
            let audioFile = try AVAudioFile(forReading: audioURL)
            
            let format = audioFile.processingFormat
            let duration = Double(audioFile.length) / format.sampleRate
            
            // Get file size
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: audioPath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            result([
                "success": true,
                "duration": duration,
                "sampleRate": format.sampleRate,
                "channels": format.channelCount,
                "bitDepth": format.settings[AVLinearPCMBitDepthKey] as? Int ?? 0,
                "fileSize": fileSize,
                "format": audioURL.pathExtension.lowercased()
            ])
            
        } catch {
            result(FlutterError(code: "AUDIO_INFO_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func configureAudioSession(arguments: [String: Any]?, result: @escaping FlutterResult) {
        // On macOS, we don't need to configure audio session like iOS
        // This is mainly for compatibility
        result([
            "success": true,
            "message": "Audio session configuration not required on macOS"
        ])
    }
    
    private func getAVFileType(for format: String) -> AVFileType {
        switch format.lowercased() {
        case "mp3":
            return .mp3
        case "wav":
            return .wav
        case "aac":
            return .aac
        case "m4a":
            return .m4a
        default:
            return .m4a // Default fallback
        }
    }
}
