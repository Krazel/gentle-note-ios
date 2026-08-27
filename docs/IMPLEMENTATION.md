# Implementation handoff — 0.3 (1)

## Implemented

- Native SwiftUI iPhone app with the approved Quiet Linen language.
- Two-step onboarding (welcome and optional device lock); detailed privacy and
  care limits remain available in Settings and Help & Safety,
  background privacy cover, and Help & Safety access from the locked screen.
- Journal Home, blank entry, seven optional templates, drafts, Journal History,
  local search/filtering, previews-off default, Keep, detail, editing, PDF/text
  export, individual deletion, and total erase.
- Separate Library for notes, video, and audio with just-in-time permissions,
  custom camera preview/recording, audio metering/waveform, review before save,
  local playback, Keep, collections, tags, metadata search, export, and delete.
- AES-GCM encrypted text/metadata and chunk-encrypted recordings, a random key
  in the device-only Keychain, complete iOS file protection, backup exclusion,
  protected temporary files, and cleanup at background/export/playback exit.
- Settings for lock delay, preview controls, guided-template visibility,
  permission status, dynamic storage breakdown, export, erase, safety, privacy,
  terms, and About.
- App-lock lifecycle handling distinguishes the temporary inactive state caused
  by the iOS authentication sheet from a real background transition and prevents
  concurrent authentication requests.
- Help & Safety selects verified Spain or United States resources from the
  iPhone region. A trusted contact can be stored in encrypted local preferences;
  one tap opens Apple’s message composer with a localized support message, and
  iOS still requires the user to confirm Send. No Contacts permission is used.
- Optional one-time StoreKit support code behind a disabled feature flag. No
  products, prices, transactions, or store configuration are active.
- Privacy manifest, localized purpose strings, English and Spanish resources,
  automatic system-language selection, manual Xcode
  project, shared scheme, unit tests, static verifier, and a manual-only macOS
  workflow that tests and packages a labeled unsigned Local-QA IPA.

## Deliberately not claimed complete

This Windows host has no Swift toolchain, Xcode, iOS Simulator, signing identity,
or physical iPhone session. GitHub Actions is the compilation and XCTest gate;
runtime behavior on a physical device, accessibility, backup, network, deletion,
and visual 1:1 gates remain unexecuted. The final app icon,
specialist/lived-experience review, legal/support endpoints, product name
clearance, signing, and App Store configuration also remain outside this handoff.

The owner authorized dispatching this workflow on 2026-08-26. It never uploads
to TestFlight or App Store Connect and does not consume signing secrets.
