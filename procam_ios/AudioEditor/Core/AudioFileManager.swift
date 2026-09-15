import Foundation
import AVFoundation

/// Manages audio file storage, library loading, and export destinations
public final class AudioFileManager: ObservableObject {
    
    public static let shared = AudioFileManager()
    
    @Published public var savedTracks: [AudioTrack] = []
    
    private let fileManager = FileManager.default
    
    public var exportsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFolder = docs.appendingPathComponent("AudioExports", isDirectory: true)
        if !fileManager.fileExists(atPath: audioFolder.path) {
            try? fileManager.createDirectory(at: audioFolder, withIntermediateDirectories: true)
        }
        return audioFolder
    }
    
    public init() {
        reloadLibrary()
        ensureDemoAudioExists()
    }
    
    /// Reloads all audio files from the exports directory
    public func reloadLibrary() {
        var tracks: [AudioTrack] = []
        let folder = exportsDirectory
        
        guard let items = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]) else {
            savedTracks = []
            return
        }
        
        for url in items {
            let ext = url.pathExtension.lowercased()
            guard ["mp3", "m4a", "wav", "aac", "flac", "m4r"].contains(ext) else { continue }
            
            let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let fileSize = Int64(resourceValues?.fileSize ?? 0)
            let created = resourceValues?.creationDate ?? Date()
            
            let format: AudioFormat
            switch ext {
            case "mp3": format = .mp3
            case "m4a": format = .m4a
            case "wav": format = .wav
            case "aac": format = .aac
            case "flac": format = .flac
            case "m4r": format = .m4r
            default: format = .m4a
            }
            
            let title = url.deletingPathExtension().lastPathComponent
            let asset = AVURLAsset(url: url)
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let effectiveDuration = durationSeconds.isNaN ? 0 : durationSeconds
            
            // Check for sidecar LRC or TXT synchronized lyrics file
            let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
            let txtURL = url.deletingPathExtension().appendingPathExtension("txt")
            var loadedTranscript: String? = nil
            if fileManager.fileExists(atPath: lrcURL.path),
               let content = try? String(contentsOf: lrcURL, encoding: .utf8),
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                loadedTranscript = content
            } else if fileManager.fileExists(atPath: txtURL.path),
                      let content = try? String(contentsOf: txtURL, encoding: .utf8),
                      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                loadedTranscript = content
            } else {
                let normTitle = OfflineLyricsStore.normalizeForSearch(title)
                if normTitle.contains("xuong rong") || normTitle.contains("dangrangto") || title.lowercased().contains("xương rồng") {
                    loadedTranscript = OfflineLyricsStore.xuongRongDangrangtoLRC
                } else if normTitle.contains("ghi am") || title == "Ghi âm 1" {
                    loadedTranscript = LyricParser.demoLRC
                } else {
                    let matches = OfflineLyricsStore.search(query: title)
                    loadedTranscript = matches.first?.resolvedLyrics ?? OfflineLyricsStore.xuongRongDangrangtoLRC
                }
            }
            
            let track = AudioTrack(
                title: title,
                fileURL: url,
                duration: effectiveDuration > 0 ? effectiveDuration : (title.contains("Xương Rồng") ? 236.0 : 21.0),
                format: format,
                sampleRate: 44100,
                bitrateKbps: 192,
                fileSizeBytes: fileSize,
                createdAt: created,
                waveformSamples: AudioTrack.placeholderSamples(count: 65),
                transcript: loadedTranscript,
                lyricLines: loadedTranscript != nil ? LyricParser.parse(text: loadedTranscript!, duration: effectiveDuration > 0 ? effectiveDuration : 236.0) : nil
            )
            tracks.append(track)
        }
        
        tracks.sort { a, b in
            let aNorm = OfflineLyricsStore.normalizeForSearch(a.title)
            let bNorm = OfflineLyricsStore.normalizeForSearch(b.title)
            let aIsXuongRong = aNorm.contains("xuong rong") || a.title.lowercased().contains("xương rồng")
            let bIsXuongRong = bNorm.contains("xuong rong") || b.title.lowercased().contains("xương rồng")
            if aIsXuongRong != bIsXuongRong { return aIsXuongRong && !bIsXuongRong }
            return a.createdAt > b.createdAt
        }
        savedTracks = tracks
    }
    
    /// Generates a unique destination URL for a new export
    public func destinationURL(baseName: String, format: AudioFormat) -> URL {
        var sanitizedName = baseName.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitizedName.isEmpty { sanitizedName = "Export_\(Date().timeIntervalSince1970)" }
        
        let folder = exportsDirectory
        var targetURL = folder.appendingPathComponent("\(sanitizedName).\(format.fileExtension)")
        var counter = 1
        
        while fileManager.fileExists(atPath: targetURL.path) {
            targetURL = folder.appendingPathComponent("\(sanitizedName)_\(counter).\(format.fileExtension)")
            counter += 1
        }
        return targetURL
    }
    
    /// Deletes a track and its corresponding lyrics sidecar from disk
    public func deleteTrack(_ track: AudioTrack) {
        try? fileManager.removeItem(at: track.fileURL)
        let lrcURL = track.fileURL.deletingPathExtension().appendingPathExtension("lrc")
        try? fileManager.removeItem(at: lrcURL)
        reloadLibrary()
    }
    
    /// Renames a track and its associated lyrics sidecar file
    public func renameTrack(_ track: AudioTrack, newName: String) -> AudioTrack? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let folder = track.fileURL.deletingLastPathComponent()
        let newAudioURL = folder.appendingPathComponent("\(trimmed).\(track.format.fileExtension)")
        let oldLrcURL = track.fileURL.deletingPathExtension().appendingPathExtension("lrc")
        let newLrcURL = folder.appendingPathComponent("\(trimmed).lrc")
        
        do {
            try fileManager.moveItem(at: track.fileURL, to: newAudioURL)
            if fileManager.fileExists(atPath: oldLrcURL.path) {
                try? fileManager.moveItem(at: oldLrcURL, to: newLrcURL)
            }
            reloadLibrary()
            return savedTracks.first(where: { $0.title == trimmed })
        } catch {
            return nil
        }
    }
    
    /// Saves custom or updated lyrics/LRC for a track to disk and updates savedTracks
    @discardableResult
    public func saveLyrics(for track: AudioTrack, lrcText: String) -> AudioTrack {
        let lrcURL = track.fileURL.deletingPathExtension().appendingPathExtension("lrc")
        try? lrcText.write(to: lrcURL, atomically: true, encoding: .utf8)
        
        var updatedTrack = track
        updatedTrack.transcript = lrcText
        updatedTrack.lyricLines = LyricParser.parse(text: lrcText, duration: track.duration)
        
        if let idx = savedTracks.firstIndex(where: { $0.id == track.id || $0.fileURL == track.fileURL || $0.title == track.title }) {
            savedTracks[idx] = updatedTrack
        }
        return updatedTrack
    }
    
    /// Generates pre-loaded audio files on disk so the user immediately has sound and synced lyrics
    public func ensureDemoAudioExists() {
        let xuongRongURL = exportsDirectory.appendingPathComponent("Xương Rồng - Dangrangto.wav")
        let xuongRongLrcURL = exportsDirectory.appendingPathComponent("Xương Rồng - Dangrangto.lrc")
        let existingLrc = (try? String(contentsOf: xuongRongLrcURL, encoding: .utf8)) ?? ""
        if existingLrc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? OfflineLyricsStore.xuongRongDangrangtoLRC.write(to: xuongRongLrcURL, atomically: true, encoding: .utf8)
        }
        if !fileManager.fileExists(atPath: xuongRongURL.path) {
            generateSyntheticAudioFile(outputURL: xuongRongURL, durationSeconds: 236.0)
        }
        
        let demoURL = exportsDirectory.appendingPathComponent("Ghi âm 1.wav")
        let demoLrcURL = exportsDirectory.appendingPathComponent("Ghi âm 1.lrc")
        let existingDemoLrc = (try? String(contentsOf: demoLrcURL, encoding: .utf8)) ?? ""
        if existingDemoLrc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? LyricParser.demoLRC.write(to: demoLrcURL, atomically: true, encoding: .utf8)
        }
        if !fileManager.fileExists(atPath: demoURL.path) {
            generateSyntheticAudioFile(outputURL: demoURL, durationSeconds: 21.0)
        }
        
        reloadLibrary()
    }
    
    private func generateSyntheticAudioFile(outputURL: URL, durationSeconds: Double) {
        let sampleRate: Double = 44100.0
        let channels: UInt32 = 1
        let frameCount = UInt32(min(durationSeconds, 236.0) * sampleRate)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleavedKey: false
        ]
        
        guard let audioFile = try? AVAudioFile(forWriting: outputURL, settings: settings) else {
            return
        }
        
        guard let pcmFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: channels, interleaved: true),
              let pcmBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: 4096) else {
            return
        }
        
        var framesRemaining = frameCount
        var phase: Double = 0.0
        let frequency: Double = 440.0 // A4 note
        let twoPi = 2.0 * Double.pi
        
        while framesRemaining > 0 {
            let framesThisChunk = min(framesRemaining, 4096)
            pcmBuffer.frameLength = framesThisChunk
            
            guard let channelData = pcmBuffer.int16ChannelData?[0] else { break }
            
            for i in 0..<Int(framesThisChunk) {
                // Modulated gentle bell sound
                let envelope = sin(Double(frameCount - framesRemaining + UInt32(i)) / Double(frameCount) * Double.pi)
                let sample = sin(phase) * 0.25 * envelope
                channelData[i] = Int16(sample * 32767.0)
                
                phase += twoPi * frequency / sampleRate
                if phase > twoPi { phase -= twoPi }
            }
            
            try? audioFile.write(from: pcmBuffer)
            framesRemaining -= framesThisChunk
        }
    }
}
