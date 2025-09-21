import SwiftUI
import Charts

// MARK: - Brand
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Shared label / button styles (orange icon + black text)
// Use for the sticky bottom button.
fileprivate struct OrangeIconBlackTextLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(brandOrange)
            configuration.title
                .foregroundStyle(.black)
        }
    }
}

// MARK: - Metric dropdown styled like "Edit goals"
fileprivate struct MetricMenu: View {
    @Binding var selection: Metric

    var body: some View {
        Menu {
            ForEach(Metric.allCases) { m in
                Button {
                    selection = m
                } label: {
                    Label(m.menuTitle, systemImage: m.menuIcon)
                }
            }
        } label: {
            // Custom label mimicking MiniBorderButtonStyle
            HStack(spacing: 8) {
                Image(systemName: selection.menuIcon)
                    .foregroundStyle(brandOrange)
                Text(selection.menuTitle)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        // keeps it tappable without extra highlight
        .buttonStyle(.plain)
    }
}

fileprivate struct WhiteOrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(OrangeIconBlackTextLabelStyle())
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// Mini version for “Edit goals”
fileprivate struct MiniBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(OrangeIconBlackTextLabelStyle())
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Models

fileprivate struct IntakeEntry: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var name: String
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var kcal: Double { proteinG * 4 + carbsG * 4 + fatG * 9 }
}

fileprivate struct DayTotals: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let calories: Double
    var weekdayShort: String {
        let f = DateFormatter(); f.dateFormat = "EE"; return f.string(from: date)
    }
}

// MARK: - Seed (30 days + “pre-tracked” today)

fileprivate enum TVSeed {
    static func daysBack(_ n: Int, from ref: Date = Date()) -> [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: ref)
        return (0..<n).compactMap { cal.date(byAdding: .day, value: -$0, to: start) }.reversed()
    }

    static func entries(days: Int = 30) -> [IntakeEntry] {
        let cal = Calendar.current
        let ds = daysBack(days)
        var out: [IntakeEntry] = []

        for d in ds {
            let base = 1950.0 + Double(Int.random(in: -250...300))
            let p = max(60, (base * 0.25)/4 + Double.random(in: -12...12))
            let c = max(120, (base * 0.50)/4 + Double.random(in: -18...18))
            let f = max(40,  (base * 0.25)/9 + Double.random(in: -8...8))
            let splits: [(String, Double)] = [("Breakfast",0.25),("Lunch",0.30),("Dinner",0.35),("Snack",0.10)]
            for (name, pct) in splits {
                out.append(.init(date: d, name: name, proteinG: p*pct, carbsG: c*pct, fatG: f*pct))
            }
        }

        if let today = ds.last {
            out.removeAll { cal.isDate($0.date, inSameDayAs: today) }
            out.append(contentsOf: [
                .init(date: today, name: "Overnight oats",      proteinG: 22, carbsG: 48, fatG: 9),
                .init(date: today, name: "Chicken Caesar wrap", proteinG: 32, carbsG: 42, fatG: 18),
                .init(date: today, name: "Greek yogurt",        proteinG: 17, carbsG: 12, fatG: 4),
                .init(date: today, name: "Katsu chicken curry", proteinG: 38, carbsG: 70, fatG: 22),
            ])
        }
        return out
    }
}

// MARK: - Helpers

fileprivate func totals(for date: Date, from entries: [IntakeEntry]) -> DayTotals {
    let cal = Calendar.current
    let todays = entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    let p = todays.map(\.proteinG).reduce(0,+)
    let c = todays.map(\.carbsG).reduce(0,+)
    let f = todays.map(\.fatG).reduce(0,+)
    return DayTotals(date: cal.startOfDay(for: date), proteinG: p, carbsG: c, fatG: f, calories: p*4 + c*4 + f*9)
}

fileprivate func weekDates(_ n: Int = 7) -> [Date] { TVSeed.daysBack(n) }

// MARK: - Gradients / Metric
fileprivate enum Metric: String, CaseIterable, Identifiable {
    case calories, protein, carbs, fat
    var id: String { rawValue }
    var title: String {
        switch self {
        case .calories: return "Calories"
        case .protein:  return "Protein"
        case .carbs:    return "Carbs"
        case .fat:      return "Fat"
        }
    }
}


// Which metric to plot in the weekly chart
// Which metric to show
fileprivate extension Metric {
    var menuTitle: String {
        switch self {
        case .calories: return "Calories"
        case .protein:  return "Protein"
        case .carbs:    return "Carbs"
        case .fat:      return "Fat"
        }
    }
    var menuIcon: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein:  return "bolt.fill"
        case .carbs:    return "leaf.fill"
        case .fat:      return "drop.fill"
        }
    }
}

fileprivate extension Metric {
    var gradient: LinearGradient { metricGradient(self) }
}

