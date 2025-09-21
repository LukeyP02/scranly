import SwiftUI
import UIKit

// MARK: - Brand
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Models
struct Recipe: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let desc: String
    let imageName: String?
    let emojiFallback: String
    let timeMinutes: Int
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

// MARK: - Sample Data
fileprivate let chefsPick: [Recipe] = [
    .init(title: "Katsu Chicken Curry", desc: "Crispy chicken, rich curry sauce.", imageName: "Katsu Chicken Curry", emojiFallback: "🍛", timeMinutes: 25, calories: 612, protein: 38, carbs: 72, fat: 18),
    .init(title: "Salmon & Rice", desc: "Flaky salmon with fluffy rice.", imageName: "Salmon & Rice", emojiFallback: "🍣", timeMinutes: 20, calories: 590, protein: 34, carbs: 60, fat: 20),
    .init(title: "Veggie Stir Fry", desc: "Crunchy veg, gingery glaze.", imageName: "Veggie Stir Fry", emojiFallback: "🥦", timeMinutes: 15, calories: 520, protein: 18, carbs: 68, fat: 12)
]
fileprivate let trending: [Recipe] = [
    .init(title: "Chicken Caesar Wrap", desc: "Grilled chicken, creamy Caesar.", imageName: "Chicken Caesar Wrap", emojiFallback: "🌯", timeMinutes: 10, calories: 520, protein: 30, carbs: 45, fat: 22),
    .init(title: "Poke Bowl", desc: "Fresh toppings over sushi rice.", imageName: "Poke Bowl", emojiFallback: "🍱", timeMinutes: 15, calories: 560, protein: 32, carbs: 62, fat: 14),
    .init(title: "Tomato Mozzarella Panini", desc: "Melty mozz & basil press.", imageName: "Tomato Mozzarella Panini", emojiFallback: "🥪", timeMinutes: 12, calories: 480, protein: 21, carbs: 50, fat: 16)
]
fileprivate let quickAndEasy: [Recipe] = [
    .init(title: "Eggs on Toast", desc: "Buttery toast, soft eggs.", imageName: "Eggs on Toast", emojiFallback: "🍳", timeMinutes: 7, calories: 450, protein: 24, carbs: 38, fat: 20),
    .init(title: "Greek Yogurt & Fruit", desc: "Tangy yogurt, sweet berries.", imageName: "Greek Yogurt & Fruit", emojiFallback: "🫐", timeMinutes: 5, calories: 420, protein: 20, carbs: 48, fat: 12),
    .init(title: "Overnight Oats", desc: "Creamy, ready by morning.", imageName: "Overnight Oats", emojiFallback: "🥣", timeMinutes: 5, calories: 380, protein: 16, carbs: 55, fat: 9)
]
fileprivate let highProtein: [Recipe] = [
    .init(title: "Chicken Tikka Bowl", desc: "Spiced chicken, herby rice.", imageName: nil, emojiFallback: "🍗", timeMinutes: 28, calories: 630, protein: 46, carbs: 58, fat: 18),
    .init(title: "Turkey Bolognese", desc: "Lean meat, rich tomato sauce.", imageName: nil, emojiFallback: "🍝", timeMinutes: 30, calories: 590, protein: 42, carbs: 62, fat: 14),
    .init(title: "Tofu Power Salad", desc: "Crispy tofu, crunchy veg.", imageName: nil, emojiFallback: "🥗", timeMinutes: 12, calories: 410, protein: 26, carbs: 36, fat: 14)
]

// MARK: - Helpers
fileprivate func assetImage(named: String?) -> Image? {
    guard let name = named, let ui = UIImage(named: name) else { return nil }
    return Image(uiImage: ui)
}

