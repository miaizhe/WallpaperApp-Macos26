import Cocoa
import AVKit
import AVFoundation

class WallpaperWindow: NSWindow {
    var playerLayer: AVPlayerLayer?
    var playerLooper: AVPlayerLooper?
    var player: AVQueuePlayer?

    init(screen: NSScreen, videoURL: URL?) {
        let screenRect = screen.frame
        
        super.init(contentRect: screenRect,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.backgroundColor = .black
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        
        // Ensure the window spans the entire screen, including under the menu bar
        self.setFrame(screenRect, display: true)
        
        if let url = videoURL {
            setupPlayer(url: url)
        }
    }
    
    deinit {
        // Clean up resources when window is deallocated
        NotificationCenter.default.removeObserver(self)
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
    }
    
    func setupPlayer(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Create a QueuePlayer and a PlayerLooper for seamless looping
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.volume = WallpaperManager.shared.volume
        self.player = queuePlayer
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        let layer = AVPlayerLayer(player: self.player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = self.contentView!.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        self.contentView?.wantsLayer = true
        self.contentView?.layer = CALayer()
        self.contentView?.layer?.addSublayer(layer)
        self.playerLayer = layer
        
        if WallpaperManager.shared.isPlaying {
            self.player?.play()
        }
    }
    
    func updateVideo(url: URL) {
        // Keep reference to old player and layer
        let oldPlayer = self.player
        let oldLayer = self.playerLayer
        let oldLooper = self.playerLooper
        
        // Setup new player
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.volume = WallpaperManager.shared.volume
        
        // New Looper
        let newLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // New Layer
        let newLayer = AVPlayerLayer(player: queuePlayer)
        newLayer.videoGravity = .resizeAspectFill
        newLayer.frame = self.contentView!.bounds
        newLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        // Add new layer on top of old one
        self.contentView?.layer?.addSublayer(newLayer)
        
        // Update references
        self.player = queuePlayer
        self.playerLooper = newLooper
        self.playerLayer = newLayer
        
        if WallpaperManager.shared.isPlaying {
            self.player?.play()
        }
        
        // Remove old layer after a delay to allow new video to load and start rendering
        // This prevents the black flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak oldPlayer, weak oldLayer] in
            // Keep oldLooper alive until now
            _ = oldLooper
            oldPlayer?.pause()
            oldLayer?.removeFromSuperlayer()
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
