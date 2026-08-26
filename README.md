# Gentle Note

Gentle Note is an English-first, iPhone-only private recovery journal. The MVP
keeps Journal entries and a multimedia Library on the device, without accounts,
analytics, advertising, tracking, social features, AI, scores, streaks, weight,
calorie, macro, or required meal logging.

## Product structure

- **Journal**: blank writing or seven optional, non-quantified reflection
  templates; `Journal History`, local search, Keep, edit, export, and deletion.
- **Library**: free-form notes, private video, and private audio; manual
  collections, tags, Keep, local search, playback, export, and deletion.
- **Settings**: app lock, preview controls, just-in-time permission status,
  storage, export, erase all, Help & Safety, privacy, and About.

## Open in Xcode

1. Use macOS with Xcode 16 or newer.
2. Open `GentleNote.xcodeproj` after it is generated from `project.yml` with
   XcodeGen, or generate the project using `scripts/bootstrap-xcode.sh`.
3. Select an iPhone simulator running iOS 17 or later.
4. Build the `GentleNote` scheme.

No third-party runtime dependency is used. Camera, microphone, Face ID/Touch ID,
StoreKit, PDF export, and playback use Apple frameworks.

## Release boundary

Version is `0.1`, build `1`. This source is not published, uploaded to
TestFlight, submitted to App Review, or connected to real StoreKit products.
The visual runtime comparison, physical-device privacy tests, specialist/lived
experience copy review, final app icon, legal URLs, signing, and release
preflight remain required before a candidate can be called publishable.
