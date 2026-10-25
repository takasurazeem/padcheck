import SwiftUI
import GameController
import IOKit.hid

// MARK: - Root

struct ContentView: View {
    @EnvironmentObject private var model: PadModel
    @State private var tab = Tab.buttons

    enum Tab: String, CaseIterable { case buttons = "Button Test", raw = "Raw HID" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.hidStatus != kIOReturnSuccess {
                Label("Couldn't open HID devices. Allow PadCheck in System Settings → Privacy & Security → Input Monitoring.",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            if let candidate = model.candidate {
                if model.candidates.count > 1 {
                    Picker("Controller", selection: $model.selection) {
                        ForEach(model.candidates.indices, id: \.self) { i in
                            Text(model.candidates[i].product ?? "Controller \(i + 1)").tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                IdentityCard(candidate: candidate, gameController: model.gc?.controller)
                Picker("View", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
                switch tab {
                case .buttons:
                    if let source = model.source {
                        ButtonTestView(snapshot: source.snapshot())
                    } else {
                        ContentUnavailableView("macOS isn't exposing this controller to games",
                                               systemImage: "gamecontroller",
                                               description: Text("Try the Raw HID view, or switch the controller to Switch or DInput/Android mode."))
                    }
                case .raw:
                    if let hid = model.hid {
                        RawHIDView(monitor: hid)
                    } else {
                        ContentUnavailableView("No HID interface",
                                               systemImage: "cable.connector",
                                               description: Text("In this mode the controller doesn't present a HID interface macOS can read."))
                    }
                }
            } else {
                ContentUnavailableView("No controller connected",
                                       systemImage: "gamecontroller",
                                       description: Text("Plug a controller in over USB or pair it over Bluetooth. Charge-only cables won't work."))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            Button("Reset Checklist", systemImage: "arrow.counterclockwise") { model.reset() }
                .help("Clear which inputs have been verified")
            Button("Rescan", systemImage: "arrow.clockwise") { model.rescan() }
                .help("Look for controllers again")
        }
    }
}

// MARK: - Identity

struct IdentityCard: View {
    let candidate: Candidate
    let gameController: GCController?

    var body: some View {
        let gameSir = gameSirVerdict(candidate, gcVendors: [gameController?.vendorName].compactMap { $0 })
        let mode = modeFor(candidate)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
                    .frame(width: 52, height: 52)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.knownName ?? candidate.product ?? "Unknown controller")
                        .font(.title2.bold())
                    authenticity
                    if let gameSir {
                        Label(gameSir, systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    } else {
                        Label("No GameSir signature found", systemImage: "questionmark.circle").foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(gameSir != nil ? "GameSir mode" : "Mode")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(mode).font(.title3.bold())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading), count: 4), spacing: 10) {
                Detail("USB ID", "\(hex4(candidate.vid)):\(hex4(candidate.pid))  ·  \(candidate.vendorOwner)")
                Detail("Manufacturer", candidate.manufacturer.map { "\"\($0)\"" } ?? "None reported")
                Detail("Product", candidate.product.map { "\"\($0)\"" } ?? "None reported")
                Detail("Connection", candidate.transport)
                Detail("Firmware", candidate.firmware ?? "—")
                Detail("Serial", candidate.serial ?? "—")
                Detail("USB interfaces", candidate.interfaces.isEmpty ? "—" : candidate.interfaces.map(describe).joined(separator: ", "))
                Detail("macOS sees", macOSDescription)
            }

            if candidate.hid == nil {
                Label("macOS has no driver for this mode, so its buttons can't be read. Switch the controller to Switch or DInput/Android mode to test buttons.",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var authenticity: some View {
        switch candidate.authenticity {
        case .genuine(let name)?:
            Label("Looks like a genuine \(name)", systemImage: "checkmark.shield").foregroundStyle(.secondary)
        case .emulating(let name)?:
            Label("Third-party controller emulating a \(name)", systemImage: "theatermasks").foregroundStyle(.orange)
        case .unknown?:
            Label("Can't tell who made it (no manufacturer string)", systemImage: "questionmark.circle").foregroundStyle(.secondary)
        case nil:
            EmptyView()
        }
    }

    private var macOSDescription: String {
        guard let g = gameController else { return "Not visible to games" }
        var s = "\(g.vendorName ?? "Unnamed") (\(g.productCategory))"
        if let b = g.battery, b.batteryState != .unknown { s += String(format: " · %.0f%%", b.batteryLevel * 100) }
        return s
    }
}

struct Detail: View {
    let title: String, value: String
    init(_ title: String, _ value: String) { self.title = title; self.value = value }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled).lineLimit(2)
        }
    }
}

// MARK: - Input state styling

enum InputState {
    case untested, verified, pressed

    init(pressed: Bool, verified: Bool) { self = pressed ? .pressed : verified ? .verified : .untested }

    var fill: Color {
        switch self {
        case .pressed: .accentColor
        case .verified: .green.opacity(0.22)
        case .untested: .primary.opacity(0.07)
        }
    }

    var stroke: Color {
        switch self {
        case .pressed: .accentColor
        case .verified: .green
        case .untested: .primary.opacity(0.25)
        }
    }
}

extension PadButtonState {
    var state: InputState { InputState(pressed: pressed, verified: verified) }
}

extension DirectionState {
    var state: InputState { InputState(pressed: pressed, verified: verified) }
}

// MARK: - Button test

struct ButtonTestView: View {
    let snapshot: PadSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                if snapshot.buttons.contains(where: { $0.role != nil }) {
                    ControllerDiagram(snapshot: snapshot)
                    let others = snapshot.buttons.filter { $0.role == nil }
                    if !others.isEmpty {
                        Text("Other buttons").font(.headline)
                        HStack(spacing: 8) {
                            ForEach(others, id: \.id) { b in
                                Text(b.name)
                                    .font(.callout.weight(.medium))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(b.state.fill, in: Capsule())
                                    .overlay(Capsule().strokeBorder(b.state.stroke, lineWidth: 1.5))
                                    .foregroundStyle(b.pressed ? .white : .primary)
                            }
                        }
                    }
                } else {
                    Text("This controller has no standard gamepad layout; use the checklist.")
                        .foregroundStyle(.secondary)
                }
                Label("Reading inputs from \(snapshot.source)", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            Checklist(snapshot: snapshot)
                .frame(minWidth: 300, maxWidth: 380)
        }
    }
}

struct ControllerDiagram: View {
    let snapshot: PadSnapshot

