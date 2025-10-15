import SwiftUI

// MARK: - Brand
private let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Units / Pricing Models (estimates only)

enum SRUnit: String, CaseIterable, Codable, Hashable {
    case count, grams, milliliters
    var label: String { self == .count ? "×" : (self == .grams ? "g" : "ml") }
    var title: String {
        switch self {
        case .count:        return "Count"
        case .grams:        return "Grams"
        case .milliliters:  return "Milliliters"
        }
    }
}

/// CHANGED: single estimated pack/price (no stores)
struct SREstimatePrice: Identifiable, Hashable {
    let id = UUID()
    let pricePerPack: Double       // e.g. £1.20
    let packAmount: Double         // e.g. 500
    let packUnit: SRUnit           // grams/ml/count
    let sizeLabel: String          // "500g", "2L", "6 pack", etc.
}

struct SRItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var aisle: String
    var needAmount: Double
    var needUnit: SRUnit
    var estimate: SREstimatePrice  // ← single estimate
    var emoji: String
    var isChecked: Bool = false
}

// MARK: - Utils

private func currency(_ v: Double) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "GBP"
    return f.string(from: NSNumber(value: v)) ?? "£" + String(format: "%.2f", v)
}

/// How many packs do we need to cover the need?
private func packsNeeded(need amount: Double, unit: SRUnit, for est: SREstimatePrice) -> Int {
    guard amount > 0 else { return 0 }
    guard unit == est.packUnit, est.packAmount > 0 else { return 1 }
    return max(1, Int(ceil(amount / est.packAmount)))
}

/// Estimated line total for an item
private func lineTotal(for item: SRItem) -> Double {
    let n = packsNeeded(need: item.needAmount, unit: item.needUnit, for: item.estimate)
    return Double(n) * item.estimate.pricePerPack
}

/// Basket total (estimated)
private func basketTotal(_ items: [SRItem]) -> Double {
    items.map(lineTotal(for:)).reduce(0, +)
}

// MARK: - Samples (now estimates only)

