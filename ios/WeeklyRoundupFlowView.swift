import SwiftUI
import UIKit
// Same tag helper used in Discover
fileprivate func shortTag(for title: String) -> String {
    let t = title.lowercased()
    if t.contains("salmon") || t.contains("poke") { return "Protein • flavour • glow" }
    if t.contains("katsu")                      { return "Crispy • cosy" }
    if t.contains("pesto") || t.contains("pasta"){ return "Twirls • sauce • comfort" }
    if t.contains("wrap")                       { return "Handheld • speedy" }
    if t.contains("stir")                       { return "Fast • veg-heavy" }
    return "Good food • good plan"
}

// Lightweight model (no external dependencies)
// MARK: - Pager (swipe) of 2x2 pages
private struct WeeklyBitesPager: View {
    let meals: [WeeklyRoundupFlowView.MealReview]
    let accent: Color
    let pageSize: Int

    @State private var index = 0

    private var pages: [[WeeklyRoundupFlowView.MealReview]] {
        stride(from: 0, to: meals.count, by: pageSize).map {
            Array(meals[$0..<min($0 + pageSize, meals.count)])
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 8) {
            // progress pill
            HStack {
                Spacer()
                Text("\(index + 1)/\(max(pages.count, 1))")
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .overlay(Capsule().stroke(.black.opacity(0.15), lineWidth: 1))
                    )
            }

            TabView(selection: $index) {
                ForEach(pages.indices, id: \.self) { p in
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(pages[p]) { m in
                            WeeklyBiteTile(
                                imageName: m.imageName,
                                title: m.title,
                                timeMin: m.timeMin,
                                kcal: m.kcal
                            )
                        }
                    }
                    .tag(p)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 2 * 240 + 14) // two rows of 240pt tiles + spacing
        }
    }
}

private struct MealDetailView: View {
    let meal: WeeklyRoundupFlowView.MealReview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(meal.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                Text(meal.title)
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .kerning(0.5)

                HStack(spacing: 8) {
                    Meta(system: "clock", text: "\(meal.timeMin)m")
                    Meta(system: "flame.fill", text: "\(meal.kcal) kcal")
                    Meta(system: "bolt.fill",  text: "\(meal.proteinG)g P")
                }

                Text("A bright, weeknight-friendly dish. Built from pantry staples with fresh add-ins — easy to tweak for whatever’s in the fridge, and scales well for leftovers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Meta: View {
        let system: String
        let text: String
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: system)
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
}

// MARK: - Big tile (overlay style, matches rails)
private struct WeeklyBiteTile: View {
    let imageName: String
    let title: String
    let timeMin: Int
    let kcal: Int

    private let corner: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 240) // bigger card
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
                .frame(height: 240)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18.5, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(radius: 3)

                HStack(spacing: 8) {
                    OverlayMeta(system: "clock", text: "\(timeMin)m")
                    OverlayMeta(system: "flame.fill", text: "\(kcal) kcal")
                }
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private struct OverlayMeta: View {
        let system: String
        let text: String
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: system)
                Text(text)
            }
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .background(
                Capsule()
                    .fill(.black.opacity(0.28))
                    .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
            )
            .foregroundStyle(.white)
        }
    }
}

