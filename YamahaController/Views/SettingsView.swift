import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @State private var draft: String = ""
    @State private var scheduleExpanded = false
    @State private var buttonsExpanded = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // ── Receiver IP ──────────────────────────────────────────
                HStack {
                    Text("Receiver IP")
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("192.168.x.x", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .focused($focused)
                        .onAppear { draft = settings.ipAddress }
                        .onSubmit { commit() }
                }

                Button("Save IP") { commit() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .controlSize(.regular)

                Divider()

                // ── Source Buttons ───────────────────────────────────────
                DisclosureGroup(isExpanded: $buttonsExpanded) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(zip(1...4, [
                            $settings.button1Source,
                            $settings.button2Source,
                            $settings.button3Source,
                            $settings.button4Source
                        ])), id: \.0) { index, binding in
                            HStack {
                                Text("Button \(index)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("", selection: binding) {
                                    ForEach(YamahaAPIService.allSources, id: \.value) { s in
                                        Text(s.label).tag(s.value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Source Buttons")
                        .font(.headline)
                }

                Divider()

                // ── Schedule ─────────────────────────────────────────────
                DisclosureGroup(isExpanded: $scheduleExpanded) {
                    VStack(alignment: .leading, spacing: 0) {
                        MorningAlarmView()
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                        Divider()
                        AutoOffView()
                            .padding(.top, 6)
                            .padding(.bottom, 8)
                    }
                } label: {
                    Text("Schedule")
                        .font(.headline)
                }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func commit() {
        settings.ipAddress = draft.trimmingCharacters(in: .whitespaces)
        focused = false
    }
}
