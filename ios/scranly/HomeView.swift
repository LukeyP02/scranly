import SwiftUI

// Local brand so we don’t depend on global extensions
fileprivate let hvBrand = Color(red: 0.95, green: 0.40, blue: 0.00)
fileprivate let hvCream = Color(red: 1.00, green: 0.97, blue: 0.93)

// MARK: - Black/Orange label + mini button (matches your style)
fileprivate struct HVIconBlackTextLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(hvBrand)
            configuration.title.foregroundStyle(.black)
        }
    }
}
fileprivate struct HVMiniBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(HVIconBlackTextLabelStyle())
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Header (logo + greeting)
fileprivate struct HVHeader: View {
    @AppStorage("userName") private var userName: String = "Alex"
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hello"
        }
    }
    var body: some View {
        VStack(spacing: 6) {
            Text("scranly")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .kerning(0.5)
                .foregroundStyle(hvBrand)
            Text("\(greeting), \(userName) 👋")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2).padding(.bottom, 2)
        .background(
            Color(.systemBackground)
                .overlay(Divider(), alignment: .bottom)
        )
    }
}

fileprivate struct HVWideAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)                // ✅ full width
            .padding(.vertical, 14)                    // ✅ taller
            .background(Color(.systemBackground))
            // Outer black border
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.black, lineWidth: 12.5)
            )
            // Inner orange border (slightly inset)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(hvBrand, lineWidth: 8.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// === Week summary components (drop into HomeView.swift) ===

fileprivate struct SummaryChip: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.scranOrange)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

fileprivate struct WeekSummaryStrip: View {
    // hard-coded for now; swap with real values later
    var mealsPlanned: String = "14"
    var itemsToShop: String  = "23"
    var avgKcalPerDay: String = "2,180"

    var body: some View {
        HStack(spacing: 12) {
            SummaryChip(title: "Meals planned", value: mealsPlanned)
            SummaryChip(title: "Items to shop", value: itemsToShop)
            SummaryChip(title: "Avg kcal/day", value: avgKcalPerDay)
        }
        .padding(.horizontal)
    }
}

// (alternative single-card version)
fileprivate struct WeekOverviewCard: View {
    // hard-coded for now; swap with real values later
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your week at a glance")
                .font(.headline)
                .padding(.bottom, 4)

            Text("14 meals planned • 23 items to shop • avg 2,180 kcal/day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}





// MARK: - Hero: Your Scran Wins (carousel + progress ring)
struct ScranWinsHero: View {
    struct Win: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let value: String
        let delta: String
        let ringProgress: Double  // 0...1 (you can wire this to real goals later)
        let icon: String          // SF Symbol (e.g., "clock.badge.checkmark")
    }

    let wins: [Win]

    @State private var index = 0
    @State private var isDragging = false

    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 8) {
                YourScranlyWinsTitle()
                Spacer()
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 4)

            VStack {
                TabView(selection: $index) {
                    ForEach(Array(wins.enumerated()), id: \.element.id) { (i, win) in
                        WinCard(win: win)
                            .tag(i)
                            .padding(.vertical, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 170)
                .onReceive(timer) { _ in
                    guard !isDragging, wins.count > 1 else { return }
                    withAnimation(.easeInOut) {
                        index = (index + 1) % wins.count
                    }
                }
                .gesture(DragGesture()
                    .onChanged { _ in isDragging = true }
                    .onEnded   { _ in isDragging = false })
            }
            .padding(.top, 28) // make room for the header row
        }
    }
}




private struct WinCard: View {
    let win: ScranWinsHero.Win

    private func bgName(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("money") { return "money" }
        if t.contains("time")  { return "time" }
        if t.contains("meal")  { return "meals" }
        return "meals"
    }

    var body: some View {
        ZStack {
            // Background image from Assets (money.png / time.png / meals.png)
            Image(bgName(for: win.title))
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.0), .black.opacity(0.45)],
                        startPoint: .center, endPoint: .bottom
                    )
                )

            HStack(alignment: .center, spacing: 12) {
                // Ring
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground)) // solid white/light in Light Mode, solid dark in Dark Mode
                        .overlay(Circle().stroke(.black, lineWidth: 2))
                        .frame(width: 56, height: 56)

                    Image(systemName: win.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.scranOrange)
                }
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(win.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(win.value)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                        if !win.delta.isEmpty {
                            Text(win.delta)
                                .font(.caption2.weight(.semibold))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(.white.opacity(0.12), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }

                Spacer()
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

fileprivate struct ProgressRing: View {
    let progress: Double // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(Color(.systemGray5), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0.03, min(1, progress)))
                .stroke(hvBrand, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: progress)
        }
        .overlay(
            Image(systemName: "sparkles")
                .font(.caption2.weight(.bold))
                .foregroundStyle(hvBrand)
        )
    }
}

