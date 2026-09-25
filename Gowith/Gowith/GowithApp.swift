import SwiftUI
import UIKit

@main
struct GowithApp: App {
    @StateObject private var store = GowithStore()
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(locationService)
        }
    }
}
