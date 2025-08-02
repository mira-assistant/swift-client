import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var locationTracker = LocationTracker()
    @State private var searchText = ""
    @State private var searchResults: [InteractionSearchResult] = []
    @State private var isSearchingInteractions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Minimal Header
                    HStack {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Audio Training Service Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Audio Training Service")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        AudioTrainingView()
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Interaction Search
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Search Interactions")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search interactions...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onSubmit {
                                    searchInteractions()
                                }
                            
                            if isSearchingInteractions {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                        
                        if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(searchResults) { result in
                                    InteractionSearchRow(result: result)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Recent Interactions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Interactions")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if networkManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if networkManager.interactionData.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                Text("No recent interactions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(networkManager.interactionData.prefix(5)) { interaction in
                                    HStack {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 6, height: 6)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(interaction.type)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Text(formatDate(interaction.timestamp))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let duration = interaction.duration {
                                            Text("\(duration, specifier: "%.1f")s")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Connected Clients & RSSI
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Connected Clients")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if locationTracker.connectedClients.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                Text("No connected clients")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(locationTracker.connectedClients, id: \.self) { clientId in
                                    HStack {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 6, height: 6)
                                        
                                        Text(clientId)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if let rssi = locationTracker.clientRSSI[clientId] {
                                            HStack(spacing: 4) {
                                                Text("\(rssi, specifier: "%.0f")")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("dBm")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                
                                                // Signal strength bars
                                                HStack(spacing: 2) {
                                                    ForEach(0..<4) { bar in
                                                        Rectangle()
                                                            .fill(bar < signalBars(for: rssi) ? .green : .gray.opacity(0.3))
                                                            .frame(width: 3, height: CGFloat(4 + bar * 2))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await networkManager.fetchInteractionData()
                await locationTracker.fetchConnectedClients()
            }
        }
        .task {
            await networkManager.fetchInteractionData()
            await locationTracker.fetchConnectedClients()
        }
    }
    
    private func searchInteractions() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearchingInteractions = true
        
        Task {
            await performInteractionSearch(query: searchText)
            await MainActor.run {
                isSearchingInteractions = false
            }
        }
    }
    
    private func performInteractionSearch(query: String) async {
        let results = await networkManager.searchInteractions(query: query)
        await MainActor.run {
            searchResults = results
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func signalBars(for rssi: Double) -> Int {
		if rssi >= -40.0 {
			return 4
		} else if rssi >= -55.0 {
			return 3
		} else if rssi >= -70.0 {
			return 2
		} else if rssi >= -85.0 {
			return 1
		} else {
			return 0
		}
    }
}

struct InteractionSearchRow: View {
    let result: InteractionSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(result.relevance * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(formatDate(result.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
