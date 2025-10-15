import Foundation

// /v1/plans list item
struct PlanSummary: Identifiable, Decodable, Hashable {
    let id: Int
    let userId: String
    let startDate: String
    let endDate: String
    let lengthDays: Int
    let createdAt: String?
}

// Event inside a day (supports expanded plans: recipe is optional)
struct PlanEvent: Identifiable, Decodable, Hashable {
    let id: String              // "{planId}|{date}|{slot}|{index}"
    let mealId: String
    let time: String?
    let recipe: Recipe?         // present when expand=true
}

struct PlanDay: Decodable, Hashable {
    let date: String
    let breakfast: [PlanEvent]
    let lunch: [PlanEvent]
    let dinner: [PlanEvent]
}

// Full plan payload from /v1/plans/{id} and /v1/plans/current
struct Plan: Identifiable, Decodable, Hashable {
    let id: Int
    let userId: String
    let startDate: String
    let endDate: String
    let lengthDays: Int
    let days: [PlanDay]
}
