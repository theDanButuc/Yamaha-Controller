import SwiftUI

// Custom shape: rounded rect with diagonal cut at top-left corner (like the .corner CSS element)
private struct KeycapShape: Shape {
    var cornerRadius: CGFloat = 7
    var cutSize: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = cornerRadius
        let c = cutSize
        p.move(to: CGPoint(x: rect.minX + c, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + c))
        p.closeSubpath()
        return p
    }
}

private struct KeycapPressStyle: ButtonStyle {
    let isDisabled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed && !isDisabled ? 3 : 0)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}

private struct KeycapButton: View {
    let label: String
    let isActive: Bool
    let isDisabled: Bool
    let onTap: () -> Void

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
                        .fill(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.18))
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
                                ? [Color(red: 0.07, green: 0.16, blue: 0.12),
                                   Color(red: 0.03, green: 0.09, blue: 0.07)]
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
                            .stroke(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.55),
                                    lineWidth: 1)
                    }

                    // Label
                    Text(label)
                        .font(.system(size: label.count > 5 ? 7 : 9,
                                      weight: .bold, design: .monospaced))
                        .foregroundColor(isActive
                            ? Color(red: 0.25, green: 0.9, blue: 0.6)
                            : Color(white: 0.65))
                        .shadow(color: isActive
                            ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.8)
                            : .clear, radius: 4)
                        .tracking(0.5)
                        .animation(.easeInOut(duration: 0.15), value: isActive)
                }
                .frame(width: w, height: h)

                // ── LED indicator ────────────────────────────────────────
                ZStack {
                    if isActive {
                        Circle()
                            .fill(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.5))
                            .blur(radius: 5)
                            .frame(width: 10, height: 10)
                    }
                    Circle()
                        .fill(isActive
                              ? Color(red: 0.18, green: 0.95, blue: 0.55)
                              : Color(white: 0.10))
                        .frame(width: 4, height: 4)
                        .overlay(Circle().stroke(Color(white: 0.22), lineWidth: 0.5))
                        .shadow(color: isActive
                            ? Color(red: 0.06, green: 0.73, blue: 0.51)
                            : .clear, radius: 3)
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

private struct InputSource {
    let label: String
    let input: String
}

private let sources: [InputSource] = [
    InputSource(label: "TV",      input: "tv"),
    InputSource(label: "XBOX",    input: "hdmi2"),
    InputSource(label: "SPOTIFY", input: "spotify"),
    InputSource(label: "RADIO",   input: "net_radio"),
]

struct SceneButtonsView: View {
    @ObservedObject private var api = YamahaAPIService.shared

    var body: some View {
        HStack(spacing: 6) {
                ForEach(sources, id: \.input) { source in
                    KeycapButton(
                        label: source.label,
                        isActive: api.currentInput.lowercased() == source.input,
                        isDisabled: api.powerState != .on,
                        onTap: { api.setInput(source.input) { _ in } }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
