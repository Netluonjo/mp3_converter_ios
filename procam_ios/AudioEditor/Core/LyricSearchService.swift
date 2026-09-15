import Foundation
import Combine

/// Model representing a lyric search result from LRCLIB API
public struct LyricSearchResult: Identifiable, Codable, Hashable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String?
    public let duration: Double?
    public let syncedLyrics: String?
    public let plainLyrics: String?
    
    public var hasSyncedLyrics: Bool {
        guard let synced = syncedLyrics else { return false }
        return !synced.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var formattedDuration: String {
        guard let dur = duration, dur > 0 else { return "--:--" }
        let total = Int(dur)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var resolvedLyrics: String? {
        return (hasSyncedLyrics ? syncedLyrics : plainLyrics)
    }
}

/// Service connecting to LRCLIB (open-source synced lyrics database)
@MainActor
public final class LyricSearchService: ObservableObject {
    public static let shared = LyricSearchService()
    
    @Published public var isSearching: Bool = false
    @Published public var searchResults: [LyricSearchResult] = []
    @Published public var errorMessage: String? = nil
    
    private init() {}
    
    /// Searches for synced lyrics matching user query (e.g. song title and/or artist)
    public func search(query: String) async -> [LyricSearchResult] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            self.searchResults = []
            return []
        }
        
        self.isSearching = true
        self.errorMessage = nil
        
        guard let encodedQuery = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lrclib.net/api/search?q=\(encodedQuery)") else {
            self.isSearching = false
            self.errorMessage = "URL không hợp lệ"
            return []
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10.0
            request.setValue("ProCam-AudioEditor/1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.isSearching = false
                self.errorMessage = "Không thể tải dữ liệu từ máy chủ"
                return []
            }
            
            let results = try JSONDecoder().decode([LyricSearchResult].self, from: data)
            // Prioritize results with synced LRC lyrics
            let sorted = results.sorted { lhs, rhs in
                if lhs.hasSyncedLyrics != rhs.hasSyncedLyrics {
                    return lhs.hasSyncedLyrics && !rhs.hasSyncedLyrics
                }
                return false
            }
            
            self.searchResults = sorted
            self.isSearching = false
            return sorted
        } catch {
            self.isSearching = false
            self.errorMessage = "Lỗi kết nối: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Auto-fetch best matched LRC lyrics for a given track title and audio duration
    public func autoFetchBestMatch(trackTitle: String, duration: TimeInterval) async -> String? {
        // Strip out file extensions or recording tags like "Ghi âm 1", ".mp3", "(1)"
        var cleanTitle = trackTitle
            .replacingOccurrences(of: "\\.[a-zA-Z0-9]{2,4}$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanTitle.isEmpty else { return nil }
        
        let results = await search(query: cleanTitle)
        
        // Find best match with synced lyrics
        if let exactSynced = results.first(where: { $0.hasSyncedLyrics }) {
            return exactSynced.syncedLyrics
        }
        
        return results.first?.resolvedLyrics
    }
}
