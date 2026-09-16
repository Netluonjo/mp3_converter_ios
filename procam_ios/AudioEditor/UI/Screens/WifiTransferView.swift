import SwiftUI

/// Screen faithfully matching Android's WifiTransferScreen:
/// - Server switch toggle
/// - IP address display box (e.g. http://192.168.1.15:8080)
/// - Copy and Share buttons
/// - 3-step simple connection guide
/// - Live file transfer event logs
public struct WifiTransferView: View {
    @StateObject private var transferManager = WifiTransferManager()
    @ObservedObject public var fileManager: AudioFileManager
    public var onBack: (() -> Void)?
    
    @State private var showCopiedAlert = false
    @State private var showShareSheet = false
    
    public init(fileManager: AudioFileManager = .shared, onBack: (() -> Void)? = nil) {
        self.fileManager = fileManager
        self.onBack = onBack
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Server Status Card
                    serverStatusCard
                    
                    // MARK: - 3-Step Instructions Card
                    instructionsCard
                    
                    // MARK: - Live Activity Logs Card
                    activityLogsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Chuyển nhạc qua Wi-Fi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onBack?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Quay lại")
                        }
                        .foregroundColor(AudioEditorTheme.accentRed)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !transferManager.serverUrl.isEmpty {
                    ShareSheet(activityItems: ["Truy cập địa chỉ này trên máy tính để chuyển file nhạc: \(transferManager.serverUrl)"])
                }
            }
            .overlay(
                // Toast notification when copied
                VStack {
                    if showCopiedAlert {
                        Text("Đã sao chép địa chỉ vào bộ nhớ tạm!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.black.opacity(0.85)))
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .animation(.easeInOut, value: showCopiedAlert)
            )
            .onDisappear {
                transferManager.stopServer()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var serverStatusCard: some View {
        VStack(spacing: 14) {
            // Header Row with Indicator and Switch
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(transferManager.isServerRunning ? Color(red: 0.2, green: 0.78, blue: 0.35) : Color.gray)
                        .frame(width: 14, height: 14)
                    
                    Text(transferManager.isServerRunning ? "Máy chủ đang chạy" : "Máy chủ đã tắt")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(transferManager.isServerRunning ? Color(red: 0.3, green: 0.85, blue: 0.45) : Color(UIColor.label))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { transferManager.isServerRunning },
                    set: { shouldRun in
                        if shouldRun {
                            transferManager.startServer()
                        } else {
                            transferManager.stopServer()
                        }
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.2, green: 0.78, blue: 0.35))
            }
            
            if transferManager.isServerRunning && !transferManager.serverUrl.isEmpty {
                VStack(spacing: 10) {
                    Text("Nhập địa chỉ sau vào trình duyệt trên PC:")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.lightGray))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Highlighted URL Box
                    HStack {
                        Spacer()
                        Text(transferManager.serverUrl)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.06, green: 0.11, blue: 0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.22, green: 0.56, blue: 0.24), lineWidth: 1)
                            )
                    )
                    
                    // Important HTTP hint
                    Text("⚠️ Lưu ý: Bắt buộc gõ đầy đủ http:// ở đầu (không dùng https://)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.72, blue: 0.30))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    // Copy & Share buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            UIPasteboard.general.string = transferManager.serverUrl
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation { showCopiedAlert = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopiedAlert = false }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 13))
                                Text("Sao chép")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.18, green: 0.49, blue: 0.20))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13))
                                Text("Chia sẻ")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.51, green: 0.78, blue: 0.52), lineWidth: 1)
                            )
                            .foregroundColor(Color(red: 0.51, green: 0.78, blue: 0.52))
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Gạt nút công tắc phía trên để bắt đầu chia sẻ file với máy tính qua Wi-Fi.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(transferManager.isServerRunning ? Color(red: 0.11, green: 0.16, blue: 0.13) : Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    transferManager.isServerRunning ?
                    RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.18, green: 0.49, blue: 0.20), lineWidth: 1) : nil
                )
        )
    }
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hướng dẫn 3 bước đơn giản")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            
            instructionRow(
                number: "1",
                title: "Chung mạng Wi-Fi",
                desc: "Đảm bảo điện thoại và máy tính kết nối cùng 1 mạng Wi-Fi (hoặc điện thoại bật Điểm phát sóng di động)."
            )
            
            instructionRow(
                number: "2",
                title: "Mở trình duyệt trên máy tính",
                desc: "Mở Chrome, Cốc Cốc hoặc Edge trên máy tính, gõ đúng địa chỉ IP hiển thị ở khung trên."
            )
            
            instructionRow(
                number: "3",
                title: "Kéo thả & Tải file 2 chiều",
                desc: "Kéo file nhạc vào trình duyệt để chuyển vào app, hoặc bấm Tải về để copy nhạc về máy tính."
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private func instructionRow(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AudioEditorTheme.accentRed)
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var activityLogsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nhật ký truyền file")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(transferManager.logs.count) sự kiện")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            if transferManager.logs.isEmpty {
                Text("Chưa có lượt truyền file nào. Các sự kiện tải lên và tải về sẽ hiển thị tại đây theo thời gian thực.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(transferManager.logs.prefix(15), id: \.self) { log in
                        Text(log)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(red: 0.85, green: 0.9, blue: 0.88))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.09, green: 0.09, blue: 0.11))
        )
    }
}
