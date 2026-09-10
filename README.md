# ProCam iOS – Professional Manual Camera for iOS

Ứng dụng máy ảnh chuyên nghiệp native cho hệ điều hành iOS (viết bằng **SwiftUI**, **AVFoundation**, **CoreMotion**, **CoreGraphics/vImage** và **AVAudioSession**), phiên bản đối ứng hoàn chỉnh 100% với **ProCam Android**, kết hợp phong cách DSLR cao cấp và tinh hoa từ **Halide Camera** & **ProCam**.

---

## 📸 Tính năng cốt lõi (Features)

### 1. Điều khiển thủ công hoàn toàn (Full Manual Controls)
- **Tốc độ màn trập (Shutter Speed - SEC):** Tùy biến từ $1/8000\text{s}$ đến $30\text{s}$ bằng thước đo cơ học với kim đỏ ProCam Red (`ProCamRulerDialView`).
- **Độ nhạy sáng (ISO):** Tinh chỉnh từ ISO 50 đến 6400 bằng vòng xoay 3D Halide Drum Dial (`HalideDrumDialView`), kèm phím tắt nhảy nhanh `[ AUTO ]`, `[ 100 ]`, `[ 400 ]`, `[ 1600 ]`.
- **Lấy nét thủ công (Manual Focus - AF):** Vòng lấy nét mượt mà từ cận cảnh (`MACRO`), $0.1\text{m}$, $0.5\text{m}$, $1.0\text{m}$ đến vô cực ($\infty$) kèm phím tắt nhanh (`HalideFocusDialView`).
- **Cân bằng trắng (White Balance - AWB):** Điều chỉnh nhiệt độ màu Kelvin từ $2000\text{K}$ đến $10000\text{K}$ với chấm màu quang phổ trực quan và phím chọn nhanh `[ AUTO ]`, `[ INCAN ]`, `[ FLUOR ]`, `[ DAY ]`, `[ SHADE ]` (`HalideWbDialView`).
- **Bù trừ sáng (Exposure Compensation - EV):** Vòng xoay khắc số 3D từ $-3.0\text{EV}$ đến $+4.0\text{EV}$ theo từng nấc $0.5\text{EV}$, kèm phím nhảy nhanh `[ 0.0 ]`, `[ +1.0 ]`, `[ +2.0 ]`, `[ +3.0 ]`.
- **Khóa đo sáng & lấy nét độc lập (E/F Lock):** Phím bấm kích hoạt nhanh `[ LOCK AE/AF ]` và `[ LOCK WB ]`.

### 2. Công cụ hỗ trợ nét & sáng chuyên nghiệp (Professional Assist Tools)
- **Thanh thông số 6 cột chuẩn ProCam:** `[ ISO ]  [ SEC ]  [ EV ]  [ AF ]  [ AWB ]  [ E/F ]` với gạch chân vàng hổ phách hiển thị trạng thái và giá trị thời gian thực.
- **Thước cân bằng điện tử (Artificial Horizon / Tiltmeter):** Cảm biến con quay hồi chuyển 3 trục từ `CoreMotion`, tự động chuyển sang màu xanh lá (`PeakingGreen`) khi máy nằm ngang hoàn hảo trong ngưỡng $\pm 0.75^\circ$.
- **Biểu đồ đo sáng thời gian thực (Live Luminance Histogram):** Biểu đồ 256 bậc độ sáng hiển thị dưới dạng đồ thị sóng gradient ở góc dưới bên phải.
- **Đo âm lượng thời gian thực (Stereo Audio VU Meter):** Đo âm thanh micro đa kênh hiển thị 16 vạch chia màu (xanh lá, vàng, đỏ) ở cạnh trái màn hình khi quay Video.
- **Điểm chạm lấy nét thông minh (Tap to Focus):** Vòng ngắm nét ma trận màu vàng hổ phách kèm biểu tượng mặt trời đo sáng AE tự động ẩn sau 2.5s.
- **Lưới căn tỉ lệ (Composition Grids):** Quy tắc $1/3$ (Rule of Thirds), tỉ lệ vàng (Golden Ratio) và hồng tâm (Crosshair).
- **Hộp thoại cài đặt nhanh (SET Modal):** Bật tắt Focus Peaking, Zebra stripes, Viewfinder Grid, Tiltmeter, Histogram và Aspect Ratio ($16:9$, $4:3$, $1:1$).

