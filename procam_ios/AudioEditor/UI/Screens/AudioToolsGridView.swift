import SwiftUI

/// Tools hub presenting quick access cards to each audio processing engine tool
public struct AudioToolsGridView: View {
    @ObservedObject public var fileManager: AudioFileManager
    @ObservedObject public var playerManager: AudioPlayerManager
    
    @State private var activeSheet: ActiveToolSheet? = nil
    
    enum ActiveToolSheet: Identifiable {
        case videoToAudio
        case trimmer
        case merger
        case volumeBooster
        case formatConverter
        case lyricFinder
        case ffmpegTerminal
        
        var id: Int { hashValue }
    }
    
    public init(fileManager: AudioFileManager = .shared, playerManager: AudioPlayerManager) {
        self.fileManager = fileManager
        self.playerManager = playerManager
    }
    
    private var currentTrack: AudioTrack {
        playerManager.currentTrack ?? AudioTrack.demoTrack
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Action Cards
                    VStack(spacing: 12) {
                        ForEach(AudioToolType.allCases) { tool in
                            toolCard(tool)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // FFmpeg & Architecture Information Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(AudioEditorTheme.accentRed)
                            Text("KIẾN TRÚC FFMPEG & NATIVE AUDIO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Text("Ứng dụng chạy trên kiến trúc Dual-Engine: Sử dụng AVFoundation Native cho tốc độ xử lý siêu tốc 0.1s và FFmpeg-Kit command-line bridge đáp ứng các định dạng nâng cao.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Button(action: { activeSheet = .ffmpegTerminal }) {
                            HStack {
                                Image(systemName: "terminal")
                                Text("Xem chuỗi lệnh FFmpeg mẫu")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(AudioEditorTheme.accentRed)
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Bộ công cụ (Tools)")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .videoToAudio:
                    VideoToAudioView(fileManager: fileManager)
                case .trimmer:
                    AudioTrimmerSheet(track: currentTrack, playerManager: playerManager, fileManager: fileManager)
                case .merger:
                    AudioMergerView(fileManager: fileManager)
                case .volumeBooster:
                    AudioEffectsSheet(track: currentTrack, fileManager: fileManager)
                case .formatConverter:
                    ExportSettingsSheet(track: currentTrack, fileManager: fileManager)
                case .lyricFinder:
                    LyricSearchSheet(
                        initialQuery: currentTrack.title,
                        duration: currentTrack.duration,
                        onApplyLyrics: { lrc in
                            let updated = fileManager.saveLyrics(for: currentTrack, lrcText: lrc)
                            playerManager.loadTrack(updated)
                        }
                    )
                case .ffmpegTerminal:
                    FFmpegCommandsReferenceSheet()
                }
            }
        }
    }
    
    private func toolCard(_ tool: AudioToolType) -> some View {
        Button(action: {
            switch tool {
            case .videoToAudio: activeSheet = .videoToAudio
            case .trimmer: activeSheet = .trimmer
            case .merger: activeSheet = .merger
            case .volumeBooster: activeSheet = .volumeBooster
            case .formatConverter: activeSheet = .formatConverter
            case .lyricFinder: activeSheet = .lyricFinder
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tool.tintColor.opacity(0.12))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: tool.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(tool.tintColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.titleVi)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(tool.subtitleVi)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

/// Sheet showing the exact FFmpeg commands requested by the user
struct FFmpegCommandsReferenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let commands: [(title: String, cmd: String, note: String)] = [
        (
            "1. Trích xuất âm thanh từ Video (Video to MP3)",
            "-i input_video.mp4 -vn -c:a libmp3lame -b:a 320k output.mp3",
            "-vn: Bỏ video stream\n-c:a libmp3lame: Mã hóa MP3\n-b:a 320k: Bitrate chất lượng cao nhất"
        ),
        (
            "2. Cắt nhạc siêu tốc (Lossless Audio Cutter)",
            "-ss 00:00:15 -to 00:00:45 -i input.mp3 -c copy output_trimmed.mp3",
            "Cắt từ 00:15 đến 00:45 mà không cần giải mã lại (-c copy giúp cắt trong 0.1s)."
        ),
        (
            "3. Ghép nhiều file (Audio Merger)",
            "-i audio1.mp3 -i audio2.mp3 -filter_complex \"[0:0][1:0]concat=n=2:v=0:a=1[out]\" -map \"[out]\" output_merged.mp3",
            "Ghép nối tiếp tuần tự 2 hay nhiều luồng âm thanh."
        ),
        (
            "4. Tăng âm lượng (Volume Booster)",
            "-i input.mp3 -filter:a \"volume=1.5\" output_boosted.mp3",
            "Khuếch đại âm lượng lên 150% (1.5x) mà không làm méo tiếng."
        ),
        (
            "5. Hiệu ứng mờ dần (Fade In / Fade Out)",
            "-i input.mp3 -filter:a \"afade=t=in:ss=0:d=3,afade=t=out:st=27:d=3\" output_faded.mp3",
            "Fade in 3 giây đầu tiên, Fade out 3 giây cuối cùng."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(commands, id: \.title) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 15, weight: .bold))
                            
                            Text(item.cmd)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.85))
                                )
                                .foregroundColor(.green)
                            
                            Text(item.note)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Lệnh FFmpeg mẫu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
