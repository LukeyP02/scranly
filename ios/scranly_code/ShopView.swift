import SwiftUI
import UIKit

// MARK: - Brand
private let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Units / Pricing Models

enum SRUnit: String, CaseIterable, Codable, Hashable {
    case count, grams, milliliters
    var label: String { self == .count ? "x" : (self == .grams ? "g" : "ml") }
    var title: String {
        switch self {
        case .count:        return "Count"
        case .grams:        return "Grams"
        case .milliliters:  return "Milliliters"
        }
    }
}

struct SRStorePrice: Identifiable, Hashable {
    let id = UUID()
    let store: String
    let pricePerPack: Double
    let packAmount: Double
    let packUnit: SRUnit
    let sizeLabel: String
}

struct SRItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var aisle: String
    var needAmount: Double
    var needUnit: SRUnit
    var storePrices: [SRStorePrice]
    var emoji: String
    var isChecked: Bool = false
}

enum StoreSelection: Equatable {
    case single(String)
    case split
    var label: String {
        switch self {
        case .single(let s): return s
        case .split:         return "Cheapest split"
        }
    }
}

// MARK: - Utils

private func currency(_ v: Double) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "GBP"
    return f.string(from: NSNumber(value: v)) ?? "£" + String(format: "%.2f", v)
}

private func storeURL(_ name: String) -> URL? {
    switch name.lowercased() {
    case "tesco":        return URL(string: "https://www.tesco.com/groceries/")
    case "sainsbury’s", "sainsburys":
        return URL(string: "https://www.sainsburys.co.uk/")
    case "asda":         return URL(string: "https://groceries.asda.com/")
    case "aldi":         return URL(string: "https://groceries.aldi.co.uk/")
    default:             return nil
    }
}

private func packsNeeded(need amount: Double, unit: SRUnit, for sp: SRStorePrice) -> Int {
    guard amount > 0 else { return 0 }
    guard unit == sp.packUnit, sp.packAmount > 0 else { return 1 }
    return max(1, Int(ceil(amount / sp.packAmount)))
}

private func lineTotal(for item: SRItem, at store: String) -> Double? {
    guard let sp = item.storePrices.first(where: { $0.store == store }) else { return nil }
    let n = packsNeeded(need: item.needAmount, unit: item.needUnit, for: sp)
    return Double(n) * sp.pricePerPack
}

private func totalForStore(_ store: String, items: [SRItem]) -> Double {
    items.compactMap { lineTotal(for: $0, at: store) }.reduce(0, +)
}

private func totalForCheapestSplit(items: [SRItem]) -> Double {
    items.compactMap { item in
        item.storePrices.map { sp in
            Double(packsNeeded(need: item.needAmount, unit: item.needUnit, for: sp)) * sp.pricePerPack
        }.min()
    }.reduce(0, +)
}

private func allStores(from items: [SRItem]) -> [String] {
    Array(Set(items.flatMap { $0.storePrices.map(\.store) })).sorted()
}

// MARK: - Samples

enum SRSamples {
    static let stores = ["Tesco","Sainsbury’s","Asda","Aldi"]

