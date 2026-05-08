import SwiftUI

private struct TransportButton: View {
    let label: String
    let systemImage: String?
    let isDisabled: Bool
    let onTap: () -> Void

    init(label: String, systemImage: String? = nil, isDisabled: Bool, onTap: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.isDisabled = isDisabled
        self.onTap = onTap
    }

    private let w: CGFloat = 54
    private let h: CGFloat = 15

    var body: some View {
        Button(action: { if !isDisabled { onTap() } }) {
            ZStack(alignment: .bottom) {

                // Housing
                KeycapShape(cornerRadius: 3, cutSize: 4)
                    .fill(Color(white: 0.05))
                    .frame(width: w, height: h + 2)
                    .offset(y: 1)

                // Key face
                ZStack {
                    KeycapShape(cornerRadius: 3, cutSize: 4)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.17), Color(white: 0.11)],
                            startPoint: .top, endPoint: .bottom
                        ))

                    KeycapShape(cornerRadius: 3, cutSize: 4)
                        .stroke(
                            LinearGradient(
                                colors: [Color(white: 0.30), Color(white: 0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )

                    LinearGradient(
                        colors: [Color(white: 1.0, opacity: 0.06), .clear],
                        startPoint: .top, endPoint: .init(x: 0.5, y: 0.4)
                    )
                    .clipShape(KeycapShape(cornerRadius: 3, cutSize: 4))

                    if let sysImg = systemImage {
                        Image(systemName: sysImg)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(Color(white: 0.65))
                    } else {
                        Text(label)
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.65))
                            .tracking(0.3)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: w, height: h)
            }
            .frame(width: w, height: h + 4)
        }
        .buttonStyle(KeycapPressStyle(isDisabled: isDisabled))
        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
        .opacity(isDisabled ? 0.35 : 1)
    }
}

struct TransportControlsView: View {
    @ObservedObject private var api = YamahaAPIService.shared

    private var off: Bool { api.powerState != .on }
    private var isTuner: Bool { api.currentInput.lowercased() == "tuner" }
    private var isNetRadio: Bool { api.currentInput.lowercased() == "net_radio" }

    var body: some View {
        VStack(spacing: 4) {

            // Row 1: |<<  ►  >>|
            HStack(spacing: 6) {
                TransportButton(label: "|<<", systemImage: "backward.end.fill", isDisabled: off) {
                    api.setPlayback("previous")
                }
                TransportButton(label: "▶", systemImage: "play.fill", isDisabled: off) {
                    api.setPlayback("play")
                }
                TransportButton(label: ">>|", systemImage: "forward.end.fill", isDisabled: off) {
                    api.setPlayback("next")
                }
            }

            // Row 2: <<  ■  ‖  >>
            // ■ = stop (netusb) or MODE cycle (tuner)
            // ‖ = pause (netusb) or BAND toggle (tuner)
            HStack(spacing: 6) {
                TransportButton(label: "<<", systemImage: "backward.fill", isDisabled: off) {
                    api.tuneStep("down")
                }
                TransportButton(label: "■", systemImage: "stop.fill", isDisabled: off) {
                    if isTuner { api.cycleSoundProgram() }
                    else       { api.setPlayback("stop") }
                }
                TransportButton(label: "‖", systemImage: "pause.fill", isDisabled: off) {
                    if isTuner {
                        let next = api.tunerBand == "fm" ? "am" : "fm"
                        api.setBand(next)
                    } else {
                        api.setPlayback("pause")
                    }
                }
                TransportButton(label: ">>", systemImage: "forward.fill", isDisabled: off) {
                    api.tuneStep("up")
                }
            }

            // Row 3: PRESET <  >
            // Net Radio → cycle netusb presets 1-5
            // Tuner     → switch tuner FM/AM presets
            HStack(spacing: 6) {
                TransportButton(label: "<", isDisabled: off) {
                    if isNetRadio { api.prevNetPreset() }
                    else          { api.switchTunerPreset("previous") }
                }
                TransportButton(label: ">", isDisabled: off) {
                    if isNetRadio { api.nextNetPreset() }
                    else          { api.switchTunerPreset("next") }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
