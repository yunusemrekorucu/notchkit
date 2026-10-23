<p align="center">
  <img src="App/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="128" alt="NotchKit app icon">
</p>

<h1 align="center">NotchKit</h1>

<p align="center">
  A free, open-source macOS app that turns your MacBook's notch into a home for widgets, live activities and system tools.<br>
  NotchKit 2 is built on <a href="https://github.com/cshariq/Sapphire">Sapphire</a> by Shariq Charolia and keeps only the parts that cost nothing to run.
</p>

---

## What's in NotchKit 2

NotchKit 2 uses Sapphire's notch, widgets and settings. Everything that needs a paid service, an AI API or a paid Apple Developer account was left out, so nothing in the app costs money to run.

### Notch and widgets

Click the notch (or hover, if **Expand on Hover** is on) to open it. Swipe to switch widgets, and use the icons along the top for the file shelf, notes, clipboard and Focus.

| Widget | What it does |
|---|---|
| **Music** | System-wide Now Playing with artwork, controls, a media source switcher and synced lyrics from [LRCLIB](https://lrclib.net) |
| **Weather** | Current conditions and forecast from [Open-Meteo](https://open-meteo.com), with no API key |
| **Calendar** | Day strip, events and reminders |
| **Focus** | Focus sessions with streaks, app and website blocking |
| **Pomodoro** | Focus, short break and long break cycles with session dots |
| **To-dos** | A quick task list with stars |
| **Quick Apps** | Pinned apps you open in one click; a dot marks running apps |
| **Timer**, **Notes**, **Clipboard**, **Shortcuts**, **Mirror**, **Battery**, **Dev** | Timers and stopwatch, rich-text notes, clipboard history, Shortcuts, camera mirror, battery details and developer activity |

### Live activities

While the notch is closed, it shows what's going on: the track that's playing, timers, Focus, battery and charging, calendar events, file transfers, Bluetooth connections, eye-break reminders and more.

### System tools

- **Snap Zones**: drag windows into custom zones, with keyboard shortcuts
- **HUD**: volume and brightness overlays that replace the system ones
- **Clipboard history**, **Caffeinate**, **Eye Break** (20-20-20), **File Shelf** with AirDrop
- **Lock screen** widgets, **menu bar** item management, **Launchpad**
- **App activities** for Zoom, Meet, Teams and others, and **file progress** for downloads and copies

### Left out on purpose

Gemini Live, Blip and other AI features, sports, finance and Shopify widgets, Nearby Share, phone continuity, the virtual audio driver, the camera extension, Face ID unlock, Spotify/TIDAL account login, analytics and Sapphire's premium-only features.

## Install

1. Download the latest **NotchKit-x.y.z.dmg** from [Releases](https://github.com/yunusemrekorucu/notchkit/releases/latest) and open it.
2. Drag **NotchKit** to **Applications**.
3. Open NotchKit. Because the app isn't notarized, macOS blocks the first launch. Go to **System Settings → Privacy & Security** and click **Open Anyway** next to the NotchKit message. You only need to do this once.

   If you prefer the Terminal, this removes the download quarantine instead:

   ```bash
   xattr -dr com.apple.quarantine /Applications/NotchKit.app
   ```

NotchKit runs on macOS 14.6 or later, natively on both Apple silicon and Intel Macs.

Upgrading from NotchKit 1.x keeps your to-dos, pinned Quick Apps and Pomodoro durations, and turns on the widgets you had enabled.

## Building from source

### Requirements

- Xcode 26 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### Build

```bash
git clone https://github.com/yunusemrekorucu/notchkit.git
cd notchkit
xcodegen generate
open NotchKit.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project NotchKit.xcodeproj -scheme NotchKit -configuration Release -derivedDataPath build/DD build
```

The app is produced as `NotchKit.app`; copy it to `/Applications` and open it.

### Release DMG

`scripts/build-release.sh` builds a universal app and packages it as `build/release/NotchKit-<version>.dmg` (it also needs `brew install create-dmg`). Pushing a tag such as `v2.0.0` runs the same script on GitHub Actions and attaches the DMG to a release. Release notes are read from `docs/release-notes/<tag>.md` when that file exists.

## Permissions

NotchKit walks you through permissions on first launch. Each one only powers the features listed.

| Permission | Used for |
|---|---|
| Accessibility | Media keys, Snap Zones and the HUD |
| Bluetooth | Connection notices and device batteries |
| Location | Local weather |
| Calendars and Reminders | Calendar widget and event activities |
| Camera | Mirror widget |
| Automation (Apple Events) | Controlling Music and Spotify |
| Screen Recording | Per-app audio capture and menu bar tinting |

## Project structure

```
App/
├── Sources/          Sapphire's Swift sources, trimmed and rebranded
│   ├── Notch/        Notch window, shape, morph animation and layout
│   ├── Widgets/      Widget views, including NotchKit's Productivity widgets
│   ├── Services/     Music, weather, calendar, zones, menu bar, lock screen and more
│   ├── App Settings/ Settings window
│   └── Stubs/        No-op stand-ins for Sapphire's private and paid modules
├── ObjC/             Objective-C helpers and the bridging header
├── PrivateHeaders/   Private framework headers
└── Resources/        Asset catalog
```

## Credits and license

NotchKit 2 is a fork of [Sapphire](https://github.com/cshariq/Sapphire), Copyright © Shariq Charolia, licensed under the GNU Affero General Public License v3.0. NotchKit's own code is Copyright © 2026 Yunus Emre Korucu and is released under the same license.

NotchKit is distributed under the [GNU AGPL v3.0](LICENSE). See [NOTICE.md](NOTICE.md) and [CREDITS.md](CREDITS.md) for the third-party components Sapphire includes.
