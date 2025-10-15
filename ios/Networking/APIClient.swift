import Foundation

enum APIError: Error, LocalizedError {
    case url(String)
    case http(Int, Data?)
    case decoding(Error)
    case network(URLError)

    var errorDescription: String? {
        switch self {
        case .url(let s):          return "Bad URL: \(s)"
        case .http(let c, _):      return "Server responded with \(c)"
        case .decoding(let e):     return "Couldn’t read server data (\(e.localizedDescription))"
        case .network(let e):      return "Network error (\(e.localizedDescription))"
        }
    }
}

struct PageOut<T: Decodable>: Decodable {
    let data: [T]
    let page: Int
    let totalPages: Int

    private enum CodingKeys: String, CodingKey {
        case data, page
        case totalPages = "total_pages"
    }
}


struct APIClient {
    static let shared = APIClient()
    /// change this if your server differs
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    // ---------- generic helpers ----------
    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        #if DEBUG
        print("GET \(path) ✅ \(data.count) bytes")
        #endif
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// POST expecting a response body
    func post<T: Encodable, U: Decodable>(_ path: String, body: T) async throws -> U {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        #if DEBUG
        print("POST \(path) ✅ \(data.count) bytes")
        #endif
        return try JSONDecoder().decode(U.self, from: data)
    }

    /// POST when you don’t care about the response body (204/200)
    func post<T: Encodable>(_ path: String, body: T) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        #if DEBUG
        print("POST \(path) ✅")
        #endif
    }
}

extension APIClient {

    // Compact, opt-in debug logging
    #if DEBUG
    private func debugLogRecipes(_ whereFrom: String, _ recipes: [Recipe]) {
        print("🍽️ \(whereFrom): count=\(recipes.count)")
        for r in recipes.prefix(8) {
            print("  – [\(r.id)] \(r.title)  img=\(r.imageURL?.absoluteString ?? "nil")")
        }
    }
    #endif

    func fetchRecipes(limit: Int = 200, page: Int = 1) async throws -> [Recipe] {
        let q = [URLQueryItem(name: "limit", value: "\(limit)"),
                 URLQueryItem(name: "page",  value: "\(page)")]
        let pageOut: PageOut<Recipe> = try await get("v1/recipes", query: q)
        return pageOut.data
    }

    func fetchDeck(limit: Int = 40) async throws -> [Recipe] {
        let items: [Recipe] = try await get(
            "v1/recipes/deck",
            query: [.init(name: "limit", value: "\(limit)")]
        )
        #if DEBUG
        debugLogRecipes("/v1/recipes/deck", items)
        #endif
        return items
    }
}



// MARK: - Plans API
// Drop this in the same file as your APIClient, below the existing extension.


extension APIClient {
    func fetchPlanSummaries(userId: String, limit: Int = 20) async throws -> [PlanSummaryDTO] {
        try await get("v1/plans", query: [
            .init(name: "user_id", value: userId),
            .init(name: "limit", value: "\(limit)")
        ])
    }

    func fetchCurrentPlan(userId: String, asOf: String? = nil, expand: Bool = true) async throws -> PlanDTO {
        var items: [URLQueryItem] = [
            .init(name: "user_id", value: userId),
            .init(name: "expand",  value: expand ? "true" : "false")
        ]
        if let asOf { items.append(.init(name: "as_of", value: asOf)) }
        return try await get("v1/plans/current", query: items)
    }

    func fetchPlan(planId: Int, expand: Bool = true) async throws -> PlanDTO {
        try await get("v1/plans/\(planId)", query: [
            .init(name: "expand", value: expand ? "true" : "false")
        ])
    }
}




extension APIClient {
    // POST /v1/basket/rebuild?user_id=&week_start=
    @discardableResult
    func rebuildBasket(userId: String, weekStart: String) async throws -> BasketDTO {
        // send POST (we’ll reuse the post<T>(_:) that returns Decodable)
        struct Empty: Encodable {}
        var items = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "week_start", value: weekStart)
        ]
        // Build URL manually because our post(_:body:) doesn’t add query items
        var comps = URLComponents(url: baseURL.appendingPathComponent("v1/basket/rebuild"), resolvingAgainstBaseURL: false)!
        comps.queryItems = items
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Empty())

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        #if DEBUG
        print("POST v1/basket/rebuild ✅ \(data.count) bytes")
        #endif
        return try JSONDecoder().decode(BasketDTO.self, from: data)
    }
}




struct BasketDTO: Decodable {
    struct Estimate: Decodable {
        let pricePerPack: Double
        let packAmount: Double
        let packUnit: String
        let sizeLabel: String

        private enum CodingKeys: String, CodingKey {
            case pricePerPack = "price_per_pack"
            case packAmount   = "pack_amount"
            case packUnit     = "pack_unit"
            case sizeLabel    = "size_label"
        }
    }
    struct Item: Decodable, Identifiable {
        var id: String { name + (estimate.sizeLabel) } // stable enough for list
        let name: String
        let aisle: String
        let emoji: String
        let needAmount: Double
        let needUnit: String
        let estimate: Estimate