    var body: some View {
        let s = snapshot
        let upperLeft = CGPoint(x: 130, y: 132), lowerLeft = CGPoint(x: 196, y: 210)

        ZStack {
            ControllerBody()
                .fill(.quinary)
                .overlay(ControllerBody().stroke(.primary.opacity(0.15), lineWidth: 1.5))
                .frame(width: 480, height: 270)
                .position(x: 240, y: 205)

            if let b = s.button(.leftTrigger) { TriggerView(button: b, fallback: "LT").position(x: 120, y: 22) }
            if let b = s.button(.rightTrigger) { TriggerView(button: b, fallback: "RT").position(x: 360, y: 22) }
            if let b = s.button(.leftShoulder) { ShoulderView(button: b, fallback: "LB").position(x: 120, y: 54) }
            if let b = s.button(.rightShoulder) { ShoulderView(button: b, fallback: "RB").position(x: 360, y: 54) }

            if let stick = s.stick(.leftStick) {
                StickView(stick: stick, click: s.button(.leftStickClick))
                    .position(s.playStationLayout ? lowerLeft : upperLeft)
            }
            if let dpad = s.stick(.dpad) {
                DpadView(pad: dpad).position(s.playStationLayout ? upperLeft : lowerLeft)
            }
            if let stick = s.stick(.rightStick) {
                StickView(stick: stick, click: s.button(.rightStickClick)).position(x: 284, y: 210)
            }

            if let b = s.button(.north) { FaceButton(button: b).position(x: 350, y: 96) }
            if let b = s.button(.south) { FaceButton(button: b).position(x: 350, y: 168) }
            if let b = s.button(.west) { FaceButton(button: b).position(x: 314, y: 132) }
            if let b = s.button(.east) { FaceButton(button: b).position(x: 386, y: 132) }

            if let b = s.button(.options) { FaceButton(button: b, size: 26).position(x: 206, y: 110) }
            if let b = s.button(.menu) { FaceButton(button: b, size: 26).position(x: 274, y: 110) }
            if let b = s.button(.share) { FaceButton(button: b, size: 26).position(x: 212, y: 154) }
            if let b = s.button(.home) { FaceButton(button: b, size: 30).position(x: 268, y: 154) }
        }
        .frame(width: 480, height: 345)
    }
}

struct ControllerBody: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let body = CGPath(roundedRect: CGRect(x: w * 0.06, y: 0, width: w * 0.88, height: h * 0.6),
                          cornerWidth: h * 0.28, cornerHeight: h * 0.28, transform: nil)
        let leftGrip = CGPath(ellipseIn: CGRect(x: w * 0.04, y: h * 0.2, width: w * 0.32, height: h * 0.8), transform: nil)
        let rightGrip = CGPath(ellipseIn: CGRect(x: w * 0.64, y: h * 0.2, width: w * 0.32, height: h * 0.8), transform: nil)
        return Path(body.union(leftGrip).union(rightGrip)).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// Diagram label for buttons without a short name, from the button's own name.
private func diagramLabel(_ b: PadButtonState, _ fallback: String) -> String {
    let bare = b.name.replacingOccurrences(of: " Button", with: "")
    return bare.count <= 6 ? bare : fallback
}

struct FaceButton: View {
    let button: PadButtonState
    var size: CGFloat = 38

