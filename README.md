# Gentle Note

Gentle Note is an English-and-Spanish, iPhone-only private recovery journal. The MVP
keeps Journal entries, optional Meal Reflections, and a multimedia Library on the device, without accounts,
analytics, advertising, tracking, social features, AI, scores, streaks, weight,
calorie, macro, or required meal logging.

## Product structure

- **Journal**: two explicit paths—blank writing or seven optional,
  non-quantified reflection templates with a short purpose summary—plus
  `Journal History`, local search, Keep, edit, export, and deletion.
- **Library**: standalone notes, images, video, and audio created in the app or
  chosen from the iPhone; four included tags plus custom tags that act as
  filters, Keep, local search, playback, export, and deletion. Its dismissible
  introduction explains how the Library can preserve words and reminders that
  feel clear now but may be harder to remember later.
- **Meal Reflections**: an optional, independent, camera-first section. Every
  saved moment has one main photo and may combine words, multiple audio clips,
  videos, and additional images. Its own history and calendar use optional
  Breakfast/Morning snack/Lunch/Afternoon snack/Dinner labels without scores,
  streaks, required timing, analysis, or plate comparison. Photo previews are
  off by default and the entire navigation section can be hidden without
  deleting its encrypted local content.
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
as a normally signed iPhone app. That Local-QA workflow never uploads to
TestFlight or App Store Connect and reads no signing secrets.

A separate, manual TestFlight workflow in this public repository was authorized
on 2026-08-27. Its release job is limited to the protected
`app-store-production` environment. It runs the same source and XCTest gates,
imports dedicated encrypted environment secrets into a temporary keychain,
archives with the registered App Store identifier, verifies the signature, and
uploads only when the manual `upload_to_testflight` input is enabled. No signing
secret is stored in source, artifacts, or logs. The workflow does not submit a
version to App Review or release the app publicly.

## Release boundary

Source candidate version is `0.7`, build `1`. The source repository is public
and TestFlight preparation/upload is authorized. App Review submission, public
App Store release, and real StoreKit products are not authorized by that step.
The visual runtime comparison, physical-device privacy tests, specialist/lived
experience copy review, final app icon, legal URLs, signing, and release
preflight remain required before a candidate can be called publishable.
