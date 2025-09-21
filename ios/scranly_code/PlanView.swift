import SwiftUI
import UIKit

// MARK: - Brand
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Models
enum MealSlot: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast", lunch = "Lunch", dinner = "Dinner"
    var id: String { rawValue }
}

// === Meal image assets (single source of truth) ===
fileprivate enum MealAssets {
    static let nameByTitle: [String: String] = [
        "Overnight Oats":      "oats",
        "Katsu Chicken Curry": "katsu",
        "Chicken Caesar Wrap": "caeser" // matches your asset name
    ]

    static func image(for meal: PlannedMeal) -> Image? {
        guard let name = nameByTitle[meal.title],
              UIImage(named: name) != nil else { return nil }
        return Image(name)
    }

    static func image(named title: String) -> Image? {
        guard let name = nameByTitle[title],
              UIImage(named: name) != nil else { return nil }
        return Image(name)
    }
}

enum ImageSource {
    case ai
    case ccBy
    case stock
    case none
}

struct PlannedMeal: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var slot: MealSlot
    var time: String   // "HH:mm"
    var kcal: Int
    var emoji: String

    // NEW: image attribution
    var imageSource: ImageSource = .none
    var imageAttributionText: String? = nil
    var imageAttributionURL: URL? = nil

    static func sample(_ slot: MealSlot) -> [PlannedMeal] {
        switch slot {
        case .breakfast:
            return [
                .init(title: "Overnight Oats",
                      slot: .breakfast, time: "08:00", kcal: 380, emoji: "🥣",
                      imageSource: .ai),
                .init(title: "Greek Yogurt & Fruit",
                      slot: .breakfast, time: "08:00", kcal: 420, emoji: "🫐",
                      imageSource: .ccBy,
                      imageAttributionText: "Photographer — CC BY 4.0",
                      imageAttributionURL: URL(string: "https://creativecommons.org/licenses/by/4.0/")),
                .init(title: "Eggs on Toast",
                      slot: .breakfast, time: "08:00", kcal: 450, emoji: "🍳")
            ]
        case .lunch:
            return [
                .init(title: "Chicken Caesar Wrap",
                      slot: .lunch, time: "12:30", kcal: 520, emoji: "🌯"),
                .init(title: "Poke Bowl",
                      slot: .lunch, time: "12:30", kcal: 560, emoji: "🍱",
                      imageSource: .ccBy,
                      imageAttributionText: "Photographer — CC BY 4.0",
                      imageAttributionURL: URL(string: "https://creativecommons.org/licenses/by/4.0/")),
                .init(title: "Tomato Mozzarella Panini",
                      slot: .lunch, time: "12:30", kcal: 480, emoji: "🥪",
                      imageSource: .stock,
                      imageAttributionText: "Stock provider",
                      imageAttributionURL: URL(string: "https://example.com"))
            ]
        case .dinner:
            return [
                .init(title: "Katsu Chicken Curry",
                      slot: .dinner, time: "19:00", kcal: 612, emoji: "🍛",
                      imageSource: .ai),
                .init(title: "Salmon & Rice",
                      slot: .dinner, time: "19:00", kcal: 590, emoji: "🍣"),
                .init(title: "Veggie Stir Fry",
                      slot: .dinner, time: "19:00", kcal: 520, emoji: "🥦")
            ]
        }
    }
}

// MARK: - Routing (single, consolidated)
private enum PlanRoute: Hashable {
    case previous
    case meal(PlannedMeal)
    case cook(PlannedMeal)

    // Plan & Modify hub + subflows
    case planHub
    case oneTapPlan
    case detailedPlan
    case mealPrep
    case kodify
}

// MARK: - Styles
fileprivate struct PlanOrangeIconBlackTextLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(brandOrange)
            configuration.title.foregroundStyle(.black)
        }
    }
}
fileprivate struct PlanWhiteBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black, lineWidth: 3)   // ← black border
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
fileprivate struct FlatChipStyle: ViewModifier {
    var corner: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.85), .clear],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            // 👇 no shadows here
            .compositingGroup()
    }
}

fileprivate extension View {
    func flatChip(corner: CGFloat = 10) -> some View { modifier(FlatChipStyle(corner: corner)) }
}

fileprivate struct PlanMiniBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Shape for bottom-only rounded bar
private struct BottomCorners: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(p.cgPath)
    }
}

// MARK: - Sticky header (fixed at top)
// MARK: - Sticky header (fixed at top) — UPDATED with week arrows
// MARK: - Empty week placeholder
// MARK: - Empty day placeholders

