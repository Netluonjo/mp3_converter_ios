import Foundation

/// Offline database of popular synchronized LRC lyrics guaranteed to work with zero latency and no internet connection
public struct OfflineLyricsStore {
    
    // MARK: - Pre-packaged Synced Lyrics
    
    public static let xuongRongDangrangtoLRC = """
    [00:18.27]Oh-oh
    [00:21.63]Oh-oh-oh
    [00:25.99]Hm-mm-mm
    [00:30.93]Chắc em không lộng lẫy kiêu sa tựa hoa hồng
    [00:34.62]Chắc em không gần gũi, trên thân toàn gai nhọn
    [00:38.38]Chắc hương thơm chẳng vấn vương bao người xiêu lòng
    [00:41.69]Điều gì khiến cho ai từng đến bên em rồi cũng sẽ chọn đi?
    [00:45.61]Thế gian kia tàn nhẫn coi em là xương rồng
    [00:48.92]Vậy thì có hay không một người sẽ tới đây?
    [00:52.93]Nắm lấy tay em khi vừa thức dậy
    [00:56.63]Ôm lấy em thật chặt vào lúc này, baby
    [01:00.40]Một người chịu đi tưới mát chiếc cây khô cằn
    [01:03.80]Dù là cỏ lạ và hoa thơm kéo tới đây vô vàn
    [01:07.67]Mặc kệ trời nắng cháy rát ở nơi sa mạc
    [01:11.16]Và mặc kệ là nhiều gai đâm nhưng vẫn luôn chọn cố gắng
    [01:15.15]Vì mình cần được yêu cũng giống như xương rồng
    [01:18.51]Cần phải đón lấy chút sương mai để nở lên hoa hồng
    [01:22.48]Chờ một người đặc biệt để sà vào lòng thật lâu
    [01:25.02]Làm dịu bao cơn đau em thường cất giấu
    [01:28.23]Em đừng khóc
    [01:31.74]Ai sẽ lau đi hết nước mắt em long lanh
    [01:35.35]Mạnh mẽ lắm cũng sẽ có khi mong manh
    [01:39.12]Nắng cháy da nhưng trong lòng trăm đợt sóng đánh
    [01:42.65]Bởi vì vết thương lòng đâm sâu, em trở thành chiếc xương rồng
    [01:49.28]Quay đi, em bỏ lại mình của ngày xưa
    [01:52.74]Không cho ai làm tổn thương em nữa
    [01:56.76]Huh-uh-uh-uh-uh, yeah-eh-eh
    [02:06.05]Đừng lo lắng nhé, dựa vai anh
    [02:13.60]Huh, huh-uh-uh, huh-uh-uh
    [02:24.52]Huh-uh-uh-uh
    [02:27.36]Cứ tin anh, baby, đã có anh đây rồi
    [02:30.68]Chẳng sao đâu, cơn đau sẽ qua thật nhanh thôi
    [02:34.56]Nép lên vai và cho anh thêm một cơ hội
    [02:37.97]Và tháng năm sau này để anh cầm tay dẫn lối
    [02:42.01]Có ai trót đi ngang để nơi em tiêu điều
    [02:45.28]Để lại lớp gai đâm em khoác lên vai mình khi yêu
    [02:49.43]Cứa lên anh như trăm con dao kia sắc lẹm
    [02:52.70]Vì giọt lệ hằn sâu trong mắt em
    [02:56.77]Em đừng khóc
    [03:00.45]Anh sẽ lau đi hết nước mắt em long lanh
    [03:04.13]Mạnh mẽ lắm cũng sẽ có khi em mong manh
    [03:07.81]Nắng cháy da nhưng trong lòng trăm đợt sóng đánh
    [03:11.16]Bởi vì vết thương lòng đâm sâu, em trở thành chiếc xương rồng
    [03:17.82]Theo anh đi tìm lại mình của ngày xưa
    [03:21.58]Không cho ai làm tổn thương em nữa
    [03:26.41]Cứ tin anh, baby, đã có anh đây rồi mà
    [03:30.16]Chẳng sao đâu, cơn đau sẽ qua thật nhanh thôi
    [03:33.88]Nép lên vai và cho anh thêm một cơ hội
    [03:37.10]Tháng năm sau này để anh cầm tay dẫn lối
    [03:41.18]Có ai trót đi ngang để nơi em tiêu điều
    [03:44.41]Để lại lớp gai đâm em khoác lên vai mình khi yêu
    [03:48.43]Cứa lên anh như trăm con dao kia sắc lẹm
    [03:52.02]Những cơn đau để anh được chịu đựng cùng em
    """
    
    public static let hoaXuongRongLunasLRC = """
    [00:15.00]Nhìn vào sâu trong đôi mắt em
    [00:18.50]Có những điều chẳng thể nói ra
    [00:22.00]Từng ngày qua em giấu sau nụ cười
    [00:26.50]Dù cho bão giông vây quanh cuộc đời
    [00:30.50]Em như bông hoa xương rồng trong cát
    [00:34.80]Mạnh mẽ kiêu hãnh giữa trời mây
    [00:39.00]Dù thân đầy gai nhọn và khô rát
    [00:43.50]Vẫn nở rộ đón ánh ban mai
    [00:48.00]Hoa xương rồng vươn mình trong nắng
    [00:52.50]Không cúi đầu trước những cuồng phong
    [00:57.00]Dẫu thế gian đổi thay bao lần
    [01:01.50]Trái tim này vẫn mãi kiên cường
    """
    
