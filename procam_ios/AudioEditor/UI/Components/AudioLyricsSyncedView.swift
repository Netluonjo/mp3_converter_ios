import SwiftUI

/// Modern, Apple Music / Spotify inspired real-time synchronized lyrics view.
/// Features:
/// - Real-time active lyric tracking matching `playerManager.currentTime`
/// - Smooth automatic scrolling to keep active lyric centered (`ScrollViewReader`)
/// - Tap any line to seek playback directly to that timestamp
/// - Real-time sync offset adjustment (+/- 0.5s) to align with audio lag or lead
/// - Built-in Online LRC Search from open database (LRCLIB)
/// - Native Apple AI Speech Recognition to extract voice from recordings
/// - Built-in LRC & text editor sheet with export and copy support
public struct AudioLyricsSyncedView: View {
    @ObservedObject public var playerManager: AudioPlayerManager
    public let track: AudioTrack
    public var onUpdateLyrics: ((String) -> Void)?
    
    @StateObject private var speechService = SpeechRecognitionService.shared
    
    @State private var showEditSheet: Bool = false
    @State private var showSearchSheet: Bool = false
    @State private var userIsScrolledAway: Bool = false
    @State private var copiedToast: Bool = false
    @State private var aiAlertMessage: String? = nil
    @State private var showAiAlert: Bool = false
    
    public init(
        playerManager: AudioPlayerManager,
        track: AudioTrack,
        onUpdateLyrics: ((String) -> Void)? = nil
    ) {
        self.playerManager = playerManager
        self.track = track
        self.onUpdateLyrics = onUpdateLyrics
    }
    
    private var effectiveTrack: AudioTrack {
        playerManager.currentTrack ?? track
    }
    
    private var lyrics: [LyricLine] {
        effectiveTrack.lyrics
    }
    
