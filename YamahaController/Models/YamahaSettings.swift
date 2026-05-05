import Foundation
import Combine

class YamahaSettings: ObservableObject {
    static let shared = YamahaSettings()

    @Published var ipAddress: String {
        didSet { UserDefaults.standard.set(ipAddress, forKey: "yamaha_ip"); rescheduleAll() }
    }
    @Published var morningEnabled: Bool {
        didSet { UserDefaults.standard.set(morningEnabled, forKey: "morning_enabled"); scheduleMorning() }
    }
    @Published var morningHour: Int {
        didSet { UserDefaults.standard.set(morningHour, forKey: "morning_hour"); scheduleMorning() }
    }
    @Published var morningMinute: Int {
        didSet { UserDefaults.standard.set(morningMinute, forKey: "morning_minute"); scheduleMorning() }
    }
    @Published var morningSource: String {
        didSet { UserDefaults.standard.set(morningSource, forKey: "morning_source"); scheduleMorning() }
    }
    @Published var morningPreset: Int {
        didSet { UserDefaults.standard.set(morningPreset, forKey: "morning_preset"); scheduleMorning() }
    }
    @Published var autoOffEnabled: Bool {
        didSet { UserDefaults.standard.set(autoOffEnabled, forKey: "autooff_enabled"); scheduleAutoOff() }
    }
    @Published var autoOffHour: Int {
        didSet { UserDefaults.standard.set(autoOffHour, forKey: "autooff_hour"); scheduleAutoOff() }
    }
    @Published var autoOffMinute: Int {
        didSet { UserDefaults.standard.set(autoOffMinute, forKey: "autooff_minute"); scheduleAutoOff() }
    }

    private init() {
        let ud = UserDefaults.standard
        ipAddress    = ud.string(forKey: "yamaha_ip") ?? "192.168.178.65"
        morningEnabled = ud.bool(forKey: "morning_enabled")
        morningHour    = ud.integer(forKey: "morning_hour")
        morningMinute  = ud.integer(forKey: "morning_minute")
        morningSource  = ud.string(forKey: "morning_source") ?? "net_radio"
        let preset     = ud.integer(forKey: "morning_preset")
        morningPreset  = preset == 0 ? 1 : preset
        autoOffEnabled = ud.bool(forKey: "autooff_enabled")
        autoOffHour    = ud.integer(forKey: "autooff_hour")
        autoOffMinute  = ud.integer(forKey: "autooff_minute")
    }

    private func scheduleMorning() {
        if morningEnabled {
            SchedulerService.shared.scheduleMorningAlarm(
                hour: morningHour, minute: morningMinute,
                ip: ipAddress, source: morningSource, preset: morningPreset
            )
        } else {
            SchedulerService.shared.unscheduleMorningAlarm()
        }
    }

    private func scheduleAutoOff() {
        if autoOffEnabled {
            SchedulerService.shared.scheduleAutoOff(hour: autoOffHour, minute: autoOffMinute, ip: ipAddress)
        } else {
            SchedulerService.shared.unscheduleAutoOff()
        }
    }

    private func rescheduleAll() {
        scheduleMorning()
        scheduleAutoOff()
    }
}
