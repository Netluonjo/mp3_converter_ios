import Foundation
import SwiftUI

/// Represents a single audio track in the editor, either imported or exported.
public struct AudioTrack: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var fileURL: URL
    public var duration: TimeInterval
    public var format: AudioFormat
    public var sampleRate: Int
    public var bitrateKbps: Int
    public var fileSizeBytes: Int64
    public var createdAt: Date
    public var waveformSamples: [Float]
    public var transcript: String?
    public var lyricLines: [LyricLine]?
    
    public init(
        id: UUID = UUID(),
        title: String,
        fileURL: URL,
        duration: TimeInterval,
        format: AudioFormat = .m4a,
        sampleRate: Int = 44100,
        bitrateKbps: Int = 192,
        fileSizeBytes: Int64 = 0,
        createdAt: Date = Date(),
        waveformSamples: [Float] = [],
        transcript: String? = nil,
        lyricLines: [LyricLine]? = nil
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.format = format
        self.sampleRate = sampleRate
        self.bitrateKbps = bitrateKbps
        self.fileSizeBytes = fileSizeBytes
        self.createdAt = createdAt
        self.waveformSamples = waveformSamples
        self.transcript = transcript
        self.lyricLines = lyricLines
    }
    
    /// Synchronized lyric lines, parsed on-demand from transcript if lyricLines is nil
    public var lyrics: [LyricLine] {
        if let lines = lyricLines, !lines.isEmpty {
            return lines
        }
        if let text = transcript, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LyricParser.parse(text: text, duration: duration)
        }
        return []
    }
    
    /// Formatted duration string e.g. "00:21" or "03:45"
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formatted file size string e.g. "2.4 MB"
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSizeBytes)
    }
    
    /// Generate synthetic preview samples if waveform wasn't yet extracted
    public static func placeholderSamples(count: Int = 60) -> [Float] {
        var samples: [Float] = []
        for i in 0..<count {
            let progress = Float(i) / Float(count)
            // Bell-shaped amplitude wave with micro-variations
            let bell = sin(progress * .pi)
            let wobble = sin(progress * 16.0) * 0.2 + cos(progress * 8.0) * 0.15
            let amplitude = max(0.1, min(1.0, (bell * 0.7 + wobble * 0.3) + 0.15))
            samples.append(amplitude)
        }
        return samples
    }
    
    /// Sample demo recording matching the screenshot "Ghi âm 1"
    public static var demoTrack: AudioTrack {
        let demoUrl = AudioFileManager.shared.exportsDirectory.appendingPathComponent("Ghi âm 1.m4a")
        return AudioTrack(
            title: "Ghi âm 1",
            fileURL: demoUrl,
            duration: 21.0,
            format: .m4a,
            sampleRate: 44100,
            bitrateKbps: 192,
            fileSizeBytes: 512_000,
            createdAt: Date(),
            waveformSamples: placeholderSamples(count: 65),
            transcript: LyricParser.demoLRC,
            lyricLines: LyricParser.parse(text: LyricParser.demoLRC, duration: 21.0)
        )
    }
}
