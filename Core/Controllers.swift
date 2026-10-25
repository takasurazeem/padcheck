// Shared by the padcheck CLI and the PadCheck app: identifies connected game controllers,
// detects which mode a GameSir controller is in, and tracks which inputs have responded.

import Foundation
import IOKit
import IOKit.hid
import GameController

func hex4(_ v: Int) -> String { String(format: "%04X", v) }

// MARK: - Known identities

struct KnownPad { let name: String; let mode: String }

let knownPads: [Int: [Int: KnownPad]] = [
    0x057E: [
        0x2009: KnownPad(name: "Nintendo Switch Pro Controller", mode: "Switch mode"),
        0x2006: KnownPad(name: "Nintendo Joy-Con (L)", mode: "Switch mode"),
        0x2007: KnownPad(name: "Nintendo Joy-Con (R)", mode: "Switch mode"),
    ],
    0x045E: [
        0x028E: KnownPad(name: "Xbox 360 Controller", mode: "XInput (PC) mode"),
        0x02D1: KnownPad(name: "Xbox One Controller", mode: "Xbox mode"),
        0x02DD: KnownPad(name: "Xbox One Controller", mode: "Xbox mode"),
        0x02EA: KnownPad(name: "Xbox One S Controller", mode: "Xbox mode"),
        0x0B12: KnownPad(name: "Xbox Series X|S Controller", mode: "Xbox mode"),
    ],
    0x054C: [
        0x0268: KnownPad(name: "Sony DualShock 3", mode: "PS3 mode"),
        0x05C4: KnownPad(name: "Sony DualShock 4", mode: "PS4 mode"),
        0x09CC: KnownPad(name: "Sony DualShock 4 (v2)", mode: "PS4 mode"),
        0x0CE6: KnownPad(name: "Sony DualSense", mode: "PS5 mode"),
        0x0DF2: KnownPad(name: "Sony DualSense Edge", mode: "PS5 mode"),
    ],
    // GameSir's own IDs; the Nova 2 Lite's PC-mode IDs come from GameSir Connect's model table.
    0x3537: [
        0x100F: KnownPad(name: "GameSir Nova 2 Lite", mode: "XInput (PC) mode"),
        0x1098: KnownPad(name: "GameSir Nova 2 Lite (wireless)", mode: "XInput (PC) mode"),
    ],
]

let vendorNames: [Int: String] = [
    0x057E: "Nintendo", 0x045E: "Microsoft", 0x054C: "Sony", 0x3537: "GameSir",
    0x2DC8: "8BitDo", 0x0F0D: "Hori", 0x0E6F: "PDP", 0x24C6: "PowerA", 0x20D6: "PowerA",
    0x1532: "Razer", 0x046D: "Logitech", 0x28DE: "Valve", 0x2563: "ShanWan",
    0x0079: "DragonRise", 0x05AC: "Apple", 0x1949: "Amazon", 0x18D1: "Google",
    0x0738: "Mad Catz", 0x0583: "Padix", 0x11C0: "Betop", 0x1A86: "QinHeng",
]

// Manufacturer strings real first-party controllers report; anything else is an emulation.
let genuineManufacturers: [Int: [String]] = [
    0x057E: ["nintendo"], 0x045E: ["microsoft"], 0x054C: ["sony"],
]

// MARK: - USB enumeration (sees XInput devices that have no HID interface)

struct USBInterface { let cls: Int, sub: Int, proto: Int }

struct USBDevice {
    let vid: Int, pid: Int, bcd: Int, locationID: Int
    let manufacturer: String?, product: String?, serial: String?
    let interfaces: [USBInterface]
}

