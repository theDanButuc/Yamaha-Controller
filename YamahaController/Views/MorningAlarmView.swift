import SwiftUI

struct MorningAlarmView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @State private var isExpanded = false

    private let sources: [(label: String, value: String)] = [
        ("Net Radio",  "net_radio"),
        ("FM Tuner",   "tuner"),
        ("Bluetooth",  "bluetooth"),
        ("AirPlay",    "airplay"),
    ]

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Enable", isOn: $settings.morningEnabled)

                if settings.morningEnabled {
                    HStack {
                        Text("Time")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $settings.morningHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(String(format: "%02d", h)).tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        Text(":").foregroundColor(.secondary)
                        Picker("", selection: $settings.morningMinute) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                    }

                    HStack {
                        Text("Source")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $settings.morningSource) {
                            ForEach(sources, id: \.value) { s in
                                Text(s.label).tag(s.value)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    if settings.morningSource == "net_radio" {
                        HStack {
                            Text("Preset")
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $settings.morningPreset) {
                                ForEach(1...5, id: \.self) { p in
                                    Text("Preset \(p)").tag(p)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                Text("Morning Alarm")
                    .font(.headline)
                if settings.morningEnabled {
                    Circle()
                        .fill(Color(red: 0.18, green: 0.72, blue: 0.35))
                        .frame(width: 7, height: 7)
                }
            }
        }
    }
}
