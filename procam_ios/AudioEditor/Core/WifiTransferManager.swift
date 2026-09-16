import Foundation
import Combine
#if canImport(Darwin)
import Darwin
#endif

/// Manager responsible for starting/stopping the Wi-Fi HTTP transfer server and tracking transfer logs
public final class WifiTransferManager: ObservableObject {
    @Published public var isServerRunning: Bool = false
    @Published public var serverUrl: String = ""
    @Published public var localIp: String = ""
    @Published public var logs: [String] = []
    
    private var httpServer: WifiHttpServer?
    public let port: UInt16 = 8080
    
    public init() {
        self.localIp = getWiFiAddress() ?? "127.0.0.1"
    }
    
    public func startServer() {
        guard !isServerRunning else { return }
        
        let ip = getWiFiAddress() ?? "127.0.0.1"
        self.localIp = ip
        
        let server = WifiHttpServer(port: port)
        server.onLogEvent = { [weak self] message in
            DispatchQueue.main.async {
                let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                self?.logs.insert("[\(timeStr)] \(message)", at: 0)
                if (self?.logs.count ?? 0) > 50 {
                    self?.logs.removeLast()
                }
            }
        }
        
        server.onFilesChanged = {
            DispatchQueue.main.async {
                AudioFileManager.shared.reloadLibrary()
            }
        }
        
        do {
            try server.start()
            self.httpServer = server
            self.isServerRunning = true
            self.serverUrl = "http://\(ip):\(port)"
            
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            logs.insert("[\(timeStr)] 🚀 Máy chủ Wi-Fi đã khởi động tại: \(serverUrl)", at: 0)
        } catch {
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            logs.insert("[\(timeStr)] ❌ Không thể khởi động máy chủ: \(error.localizedDescription)", at: 0)
            self.isServerRunning = false
        }
    }
    
    public func stopServer() {
        httpServer?.stop()
        httpServer = nil
        isServerRunning = false
        
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.insert("[\(timeStr)] 🛑 Đã dừng máy chủ Wi-Fi", at: 0)
    }
    
    public func clearLogs() {
        logs.removeAll()
    }
    
    /// Queries Unix network interfaces for active IPv4 Wi-Fi or Personal Hotspot address
    public func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            
            if isUp && isRunning && !isLoopback {
                if addr.sa_family == UInt8(AF_INET) {
                    let name = String(cString: ptr.pointee.ifa_name)
                    // en0 = Wi-Fi, bridge100 = Hotspot, pdp_ip0 = Cellular
                    if name == "en0" || name == "bridge100" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len),
                                       &hostname, socklen_t(hostname.count),
                                       nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                            if name == "en0" { break }
                        }
                    }
                }
            }
        }
        return address
    }
}
