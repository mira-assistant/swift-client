import SwiftUI

struct ServiceToggleView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var showingConfirmation = false
    @State private var pendingAction: ServiceAction?
    
    enum ServiceAction {
        case enable, disable
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "power")
                        .font(.system(size: 50))
                        .foregroundColor(networkManager.isServiceEnabled ? .green : .gray)
                    
                    Text("Service Control")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage the Mira Assistant service")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Service Status Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Service Status")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(networkManager.isServiceEnabled ? .green : .red)
                                    .frame(width: 12, height: 12)
                                
                                Text(networkManager.isServiceEnabled ? "Enabled" : "Disabled")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(networkManager.isServiceEnabled ? .green : .red)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: networkManager.isServiceEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(networkManager.isServiceEnabled ? .green : .red)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Control Buttons
                VStack(spacing: 16) {
                    if networkManager.isServiceEnabled {
                        Button(action: {
                            pendingAction = .disable
                            showingConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Disable Service")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                        }
                        .disabled(networkManager.isLoading)
                    } else {
                        Button(action: {
                            pendingAction = .enable
                            showingConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Enable Service")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                        }
                        .disabled(networkManager.isLoading)
                    }
                    
                    if networkManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = networkManager.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Service Information
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Service Information")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(title: "Backend URL", value: "api.mira-assistant.com")
                        InfoRow(title: "Version", value: "1.0.0")
                        InfoRow(title: "Last Updated", value: formatDate(Date()))
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .navigationBarHidden(true)
        }
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
                     "Are you sure you want to enable the Mira Assistant service?" : 
                     "Are you sure you want to disable the Mira Assistant service?")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    ServiceToggleView()
}