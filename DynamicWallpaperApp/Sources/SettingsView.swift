import SwiftUI

struct SettingsView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
            
            // Appearance Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Card Opacity")
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Text("\(Int(wallpaperManager.cardOpacity * 100))%")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Slider(value: $wallpaperManager.cardOpacity, in: 0.1...1.0)
                            .tint(.blue)
                    }
                    .padding()
                }
            }
            
            // Background Section
            VStack(alignment: .leading, spacing: 10) {
                Text("App Background")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Background Image API URL")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("https://picsum.photos/1920/1080", text: $wallpaperManager.backgroundApiUrl)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            wallpaperManager.fetchCustomBackground()
                        }) {
                            Text("Refresh Background")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding(20)
        // No fixed frame here, let popover determine size or use parent constraint
    }
}