// Discover-style Daily Bites card, adapted for Weekly (accent injected, no Recipe deps)
private struct WeeklyDailyBitesCard: View {
    let accent: Color
    // You can inject your real picks here; keeping the same 3 demo items for now
    private let meals: [DailyBite] = [
        .init(title: "Katsu Curry",     subtitle: "Crispy + cosy",   imageName: "katsu", kcal: 680, timeMin: 30),
        .init(title: "Katsu Rice Bowl", subtitle: "Weeknight quick", imageName: "katsu", kcal: 540, timeMin: 18),
        .init(title: "Veggie Katsu",    subtitle: "Light & crunchy", imageName: "katsu", kcal: 460, timeMin: 22),
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
                TabView(selection: $index) {
                    ForEach(meals.indices, id: \.self) { i in
                        let m = meals[i]
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

                                Text(shortTag(for: m.title))
                                    .font(.system(size: 12.5, weight: .semibold, design: .serif))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(
                                        Capsule()
                                            .fill(.black.opacity(0.28))
                                            .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
                                    )
                                    .foregroundStyle(.white)
                            }
                            .padding(12)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 220)

                // Bin / Cook row
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
                    .background(accent)
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



// MARK: - 12-card grid (bigger tiles)
private struct WeeklyBitesGrid: View {
    let accent: Color
    let bites: [DailyBite]

    init(accent: Color) {
        self.accent = accent
        // Seed pool → expand to 12 (cycles assets you have: katsu / caeser / oats)
        let pool: [DailyBite] = [
            .init(title: "Katsu Curry",       subtitle: "Crispy + cosy",   imageName: "katsu",  kcal: 680, timeMin: 30),
            .init(title: "Chicken Caesar",    subtitle: "Handheld + speedy", imageName: "caeser", kcal: 520, timeMin: 14),
            .init(title: "Overnight Oats",    subtitle: "Prep-ahead easy", imageName: "oats",   kcal: 380, timeMin: 5),
            .init(title: "Veggie Katsu",      subtitle: "Light & crunchy", imageName: "katsu",  kcal: 460, timeMin: 22),
            .init(title: "Caesar Wrap",       subtitle: "Lunchable",       imageName: "caeser", kcal: 480, timeMin: 12),
            .init(title: "PB Oats",           subtitle: "Protein glow",    imageName: "oats",   kcal: 420, timeMin: 6),
        ]
        self.bites = (0..<12).map { i in
            let b = pool[i % pool.count]
            return DailyBite(title: b.title, subtitle: b.subtitle, imageName: b.imageName, kcal: b.kcal, timeMin: b.timeMin)
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(bites) { m in
                WeeklyBiteTile(
                    imageName: m.imageName,
                    title: m.title,
                    timeMin: m.timeMin,
                    kcal: m.kcal
                )
            }
        }
    }
}


// MARK: - Original single-card swiper, but 12 items
// MARK: - Original single-card swiper, now with BIN / COOK row
private struct WeeklyBitesSwipeCard: View {
    let meals: [WeeklyRoundupFlowView.MealReview]
    let accent: Color
    var height: CGFloat = 280

    // Callbacks
    var onBin: (WeeklyRoundupFlowView.MealReview) -> Void = { _ in }
    // Cook navigates via NavigationLink(value:), so no onCook needed unless you want extra side-effects
    var onCookSideEffect: (WeeklyRoundupFlowView.MealReview) -> Void = { _ in }

    @State private var index: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            // progress pill → 1/12, 2/12 ...
            HStack {
                Spacer()
                Text("\(min(index + 1, max(meals.count, 1)))/\(max(meals.count, 1))")
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .overlay(Capsule().stroke(.black.opacity(0.15), lineWidth: 1))
                    )
            }

            // Swiper
            TabView(selection: $index) {
                ForEach(meals.indices, id: \.self) { i in
                    let m = meals[i]
                    ZStack(alignment: .bottomLeading) {
                        Image(m.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: height)
                            .clipped()

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.45)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(height: height)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(m.title)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .shadow(radius: 3)

                            // Meta chips (time + kcal) → link to detail
                            HStack(spacing: 8) {
                                NavigationLink(value: m) {
                                    OverlayMeta(system: "clock", text: "\(m.timeMin)m")
                                }
                                .buttonStyle(.plain)

                                NavigationLink(value: m) {
                                    OverlayMeta(system: "flame.fill", text: "\(m.kcal) kcal")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)

            // BIN / COOK row (matches Discover look)
            if !meals.isEmpty {
                HStack(spacing: 0) {
                    // BIN
                    Button {
                        let current = meals[index]
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            onBin(current)
                            // advance to next card if possible
                            if index < meals.count - 1 {
                                index += 1
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Bin").font(.subheadline.weight(.heavy))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.systemGray6))
                    .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.black.opacity(0.08)), alignment: .trailing)

                    // COOK → navigates to detail
                    NavigationLink(value: meals[index]) {
                        HStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                            Text("Cook").font(.subheadline.weight(.heavy))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.white)
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            onCookSideEffect(meals[index])
                        }
                    )
                    .buttonStyle(.plain)
                    .background(accent)
                }
            }
        }
    }

