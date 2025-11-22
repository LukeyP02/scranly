import SwiftUI
import UIKit

// Full-bleed square icon: orange background + white serif "scranly"
struct WordmarkIconArtwork: View {
    var background: Color = .scranOrange
    var textColor: Color = .white
    var insetRatio: CGFloat = 0.12   // padding around the wordmark
    var shadowOpacity: Double = 0.18

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let pad = s * insetRatio
            let fontSize = s * 0.28     // tuned for legibility across sizes

            ZStack {
                Rectangle().fill(background) // full square, opaque
                Text("scranly")
                    .font(.system(size: fontSize, weight: .black, design: .serif))
                    .kerning(0.5)
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, pad)
                    .shadow(color: .black.opacity(shadowOpacity), radius: s * 0.035, y: s * 0.02) // subtle "raised"
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct WordmarkIconExporterView: View {
    private let bg = Color.scranOrange
    private let fg = Color.white

    var body: some View {
        VStack(spacing: 12) {
            Text("App Icon Exporter").font(.headline)
            WordmarkIconArtwork(background: bg, textColor: fg)
                .frame(width: 128, height: 128)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))
            Button("Export PNGs to Documents/AppIcons") { exportAll() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func exportAll() {
        let sizes: [(String, CGFloat)] = [
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
            // App Store
            ("AppStore-1024", 1024)
        ]

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        for (name, px) in sizes {
            let view = WordmarkIconArtwork(background: bg, textColor: fg)
                .frame(width: px, height: px)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0 // exact px
            if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
                let url = dir.appendingPathComponent("\(name).png")
                try? data.write(to: url)
                print("✅ wrote", url.path)
            } else {
                print("⚠️ failed", name)
            }
        }
        print("📂 Exported to:", dir.path)
    }
}

#Preview {
    WordmarkIconExporterView()
}
