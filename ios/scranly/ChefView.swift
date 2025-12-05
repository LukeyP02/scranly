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
                        .stroke(Color.black.opacity(message.isUser ? 0.0 : 0.08),
                                lineWidth: message.isUser ? 0 : 1)
                )

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Big Ask Scranly hero card (under “Hello Alex”)

fileprivate struct AskScranlyHeroCard: View {
    var isExpanded: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.scranOrange.opacity(0.18),
                                    Color.scranOrange.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.scranOrange)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Ask Scranly")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Image(systemName: "sparkles")
                            .font(.caption2.weight(.bold))
                    }

                    Text("Tell me what kind of week you want — I’ll plan, tweak, and shop with you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.caption.weight(.bold))
                        Text(isExpanded ? "Hide chef chat" : "Open chef chat")
                            .font(.caption.weight(.heavy))
                    }
                    .foregroundStyle(.scranOrange)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.scranOrange)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Context “one card at a time” pager at the bottom

fileprivate struct ChefContextHighlight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let tint: Color
}

fileprivate let chefContextHighlights: [ChefContextHighlight] = [
    .init(
        icon: "clock.badge.checkmark",
        title: "Your week skews quick",
        detail: "Most dinners are in the 20–30 minute range. Perfect for after-work energy.",
        tint: .scranOrange
    ),
    .init(
        icon: "leaf.fill",
        title: "Veg is looking strong",
        detail: "You’ve got plenty of veg-heavy dishes. I can keep that going if you like.",
        tint: .green
    ),
    .init(
        icon: "basket.fill",
        title: "Compact shopping list",
        detail: "Your current plan fits into a single basket shop — no sprawling supermarket run.",
        tint: .purple
    )
]

fileprivate struct ChefContextPager: View {
    let highlights: [ChefContextHighlight]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.scranOrange)
                Text("This week, Scranly notices…")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }
            .padding(.horizontal)

            TabView {
                ForEach(highlights) { h in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(h.tint.opacity(0.12))
                                    .frame(width: 42, height: 42)
                                Image(systemName: h.icon)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(h.tint)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(h.title)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                Text(h.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 5, y: 3)
                    .padding(.horizontal)
                }
            }
            .frame(height: 140)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Collapsible Ask Scranly panel (bottom sheet)

fileprivate struct ChefChatPanel: View {
    @Binding var messages: [ChefChatMessage]
    @Binding var inputText: String
    let quickPrompts: [String]
    var onSend: () -> Void
    var onSendPrompt: (String) -> Void
    var onClose: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                // Handle
                Capsule()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 6)

                // Header row
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.scranOrange)
                    Text("Ask Scranly")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .padding(6)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)

                // Quick prompts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { prompt in
                            Button {
                                onSendPrompt(prompt)
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
                    .padding(.horizontal, 12)
                }

                // Chat transcript
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { msg in
                                ChefBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
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

                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray.opacity(0.4)
                                : .scranOrange
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 8)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity,
                   maxHeight: geo.size.height * 0.72,
                   alignment: .bottom)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, y: -2)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Chef root view (Ask Scranly home)

struct ChefView: View {
    @State private var messages: [ChefChatMessage] = [
        .init(text: "Hey, I’m Scranly. Ask me anything about dinner this week.", isUser: false)
    ]
    @State private var inputText: String = ""
    @State private var isChatExpanded: Bool = false

    private let quickPrompts: [String] = [
        "Plan my week of dinners",
        "Use up chicken, spinach, rice",
        "Make tonight lighter",
        "Cook in under 20 minutes",
        "Plan & shop for 2 people"
    ]

    // Slim KPIs for context (kept light)
    private let sampleKPI: [KPI] = [
        .init(icon: "flame.fill", value: "3,420", label: "kcal planned", tint: .orange),
        .init(icon: "clock.fill", value: "26m",   label: "avg cook time", tint: .blue)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header below the notch
                    ScranlyLogoBar()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {

                            // Greeting + big Ask Scranly hero
                            VStack(spacing: 12) {
                                GreetingHello(userName: "Alex")

                                AskScranlyHeroCard(
                                    isExpanded: isChatExpanded,
                                    onTap: {
                                        withAnimation(.spring(response: 0.35,
                                                              dampingFraction: 0.88)) {
                                            isChatExpanded.toggle()
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)

                            // “This week” context (basket + tiny KPIs)
                            VStack(alignment: .leading, spacing: 12) {
                                BasketSummaryChip(
                                    title: "This week’s shop",
                                    itemsCount: 16,
                                    totalGBP: 42.75,
                                    onTap: {
                                        // wire to Shop tab later
                                    }
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("This week at a glance")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    KPIGrid(kpis: sampleKPI)
                                }
                            }
                            .padding(.horizontal)

                            // Bottom context window: one visual nugget at a time
                            ChefContextPager(highlights: chefContextHighlights)

                            Spacer(minLength: 40)
                        }
                        .padding(.bottom, 100) // space for chat sheet handle
                    }
                }

                // Bottom collapsible chat sheet
                if isChatExpanded {
                    ChefChatPanel(
                        messages: $messages,
                        inputText: $inputText,
                        quickPrompts: quickPrompts,
                        onSend: { sendMessage() },
                        onSendPrompt: { prompt in
                            sendFromPrompt(prompt)
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                isChatExpanded = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
