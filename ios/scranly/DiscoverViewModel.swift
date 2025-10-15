import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []      // feeds chips/catalogue/search
    @Published var swipeDeck: [Recipe] = []    // feeds swipe (Tinder) stack
    @Published var liked: [Recipe] = []        // shortlist
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canUndo = false

    private let api = APIClient()
    private var lastOp: (item: Recipe, liked: Bool)?

    func load() async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            async let list = api.fetchRecipes(limit: 200)
            async let deck = api.fetchDeck(limit: 40)
            recipes  = try await list
            swipeDeck = try await deck
            liked.removeAll(); lastOp = nil; canUndo = false

            // 🔎 quick proof
            print("VM ✅ loaded recipes=\(recipes.count), deck=\(swipeDeck.count)")
            if let first = recipes.first {
                print("VM first recipe:", first.id, first.title, first.imageURL as Any)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("VM ❌ load error:", error)
        }
    }

    func resetDeck() async {
        do {
            swipeDeck = try await api.fetchDeck(limit: 40)
            liked.removeAll(); lastOp = nil; canUndo = false
        } catch { errorMessage = error.localizedDescription }
    }

    func registerSwipe(_ item: Recipe, likedRight: Bool) {
        if likedRight { liked.append(item) }
        lastOp = (item, likedRight)
        canUndo = true
    }

    func undoLast() {
        guard let last = lastOp else { return }
        if last.liked, let i = liked.lastIndex(of: last.item) { liked.remove(at: i) }
        swipeDeck.append(last.item)
        lastOp = nil
        canUndo = false
    }
}
