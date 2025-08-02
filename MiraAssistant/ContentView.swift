import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1 // Start with Service Control (center tab)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Left Tab - Dashboard
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Center Tab - Service Control (highlighted differently)
            ServiceToggleView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "power.circle.fill" : "power.circle")
                    Text("Service")
                }
                .tag(1)
            
            // Right Tab - Audio Training
            AudioEmbeddingView()
                .tabItem {
                    Image(systemName: "mic.circle")
                    Text("Audio")
                }
                .tag(2)
        }
        .accentColor(.green) // Changed from purple to green to match desktop client
        .onAppear {
            // Custom tab bar appearance for center tab highlighting
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}