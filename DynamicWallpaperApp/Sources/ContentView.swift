import SwiftUI
import UniformTypeIdentifiers

// MARK: - Liquid Background
struct LiquidBackground: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let colors: [Color] = [.blue, .purple, .pink, .cyan, .mint]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
                .animation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true), value: start)
                .animation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true), value: end)
                .onAppear {
                    self.start = UnitPoint(x: 4, y: 0)
                    self.end = UnitPoint(x: 0, y: 2)
                }
                .blur(radius: 60)
                .opacity(0.6)
            
            // Add some floating blobs for "liquid" feel
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .blur(radius: 50)
                        .offset(x: -150, y: -100)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.4))
                        .frame(width: 250, height: 250)
                        .blur(radius: 40)
                        .offset(x: 150, y: 100)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Glass Card Style
struct GlassCard<Content: View>: View {
    let content: Content
    // Observe WallpaperManager to react to changes
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(wallpaperManager.cardOpacity)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            
            content
                .padding()
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
    @State private var showingSettings = false
    @State private var showingImporter = false
    @State private var isSidebarExpanded = true
    
    var body: some View {
        ZStack {
            // Main Content with Sidebar
            HStack(spacing: 0) {
                // MARK: - LEFT SIDEBAR
                if isSidebarExpanded {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Liquid Wall")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                                
                                Text("v1.2")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    isSidebarExpanded.toggle()
                                }
                            }) {
                                Image(systemName: "sidebar.left")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        // Main Action Card
                        GlassCard {
                            VStack(spacing: 15) {
                                if let currentURL = wallpaperManager.currentWallpaperURL {
                                    VStack(spacing: 8) {
                                        Image(systemName: "film.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.secondary)
                                        
                                        Text(currentURL.lastPathComponent)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        // Playback Controls
                                        HStack(spacing: 20) {
                                            Button(action: {
                                                withAnimation {
                                                    wallpaperManager.isPlaying.toggle()
                                                }
                                            }) {
                                                Image(systemName: wallpaperManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.blue.opacity(0.8))
                                            }
                                            .buttonStyle(.plain)
                                            
                                            // Volume Control
                                            VStack(spacing: 5) {
                                                Image(systemName: wallpaperManager.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Slider(value: $wallpaperManager.volume, in: 0...1)
                                                    .tint(.blue)
                                                    .frame(width: 80)
                                            }
                                        }
                                        .padding(.top, 5)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(12)
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 36))
                                            .foregroundStyle(.secondary.opacity(0.5))
                                        
                                        Text("No Wallpaper")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                }
                                
                                Button(action: {
                                    showingImporter = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Import")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                                .fileImporter(isPresented: $showingImporter,
                                              allowedContentTypes: [.movie, .video],
                                              allowsMultipleSelection: false) { result in
                                    switch result {
                                    case .success(let urls):
                                        guard let url = urls.first else { return }
                                        // Try to access security scope if possible, ignore result if not applicable
                                        _ = url.startAccessingSecurityScopedResource()
                                        withAnimation {
                                            wallpaperManager.setWallpaper(url: url)
                                        }
                                    case .failure(let error):
                                        print("Import failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(width: 260)
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: {
                            withAnimation(.spring()) {
                                showingSettings = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 300)
                    .background(Color.black.opacity(0.15)) // Sidebar separator
                    .transition(.move(edge: .leading))
                }
                
                // MARK: - RIGHT CONTENT: Library Grid
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        if !isSidebarExpanded {
                            Button(action: {
                                withAnimation {
                                    isSidebarExpanded.toggle()
                                }
                            }) {
                                Image(systemName: "sidebar.left")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 20)
                        }
                        
                        Text("Library")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, isSidebarExpanded ? 20 : 0)
                        
                        Spacer()
                    }
                    .padding(.top, 30)
                    
                    if wallpaperManager.history.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.bottom, 10)
                            Text("No wallpapers imported yet")
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 15)], spacing: 15) {
                                ForEach(wallpaperManager.history) { item in
                                    HistoryItemView(item: item, isSelected: wallpaperManager.currentWallpaperURL?.path == item.url.path)
                                        .onTapGesture {
                                            withAnimation {
                                                wallpaperManager.setWallpaper(url: item.url)
                                            }
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    wallpaperManager.removeFromHistory(id: item.id)
                                                }
                                            } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the space
            }
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .background(
                ZStack {
                    // Background Layer (Color base to prevent transparency issues)
                    Color.black.ignoresSafeArea()
                    
                    // Animated Liquid Background or API Image
                    if let customImage = wallpaperManager.customBackgroundImage {
                        GeometryReader { geo in
                            Image(nsImage: customImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                // Added animation for smooth transition
                                .transition(.opacity)
                                .id(customImage) // Force view update when image changes
                        }
                        .ignoresSafeArea()
                    } else {
                        LiquidBackground()
                            .ignoresSafeArea()
                    }
                    
                    // Visual Effect Blur on top of background
                    // Reduced blur slightly so the image is more visible
                    // Use a slightly more transparent material or control opacity
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                        .allowsHitTesting(false) // Let clicks pass through to background drag handler or UI
                        .opacity(wallpaperManager.backgroundBlurOpacity)
                    
                    // Dark Overlay
                    Color.black.opacity(wallpaperManager.backgroundOverlayOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    
                    // Window Drag Handler
                    WindowDragHandler()
                        .ignoresSafeArea()
                }
                .animation(.easeInOut(duration: 0.5), value: wallpaperManager.customBackgroundImage)
            )
            .clipped() // Prevent any background from overflowing the actual window frame
            
            // Custom Settings Overlay
            if showingSettings {
                ZStack {
                    Color.black.opacity(0.01) // Nearly invisible background to catch clicks
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showingSettings = false
                            }
                        }
                    
                    SettingsView(isPresented: $showingSettings)
                        .frame(width: 320, height: 350)
                        .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(100) // Ensure it's on top of everything
            }
        }
    }
}

// Replaced WindowDragGesture with a reliable NSViewRepresentable approach
struct WindowDragHandler: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class DraggableView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        
        override func draw(_ dirtyRect: NSRect) {
            NSColor.clear.set()
            dirtyRect.fill()
        }
        
        // Let clicks pass through if they are meant for interactive elements like TextFields
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil // Allow interaction with views behind or above
        }
    }
}

struct HistoryItemView: View {
    let item: WallpaperItem
    let isSelected: Bool
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 70)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue.opacity(0.8) : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
                
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if isSelected {
                    ZStack {
                        Color.black.opacity(0.3)
                            .cornerRadius(12)
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 70)
                }
            }
            .onAppear {
                WallpaperManager.shared.getThumbnail(for: item) { image in
                    self.thumbnail = image
                }
            }
            
            Text(item.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .frame(width: 120)
        }
        .contentShape(Rectangle()) // Improve tap area
    }
}

// MARK: - Visual Effect Blur (for Window Background)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        
        // This is crucial: if we use a background image, we need to allow it to show through.
        // For some materials, macOS makes it completely opaque.
        // We'll set an alpha value if needed, or rely on specific materials.
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
