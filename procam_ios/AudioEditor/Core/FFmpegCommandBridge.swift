import Foundation

/// Generates and manages FFmpeg command strings conforming to user specifications
/// and acts as a bridge for FFmpegKit execution.
public struct FFmpegCommandBridge {
    
    // MARK: - Command String Builders
    
    /// Extract audio from video: -i input_video.mp4 -vn -c:a libmp3lame -b:a 320k output.mp3
    public static func buildVideoToAudioCommand(
        inputVideoURL: URL,
        outputAudioURL: URL,
        format: AudioFormat = .mp3,
        bitrateKbps: Int = 320
    ) -> String {
        let codec: String
        switch format {
        case .mp3: codec = "libmp3lame"
        case .m4a, .aac, .m4r: codec = "aac"
        case .wav: codec = "pcm_s16le"
        case .flac: codec = "flac"
        }
        
        if format == .wav {
            return "-i \"\(inputVideoURL.path)\" -vn -c:a \(codec) \"\(outputAudioURL.path)\""
        }
        return "-i \"\(inputVideoURL.path)\" -vn -c:a \(codec) -b:a \(bitrateKbps)k \"\(outputAudioURL.path)\""
    }
    
    /// Audio Cutter / Trimmer: -ss 00:00:15 -to 00:00:45 -i input.mp3 -c copy output_trimmed.mp3
    public static func buildTrimCommand(
        inputAudioURL: URL,
        outputAudioURL: URL,
        startTimeSeconds: TimeInterval,
        endTimeSeconds: TimeInterval,
        losslessCopy: Bool = true
    ) -> String {
        let startStr = formatTimestamp(startTimeSeconds)
        let endStr = formatTimestamp(endTimeSeconds)
        let codecArg = losslessCopy ? "-c copy" : "-c:a libmp3lame"
        
        return "-ss \(startStr) -to \(endStr) -i \"\(inputAudioURL.path)\" \(codecArg) \"\(outputAudioURL.path)\""
    }
    
    /// Audio Merger: -i audio1.mp3 -i audio2.mp3 -filter_complex "[0:0][1:0]concat=n=2:v=0:a=1[out]" -map "[out]" output_merged.mp3
    public static func buildMergeCommand(
        inputAudioURLs: [URL],
        outputAudioURL: URL
    ) -> String {
        guard !inputAudioURLs.isEmpty else { return "" }
        
        var inputArgs = ""
        var filterInputs = ""
        
        for (index, url) in inputAudioURLs.enumerated() {
            inputArgs += "-i \"\(url.path)\" "
            filterInputs += "[\(index):0]"
        }
        
        let filterComplex = "-filter_complex \"\(filterInputs)concat=n=\(inputAudioURLs.count):v=0:a=1[out]\" -map \"[out]\""
        return "\(inputArgs.trimmingCharacters(in: .whitespaces)) \(filterComplex) \"\(outputAudioURL.path)\""
    }
    
    /// Volume Booster: -i input.mp3 -filter:a "volume=1.5" output_boosted.mp3
    public static func buildVolumeBoostCommand(
        inputAudioURL: URL,
        outputAudioURL: URL,
        multiplier: Float
    ) -> String {
        return "-i \"\(inputAudioURL.path)\" -filter:a \"volume=\(String(format: "%.2f", multiplier))\" \"\(outputAudioURL.path)\""
    }
    
    /// Fade In / Fade Out: -i input.mp3 -filter:a "afade=t=in:ss=0:d=3,afade=t=out:st=27:d=3" output_faded.mp3
    public static func buildFadeCommand(
        inputAudioURL: URL,
        outputAudioURL: URL,
        totalDuration: TimeInterval,
        fadeInSeconds: TimeInterval,
        fadeOutSeconds: TimeInterval
    ) -> String {
        var filters: [String] = []
        if fadeInSeconds > 0 {
            filters.append("afade=t=in:ss=0:d=\(String(format: "%.1f", fadeInSeconds))")
        }
        if fadeOutSeconds > 0 {
            let fadeOutStart = max(0, totalDuration - fadeOutSeconds)
            filters.append("afade=t=out:st=\(String(format: "%.1f", fadeOutStart)):d=\(String(format: "%.1f", fadeOutSeconds))")
        }
        
        let filterArg = filters.isEmpty ? "" : "-filter:a \"\(filters.joined(separator: ","))\""
        return "-i \"\(inputAudioURL.path)\" \(filterArg) \"\(outputAudioURL.path)\""
    }
    
    /// Full master command combining trim, volume, fade, and format options
    public static func buildMasterCommand(
        inputURL: URL,
        outputURL: URL,
        config: AudioExportConfig,
        totalDuration: TimeInterval
    ) -> String {
        var preInputs = ""
        if let start = config.trimStartTime, let end = config.trimEndTime {
            preInputs = "-ss \(formatTimestamp(start)) -to \(formatTimestamp(end)) "
        }
        
        var audioFilters: [String] = []
        if config.effects.volumeMultiplier != 1.0 {
            audioFilters.append("volume=\(String(format: "%.2f", config.effects.volumeMultiplier))")
        }
        if config.effects.fadeInDuration > 0 {
            audioFilters.append("afade=t=in:ss=0:d=\(String(format: "%.1f", config.effects.fadeInDuration))")
        }
        if config.effects.fadeOutDuration > 0 {
            let effectiveDuration = (config.trimEndTime ?? totalDuration) - (config.trimStartTime ?? 0)
            let outStart = max(0, effectiveDuration - config.effects.fadeOutDuration)
            audioFilters.append("afade=t=out:st=\(String(format: "%.1f", outStart)):d=\(String(format: "%.1f", config.effects.fadeOutDuration))")
        }
        
        var filterStr = ""
        if !audioFilters.isEmpty {
            filterStr = "-filter:a \"\(audioFilters.joined(separator: ","))\" "
        }
        
        let codec: String
        switch config.format {
        case .mp3: codec = "libmp3lame"
        case .m4a, .aac, .m4r: codec = "aac"
        case .wav: codec = "pcm_s16le"
        case .flac: codec = "flac"
        }
        
        return "\(preInputs)-i \"\(inputURL.path)\" -vn -c:a \(codec) -ar \(config.sampleRate.rawValue) -b:a \(config.bitrate.rawValue)k \(filterStr)\"\(outputURL.path)\""
    }
    
    // MARK: - Helpers
    
    public static func formatTimestamp(_ seconds: TimeInterval) -> String {
        let totalSecs = Int(seconds)
        let hours = totalSecs / 3600
        let minutes = (totalSecs % 3600) / 60
        let secs = totalSecs % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1.0)) * 100)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d.%02d", hours, minutes, secs, millis)
        } else {
            return String(format: "00:%02d:%02d.%02d", minutes, secs, millis)
        }
    }
}
