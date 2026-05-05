import SwiftUI

struct ReceiverDisplayView: View {
    @ObservedObject private var api = YamahaAPIService.shared

    private var inputLabel: String {
        api.powerState == .on && !api.currentInput.isEmpty
            ? YamahaAPIService.formatInput(api.currentInput).uppercased()
            : "– – –"
    }

    private var volumeLabel: String {
        guard api.powerState == .on else { return "– – –" }
        if api.isMuted { return "MUTE" }
        if let db = api.actualVolumeDb { return String(format: "%.1f dB", db) }
        return "VOL \(api.volume)"
    }

    private var soundLabel: String {
        guard api.powerState == .on, !api.soundProgram.isEmpty else { return "– – –" }
        return api.soundProgram.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    // Whether current input has now-playing info
    private var hasNowPlaying: Bool {
        let input = api.currentInput.lowercased()
        return api.powerState == .on &&
               (input == "net_radio" || input == "spotify") &&
               (!api.nowPlayingTrack.isEmpty || !api.nowPlayingArtist.isEmpty)
    }

    private var isOn: Bool { api.powerState == .on }

    var body: some View {
        ZStack {
            // Panel background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.04, green: 0.06, blue: 0.05))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.15), lineWidth: 1))

            // Scanlines
            GeometryReader { _ in
                Canvas { context, size in
                    var y: CGFloat = 0
                    while y < size.height {
                        context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                                     with: .color(Color.black.opacity(0.12)))
                        y += 3
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {

                // ── Row 1: INPUT label + status dots ────────────────────
                HStack {
                    Text("INPUT")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(lcdDim).tracking(1.5)
                    Spacer()
                    if isOn && api.isMuted {
                        Text("MUTE")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.2))
                            .tracking(1)
                    }
                    Circle()
                        .fill(isOn ? Color(red: 0.06, green: 0.73, blue: 0.51) : Color(white: 0.2))
                        .frame(width: 5, height: 5)
                        .shadow(color: isOn
                                ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.9) : .clear,
                                radius: 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // ── Row 2: Input name (big) ──────────────────────────────
                Text(inputLabel)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isOn ? lcdGreen : lcdDim)
                    .shadow(color: isOn ? lcdGlow : .clear, radius: 4)
                    .tracking(2).lineLimit(1).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)

                // ── Row 3: Now Playing (Spotify / Radio only) ────────────
                if hasNowPlaying {
                    Divider()
                        .background(Color(white: 0.12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 2) {
                        if !api.nowPlayingTrack.isEmpty {
                            Text(api.nowPlayingTrack)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(lcdGreen)
                                .shadow(color: lcdGlow, radius: 3)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        if !api.nowPlayingArtist.isEmpty {
                            Text(api.nowPlayingArtist)
                                .font(.system(size: 8, weight: .regular, design: .monospaced))
                                .foregroundColor(lcdAmber)
                                .shadow(color: lcdAmberGlow, radius: 2)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                }

                Divider()
                    .background(Color(white: 0.12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, hasNowPlaying ? 4 : 6)

                // ── Row 4: Volume + Mode ─────────────────────────────────
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VOLUME")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(lcdDim).tracking(1.5)
                        Text(volumeLabel)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(isOn
                                ? (api.isMuted ? Color(red: 1.0, green: 0.35, blue: 0.2) : lcdGreen)
                                : lcdDim)
                            .shadow(color: isOn && !api.isMuted ? lcdGlow : .clear, radius: 3)
                            .tracking(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MODE")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(lcdDim).tracking(1.5)
                        Text(soundLabel)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(isOn ? lcdAmber : lcdDim)
                            .shadow(color: isOn ? lcdAmberGlow : .clear, radius: 3)
                            .tracking(0.8).lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hasNowPlaying ? 130 : 96)
        .animation(.easeInOut(duration: 0.3), value: api.powerState)
        .animation(.easeInOut(duration: 0.25), value: hasNowPlaying)
        .animation(.easeInOut(duration: 0.2), value: api.currentInput)
    }

    private var lcdGreen:     Color { Color(red: 0.18, green: 0.95, blue: 0.55) }
    private var lcdGlow:      Color { Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.6) }
    private var lcdAmber:     Color { Color(red: 1.00, green: 0.75, blue: 0.10) }
    private var lcdAmberGlow: Color { Color(red: 1.00, green: 0.65, blue: 0.00).opacity(0.5) }
    private var lcdDim:       Color { Color(red: 0.15, green: 0.35, blue: 0.22) }
}