fileprivate struct FutureEmptyDayPlaceholder: View {
    var onPlan: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(brandOrange)
            Text("No meals planned for this day")
                .font(.headline)
            Text("Use Plan & Modify to build a day in a tap, or customise it to taste.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onPlan) {
                Label("Plan & Modify", systemImage: "wand.and.rays")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

fileprivate struct PastEmptyDayPlaceholder: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No meals saved for this day")
                .font(.headline)
            Text("Past days are shown as history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
// Map recipe titles -> asset names in your xcassets
fileprivate let assetNameByTitle: [String: String] = [
    "Overnight Oats":       "oats",
    "Katsu Chicken Curry":  "katsu",
    "Chicken Caesar Wrap":  "caeser" // <-- matches your asset's spelling
]



fileprivate struct SubtleChipStyle: ViewModifier {
    var corner: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            // lighter, single shadow (no brand glow / stacked shadows)
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}
fileprivate extension View {
    func subtleChip(corner: CGFloat = 12) -> some View { modifier(SubtleChipStyle(corner: corner)) }
}
// MARK: - Sticky header (fixed at top) — arrows inline with calendar chips
fileprivate struct PlanStickyWeekHeader: View {
    let days: [Date]
    @Binding var selectedIndex: Int
    var onPreviousTap: () -> Void = {}
    var onPrevWeek: () -> Void = {}
    var onNextWeek: () -> Void = {}

    private func isToday(_ d: Date) -> Bool { Calendar.current.isDateInToday(d) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Plan")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)
                Spacer()
                Button(action: onPreviousTap) {
                    Label("Previous", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(PlanMiniBorderButtonStyle())
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Button(action: onPrevWeek) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.heavy))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PlanMiniBorderButtonStyle())

                ForEach(days.indices, id: \.self) { i in
                    let d = days[i]
                    let selected = (i == selectedIndex)
                    let today    = isToday(d)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedIndex = i }
                    } label: {
                        VStack(spacing: 2) {
                            Text(d.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2.weight(selected ? .heavy : .regular))
                            Text(d.formatted(.dateTime.day()))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selected ? brandOrange.opacity(0.10) : Color(.systemBackground))
                        .overlay(
                            VStack(spacing: 0) {
                                Spacer()
                                if today { Rectangle().fill(brandOrange).frame(height: 3) }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.black, lineWidth: selected ? 3 : 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onNextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.heavy))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PlanMiniBorderButtonStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Value banner
fileprivate struct PlanTimeSavedBanner: View {
    let minutes: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(brandOrange.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(brandOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(minutes)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                        Text("min")
                            .font(.callout.weight(.semibold))
                            .padding(.vertical, 2).padding(.horizontal, 8)
                            .overlay(Capsule().stroke(brandOrange.opacity(0.6), lineWidth: 1.5))
                    }
                    Text("saved planning with Scranly this week")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(contextLine(minutes))
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.black, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func contextLine(_ m: Int) -> String {
        switch m {
        case 0..<10:   return "That’s a quick coffee break ☕️"
        case 10..<25:  return "That’s an upbeat walk around the block 🚶"
        case 25..<45:  return "That’s an episode of your fave show 📺"
        case 45..<75:  return "That’s a gym session in the bank 🏋️"
        default:       return "That’s a proper night’s downtime 😌"
        }
    }
}

// MARK: - Cards (emoji visuals)
// MARK: - Cards (emoji visuals) — now tries to load real images first
// Add this helper near the top of the file (outside the view):

// MARK: - Cards (inline Cook button)
// Large card
private struct MealCardLarge: View {
    let meal: PlannedMeal
    var onOpenDetails: () -> Void
    var onCook: () -> Void

    private let corner: CGFloat = 18
    private let visualHeight: CGFloat = 220
    private var barHeight: CGFloat { visualHeight / 3 }
    private let barOverlap: CGFloat = 14

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // --- inside MealCardLarge ---
            Group {
                if let img = MealAssets.image(named: meal.title) {
                    img.resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: visualHeight, alignment: .top) // anchor crop to top
                        .clipped()
                } else {
                    ZStack { brandOrange.opacity(0.16); Text(meal.emoji).font(.system(size: 90)) }
                        .frame(height: visualHeight)
                }
            }
            .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .frame(height: visualHeight)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
            .onTapGesture(perform: onOpenDetails)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.title).font(.headline.weight(.heavy)).foregroundStyle(.black).lineLimit(2)
                    Text("\(meal.slot.rawValue) • \(meal.time) • \(meal.kcal) kcal")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button(action: onCook) { Label("Cook", systemImage: "flame.fill") }
                    .buttonStyle(.borderedProminent).tint(brandOrange)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(height: barHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BottomCorners(radius: corner).fill(Color(.systemBackground)))
            // ⬇️ keep the soft rim-light, remove black stroke
            .overlay(
                BottomCorners(radius: corner)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.85), .clear],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .shadow(color: brandOrange.opacity(0.10), radius: 14, y: 6)
            .offset(y: barOverlap)
            .compositingGroup()
        }
        .padding(.bottom, barOverlap)
    }
}

private struct MealCardSmall: View {
    let meal: PlannedMeal
    var onOpenDetails: () -> Void
    var onCook: () -> Void

    private let corner: CGFloat = 16
    private let imageHeight: CGFloat = 130
    private var barHeight: CGFloat { imageHeight * 0.28 }
    private let barOverlap: CGFloat = 12

    var body: some View {
        ZStack(alignment: .bottom) {
            // Image/emoji visual
            Group {
                if let img = MealAssets.image(named: meal.title) {
                    img.resizable()
                        .scaledToFill()
                        .frame(height: imageHeight, alignment: .top) // anchor crop to top
                        .clipped()
                } else {
                    ZStack {
                        brandOrange.opacity(0.14)
                        Text(meal.emoji).font(.system(size: 64))
                    }
                    .frame(height: imageHeight)
                }
            }
            .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, y: 5)
            .onTapGesture(perform: onOpenDetails)

            // Info bar
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.title)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                    Text("\(meal.time) • \(meal.kcal) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Button(action: onCook) {
                    Label("Cook", systemImage: "flame.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(brandOrange)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: barHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BottomCorners(radius: corner).fill(Color(.systemBackground)))
            .overlay(
                BottomCorners(radius: corner)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.85), .clear],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
            .shadow(color: brandOrange.opacity(0.08), radius: 10, y: 5)
            .offset(y: barOverlap)
            .compositingGroup()
        }
        .padding(.bottom, barOverlap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meal.title), \(meal.time), \(meal.kcal) calories")
        .accessibilityHint("Tap to view details or use Cook.")
    }
}

