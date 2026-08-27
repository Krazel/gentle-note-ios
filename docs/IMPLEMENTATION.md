# Implementation handoff — 0.6 (1)

## Implemented

- Native SwiftUI iPhone app with the approved Quiet Linen language.
- Two-step onboarding (welcome and optional device lock); detailed privacy and
  care limits remain available in Settings and Help & Safety,
  background privacy cover, and Help & Safety access from the locked screen.
- Journal Home with distinct blank/template paths, seven optional templates
  with purpose summaries and reachable cancellation, drafts, Journal History,
  local search/filtering, previews-off default, Keep, detail, editing, PDF/text
  export, individual deletion, and total erase.
- Library for notes, images, video, and audio with one tag system for both
  organization and filtering. Images can be captured or selected in Photos;
  videos can be recorded or selected in Photos; audio can be recorded or
  chosen with the system file picker. Camera/microphone access is requested
  only for capture. The app provides four included tags plus user-created tags,
  local playback, Keep, metadata search, export, and delete. A schema-v2
  migration converts every legacy collection into a tag and preserves all item
  assignments. Library has a dismissible
  introduction explaining that it is a standalone archive for words and
  reminders the person may want to recover later; Settings can show it again.
- AES-GCM encrypted text/metadata and chunk-encrypted recordings, a random key
  in the device-only Keychain, complete iOS file protection, backup exclusion,
  protected temporary files, and cleanup at background/export/playback exit.
- Settings for system-default/English/Spanish language selection, the Library
  introduction, lock delay, preview controls, guided-template visibility,
  permission status, dynamic storage breakdown, export, erase, safety, privacy,
  terms, and About.
- Authentication before deletion is a separate App Lock option and is off by
  default. Confirmations remain visible; Face ID/Touch ID/passcode is requested
  only when this option and App Lock are both enabled.
- A global outside-tap handler dismisses active text fields and editors while
  allowing the tapped control to continue receiving its action.
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
  automatic system-language selection with an in-app override, manual Xcode
  project, shared scheme, unit tests, static verifier, and a manual-only macOS
  workflow that tests and packages a labeled unsigned Local-QA IPA.

## Deliberately not claimed complete

This Windows host has no Swift toolchain, Xcode, iOS Simulator, or physical
iPhone session. A dedicated Apple Distribution identity and App Store profile
are consumed only as encrypted secrets in this public repository's protected
`app-store-production` environment, never as source files, artifacts, or logs.
GitHub Actions is the compilation, XCTest, signed archive, and TestFlight upload gate;
runtime behavior on a physical device, accessibility, backup, network, deletion,
and visual 1:1 gates remain unexecuted. The final app icon,
specialist/lived-experience review, legal/support endpoints, product name
clearance, and full App Store submission metadata remain incomplete.

The owner authorized the unsigned Local-QA workflow on 2026-08-26 and explicitly
authorized App Store Connect app creation, signing, and TestFlight preparation
on 2026-08-27. The TestFlight workflow remains manual and never submits to App
Review or releases the app publicly.