    var body: some View {
        let state = button.state
        content
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .frame(width: size, height: size)
            .background(Circle().fill(state.fill))
            .overlay(Circle().strokeBorder(state.stroke, lineWidth: 2))
            .foregroundStyle(state == .pressed ? .white : .primary)
            .scaleEffect(state == .pressed ? 0.9 : 1)
            .help(button.name)
    }

    /// Short labels ("A", "+") as text; longer ones ("HOME") as a symbol.
    @ViewBuilder private var content: some View {
        if !button.label.isEmpty {
            Text(button.label)
        } else if let symbol = button.symbol {
            let bare = symbol.replacingOccurrences(of: ".circle", with: "")
            Image(systemName: NSImage(systemSymbolName: bare, accessibilityDescription: nil) != nil ? bare : symbol)
        } else {
            Text(String(button.name.prefix(1)))
        }
    }
}

struct ShoulderView: View {
    let button: PadButtonState
    let fallback: String

    var body: some View {
        let state = button.state
        Text(diagramLabel(button, fallback))
            .font(.callout.weight(.semibold))
            .frame(width: 96, height: 24)
            .background(Capsule().fill(state.fill))
            .overlay(Capsule().strokeBorder(state.stroke, lineWidth: 1.5))
            .foregroundStyle(state == .pressed ? .white : .primary)
    }
}

struct TriggerView: View {
    let button: PadButtonState
    let fallback: String

    var body: some View {
        let state = button.state
        let shape = RoundedRectangle(cornerRadius: 8)
        ZStack(alignment: .leading) {
            shape.fill(InputState.untested.fill)
            GeometryReader { geo in
                shape.fill(button.verified ? Color.green.opacity(0.55) : Color.accentColor.opacity(0.6))
                    .frame(width: geo.size.width * CGFloat(button.value))
            }
            HStack {
                Text(diagramLabel(button, fallback)).font(.callout.weight(.semibold))
                Spacer()
                if button.isAnalog { Text(String(format: "%.2f", button.value)).font(.caption.monospacedDigit()) }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 96, height: 26)
        .overlay(shape.strokeBorder(state.stroke, lineWidth: 1.5))
    }
}

struct StickView: View {
    let stick: PadStickState
    let click: PadButtonState?

    var body: some View {
        let ring = stick.verified ? Color.green : Color.primary.opacity(0.25)
        let clickState = click?.state ?? .untested
        ZStack {
            Circle().fill(.primary.opacity(0.05))
            Circle().strokeBorder(ring, lineWidth: 2)
            ForEach(Array(arrows.enumerated()), id: \.offset) { _, entry in
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(color(entry.0))
                    .offset(y: -31)
                    .rotationEffect(.degrees(entry.1))
            }
            Circle()
                .fill(clickState == .pressed ? Color.accentColor : Color.primary.opacity(0.18))
                .overlay(Circle().strokeBorder(clickState == .verified ? Color.green : .clear, lineWidth: 2))
                .frame(width: 30, height: 30)
                .offset(x: CGFloat(stick.x) * 20, y: CGFloat(-stick.y) * 20)
        }
        .frame(width: 74, height: 74)
        .help("\(stick.name) — click it to test the stick button")
    }

    private var arrows: [(DirectionState, Double)] {
        [(stick.up, 0), (stick.right, 90), (stick.down, 180), (stick.left, 270)]
    }

    private func color(_ d: DirectionState) -> Color {
        d.pressed ? .accentColor : d.verified ? .green : .primary.opacity(0.3)
    }
}

struct DpadView: View {
    let pad: PadStickState

    var body: some View {
        ZStack {
            segment(pad.up, "chevron.up").offset(y: -24)
            segment(pad.down, "chevron.down").offset(y: 24)
            segment(pad.left, "chevron.left").offset(x: -24)
            segment(pad.right, "chevron.right").offset(x: 24)
        }
        .frame(width: 74, height: 74)
    }

