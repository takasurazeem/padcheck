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
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil,
                                               queue: .main) { [weak self] _ in self?.source?.close() }
    }

    var candidate: Candidate? {
        candidates.first { $0.id == selectedID } ?? candidates.first
    }

    /// What the button test reads from: decoded Switch reports or the Nova 2 Lite's
    /// configuration interface when possible, else GameController.
    private(set) var source: PadSource? {
        willSet { if newValue !== source { source?.close() } }
    }
    private var sourceCandidateID: String?

    /// The Nova 2 Lite reader when that's the selected controller (firmware, vibration).
    var nova: Nova2LiteMonitor? { source as? Nova2LiteMonitor }

    func rescan() {
        candidates = findCandidates()
        // Keep the user's pick while it's still connected; otherwise fall back to the first one.
        if !candidates.contains(where: { $0.id == selectedID }), let first = candidates.first?.id {
            selectedID = first  // didSet re-enters rescan with a valid selection
            return
        }
        var changed = source == nil || candidate?.id != sourceCandidateID
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
        if changed {
            source = nil  // let the old source turn off anything it enabled before a new one opens
            source = makePadSource(for: candidate, hid: hid, gc: gc)
            sourceCandidateID = candidate?.id
        }
    }

    func reset() {
        source?.reset()
        hid?.resetState()
    }

    // MARK: Inputs a controller doesn't have

    private static let skippedKey = "skippedInputs"

    /// Per controller ID, remembered across launches.
    @Published private var skipped: [String: Set<String>] =
        (UserDefaults.standard.dictionary(forKey: skippedKey) as? [String: [String]] ?? [:]).mapValues(Set.init)

    var snapshot: PadSnapshot? {
        guard var s = source?.snapshot() else { return nil }
        s.skipped = candidate.flatMap { skipped[$0.id] } ?? []
        return s
    }

    /// Skips the given inputs, or counts them again if they're all skipped already.
    func toggleSkip(_ names: [String]) {
        guard let id = candidate?.id else { return }
        var set = skipped[id] ?? []
        if names.allSatisfy(set.contains) { set.subtract(names) } else { set.formUnion(names) }
        skipped[id] = set.isEmpty ? nil : set
        UserDefaults.standard.set(skipped.mapValues { Array($0) }, forKey: Self.skippedKey)
    }
}
