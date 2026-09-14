import SwiftUI

/// Sheet modal for visual audio trimming using Start/End time handles
public struct AudioTrimmerSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let track: AudioTrack
    @ObservedObject public var playerManager: AudioPlayerManager
    @ObservedObject public var fileManager: AudioFileManager
    
    @State private var startProgress: Double = 0.15
    @State private var endProgress: Double = 0.85
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert: Bool = false
    @State private var outputURL: URL? = nil
    
    public init(
        track: AudioTrack,
        playerManager: AudioPlayerManager,
        fileManager: AudioFileManager = .shared
    ) {
        self.track = track
        self.playerManager = playerManager
        self.fileManager = fileManager
    }
    
    private var startTimeSeconds: TimeInterval {
        startProgress * track.duration
    }
    
    private var endTimeSeconds: TimeInterval {
        endProgress * track.duration
    }
    
    private var selectionDuration: TimeInterval {
        max(0, endTimeSeconds - startTimeSeconds)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Track Info Header
                VStack(spacing: 4) {
                    Text(track.title)
                        .font(.headline)
                    Text("Thời lượng gốc: \(track.formattedDuration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // Trimmer Waveform Section
                ZStack {
                    // Background Waveform
                    AudioWaveformVisualizer(
                        samples: track.waveformSamples,
                        progress: playerManager.progress,
                        onSeek: { p in playerManager.seekToProgress(p) }
                    )
                    
                    // Trimmer dual-handle overlay
                    WaveformTrimmerOverlay(
                        startProgress: $startProgress,
                        endProgress: $endProgress,
                        duration: track.duration
                    )
                }
                .frame(height: 180)
                .padding(.horizontal, 16)
                
                // Selection Info Box
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ĐIỂM BẮT ĐẦU")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(formatTime(startTimeSeconds))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(AudioEditorTheme.accentRed)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("ĐOẠN CẮT (DÀI)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(formatTime(selectionDuration))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ĐIỂM KẾT THÚC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(formatTime(endTimeSeconds))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(AudioEditorTheme.accentRed)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal, 20)
                
                // Preview Section Button
                Button(action: {
                    playerManager.seek(to: startTimeSeconds)
                    playerManager.play()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                        Text("Nghe thử đoạn đã chọn")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(AudioEditorTheme.accentRed)
                    .padding(.vertical, 8)
                }
                
                // Generated FFmpeg Command Preview
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "terminal")
                            .font(.system(size: 12))
                        Text("LỆNH FFMPEG THỰC THI (-c copy)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                    
                    let dummyOut = URL(fileURLWithPath: "/Documents/output_trimmed.mp3")
                    Text(FFmpegCommandBridge.buildTrimCommand(
                        inputAudioURL: track.fileURL,
                        outputAudioURL: dummyOut,
                        startTimeSeconds: startTimeSeconds,
                        endTimeSeconds: endTimeSeconds
                    ))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                Button(action: executeTrim) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AudioEditorTheme.accentRed)
                            .frame(height: 54)
                        
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "scissors")
                                    .font(.system(size: 17, weight: .bold))
                                Text("Cắt và Lưu tệp mới")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isProcessing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Cắt nhạc (Audio Trimmer)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Cắt nhạc thành công!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Tệp đã được lưu vào thư mục Tệp âm thanh đã xuất.")
            }
        }
    }
    
    private func executeTrim() {
        isProcessing = true
        let targetURL = fileManager.destinationURL(baseName: "\(track.title)_Trimmed", format: track.format)
        
        Task {
            do {
                try await AudioProcessingEngine.shared.trimAudio(
                    inputURL: track.fileURL,
                    outputURL: targetURL,
                    startTime: startTimeSeconds,
                    endTime: endTimeSeconds
                )
                await MainActor.run {
                    fileManager.reloadLibrary()
                    isProcessing = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatTime(_ s: TimeInterval) -> String {
        let total = Int(max(0, s))
        let m = total / 60
        let sec = total % 60
        let millis = Int((s.truncatingRemainder(dividingBy: 1.0)) * 10)
        return String(format: "%02d:%02d.%d", m, sec, millis)
    }
}