// MARK: - Middle: Up Next (large photo card)
fileprivate struct UpNextCard: View {
    struct Model {
        let title: String
        let meta:  String
        let imageName: String?
        let imageURL: URL?
        let emoji: String
    }

    let model: Model
    var onCook: () -> Void = {}
    var onSwap: () -> Void = {}
    var onSuggest: () -> Void = {} // ✅ new optional callback

    // fallback emoji if no image
    @ViewBuilder private var fallbackEmoji: some View {
        ZStack {
            Color.orange.opacity(0.12)
            Text(model.emoji)
                .font(.system(size: 64))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Up Next Card (smaller)
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let url = model.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            case .failure(_):
                                fallbackEmoji
                            case .empty:
                                ZStack {
                                    Color(.systemGray6)
                                    ProgressView()
                                }
                            @unknown default:
                                fallbackEmoji
                            }
                        }
                    } else if let name = model.imageName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        fallbackEmoji
                    }
                }
                .frame(height: 150) // ✅ smaller card height
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                   startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.black, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Up next")
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(model.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(model.meta)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 2)
                }
                .padding(12)
            }

            // Suggestion section
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Scranly stats roundup")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.primary)

                Button(action: onSuggest) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.text.bubble.fill")
                        Text("Stats 📊")
                    }
                }
                .buttonStyle(HVWideAccentButtonStyle())  // ✅ new style
            }
            .padding(.horizontal, 2)
            .padding(.top, 4)
        }
    }
}

// MARK: - Bottom: Week at a Glance (heatmap + meal dots + bars)
fileprivate struct WeekAtAGlance: View {
    struct Day: Identifiable {
        let id = UUID()
        let label: String   // “Mon”, “Tue”…
        let meals: Int      // 0...3
        let calories: Int   // for mini bar
        let goal: Int
    }
    let days: [Day]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(hvBrand)
                Text("Week at a glance")
                    .font(.headline)
                Spacer()
                Legend()
            }

            HStack(spacing: 10) {
                ForEach(days) { d in
                    VStack(spacing: 8) {
                        // heat cell
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(heat(for: d))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.black, lineWidth: 2))
                            .frame(width: 42, height: 56)
                            .overlay(
                                VStack(spacing: 5) {
                                    HStack(spacing: 3) {
                                        ForEach(0..<3) { i in
                                            Circle()
                                                .fill(i < d.meals ? hvBrand : Color(.systemGray5))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    // mini bar (kcal vs goal)
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color(.systemGray5)).frame(height: 6)
                                        GeometryReader { geo in
                                            let p = min(1, max(0, Double(d.calories) / Double(d.goal)))
                                            Capsule()
                                                .fill(hvBrand)
                                                .frame(width: geo.size.width * p, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }
                                .padding(.horizontal, 6)
                            )

                        Text(d.label)
                            .font(.caption2.weight(.heavy))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func heat(for d: Day) -> Color {
        // simple heat: meals + kcal ratio
        let m = Double(d.meals) / 3.0
        let c = min(1.0, Double(d.calories) / Double(d.goal))
        let a = 0.08 + (0.18 * (0.6*m + 0.4*c))
        return hvBrand.opacity(a)
    }

    private struct Legend: View {
        var body: some View {
            HStack(spacing: 8) {
                Capsule().fill(hvBrand).frame(width: 14, height: 6)
                Text("kcal vs goal").font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 3) {
                    Circle().fill(hvBrand).frame(width: 6, height: 6)
                    Circle().fill(hvBrand.opacity(0.6)).frame(width: 6, height: 6)
                    Circle().fill(Color(.systemGray5)).frame(width: 6, height: 6)
                }
                Text("meals").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct WeekProgressSummary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your week at a glance")
                .font(.headline)
                .padding(.horizontal)

            ProgressRow(title: "Meals planned", value: 0.7, color: .scranOrange)
            ProgressRow(title: "Shopping done", value: 0.5, color: .green)
            ProgressRow(title: "Tracking progress", value: 0.8, color: .blue)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
}

fileprivate struct ProgressRow: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: CGFloat(value) * UIScreen.main.bounds.width * 0.75, height: 10)
                    .animation(.easeOut(duration: 0.6), value: value)
            }
        }
    }
}

struct ScranFact {
    let emoji: String
    let category: String
    let text: String
}

struct ScranFactCard: View {
    let fact: ScranFact
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // tiny header line
            HStack(spacing: 6) {
                Text(fact.emoji).font(.title3)
                Text(fact.category.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // the line that matters
            Text(fact.text)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // soft, clean, no border:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.scranOrange.opacity(0.08))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
        )
        .padding(.horizontal)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: appear)
        .onAppear { appear = true }
    }
}