    private struct OverlayMeta: View {
        let system: String
        let text: String
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: system)
                Text(text)
            }
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .background(
                Capsule()
                    .fill(.black.opacity(0.28))
                    .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
            )
            .foregroundStyle(.white)
        }
    }
}




struct WeeklyRoundupFlowView: View {
    // MARK: - Brand
    // Keep this lighter to match your recent tweak
    private let scranOrange = Color(red: 1.00, green: 0.55, blue: 0.12)
    private let cardRadius: CGFloat = 18
    private let chipRadius: CGFloat = 12

    // MARK: - Demo data
    struct MealReview: Identifiable, Equatable, Hashable {   // ⬅️ add Hashable
        let id = UUID()
        let title: String
        let cuisine: String
        let emoji: String
        let kcal: Int
        let proteinG: Int
        let timeMin: Int
        let imageName: String
    }

    private let weekDeck: [MealReview] = [
        .init(title: "Thai Green Curry",     cuisine: "Thai",     emoji: "🍛", kcal: 640, proteinG: 34, timeMin: 30, imageName: "katsu"),
        .init(title: "Salmon Teriyaki Bowl", cuisine: "Japanese", emoji: "🐟", kcal: 610, proteinG: 36, timeMin: 22, imageName: "katsu"),
        .init(title: "Chicken Fajitas",      cuisine: "Mexican",  emoji: "🌮", kcal: 590, proteinG: 33, timeMin: 25, imageName: "katsu"),
        .init(title: "Creamy Pesto Pasta",   cuisine: "Italian",  emoji: "🍝", kcal: 780, proteinG: 22, timeMin: 20, imageName: "katsu"),
        .init(title: "Veggie Stir-fry",      cuisine: "Comfort",  emoji: "🥦", kcal: 520, proteinG: 20, timeMin: 16, imageName: "katsu")
    ]

    private var cookedThisWeek: Int { weekDeck.count }
    private var avgCookTimeMin: Int {
        guard !weekDeck.isEmpty else { return 0 }
        let total = weekDeck.map(\.timeMin).reduce(0, +)
        return Int(round(Double(total) / Double(weekDeck.count)))
    }
    private var totalCookTimeMin: Int { weekDeck.map(\.timeMin).reduce(0, +) }
    private var fastestMin: Int { weekDeck.map(\.timeMin).min() ?? 0 }
    private var avgProteinPerMeal: Int {
        guard !weekDeck.isEmpty else { return 0 }
        let t = weekDeck.map(\.proteinG).reduce(0, +)
        return Int(round(Double(t) / Double(weekDeck.count)))
    }
    // rough money demo
    private var estSavedPerMealGBP: Double { 3.50 }
    private var estSavedTotalGBP: Double { Double(cookedThisWeek) * estSavedPerMealGBP }