    static let items: [SRItem] = [
        .init(name: "Bananas", aisle: "Produce", needAmount: 6, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.05, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
                .init(store: "Asda",  pricePerPack: 0.98, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
                .init(store: "Aldi",  pricePerPack: 0.89, packAmount: 6, packUnit: .count, sizeLabel: "6 pack")
              ], emoji: "🍌"),
        .init(name: "Tomatoes", aisle: "Produce", needAmount: 6, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.20, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
                .init(store: "Asda",  pricePerPack: 1.05, packAmount: 6, packUnit: .count, sizeLabel: "6 pack"),
                .init(store: "Aldi",  pricePerPack: 0.99, packAmount: 6, packUnit: .count, sizeLabel: "6 pack")
              ], emoji: "🍅"),
        .init(name: "Spinach", aisle: "Produce", needAmount: 240, needUnit: .grams,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.10, packAmount: 240, packUnit: .grams, sizeLabel: "240g"),
                .init(store: "Asda",  pricePerPack: 1.00, packAmount: 240, packUnit: .grams, sizeLabel: "240g"),
                .init(store: "Aldi",  pricePerPack: 0.95, packAmount: 240, packUnit: .grams, sizeLabel: "240g")
              ], emoji: "🥬"),
        .init(name: "Spring Onions", aisle: "Produce", needAmount: 1, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 0.55, packAmount: 1, packUnit: .count, sizeLabel: "bunch"),
                .init(store: "Asda",  pricePerPack: 0.50, packAmount: 1, packUnit: .count, sizeLabel: "bunch"),
                .init(store: "Aldi",  pricePerPack: 0.49, packAmount: 1, packUnit: .count, sizeLabel: "bunch")
              ], emoji: "🧅"),

        .init(name: "Chicken Breast", aisle: "Meat", needAmount: 600, needUnit: .grams,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 5.60, packAmount: 600, packUnit: .grams, sizeLabel: "600g"),
                .init(store: "Asda",  pricePerPack: 5.40, packAmount: 600, packUnit: .grams, sizeLabel: "600g"),
                .init(store: "Aldi",  pricePerPack: 5.10, packAmount: 600, packUnit: .grams, sizeLabel: "600g")
              ], emoji: "🍗"),
        .init(name: "Salmon Fillets", aisle: "Fish", needAmount: 2, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 4.50, packAmount: 2, packUnit: .count, sizeLabel: "2 fillets"),
                .init(store: "Asda",  pricePerPack: 4.20, packAmount: 2, packUnit: .count, sizeLabel: "2 fillets"),
                .init(store: "Aldi",  pricePerPack: 3.99, packAmount: 2, packUnit: .count, sizeLabel: "2 fillets")
              ], emoji: "🐟"),

        .init(name: "Milk (Semi-skimmed)", aisle: "Dairy", needAmount: 2_000, needUnit: .milliliters,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.30, packAmount: 2_000, packUnit: .milliliters, sizeLabel: "2L"),
                .init(store: "Asda",  pricePerPack: 1.25, packAmount: 2_000, packUnit: .milliliters, sizeLabel: "2L"),
                .init(store: "Aldi",  pricePerPack: 1.19, packAmount: 2_000, packUnit: .milliliters, sizeLabel: "2L")
              ], emoji: "🥛"),
        .init(name: "Greek Yogurt", aisle: "Dairy", needAmount: 500, needUnit: .grams,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.50, packAmount: 500, packUnit: .grams, sizeLabel: "500g"),
                .init(store: "Asda",  pricePerPack: 1.35, packAmount: 500, packUnit: .grams, sizeLabel: "500g"),
                .init(store: "Aldi",  pricePerPack: 1.29, packAmount: 500, packUnit: .grams, sizeLabel: "500g")
              ], emoji: "🥣"),
        .init(name: "Bread (Wholemeal)", aisle: "Bakery", needAmount: 1, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 0.75, packAmount: 1, packUnit: .count, sizeLabel: "800g loaf"),
                .init(store: "Asda",  pricePerPack: 0.72, packAmount: 1, packUnit: .count, sizeLabel: "800g loaf"),
                .init(store: "Aldi",  pricePerPack: 0.65, packAmount: 1, packUnit: .count, sizeLabel: "800g loaf")
              ], emoji: "🍞"),
        .init(name: "Eggs (Free-range)", aisle: "Dairy", needAmount: 12, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 2.20, packAmount: 12, packUnit: .count, sizeLabel: "12 pack"),
                .init(store: "Asda",  pricePerPack: 2.05, packAmount: 12, packUnit: .count, sizeLabel: "12 pack"),
                .init(store: "Aldi",  pricePerPack: 1.99, packAmount: 12, packUnit: .count, sizeLabel: "12 pack")
              ], emoji: "🥚"),

        .init(name: "Rice (Basmati)", aisle: "Cupboard", needAmount: 1000, needUnit: .grams,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.59, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
                .init(store: "Asda",  pricePerPack: 1.45, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
                .init(store: "Aldi",  pricePerPack: 1.39, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg")
              ], emoji: "🍚"),
        .init(name: "Pasta (Penne)", aisle: "Cupboard", needAmount: 1000, needUnit: .grams,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.20, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
                .init(store: "Asda",  pricePerPack: 1.08, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg"),
                .init(store: "Aldi",  pricePerPack: 0.99, packAmount: 1000, packUnit: .grams, sizeLabel: "1kg")
              ], emoji: "🍝"),
        .init(name: "Passata", aisle: "Cupboard", needAmount: 500, needUnit: .milliliters,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 0.65, packAmount: 500, packUnit: .milliliters, sizeLabel: "500ml"),
                .init(store: "Asda",  pricePerPack: 0.59, packAmount: 500, packUnit: .milliliters, sizeLabel: "500ml"),
                .init(store: "Aldi",  pricePerPack: 0.55, packAmount: 500, packUnit: .milliliters, sizeLabel: "500ml")
              ], emoji: "🫙"),
        .init(name: "Black Beans", aisle: "Cupboard", needAmount: 2, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 0.65, packAmount: 1, packUnit: .count, sizeLabel: "400g can"),
                .init(store: "Asda",  pricePerPack: 0.55, packAmount: 1, packUnit: .count, sizeLabel: "400g can"),
                .init(store: "Aldi",  pricePerPack: 0.52, packAmount: 1, packUnit: .count, sizeLabel: "400g can")
              ], emoji: "🫘"),
        .init(name: "Coconut Milk", aisle: "World Foods", needAmount: 2, needUnit: .count,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 1.10, packAmount: 1, packUnit: .count, sizeLabel: "400ml can"),
                .init(store: "Asda",  pricePerPack: 0.95, packAmount: 1, packUnit: .count, sizeLabel: "400ml can"),
                .init(store: "Aldi",  pricePerPack: 0.89, packAmount: 1, packUnit: .count, sizeLabel: "400ml can")
              ], emoji: "🥥"),
        .init(name: "Soy Sauce", aisle: "World Foods", needAmount: 150, needUnit: .milliliters,
              storePrices: [
                .init(store: "Tesco", pricePerPack: 0.90, packAmount: 150, packUnit: .milliliters, sizeLabel: "150ml"),
                .init(store: "Asda",  pricePerPack: 0.85, packAmount: 150, packUnit: .milliliters, sizeLabel: "150ml")
              ], emoji: "🧂")
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
    // group by display category, then sort categories by categoryOrder
    let pairs = items.enumerated().map { ($0.offset, $0.element) }
    let dict = Dictionary(grouping: pairs, by: { displayCategory(for: $0.1.aisle) })
    return dict.keys
        .sorted { (categoryOrder.firstIndex(of: $0) ?? 999) < (categoryOrder.firstIndex(of: $1) ?? 999) }
        .map { cat in
            let idxs = (dict[cat] ?? [])
                .sorted { (lhs, rhs) in
                    // within a category, sort by aisle (stable) then by name
                    if lhs.1.aisle != rhs.1.aisle {
                        return lhs.1.aisle < rhs.1.aisle
                    }
                    return lhs.1.name < rhs.1.name
                }
                .map { $0.0 }
            return (cat, idxs)
        }
}

