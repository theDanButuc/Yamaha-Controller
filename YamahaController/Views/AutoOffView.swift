import SwiftUI

struct AutoOffView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Enable", isOn: $settings.autoOffEnabled)

                if settings.autoOffEnabled {
                    HStack {
                        Text("Time")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $settings.autoOffHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(String(format: "%02d", h)).tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        Text(":").foregroundColor(.secondary)
                        Picker("", selection: $settings.autoOffMinute) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                Text("Auto Off")
                    .font(.headline)
                if settings.autoOffEnabled {
                    Circle()
                        .fill(.orange)
                        .frame(width: 7, height: 7)
                }
            }
        }
    }
}
