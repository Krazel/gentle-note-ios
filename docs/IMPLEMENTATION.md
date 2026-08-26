# Implementation handoff — 0.1 (1)

## Implemented

- Native SwiftUI iPhone app with the approved Quiet Linen language.
- Four-step onboarding, care limits, privacy/loss warning, optional device lock,
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
- Optional one-time StoreKit support code behind a disabled feature flag. No
  products, prices, transactions, or store configuration are active.
- Privacy manifest, purpose strings, English-only resources, manual Xcode
  project, shared scheme, unit tests, static verifier, and a manual-only macOS
  build workflow.

## Deliberately not claimed complete

This Windows host has no Swift toolchain, Xcode, iOS Simulator, signing identity,
or physical iPhone session. The source and project topology have passed the
local static verifier, but compilation, runtime behavior, accessibility, backup,
network, deletion, and visual 1:1 gates remain unexecuted. The final app icon,
specialist/lived-experience review, legal/support endpoints, product name
clearance, signing, and App Store configuration also remain outside this handoff.

The manual GitHub workflow must not be dispatched until macOS minutes/cost are
authorized. It never uploads to TestFlight or App Store Connect.
