import SwiftUI
import Foundation

// MARK: - Brand
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - MealSlot
enum MealSlot: String, Hashable, CaseIterable {
    case breakfast, lunch, dinner, snack
}

// Common diets, allergies & intolerances
enum DietaryRequirement: String, CaseIterable, Identifiable, Hashable {
    case vegetarian
    case vegan
    case pescatarian
    case dairyFree
    case glutenFree
    case nutAllergy
    case shellfishAllergy
    case eggFree
    case soyFree
    case porkFree

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vegetarian:        return "Vegetarian"
        case .vegan:             return "Vegan"
        case .pescatarian:       return "Pescatarian"
        case .dairyFree:         return "Dairy-free"
        case .glutenFree:        return "Gluten-free"
        case .nutAllergy:        return "Nut allergy"
        case .shellfishAllergy:  return "Shellfish allergy"
        case .eggFree:           return "Egg-free"
        case .soyFree:           return "Soy-free"
        case .porkFree:          return "No pork"
        }
    }

    var subtitle: String {
        switch self {
        case .vegetarian:        return "No meat or fish"
        case .vegan:             return "No animal products"
        case .pescatarian:       return "Fish, no meat"
        case .dairyFree:         return "No milk or cheese"
        case .glutenFree:        return "No wheat, barley, rye"
        case .nutAllergy:        return "Avoid all nuts"
        case .shellfishAllergy:  return "Avoid shellfish"
        case .eggFree:           return "No eggs"
        case .soyFree:           return "No soy"
        case .porkFree:          return "No pork"
        }
    }
}

// Put near your other enums
enum CalorieBand: String, CaseIterable, Identifiable {
    case light, balanced, hearty
    var id: String { rawValue }

    var title: String {
        switch self { case .light: "Light"; case .balanced: "Balanced"; case .hearty: "Hearty" }
    }
    var subtitle: String {
        switch self { case .light: "< 550 kcal"; case .balanced: "550–700 kcal"; case .hearty: "700+ kcal" }
    }
    var range: ClosedRange<Int> {
        switch self { case .light: 0...549; case .balanced: 550...700; case .hearty: 701...2000 }
    }
}

fileprivate struct DaySquareChip: View {
    let label: String
    let isOn: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption.weight(.heavy))
                    .multilineTextAlignment(.center)

                // mini square inside a bordered square
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(.black, lineWidth: 2)
                        .frame(width: 18, height: 18)

                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(isOn ? brandOrange : brandOrange.opacity(0.18))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(minWidth: 56) // keeps chips even
            .background(Color(.systemBackground)) // white
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black, lineWidth: 2) // chip border stays
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "selected" : "not selected")
    }
}

