import SwiftUI
import Foundation

// MARK: - Brand
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Quote helper
fileprivate func quoteForMeal(_ title: String?) -> String {
    guard let t = title?.lowercased(), !t.isEmpty else {
        return "Let’s lock in dinner. We’ll keep it realistic."
    }
    if t.contains("katsu") { return "Crispy, cosy, total comfort. You earned this 😌" }
    if t.contains("pesto") || t.contains("pasta") { return "Twirls, sauce, comfort. You nailed dinner 🍝" }
    if t.contains("salmon") { return "Protein, flavour, glow. Chef mode 🐟" }
    return "Good food, good plan — Scranly style 👨‍🍳"
}

// MARK: - Core planning models

struct PlannedMeal {
    // Core data
    let recipe: Recipe          // your existing Recipe type
    let title: String
    let time: String            // e.g. "19:15"
    let kcal: Int
    let slot: MealSlot          // breakfast / lunch / dinner / snack
    let emoji: String           // used for the UI (🍛, 🐟, etc.)

    // Optional image hook
    let imageURL: URL?          // currently passed as nil in demoWeek
}

struct DayPlan {
    let date: Date
    var meals: [PlannedMeal]
}

enum MealSlot: String, Hashable, CaseIterable {
    case breakfast, lunch, dinner, snack
}

// MARK: - View model

@MainActor
final class WeekPlanViewModel: ObservableObject {
    @Published var weekStart: Date
    @Published var workWeek: [DayPlan] = []
    private let cal = Calendar.current

    init() {
        let today = cal.startOfDay(for: Date())
        if let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) {
            self.weekStart = monday
        } else {
            self.weekStart = today
        }
        self.workWeek = Self.demoWeek(startingAt: weekStart, calendar: cal)
    }

    func goToPreviousWeek() {
        guard let newStart = cal.date(byAdding: .day, value: -7, to: weekStart) else { return }
        weekStart = newStart
        workWeek  = Self.emptyWeek(startingAt: newStart, calendar: cal)
    }

    func goToNextWeek() {
        guard let newStart = cal.date(byAdding: .day, value: 7, to: weekStart) else { return }
        weekStart = newStart
        workWeek  = Self.emptyWeek(startingAt: newStart, calendar: cal)
    }
}

private extension WeekPlanViewModel {
    static func demoWeek(startingAt monday: Date, calendar cal: Calendar) -> [DayPlan] {
        func makeMeal(title: String, time: String, kcal: Int, emoji: String) -> PlannedMeal {
            PlannedMeal(
                recipe: Recipe.mock(
                    title: title,
                    calories: kcal,
                    protein: Int.random(in: 20...50),
                    carbs: Int.random(in: 20...70),
                    fat: Int.random(in: 5...30)
                ),
                title: title,
                time: time,
                kcal: kcal,
                slot: .dinner,
                emoji: emoji,
                imageURL: nil
            )
        }

        let katsu       = makeMeal(title: "Katsu Curry",                   time: "19:15", kcal: 680, emoji: "🍛")
        let honeyGarlic = makeMeal(title: "Honey Garlic Salmon + Greens",  time: "19:00", kcal: 620, emoji: "🐟")
        let pesto       = makeMeal(title: "Creamy Pesto Pasta",            time: "19:30", kcal: 710, emoji: "🍝")
        let tikka       = makeMeal(title: "Chicken Tikka Wraps",           time: "20:00", kcal: 680, emoji: "🌯")
        let burrito     = makeMeal(title: "Chipotle Chicken Burrito Bowl", time: "19:45", kcal: 730, emoji: "🌯")

        return (0..<5).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: monday)!
            switch offset {
            case 0: return DayPlan(date: d, meals: [katsu])
            case 1: return DayPlan(date: d, meals: [honeyGarlic])
            case 2: return DayPlan(date: d, meals: [pesto])
            case 3: return DayPlan(date: d, meals: [tikka])
            case 4: return DayPlan(date: d, meals: [burrito])
            default: return DayPlan(date: d, meals: [])
            }
        }
    }

    static func emptyWeek(startingAt monday: Date, calendar cal: Calendar) -> [DayPlan] {
        (0..<5).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: monday)!
            return DayPlan(date: d, meals: [])
        }
    }
}

// MARK: - Shapes

fileprivate struct TopCornersOnly: Shape {
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        let bez = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bez.cgPath)
    }
}
fileprivate struct BottomCornersOnly: Shape {
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(p.cgPath)
    }
}

