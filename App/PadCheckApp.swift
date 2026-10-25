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
                .frame(minWidth: 640, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}

/// Owns the controller monitors. GameController and IOKit objects aren't observable,
/// so the model republishes at 30 Hz while the window is up.
final class PadModel: ObservableObject {
    @Published private(set) var candidates: [Candidate] = []
    @Published var selectedID: String? {
        didSet { if selectedID != oldValue { rescan() } }
    }
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
        candidates.first { $0.id == selectedID } ?? candidates.first
    }

    /// What the button test reads from: decoded Switch reports when possible, else GameController.
    private(set) var source: PadSource?

    func rescan() {
        candidates = findCandidates()
        // Keep the user's pick while it's still connected; otherwise fall back to the first one.
        if !candidates.contains(where: { $0.id == selectedID }), let first = candidates.first?.id {
            selectedID = first  // didSet re-enters rescan with a valid selection
            return
        }
        var changed = source == nil
        let controller = gameController(for: candidate, among: candidates)
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
