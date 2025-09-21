import SwiftUI

// Keep styles local to avoid name collisions
fileprivate let hvBrand = Color.scranOrange

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

fileprivate struct HVTagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.vertical, 8).padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

fileprivate struct HVNextChip: View {
    let title: String
    let time: String
    var tap: () -> Void
    var body: some View {
        Button(action: tap) {
            HStack(spacing: 8) {
                Text("Next").font(.system(size: 14, weight: .heavy, design: .rounded))
                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("• \(time)").font(.caption).foregroundStyle(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct HVQuickWidget: View {
    let icon: String, title: String, subtitle: String, lines: [String], accent: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent ? hvBrand.opacity(0.12) : Color(.systemGray6))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.black, lineWidth: 2))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(accent ? hvBrand : .black)
                }
                .frame(width: 56, height: 56)

                Text(title).font(.system(size: 18, weight: .black, design: .rounded))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)

                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(line.first?.isNumber == true || line.contains("kcal") ? .primary : .secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct HVTrackTile: View {
    let kcal: Int, goal: Int, protein: Int
    var open: () -> Void
    private var progress: Double { max(0, min(1, Double(kcal) / Double(goal))) }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.black, lineWidth: 2).frame(width: 58, height: 58)
                Circle().stroke(Color(.systemGray5), lineWidth: 8).frame(width: 56, height: 56)
                Circle().trim(from: 0, to: progress)
                    .stroke(hvBrand, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                Text("\(Int(progress * 100))%").font(.caption.weight(.heavy))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Track").font(.system(size: 18, weight: .black, design: .rounded))
                Text("\(kcal) / \(goal) kcal • \(protein) g protein")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: open) {
                Label("Open", systemImage: "chevron.right").labelStyle(HVIconBlackTextLabelStyle())
            }
            .buttonStyle(HVMiniBorderButtonStyle())
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - HOME (single screen, no scroll)
struct HomeView: View {
    /// Matches RootTabView tags: 0=Home, 1=Discover, 2=Plan, 3=Shop, 4=Track
    @Binding var selectedTab: Int
    @AppStorage("userName") private var userName: String = "Alex"

    // Demo metrics — replace from backend /home payload
    @State private var kpis: [KPI] = [
        .init(icon: "sterlingsign.circle.fill", value: "£184",  label: "Saved",         tint: .green),
        .init(icon: "clock.badge.checkmark",    value: "46m",   label: "Time Saved",    tint: .purple),
        .init(icon: "fork.knife",               value: "73",    label: "Meals Planned", tint: .blue)
    ]
    private let tonight = NextMealHero.Model(
        title: "Katsu Chicken Curry",
        meta:  "Dinner • 19:00 • 612 kcal",
        emoji: "🍛"
    )
    private let nextTitle = "Chicken Caesar Wrap"
    private let nextTime  = "12:30"

    @State private var shopItems = 12
    @State private var shopTotal = 27.59
    @State private var kcalToday = 1640
    @State private var kcalGoal  = 2200
    @State private var proteinToday = 92

    // Rotating micro-tag
    @State private var tagIndex = 0
    private let tags = ["let’s cook 🍳", "< 30 min ⏱️", "high-protein 💪"]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 14) {

                // Top row: brand, greeting, cycling tag
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("scranly")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .kerning(0.5)
                        .foregroundStyle(hvBrand)
                    Spacer()
                    Text("Hi \(userName)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    HVTagChip(text: tags[tagIndex])
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    tagIndex = (tagIndex + 1) % tags.count
                                }
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.top, 6)

                // KPIs (uses your existing KPIGrid)
                KPIGrid(kpis: kpis)
                    .padding(.horizontal)

                // Tonight block (uses your NextMealHero)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tonight")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    NextMealHero(
                        model: tonight,
                        onCook: { selectedTab = 4 },
                        onSwap: { selectedTab = 2 }
                    )
                }
                .padding(.horizontal)

                // Next chip
                HStack {
                    HVNextChip(title: nextTitle, time: nextTime) { selectedTab = 2 }
                    Spacer()
                }
                .padding(.horizontal)

                // Quick widgets in your black-stroke style
                HStack(spacing: 10) {
                    HVQuickWidget(
                        icon: "safari",
                        title: "Discover",
                        subtitle: "for you",
                        lines: ["Because you like", "high-protein"],
                        accent: true
                    ) { selectedTab = 1 }

                    HVQuickWidget(
                        icon: "basket.fill",
                        title: "Shop",
                        subtitle: "your list",
                        lines: ["\(shopItems) items", "£" + String(format: "%.2f", shopTotal) + " est."],
                        accent: false
                    ) { selectedTab = 3 }
                }
                .padding(.horizontal)

                // Track ring tile at bottom
                HVTrackTile(kcal: kcalToday, goal: kcalGoal, protein: proteinToday) {
                    selectedTab = 4
                }
                .padding(.horizontal)

                Spacer(minLength: 6)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView(selectedTab: .constant(0))
}
