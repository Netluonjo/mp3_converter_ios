import SwiftUI
import PhotosUI
import AVFoundation

/// Video to MP3 / Audio extractor screen
public struct VideoToAudioView: View {
    @ObservedObject public var fileManager: AudioFileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var videoTitle: String = ""
    @State private var videoDuration: TimeInterval = 0.0
    @State private var videoFileSize: Int64 = 0
    
    // Output options
    @State private var outputFormat: AudioFormat = .mp3
    @State private var outputBitrate: AudioBitrate = .kbps320
    @State private var isExtracting: Bool = false
    @State private var extractionProgress: Float = 0.0
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(fileManager: AudioFileManager = .shared) {
        self.fileManager = fileManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Video Picker Box
                    if let selectedVideoURL = selectedVideoURL {
                        videoSelectedCard
                    } else {
                        videoPickerPlaceholder
                    }
                    
                    // MARK: - Format & Bitrate Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CẤU HÌNH ÂM THANH XUẤT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Format Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Định dạng file")
                                .font(.system(size: 14, weight: .medium))
                            
                            Picker("Định dạng", selection: $outputFormat) {
                                Text("MP3 (Phổ biến nhất)").tag(AudioFormat.mp3)
                                Text("M4A (Chuẩn Apple AAC)").tag(AudioFormat.m4a)
                                Text("WAV (Không nén Lossless)").tag(AudioFormat.wav)
                                Text("AAC (Chuẩn phát thanh)").tag(AudioFormat.aac)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Bitrate Picker (if not WAV)
                        if outputFormat != .wav {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chất lượng Bitrate")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Picker("Bitrate", selection: $outputBitrate) {
                                    Text("128 kbps").tag(AudioBitrate.kbps128)
                                    Text("192 kbps").tag(AudioBitrate.kbps192)
                                    Text("256 kbps").tag(AudioBitrate.kbps256)
                                    Text("320 kbps (Cao nhất)").tag(AudioBitrate.kbps320)
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
                    
                    // MARK: - FFmpeg Command Inspection
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 12))
                            Text("LỆNH FFMPEG XỬ LÝ (Background Engine)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.secondary)
                        
                        let dummyIn = selectedVideoURL ?? URL(fileURLWithPath: "input_video.mp4")
                        let dummyOut = URL(fileURLWithPath: "output.\(outputFormat.fileExtension)")
                        Text(FFmpegCommandBridge.buildVideoToAudioCommand(
                            inputVideoURL: dummyIn,
                            outputAudioURL: dummyOut,
                            format: outputFormat,
                            bitrateKbps: outputBitrate.rawValue
                        ))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Extract Button
                    Button(action: startExtraction) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedVideoURL != nil ? AudioEditorTheme.accentRed : Color(UIColor.systemGray4))
                                .frame(height: 54)
                            
                            if isExtracting {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Đang bóc tách âm thanh...")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 17, weight: .bold))
                                    Text("Bắt đầu trích xuất âm thanh")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(selectedVideoURL == nil || isExtracting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Trích xuất từ Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Trích xuất hoàn tất!", isPresented: $showSuccessAlert) {
                Button("Xem trong Thư viện") {
                    dismiss()
                }
            } message: {
                Text("File âm thanh '\(videoTitle).\(outputFormat.fileExtension)' đã được tạo thành công.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var videoPickerPlaceholder: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AudioEditorTheme.accentRed.opacity(0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(AudioEditorTheme.accentRed)
                }
                
                VStack(spacing: 4) {
                    Text("Chọn Video từ Photos")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("Hỗ trợ MP4, MOV, Cinematic và Video quay màn hình")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(Color(UIColor.systemGray4))
            )
            .padding(.horizontal, 20)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                await handlePickedVideo(newItem)
            }
        }
    }
    
    private var videoSelectedCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "film.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(videoTitle)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text(formatDuration(videoDuration))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AudioEditorTheme.accentRed)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(ByteCountFormatter.string(fromByteCount: videoFileSize, countStyle: .file))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .videos,
                photoLibrary: .shared()
            ) {
                Text("Đổi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AudioEditorTheme.accentRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AudioEditorTheme.accentRed.opacity(0.12)))
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    await handlePickedVideo(newItem)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Handlers
    
    private func handlePickedVideo(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                let asset = AVURLAsset(url: movie.url)
                let duration = try await asset.load(.duration)
                let durationSecs = CMTimeGetSeconds(duration)
                let resourceValues = try? movie.url.resourceValues(forKeys: [.fileSizeKey])
                let size = Int64(resourceValues?.fileSize ?? 0)
                
                await MainActor.run {
                    self.selectedVideoURL = movie.url
                    self.videoTitle = movie.url.deletingPathExtension().lastPathComponent
                    self.videoDuration = durationSecs.isNaN ? 0 : durationSecs
                    self.videoFileSize = size
                }
            }
        } catch {
            print("Failed to load video: \(error)")
        }
    }
    
    private func startExtraction() {
        guard let videoURL = selectedVideoURL else { return }
        isExtracting = true
        
        let outputName = videoTitle.isEmpty ? "Extracted_Audio" : videoTitle
        let targetURL = fileManager.destinationURL(baseName: outputName, format: outputFormat)
        
        Task {
            do {
                try await AudioProcessingEngine.shared.extractAudioFromVideo(
                    videoURL: videoURL,
                    outputURL: targetURL
                )
                await MainActor.run {
                    fileManager.reloadLibrary()
                    isExtracting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatDuration(_ s: TimeInterval) -> String {
        let t = Int(max(0, s))
        let m = t / 60
        let sec = t % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

/// Helper transferable type for PhotosPicker video transfer
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempDir = FileManager.default.temporaryDirectory
            let copyUrl = tempDir.appendingPathComponent(received.file.lastPathComponent)
            try? FileManager.default.removeItem(at: copyUrl)
            try FileManager.default.copyItem(at: received.file, to: copyUrl)
            return Self(url: copyUrl)
        }
    }
}
