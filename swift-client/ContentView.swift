import SwiftUI

struct ContentView: View {
	@State private var selectedTab = 1

	var body: some View {
		TabView(selection: $selectedTab) {
			Tab("Dashboard", systemImage: "chart.line.uptrend.xyaxis", value: 0 ) {
				DashboardView()
			}

			Tab("Service", systemImage: "power.circle", value: 1) {
				ServiceToggleView()
			}

			Tab("Audio", systemImage: "mic.circle", value: 2) {
				AudioEmbeddingView()
			}

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
