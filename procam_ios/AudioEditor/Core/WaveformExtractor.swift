import Foundation
import AVFoundation

/// Extracts audio PCM amplitudes from audio files for high-performance waveform rendering
public final class WaveformExtractor {
    
    public static let shared = WaveformExtractor()
    
    private init() {}
    
    /// Reads audio file and downsamples PCM amplitudes into `sampleCount` normalized bars (0.0 ... 1.0)
    public func extractAmplitudes(from url: URL, targetCount: Int = 70) async -> [Float] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let audioFile = try? AVAudioFile(forReading: url) else {
                    continuation.resume(returning: AudioTrack.placeholderSamples(count: targetCount))
                    return
                }
                
                let format = audioFile.processingFormat
                let totalFrames = AVAudioFrameCount(audioFile.length)
                
                guard totalFrames > 0,
                      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
                    continuation.resume(returning: AudioTrack.placeholderSamples(count: targetCount))
                    return
                }
                
                do {
                    try audioFile.read(into: buffer)
                } catch {
                    continuation.resume(returning: AudioTrack.placeholderSamples(count: targetCount))
                    return
                }
                
                guard let channelData = buffer.floatChannelData else {
                    continuation.resume(returning: AudioTrack.placeholderSamples(count: targetCount))
                    return
                }
                
                let channelSamples = channelData[0]
                let framesCount = Int(buffer.frameLength)
                let chunkSize = max(1, framesCount / targetCount)
                
                var samples: [Float] = []
                samples.reserveCapacity(targetCount)
                
                for i in 0..<targetCount {
                    let startFrame = i * chunkSize
                    let endFrame = min(startFrame + chunkSize, framesCount)
                    guard startFrame < framesCount else {
                        samples.append(0.1)
                        continue
                    }
                    
                    var sumSquare: Float = 0.0
                    var count: Float = 0.0
                    for frame in startFrame..<endFrame {
                        let sample = channelSamples[frame]
                        sumSquare += sample * sample
                        count += 1.0
                    }
                    
                    let rms = count > 0 ? sqrt(sumSquare / count) : 0.0
                    samples.append(rms)
                }
                
                // Normalize amplitudes between 0.1 and 1.0
                let maxRms = samples.max() ?? 1.0
                let normalized: [Float] = samples.map { sample in
                    if maxRms > 0.0001 {
                        let val = sample / maxRms
                        return max(0.12, min(1.0, val))
                    } else {
                        return 0.15
                    }
                }
                
                continuation.resume(returning: normalized)
            }
        }
    }
}
