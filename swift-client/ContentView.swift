import SwiftUI

struct ContentView: View {
	@State private var selectedTab = 1

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
					Image(systemName: "power.circle")
					Text("Service")
				}
				.tag(1)

			AudioEmbeddingView()
				.tabItem {
					Image(systemName: "mic.circle")
					Text("Audio")
				}
				.tag(2)
		}
		.accentColor(.green)
		.onAppear {
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
