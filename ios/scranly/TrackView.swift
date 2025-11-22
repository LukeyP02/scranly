import SwiftUI

// MARK: - Brand tokens
fileprivate let scranOrange = Color(red: 0.95, green: 0.40, blue: 0.00)
fileprivate let cardRadius: CGFloat = 18
fileprivate let chipRadius: CGFloat = 12

private struct ElevatedCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.10), radius: 18, y: 14)
            .shadow(color: .black.opacity(0.04), radius: 4,  y: 2)
    }
}
private extension View { func elevatedCard() -> some View { modifier(ElevatedCard()) } }

// ===================================================================
// Brand token used by the chip
fileprivate let cream = Color(red: 1.00, green: 0.97, blue: 0.93)

private struct ScranlyNoteChip: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(scranOrange)
                    .font(.caption.weight(.bold))
                Text("Scranly")
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(scranOrange)
            }
            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cream)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 5)
    }
}
struct MyScranlyWeeklyRoundupView: View {
    // Demo data (same shape as before)
    struct MealReview: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let cuisine: String
        let emoji: String
        let kcal: Int
        let proteinG: Int
    }
    private let weekDeck: [MealReview] = [
        .init(title: "Thai Green Curry",     cuisine: "Thai",     emoji: "🍛", kcal: 640, proteinG: 34),
        .init(title: "Salmon Teriyaki Bowl", cuisine: "Japanese", emoji: "🐟", kcal: 610, proteinG: 36),
        .init(title: "Chicken Fajitas",      cuisine: "Mexican",  emoji: "🌮", kcal: 590, proteinG: 33),
        .init(title: "Creamy Pesto Pasta",   cuisine: "Italian",  emoji: "🍝", kcal: 780, proteinG: 22),
        .init(title: "Veggie Stir-fry",      cuisine: "Comfort",  emoji: "🥦", kcal: 520, proteinG: 20)
    ]

    // Weekly metrics
    private let cookedThisWeek = 7
    private let topCuisineThisWeek = "Italian"
    private let avgCookTimeThisWeekMin = 28
    private let estSavedTotalGBP: Double = 24.50
    private let fastestNightMin = 16

    private var avgProteinPerMeal: Int {
        guard !weekDeck.isEmpty else { return 0 }
        let total = weekDeck.map(\.proteinG).reduce(0, +)
        return Int(round(Double(total) / Double(weekDeck.count)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky header
                    InsightsHeaderBar(scranOrange: scranOrange) {
                        // Share tapped
                    }

                    // Title row
                    HStack(spacing: 6) {
                        Text("Scranly")
                            .font(.system(size: 28, weight: .black, design: .serif))
                            .foregroundStyle(scranOrange)
                        Text("weekly roundup")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // FACT FILE (same structure as “Your Scranly wins”)
                            

                            ScranlyNoteChip(
                                text: "Your week, decoded. See the wins"
                            )
                            .padding(.horizontal)
                            Spacer(minLength: 6)

                            WeeklyFactFileCard(
                                cookedThisWeek: cookedThisWeek,
                                fastestNightMin: fastestNightMin,
                                avgCookTimeMin: avgCookTimeThisWeekMin,
                                avgProteinG: avgProteinPerMeal,
                                estSavedGBP: estSavedTotalGBP,
                                topCuisine: topCuisineThisWeek,
                                imageNames: ["oats", "katsu", "caeser"].shuffled() // NEW
                            )
                            .padding(.horizontal)
                            
                            

                           
                        }
                        .padding(.top, 6)
                    }
                }
            }
            // Bottom CTA
            .safeAreaInset(edge: .bottom) {
                NavigationLink {
                    WeeklyRoundupFlowView()
                } label: {
                    HStack(spacing: 10) {
                        Text("Show me my week")
                            .font(.system(size: 20, weight: .heavy, design: .serif))
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(RoundedRectangle(cornerRadius: chipRadius, style: .continuous).stroke(.black, lineWidth: 2))
                            .overlay(
                                LinearGradient(colors: [Color.white.opacity(0.35), .clear],
                                               startPoint: .top, endPoint: .center)
                                .clipShape(RoundedRectangle(cornerRadius: chipRadius, style: .continuous))
                            )
                    )
                    .elevatedCard()
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(.clear)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header
    private struct InsightsHeaderBar: View {
        let scranOrange: Color
        var onShare: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Text("Insights")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .kerning(0.5)

                    Spacer()

                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
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

    // MARK: - Weekly fact file (mirrors MiniFactFileCard structure)
    private struct WeeklyFactFileCard: View {
        let cookedThisWeek: Int
        let fastestNightMin: Int
        let avgCookTimeMin: Int
        let avgProteinG: Int
        let estSavedGBP: Double
        let topCuisine: String
        let imageNames: [String] // NEW

        var body: some View {
            VStack(spacing: 0) {
                FactRow(icon: "fork.knife", title: "Meals cooked", value: "\(cookedThisWeek)")
                OrangeDivider(accent: scranOrange)
                FactRow(icon: "hare.fill", title: "Fastest night", value: "\(fastestNightMin)m")
                OrangeDivider(accent: scranOrange)
                FactRow(icon: "timer", title: "Avg cook", value: "\(avgCookTimeMin)m")
                OrangeDivider(accent: scranOrange)
                FactRow(icon: "bolt.heart", title: "Avg protein", value: "\(avgProteinG) g")
                OrangeDivider(accent: scranOrange)
                FactRow(icon: "sterlingsign.circle.fill", title: "Saved this week", value: String(format: "£%.2f", estSavedGBP))
                OrangeDivider(accent: scranOrange)
                FactRow(icon: "globe", title: "Most-eaten cuisine", value: topCuisine)

                // Triptych INSIDE the chip
                if !imageNames.isEmpty {
                    OrangeDivider(accent: scranOrange)
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
                    .padding(.top, 10)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.black, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }

        private struct FactRow: View {
            let icon: String
            let title: String
            let value: String
            var body: some View {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(scranOrange)
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
    }

    // MARK: - Collage
    private struct TriptychCollage: View {
        let imageNames: [String]
        var body: some View {
            HStack(spacing: 8) {
                ForEach(imageNames.prefix(3), id: \.self) { name in
                    MiddleThirdTile(imageName: name, zoom: 2.2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    private struct MiddleThirdTile: View {
        let imageName: String
        var zoom: CGFloat = 2.2
        var verticalBias: CGFloat = 0.0

        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let z = max(1, zoom)

                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h * z)
                        .offset(y: (h * (z - 1) / 2) * verticalBias)
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Styles
    private struct MiniBorderButtonStyle: ButtonStyle {
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
}

// MARK: - Preview
#Preview {
    MyScranlyWeeklyRoundupView()
}
