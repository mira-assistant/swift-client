import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var locationTracker = LocationTracker()
    
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func signalBars(for rssi: Double) -> Int {
        switch rssi {
        case -40...:
            return 4
        case -55..<(-40):
            return 3
        case -70..<(-55):
            return 2
        case -85..<(-70):
            return 1
        default:
            return 0
        }
    }
}

#Preview {
    DashboardView()
}