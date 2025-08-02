import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var clientId: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Client ID Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Client Configuration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Client ID")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your client ID", text: $clientId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Text("This ID will be used to identify your device when connecting to the Mira backend.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: saveClientId) {
                            Text("Save Client ID")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Device Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Device Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "Device Name", value: UIDevice.current.name)
                            InfoRow(label: "System Version", value: UIDevice.current.systemVersion)
                            InfoRow(label: "Model", value: UIDevice.current.model)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear(perform: loadClientId)
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadClientId() {
        clientId = UserDefaults.standard.string(forKey: "ClientID") ?? generateDefaultClientId()
    }
    
    private func saveClientId() {
        guard !clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Client ID cannot be empty"
            showingAlert = true
            return
        }
        
        UserDefaults.standard.set(clientId, forKey: "ClientID")
        alertMessage = "Client ID saved successfully"
        showingAlert = true
    }
    
    private func generateDefaultClientId() -> String {
        let deviceName = UIDevice.current.name
        return deviceName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "'", with: "")
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    SettingsView()
}