// Gradient for each metric (soft top→solid bottom)
fileprivate func metricGradient(_ metric: Metric) -> LinearGradient {
    let top: Color
    let bottom: Color
    switch metric {
    case .calories: top = brandOrange.opacity(0.55); bottom = brandOrange
    case .protein:  top = .blue.opacity(0.55);       bottom = .blue
    case .carbs:    top = .green.opacity(0.55);      bottom = .green
    case .fat:      top = .pink.opacity(0.55);       bottom = .pink
    }
    return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
}

// Clamp 0...1 as CGFloat for bar widths
fileprivate func clampProgress(_ value: Double, goal: Double) -> CGFloat {
    guard goal > 0 else { return 0 }
    return CGFloat(max(0, min(1, value / goal)))
}

fileprivate func gradient(for metric: Metric) -> LinearGradient {
    switch metric {
    case .calories:
        return LinearGradient(colors: [Color.orange.opacity(0.6), brandOrange],
                              startPoint: .leading, endPoint: .trailing)
    case .protein:
        return LinearGradient(colors: [Color.blue.opacity(0.55), Color.blue],
                              startPoint: .leading, endPoint: .trailing)
    case .carbs:
        return LinearGradient(colors: [Color.green.opacity(0.55), Color.green],
                              startPoint: .leading, endPoint: .trailing)
    case .fat:
        return LinearGradient(colors: [Color.pink.opacity(0.55), Color.pink],
                              startPoint: .leading, endPoint: .trailing)
    }
}



// MARK: - UI Components

// Big loud header + Edit goals
fileprivate struct TrackHeader: View {
    var onEditGoals: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Track")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .kerning(0.5)
            Spacer()
            Button(action: onEditGoals) {
                Label("Edit goals", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(MiniBorderButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}

// Thick black-border banner with primary value (streak / consistency)
fileprivate struct StreakConsistencyBanner: View {
    let streakDays: Int
    let consistency: Int  // days tracked this week (0...7)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(brandOrange.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(brandOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(streakDays)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                        Text("day streak")
                            .font(.callout.weight(.semibold))
                            .padding(.vertical, 2).padding(.horizontal, 8)
                            .overlay(Capsule().stroke(brandOrange.opacity(0.6), lineWidth: 1.5))
                    }
                    Text("Consistency: \(consistency)/7 this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Consistency \(consistency) of 7 this week")
                }
                Spacer()
            }

            Text(contextLine(streakDays: streakDays, consistency: consistency))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    private func contextLine(streakDays: Int, consistency: Int) -> String {
        if streakDays >= 14 { return "Hot streak! Two weeks of momentum 🔥" }
        if consistency >= 5 { return "Solid week—keep it rolling 💪" }
        return "Every log counts. You’ve got this 🙌"
    }
}


// Weekly chart for Calories/Protein/Carbs/Fat


// Gradient macro progress
// Gradient macro bar (Today)
fileprivate struct MacroProgress: View {
    let title: String
    let grams: Double
    let goalGrams: Double
    let metric: Metric   // drives the gradient color

    private var progress: CGFloat { clampProgress(grams, goal: goalGrams) }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(grams))g / \(Int(goalGrams))g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 10)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(metricGradient(metric))
                        .frame(width: geo.size.width * progress, height: 10)
                }
                .frame(height: 10)
            }
        }
    }
}

// One-line intake row (removable)
fileprivate struct IntakeRow: View {
    let entry: IntakeEntry
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("•").font(.headline)
            Text(entry.name).font(.subheadline.weight(.semibold)).lineLimit(1)
            Spacer(minLength: 8)
            Text("P\(Int(entry.proteinG)) C\(Int(entry.carbsG)) F\(Int(entry.fatG))")
                .font(.caption).foregroundStyle(.secondary)
            Text("\(Int(entry.kcal)) kcal")
                .font(.subheadline.weight(.semibold)).monospacedDigit()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// Weekly metric chart (gradient + goal line)
// Weekly chart that can show Calories / Protein / Carbs / Fat
fileprivate struct WeeklyMetricChart: View {
    let data: [DayTotals]
    let metric: Metric
    let goal: Double  // pass the right daily goal for the selected metric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart(data) { d in
                BarMark(
                    x: .value("Day", d.weekdayShort),
                    y: .value(metric.title, value(for: d))
                )
                .foregroundStyle(metric.gradient)

                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.55))
            }
            .frame(height: 180)
        }
    }

    private func value(for d: DayTotals) -> Double {
        switch metric {
        case .calories: return d.calories
        case .protein:  return d.proteinG
        case .carbs:    return d.carbsG
        case .fat:      return d.fatG
        }
    }
}

