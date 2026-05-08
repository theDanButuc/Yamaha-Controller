import SwiftUI

private struct KeycapButton: View {
    let label: String
    let isActive: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @ObservedObject private var settings = YamahaSettings.shared

    private let w: CGFloat = 58
    private let h: CGFloat = 52

    var body: some View {
        Button(action: { if !isDisabled { onTap() } }) {
            ZStack(alignment: .bottom) {

                // ── Housing / bottom plate (creates depth illusion) ──────
                KeycapShape(cornerRadius: 8, cutSize: 10)
                    .fill(Color(white: 0.05))
                    .frame(width: w, height: h + 5)
                    .offset(y: 2)

                // ── Active background glow ───────────────────────────────
                if isActive {
                    KeycapShape(cornerRadius: 8, cutSize: 10)
                        .fill(settings.schemeMid.opacity(0.18))
                        .blur(radius: 6)
                        .frame(width: w + 6, height: h + 10)
                        .offset(y: 2)
                }

                // ── Key face ─────────────────────────────────────────────
                ZStack {
                    // Base fill
                    KeycapShape(cornerRadius: 7, cutSize: 10)
                        .fill(LinearGradient(
                            colors: isActive
                                ? [settings.schemeDarkTop, settings.schemeDarkBottom]
                                : [Color(white: 0.17), Color(white: 0.11)],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // Bevel border
                    KeycapShape(cornerRadius: 7, cutSize: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color(white: 0.32), Color(white: 0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    // Top shine strip
                    LinearGradient(
                        colors: [Color(white: 1.0, opacity: 0.07), .clear],
                        startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)
                    )
                    .clipShape(KeycapShape(cornerRadius: 7, cutSize: 10))

                    // Active inner stroke
                    if isActive {
                        KeycapShape(cornerRadius: 7, cutSize: 10)
                            .stroke(settings.schemeMid.opacity(0.55), lineWidth: 1)
                    }

                    // Label
                    Text(label)
                        .font(.system(size: label.count > 5 ? 7 : 9,
                                      weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? settings.schemeColor : Color(white: 0.65))
                        .shadow(color: isActive ? settings.schemeMid.opacity(0.8) : .clear, radius: 4)
                        .tracking(0.5)
                        .animation(.easeInOut(duration: 0.15), value: isActive)
                }
                .frame(width: w, height: h)

                // ── LED indicator ────────────────────────────────────────
                ZStack {
                    if isActive {
                        Circle()
                            .fill(settings.schemeMid.opacity(0.5))
                            .blur(radius: 5)
                            .frame(width: 10, height: 10)
                    }
                    Circle()
                        .fill(isActive ? settings.schemeColor : Color(white: 0.10))
                        .frame(width: 4, height: 4)
                        .overlay(Circle().stroke(Color(white: 0.22), lineWidth: 0.5))
                        .shadow(color: isActive ? settings.schemeMid : .clear, radius: 3)
                }
                .offset(y: 10)
                .animation(.easeInOut(duration: 0.15), value: isActive)
            }
            .frame(width: w, height: h + 14)
        }
        .buttonStyle(KeycapPressStyle(isDisabled: isDisabled))
        .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 4)
        .opacity(isDisabled ? 0.4 : 1)
    }
}

struct SceneButtonsView: View {
    @ObservedObject private var api      = YamahaAPIService.shared
    @ObservedObject private var settings = YamahaSettings.shared

    var body: some View {
        let sources = [settings.button1Source, settings.button2Source,
                       settings.button3Source, settings.button4Source]
        HStack(spacing: 6) {
            ForEach(sources, id: \.self) { input in
                KeycapButton(
                    label: YamahaAPIService.buttonLabel(input),
                    isActive: api.currentInput.lowercased() == input.lowercased(),
                    isDisabled: api.powerState != .on,
                    onTap: { api.setInput(input) { _ in } }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
