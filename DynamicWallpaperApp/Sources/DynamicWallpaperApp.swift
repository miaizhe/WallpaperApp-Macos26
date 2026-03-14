import SwiftUI

@main
struct DynamicWallpaperApp: App {
    @StateObject private var manager = WallpaperManager.shared
    @State private var statusBarController: StatusBarController?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                .onAppear {
                    // Start the wallpaper window management when the app launches
                    manager.start()
                    // Initialize status bar controller
                    if statusBarController == nil {
                        statusBarController = StatusBarController()
                    }
                    // Force app to become active and frontmost
                    NSApp.activate(ignoringOtherApps: true)
                }
                .background(WindowAccessor { window in
                    if let window = window {
                        window.titlebarAppearsTransparent = true
                        window.title = ""
                        window.styleMask.insert([.fullSizeContentView, .resizable])
                        // Disable this to prevent conflict with ScrollView drag
                        window.isMovableByWindowBackground = false 
                        window.backgroundColor = .clear
                        window.isOpaque = false
                        window.hasShadow = true
                        
                        // Set content size and aspect ratio
                        let initialSize = NSSize(width: 700, height: 450)
                        window.setContentSize(initialSize)
                        window.minSize = NSSize(width: 600, height: 400)
                        
                        // Center window on screen if it's the first launch
                        window.center()
                    }
                })
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Optional: Add menu commands here
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
