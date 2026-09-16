import SwiftUI

/// Primary detail view matching Android's AudioPlayerDetailScreen:
/// - Top Bar: Back arrow, Track title & format/duration subtitle, 3-dot menu
/// - Compact Waveform visualizer card with seeking
/// - Center-stage synchronized Karaoke lyrics card with live sync highlight, tap-to-seek
/// - Scrubber bar with elapsed and remaining timestamps
/// - Audio control buttons: Speed multiplier, Skip -10s, Play/Pause circle, Skip +10s, Loop, Mute
public struct AudioPlayerDetailView: View {
    @ObservedObject public var playerManager: AudioPlayerManager
    @ObservedObject public var fileManager: AudioFileManager
    public var onBack: (() -> Void)?
    
    // Sheets
    @State private var showExportSheet = false
    @State private var showTrimSheet = false
    @State private var showEffectsSheet = false
    @State private var showShareSheet = false
    @State private var showSearchLyricsSheet = false
    @State private var showPasteLyricsSheet = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
    
    public init(
        playerManager: AudioPlayerManager,
        fileManager: AudioFileManager = .shared,
        onBack: (() -> Void)? = nil
    ) {
        self.playerManager = playerManager
        self.fileManager = fileManager
        self.onBack = onBack
    }
    
    private var currentTrack: AudioTrack {
        playerManager.currentTrack ?? AudioTrack.demoTrack
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Bar
            headerBar
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // MARK: - Compact Waveform Visualizer Card
            VStack {
                AudioWaveformVisualizer(
                    samples: currentTrack.waveformSamples,
                    progress: playerManager.progress,
                    onSeek: { newProgress in
                        playerManager.seekToProgress(newProgress)
                    }
                )
                .frame(height: 54)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // MARK: - Main Lyrics Display Card (Center Stage)
            AudioLyricsSyncedView(
                playerManager: playerManager,
                track: currentTrack,
                onUpdateLyrics: { newLRC in
                    let updated = fileManager.saveLyrics(for: currentTrack, lrcText: newLRC)
                    playerManager.updateTrackLyrics(updated)
                }
            )
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
            .padding(.bottom, 12)
            
            // MARK: - Scrubber Progress Bar
            AudioScrubberBar(
                currentTime: playerManager.currentTime,
                duration: playerManager.duration,
                onSeek: { time in
                    playerManager.seek(to: time)
                }
            )
            .padding(.bottom, 16)
            
            // MARK: - Main Playback Controls
            AudioControlButtonsView(
                isPlaying: playerManager.isPlaying,
                playbackRate: playerManager.playbackRate,
                isLooping: playerManager.isLooping,
                onTogglePlayPause: { playerManager.togglePlayPause() },
                onSkipBackward: { playerManager.skipBackward10() },
                onSkipForward: { playerManager.skipForward10() },
                onCycleSpeed: { playerManager.cyclePlaybackRate() },
                onToggleLoop: { playerManager.toggleLoop() }
            )
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .sheet(isPresented: $showExportSheet) {
            ExportSettingsSheet(track: currentTrack, fileManager: fileManager)
        }
        .sheet(isPresented: $showTrimSheet) {
            AudioTrimmerSheet(track: currentTrack, playerManager: playerManager, fileManager: fileManager)
        }
        .sheet(isPresented: $showEffectsSheet) {
            AudioEffectsSheet(track: currentTrack, fileManager: fileManager)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [currentTrack.fileURL])
        }
        .sheet(isPresented: $showSearchLyricsSheet) {
            LyricSearchSheet(
                initialQuery: currentTrack.title,
                duration: currentTrack.duration,
                onApplyLyrics: { lrc in
                    let updated = fileManager.saveLyrics(for: currentTrack, lrcText: lrc)
                    playerManager.updateTrackLyrics(updated)
                }
            )
        }
        .sheet(isPresented: $showPasteLyricsSheet) {
            LyricsEditSheet(
                initialText: currentTrack.transcript ?? LyricParser.exportToLRC(lines: currentTrack.lyrics),
                duration: currentTrack.duration,
                onSave: { newLRC in
                    let updated = fileManager.saveLyrics(for: currentTrack, lrcText: newLRC)
                    playerManager.updateTrackLyrics(updated)
                }
            )
        }
        .alert("Đổi tên tệp", isPresented: $showRenameAlert) {
            TextField("Tên mới", text: $renameText)
            Button("Hủy", role: .cancel) {}
            Button("Lưu") {
                if let updated = fileManager.renameTrack(currentTrack, newName: renameText) {
                    playerManager.loadTrack(updated)
                }
            }
        }
        .onAppear {
            if playerManager.currentTrack == nil {
                playerManager.loadTrack(fileManager.savedTracks.first ?? AudioTrack.demoTrack)
            }
            if let curr = playerManager.currentTrack, curr.lyrics.isEmpty || curr.transcript == nil {
                let matches = OfflineLyricsStore.search(query: curr.title)
                let lrc = matches.first?.resolvedLyrics ?? OfflineLyricsStore.xuongRongDangrangtoLRC
                let updated = fileManager.saveLyrics(for: curr, lrcText: lrc)
                playerManager.updateTrackLyrics(updated)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        HStack {
            Button(action: {
                onBack?()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(currentTrack.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)
                
                Text("\(currentTrack.format.rawValue) • \(currentTrack.formattedDuration)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button(action: { showSearchLyricsSheet = true }) {
                    Label("Tìm lời bài hát online", systemImage: "magnifyingglass")
                }
                Button(action: { showPasteLyricsSheet = true }) {
                    Label("Dán lời bài hát (Lyrics / LRC)", systemImage: "square.and.pencil")
                }
                Divider()
                Button(action: { showExportSheet = true }) {
                    Label("Xuất / Đổi định dạng", systemImage: "arrow.2.squarepath")
                }
                Button(action: { showTrimSheet = true }) {
                    Label("Cắt nhạc (Trimmer)", systemImage: "scissors")
                }
                Button(action: { showEffectsSheet = true }) {
                    Label("Tăng âm lượng & Fade", systemImage: "speaker.wave.3.fill")
                }
                Button(action: {
                    renameText = currentTrack.title
                    showRenameAlert = true
                }) {
                    Label("Đổi tên", systemImage: "pencil")
                }
                Button(action: { showShareSheet = true }) {
                    Label("Chia sẻ file", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive, action: {
                    fileManager.deleteTrack(currentTrack)
                    if let first = fileManager.savedTracks.first {
                        playerManager.loadTrack(first)
                    }
                }) {
                    Label("Xóa bài này", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Helper UIActivityViewController wrapper for AirDrop and Files export
public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
