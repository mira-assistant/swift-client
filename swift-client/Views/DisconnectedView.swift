import SwiftUI

struct DisconnectedView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // WiFi slash-through icon
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Text("Backend Disconnected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Unable to connect to the Mira backend. Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    DisconnectedView()
}