fileprivate let demoFacts: [ScranFact] = [
    .init(emoji: "⏱️", category: "Time",    text: "Meal planning can save ~3 hours a week."),
    .init(emoji: "💷",  category: "Money",   text: "Cooking at home can save ££ each month."),
    .init(emoji: "🥦",  category: "Health",  text: "A balanced plate: ½ veg, ¼ carbs, ¼ protein."),
    .init(emoji: "🔥",  category: "Tip",     text: "Batch-cook once, reheat twice. Future you says thanks."),
    .init(emoji: "🍽️",  category: "Scranly", text: "Tiny plans beat huge intentions. Log one meal today.")
]


// MARK: - Palette

enum MeterPalette {
    case neutralWithCaps      // ✅ recommended
    case singleHueOrange      // calm variant
}

struct SoftMeterRow: View {
    let title: String
    let valueText: String
    /// normalized progress 0...1 (it’s fine if you pass any Double; we clamp)
    let progress: Double
    let palette: MeterPalette

    private var clamped: CGFloat { CGFloat(max(0, min(1, progress))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(valueText).font(.caption).foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.black.opacity(0.08), lineWidth: 1)
                        )
                        .frame(height: 12)

                    switch palette {
                    case .neutralWithCaps:
                        // gray body + brand “cap” at the end (last 16pt)
                        let bodyWidth = max(0, w * clamped - 16)
                        if bodyWidth > 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray3))
                                .frame(width: bodyWidth, height: 12)
                        }
                        if clamped > 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.scranOrange)
                                .frame(width: min(16, w * clamped), height: 12)
                                .offset(x: max(0, w * clamped - min(16, w * clamped)))
                        }

                    case .singleHueOrange:
                        // same orange, different “feel” per row via overlay pattern
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.scranOrange.opacity(0.75))
                            .frame(width: w * clamped, height: 12)
                            .overlay(
                                // subtle texture that won’t clash with your style
                                Stripes(opacity: 0.08)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            )
                    }
                }
            }
            .frame(height: 12)
        }
    }
}

// Tiny stripe overlay (very subtle)
struct Stripes: View {
    let opacity: Double
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(opacity), location: 0.00),
                        .init(color: .clear,                 location: 0.10),
                        .init(color: .black.opacity(opacity), location: 0.20),
                        .init(color: .clear,                 location: 0.30),
                        .init(color: .black.opacity(opacity), location: 0.40),
                        .init(color: .clear,                 location: 0.50),
                        .init(color: .black.opacity(opacity), location: 0.60),
                        .init(color: .clear,                 location: 0.70),
                        .init(color: .black.opacity(opacity), location: 0.80),
                        .init(color: .clear,                 location: 0.90),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
    }
}

// MARK: - Use in WeekSoftSummary

struct WeekSoftSummary: View {
    let mealsPlanned: Int
    let shoppingItems: Int
    let daysTracked: Int
    var palette: MeterPalette = .neutralWithCaps  // ⬅️ pick your style

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.scranOrange)
                Text("Your week, so far")
                    .font(.headline)
            }
            .padding(.horizontal, 2)

            SoftMeterRow(
                title: "Meals planned",
                valueText: "\(mealsPlanned) meals",
                progress: min(1, Double(mealsPlanned) / 7.0), // calm scaling, not a “target”
                palette: palette
            )

            SoftMeterRow(
                title: "Shopping list",
                valueText: "\(shoppingItems) items",
                progress: min(1, Double(shoppingItems) / 24.0),
                palette: palette
            )

            SoftMeterRow(
                title: "Days tracked",
                valueText: "\(daysTracked) days",
                progress: min(1, Double(daysTracked) / 7.0),
                palette: palette
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// brand wordmark used in your header
fileprivate struct ScranlyWordmark: View {
    var body: some View {
        Text("scranly")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .kerning(0.5)
            .foregroundStyle(.scranOrange)
            .accessibilityLabel("Scranly")
    }
}

// drop-in section title: “Your Scranly Wins”
struct YourScranlyWinsTitle: View {
    var body: some View {
        HStack(spacing: 1) {
            Text("Your ")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .kerning(0.5)

            Text("scranly")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .kerning(0.5)
                .foregroundStyle(.scranOrange)

            Text(" wins 🎉")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)

            Spacer(minLength: 4)
        }
        
    }
}

// MARK: - HOME (now: Top = Wins, Middle = Up Next, Bottom = Week)
struct HomeView: View {
    /// Matches RootTabView tags: 0=Home, 1=Discover, 2=Plan, 3=Shop, 4=Track
    @Binding var selectedTab: Int

