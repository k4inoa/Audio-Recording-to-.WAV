import SwiftUI

@main
struct AudioSamplerApp: App {
    @StateObject private var viewModel = AudioSamplerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    viewModel.handleIncomingURL(url)
                }
        }
    }
}
