import Cocoa
import SwiftUI

class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem
    
    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles.tv", accessibilityDescription: "Dynamic Wallpaper")
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // Open App
        menu.addItem(NSMenuItem(title: NSLocalizedString("Open Liquid Wall", comment: "Open App"), action: #selector(openApp), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        
        // Play/Pause
        let isPlaying = WallpaperManager.shared.isPlaying
        let playTitle = isPlaying ? NSLocalizedString("Pause", comment: "Pause") : NSLocalizedString("Play", comment: "Play")
        let playItem = NSMenuItem(title: playTitle, action: #selector(togglePlayback), keyEquivalent: "p")
        playItem.target = self
        menu.addItem(playItem)
        
        // Next Wallpaper
        let nextItem = NSMenuItem(title: NSLocalizedString("Next Wallpaper", comment: "Next"), action: #selector(nextWallpaper), keyEquivalent: "n")
        nextItem.target = self
        menu.addItem(nextItem)
        
        // Random Wallpaper
        let randomItem = NSMenuItem(title: NSLocalizedString("Random Wallpaper", comment: "Random"), action: #selector(randomWallpaper), keyEquivalent: "r")
        randomItem.target = self
        menu.addItem(randomItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Wallpapers Submenu
        let wallpapersMenu = NSMenu()
        let wallpapersItem = NSMenuItem(title: NSLocalizedString("Select Wallpaper", comment: "Select"), action: nil, keyEquivalent: "")
        wallpapersItem.submenu = wallpapersMenu
        menu.addItem(wallpapersItem)
        
        if WallpaperManager.shared.history.isEmpty {
            wallpapersMenu.addItem(NSMenuItem(title: NSLocalizedString("No Wallpaper", comment: ""), action: nil, keyEquivalent: ""))
        } else {
            for item in WallpaperManager.shared.history {
                let menuItem = NSMenuItem(title: item.name, action: #selector(selectWallpaper(_:)), keyEquivalent: "")
                menuItem.target = self
                // Store UUID as string or URL path since representedObject can be anything
                // But URL is better
                menuItem.representedObject = item.url
                
                if item.url.path == WallpaperManager.shared.currentWallpaperURL?.path {
                    menuItem.state = .on
                }
                wallpapersMenu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: "Quit"), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func togglePlayback() {
        WallpaperManager.shared.isPlaying.toggle()
    }
    
    @objc func nextWallpaper() {
        WallpaperManager.shared.playNextWallpaper()
    }
    
    @objc func randomWallpaper() {
        WallpaperManager.shared.playRandomWallpaper()
    }
    
    @objc func selectWallpaper(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? URL {
            WallpaperManager.shared.setWallpaper(url: url)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
