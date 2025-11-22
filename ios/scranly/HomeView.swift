import SwiftUI

// MARK: - brand (scoped to Home only so it won't clash elsewhere)
private let homeBrand = Color(red: 0.95, green: 0.40, blue: 0.00)
private let cream = Color(red: 1.00, green: 0.97, blue: 0.93)

// MARK: - MAIN HOME VIEW
struct HomeView: View {

    // hardcoded demo content
    private let upNext = UpNextCardStatic.Model(
        title: "Katsu Curry",
        meta: "680 kcal • 19:15",
        imageName: "katsu",
        emoji: "🍛"
    )

    // simple fact of the day
    private let fact = ScranFact(
        emoji: "🍽️",
        category: "Scranly",
        text: "Tiny plans beat huge intentions. Lock in dinner for tonight."
    )

    // demo stats for the mini fact file
    private let mealsCooked = 12
    private let favouriteCuisine = "Japanese"
    private let moneySavedGBP: Double = 24.50
    private let timeSavedMin = 75
    private let memberSince: Date =
        Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 4))!

    // NEW: settings sheet toggle
    @State private var showSettings = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {

                // (Header is sticky via safeAreaInset)
                Greeting()

                // Up next (primary block)
                VStack(alignment: .leading, spacing: 8) {
                    UpNextCardStatic(model: upNext)
                        .padding(.horizontal)
                }

                // Fact chip (words only, on cream)
                ScranFactImageChip(
                    text: fact.text,
                    imageName: "" // no image
                )

                // Your scranly wins → mini fact file (includes “Member since”)
                VStack(alignment: .leading, spacing: 8) {
                    YourScranlyWinsTitle()
                        .padding(.horizontal)
                        .padding(.top, 2)

                    MiniFactFileCard(
                        mealsCooked: mealsCooked,
                        favouriteCuisine: favouriteCuisine,
                        moneySavedGBP: moneySavedGBP,
                        timeSavedMin: timeSavedMin,
                        memberSince: memberSince
                    )
                    .padding(.horizontal)
                }

                Spacer(minLength: 10)
            }
            .padding(.top, 6)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        // 🔒 Sticky header pinned to the top safe area
        .safeAreaInset(edge: .top) {
            HVHeaderStatic(onSettings: { showSettings = true })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Sticky Header (Scranly centered + cog on right)
private struct HVHeaderStatic: View {
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            // Centered brand
            Text("Scranly")
                .font(.system(size: 40, weight: .black, design: .serif))
                .kerning(0.5)
                .foregroundStyle(homeBrand)

            // Right-aligned settings button
            HStack {
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(8) // touch target
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea(edges: .top)
                .overlay(Divider(), alignment: .bottom)
        )
    }
}

// MARK: - Simple settings placeholder
private struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Text("Profile")
                    Text("Notifications")
                }
                Section("App") {
                    Text("Appearance")
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct Greeting: View {
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Text("Let's cook, Luke ")
                .font(.system(size: 22, weight: .black, design: .serif))
                .kerning(0.5)
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Image + Fact chip (text-only on cream)
private struct RoundedCorner: Shape {
    var radius: CGFloat = 18
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

private struct ScranFactImageChip: View {
    let text: String
    var imageName: String
    var cornerRadius: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // UPDATED: brand tag → “Scranly” (orange, serif)
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(homeBrand)
                        .font(.caption.weight(.bold))
                    Text("Scranly")
                        .font(.system(size: 18, weight: .black, design: .serif))
                        .foregroundStyle(homeBrand)
                }
                Text(text)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cream)
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.allCorners]))
        }
        .background(cream)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scranly fact. \(text)")
    }
}

// MARK: - Title
private struct YourScranlyWinsTitle: View {
    var body: some View {
        HStack(spacing: 1) {
            Text("Your ")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .kerning(0.5)
            Text("Scranly")
                .font(.system(size: 26, weight: .black, design: .serif))
                .kerning(0.5)
                .foregroundStyle(homeBrand)
            Text(" wins 🎉")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            Spacer(minLength: 4)
        }
    }
}

// MARK: - Mini fact file (unchanged from your last)
private struct MiniFactFileCard: View {
    let mealsCooked: Int
    let favouriteCuisine: String
    let moneySavedGBP: Double
    let timeSavedMin: Int
    let memberSince: Date

    private var currencyText: String { String(format: "£%.2f", moneySavedGBP) }
    private var timeText: String { "\(timeSavedMin)m" }
    private var memberSinceText: String {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yy"
        return df.string(from: memberSince)
    }

    var body: some View {
        VStack(spacing: 0) {
            FactRow(icon: "calendar", title: "Member since", value: memberSinceText)
            OrangeDivider()
            FactRow(icon: "fork.knife", title: "Meals cooked", value: "\(mealsCooked)")
            OrangeDivider()
            FactRow(icon: "globe", title: "Favourite cuisine", value: favouriteCuisine)
            OrangeDivider()
            FactRow(icon: "sterlingsign.circle.fill", title: "Money saved", value: currencyText)
            OrangeDivider()
            FactRow(icon: "clock.badge.checkmark", title: "Time saved", value: timeText)
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
                    .foregroundStyle(homeBrand)
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
        var body: some View {
            Rectangle()
                .fill(homeBrand.opacity(0.9))
                .frame(height: 1)
                .opacity(0.9)
        }
    }
}

// MARK: - Fact model
private struct ScranFact {
    let emoji: String
    let category: String
    let text: String
}

// MARK: - Up Next card (hardcoded katsu asset)
private struct UpNextCardStatic: View {
    struct Model {
        let title: String
        let meta:  String
        let imageName: String?
        let emoji: String
    }
    let model: Model

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(model.imageName ?? "katsu")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                   startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.black, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Up next")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                Text(model.title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(12)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
