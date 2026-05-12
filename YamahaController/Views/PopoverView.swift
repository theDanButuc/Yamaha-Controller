import SwiftUI

private struct CloseButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.27, blue: 0.27))
                if isHovered {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.05, blue: 0.05))
                }
            }
            .frame(width: 13, height: 13)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Quit Yamaha Controller")
    }
}

struct PopoverView: View {
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────
            ZStack {
                // Centered logo + title
                HStack(spacing: 6) {
                    Image(nsImage: {
                        if let url = Bundle.main.url(forResource: "yamaha_white", withExtension: "png"),
                           let img = NSImage(contentsOf: url) { return img }
                        return NSImage()
                    }())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 18, height: 18)

                    Text("Yamaha Controller")
                        .font(.headline)
                }

                // Left: close, Right: gear
                HStack {
                    CloseButton { NSApplication.shared.terminate(nil) }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showingSettings.toggle()
                        }
                    } label: {
                        Image(systemName: showingSettings ? "xmark.circle.fill" : "gear")
                            .font(.system(size: 16))
                            .foregroundColor(showingSettings ? .secondary : .primary)
                    }
                    .buttonStyle(.plain)
                    .help(showingSettings ? "Close Settings" : "Settings")
                }
            }
            .padding(.horizontal)
            .frame(height: 44)

            Divider()

            if showingSettings {
                SettingsView()
                    .frame(width: 300)
                    .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ReceiverDisplayView()
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    Divider()

                    ManualControlsView()
                        .padding()

                    Divider()

                    SceneButtonsView()
                        .padding()

                    Divider()

                    TransportControlsView()
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                }
                .frame(width: 300)
                .transition(.opacity)

            }
        }
        .frame(width: 300)
    }
}