    private var weekRangeString: String {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -6, to: end) ?? end
        let df = DateFormatter(); df.dateFormat = "d MMM"
        return "\(df.string(from: start)) – \(df.string(from: end))"
    }

    // MARK: Flow
    fileprivate enum Step: Int, CaseIterable { case time, money, choice, rate, bites }
    @State private var step: Step = .time
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false

    // choice
    private let choices = ["Faster nights","Budget week","High protein","Veg-heavy","Comfort","Surprise me"]
    @State private var selectedChoice: String? = nil

    // ratings
    enum ReviewOutcome: String, CaseIterable { case loved = "Loved", meh = "Meh", again = "Cook again" }
    @State private var ratings: [UUID: ReviewOutcome] = [:]

    // bites (12)
    private var bites12: [MealReview] {
        var arr: [MealReview] = []
        for i in 0..<12 {
            let base = weekDeck[i % weekDeck.count]
            arr.append(.init(title: base.title, cuisine: base.cuisine, emoji: base.emoji,
                             kcal: base.kcal, proteinG: base.proteinG, timeMin: base.timeMin,
                             imageName: base.imageName))
        }
        return arr
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky header
                    HeaderBar(
                        titleCenter: {
                            HStack(spacing: 6) {
                                Text("Scranly")
                                    .font(.system(size: 24, weight: .black, design: .serif))
                                    .foregroundStyle(scranOrange)
                                Text("weekly roundup")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                            }
                        },
                        left: {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left").font(.headline.weight(.heavy))
                            }.buttonStyle(.plain)
                        },
                        right: {
                            Button { showShare = true } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                            }
                            .buttonStyle(MiniBorderButtonStyle())
                        }
                    )

                    // Progress chips (word above icon, matches fact-file styling)
                    StepProgressBar(current: step, accent: scranOrange)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 6)

                    // Pager
                    TabView(selection: $step) {
                        TimeStep.tag(Step.time)
                        MoneyStep.tag(Step.money)
                        ChoiceStep.tag(Step.choice)
                        RateStep.tag(Step.rate)
                        BitesStep.tag(Step.bites)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            // Bottom nav
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) { goBack() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.subheadline.weight(.bold))
                            Text("Back").font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                                        .stroke(.black.opacity(0.18), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(step == .time ? 0.4 : 1)
                    .disabled(step == .time)

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) { goNext() }
                    } label: {
                        HStack(spacing: 8) {
                            Text(step == .bites ? "Finish" : "Next")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                            Image(systemName: "arrow.right").font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                                .fill(scranOrange)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(Color(.systemBackground).opacity(0.001))
            }
            .sheet(isPresented: $showShare) {
                ActivityView(text: shareText()).presentationDetents([.medium])
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MealReview.self) { meal in
                MealDetailView(meal: meal)
            }
        }
    }

    // MARK: - Steps (each uses the FactFile look)

    private var TimeStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                TitleRow(lead: "Time", trail: weekRangeString, accent: scranOrange)
                    .padding(.horizontal)

                FactFileCard(cardRadius: cardRadius, accent: scranOrange) {
                    FactRow(icon: "timer", title: "Avg cook", value: "\(avgCookTimeMin)m", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "hourglass", title: "Total time", value: "\(totalCookTimeMin)m", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "hare.fill", title: "Fastest night", value: "\(fastestMin)m", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "bolt.heart", title: "Avg protein", value: "\(avgProteinPerMeal) g", accent: scranOrange)

                    // Triptych inside the card (optional, matches your example)
                    OrangeDivider(accent: scranOrange)
                    TriptychInsideCard(imageNames: ["oats","katsu","caeser"])
                        .frame(height: 120)
                        .padding(.top, 10)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 6)
        }
    }

    private var MoneyStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                TitleRow(lead: "Money", trail: "Estimated vs takeaway", accent: scranOrange)
                    .padding(.horizontal)

                FactFileCard(cardRadius: cardRadius, accent: scranOrange) {
                    FactRow(icon: "sterlingsign.circle.fill", title: "Saved total", value: "£\(String(format: "%.2f", estSavedTotalGBP))", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "banknote", title: "Saved / meal", value: "£\(String(format: "%.2f", estSavedPerMealGBP))", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "cart", title: "Meals cooked", value: "\(cookedThisWeek)", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)
                    FactRow(icon: "fork.knife", title: "Home vs out", value: "Mostly at home", accent: scranOrange)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 6)
        }
    }

    private var ChoiceStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                TitleRow(lead: "Your choice", trail: "Tune next week’s plan", accent: scranOrange)
                    .padding(.horizontal)

                // Fact-file card + inline chip row, both inside the same card
                FactFileCard(cardRadius: cardRadius, accent: scranOrange) {
                    FactRow(icon: "target", title: "Focus", value: selectedChoice ?? "Balanced", accent: scranOrange)
                    OrangeDivider(accent: scranOrange)

                    // Inline chips (wrap) styled like fact file (white + black stroke; selected = accent stroke + soft fill)
                    WrapChips(data: choices, spacing: 10) { option in
                        SelectChip(text: option, selected: selectedChoice == option, accent: scranOrange) {
                            selectedChoice = (selectedChoice == option ? nil : option)
                        }
                    }
                    .frame(minHeight: 40)
                    .padding(.vertical, 6)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 6)
        }
    }

    private var RateStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // In RateStep
                TitleRow(lead: "Rate this week", trail: "", accent: scranOrange)
                    .padding(.horizontal)

                // Entire ratings list inside a single fact-file card (row per meal + divider)
                FactFileCard(cardRadius: cardRadius, accent: scranOrange) {
                    ForEach(Array(weekDeck.enumerated()), id: \.element.id) { idx, meal in
                        RatingRowLine(
                            meal: meal,
                            selection: ratings[meal.id],
                            onSelect: { ratings[meal.id] = $0 },
                            accent: scranOrange
                        )
                        if idx < weekDeck.count - 1 {
                            OrangeDivider(accent: scranOrange)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 60)
            }
            .padding(.top, 6)
        }
    }

    // MARK: Daily Bites step (uses the Discover-style card)
    // MARK: Daily Bites step → 12 big cards (no subtitle, no rounded container)
    // MARK: Daily Bites step → 12 big cards with swipe (paged 4-per page)
    // MARK: - Daily Bites (original swipe, now 12 cards + bigger)
    private var BitesStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                HStack {
                    Text("Daily Bites")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal)

                WeeklyBitesSwipeCard(
                    meals: bites12,
                    accent: scranOrange,
                    height: 280,
                    onBin: { meal in
                        // e.g. mark as dismissed / telemetry / remove from a source array you own
                        print("Binned:", meal.title)
                    },
                    onCookSideEffect: { meal in
                        // fires together with the NavigationLink push
                        print("Cook:", meal.title)
                    }
                )
                .padding(.horizontal)

                Spacer(minLength: 60)
            }
            .padding(.top, 6)
        }
    }

    // MARK: Nav helpers
    private func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }
    private func goNext() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        } else {
            dismiss()
        }
    }

    private func shareText() -> String {
        var lines: [String] = [
            "Scranly Weekly Roundup",
            "Dates: \(weekRangeString)",
            "Avg cook: \(avgCookTimeMin)m  •  Total: \(totalCookTimeMin)m",
            "Est. saved: £\(String(format: "%.2f", estSavedTotalGBP)) (≈£\(String(format: "%.2f", estSavedPerMealGBP))/meal)",
            "Focus: \(selectedChoice ?? "Balanced")",
            "",
            "Ratings:"
        ]
        for m in weekDeck {
            let r = ratings[m.id]?.rawValue ?? "—"
            lines.append("• \(m.title): \(r)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Shared Components (Fact-file look)

private struct FactFileCard<Content: View>: View {
    let cardRadius: CGFloat
    let accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cardRadius, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

private struct FactRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 18)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .serif))
        }
        .padding(.vertical, 8)
    }
}

