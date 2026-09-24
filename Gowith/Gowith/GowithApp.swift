import SwiftUI
import UIKit

@main
struct GowithApp: App {
    @StateObject private var store = GowithStore()
    @StateObject private var locationService = LocationService()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.07, alpha: 1)
                : UIColor(red: 0.961, green: 0.953, blue: 0.941, alpha: 1)
        }
        appearance.backgroundEffect = nil
        appearance.shadowColor = UIColor.separator
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = false
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(locationService)
        }
    }
}
