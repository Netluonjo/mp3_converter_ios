import Foundation
import AVFoundation
import SwiftUI
import UIKit

// MARK: - Shooting Modes
public enum ShootingMode: String, CaseIterable, Identifiable {
    case photo = "PHOTO"
    case manual = "MANUAL"
    case slowShutter = "SLOW SHUTTER"
    case burst = "BURST"
    case antiShake = "ANTI-SHAKE"
    case video = "VIDEO"
    case portrait = "PORTRAIT"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}

// MARK: - Slow Shutter Modes
public enum SlowShutterMode: String, CaseIterable, Identifiable {
    case lightTrails = "Light Trails"
    case motionBlur = "Motion Blur"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}

// MARK: - Manual Parameters
public enum ManualParameter: String, CaseIterable, Identifiable {
    case none = "NONE"
    case iso = "ISO"
    case sec = "SEC"
    case ev = "EV"
    case af = "AF"
    case awb = "AWB"
    case lock = "E/F"
    
    public var id: String { rawValue }
    public var label: String { rawValue }
}

// MARK: - Peaking Color
public enum PeakingColor: String, CaseIterable, Identifiable {
    case green = "Green"
    case red = "Red"
    case cyan = "Cyan"
    
    public var id: String { rawValue }
    public var color: Color {
        switch self {
        case .green: return ProCamColors.peakingGreen
        case .red: return ProCamColors.peakingRed
        case .cyan: return ProCamColors.peakingCyan
        }
    }
}

// MARK: - Viewfinder Grid Type
public enum GridType: String, CaseIterable, Identifiable {
    case none = "Off"
    case ruleOfThirds = "3x3"
    case goldenRatio = "Golden"
    case crosshair = "Target"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}

// MARK: - Aspect Ratio
public enum AspectRatio: String, CaseIterable, Identifiable {
    case ratio16_9 = "16:9"
    case ratio4_3 = "4:3"
    case ratio1_1 = "1:1"
    
    public var id: String { rawValue }
    public var label: String { rawValue }
    
    public var multiplier: CGFloat {
        switch self {
        case .ratio16_9: return 9.0 / 16.0
        case .ratio4_3: return 3.0 / 4.0
        case .ratio1_1: return 1.0
        }
    }
}

// MARK: - Flash Mode
public enum FlashMode: Int, CaseIterable {
    case off = 0
    case auto = 1
    case on = 2
    case torch = 3
    
    public var label: String {
        switch self {
        case .off: return "Off"
        case .auto: return "Auto"
        case .on: return "On"
        case .torch: return "Torch"
        }
    }
}

// MARK: - EV Photographic Stops
public struct EvStop: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let value: Float
    
    public init(_ label: String, _ value: Float) {
        self.label = label
        self.value = value
    }
}

public let HALIDE_EV_VALUES: [EvStop] = [
    EvStop("-3.0", -3.0),
    EvStop("-2.5", -2.5),
    EvStop("-2.0", -2.0),
    EvStop("-1.5", -1.5),
    EvStop("-1.0", -1.0),
    EvStop("-0.5", -0.5),
    EvStop("0.0", 0.0),
    EvStop("+0.5", 0.5),
    EvStop("+1.0", 1.0),
    EvStop("+1.5", 1.5),
    EvStop("+2.0", 2.0),
    EvStop("+2.5", 2.5),
    EvStop("+3.0", 3.0),
    EvStop("+3.5", 3.5),
    EvStop("+4.0", 4.0)
]

// MARK: - ISO Photographic Stops
public struct IsoStop: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let value: Int // -1 represents AUTO
    
    public init(_ label: String, _ value: Int) {
        self.label = label
        self.value = value
    }
}

public let HALIDE_ISO_VALUES: [IsoStop] = [
    IsoStop("AUTO", -1),
    IsoStop("50", 50),
    IsoStop("64", 64),
    IsoStop("80", 80),
    IsoStop("100", 100),
    IsoStop("125", 125),
    IsoStop("160", 160),
    IsoStop("200", 200),
    IsoStop("250", 250),
    IsoStop("320", 320),
    IsoStop("400", 400),
    IsoStop("500", 500),
    IsoStop("640", 640),
    IsoStop("800", 800),
    IsoStop("1000", 1000),
    IsoStop("1250", 1250),
    IsoStop("1600", 1600),
    IsoStop("2000", 2000),
    IsoStop("2500", 2500),
    IsoStop("3200", 3200),
    IsoStop("6400", 6400)
]

