import Cocoa
import AVKit

struct WallpaperItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let url: URL
    let name: String
    var bookmarkData: Data?
    
    // Custom coding keys to handle URL bookmark resolution if needed,
    // but storing bookmarkData is safer for sandbox.
}

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    @Published var currentWallpaperURL: URL?
    @Published var history: [WallpaperItem] = []
    
    // Playback Controls
    @Published var volume: Float = 0.0 {
        didSet { updateVolume() }
    }
    @Published var isPlaying: Bool = true {
        didSet { updatePlaybackState() }
    }
    
    // Settings
    @Published var backgroundApiUrl: String = "" {
        didSet {
            UserDefaults.standard.set(backgroundApiUrl, forKey: "backgroundApiUrl")
        }
    }
    @Published var cardOpacity: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(cardOpacity, forKey: "cardOpacity")
        }
    }
    @Published var customBackgroundImage: NSImage? = nil
    
    // Thumbnail Cache
    var thumbnailCache: [UUID: NSImage] = [:]
    
    private var windows: [WallpaperWindow] = []
    
    private init() {
        // Listen for screen changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenParametersDidChange),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil)
        loadHistory()
        loadSavedWallpaper()
        
        // Load settings
        self.volume = UserDefaults.standard.float(forKey: "wallpaperVolume")
        self.backgroundApiUrl = UserDefaults.standard.string(forKey: "backgroundApiUrl") ?? "https://picsum.photos/1920/1080"
        self.cardOpacity = UserDefaults.standard.object(forKey: "cardOpacity") as? Double ?? 0.5
        
        // Fetch background if API URL is set
        if !backgroundApiUrl.isEmpty {
            fetchCustomBackground()
        }
    }
    
    func fetchCustomBackground() {
        guard let url = URL(string: backgroundApiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Failed to fetch background: \(error)")
                return
            }
            guard let data = data, let image = NSImage(data: data) else { 
                print("Invalid image data received")
                return 
            }
            DispatchQueue.main.async {
                self?.customBackgroundImage = image
            }
        }.resume()
    }
    
    func getThumbnail(for item: WallpaperItem, completion: @escaping (NSImage?) -> Void) {
        if let cached = thumbnailCache[item.id] {
            completion(cached)
            return
        }
        
        let asset = AVAsset(url: item.url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        // Generate at 1s mark
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        // Use background queue
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 240, height: 135))
                DispatchQueue.main.async {
                    self.thumbnailCache[item.id] = nsImage
                    completion(nsImage)
                }
            } catch {
                print("Thumbnail generation failed for \(item.name): \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func updateVolume() {
        for window in windows {
            window.player?.volume = volume
        }
        UserDefaults.standard.set(volume, forKey: "wallpaperVolume")
    }
    
    func updatePlaybackState() {
        for window in windows {
            if isPlaying {
                window.player?.play()
            } else {
                window.player?.pause()
            }
        }
    }
    
    func start() {
        setupWindows()
    }
    
    private func setupWindows() {
        // Clear existing windows properly
        windows.forEach { window in
            window.close()
            // Ensure no lingering references
        }
        windows.removeAll()
        
        // Create a window for each screen
        for screen in NSScreen.screens {
            let window = WallpaperWindow(screen: screen, videoURL: currentWallpaperURL)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }
    
    @objc private func screenParametersDidChange() {
        setupWindows()
    }
    
    func setWallpaper(url: URL) {
        self.currentWallpaperURL = url
        saveWallpaperBookmark(url)
        addToHistory(url: url)
        
        for window in windows {
            window.updateVideo(url: url)
        }
    }
    
    func addToHistory(url: URL) {
        // Avoid duplicates
        if !history.contains(where: { $0.url.path == url.path }) {
            let bookmark = try? createBookmark(for: url)
            let item = WallpaperItem(url: url, name: url.lastPathComponent, bookmarkData: bookmark)
            history.insert(item, at: 0)
            saveHistory()
        }
        // If it exists, we don't move it to top anymore to maintain "Library" order for "Next" playback
    }
    
    func playNextWallpaper() {
        guard !history.isEmpty else { return }
        
        // If no current wallpaper, play first
        guard let current = currentWallpaperURL,
              let index = history.firstIndex(where: { $0.url.path == current.path }) else {
            setWallpaper(url: history[0].url)
            return
        }
        
        let nextIndex = (index + 1) % history.count
        setWallpaper(url: history[nextIndex].url)
    }
    
    func playRandomWallpaper() {
        guard !history.isEmpty else { return }
        // Pick a random one different from current if possible
        let available = history.filter { $0.url.path != currentWallpaperURL?.path }
        if let randomItem = available.randomElement() ?? history.first {
            setWallpaper(url: randomItem.url)
        }
    }
    
    func removeFromHistory(id: UUID) {
        history.removeAll(where: { $0.id == id })
        saveHistory()
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "wallpaperHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "wallpaperHistory"),
           let savedHistory = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
            self.history = savedHistory
            
            // Resolve bookmarks for history items to ensure access
            for i in 0..<self.history.count {
                if let bookmarkData = self.history[i].bookmarkData {
                    if let resolvedURL = resolveBookmark(data: bookmarkData) {
                        // Access the resource
                        _ = resolvedURL.startAccessingSecurityScopedResource()
                    }
                }
            }
        }
    }
    
    private func createBookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(options: .withSecurityScope,
                                        includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
        } catch {
            // Fallback for non-sandbox
            return try url.bookmarkData(options: [],
                                        includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
        }
    }
    
    private func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            return url
        } catch {
            // Fallback
            return try? URL(resolvingBookmarkData: data,
                            options: [],
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)
        }
    }
    
    private func saveWallpaperBookmark(_ url: URL) {
        if let bookmarkData = try? createBookmark(for: url) {
            UserDefaults.standard.set(bookmarkData, forKey: "savedWallpaperBookmark")
        } else {
            UserDefaults.standard.set(url.path, forKey: "savedWallpaperPath")
        }
    }
    
    private func loadSavedWallpaper() {
        if let bookmarkData = UserDefaults.standard.data(forKey: "savedWallpaperBookmark") {
            if let url = resolveBookmark(data: bookmarkData) {
                _ = url.startAccessingSecurityScopedResource()
                self.currentWallpaperURL = url
                return
            }
        }
        
        // Fallback to path if bookmark failed
        if let path = UserDefaults.standard.string(forKey: "savedWallpaperPath") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                self.currentWallpaperURL = url
            }
        }
    }
}