// Dietary requirements grid
fileprivate struct DietaryRequirementsSection: View {
    @Binding var selected: Set<DietaryRequirement>

    // Adaptive grid so chips wrap nicely
    private let columns = [
        GridItem(.adaptive(minimum: 130), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(DietaryRequirement.allCases) { req in
                DietaryRequirementChip(
                    requirement: req,
                    isSelected: selected.contains(req),
                    toggle: {
                        if selected.contains(req) {
                            selected.remove(req)
                        } else {
                            selected.insert(req)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

fileprivate struct DietaryRequirementChip: View {
    let requirement: DietaryRequirement
    let isSelected: Bool
    var toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.label)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Text(requirement.subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? brandOrange : Color.black.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(requirement.label)
        .accessibilityValue(isSelected ? "selected" : "not selected")
    }
}

// MARK: - ONE-TAP PLANNER (MF calendar + portions + time)
struct PlanOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    // UI state
    @State private var selectedDays: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri]   // M–F default
    @State private var portions: Int = 2
    @State private var timePerMeal: Int = 30                                         // minutes

    // Optional nudge (kept, but minimal)
    @State private var cuisineBias: String = "Italian"
    @State private var allowLeftovers: Bool = true
    @State private var calorieBand: CalorieBand = .balanced
    @State private var dietaryRequirements: Set<DietaryRequirement> = []

    // Expand/collapse per section
    @State private var expandDays = true
    @State private var expandPortions = true
    @State private var expandTime = true
    @State private var expandCalories = true
    @State private var expandDietary = true

    // Build overlay + nav
    @State private var isPlanning = false
    @State private var progress: Double = 0
    @State private var stepIndex: Int = 0
    @State private var slideIndex: Int = 0
    @State private var suggested: [DraftDay] = []
    @State private var showSuggestions: Bool = false

    private let weekdaysMF: [Weekday] = [.mon, .tue, .wed, .thu, .fri]
    private let taglines = ["Crafting flavours", "Saving time", "Balancing macros", "Zero faff"]

    // Map slider → effort band used by the builder
    private var effortRange: ClosedRange<Int> {
        if timePerMeal <= 22 { return 15...22 }
        if timePerMeal <= 35 { return 23...35 }
        return 36...120
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Title + explainer
                        VStack(spacing: 6) {
                            Text("Plan your week")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                            Text("Pick days, portions, and your time budget.")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 6)

                        // Main hub card (Days + Portions + Time + Calories + Dietary)
                        VStack(alignment: .leading, spacing: 20) {

                            // Days
                            PlanSection(
                                iconName: "calendar",
                                title: "Which days?",
                                subtitle: nil,
                                isExpanded: $expandDays
                            ) {
                                HStack(spacing: 12) {
                                    ForEach([Weekday.mon, .tue, .wed, .thu, .fri], id: \.self) { day in
                                        DaySquareChip(
                                            label: day.prettyLabel,
                                            isOn: selectedDays.contains(day),
                                            onTap: {
                                                if selectedDays.contains(day) { selectedDays.remove(day) }
                                                else { selectedDays.insert(day) }
                                            }
                                        )
                                    }
                                }
                            }

                            Divider()

                            // Portions
                            PlanSection(
                                iconName: "person.2",
                                title: "Portions",
                                subtitle: "\(portions) each",
                                isExpanded: $expandPortions
                            ) {
                                PortionsSlider(value: $portions)
                            }

                            Divider()

                            // Time per meal
                            PlanSection(
                                iconName: "timer",
                                title: "Time per meal",
                                subtitle: "\(timePerMeal)m",
                                isExpanded: $expandTime
                            ) {
                                TimeButtonsRowLarge(minutes: $timePerMeal)
                            }

                            Divider()

                            // Calorie vibe
                            PlanSection(
                                iconName: "flame.fill",
                                title: "Calorie vibe",
                                subtitle: calorieBand.subtitle,
                                isExpanded: $expandCalories
                            ) {
                                CalorieButtonsRowLarge(band: $calorieBand)
                            }

                            Divider()

                            // Dietary requirements
                            PlanSection(
                                iconName: "leaf.circle.fill",
                                title: "Dietary needs",
                                subtitle: dietaryRequirements.isEmpty
                                    ? "Optional"
                                    : "\(dietaryRequirements.count) selected",
                                isExpanded: $expandDietary
                            ) {
                                DietaryRequirementsSection(selected: $dietaryRequirements)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
                        )
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .top)

                        Spacer(minLength: 24)
                    }
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 6)

                // Overlay while “building”
                if isPlanning {
                    PlanBuildOverlay(
                        progress: progress,
                        tagline: taglines[min(stepIndex, taglines.count - 1)],
                        imageName: Array(LIBRARY.map { $0.imageName }.prefix(3))[min(slideIndex, 2)]
                    )
                    .transition(.opacity)
                    .onAppear { runPlannerAnimation() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Scranly")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(brandOrange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 30, height: 30)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                            .accessibilityLabel("Close")
                    }
                    .buttonStyle(.plain)
                }
            }
            // Push “Scranly suggests”
            .navigationDestination(isPresented: $showSuggestions) {
                DraftPlanView(
                    title: "Scranly suggests",
                    draft: suggested,
                    effortRange: effortRange,
                    cuisineBias: cuisineBias,
                    calorieRange: calorieBand.range,   // pass kcal filter through
                    onAccept: {
                        showSuggestions = false
                        dismiss()
                    },
                    onRedoAll: { startPlanning() }
                )
            }
            // Stick the brand CTA to the bottom
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    Button(action: startPlanning) {
                        HStack(spacing: 10) {
                            Image(systemName: "wand.and.stars")
                                .font(.headline.weight(.black))
                            Text("Plan now")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(.white)
                        .background(brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.systemBackground).ignoresSafeArea())
                }
            }
        }
    }

    // MARK: - Build draft using selectedDays + controls
    private func buildDraft() -> [DraftDay] {
        let start = mondayOfThisWeek()

        // Convert selected days into weekday offsets from Monday
        let offsets: [Int] = weekdaysMF.enumerated()
            .filter { selectedDays.contains($0.element) }
            .map { $0.offset } // Mon=0 ... Fri=4

        guard !offsets.isEmpty else { return [] }

        // Filter by time + calories, fallback to time-only if needed
        var candidates = LIBRARY
            .filter { effortRange.contains($0.timeMin) && calorieBand.range.contains($0.kcal) }
        if candidates.isEmpty {
            candidates = LIBRARY.filter { effortRange.contains($0.timeMin) }
        }

        // Bias + sort
        candidates.sort {
            let aBias = $0.cuisine == cuisineBias ? -1 : 0
            let bBias = $1.cuisine == cuisineBias ? -1 : 0
            return aBias == bBias ? $0.timeMin < $1.timeMin : aBias < bBias
        }

        // Optional “leftovers” nudge
        if allowLeftovers, let first = candidates.first {
            candidates.insert(first, at: min(1, candidates.count))
        }
        guard !candidates.isEmpty else { return [] }

        // Fill selected weekdays
        var out: [DraftDay] = []
        for (i, off) in offsets.enumerated() {
            let pick = candidates[i % candidates.count]
            out.append(.init(date: addDays(start, off), recipe: pick))
        }
        return out
    }

    // MARK: - Animation
    private func slideshowImages() -> [String] {
        Array(LIBRARY.map { $0.imageName }.prefix(3))
    }

    private func runPlannerAnimation() {
        let steps = 4
        let perStep: UInt64 = 1_200_000_000 // ~4.8s total
        let imgs = slideshowImages()

        Task {
            for s in 0..<steps {
                try? await Task.sleep(nanoseconds: perStep)
                withAnimation(.easeInOut(duration: 0.28)) {
                    stepIndex = s
                    slideIndex = imgs.isEmpty ? 0 : (s % imgs.count)
                    progress = Double(s + 1) / Double(steps)
                }
            }

            let newDraft = buildDraft()
            self.suggested = newDraft
            self.showSuggestions = true

            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                self.isPlanning = false
            }
        }
    }

    private func startPlanning() {
        isPlanning = true
        progress = 0
        stepIndex = 0
        slideIndex = 0
    }
}

