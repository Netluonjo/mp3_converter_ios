import SwiftUI

/// Screen for merging multiple audio files into a single track
public struct AudioMergerView: View {
    @ObservedObject public var fileManager: AudioFileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTracks: [AudioTrack] = []
    @State private var outputTitle: String = "Merged_Audio"
    @State private var outputFormat: AudioFormat = .mp3
    @State private var isMerging: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showAddTrackPicker: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(fileManager: AudioFileManager = .shared) {
        self.fileManager = fileManager
    }
    
    private var totalDuration: TimeInterval {
        selectedTracks.reduce(0) { $0 + $1.duration }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedTracks.isEmpty {
                    emptySelectionView
                } else {
                    trackListContent
                }
            }
            .navigationTitle("Ghép nhạc (Audio Merger)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddTrackPicker = true }) {
                        Label("Thêm", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTrackPicker) {
                AddTracksSelectionSheet(availableTracks: fileManager.savedTracks) { newTrack in
                    selectedTracks.append(newTrack)
                }
            }
            .alert("Ghép file thành công!", isPresented: $showSuccessAlert) {
                Button("Xem kết quả") { dismiss() }
            } message: {
                Text("Tệp '\(outputTitle).\(outputFormat.fileExtension)' đã được lưu vào Thư viện.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptySelectionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.2, green: 0.78, blue: 0.35))
            }
            
            VStack(spacing: 6) {
                Text("Chưa chọn file âm thanh nào")
                    .font(.system(size: 18, weight: .bold))
                
                Text("Hãy thêm từ 2 file âm thanh trở lên để tiến hành nối nhạc liền mạch.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showAddTrackPicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Chọn file để ghép")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color(red: 0.2, green: 0.78, blue: 0.35)))
            }
            
            Spacer()
        }
    }
    
    private var trackListContent: some View {
        VStack(spacing: 0) {
            // Header summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedTracks.count) tệp được chọn")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tổng thời lượng: \(formatTime(totalDuration))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { showAddTrackPicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Thêm tệp")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AudioEditorTheme.accentRed)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Reorderable list
            List {
                ForEach(Array(selectedTracks.enumerated()), id: \.element.id) { index, track in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(1)
                            Text("\(track.formattedDuration) • \(track.format.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    selectedTracks.remove(atOffsets: indices)
                }
                .onMove { source, destination in
                    selectedTracks.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom configuration and merge button
            VStack(spacing: 16) {
                // Generated FFmpeg command preview
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "terminal")
                            .font(.system(size: 12))
                        Text("LỆNH FFMPEG GHÉP FILE (Concat Filter)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                    
                    let dummyOut = URL(fileURLWithPath: "/Documents/output_merged.mp3")
                    Text(FFmpegCommandBridge.buildMergeCommand(
                        inputAudioURLs: selectedTracks.map { $0.fileURL },
                        outputAudioURL: dummyOut
                    ))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                .padding(.horizontal, 20)
                
                // Merge action button
                Button(action: executeMerge) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTracks.count >= 2 ? AudioEditorTheme.accentRed : Color(UIColor.systemGray4))
                            .frame(height: 54)
                        
                        if isMerging {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.merge")
                                    .font(.system(size: 17, weight: .bold))
                                Text("Ghép \(selectedTracks.count) tệp thành một")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .disabled(selectedTracks.count < 2 || isMerging)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemBackground))
        }
    }
    
    private func executeMerge() {
        guard selectedTracks.count >= 2 else { return }
        isMerging = true
        
        let targetURL = fileManager.destinationURL(baseName: outputTitle, format: outputFormat)
        
        Task {
            do {
                try await AudioProcessingEngine.shared.mergeAudioFiles(
                    inputURLs: selectedTracks.map { $0.fileURL },
                    outputURL: targetURL
                )
                await MainActor.run {
                    fileManager.reloadLibrary()
                    isMerging = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isMerging = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatTime(_ s: TimeInterval) -> String {
        let t = Int(s)
        let m = t / 60
        let sec = t % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

/// Helper sheet for picking tracks to append
struct AddTracksSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let availableTracks: [AudioTrack]
    let onSelect: (AudioTrack) -> Void
    
    var body: some View {
        NavigationStack {
            List(availableTracks) { track in
                Button(action: {
                    onSelect(track)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(UIColor.label))
                            Text("\(track.formattedDuration) • \(track.format.rawValue)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AudioEditorTheme.accentRed)
                            .font(.system(size: 20))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Chọn bài hát")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
        }
    }
}
