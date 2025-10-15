//import SwiftUI
//import Charts
//
//// MARK: - Brand
//fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)
//
//// MARK: - Shared label / button styles (orange icon + black text)
//// Use for the sticky bottom button.
//fileprivate struct OrangeIconBlackTextLabelStyle: LabelStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack(spacing: 8) {
//            configuration.icon
//                .foregroundStyle(brandOrange)
//            configuration.title
//                .foregroundStyle(.black)
//        }
//    }
//}
//
//// MARK: - Metric dropdown styled like "Edit goals"
//fileprivate struct MetricMenu: View {
//    @Binding var selection: Metric
//
//    var body: some View {
//        Menu {
//            ForEach(Metric.allCases) { m in
//                Button {
//                    selection = m
//                } label: {
//                    Label(m.menuTitle, systemImage: m.menuIcon)
//                }
//            }
//        } label: {
//            // Custom label mimicking MiniBorderButtonStyle
//            HStack(spacing: 8) {
//                Image(systemName: selection.menuIcon)
//                    .foregroundStyle(brandOrange)
//                Text(selection.menuTitle)
//                    .font(.system(size: 14, weight: .heavy, design: .rounded))
//                    .foregroundStyle(.black)
//                Image(systemName: "chevron.up.chevron.down")
//                    .font(.caption2.weight(.bold))
//                    .foregroundStyle(.secondary)
//                    .padding(.leading, 2)
//            }
//            .padding(.vertical, 6)
//            .padding(.horizontal, 10)
//            .background(Color(.systemBackground))
//            .overlay(
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .stroke(Color.black, lineWidth: 2)
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
//        }
//        // keeps it tappable without extra highlight
//        .buttonStyle(.plain)
//    }
//}
//
//fileprivate struct WhiteOrangeButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .labelStyle(OrangeIconBlackTextLabelStyle())
//            .font(.system(size: 16, weight: .heavy, design: .rounded))
//            .padding(.vertical, 12)
//            .frame(maxWidth: .infinity)
//            .background(Color(.systemBackground))
//            .overlay(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .stroke(Color.black, lineWidth: 3)
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//            .scaleEffect(configuration.isPressed ? 0.98 : 1)
//            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
//    }
//}
//
//// Mini version for “Edit goals”
//fileprivate struct MiniBorderButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .labelStyle(OrangeIconBlackTextLabelStyle())
//            .font(.system(size: 14, weight: .heavy, design: .rounded))
//            .padding(.vertical, 6).padding(.horizontal, 10)
//            .background(Color(.systemBackground))
//            .overlay(
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .stroke(Color.black, lineWidth: 2)
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
//            .scaleEffect(configuration.isPressed ? 0.98 : 1)
//    }
//}
//
//// MARK: - Models
//


