//
//  AIAssistantView.swift
//  PocketPrep
//
//  Competition-level AI assistant using Apple Foundation Models
//  Multi-turn conversations, streaming text, categorized suggestions,
//  smart context pickers, premium animations & glassmorphism
//

import SwiftUI
import Combine

struct AIAssistantView: View {
    @ObservedObject var listsViewModel: ListsViewModel
    @StateObject private var chatVM = AIChatViewModel()
    
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showListPicker = false
    @State private var pendingSuggestion = ""
    @State private var showNewListAlert = false
    @State private var newListName = ""
    @State private var selectedSuggestions: Set<String> = []
    @State private var collapsedCategories: Set<String> = []
    
    // Apple Intelligence availability
    private let isModelAvailable = FoundationModelService.isAvailable
    
    // Smart context state
    @State private var showContextPicker = false
    @State private var selectedTripType: TripContext.TripType = .travel
    @State private var selectedDuration: TripContext.TripDuration = .weekend
    @State private var selectedClimate: TripContext.TripClimate = .warm
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isModelAvailable {
                    chatView
                } else {
                    appleIntelligenceUnavailableView
                }
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                if !chatVM.messages.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                chatVM.clearChat()
                                selectedSuggestions.removeAll()
                                collapsedCategories.removeAll()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Unavailable Screen
    
