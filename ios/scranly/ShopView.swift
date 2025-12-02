import SwiftUI
import UIKit

// MARK: - Brand
private let brandOrange = Color(red: 0.95, green: 0.40, blue: 0.00)

// MARK: - Brand Fonts (rounded default; serif for brand moments)
private enum BrandFont {
    static let display   = Font.system(size: 26, weight: .semibold, design: .serif)
    static let section   = Font.system(size: 22, weight: .semibold, design: .serif)
    static let quote     = Font.system(size: 20, weight: .regular,  design: .serif).italic()
}

// MARK: - Range for the shopping horizon
enum ShopRange: String, CaseIterable, Identifiable {
    case today
    case next3Days
    case thisWeek

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today:      return "Today"
        case .next3Days:  return "Next 3 days"
        case .thisWeek:   return "This week"
        }
    }

    var listTitle: String {
        switch self {
        case .today:      return "Today’s list"
        case .next3Days:  return "Next 3 days"
        case .thisWeek:   return "This week’s list"
        }
    }
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

/// Sticky header: page title + remaining + horizon selector
fileprivate struct ShopStickyHeader: View {
    let remaining: Int
    let total: Int
    var selectedRange: ShopRange
    var onRangeChange: (ShopRange) -> Void

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
            }
            .padding(.horizontal)

            // Horizon selector: Today / Next 3 days / This week
            HStack(spacing: 8) {
                ForEach(ShopRange.allCases) { range in
                    Button {
                        onRangeChange(range)
                    } label: {
                        Text(range.label)
                            .font(.caption.weight(.heavy))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        range == selectedRange
                                        ? brandOrange.opacity(0.14)
                                        : Color(.systemBackground)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        range == selectedRange
                                        ? brandOrange
                                        : Color.black.opacity(0.15),
                                        lineWidth: range == selectedRange ? 1.5 : 1
                                    )
                            )
                            .foregroundStyle(
                                range == selectedRange
                                ? brandOrange
                                : Color.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .padding(.top, 4)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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

// MARK: - Ask Scranly bottom sheet

fileprivate struct AskScranlyShopSheet: View {
    var onClose: () -> Void

    @State private var message: String = ""
    private let prompts = [
        "Make this list cheaper",
        "Swap to veggie options",
        "Focus on cupboard staples",
        "Trim this to essentials"
    ]

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // grab handle
                Capsule()
                    .fill(Color(.systemGray3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(brandOrange)
                        Text("Ask Scranly about your shop")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .heavy))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Quick prompts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prompts, id: \.self) { prompt in
                            Button {
                                message = prompt
                                // hook this into real chat later
                            } label: {
                                Text(prompt)
                                    .font(.caption.weight(.heavy))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color(.secondarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Fake chat area (placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chat")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 120)
                        .overlay(
                            Text("Scranly’s responses will appear here once wired up.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(10),
                            alignment: .topLeading
                        )
                }
                .padding(.horizontal)

                // Input
                HStack(spacing: 8) {
                    TextField("Ask Scranly about this list…", text: $message)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        // send message to backend later
                        message = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: -4)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - MAIN VIEW
struct ShopView: View {
    @State private var selectedRange: ShopRange = .thisWeek
    @State private var items: [SRItem] = SRSamples.items

    @State private var showAskScranly = false

    private var totalCount: Int { items.count }
    private var remainingCount: Int { items.filter { !$0.isChecked }.count }
    private var grouped: [(String,[Int])] { groupedCategoryIndices(items: items) }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 12) {

                        LoudSectionTitle(text: selectedRange.listTitle)

                        if items.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "cart")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(brandOrange)
                                    .padding(.bottom, 2)

                                Text("Your basket is empty.")
                                    .font(BrandFont.section)
                                    .foregroundStyle(.primary)

                                Text("Add a plan for this horizon to generate your shopping list.")
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
                        selectedRange: selectedRange,
                        onRangeChange: { newRange in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                selectedRange = newRange
                            }
                            // TODO: later update `items` based on range
                        }
                    )
                }
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showAskScranly.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Ask Scranly")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(brandOrange)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(.clear)
                }
            }
            .environment(\.font, .system(size: 15, weight: .regular, design: .rounded))

            if showAskScranly {
                AskScranlyShopSheet {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        showAskScranly = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview { ShopView() }
