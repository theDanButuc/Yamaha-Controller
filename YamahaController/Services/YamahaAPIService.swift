import Foundation
import Combine
import UserNotifications

enum PowerState: Equatable {
    case on
    case standby
    case unknown
}

class YamahaAPIService: ObservableObject {
    static let shared = YamahaAPIService()

    @Published var powerState: PowerState = .unknown
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var currentInput: String = ""
    @Published var volume: Int = 0
    @Published var maxVolume: Int = 100
    @Published var soundProgram: String = ""
    @Published var isMuted: Bool = false
    @Published var actualVolumeDb: Double? = nil
    @Published var nowPlayingTrack: String = ""
    @Published var nowPlayingArtist: String = ""
    @Published var albumArtURLString: String = ""
    @Published var tunerBand: String = "fm"
    @Published var soundProgramList: [String] = []
    @Published var currentNetPreset: Int = 1
    @Published var activeScene: Int? = {
        UserDefaults.standard.object(forKey: "active_scene") as? Int
    }()

    private var pollingTimer: Timer?
    private var playInfoTimer: Timer?
    private var previousState: PowerState = .unknown

    private init() {}

    private var baseURL: String {
        "http://\(YamahaSettings.shared.ipAddress)/YamahaExtendedControl/v1"
    }

    // MARK: - Polling

