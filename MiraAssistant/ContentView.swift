import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Dashboard")
                }
                .tag(0)
            
            ServiceToggleView()
                .tabItem {
                    Image(systemName: "power")
                    Text("Service")
                }
                .tag(1)
            
            AudioEmbeddingView()
                .tabItem {
                    Image(systemName: "waveform")
                    Text("Audio")
                }
                .tag(2)
        }
        .accentColor(.purple)
    }
}

#Preview {
    ContentView()
}