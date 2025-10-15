import Foundation

struct Recipe: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let desc: String

    // Maps from JSON `image_url` via convertFromSnakeCase -> imageUrlString
    private let imageUrlString: String?
    var imageURL: URL? {
        guard let s = imageUrlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty
        else { return nil }
        return URL(string: s) ?? URL(string: s.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
    }

    // Maps from `time_minutes`
    let timeMinutes: Int

    let calories: Int

    // JSON has protein_g / carbs_g / fat_g → Swift needs proteinG / carbsG / fatG
    private let proteinG: Int
    private let carbsG: Int
    private let fatG: Int

    // Keep your existing call sites working:
    var protein: Int { proteinG }
    var carbs: Int { carbsG }
    var fat: Int { fatG }

    let tags: [String]

    // sub_cuisine → subCuisine, meal_type → mealType
    let cuisine: String?
    let subCuisine: String?
    let diet: String?
    let mealType: String?
    let difficulty: String?
    let allergens: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, title, desc, tags, cuisine, diet, difficulty, allergens, calories

        // snake_case → your properties
        case imageUrlString = "image_url"
        case timeMinutes    = "time_minutes"
        case proteinG       = "protein_g"
        case carbsG         = "carbs_g"
        case fatG           = "fat_g"
        case subCuisine     = "sub_cuisine"
        case mealType       = "meal_type"
    }
}
