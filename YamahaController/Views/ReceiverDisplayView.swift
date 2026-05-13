import SwiftUI

private struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let glow: Color

    @State private var xOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(font)
                .foregroundColor(color)
                .shadow(color: glow, radius: 3)
                .fixedSize()
                .offset(x: xOffset)
                .background(
                    GeometryReader { textGeo in
                        Color.clear.onAppear {
                            let textW = textGeo.size.width
                            let containerW = geo.size.width
                            guard textW > containerW else { return }
                            // Start off-screen to the right, scroll left, exit left with gap, repeat
                            xOffset = containerW
                            let gap: CGFloat = 28
                            let totalDist = containerW + textW + gap
                            let dur = Double(totalDist) / 42.0
                            DispatchQueue.main.async {
                                withAnimation(.linear(duration: dur).repeatForever(autoreverses: false)) {
                                    xOffset = -(textW + gap)
                                }
                            }
                        }
                    }
                )
        }
        .clipped()
        .id(text)
    }
}

struct ReceiverDisplayView: View {
    @ObservedObject private var api = YamahaAPIService.shared
    @ObservedObject private var settings = YamahaSettings.shared

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
    private var signalLabel: String {
        guard isOn, !api.audioFormat.isEmpty else { return "" }
        let ch = api.audioChannels.isEmpty ? "" : " \(api.audioChannels)"
        return (api.audioFormat + ch).uppercased()
    }

    private var hasNowPlaying: Bool {
        let input = api.currentInput.lowercased()
        return api.powerState == .on &&
               (input == "net_radio" || input == "spotify") &&
               (!api.nowPlayingTrack.isEmpty || !api.nowPlayingArtist.isEmpty)
    }

    private var hasAlbumArt: Bool { hasNowPlaying && !api.albumArtURLString.isEmpty }

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

                // ── Row 0: Signal format (centered, above INPUT) ─────────
                if !signalLabel.isEmpty {
                    Text(signalLabel)
                        .font(.custom("BitcountPropSingle-ExtraLight", size: 9))
                        .foregroundColor(lcdAmber)
                        .shadow(color: lcdAmberGlow, radius: 2)
                        .tracking(1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                }

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
                        .fill(isOn ? lcdGreen : Color(white: 0.2))
                        .frame(width: 5, height: 5)
                        .shadow(color: isOn ? lcdGreen.opacity(0.9) : .clear, radius: 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // ── Row 2: Input name (big) ──────────────────────────────
                Text(inputLabel)
                    .font(.custom("BitcountPropSingle-ExtraLight", size: 22))
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

                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            if !api.nowPlayingTrack.isEmpty {
                                MarqueeText(
                                    text: api.nowPlayingTrack,
                                    font: .custom("BitcountPropSingle-ExtraLight", size: 14),
                                    color: lcdGreen,
                                    glow: lcdGlow
                                )
                                .frame(height: 18)
                            }
                            if !api.nowPlayingArtist.isEmpty {
                                MarqueeText(
                                    text: api.nowPlayingArtist,
                                    font: .custom("BitcountPropSingle-ExtraLight", size: 14),
                                    color: lcdAmber,
                                    glow: lcdAmberGlow
                                )
                                .frame(height: 18)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if hasAlbumArt, let artURL = URL(string: api.albumArtURLString) {
                            AsyncImage(url: artURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    placeholderArt
                                case .empty:
                                    placeholderArt
                                @unknown default:
                                    placeholderArt
                                }
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4)
                                .stroke(lcdGreen.opacity(0.75), lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 10)
                }

                Divider()
                    .background(Color(white: 0.12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, hasNowPlaying ? 4 : 6)

                // ── Row 4: Volume + [shuffle/repeat] + Mode ─────────────
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VOLUME")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(lcdDim).tracking(1.5)
                        Text(volumeLabel)
                            .font(.custom("BitcountPropSingle-ExtraLight", size: 16))
                            .foregroundColor(isOn
                                ? (api.isMuted ? Color(red: 1.0, green: 0.35, blue: 0.2) : lcdGreen)
                                : lcdDim)
                            .shadow(color: isOn && !api.isMuted ? lcdGlow : .clear, radius: 3)
                            .tracking(1)
                    }

                    Spacer()

                    // Shuffle + Repeat indicators — visible only when active
                    if isOn && (api.shuffleMode != "off" || api.repeatMode != "off") {
                        HStack(spacing: 5) {
                            if api.shuffleMode != "off" {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(lcdGreen)
                                    .shadow(color: lcdGlow, radius: 4)
                            }
                            if api.repeatMode != "off" {
                                Image(systemName: api.repeatMode == "one" ? "repeat.1" : "repeat")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(lcdGreen)
                                    .shadow(color: lcdGlow, radius: 4)
                            }
                        }
                        .padding(.bottom, 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MODE")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(lcdDim).tracking(1.5)
                        Text(soundLabel)
                            .font(.custom("BitcountPropSingle-ExtraLight", size: 11))
                            .foregroundColor(isOn ? lcdAmber : lcdDim)
                            .shadow(color: isOn ? lcdAmberGlow : .clear, radius: 3)
                            .tracking(0.8).lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: api.shuffleMode)
                .animation(.easeInOut(duration: 0.2), value: api.repeatMode)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: (hasAlbumArt ? 150 : (hasNowPlaying ? 130 : 96)) + (signalLabel.isEmpty ? 0 : 18))
        .animation(.easeInOut(duration: 0.3), value: api.powerState)
        .animation(.easeInOut(duration: 0.25), value: hasNowPlaying)
        .animation(.easeInOut(duration: 0.25), value: hasAlbumArt)
        .animation(.easeInOut(duration: 0.25), value: signalLabel)
        .animation(.easeInOut(duration: 0.2), value: api.currentInput)
    }

    private var placeholderArt: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(lcdDim.opacity(0.2))
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(lcdDim)
            )
    }

    private var lcdGreen:     Color { settings.schemeColor }
    private var lcdGlow:      Color { settings.schemeGlow }
    private var lcdAmber:     Color { Color(red: 1.00, green: 0.75, blue: 0.10) }
    private var lcdAmberGlow: Color { Color(red: 1.00, green: 0.65, blue: 0.00).opacity(0.5) }
    private var lcdDim:       Color { settings.schemeLcdDim }
}
