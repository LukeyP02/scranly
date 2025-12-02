import SwiftUI

// MARK: - Simple chat model

struct ChefChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - Chat bubble

fileprivate struct ChefBubble: View {
    let message: ChefChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            Text(message.text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(message.isUser ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(message.isUser ? Color.scranOrange : Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(message.isUser ? 0.0 : 0.08), lineWidth: message.isUser ? 0 : 1)
                )

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Chef root view (Ask Scranly)

struct ChefView: View {
    @State private var messages: [ChefChatMessage] = [
        .init(text: "Hey, I’m Scranly. Ask me anything about dinner this week.", isUser: false)
    ]
    @State private var inputText: String = ""

    private let quickPrompts: [String] = [
        "Plan my week of dinners",
        "Use up chicken, spinach, rice",
        "Make tonight lighter",
        "Cook in under 20 minutes",
        "Plan & shop for 2 people"
    ]

    private let sampleKPI: [KPI] = [
        .init(icon: "flame.fill", value: "3,420", label: "kcal planned", tint: .orange),
        .init(icon: "leaf.fill",  value: "5",     label: "veg-heavy meals", tint: .green),
        .init(icon: "clock.fill", value: "26m",   label: "avg. cook time", tint: .blue),
        .init(icon: "basket.fill",value: "16",    label: "items in basket", tint: .purple)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Brand bar
                ScranlyLogoBar()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {

                            // Greeting + hero
                            VStack(spacing: 16) {
                                GreetingHello(userName: "Alex")

                                NextMealHero(
                                    model: .init(
                                        title: "Katsu Curry",
                                        meta: "Tonight · 25 min · 680 kcal",
                                        emoji: "🍛"
                                    ),
                                    onCook: {
                                        sendFromPrompt("Walk me through cooking my Katsu step by step")
                                    },
                                    onSwap: {
                                        sendFromPrompt("Swap tonight’s Katsu for something lighter")
                                    }
                                )
                            }
                            .padding(.horizontal)

                            // Basket chip (stubbed)
                            BasketSummaryChip(
                                title: "This week’s shop",
                                itemsCount: 16,
                                totalGBP: 42.75,
                                onTap: {
                                    // you can route to Shop tab programmatically later
                                }
                            )
                            .padding(.horizontal)

                            // KPIs
                            KPIGrid(kpis: sampleKPI)
                                .padding(.horizontal)

                            // Quick prompts row
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.scranOrange)
                                    Text("Ask Scranly")
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                }

                                Text("Tap a prompt or type your own question.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(quickPrompts, id: \.self) { prompt in
                                            Button {
                                                sendFromPrompt(prompt)
                                            } label: {
                                                Text(prompt)
                                                    .font(.caption.weight(.heavy))
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 10)
                                                    .background(Color(.systemBackground))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.black.opacity(0.18), lineWidth: 1)
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Chat transcript
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(messages) { msg in
                                    ChefBubble(message: msg)
                                        .id(msg.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 80) // space for input bar
                        }
                        .padding(.top, 8)
                        .onChange(of: messages.count) { _ in
                            if let lastId = messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.scranOrange)

                    TextField("Ask Scranly about dinner…", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.4) : .scranOrange)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(.init(text: trimmed, isUser: true))
        inputText = ""

        // Temporary fake reply (replace with real model later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.messages.append(
                .init(
                    text: "Got it – I’ll help you with “\(trimmed)”. Soon this will hook into the real Scranly chef.",
                    isUser: false
                )
            )
        }
    }

    private func sendFromPrompt(_ prompt: String) {
        inputText = prompt
        sendMessage()
    }
}

// MARK: - Preview

#Preview {
    ChefView()
}
