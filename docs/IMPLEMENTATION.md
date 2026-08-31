# Implementation handoff — 1.0 (1)

## Implemented

- Native SwiftUI iPhone app with the approved Quiet Linen language.
- Three-step onboarding (welcome, a first-run overview that always lists
  Journal, Library and Intakes, then optional device lock). The overview can
  be skipped only to the App Lock choice and never completes onboarding or
  changes the lock preference. Detailed privacy and care limits remain
  available in Settings and Help & Safety,
  background privacy cover, and Help & Safety access from the locked screen.
- Journal Home with distinct blank/template paths, seven optional templates
  with purpose summaries and reachable cancellation, drafts, Journal History,
  local search/filtering, previews on by default with user controls, Keep, detail, editing, PDF/text
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
- Intakes as a dedicated root section for meal photos and their context.
  Creation is camera-first with a multi-photo Photos alternative. A required main
  photo anchors each saved intake; optional words, a qualitative guided check-in,
  multiple audio recordings or
  chosen files, multiple recorded or chosen videos, and multiple additional
  captured or chosen images can coexist. The date defaults to now but is
  editable, and Breakfast, Morning snack, Lunch, Afternoon snack, or Dinner can
  be applied or removed with one tap. Its own discreet history and calendar use
  dots and a selected-day list instead of a food-photo grid. Calendar is opened
  from the top-right navigation button; there is no Moments/Calendar switch. Detail supports
  playback, editing, authenticated export, authenticated optional deletion,
  user-controlled previews, and hiding the entire navigation section without data
  loss. All preview types are on by default in this beta and remain individually
  configurable. The section introduction can be dismissed and restored from
  Settings. Vault schema v3 preserves older content and defaults the section empty.
- Audio capture uses the compatible `.record`/`.default` session pair, checks
  both preparation and recording start, and restores other audio sessions when
  finished. Video capture commits its camera configuration before starting the
  session, preventing the launch-time exception found during physical-device
  QA of 0.6 (1).
- AES-GCM encrypted text/metadata and chunk-encrypted recordings, a random key
  in the device-only Keychain, complete iOS file protection, backup exclusion,
  protected temporary files, and cleanup at background/export/playback exit.
- Settings for system-default/English/Spanish language selection with immediate
  full-interface refresh, the Library introduction, Meal Reflections visibility,
  lock delay, preview controls, guided-template visibility, permission status,
  dynamic storage breakdown, export, erase, safety, privacy, terms, and About.
  The longer Library and Intakes explanations are collapsed by default
  behind clearly labelled information rows and expand only when requested.
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