// MARK: - Reusable section container with chevron
fileprivate struct PlanSection<Content: View>: View {
    let iconName: String
    let title: String
    let subtitle: String?
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.headline.weight(.bold))
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// --- Helpers for sliders / chips ---

// slider-only portions row
fileprivate struct PortionsSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int> = 1...6

    var body: some View {
        Slider(
            value: Binding<Double>(
                get: { Double(value) },
                set: { value = min(range.upperBound, max(range.lowerBound, Int(round($0)))) }
            ),
            in: Double(range.lowerBound)...Double(range.upperBound),
            step: 1
        )
        .tint(brandOrange)
        .padding(.horizontal, 2)
    }
}

fileprivate struct CalorieButtonsRowLarge: View {
    @Binding var band: CalorieBand

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CalorieBand.allCases) { b in
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { band = b }
                } label: {
                    VStack(spacing: 2) {
                        Text(b.title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text(b.subtitle)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(band == b ? brandOrange : Color.black.opacity(0.2),
                                    lineWidth: band == b ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: band == b ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
                    .scaleEffect(band == b ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Bigger, full-width time preset chips
fileprivate struct TimeButtonsRowLarge: View {
    @Binding var minutes: Int
    private let presets = [15, 30, 45]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(presets, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { minutes = m }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer").font(.subheadline.weight(.bold)).opacity(0.85)
                        Text(" \(m)m")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(minutes == m ? brandOrange : Color.black.opacity(0.2),
                                    lineWidth: minutes == m ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: minutes == m ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
                    .scaleEffect(minutes == m ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tiny day tick chip
fileprivate struct DayTick: View {
    let day: Weekday
    let isOn: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(day.short)
                    .font(.caption.weight(.heavy))
                if isOn { Image(systemName: "checkmark") }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isOn ? brandOrange.opacity(0.14) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isOn ? brandOrange : .black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.short)")
        .accessibilityValue(isOn ? "selected" : "not selected")
    }
}

fileprivate extension Weekday {
    var prettyLabel: String {
        switch self {
        case .mon: "Mon"
        case .tue: "Tues"
        case .wed: "Weds"
        case .thu: "Thu"
        case .fri: "Fri"
        case .sat: "Sat"
        case .sun: "Sun"
        }
    }
}

// MARK: - Clean overlay (less chrome)
fileprivate struct PlanBuildOverlay: View {
    let progress: Double
    let tagline: String
    let imageName: String

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(brandOrange)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Center the tagline chip
                Chip(text: tagline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)

                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.black, lineWidth: 2))
                    .padding(.horizontal)

                Text("Mixing a week that fits your time and taste…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .transition(.opacity)
    }
}

fileprivate struct PortionsSliderRow: View {
    @Binding var value: Int
    let range: ClosedRange<Int> = 1...6

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Portions")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value) per meal")
                    .font(.subheadline.weight(.bold))
            }

            Slider(
                value: Binding<Double>(
                    get: { Double(value) },
                    set: { value = min(range.upperBound, max(range.lowerBound, Int(round($0)))) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(brandOrange)
            .padding(.horizontal, 2)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Tiny helpers (local, self-contained)
fileprivate struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

fileprivate struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(Capsule().stroke(.black, lineWidth: 2))
            .clipShape(Capsule())
    }
}

// MARK: - Clean “Plan hub” (minimal, focused)
struct PlanHubView: View {
    // Defaults the user asked for
    @State private var meals: Int = 3
    @State private var portions: Int = 2
    @State private var timePerMeal: Int = 30
    @State private var selectedDays: Set<Weekday> = [.wed, .thu, .fri]

    @State private var prefsExpanded = false

    // Tile popovers
    @State private var showMealsPicker = false
    @State private var showPortionsPicker = false
    @State private var showTimePicker = false
    @State private var showDaysSheet = false

    var onPlanNow: ((PlanPrefs) -> Void)?

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {

                // Title + explainer
                VStack(spacing: 6) {
                    Text("Plan your week")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("Quick setup. You can tweak anything later.")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)

                // Summary grid (tap to edit)
                LazyVGrid(columns: cols, spacing: 12) {
                    SummaryTile(title: "Meals", value: "\(meals)") {
                        showMealsPicker = true
                    }
                    SummaryTile(
                        title: "Days",
                        value: selectedDays.sorted().map(\.short).joined(separator: " • ")
                    ) { showDaysSheet = true }

                    SummaryTile(title: "Portions", value: "\(portions) each") {
                        showPortionsPicker = true
                    }
                    SummaryTile(title: "Time", value: " \(timePerMeal)m") {
                        showTimePicker = true
                    }
                }
                .padding(.horizontal)

                // Collapsed preferences (advanced)
                DisclosureGroup(isExpanded: $prefsExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        RowStepper(title: "Meals", value: $meals, range: 1...7)

                        // NEW: portions slider
                        PortionsSliderRow(value: $portions)

                        // NEW: 15/30/45 preset buttons
                        TimeButtonsRowLarge(minutes: $timePerMeal)

                        Button {
                            showDaysSheet = true
                        } label: {
                            HStack {
                                Text("Pick days")
                                Spacer()
                                Text(selectedDays.sorted().map(\.short).joined(separator: " • "))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3").font(.headline)
                        Text(prefsExpanded ? "Hide preferences" : "Show preferences")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                )
                .padding(.horizontal)

                Spacer()

                // Big CTA
                Button {
                    onPlanNow?(
                        PlanPrefs(
                            meals: meals,
                            portions: portions,
                            timePerMeal: timePerMeal,
                            days: Array(selectedDays)
                        )
                    )
                } label: {
                    Text("Plan now!")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        // Pickers / editors
        .confirmationDialog("Meals", isPresented: $showMealsPicker, titleVisibility: .visible) {
            ForEach([2,3,4,5,6], id: \.self) { n in
                Button("\(n)") { meals = n }
            }
        }
        .confirmationDialog("Portions", isPresented: $showPortionsPicker, titleVisibility: .visible) {
            ForEach(1...6, id: \.self) { n in
                Button("\(n)") { portions = n }
            }
        }
        .confirmationDialog("Time per meal", isPresented: $showTimePicker, titleVisibility: .visible) {
            ForEach([15,20,25,30,35,40,45,60], id: \.self) { m in
                Button("~\(m)m") { timePerMeal = m }
            }
        }
        .sheet(isPresented: $showDaysSheet) {
            DayPickerSheet(selected: $selectedDays)
        }
    }
}

// MARK: - Summary tile
fileprivate struct SummaryTile: View {
    let title: String
    let value: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small row stepper (compact)
fileprivate struct RowStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            HStack(spacing: 0) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: { Image(systemName: "minus").padding(8) }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 34)
                Button {
                    value = min(range.upperBound, value + step)
                } label: { Image(systemName: "plus").padding(8) }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Day picker sheet
enum Weekday: Int, CaseIterable, Identifiable, Comparable {
    case mon = 2, tue, wed, thu, fri, sat, sun = 1
    var id: Int { rawValue }
    var short: String {
        switch self {
        case .mon: return "Mon"; case .tue: return "Tue"; case .wed: return "Wed"
        case .thu: return "Thu"; case .fri: return "Fri"; case .sat: return "Sat"; case .sun: return "Sun"
        }
    }
    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.orderIndex < rhs.orderIndex }
    private var orderIndex: Int { [2,3,4,5,6,7,1].firstIndex(of: rawValue)! } // Mon…Sun
}

fileprivate struct DayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Set<Weekday>

    var body: some View {
        NavigationStack {
            List {
                ForEach(Weekday.allCases.sorted()) { day in
                    Button {
                        if selected.contains(day) { selected.remove(day) } else { selected.insert(day) }
                    } label: {
                        HStack {
                            Text(day.short)
                            Spacer()
                            if selected.contains(day) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Pick days")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Prefs payload
struct PlanPrefs {
    let meals: Int
    let portions: Int
    let timePerMeal: Int
    let days: [Weekday]
}

struct StepperPill: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.heavy))

            HStack(spacing: 0) {
                Button {
                    value = max(range.lowerBound, value - 1)
                } label: {
                    Image(systemName: "minus").padding(8)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                .opacity(value <= range.lowerBound ? 0.4 : 1)

                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .frame(minWidth: 28)

                Button {
                    value = min(range.upperBound, value + 1)
                } label: {
                    Image(systemName: "plus").padding(8)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
                .opacity(value >= range.upperBound ? 0.4 : 1)
            }
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct HeroStrip<Overlay: View>: View {
    let imageName: String
    @ViewBuilder var overlay: () -> Overlay
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.45)],
                           startPoint: .center, endPoint: .bottom)
                .frame(maxWidth: .infinity)

            overlay()
                .padding(10)
                .foregroundStyle(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}


//-------

// MARK: - Lightweight demo recipe library (for One-tap)
struct LibraryRecipe: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let cuisine: String
    let imageName: String
    let timeMin: Int
    let kcal: Int
    let emoji: String
}
fileprivate let LIBRARY: [LibraryRecipe] = [
    .init(title: "Katsu Curry",                 cuisine: "Japanese", imageName: "katsu", timeMin: 30, kcal: 680, emoji: "🍛"),
    .init(title: "Honey Garlic Salmon + Greens",cuisine: "Japanese", imageName: "katsu", timeMin: 25, kcal: 620, emoji: "🐟"),
    .init(title: "Creamy Pesto Pasta",          cuisine: "Italian",  imageName: "katsu", timeMin: 22, kcal: 710, emoji: "🍝"),
    .init(title: "Chicken Tikka Wraps",         cuisine: "Indian",   imageName: "katsu", timeMin: 20, kcal: 680, emoji: "🌯"),
    .init(title: "Chipotle Chicken Burrito",    cuisine: "Mexican",  imageName: "katsu", timeMin: 28, kcal: 730, emoji: "🌯"),
    .init(title: "Prawn Stir-fry",              cuisine: "Thai",     imageName: "katsu", timeMin: 16, kcal: 520, emoji: "🦐"),
    .init(title: "Roast Veg & Pesto Bowls",     cuisine: "Italian",  imageName: "katsu", timeMin: 35, kcal: 580, emoji: "🥦"),
    .init(title: "Harissa Chicken & Couscous",  cuisine: "Middle Eastern", imageName: "katsu", timeMin: 27, kcal: 640, emoji: "🍗"),
    .init(title: "Salmon Teriyaki Bowl",        cuisine: "Japanese", imageName: "katsu", timeMin: 20, kcal: 610, emoji: "🐟"),
    .init(title: "Veggie Green Curry",          cuisine: "Thai",     imageName: "katsu", timeMin: 24, kcal: 540, emoji: "🥬"),
]

// MARK: - Helpers
fileprivate func mondayOfThisWeek(_ d: Date = Date()) -> Date {
    let cal = Calendar.current
    return cal.date(from: cal.dateComponents([.yearForWeekOfYear,.weekOfYear], from: d))
        ?? cal.startOfDay(for: d)
}
fileprivate func addDays(_ d: Date, _ n: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: n, to: d) ?? d
}

// MARK: - SUGGESTIONS PAGE
fileprivate struct DraftPlanView: View {
    @Environment(\.dismiss) private var dismiss

        // incoming data (title ignored now)
        let title: String
        @State var draft: [DraftDay]

        // filters
        let effortRange: ClosedRange<Int>
        let cuisineBias: String
        let calorieRange: ClosedRange<Int>

        // callbacks
        var onAccept: () -> Void
        var onRedoAll: () -> Void

        // overlay for redo-all
        @State private var isRebuilding = false
        @State private var progress: Double = 0
        @State private var stepIndex: Int = 0
        @State private var slideIndex: Int = 0
        private let taglines = ["Crafting flavours", "Saving time", "Balancing macros", "Zero faff", "Matching your vibe"]

        // MAIN HEADER = tagline
        @State private var mainTagline: String = DraftPlanView.randomTagline()
        private static func randomTagline() -> String {
            ["Crafting flavours","Saving time","Balancing macros","Zero faff","Matching your vibe"].randomElement()!
        }

        // “Dinner planned in … seconds”
        @State private var buildSeconds: Double = DraftPlanView.randomBuildSeconds()
        private var buildSecondsText: String { String(format: "%.1f", buildSeconds) }
        private static func randomBuildSeconds() -> Double {
            let v = Double.random(in: 22.5...38.5); return (v * 10).rounded() / 10.0
        }

        // Week range from the canonical Mon–Fri
        private var monToFri: [Date] {
            let start = mondayOfThisWeek()
            return (0..<5).map { addDays(start, $0) }
        }
        private var rangeText: String {
            let df = DateFormatter(); df.dateFormat = "d MMM"
            guard let first = monToFri.first, let last = monToFri.last else { return "" }
            return "\(df.string(from: first)) to \(df.string(from: last))"
        }
        private func recipeFor(_ date: Date) -> LibraryRecipe? {
            let cal = Calendar.current
            return draft.first(where: { cal.isDate($0.date, inSameDayAs: date) })?.recipe
        }

        var body: some View {
            ZStack {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 10) {
                        Text(mainTagline)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)

                        // UPDATED: simple grey text, no chip
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 12, weight: .bold))
                            Text("Dinner planned in \(buildSecondsText) seconds")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)

                    Spacer(minLength: 8)

                    // Range subheader
                    Text("Your meal plan for \(rangeText)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)

                // 5-day list (always Mon–Fri)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(monToFri, id: \.self) { dayDate in
                            let rec = recipeFor(dayDate)
                            BigDraftRow(date: dayDate, recipe: rec)
                                .overlay(alignment: .trailing) {
                                    Button {
                                        reroll(for: dayDate)
                                    } label: {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing, 14)
                                }
                                .padding(.horizontal)
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }

                // Brand buttons: half width, tall, white + black border
                HStack(spacing: 12) {
                    Button {
                        startRebuild()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.headline.weight(.bold))
                            Text("Redo")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onAccept()   // parent will pop suggestions & dismiss planner
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle").font(.headline.weight(.bold))
                            Text("Accept")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                .background(.thinMaterial)
                .overlay(Divider(), alignment: .top)
            }

            // Redo-all overlay animation
            if isRebuilding {
                PlanBuildOverlay(
                    progress: progress,
                    tagline: taglines[min(stepIndex, taglines.count-1)],
                    imageName: Array(LIBRARY.map { $0.imageName }.prefix(3))[min(slideIndex, 2)]
                )
                .onAppear { runRebuildAnimation() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Scranly")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundStyle(brandOrange)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .heavy))
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.black, lineWidth: 2))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        .accessibilityLabel("Close")
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .onAppear {
            mainTagline = Self.randomTagline()
            buildSeconds = Self.randomBuildSeconds()
        }
    }

    // MARK: - Actions
    private func reroll(for date: Date) {
        var pool = LIBRARY.filter { effortRange.contains($0.timeMin) && calorieRange.contains($0.kcal) }
        if pool.isEmpty { pool = LIBRARY.filter { effortRange.contains($0.timeMin) } }

        pool.sort {
            let aBias = $0.cuisine == cuisineBias ? -1 : 0
            let bBias = $1.cuisine == cuisineBias ? -1 : 0
            return aBias == bBias ? $0.timeMin < $1.timeMin : aBias < bBias
        }
        guard let pick = pool.randomElement() else { return }
        let cal = Calendar.current
        if let idx = draft.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            draft[idx].recipe = pick
        } else {
            draft.append(.init(date: date, recipe: pick))
        }
    }

    private func startRebuild() {
        isRebuilding = true
        progress = 0
        stepIndex = 0
        slideIndex = 0
    }

    private func runRebuildAnimation() {
        let steps = 5
        let perStep: UInt64 = 3_000_000_000 // 3s per step ≈ 15s
        let imgs = Array(LIBRARY.map { $0.imageName }.prefix(3))

        Task {
            for s in 0..<steps {
                try? await Task.sleep(nanoseconds: perStep)
                withAnimation(.easeInOut(duration: 0.35)) {
                    stepIndex = s
                    slideIndex = imgs.isEmpty ? 0 : (s % imgs.count)
                    progress = Double(s + 1) / Double(steps)
                }
            }

            // Rebuild across Mon–Fri with filters
            let start = mondayOfThisWeek()
            var pool = LIBRARY.filter { effortRange.contains($0.timeMin) && calorieRange.contains($0.kcal) }
            if pool.isEmpty { pool = LIBRARY.filter { effortRange.contains($0.timeMin) } }

            pool.sort {
                let aBias = $0.cuisine == cuisineBias ? -1 : 0
                let bBias = $1.cuisine == cuisineBias ? -1 : 0
                return aBias == bBias ? $0.timeMin < $1.timeMin : aBias < bBias
            }
            var newDraft: [DraftDay] = []
            for i in 0..<5 {
                let pick = pool[i % pool.count]
                newDraft.append(.init(date: addDays(start, i), recipe: pick))
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                self.draft = newDraft
                self.isRebuilding = false
                self.buildSeconds = Self.randomBuildSeconds()
                self.mainTagline = Self.randomTagline()
            }
        }
    }
}

// Bigger chip used on the suggestions page
fileprivate struct BigDraftRow: View {
    let date: Date
    let recipe: LibraryRecipe?

    private var weekday: String { date.formatted(.dateTime.weekday(.wide)) }
    private var dateChip: String { date.formatted(Date.FormatStyle().day().month(.abbreviated)) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(brandOrange.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.black.opacity(0.12), lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                Text(recipe?.emoji ?? "🍽️").font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(weekday)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))

                if let r = recipe {
                    Text(r.title)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .lineLimit(2)
                } else {
                    Text("No dinner planned")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(dateChip)
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color(.secondarySystemBackground)))
                    .overlay(Capsule().stroke(.black.opacity(0.2), lineWidth: 1))

                if let r = recipe {
                    Text("\(r.timeMin)m • \(r.kcal) kcal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("—")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 14)
        .padding(.trailing, 52) // space for reroll icon overlay
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.black.opacity(0.18), lineWidth: 1.8))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Little reusable bits
fileprivate struct SelectPill: View {
    let text: String
    let selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption.weight(.heavy))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? .black : .black.opacity(0.2), lineWidth: selected ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct HeroCollage: View {
    let imageNames: [String]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if let a = imageNames.first {
                    Image(a).resizable().scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .overlay(Color.black.opacity(0.10))
                } else {
                    Color(.systemGray5)
                }
                HStack(spacing: 8) {
                    ForEach(imageNames.prefix(3), id: \.self) { n in
                        Image(n).resizable().scaledToFill()
                            .frame(width: (w-16)/3, height: h*0.82)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.black.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black, lineWidth: 2))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
    }
}

// MARK: - Draft row (preview)
fileprivate struct DraftRow: View {
    let day: DraftDay

    private var weekday: String { day.date.formatted(.dateTime.weekday(.wide)) }
    private var dateChip: String { day.date.formatted(Date.FormatStyle().day().month(.abbreviated)) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(brandOrange.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 1))
                    .frame(width: 30, height: 30)
                Text(day.recipe.emoji).font(.footnote)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(weekday)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                Text(day.recipe.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(dateChip)
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Capsule().fill(Color(.secondarySystemBackground)))
                    .overlay(Capsule().stroke(.black.opacity(0.2), lineWidth: 1))

                Text("\(day.recipe.timeMin)m • \(day.recipe.kcal) kcal")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 12)
        .padding(.trailing, 44) // space for reroll icon overlay
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black.opacity(0.15), lineWidth: 1.5))
    }
}