func regProp(_ e: io_registry_entry_t, _ key: String) -> Any? {
    IORegistryEntryCreateCFProperty(e, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
}

func enumerateUSB() -> [USBDevice] {
    var iter: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"), &iter) == KERN_SUCCESS
    else { return [] }
    defer { IOObjectRelease(iter) }

    var devices: [USBDevice] = []
    while case let dev = IOIteratorNext(iter), dev != 0 {
        defer { IOObjectRelease(dev) }
        var interfaces: [USBInterface] = []
        var childIter: io_iterator_t = 0
        if IORegistryEntryGetChildIterator(dev, kIOServicePlane, &childIter) == KERN_SUCCESS {
            while case let child = IOIteratorNext(childIter), child != 0 {
                if IOObjectConformsTo(child, "IOUSBHostInterface") != 0 {
                    interfaces.append(USBInterface(
                        cls: regProp(child, "bInterfaceClass") as? Int ?? -1,
                        sub: regProp(child, "bInterfaceSubClass") as? Int ?? -1,
                        proto: regProp(child, "bInterfaceProtocol") as? Int ?? -1))
                }
                IOObjectRelease(child)
            }
            IOObjectRelease(childIter)
        }
        devices.append(USBDevice(
            vid: regProp(dev, "idVendor") as? Int ?? 0,
            pid: regProp(dev, "idProduct") as? Int ?? 0,
            bcd: regProp(dev, "bcdDevice") as? Int ?? 0,
            locationID: regProp(dev, "locationID") as? Int ?? 0,
            manufacturer: (regProp(dev, "USB Vendor Name") ?? regProp(dev, "kUSBVendorString")) as? String,
            product: (regProp(dev, "USB Product Name") ?? regProp(dev, "kUSBProductString")) as? String,
            serial: regProp(dev, "kUSBSerialNumberString") as? String,
            interfaces: interfaces))
    }
    return devices
}

func describe(_ i: USBInterface) -> String {
    switch (i.cls, i.sub, i.proto) {
    case (3, _, _): return "HID"
    case (0xFF, 0x5D, 0x01): return "XInput (Xbox 360 protocol)"
    case (0xFF, 0x5D, _): return "XInput auxiliary"
    case (0xFF, 0x47, 0xD0): return "Xbox One GIP"
    case (0xFF, _, _): return String(format: "Vendor-specific (FF/%02X/%02X)", i.sub, i.proto)
    case (1, _, _): return "Audio"
    default: return String(format: "Class %02X/%02X/%02X", i.cls, i.sub, i.proto)
    }
}

// MARK: - HID enumeration

let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

func hidProp(_ d: IOHIDDevice, _ key: String) -> Any? { IOHIDDeviceGetProperty(d, key as CFString) }

func startHID() -> IOReturn {
    let usages = [kHIDUsage_GD_Joystick, kHIDUsage_GD_GamePad, kHIDUsage_GD_MultiAxisController]
    let matching = usages.map { [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: $0] }
    IOHIDManagerSetDeviceMatchingMultiple(hidManager, matching as CFArray)
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    return IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
}

func hidGameDevices() -> [IOHIDDevice] {
    guard let set = IOHIDManagerCopyDevices(hidManager) as? Set<IOHIDDevice> else { return [] }
    return set.sorted { (hidProp($0, kIOHIDLocationIDKey) as? Int ?? 0) < (hidProp($1, kIOHIDLocationIDKey) as? Int ?? 0) }
}

// MARK: - Controller candidates

struct Candidate {
    var vid: Int, pid: Int
    var manufacturer: String?, product: String?, serial: String?
    var bcd: Int?
    var transport: String
    var interfaces: [USBInterface]
    var hid: IOHIDDevice?
    var locationID: Int

    /// Stays the same across rescans so a selection survives devices coming and going.
    var id: String { "\(hex4(vid)):\(hex4(pid))#\(serial ?? String(locationID))" }
    var displayName: String { knownName ?? product ?? "Unknown controller" }
    var knownName: String? { knownPads[vid]?[pid]?.name }
    var vendorOwner: String { vendorNames[vid] ?? "unknown vendor" }
    var firmware: String? { bcd.map { String(format: "%X.%02X", $0 >> 8, $0 & 0xFF) } }

    enum Authenticity { case genuine(String), emulating(String), unknown }

    /// Only meaningful for vendor IDs whose real manufacturer string we know.
    var authenticity: Authenticity? {
        guard let genuine = genuineManufacturers[vid], let name = knownName ?? vendorNames[vid] else { return nil }
        guard let m = manufacturer?.lowercased() else { return .unknown }
        return genuine.contains(where: { m.contains($0) }) ? .genuine(name) : .emulating(name)
    }

    var isEmulating: Bool {
        if case .emulating? = authenticity { return true }
        return false
    }
}

func findCandidates() -> [Candidate] {
    let usb = enumerateUSB()
    var usedUSB = Set<Int>()
    var candidates: [Candidate] = []

    for d in hidGameDevices() {
        let vid = hidProp(d, kIOHIDVendorIDKey) as? Int ?? 0
        let pid = hidProp(d, kIOHIDProductIDKey) as? Int ?? 0
        let loc = hidProp(d, kIOHIDLocationIDKey) as? Int ?? -1
        let match = usb.firstIndex { $0.locationID == loc } ?? usb.firstIndex { $0.vid == vid && $0.pid == pid }
        if let m = match { usedUSB.insert(m) }
        let u = match.map { usb[$0] }
        candidates.append(Candidate(
            vid: vid, pid: pid,
            manufacturer: u?.manufacturer ?? hidProp(d, kIOHIDManufacturerKey) as? String,
            product: u?.product ?? hidProp(d, kIOHIDProductKey) as? String,
            serial: u?.serial ?? hidProp(d, kIOHIDSerialNumberKey) as? String,
            bcd: u?.bcd ?? hidProp(d, kIOHIDVersionNumberKey) as? Int,
            transport: hidProp(d, kIOHIDTransportKey) as? String ?? "?",
            interfaces: u?.interfaces ?? [],
            hid: d,
            locationID: loc))
    }

    // Controllers macOS has no HID driver for (XInput / GIP) only show up at the USB level.
    for (i, u) in usb.enumerated() where !usedUSB.contains(i) {
        let isXbox = u.interfaces.contains { $0.cls == 0xFF && ($0.sub == 0x5D || $0.sub == 0x47) }
        guard isXbox || knownPads[u.vid]?[u.pid] != nil else { continue }
        candidates.append(Candidate(
            vid: u.vid, pid: u.pid, manufacturer: u.manufacturer, product: u.product, serial: u.serial,
            bcd: u.bcd, transport: "USB", interfaces: u.interfaces, hid: nil, locationID: u.locationID))
    }
    return candidates
}

func modeFor(_ c: Candidate) -> String {
    if let k = knownPads[c.vid]?[c.pid] { return k.mode }
    switch c.vid {
    case 0x057E: return "Switch mode"
    case 0x045E: return "XInput / Xbox mode"
    case 0x054C: return "PlayStation mode"
    default: break
    }
    if c.interfaces.contains(where: { $0.cls == 0xFF && $0.sub == 0x5D }) { return "XInput (PC) mode" }
    if c.interfaces.contains(where: { $0.cls == 0xFF && $0.sub == 0x47 }) { return "Xbox mode (GIP)" }
    if c.hid != nil || c.interfaces.contains(where: { $0.cls == 3 }) { return "DInput / Android / generic HID mode" }
    return "Unknown"
}

/// Why this looks like a GameSir controller, or nil when there is no GameSir signature.
func gameSirVerdict(_ c: Candidate, gcVendors: [String]) -> String? {
    let strings = [c.manufacturer, c.product].compactMap { $0?.lowercased() } + gcVendors.map { $0.lowercased() }
    if c.vid == 0x3537 { return "Yes — GameSir's own USB vendor ID (0x3537)" }
    if strings.contains(where: { $0.contains("gamesir") }) { return "Yes — the device names itself GameSir" }
    if strings.contains(where: { $0.contains("zikway") }) {
        return "Very likely — Zikway firmware, which GameSir controllers use (a few other brands do too)"
    }
    return nil
}

// MARK: - GameController input tracking

final class GCMonitor {
    let controller: GCController
    var seen = Set<ObjectIdentifier>()
    var onEvent: ((String) -> Void)?

    init(_ controller: GCController) {
        self.controller = controller
        // Without this, macOS swallows system-gesture buttons (HOME/PS opens the Games app,
        // Share/Create takes a screenshot) so they never reach us. Applies while we're frontmost.
        for element in controller.physicalInputProfile.allElements {
            element.preferredSystemGestureState = .disabled
        }
        controller.physicalInputProfile.valueDidChangeHandler = { [weak self] _, element in
            self?.record(element)
        }
    }

    var buttons: [(String, GCControllerButtonInput)] {
        let p = controller.physicalInputProfile
        let dpadParts = Set(p.dpads.values.flatMap { [$0.up, $0.down, $0.left, $0.right].map(ObjectIdentifier.init) })
        var byID: [ObjectIdentifier: (String, GCControllerButtonInput)] = [:]
        for (key, b) in p.buttons where !dpadParts.contains(ObjectIdentifier(b)) {
            let name = b.localizedName ?? key
            if let existing = byID[ObjectIdentifier(b)], existing.0.count <= name.count { continue }
            byID[ObjectIdentifier(b)] = (name, b)
        }
        return byID.values.sorted { $0.0 < $1.0 }
    }

    var dpads: [(String, GCControllerDirectionPad)] {
        var byID: [ObjectIdentifier: (String, GCControllerDirectionPad)] = [:]
        for (key, d) in controller.physicalInputProfile.dpads {
            let name = d.localizedName ?? key
            if let existing = byID[ObjectIdentifier(d)], existing.0.count <= name.count { continue }
            byID[ObjectIdentifier(d)] = (name, d)
        }
        return byID.values.sorted { $0.0 < $1.0 }
    }

    func isVerified(_ element: GCControllerElement) -> Bool { seen.contains(ObjectIdentifier(element)) }

    /// A d-pad or stick counts as verified once all four directions have been reached.
    func isVerified(_ d: GCControllerDirectionPad) -> Bool { [d.up, d.down, d.left, d.right].allSatisfy(isVerified) }

    func record(_ element: GCControllerElement) {
        if let b = element as? GCControllerButtonInput {
            if b.isPressed { seen.insert(ObjectIdentifier(b)) }
            onEvent?(String(format: "%@  %@  %.2f", b.localizedName ?? "button", b.isPressed ? "DOWN" : "up  ", b.value))
        } else if let d = element as? GCControllerDirectionPad {
            for part in [d.up, d.down, d.left, d.right] where part.isPressed { seen.insert(ObjectIdentifier(part)) }
            onEvent?(String(format: "%@  x %+.2f  y %+.2f", d.localizedName ?? "dpad", d.xAxis.value, d.yAxis.value))
        }
    }

}

extension GCMonitor: PadSource {
    func reset() { seen.removeAll() }

    func snapshot() -> PadSnapshot {
        var roles: [ObjectIdentifier: PadRole] = [:]
        var stickRoles: [ObjectIdentifier: StickRole] = [:]
        if let g = controller.extendedGamepad {
            // GameController names face buttons by position: A south, B east, X west, Y north.
            let placed: [(GCControllerButtonInput?, PadRole)] = [
                (g.buttonA, .south), (g.buttonB, .east), (g.buttonX, .west), (g.buttonY, .north),
                (g.leftShoulder, .leftShoulder), (g.rightShoulder, .rightShoulder),
                (g.leftTrigger, .leftTrigger), (g.rightTrigger, .rightTrigger),
                (g.buttonMenu, .menu), (g.buttonOptions, .options), (g.buttonHome, .home),
                (g.leftThumbstickButton, .leftStickClick), (g.rightThumbstickButton, .rightStickClick),
            ]
            for case let (b?, role) in placed { roles[ObjectIdentifier(b)] = role }
            stickRoles = [ObjectIdentifier(g.leftThumbstick): .leftStick,
                          ObjectIdentifier(g.rightThumbstick): .rightStick,
                          ObjectIdentifier(g.dpad): .dpad]
        }
        let category = controller.productCategory
        func dir(_ b: GCControllerButtonInput) -> DirectionState { DirectionState(pressed: b.isPressed, verified: isVerified(b)) }

        return PadSnapshot(
            title: controller.vendorName ?? "controller",
            source: "macOS GameController",
            playStationLayout: ["DualShock", "DualSense", "PS"].contains { category.contains($0) },
            buttons: buttons.map { name, b in
                PadButtonState(id: name, name: name, label: shortLabel(name), symbol: b.sfSymbolsName,
                               role: roles[ObjectIdentifier(b)], pressed: b.isPressed, value: b.value,
                               isAnalog: b.isAnalog, verified: isVerified(b))
            },
            sticks: dpads.map { name, d in
                PadStickState(id: name, name: name, role: stickRoles[ObjectIdentifier(d)],
                              x: d.xAxis.value, y: d.yAxis.value,
                              up: dir(d.up), down: dir(d.down), left: dir(d.left), right: dir(d.right))
            },
            battery: controller.battery.flatMap { $0.batteryState == .unknown ? nil : $0.batteryLevel })
    }
}

/// "A Button" → "A", "+ Button" → "+"; longer names come back empty so views can show a symbol instead.
func shortLabel(_ name: String) -> String {
    let bare = name.replacingOccurrences(of: " Button", with: "")
    return bare.count <= 2 ? bare : ""
}

// MARK: - Unified input snapshot (what the testers render, whatever the source)

enum PadRole {
    case south, east, west, north, leftShoulder, rightShoulder, leftTrigger, rightTrigger
    case menu, options, home, share, leftStickClick, rightStickClick
}

enum StickRole { case leftStick, rightStick, dpad }

struct DirectionState { var pressed = false, verified = false }

struct PadButtonState {
    let id: String, name: String
    let label: String          // short text for the diagram; empty → use `symbol`
    let symbol: String?
    let role: PadRole?
    let pressed: Bool, value: Float, isAnalog: Bool, verified: Bool
}

struct PadStickState {
    let id: String, name: String
    let role: StickRole?
    let x: Float, y: Float
    let up: DirectionState, down: DirectionState, left: DirectionState, right: DirectionState

    var directions: [(String, DirectionState)] { [("Up", up), ("Down", down), ("Left", left), ("Right", right)] }
    var verified: Bool { directions.allSatisfy(\.1.verified) }
}

struct PadSnapshot {
    let title: String
    let source: String
    let playStationLayout: Bool
    let buttons: [PadButtonState]
    let sticks: [PadStickState]
    let battery: Float?
    /// Input names the user said this controller doesn't have; left out of the totals.
    var skipped: Set<String> = []

    func button(_ role: PadRole) -> PadButtonState? { buttons.first { $0.role == role } }
    func stick(_ role: StickRole) -> PadStickState? { sticks.first { $0.role == role } }

    static func inputName(_ stick: PadStickState, _ direction: String) -> String { "\(stick.name) \(direction)" }

    /// Every checklist input as (name, verified).
    var inputs: [(String, Bool)] {
        buttons.map { ($0.name, $0.verified) }
            + sticks.flatMap { s in s.directions.map { (Self.inputName(s, $0.0), $0.1.verified) } }
    }

    /// A skipped input that responds anyway counts again.
    func isSkipped(_ name: String, verified: Bool) -> Bool { !verified && skipped.contains(name) }

    var totals: (verified: Int, total: Int, missing: [String]) {
        let counted = inputs.filter { !isSkipped($0.0, verified: $0.1) }
        let missing = counted.filter { !$0.1 }.map(\.0)
        return (counted.count - missing.count, counted.count, missing)
    }
}

protocol PadSource: AnyObject {
    func snapshot() -> PadSnapshot
    func reset()
    /// Undo anything the source switched on in the controller. Called before it's dropped.
    func close()
}

extension PadSource {
    func close() {}
}

// MARK: - Switch Pro report decoding

/// Reads Switch Pro Controller input reports (ID 0x30) directly. macOS's GameController
/// driver drops some buttons from third-party Switch-mode controllers, so for those this
/// is the source of truth.
final class SwitchProMonitor: PadSource {
    struct Button { let name: String, label: String, symbol: String?, role: PadRole, byte: Int, mask: UInt8 }

    static let buttons: [Button] = [
        Button(name: "A Button", label: "A", symbol: nil, role: .east, byte: 3, mask: 0x08),
        Button(name: "B Button", label: "B", symbol: nil, role: .south, byte: 3, mask: 0x04),
        Button(name: "X Button", label: "X", symbol: nil, role: .north, byte: 3, mask: 0x02),
        Button(name: "Y Button", label: "Y", symbol: nil, role: .west, byte: 3, mask: 0x01),
        Button(name: "R Button", label: "R", symbol: nil, role: .rightShoulder, byte: 3, mask: 0x40),
        Button(name: "ZR Button", label: "ZR", symbol: nil, role: .rightTrigger, byte: 3, mask: 0x80),
        Button(name: "- Button", label: "−", symbol: nil, role: .options, byte: 4, mask: 0x01),
        Button(name: "+ Button", label: "+", symbol: nil, role: .menu, byte: 4, mask: 0x02),
        Button(name: "Right Stick Button", label: "", symbol: nil, role: .rightStickClick, byte: 4, mask: 0x04),
        Button(name: "Left Stick Button", label: "", symbol: nil, role: .leftStickClick, byte: 4, mask: 0x08),
        Button(name: "HOME Button", label: "", symbol: "house", role: .home, byte: 4, mask: 0x10),
        Button(name: "Capture Button", label: "", symbol: "camera", role: .share, byte: 4, mask: 0x20),
        Button(name: "L Button", label: "L", symbol: nil, role: .leftShoulder, byte: 5, mask: 0x40),
        Button(name: "ZL Button", label: "ZL", symbol: nil, role: .leftTrigger, byte: 5, mask: 0x80),
    ]
    // D-pad bits in byte 5.
    static let dpadDown: UInt8 = 0x01, dpadUp: UInt8 = 0x02, dpadRight: UInt8 = 0x04, dpadLeft: UInt8 = 0x08

    let hid: HIDMonitor
    private var report: [UInt8] = []
    private var seen = Set<String>()

    static func matches(_ c: Candidate) -> Bool { c.vid == 0x057E && c.pid == 0x2009 && c.hid != nil }

    init(_ hid: HIDMonitor) {
        self.hid = hid
        hid.onReportBytes = { [weak self] id, bytes in
            if id == 0x30, bytes.count >= 12 { self?.ingest(bytes) }
        }
    }

    func reset() { seen.removeAll() }

    private func ingest(_ bytes: [UInt8]) {
        report = bytes
        for b in Self.buttons where bytes[b.byte] & b.mask != 0 { seen.insert(b.name) }
        for s in sticks(from: bytes) {
            for (dir, state) in s.directions where state.pressed { seen.insert("\(s.name) \(dir)") }
        }
    }

    /// 12-bit stick values packed into three bytes, centred near 2048. Uncalibrated, so
    /// scaled a little generously and clamped.
    private static func stick(_ b: [UInt8], at o: Int) -> (Float, Float) {
        let x = Int(b[o]) | (Int(b[o + 1]) & 0x0F) << 8
        let y = Int(b[o + 1]) >> 4 | Int(b[o + 2]) << 4
        func norm(_ v: Int) -> Float { max(-1, min(1, Float(v - 2048) / 1600)) }
        return (norm(x), norm(y))
    }

    private func sticks(from b: [UInt8]) -> [PadStickState] {
        func dir(_ name: String, _ d: String, _ pressed: Bool) -> DirectionState {
            DirectionState(pressed: pressed, verified: pressed || seen.contains("\(name) \(d)"))
        }
        func analog(_ name: String, _ role: StickRole, _ offset: Int) -> PadStickState {
            let (x, y) = b.count >= 12 ? Self.stick(b, at: offset) : (0, 0)
            return PadStickState(id: name, name: name, role: role, x: x, y: y,
                                 up: dir(name, "Up", y > 0.5), down: dir(name, "Down", y < -0.5),
                                 left: dir(name, "Left", x < -0.5), right: dir(name, "Right", x > 0.5))
        }
        let d = b.count >= 6 ? b[5] : 0
        let dpad = "Directional Buttons"
        let up = d & Self.dpadUp != 0, down = d & Self.dpadDown != 0
        let left = d & Self.dpadLeft != 0, right = d & Self.dpadRight != 0
        return [
            PadStickState(id: dpad, name: dpad, role: .dpad,
                          x: right ? 1 : left ? -1 : 0, y: up ? 1 : down ? -1 : 0,
                          up: dir(dpad, "Up", up), down: dir(dpad, "Down", down),
                          left: dir(dpad, "Left", left), right: dir(dpad, "Right", right)),
            analog("Left Stick", .leftStick, 6),
            analog("Right Stick", .rightStick, 9),
        ]
    }

    func snapshot() -> PadSnapshot {
        let b = report
        return PadSnapshot(
            title: hid.name,
            source: "the controller's own Switch reports",
            playStationLayout: false,
            buttons: Self.buttons.map { btn in
                let pressed = b.count > btn.byte && b[btn.byte] & btn.mask != 0
                return PadButtonState(id: btn.name, name: btn.name, label: btn.label, symbol: btn.symbol,
                                      role: btn.role, pressed: pressed, value: pressed ? 1 : 0,
                                      isAnalog: false, verified: seen.contains(btn.name))
            }.sorted { $0.name < $1.name },
            sticks: sticks(from: b).sorted { $0.name < $1.name },
            battery: nil)
    }
}

/// GameController doesn't expose USB IDs, so pair by name: the controller whose name matches
/// the candidate's product string, else the one at the same position among HID candidates.
func gameController(for candidate: Candidate?, among candidates: [Candidate]) -> GCController? {
    let controllers = GCController.controllers()
    guard let candidate else { return controllers.first }
    if let product = candidate.product?.lowercased(),
       let named = controllers.first(where: { $0.vendorName?.lowercased() == product }) {
        return named
    }
    let hidCandidates = candidates.filter { $0.hid != nil }
    guard let i = hidCandidates.firstIndex(where: { $0.id == candidate.id }), controllers.indices.contains(i) else {
        return controllers.count == 1 && hidCandidates.count <= 1 ? controllers.first : nil
    }
    return controllers[i]
}

/// Prefers decoding Switch reports directly; otherwise uses macOS GameController.
func makePadSource(for candidate: Candidate?, hid: HIDMonitor?, gc: GCMonitor?) -> PadSource? {
    if let candidate, SwitchProMonitor.matches(candidate), let hid { return SwitchProMonitor(hid) }
    if let candidate, Nova2LiteMonitor.matches(candidate), let nova = Nova2LiteMonitor() { return nova }
    return gc
}

// MARK: - GameSir Nova 2 Lite in PC mode

/// Talks to the Nova 2 Lite's configuration interface (vendor page FF7A) in PC mode, where
/// macOS has no driver for its XInput gamepad interface. Every packet here was taken from
/// GameSir Connect 1.14.5 and checked against the controller.
/// Never sends anything else: in particular not F2 00 04 F6, which starts a firmware update.
final class Nova2LiteMonitor: PadSource {
    struct Button { let name: String, label: String, symbol: String?, role: PadRole, byte: Int, mask: UInt8 }

    // Offsets relative to the first button byte, from GameSir Connect's state decoder.
    static let buttons: [Button] = [
        Button(name: "A Button", label: "A", symbol: nil, role: .south, byte: 0, mask: 0x01),
        Button(name: "B Button", label: "B", symbol: nil, role: .east, byte: 0, mask: 0x02),
        Button(name: "X Button", label: "X", symbol: nil, role: .west, byte: 0, mask: 0x08),
        Button(name: "Y Button", label: "Y", symbol: nil, role: .north, byte: 0, mask: 0x10),
        Button(name: "LB Button", label: "LB", symbol: nil, role: .leftShoulder, byte: 0, mask: 0x40),
        Button(name: "RB Button", label: "RB", symbol: nil, role: .rightShoulder, byte: 0, mask: 0x80),
        Button(name: "View Button", label: "", symbol: nil, role: .options, byte: 1, mask: 0x04),
        Button(name: "Menu Button", label: "", symbol: nil, role: .menu, byte: 1, mask: 0x08),
        Button(name: "Home Button", label: "", symbol: "house", role: .home, byte: 1, mask: 0x10),
        Button(name: "Left Stick Button", label: "", symbol: nil, role: .leftStickClick, byte: 1, mask: 0x20),
        Button(name: "Right Stick Button", label: "", symbol: nil, role: .rightStickClick, byte: 1, mask: 0x40),
        Button(name: "Capture Button", label: "", symbol: "camera", role: .share, byte: 1, mask: 0x80),
    ]
    static let dpadUp: UInt8 = 0x01, dpadDown: UInt8 = 0x02, dpadLeft: UInt8 = 0x04, dpadRight: UInt8 = 0x08

    static func matches(_ c: Candidate) -> Bool { c.vid == 0x3537 && (c.pid == 0x100F || c.pid == 0x1098) }

    private let manager: IOHIDManager
    private let device: IOHIDDevice
    private let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private var report: [UInt8] = []
    private var seen = Set<String>()
    private var closed = false

    /// Firmware as GameSir writes it, e.g. "6101": version 61, then edition 01.
    private(set) var firmwareCode: String?

    var firmwareDescription: String? {
        guard let code = firmwareCode, code.count == 4 else { return firmwareCode }
        let edition = code.hasSuffix("01") ? "international" : code.hasSuffix("00") ? "internal" : "edition \(code.suffix(2))"
        return "V\(code.prefix(2)) \(edition) (\(code))"
    }

    init?() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: 0x3537, kIOHIDPrimaryUsagePageKey: 0xFF7A] as CFDictionary)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let device = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first(where: {
            [0x100F, 0x1098].contains(hidProp($0, kIOHIDProductIDKey) as? Int ?? 0)
        }) else { return nil }
        self.device = device
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, 64, { ctx, _, _, _, _, report, length in
            Unmanaged<Nova2LiteMonitor>.fromOpaque(ctx!).takeUnretainedValue()
                .receive(Array(UnsafeBufferPointer(start: report, count: length)))
        }, ctx)
        send([0x01, 0x01])                                  // GetVersion of the controller (device 1)
        send(Self.withChecksum([0xF3, 0x01, 0x05, 0x01]))   // state reports on, "Original" (physical) layout
    }

    deinit { close() }

    /// Turns state reports off again, as GameSir Connect does when it lets go of a controller.
    func close() {
        guard !closed else { return }
        closed = true
        send(Self.withChecksum([0xF3, 0x01, 0x05, 0x00]))
        IOHIDDeviceRegisterInputReportCallback(device, buffer, 64, nil, nil)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    func reset() { seen.removeAll() }

    /// Runs both motors briefly with GameSir Connect's own vibrate and stop packets.
    func vibrate(strength: UInt8 = 0x60, duration: TimeInterval = 0.5) {
        send([0x04, strength, 0x08, strength, 0x08, 0x00, 0x08, 0x00, 0x08])
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.send([0x04, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08])
        }
    }

    /// Settings packets end with the low byte of the sum of everything before it.
    private static func withChecksum(_ bytes: [UInt8]) -> [UInt8] {
        bytes + [bytes.reduce(0, &+)]
    }

    private func send(_ payload: [UInt8]) {
        guard !closed || payload.first == 0xF3 else { return }
        var out = payload + [UInt8](repeating: 0, count: 64 - payload.count)
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &out, out.count)
    }

    private func receive(_ bytes: [UInt8]) {
        switch bytes.first {
        case 0x01 where bytes.count > 11:  // GetVersion reply: firmware in bytes 10–11
            firmwareCode = String(format: "%02X%02X", bytes[10], bytes[11])
        case 0xF4 where bytes.count > 21 && bytes[1] == 0x00:
            report = bytes
            if firmwareCode == nil { firmwareCode = String(format: "%02X%02X", bytes[20], bytes[21]) }
            record(bytes)
        default:
            break  // acknowledgements (F3 echo) and anything unknown
        }
    }

    /// Byte positions depend on the report format in byte 2 (GameSir Connect's decoder):
    /// below 32 the buttons start at 4 and sticks at 8; from 32 the sticks move to 22, and
    /// from 38 the triggers move to 30 and buttons to 32.
    private struct Layout { let keys: Int, sticks: Int, leftTrigger: Int, rightTrigger: Int }

    private func layout(_ b: [UInt8]) -> Layout {
        let format = b.count > 2 ? Int(b[2]) : 0
        if format >= 38 && b.count >= 38 { return Layout(keys: 32, sticks: 22, leftTrigger: 30, rightTrigger: 31) }
        if format >= 32 { return Layout(keys: 4, sticks: 22, leftTrigger: 16, rightTrigger: 17) }
        return Layout(keys: 4, sticks: 8, leftTrigger: 16, rightTrigger: 17)
    }

    private func axis(_ b: [UInt8], _ offset: Int) -> Float {
        guard b.count > offset + 1 else { return 0 }
        let raw = Int16(bitPattern: UInt16(b[offset]) | UInt16(b[offset + 1]) << 8)
        return raw >= 0 ? Float(raw) / 32767 : Float(raw) / 32768
    }

    private func record(_ b: [UInt8]) {
        let s = state(b)
        for btn in s.buttons where btn.pressed { seen.insert(btn.name) }
        for stick in s.sticks {
            for (dir, d) in stick.directions where d.pressed { seen.insert(PadSnapshot.inputName(stick, dir)) }
        }
    }

    private func state(_ b: [UInt8]) -> (buttons: [PadButtonState], sticks: [PadStickState]) {
        guard b.count >= 22 else { return ([], []) }
        let l = layout(b)
        var buttons = Self.buttons.map { btn -> PadButtonState in
            let pressed = b[l.keys + btn.byte] & btn.mask != 0
            return PadButtonState(id: btn.name, name: btn.name, label: btn.label, symbol: btn.symbol, role: btn.role,
                                  pressed: pressed, value: pressed ? 1 : 0, isAnalog: false, verified: seen.contains(btn.name))
        }
        for (name, label, role, offset) in [("LT Button", "LT", PadRole.leftTrigger, l.leftTrigger),
                                            ("RT Button", "RT", PadRole.rightTrigger, l.rightTrigger)] {
            let value = Float(b[offset]) / 255
            buttons.append(PadButtonState(id: name, name: name, label: label, symbol: nil, role: role,
                                          pressed: value > 0.1, value: value, isAnalog: true, verified: seen.contains(name)))
        }

        func dir(_ stick: String, _ d: String, _ pressed: Bool) -> DirectionState {
            DirectionState(pressed: pressed, verified: pressed || seen.contains("\(stick) \(d)"))
        }
        func analog(_ name: String, _ role: StickRole, _ offset: Int) -> PadStickState {
            let x = axis(b, offset), y = axis(b, offset + 2)  // positive y is up
            return PadStickState(id: name, name: name, role: role, x: x, y: y,
                                 up: dir(name, "Up", y > 0.5), down: dir(name, "Down", y < -0.5),
                                 left: dir(name, "Left", x < -0.5), right: dir(name, "Right", x > 0.5))
        }
        let d = b[l.keys + 2], dpad = "Directional Buttons"
        let up = d & Self.dpadUp != 0, down = d & Self.dpadDown != 0
        let left = d & Self.dpadLeft != 0, right = d & Self.dpadRight != 0
        let sticks = [
            PadStickState(id: dpad, name: dpad, role: .dpad,
                          x: right ? 1 : left ? -1 : 0, y: up ? 1 : down ? -1 : 0,
                          up: dir(dpad, "Up", up), down: dir(dpad, "Down", down),
                          left: dir(dpad, "Left", left), right: dir(dpad, "Right", right)),
            analog("Left Stick", .leftStick, l.sticks),
            analog("Right Stick", .rightStick, l.sticks + 4),
        ]
        return (buttons, sticks)
    }

    /// An all-released report, so the checklist lists every input before the first report arrives.
    private static let idleReport: [UInt8] = [0xF4, 0x00, 0x17] + [UInt8](repeating: 0, count: 61)

    func snapshot() -> PadSnapshot {
        let s = state(report.isEmpty ? Self.idleReport : report)
        return PadSnapshot(title: "GameSir Nova 2 Lite", source: "GameSir's configuration interface",
                           playStationLayout: false,
                           buttons: s.buttons.sorted { $0.name < $1.name },
                           sticks: s.sticks.sorted { $0.name < $1.name },
                           battery: nil)
    }
}

