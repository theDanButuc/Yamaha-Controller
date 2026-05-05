import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @State private var draft: String = ""
    @State private var scheduleExpanded = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func commit() {
        settings.ipAddress = draft.trimmingCharacters(in: .whitespaces)
        focused = false
    }
}
