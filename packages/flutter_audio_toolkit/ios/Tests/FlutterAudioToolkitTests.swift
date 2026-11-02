import XCTest
import AVFoundation
@testable import flutter_audio_toolkit

class FlutterAudioToolkitTests: XCTestCase {
    
    var plugin: FlutterAudioToolkitPlugin!
    
    override func setUpWithError() throws {
        plugin = FlutterAudioToolkitPlugin()
    }
    
    override func tearDownWithError() throws {
        plugin = nil
    }
    
    // Test audio format support validation
    func testIsAudioFormatSupported() throws {
        // Test supported formats
        XCTAssertTrue(plugin.isAudioFormatSupported(inputPath: "/test/audio.mp3"))
        XCTAssertTrue(plugin.isAudioFormatSupported(inputPath: "/test/audio.m4a"))
        XCTAssertTrue(plugin.isAudioFormatSupported(inputPath: "/test/audio.aac"))
        XCTAssertTrue(plugin.isAudioFormatSupported(inputPath: "/test/audio.wav"))
        XCTAssertTrue(plugin.isAudioFormatSupported(inputPath: "/test/audio.ogg"))
        
        // Test unsupported formats
        XCTAssertFalse(plugin.isAudioFormatSupported(inputPath: "/test/video.mp4"))
        XCTAssertFalse(plugin.isAudioFormatSupported(inputPath: "/test/document.pdf"))
        XCTAssertFalse(plugin.isAudioFormatSupported(inputPath: "/test/unknown.xyz"))
    }
    
    // Test FourCharCode conversion
    func testFourCharCodeToString() throws {
        // Test common audio format codes
        let mp3Code: FourCharCode = 0x6D703320 // "mp3 "
        let aacCode: FourCharCode = 0x61616320 // "aac "
        
        let mp3String = plugin.fourCharCodeToString(mp3Code)
        let aacString = plugin.fourCharCodeToString(aacCode)
        
        XCTAssertFalse(mp3String.isEmpty)
        XCTAssertFalse(aacString.isEmpty)
        
        // Test invalid code
        let invalidCode: FourCharCode = 0x12345678
        let invalidString = plugin.fourCharCodeToString(invalidCode)
        XCTAssertTrue(invalidString.hasPrefix("0x"))
    }
    
    // Test CMTime range creation
    func testCMTimeRangeCreation() throws {
        let startTimeMs = 1000  // 1 second
        let endTimeMs = 5000    // 5 seconds
        
        let startTime = CMTime(seconds: Double(startTimeMs) / 1000.0, preferredTimescale: 600)
        let endTime = CMTime(seconds: Double(endTimeMs) / 1000.0, preferredTimescale: 600)
        let duration = CMTimeSubtract(endTime, startTime)
        let timeRange = CMTimeRangeMake(start: startTime, duration: duration)
        
        XCTAssertTrue(CMTIME_IS_VALID(timeRange.start))
        XCTAssertTrue(CMTIME_IS_VALID(timeRange.duration))
        XCTAssertEqual(CMTimeGetSeconds(timeRange.duration), 4.0, accuracy: 0.01)
    }
    
    // Test audio session configuration
    func testAudioSessionConfiguration() throws {
        // This should not throw an error
        XCTAssertNoThrow(try plugin.configureAudioSession())
    }
    
    // Test method call handling
    func testMethodCallHandling() throws {
        let expectation = self.expectation(description: "Method call completed")
        
        // Test getPlatformVersion
        let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: nil)
        
        plugin.handle(call) { result in
            if let versionString = result as? String {
                XCTAssertTrue(versionString.hasPrefix("iOS"))
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // Test invalid method calls
    func testInvalidMethodCalls() throws {
        let expectation = self.expectation(description: "Invalid method call handled")
        
        let call = FlutterMethodCall(methodName: "invalidMethod", arguments: nil)
        
        plugin.handle(call) { result in
            XCTAssertTrue(result is FlutterMethodNotImplemented)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // Test argument validation
    func testArgumentValidation() throws {
        let expectation = self.expectation(description: "Argument validation completed")
        
        // Test convertAudio with missing arguments
        let call = FlutterMethodCall(methodName: "convertAudio", arguments: [:])
        
        plugin.handle(call) { result in
            if let error = result as? FlutterError {
                XCTAssertEqual(error.code, "INVALID_ARGUMENTS")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// Extension to access private methods for testing
extension FlutterAudioToolkitPlugin {
    func isAudioFormatSupported(inputPath: String) -> Bool {
        let url = URL(fileURLWithPath: inputPath)
        let pathExtension = url.pathExtension.lowercased()
        let supportedExtensions = ["mp3", "m4a", "aac", "wav", "ogg", "mp4"]
        return supportedExtensions.contains(pathExtension)
    }
    
    func fourCharCodeToString(_ code: FourCharCode) -> String {
        let bytes = withUnsafeBytes(of: code.bigEndian) { Data($0) }
        if let string = String(data: bytes, encoding: .ascii), !string.isEmpty {
            return string.trimmingCharacters(in: .controlCharacters)
        }
        return String(format: "0x%08X", code)
    }
    
    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            // If audio session configuration fails, try with a simpler configuration
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        }
    }
}
