import SwiftUI
import UIKit

/// Exports your BasketIconArtwork (from LogoView.swift) to all required App Icon PNG sizes.
/// Files are written to Documents/AppIcons inside the app sandbox.
struct BasketIconExporterView: View {
    // Tune if needed
    private let inset: CGFloat = 0.18        // padding around the glyph
    private let highlight: Double = 0.12     // top sheen opacity

    var body: some View {
        VStack(spacing: 12) {
            Text("App Icon Exporter").font(.headline)

            // Preview (uses the BasketIconArtwork you defined in LogoView.swift)
            BasketIconArtwork(insetRatio: inset, highlightOpacity: highlight)
                .frame(width: 128, height: 128)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))

            Button("Export PNGs to Documents/AppIcons") {
                exportAll()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func exportAll() {
        // iOS + iPadOS + App Store sizes
        let sizes: [(name: String, px: CGFloat)] = [
            // iPhone
            ("iPhone-Notification-20@2x", 40),  ("iPhone-Notification-20@3x", 60),
            ("iPhone-Settings-29@2x", 58),      ("iPhone-Settings-29@3x", 87),
            ("iPhone-Spotlight-40@2x", 80),     ("iPhone-Spotlight-40@3x", 120),
            ("iPhone-App-60@2x", 120),          ("iPhone-App-60@3x", 180),
            // iPad
            ("iPad-Notifications-20@1x", 20),   ("iPad-Notifications-20@2x", 40),
            ("iPad-Settings-29@1x", 29),        ("iPad-Settings-29@2x", 58),
            ("iPad-Spotlight-40@1x", 40),       ("iPad-Spotlight-40@2x", 80),
            ("iPad-App-76@1x", 76),             ("iPad-App-76@2x", 152),
            ("iPad-Pro-App-83.5@2x", 167),
            // App Store (Marketing)
            ("AppStore-1024", 1024)
        ]

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outDir = docs.appendingPathComponent("AppIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        for (name, px) in sizes {
            let view = BasketIconArtwork(insetRatio: inset, highlightOpacity: highlight)
                .frame(width: px, height: px)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0 // we specify exact pixel size via frame

            if let image = renderer.uiImage, let data = image.pngData() {
                let url = outDir.appendingPathComponent("\(name).png")
                do {
                    try data.write(to: url)
                    print("✅ wrote", url.path)
                } catch {
                    print("❌ write failed:", url.path, error.localizedDescription)
                }
            } else {
                print("⚠️ render failed:", name)
            }
        }

        print("📂 Exported to:", outDir.path)
    }
}

#Preview {
    BasketIconExporterView()
}