// MARK: - Swipe action bar (buttons under title)
fileprivate struct SwipeActionBar: View {
    let canUndo: Bool
    let canSwipe: Bool
    var onUndo: () -> Void
    var onNope: () -> Void
    var onLike: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onUndo) {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.callout.weight(.heavy))
            }
            .buttonStyle(.bordered)
            .disabled(!canUndo)

            Spacer()

            Button(action: onNope) {
                Label("Skip", systemImage: "xmark")
                    .font(.callout.weight(.heavy))
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Button(action: onLike) {
                Label("Like", systemImage: "heart.fill")
                    .font(.callout.weight(.heavy))
            }
            .buttonStyle(.borderedProminent)
            .tint(brandOrange)
            .disabled(!canSwipe)
        }
        .padding(.horizontal)
    }
}

// MARK: - Discover
struct DiscoverView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case forYou = "For You", swipe = "Swipe"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .forYou
    @State private var search: String = ""

    // Swipe state
    @State private var swipeDeck: [Recipe] = trending + highProtein + quickAndEasy + chefsPick
    @State private var liked: [Recipe] = []
    @State private var programmaticSwipe: SwipeDirection? = nil
    @State private var lastOp: (item: Recipe, liked: Bool)? = nil

    private var allRecipes: [Recipe] {
        // de-dup by title so sections don’t repeat the same dish
        Array([chefsPick, trending, quickAndEasy, highProtein].joined())
            .reduce(into: [String:Recipe]()) { dict, r in
                if dict[r.title] == nil { dict[r.title] = r }
            }
            .map { $0.value }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if mode == .forYou {
                    ForYouFeed(all: allRecipes, liked: liked, search: $search)
                        .safeAreaInset(edge: .top) {
                            DiscoverHeader(mode: $mode, showSearch: true, search: $search, catalogue: allRecipes)
                        }

                } else {
                    // --- SWIPE MODE ---
                    VStack(spacing: 14) {
                        // Buttons now live directly under the screen title (header)
                        SwipeActionBar(
                            canUndo: lastOp != nil,
                            canSwipe: !swipeDeck.isEmpty,
                            onUndo: undoLast,
                            onNope: { programmaticSwipe = .nope },
                            onLike: { programmaticSwipe = .like }
                        )
                        .padding(.top, 8)

                        Text("Swipe to Discover 🍴")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(brandOrange)

                        Text("Based on your favourites & taste")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)

                        if swipeDeck.isEmpty {
                            EmptySwipeState {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    swipeDeck = trending + highProtein + quickAndEasy + chefsPick
                                    liked.removeAll()
                                    lastOp = nil
                                }
                            }
                            .padding(.top, 24)
                            .padding(.horizontal)
                        } else {
                            SwipeDeck(
                                items: swipeDeck,
                                programmaticSwipe: $programmaticSwipe,
                                onSwipe: { item, likedRight in
                                    // remove from deck + remember op
                                    if let idx = swipeDeck.firstIndex(of: item) {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                            swipeDeck.remove(at: idx)
                                        }
                                    }
                                    if likedRight { liked.append(item) }
                                    lastOp = (item, likedRight)
                                }
                            )
                            .frame(height: 500)
                            .padding(.horizontal)
                            .padding(.top, 6)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Optional: quick glance liked list
                        if !liked.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Shortlist")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(liked, id: \.id) { r in
                                            HStack(spacing: 8) {
                                                Text(r.emojiFallback)
                                                Text(r.title).lineLimit(1)
                                            }
                                            .font(.caption.weight(.semibold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Color(.systemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(.black, lineWidth: 2)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 10)
                    }
                    .padding(.top, 12)
                    .safeAreaInset(edge: .top) {
                        DiscoverHeader(mode: $mode, showSearch: false, search: .constant(""), catalogue: allRecipes)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
    }

    // MARK: - Undo
    private func undoLast() {
        guard let last = lastOp else { return }
        // Remove from liked if that was a like
        if last.liked, let idx = liked.lastIndex(of: last.item) {
            liked.remove(at: idx)
        }
        // Put card back on top (end of array is top)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            swipeDeck.append(last.item)
        }
        lastOp = nil
    }
}

