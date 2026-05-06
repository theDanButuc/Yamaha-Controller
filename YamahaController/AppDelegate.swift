import AppKit
import SwiftUI
import Combine
import UserNotifications
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        requestNotificationPermission()
        setupStatusItem()
        setupPopover()
        observePowerState()
        YamahaAPIService.shared.startPolling()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(for: .unknown)
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }

    private func observePowerState() {
        YamahaAPIService.shared.$powerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.updateIcon(for: state) }
            .store(in: &cancellables)
    }

    private func updateIcon(for state: PowerState) {
        statusItem?.button?.image = menuBarIcon(for: state)
    }

    // MARK: - Menu bar icon

    private func menuBarIcon(for state: PowerState) -> NSImage? {
        let pt = 18.0
        let px = Int(pt * 2)   // @2x for Retina

        guard let logoPath = Bundle.main.path(forResource: "yamaha_white", ofType: "png"),
              let sourceImg = NSImage(contentsOfFile: logoPath) else {
            return sfSymbolFallback(for: state)
        }

        var nsRect = NSRect(origin: .zero, size: sourceImg.size)
        guard let logoCG = sourceImg.cgImage(forProposedRect: &nsRect, context: nil, hints: nil) else {
            return sfSymbolFallback(for: state)
        }

        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: px, height: px,
            bitsPerComponent: 8, bytesPerRow: 0, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return sfSymbolFallback(for: state) }

        // Draw Yamaha logo (flip for CG bottom-left origin)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(px))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(logoCG, in: CGRect(x: 0, y: 0, width: px, height: px))
        ctx.restoreGState()

        // Tint with power state colour
        switch state {
        case .on:
            ctx.setBlendMode(.sourceAtop)
            ctx.setFillColor(NSColor.systemGreen.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: px, height: px))
        case .standby:
            ctx.setBlendMode(.sourceAtop)
            ctx.setFillColor(NSColor.systemRed.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: px, height: px))
        case .unknown:
            // keep white; will be shown as template
            break
        }

        guard let cgResult = ctx.makeImage() else { return sfSymbolFallback(for: state) }

        let result = NSImage(size: NSSize(width: pt, height: pt))
        result.addRepresentation(NSBitmapImageRep(cgImage: cgResult))
        result.isTemplate = (state == .unknown)
        return result
    }

    private func sfSymbolFallback(for state: PowerState) -> NSImage? {
        let name: String
        switch state {
        case .on:      name = "circle.fill"
        case .standby: name = "circle"
        case .unknown: name = "questionmark.circle"
        }
        let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }

    // MARK: - Popover

    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        let hc = NSHostingController(rootView: PopoverView())
        hc.sizingOptions = .intrinsicContentSize
        popover.contentViewController = hc
        self.popover = popover

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            YamahaAPIService.shared.fetchStatus()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
