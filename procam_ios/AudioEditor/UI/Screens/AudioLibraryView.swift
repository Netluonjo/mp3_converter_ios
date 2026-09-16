import SwiftUI
import UniformTypeIdentifiers

/// Document manager and library browser for all converted, recorded, and trimmed audio files
public struct AudioLibraryView: View {
    @ObservedObject public var fileManager: AudioFileManager
    @ObservedObject public var playerManager: AudioPlayerManager
    public let onSelectTrack: (AudioTrack) -> Void
    public var onNavigateToWifiTransfer: (() -> Void)? = nil
    
    @State private var shareURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showRingtoneGuide: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var showWifiTransferSheet: Bool = false
    
    public init(
        fileManager: AudioFileManager = .shared,
        playerManager: AudioPlayerManager,
        onSelectTrack: @escaping (AudioTrack) -> Void,
        onNavigateToWifiTransfer: (() -> Void)? = nil
    ) {
        self.fileManager = fileManager
        self.playerManager = playerManager
        self.onSelectTrack = onSelectTrack
        self.onNavigateToWifiTransfer = onNavigateToWifiTransfer
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if fileManager.savedTracks.isEmpty {
                    emptyLibraryView
                } else {
                    libraryListView
                }
            }
            .navigationTitle("Thư viện bài hát")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFileImporter = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Thêm nhạc từ máy")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AudioEditorTheme.accentRed)
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showWifiTransferSheet = true }) {
                        Image(systemName: "wifi")
                            .foregroundColor(Color(red: 0.0, green: 0.74, blue: 0.83))
                    }
                    
                    Button(action: { fileManager.reloadLibrary() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AudioEditorTheme.accentRed)
                    }
                    
                    Button(action: { showRingtoneGuide = true }) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        if let imported = fileManager.importAudioFile(from: url) {
                            playerManager.loadTrack(imported)
                            onSelectTrack(imported)
                        }
                    }
                case .failure:
                    break
                }
            }
            .sheet(isPresented: $showWifiTransferSheet) {
                WifiTransferView(fileManager: fileManager, onBack: { showWifiTransferSheet = false })
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showRingtoneGuide) {
                RingtoneGuideSheet()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(Color(UIColor.systemGray3))
            
            Text("Thư viện trống")
                .font(.system(size: 18, weight: .bold))
            
            Text("Các file nhạc sau khi cắt ghép, trích xuất từ video hoặc chuyển đổi sẽ tự động xuất hiện tại đây.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var libraryListView: some View {
        List {
            Section(header: Text("TỆP ÂM THANH ĐÃ LƯU (\(fileManager.savedTracks.count))")) {
                ForEach(fileManager.savedTracks) { track in
                    trackRow(track)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerManager.loadTrack(track)
                            onSelectTrack(track)
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let track = fileManager.savedTracks[index]
                        fileManager.deleteTrack(track)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func trackRow(_ track: AudioTrack) -> some View {
        let isCurrentTrack = playerManager.currentTrack?.id == track.id
        
        return HStack(spacing: 14) {
            // Mini play/pause button
            Button(action: {
                if isCurrentTrack {
                    playerManager.togglePlayPause()
                } else {
                    playerManager.loadTrack(track)
                    playerManager.play()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isCurrentTrack && playerManager.isPlaying ? AudioEditorTheme.accentRed : Color(UIColor.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isCurrentTrack && playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCurrentTrack && playerManager.isPlaying ? .white : AudioEditorTheme.accentRed)
                        .offset(x: isCurrentTrack && playerManager.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Track details
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: isCurrentTrack ? .bold : .semibold))
                    .foregroundColor(isCurrentTrack ? AudioEditorTheme.accentRed : Color(UIColor.label))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(track.format.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(UIColor.systemGray5)))
                        .foregroundColor(.secondary)
                    
                    Text(track.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(track.formattedFileSize)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Share button
            Button(action: {
                shareURL = track.fileURL
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.systemGray))
                    .padding(8)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

/// Guide sheet for setting custom iPhone ringtone (.m4r)
struct RingtoneGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cách cài nhạc chuông iPhone miễn phí")
                            .font(.system(size: 20, weight: .bold))
                        Text("Sử dụng file .M4R vừa xuất kết hợp GarageBand trên iOS")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    guideStep(number: "1", title: "Cắt đoạn nhạc dưới 30 giây", desc: "Vào công cụ 'Cắt nhạc (Audio Trimmer)', chọn đoạn điệp khúc yêu thích dưới 30 giây.")
                    guideStep(number: "2", title: "Xuất file chuẩn M4R (Ringtone)", desc: "Trong mục 'Xuất file', chọn định dạng M4R (iPhone Ringtone) và nhấn Xuất.")
                    guideStep(number: "3", title: "Mở bằng ứng dụng GarageBand", desc: "Bấm nút Chia sẻ (Share) trên tệp đã xuất, chọn app GarageBand trên iPhone của bạn.")
                    guideStep(number: "4", title: "Gán làm Nhạc chuông", desc: "Trong GarageBand, nhấn giữ vào bài hát -> Chọn 'Chia sẻ' -> 'Nhạc chuông (Ringtone)' -> 'Sử dụng âm thanh làm Nhạc chuông chuẩn'.")
                }
                .padding(20)
            }
            .navigationTitle("Hướng dẫn Nhạc chuông")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đã hiểu") { dismiss() }
                }
            }
        }
    }
    
    private func guideStep(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AudioEditorTheme.accentRed)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