// MARK: - Raw HID input tracking (works for any HID controller, even ones GameController ignores)

final class HIDMonitor {
    struct Element { let page: Int, usage: Int; var value: Int; var min: Int; var max: Int; var everActive: Bool }

    let device: IOHIDDevice
    let name: String
    let buffer: UnsafeMutablePointer<UInt8>
    let bufferSize: Int
    var baseline: [UInt32: [UInt8]] = [:]
    var latest: [UInt32: [UInt8]] = [:]
    var everChanged: [UInt32: Set<Int>] = [:]
    var reportCount = 0
    var elements: [UInt32: Element] = [:]
    var handshakeSent = false
    var onEvent: ((String) -> Void)?
    var onReportBytes: ((UInt32, [UInt8]) -> Void)?

    init(_ device: IOHIDDevice) {
        self.device = device
        name = hidProp(device, kIOHIDProductKey) as? String ?? "HID controller"
        bufferSize = max(hidProp(device, kIOHIDMaxInputReportSizeKey) as? Int ?? 64, 64)
        buffer = .allocate(capacity: bufferSize)
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferSize, { ctx, _, _, _, reportID, report, length in
            Unmanaged<HIDMonitor>.fromOpaque(ctx!).takeUnretainedValue()
                .onReport(reportID, Array(UnsafeBufferPointer(start: report, count: length)))
        }, ctx)
        IOHIDDeviceRegisterInputValueCallback(device, { ctx, _, _, value in
            Unmanaged<HIDMonitor>.fromOpaque(ctx!).takeUnretainedValue().onValue(value)
        }, ctx)