// MARK: - Expanded day card (NO Cook Now footer)

fileprivate struct ExpandedDayCardContent: View {
    let dayPlan: DayPlan
    let isToday: Bool

    private var meal: PlannedMeal? { dayPlan.meals.first }
    private var dayLabel: String { dayPlan.date.formatted(.dateTime.weekday(.wide)) }
    private var dateLabel: String { dayPlan.date.formatted(Date.FormatStyle().day().month(.abbreviated)) }

    private let corner: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image("katsu")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(TopCornersOnly(radius: corner))

                LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.0)],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .clipShape(TopCornersOnly(radius: corner))

                VStack(alignment: .leading, spacing: 6) {
                    Text(meal?.title ?? "No dinner planned")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text(dayLabel)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(dateLabel.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(
                                Capsule().fill(isToday ? brandOrange.opacity(0.18) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                Capsule().stroke(isToday ? brandOrange : Color.black.opacity(0.2), lineWidth: 1.2)
                            )
                    }

                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .background(brandOrange.opacity(0.15))
                            .overlay(Capsule().stroke(brandOrange, lineWidth: 1.2))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color(.systemBackground)
                    .overlay(Rectangle().fill(Color.black.opacity(0.08)).frame(height: 0.5), alignment: .top)
            )
            .clipShape(BottomCornersOnly(radius: corner))
        }
        .background(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty card

fileprivate struct EmptyDayPlanCard: View {
    let date: Date
    let isToday: Bool

    private var dayLabel: String {
        date.formatted(.dateTime.weekday(.wide))
    }
    private var dateLabel: String {
        date.formatted(Date.FormatStyle().day().month(.abbreviated))
    }

    private let corner: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 150)

                VStack(alignment: .leading, spacing: 6) {
                    Text("No dinner planned")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                    Text("Use Scranly or the planner to fill this day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .clipShape(TopCornersOnly(radius: corner))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(dayLabel)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))

                    Text(dateLabel.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(
                            Capsule().fill(isToday ? brandOrange.opacity(0.15)
                                                   : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            Capsule().stroke(isToday ? brandOrange : Color.black.opacity(0.2),
                                             lineWidth: 1.2)
                        )

                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .background(brandOrange.opacity(0.15))
                            .overlay(Capsule().stroke(brandOrange, lineWidth: 1.2))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                Text("Tap Plan to add something here later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color(.systemBackground)
                    .overlay(Rectangle().fill(Color.black.opacity(0.08))
                                .frame(height: 0.5),
                             alignment: .top)
            )
            .clipShape(BottomCornersOnly(radius: corner))
        }
        .background(RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 3)
    }
}

// MARK: - Ask Scranly section under card

fileprivate struct AskScranlyPlanSection: View {
    let isEmptyDay: Bool
    let recipeTitle: String?

    private var prompts: [String] {
        if isEmptyDay {
            return [
                "Fill this day for me",
                "Plan a 15-minute dinner",
                "Use up what I already have",
                "Plan the rest of my week"
            ]
        } else {
            return [
                "Make this lighter",
                "Swap to veggie version",
                "Double for leftovers",
                "Speed this up"
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(brandOrange)
                Text("Ask Scranly")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }

            Text(isEmptyDay
                 ? "Not sure what to cook? Let Scranly fill this day or even your whole week."
                 : "Want to tweak \(recipeTitle ?? "this dinner")? Ask Scranly to adjust it for you.")
            .font(.caption)
            .foregroundStyle(.secondary)

            WrapPrompts(prompts: prompts)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.12), lineWidth: 1.2)
        )
    }
}

// MARK: - Simple wrapping layout for prompt chips

