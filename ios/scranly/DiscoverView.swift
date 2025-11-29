import SwiftUI
// One brand color declaration
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// Recipe+Stub.swift

// MARK: - Liked grid cell (2-up)
fileprivate struct LikedGridItem: View {
    let recipe: Recipe
    let added: Bool
    var onAddToNext: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Whole card (image + footer) in one rounded container
                VStack(spacing: 0) {
                    // Tap image area → detail
                    NavigationLink {
                        RecipeDetailView(meal: recipe)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            thumb(recipe)
                                .frame(height: 160)
                                .clipped()

                            LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                           startPoint: .center,
                                           endPoint: .bottom)
                                .frame(height: 90)

                            Text(recipe.title)
                                .font(.system(size: 15.5, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .shadow(radius: 2)
                                .padding(10)
                        }
                    }
                    .buttonStyle(.plain)

                    // Seamless footer row – feels part of the same card
                    Button(action: onAddToNext) {
                        HStack(spacing: 8) {
                            Image(systemName: added ? "checkmark.circle.fill" : "calendar.badge.plus")
                            Text(added ? "Added to next plan" : "Add to next plan")
                        }
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            (added ? brandOrange.opacity(0.12) : Color(.secondarySystemBackground))
                                .overlay(
                                    Rectangle()
                                        .fill(Color.black.opacity(0.06))
                                        .frame(height: 0.5),
                                    alignment: .top
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                // Subtle X in top-right
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.10), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
    }

    // Local asset first, then URL, then fallback
    @ViewBuilder private func thumb(_ r: Recipe) -> some View {
        if let asset = localAssetName(for: r.title), UIImage(named: asset) != nil {
            Image(asset).resizable().scaledToFill()
        } else if let url = r.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                case .empty: Color.gray.opacity(0.08)
                case .failure: fallbackEmoji
                @unknown default: fallbackEmoji
                }
            }
        } else {
            fallbackEmoji
        }
    }

    private var fallbackEmoji: some View {
        ZStack {
            brandOrange.opacity(0.15)
            Text("🍽️").font(.system(size: 64))
        }
    }
}
// Map recipe titles → asset names in Assets.xcassets
fileprivate func localAssetName(for title: String) -> String? {
    let t = title.lowercased()
    if t.contains("katsu") || t.contains("kastu") { return "katsu" }
    if t.contains("caesar") || t.contains("caeser") { return "caeser" }
    if t.contains("oats") || t.contains("overnight") { return "oats" }
    return nil
}

// MARK: - Liked screen
struct LikedRecipesView: View {
    @State private var query = ""

    // Only titles that map to your assets (katsu / caesar / oats)
    @State private var liked: [Recipe] = [
        .stub(title: "Katsu Chicken Curry", time: 30, kcal: 680),
        .stub(title: "Veggie Katsu", time: 22, kcal: 520),
        .stub(title: "Chicken Caesar Wrap", time: 12, kcal: 520),
        .stub(title: "Classic Caesar Salad Wrap", time: 14, kcal: 480),
        .stub(title: "Overnight Oats", time: 5, kcal: 380),
        .stub(title: "Peanut Butter Oats", time: 6, kcal: 420)
    ]

    @State private var addedToNext: Set<String> = []