        private enum CodingKeys: String, CodingKey {
            case name, aisle, emoji
            case needAmount = "need_amount"
            case needUnit   = "need_unit"
            case estimate
        }
    }
    let userId: String
    let weekStart: String
    let sourcePlanId: Int?
    let items: [Item]
    let estimatedTotal: Double
    let persisted: Bool?

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weekStart = "week_start"
        case sourcePlanId = "source_plan_id"
        case items
        case estimatedTotal = "estimated_total"
        case persisted
    }
}

extension APIClient {
    func fetchBasket(userId: String, weekStart: String? = nil) async throws -> BasketDTO {
        var q = [URLQueryItem(name: "user_id", value: userId)]
        if let weekStart { q.append(.init(name: "week_start", value: weekStart)) }
        let dto: BasketDTO = try await get("v1/basket", query: q)
        #if DEBUG
        print("🧺 basket items=\(dto.items.count) total=\(dto.estimatedTotal) persisted=\(dto.persisted ?? false)")
        for it in dto.items.prefix(6) {
            print("  – \(it.emoji) \(it.name)  \(Int(it.needAmount))\(it.needUnit)  ~£\(it.estimate.pricePerPack) / \(it.estimate.sizeLabel)")
        }
        #endif
        return dto
    }
}

// MARK: - DTOs (mirror the API)

struct TrackEntryDTO: Codable, Identifiable {
    var id: String { "\(user_id)|\(date)" }
    let user_id: String
    let date: String           // "YYYY-MM-DD"
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
}

struct AddTrackRequest: Encodable {
    let user_id: String
    let date: String           // "YYYY-MM-DD"
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
}

// MARK: - Endpoints

extension APIClient {
    /// GET /v1/track?user_id=&days=
    func fetchTrack(userId: String, days: Int = 7) async throws -> [TrackEntryDTO] {
        try await get("v1/track", query: [
            .init(name: "user_id", value: userId),
            .init(name: "days", value: String(days))
        ])
    }

    /// POST /v1/track  (upsert a day) – returns the saved row
    @discardableResult
    func addTrack(_ body: AddTrackRequest) async throws -> TrackEntryDTO {
        try await post("v1/track", body: body)
    }
}

public struct StatsSummaryDTO: Decodable {
    public let user_id: String
    public let meals_cooked: Int
    public let money_saved: Double
    public let time_saved_min: Int
    public let calories_avg_7d: Double?
    public let protein_avg_7d: Double?
}


public struct HomePlanDTO: Decodable {
    public struct Recipe: Decodable { public let title: String; public let calories: Int? }
    public struct Event: Decodable { public let time: String?; public let recipe: Recipe? }
    public struct Day: Decodable { public let date: String; public let breakfast: [Event]; public let lunch: [Event]; public let dinner: [Event] }
    public let id: Int
    public let user_id: String
    public let start_date: String
    public let end_date: String
    public let length_days: Int
    public let days: [Day]
}

extension APIClient {
    /// GET /v1/stats/summary?user_id=
    func fetchStatsSummary(userId: String) async throws -> StatsSummaryDTO {
        try await get("v1/stats/summary", query: [.init(name: "user_id", value: userId)])
    }

    /// GET /v1/plans/current?user_id=&expand=true (lite shape for Home)
    func fetchCurrentPlanLite(userId: String) async throws -> HomePlanDTO {
        try await get("v1/plans/current", query: [
            .init(name: "user_id", value: userId),
            .init(name: "expand", value: "true")
        ])
    }
}

// Simple basket summary we already get from /v1/basket
struct BasketSummary: Decodable {
    let user_id: String
    let week_start: String
    let source_plan_id: Int?
    let items: [BasketDTO.Item]
    let estimated_total: Double
    let persisted: Bool?
}

// Lightweight helpers (reusing your existing API)
extension APIClient {

    /// GET the current plan with recipes expanded so we can render "next meal".
    func fetchCurrentPlanExpanded(userId: String, asOf: String? = nil) async throws -> PlanDTO {
        try await fetchCurrentPlan(userId: userId, asOf: asOf, expand: true)
    }

    /// GET last 7 days of track (you already have this).
    func fetchTrack7(userId: String) async throws -> [TrackEntryDTO] {
        try await fetchTrack(userId: userId, days: 7)
    }

    /// GET basket for this week (to show count/£ on Home).
    func fetchBasketSummary(userId: String, weekStartISO: String) async throws -> BasketSummary {
        try await get("v1/basket", query: [
            .init(name: "user_id", value: userId),
            .init(name: "week_start", value: weekStartISO)
        ])
    }
}

// MARK: - Image DTO

struct ImageOnlyDTO: Decodable {
    let image_url: String?
}

extension APIClient {
    /// GET /v1/recipes/{id}/image → returns { "image_url": "..." }
    func fetchRecipeImage(mealId: String) async throws -> URL? {
        // Build URL
        let path = "v1/recipes/\(mealId)/image"

        // Reuse your existing generic GET helper
        let dto: ImageOnlyDTO = try await get(path)

        // Parse + safely return
        guard let s = dto.image_url, !s.isEmpty else { return nil }
        // Allow fallback in case of spaces etc.
        return URL(string: s) ?? URL(string: s.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
    }
}
