import SwiftUI

struct ServiceToggleView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var showingConfirmation = false
    @State private var pendingAction: ServiceAction?

    enum ServiceAction {
        case enable, disable
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 40) {
                Spacer()

                // Status Text
                VStack(spacing: 8) {
                    Text(statusText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)

                    if !networkManager.isBackendAvailable {
                        Text("Backend Unavailable")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Big Circular Power Button
                Button(action: {
                    if networkManager.isBackendAvailable {
                        if networkManager.isServiceEnabled {
                            pendingAction = .disable
                            showingConfirmation = true
                        } else {
                            pendingAction = .enable
                            showingConfirmation = true
                        }
                    }
                }) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(buttonColor, lineWidth: 4)
                            .frame(width: 180, height: 180)

                        // Inner fill
                        Circle()
                            .fill(buttonColor.opacity(networkManager.isServiceEnabled ? 0.2 : 0.1))
                            .frame(width: 160, height: 160)

                        // Power icon
                        Image(systemName: "power")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(buttonColor)

                        // Loading overlay
                        if networkManager.isLoading {
                            Circle()
                                .stroke(Color.clear, lineWidth: 4)
                                .frame(width: 180, height: 180)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(2.0)
                                )
                        }
                    }
                }
                .disabled(networkManager.isLoading || !networkManager.isBackendAvailable)
                .scaleEffect(networkManager.isLoading ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: networkManager.isLoading)

                // Error Message
                if let error = networkManager.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Minimal Service Information
                VStack(spacing: 8) {
                    Text("Mira Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
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
                     "Are you sure you want to enable Mira?" :
                     "Are you sure you want to disable Mira?")
            }
        }
    }

    private var statusText: String {
        if !networkManager.isBackendAvailable {
            return "Service Unavailable"
        } else if networkManager.isServiceEnabled {
            return "Service Enabled"
        } else {
            return "Service Disabled"
        }
    }

    private var statusColor: Color {
        if !networkManager.isBackendAvailable {
            return .gray
        } else if networkManager.isServiceEnabled {
            return .green
        } else {
            return .red
        }
    }

    private var buttonColor: Color {
        if !networkManager.isBackendAvailable {
            return .gray
        } else if networkManager.isServiceEnabled {
            return .green
        } else {
            return .gray
        }
    }
}

#Preview {
    ServiceToggleView()
}