    func startPolling() {
        fetchStatus()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchStatus()
        }
        playInfoTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.fetchPlayInfoIfNeeded()
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        playInfoTimer?.invalidate()
        playInfoTimer = nil
    }

    func fetchStatus() {
        guard !YamahaSettings.shared.ipAddress.isEmpty else {
            DispatchQueue.main.async {
                self.powerState = .unknown
                self.lastError = "No IP address configured."
            }
            return
        }
        guard let url = URL(string: "\(baseURL)/main/getStatus") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.powerState = .unknown
                    self.lastError = error.localizedDescription
                    return
                }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let power = json["power"] as? String else {
                    self.powerState = .unknown
                    self.lastError = "Unexpected response from receiver."
                    return
                }
                self.lastError = nil
                let newState: PowerState = power == "on" ? .on : .standby

                if self.previousState != .unknown && self.previousState != newState {
                    self.sendTransitionNotification(newState: newState)
                }
                self.previousState = newState
                self.powerState = newState

                // Current input source
                if let input = json["input"] as? String {
                    self.currentInput = input
                    if newState == .on {
                        UserDefaults.standard.set(input, forKey: "last_input")
                    }
                }

                // Volume
                if let vol = json["volume"] as? Int { self.volume = vol }
                if let maxVol = json["max_volume"] as? Int { self.maxVolume = maxVol }
                if let mute = json["mute"] as? Bool { self.isMuted = mute }

                // Actual volume in dB (e.g. -30.5)
                if let av = json["actual_volume"] as? [String: Any],
                   let val = av["value"] as? Double {
                    self.actualVolumeDb = val
                } else if let val = json["actual_volume"] as? Double {
                    self.actualVolumeDb = val
                }

                // Sound program (DSP mode)
                if let sp = json["sound_program"] as? String { self.soundProgram = sp }

                // Active scene — clear on standby, keep persisted value on "on"
                if newState == .standby {
                    self.setActiveScene(nil)
                    self.nowPlayingTrack = ""
                    self.nowPlayingArtist = ""
                    self.albumArtURLString = ""
                } else {
                    self.fetchPlayInfoIfNeeded()
                    self.fetchTunerInfoIfNeeded()
                }
            }
        }.resume()
    }

    // MARK: - Commands

    func setPower(_ state: String, completion: @escaping (Error?) -> Void) {
        guard !YamahaSettings.shared.ipAddress.isEmpty,
              let url = URL(string: "\(baseURL)/main/setPower?power=\(state)") else {
            completion(URLError(.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { _, _, error in
            DispatchQueue.main.async { completion(error) }
        }.resume()
    }

    func setInput(_ input: String, completion: @escaping (Error?) -> Void) {
        guard !YamahaSettings.shared.ipAddress.isEmpty,
              let url = URL(string: "\(baseURL)/main/setInput?input=\(input)") else {
            completion(URLError(.badURL))
            return
        }
        let previous = currentInput
        currentInput = input
        nowPlayingTrack = ""
        nowPlayingArtist = ""
        albumArtURLString = ""
        URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.currentInput = previous
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.fetchPlayInfoIfNeeded()
                    }
                }
                completion(error)
            }
        }.resume()
    }

    func setVolume(_ value: Int, completion: @escaping (Error?) -> Void) {
        guard !YamahaSettings.shared.ipAddress.isEmpty,
              let url = URL(string: "\(baseURL)/main/setVolume?volume=\(value)") else {
            completion(URLError(.badURL))
            return
        }
        let previous = volume
        volume = value
        URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
            DispatchQueue.main.async {
                if error != nil { self?.volume = previous }
                completion(error)
            }
        }.resume()
    }

    func recallPreset(_ preset: Int, completion: @escaping (Error?) -> Void) {
        guard !YamahaSettings.shared.ipAddress.isEmpty,
              let url = URL(string: "\(baseURL)/netusb/recallPreset?zone=main&num=\(preset)") else {
            completion(URLError(.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { _, _, error in
            DispatchQueue.main.async { completion(error) }
        }.resume()
    }

    func recallScene(_ num: Int) {
        guard !YamahaSettings.shared.ipAddress.isEmpty,
              let url = URL(string: "\(baseURL)/main/recallScene?num=\(num)") else { return }
        setActiveScene(num)
        URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
            DispatchQueue.main.async {
                if error != nil { self?.setActiveScene(nil) }
            }
        }.resume()
    }

    // MARK: - Transport / Tuner Commands

    func setPlayback(_ playback: String) {
        guard let url = URL(string: "\(baseURL)/netusb/setPlayback?playback=\(playback)") else { return }
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }

    func fetchSoundProgramList(completion: @escaping () -> Void = {}) {
        guard !soundProgramList.isEmpty else {
            guard let url = URL(string: "\(baseURL)/main/getSoundProgramList") else { completion(); return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let list = json["sound_program_list"] as? [String] else {
                    DispatchQueue.main.async { completion() }
                    return
                }
                DispatchQueue.main.async {
                    self.soundProgramList = list
                    completion()
                }
            }.resume()
            return
        }
        completion()
    }

    func cycleSoundProgram() {
        fetchSoundProgramList { [weak self] in
            guard let self, !self.soundProgramList.isEmpty else { return }
            let current = self.soundProgram
            let idx = self.soundProgramList.firstIndex(of: current) ?? -1
            let next = self.soundProgramList[(idx + 1) % self.soundProgramList.count]
            guard let url = URL(string: "\(self.baseURL)/main/setSoundProgram?program=\(next.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? next)") else { return }
            URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
                if error == nil {
                    DispatchQueue.main.async { self?.soundProgram = next }
                }
            }.resume()
        }
    }

    func setBand(_ band: String) {
        guard let url = URL(string: "\(baseURL)/tuner/setBand?band=\(band)") else { return }
        tunerBand = band
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }

    func tuneStep(_ dir: String) {
        guard let url = URL(string: "\(baseURL)/tuner/setFreq?band=\(tunerBand)&tuning=\(dir)") else { return }
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }

    func switchTunerPreset(_ dir: String) {
        guard let url = URL(string: "\(baseURL)/tuner/switchPreset?zone=main&dir=\(dir)") else { return }
        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
    }

    func nextNetPreset() {
        currentNetPreset = (currentNetPreset % 5) + 1
        recallPreset(currentNetPreset) { _ in }
    }

    func prevNetPreset() {
        currentNetPreset = currentNetPreset == 1 ? 5 : currentNetPreset - 1
        recallPreset(currentNetPreset) { _ in }
    }

    // MARK: - Volume / Mute Helpers

    func volumeUp()   { setVolume(min(volume + 1, maxVolume)) { _ in } }
    func volumeDown() { setVolume(max(volume - 1, 0))         { _ in } }

    func toggleMute() {
        let enable = !isMuted
        guard let url = URL(string: "\(baseURL)/main/setMute?enable=\(enable)") else { return }
        isMuted = enable
        URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
            DispatchQueue.main.async { if error != nil { self?.isMuted = !enable } }
        }.resume()
    }

    // MARK: - Helpers

    private func setActiveScene(_ scene: Int?) {
        activeScene = scene
        if let scene {
            UserDefaults.standard.set(scene, forKey: "active_scene")
        } else {
            UserDefaults.standard.removeObject(forKey: "active_scene")
        }
    }

    // Full source list — shared across Morning Alarm, Settings, and button config
    static let allSources: [(label: String, value: String)] = [
        ("TV (HDMI ARC)", "tv"),
        ("HDMI 1",        "hdmi1"),
        ("HDMI 2",        "hdmi2"),
        ("HDMI 3",        "hdmi3"),
        ("HDMI 4",        "hdmi4"),
        ("HDMI 5",        "hdmi5"),
        ("HDMI 6",        "hdmi6"),
        ("Net Radio",     "net_radio"),
        ("Spotify",       "spotify"),
        ("Bluetooth",     "bluetooth"),
        ("AirPlay",       "airplay"),
        ("FM Tuner",      "tuner"),
        ("Server",        "server"),
        ("USB",           "usb"),
        ("Audio 1",       "audio1"),
        ("Audio 2",       "audio2"),
        ("AV 1",          "av1"),
        ("AV 2",          "av2"),
    ]

    // Short label for keycap buttons
    static func buttonLabel(_ input: String) -> String {
        switch input.lowercased() {
        case "tv":        return "TV"
        case "hdmi1":     return "HDMI1"
        case "hdmi2":     return "HDMI2"
        case "hdmi3":     return "HDMI3"
        case "hdmi4":     return "HDMI4"
        case "hdmi5":     return "HDMI5"
        case "hdmi6":     return "HDMI6"
        case "net_radio": return "RADIO"
        case "spotify":   return "SPOTIFY"
        case "bluetooth": return "BT"
        case "airplay":   return "APLAY"
        case "tuner":     return "TUNER"
        case "server":    return "SERVER"
        case "usb":       return "USB"
        case "audio1":    return "AUD 1"
        case "audio2":    return "AUD 2"
        case "av1":       return "AV 1"
        case "av2":       return "AV 2"
        default:          return String(input.uppercased().prefix(6))
        }
    }

    static func formatInput(_ raw: String) -> String {
        switch raw.lowercased() {
        case "hdmi1":      return "HDMI 1"
        case "hdmi2":      return "HDMI 2"
        case "hdmi3":      return "HDMI 3"
        case "hdmi4":      return "HDMI 4"
        case "hdmi5":      return "HDMI 5"
        case "hdmi6":      return "HDMI 6"
        case "av1":        return "AV 1"
        case "av2":        return "AV 2"
        case "av3":        return "AV 3"
        case "audio1":     return "Audio 1"
        case "audio2":     return "Audio 2"
        case "audio3":     return "Audio 3"
        case "audio4":     return "Audio 4"
        case "optical1":   return "Optical 1"
        case "optical2":   return "Optical 2"
        case "coaxial1":   return "Coaxial 1"
        case "coaxial2":   return "Coaxial 2"
        case "net_radio":  return "Net Radio"
        case "tuner":      return "Tuner"
        case "bluetooth":  return "Bluetooth"
        case "airplay":    return "AirPlay"
        case "spotify":    return "Spotify"
        case "server":     return "Server"
        case "usb":        return "USB"
        case "tv":         return "TV"
        case "multi_ch":   return "Multi Ch"
        default:
            return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: - Play Info

    func fetchPlayInfoIfNeeded() {
        let input = currentInput.lowercased()
        guard powerState == .on,
              input == "net_radio" || input == "spotify" else {
            nowPlayingTrack = ""
            nowPlayingArtist = ""
            albumArtURLString = ""
            if powerState == .on && currentInput.lowercased() == "tuner" {
                fetchTunerInfoIfNeeded()
            }
            return
        }
        guard let url = URL(string: "\(baseURL)/netusb/getPlayInfo") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            DispatchQueue.main.async {
                let track  = json["track"]  as? String ?? ""
                let artist = json["artist"] as? String ?? ""
                self.nowPlayingTrack  = track
                self.nowPlayingArtist = artist

                if let artPath = json["albumart_url"] as? String,
                   let artId   = json["albumart_id"]  as? Int,
                   artId > 0,
                   !artPath.isEmpty {
                    self.albumArtURLString = "http://\(YamahaSettings.shared.ipAddress)\(artPath)"
                } else {
                    self.albumArtURLString = ""
                }
            }
        }.resume()
    }

    func fetchTunerInfoIfNeeded() {
        guard powerState == .on,
              currentInput.lowercased() == "tuner",
              let url = URL(string: "\(baseURL)/tuner/getPlayInfo") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            DispatchQueue.main.async {
                if let band = json["band"] as? String { self.tunerBand = band }
            }
        }.resume()
    }

    // MARK: - Sequence

    func powerOnSequence(completion: @escaping (Error?) -> Void) {
        let lastInput = UserDefaults.standard.string(forKey: "last_input") ?? ""

        setPower("on") { error in
            if let error { completion(error); return }
            guard !lastInput.isEmpty else { completion(nil); return }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                self.setInput(lastInput, completion: completion)
            }
        }
    }

    // MARK: - Notifications

    private func sendTransitionNotification(newState: PowerState) {
        let content = UNMutableNotificationContent()
        content.title = "Yamaha Controller"
        content.sound = .default
        switch newState {
        case .on:
            content.body = "Receiver turned on automatically."
        case .standby:
            content.body = "Receiver turned off automatically."
        case .unknown:
            return
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
