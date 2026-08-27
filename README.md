# Gentle Note

Gentle Note is an English-and-Spanish, iPhone-only private recovery journal. The MVP
keeps Journal entries and a multimedia Library on the device, without accounts,
analytics, advertising, tracking, social features, AI, scores, streaks, weight,
calorie, macro, or required meal logging.

## Product structure

- **Journal**: two explicit paths—blank writing or seven optional,
  non-quantified reflection templates with a short purpose summary—plus
  `Journal History`, local search, Keep, edit, export, and deletion.
- **Library**: standalone notes, selected images, private video, and private
  audio; four included collections plus custom collections that also act as
  filters,
  tags, Keep, local search, playback, export, and deletion. Its dismissible
  introduction explains how the Library can preserve words and reminders that
  feel clear now but may be harder to remember later.
- **Settings**: app lock, preview controls, just-in-time permission status,
  storage, export, erase all, region-aware Help & Safety, an optional local
  trusted contact, optional authentication before deletion, an in-app language
  choice (system default, English, or Spanish), Library introduction control,
  privacy, and About.

## Open in Xcode

1. Use macOS with Xcode 16 or newer.
2. Open `GentleNote.xcodeproj` after it is generated from `project.yml` with
   XcodeGen, or generate the project using `scripts/bootstrap-xcode.sh`.
3. Select an iPhone simulator running iOS 16 or later.
4. Build the `GentleNote` scheme.

No third-party runtime dependency is used. Camera, microphone, Face ID/Touch ID,
StoreKit, PDF export, and playback use Apple frameworks.

## Local-QA IPA

The manual GitHub Actions workflow compiles and tests the app on macOS, builds a
device `.app` without Apple signing, and packages it as a clearly labeled
`Local-QA-unsigned.ipa` artifact with a JSON manifest and SHA-256 file.

The unsigned IPA is intended for a sideloading or re-signing service that adds
a valid Apple identity and provisioning profile. It is not directly installable
as a normally signed iPhone app. The workflow never uploads to TestFlight or
App Store Connect and reads no signing secrets.

## Release boundary

Source candidate version is `0.5`, build `1`. The source repository may be public, but the app is
not uploaded to TestFlight, submitted to App Review, or connected to real
StoreKit products.
The visual runtime comparison, physical-device privacy tests, specialist/lived
experience copy review, final app icon, legal URLs, signing, and release
preflight remain required before a candidate can be called publishable.