// MARK: - Draft model
struct DraftDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var recipe: LibraryRecipe
}

// ==== Everything below here is your existing Plan screen ====
// (Left as-is so the project continues to compile)

// Quote helper (kept local so ExpandedDayCardContent compiles)
fileprivate func quoteForMeal(_ title: String?) -> String {
    guard let t = title?.lowercased(), !t.isEmpty else {
        return "Let’s lock in dinner. We’ll keep it realistic."
    }
    if t.contains("katsu") { return "Crispy, cosy, total comfort. You earned this 😌" }
    if t.contains("pesto") || t.contains("pasta") { return "Twirls, sauce, comfort. You nailed dinner 🍝" }
    if t.contains("salmon") { return "Protein, flavour, glow. Chef mode 🐟" }
    return "Good food, good plan — Scranly style 👨‍🍳"
}

fileprivate struct WeekNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

private func ctaLabel(for dayDate: Date, isToday: Bool) -> (emoji: String, text: String, bg: Color, fg: Color) {
    let cal = Calendar.current
    let startOfToday = cal.startOfDay(for: Date())
    if isToday { return ("🍽", "Cook now!", brandOrange, .white) }
    if dayDate < startOfToday { return ("✓", "Logged", Color(.secondarySystemBackground), .primary) }
    return ("✨", "Plan this dinner", Color(.secondarySystemBackground), .primary)
}

