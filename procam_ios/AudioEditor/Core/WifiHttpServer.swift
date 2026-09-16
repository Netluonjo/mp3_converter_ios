import Foundation
import Network

/// Lightweight embedded HTTP Server on iOS serving Web Transfer API (matching Android's WifiHttpServer)
public final class WifiHttpServer {
    public let port: UInt16
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.sondeptrai.mp3converter.wifiserver", qos: .userInitiated)
    
    public var onLogEvent: ((String) -> Void)?
    public var onFilesChanged: (() -> Void)?
    
    private var isRunning: Bool = false
    
    public init(port: UInt16 = 8080) {
        self.port = port
    }
    
    public func start() throws {
        guard !isRunning else { return }
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "WifiHttpServer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cổng không hợp lệ: \(port)"])
        }
        
        let newListener = try NWListener(using: parameters, on: nwPort)
        self.listener = newListener
        
        newListener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isRunning = true
                self.onLogEvent?("Máy chủ đã sẵn sàng trên cổng \(self.port)")
            case .failed(let error):
                self.isRunning = false
                self.onLogEvent?("Lỗi máy chủ: \(error.localizedDescription)")
            case .cancelled:
                self.isRunning = false
                self.onLogEvent?("Máy chủ đã dừng")
            default:
                break
            }
        }
        
        newListener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        newListener.start(queue: queue)
    }
    
    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        readRequest(from: connection, accumulatedData: Data())
    }
    
    private func readRequest(from connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                connection.cancel()
                return
            }
            
            var totalData = accumulatedData
            if let data = data {
                totalData.append(data)
            }
            
            // Check if HTTP header is fully received
            let headerSeparator = Data("\r\n\r\n".utf8)
            if let headerRange = totalData.range(of: headerSeparator) {
                let headerData = totalData.subdata(in: 0..<headerRange.lowerBound)
                guard let headerString = String(data: headerData, encoding: .utf8) else {
                    self.sendResponse(connection: connection, statusCode: 400, contentType: "text/plain", body: Data("Bad Request".utf8))
                    return
                }
                
                // Parse Content-Length if present
                let contentLength = self.extractContentLength(from: headerString)
                let bodyStart = headerRange.upperBound
                let currentBodyLength = totalData.count - bodyStart
                
                if currentBodyLength < contentLength {
                    // Need more body data
                    self.readRequest(from: connection, accumulatedData: totalData)
                    return
                }
                
                // Full request received
                let bodyData = totalData.subdata(in: bodyStart..<(bodyStart + contentLength))
                self.processRequest(connection: connection, headerString: headerString, bodyData: bodyData)
            } else if isComplete {
                connection.cancel()
            } else {
                self.readRequest(from: connection, accumulatedData: totalData)
            }
        }
    }
    
    private func extractContentLength(from headers: String) -> Int {
        for line in headers.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("content-length:") {
                let parts = line.components(separatedBy: ":")
                if parts.count >= 2, let len = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    return len
                }
            }
        }
        return 0
    }
    
    private func processRequest(connection: NWConnection, headerString: String, bodyData: Data) {
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, contentType: "text/plain", body: Data("Bad Request".utf8))
            return
        }
        
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, contentType: "text/plain", body: Data("Bad Request".utf8))
            return
        }
        
        let method = parts[0].uppercased()
        let fullPath = parts[1]
        
        let urlComponents = URLComponents(string: fullPath)
        let path = urlComponents?.path ?? fullPath
        let queryItems = urlComponents?.queryItems ?? []
        
        switch (method, path) {
        case ("GET", "/"):
            serveHtmlPage(connection: connection)
            
        case ("GET", "/api/files"):
            serveFileListJson(connection: connection)
            
        case ("POST", "/api/upload"):
            handleFileUpload(connection: connection, headers: headerString, body: bodyData)
            
        case ("GET", "/api/stream"), ("GET", "/api/download"):
            let fileName = queryItems.first(where: { $0.name == "file" })?.value ?? ""
            let isStream = (path == "/api/stream")
            handleFileServe(connection: connection, fileName: fileName, isStream: isStream)
            
        case ("POST", "/api/delete"):
            handleFileDelete(connection: connection, headers: headerString, body: bodyData)
            
        default:
            sendResponse(connection: connection, statusCode: 404, contentType: "text/plain", body: Data("404 Not Found".utf8))
        }
    }
    
    // MARK: - Handlers
    
    private func serveHtmlPage(connection: NWConnection) {
        // Try loading web_transfer.html from main bundle or Resources
        var htmlContent: String? = nil
        
        if let bundlePath = Bundle.main.path(forResource: "web_transfer", ofType: "html"),
           let content = try? String(contentsOfFile: bundlePath, encoding: .utf8) {
            htmlContent = content
        } else {
            // Check Documents/Resources fallback or direct relative path
            let possiblePaths = [
                Bundle.main.bundlePath + "/web_transfer.html",
                Bundle.main.bundlePath + "/Resources/web_transfer.html"
            ]
            for p in possiblePaths {
                if let c = try? String(contentsOfFile: p, encoding: .utf8) {
                    htmlContent = c
                    break
                }
            }
        }
        
        if htmlContent == nil {
            htmlContent = """
            <!DOCTYPE html><html><head><meta charset="utf-8"><title>MP3 Converter WiFi Transfer</title></head>
            <body style="font-family:sans-serif;background:#0D0D10;color:#fff;text-align:center;padding:50px;">
            <h2>MP3 Converter & Audio Editor • WiFi Transfer</h2>
            <p>Kết nối thành công! Đang đồng bộ giao diện truyền nhạc...</p>
            </body></html>
            """
        }
        
        sendResponse(connection: connection, statusCode: 200, contentType: "text/html; charset=utf-8", body: Data(htmlContent!.utf8))
    }
    
    private func serveFileListJson(connection: NWConnection) {
        let exportDir = AudioFileManager.shared.exportsDirectory
        let fileManager = FileManager.default
        let items = (try? fileManager.contentsOfDirectory(at: exportDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])) ?? []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        
        var filesList: [[String: Any]] = []
        for url in items {
            let ext = url.pathExtension.lowercased()
            guard ["mp3", "m4a", "wav", "aac", "flac", "ogg", "m4r"].contains(ext) else { continue }
            
            let res = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = res?.fileSize ?? 0
            let date = res?.contentModificationDate ?? Date()
            
            let formattedSize: String
            if size < 1024 * 1024 {
                formattedSize = String(format: "%.1f KB", Double(size) / 1024.0)
            } else {
                formattedSize = String(format: "%.1f MB", Double(size) / (1024.0 * 1024.0))
            }
            
            filesList.append([
                "name": url.lastPathComponent,
                "extension": ext.uppercased(),
                "size": size,
                "formattedSize": formattedSize,
                "date": dateFormatter.string(from: date)
            ])
        }
        
        let jsonData = (try? JSONSerialization.data(withJSONObject: filesList, options: [])) ?? Data("[]".utf8)
        sendResponse(connection: connection, statusCode: 200, contentType: "application/json; charset=utf-8", body: jsonData)
    }
    
    private func handleFileUpload(connection: NWConnection, headers: String, body: Data) {
        guard let boundary = extractBoundary(from: headers) else {
            sendResponse(connection: connection, statusCode: 400, contentType: "application/json", body: Data("{\"success\":false,\"message\":\"Missing boundary\"}".utf8))
            return
        }
        
        let savedFiles = parseMultipartAndSave(body: body, boundary: boundary)
        DispatchQueue.main.async { [weak self] in
            AudioFileManager.shared.reloadLibrary()
            self?.onFilesChanged?()
        }
        
        for name in savedFiles {
            onLogEvent?("⬇️ Đã nhận từ PC: \(name)")
        }
        
        sendResponse(connection: connection, statusCode: 200, contentType: "application/json", body: Data("{\"success\":true}".utf8))
    }
    
    private func extractBoundary(from headers: String) -> String? {
        for line in headers.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.contains("content-type:") && lower.contains("boundary=") {
                let parts = line.components(separatedBy: "boundary=")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                }
            }
        }
        return nil
    }
    
    private func parseMultipartAndSave(body: Data, boundary: String) -> [String] {
        var savedFileNames: [String] = []
        let boundaryPrefix = "--" + boundary
        let boundaryData = Data(boundaryPrefix.utf8)
        let exportDir = AudioFileManager.shared.exportsDirectory
        
        var searchRange = 0..<body.count
        while let startRange = body.range(of: boundaryData, in: searchRange) {
            let nextStart = startRange.upperBound
            searchRange = nextStart..<body.count
            
            guard let endRange = body.range(of: boundaryData, in: searchRange) else { break }
            let partData = body.subdata(in: nextStart..<endRange.lowerBound)
            
            // Look for \r\n\r\n dividing headers and binary payload
            let headerSep = Data("\r\n\r\n".utf8)
            guard let sepRange = partData.range(of: headerSep) else { continue }
            
            let partHeaderData = partData.subdata(in: 0..<sepRange.lowerBound)
            guard let partHeaderStr = String(data: partHeaderData, encoding: .utf8) else { continue }
            
            // Extract filename="..."
            if let fnRange = partHeaderStr.range(of: "filename=\"") {
                let rest = partHeaderStr[fnRange.upperBound...]
                if let quoteEnd = rest.firstIndex(of: "\"") {
                    let rawFilename = String(rest[..<quoteEnd])
                    let cleanFilename = URL(fileURLWithPath: rawFilename).lastPathComponent
                    guard !cleanFilename.isEmpty else { continue }
                    
                    var filePayload = partData.subdata(in: sepRange.upperBound..<partData.count)
                    // Trim trailing \r\n
                    if filePayload.count >= 2 && filePayload.suffix(2) == Data("\r\n".utf8) {
                        filePayload = filePayload.subdata(in: 0..<(filePayload.count - 2))
                    }
                    
                    let targetURL = exportDir.appendingPathComponent(cleanFilename)
                    try? filePayload.write(to: targetURL, options: .atomic)
                    savedFileNames.append(cleanFilename)
                }
            }
        }
        return savedFileNames
    }
    
    private func handleFileServe(connection: NWConnection, fileName: String, isStream: Bool) {
        let cleanName = (fileName.removingPercentEncoding ?? fileName).trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else {
            sendResponse(connection: connection, statusCode: 400, contentType: "text/plain", body: Data("Missing file parameter".utf8))
            return
        }
        
        let targetURL = AudioFileManager.shared.exportsDirectory.appendingPathComponent(cleanName)
        guard FileManager.default.fileExists(atPath: targetURL.path),
              let fileData = try? Data(contentsOf: targetURL) else {
            sendResponse(connection: connection, statusCode: 404, contentType: "text/plain", body: Data("File not found".utf8))
            return
        }
        
        let ext = targetURL.pathExtension.lowercased()
        let mimeType: String
        switch ext {
        case "mp3": mimeType = "audio/mpeg"
        case "m4a": mimeType = "audio/mp4"
        case "wav": mimeType = "audio/wav"
        case "aac": mimeType = "audio/aac"
        case "flac": mimeType = "audio/flac"
        default: mimeType = "application/octet-stream"
        }
        
        var extraHeaders: [String: String] = [:]
        if !isStream {
            extraHeaders["Content-Disposition"] = "attachment; filename=\"\(cleanName)\""
            onLogEvent?("⬆️ Đã gửi về PC: \(cleanName)")
        }
        
        sendResponse(connection: connection, statusCode: 200, contentType: mimeType, body: fileData, extraHeaders: extraHeaders)
    }
    
    private func handleFileDelete(connection: NWConnection, headers: String, body: Data) {
        var fileName: String? = nil
        
        if let bodyString = String(data: body, encoding: .utf8) {
            // Check form-data or urlencoded
            if bodyString.contains("name=\"file\"") {
                let parts = bodyString.components(separatedBy: "name=\"file\"")
                if parts.count >= 2 {
                    let sub = parts[1].components(separatedBy: "\r\n\r\n")
                    if sub.count >= 2 {
                        fileName = sub[1].components(separatedBy: "\r\n").first?.trimmingCharacters(in: .whitespaces)
                    }
                }
            } else if bodyString.contains("file=") {
                let parts = bodyString.components(separatedBy: "file=")
                if parts.count >= 2 {
                    fileName = parts[1].components(separatedBy: "&").first?.removingPercentEncoding
                }
            }
        }
        
        if let name = fileName, !name.isEmpty {
            let targetURL = AudioFileManager.shared.exportsDirectory.appendingPathComponent(name)
            let lrcURL = targetURL.deletingPathExtension().appendingPathExtension("lrc")
            try? FileManager.default.removeItem(at: targetURL)
            try? FileManager.default.removeItem(at: lrcURL)
            
            DispatchQueue.main.async { [weak self] in
                AudioFileManager.shared.reloadLibrary()
                self?.onFilesChanged?()
            }
            onLogEvent?("🗑️ Đã xóa từ Web: \(name)")
            sendResponse(connection: connection, statusCode: 200, contentType: "application/json", body: Data("{\"success\":true}".utf8))
        } else {
            sendResponse(connection: connection, statusCode: 400, contentType: "application/json", body: Data("{\"success\":false,\"message\":\"Missing file name\"}".utf8))
        }
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, contentType: String, body: Data, extraHeaders: [String: String] = [:]) {
        let statusText = (statusCode == 200) ? "OK" : (statusCode == 404 ? "Not Found" : "Error")
        var headerString = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        headerString += "Content-Type: \(contentType)\r\n"
        headerString += "Content-Length: \(body.count)\r\n"
        headerString += "Connection: close\r\n"
        headerString += "Access-Control-Allow-Origin: *\r\n"
        
        for (k, v) in extraHeaders {
            headerString += "\(k): \(v)\r\n"
        }
        headerString += "\r\n"
        
        var responseData = Data(headerString.utf8)
        responseData.append(body)
        
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
