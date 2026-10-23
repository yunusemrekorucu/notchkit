# Notice

NotchKit
Copyright (c) 2026 Yunus Emre Korucu

NotchKit is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3. See [LICENSE](LICENSE).

## Based on Sapphire

Most of NotchKit 2's source code comes from Sapphire:

- Project: https://github.com/cshariq/Sapphire
- Copyright (c) Shariq Charolia
- License: GNU Affero General Public License v3.0

NotchKit changes Sapphire as follows:

- Renames the app and its user-facing text to NotchKit.
- Removes Firebase analytics, performance traces and the shared Firestore lyrics cache (`App/Sources/App/Telemetry.swift`).
- Replaces Nearby Share and phone continuity with inert stand-ins (`App/Sources/Services/NearbyShareShim.swift`, `App/Sources/Stubs/StubAdditions.swift`).
- Unlocks every feature whose code ships in Sapphire's public source and hides the paid, AI and private-only ones.
- Removes the in-app updater, subscription and helper onboarding steps.
- Adds the Pomodoro, To-dos and Quick Apps widgets from NotchKit 1.x.

NotchKit 1.x (before the move to Sapphire's code) was released under the MIT License. That earlier code is now distributed under the AGPL v3.0 as part of NotchKit 2.

## Third-party components

Sapphire bundles prebuilt `MediaRemoteAdapter.framework` and `SapphireMediaQueue.framework`, based on [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) (BSD-3-Clause). [CREDITS.md](CREDITS.md) lists the other open-source projects Sapphire credits.

Weather data comes from [Open-Meteo](https://open-meteo.com) (CC BY 4.0) and lyrics from [LRCLIB](https://lrclib.net).