// MARK: - Top bar (now triggers FULL SCREEN cover)
fileprivate struct PlanTopBar: View {
    var onPlanTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Plan")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)

                Spacer()

                Button(action: onPlanTap) {
                    Label("Plan", systemImage: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .buttonStyle(MiniBorderButtonStyle()) // same button style as Discover liked button
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

@MainActor
final class WeekPlanViewModel: ObservableObject {
    @Published var weekStart: Date
    @Published var workWeek: [DayPlan] = []
    private let cal = Calendar.current

    init() {
        let today = cal.startOfDay(for: Date())
        if let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) {
            self.weekStart = monday
        } else {
            self.weekStart = today
        }
        self.workWeek = Self.demoWeek(startingAt: weekStart, calendar: cal)
    }

    func goToPreviousWeek() {
        guard let newStart = cal.date(byAdding: .day, value: -7, to: weekStart) else { return }
        weekStart = newStart
        workWeek  = Self.emptyWeek(startingAt: newStart, calendar: cal)
    }

    func goToNextWeek() {
        guard let newStart = cal.date(byAdding: .day, value: 7, to: weekStart) else { return }
        weekStart = newStart
        workWeek  = Self.emptyWeek(startingAt: newStart, calendar: cal)
    }
}

private extension WeekPlanViewModel {
    static func demoWeek(startingAt monday: Date, calendar cal: Calendar) -> [DayPlan] {
        func makeMeal(title: String, time: String, kcal: Int, emoji: String) -> PlannedMeal {
            PlannedMeal(
                recipe: Recipe.mock(
                    title: title,
                    calories: kcal,
                    protein: Int.random(in: 20...50),
                    carbs: Int.random(in: 20...70),
                    fat: Int.random(in: 5...30)
                ),
                title: title,
                time: time,
                kcal: kcal,
                slot: .dinner,
                emoji: emoji,
                imageURL: nil
            )
        }

        let katsu       = makeMeal(title: "Katsu Curry",                      time: "19:15", kcal: 680, emoji: "🍛")
        let honeyGarlic = makeMeal(title: "Honey Garlic Salmon + Greens",     time: "19:00", kcal: 620, emoji: "🐟")
        let pesto       = makeMeal(title: "Creamy Pesto Pasta",               time: "19:30", kcal: 710, emoji: "🍝")
        let tikka       = makeMeal(title: "Chicken Tikka Wraps",              time: "20:00", kcal: 680, emoji: "🌯")
        let burrito     = makeMeal(title: "Chipotle Chicken Burrito Bowl",    time: "19:45", kcal: 730, emoji: "🌯")

        return (0..<5).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: monday)!
            switch offset {
            case 0: return DayPlan(date: d, meals: [katsu])
            case 1: return DayPlan(date: d, meals: [honeyGarlic])
            case 2: return DayPlan(date: d, meals: [pesto])
            case 3: return DayPlan(date: d, meals: [tikka])
            case 4: return DayPlan(date: d, meals: [burrito])
            default: return DayPlan(date: d, meals: [])
            }
        }
    }

    static func emptyWeek(startingAt monday: Date, calendar cal: Calendar) -> [DayPlan] {
        (0..<5).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: monday)!
            return DayPlan(date: d, meals: [])
        }
    }
}