fileprivate struct WrapPrompts: View {
    let prompts: [String]

    var body: some View {
        WrappingHStack(spacing: 8) {
            ForEach(prompts, id: \.self) { prompt in
                Button {
                    // hook up to real chat later
                } label: {
                    Text(prompt)
                        .font(.caption.weight(.heavy))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(.systemBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Public, tiny wrapping HStack layout that doesn't use any private APIs.
fileprivate struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: nil, height: nil))

            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                maxRowWidth = max(maxRowWidth, rowWidth)
                totalHeight += rowHeight + lineSpacing
                rowWidth = 0
                rowHeight = 0
            }

            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        maxRowWidth = max(maxRowWidth, rowWidth)
        totalHeight += rowHeight

        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = bounds.width

        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: nil, height: nil))

            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - PlanView (day-only)

struct PlanView: View {
    @StateObject private var vm = WeekPlanViewModel()
    @State private var path = NavigationPath()

    @State private var selectedDayIndex: Int = 0

    private var days: [DayPlan] { vm.workWeek }

    private var todayIndex: Int? {
        days.firstIndex(where: { Calendar.current.isDateInToday($0.date) })
    }

    private var selectedDay: DayPlan? {
        guard days.indices.contains(selectedDayIndex) else { return nil }
        return days[selectedDayIndex]
    }

    private var selectedDayIsToday: Bool {
        guard let d = selectedDay?.date else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var selectedDayWeekdayText: String {
        selectedDay?.date.formatted(.dateTime.weekday(.wide)) ?? ""
    }

    private var selectedDayDateLine: String {
        selectedDay?.date.formatted(Date.FormatStyle().day().month(.abbreviated)) ?? ""
    }

    private var selectedMealEmoji: String {
        selectedDay?.meals.first?.emoji ?? "🍽️"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {

                            if days.isEmpty {
                                VStack(spacing: 10) {
                                    Text("No dinners planned yet.")
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                    Text("Head to Scranly or the planner to fill your week.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                            } else if let selectedDay {
                                // Header: emoji + weekday + TODAY + date, with chevrons
                                HStack(alignment: .center, spacing: 10) {

                                    Button {
                                        if selectedDayIndex > 0 {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                selectedDayIndex -= 1
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.body.weight(.heavy))
                                            .frame(width: 32, height: 32)
                                    }
                                    .buttonStyle(WeekNavButtonStyle())
                                    .disabled(selectedDayIndex == 0)
                                    .opacity(selectedDayIndex == 0 ? 0.4 : 1.0)

                                    VStack(spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(selectedMealEmoji)
                                                .font(.system(size: 22))

                                            Text(selectedDayWeekdayText)
                                                .font(.system(size: 16, weight: .heavy, design: .rounded))

                                            if selectedDayIsToday {
                                                Text("TODAY")
                                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                                    .padding(.vertical, 2)
                                                    .padding(.horizontal, 6)
                                                    .background(brandOrange.opacity(0.15))
                                                    .overlay(
                                                        Capsule().stroke(brandOrange, lineWidth: 1.2)
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        Text(selectedDayDateLine)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)

                                    Button {
                                        if selectedDayIndex < days.count - 1 {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                selectedDayIndex += 1
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .font(.body.weight(.heavy))
                                            .frame(width: 32, height: 32)
                                    }
                                    .buttonStyle(WeekNavButtonStyle())
                                    .disabled(selectedDayIndex >= days.count - 1)
                                    .opacity(selectedDayIndex >= days.count - 1 ? 0.4 : 1.0)
                                }
                                .padding(.horizontal, 16)

                                let isToday = selectedDayIsToday
                                let recipe = selectedDay.meals.first?.recipe

                                if let recipe {
                                    NavigationLink(value: recipe) {
                                        ExpandedDayCardContent(dayPlan: selectedDay, isToday: isToday)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)

                                    // Tagline under the meal card
                                    Text(quoteForMeal(recipe.title))
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineSpacing(2)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 6)

                                    // Ask Scranly section
                                    AskScranlyPlanSection(
                                        isEmptyDay: false,
                                        recipeTitle: recipe.title
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)

                                } else {
                                    EmptyDayPlanCard(date: selectedDay.date, isToday: isToday)
                                        .padding(.horizontal, 16)

                                    Text(quoteForMeal(nil))
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineSpacing(2)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 6)

                                    AskScranlyPlanSection(
                                        isEmptyDay: true,
                                        recipeTitle: nil
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                }
                            }

                            Spacer(minLength: 16)
                        }
                        .padding(.vertical, 8)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
            .onAppear {
                resetSelectionToTodayOrFirst()
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(meal: recipe)
            }
        }
    }

    private func resetSelectionToTodayOrFirst() {
        let defaultIndex = todayIndex ?? 0
        if days.indices.contains(defaultIndex) {
            selectedDayIndex = defaultIndex
        } else {
            selectedDayIndex = days.indices.isEmpty ? 0 : days.startIndex
        }
    }
}

// Reuse your existing WeekNavButtonStyle
fileprivate struct WeekNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PlanView()
        }
        .preferredColorScheme(.light)
    }
}