enum SRSamples {
    static let items: [SRItem] = [
        .init(name: "Bananas", aisle: "Produce", needAmount: 6, needUnit: .count,
              estimate: .init(pricePerPack: 1.05, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
              emoji: "🍌"),
        .init(name: "Tomatoes", aisle: "Produce", needAmount: 6, needUnit: .count,
              estimate: .init(pricePerPack: 1.10, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
              emoji: "🍅"),
        .init(name: "Spinach", aisle: "Produce", needAmount: 240, needUnit: .grams,
              estimate: .init(pricePerPack: 0.95, packAmount: 240, packUnit: .grams, sizeLabel: "240g"),
              emoji: "🥬"),
        .init(name: "Spring Onions", aisle: "Produce", needAmount: 1, needUnit: .count,
              estimate: .init(pricePerPack: 0.49, packAmount: 1, packUnit: .count, sizeLabel: "bunch"),
              emoji: "🧅"),

        .init(name: "Chicken Breast", aisle: "Meat", needAmount: 600, needUnit: .grams,
              estimate: .init(pricePerPack: 5.20, packAmount: 600, packUnit: .grams, sizeLabel: "600g"),
              emoji: "🍗"),
        .init(name: "Salmon Fillets", aisle: "Fish", needAmount: 2, needUnit: .count,
              estimate: .init(pricePerPack: 4.20, packAmount: 2, packUnit: .count, sizeLabel: "2 fillets"),
              emoji: "🐟"),

        .init(name: "Milk (Semi-skimmed)", aisle: "Dairy", needAmount: 2_000, needUnit: .milliliters,
              estimate: .init(pricePerPack: 1.25, packAmount: 2_000, packUnit: .milliliters, sizeLabel: "2L"),
              emoji: "🥛"),
        .init(name: "Greek Yogurt", aisle: "Dairy", needAmount: 500, needUnit: .grams,
              estimate: .init(pricePerPack: 1.29, packAmount: 500, packUnit: .grams, sizeLabel: "500g"),
              emoji: "🥣"),
        .init(name: "Bread (Wholemeal)", aisle: "Bakery", needAmount: 1, needUnit: .count,
              estimate: .init(pricePerPack: 0.65, packAmount: 1, packUnit: .count, sizeLabel: "800g loaf"),
              emoji: "🍞"),
        .init(name: "Eggs (Free-range)", aisle: "Dairy", needAmount: 12, needUnit: .count,
              estimate: .init(pricePerPack: 2.05, packAmount: 12, packUnit: .count, sizeLabel: "12 pack"),
              emoji: "🥚"),

        .init(name: "Rice (Basmati)", aisle: "Cupboard", needAmount: 1000, needUnit: .grams,
              estimate: .init(pricePerPack: 1.39, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
              emoji: "🍚"),
        .init(name: "Pasta (Penne)", aisle: "Cupboard", needAmount: 1000, needUnit: .grams,
              estimate: .init(pricePerPack: 0.99, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
              emoji: "🍝"),
        .init(name: "Passata", aisle: "Cupboard", needAmount: 500, needUnit: .milliliters,
              estimate: .init(pricePerPack: 0.55, packAmount: 500, packUnit: .milliliters, sizeLabel: "500ml"),
              emoji: "🫙"),
        .init(name: "Black Beans", aisle: "Cupboard", needAmount: 2, needUnit: .count,
              estimate: .init(pricePerPack: 0.55, packAmount: 1, packUnit: .count, sizeLabel: "400g can"),
              emoji: "🫘"),
        .init(name: "Coconut Milk", aisle: "World Foods", needAmount: 2, needUnit: .count,
              estimate: .init(pricePerPack: 0.95, packAmount: 1, packUnit: .count, sizeLabel: "400ml can"),
              emoji: "🥥"),
        .init(name: "Soy Sauce", aisle: "World Foods", needAmount: 150, needUnit: .milliliters,
              estimate: .init(pricePerPack: 0.85, packAmount: 150, packUnit: .milliliters, sizeLabel: "150ml"),
              emoji: "🧂")
    ]
}

// MARK: - Category mapping / ordering

private func displayCategory(for aisle: String) -> String {
    let k = aisle.lowercased()
    if k == "produce" { return "Fruit & Veg" }
    if k == "meat" || k == "fish" { return "Meat & Fish" }
    if k == "dairy" { return "Dairy & Eggs" }
    if k == "bakery" { return "Bakery" }
    if k == "cupboard" { return "Pantry" }
    if k == "world foods" { return "World & Sauces" }
    return "Other"
}

private let categoryOrder: [String] = [
    "Fruit & Veg","Meat & Fish","Dairy & Eggs","Bakery","Pantry","World & Sauces","Other"
]

private func groupedCategoryIndices(items: [SRItem]) -> [(String,[Int])] {
    let pairs = items.enumerated().map { ($0.offset, $0.element) }
    let dict = Dictionary(grouping: pairs, by: { displayCategory(for: $0.1.aisle) })
    return dict.keys
        .sorted { (categoryOrder.firstIndex(of: $0) ?? 999) < (categoryOrder.firstIndex(of: $1) ?? 999) }
        .map { cat in
            let idxs = (dict[cat] ?? [])
                .sorted { (lhs, rhs) in
                    if lhs.1.aisle != rhs.1.aisle { return lhs.1.aisle < rhs.1.aisle }
                    return lhs.1.name < rhs.1.name
                }
                .map { $0.0 }
            return (cat, idxs)
        }
}

private struct ShoppingFactCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "cart.fill")
                    .foregroundColor(brandOrange)
                    .font(.title3)
                Text("Scranly fact")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(brandOrange.opacity(0.08))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
        )
        .padding(.horizontal)
    }
}

private let shoppingFacts: [String] = [
    "Lists save brains — science says so 🧠📝",
    "Planning ahead cuts food waste by up to 30%.",
    "Shop once, eat well all week.",
    "Impulse buys? We don’t know her.",
    "Every planned meal = less food in the bin.",
    "A good list turns chaos into calm 🛒"
]

private struct MoneySavedCompactBar: View {
    let pounds: Int
    let hasMeals: Bool
    var onPlanTap: () -> Void = {}

