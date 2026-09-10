import Foundation
import AVFoundation
import Combine

public class AudioMeterManager: ObservableObject {
    @Published public var decibelLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    public init() {}
    
    public func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            let tempDir = FileManager.default.temporaryDirectory
            let url = tempDir.appendingPathComponent("procam_temp_audio_meter.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let avgPower = recorder.averagePower(forChannel: 0) // -160 to 0 dB
                // Normalize -60dB ... 0dB to 0.0 ... 1.0
                let normalized = max(0.0, min(1.0, (avgPower + 60.0) / 60.0))
                DispatchQueue.main.async {
                    self.decibelLevel = normalized
                }
            }
        } catch {
            print("Failed to start audio metering: \(error)")
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }
}
