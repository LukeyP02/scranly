import SwiftUI

// MARK: - Rounded trapezoid body path (reusable)
struct BasketBodyPath: Shape {
    var topWidth: CGFloat
    var bottomWidth: CGFloat
    var topY: CGFloat
    var bottomY: CGFloat
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let tl = CGPoint(x: cx - topWidth/2,    y: topY)
        let tr = CGPoint(x: cx + topWidth/2,    y: topY)
        let bl = CGPoint(x: cx - bottomWidth/2, y: bottomY)
        let br = CGPoint(x: cx + bottomWidth/2, y: bottomY)

        var p = Path()
        p.move(to: CGPoint(x: tl.x + cornerRadius, y: tl.y))
        p.addLine(to: CGPoint(x: tr.x - cornerRadius, y: tr.y))
        p.addQuadCurve(to: CGPoint(x: tr.x, y: tr.y + cornerRadius), control: CGPoint(x: tr.x, y: tr.y))
        p.addLine(to: CGPoint(x: br.x, y: br.y - cornerRadius))
        p.addQuadCurve(to: CGPoint(x: br.x - cornerRadius, y: br.y), control: CGPoint(x: br.x, y: br.y))
        p.addLine(to: CGPoint(x: bl.x + cornerRadius, y: bl.y))
        p.addQuadCurve(to: CGPoint(x: bl.x, y: bl.y - cornerRadius), control: CGPoint(x: bl.x, y: bl.y))
        p.addLine(to: CGPoint(x: tl.x, y: tl.y + cornerRadius))
        p.addQuadCurve(to: CGPoint(x: tl.x + cornerRadius, y: tl.y), control: CGPoint(x: tl.x, y: tl.y))
        p.closeSubpath()
        return p
    }
}

// MARK: - Premium Basket Glyph (white, raised)
// Size-aware: simplifies details below a cutoff so it reads cleanly in headers/small icons.
struct BasketGlyphPremium: View {
    var fillColor: Color = .white
    /// Below this size, we hide slots and extra shading to keep it crisp.
    var detailCutoff: CGFloat = 64

    var body: some View {
        GeometryReader { g in
            let s  = min(g.size.width, g.size.height)
            let cx = s * 0.5
            let isSmall = s < detailCutoff

            // Proportions tuned to feel balanced inside a circle/square
            let rimW: CGFloat = s * 0.80
            let rimH: CGFloat = s * 0.165
            let rimY: CGFloat = s * 0.40
            let rimR: CGFloat = s * 0.10

            let bodyTopW: CGFloat = s * 0.70
            let bodyBotW: CGFloat = s * 0.61
            let bodyTopY: CGFloat = s * 0.505
            let bodyBotY: CGFloat = s * 0.86
            let bodyCR:  CGFloat = s * 0.135

            let handleSpan: CGFloat = s * 0.36    // distance between handle ends
            let handleY: CGFloat   = s * 0.305
            let archHeight: CGFloat = s * 0.14    // how high the handle arches

            ZStack {
                // Rim
                RoundedRectangle(cornerRadius: rimR, style: .continuous)
                    .fill(fillColor)
                    .frame(width: rimW, height: rimH)
                    .position(x: cx, y: rimY)

                // Body
                BasketBodyPath(topWidth: bodyTopW, bottomWidth: bodyBotW,
                               topY: bodyTopY, bottomY: bodyBotY,
                               cornerRadius: bodyCR)
                    .fill(fillColor)

                // Subtle lip shadow under the rim (hidden when tiny)
                if !isSmall {
                    RoundedRectangle(cornerRadius: rimR * 0.9, style: .continuous)
                        .fill(Color.black.opacity(0.08))
                        .frame(width: rimW * 0.92, height: rimH * 0.42)
                        .position(x: cx, y: rimY + rimH * 0.82)
                        .blur(radius: s * 0.015)
                        .mask(
                            BasketBodyPath(topWidth: bodyTopW, bottomWidth: bodyBotW,
                                           topY: bodyTopY, bottomY: bodyBotY,
                                           cornerRadius: bodyCR)
                                .fill(Color.white)
                        )
                }

                // Handle (arched stroke)
                Path { p in
                    let start = CGPoint(x: cx - handleSpan/2, y: handleY)
                    let end   = CGPoint(x: cx + handleSpan/2, y: handleY)
                    let c1    = CGPoint(x: cx - handleSpan*0.28, y: handleY - archHeight)
                    let c2    = CGPoint(x: cx + handleSpan*0.28, y: handleY - archHeight)

                    p.move(to: start)
                    p.addCurve(to: end, control1: c1, control2: c2)
                }
                .stroke(fillColor, style: StrokeStyle(lineWidth: max(2, s * 0.06), lineCap: .round, lineJoin: .round))

                // Slots (punched out) – hide when tiny to avoid noise
                if !isSmall {
                    HStack(spacing: s * 0.085) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: s * 0.045, style: .continuous)
                                .frame(width: s * 0.095, height: s * 0.26)
                        }
                    }
                    .frame(width: bodyBotW * 0.78)
                    .position(x: cx, y: s * 0.685)
                    .blendMode(.destinationOut)
                }
            }
            .compositingGroup() // required for destinationOut
            // Raised shadow (lighter when tiny)
            .shadow(color: Color.black.opacity(isSmall ? 0.16 : 0.22),
                    radius: s * (isSmall ? 0.06 : 0.08),
                    y: s * (isSmall ? 0.04 : 0.05))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Scranly basket symbol")
    }
}

// MARK: - Icon artwork (square, no rounded corners; gradient bg + sheen)
struct BasketIconArtwork: View {
    private static let top = Color(red: 1.00, green: 0.62, blue: 0.18)
    private static let mid = Color.scranOrange
    private static let bot = Color(red: 0.85, green: 0.28, blue: 0.00)

    /// padding around the glyph as a % of the icon side
    var insetRatio: CGFloat = 0.19
    /// subtle top sheen like a premium enamel
    var highlightOpacity: Double = 0.10

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let pad = s * insetRatio

            ZStack {
                // Rich orange gradient
                Rectangle()
                    .fill(LinearGradient(colors: [Self.top, Self.mid, Self.bot],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    // Top sheen
                    .overlay(
                        LinearGradient(colors: [Color.white.opacity(highlightOpacity), .clear],
                                       startPoint: .top, endPoint: .center)
                    )
                    // Soft vignette for depth
                    .overlay(
                        RadialGradient(colors: [.clear, Color.black.opacity(0.10)],
                                       center: .center, startRadius: s * 0.6, endRadius: s * 1.0)
                    )

                // White raised basket glyph (auto-simplifies when tiny)
                BasketGlyphPremium(fillColor: .white, detailCutoff: 64)
                    .padding(pad)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Scranly App Icon")
    }
}

// MARK: - Quick previews
#Preview("Glyph (header size)") {
    ZStack {
        LinearGradient(colors: [.orange, Color.scranOrange], startPoint: .top, endPoint: .bottom)
        BasketGlyphPremium(fillColor: .white, detailCutoff: 64)
            .frame(width: 22, height: 22)
            .padding(20)
    }
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .frame(width: 120, height: 80)
    .background(Color(.systemBackground))
}

#Preview("Icon 220") {
    BasketIconArtwork()
        .frame(width: 220, height: 220)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.secondary))
        .padding()
        .background(Color(.systemBackground))
}