    private var appleIntelligenceUnavailableView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#764ba2")?.opacity(0.2) ?? .purple.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 90
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.systemGray4),
                                    Color(.systemGray3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                    
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Text block
                VStack(spacing: 12) {
                    Text("Apple Intelligence Required")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("This feature uses on-device AI powered by Apple Intelligence, available on iPhone 16 or later running iOS 26.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 32)
                
                // Info card
                VStack(alignment: .leading, spacing: 14) {
                    InfoRow(
                        icon: "iphone",
                        iconColor: .blue,
                        title: "iPhone 16 or later",
                        subtitle: "iPhone 16, 16 Plus, 16 Pro, or 16 Pro Max"
                    )
                    Divider()
                    InfoRow(
                        icon: "cpu",
                        iconColor: .purple,
                        title: "iOS 26 required",
                        subtitle: "Update your device in Settings → General → Software Update"
                    )
                    Divider()
                    InfoRow(
                        icon: "wifi.slash",
                        iconColor: .green,
                        title: "Fully offline",
                        subtitle: "All processing happens on your device — no internet needed"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 24)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Chat View
    
    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if chatVM.messages.isEmpty {
                            welcomeSection
                        }
                        
                        ForEach(Array(chatVM.messages.enumerated()), id: \.element.id) { index, message in
                            ChatBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Streaming text
                        if chatVM.isStreaming && !chatVM.streamingText.isEmpty {
                            StreamingBubble(text: chatVM.streamingText)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Categorized suggestions
                        if !chatVM.categorizedSuggestions.isEmpty {
                            categorizedSuggestionsSection
                        }
                        
                        if chatVM.isLoading && !chatVM.isStreaming {
                            TypingIndicator()
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.vertical)
                }
                .onChange(of: chatVM.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: chatVM.streamingText) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: chatVM.categorizedSuggestions.count) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            
            Divider()
            inputBar
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    // MARK: - Welcome
    
    private var welcomeSection: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            
            // AI brand icon with animated gradient
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#764ba2")?.opacity(0.2) ?? .purple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#667eea") ?? .blue,
                                Color(hex: "#764ba2") ?? .purple,
                                Color(hex: "#f093fb") ?? .pink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .purple.opacity(0.35), radius: 25, y: 10)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundColor(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            
            VStack(spacing: 8) {
                Text("PocketPrep AI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                HStack(spacing: 6) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 11))
                    Text("Powered by Apple Intelligence")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(.systemGray6)))
            }
            
            Text("Tell me what you're packing for and\nI'll suggest categorized essentials!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            // Smart Context Picker
            smartContextButton
            
            // Quick prompts
            VStack(spacing: 10) {
                ForEach(quickPrompts, id: \.text) { prompt in
                    Button {
                        inputText = prompt.text
                        sendMessage()
                    } label: {
                        HStack(spacing: 10) {
                            Text(prompt.emoji)
                                .font(.title3)
                            Text(prompt.text)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var smartContextButton: some View {
        Button {
            showContextPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("Smart Suggest")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("Set trip details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.25), radius: 10, y: 4)
            )
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showContextPicker) {
            SmartContextSheet(
                selectedType: $selectedTripType,
                selectedDuration: $selectedDuration,
                selectedClimate: $selectedClimate
            ) {
                showContextPicker = false
                chatVM.sendWithContext(
                    type: selectedTripType,
                    duration: selectedDuration,
                    climate: selectedClimate
                )
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private let quickPrompts: [(emoji: String, text: String)] = [
        ("⛺", "Weekend camping trip in the mountains"),
        ("💼", "Business conference in New York"),
        ("🏖️", "Beach vacation for a week"),
        ("🎓", "First day of college essentials"),
        ("🥾", "Day hike in the national park"),
        ("🎵", "3-day music festival outdoors")
    ]
    
    // MARK: - Categorized Suggestions
    
    private var categorizedSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#f093fb") ?? .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Suggested Items")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                // Select all / deselect all
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    let allItems = chatVM.suggestions
                    if selectedSuggestions.count == allItems.count {
                        selectedSuggestions.removeAll()
                    } else {
                        selectedSuggestions = Set(allItems)
                    }
                } label: {
                    Text(selectedSuggestions.count == chatVM.suggestions.count ? "Deselect All" : "Select All")
                        .font(.caption2.bold())
                        .foregroundColor(Color(hex: "#667eea") ?? .blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            
            // Category groups
            ForEach(Array(chatVM.categorizedSuggestions.enumerated()), id: \.element.id) { catIndex, category in
                VStack(alignment: .leading, spacing: 0) {
                    // Category header
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if collapsedCategories.contains(category.name) {
                                collapsedCategories.remove(category.name)
                            } else {
                                collapsedCategories.insert(category.name)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            (Color(hex: category.color) ?? .blue).gradient
                                        )
                                )
                            
                            Text(category.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            Text("\(category.items.count)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill((Color(hex: category.color) ?? .blue).opacity(0.7))
                                )
                            
                            Spacer()
                            
                            // Category select all
                            Button {
                                let gen = UIImpactFeedbackGenerator(style: .light)
                                gen.impactOccurred()
                                let catItems = Set(category.items)
                                if catItems.isSubset(of: selectedSuggestions) {
                                    selectedSuggestions.subtract(catItems)
                                } else {
                                    selectedSuggestions.formUnion(catItems)
                                }
                            } label: {
                                let catItems = Set(category.items)
                                let allSelected = catItems.isSubset(of: selectedSuggestions) && !catItems.isEmpty
                                Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(allSelected ? (Color(hex: category.color) ?? .blue) : .secondary.opacity(0.4))
                            }
                            
                            Image(systemName: collapsedCategories.contains(category.name) ? "chevron.down" : "chevron.up")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    // Items (collapsible)
                    if !collapsedCategories.contains(category.name) {
                        VStack(spacing: 1) {
                            ForEach(Array(category.items.enumerated()), id: \.element) { itemIndex, item in
                                SuggestionItemRow(
                                    item: item,
                                    icon: chatVM.determineIcon(for: item),
                                    accentColor: Color(hex: category.color) ?? .blue,
                                    isSelected: selectedSuggestions.contains(item),
                                    onToggle: {
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.impactOccurred()
                                        if selectedSuggestions.contains(item) {
                                            selectedSuggestions.remove(item)
                                        } else {
                                            selectedSuggestions.insert(item)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 20)
            }
            
            // Create new list button
            Button {
                if selectedSuggestions.isEmpty {
                    selectedSuggestions = Set(chatVM.suggestions)
                }
                newListName = ""
                showNewListAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text(selectedSuggestions.isEmpty
                         ? "New List (All \(chatVM.suggestions.count) items)"
                         : "New List (\(selectedSuggestions.count) selected)")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.2), radius: 8, y: 4)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .confirmationDialog("Add to List", isPresented: $showListPicker) {
            ForEach(listsViewModel.lists) { list in
                Button(list.name) {
                    let icon = chatVM.determineIcon(for: pendingSuggestion)
                    let category = chatVM.determineCategory(for: pendingSuggestion)
                    listsViewModel.addItem(to: list, name: pendingSuggestion, icon: icon, category: category)
                    chatVM.removeSuggestion(pendingSuggestion)
                    selectedSuggestions.remove(pendingSuggestion)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose which list to add \"\(pendingSuggestion)\" to")
        }
        .alert("Create New List", isPresented: $showNewListAlert) {
            TextField("List name", text: $newListName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let trimmed = newListName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                
                let itemsToAdd = selectedSuggestions.isEmpty ? chatVM.suggestions : Array(selectedSuggestions)
                let items = itemsToAdd.map { suggestion in
                    (
                        name: suggestion,
                        icon: chatVM.determineIcon(for: suggestion),
                        category: chatVM.determineCategory(for: suggestion)
                    )
                }
                
                listsViewModel.createListWithItems(
                    name: trimmed,
                    icon: "sparkles",
                    colorHex: "#764ba2",
                    items: items
                )
                
                withAnimation {
                    for item in itemsToAdd {
                        chatVM.removeSuggestion(item)
                    }
                    selectedSuggestions.removeAll()
                }
                
                let aiMessage = ChatMessage(
                    text: "✅ Created \"\(trimmed)\" with \(items.count) items!",
                    isUser: false
                )
                chatVM.messages.append(aiMessage)
                
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
            }
        } message: {
            let count = selectedSuggestions.isEmpty ? chatVM.suggestions.count : selectedSuggestions.count
            Text("\(count) suggested item\(count == 1 ? "" : "s") will be added to the new list.")
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("What are you packing for?", text: $inputText)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        canSend
                        ? LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .disabled(!canSend)
            .scaleEffect(canSend ? 1.0 : 0.9)
            .animation(.spring(response: 0.2), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !chatVM.isLoading
    }
    
    // MARK: - Send
    
    private func sendMessage() {
        guard canSend else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        selectedSuggestions.removeAll()
        collapsedCategories.removeAll()
        chatVM.sendMessage(inputText)
        inputText = ""
        isInputFocused = false
    }
}

// MARK: - Suggestion Item Row

struct SuggestionItemRow: View {
    let item: String
    let icon: String
    let accentColor: Color
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Selection toggle
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color.gray.opacity(0.25), lineWidth: 2)
                        .background(
                            Circle().fill(isSelected ? accentColor : Color.clear)
                        )
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(accentColor.opacity(0.8))
                .frame(width: 20)
            
            Text(item)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

// MARK: - Streaming Bubble

struct StreamingBubble: View {
    let text: String
    @State private var cursorVisible = true
    
    let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 0) {
                Text(text)
                    .font(.body)
                
                // Blinking cursor
                Text("▍")
                    .font(.body)
                    .foregroundColor(Color(hex: "#764ba2") ?? .purple)
                    .opacity(cursorVisible ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 16)
        .onReceive(cursorTimer) { _ in
            cursorVisible.toggle()
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser { Spacer(minLength: 60) }
            
            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(message.text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color(.systemGray5))
                )
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotIndex = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 6) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(dotIndex == index ? 1.3 : 0.8)
                        .opacity(dotIndex == index ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: dotIndex)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

// MARK: - Smart Context Sheet

struct SmartContextSheet: View {
    @Binding var selectedType: TripContext.TripType
    @Binding var selectedDuration: TripContext.TripDuration
    @Binding var selectedClimate: TripContext.TripClimate
    let onGenerate: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Trip Type
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Trip Type", systemImage: "airplane")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(TripContext.TripType.allCases, id: \.self) { type in
                                Button {
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                    selectedType = type
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(type.emoji)
                                            .font(.caption)
                                        Text(type.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedType == type
                                                  ? (Color(hex: "#667eea") ?? .blue)
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                    .foregroundColor(selectedType == type ? .white : .primary)
                                }
                            }
                        }
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Duration", systemImage: "calendar")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(TripContext.TripDuration.allCases, id: \.self) { dur in
                                Button {
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                    selectedDuration = dur
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(dur.emoji)
                                            .font(.caption)
                                        Text(dur.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedDuration == dur
                                                  ? (Color(hex: "#764ba2") ?? .purple)
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                    .foregroundColor(selectedDuration == dur ? .white : .primary)
                                }
                            }
                        }
                    }
                    
                    // Climate
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Weather", systemImage: "cloud.sun")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(TripContext.TripClimate.allCases, id: \.self) { climate in
                                Button {
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                    selectedClimate = climate
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(climate.emoji)
                                            .font(.caption)
                                        Text(climate.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedClimate == climate
                                                  ? (Color(hex: "#f093fb") ?? .pink)
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                    .foregroundColor(selectedClimate == climate ? .white : .primary)
                                }
                            }
                        }
                    }
                    
                    // Preview
                    VStack(spacing: 8) {
                        Text("AI will suggest items for:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(selectedType.emoji) \(selectedType.rawValue) · \(selectedDuration.rawValue) · \(selectedClimate.emoji) \(selectedClimate.rawValue)")
                            .font(.subheadline.bold())
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    
                    // Generate button
                    Button {
                        onGenerate()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generate Packing List")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#667eea") ?? .blue,
                                            Color(hex: "#764ba2") ?? .purple,
                                            Color(hex: "#f093fb") ?? .pink
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Smart Suggest")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        let totalHeight = currentY + lineHeight
        return ArrangementResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: maxWidth, height: totalHeight)
        )
    }
    
    struct ArrangementResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }
}

// MARK: - Info Row (used in Apple Intelligence unavailable screen)

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
