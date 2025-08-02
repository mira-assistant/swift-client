import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var distanceCalculator = DistanceCalculator()
    
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
                    
                    // Distance Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("Current Distance")
                                .font(.headline)
                            Spacer()
                            if distanceCalculator.isCalculating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        Text("\(distanceCalculator.currentDistance, specifier: "%.1f") m")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let error = distanceCalculator.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
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
                                distanceCalculator.requestLocationPermission()
                                // Set a default target location (can be made configurable)
                                distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
                            }) {
                                HStack {
                                    Image(systemName: "location.viewfinder")
                                    Text("Start Tracking")
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
}

#Preview {
    DashboardView()
}