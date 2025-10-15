import Foundation

@MainActor
final class PlanViewModel: ObservableObject {
    // MARK: - API-backed state
    @Published var summaries: [PlanSummaryDTO] = []
    @Published var current: PlanDTO? { didSet { rebuildIndex() } }
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Visible week (Sunday → Saturday)
    @Published var selectedWeekStart: Date

    // MARK: - Lookups built from `current`
    private var dayIndex: [String: PlanDayDTO] = [:]           // "yyyy-MM-dd" -> day
    private var recipeByMealId: [String: Recipe] = [:]

    private let api = APIClient()

    // MARK: - Calendars & formatters
    private static let weekCalStatic: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1                  // 1 = Sunday
        c.minimumDaysInFirstWeek = 1
        return c
    }()
    private var weekCal: Calendar { Self.weekCalStatic }

    private let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let prettyDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "d MMM"
        return f
    }()

    // MARK: - Init
    init() {
        let today = Date()
        self.selectedWeekStart = PlanViewModel.sundayOfWeek(containing: today, calendar: PlanViewModel.weekCalStatic)
    }

    // Sunday that contains a given date (using our Sunday-first calendar)
    private static func sundayOfWeek(containing date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start) // 1..7 (Sun..Sat)
        return calendar.date(byAdding: .day, value: -(weekday - 1), to: start)!
    }

    // MARK: - Loading
    /// Loads summaries and the most recent plan (expanded so cards have images/titles).
    func load(userId: String) async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            let s = try await api.fetchPlanSummaries(userId: userId, limit: 40)
            // Sort summaries by start desc (newest first) in case API doesn't
            self.summaries = s.sorted {
                guard let a = isoDay.date(from: $0.startDate),
                      let b = isoDay.date(from: $1.startDate) else { return false }
                return a > b
            }

            if let latest = summaries.first {
                self.current = try await api.fetchPlan(planId: latest.id, expand: true)
            } else {
                self.current = nil
            }

            // Ensure the plan covers the initially visible (this) week; if not, swap.
            await ensurePlanForVisibleWeek()

            #if DEBUG
            print("🗓️ summaries=\(summaries.count)  current.days=\(current?.days.count ?? 0)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ PlanViewModel.load error:", error)
            #endif
        }
    }

    // MARK: - Indexing
    /// Build quick lookups whenever `current` changes.
    
    private func rebuildIndex() {
        dayIndex.removeAll()
        recipeByMealId.removeAll()
        guard let plan = current else { return }

        for d in plan.days {
            dayIndex[d.date] = d
            for e in d.breakfast { if let r = e.recipe, let id = e.mealId { recipeByMealId[id] = r } }
            for e in d.lunch     { if let r = e.recipe, let id = e.mealId { recipeByMealId[id] = r } }
            for e in d.dinner    { if let r = e.recipe, let id = e.mealId { recipeByMealId[id] = r } }
        }
    }

    func recipe(forMealId id: String) -> Recipe? { recipeByMealId[id] }
    // MARK: - Week paging
    /// Move the visible week by ±N weeks and load a covering plan if needed.
    func shiftWeek(by deltaWeeks: Int) async {
        selectedWeekStart = weekCal.date(byAdding: .day, value: deltaWeeks * 7, to: selectedWeekStart)!
        await ensurePlanForVisibleWeek()
    }

    /// Ensure the loaded plan overlaps the currently visible week; if not, load the matching one (if any).
    private func ensurePlanForVisibleWeek() async {
        guard let (wStart, wEnd) = visibleWeekRange() else { return }

        if let cur = current, plan(cur, overlaps: (wStart...wEnd)) {
            return
        }

        if let hit = summaries.first(where: { summary in
            guard let ps = isoDay.date(from: summary.startDate),
                  let pe = isoDay.date(from: summary.endDate) else { return false }
            return rangesOverlap((ps...pe), (wStart...wEnd))
        }) {
            do {
                self.current = try await api.fetchPlan(planId: hit.id, expand: true)
            } catch {
                #if DEBUG
                print("⚠️ Failed to fetch plan \(hit.id) for visible week:", error)
                #endif
            }
        } else {
            // No plan for that week → show empty days
            self.current = nil
        }
    }

    private func visibleWeekRange() -> (Date, Date)? {
        let start = selectedWeekStart
        guard let end = weekCal.date(byAdding: .day, value: 6, to: start) else { return nil }
        return (weekCal.startOfDay(for: start), weekCal.startOfDay(for: end))
    }

    private func plan(_ plan: PlanDTO, overlaps week: ClosedRange<Date>) -> Bool {
        guard let ps = isoDay.date(from: plan.startDate),
              let pe = isoDay.date(from: plan.endDate) else { return false }
        return rangesOverlap((ps...pe), week)
    }

    private func rangesOverlap(_ a: ClosedRange<Date>, _ b: ClosedRange<Date>) -> Bool {
        a.lowerBound <= b.upperBound && b.lowerBound <= a.upperBound
    }

    // MARK: - Data for PlanView
    /// Always returns the 7 chip dates for the **currently visible** week (Sun→Sat), even if there are no meals.
    func dayDates() -> [Date] {
        let start = selectedWeekStart
        return (0..<7).compactMap { weekCal.date(byAdding: .day, value: $0, to: start) }
    }

    /// "2 Oct – 8 Oct" for the visible week header.
    var weekRangeLabel: String {
        let days = dayDates()
        guard let first = days.first, let last = days.last else { return "" }
        return "\(prettyDay.string(from: first)) – \(prettyDay.string(from: last))"
    }

    /// Raw groups (B/L/D) for a given chip date. Returns empty groups if no data.
    func events(on date: Date) -> (breakfast: [PlanEventDTO], lunch: [PlanEventDTO], dinner: [PlanEventDTO]) {
        let key = isoDay.string(from: date)
        guard let day = dayIndex[key] else { return ([], [], []) }
        return (day.breakfast, day.lunch, day.dinner)
    }

    /// UI-friendly flattened list for the given date, sorted by time. Falls back when data is partial.
    func uiMeals(on date: Date) -> [PlannedMeal] {
        let slots = events(on: date)
        let defaults: [MealSlot: String] = [.breakfast:"08:00", .lunch:"12:30", .dinner:"19:00"]

        func map(_ e: PlanEventDTO, slot: MealSlot) -> PlannedMeal {
            PlannedMeal(
                recipe:   e.recipe,              // <- include the real recipe
                title:    e.recipe?.title ?? "Meal",
                time:     e.time ?? defaults[slot] ?? "00:00",
                kcal:     e.recipe?.calories ?? 0,
                slot:     slot,
                emoji:    (slot == .breakfast ? "🥣" : slot == .lunch ? "🥪" : "🍛"),
                imageURL: e.recipe?.imageURL
            )
        }

        let b = slots.breakfast.map { map($0, slot: .breakfast) }
        let l = slots.lunch.map     { map($0, slot: .lunch) }
        let d = slots.dinner.map    { map($0, slot: .dinner) }
        return (b + l + d).sorted { timeToMinutes($0.time) < timeToMinutes($1.time) }
    }
    
    
    

    // MARK: - Local helper (kept here so VM doesn't depend on a global)
    private func minutes(from hhmm: String) -> Int {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
        return h * 60 + m
    }
}