    public static let chayNgayDiLRC = """
    [00:15.20]Khóa chặt cửa phòng, buông lơi rèm che
    [00:19.40]Bóng tối bao trùm lấy không gian
    [00:23.50]Một mình ngồi lặng im trong cô đơn
    [00:27.80]Những ký ức xưa cứ ùa về
    [00:32.00]Chạy ngay đi trước khi mọi chuyện dần tồi tệ hơn
    [00:36.50]Chạy ngay đi trước khi lòng này chẳng còn bận tâm
    [00:40.80]Đừng nhìn lại làm chi chỉ thêm đau lòng
    [00:45.00]Hết thật rồi, kết thúc từ đây!
    """
    
    public static let noiNayCoAnhLRC = """
    [00:14.50]Em là ai từ đâu bước đến nơi đây dịu dàng chân phương
    [00:19.80]Em là ai mang nụ cười ấm áp khiến con tim anh xuyến xao
    [00:25.20]Từ lần đầu gặp gỡ anh đã biết mình yêu
    [00:30.50]Một tình yêu đong đầy như đại dương xanh
    [00:35.80]Cầm tay anh đi qua bao giông tố
    [00:41.00]Dẫu ngày mai chông gai khó khăn ngút ngàn
    [00:46.20]Bởi vì nơi này có anh luôn đợi chờ em!
    """
    
    // MARK: - Search in Offline Store
    
    public static let catalog: [LyricSearchResult] = [
        LyricSearchResult(
            id: 888001,
            trackName: "Xương Rồng",
            artistName: "Dangrangto",
            albumName: "Xương Rồng (Single)",
            duration: 236.0,
            syncedLyrics: xuongRongDangrangtoLRC,
            plainLyrics: nil
        ),
        LyricSearchResult(
            id: 888002,
            trackName: "xương rồng (intro)",
            artistName: "Dangrangto",
            albumName: "Xương Rồng",
            duration: 120.0,
            syncedLyrics: xuongRongDangrangtoLRC,
            plainLyrics: nil
        ),
        LyricSearchResult(
            id: 888003,
            trackName: "Hoa Xương Rồng",
            artistName: "LUNAS",
            albumName: "Hoa Xương Rồng",
            duration: 215.0,
            syncedLyrics: hoaXuongRongLunasLRC,
            plainLyrics: nil
        ),
        LyricSearchResult(
            id: 888004,
            trackName: "Chạy Ngay Đi",
            artistName: "Sơn Tùng M-TP",
            albumName: "Chạy Ngay Đi",
            duration: 247.0,
            syncedLyrics: chayNgayDiLRC,
            plainLyrics: nil
        ),
        LyricSearchResult(
            id: 888005,
            trackName: "Nơi Này Có Anh",
            artistName: "Sơn Tùng M-TP",
            albumName: "Nơi Này Có Anh",
            duration: 260.0,
            syncedLyrics: noiNayCoAnhLRC,
            plainLyrics: nil
        ),
        LyricSearchResult(
            id: 888006,
            trackName: "Ghi âm 1 (Bản ghi mẫu)",
            artistName: "Audio Editor Studio",
            albumName: "Demo Recording",
            duration: 21.0,
            syncedLyrics: LyricParser.demoLRC,
            plainLyrics: nil
        )
    ]
    
    /// Normalizes text for search by stripping diacritics, replacing đ/Đ with d, lowercasing, and removing punctuation
    public static func normalizeForSearch(_ str: String) -> String {
        var result = str.replacingOccurrences(of: "đ", with: "d")
                        .replacingOccurrences(of: "Đ", with: "d")
        result = result.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN"))
                       .lowercased()
        // Replace non-alphanumeric characters with spaces
        result = result.replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        // Collapse multiple spaces
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Instant intelligent matching ignoring accents, case, punctuation, and song search prefixes
    public static func search(query: String) -> [LyricSearchResult] {
        let normQuery = normalizeForSearch(query)
        guard !normQuery.isEmpty else { return catalog }
        
        let stopWords = Set(["bai", "hat", "loi", "tim", "kiem", "nhac", "ca", "khuc", "lyrics", "lyric", "song", "cua", "cho", "xin", "ve"])
        let tokens = normQuery.components(separatedBy: " ").filter { $0.count >= 2 && !stopWords.contains($0) }
        
        let matched = catalog.filter { item in
            let titleNorm = normalizeForSearch(item.trackName)
            let artistNorm = normalizeForSearch(item.artistName)
            let fullNorm = "\(titleNorm) \(artistNorm)"
            
            // 1. Direct contains check
            if fullNorm.contains(normQuery) || normQuery.contains(titleNorm) {
                return true
            }
            
            // 2. Special case for "Xương Rồng"
            if (normQuery.contains("xuong") && normQuery.contains("rong")) ||
               (tokens.contains("xuong") && tokens.contains("rong")) {
                if titleNorm.contains("xuong") && titleNorm.contains("rong") {
                    return true
                }
            }
            
            // 3. All non-stopword tokens match
            if !tokens.isEmpty && tokens.allSatisfy({ fullNorm.contains($0) }) {
                return true
            }
            
            // 4. Any substantial token (>= 4 characters) matches title
            if tokens.contains(where: { $0.count >= 4 && titleNorm.contains($0) }) {
                return true
            }
            
            return false
        }
        
        if !matched.isEmpty {
            // Sort: items matching title directly come first
            return matched.sorted { a, b in
                let aTitle = normalizeForSearch(a.trackName)
                let bTitle = normalizeForSearch(b.trackName)
                let aExact = normQuery.contains(aTitle) || aTitle.contains(normQuery)
                let bExact = normQuery.contains(bTitle) || bTitle.contains(normQuery)
                if aExact != bExact { return aExact && !bExact }
                return a.hasSyncedLyrics && !b.hasSyncedLyrics
            }
        }
        
        // Fallback: If no match found, return entire catalog (with Xương Rồng at top) as recommendations
        return catalog
    }
}