// MARK: - Day Page
// MARK: - Day Page — UPDATED to show placeholder when empty
// MARK: - Day Page — UPDATED to show placeholder when empty
private struct DayPage: View {
    let date: Date
    let meals: [PlannedMeal]
    var onOpenDetails: (PlannedMeal) -> Void
    var onCook: (PlannedMeal) -> Void
    var onPlanWeek: () -> Void = {}   // unchanged

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isPastDay: Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: date) < cal.startOfDay(for: Date())
    }
    private var nowMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
    private var upNext: PlannedMeal? {
        guard isToday, !meals.isEmpty else { return nil }
        return meals.first(where: { timeToMinutes($0.time) > nowMinutes }) ?? meals.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let next = upNext {
                Text("Up next…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                MealCardLarge(
                    meal: next,
                    onOpenDetails: { onOpenDetails(next) },
                    onCook: { onCook(next) }
                )
            }

            Text(isToday ? "Today’s foods" : "Meals")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if meals.isEmpty {
                if isPastDay {
                    PastEmptyDayPlaceholder()          // 👈 no Plan button in the past
                        .padding(.bottom, 6)
                } else {
                    FutureEmptyDayPlaceholder(onPlan: onPlanWeek) // 👈 CTA for today/future
                        .padding(.bottom, 6)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(meals, id: \.id) { m in
                        MealCardSmall(
                            meal: m,
                            onOpenDetails: { onOpenDetails(m) },
                            onCook: { onCook(m) }
                        )
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - Plan & Modify Hub
private struct PlanModifyHubView: View {
    let onOpen: (PlanRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Plan")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ActionChip(title: "One-tap plan", system: "sparkles", subtitle: "Auto-fill a sensible week") {
                        onOpen(.oneTapPlan)
                    }
                    ActionChip(title: "Detailed plan", system: "list.bullet.rectangle", subtitle: "Choose meals, days, times") {
                        onOpen(.detailedPlan)
                    }
                    ActionChip(title: "Meal prep (Beta)", system: "beaker", subtitle: "Batch cook, portion, repeat") {
                        onOpen(.mealPrep)
                    }
                }
                .padding(.horizontal)

                Text("Modify")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .padding(.top, 8)
                    .padding(.horizontal)

                ActionChip(title: "Kodifying (coming soon)", system: "hammer", subtitle: "Edit rules & constraints") {
                    onOpen(.kodify)
                }
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ActionChip: View {
    let title: String
    let system: String
    var subtitle: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(brandOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .subtleChip(corner: 12)   // ⬅️ was .floatChip
    }
}
                

// MARK: - Plan View — UPDATED with weekOffset + header arrows + placeholder wiring
                // MARK: - Plan View (drop-in)
struct PlanView: View {
    // Calendar model
    private let cal = Calendar.current
    private let startOfCurrentWeek: Date
    @State private var days: [Date]

    // Data
    @State private var plan: [Date: [PlannedMeal]] = [:]        // startOfDay -> meals
    @State private var timeSavedByWeek: [Date: Int] = [:]        // weekStart -> minutes

    // UI state
    @State private var selectedIndex: Int = 0
    @State private var path: [PlanRoute] = []
    @State private var weekOffset: Int = 0

    init() {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        self.startOfCurrentWeek = start
        self._days = State(initialValue: (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) })

        // Seed: this week (breakfast/lunch/dinner)
        var seeded: [Date: [PlannedMeal]] = [:]
        for d in (0..<7).compactMap({ cal.date(byAdding: .day, value: $0, to: start) }) {
            let k = cal.startOfDay(for: d)
            seeded[k] = [
                PlannedMeal.sample(.breakfast)[0],
                PlannedMeal.sample(.lunch)[0],
                PlannedMeal.sample(.dinner)[0]
            ]
        }

        // Seed: last week (a couple of days for variety)
        let lastWeekStart = cal.date(byAdding: .day, value: -7, to: start)!
        let monLastWeek   = cal.date(byAdding: .day, value: 1, to: lastWeekStart)!
        let thuLastWeek   = cal.date(byAdding: .day, value: 4, to: lastWeekStart)!
        seeded[cal.startOfDay(for: monLastWeek)] = [PlannedMeal.sample(.lunch)[1]]
        seeded[cal.startOfDay(for: thuLastWeek)] = [PlannedMeal.sample(.dinner)[1]]

        _plan = State(initialValue: seeded)
        _timeSavedByWeek = State(initialValue: [
            start: 37,
            lastWeekStart: 12
        ])

        // Select today's chip if visible
        if let i = (0..<7)
            .compactMap({ cal.date(byAdding: .day, value: $0, to: start) })
            .firstIndex(where: { cal.isDateInToday($0) }) {
            _selectedIndex = State(initialValue: i)
        }
    }

    // MARK: - Week helpers
    private func weekDays(startingAt start: Date) -> [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    private func currentWeekStart() -> Date {
        cal.date(byAdding: .day, value: weekOffset * 7, to: startOfCurrentWeek)!
    }
    private func goPrevWeek() {
        weekOffset -= 1
        days = weekDays(startingAt: currentWeekStart())
        selectedIndex = min(max(selectedIndex, 0), 6)
    }
    private func goNextWeek() {
        weekOffset += 1
        days = weekDays(startingAt: currentWeekStart())
        selectedIndex = min(max(selectedIndex, 0), 6)
    }

    // MARK: - Data helpers
    private func key(_ d: Date) -> Date { cal.startOfDay(for: d) }
    private func meals(for date: Date) -> [PlannedMeal] {
        (plan[key(date)] ?? []).sorted { timeToMinutes($0.time) < timeToMinutes($1.time) }
    }
    private var welcomeRangeText: String {
        guard let first = days.first, let last = days.last else { return "" }
        let df = DateFormatter(); df.locale = .current; df.dateFormat = "d MMM"
        return "\(df.string(from: first)) – \(df.string(from: last))"
    }
    private var weekHasMeals: Bool {
        days.contains { !(plan[key($0)] ?? []).isEmpty }
    }
    private var weekTimeSaved: Int {
        timeSavedByWeek[currentWeekStart()] ?? 0
    }

    // MARK: - View
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                PlanStickyWeekHeader(
                    days: days,
                    selectedIndex: $selectedIndex,
                    onPreviousTap: { path.append(.previous) },
                    onPrevWeek: goPrevWeek,
                    onNextWeek: goNextWeek
                )
                Divider()

                ScrollView {
                    VStack(spacing: 14) {
                        Text("Your week • \(welcomeRangeText)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        if weekHasMeals {
                            PlanTimeSavedBanner(minutes: weekTimeSaved)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        }

                        let dayDate = days[selectedIndex]
                        DayPage(
                            date: dayDate,
                            meals: meals(for: dayDate),
                            onOpenDetails: { meal in path.append(.meal(meal)) },
                            onCook: { meal in path.append(.cook(meal)) },
                            onPlanWeek: { path.append(.planHub) }
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 8)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: { path.append(.planHub) }) {
                    Label("Plan & Modify", systemImage: "wand.and.rays")
                        .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                }
                .buttonStyle(PlanWhiteBorderButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
            .navigationDestination(for: PlanRoute.self) { route in
                switch route {
                case .previous:
                    PreviousPlansView()
                case .meal(let meal):
                    MealDetailView(meal: meal, onCook: { path.append(.cook(meal)) })
                case .cook(let meal):
                    CookingModeView(meal: meal)
                case .planHub:
                    PlanModifyHubView(onOpen: { path.append($0) })
                case .oneTapPlan:
                    OneTapPlanView()
                case .detailedPlan:
                    DetailedPlanView()
                case .mealPrep:
                    MealPrepView()
                case .kodify:
                    KodifyPlaceholderView()
                }
            }
        }
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
    }
}

// Small, friendly prompt for empty current/future weeks
private struct EmptyWeekPrompt: View {
    var onPlanTap: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3.bold())
                .foregroundStyle(brandOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text("No meals planned yet")
                    .font(.subheadline.weight(.heavy))
                Text("Kick things off with One-Tap Plan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onPlanTap) {
                Label("Plan week", systemImage: "wand.and.stars")
            }
            .buttonStyle(PlanMiniBorderButtonStyle())
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// Small, friendly prompt for empty current/future weeks


private struct PreviousPlansView: View {
    var body: some View {
        List {
            Section("Recent") {
                ForEach(0..<4) { i in
                    HStack {
                        Image(systemName: "calendar")
                        VStack(alignment: .leading) {
                            Text("Week \(i + 1) of \(Calendar.current.component(.year, from: Date()))")
                            Text("Tap to view details").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Previous plans")
    }
}

// MARK: - Hub placeholders
// MARK: - One-tap Plan

private struct OneTapPlanView: View {
    /// Call this to actually create the plan (then pop / navigate as you like).
    var onPlan: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(brandOrange)

            Text("One-tap plan")
                .font(.system(size: 28, weight: .black, design: .rounded))

            Text("We’ll build a sensible week from your saved preferences.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Central one-tap button
            Button(action: onPlan) {
                Label("Plan my week", systemImage: "wand.and.stars")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
            .padding(.horizontal)

            // Disclaimer
            Text("You can update your preferences any time in Settings → Planning Preferences.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("One-tap plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UI bits

private struct SectionHeader: View {
    let text: String
    init(_ t: String) { self.text = t }
    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .padding(.top, 4)
    }
}

private struct SelectableChip: View {
    var title: String
    var system: String? = nil
    @Binding var isOn: Bool
    var corner: CGFloat = 10

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() }
        } label: {
            HStack(spacing: 8) {
                if let system { Image(systemName: system).font(.caption.weight(.heavy)) }
                Text(title).font(.caption.weight(.semibold))
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(isOn ? brandOrange.opacity(0.15) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FlexibleChipsGrid<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            content
        }
    }
}

// MARK: - Enums (simple, readable labels)

private enum DaysPreset: String, CaseIterable, Identifiable {
    case weekdays, fullWeek, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .weekdays: return "Weekdays (5)"
        case .fullWeek: return "Full week (7)"
        case .custom:   return "Custom"
        }
    }
}

private enum BudgetTier: String, CaseIterable, Identifiable {
    case lean, balanced, generous
    var id: String { rawValue }
    var label: String {
        switch self {
        case .lean:     return "Lean"
        case .balanced: return "Balanced"
        case .generous: return "Generous"
        }
    }
}

private enum Protein: String, CaseIterable, Identifiable, Hashable {
    case chicken, beef, pork, fish, seafood, tofu, beans, eggs
    var id: String { rawValue }
    var label: String {
        switch self {
        case .chicken: return "Chicken"
        case .beef:    return "Beef"
        case .pork:    return "Pork"
        case .fish:    return "Fish"
        case .seafood: return "Seafood"
        case .tofu:    return "Tofu/Tempeh"
        case .beans:   return "Beans/Lentils"
        case .eggs:    return "Eggs"
        }
    }
    var system: String {
        switch self {
        case .chicken: return "drumstick.fill"
        case .beef:    return "fork.knife"
        case .pork:    return "fork.knife"
        case .fish:    return "fish"
        case .seafood: return "catfish.fill"
        case .tofu:    return "leaf"
        case .beans:   return "leaf.circle"
        case .eggs:    return "circle.lefthalf.filled"
        }
    }
}

private enum QuickTag: String, CaseIterable, Identifiable, Hashable {
    case quick, onePan, comfort, vegForward, kidFriendly, lowCarb, spicy, mealPrep
    var id: String { rawValue }
    var label: String {
        switch self {
        case .quick:      return "Quick (<20m)"
        case .onePan:     return "One-pan"
        case .comfort:    return "Comfort"
        case .vegForward: return "Veg-forward"
        case .kidFriendly:return "Kid-friendly"
        case .lowCarb:    return "Low-carb"
        case .spicy:      return "Spicy"
        case .mealPrep:   return "Meal-prep"
        }
    }
    var system: String {
        switch self {
        case .quick:      return "bolt.fill"
        case .onePan:     return "frying.pan"
        case .comfort:    return "heart.fill"
        case .vegForward: return "leaf.fill"
        case .kidFriendly:return "face.smiling"
        case .lowCarb:    return "scalemass"
        case .spicy:      return "flame.fill"
        case .mealPrep:   return "tray.fill"
        }
    }
}

private enum DietaryRule: String, CaseIterable, Identifiable, Hashable {
    case vegetarian, vegan, pescatarian, dairyFree, glutenFree, nutFree, halal, kosher
    var id: String { rawValue }
    var label: String {
        switch self {
        case .vegetarian:  return "Vegetarian"
        case .vegan:       return "Vegan"
        case .pescatarian: return "Pescatarian"
        case .dairyFree:   return "Dairy-free"
        case .glutenFree:  return "Gluten-free"
        case .nutFree:     return "Nut-free"
        case .halal:       return "Halal"
        case .kosher:      return "Kosher"
        }
    }
}
// MARK: - Detailed Plan (working/staging planner)
private struct DetailedPlanView: View {
    // Hook to apply the staged plan back to your main store later if you want.
    // Key = weekday 0...6 (Mon...Sun), Value = slot -> meal
    var onApply: (_ staged: [Int: [MealSlot: PlannedMeal]]) -> Void = { _ in }

    @State private var selectedDays: Set<Int> = [0,1,2,3,4,5,6]
    @State private var selectedSlot: MealSlot = .dinner
    @State private var selectedMealIndex: Int = 0

    // Staging area: weekday -> [slot: meal]
    @State private var staging: [Int: [MealSlot: PlannedMeal]] = [:]

    private let weekdayShort = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    private let defaultTimes: [MealSlot: String] = [.breakfast:"08:00", .lunch:"12:30", .dinner:"19:00"]

    private func options(for slot: MealSlot) -> [PlannedMeal] {
        PlannedMeal.sample(slot)
    }

    private func addSelection() {
        let base = options(for: selectedSlot)[selectedMealIndex]
        for d in selectedDays {
            var day = staging[d] ?? [:]
            var m = base
            m.slot = selectedSlot
            m.time = defaultTimes[selectedSlot] ?? m.time
            day[selectedSlot] = m // replace if already present for that slot
            staging[d] = day
        }
    }

    private func clearAll() { staging.removeAll() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Days")
                FlexibleChipsGrid {
                    ForEach(0..<7, id: \.self) { i in
                        SelectableChip(
                            title: weekdayShort[i],
                            isOn: Binding(
                                get: { selectedDays.contains(i) },
                                set: { on in
                                    if on { _ = selectedDays.insert(i) } else { selectedDays.remove(i) }
                                }
                            )
                        )
                    }
                }

                SectionHeader("Meal slot")
                Picker("", selection: $selectedSlot) {
                    ForEach(MealSlot.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                SectionHeader("Pick a meal")
                // Horizontal meal picker matching slot
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(options(for: selectedSlot).enumerated()), id: \.offset) { idx, meal in
                            MealOptionCard(meal: meal, isSelected: idx == selectedMealIndex)
                                .onTapGesture { selectedMealIndex = idx }
                        }
                    }
                    .padding(.horizontal, 2)
                }

                HStack(spacing: 10) {
                    Button(action: addSelection) {
                        Label("Add to selected days", systemImage: "plus.circle.fill")
                            .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                    }
                    .buttonStyle(PlanWhiteBorderButtonStyle())

                    Button(role: .destructive, action: clearAll) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(PlanMiniBorderButtonStyle())
                }

                SectionHeader("This week (staging)")
                VStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { d in
                        DayStagingCard(
                            title: weekdayShort[d],
                            items: staging[d] ?? [:],
                            onRemove: { slot in
                                var day = staging[d] ?? [:]
                                day.removeValue(forKey: slot)
                                if day.isEmpty { staging.removeValue(forKey: d) } else { staging[d] = day }
                            }
                        )
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onApply(staging)
            } label: {
                Label("Save to plan", systemImage: "checkmark.seal.fill")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Detailed plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MealOptionCard: View {
    let meal: PlannedMeal
    let isSelected: Bool
    var body: some View {
        HStack(spacing: 10) {
            Text(meal.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.title)
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text("\(meal.kcal) kcal • \(meal.time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isSelected ? brandOrange.opacity(0.12) : Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black, lineWidth: isSelected ? 3 : 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DayStagingCard: View {
    let title: String
    let items: [MealSlot: PlannedMeal]
    var onRemove: (MealSlot) -> Void

    private var ordered: [(MealSlot, PlannedMeal)] {
        MealSlot.allCases.compactMap { slot in
            items[slot].map { (slot, $0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
            if ordered.isEmpty {
                Text("— No meals added —")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(ordered, id: \.0) { slot, meal in
                    HStack(spacing: 10) {
                        Text(meal.emoji).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.title).font(.subheadline.weight(.semibold))
                            Text("\(slot.rawValue) • \(meal.time) • \(meal.kcal) kcal")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            onRemove(slot)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.black, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
// MARK: - Meal Prep (Beta)
private struct MealPrepView: View {
    // Hook for applying generated prep batches
    var onApply: (_ sessions: [Int: [PlannedMeal]], _ portionsPerMeal: Int) -> Void = { _,_  in }

    @State private var totalMeals: Int = 4
    @State private var sessionsPerWeek: Int = 2
    @State private var portionsPerMeal: Int = 3

    @State private var cookDays: Set<Int> = [1,4] // Tue & Fri default
    @State private var proteinFilters: Set<Protein> = [.chicken, .fish, .tofu]

    @State private var generated: [Int: [PlannedMeal]] = [:] // weekday -> meals (batch)
    @State private var hasGenerated = false

    private let weekdayShort = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    private func candidatePool() -> [PlannedMeal] {
        // Build a simple pool filtered by protein tags (approximate using emoji/title)
        let all = MealSlot.allCases.flatMap { PlannedMeal.sample($0) }
        guard !proteinFilters.isEmpty else { return all }
        return all.filter { m in
            let t = m.title.lowercased()
            return (proteinFilters.contains(.chicken) && t.contains("chicken")) ||
                   (proteinFilters.contains(.beef)    && t.contains("beef")) ||
                   (proteinFilters.contains(.pork)    && t.contains("pork")) ||
                   (proteinFilters.contains(.fish)    && (t.contains("salmon") || t.contains("poke") || t.contains("fish"))) ||
                   (proteinFilters.contains(.seafood) && t.contains("prawn")) ||
                   (proteinFilters.contains(.tofu)    && t.contains("tofu")) ||
                   (proteinFilters.contains(.beans)   && (t.contains("bean") || t.contains("lentil"))) ||
                   (proteinFilters.contains(.eggs)    && t.contains("egg"))
        }
    }

    private func generate() {
        let days = cookDays.isEmpty ? [1,4] : Array(cookDays).sorted() // default Tue/Fri if none picked
        let sessions = max(1, min(sessionsPerWeek, days.count))
        let pool = candidatePool()
        guard !pool.isEmpty else { generated = [:]; hasGenerated = false; return }

        // Pick meals
        var chosen: [PlannedMeal] = []
        var idx = 0
        while chosen.count < totalMeals {
            chosen.append(pool[idx % pool.count])
            idx += 1
        }

        // Distribute meals across sessions
        var out: [Int: [PlannedMeal]] = [:]
        for (i, meal) in chosen.enumerated() {
            let sessionIndex = i % sessions
            let dayKey = days[sessionIndex]
            var batch = out[dayKey] ?? []
            var m = meal
            // Use dinner time as default for batch cooking
            m.slot = .dinner
            m.time = "18:00"
            batch.append(m)
            out[dayKey] = batch
        }
        generated = out
        hasGenerated = true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                SectionHeader("How many")
                VStack(spacing: 10) {
                    Stepper(value: $totalMeals, in: 1...12) {
                        Text("\(totalMeals) \(totalMeals == 1 ? "meal" : "meals") to prep")
                            .font(.subheadline.weight(.semibold))
                    }
                    Stepper(value: $sessionsPerWeek, in: 1...7) {
                        Text("\(sessionsPerWeek) \(sessionsPerWeek == 1 ? "session" : "sessions") per week")
                            .font(.subheadline.weight(.semibold))
                    }
                    Stepper(value: $portionsPerMeal, in: 1...8) {
                        Text("\(portionsPerMeal) \(portionsPerMeal == 1 ? "portion" : "portions") per meal")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(.horizontal, 2)

                SectionHeader("Cook days")
                FlexibleChipsGrid {
                    ForEach(0..<7, id: \.self) { i in
                        SelectableChip(
                            title: weekdayShort[i],
                            isOn: Binding(
                                get: { cookDays.contains(i) },
                                set: { on in
                                    if on { _ = cookDays.insert(i) } else { cookDays.remove(i) }
                                }
                            )
                        )
                    }
                }

                SectionHeader("Protein picks")
                FlexibleChipsGrid {
                    ForEach(Protein.allCases) { p in
                        SelectableChip(
                            title: p.label,
                            system: p.system,
                            isOn: Binding(
                                get: { proteinFilters.contains(p) },
                                set: { on in
                                    if on { _ = proteinFilters.insert(p) } else { proteinFilters.remove(p) }
                                }
                            )
                        )
                    }
                }

                // Result preview
                if hasGenerated {
                    SectionHeader("Prep schedule (preview)")
                    VStack(spacing: 12) {
                        ForEach(Array(generated.keys).sorted(), id: \.self) { d in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(weekdayShort[d])
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                ForEach(generated[d] ?? [], id: \.id) { meal in
                                    HStack(spacing: 10) {
                                        Text(meal.emoji).font(.title3)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal.title).font(.subheadline.weight(.semibold))
                                            Text("\(portionsPerMeal) portions • batch @ \(meal.time)")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(.black, lineWidth: 2)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.black, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Button(action: generate) {
                    Label(hasGenerated ? "Regenerate" : "Build prep plan", systemImage: "wand.and.stars")
                        .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlanWhiteBorderButtonStyle())

                if hasGenerated {
                    Button {
                        onApply(generated, portionsPerMeal)
                    } label: {
                        Label("Save", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(PlanMiniBorderButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Meal prep (Beta)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
private struct KodifyPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Kodifying").font(.title2.weight(.heavy))
            Text("Rules & constraints editor — tweak budget, macros, cuisines and more.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)
            Spacer()
        }.padding()
    }
}

// MARK: - Meal Detail (Plan: identical tone + Cook CTA)
fileprivate struct MethodHintPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.footnote.weight(.heavy))
                .foregroundStyle(brandOrange)
            Text("Prefer a hands-free, step-by-step flow with big buttons and timers? Jump into Cook Mode.")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .flatChip(corner: 10)   // ← no shadow now
    }
}

private struct MealDetailView: View {
    let meal: PlannedMeal
    var onCook: () -> Void
    @State private var tab: Tab = .ingredients
    @State private var completedSteps: Set<Int> = []
    @State private var showAIDisclosure = false
    
    enum Tab: String, CaseIterable, Identifiable {
        case ingredients = "Ingredients", method = "Method"
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                
                // Title + meta (moved ABOVE the image)
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .kerning(0.5)
                    
                    HStack(spacing: 8) {
                        PlanRDMetaTag(systemImage: "clock",      text: meal.time)
                        PlanRDMetaTag(systemImage: "flame.fill", text: "\(meal.kcal) kcal")
                        PlanRDMetaTag(systemImage: "fork.knife", text: meal.slot.rawValue)
                    }
                }
                
                // Subtle disclosure / attribution (sandwiched between title and image)
                HStack(spacing: 6) {
                    switch meal.imageSource {
                    case .ai:
                        Image(systemName: "sparkles")
                        Text("May contain AI-generated imagery")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button { showAIDisclosure = true } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("About this image")
                        
                    case .ccBy, .stock:
                        if let txt = meal.imageAttributionText {
                            Image(systemName: "camera")
                            if let url = meal.imageAttributionURL {
                                Link("Photo: \(txt)", destination: url)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Photo: \(txt)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        
                    case .none:
                        EmptyView()
                    }
                }
                .padding(.top, 2)
                
                // Hero image (now BELOW the disclosure)
                // Hero image (now BELOW the disclosure)
                // Hero image (below the disclosure)
                Group {
                    if let img = MealAssets.image(for: meal) {
                        img.resizable().scaledToFill()
                    } else {
                        ZStack { brandOrange.opacity(0.15); Text(meal.emoji).font(.system(size: 96)) }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .contentShape(Rectangle())
                
                // Description
                Text(longDescription(for: meal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                
                // Tabs
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                // Content
                if tab == .ingredients {
                    let data = PlanRDIngredients.make(for: meal)
                    let grouped = PlanRDIngredients.grouped(data)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(grouped, id: \.0) { (category, idxs) in
                            PlanRDCategoryHeader(text: category)
                            VStack(spacing: 0) {
                                ForEach(idxs, id: \.self) { i in
                                    PlanRDIngredientRow(item: data[i])
                                    if i != idxs.last { PlanRDRowSeparator() }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 2)
                        }
                    }
                    .padding(.top, 4)
                    
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        MethodHintPill()
                        ForEach(Array(methodSteps.enumerated()), id: \.offset) { idx, line in
                            PlanRDMethodStepRow(
                                index: idx + 1,
                                text: line,
                                done: completedSteps.contains(idx),
                                onToggle: {
                                    if completedSteps.contains(idx) { completedSteps.remove(idx) }
                                    else { completedSteps.insert(idx) }
                                }
                            )
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 24)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onCook) {
                Label("Cook now", systemImage: "flame.fill")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(meal.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAIDisclosure) {
            VStack(spacing: 12) {
                Text("About this image").font(.headline)
                Text("We sometimes use AI images when a suitable photo isn’t available. Images are for illustration only. We’re working to minimise AI use and replace it with real photography over time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Got it") { showAIDisclosure = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    private func longDescription(for meal: PlannedMeal) -> String {
        switch meal.title {
        case "Katsu Chicken Curry":
            return "Crisp panko-coated chicken over warm rice with a silky Japanese curry that’s mellow, gently sweet and deeply comforting. Caramelised onion and carrot give body; a splash of soy adds depth."
        case "Salmon & Rice":
            return "Roasted salmon on fluffy rice with bright greens and a citrus–soy finish. Clean, savoury and weeknight-fast; great with sesame and cucumber."
        case "Veggie Stir Fry":
            return "Snappy vegetables tossed hot and fast in a gingery, garlicky glaze. Glossy, fragrant and full of bite — perfect over noodles or rice."
        case "Chicken Caesar Wrap":
            return "Juicy grilled chicken wrapped with romaine, parmesan and a garlicky dressing. Toast briefly for crunch; travels well for desk lunches."
        case "Poke Bowl":
            return "A sushi-shop bowl on warm rice: marinated fish or tofu, crisp veg and sesame. Add edamame, avocado, nori and a touch of heat."
        case "Tomato Mozzarella Panini":
            return "Ripe tomatoes and molten mozzarella with basil on crackly bread. Simple and generous; pesto or balsamic take it over the top."
        case "Eggs on Toast":
            return "Buttery toast piled with soft, just-set eggs and a peppery finish. Chives, hot sauce or a little cheese keep it interesting."
        case "Greek Yogurt & Fruit":
            return "Thick, tangy yogurt with sweet fruit and a little crunch. Swap berries for what’s in season; a drizzle of honey ties it together."
        case "Overnight Oats":
            return "Oats soaked until plush and spoonable — ready when you are. Layer with fruit, seeds or nut butter for texture and staying power."
        default:
            return "Balanced, flavour-forward and easy to make. Fresh herbs or a squeeze of citrus at the end make it feel restaurant-ready."
        }
    }
    
    private var methodSteps: [String] {
        [
            "Heat pan until hot; prep everything first.",
            "Sear protein 2–3 min per side. Rest briefly.",
            "Flash aromatics 30–60s until fragrant.",
            "Toss veg 2–3 min — keep some bite.",
            "Sauce, season boldly, plate and serve."
        ]
    }
}

// MARK: - Helpers copied to match Discover detail (prefixed PlanRD*)
// Replace your existing PlanRDMetaTag with this
private struct PlanRDMetaTag: View {
    let systemImage: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .foregroundStyle(.secondary)
    }
}

private enum PlanRDUnit: String, CaseIterable, Hashable {
    case count, grams, milliliters
    var label: String { self == .count ? "×" : (self == .grams ? "g" : "ml") }
}
private struct PlanRDIngredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var aisle: String
    var amount: Double
    var unit: PlanRDUnit
    var emoji: String
    var isChecked: Bool = false
}

private enum PlanRDIngredients {
    private static func displayCategory(for aisle: String) -> String {
        let k = aisle.lowercased()
        if k == "produce" { return "Fruit & Veg" }
        if k == "meat" || k == "fish" { return "Meat & Fish" }
        if k == "dairy" { return "Dairy & Eggs" }
        if k == "bakery" { return "Bakery" }
        if k == "cupboard" || k == "pantry" { return "Pantry" }
        if k == "world foods" { return "World & Sauces" }
        return "Other"
    }
    private static let order = ["Fruit & Veg","Meat & Fish","Dairy & Eggs","Bakery","Pantry","World & Sauces","Other"]

    static func grouped(_ items: [PlanRDIngredient]) -> [(String,[Int])] {
        let pairs = items.enumerated().map { ($0.offset, $0.element) }
        let dict = Dictionary(grouping: pairs, by: { displayCategory(for: $0.1.aisle) })
        return dict.keys
            .sorted { (order.firstIndex(of: $0) ?? 999) < (order.firstIndex(of: $1) ?? 999) }
            .map { cat in
                let idxs = (dict[cat] ?? [])
                    .sorted { lhs, rhs in
                        if lhs.1.aisle != rhs.1.aisle { return lhs.1.aisle < rhs.1.aisle }
                        return lhs.1.name < rhs.1.name
                    }
                    .map { $0.0 }
                return (cat, idxs)
            }
    }

    static func make(for meal: PlannedMeal) -> [PlanRDIngredient] {
        switch meal.title {
        case "Katsu Chicken Curry":
            return [
                .init(name: "Chicken breast", aisle: "Meat", amount: 500, unit: .grams, emoji: "🍗"),
                .init(name: "Onion",           aisle: "Produce", amount: 1,   unit: .count, emoji: "🧅"),
                .init(name: "Garlic",          aisle: "Produce", amount: 2,   unit: .count, emoji: "🧄"),
                .init(name: "Carrots",         aisle: "Produce", amount: 2,   unit: .count, emoji: "🥕"),
                .init(name: "Curry paste/roux", aisle: "World Foods", amount: 100, unit: .grams, emoji: "🧂"),
                .init(name: "Coconut milk",    aisle: "World Foods", amount: 400, unit: .milliliters, emoji: "🥥"),
                .init(name: "Cooked rice",     aisle: "Pantry", amount: 300, unit: .grams, emoji: "🍚")
            ]
        case "Salmon & Rice":
            return [
                .init(name: "Salmon fillets",  aisle: "Fish", amount: 2, unit: .count, emoji: "🐟"),
                .init(name: "Rice",            aisle: "Pantry", amount: 200, unit: .grams, emoji: "🍚"),
                .init(name: "Spring onions",   aisle: "Produce", amount: 1, unit: .count, emoji: "🧅"),
                .init(name: "Soy sauce",       aisle: "World Foods", amount: 30, unit: .milliliters, emoji: "🧂")
            ]
        case "Veggie Stir Fry":
            return [
                .init(name: "Mixed veg",       aisle: "Produce", amount: 400, unit: .grams, emoji: "🥦"),
                .init(name: "Garlic",          aisle: "Produce", amount: 2, unit: .count, emoji: "🧄"),
                .init(name: "Ginger",          aisle: "Produce", amount: 1, unit: .count, emoji: "🫚"),
                .init(name: "Noodles / rice",  aisle: "Pantry", amount: 200, unit: .grams, emoji: "🍜"),
                .init(name: "Soy sauce",       aisle: "World Foods", amount: 30, unit: .milliliters, emoji: "🧂")
            ]
        case "Chicken Caesar Wrap":
            return [
                .init(name: "Chicken",         aisle: "Meat", amount: 250, unit: .grams, emoji: "🍗"),
                .init(name: "Wraps",           aisle: "Bakery", amount: 4, unit: .count, emoji: "🌯"),
                .init(name: "Lettuce",         aisle: "Produce", amount: 1, unit: .count, emoji: "🥬"),
                .init(name: "Caesar dressing", aisle: "Dairy", amount: 60, unit: .milliliters, emoji: "🥛")
            ]
        case "Poke Bowl":
            return [
                .init(name: "Rice",            aisle: "Pantry", amount: 200, unit: .grams, emoji: "🍚"),
                .init(name: "Protein (salmon/tofu)", aisle: "Fish", amount: 250, unit: .grams, emoji: "🐟"),
                .init(name: "Cucumber",        aisle: "Produce", amount: 1, unit: .count, emoji: "🥒"),
                .init(name: "Soy + sesame",    aisle: "World Foods", amount: 30, unit: .milliliters, emoji: "🧂")
            ]
        case "Tomato Mozzarella Panini":
            return [
                .init(name: "Panini bread",    aisle: "Bakery", amount: 2, unit: .count, emoji: "🥖"),
                .init(name: "Mozzarella",      aisle: "Dairy", amount: 200, unit: .grams, emoji: "🧀"),
                .init(name: "Tomatoes",        aisle: "Produce", amount: 2, unit: .count, emoji: "🍅"),
                .init(name: "Basil",           aisle: "Produce", amount: 1, unit: .count, emoji: "🌿")
            ]
        case "Eggs on Toast":
            return [
                .init(name: "Eggs",            aisle: "Dairy", amount: 4, unit: .count, emoji: "🥚"),
                .init(name: "Bread",           aisle: "Bakery", amount: 4, unit: .count, emoji: "🍞"),
                .init(name: "Butter",          aisle: "Dairy", amount: 20, unit: .grams, emoji: "🧈")
            ]
        case "Greek Yogurt & Fruit":
            return [
                .init(name: "Greek yogurt",    aisle: "Dairy", amount: 300, unit: .grams, emoji: "🥣"),
                .init(name: "Mixed berries",   aisle: "Produce", amount: 200, unit: .grams, emoji: "🫐"),
                .init(name: "Honey",           aisle: "Pantry", amount: 20, unit: .grams, emoji: "🍯")
            ]
        case "Overnight Oats":
            return [
                .init(name: "Oats",            aisle: "Pantry", amount: 120, unit: .grams, emoji: "🥣"),
                .init(name: "Milk",            aisle: "Dairy", amount: 250, unit: .milliliters, emoji: "🥛"),
                .init(name: "Fruit (topping)", aisle: "Produce", amount: 1, unit: .count, emoji: "🍓")
            ]
        default:
            return [
                .init(name: "Main protein",    aisle: "Meat",     amount: 400, unit: .grams, emoji: "🍗"),
                .init(name: "Mixed veg",       aisle: "Produce",  amount: 300, unit: .grams, emoji: "🥦"),
                .init(name: "Base (rice/pasta)", aisle: "Pantry", amount: 200, unit: .grams, emoji: "🍚")
            ]
        }
    }
}

private struct PlanRDIngredientRow: View {
    @State var item: PlanRDIngredient

    private var qtyText: String {
        switch item.unit {
        case .count:        return "\(Int(item.amount))\(PlanRDUnit.count.label)"
        case .grams:        return "\(Int(item.amount))\(PlanRDUnit.grams.label)"
        case .milliliters:  return "\(Int(item.amount))\(PlanRDUnit.milliliters.label)"
        }
    }

    var body: some View {
        Toggle(isOn: $item.isChecked) {
            HStack(spacing: 8) {
                Text(item.emoji).font(.system(size: 18)).frame(width: 26, height: 26)
                Text(qtyText).font(.subheadline.monospacedDigit())
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                    .layoutPriority(1)
                Spacer(minLength: 8)
            }
            .contentShape(Rectangle())
        }
        .toggleStyle(PlanRDRightCheckToggleStyle())
    }
}

private struct PlanRDRightCheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    configuration.isOn.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                        .frame(width: 22, height: 22)
                    if configuration.isOn {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(.label))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(.systemBackground))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

private struct PlanRDRowSeparator: View {
    var body: some View {
        Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
            .padding(.leading, 44)
    }
}

private struct PlanRDCategoryHeader: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

private struct PlanRDMethodStepRow: View {
    let index: Int
    let text: String
    var done: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { onToggle() }
        }) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [brandOrange, brandOrange.opacity(0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 28, height: 28)
                    Text("\(index)")
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(.white)
                }

                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(done ? .secondary : .primary)
                    .strikethrough(done, color: .secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? brandOrange : .secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(colors: [Color(.systemBackground), brandOrange.opacity(0.05)],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Misc UI helpers you kept
fileprivate struct PopChipStyle: ViewModifier {
    var corner: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
fileprivate extension View { func popChip(corner: CGFloat = 10) -> some View { modifier(PopChipStyle(corner: corner)) } }

private struct DetailInfoPill: View {
    let system: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: system)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .floatChip(corner: 10)
    }
}

private struct IngredientRow: View {
    let title: String
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isChecked.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isChecked ? brandOrange.opacity(0.15) : Color(.systemBackground))
                        .frame(width: 26, height: 26)
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isChecked ? brandOrange : .secondary)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .strikethrough(isChecked, color: .secondary)
                    .opacity(isChecked ? 0.65 : 1)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MethodStepCard: View {
    let stepNumber: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [brandOrange, brandOrange.opacity(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                Text("\(stepNumber)")
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                LinearGradient(colors: [Color(.systemBackground), brandOrange.opacity(0.05)],
                               startPoint: .top, endPoint: .bottom)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Cooking Mode
private struct CookingModeView: View {
    let meal: PlannedMeal
    @Environment(\.dismiss) private var dismiss
    @State private var stepIndex = 0

    private var steps: [String] {
        [
            "Gather all ingredients and tools.",
            "Heat pan / oven as needed.",
            "Cook main ingredient to doneness.",
            "Add aromatics and veg; toss.",
            "Season, plate, and serve."
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2) }
                Spacer()
                Text(meal.title).font(.headline.weight(.heavy))
                Spacer()
                Spacer().frame(width: 28)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            VStack(spacing: 12) {
                Text("Step \(stepIndex + 1) of \(steps.count)")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(steps[stepIndex])
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            Spacer()

            HStack {
                Button {
                    if stepIndex > 0 { stepIndex -= 1 }
                } label: { Label("Back", systemImage: "chevron.left") }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    if stepIndex < steps.count - 1 { stepIndex += 1 } else { dismiss() }
                } label: { Label(stepIndex < steps.count - 1 ? "Next" : "Finish", systemImage: "chevron.right") }
                .buttonStyle(.borderedProminent)
                .tint(brandOrange)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// MARK: - Helper
private func timeToMinutes(_ hhmm: String) -> Int {
    let parts = hhmm.split(separator: ":")
    guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
    return h * 60 + m
}

// MARK: - Floating Chip Style (beefed up)
fileprivate struct FloatChipStyle: ViewModifier {
    var corner: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.85), .clear],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 14)
            .shadow(color: .black.opacity(0.12), radius: 8,  x: 0, y: 4)
            .shadow(color: brandOrange.opacity(0.14), radius: 22, x: 0, y: 10)
            .compositingGroup()
    }
}
fileprivate extension View {
    func floatChip(corner: CGFloat = 10) -> some View { modifier(FloatChipStyle(corner: corner)) }
}

// MARK: - Preview
#Preview { PlanView() }
