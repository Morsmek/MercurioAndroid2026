import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var conversations: [ConversationViewModel] = []
    @State private var contacts: [Contact] = []
    @State private var isLoading = true
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    ChatsListView(conversations: filteredConversations, contacts: contacts)
                        .tabItem {
                            Label("Chats", systemImage: "message.fill")
                        }
                        .tag(0)

                    GroupsListView()
                        .tabItem {
                            Label("Groups", systemImage: "person.3.fill")
                        }
                        .tag(1)

                    SettingsView(contacts: $contacts)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(2)
                }
                .tint(.orange)
            }
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Mercurio")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: AddContactView(onContactAdded: loadData)) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
        }
    }

    private var filteredConversations: [ConversationViewModel] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter {
            $0.contactName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadData() async {
        guard let myId = appState.mercurioId else { return }

        do {
            contacts = try await SupabaseService.shared.fetchContacts(for: myId)
            let convs = try await SupabaseService.shared.fetchConversations(for: myId)

            conversations = convs.compactMap { conv in
                let otherId = conv.otherParticipantId(myId: myId)
                let contact = contacts.first { $0.contactMercurioId == otherId }
                let name = contact?.displayName ?? "User \(otherId.prefix(10))..."

                return ConversationViewModel(
                    conversation: conv,
                    contactName: name,
                    unreadCount: 0
                )
            }

            isLoading = false
        } catch {
            print("Error loading data: \(error)")
            isLoading = false
        }
    }
}

struct ConversationViewModel: Identifiable {
    let conversation: Conversation
    let contactName: String
    var unreadCount: Int

    var id: String { conversation.id }
}

struct ChatsListView: View {
    let conversations: [ConversationViewModel]
    let contacts: [Contact]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "message")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange.opacity(0.5))

                    Text("No conversations yet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Tap + to start a new chat")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                List {
                    ForEach(conversations) { convViewModel in
                        NavigationLink(destination: ChatView(
                            conversationId: convViewModel.conversation.id,
                            contactName: convViewModel.contactName,
                            contactId: convViewModel.conversation.otherParticipantId(myId: convViewModel.conversation.participant1Id)
                        )) {
                            ConversationRow(viewModel: convViewModel)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

struct ConversationRow: View {
    let viewModel: ConversationViewModel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(viewModel.contactName.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.contactName)
                    .font(.headline)
                    .foregroundColor(.white)

                if let lastMessage = viewModel.conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessageAt = viewModel.conversation.lastMessageAt {
                    Text(formatTime(lastMessageAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                if viewModel.unreadCount > 0 {
                    Text("\(viewModel.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }

        return formatter.string(from: date)
    }
}

struct GroupsListView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "person.3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange.opacity(0.5))

                Text("No groups yet")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Group chats coming soon")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}