// MARK: - Header (title + picker + optional search)
fileprivate struct DiscoverHeader: View {
    @Binding var mode: DiscoverView.Mode
    var showSearch: Bool
    @Binding var search: String
    var catalogue: [Recipe]

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Discover")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)
                Spacer()
                NavigationLink {
                    MealCatalogueView(recipes: catalogue)
                } label: {
                    Label("Catalogue", systemImage: "square.grid.2x2")
                        .font(.callout.weight(.heavy))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal)

            Picker("", selection: $mode) {
                ForEach(DiscoverView.Mode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if showSearch {
                SearchBar(text: $search)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Taste dials & personalised feed
fileprivate struct TasteDials: View {
    @Binding var preferQuick: Bool
    @Binding var preferHighProtein: Bool

    var body: some View {
        HStack(spacing: 8) {
            TasteDial(isOn: $preferQuick, label: "Quick", system: "bolt.fill")
            TasteDial(isOn: $preferHighProtein, label: "High-protein", system: "dumbbell.fill")
            Spacer()
        }
        .padding(.horizontal)
    }
}

fileprivate struct TasteDial: View {
    @Binding var isOn: Bool
    let label: String
    let system: String

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: system).font(.caption.weight(.heavy))
                Text(label).font(.caption.weight(.semibold))
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isOn ? brandOrange.opacity(0.15) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct ForYouFeed: View {
    let all: [Recipe]
    let liked: [Recipe]
    @Binding var search: String

    @State private var preferQuick = true
    @State private var preferHighProtein = false

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    private var filteredForSearch: [Recipe] {
        guard !search.isEmpty else { return all }
        let q = search.lowercased()
        return all.filter { $0.title.lowercased().contains(q) || $0.desc.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                if !search.isEmpty {
                    SectionHeader(title: "Results", subtitle: "Matching “\(search)”")
                    MealCatalogueView(recipes: filteredForSearch)
                        .frame(minHeight: 300)
                    Spacer(minLength: 20)

                } else {
                    // Taste dials
                    TasteDials(preferQuick: $preferQuick, preferHighProtein: $preferHighProtein)
                        .padding(.top, 6)

                    // Compute feed
                    let profile = TasteProfile(
                        likedTitles: Set(liked.map { $0.title }),
                        preferQuick: preferQuick,
                        preferHighProtein: preferHighProtein
                    )

                    let topPicks = TasteEngine.rank(all: all, profile: profile, hour: hour).prefix(10)
                    let similar = TasteEngine.similar(to: liked, from: all, max: 10)
                    let quickTonight = TasteEngine.quick(all: all, limit: 8)
                    let proteinPicks = TasteEngine.highProtein(all: all, limit: 8)

                    if !topPicks.isEmpty {
                        SectionHeader(title: "Top picks for you", subtitle: "Freshly mixed, right now")
                        HorizontalCarousel(data: Array(topPicks), size: CGSize(width: 320, height: 280), showForYouBadge: true)
                            .padding(.bottom, 6)
                    }

                    if !similar.isEmpty {
                        SectionHeader(title: "Because you liked…", subtitle: liked.first?.title ?? "your recent likes")
                        HorizontalCarousel(data: similar, size: CGSize(width: 200, height: 250))
                            .padding(.bottom, 6)
                    }

                    SectionHeader(title: hour >= 16 ? "Quick tonight" : "Fast & fuss-free", subtitle: "<15 minutes")
                    HorizontalCarousel(data: quickTonight, size: CGSize(width: 200, height: 250))
                        .padding(.bottom, 6)

                    SectionHeader(title: "High-protein for you", subtitle: "Powered-up plates")
                    HorizontalCarousel(data: proteinPicks, size: CGSize(width: 200, height: 250))
                        .padding(.bottom, 12)
                }
            }
            .padding(.bottom, 28)
        }
    }
}

fileprivate struct TasteProfile {
    let likedTitles: Set<String>
    let preferQuick: Bool
    let preferHighProtein: Bool
}

fileprivate enum TasteEngine {
    // Simple keyword map to cluster “similar” dishes
    private static let tags: [String:Set<String>] = [
        "Katsu Chicken Curry": ["chicken","curry","japanese","rice","crispy"],
        "Salmon & Rice": ["salmon","fish","rice","quick"],
        "Veggie Stir Fry": ["veg","stirfry","noodles","quick"],
        "Chicken Caesar Wrap": ["chicken","wrap","salad","lunch","quick"],
        "Poke Bowl": ["bowl","rice","salmon","fresh","quick"],
        "Tomato Mozzarella Panini": ["panini","mozzarella","tomato","basil","veg","lunch","quick"],
        "Eggs on Toast": ["eggs","breakfast","quick"],
        "Greek Yogurt & Fruit": ["yogurt","fruit","breakfast","quick","veg"],
        "Overnight Oats": ["oats","breakfast","veg","quick"],
        "Chicken Tikka Bowl": ["chicken","bowl","spiced","rice","protein"],
        "Turkey Bolognese": ["turkey","pasta","bolognese","protein"],
        "Tofu Power Salad": ["tofu","salad","veg","protein","quick"]
    ]

    static func tags(for r: Recipe) -> Set<String> {
        tags[r.title] ?? Set(r.title.lowercased().split{ !$0.isLetter }.map(String.init))
    }

    static func similar(to liked: [Recipe], from pool: [Recipe], max: Int) -> [Recipe] {
        guard let anchor = liked.last else { return [] }
        let anchorTags = tags(for: anchor)
        return pool
            .filter { $0.title != anchor.title }
            .sorted { jaccard(tags(for:$0), anchorTags) > jaccard(tags(for:$1), anchorTags) }
            .prefix(max)
            .map { $0 }
    }

    static func quick(all: [Recipe], limit: Int) -> [Recipe] {
        Array(all.sorted { $0.timeMinutes < $1.timeMinutes }.prefix(limit))
    }

    static func highProtein(all: [Recipe], limit: Int) -> [Recipe] {
        Array(all.sorted { $0.protein > $1.protein }.prefix(limit))
    }

    static func rank(all: [Recipe], profile: TasteProfile, hour: Int) -> [Recipe] {
        all.sorted { score($0, profile, hour) > score($1, profile, hour) }
    }

    private static func score(_ r: Recipe, _ p: TasteProfile, _ hour: Int) -> Double {
        var s: Double = 0

        // If you liked similar dishes
        let likedBoost = p.likedTitles
            .map { jaccard(tags(for: r), tags(forTitle: $0)) }
            .max() ?? 0
        s += likedBoost * 2.0

        // Quick preference
        if p.preferQuick { s += (r.timeMinutes <= 15 ? 1.2 : 0) }

        // High protein preference
        if p.preferHighProtein { s += Double(r.protein) / 50.0 }

        // Time-of-day bias
        if hour < 11 { s += (r.timeMinutes <= 15 ? 0.6 : 0); if tags(for:r).contains("breakfast") { s += 0.6 } }
        if hour >= 17 { if tags(for:r).contains("curry") || tags(for:r).contains("bowl") { s += 0.4 } }

        // Keep calories reasonable
        s += (r.calories >= 400 && r.calories <= 700) ? 0.2 : 0

        return s
    }

    private static func tags(forTitle title: String) -> Set<String> {
        tags[title] ?? Set(title.lowercased().split{ !$0.isLetter }.map(String.init))
    }

    private static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let inter = a.intersection(b).count
        if inter == 0 { return 0 }
        return Double(inter) / Double(a.union(b).count)
    }
}

// MARK: - Section header (minimal)
fileprivate struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Rectangle()
                .fill(brandOrange)
                .frame(width: 4, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)

                if let s = subtitle, !s.isEmpty {
                    Text(s)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Search
fileprivate struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.subheadline).foregroundStyle(.secondary)
            TextField("Search recipes, cuisines, ingredients…", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Swipe Deck
fileprivate enum SwipeDirection { case like, nope }

fileprivate struct SwipeDeck: View {
    var items: [Recipe]
    @Binding var programmaticSwipe: SwipeDirection?
    var onSwipe: (Recipe, Bool) -> Void

    private let cardOffsetY: CGFloat = 12
    private let cardScaleStep: CGFloat = 0.035

    var body: some View {
        GeometryReader { geo in
            let width = min(max(geo.size.width - 40, 280), 380)
            let height = max(width * 1.35, 460)

            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { (idx, item) in
                    let isTop = idx == items.count - 1
                    let positionFromTop = items.count - 1 - idx

                    SwipeCard(
                        recipe: item,
                        width: width,
                        height: height,
                        isTop: isTop,
                        programmaticSwipe: $programmaticSwipe,
                        onRemove: { likedRight in onSwipe(item, likedRight) }
                    )
                    .stackStyle(positionFromTop: positionFromTop,
                                baseOffsetY: cardOffsetY,
                                scaleStep: cardScaleStep)
                    .zIndex(Double(idx))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 580)
    }
}

fileprivate struct SwipeCard: View {
    let recipe: Recipe
    let width: CGFloat
    let height: CGFloat
    let isTop: Bool
    @Binding var programmaticSwipe: SwipeDirection?
    var onRemove: (Bool) -> Void

    @State private var offset: CGSize = .zero
    @State private var isGone: Bool = false

    private let corner: CGFloat = 18
    private let threshold: CGFloat = 120

    private var likeProgress: CGFloat { max(0, min(1,  offset.width / threshold)) }
    private var nopeProgress: CGFloat { max(0, min(1, -offset.width / threshold)) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 6)

            VStack(spacing: 0) {
                ZStack {
                    Group {
                        if let img = assetImage(named: recipe.imageName) {
                            img.resizable().scaledToFill()
                        } else {
                            ZStack {
                                brandOrange.opacity(0.15)
                                Text(recipe.emojiFallback).font(.system(size: 96))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    LinearGradient(colors: [brandOrange.opacity(0.10), .clear],
                                   startPoint: .topLeading, endPoint: .center)
                    LinearGradient(colors: [.clear, .black.opacity(0.35)],
                                   startPoint: .center, endPoint: .bottom)
                }
                .frame(height: height * 0.75)

                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Text(recipe.desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("\(recipe.timeMinutes)m", systemImage: "clock")
                            .font(.caption.weight(.semibold))
                        Text("·").font(.caption)
                        Label("\(recipe.calories) kcal", systemImage: "flame.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .frame(width: width, height: height)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(Double(offset.width / 14)))
        // Drag only for TOP card
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    guard isTop else { return }
                    offset = value.translation
                }
                .onEnded { value in
                    guard isTop else { return }
                    endDrag(with: value.translation)
                }
        )
        // LIKE/NOPE stamps
        .overlay(alignment: .topLeading) {
            if likeProgress > 0.6 {
                Stamp(text: "LIKE").rotationEffect(.degrees(-15)).padding(16)
            }
        }
        .overlay(alignment: .topTrailing) {
            if nopeProgress > 0.6 {
                Stamp(text: "NOPE").rotationEffect(.degrees(15)).padding(16)
            }
        }
        .opacity(isGone ? 0.6 : 1)
        // Programmatic swipe
        .onChange(of: programmaticSwipe) { dir in
            guard isTop, let dir else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                isGone = true
                if dir == .like { offset.width = 800 } else { offset.width = -800 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                onRemove(dir == .like)
                offset = .zero
                isGone = false
                programmaticSwipe = nil
            }
        }
    }

    private func endDrag(with translation: CGSize) {
        let like = translation.width > threshold
        let nope = translation.width < -threshold
        if like || nope {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                isGone = true
                offset.width += like ? 600 : -600
                offset.height += translation.height
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onRemove(like)
                offset = .zero
                isGone = false
            }
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75, blendDuration: 0.15)) {
                offset = .zero
                isGone = false
            }
        }
    }
}

fileprivate struct Stamp: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .foregroundStyle(.white)
            .background(brandOrange.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

fileprivate extension View {
    func stackStyle(positionFromTop: Int, baseOffsetY: CGFloat, scaleStep: CGFloat) -> some View {
        let scale = max(0.6, 1 - CGFloat(positionFromTop) * scaleStep)
        let y = CGFloat(positionFromTop) * baseOffsetY
        return self
            .scaleEffect(scale)
            .offset(y: y)
    }
}

// MARK: - Recipe Detail (Plan-style)
private struct RecipeDetailView: View {
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

                // Hero
                ZStack {
                    if let img = assetImage(named: meal.imageName) {
                        img.resizable().scaledToFill()
                    } else {
                        ZStack { brandOrange.opacity(0.15); Text(meal.emojiFallback).font(.system(size: 96)) }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Title + tags
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .kerning(0.5)

                    HStack(spacing: 8) {
                        RDMetaTag(systemImage: "clock",      text: "\(meal.timeMinutes)m")
                        RDMetaTag(systemImage: "flame.fill", text: "\(meal.calories) kcal")
                        RDMetaTag(systemImage: "bolt.fill",  text: "\(meal.protein)g P")
                    }
                }

                // Description (longer, lighter)
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
                    // METHOD — punchy, tappable steps
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

// Row (Shop-like)
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

// MARK: - Carousel (links to detail)
fileprivate struct HorizontalCarousel: View {
    let data: [Recipe]
    let size: CGSize
    var showForYouBadge: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(data) { r in
                    NavigationLink {
                        RecipeDetailView(meal: r)
                    } label: {
                        MealChipCard(recipe: r, size: size, showForYouBadge: showForYouBadge)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
        .zIndex(1)
    }
}

// MARK: - Meal Chip
fileprivate struct MealChipCard: View {
    let recipe: Recipe
    let size: CGSize
    var showForYouBadge: Bool = false

    private let corner: CGFloat = 16

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)

            VStack(spacing: 0) {
                ZStack {
                    Group {
                        if let img = assetImage(named: recipe.imageName) {
                            img.resizable().scaledToFill()
                        } else {
                            ZStack {
                                brandOrange.opacity(0.15)
                                Text(recipe.emojiFallback).font(.system(size: 72))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    LinearGradient(colors: [brandOrange.opacity(0.10), .clear],
                                   startPoint: .topLeading, endPoint: .center)
                    LinearGradient(colors: [.clear, .black.opacity(0.35)],
                                   startPoint: .center, endPoint: .bottom)
                }
                .frame(height: size.height * 0.75)

                VStack(alignment: .leading, spacing: 6) {
                    if showForYouBadge {
                        Text("For you")
                            .font(.caption.weight(.heavy))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(brandOrange.opacity(0.12))
                            .foregroundStyle(brandOrange)
                            .clipShape(Capsule())
                    }

                    Text(recipe.title)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Text(recipe.desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .frame(width: size.width, height: size.height)
        .compositingGroup()
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// MARK: - Catalogue Grid
fileprivate struct MealCatalogueView: View {
    let recipes: [Recipe]
    @State private var query: String = ""

    private var filtered: [Recipe] {
        guard !query.isEmpty else { return recipes }
        let q = query.lowercased()
        return recipes.filter {
            $0.title.lowercased().contains(q) || $0.desc.lowercased().contains(q)
        }
    }

    private let grid = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: grid, spacing: 14) {
                ForEach(filtered) { r in
                    NavigationLink {
                        RecipeDetailView(meal: r)
                    } label: {
                        MealChipCard(recipe: r, size: CGSize(width: 170, height: 210))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("Catalogue")
        .searchable(text: $query, prompt: "Search meals")
    }
}

// MARK: - Empty swipe state
fileprivate struct EmptySwipeState: View {
    var reset: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(brandOrange)
            Text("You’re all caught up").font(.headline)
            Text("Reset the deck to keep discovering more.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Reset deck", action: reset)
                .buttonStyle(.borderedProminent)
                .tint(brandOrange)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview { DiscoverView() }
