import Foundation

// MARK: - UI models the view actually renders

/// Lightweight model consumed by cards/day page (image/title/time etc.).
/// This stays stable even if the backend shape changes.
struct PlannedMeal: Identifiable, Hashable {
    var recipe: Recipe?     // you can stub Recipe? as nil in demo
    let id = UUID()

    var title: String
    var time: String        // "HH:mm"
    var kcal: Int
    var slot: MealSlot      // e.g. .dinner
    var emoji: String
    var imageURL: URL?
}



struct DayPlan: Identifiable, Hashable {
    var id: Date { date }        // stable identity = actual calendar day
    let date: Date
    let meals: [PlannedMeal]

    /// right now we only surface "the" meal (dinner) in the card
    var primaryMeal: PlannedMeal? {
        // prefer dinner if there is one, else first meal
        if let dinner = meals.first(where: { $0.slot == .dinner }) {
            return dinner
        }
        return meals.first
    }
}


// super lightweight so we can compile without pulling in real Recipe yet

// MARK: - Shared helpers

/// Convert "HH:mm" to minutes since midnight for sorting & "Up next".
func timeToMinutes(_ hhmm: String) -> Int {
    let p = hhmm.split(separator: ":")
    guard p.count == 2, let h = Int(p[0]), let m = Int(p[1]) else { return 0 }
    return h * 60 + m
}

// MARK: - DTOs (backend → app VM). These never leak to the View.

struct PlanSummaryDTO: Decodable {
    let id: Int
    let startDate: String     // "yyyy-MM-dd"
    let endDate: String       // "yyyy-MM-dd"

    enum CodingKeys: String, CodingKey {
        case id
        case startDate = "start_date"
        case endDate   = "end_date"
    }
}

struct PlanDTO: Decodable {
    let id: Int
    let startDate: String     // "yyyy-MM-dd"
    let endDate: String       // "yyyy-MM-dd"
    let days: [PlanDayDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case startDate = "start_date"
        case endDate   = "end_date"
        case days
    }
}

struct PlanDayDTO: Decodable {
    let date: String                 // "yyyy-MM-dd"
    let breakfast: [PlanEventDTO]
    let lunch: [PlanEventDTO]
    let dinner: [PlanEventDTO]
}

/// One event on a day (optionally expanded with a Recipe).
/// NOTE: we reuse your existing `Recipe` model from Discover, so images/titles “just work”.
struct PlanEventDTO: Decodable {
    let id: String
    let mealId: String?
    let time: String?
    let recipe: Recipe?          // <- your existing model

    enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case time
        case recipe
    }

    /// Be lenient: id/meal_id may come as String or Int.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            id = String(i)
        } else {
            id = UUID().uuidString
        }

        // meal_id
        if let s = try? c.decode(String.self, forKey: .mealId) {
            mealId = s
        } else if let i = try? c.decode(Int.self, forKey: .mealId) {
            mealId = String(i)
        } else {
            mealId = nil
        }

        time   = try? c.decode(String.self, forKey: .time)
        recipe = try? c.decode(Recipe.self, forKey: .recipe)
    }
}

// MARK: - Mapping (DTO → UI model)

extension PlanEventDTO {
    /// Map a backend event into a renderable `PlannedMeal` for the given slot.
    func toPlannedMeal(slot: MealSlot) -> PlannedMeal {
        // Slot defaults (used when `time` is nil)
        let defaults: [MealSlot: String] = [.breakfast:"08:00", .lunch:"12:30", .dinner:"19:00"]
        // Friendly emoji fallback (no local assets)
        let emoji: String = {
            switch slot {
            case .breakfast: return "🥣"
            case .lunch:     return "🥪"
            case .dinner:    return "🍛"
                
            case .snack:     return "🍫"
            }
        }()

        return PlannedMeal(
            title:   recipe?.title ?? "Meal",
            time:    time ?? defaults[slot] ?? "00:00",
            kcal:    recipe?.calories ?? 0,
            slot:    slot,
            emoji:   emoji,
            imageURL: recipe?.imageURL
        )
    }
}
