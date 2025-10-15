//import Foundation
//
//@MainActor
//final class HomeViewModel: ObservableObject {
//    @Published var kpis: [KPI] = []          // feeds your KPIGrid
//    @Published var isLoading = false
//    @Published var error: String?
//
//    private let api = APIClient.shared
//    private let userId: String
//
//    init(userId: String) {
//        self.userId = userId
//    }
//
//    func load() async {
//        guard !isLoading else { return }
//        isLoading = true; error = nil
//        defer { isLoading = false }
//
//        do {
//            let s = try await api.fetchStatsSummary(userId: userId)
//
//            // Formatters
//            let money = "£" + String(format: "%.2f", s.money_saved)
//
//            // Convert minutes → h m (e.g. "11h 07m")
//            let hours = s.time_saved_min / 60
//            let mins  = s.time_saved_min % 60
//            let timeSaved = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
//
//            // Optional avgs
//            let kcalAvg = s.calories_avg_7d.map { Int($0.rounded()) }
//            let proteinAvg = s.protein_avg_7d.map { Int($0.rounded()) }
//
//            var out: [KPI] = []
//            out.append(.init(icon: "sterlingsign.circle.fill", value: money,   label: "Money Saved",  tint: .green))
//            out.append(.init(icon: "clock.badge.checkmark",    value: timeSaved, label: "Time Saved", tint: .purple))
//            out.append(.init(icon: "fork.knife",               value: "\(s.meals_cooked)", label: "Meals Planned", tint: .blue))
//
//            if let kcalAvg { out.append(.init(icon: "flame.fill", value: "\(kcalAvg) kcal", label: "Avg / day", tint: .orange)) }
//            if let proteinAvg { out.append(.init(icon: "bolt.fill", value: "\(proteinAvg) g", label: "Protein / day", tint: .pink)) }
//
//            self.kpis = out
//        } catch {
//            self.error = error.localizedDescription
//            #if DEBUG
//            print("❌ HomeViewModel.load:", error)
//            #endif
//        }
//    }
//}
import Foundation