// MARK: - Focus Stops
public struct FocusStop: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let lensPosition: Float // 0.0: infinity, 1.0: closest macro
    public let isAuto: Bool
    
    public init(_ label: String, _ lensPosition: Float, isAuto: Bool = false) {
        self.label = label
        self.lensPosition = lensPosition
        self.isAuto = isAuto
    }
}

public let HALIDE_FOCUS_VALUES: [FocusStop] = [
    FocusStop("AUTO", 0.0, isAuto: true),
    FocusStop("MACRO", 1.0),
    FocusStop("0.1m", 0.85),
    FocusStop("0.2m", 0.70),
    FocusStop("0.35m", 0.55),
    FocusStop("0.5m", 0.40),
    FocusStop("1.0m", 0.25),
    FocusStop("2.0m", 0.15),
    FocusStop("5.0m", 0.07),
    FocusStop("∞", 0.0)
]

// MARK: - White Balance Stops
public struct WbStop: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let kelvin: Int // -1 for AUTO
    public let isAuto: Bool
    public let indicatorColor: Color
    
    public init(_ label: String, _ kelvin: Int, isAuto: Bool = false, indicatorColor: Color = Color.white) {
        self.label = label
        self.kelvin = kelvin
        self.isAuto = isAuto
        self.indicatorColor = indicatorColor
    }
}

public let HALIDE_WB_VALUES: [WbStop] = [
    WbStop("AUTO", -1, isAuto: true, indicatorColor: Color(red: 0.2, green: 0.8, blue: 0.4)),
    WbStop("2000K", 2000, indicatorColor: Color(red: 1.0, green: 0.4, blue: 0.1)),
    WbStop("2800K", 2800, indicatorColor: Color(red: 1.0, green: 0.55, blue: 0.2)),
    WbStop("3200K", 3200, indicatorColor: Color(red: 1.0, green: 0.7, blue: 0.3)),
    WbStop("4000K", 4000, indicatorColor: Color(red: 1.0, green: 0.85, blue: 0.5)),
    WbStop("5000K", 5000, indicatorColor: Color(red: 1.0, green: 0.95, blue: 0.8)),
    WbStop("5500K", 5500, indicatorColor: Color.white),
    WbStop("6000K", 6000, indicatorColor: Color(red: 0.85, green: 0.9, blue: 1.0)),
    WbStop("6500K", 6500, indicatorColor: Color(red: 0.7, green: 0.8, blue: 1.0)),
    WbStop("7500K", 7500, indicatorColor: Color(red: 0.55, green: 0.7, blue: 1.0)),
    WbStop("8500K", 8500, indicatorColor: Color(red: 0.45, green: 0.6, blue: 1.0)),
    WbStop("10000K", 10000, indicatorColor: Color(red: 0.35, green: 0.5, blue: 1.0))
]

// MARK: - Shutter Speed Stops
public struct ShutterStop: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let seconds: Double // -1 for AUTO
    public let isAuto: Bool
    
    public init(_ label: String, _ seconds: Double, isAuto: Bool = false) {
        self.label = label
        self.seconds = seconds
        self.isAuto = isAuto
    }
}

public let SHUTTER_STOPS: [ShutterStop] = [
    ShutterStop("AUTO", -1.0, isAuto: true),
    ShutterStop("1/8000", 1.0 / 8000.0),
    ShutterStop("1/4000", 1.0 / 4000.0),
    ShutterStop("1/2000", 1.0 / 2000.0),
    ShutterStop("1/1000", 1.0 / 1000.0),
    ShutterStop("1/500", 1.0 / 500.0),
    ShutterStop("1/250", 1.0 / 250.0),
    ShutterStop("1/125", 1.0 / 125.0),
    ShutterStop("1/60", 1.0 / 60.0),
    ShutterStop("1/30", 1.0 / 30.0),
    ShutterStop("1/15", 1.0 / 15.0),
    ShutterStop("1/8", 1.0 / 8.0),
    ShutterStop("1/4", 1.0 / 4.0),
    ShutterStop("1/2", 1.0 / 2.0),
    ShutterStop("1\"", 1.0),
    ShutterStop("2\"", 2.0),
    ShutterStop("4\"", 4.0),
    ShutterStop("8\"", 8.0),
    ShutterStop("15\"", 15.0),
    ShutterStop("30\"", 30.0)
]

