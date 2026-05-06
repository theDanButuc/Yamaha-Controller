import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = YamahaSettings.shared
    @StateObject private var discovery = DiscoveryService()
    @State private var draft: String = ""
    @State private var showManual = false
    @State private var scheduleExpanded = false
    @State private var buttonsExpanded = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // ── Receiver ─────────────────────────────────────────────
                discoverSection

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

    // MARK: - Discovery section

    @ViewBuilder
    private var discoverSection: some View {
        if discovery.isScanning {
            // ── Scanning ─────────────────────────────────────────────────
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Scanning…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Cancel") { discovery.stopScan() }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
        } else if !discovery.discovered.isEmpty {
            // ── Results ──────────────────────────────────────────────────
            deviceList
        } else {
            // ── Idle ─────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showManual = false
                    discovery.startScan()
                } label: {
                    Label("Discover Receiver", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                if let err = discovery.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                // Current IP (read-only summary)
                if !settings.ipAddress.isEmpty && !showManual {
                    HStack {
                        Text("Connected to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(settings.ipAddress)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Change") { showManual = true }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                    }
                }

                // Manual input — shown after error or "Change" tap
                if showManual {
                    HStack(spacing: 6) {
                        TextField("192.168.x.x", text: $draft)
                            .textFieldStyle(.roundedBorder)
                            .onAppear { draft = settings.ipAddress }
                            .onSubmit { commit() }
                            .focused($focused)
                        Button("Save") { commit() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Found \(discovery.discovered.count) receiver\(discovery.discovered.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Scan again") { discovery.startScan() }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            ForEach(discovery.discovered) { device in
                Button {
                    draft = device.host
                    commit()
                    discovery.discovered = []
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(device.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            Text(device.host)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.15).cornerRadius(6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func commit() {
        settings.ipAddress = draft.trimmingCharacters(in: .whitespaces)
        focused = false
        showManual = false
    }
}
