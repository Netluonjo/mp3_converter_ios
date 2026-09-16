import Foundation
import SwiftUI

/// Defines the core tools provided in MP3 Converter & Audio Editor
public enum AudioToolType: String, CaseIterable, Identifiable {
    case videoToAudio = "Video to MP3"
    case trimmer = "Audio Cutter"
    case merger = "Audio Merger"
    case volumeBooster = "Volume Booster"
    case formatConverter = "Format Converter"
    case wifiTransfer = "WiFi Transfer"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .videoToAudio: return "film"
        case .trimmer: return "scissors"
        case .merger: return "arrow.triangle.merge"
        case .volumeBooster: return "speaker.wave.3.fill"
        case .formatConverter: return "arrow.2.squarepath"
        case .wifiTransfer: return "wifi"
        }
    }
    
    public var titleVi: String {
        switch self {
        case .videoToAudio: return "Bóc Audio từ Video"
        case .trimmer: return "Cắt nhạc (Trimmer)"
        case .merger: return "Ghép file âm thanh"
        case .volumeBooster: return "Tăng âm lượng"
        case .formatConverter: return "Đổi định dạng"
        case .wifiTransfer: return "Chuyển nhạc Wi-Fi"
        }
    }
    
    public var subtitleVi: String {
        switch self {
        case .videoToAudio: return "Trích xuất MP3/M4A từ video trong Camera Roll"
        case .trimmer: return "Cắt đoạn điệp khúc bằng sóng âm thanh chuẩn xác"
        case .merger: return "Nối nhiều bài hát, bản ghi âm thành 1 file duy nhất"
        case .volumeBooster: return "Khuếch đại âm lượng lên đến 200% - 300%"
        case .formatConverter: return "Chuyển đổi MP3, M4A, WAV, AAC, FLAC, M4R"
        case .wifiTransfer: return "Truyền file 2 chiều giữa Máy tính và Điện thoại"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .videoToAudio: return Color(red: 1.0, green: 0.29, blue: 0.29) // Coral red
        case .trimmer: return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
        case .merger: return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        case .volumeBooster: return Color(red: 0.35, green: 0.34, blue: 0.84) // Purple
        case .formatConverter: return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
        case .wifiTransfer: return Color(red: 0.0, green: 0.74, blue: 0.83) // Cyan (#00BCD4)
        }
    }
}
