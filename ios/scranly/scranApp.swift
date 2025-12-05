

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
    @AppStorage("hasPlanThisWeek") private var hasPlanThisWeek = true

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
            // Chef (home)
            ChefView()
                .tabItem { Label("Chef", systemImage: "wand.and.stars") }
                .tag(0)

            // Plan
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(1)

            // Shop
            ShopView()
                .tabItem { Label("Shop", systemImage: "basket.fill") }
                .badge(shopBadgeCount > 0 ? shopBadgeCount : 0)
                .tag(2)

            // You
            YouView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(3)
        }
        .onAppear {
            // default Chef if they’ve got a plan, else Plan
            selected = hasPlanThisWeek ? 0 : 1
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
    var trailing: AnyView? = nil
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
                if let trailing = trailing {
                    trailing
                } else {
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.primary)
                            .padding(.trailing, 16)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - HOME HELPERS YOU ALREADY HAVE

// MARK: - Greeting (Hello Alex! / What’s cooking!)
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

// MARK: - Next Meal Hero (compact with image)
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

// MARK: - KPI Grid
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

// MARK: - Basket Summary Chip (single compact card)
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

// MARK: - Detailed Stats Highlights

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
            // Header
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

            // Stacked chips
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

// MARK: - Simple models used here
struct KPI: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    let tint: Color
}

// MARK: - YOU VIEW

struct YouView: View {
    @State private var name: String = "Alex"
    @State private var isVeggie: Bool = false
    @State private var isGlutenFree: Bool = false
    @State private var budgetPerWeek: Double = 45
    @State private var timePerMeal: Double = 30
    @State private var notificationsOn: Bool = true
    @State private var smartSuggestionsOn: Bool = true
    @State private var showSettingsSheet = false

    private var kpis: [KPI] {
        [
            KPI(icon: "flame.fill",   value: "6k",   label: "Calories cooked", tint: .orange),
            KPI(icon: "leaf.fill",    value: "12",   label: "Veg-forward meals", tint: .green),
            KPI(icon: "clock.fill",   value: "2.5h", label: "Time saved", tint: .blue),
            KPI(icon: "cart.badge.plus", value: "3", label: "Shops automated", tint: .purple)
        ]
    }

    private var highlights: [StatsHighlight] {
        [
            StatsHighlight(
                icon: "chart.line.uptrend.xyaxis",
                title: "Consistency streak",
                detail: "You’ve cooked at home 4 nights in a row. Scranly loves the run you’re on.",
                badge: "On a roll",
                badgeTint: .green
            ),
            StatsHighlight(
                icon: "fork.knife",
                title: "Go-to cuisines",
                detail: "Italian, Japanese and Mexican are showing up the most in your recent dinners.",
                badge: "Taste map",
                badgeTint: .orange
            ),
            StatsHighlight(
                icon: "bolt.heart",
                title: "Your sweet spot",
                detail: "You tend to cook 25–35 minute dinners around 600–700 kcal.",
                badge: "Dialed in",
                badgeTint: .blue
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ScranlyLogoBar(
                        trailing: AnyView(
                            Button {
                                showSettingsSheet = true
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .imageScale(.medium)
                                    .foregroundStyle(.primary)
                                    .padding(.trailing, 16)
                            }
                        )
                    )

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {

                            // Profile / intro
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.scranOrange.opacity(0.12))
                                            .frame(width: 48, height: 48)
                                        Text(String(name.prefix(1)))
                                            .font(.system(size: 24, weight: .black, design: .rounded))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("You")
                                            .font(.caption.weight(.heavy))
                                            .foregroundStyle(.secondary)
                                        Text(name)
                                            .font(.system(size: 22, weight: .black, design: .rounded))
                                        Text("Tuning Scranly to your life")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .padding(.horizontal)

                            // KPIs
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your cooking stats")
                                    .font(.headline)
                                KPIGrid(kpis: kpis)
                            }
                            .padding(.horizontal)

                            // Highlights
                            StatsHighlightsSection(
                                title: "What Scranly’s noticed",
                                subtitle: "We’ll keep adjusting plans and shops to match your patterns.",
                                highlights: highlights
                            )
                            .padding(.horizontal)

                            // Preferences card
                            YouPreferencesCard(
                                name: $name,
                                isVeggie: $isVeggie,
                                isGlutenFree: $isGlutenFree,
                                budgetPerWeek: $budgetPerWeek,
                                timePerMeal: $timePerMeal
                            )
                            .padding(.horizontal)

                            // Settings card
                            YouSettingsCard(
                                notificationsOn: $notificationsOn,
                                smartSuggestionsOn: $smartSuggestionsOn
                            )
                            .padding(.horizontal)

                            Spacer(minLength: 24)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    Form {
                        Section("Notifications") {
                            Toggle("Cooking reminders", isOn: $notificationsOn)
                            Toggle("Smart suggestions", isOn: $smartSuggestionsOn)
                        }

                        Section("Preferences") {
                            Toggle("Prefer veggie dishes", isOn: $isVeggie)
                            Toggle("Gluten-free friendly", isOn: $isGlutenFree)
                        }

                        Section("Planning") {
                            Stepper("Budget ~£\(Int(budgetPerWeek))/week", value: $budgetPerWeek, in: 10...200, step: 5)
                            Stepper("Time per meal ~\(Int(timePerMeal)) mins", value: $timePerMeal, in: 10...90, step: 5)
                        }
                    }
                    .navigationTitle("You settings")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showSettingsSheet = false }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - You preferences card

fileprivate struct YouPreferencesCard: View {
    @Binding var name: String
    @Binding var isVeggie: Bool
    @Binding var isGlutenFree: Bool
    @Binding var budgetPerWeek: Double
    @Binding var timePerMeal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.scranOrange)
                Text("Your preferences")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Toggle("Prefer veggie dishes", isOn: $isVeggie)
                Toggle("Gluten-free friendly", isOn: $isGlutenFree)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Weekly food budget")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("~£\(Int(budgetPerWeek))")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $budgetPerWeek, in: 10...200, step: 5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Time per dinner")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("~\(Int(timePerMeal)) mins")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $timePerMeal, in: 10...90, step: 5)
                }

                Text("Scranly will use this to tune recipes, plans and your shopping lists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - You settings card

fileprivate struct YouSettingsCard: View {
    @Binding var notificationsOn: Bool
    @Binding var smartSuggestionsOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.scranOrange)
                Text("App settings")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Cooking reminders", isOn: $notificationsOn)
                Toggle("Smart suggestions", isOn: $smartSuggestionsOn)

                Text("Fine-tune how proactive Scranly should be. You’re always in control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview
#Preview {
    RootTabView()
}
