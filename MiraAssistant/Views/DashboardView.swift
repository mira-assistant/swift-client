import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var locationTracker = LocationTracker()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Mira Assistant")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Dashboard")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Service Status Indicator
                        HStack {
                            Circle()
                                .fill(networkManager.isServiceEnabled ? .green : .red)
                                .frame(width: 12, height: 12)
                            Text(networkManager.isServiceEnabled ? "Online" : "Offline")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.horizontal)
                    
                    // Location Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("Current Location")
                                .font(.headline)
                            Spacer()
                            if locationTracker.isTracking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if let location = locationTracker.currentLocation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lat: \(location.coordinate.latitude, specifier: "%.4f")")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Lng: \(location.coordinate.longitude, specifier: "%.4f")")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Accuracy: ±\(location.horizontalAccuracy, specifier: "%.1f")m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Location not available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let error = locationTracker.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // RSSI Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                            Text("Connected Clients & RSSI")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if locationTracker.connectedClients.isEmpty {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                Text("No connected clients")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(locationTracker.connectedClients, id: \.self) { clientId in
                                    HStack {
                                        Text(clientId)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if let rssi = locationTracker.clientRSSI[clientId] {
                                            Text("\(rssi, specifier: "%.0f") dBm")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(rssiColor(for: rssi), in: Capsule())
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Interaction Data Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.purple)
                            Text("Interactions")
                                .font(.headline)
                            Spacer()
                            
                            if networkManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if networkManager.interactionData.isEmpty {
                            VStack {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No interaction data available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                        } else {
                            Chart(networkManager.interactionData) { interaction in
                                LineMark(
                                    x: .value("Time", interaction.timestamp),
                                    y: .value("Duration", interaction.duration ?? 0)
                                )
                                .foregroundStyle(.purple)
                            }
                            .frame(height: 150)
                        }
                        
                        if let error = networkManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                            Text("Quick Actions")
                                .font(.headline)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                if locationTracker.isTracking {
                                    locationTracker.stopLocationTracking()
                                } else {
                                    locationTracker.requestLocationPermission()
                                }
                            }) {
                                HStack {
                                    Image(systemName: locationTracker.isTracking ? "location.slash" : "location.viewfinder")
                                    Text(locationTracker.isTracking ? "Stop Tracking" : "Start Tracking")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                Task {
                                    await networkManager.fetchInteractionData()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh Data")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await networkManager.fetchInteractionData()
            }
        }
        .task {
            await networkManager.fetchInteractionData()
        }
    }
    
    private func rssiColor(for rssi: Double) -> Color {
        switch rssi {
        case -40...:
            return .green
        case -60..<(-40):
            return .yellow
        case -80..<(-60):
            return .orange
        default:
            return .red
        }
    }
}