// Add Intake Sheet (simple)
fileprivate struct AddIntakeSheet: View {
    var onAdd: (IntakeEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you eat?") {
                    TextField("Name (e.g. Chicken wrap)", text: $name)
                }
                Section("Macros") {
                    Stepper("Protein: \(Int(protein)) g", value: $protein, in: 0...200, step: 2)
                    Stepper("Carbs: \(Int(carbs)) g",     value: $carbs,   in: 0...300, step: 5)
                    Stepper("Fat: \(Int(fat)) g",         value: $fat,     in: 0...120, step: 2)
                    LabeledContent("Calories") { Text("\(Int(protein*4 + carbs*4 + fat*9)) kcal") }
                }
            }
            .navigationTitle("Add food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let e = IntakeEntry(date: Date(),
                                            name: name.isEmpty ? "Custom" : name,
                                            proteinG: protein, carbsG: carbs, fatG: fat)
                        onAdd(e); dismiss()
                    }
                    .tint(brandOrange)
                }
            }
        }
    }
}

// Goals sheet (simple calorie goal)
fileprivate struct GoalsSheet: View {
    @Binding var dailyGoal: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily target") {
                    Stepper("Calories: \(Int(dailyGoal)) kcal", value: $dailyGoal, in: 1200...4000, step: 50)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - TRACK VIEW (drop-in)

struct TrackView: View {
    // State
    @State private var dailyGoal: Double = 2100
    @State private var entries: [IntakeEntry] = TVSeed.entries(days: 30)
    @State private var weekMetric: Metric = .calories
    @State private var showAdd = false
    @State private var showGoals = false



    // Derived
    private var todayTotals: DayTotals { totals(for: Date(), from: entries) }

    // Macro gram goals inferred from calorie goal (25/50/25 split)
    private var proteinGoalG: Double { (dailyGoal * 0.25) / 4 }
    private var carbsGoalG:   Double { (dailyGoal * 0.50) / 4 }
    private var fatGoalG:     Double { (dailyGoal * 0.25) / 9 }

    private var thisWeek: [DayTotals] { weekDates().map { totals(for: $0, from: entries) } }

    // Streak & consistency (toy logic: a “tracked” day means > 300 kcal logged)
    private var consistency: Int { thisWeek.filter { $0.calories > 300 }.count }
    private var streakDays: Int {
        let cal = Calendar.current
        var d = cal.startOfDay(for: Date())
        var s = 0
        while true {
            let t = totals(for: d, from: entries)
            if t.calories > 300 { s += 1 } else { break }
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return s
    }

    private var todayEntries: [IntakeEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Header
                    TrackHeader(onEditGoals: { showGoals = true })

                    // Value banner (streak & consistency)
                    StreakConsistencyBanner(streakDays: streakDays, consistency: consistency)

                    // “Today” section title (big + loud)
                    HStack {
                        Text("TODAY")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.secondary)
                            .kerning(0.7)
                        Spacer()
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Macro progress (gradient bars)
                    VStack(spacing: 12) {
                        MacroProgress(title: "Protein",
                                      grams: todayTotals.proteinG,
                                      goalGrams: proteinGoalG,
                                      metric: .protein)

                        MacroProgress(title: "Carbs",
                                      grams: todayTotals.carbsG,
                                      goalGrams: carbsGoalG,
                                      metric: .carbs)

                        MacroProgress(title: "Fat",
                                      grams: todayTotals.fatG,
                                      goalGrams: fatGoalG,
                                      metric: .fat)

                        // Calories gradient bar
                        VStack(spacing: 6) {
                            HStack {
                                Text("Calories").font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Int(todayTotals.calories)) / \(Int(dailyGoal)) kcal")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)).frame(height: 10)
                                GeometryReader { geo in
                                    let p = clampProgress(todayTotals.calories, goal: dailyGoal)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(metricGradient(.calories))
                                        .frame(width: geo.size.width * p, height: 10)
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Today’s intakes (one-liners)
                    if !todayEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today’s entries")
                                .font(.headline)
                            VStack(spacing: 0) {
                                ForEach(todayEntries) { e in
                                    IntakeRow(entry: e) {
                                        entries.removeAll { $0.id == e.id }
                                    }
                                    if e.id != todayEntries.last?.id {
                                        Divider().padding(.leading, 12)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                    }

                    // Weekly chart + metric toggle inline
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("This week")
                                .font(.headline)
                            Spacer()
                            MetricMenu(selection: $weekMetric)
                        }
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .padding(.horizontal)

                        let metricGoal: Double = {
                            switch weekMetric {
                            case .calories: return dailyGoal
                            case .protein:  return proteinGoalG
                            case .carbs:    return carbsGoalG
                            case .fat:      return fatGoalG
                            }
                        }()

                        WeeklyMetricChart(data: thisWeek, metric: weekMetric, goal: metricGoal)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 90)
                }
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground).ignoresSafeArea()) // white
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button { showAdd = true } label: { Label("Add food", systemImage: "plus") }
                        .buttonStyle(WhiteOrangeButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial)
            }
        }
        // Rounded system font gives it that “slick” vibe
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
        .sheet(isPresented: $showAdd) {
            AddIntakeSheet { new in entries.append(new) }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showGoals) {
            GoalsSheet(dailyGoal: $dailyGoal)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Preview
#Preview {
    TrackView()
}
