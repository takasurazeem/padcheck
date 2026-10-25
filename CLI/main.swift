// padcheck — identify any connected game controller, detect which mode a GameSir
// controller is in, and interactively verify that every input works.
//
// Build:  ./build.sh
// Usage:  ./padcheck            identify, then open the live input tester
//         ./padcheck --info     identify only
//         ./padcheck --raw      skip the GameController view, test via raw HID reports
//         ./padcheck --log      print one line per input event instead of the live view

import Foundation
import IOKit
import IOKit.hid
import GameController

// MARK: - Terminal styling

let esc = "\u{1B}["
let bold = esc + "1m", dim = esc + "2m", rev = esc + "7m", reset = esc + "0m"
let green = esc + "32m", yellow = esc + "33m", red = esc + "31m", cyan = esc + "36m"

func pad(_ s: String, _ width: Int) -> String {
    s.count >= width ? String(s.prefix(width)) : s + String(repeating: " ", count: width - s.count)
}

func terminalWidth() -> Int {
    var ws = winsize()
    return ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 ? Int(ws.ws_col) : 100
}

// MARK: - Identification report

func report(_ candidates: [Candidate]) {
    let gc = GCController.controllers()
    if candidates.isEmpty && gc.isEmpty {
        print("\(red)No game controller found.\(reset) Check the cable is a data cable (not charge-only) and the controller is on.")
        return
    }
    for (n, c) in candidates.enumerated() {
        print("\(bold)━━ Controller \(n + 1) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(reset)")
        func row(_ k: String, _ v: String) { print("  \(dim)\(pad(k, 16))\(reset)\(v)") }
        row("Identifies as", "\(bold)\(c.knownName ?? c.product ?? "Unknown controller")\(reset)")
        row("USB ID", "\(hex4(c.vid)):\(hex4(c.pid))  (vendor ID belongs to \(c.vendorOwner))")
        row("Manufacturer", c.manufacturer.map { "\"\($0)\"" } ?? "(none reported)")
        row("Product", c.product.map { "\"\($0)\"" } ?? "(none reported)")
        if let s = c.serial { row("Serial", s) }
        if let f = c.firmware { row("Firmware rev", f) }
        row("Connection", c.transport)
        if !c.interfaces.isEmpty { row("USB interfaces", c.interfaces.map(describe).joined(separator: ", ")) }

        switch c.authenticity {
        case .genuine(let name)?: row("Authenticity", "\(green)Looks like a genuine \(name)\(reset)")
        case .emulating(let name)?: row("Authenticity", "\(yellow)Third-party controller emulating a \(name)\(reset)")
        case .unknown?: row("Authenticity", "Can't tell (no manufacturer string)")
        case nil: break
        }

        row("Protocol / mode", modeFor(c))
        if let verdict = gameSirVerdict(c, gcVendors: gc.compactMap(\.vendorName)) {
            row("GameSir?", "\(green)\(verdict)\(reset)")
            row("GameSir mode", "\(bold)\(cyan)\(modeFor(c))\(reset)")
        } else {
            row("GameSir?", "No GameSir signature found")
        }
        if c.hid == nil {
            print("  \(yellow)macOS has no driver for this mode, so its buttons can't be read here.")
            print("  Switch the controller to Switch or DInput/Android mode to test buttons.\(reset)")
        }
    }
    if !gc.isEmpty {
        print("\(bold)━━ macOS GameController framework ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(reset)")
        for g in gc {
            var line = "  \(g.vendorName ?? "Unnamed")  —  category \"\(g.productCategory)\""
            if let b = g.battery, b.batteryState != .unknown { line += String(format: ", battery %.0f%%", b.batteryLevel * 100) }
            print(line)
        }
    }
}

// MARK: - Live tester infrastructure

var originalTermios = termios()
var tuiActive = false
var logMode = false
var renderer: (() -> [String])?
var keyHandler: ((Character) -> Void)?
var summary: (() -> [String])?

func enterTUI() {
    tcgetattr(STDIN_FILENO, &originalTermios)
    var raw = originalTermios
    raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSANOW, &raw)
    if !logMode { print("\u{1B}[?1049h\u{1B}[?25l", terminator: "") }
    tuiActive = true
}

func quit() -> Never {
    if tuiActive {
        if !logMode { print("\u{1B}[?25h\u{1B}[?1049l", terminator: "") }
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios)
    }
    summary?().forEach { print($0) }
    exit(0)
}

func draw() {
    guard !logMode, let lines = renderer?() else { return }
    var out = "\u{1B}[H"
    for l in lines { out += l + "\u{1B}[K\n" }
    out += "\u{1B}[J"
    FileHandle.standardOutput.write(out.data(using: .utf8)!)
}

