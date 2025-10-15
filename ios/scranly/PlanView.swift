import SwiftUI

// Brand color
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)
let userId = "testing"

private enum PlanRoute: Hashable {
    case previous
    case meal(PlannedMeal)
    case cook(PlannedMeal)
    case recipe(Recipe)        // NEW: open Discover’s detail
    case planHub
    case oneTapPlan, detailedPlan, mealPrep, kodify
}

// MARK: - Small styles reused around the screen
fileprivate struct EmptyDayPlaceholder: View {
    let isPast: Bool
    let isToday: Bool
    var onPlan: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isPast ? "calendar" : "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(isPast ? .secondary : brandOrange)

            if isPast {
                Text("No meals saved for this day")
                    .font(.headline)
                Text("Past days are shown as history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(isToday ? "No meals planned for today" : "No meals planned for this day")
                    .font(.headline)
                Text("Use Plan & Modify to build your day in a tap, or customise it to taste.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onPlan) {
                    Label("Plan my meals", systemImage: "wand.and.rays")
                        .labelStyle(PlanOrangeIconBlackTextLabelStyle())
                }
                .buttonStyle(PlanWhiteBorderButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity)
    }
}

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
                    .stroke(Color.black, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
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

// Bottom-only rounded shape for the info bar under images
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

// MARK: - Sticky week header

fileprivate struct PlanStickyWeekHeader: View {
    let days: [Date]
    @Binding var selectedIndex: Int
    var onPreviousTap: () -> Void = {}
    var onPrevWeek: () -> Void = {}
    var onNextWeek: () -> Void = {}
    var onTodayTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Plan")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                Spacer()
                Button(action: onPreviousTap) {
                    Label("Previous", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(PlanMiniBorderButtonStyle())
            }
            .padding(.horizontal)

            Button(action: onTodayTap) {
                Label("Today", systemImage: "calendar")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
            .padding(.horizontal)
        }
        .padding(.top, 4)
        .padding(.bottom, 12) // 🔥 no extra space below
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom) // 🔥 move divider inside
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

fileprivate struct BottomWeekCarousel: View {
    let days: [Date]
    @Binding var selectedIndex: Int
    var onPrevWeek: () -> Void
    var onNextWeek: () -> Void

    private func isToday(_ d: Date) -> Bool { Calendar.current.isDateInToday(d) }

    var body: some View {
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
                let today = isToday(d)

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
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
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

// MARK: - Empty placeholders

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
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onPlan) {
                Label("Plan", systemImage: "wand.and.rays")
                    .labelStyle(PlanOrangeIconBlackTextLabelStyle())
            }
            .buttonStyle(PlanWhiteBorderButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top, 160)
    }
}

fileprivate struct PastEmptyDayPlaceholder: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No meals saved for this day").font(.headline)
            Text("Past days are shown as history.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

// MARK: - Cards

private struct MealCardLarge: View {
    let meal: PlannedMeal
    var onOpenDetails: () -> Void
    var onCook: () -> Void

    private let corner: CGFloat = 18
    private let visualHeight: CGFloat = 300
    private var barHeight: CGFloat { visualHeight / 4 }
    private let barOverlap: CGFloat = 14

    // Fallback visual (no local assets)
    private var fallbackVisual: some View {
        ZStack { brandOrange.opacity(0.16); Text(meal.emoji).font(.system(size: 90)) }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = meal.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .empty:            Color.gray.opacity(0.08)
                        case .failure:          fallbackVisual
                        @unknown default:       fallbackVisual
                        }
                    }
                } else {
                    fallbackVisual
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: visualHeight, alignment: .top)
            .clipped()
            .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
            .onTapGesture(perform: onOpenDetails)

            HStack {
                Text(meal.title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
    private var barMinHeight: CGFloat { imageHeight * 0.36 } // was 0.28
    private let barOverlap: CGFloat = 12

    private var fallbackVisual: some View {
        ZStack { brandOrange.opacity(0.14); Text(meal.emoji).font(.system(size: 64)) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let url = meal.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .empty:            Color.gray.opacity(0.08)
                        case .failure:          fallbackVisual
                        @unknown default:       fallbackVisual
                        }
                    }
                } else {
                    fallbackVisual
                }
            }
            .frame(height: imageHeight, alignment: .top)
            .clipped()
            .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(Color.black.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.10), radius: 8, y: 5)
            .onTapGesture(perform: onOpenDetails)

            // Info bar
            HStack(alignment: .firstTextBaseline) {
                Text(meal.title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true) // let it wrap to 2 lines
                Spacer(minLength: 6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: barMinHeight) // ← allow more than one line
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BottomCorners(radius: corner).fill(Color(.systemBackground)))
            .overlay(
                BottomCorners(radius: corner)
                    .stroke(LinearGradient(colors: [.white.opacity(0.85), .clear],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
            .shadow(color: brandOrange.opacity(0.08), radius: 10, y: 5)
            .offset(y: barOverlap)
            .compositingGroup()
        }
        .padding(.bottom, barOverlap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meal.title), \(meal.time), \(meal.kcal) calories")
        .accessibilityHint("Tap to view details.")
    }
}

// MARK: - Day page

private struct DayPage: View {
    let date: Date
    let meals: [PlannedMeal]
    var onOpenDetails: (PlannedMeal) -> Void
    var onCook: (PlannedMeal) -> Void
    var onPlanWeek: () -> Void = {}

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var nowMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
    private var upNext: PlannedMeal? {
        guard isToday, !meals.isEmpty else { return nil }
        return meals.first(where: { timeToMinutes($0.time) > nowMinutes }) ?? meals.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // ———————————————————————————————————————————
            // Replace your existing day-content conditional with this:
            if meals.isEmpty {
                EmptyDayPlaceholder(
                    isPast: date < Calendar.autoupdatingCurrent.startOfDay(for: Date()),
                    isToday: isToday,
                    onPlan: onPlanWeek
                )
                .padding(.top, 10)
            } else {
                if isToday, let next = upNext {
                    // --- TODAY: quote + up-next card ---
                    VStack(alignment: .leading, spacing: 18) {
                        // Quote
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 2) {
                                Text("💬").font(.title3)
                                Text("Scranly says")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(mealQuote(for: next.title))
                                .font(.title3.weight(.bold))
                                .lineSpacing(4)
                                .foregroundColor(.black)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(brandOrange.opacity(0.08))
                                .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
                        )

                        // Up next meal card
                        MealCardLarge(
                            meal: next,
                            onOpenDetails: { onOpenDetails(next) },
                            onCook: { onCook(next) }
                        )
                    }
                } else {
                    // --- NON-TODAY: list meals for that day ---
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(meals, id: \.id) { meal in
                            MealSection(
                                meal: meal,
                                onOpenDetails: onOpenDetails,
                                onCook: onCook
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            // ———————————————————————————————————————————
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}


private func mealQuote(for title: String) -> String {
    if title.localizedCaseInsensitiveContains("thai") {
        return "A little spice, a lot of comfort — big flavour, low fuss."
    } else if title.localizedCaseInsensitiveContains("pasta") {
        return "Twirls, sauce, comfort. You’ve nailed dinner 🍝"
    } else if title.localizedCaseInsensitiveContains("salad") {
        return "Fresh, fast, and full of colour 🥗"
    } else if title.localizedCaseInsensitiveContains("soup") {
        return "Warm bowl. Warm soul. Simple as that 🍲"
    } else {
        return "Good food, good plan — Scranly style 👨‍🍳"
    }
}
// 1) Custom label style with the icon on the right
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

// 2) Convenience to enable `.labelStyle(.iconTrailing)` syntax
extension LabelStyle where Self == TrailingIconLabelStyle {
    static var iconTrailing: TrailingIconLabelStyle { .init() }
}

private struct TodaysPlanDetailView: View {
    let meals: [PlannedMeal]
    var onOpenDetails: (PlannedMeal) -> Void
    var onCook: (PlannedMeal) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(meals, id: \.id) { meal in
                        MealSection(
                            meal: meal,
                            onOpenDetails: onOpenDetails,
                            onCook: onCook
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Today’s plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

fileprivate struct PlanTimeSavedCompactBar: View {
    let minutes: Int
    var onSeeMore: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(brandOrange)

            Text("\(minutes) min saved this week")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Button(action: onSeeMore) {
                HStack(spacing: 4) {
                    Text("Stats roundup")
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
            }
            .tint(brandOrange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)              // compact height
        .background(Color(.systemBackground))
        .overlay(                             // inner orange border
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(brandOrange.opacity(0.75), lineWidth: 2)
        )
        .overlay(                             // outer black border
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black, lineWidth: 2.5)
                .padding(1)                   // sits just outside the orange
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(minutes) minutes saved this week. See more.")
    }
}

private struct MealSection: View {
    let meal: PlannedMeal
    var onOpenDetails: (PlannedMeal) -> Void
    var onCook: (PlannedMeal) -> Void

    private var inlineMacro: String {
        if let r = meal.recipe {
            return "\(r.calories) kcal • \(Int(r.protein))g P • \(Int(r.carbs))g C • \(Int(r.fat))g F"
        } else {
            return "\(meal.kcal) kcal"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {   // tighter than before
            HStack(spacing: 6) {
                Text(meal.slot.rawValue.capitalized)
                    .font(.headline.weight(.bold))
                Text("(\(inlineMacro))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            MealCardSmall(
                meal: meal,
                onOpenDetails: { onOpenDetails(meal) },
                onCook: { onCook(meal) }
            )
        }
        .padding(.bottom, 6) // tighter than before
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Plan view (server-driven)


struct PlanView: View {
    // MARK: - State
    @StateObject private var vm = PlanViewModel()
    @State private var selectedRecipe: Recipe?
    @State private var showTodaysPlan = false

    // Which chip (day) is selected inside the visible week
    @State private var selectedIndex: Int = 0

    // Convenience: the 7 dates for the currently visible week (Sun→Sat)
    private var days: [Date] { vm.dayDates() }

    // Calendar used only to preserve “same weekday” when paging weeks
    private let cal = Calendar(identifier: .gregorian)
    private func weekday(_ d: Date) -> Int { cal.component(.weekday, from: d) } // 1=Sun…7=Sat

    // TEMP: wire this to your auth/session when ready
    private let userId = "testing"

    // Brand metric placeholder: 5 min per planned event in the visible week
    private var timeSavedMinutes: Int {
        days.reduce(0) { $0 + vm.uiMeals(on: $1).count * 5 }
    }

    // MARK: - View
    var body: some View {
        VStack(spacing: 0) {
            // Sticky week header with inline arrows
            PlanStickyWeekHeader(
                days: days,
                selectedIndex: Binding(
                    get: { min(selectedIndex, max(days.count - 1, 0)) },
                    set: { selectedIndex = $0 }
                ),
                onPreviousTap: { /* ... */ },
                onPrevWeek: {
                    Task {
                        let targetWeekday = days[safe: selectedIndex].map(weekday)
                        await vm.shiftWeek(by: -1)
                        let newDays = vm.dayDates()
                        if let w = targetWeekday,
                           let idx = newDays.firstIndex(where: { weekday($0) == w }) {
                            selectedIndex = idx
                        } else {
                            selectedIndex = 0
                        }
                    }
                },
                onNextWeek: {
                    Task {
                        let targetWeekday = days[safe: selectedIndex].map(weekday)
                        await vm.shiftWeek(by: 1)
                        let newDays = vm.dayDates()
                        if let w = targetWeekday,
                           let idx = newDays.firstIndex(where: { weekday($0) == w }) {
                            selectedIndex = idx
                        } else {
                            selectedIndex = 0
                        }
                    }
                },
                onTodayTap: {
                        // 👇 This is what runs when you tap the Today button in the header
                        showTodaysPlan = true
                    }
            )


            // Content
            ScrollView {
                VStack(spacing: 8) {
                
                    if let dayDate = days[safe: selectedIndex] {
                        DayPage(
                            date: dayDate,
                            meals: vm.uiMeals(on: dayDate),
                            onOpenDetails: { meal in
                                // open recipe detail if available
                                selectedRecipe = meal.recipe
                            },
                            onCook: { _ in }
                        )
                        .padding(.horizontal)
                        .sheet(isPresented: .init(
                            get: { selectedRecipe != nil },
                            set: { if !$0 { selectedRecipe = nil } }
                        )) {
                            if let r = selectedRecipe {
                                RecipeDetailView(meal: r)
                            }
                        }
                    }
                    
                    if timeSavedMinutes > 0 {
                               PlanTimeSavedCompactBar(minutes: timeSavedMinutes, onSeeMore: {
                                   // TODO: open insights screen
                               })
                               .padding(.horizontal)
                               .padding(.top, 4)
                    }

                }
                .padding(.top, 0)
                .padding(.bottom, 10)
            }
            .overlay(alignment: .bottom) {
                BottomWeekCarousel(
                    days: days,
                    selectedIndex: $selectedIndex,
                    onPrevWeek: {
                        Task {
                            let targetWeekday = days[safe: selectedIndex].map(weekday)
                            await vm.shiftWeek(by: -1)
                            let newDays = vm.dayDates()
                            if let w = targetWeekday,
                               let idx = newDays.firstIndex(where: { weekday($0) == w }) {
                                selectedIndex = idx
                            } else {
                                selectedIndex = 0
                            }
                        }
                    },
                    onNextWeek: {
                        Task {
                            let targetWeekday = days[safe: selectedIndex].map(weekday)
                            await vm.shiftWeek(by:  1)
                            let newDays = vm.dayDates()
                            if let w = targetWeekday,
                               let idx = newDays.firstIndex(where: { weekday($0) == w }) {
                                selectedIndex = idx
                            } else {
                                selectedIndex = 0
                            }
                        }
                    }
                )
            }
        }


        // First load
        .task {
            await vm.load(userId: userId)

            // After load, if today is inside the visible week, auto-select that chip; else select the first chip
            if let idx = days.firstIndex(where: { Calendar.current.isDateInToday($0) }) {
                selectedIndex = idx
            } else {
                selectedIndex = 0
            }
        }

        // Lightweight loading overlay
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.08).ignoresSafeArea()
                    ProgressView("Loading…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }

        // Errors
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }

        // Global type style matches the rest of the app
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
        .sheet(isPresented: $showTodaysPlan) {
            let cal = Calendar.autoupdatingCurrent
            let today = cal.startOfDay(for: .now)
            let _ = print("📅 [Debug] Device-reported today: \(today.formatted(.dateTime.year().month().day()))")

            let todaysMeals = vm.uiMeals(on: today)

            if todaysMeals.isEmpty {
                Text("No meals planned for today")
                    .font(.headline)
                    .padding()
            } else {
                TodaysPlanDetailView(
                    meals: todaysMeals,
                    onOpenDetails: { meal in selectedRecipe = meal.recipe },
                    onCook: { _ in }
                )
            }
        }
    }
}

// MARK: - Tiny safe-subscript helper used above
private extension Array {
    subscript(safe i: Index) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - Small utilities

fileprivate struct EmptyWeekPrompt: View {
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