    private var filtered: [Recipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return liked }
        return liked.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 12) {
                    header
                    content
                }
            }
            // Search bar “docked” at the bottom
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                }
                .background(Color(.systemBackground).ignoresSafeArea())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var header: some View {
        HStack {
            Text("Liked")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            BrandSearchField(text: $query)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch (liked.isEmpty, filtered.isEmpty) {
        case (true, _):
            emptyLiked
        case (false, true):
            emptySearch
        default:
            grid
        }
    }

    // MARK: - States

    private var emptyLiked: some View {
        VStack(spacing: 10) {
            Text("No liked recipes yet")
                .font(.system(size: 22, weight: .black, design: .rounded))
            Text("Tap ♥ on any recipe to save it here.")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }

    private var emptySearch: some View {
        VStack(spacing: 8) {
            Text("No matches")
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text("Try a different search.")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var grid: some View {
        // Be explicit to avoid the overload clash
        SwiftUI.ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(filtered, id: \.title) { r in
                    LikedGridItem(
                        recipe: r,
                        added: addedToNext.contains(r.title),
                        onAddToNext: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                _ = addedToNext.insert(r.title)   // discard (inserted: Bool, memberAfterInsert: String)
                            }
                        },
                        onRemove: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                liked.removeAll { $0.title == r.title }  // already Void
                                _ = addedToNext.remove(r.title)          // discard Optional<String>
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
    }
}



extension Recipe {
    static func stub(title: String, time: Int, kcal: Int) -> Recipe {
        Recipe.mock(
            title: title,
            desc: "Demo hardcoded recipe",
            imageURL: nil,          // keeps your 🍽️ fallback in RecipeDetailView
            timeMinutes: time,
            calories: kcal,
            protein: 30,
            carbs: 55,
            fat: 15,
            tags: ["demo"],
            cuisine: "Japanese",
            subCuisine: nil,
            diet: nil,
            mealType: "dinner",
            difficulty: "easy",
            allergens: []
        )
    }
}

// MARK: - Shop-style ingredient list (shared)
private enum RDUnit: String, CaseIterable, Hashable {
    case count, grams, milliliters
    var label: String { self == .count ? "×" : (self == .grams ? "g" : "ml") }
}

private struct RDIngredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var aisle: String
    var amount: Double
    var unit: RDUnit
    var emoji: String
    var isChecked: Bool = false
}

private enum RDIngredients {
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

    private static let order: [String] = [
        "Fruit & Veg","Meat & Fish","Dairy & Eggs","Bakery","Pantry","World & Sauces","Other"
    ]

    static func grouped(_ items: [RDIngredient]) -> [(String,[Int])] {
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

    // Sample ingredients per recipe
    static func make(for meal: Recipe) -> [RDIngredient] {
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

private struct RDRightCheckToggleStyle: ToggleStyle {
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

private struct RDRowSeparator: View {
    var body: some View {
        Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
            .padding(.leading, 44)
    }
}

private struct RDCategoryHeader: View {
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

// Meta pill under title
private struct RDMetaTag: View {
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

// Punchy, tappable method row
fileprivate struct RDMethodStepRow: View {
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

fileprivate struct BrandSearchField: View {
    @Binding var text: String
    var prompt: String = "Search liked recipes"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .tint(brandOrange)

            if !text.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
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
}

struct RecipeDetailView: View {
    let meal: Recipe

    enum Tab: String, CaseIterable, Identifiable {
        case ingredients = "Ingredients", method = "Method"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .ingredients
    @State private var completedSteps: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // HERO
                heroImage
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Title + meta
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.title)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .kerning(0.5)

                    HStack(spacing: 8) {
                        RDMetaTag(systemImage: "clock",      text: "\(meal.timeMinutes)m")
                        RDMetaTag(systemImage: "flame.fill", text: "\(meal.calories) kcal")
                        RDMetaTag(systemImage: "bolt.fill",  text: "\(meal.protein)g P")
                    }
                }

                // Description
                Text(longDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                // Segmented tabs
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                // Content
                if tab == .ingredients {
                    let data = RDIngredients.make(for: meal)
                    let grouped = RDIngredients.grouped(data)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(grouped, id: \.0) { (category, idxs) in
                            RDCategoryHeader(text: category)
                            VStack(spacing: 0) {
                                ForEach(idxs, id: \.self) { i in
                                    RDIngredientRow(item: data[i])
                                    if i != idxs.last { RDRowSeparator() }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 2)
                        }
                    }
                    .padding(.top, 4)

                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { idx, line in
                            RDMethodStepRow(
                                index: idx + 1,
                                text: line,
                                done: completedSteps.contains(idx),
                                onToggle: {
                                    if completedSteps.contains(idx) {
                                        completedSteps.remove(idx)
                                    } else {
                                        completedSteps.insert(idx)
                                    }
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
        .navigationTitle(meal.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers
    @ViewBuilder
    private var heroImage: some View {
        if let asset = localAssetName(for: meal.title), UIImage(named: asset) != nil {
            Image(asset).resizable().scaledToFill()
        } else if let url = meal.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                case .empty: Color.gray.opacity(0.08)
                case .failure: fallbackEmoji
                @unknown default: fallbackEmoji
                }
            }
        } else {
            fallbackEmoji
        }
    }

    private var fallbackEmoji: some View {
        ZStack {
            brandOrange.opacity(0.15)
            Text("🍽️").font(.system(size: 96))
        }
    }

    private var longDescription: String {
        let base = meal.desc.isEmpty ? "A bright, weeknight-friendly dish." : meal.desc
        return "\(base) Built from pantry staples with fresh add-ins — easy to tweak for whatever’s in the fridge, and scales well for leftovers."
    }

    private var steps: [String] {
        [
            "Heat pan until hot; prep everything first.",
            "Sear protein 2–3 min per side. Rest briefly.",
            "Flash aromatics 30–60s until fragrant.",
            "Toss veg 2–3 min — keep some bite.",
            "Sauce, season boldly, plate and serve."
        ]
    }
}

// MARK: - Small shared styles
struct MiniBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// Short, friendly tag line for the overlay pill
fileprivate func shortTag(for title: String) -> String {
    let t = title.lowercased()
    if t.contains("salmon") || t.contains("poke") { return "Protein • flavour • glow" }
    if t.contains("katsu")                      { return "Crispy • cosy" }
    if t.contains("pesto") || t.contains("pasta"){ return "Twirls • sauce • comfort" }
    if t.contains("wrap")                       { return "Handheld • speedy" }
    if t.contains("stir")                       { return "Fast • veg-heavy" }
    return "Good food • good plan"
}

// MARK: - Sticky Header
fileprivate struct DiscoverStickyHeader: View {
    var onLikedTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Discover")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)

                Spacer()

                Button(action: onLikedTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                        Text("Liked")
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .buttonStyle(MiniBorderButtonStyle())
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Daily Bites
struct DailyBite: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let kcal: Int
    let timeMin: Int
}

fileprivate struct DailyBitesCard: View {
    private let meals: [DailyBite] = [
        .init(title: "Katsu Curry",       subtitle: "Crispy + cosy",     imageName: "katsu", kcal: 680, timeMin: 30),
        .init(title: "Katsu Rice Bowl",   subtitle: "Weeknight quick",   imageName: "katsu", kcal: 540, timeMin: 18),
        .init(title: "Veggie Katsu",      subtitle: "Light & crunchy",   imageName: "katsu", kcal: 460, timeMin: 22),
    ]

    var onBin: (DailyBite) -> Void = { _ in }
    var onCook: (DailyBite) -> Void = { _ in }

    @State private var index: Int = 0
    private let corner: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Bites")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text("Three quick picks just for today.")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(index + 1)/\(meals.count)")
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground).opacity(0.9))
                            .overlay(Capsule().stroke(.black.opacity(0.15), lineWidth: 1))
                    )
            }
            .padding(.horizontal)

            // Card container
            VStack(spacing: 0) {
                // Each page is a NavigationLink to RecipeDetailView
                TabView(selection: $index) {
                    ForEach(meals.indices, id: \.self) { i in
                        let m = meals[i]
                        NavigationLink {
                            RecipeDetailView(meal: .stub(title: m.title, time: m.timeMin, kcal: m.kcal))
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                Image(m.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipped()

                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.38)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 120)
                                .frame(maxHeight: .infinity, alignment: .bottom)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(m.title)
                                        .font(.system(size: 18, weight: .bold, design: .serif))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 3)
                                        .lineLimit(2)
                                }
                                .padding(12)
                            }
                        }
                        .buttonStyle(.plain)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 220)

                // bin / cook row
                HStack(spacing: 0) {
                    Button { onBin(meals[index]) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Bin").font(.subheadline.weight(.heavy))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.systemGray6))
                    .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.black.opacity(0.08)), alignment: .trailing)

                    Button { onCook(meals[index]) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                            Text("Cook").font(.subheadline.weight(.heavy))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .background(brandOrange)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.black, lineWidth: 2))
            .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Recipe card
fileprivate struct RecipeTileCard: View {
    let imageName: String
    let title: String
    let timeMin: Int
    let kcal: Int
    var onCook: () -> Void = {}
    var onRemove: () -> Void = {}

    private let corner: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 180)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: 220, height: 180)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16.5, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)
            }
            .padding(10)
        }
        .frame(width: 220, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))
                }
                Button(action: onCook) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(brandOrange)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }
            }
            .padding(10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title).")
        .accessibilityHint("Use Cook to start or Trash to dismiss.")
    }
}