    private func segment(_ d: DirectionState, _ symbol: String) -> some View {
        let state = d.state
        return Image(systemName: symbol)
            .font(.system(size: 11, weight: .bold))
            .frame(width: 24, height: 24)
            .background(RoundedRectangle(cornerRadius: 5).fill(state.fill))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(state.stroke, lineWidth: 1.5))
            .foregroundStyle(state == .pressed ? .white : .primary)
    }
}

// MARK: - Checklist

struct Checklist: View {
    let snapshot: PadSnapshot

    var body: some View {
        let totals = snapshot.totals
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Checklist").font(.headline)
                Spacer()
                Text("\(totals.verified) of \(totals.total) verified")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(totals.verified == totals.total ? .green : .secondary)
            }
            ProgressView(value: Double(totals.verified), total: Double(max(totals.total, 1)))
                .tint(totals.verified == totals.total ? .green : .accentColor)
            if totals.verified == totals.total {
                Label("Every input responded", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Text("Press every button, pull each trigger, and push each stick and the d-pad all four ways.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            List {
                Section("Buttons") {
                    ForEach(snapshot.buttons, id: \.id) { b in
                        row(b.name, verified: b.verified, pressed: b.pressed,
                            detail: b.isAnalog ? String(format: "%.2f", b.value) : nil)
                    }
                }
                ForEach(snapshot.sticks, id: \.id) { s in
                    Section(s.name) {
                        ForEach(s.directions, id: \.0) { dir, d in
                            row(dir, verified: d.verified, pressed: d.pressed, detail: nil)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func row(_ name: String, verified: Bool, pressed: Bool, detail: String?) -> some View {
        HStack {
            Image(systemName: verified ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(verified ? .green : .secondary)
            Text(name)
            Spacer()
            if let detail { Text(detail).font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            if pressed {
                Text("ON")
                    .font(.caption.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Raw HID

struct RawHIDView: View {
    let monitor: HIDMonitor

    var body: some View {
        let elements = monitor.sortedElements
        let buttons = elements.filter { $0.page == kHIDPage_Button }
        let axes = elements.filter { $0.page != kHIDPage_Button }

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("\"\(monitor.name)\"").font(.headline)
                    Text("· \(monitor.reportCount) reports received").foregroundStyle(.secondary)
                    if monitor.handshakeSent { Text("· sent Switch USB handshake").foregroundStyle(.secondary) }
                }
                if monitor.reportCount == 0 {
                    Label("No input reports yet. Press a button.", systemImage: "hand.tap").foregroundStyle(.orange)
                }

                if !buttons.isEmpty {
                    Text("Buttons  \(buttons.filter(\.everActive).count)/\(buttons.count) seen").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), alignment: .leading)], spacing: 8) {
                        ForEach(buttons, id: \.usage) { b in
                            let state = InputState(pressed: b.value != 0, verified: b.everActive)
                            Text(HIDMonitor.usageName(b.page, b.usage))
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(state.fill, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(state.stroke, lineWidth: 1.5))
                                .foregroundStyle(state == .pressed ? .white : .primary)
                        }
                    }
                }

                if !axes.isEmpty {
                    Text("Axes").font(.headline)
                    ForEach(axes, id: \.usage) { a in
                        HStack {
                            Image(systemName: a.everActive ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(a.everActive ? .green : .secondary)
                            Text(HIDMonitor.usageName(a.page, a.usage)).frame(width: 100, alignment: .leading)
                            Text("\(a.value)").font(.body.monospacedDigit()).frame(width: 60, alignment: .trailing)
                            Text("range \(a.min)…\(a.max)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(monitor.latest.keys.sorted(), id: \.self) { id in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Report \(id)  ·  \(monitor.latest[id]!.count) bytes").font(.headline)
                        Text("Highlighted bytes differ from the first report right now; orange bytes have changed at some point.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(hexDump(id))
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func hexDump(_ id: UInt32) -> AttributedString {
        let bytes = monitor.latest[id] ?? [], base = monitor.baseline[id] ?? [], ever = monitor.everChanged[id] ?? []
        var out = AttributedString()
        for start in stride(from: 0, to: min(bytes.count, 64), by: 16) {
            var offset = AttributedString(String(format: "%02X   ", start))
            offset.foregroundColor = .secondary
            out += offset
            for i in start..<min(start + 16, bytes.count) {
                var byte = AttributedString(String(format: "%02X", bytes[i]))
                if i < base.count && bytes[i] != base[i] {
                    byte.backgroundColor = .accentColor
                    byte.foregroundColor = .white
                } else if ever.contains(i) {
                    byte.foregroundColor = .orange
                } else {
                    byte.foregroundColor = .secondary
                }
                out += byte + AttributedString(" ")
            }
            out += AttributedString("\n")
        }
        return out
    }
}