// MARK: - UI Pieces

private struct SupermarketMenu: View {
    @Binding var selection: StoreSelection
    private let stores = SRSamples.stores

    var body: some View {
        Menu {
            Section("Buy everything at…") {
                ForEach(stores, id: \.self) { s in
                    Button {
                        selection = .single(s)
                    } label: {
                        if case .single(let cur) = selection, cur == s {
                            Label(s, systemImage: "checkmark")
                        } else { Text(s) }
                    }
                }
            }
            Section {
                Button {
                    selection = .split
                } label: {
                    if case .split = selection {
                        Label("Cheapest split", systemImage: "checkmark")
                    } else { Text("Cheapest split") }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection.label).font(.footnote.weight(.semibold))
                Image(systemName: "chevron.down").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ShopHeaderMinimal: View {
    @Binding var selection: StoreSelection
    let primaryAmount: Double

    private var subtitle: String {
        switch selection {
        case .single(let s): return "at \(s)"
        case .split:        return "cheapest split across stores"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shop")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)
                Spacer()
                SupermarketMenu(selection: $selection)
            }
            Text("Your basket this week").font(.headline)
            VStack(spacing: 4) {
                Text(currency(primaryAmount))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

private struct BeefyStickySummaryBar: View {
    @Binding var selection: StoreSelection
    let total: Double
    let itemsRemaining: Int
    let itemsTotal: Int

    private var done: Int { max(0, itemsTotal - itemsRemaining) }
    private var progress: Double {
        guard itemsTotal > 0 else { return 0 }
        return Double(done) / Double(itemsTotal)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: big total + live store selector
            HStack(alignment: .firstTextBaseline) {
                Text(currency(total))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                Spacer()
                SupermarketMenu(selection: $selection)
            }

            // Middle row: items summary
            HStack(spacing: 10) {
                Label("\(done) / \(itemsTotal) items", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                Spacer()
                Text("\(itemsRemaining) left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [brandOrange.opacity(0.25), brandOrange],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(max(0, min(1, progress)))) , height: 8)
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)                // meatier visual presence
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
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

// One-line row: emoji • qty • name • (price) • checkbox
private struct PlainItemRow: View {
    @Binding var item: SRItem
    let selection: StoreSelection

    private func chosenStore() -> String? {
        switch selection {
        case .single(let s): return s
        case .split:
            return item.storePrices.min { a, b in
                total(for: a) < total(for: b)
            }?.store
        }
    }

    private func total(for sp: SRStorePrice) -> Double {
        Double(packsNeeded(need: item.needAmount, unit: item.needUnit, for: sp)) * sp.pricePerPack
    }

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
                if let s = chosenStore(),
                   let sp = item.storePrices.first(where: { $0.store == s }) {
                    Text(currency(total(for: sp)))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                }
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

// Sticky top summary bar
private struct StickySummaryBar: View {
    let total: Double
    let itemsRemaining: Int
    var body: some View {
        HStack {
            Text(currency(total)).font(.headline).bold()
            Spacer()
            Text("\(itemsRemaining) items").font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

// Bottom sticky actions
fileprivate struct BottomBar: View {
    var onAddItem: () -> Void
    var onBuyOnline: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button { onAddItem() } label: {
                Label("Add item", systemImage: "plus")
            }
            .buttonStyle(WhiteOrangeButtonStyle())

            Button { onBuyOnline() } label: {
                Label("Buy online", systemImage: "safari")
            }
            .buttonStyle(WhiteOrangeButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
// Label style: orange icon, black text
fileprivate struct OrangeIconBlackTextLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(brandOrange)   // 🟧 icon
            configuration.title
                .foregroundStyle(.black)        // ⬛️ text
        }
    }
}

// Button style: white fill, thick black border, heavy rounded font
fileprivate struct WhiteOrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(OrangeIconBlackTextLabelStyle())
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground)) // white
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black, lineWidth: 3) // thicker black border
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
// Simple Add Item
private struct AddItemSheet: View {
    var onAdd: (SRItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var aisle: String = "Other"
    @State private var amount: Double = 1
    @State private var unit: SRUnit = .count
    @State private var emoji: String = "🛒"

    @State private var store: String = SRSamples.stores.first ?? "Tesco"
    @State private var pricePerPack: Double = 1.00
    @State private var packAmount: Double = 1
    @State private var packUnit: SRUnit = .count
    @State private var sizeLabel: String = "1x"

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    TextField("Aisle (e.g. Produce)", text: $aisle)
                    TextField("Emoji", text: $emoji)
                    Stepper("Needed: \(Int(amount)) \(unit.label)", value: $amount, in: 0...5000, step: unit == .count ? 1 : 50)
                    Picker("Need unit", selection: $unit) {
                        ForEach(SRUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }
                Section("Pack & Price (for one store)") {
                    Picker("Store", selection: $store) {
                        ForEach(SRSamples.stores, id: \.self) { Text($0) }
                    }
                    TextField("Price per pack (£)", value: $pricePerPack, format: .number)
                        .keyboardType(.decimalPad)
                    Stepper("Pack amount: \(Int(packAmount)) \(packUnit.label)", value: $packAmount, in: 1...5000, step: packUnit == .count ? 1 : 50)
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
                        let sp = SRStorePrice(store: store, pricePerPack: pricePerPack, packAmount: packAmount, packUnit: packUnit, sizeLabel: sizeLabel)
                        let item = SRItem(name: name.isEmpty ? "New item" : name,
                                          aisle: aisle.isEmpty ? "Other" : aisle,
                                          needAmount: amount, needUnit: unit,
                                          storePrices: [sp],
                                          emoji: emoji.isEmpty ? "🛒" : emoji)
                        onAdd(item); dismiss()
                    }
                    .tint(brandOrange)
                }
            }
        }
    }
}

fileprivate struct ShopStickyHeader: View {
    @Binding var selection: StoreSelection
    let amount: Double
    let remaining: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            // Title + picker
            HStack(alignment: .firstTextBaseline) {
                Text("Shop")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .kerning(0.5)
                Spacer()
                SupermarketMenu(selection: $selection)
            }

            // Quick stat pill
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "basket.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(brandOrange)
                    Text(currency(amount))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 2))

                Text("\(remaining) of \(total) remaining")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(Color(.systemBackground).opacity(0.98))   // stays white
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - MAIN VIEW

struct ShopView: View {
    @State private var items: [SRItem] = SRSamples.items
    @State private var selection: StoreSelection = .single("Tesco")

    @State private var showAdd = false
    @State private var showNoStoreAlert = false
    @Environment(\.openURL) private var openURL

    // time-saved stat (wire to telemetry later)
    @State private var timeSavedMin: Int = 37

    private var primaryAmount: Double {
        switch selection {
        case .single(let s): return totalForStore(s, items: items)
        case .split:         return totalForCheapestSplit(items: items)
        }
    }
    private var itemsRemaining: Int { items.filter { !$0.isChecked }.count }
    

    // Stores available in the current list
    private var stores: [String] { allStores(from: items) }

    // Per-store basket totals and the cheapest split
    private var totalsByStore: [(store: String, total: Double)] {
        stores.map { ($0, totalForStore($0, items: items)) }
    }
    private var splitTotal: Double { totalForCheapestSplit(items: items) }

    // Counts for the mini pill
    private var totalCount: Int { items.count }
    private var remainingCount: Int { items.filter { !$0.isChecked }.count }

    // The amount to show in the sticky header
    private var primaryTotal: Double {
        switch selection {
        case .single(let s):
            return totalsByStore.first(where: { $0.store == s })?.total ?? 0
        case .split:
            return splitTotal
        }
    }


    // Grouped by friendly categories
    private var grouped: [(String,[Int])] { groupedCategoryIndices(items: items) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header (Shop + basket)
                    ShopHeaderMinimal(selection: $selection, primaryAmount: primaryAmount)

                    // Time saved
                    // Money saved
                    MoneySavedBanner(pounds: 14)

                    // Loud title
                    LoudSectionTitle(text: "This week’s list")

                    // Category sections (bold headers) with one-line rows
                    ForEach(Array(grouped.enumerated()), id: \.offset) { _, section in
                        CategoryHeader(text: section.0)
                        VStack(spacing: 0) {
                            ForEach(section.1, id: \.self) { i in
                                PlainItemRow(item: $items[i], selection: selection)
                                if i != section.1.last { RowSeparator() }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                ShopStickyHeader(
                    selection: $selection,
                    amount: primaryTotal,
                    remaining: remainingCount,
                    total: totalCount
                )
            }
            .safeAreaInset(edge: .bottom) {
                BottomBar(
                    onAddItem: { showAdd = true },
                    onBuyOnline: {
                        switch selection {
                        case .single(let s):
                            if let url = storeURL(s) { openURL(url) } else { showNoStoreAlert = true }
                        case .split:
                            showNoStoreAlert = true
                        }
                    }
                )
            }
        }
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
        .sheet(isPresented: $showAdd) {
            AddItemSheet { newItem in items.append(newItem) }
                .presentationDetents([.medium])
        }
        .alert("Choose a store", isPresented: $showNoStoreAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("Pick a single supermarket from the menu to open their online shop.")
        })
    }
}

// MARK: - Preview
#Preview { ShopView() }
