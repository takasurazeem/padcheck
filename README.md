# PadCheck

A macOS app and command-line tool that tells you **what game controller is plugged in** (whoever
made it), **whether it's a GameSir and which mode it's in**, and lets you **verify every
button, trigger, stick and d-pad direction**.

## What it identifies

- **What the controller claims to be:** USB vendor/product ID matched against known pads
  (Switch Pro, Joy-Con, Xbox 360/One/Series, DualShock 3/4, DualSense).
- **Genuine or emulated:** third-party controllers that pretend to be a first-party pad
  report their own manufacturer string; PadCheck compares it with the real one.
- **GameSir detection:** GameSir's USB vendor ID (`0x3537`), "GameSir" in the device
  names, or Zikway firmware (which GameSir uses).
- **Mode:** Switch, XInput (PC), Xbox, PS3/PS4/PS5, or DInput/Android/generic HID,
  worked out from the emulated IDs and the USB interface classes.
- Manufacturer and product strings, serial, firmware revision, connection, battery.

With several controllers connected, pick one from the **Controller** dropdown; **Refresh**
(⌘R) scans again. The app also rescans on its own every couple of seconds.

## Testing inputs

Each input turns green once it has registered, and the checklist shows what's left.

- **Switch-mode controllers** are read straight from their own `0x30` input reports.
  macOS's GameController framework drops face buttons and Capture from some third-party
  Switch-mode pads, so PadCheck doesn't rely on it for these.
- **Other controllers** are read through the GameController framework. While PadCheck is
  in front it turns off macOS's controller shortcuts (HOME/PS opening the Games app,
  Share taking a screenshot) so those buttons can be tested too.
- **Raw HID view** shows every HID button and axis plus a live hex dump of the input
  reports, with changing bytes highlighted. This works for any HID controller,
  even ones macOS doesn't present to games.

Controllers in XInput mode over USB can be identified, but macOS has no driver for them,
so their buttons can't be read. Switch the controller to Switch or DInput/Android mode to
test them.

## Build

Requires macOS 14+ and the Xcode command-line tools.

```sh
./build.sh
```

This produces `build/PadCheck.app` and the `build/padcheck` CLI.

## CLI usage

```sh
build/padcheck            # identify, then open the live input tester
build/padcheck --info     # identify only
build/padcheck --raw      # start in the raw HID view
build/padcheck --log      # print one line per input event
```

In the live tester: `r` resets the checklist, `h` toggles the raw HID view, `q` quits and
prints any inputs that never registered.

## Layout

| Path | Contents |
|---|---|
| `Core/Controllers.swift` | Identification, GameSir mode detection, input tracking, Switch report decoder |
| `App/` | SwiftUI app |
| `CLI/main.swift` | Terminal tool |
| `build.sh` | Builds both |