// MARK: - Camera UI State
public struct CameraUiState {
    public var isInitialized: Bool = false
    public var selectedMode: ShootingMode = .manual
    public var activeManualParam: ManualParameter = .none
    
    // Exposure controls
    public var isAutoIso: Bool = true
    public var currentIso: Int = 100
    
    public var isAutoShutter: Bool = true
    public var currentExposureDurationSeconds: Double = 1.0 / 100.0
    
    public var isAutoFocus: Bool = true
    public var currentLensPosition: Float = 0.5 // 0.0: infinity, 1.0: closest macro
    
    public var isAutoWb: Bool = true
    public var currentKelvin: Int = 5500
    
    public var currentEv: Float = 0.0 // -3.0 to +4.0
    public var currentZoomRatio: CGFloat = 1.0
    public var maxZoomRatio: CGFloat = 10.0
    
    public var currentZoomFactor: CGFloat {
        get { currentZoomRatio }
        set { currentZoomRatio = newValue }
    }
    public var maxZoomFactor: CGFloat {
        get { maxZoomRatio }
        set { maxZoomRatio = newValue }
    }
    
    // Capture format & Top bar pills
    public var isRawEnabled: Bool = false
    public var isTiffEnabled: Bool = false
    public var isSbrtEnabled: Bool = false
    public var isAebEnabled: Bool = false
    public var flashMode: FlashMode = .off
    
    // Assistance overlays & Settings
    public var isFocusPeakingEnabled: Bool = false
    public var peakingColor: PeakingColor = .green
    public var isZebraEnabled: Bool = false
    public var zebraThreshold: Float = 0.95
    public var gridType: GridType = .ruleOfThirds
    public var isHistogramEnabled: Bool = true
    public var isTiltMeterEnabled: Bool = true
    public var aspectRatio: AspectRatio = .ratio16_9
    
    // Slow Shutter & Anti-Shake
    public var slowShutterMode: SlowShutterMode = .lightTrails
    public var slowShutterDurationSec: Int = 4
    public var isCapturingLongExposure: Bool = false
    public var isSteadyForCapture: Bool = true
    
    // Video
    public var isRecordingVideo: Bool = false
    public var videoRecordingSeconds: Int = 0
    public var audioDecibelLevel: Float = 0.0
    
    // Camera Position & Feedback
    public var isFrontCamera: Bool = false
    public var isShutterFlashing: Bool = false
    public var lastCapturedImage: UIImage? = nil
    
    // ProCam Controls & Menu Modals
    public var isAeAfLocked: Bool = false
    public var isWbLocked: Bool = false
    public var timerSeconds: Int = 0 // 0: Off, 3: 3s, 10: 10s
    public var isModeDrawerExpanded: Bool = false
    public var isSetMenuOpen: Bool = false
    public var batteryPercent: Int = 85
    public var freeStorageGb: String = "127.8"
    public var sensorMegapixels: String = "48MP"
    
    public init() {}
    
    public func formatShutterSpeed(_ seconds: Double) -> String {
        if seconds >= 1.0 {
            return String(format: "%.1f\"", seconds)
        } else if seconds > 0.0 {
            let denom = Int(round(1.0 / seconds))
            return "1/\(denom)"
        } else {
            return "AUTO"
        }
    }
    
    public func formatEv(_ ev: Float) -> String {
        if ev > 0 {
            return String(format: "+%.1f", ev)
        } else if ev < 0 {
            return String(format: "%.1f", ev)
        } else {
            return "+0.0"
        }
    }
    
    public func formatFocusDistance(_ pos: Float) -> String {
        if pos <= 0.05 {
            return "∞"
        } else if pos >= 0.90 {
            return "MACRO"
        } else {
            let meters = (1.0 - pos) * 3.0 + 0.1
            return String(format: "%.1fm", meters)
        }
    }
}