// --- Existing Plan UI kept the same (expanded/collapsed rows etc.) ---

fileprivate struct TopCornersOnly: Shape {
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        let bez = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bez.cgPath)
    }
}
fileprivate struct BottomCornersOnly: Shape {
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(p.cgPath)
    }
}

fileprivate struct ExpandedDayCardContent: View {
    let dayPlan: DayPlan
    let isToday: Bool

    private var meal: PlannedMeal? { dayPlan.meals.first }
    private var dayLabel: String { dayPlan.date.formatted(.dateTime.weekday(.wide)) }
    private var dateLabel: String { dayPlan.date.formatted(Date.FormatStyle().day().month(.abbreviated)) }
    private var footerCTA: (emoji: String, text: String, bg: Color, fg: Color) {
        ctaLabel(for: dayPlan.date, isToday: isToday)
    }

    private let corner: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image("katsu")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(TopCornersOnly(radius: corner))

                LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.0)],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .clipShape(TopCornersOnly(radius: corner))

                VStack(alignment: .leading, spacing: 6) {
                    Text(meal?.title ?? "No dinner planned")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text(dayLabel)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(dateLabel.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(
                                Capsule().fill(isToday ? brandOrange.opacity(0.18) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                Capsule().stroke(isToday ? brandOrange : Color.black.opacity(0.2), lineWidth: 1.2)
                            )
                    }

                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .background(brandOrange.opacity(0.15))
                            .overlay(Capsule().stroke(brandOrange, lineWidth: 1.2))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Text(quoteForMeal(meal?.title))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color(.systemBackground)
                    .overlay(Rectangle().fill(Color.black.opacity(0.08)).frame(height: 0.5), alignment: .top)
            )

            HStack(spacing: 6) {
                let cta = footerCTA
                Text(cta.emoji).font(.system(size: 16, weight: .semibold))
                Text(cta.text).font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(footerCTA.bg)
            .foregroundStyle(footerCTA.fg)
            .clipShape(BottomCornersOnly(radius: corner))
        }
        .background(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        .contentShape(Rectangle())
    }
}

