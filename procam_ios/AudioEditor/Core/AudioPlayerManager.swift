import Foundation
import AVFoundation
import Combine

/// Manages real-time audio playback, waveform playhead tracking, scrubbing, and speed controls
public final class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    // MARK: - Published State
    
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 21.0
    @Published public var playbackRate: Float = 1.0
    @Published public var isLooping: Bool = false
    @Published public var isMuted: Bool = false
    @Published public var currentTrack: AudioTrack?
    @Published public var lyricOffset: TimeInterval = 0.0
    
    // Normalized progress (0.0 to 1.0)
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, max(0.0, currentTime / duration))
    }
    
    // MARK: - Formatted Timestamps
    
    public var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    public var formattedDuration: String {
        formatTime(duration)
    }
    
    public var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return "-\(formatTime(remaining))"
    }
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?
    private var previousVolume: Float = 1.0
    
    // Available playback speeds
    public let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopTimer()
        audioPlayer?.stop()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Playback Controls
    
    /// Loads a track for playback with auto-healing of lyrics
    public func loadTrack(_ track: AudioTrack) {
        var mutableTrack = track
        if mutableTrack.transcript == nil || mutableTrack.lyrics.isEmpty {
            let matches = OfflineLyricsStore.search(query: track.title)
            if let best = matches.first, let lrc = best.resolvedLyrics {
                mutableTrack.transcript = lrc
                mutableTrack.lyricLines = LyricParser.parse(text: lrc, duration: track.duration)
            }
        }
        currentTrack = mutableTrack
        duration = mutableTrack.duration
        currentTime = 0.0
        
        guard FileManager.default.fileExists(atPath: mutableTrack.fileURL.path) else {
            // Virtual simulation mode for demo track if file not written yet
            setupVirtualDemo(duration: mutableTrack.duration)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: track.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.numberOfLoops = isLooping ? -1 : 0
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? track.duration
        } catch {
            print("Failed to initialize AVAudioPlayer: \(error.localizedDescription)")
            setupVirtualDemo(duration: track.duration)
        }
    }
    
    private func setupVirtualDemo(duration: TimeInterval) {
        self.duration = duration
        self.currentTime = 0.0
    }
    
    /// Updates lyrics of the currently playing track without resetting playback position or stopping audio
    public func updateTrackLyrics(_ updatedTrack: AudioTrack) {
        self.currentTrack = updatedTrack
    }
    
    /// Toggles play / pause
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func play() {
        if let player = audioPlayer {
            player.rate = playbackRate
            player.numberOfLoops = isLooping ? -1 : 0
            player.play()
        }
        isPlaying = true
        startTimer()
    }
    
    public func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    public func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0.0
        isPlaying = false
        stopTimer()
    }
    
    /// Seeks to a specific timestamp
    public func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        currentTime = clampedTime
        if let player = audioPlayer {
            player.currentTime = clampedTime
        }
    }
    
    /// Seeks by relative normalized progress (0.0 ... 1.0)
    public func seekToProgress(_ progress: Double) {
        seek(to: progress * duration)
    }
    
    /// Skip 10 seconds backwards (-10s)
    public func skipBackward10() {
        seek(to: max(0, currentTime - 10.0))
    }
    
    /// Skip 10 seconds forward (+10s)
    public func skipForward10() {
        seek(to: min(duration, currentTime + 10.0))
    }
    
    /// Cycle through playback speeds: 1.0x -> 1.25x -> 1.5x -> 2.0x -> 0.5x -> 1.0x
    public func cyclePlaybackRate() {
        if let currentIndex = availableRates.firstIndex(of: playbackRate) {
            let nextIndex = (currentIndex + 1) % availableRates.count
            playbackRate = availableRates[nextIndex]
        } else {
            playbackRate = 1.0
        }
        audioPlayer?.rate = playbackRate
    }
    
    /// Toggle loop repeat mode
    public func toggleLoop() {
        isLooping.toggle()
        audioPlayer?.numberOfLoops = isLooping ? -1 : 0
    }
    
    /// Toggle mute
    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            previousVolume = audioPlayer?.volume ?? 1.0
            audioPlayer?.volume = 0.0
        } else {
            audioPlayer?.volume = previousVolume
        }
    }
    
    // MARK: - Timer for Smooth 30Hz Playhead Sync
    
    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let player = self.audioPlayer {
                    self.currentTime = player.currentTime
                    if !player.isPlaying && self.isPlaying {
                        self.isPlaying = false
                        self.stopTimer()
                    }
                } else {
                    // Virtual playback progression for demo simulation
                    if self.isPlaying {
                        self.currentTime += (1.0 / 30.0) * Double(self.playbackRate)
                        if self.currentTime >= self.duration {
                            if self.isLooping {
                                self.currentTime = 0.0
                            } else {
                                self.currentTime = self.duration
                                self.pause()
                            }
                        }
                    }
                }
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !isLooping {
            isPlaying = false
            currentTime = duration
            stopTimer()
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Synchronized Lyrics Support
    
    /// Returns the active lyric line index for the current playback time with lyricOffset applied
    public func currentLyricIndex(for lyrics: [LyricLine]) -> Int? {
        guard !lyrics.isEmpty else { return nil }
        let effectiveTime = max(0, currentTime + lyricOffset)
        
        if effectiveTime < lyrics[0].startTime {
            return 0
        }
        
        for (index, line) in lyrics.enumerated() {
            if effectiveTime >= line.startTime && effectiveTime < line.endTime {
                return index
            }
        }
        
        if effectiveTime >= lyrics.last!.startTime {
            return lyrics.count - 1
        }
        
        return 0
    }
    
    /// Adjust the lyric synchronization offset by delta seconds (e.g. +0.5s or -0.5s)
    public func adjustLyricOffset(by delta: TimeInterval) {
        lyricOffset = max(-10.0, min(10.0, lyricOffset + delta))
    }
    
    /// Reset the lyric synchronization offset back to 0.0s
    public func resetLyricOffset() {
        lyricOffset = 0.0
    }
}