    // Hook into API-backed VM
    @StateObject private var vm = HomeViewModel(userId: "testing")

    // MARK: - Mapping helpers

    /// Build the wins carousel items from /v1/stats/summary
    private var winsFromStats: [ScranWinsHero.Win] {
        guard let s = vm.stats else {
            // lightweight placeholder while loading
            return [
                .init(title: "Money saved", value: "—", delta: "", ringProgress: 0.0, icon: "sterlingsign.circle.fill"),
                .init(title: "Time saved",  value: "—", delta: "", ringProgress: 0.0, icon: "clock.badge.checkmark"),
                .init(title: "Meals cooked", value: "—", delta: "", ringProgress: 0.0, icon: "fork.knife")
            ]
        }

        // Simple, clamped ring heuristics until you decide targets
        let moneyProgress  = min(max(s.money_saved / 50.0, 0), 1)     // assume £50 weekly target
        let timeProgress   = min(max(Double(s.time_saved_min) / 60.0, 0), 1) // 60 min target
        let mealsProgress  = min(max(Double(s.meals_cooked) / 100.0, 0), 1)  // 100 lifetime milestone

        return [
            .init(title: "Money saved",
                  value: String(format: "£%.2f", s.money_saved),
                  delta: "", // fill when you have WoW deltas
                  ringProgress: moneyProgress,
                  icon: "sterlingsign.circle.fill"),
            .init(title: "Time saved",
                  value: "\(s.time_saved_min)m",
                  delta: "",
                  ringProgress: timeProgress,
                  icon: "clock.badge.checkmark"),
            .init(title: "Meals cooked",
                  value: "\(s.meals_cooked)",
                  delta: "",
                  ringProgress: mealsProgress,
                  icon: "fork.knife")
        ]
    }

    /// Build UpNext card model from vm.upNext (plan current, expand=true)
    private var upNextFromVM: UpNextCard.Model? {
        guard let n = vm.upNext else { return nil }

        let remoteURL = n.imageURL.flatMap { URL(string: $0) }

        return .init(
            title: n.title,
            meta:  n.meta,
            imageName: nil,     // we’re not using a local asset
            imageURL: remoteURL, // ✅ pass remote URL
            emoji: "🍽️"
        )
    }

    /// Map week chips (meals count per day)
    private var weekFromVM: [WeekAtAGlance.Day] {
        // NOTE: Your WeekAtAGlance.Day in your snippet = (label, meals, calories, goal).
        // VM only provides label + mealsCount. We set calories/goal to 0 for now.
        return vm.weekChips.map { chip in
            WeekAtAGlance.Day(
                label: chip.label,
                meals: chip.mealsCount,
                calories: 0,   // TODO: wire with /v1/track if you want cals
                goal: 0        // TODO: provide daily goal if you track it
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header (unchanged)
                    HVHeader()
                        .padding(.bottom, 2)

                    // TOP THIRD – Scran Wins (API)
                    ScranWinsHero(wins: winsFromStats)
                        .padding(.horizontal)

                    // MIDDLE THIRD – Scranly Bite (clean, borderless)
                    let fact = demoFacts.randomElement()
                    if let fact {
                        ScranFactCard(fact: fact)
                    }

                    // BOTTOM THIRD – Next up (large photo)
                    if let up = upNextFromVM {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            UpNextCard(
                                model: up,
                                onCook: { selectedTab = 4 },
                                onSwap: { selectedTab = 2 },
                                onSuggest: { print("Let us know!") } // or open a suggestion view

                            )
                            .padding(.horizontal)
                        }
                    } else {
                        // Minimal placeholder if no upcoming meal
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            PlaceholderCard(title: "No upcoming meal",
                                            subtitle: "Add meals to your plan to see them here.")
                            .padding(.horizontal)
                        }
                    }

                    // Error / Loading indicators
                    if let err = vm.error {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    } else if vm.isLoading {
                        ProgressView().padding(.top, 4)
                    }

                    Spacer(minLength: 10)
                }
                .padding(.top, 6)
                .frame(minHeight: geo.size.height, alignment: .top)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .task { await vm.load() }
    }
}

// Simple placeholder card for empty up-next
fileprivate struct PlaceholderCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(hvBrand)
                .padding(.bottom, 2)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}



fileprivate struct StatWinTile: View {
    let title: String
    let value: String
    let caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .kerning(0.6)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(hvBrand)
            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

fileprivate struct WeekGlanceChip: View {
    let label: String
    let count: Int
    var body: some View {
        VStack(spacing: 6) {
            Text(label).font(.caption.weight(.heavy))
            Text("\(count)")
                .font(.title3.weight(.black))
                .foregroundStyle(hvBrand)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    HomeView(selectedTab: .constant(0))
}