struct IntakeEntry: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var name: String
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var kcal: Double { proteinG * 4 + carbsG * 4 + fatG * 9 }
}
//
//fileprivate struct DayTotals: Identifiable, Hashable {
//    let id = UUID()
//    let date: Date
//    let proteinG: Double
//    let carbsG: Double
//    let fatG: Double
//    let calories: Double
//    var weekdayShort: String {
//        let f = DateFormatter(); f.dateFormat = "EE"; return f.string(from: date)
//    }
//}
//
//// MARK: - Seed (30 days + “pre-tracked” today)
//
//fileprivate enum TVSeed {
//    static func daysBack(_ n: Int, from ref: Date = Date()) -> [Date] {
//        let cal = Calendar.current
//        let start = cal.startOfDay(for: ref)
//        return (0..<n).compactMap { cal.date(byAdding: .day, value: -$0, to: start) }.reversed()
//    }
//
//    static func entries(days: Int = 30) -> [IntakeEntry] {
//        let cal = Calendar.current
//        let ds = daysBack(days)
//        var out: [IntakeEntry] = []
//
//        for d in ds {
//            let base = 1950.0 + Double(Int.random(in: -250...300))
//            let p = max(60, (base * 0.25)/4 + Double.random(in: -12...12))
//            let c = max(120, (base * 0.50)/4 + Double.random(in: -18...18))
//            let f = max(40,  (base * 0.25)/9 + Double.random(in: -8...8))
//            let splits: [(String, Double)] = [("Breakfast",0.25),("Lunch",0.30),("Dinner",0.35),("Snack",0.10)]
//            for (name, pct) in splits {
//                out.append(.init(date: d, name: name, proteinG: p*pct, carbsG: c*pct, fatG: f*pct))
//            }
//        }
//
//        if let today = ds.last {
//            out.removeAll { cal.isDate($0.date, inSameDayAs: today) }
//            out.append(contentsOf: [
//                .init(date: today, name: "Overnight oats",      proteinG: 22, carbsG: 48, fatG: 9),
//                .init(date: today, name: "Chicken Caesar wrap", proteinG: 32, carbsG: 42, fatG: 18),
//                .init(date: today, name: "Greek yogurt",        proteinG: 17, carbsG: 12, fatG: 4),
//                .init(date: today, name: "Katsu chicken curry", proteinG: 38, carbsG: 70, fatG: 22),
//            ])
//        }
//        return out
//    }
//}
//
//// MARK: - Helpers
//
//fileprivate func totals(for date: Date, from entries: [IntakeEntry]) -> DayTotals {
//    let cal = Calendar.current
//    let todays = entries.filter { cal.isDate($0.date, inSameDayAs: date) }
//    let p = todays.map(\.proteinG).reduce(0,+)
//    let c = todays.map(\.carbsG).reduce(0,+)
//    let f = todays.map(\.fatG).reduce(0,+)
//    return DayTotals(date: cal.startOfDay(for: date), proteinG: p, carbsG: c, fatG: f, calories: p*4 + c*4 + f*9)
//}
//
//fileprivate func weekDates(_ n: Int = 7) -> [Date] { TVSeed.daysBack(n) }
//
//// MARK: - Gradients / Metric
//fileprivate enum Metric: String, CaseIterable, Identifiable {
//    case calories, protein, carbs, fat
//    var id: String { rawValue }
//    var title: String {
//        switch self {
//        case .calories: return "Calories"
//        case .protein:  return "Protein"
//        case .carbs:    return "Carbs"
//        case .fat:      return "Fat"
//        }
//    }
//}
//
//
//// Which metric to plot in the weekly chart
//// Which metric to show
//fileprivate extension Metric {
//    var menuTitle: String {
//        switch self {
//        case .calories: return "Calories"
//        case .protein:  return "Protein"
//        case .carbs:    return "Carbs"
//        case .fat:      return "Fat"
//        }
//    }
//    var menuIcon: String {
//        switch self {
//        case .calories: return "flame.fill"
//        case .protein:  return "bolt.fill"
//        case .carbs:    return "leaf.fill"
//        case .fat:      return "drop.fill"
//        }
//    }
//}
//
//fileprivate extension Metric {
//    var gradient: LinearGradient { metricGradient(self) }
//}
//
//// Gradient for each metric (soft top→solid bottom)
//fileprivate func metricGradient(_ metric: Metric) -> LinearGradient {
//    let top: Color
//    let bottom: Color
//    switch metric {
//    case .calories: top = brandOrange.opacity(0.55); bottom = brandOrange
//    case .protein:  top = .blue.opacity(0.55);       bottom = .blue
//    case .carbs:    top = .green.opacity(0.55);      bottom = .green
//    case .fat:      top = .pink.opacity(0.55);       bottom = .pink
//    }
//    return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
//}
//
//// Clamp 0...1 as CGFloat for bar widths
//fileprivate func clampProgress(_ value: Double, goal: Double) -> CGFloat {
//    guard goal > 0 else { return 0 }
//    return CGFloat(max(0, min(1, value / goal)))
//}
//
//fileprivate func gradient(for metric: Metric) -> LinearGradient {
//    switch metric {
//    case .calories:
//        return LinearGradient(colors: [Color.orange.opacity(0.6), brandOrange],
//                              startPoint: .leading, endPoint: .trailing)
//    case .protein:
//        return LinearGradient(colors: [Color.blue.opacity(0.55), Color.blue],
//                              startPoint: .leading, endPoint: .trailing)
//    case .carbs:
//        return LinearGradient(colors: [Color.green.opacity(0.55), Color.green],
//                              startPoint: .leading, endPoint: .trailing)
//    case .fat:
//        return LinearGradient(colors: [Color.pink.opacity(0.55), Color.pink],
//                              startPoint: .leading, endPoint: .trailing)
//    }
//}
//
//
//
//// MARK: - UI Components
//
//// Big loud header + Edit goals
//fileprivate struct TrackHeader: View {
//    var onEditGoals: () -> Void
//
//    var body: some View {
//        HStack(alignment: .firstTextBaseline) {
//            Text("Track")
//                .font(.system(size: 34, weight: .black, design: .rounded))
//                .kerning(0.5)
//            Spacer()
//            Button(action: onEditGoals) {
//                Label("Edit goals", systemImage: "slider.horizontal.3")
//            }
//            .buttonStyle(MiniBorderButtonStyle())
//        }
//        .padding(.horizontal)
//        .padding(.top, 6)
//    }
//}
//
//// Thick black-border banner with primary value (streak / consistency)
//fileprivate struct StreakConsistencyBanner: View {
//    let streakDays: Int
//    let consistency: Int  // days tracked this week (0...7)
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            HStack(spacing: 12) {
//                ZStack {
//                    Circle().fill(brandOrange.opacity(0.12)).frame(width: 42, height: 42)
//                    Image(systemName: "flame.fill")
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundStyle(brandOrange)
//                }
//
//                VStack(alignment: .leading, spacing: 2) {
//                    HStack(alignment: .firstTextBaseline, spacing: 8) {
//                        Text("\(streakDays)")
//                            .font(.system(size: 28, weight: .heavy, design: .rounded))
//                            .monospacedDigit()
//                        Text("day streak")
//                            .font(.callout.weight(.semibold))
//                            .padding(.vertical, 2).padding(.horizontal, 8)
//                            .overlay(Capsule().stroke(brandOrange.opacity(0.6), lineWidth: 1.5))
//                    }
//                    Text("Consistency: \(consistency)/7 this week")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                        .accessibilityLabel("Consistency \(consistency) of 7 this week")
//                }
//                Spacer()
//            }
//
//            Text(contextLine(streakDays: streakDays, consistency: consistency))
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//        }
//        .padding(14)
//        .background(Color(.systemBackground))
//        .overlay(
//            RoundedRectangle(cornerRadius: 14, style: .continuous)
//                .stroke(.black, lineWidth: 3)
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
//        .padding(.horizontal)
//    }
//
//    private func contextLine(streakDays: Int, consistency: Int) -> String {
//        if streakDays >= 14 { return "Hot streak! Two weeks of momentum 🔥" }
//        if consistency >= 5 { return "Solid week—keep it rolling 💪" }
//        return "Every log counts. You’ve got this 🙌"
//    }
//}
//
//
//// Weekly chart for Calories/Protein/Carbs/Fat
//
//
//// Gradient macro progress
//// Gradient macro bar (Today)
//fileprivate struct MacroProgress: View {
//    let title: String
//    let grams: Double
//    let goalGrams: Double
//    let metric: Metric   // drives the gradient color
//
//    private var progress: CGFloat { clampProgress(grams, goal: goalGrams) }
//
//    var body: some View {
//        VStack(spacing: 6) {
//            HStack {
//                Text(title).font(.subheadline.weight(.semibold))
//                Spacer()
//                Text("\(Int(grams))g / \(Int(goalGrams))g")
//                    .font(.caption).foregroundStyle(.secondary)
//            }
//            ZStack(alignment: .leading) {
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.systemGray6))
//                    .frame(height: 10)
//                GeometryReader { geo in
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(metricGradient(metric))
//                        .frame(width: geo.size.width * progress, height: 10)
//                }
//                .frame(height: 10)
//            }
//        }
//    }
//}
//
//// One-line intake row (removable)
//fileprivate struct IntakeRow: View {
//    let entry: IntakeEntry
//    var onRemove: () -> Void
//
//    var body: some View {
//        HStack(spacing: 10) {
//            Text("•").font(.headline)
//            Text(entry.name).font(.subheadline.weight(.semibold)).lineLimit(1)
//            Spacer(minLength: 8)
//            Text("P\(Int(entry.proteinG)) C\(Int(entry.carbsG)) F\(Int(entry.fatG))")
//                .font(.caption).foregroundStyle(.secondary)
//            Text("\(Int(entry.kcal)) kcal")
//                .font(.subheadline.weight(.semibold)).monospacedDigit()
//            Button(action: onRemove) {
//                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
//            }
//            .buttonStyle(.plain)
//        }
//        .padding(.vertical, 8)
//        .contentShape(Rectangle())
//    }
//}
//
//// Weekly metric chart (gradient + goal line)
//// Weekly chart that can show Calories / Protein / Carbs / Fat
//fileprivate struct WeeklyMetricChart: View {
//    let data: [DayTotals]
//    let metric: Metric
//    let goal: Double  // pass the right daily goal for the selected metric
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Chart(data) { d in
//                BarMark(
//                    x: .value("Day", d.weekdayShort),
//                    y: .value(metric.title, value(for: d))
//                )
//                .foregroundStyle(metric.gradient)
//
//                RuleMark(y: .value("Goal", goal))
//                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
//                    .foregroundStyle(.gray.opacity(0.55))
//            }
//            .frame(height: 180)
//        }
//    }
//
//    private func value(for d: DayTotals) -> Double {
//        switch metric {
//        case .calories: return d.calories
//        case .protein:  return d.proteinG
//        case .carbs:    return d.carbsG
//        case .fat:      return d.fatG
//        }
//    }
//}
//
//// Add Intake Sheet (simple)
//fileprivate struct AddIntakeSheet: View {
//    var onAdd: (IntakeEntry) -> Void
//    @Environment(\.dismiss) private var dismiss
//
//    @State private var name: String = ""
//    @State private var protein: Double = 0
//    @State private var carbs: Double = 0
//    @State private var fat: Double = 0
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("What did you eat?") {
//                    TextField("Name (e.g. Chicken wrap)", text: $name)
//                }
//                Section("Macros") {
//                    Stepper("Protein: \(Int(protein)) g", value: $protein, in: 0...200, step: 2)
//                    Stepper("Carbs: \(Int(carbs)) g",     value: $carbs,   in: 0...300, step: 5)
//                    Stepper("Fat: \(Int(fat)) g",         value: $fat,     in: 0...120, step: 2)
//                    LabeledContent("Calories") { Text("\(Int(protein*4 + carbs*4 + fat*9)) kcal") }
//                }
//            }
//            .navigationTitle("Add food")
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Add") {
//                        let e = IntakeEntry(date: Date(),
//                                            name: name.isEmpty ? "Custom" : name,
//                                            proteinG: protein, carbsG: carbs, fatG: fat)
//                        onAdd(e); dismiss()
//                    }
//                    .tint(brandOrange)
//                }
//            }
//        }
//    }
//}
//
//// Goals sheet (simple calorie goal)
//fileprivate struct GoalsSheet: View {
//    @Binding var dailyGoal: Double
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Daily target") {
//                    Stepper("Calories: \(Int(dailyGoal)) kcal", value: $dailyGoal, in: 1200...4000, step: 50)
//                }
//            }
//            .navigationTitle("Goals")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
//            }
//        }
//    }
//}
//
//// MARK: - TRACK VIEW (drop-in)
//
//struct TrackView: View {
//    // VM (set real userId)
//    @StateObject private var vm = TrackViewModel(userId: "testing")
//
//    // UI state
//    @State private var dailyGoal: Double = 2100
//    @State private var weekMetric: Metric = .calories
//    @State private var showAdd = false
//    @State private var showGoals = false
//
//    // Derived
//    private var todayTotals: DayTotals { totals(for: Date(), from: vm.entries) }
//    private var proteinGoalG: Double { (dailyGoal * 0.25) / 4 }
//    private var carbsGoalG:   Double { (dailyGoal * 0.50) / 4 }
//    private var fatGoalG:     Double { (dailyGoal * 0.25) / 9 }
//    private var thisWeek: [DayTotals] { weekDates().map { totals(for: $0, from: vm.entries) } }
//    private var consistency: Int { thisWeek.filter { $0.calories > 300 }.count }
//    private var streakDays: Int {
//        let cal = Calendar.current
//        var d = cal.startOfDay(for: Date()), s = 0
//        while true {
//            let t = totals(for: d, from: vm.entries)
//            if t.calories > 300 { s += 1 } else { break }
//            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
//            d = prev
//        }
//        return s
//    }
//    private var todayEntries: [IntakeEntry] { vm.entries.filter { Calendar.current.isDateInToday($0.date) } }
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 16) {
//
//                    TrackHeader(onEditGoals: { showGoals = true })
//
//                    StreakConsistencyBanner(streakDays: streakDays, consistency: consistency)
//
//                    HStack {
//                        Text("TODAY")
//                            .font(.system(size: 13, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.secondary)
//                            .kerning(0.7)
//                        Spacer()
//                        Text(Date(), style: .date)
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                    .padding(.horizontal)
//
//                    VStack(spacing: 12) {
//                        MacroProgress(title: "Protein", grams: todayTotals.proteinG, goalGrams: proteinGoalG, metric: .protein)
//                        MacroProgress(title: "Carbs",   grams: todayTotals.carbsG,   goalGrams: carbsGoalG,   metric: .carbs)
//                        MacroProgress(title: "Fat",     grams: todayTotals.fatG,     goalGrams: fatGoalG,     metric: .fat)
//                        VStack(spacing: 6) {
//                            HStack {
//                                Text("Calories").font(.subheadline.weight(.semibold))
//                                Spacer()
//                                Text("\(Int(todayTotals.calories)) / \(Int(dailyGoal)) kcal")
//                                    .font(.caption).foregroundStyle(.secondary)
//                            }
//                            ZStack(alignment: .leading) {
//                                RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)).frame(height: 10)
//                                GeometryReader { geo in
//                                    let p = clampProgress(todayTotals.calories, goal: dailyGoal)
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(LinearGradient(colors: [brandOrange.opacity(0.55), brandOrange], startPoint: .leading, endPoint: .trailing))
//                                        .frame(width: geo.size.width * p, height: 10)
//                                }
//                                .frame(height: 10)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//
//                    if !todayEntries.isEmpty {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Today’s entries").font(.headline)
//                            VStack(spacing: 0) {
//                                ForEach(todayEntries) { e in
//                                    IntakeRow(entry: e) {
//                                        // local remove only (keep simple)
//                                        if let idx = vm.entries.firstIndex(of: e) { vm.entries.remove(at: idx) }
//                                    }
//                                    if e.id != todayEntries.last?.id { Divider().padding(.leading, 12) }
//                                }
//                            }
//                            .padding(.vertical, 4)
//                        }
//                        .padding(.horizontal)
//                    }
//
//                    VStack(alignment: .leading, spacing: 12) {
//                        HStack(spacing: 12) {
//                            Text("This week").font(.headline)
//                            Spacer()
//                            MetricMenu(selection: $weekMetric)
//                        }
//                        .padding(.horizontal)
//                        let metricGoal: Double = {
//                            switch weekMetric {
//                            case .calories: return dailyGoal
//                            case .protein:  return proteinGoalG
//                            case .carbs:    return carbsGoalG
//                            case .fat:      return fatGoalG
//                            }
//                        }()
//                        WeeklyMetricChart(data: thisWeek, metric: weekMetric, goal: metricGoal)
//                            .padding(.horizontal)
//                    }
//
//                    Spacer(minLength: 90)
//                }
//                .padding(.vertical, 10)
//            }
//            .background(Color(.systemBackground).ignoresSafeArea())
//            .navigationBarTitleDisplayMode(.inline)
//            .overlay(alignment: .top) {
//                if vm.isLoading {
//                    ProgressView().padding(.top, 8)
//                }
//            }
//            .safeAreaInset(edge: .bottom) {
//                HStack(spacing: 10) {
//                    Button { showAdd = true } label: { Label("Add food", systemImage: "plus") }
//                        .buttonStyle(WhiteOrangeButtonStyle())
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 1)
//                .background(.ultraThinMaterial)
//            }
//        }
//        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
//        .sheet(isPresented: $showAdd) {
//            AddIntakeSheet { new in
//                Task { await vm.add(name: new.name, protein: new.proteinG, carbs: new.carbsG, fat: new.fatG) }
//            }
//            .presentationDetents([.medium])
//        }
//        .sheet(isPresented: $showGoals) {
//            GoalsSheet(dailyGoal: $dailyGoal).presentationDetents([.medium])
//        }
//        .task { await vm.load(days: 30) }
//    }
//}
//
//
//// MARK: - Preview
//#Preview {
//    TrackView()
//}
import SwiftUI
import Charts

// MARK: - Brand + shared styles
fileprivate let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

fileprivate struct PlanWhiteBorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Main TrackView
struct TrackView: View {
    @State private var showGoals = false

    // Demo data
    @State private var caloriesToday = 1460
    @State private var calorieGoal = 2200
    @State private var meals: [(String, String, Int)] = [
        ("🥣", "Breakfast", 380),
        ("🍛", "Lunch", 640),
        ("🍽️", "Dinner", 360),
        ("🍫", "Other", 80)
    ]
    @State private var macros: [(String, Double, Color)] = [
        ("Carbs", 220, .blue),
        ("Protein", 95, .green),
        ("Fat", 60, .orange)
    ]

    private var calorieProgress: Double {
        min(Double(caloriesToday) / Double(calorieGoal), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1️⃣ Header
                TrackHeader {
                    showGoals = true
                }

                // 2️⃣ Calories section
                caloriesSection
                progressTodaySection
                // 3️⃣ Today’s food section
                weeklyTrendsSection
                // 4️⃣ Macros section
                macrosSection
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showGoals) {
            Text("Edit goals here").font(.title3)
        }
    }

    // MARK: - Section 1: Calories
    // MARK: - Section 1: Your Calories Today (Pie)
    private var caloriesSection: some View {
        // Example data
        let meals = [
            ("Breakfast", 480.0, "🥣"),
            ("Lunch",     720.0, "🥪"),
            ("Dinner",    680.0, "🍛"),
            ("Other",     220.0, "🍪")
        ]
        let total = meals.reduce(0) { $0 + $1.1 }

        return VStack(alignment: .leading, spacing: 10) {
            // ✅ Title OUTSIDE the card
            Text("Your Calories Today")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .kerning(0.5)
                .padding(.horizontal)

            // Card content
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    // Pie
                    Chart {
                        ForEach(meals, id: \.0) { meal in
                            SectorMark(
                                angle: .value("Calories", meal.1),
                                innerRadius: .ratio(0.55),
                                angularInset: 1.5
                            )
                            .foregroundStyle(brandOrange.gradient)
                            .cornerRadius(3)
                        }
                    }
                    .frame(width: 150, height: 150)
                    .padding(.leading, 8)

                    // Key
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(meals, id: \.0) { meal in
                            let pct = meal.1 / max(total, 1) * 100
                            HStack(spacing: 8) {
                                Text(meal.2).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meal.0)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(Int(meal.1)) kcal  (\(Int(pct))%)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Footer line inside card
                Text("Total: \(Int(total)) kcal")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
        }
    }
    
    private var progressTodaySection: some View {
        let consumed = 1760.0
        let goal = 2200.0
        let percent = consumed / goal

        return VStack(alignment: .leading, spacing: 16) {
            Text("Today’s Progress")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .kerning(0.5)
                .padding(.horizontal)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 12)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: percent)
                        .stroke(brandOrange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                    Text("\(Int(percent * 100))%")
                        .font(.headline.weight(.heavy))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Int(consumed)) / \(Int(goal)) kcal")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    if percent < 0.9 {
                        Text("You’re on track today 🎯")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You’ve hit your goal — great job! 🎉")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    // MARK: - Section 2: Today’s food
    private var todaysFoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s food")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .kerning(0.5)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(meals, id: \.1) { meal in
                    let (_, name, kcal) = meal
                    let proportion = Double(kcal) / Double(caloriesToday == 0 ? 1 : caloriesToday)

                    HStack(spacing: 10) {
                        Text(meal.0)
                            .font(.title3)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(kcal) kcal")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(brandOrange)
                                        .frame(width: CGFloat(proportion) * geo.size.width, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(.horizontal)
                }

                Button {
                    // open food log sheet
                } label: {
                    Label("Log food", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(PlanWhiteBorderButtonStyle())
                .padding(.horizontal)
                .padding(.top, 6)
            }
            .padding(.bottom, 4)
        }
    }
    // MARK: - Section 4: Weekly Trends
    // MARK: - Section 4: Weekly Trends (Previous 7 Days)
    // MARK: - Section 4: Weekly Trends (Previous 7 Days)
    // MARK: - Section 4: Weekly Trends (Previous 7 Days)
    // MARK: - Section 4: Weekly Trends (Previous 7 Days)
    // MARK: - Section 3: This Week / Trends
    // MARK: - Section 3: This Week / Trends
    // MARK: - Section 3: This Week / Trends
    private var weeklyTrendsSection: some View {
        // Example data
        let dailyCalories: [(String, Double)] = [
            ("Wed", 1900),
            ("Thu", 2100),
            ("Fri", 2250),
            ("Sat", 2000),
            ("Sun", 2400),
            ("Mon", 2150),
            ("Tue", 2300)
        ]

        let goal = 2200.0
        let onTargetDays = dailyCalories.filter { abs($0.1 - goal) < 200 }.count

        return VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .kerning(0.5)
                .padding(.horizontal)

            VStack(spacing: 10) {
                Chart {
                    // Solid orange line for daily calories
                    ForEach(dailyCalories.indices, id: \.self) { i in
                        let day = dailyCalories[i].0
                        let cal = dailyCalories[i].1

                        LineMark(
                            x: .value("Day", day),
                            y: .value("Calories", cal)
                        )
                        .foregroundStyle(brandOrange)
                        .symbol(Circle()) // ✅ legal ChartSymbolShape
                        .symbolSize(50)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }

                    // Dotted goal line
                    RuleMark(y: .value("Goal", goal))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundStyle(.black)
                }
                .chartYScale(domain: 1000...2800)
                .frame(height: 200)
                .padding(.horizontal)

                Text("\(onTargetDays) of 7 days on target — keep it up 💪")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
        }
    }

    // MARK: - Section 3: Macros
    // MARK: - Section 3: Macros Breakdown (single-color + icons)
    // MARK: - Section 2: Macros Breakdown
    private var macrosSection: some View {
        let macros = [
            ("Carbs", 186.0, 250.0, "🍞"),
            ("Protein", 112.0, 130.0, "🍗"),
            ("Fats", 64.0, 70.0, "🍟")
        ]

        let avgPct = macros.map { $0.1 / $0.2 }.reduce(0, +) / Double(macros.count)
        let insight: String = {
            if avgPct > 0.95 && avgPct < 1.05 {
                return "Balanced macros today 👌"
            } else if macros[1].1 / macros[1].2 < 0.8 {
                return "Low on protein — add a boost 💪"
            } else {
                return "Macros still in progress 📊"
            }
        }()

        return VStack(alignment: .leading, spacing: 16) {
            Text("Macros")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .kerning(0.5)
                .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(macros, id: \.0) { name, grams, goal, emoji in
                    VStack(spacing: 6) {
                        HStack {
                            HStack(spacing: 8) {
                                Text(emoji).font(.title3)
                                Text(name)
                                    .font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            Text("\(Int(grams))g / \(Int(goal))g")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray6))
                                    .frame(height: 10)
                                Capsule()
                                    .fill(brandOrange)
                                    .frame(width: geo.size.width * min(grams / goal, 1.0), height: 10)
                            }
                        }
                        .frame(height: 10)
                    }
                }

                Text(insight)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
        }
    }
}

// MARK: - Reusable Header
fileprivate struct TrackHeader: View {
    var onEditGoals: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Track")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                Spacer()
                Button(action: onEditGoals) {
                    Label("Edit goals", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(PlanWhiteBorderButtonStyle())
                    .frame(maxWidth: 140)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 10)
            Divider()
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Preview
#Preview {
    TrackView()
}
