import Foundation

class AppUIState: ObservableObject {
    static let shared = AppUIState()
    @Published var showSettings = false
    @Published var showAudio = false
    @Published var showMusicCenter = false
    private init() {}

    func toggleSettings() {
        showAudio = false          // right-side mutual exclusion
        showSettings.toggle()
    }

    func toggleAudio() {
        showSettings = false       // right-side mutual exclusion
        showAudio.toggle()
    }

    func toggleMusicCenter() {
        showMusicCenter.toggle()   // left panel, independent from right panels
    }
}