    var body: some View {
        if hasMeals {
            // --- Normal stat card ---
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(brandOrange.opacity(0.12)).frame(width: 42, height: 42)
                        Image(systemName: "sterlingsign.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(brandOrange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("£\(pounds)")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                            Text("saved")
                                .font(.callout.weight(.semibold))
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .overlay(Capsule().stroke(brandOrange.opacity(0.6), lineWidth: 1.5))
                        }
                        Text("by planning & shopping smart with Scranly")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Text(context(pounds))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.black, lineWidth: 3))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
            .padding(.top, 6)

        } else {
            // --- One-line, button-styled fallback ---
            Button(action: onPlanTap) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(brandOrange)
                    Text("Plan meals to start saving")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)   // <- adds insets INSIDE the border
            }
            .buttonStyle(ShopWhiteOrangeButtonStyle())
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }

    private func context(_ pounds: Int) -> String {
        switch pounds {
        case 0..<10:  return "That’s a takeaway coffee or two ☕️"
        case 10..<20: return "That’s lunch out covered 🥪"
        case 20..<40: return "That’s your weekly food waste bill erased 🚮"
        case 40..<60: return "That’s a big Friday night shop 🍕"
        default:      return "That’s real money back in your pocket 💸"
        }
    }
}

// MARK: - UI Pieces

/// Minimal sticky header: big estimated total + items remaining
private struct ShopStickyHeader: View {
    let amount: Double
    let remaining: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shop")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .kerning(0.5)
                Spacer()
                HStack(spacing: 10) {

                    Text("\(remaining) of \(total) remaining")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(brandOrange)
                }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2))
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(brandOrange)
                }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2))
            }

            
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(Color(.systemBackground).opacity(0.98))
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct MoneySavedBanner: View {
    let pounds: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(brandOrange.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: "sterlingsign.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(brandOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("£\(pounds)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                        Text("saved")
                            .font(.callout.weight(.semibold))
                            .padding(.vertical, 2).padding(.horizontal, 8)
                            .overlay(Capsule().stroke(brandOrange.opacity(0.6), lineWidth: 1.5))
                    }
                    Text("by planning & shopping smart with Scranly")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(context(pounds))
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.black, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 6)
    }
    private func context(_ pounds: Int) -> String {
        switch pounds {
        case 0..<10:  return "That’s a takeaway coffee or two ☕️"
        case 10..<20: return "That’s lunch out covered 🥪"
        case 20..<40: return "That’s your weekly food waste bill erased 🚮"
        case 40..<60: return "That’s a big Friday night shop 🍕"
        default:      return "That’s real money back in your pocket 💸"
        }
    }
}

private struct LoudSectionTitle: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .kerning(0.5)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}

private struct CategoryHeader: View {
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

// Minimal right-hand checkbox
private struct RightCheckToggleStyle: ToggleStyle {
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

// One-line row: emoji • qty • name • (estimated price) • checkbox
private struct PlainItemRow: View {
    @Binding var item: SRItem

