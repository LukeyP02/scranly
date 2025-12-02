import SwiftUI

// MARK: - App Entry
@main
struct ScranlyApp: App {
    var body: some Scene {
        WindowGroup { RootTabView() }
    }
}

struct RootTabView: View {
    @State private var selected = 0
    @State private var shopBadgeCount = 12

    init() {
        // Style the stock tab bar a bit
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()
        ap.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        ap.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        ap.stackedLayoutAppearance.selected.iconColor = UIColor(Color.scranOrange)
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.scranOrange)
        ]
        UITabBar.appearance().standardAppearance = ap
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = ap
        }
        UITabBar.appearance().tintColor = UIColor(Color.scranOrange)
    }

    var body: some View {
        TabView(selection: $selected) {
            // Chef / chat view
            ChefView()
                .tabItem { Label("Chef", systemImage: "sparkles") }
                .tag(0)

            // Weekly plan
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(1)

            // Shopping list
            ShopView()
                .tabItem { Label("Shop", systemImage: "basket.fill") }
                .badge(shopBadgeCount > 0 ? shopBadgeCount : 0)
                .tag(2)
        }
    }
}

// MARK: - Brand palette
extension Color {
    static let scranOrange = Color(red: 0.95, green: 0.40, blue: 0.00)  // deeper, warmer orange
    static let scranCream  = Color(red: 1.00, green: 0.97, blue: 0.93)  // faint cream for app background
}

// Bridge so you can use `.foregroundStyle(.scranOrange)` / `.background(.scranCream)`
extension ShapeStyle where Self == Color {
    static var scranOrange: Color { Color.scranOrange }
    static var scranCream:  Color { Color.scranCream  }
}

// MARK: - Premium brand header pill (gradient + glyph + wordmark)
private struct BrandHeaderPill: View {
    // Orange gradient tuned to feel rich (light → brand → deep)
    private let top = Color(red: 1.00, green: 0.62, blue: 0.18)
    private let mid = Color.scranOrange
    private let bot = Color(red: 0.85, green: 0.28, blue: 0.00)

    var body: some View {
        HStack(spacing: 8) {
            // Use your premium basket glyph from LogoView.swift
            BasketGlyphPremium()
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.10), radius: 2, y: 1) // tiny lift on the glyph

            Text("scranly")
                .font(.system(size: 21, weight: .black, design: .serif))
                .kerning(0.4)
                .baselineOffset(0.5)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [top, mid, bot],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // Subtle top sheen for premium feel
                .overlay(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
                // Crisp edge
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                // Soft drop shadow (raised look)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        )
        .accessibilityLabel("Scranly")
    }
}

// MARK: - Top Logo / Settings Bar
struct ScranlyLogoBar: View {
    var onSettings: () -> Void = {}

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.scranCream)
                .frame(height: 64)
                .overlay(Divider().opacity(0.8), alignment: .bottom)

            // Centered premium brand pill
            BrandHeaderPill()

            HStack {
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.medium)
                        .foregroundStyle(.primary)
                        .padding(.trailing, 16)
                }
                .accessibilityLabel("Settings")
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Home helpers still used in Chef/Home style views

struct GreetingHello: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hello, \(userName)!")
                .font(.title2).bold()
            Text("What’s cooking!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NextMealHero: View {
    struct Model {
        let title: String
        let meta:  String
        let emoji: String // replace with image/URL when ready
    }

    let model: Model
    var onCook: () -> Void
    var onSwap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next meal")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.orange.opacity(0.16))
                    .frame(height: 160)
                    .overlay(Text(model.emoji).font(.system(size: 60)))
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                    Text(model.meta)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    HStack(spacing: 8) {
                        Button("Cook now", action: onCook)
                            .buttonStyle(.borderedProminent)
                            .tint(.scranOrange)
                        Button("Swap", action: onSwap)
                            .buttonStyle(.bordered)
                            .tint(.white)
                    }
                    .padding(.top, 4)
                }
                .padding(12)
            }
        }
    }
}

// MARK: - KPI Grid / Highlights reused where needed

struct KPIGrid: View {
    let kpis: [KPI]
    private let cols = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 14) {
            ForEach(kpis) { StatTile(kpi: $0) }
        }
    }
}

fileprivate struct StatTile: View {
    let kpi: KPI

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: kpi.icon)
                    .foregroundStyle(kpi.tint)
                Text(kpi.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(kpi.value)
                .font(.title3)
                .bold()
                .foregroundStyle(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct BasketSummaryChip: View {
    var title: String
    var itemsCount: Int
    var totalGBP: Double
    var onTap: () -> Void

    private var formattedTotal: String {
        "£" + String(format: "%.2f", totalGBP)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundStyle(Color.scranOrange)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        Text("(\(itemsCount) items)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Tap to view or edit basket")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formattedTotal)
                    .font(.headline)
                    .bold()
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct StatsHighlight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let badge: String?
    let badgeTint: Color
}

struct StatsHighlightsSection: View {
    let title: String
    let subtitle: String?
    let highlights: [StatsHighlight]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.scranOrange)
                        Text(title)
                            .font(.headline)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(highlights) { h in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            ZstackIcon(h.icon)

                            Text(h.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            if let badgeText = h.badge, !badgeText.isEmpty {
                                Text(badgeText)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(h.badgeTint.opacity(0.12))
                                    .foregroundStyle(h.badgeTint)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(h.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                }
            }
        }
    }

    @ViewBuilder
    private func ZstackIcon(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.12))
                .frame(width: 28, height: 28)
            Image(systemName: systemName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.scranOrange)
        }
    }
}

struct KPI: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    let tint: Color
}

// MARK: - Preview
#Preview {
    RootTabView()
}