//final class HomeViewModel: ObservableObject {
//    @Published var stats: StatsSummaryDTO?
//    @Published var plan: PlanDTO?
//    @Published var isLoading = false
//    @Published var error: String?
//
//    // Derived UI state
//    @Published var weekChips: [HomeWeekChip] = []
//    @Published var upNext: HomeUpNext?
//
//    private let api = APIClient.shared
//    private let userId: String
//
//    init(userId: String) {
//        self.userId = userId
//    }
//
//    func load() async {
//        guard !isLoading else { return }
//        isLoading = true; error = nil
//        defer { isLoading = false }
//
//        do {
//            async let s: StatsSummaryDTO = api.fetchStatsSummary(userId: userId)
//            async let p: PlanDTO = api.fetchCurrentPlan(userId: userId, asOf: nil, expand: true)
//
//            let (stats, plan) = try await (s, p)
//            self.stats = stats
//            self.plan = plan
//
//            self.weekChips = Self.buildWeekChips(from: plan)
//            self.upNext = Self.findUpNext(from: plan)
//        } catch {
//            self.error = error.localizedDescription
//        }
//    }
//
//    // MARK: - Helpers
//
//    struct HomeWeekChip: Identifiable, Hashable {
//        let id = UUID()
//        let date: String   // ISO day yyyy-MM-dd
//        let label: String  // e.g. “Mon”
//        let mealsCount: Int
//    }
//
//    struct HomeUpNext {
//        let title: String
//        let meta: String   // “Lunch • 12:30 • 612 kcal”
//        let imageURL: String?
//    }
//
//    private static func buildWeekChips(from plan: PlanDTO) -> [HomeWeekChip] {
//        let dfIn = Self.isoDayFormatter
//        let dfOut = DateFormatter()
//        dfOut.dateFormat = "EEE" // Mon/Tue…
//
//        return plan.days.compactMap { d in
//            let meals = d.breakfast.count + d.lunch.count + d.dinner.count
//            guard let date = dfIn.date(from: d.date) else {
//                return HomeWeekChip(date: d.date, label: d.date, mealsCount: meals)
//            }
//            return HomeWeekChip(date: d.date, label: dfOut.string(from: date), mealsCount: meals)
//        }
//    }
//
//    // MARK: - Up-next builder
//
//    private static func defaultTime(for slotName: String) -> String {
//        switch slotName {
//        case "breakfast": return "08:00"
//        case "lunch":     return "12:30"
//        case "dinner":    return "19:00"
//        default:          return "—"
//        }
//    }
//
//    /// Build a HomeUpNext from a single planned event
//    private static func pick(_ ev: PlanEventDTO?, dayISO: String, slotName: String) -> HomeUpNext? {
//        guard let ev, let r = ev.recipe else { return nil }
//
//        let timeText = ev.time ?? defaultTime(for: slotName)
//        // Use the computed URL from your Recipe model
//        let imageStr: String? = r.imageURL?.absoluteString
//
//        return HomeUpNext(
//            title: r.title,
//            meta: "\(slotName.capitalized) • \(timeText) • \(r.calories) kcal",
//            imageURL: imageStr
//        )
//    }
//
//    /// Choose the best upcoming meal from a plan (today’s first, else next future day; fallback to any)
//    private static func findUpNext(from plan: PlanDTO) -> HomeUpNext? {
//        let dfIn = Self.isoDayFormatter
//        let now = Date()
//
//        // 1) Prefer today (first slot that exists), else the next future day
//        for d in plan.days {
//            guard let date = dfIn.date(from: d.date) else { continue }
//            let isToday = Calendar.current.isDateInToday(date)
//
//            let slots: [(String, [PlanEventDTO])] = [
//                ("breakfast", d.breakfast),
//                ("lunch",     d.lunch),
//                ("dinner",    d.dinner)
//            ]
//
//            for (slotName, events) in slots {
//                let first = events.first
//                if isToday {
//                    if let candidate = pick(first, dayISO: d.date, slotName: slotName) {
//                        return candidate
//                    }
//                } else if date > now {
//                    if let candidate = pick(first, dayISO: d.date, slotName: slotName) {
//                        return candidate
//                    }
//                }
//            }
//        }
//
//        // 2) Fallback: first available anywhere in the plan
//        for d in plan.days {
//            if let first = d.breakfast.first ?? d.lunch.first ?? d.dinner.first,
//               let r = first.recipe {
//                let imageStr: String? = r.imageURL?.absoluteString
//                return HomeUpNext(
//                    title: r.title,
//                    meta: "Planned • \(r.calories) kcal",
//                    imageURL: imageStr
//                )
//            }
//        }
//        return nil
//    }
//
//    // Shared ISO day formatter (yyyy-MM-dd, UTC)
//    private static let isoDayFormatter: DateFormatter = {
//        let f = DateFormatter()
//        f.calendar = Calendar(identifier: .iso8601)
//        f.locale = Locale(identifier: "en_US_POSIX")
//        f.timeZone = TimeZone(secondsFromGMT: 0)
//        f.dateFormat = "yyyy-MM-dd"
//        return f
//    }()
//}
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var stats: StatsSummaryDTO?
    @Published var plan: PlanDTO?
    @Published var isLoading = false
    @Published var error: String?

    @Published var weekChips: [HomeWeekChip] = []
    @Published var upNext: HomeUpNext?

    private let api = APIClient.shared
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }

        do {
            async let s: StatsSummaryDTO = api.fetchStatsSummary(userId: userId)
            async let p: PlanDTO = api.fetchCurrentPlan(userId: userId, asOf: nil, expand: true)

            let (stats, plan) = try await (s, p)
            self.stats = stats
            self.plan = plan
            self.weekChips = Self.buildWeekChips(from: plan)
            self.upNext = Self.findUpNext(from: plan)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Derived Models

    struct HomeWeekChip: Identifiable, Hashable {
        let id = UUID()
        let date: String   // yyyy-MM-dd
        let label: String  // Mon/Tue…
        let mealsCount: Int
    }

    struct HomeUpNext {
        let title: String
        let meta: String   // “Lunch • 12:30 • 612 kcal”
        let imageURL: String?
    }

    private static func buildWeekChips(from plan: PlanDTO) -> [HomeWeekChip] {
        let dfIn = isoDayFormatter
        let dfOut = DateFormatter(); dfOut.dateFormat = "EEE"

        return plan.days.compactMap { d in
            let meals = d.breakfast.count + d.lunch.count + d.dinner.count
            guard let date = dfIn.date(from: d.date) else {
                return HomeWeekChip(date: d.date, label: d.date, mealsCount: meals)
            }
            return HomeWeekChip(date: d.date, label: dfOut.string(from: date), mealsCount: meals)
        }
    }

    private static func defaultTime(for slotName: String) -> String {
        switch slotName {
        case "breakfast": return "08:00"
        case "lunch":     return "12:30"
        case "dinner":    return "19:00"
        default:          return "—"
        }
    }

    private static func pick(_ ev: PlanEventDTO?, slotName: String) -> HomeUpNext? {
        guard let ev, let r = ev.recipe else { return nil }
        let timeText = ev.time ?? defaultTime(for: slotName)
        let imageStr = r.imageURL?.absoluteString   // uses your Recipe computed property
        return HomeUpNext(
            title: r.title,
            meta: "\(slotName.capitalized) • \(timeText) • \(r.calories) kcal",
            imageURL: imageStr
        )
    }

    private static func findUpNext(from plan: PlanDTO) -> HomeUpNext? {
        let dfIn = isoDayFormatter
        let now = Date()

        // Prefer today's, then next future day; breakfast -> lunch -> dinner
        for d in plan.days {
            guard let date = dfIn.date(from: d.date) else { continue }
            let slots: [(String, [PlanEventDTO])] = [("breakfast", d.breakfast), ("lunch", d.lunch), ("dinner", d.dinner)]

            for (slot, events) in slots {
                if Calendar.current.isDateInToday(date), let c = pick(events.first, slotName: slot) { return c }
                if date > now, let c = pick(events.first, slotName: slot) { return c }
            }
        }

        // Fallback: first available anywhere
        for d in plan.days {
            if let e = d.breakfast.first ?? d.lunch.first ?? d.dinner.first,
               let r = e.recipe {
                return HomeUpNext(
                    title: r.title,
                    meta: "Planned • \(r.calories) kcal",
                    imageURL: r.imageURL?.absoluteString
                )
            }
        }
        return nil
    }

    // yyyy-MM-dd UTC
    private static let isoDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