    private var qtyText: String {
        switch item.needUnit {
        case .count:        return "\(Int(item.needAmount))×"
        case .grams:        return "\(Int(item.needAmount))g"
        case .milliliters:  return "\(Int(item.needAmount))ml"
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
                Text(currency(lineTotal(for: item)))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
            }
            .contentShape(Rectangle())
        }
        .toggleStyle(RightCheckToggleStyle())
    }
}

// Thin row separator
private struct RowSeparator: View {
    var body: some View {
        Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
            .padding(.leading, 44)
    }
}

// Bottom sticky actions (no external “Buy online” now)
fileprivate struct ShopWhiteOrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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

fileprivate struct BottomBar: View {
    var onAddItem: () -> Void
    var onShare: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button { onAddItem() } label: {
                Label("Add item", systemImage: "plus")
            }
            .buttonStyle(ShopWhiteOrangeButtonStyle())

            Button { onShare() } label: {
                Label("Share list", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(ShopWhiteOrangeButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

private struct FloatingAddButton: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
                .padding(20)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .overlay(
                            Circle()
                                .stroke(brandOrange, lineWidth: 2)
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add item")
    }
}

// Simple Add Item (estimate-only)
private struct AddItemSheet: View {
    var onAdd: (SRItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var aisle: String = "Other"
    @State private var amount: Double = 1
    @State private var unit: SRUnit = .count
    @State private var emoji: String = "🛒"

    // Estimate inputs
    @State private var pricePerPack: Double = 1.00
    @State private var packAmount: Double = 1
    @State private var packUnit: SRUnit = .count
    @State private var sizeLabel: String = "1×"

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    TextField("Aisle (e.g. Produce)", text: $aisle)
                    TextField("Emoji", text: $emoji)
                    Stepper("Needed: \(unit == .count ? "\(Int(amount))" : "\(Int(amount))") \(unit.label)",
                            value: $amount, in: 0...5000, step: unit == .count ? 1 : 50)
                    Picker("Need unit", selection: $unit) {
                        ForEach(SRUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }
                Section("Estimated pack & price") {
                    TextField("Price per pack (£)", value: $pricePerPack, format: .number)
                        .keyboardType(.decimalPad)
                    Stepper("Pack amount: \(Int(packAmount)) \(packUnit.label)",
                            value: $packAmount, in: 1...5000, step: packUnit == .count ? 1 : 50)
                    Picker("Pack unit", selection: $packUnit) {
                        ForEach(SRUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    TextField("Size label", text: $sizeLabel)
                }
            }
            .navigationTitle("Add item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let est = SREstimatePrice(pricePerPack: pricePerPack,
                                                  packAmount: packAmount,
                                                  packUnit: packUnit,
                                                  sizeLabel: sizeLabel)
                        let item = SRItem(name: name.isEmpty ? "New item" : name,
                                          aisle: aisle.isEmpty ? "Other" : aisle,
                                          needAmount: amount, needUnit: unit,
                                          estimate: est,
                                          emoji: emoji.isEmpty ? "🛒" : emoji)
                        onAdd(item); dismiss()
                    }
                    .tint(brandOrange)
                }
            }
        }
    }
}



// MARK: - MAIN VIEW (estimates-only)

struct ShopView: View {
    @StateObject private var vm = ShopViewModel()
    @State private var showAdd = false
    @State private var showShare = false

    private let userId = "testing"     // hardcoded for now

    private var estimatedTotal: Double { vm.items.isEmpty ? 0 : basketTotal(vm.items) }
    private var totalCount: Int { vm.items.count }
    private var remainingCount: Int { vm.items.filter { !$0.isChecked }.count }
    private var grouped: [(String,[Int])] { groupedCategoryIndices(items: vm.items) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // header...
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Your basket this week")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .kerning(0.5)
                        }
                        VStack(spacing: 4) {
                            Text(currency(estimatedTotal))
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("Estimated total")
                                .font(.subheadline)
                                .kerning(0.5)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    MoneySavedCompactBar(
                        pounds: 14,
                        hasMeals: !vm.items.isEmpty,
                        onPlanTap: {
                            // Hook this up to your Plan tab navigation:
                            // e.g., selectedTab = 2  (or trigger your routing to Plan)
                        }
                    )

                    ShoppingFactCard(text: shoppingFacts.randomElement()!)

                    LoudSectionTitle(text: "This week’s list")

                    if vm.items.isEmpty && !vm.isLoading {
                        VStack(spacing: 14) {
                            Image(systemName: "cart")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(brandOrange)
                                .padding(.bottom, 2)
                            
                            Text("Your basket is empty.")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text("Add a plan for this week to generate your shopping list.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.top, 12)
                    } else {
                        ForEach(Array(grouped.enumerated()), id: \.offset) { _, section in
                            CategoryHeader(text: section.0)
                            VStack(spacing: 0) {
                                ForEach(section.1, id: \.self) { i in
                                    PlainItemRow(item: $vm.items[i])
                                    if i != section.1.last { RowSeparator() }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 2)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                ShopStickyHeader(
                    amount: estimatedTotal,
                    remaining: remainingCount,
                    total: totalCount
                )
            }
        }
        .task {
            // Use your PlanViewModel’s selected week if you want; for now server auto-selects this week.
            await vm.load(userId: userId)
        }
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.08).ignoresSafeArea()
                    ProgressView("Loading…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
        .sheet(isPresented: $showAdd) {
            // local add still works and updates total immediately
            AddItemSheet { newItem in vm.items.append(newItem) }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showShare) {
            let text = shareListText(items: vm.items, total: estimatedTotal)
            ActivityView(text: text).presentationDetents([.medium])
        }
    }

    private func shareListText(items: [SRItem], total: Double) -> String {
        var lines: [String] = ["Shopping list (estimated)", "---------------------------"]
        for it in items {
            let qty = it.needUnit == .count ? "\(Int(it.needAmount))×" :
                      it.needUnit == .grams ? "\(Int(it.needAmount))g" : "\(Int(it.needAmount))ml"
            lines.append("• \(qty) \(it.name) — ~\(currency(lineTotal(for: it)))")
        }
        lines.append("")
        lines.append("Estimated total: \(currency(total))")
        return lines.joined(separator: "\n")
    }
}

// Simple UIActivityViewController wrapper for sharing text
private struct ActivityView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview { ShopView() }
