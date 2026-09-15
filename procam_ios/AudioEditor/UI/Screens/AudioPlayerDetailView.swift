import SwiftUI

/// Primary detail view faithfully recreating the user's screenshot (Image 1):
/// - Header: Back arrow, Track title "Ghi âm 1", More actions "..."
/// - Pill segmented toggle: [ 🔊 Âm thanh ] [ 💬 Văn bản ]
/// - Interactive center waveform with red needle playhead
/// - Scrubber bar with timestamps
/// - Control bar: x1, -10s, Red Play/Pause, +10s, Loop
/// - Bottom utility bar: Reset, Mini Play, Mute, Expand to editor tools
public struct AudioPlayerDetailView: View {
    @ObservedObject public var playerManager: AudioPlayerManager
    @ObservedObject public var fileManager: AudioFileManager
    public var onBack: (() -> Void)?
    
    // Tab state: 0 = Âm thanh (Audio), 1 = Văn bản (Transcript)
    @State private var selectedTab: Int = 0
    
    // Tool sheet presentations
    @State private var showExportSheet = false
    @State private var showTrimSheet = false
    @State private var showEffectsSheet = false
    @State private var showShareSheet = false
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
                .padding(.bottom, 16)
            
            // MARK: - Pill Mode Switcher: [ Âm thanh ] | [ Văn bản ]
            modePillSwitcher
                .padding(.bottom, 24)
            
            Spacer()
            
            // MARK: - Center Content (Waveform or Synchronized Lyrics)
            if selectedTab == 0 {
                VStack(spacing: 14) {
                    AudioWaveformVisualizer(
                        samples: currentTrack.waveformSamples,
                        progress: playerManager.progress,
                        onSeek: { newProgress in
                            playerManager.seekToProgress(newProgress)
                        }
                    )
                    
                    // Live floating karaoke subtitle pill below waveform
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "music.mic")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AudioEditorTheme.accentRed)
                            
                            let lines = currentTrack.lyrics
                            if let activeIndex = playerManager.currentLyricIndex(for: lines),
                               activeIndex < lines.count {
                                Text(lines[activeIndex].text)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                            } else {
                                Text(lines.isEmpty ? "Nhấn để tìm & đồng bộ lời bài hát" : "Chạm để mở toàn bộ lời bài hát")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.secondarySystemBackground))
                                .overlay(
                                    Capsule()
                                        .stroke(AudioEditorTheme.accentRed.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 12)
            } else {
                AudioLyricsSyncedView(
                    playerManager: playerManager,
                    track: currentTrack,
                    onUpdateLyrics: { newLRC in
                        let updated = fileManager.saveLyrics(for: currentTrack, lrcText: newLRC)
                        playerManager.updateTrackLyrics(updated)
                    }
                )
                .padding(.horizontal, 20)
                .frame(minHeight: 250, maxHeight: 310)
            }
            
            Spacer()
            
            // MARK: - Scrubber Progress Bar
            AudioScrubberBar(
                currentTime: playerManager.currentTime,
                duration: playerManager.duration,
                onSeek: { time in
                    playerManager.seek(to: time)
                }
            )
            .padding(.bottom, 24)
            
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
            .padding(.bottom, 32)
            
            // MARK: - Bottom Utility Bar
            bottomActionBar
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
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
            
            Text(currentTrack.title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(Color(UIColor.label))
                .lineLimit(1)
            
            Spacer()
            
            Menu {
                Button(action: { showExportSheet = true }) {
                    Label("Xuất / Đổi định dạng", systemImage: "square.and.arrow.up")
                }
                Button(action: { showTrimSheet = true }) {
                    Label("Cắt nhạc (Trimmer)", systemImage: "scissors")
                }
                Button(action: { showEffectsSheet = true }) {
                    Label("Tăng âm lượng & Fade", systemImage: "slider.horizontal.3")
                }
                Button(action: {
                    renameText = currentTrack.title
                    showRenameAlert = true
                }) {
                    Label("Đổi tên", systemImage: "pencil")
                }
                Button(action: { showShareSheet = true }) {
                    Label("Chia sẻ / AirDrop", systemImage: "square.and.arrow.up.fill")
                }
                Divider()
                Button(role: .destructive, action: {
                    fileManager.deleteTrack(currentTrack)
                    if let first = fileManager.savedTracks.first {
                        playerManager.loadTrack(first)
                    }
                }) {
                    Label("Xóa bản ghi", systemImage: "trash")
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
    
    private var modePillSwitcher: some View {
        HStack(spacing: 0) {
            // Tab: Âm thanh
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Âm thanh")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(selectedTab == 0 ? .white : Color(UIColor.secondaryLabel))
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(
                    selectedTab == 0 ?
                    Capsule().fill(AudioEditorTheme.pillSelectedDark) :
                    Capsule().fill(Color.clear)
                )
            }
            
            // Tab: Lời bài hát
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Lời bài hát")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(selectedTab == 1 ? .white : Color(UIColor.secondaryLabel))
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(
                    selectedTab == 1 ?
                    Capsule().fill(AudioEditorTheme.pillSelectedDark) :
                    Capsule().fill(Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var bottomActionBar: some View {
        HStack {
            // Reset to start button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                playerManager.seek(to: 0)
            }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Secondary play preview
            Button(action: {
                playerManager.togglePlayPause()
            }) {
                Circle()
                    .fill(Color(UIColor.systemGray4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray))
                    )
            }
            
            // Mute / unmute button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                playerManager.toggleMute()
            }) {
                Circle()
                    .fill(Color(UIColor.systemGray4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray))
                    )
            }
            
            // Expand / Editor Tools button
            Button(action: {
                showExportSheet = true
            }) {
                Circle()
                    .fill(Color(UIColor.systemGray4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray))
                    )
            }
        }
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