private struct OrangeDivider: View {
    let accent: Color
    var body: some View {
        Rectangle()
            .fill(accent.opacity(0.9))
            .frame(height: 1)
            .opacity(0.9)
    }
}

private struct TriptychInsideCard: View {
    let imageNames: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(imageNames.prefix(3), id: \.self) { name in
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                }
                .frame(height: 120)
            }
        }
    }
}

// Header
private struct HeaderBar<Center: View, Left: View, Right: View>: View {
    @ViewBuilder var titleCenter: () -> Center
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                left()
                Spacer()
                titleCenter()
                Spacer()
                right()
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// Progress chips (word above icon), styled like the fact-file
private struct StepProgressBar: View {
    let current: WeeklyRoundupFlowView.Step
    let accent: Color

    private struct Item: Identifiable {
        let id = UUID()
        let step: WeeklyRoundupFlowView.Step
        let title: String
        let icon: String
    }
    private var items: [Item] {
        [
            .init(step: .time,   title: "Time",   icon: "timer"),
            .init(step: .money,  title: "Money",  icon: "sterlingsign.circle.fill"),
            .init(step: .choice, title: "Choice", icon: "slider.horizontal.3"),
            .init(step: .rate,   title: "Rate",   icon: "hand.thumbsup.fill"),
            .init(step: .bites,  title: "Bites",  icon: "square.grid.2x2")
        ]
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { it in
                let active = it.step == current
                VStack(spacing: 4) {
                    Text(it.title)
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)
                    Image(systemName: it.icon)
                        .font(.caption.weight(.heavy))
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(active ? accent.opacity(0.08) : Color(.systemBackground))
                )
                .foregroundStyle(active ? accent : Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(active ? accent : .black, lineWidth: 2)
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

private struct TitleRow: View {
    let lead: String
    let trail: String
    let accent: Color
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                Spacer()
                Text(lead)
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(accent)
                Spacer()
            }
            if !trail.isEmpty {
                HStack(spacing: 8) {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(trail)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.black, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                }
            }
        }
    }
}

// Select chip (fact-file style)
private struct SelectChip: View {
    let text: String
    let selected: Bool
    let accent: Color
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? accent.opacity(0.10) : Color(.systemBackground))
                )
                .foregroundStyle(selected ? accent : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? accent : .black, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WrapChips<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    @ViewBuilder var chip: (Data.Element) -> Content

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data), id: \.self) { item in
                    chip(item)
                        .padding(.trailing, spacing)
                        .padding(.bottom, spacing)
                        .alignmentGuide(.leading) { d in
                            if width + d.width > geo.size.width {
                                width = 0
                                height -= d.height + spacing
                            }
                            let result = width
                            width += d.width + spacing
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == data.last { width = 0; height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(minHeight: 0)
    }
}

// Ratings line as a fact-file row (chips = equal width so all 3 fit)
private struct RatingRowLine: View {
    let meal: WeeklyRoundupFlowView.MealReview
    let selection: WeeklyRoundupFlowView.ReviewOutcome?
    var onSelect: (WeeklyRoundupFlowView.ReviewOutcome) -> Void
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(meal.emoji).font(.system(size: 18)).frame(width: 24)
                Text(meal.title).font(.system(size: 17, weight: .black, design: .serif))
                Spacer()
                Text(meal.cuisine).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                RatingChip(text: "Loved", isSelected: selection == .loved, accent: accent) { onSelect(.loved) }
                RatingChip(text: "Meh", isSelected: selection == .meh, accent: accent)     { onSelect(.meh) }
                RatingChip(text: "Cook again", isSelected: selection == .again, accent: accent) { onSelect(.again) }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct RatingChip: View {
    let text: String
    let isSelected: Bool
    let accent: Color
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity) // equal widths across three chips
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? accent.opacity(0.10) : Color(.systemBackground))
                )
                .foregroundStyle(isSelected ? accent : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? accent : .black, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeGridTile: View {
    let imageName: String
    let title: String
    let timeMin: Int
    let kcal: Int
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.15), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16.5, weight: .bold, design: .serif))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    MetaTag(systemImage: "clock", text: "\(timeMin)m")
                    MetaTag(systemImage: "flame.fill", text: "\(kcal) kcal")
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 4)
    }

    private struct MetaTag: View {
        let systemImage: String
        let text: String
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(text)
            }
            .font(.caption.weight(.semibold))
            .padding(.vertical, 3.5)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .foregroundStyle(.secondary)
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: Preview
#Preview { WeeklyRoundupFlowView() }