// MARK: - Horizontal section
fileprivate struct SectionView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Rectangle()
                    .fill(brandOrange)
                    .frame(width: 4, height: 20)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Wrap each card in a NavigationLink so tapping the chip/card navigates
                    ForEach(0..<8) { _ in
                        let t = "Katsu Curry with Rice"
                        let img = "katsu"
                        let time = 30
                        let kcal = 680
                        NavigationLink {
                            RecipeDetailView(meal: .stub(title: t, time: time, kcal: kcal))
                        } label: {
                            RecipeTileCard(
                                imageName: img,
                                title: t,
                                timeMin: time,
                                kcal: kcal
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// === Add this chip (matches Discover look) ===
fileprivate struct LikedGridCard: View {
    let title: String
    let imageName: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = max(140, w * 0.72) // keep proportionate

            ZStack(alignment: .bottomLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.45)],
                               startPoint: .center, endPoint: .bottom)
                    .frame(width: w, height: h)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(radius: 2)
                }
                .padding(10)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.black, lineWidth: 2))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .frame(height: 165) // good default; auto-adjusts with screen
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)")
    }
}

// MARK: - Main Discover
struct DiscoverView: View {
    @State private var showLiked = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DiscoverStickyHeader(
                    onLikedTap: { showLiked.toggle() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Daily Bites now navigates on tap
                        DailyBitesCard()

                        // Rails
                        SectionView(
                            title: "Top picks for you",
                            subtitle: "Freshly mixed, right now"
                        )

                        SectionView(
                            title: "Fast & fuss-free",
                            subtitle: "<15 minutes"
                        )

                        SectionView(
                            title: "New this week",
                            subtitle: "Hot out the kitchen 🔥"
                        )

                        SectionView(
                            title: "Because you liked Thai Curry",
                            subtitle: "Recommended just for you"
                        )

                        Spacer(minLength: 60)
                    }
                    .padding(.top, 8)
                }
            }
            .sheet(isPresented: $showLiked) {
                LikedRecipesView()
            }
            .toolbar(.hidden, for: .navigationBar)        }
    }
}

// MARK: - RDIngredientRow (left unchanged)
private struct RDIngredientRow: View {
    @State var item: RDIngredient

    private var qtyText: String {
        switch item.unit {
        case .count:        return "\(Int(item.amount))\(RDUnit.count.label)"
        case .grams:        return "\(Int(item.amount))\(RDUnit.grams.label)"
        case .milliliters:  return "\(Int(item.amount))\(RDUnit.milliliters.label)"
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
        .toggleStyle(RDRightCheckToggleStyle())
    }
}

// MARK: - Preview
#Preview {
    DiscoverView()
}
