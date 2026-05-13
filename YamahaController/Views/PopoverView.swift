import SwiftUI

private struct CloseButton: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: { NotificationCenter.default.post(name: .init("closePopover"), object: nil) }) {
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
        .help("Close")
    }
}

struct PopoverView: View {
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────
            ZStack {
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

                HStack {
                    CloseButton()
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { AppUIState.shared.toggleSettings() }
                        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .padding(.horizontal)
            .frame(height: 44)

            Divider()

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
        }
        .frame(width: 300)
    }
}