    private var activeIndex: Int? {
        playerManager.currentLyricIndex(for: lyrics)
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // MARK: - Mini Top Header with Sync Controls & Search
            topControlBar
            
            // MARK: - Synchronized Lyrics List or Empty State
            if lyrics.isEmpty {
                emptyLyricsCard
            } else {
                lyricScrollView
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showEditSheet) {
            LyricsEditSheet(
                initialText: effectiveTrack.transcript ?? LyricParser.exportToLRC(lines: lyrics),
                duration: effectiveTrack.duration,
                onSave: { newText in
                    onUpdateLyrics?(newText)
                }
            )
        }
        .sheet(isPresented: $showSearchSheet) {
            LyricSearchSheet(
                initialQuery: effectiveTrack.title,
                duration: effectiveTrack.duration,
                onApplyLyrics: { newLRC in
                    onUpdateLyrics?(newLRC)
                }
            )
        }
        .alert("Thông báo nhận diện", isPresented: $showAiAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiAlertMessage ?? "")
        }
        .onAppear {
            if lyrics.isEmpty {
                let lower = effectiveTrack.title.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN")).lowercased()
                if lower.contains("xuong rong") {
                    onUpdateLyrics?(OfflineLyricsStore.xuongRongDangrangtoLRC)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topControlBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "music.mic")
                    .foregroundColor(AudioEditorTheme.accentRed)
                    .font(.system(size: 13, weight: .bold))
                
                Text("Lời bài hát (LRC Sync)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Spacer()
            
            // Sync timing nudge: [-0.5s] [Offset] [+0.5s]
            HStack(spacing: 3) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    playerManager.adjustLyricOffset(by: -0.5)
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                
                Text(String(format: "%+.1fs", playerManager.lyricOffset))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(playerManager.lyricOffset == 0 ? .secondary : AudioEditorTheme.accentRed)
                    .padding(.horizontal, 4)
                    .onTapGesture {
                        playerManager.resetLyricOffset()
                    }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    playerManager.adjustLyricOffset(by: 0.5)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color(UIColor.systemBackground).opacity(0.6)))
            
            // Search Lyrics Button
            Button(action: {
                showSearchSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .bold))
                    Text("Tìm lời")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(AudioEditorTheme.accentRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(UIColor.systemBackground).opacity(0.8)))
            }
            
            // Edit LRC Button
            Button(action: {
                showEditSheet = true
            }) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .padding(5)
                    .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.6)))
            }
            
            // Copy LRC Button
            Button(action: {
                let lrcContent = effectiveTrack.transcript ?? LyricParser.exportToLRC(lines: lyrics)
                UIPasteboard.general.string = lrcContent
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation { copiedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copiedToast = false }
                }
            }) {
                Image(systemName: copiedToast ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(copiedToast ? .green : .secondary)
                    .padding(5)
                    .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.6)))
            }
        }
    }
    
    private var lyricScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                        let isActive = (index == activeIndex)
                        
                        lyricRowView(line: line, isActive: isActive)
                            .id(line.id)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                playerManager.seek(to: line.startTime)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    proxy.scrollTo(line.id, anchor: .center)
                                }
                            }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .onChange(of: activeIndex) { newIndex in
                guard let newIndex = newIndex, newIndex >= 0, newIndex < lyrics.count else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(lyrics[newIndex].id, anchor: .center)
                }
            }
            .onAppear {
                if let active = activeIndex, active < lyrics.count {
                    proxy.scrollTo(lyrics[active].id, anchor: .center)
                }
            }
        }
    }
    
    private func lyricRowView(line: LyricLine, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Timestamp tag & active dot indicator
            HStack(spacing: 4) {
                if isActive {
                    Circle()
                        .fill(AudioEditorTheme.accentRed)
                        .frame(width: 6, height: 6)
                        .transition(.scale)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
                
                Text(line.formattedStartTime)
                    .font(.system(size: 11, weight: isActive ? .bold : .regular, design: .monospaced))
                    .foregroundColor(isActive ? AudioEditorTheme.accentRed : Color(UIColor.tertiaryLabel))
            }
            .frame(width: 48, alignment: .leading)
            .padding(.top, 2)
            
            // Lyric text line
            Text(line.text)
                .font(.system(size: isActive ? 16 : 14, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? Color(UIColor.label) : Color(UIColor.secondaryLabel).opacity(0.65))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(isActive ? 1.02 : 1.0, anchor: .leading)
                .animation(.easeInOut(duration: 0.25), value: isActive)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            isActive ?
            RoundedRectangle(cornerRadius: 10)
                .fill(AudioEditorTheme.accentRed.opacity(0.08)) :
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    private var emptyLyricsCard: some View {
        VStack(spacing: 12) {
            if speechService.isTranscribing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, 8)
                    Text(speechService.progressText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .frame(height: 140)
            } else {
                Image(systemName: "music.note.magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundColor(AudioEditorTheme.accentRed)
                    .padding(.top, 4)
                
                Text("Chưa có lời bài hát")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                
                Text("Chọn một trong các cách dưới đây để lấy lời bài hát:")
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
                
                // Action Buttons Grid
                VStack(spacing: 8) {
                    // Button: Instant 1-tap Apply for "Xương Rồng" (Dangrangto)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onUpdateLyrics?(OfflineLyricsStore.xuongRongDangrangtoLRC)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "music.note.list")
                            Text("Áp dụng lời bài hát: Xương Rồng (Dangrangto)")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [AudioEditorTheme.accentRed, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 8) {
                        // Button 1: Online search
                        Button(action: { showSearchSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe.americas.fill")
                                Text("Tìm online")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(UIColor.tertiarySystemBackground)))
                        }
                        
                        // Button 2: Speech Recognition
                        Button(action: startSpeechRecognition) {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform.and.mic")
                                Text("Nhận diện AI")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(UIColor.tertiarySystemBackground)))
                        }
                        
                        // Button 3: Use Demo Lyrics
                        Button(action: {
                            onUpdateLyrics?(LyricParser.demoLRC)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Lời mẫu 21s")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(UIColor.tertiarySystemBackground)))
                        }
                        
                        // Button 4: Manual Paste
                        Button(action: { showEditSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("Dán LRC")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(UIColor.tertiarySystemBackground)))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private func startSpeechRecognition() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            do {
                let generatedLRC = try await speechService.transcribeAudio(url: track.fileURL, duration: track.duration)
                if !generatedLRC.isEmpty {
                    onUpdateLyrics?(generatedLRC)
                } else {
                    aiAlertMessage = "Không nhận diện được giọng nói trong tệp này."
                    showAiAlert = true
                }
            } catch {
                aiAlertMessage = error.localizedDescription
                showAiAlert = true
            }
        }
    }
}

/// Sheet for editing, pasting, or generating synchronized LRC lyrics
public struct LyricsEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    private let duration: TimeInterval
    private let onSave: (String) -> Void
    
    public init(initialText: String, duration: TimeInterval, onSave: @escaping (String) -> Void) {
        self._text = State(initialValue: initialText)
        self.duration = duration
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                // Info Banner
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AudioEditorTheme.accentRed)
                    Text("Định dạng LRC chuẩn: [mm:ss.xx] Lời bài hát. Nếu dán văn bản thường, hệ thống sẽ tự chia mốc thời gian đều theo thời lượng bài hát.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                
                // Text Editor
                TextEditor(text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(UIColor.separator), lineWidth: 1)
                    )
                
                // Helper buttons
                HStack {
                    Button(action: {
                        text = LyricParser.demoLRC
                    }) {
                        Text("Dán lời mẫu")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AudioEditorTheme.accentRed)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let paste = UIPasteboard.general.string {
                            text = paste
                        }
                    }) {
                        Label("Dán từ Clipboard", systemImage: "doc.on.clipboard")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
            .padding(16)
            .navigationTitle("Chỉnh sửa lời bài hát")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        onSave(text)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AudioEditorTheme.accentRed)
                }
            }
        }
    }
}
