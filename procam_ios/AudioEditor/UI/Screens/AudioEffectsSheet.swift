import SwiftUI

/// Sheet modal for adjusting Volume Gain (Booster) and Fade In / Fade Out effects
public struct AudioEffectsSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let track: AudioTrack
    @ObservedObject public var fileManager: AudioFileManager
    
    @State private var volumeMultiplier: Float = 1.5 // 150% boost by default
    @State private var fadeInDuration: Double = 2.0   // 2 seconds
    @State private var fadeOutDuration: Double = 3.0  // 3 seconds
    
    @State private var isProcessing: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(track: AudioTrack, fileManager: AudioFileManager = .shared) {
        self.track = track
        self.fileManager = fileManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Track Info
                    VStack(spacing: 4) {
                        Text(track.title)
                            .font(.headline)
                        Text("Thời lượng: \(track.formattedDuration)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // MARK: - Volume Booster Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(AudioEditorTheme.accentRed)
                            Text("TĂNG ÂM LƯỢNG (VOLUME BOOSTER)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(volumeMultiplier * 100))%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AudioEditorTheme.accentRed)
                        }
                        
                        Slider(value: $volumeMultiplier, in: 0.1...3.0, step: 0.05)
                            .tint(AudioEditorTheme.accentRed)
                        
                        // Preset buttons
                        HStack(spacing: 8) {
                            ForEach([0.5, 1.0, 1.5, 2.0, 2.5], id: \.self) { preset in
                                Button(action: {
                                    volumeMultiplier = Float(preset)
                                }) {
                                    Text("\(Int(preset * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(volumeMultiplier == Float(preset) ? .white : Color(UIColor.label))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(volumeMultiplier == Float(preset) ? AudioEditorTheme.accentRed : Color(UIColor.systemGray5))
                                        )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Fade In / Fade Out Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "waveform.badge.plus")
                                .foregroundColor(AudioEditorTheme.accentRed)
                            Text("HIỆU ỨNG MỜ DẦN (FADE IN / FADE OUT)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        // Fade In
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Fade In (Đầu bài)")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f giây", fadeInDuration))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(AudioEditorTheme.accentRed)
                            }
                            Slider(value: $fadeInDuration, in: 0.0...5.0, step: 0.5)
                                .tint(AudioEditorTheme.accentRed)
                        }
                        
                        Divider()
                        
                        // Fade Out
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Fade Out (Cuối bài)")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f giây", fadeOutDuration))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(AudioEditorTheme.accentRed)
                            }
                            Slider(value: $fadeOutDuration, in: 0.0...5.0, step: 0.5)
                                .tint(AudioEditorTheme.accentRed)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Generated FFmpeg Command Preview
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "terminal")
                                .font(.system(size: 12))
                            Text("LỆNH FFMPEG ÁP DỤNG BỘ LỌC AUDIO")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.secondary)
                        
                        let dummyOut = URL(fileURLWithPath: "/Documents/output_boosted.mp3")
                        Text(FFmpegCommandBridge.buildFadeCommand(
                            inputAudioURL: track.fileURL,
                            outputAudioURL: dummyOut,
                            totalDuration: track.duration,
                            fadeInSeconds: fadeInDuration,
                            fadeOutSeconds: fadeOutDuration
                        ))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(3)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Apply Button
                    Button(action: applyEffects) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AudioEditorTheme.accentRed)
                                .frame(height: 54)
                            
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 17, weight: .bold))
                                    Text("Áp dụng & Xuất tệp mới")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Tăng âm & Hiệu ứng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Xử lý thành công!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Bản ghi mới đã được khuếch đại âm lượng và lưu vào thư viện.")
            }
        }
    }
    
    private func applyEffects() {
        isProcessing = true
        let targetURL = fileManager.destinationURL(baseName: "\(track.title)_Boosted", format: track.format)
        
        var config = AudioExportConfig()
        config.effects.volumeMultiplier = volumeMultiplier
        config.effects.fadeInDuration = fadeInDuration
        config.effects.fadeOutDuration = fadeOutDuration
        
        Task {
            do {
                try await AudioProcessingEngine.shared.processAudioWithEffects(
                    inputURL: track.fileURL,
                    outputURL: targetURL,
                    config: config
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
}
