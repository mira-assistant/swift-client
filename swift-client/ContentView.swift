import SwiftUI

struct ContentView: View {
	@State private var selectedTab = 0
	@StateObject private var networkManager = NetworkManager()

	var body: some View {
		ZStack {
			// Main content
			TabView(selection: $selectedTab) {
				DashboardView()
					.tag(0)
				
				SettingsView()
					.tag(1)
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
			
			// Show disconnected overlay if backend is unavailable
			if !networkManager.isBackendAvailable {
				DisconnectedView()
					.background(Color(.systemBackground))
					.transition(.opacity)
			}
			
			// Custom Tab Bar
			VStack {
				Spacer()
				CustomTabBarView(selectedTab: $selectedTab)
					.padding(.horizontal)
					.padding(.bottom, 34) // Account for safe area
			}
		}
		.onAppear {
			let appearance = UITabBarAppearance()
			appearance.configureWithTransparentBackground()
			UITabBar.appearance().standardAppearance = appearance
			UITabBar.appearance().scrollEdgeAppearance = appearance
		}
	}
}

#Preview {
	ContentView()
}
