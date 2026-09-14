import SwiftUI

/// Export configuration modal allowing format, sample rate, bitrate selection, and sharing
public struct ExportSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let track: AudioTrack
    @ObservedObject public var fileManager: AudioFileManager
    
    @State private var outputFormat: AudioFormat = .mp3
    @State private var sampleRate: AudioSampleRate = .rate44100
    @State private var bitrate: AudioBitrate = .kbps320
    @State private var customFileName: String = ""
    @State private var isExporting: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var exportedFileURL: URL? = nil
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(track: AudioTrack, fileManager: AudioFileManager = .shared) {
        self.track = track
        self.fileManager = fileManager
        self._customFileName = State(initialValue: "\(track.title)_Converted")
    }
    
    // Estimated file size calculation
    private var estimatedSizeBytes: Int64 {
        let seconds = track.duration
        if outputFormat == .wav {
            // 16-bit stereo PCM: 44100 * 2 * 2 = 176,400 bytes/sec
            return Int64(seconds * Double(sampleRate.rawValue) * 4)
        } else {
            // Bitrate in kbps / 8 * 1024
            let bytesPerSec = Double(bitrate.rawValue * 1000) / 8.0
            return Int64(seconds * bytesPerSec)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - File Name Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TÊN TỆP XUẤT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        TextField("Tên tệp", text: $customFileName)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Format Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ĐỊNH DẠNG ÂM THANH (AUDIO FORMAT)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(AudioFormat.allCases) { fmt in
                                Button(action: {
                                    outputFormat = fmt
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(fmt.rawValue)
                                                .font(.system(size: 15, weight: .bold))
                                            Spacer()
                                            if outputFormat == fmt {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AudioEditorTheme.accentRed)
                                            }
                                        }
                                        Text(fmt.badge)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(outputFormat == fmt ? AudioEditorTheme.accentRed.opacity(0.12) : Color(UIColor.tertiarySystemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(outputFormat == fmt ? AudioEditorTheme.accentRed : Color.clear, lineWidth: 1.5)
                                            )
                                    )
                                    .foregroundColor(Color(UIColor.label))
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
                    
                    // MARK: - Sample Rate & Bitrate
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TẦN SỐ LẤY MẪU & BITRATE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Sample Rate
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sample Rate (Tần số mẫu)")
                                .font(.system(size: 14, weight: .medium))
                            
                            Picker("Sample Rate", selection: $sampleRate) {
                                ForEach(AudioSampleRate.allCases) { rate in
                                    Text(rate.displayName).tag(rate)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Bitrate
                        if outputFormat != .wav {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bitrate (Độ sắc nét)")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Picker("Bitrate", selection: $bitrate) {
                                    ForEach(AudioBitrate.allCases) { b in
                                        Text("\(b.rawValue)k").tag(b)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Estimated Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("KÍCH THƯỚC DỰ KIẾN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: estimatedSizeBytes, countStyle: .file))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AudioEditorTheme.accentRed)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("THỜI LƯỢNG")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(track.formattedDuration)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - FFmpeg Command Inspector
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 11))
                            Text("CHUỖI LỆNH FFMPEG SẼ CHẠY")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.secondary)
                        
                        let dummyOut = URL(fileURLWithPath: "/Documents/\(customFileName).\(outputFormat.fileExtension)")
                        Text(FFmpegCommandBridge.buildVideoToAudioCommand(
                            inputVideoURL: track.fileURL,
                            outputAudioURL: dummyOut,
                            format: outputFormat,
                            bitrateKbps: bitrate.rawValue
                        ))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Export Button
                    Button(action: executeExport) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AudioEditorTheme.accentRed)
                                .frame(height: 54)
                            
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .font(.system(size: 17, weight: .bold))
                                    Text("Xuất file âm thanh")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isExporting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Xuất / Đổi định dạng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Xuất tệp thành công!", isPresented: $showSuccessAlert) {
                Button("Chia sẻ ngay") {
                    showShareSheet = true
                }
                Button("Xong", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Tệp đã sẵn sàng trong thư mục Documents và app Tệp của iPhone.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func executeExport() {
        isExporting = true
        let targetURL = fileManager.destinationURL(baseName: customFileName, format: outputFormat)
        
        var config = AudioExportConfig()
        config.format = outputFormat
        config.sampleRate = sampleRate
        config.bitrate = bitrate
        
        Task {
            do {
                try await AudioProcessingEngine.shared.processAudioWithEffects(
                    inputURL: track.fileURL,
                    outputURL: targetURL,
                    config: config
                )
                await MainActor.run {
                    fileManager.reloadLibrary()
                    self.exportedFileURL = targetURL
                    self.isExporting = false
                    self.showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
