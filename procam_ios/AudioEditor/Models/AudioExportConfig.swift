import Foundation

/// Supported output audio formats
public enum AudioFormat: String, CaseIterable, Codable, Identifiable {
    case mp3 = "MP3"
    case m4a = "M4A"
    case aac = "AAC"
    case wav = "WAV"
    case flac = "FLAC"
    case m4r = "M4R (Ringtone)"
    
    public var id: String { rawValue }
    
    public var fileExtension: String {
        switch self {
        case .mp3: return "mp3"
        case .m4a: return "m4a"
        case .aac: return "aac"
        case .wav: return "wav"
        case .flac: return "flac"
        case .m4r: return "m4r"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/m4a"
        case .aac: return "audio/aac"
        case .wav: return "audio/wav"
        case .flac: return "audio/flac"
        case .m4r: return "audio/x-m4r"
        }
    }
    
    /// Description badge for UI
    public var badge: String {
        switch self {
        case .mp3: return "Universal"
        case .m4a: return "Apple AAC"
        case .aac: return "Raw AAC"
        case .wav: return "Lossless PCM"
        case .flac: return "Lossless Hi-Res"
        case .m4r: return "iPhone Ringtone"
        }
    }
}

/// Standard audio sample rates
public enum AudioSampleRate: Int, CaseIterable, Codable, Identifiable {
    case rate44100 = 44100
    case rate48000 = 48000
    case rate96000 = 96000
    
    public var id: Int { rawValue }
    
    public var displayName: String {
        switch self {
        case .rate44100: return "44.1 kHz (CD)"
        case .rate48000: return "48.0 kHz (Studio/Video)"
        case .rate96000: return "96.0 kHz (Hi-Res)"
        }
    }
}

/// Standard audio bitrates
public enum AudioBitrate: Int, CaseIterable, Codable, Identifiable {
    case kbps128 = 128
    case kbps192 = 192
    case kbps256 = 256
    case kbps320 = 320
    
    public var id: Int { rawValue }
    
    public var displayName: String {
        switch self {
        case .kbps128: return "128 kbps (Standard)"
        case .kbps192: return "192 kbps (High Quality)"
        case .kbps256: return "256 kbps (Very High)"
        case .kbps320: return "320 kbps (Maximum)"
        }
    }
}

/// Configuration options for audio effects
public struct AudioEffectsConfig: Codable, Equatable {
    public var volumeMultiplier: Float = 1.0       // 0.0 ... 3.0 (1.0 = 100%, 1.5 = 150%, 2.0 = 200%)
    public var fadeInDuration: TimeInterval = 0.0   // in seconds
    public var fadeOutDuration: TimeInterval = 0.0  // in seconds
    
    public init(
        volumeMultiplier: Float = 1.0,
        fadeInDuration: TimeInterval = 0.0,
        fadeOutDuration: TimeInterval = 0.0
    ) {
        self.volumeMultiplier = volumeMultiplier
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
    }
}

/// Master export configuration model
public struct AudioExportConfig: Codable, Equatable {
    public var format: AudioFormat = .mp3
    public var sampleRate: AudioSampleRate = .rate44100
    public var bitrate: AudioBitrate = .kbps320
    public var effects: AudioEffectsConfig = AudioEffectsConfig()
    public var trimStartTime: TimeInterval? = nil
    public var trimEndTime: TimeInterval? = nil
    
    public init(
        format: AudioFormat = .mp3,
        sampleRate: AudioSampleRate = .rate44100,
        bitrate: AudioBitrate = .kbps320,
        effects: AudioEffectsConfig = AudioEffectsConfig(),
        trimStartTime: TimeInterval? = nil,
        trimEndTime: TimeInterval? = nil
    ) {
        self.format = format
        self.sampleRate = sampleRate
        self.bitrate = bitrate
        self.effects = effects
        self.trimStartTime = trimStartTime
        self.trimEndTime = trimEndTime
    }
}
