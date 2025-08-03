import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var networkManager: NetworkManager
    @State private var showingConfirmation = false
    @State private var pendingAction: ServiceAction?
    
    enum ServiceAction {
        case enable, disable
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Dashboard Tab
            TabBarButton(
                systemImage: "chart.line.uptrend.xyaxis",
                title: "Dashboard",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            Spacer()
            
            // Service Toggle Button (Center)
            Button(action: handleServiceToggle) {
                ZStack {
                    Circle()
                        .fill(serviceButtonColor)
                        .frame(width: 60, height: 60)
                        .shadow(color: serviceButtonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    if networkManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .offset(y: -15) // Elevate the center button
            .disabled(networkManager.isLoading || !networkManager.isBackendAvailable)
            
            Spacer()
            
            // Settings Tab
            TabBarButton(
                systemImage: "gearshape",
                title: "Settings",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
        )
        .confirmationDialog(
            "Confirm Action",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(action == .enable ? "Enable Service" : "Disable Service") {
                    Task {
                        switch action {
                        case .enable:
                            await networkManager.enableService()
                        case .disable:
                            await networkManager.disableService()
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            if let action = pendingAction {
                Text(action == .enable ?
                     "Are you sure you want to enable Mira?" :
                     "Are you sure you want to disable Mira?")
            }
        }
    }
    
    private var serviceButtonColor: Color {
        if !networkManager.isBackendAvailable {
            return .gray
        } else if networkManager.isLoading {
            return .gray
        } else if networkManager.isServiceEnabled {
            return .green
        } else {
            return .red
        }
    }
    
    private func handleServiceToggle() {
        if networkManager.isBackendAvailable {
            if networkManager.isServiceEnabled {
                pendingAction = .disable
                showingConfirmation = true
            } else {
                pendingAction = .enable
                showingConfirmation = true
            }
        }
    }
}

struct TabBarButton: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .gray)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .green : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBarView(selectedTab: .constant(0))
            .environmentObject(NetworkManager())
    }
    .background(Color(.systemGray6))
}