        // A wired Switch Pro Controller (and GameSir in Switch mode) stays silent until it
        // gets the USB handshake, so nudge it if nothing has arrived after a moment.
        let vid = hidProp(device, kIOHIDVendorIDKey) as? Int ?? 0
        let pid = hidProp(device, kIOHIDProductIDKey) as? Int ?? 0
        if vid == 0x057E && pid == 0x2009 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self, self.reportCount == 0 else { return }
                for cmd: [UInt8] in [[0x80, 0x02], [0x80, 0x04]] {
                    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x80, cmd, cmd.count)
                }
                self.handshakeSent = true
            }
        }
    }

    /// Stops callbacks into this monitor; call before dropping the last reference.
    func detach() {
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferSize, nil, nil)
        IOHIDDeviceRegisterInputValueCallback(device, nil, nil)
    }

    func onReport(_ id: UInt32, _ bytes: [UInt8]) {
        reportCount += 1
        if baseline[id] == nil { baseline[id] = bytes }
        let base = baseline[id]!
        for i in bytes.indices where i < base.count && bytes[i] != base[i] {
            everChanged[id, default: []].insert(i)
        }
        onReportBytes?(id, bytes)
        if latest[id] != bytes {
            onEvent?("report \(id): " + bytes.prefix(48).map { String(format: "%02X", $0) }.joined(separator: " "))
        }
        latest[id] = bytes
    }

    func onValue(_ value: IOHIDValue) {
        let el = IOHIDValueGetElement(value)
        let page = Int(IOHIDElementGetUsagePage(el)), usage = Int(IOHIDElementGetUsage(el))
        guard page < 0xFF00, IOHIDElementGetReportSize(el) <= 32,
              page == kHIDPage_Button || page == kHIDPage_GenericDesktop || page == kHIDPage_Simulation else { return }
        let cookie = IOHIDElementGetCookie(el)
        let v = IOHIDValueGetIntegerValue(value)
        var e = elements[cookie] ?? Element(page: page, usage: usage, value: v, min: v, max: v, everActive: false)
        e.value = v
        e.min = min(e.min, v); e.max = max(e.max, v)
        if page == kHIDPage_Button && v != 0 { e.everActive = true }
        if page != kHIDPage_Button && e.max - e.min > 0 { e.everActive = true }
        elements[cookie] = e
    }

    static func usageName(_ page: Int, _ usage: Int) -> String {
        if page == kHIDPage_Button { return "Button \(usage)" }
        if page == kHIDPage_GenericDesktop {
            let names = [0x30: "X axis", 0x31: "Y axis", 0x32: "Z axis", 0x33: "Rx axis", 0x34: "Ry axis",
                         0x35: "Rz axis", 0x36: "Slider", 0x37: "Dial", 0x39: "Hat switch"]
            if let n = names[usage] { return n }
        }
        if page == kHIDPage_Simulation { return usage == 0xC4 ? "Accelerator" : usage == 0xC5 ? "Brake" : "Sim \(usage)" }
        return String(format: "%02X:%02X", page, usage)
    }

    var sortedElements: [Element] { elements.values.sorted { ($0.page, $0.usage) < ($1.page, $1.usage) } }

    func resetState() {
        baseline = latest
        everChanged = [:]
        for k in elements.keys {
            elements[k]!.everActive = false
            elements[k]!.min = elements[k]!.value
            elements[k]!.max = elements[k]!.value
        }
    }
}