func logEvent(_ s: String) {
    guard logMode else { return }
    let t = String(format: "%.3f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
    print("[\(t)] \(s)")
    fflush(stdout)
}

// MARK: - Button test view

extension PadSnapshot {
    func render() -> [String] {
        var lines: [String] = []
        let t = totals
        let color = t.verified == t.total ? green : yellow
        lines.append("\(bold)Testing \"\(title)\"\(reset) via \(source)   \(dim)[r] reset  [h] raw HID view  [q] quit\(reset)")
        lines.append("Press every button, pull every trigger, and push each stick and the d-pad in all four directions.")
        lines.append("\(color)\(bold)Verified \(t.verified)/\(t.total)\(reset)")
        lines.append("")
        lines.append("\(bold)Buttons\(reset)")
        let cellWidth = 34
        let cols = max(1, terminalWidth() / cellWidth)
        var row = ""
        for (i, b) in buttons.enumerated() {
            let mark = b.verified ? "\(green)✓\(reset)" : "\(dim)·\(reset)"
            let state = b.pressed ? "\(rev)\(bold) ON \(reset)" : "\(dim) -- \(reset)"
            let label = b.isAnalog ? String(format: "%@ %.2f", b.name, b.value) : b.name
            row += "\(mark) \(state) \(pad(label, cellWidth - 8))"
            if (i + 1) % cols == 0 { lines.append(row); row = "" }
        }
        if !row.isEmpty { lines.append(row) }
        lines.append("")
        lines.append("\(bold)Sticks & D-pad\(reset)   \(dim)(arrow lights green once that direction has been reached)\(reset)")
        for s in sticks {
            let dirs = [("↑", s.up), ("↓", s.down), ("←", s.left), ("→", s.right)].map { sym, d -> String in
                if d.pressed { return "\(rev)\(sym)\(reset)" }
                return d.verified ? "\(green)\(sym)\(reset)" : "\(dim)\(sym)\(reset)"
            }.joined(separator: " ")
            lines.append("  \(pad(s.name, 22)) " + String(format: "x %+.2f  y %+.2f   ", s.x, s.y) + dirs)
        }
        if let battery {
            lines.append("")
            lines.append(String(format: "Battery %.0f%%", battery * 100))
        }
        return lines
    }

    func summaryLines() -> [String] {
        let t = totals
        var out = ["\(bold)Result:\(reset) \(t.verified)/\(t.total) inputs verified on \"\(title)\"."]
        if t.missing.isEmpty { out.append("\(green)Every input responded.\(reset)") }
        else { out.append("\(yellow)Never registered:\(reset) " + t.missing.joined(separator: ", ")) }
        return out
    }
}

// MARK: - Raw HID view

extension HIDMonitor {
    func render() -> [String] {
        var lines: [String] = []
        lines.append("\(bold)Raw HID view: \"\(name)\"\(reset)   \(dim)[r] reset  [h] GameController view  [q] quit\(reset)")
        lines.append("Reports received: \(reportCount)" + (handshakeSent ? "   \(dim)(sent Switch USB handshake)\(reset)" : ""))
        if reportCount == 0 { lines.append("\(yellow)No input reports yet — press a button.\(reset)") }

        let named = sortedElements
        if !named.isEmpty {
            let btns = named.filter { $0.page == kHIDPage_Button }
            let axes = named.filter { $0.page != kHIDPage_Button }
            lines.append("")
            lines.append("\(bold)Buttons\(reset)  \(green)\(btns.filter(\.everActive).count)/\(btns.count) seen\(reset)")
            var row = ""
            for (i, b) in btns.enumerated() {
                let mark = b.everActive ? "\(green)✓\(reset)" : "\(dim)·\(reset)"
                let state = b.value != 0 ? "\(rev)\(bold) ON \(reset)" : "\(dim) -- \(reset)"
                row += "\(mark) \(state) \(pad(Self.usageName(b.page, b.usage), 12))"
                if (i + 1) % 4 == 0 { lines.append(row); row = "" }
            }
            if !row.isEmpty { lines.append(row) }
            if !axes.isEmpty {
                lines.append("")
                lines.append("\(bold)Axes\(reset)  \(dim)(value, and range seen so far)\(reset)")
                for a in axes {
                    let mark = a.everActive ? "\(green)✓\(reset)" : "\(dim)·\(reset)"
                    lines.append("  \(mark) \(pad(Self.usageName(a.page, a.usage), 12)) \(pad(String(a.value), 7)) range \(a.min)…\(a.max)")
                }
            }
        }

        for id in latest.keys.sorted() {
            let bytes = latest[id]!, base = baseline[id] ?? [], ever = everChanged[id] ?? []
            lines.append("")
            lines.append("\(bold)Report \(id)\(reset) (\(bytes.count) bytes)  \(dim)highlighted = differs from first report now, yellow = has changed at some point\(reset)")
            for start in stride(from: 0, to: min(bytes.count, 64), by: 16) {
                var row = String(format: "  %02X  ", start)
                for i in start..<min(start + 16, bytes.count) {
                    let h = String(format: "%02X", bytes[i])
                    if i < base.count && bytes[i] != base[i] { row += "\(rev)\(h)\(reset) " }
                    else if ever.contains(i) { row += "\(yellow)\(h)\(reset) " }
                    else { row += "\(dim)\(h)\(reset) " }
                }
                lines.append(row)
            }
        }
        return lines
    }

    func summaryLines() -> [String] {
        let btns = elements.values.filter { $0.page == kHIDPage_Button }
        guard !btns.isEmpty else { return ["\(bold)Result:\(reset) \(reportCount) reports received from \"\(name)\"."] }
        let missing = btns.filter { !$0.everActive }.sorted { $0.usage < $1.usage }.map { Self.usageName($0.page, $0.usage) }
        var out = ["\(bold)Result:\(reset) \(btns.count - missing.count)/\(btns.count) HID buttons verified on \"\(name)\"."]
        if !missing.isEmpty { out.append("\(yellow)Never registered:\(reset) " + missing.joined(separator: ", ")) }
        return out
    }
}

// MARK: - Main

let args = Set(CommandLine.arguments.dropFirst())
if args.contains("-h") || args.contains("--help") {
    print("usage: padcheck [--info] [--raw] [--log]")
    exit(0)
}
logMode = args.contains("--log")

GCController.shouldMonitorBackgroundEvents = true
let hidStatus = startHID()
// Give GameController and IOKit a moment to publish devices that were already plugged in.
RunLoop.main.run(until: Date().addingTimeInterval(1.5))

if hidStatus != kIOReturnSuccess {
    print("\(yellow)Couldn't open HID devices (IOReturn 0x\(String(UInt32(bitPattern: hidStatus), radix: 16))). If this persists, allow your terminal in System Settings → Privacy & Security → Input Monitoring.\(reset)")
}

let candidates = findCandidates()
report(candidates)

if args.contains("--info") { exit(0) }
if isatty(STDIN_FILENO) == 0 && !logMode {
    print("\n(Not a terminal; run in a terminal for the live tester, or pass --log.)")
    exit(0)
}

var gcMonitor: GCMonitor?
var hidMonitor: HIDMonitor?
var padSource: PadSource?
var showingRaw = args.contains("--raw")

if let d = candidates.compactMap(\.hid).first ?? hidGameDevices().first {
    hidMonitor = HIDMonitor(d)
    hidMonitor!.onEvent = logEvent
}

func activate() {
    if let c = GCController.controllers().first, gcMonitor?.controller !== c {
        gcMonitor = GCMonitor(c)
        gcMonitor!.onEvent = logEvent
    }
    if padSource == nil || (padSource is GCMonitor && padSource !== gcMonitor) {
        padSource = makePadSource(for: candidates.first, hid: hidMonitor, gc: gcMonitor)
    }
    if !showingRaw, let source = padSource {
        renderer = { source.snapshot().render() }
        keyHandler = { k in if k == "r" { source.reset() } }
        summary = { source.snapshot().summaryLines() }
    } else if let hidMonitor {
        showingRaw = true
        renderer = { hidMonitor.render() }
        keyHandler = { k in if k == "r" { hidMonitor.resetState() } }
        summary = { hidMonitor.summaryLines() }
    } else {
        renderer = nil
    }
}

activate()
guard renderer != nil else {
    print("\nNothing to test: no controller is exposing inputs to macOS.")
    exit(1)
}

print(logMode ? "\nLogging input events — Ctrl-C to stop.\n" : "")
enterTUI()

signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler { quit() }
sigint.resume()

let stdinSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
stdinSource.setEventHandler {
    var byte: UInt8 = 0
    guard read(STDIN_FILENO, &byte, 1) == 1 else { return }
    let key = Character(UnicodeScalar(byte))
    switch key {
    case "q", "Q": quit()
    case "h", "H":
        showingRaw.toggle()
        activate()
    default: keyHandler?(key)
    }
}
stdinSource.resume()

NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in activate() }
NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { _ in
    if padSource === gcMonitor { padSource = nil }
    gcMonitor = nil
    activate()
}

let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { _ in draw() }
RunLoop.main.add(timer, forMode: .common)
RunLoop.main.run()