### 3. Chế độ chụp chuyên dụng (Shooting Modes)
- **Chụp ảnh định dạng Apple ProRAW & HEVC/JPEG:** Tận dụng bộ cảm biến 48MP/12MP để lưu đầy đủ dải tương phản động (Dynamic Range) và EXIF metadata.
- **Chụp chống rung thông minh (Anti-Shake):** Phân tích dao động gia tốc tuyến tính và vận tốc góc từ `CoreMotion`, đảm bảo 15 khung hình liên tiếp ổn định tuyệt đối (~300ms) trước khi bấm chụp.
- **Phơi sáng ảo thông minh (Slow Shutter / Frame Stacking Engine):**
  - *Light Trails (Vệt đèn xe / Sao chạy):* Ghép đa khung hình bằng thuật toán `Maximum Luminance Blend` mà không làm cháy sáng hậu cảnh.
  - *Motion Blur (Làm mượt dòng nước chảy / Mây bay):* Thuật toán `Running Weighted Average Accumulator` làm mờ chuyển động mượt mà không cần kính lọc ND vật lý.
- **Quay phim chuyên nghiệp (Video Mode):** Hỗ trợ hiển thị huy hiệu `🔴 REC mm:ss` cùng đồng hồ đo âm lượng VU meter.

---

## 🏗 Cấu trúc dự án (Project Structure)

```
d:\procam_ios\
├── procam_ios.xcodeproj/
│   └── project.pbxproj             # File cấu hình đồ án Xcode chuẩn
├── README.md
│
└── procam_ios/
    ├── ProCamApp.swift             # Điểm khởi chạy ứng dụng SwiftUI (@main)
    ├── Info.plist                  # Khai báo quyền Camera, Mic, Thư viện ảnh, Motion
    │
    ├── Core/
    │   ├── Camera/
    │   │   ├── CameraManager.swift            # Quản lý AVFoundation, video, audio & raw
    │   │   ├── CameraParameters.swift         # Data models, stops, enums và CameraUiState
    │   │   └── LiveHistogramCalculator.swift  # Tính toán 256 luma bins từ pixel buffer
    │   ├── Sensors/
    │   │   ├── MotionSensorManager.swift      # Con quay hồi chuyển cho thước cân bằng
    │   │   ├── AntiShakeDetector.swift        # Phát hiện đứng yên bằng gia tốc/vận tốc góc
    │   │   └── AudioMeterManager.swift        # Đo mức decibel âm thanh thời gian thực
    │   └── Computational/
    │       └── FrameStackingEngine.swift      # Ghép ảnh Light Trails & Motion Blur
    │
    ├── UI/
    │   ├── Theme/
    │   │   └── ProCamTheme.swift              # Dark DSLR color palette & typography
    │   ├── Views/
    │   │   ├── CameraView.swift               # Màn hình chính điều phối giao diện
    │   │   └── CameraPreviewView.swift        # AVCaptureVideoPreviewLayer cho SwiftUI
    │   └── Components/
    │       ├── CameraTopBarView.swift         # 2 tầng: Flash, RAW/TIFF/SBRT/AEB, SET & info
    │       ├── ManualParamBarView.swift       # Dải 6 cột thông số ProCam
    │       ├── HalideDrumDialView.swift       # Vòng xoay 3D Halide cho EV và ISO
    │       ├── HalideFocusDialView.swift      # Bàn xoay lấy nét thủ công Macro -> ∞
    │       ├── HalideWbDialView.swift         # Bàn xoay cân bằng trắng Kelvin (2000K-10000K)
    │       ├── ProCamRulerDialView.swift      # Thước xoay tốc độ màn trập với kim đỏ
    │       ├── LockControlView.swift          # Bảng điều khiển nút khóa AE/AF và WB Lock
    │       ├── ModeSelectorView.swift         # Ngăn kéo mở rộng chế độ chụp
    │       ├── ShutterControlView.swift       # Nút chụp DSLR morph, gallery, timer & zoom
    │       ├── OverlaysView.swift             # Lưới, thước cân bằng, histogram, reticle
    │       ├── ZoomControlWidget.swift        # Floating zoom pills 1x, 2x, 3x, 5x
    │       ├── AudioVuMeterWidget.swift       # Thước đo âm lượng stereo dọc trong Video
    │       └── ProCamSettingsModalView.swift  # Hộp thoại cài đặt nhanh DSLR SET
    │
    └── Resources/
        └── Assets.xcassets/                   # Icon ứng dụng & tài nguyên đồ họa
```

---

## 🚀 Hướng dẫn mở và chạy dự án trên macOS (How to Run)

1. Sao chép thư mục `procam_ios` sang máy Mac (hoặc mở trực tiếp qua ổ đĩa mạng / USB).
2. Mở dự án trong **Xcode**:
   ```bash
   cd procam_ios
   open procam_ios.xcodeproj
   ```
3. Trong thanh trên cùng của Xcode, chọn thiết bị iPhone thật của bạn (hoặc iOS Simulator ví dụ iPhone 15 Pro / iPhone 16 Pro).
4. Vào mục **Signing & Capabilities** trong Xcode và chọn **Team** cá nhân.
5. Nhấn **Cmd + R** để biên dịch và trải nghiệm!