fileprivate struct CollapsedDayRow: View {
    let dayPlan: DayPlan
    let isToday: Bool
    var onTapExpand: () -> Void

    private var meal: PlannedMeal? { dayPlan.meals.first }
    private var dayLabel: String { dayPlan.date.formatted(.dateTime.weekday(.wide)) }
    private var dateLabel: String { dayPlan.date.formatted(Date.FormatStyle().day().month(.abbreviated)) }

    var body: some View {
        Button(action: onTapExpand) {
            HStack(spacing: 12) {
                Image("katsu")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(dayLabel)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(dateLabel.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(
                                Capsule().fill(isToday ? brandOrange.opacity(0.15) : Color(.secondarySystemBackground))
                            )
                            .overlay(Capsule().stroke(isToday ? brandOrange : Color.black.opacity(0.2), lineWidth: 1.2))

                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .padding(.vertical, 1.5)
                                .padding(.horizontal, 5)
                                .background(brandOrange.opacity(0.15))
                                .overlay(Capsule().stroke(brandOrange, lineWidth: 1.2))
                                .clipShape(Capsule())
                        }
                    }

                    if let m = meal {
                        Text(m.title)
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text("No dinner planned")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(isToday ? 0.5 : 0.15), lineWidth: isToday ? 2 : 1.5)
            )
            .shadow(color: .black.opacity(isToday ? 0.08 : 0.04), radius: isToday ? 6 : 3, y: isToday ? 3 : 2)
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct WeekRangeRow: View {
    let startDate: Date
    let endDate: Date
    var onPrev: () -> Void
    var onNext: () -> Void

    private var dateLine: String {
        let df = DateFormatter(); df.dateFormat = "d MMM"
        return "\(df.string(from: startDate)) – \(df.string(from: endDate))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.heavy))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(WeekNavButtonStyle())

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text("Your")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                    Text("Scranly")
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundStyle(brandOrange)
                    Text("plan")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                }
                Text(dateLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.heavy))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(WeekNavButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

struct PlanView: View {
    @StateObject private var vm = WeekPlanViewModel()
    @State private var expandedIndex: Int = 0
    @State private var path = NavigationPath()
    @State private var showPlanFullScreen = false // FULL SCREEN toggle

    private var days: [DayPlan] { vm.workWeek }
    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 4, to: vm.weekStart) ?? vm.weekStart
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tap opens FULL SCREEN cover rather than a medium/large sheet
                    PlanTopBar(onPlanTap: { showPlanFullScreen = true })
                        .background(Color(.systemBackground).ignoresSafeArea(edges: .top))

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {

                            WeekRangeRow(
                                startDate: vm.weekStart,
                                endDate: weekEnd,
                                onPrev: { vm.goToPreviousWeek(); expandedIndex = 0 },
                                onNext: { vm.goToNextWeek();  expandedIndex = 0 }
                            )

                            ForEach(days.indices, id: \.self) { idx in
                                let day = days[idx]
                                let isToday = Calendar.current.isDateInToday(day.date)

                                Group {
                                    if idx == expandedIndex {
                                        if let recipe = day.meals.first?.recipe {
                                            NavigationLink(value: recipe) {
                                                ExpandedDayCardContent(dayPlan: day, isToday: isToday)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            ExpandedDayCardContent(dayPlan: day, isToday: isToday)
                                        }
                                    } else {
                                        CollapsedDayRow(
                                            dayPlan: day,
                                            isToday: isToday,
                                            onTapExpand: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    expandedIndex = idx
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
            .onAppear {
                expandedIndex = days.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) ?? 0
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(meal: recipe)
            }
            // PRESENT FULL SCREEN (fills the page)
            .fullScreenCover(isPresented: $showPlanFullScreen) {
                PlanOptionsView() // now pushes to “Scranly suggests”
            }
        }
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PlanView()
        }
        .preferredColorScheme(.light)
    }
}

// (Optional) Your existing PlanOptionCard kept here if needed elsewhere.
struct PlanOptionCard: View {
    let title: String
    let subtitle: String
    let imageName: String?
    let systemFallback: String
    let imageOnRight: Bool

    private let cardHeight: CGFloat = 280
    private let corner: CGFloat = 18
    private let innerPad: CGFloat = 18

    var body: some View {
        GeometryReader { gr in
            let imgW = max(170, min(gr.size.width * 0.42, 230))

            HStack(spacing: 16) {
                if !imageOnRight {
                    cardImage
                        .frame(width: imgW, height: cardHeight - 32)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 26, weight: .heavy, design: .serif))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    let continueLabel = HStack(spacing: 6) {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                    if imageOnRight {
                        continueLabel.frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        continueLabel.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if imageOnRight {
                    cardImage
                        .frame(width: imgW, height: cardHeight - 32)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(innerPad)
            .frame(height: cardHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.black, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .padding(.horizontal)
        }
        .frame(height: cardHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    @ViewBuilder private var cardImage: some View {
        if let name = imageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
                .background(Color.white)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                Image(systemName: systemFallback)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(brandOrange)
            }
        }
    }
}
