import SwiftUI
import Foundation
import UIKit

// MARK: - Brand
private let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Brand Fonts (rounded default; serif for brand moments)
private enum BrandFont {
    static let display   = Font.system(size: 26, weight: .semibold, design: .serif)
    static let section   = Font.system(size: 22, weight: .semibold, design: .serif)
    static let quote     = Font.system(size: 20, weight: .regular,  design: .serif).italic()
}

// MARK: - Units (no pricing)
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

// MARK: - List item (no price fields)
struct SRItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var aisle: String
    var needAmount: Double
    var needUnit: SRUnit
    var emoji: String
    var isChecked: Bool = false
}

// MARK: - Samples (hardcoded)
enum SRSamples {
    static let items: [SRItem] = [
        .init(name: "Bananas",           aisle: "Produce",     needAmount: 6,    needUnit: .count,        emoji: "🍌"),
        .init(name: "Tomatoes",          aisle: "Produce",     needAmount: 6,    needUnit: .count,        emoji: "🍅"),
        .init(name: "Spinach",           aisle: "Produce",     needAmount: 240,  needUnit: .grams,        emoji: "🥬"),
        .init(name: "Spring Onions",     aisle: "Produce",     needAmount: 1,    needUnit: .count,        emoji: "🧅"),
        .init(name: "Chicken Breast",    aisle: "Meat",        needAmount: 600,  needUnit: .grams,        emoji: "🍗"),
        .init(name: "Salmon Fillets",    aisle: "Fish",        needAmount: 2,    needUnit: .count,        emoji: "🐟"),
        .init(name: "Milk (Semi)",       aisle: "Dairy",       needAmount: 2000, needUnit: .milliliters,  emoji: "🥛"),
        .init(name: "Greek Yogurt",      aisle: "Dairy",       needAmount: 500,  needUnit: .grams,        emoji: "🥣"),
        .init(name: "Bread (Wholemeal)", aisle: "Bakery",      needAmount: 1,    needUnit: .count,        emoji: "🍞"),
        .init(name: "Eggs",              aisle: "Dairy",       needAmount: 12,   needUnit: .count,        emoji: "🥚"),
        .init(name: "Rice (Basmati)",    aisle: "Cupboard",    needAmount: 1000, needUnit: .grams,        emoji: "🍚"),
        .init(name: "Pasta (Penne)",     aisle: "Cupboard",    needAmount: 1000, needUnit: .grams,        emoji: "🍝"),
        .init(name: "Passata",           aisle: "Cupboard",    needAmount: 500,  needUnit: .milliliters,  emoji: "🫙"),
        .init(name: "Black Beans",       aisle: "Cupboard",    needAmount: 2,    needUnit: .count,        emoji: "🫘"),
        .init(name: "Coconut Milk",      aisle: "World Foods", needAmount: 2,    needUnit: .count,        emoji: "🥥"),
        .init(name: "Soy Sauce",         aisle: "World Foods", needAmount: 150,  needUnit: .milliliters,  emoji: "🧂")
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

// MARK: - UI bits
private struct ShoppingFactCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: scranly (orange/serif) + fact (secondary)
            HStack(spacing: 8) {
                Image(systemName: "cart.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(brandOrange)

                HStack(spacing: 6) {
                    Text("Scranly")
                        .font(.system(size: 13, weight: .black, design: .serif))
                        .foregroundStyle(brandOrange)
                   
                }
            }

            Text(text)
                .font(BrandFont.display)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(brandOrange.opacity(0.08))
                // subtle top highlight to help the “lifted” feel
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.45), .clear],
                                   startPoint: .top, endPoint: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
        )
        // raised: two stacked shadows for a soft elevation
        .shadow(color: .black.opacity(0.10), radius: 18, y: 14)
        .shadow(color: .black.opacity(0.04), radius: 4,  y: 2)
        .padding(.horizontal)
        .padding(.top, 2)
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

/// Sticky header: page title + remaining + share
fileprivate struct ShopStickyHeader: View {
    let remaining: Int
    let total: Int
    var onShare: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shop")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(0.5)

                Spacer()

                Text("\(remaining) of \(total) remaining")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)

                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .buttonStyle(MiniBorderButtonStyle())
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)      // match PlanTopBar
        .padding(.bottom, 12)  // match PlanTopBar
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4) // match PlanTopBar
    }
}

private struct LoudSectionTitle: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(BrandFont.section)
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
                            .transition(.scale(1.0).combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

// One-line row: emoji • qty • name • checkbox (no price)
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

// Simple UIActivityViewController wrapper for sharing text
private struct ActivityView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - MAIN VIEW (hardcoded, no API, no prices, add-item commented)
struct ShopView: View {
    @State private var items: [SRItem] = SRSamples.items
    // @State private var showAdd = false   // ⬅️ out of scope now
    @State private var showShare = false

    private var totalCount: Int { items.count }
    private var remainingCount: Int { items.filter { !$0.isChecked }.count }
    private var grouped: [(String,[Int])] { groupedCategoryIndices(items: items) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    // Friendly fact card (serif)
                    ShoppingFactCard(text: shoppingFacts.randomElement() ?? "Plan once, relax all week.")

                    // Section title (serif)
                    LoudSectionTitle(text: "This week’s list")

                    // Body “Add item” button — OUT OF SCOPE
                    /*
                    HStack {
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("Add item")
                                    .font(.subheadline.weight(.bold))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    */

                    if items.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "cart")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(brandOrange)
                                .padding(.bottom, 2)

                            Text("Your basket is empty.")
                                .font(BrandFont.section)
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
                                    PlainItemRow(item: $items[i])
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
                    remaining: remainingCount,
                    total: totalCount,
                    onShare: { showShare = true }
                )
            }
        }
        // App default remains rounded; serif used selectively above
        .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))
        // Add-item sheet — OUT OF SCOPE
        /*
        .sheet(isPresented: $showAdd) {
            AddItemSheet { newItem in items.append(newItem) }
                .presentationDetents([.medium])
        }
        */
        .sheet(isPresented: $showShare) {
            let text = shareListText(items: items)
            ActivityView(text: text).presentationDetents([.medium])
        }
    }

    private func shareListText(items: [SRItem]) -> String {
        var lines: [String] = ["Shopping list", "----------------"]
        for it in items {
            let qty = it.needUnit == .count ? "\(Int(it.needAmount))×" :
                      it.needUnit == .grams ? "\(Int(it.needAmount))g" : "\(Int(it.needAmount))ml"
            lines.append("• \(qty) \(it.name)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Preview
#Preview { ShopView() }
