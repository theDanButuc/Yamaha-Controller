import SwiftUI

struct MorningAlarmView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @State private var isExpanded = false

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
                        .pickerStyle(.menu).frame(width: 60)
                        Text(":").foregroundColor(.secondary)
                        Picker("", selection: $settings.morningMinute) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu).frame(width: 60)
                    }

                    // Day-of-week selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Days")
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            ForEach(Array(zip(0..<7, ["Su","Mo","Tu","We","Th","Fr","Sa"])), id: \.0) { day, label in
                                let selected = settings.morningWeekdays.contains(day)
                                Button {
                                    var days = settings.morningWeekdays
                                    if selected { days.removeAll { $0 == day } }
                                    else { days.append(day) }
                                    if !days.isEmpty { settings.morningWeekdays = days }
                                } label: {
                                    Text(label)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .frame(width: 28, height: 22)
                                        .background(selected ? Color.accentColor : Color(white: 0.18))
                                        .foregroundColor(selected ? .white : .secondary)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack {
                        Text("Source")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $settings.morningSource) {
                            ForEach(YamahaAPIService.allSources, id: \.value) { s in
                                Text(s.label).tag(s.value)
                            }
                        }
                        .pickerStyle(.menu).frame(width: 140)
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
                            .pickerStyle(.menu).frame(width: 120)
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
