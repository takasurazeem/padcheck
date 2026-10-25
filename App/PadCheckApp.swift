import SwiftUI
import GameController
import IOKit.hid

@main
struct PadCheckApp: App {
    @StateObject private var model = PadModel()

    var body: some Scene {
        WindowGroup("PadCheck") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 780)
        }
        .windowResizability(.contentMinSize)
    }
}

/// Owns the controller monitors. GameController and IOKit objects aren't observable,
/// so the model republishes at 30 Hz while the window is up.
final class PadModel: ObservableObject {
    @Published private(set) var candidates: [Candidate] = []
    @Published var selection = 0
    private(set) var gc: GCMonitor?
    private(set) var hid: HIDMonitor?
    let hidStatus: IOReturn
    private var timers: [Timer] = []

    init() {
        GCController.shouldMonitorBackgroundEvents = true
        hidStatus = startHID()
        rescan()
        for name in [Notification.Name.GCControllerDidConnect, .GCControllerDidDisconnect] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.rescan()
            }
        }
        timers = [
            Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.objectWillChange.send() },
            // Catch plugs and unplugs that GameController doesn't announce (XInput, raw HID).
            Timer(timeInterval: 2, repeats: true) { [weak self] _ in self?.rescan() },
        ]
        timers.forEach { RunLoop.main.add($0, forMode: .common) }
    }

    var candidate: Candidate? {
        candidates.indices.contains(selection) ? candidates[selection] : candidates.first
    }

    /// What the button test reads from: decoded Switch reports when possible, else GameController.
    private(set) var source: PadSource?

    func rescan() {
        candidates = findCandidates()
        var changed = source == nil
        let controller = GCController.controllers().first
        if gc?.controller !== controller {
            gc = controller.map(GCMonitor.init)
            changed = true
        }

        let device = candidate?.hid
        if let h = hid, device.map({ !CFEqual(h.device, $0) }) ?? true {
            h.detach()
            hid = nil
        }
        if hid == nil, let device {
            hid = HIDMonitor(device)
            changed = true
        }
        if changed { source = makePadSource(for: candidate, hid: hid, gc: gc) }
    }

    func reset() {
        source?.reset()
        hid?.resetState()
    }
}
