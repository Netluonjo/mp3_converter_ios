import SwiftUI

/// Main container for MP3 Converter & Audio Editor application
public struct AudioEditorMainView: View {
    @StateObject private var fileManager = AudioFileManager.shared
    @StateObject private var playerManager = AudioPlayerManager()
    
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Studio (The exact screen from Image 1)
            AudioPlayerDetailView(
                playerManager: playerManager,
                fileManager: fileManager,
                onBack: {
                    selectedTab = 1
                }
            )
            .tabItem {
                Label("Studio", systemImage: "waveform.circle.fill")
            }
            .tag(0)
            
            // Tab 2: Tools
            AudioToolsGridView(
                fileManager: fileManager,
                playerManager: playerManager
            )
            .tabItem {
                Label("Công cụ", systemImage: "slider.horizontal.3")
            }
            .tag(1)
            
            // Tab 3: Library
            AudioLibraryView(
                fileManager: fileManager,
                playerManager: playerManager,
                onSelectTrack: { track in
                    selectedTab = 0 // Switch to Studio to play
                }
            )
            .tabItem {
                Label("Thư viện", systemImage: "music.note.list")
            }
            .tag(2)
            
            // Tab 4: Settings & Guidelines
            AudioSettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AudioEditorTheme.accentRed)
        .onAppear {
            if let first = fileManager.savedTracks.first {
                playerManager.loadTrack(first)
            } else {
                playerManager.loadTrack(AudioTrack.demoTrack)
            }
        }
    }
}

/// Settings and Technical Compliance Screen
struct AudioSettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("BẢN QUYỀN & GIẤY PHÉP PHẦN MỀM")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Giấy phép FFmpeg (LGPL v2.1+)")
                            .font(.system(size: 15, weight: .bold))
                        Text("Ứng dụng tuân thủ tiêu chuẩn LGPL khi đóng gói thư viện FFmpeg-Kit. Bộ mã nguồn mở không vi phạm chính sách của Apple App Store.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("TÍNH NĂNG TỆP & CHIA SẺ")) {
                    HStack {
                        Image(systemName: "folder.badge.gear")
                            .foregroundColor(AudioEditorTheme.accentRed)
                        VStack(alignment: .leading) {
                            Text("Truy cập trong app Tệp (Files)")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Bật cờ UIFileSharingEnabled & LSSupportsOpeningDocumentsInPlace")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "airdrop")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Chia sẻ AirDrop & Mạng xã hội")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Xuất trực tiếp tới máy Mac, iPad hoặc các ứng dụng khác")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("MÔ HÌNH KIẾM TIỀN (MONETIZATION)")) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text("Gói Pro / VIP Lifetime")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Xóa quảng cáo, mở khóa xuất FLAC Lossless & Bitrate 320k")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Đã kích hoạt")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AudioEditorTheme.accentRed)
                    }
                }
                
                Section(footer: Text("MP3 Converter & Audio Editor v1.0 • ProCam Engine iOS")) {
                    EmptyView()
                }
            }
            .navigationTitle("Cài đặt & Giấy phép")
        }
    }
}
