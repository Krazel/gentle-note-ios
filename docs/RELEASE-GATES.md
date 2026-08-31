# Gates remaining before a publishable candidate

Prepared locally for candidate 1.0 (1): explicit English localization to
make Settings language switching reliable, bilingual store metadata, truthful
review notes, per-release privacy/age/category/export answers, bilingual legal
page drafts, deterministic runtime screenshot fixtures, and manual protected
workflows for screenshot capture and App Store metadata/assets. None of these
new materials has been pushed, published, uploaded, or submitted yet.

- Generate the Xcode project and compile/test on macOS with Xcode 16+.
- Run all unit and UI flows on iOS 16/17/18 hardware and simulator.
- On iOS 16 hardware, switch Settings between System Default, English, and
  Spanish; verify every visible surface refreshes immediately and System Default
  follows the iPhone language after relaunch.
- In Settings, expand and collapse the Library and Intakes information
  rows in English and Spanish; verify both begin collapsed, remain readable at
  large Dynamic Type sizes, and expose meaningful VoiceOver labels and states.
- Create and edit an Intake in English and Spanish, reveal and hide the guided
  questions, save a partial set of answers, confirm unanswered fields are not
  displayed, and verify the answers survive relaunch and appear in export.
- Verify the Library introduction can be dismissed, remains hidden after
  relaunch, and can be restored from Settings. Check its copy at large Dynamic
  Type sizes and the 44-point dismiss target with VoiceOver.
- Open and cancel the template chooser and every composer both before and after
  typing. Confirm each template purpose summary wraps without truncation in EN/ES.
- Capture every approved surface at matching size; compare against
  `design/approved/` and resolve visual differences.
- Test Face ID/Touch ID/passcode fallback, background snapshots, all lock delays,
  camera/microphone denied/interrupted states, low storage, export cancellation,
  and deletion failure paths on a physical iPhone.
- Verify encrypted vault/media, complete file protection, backup exclusion,
  uninstall behavior, temporary-file cleanup, and zero journal transmission.
- Verify image capture and photo selection, video recording and photo-library
  selection, and audio recording and file selection. Confirm encrypted local
  storage, detail playback/rendering, export, deletion, cancellation cleanup,
  and that system pickers transfer only the explicitly selected item.
- Upgrade a populated schema-v1 vault and verify every legacy collection becomes
  a tag without losing assignments. Tap every included and custom tag to filter,
  verify empty results and filter clearing, then create, rename, and delete a
  custom tag without deleting its Library items.
- Test VoiceOver, Voice Control, Switch Control, AX5, Increase Contrast, Reduce
  Motion, Reduce Transparency, and both system appearances.
- Obtain eating-disorder clinical, crisis, ARFID/neurodivergence, and diverse
  lived-experience review of every prompt, safety sentence, asset, and store
  claim. Do not add a review credit until that work and permission exist.
- Approve the current 1024×1024 opaque app icon as the final 1.0 icon or replace
  it through a separately approved visual.
- Publish and verify the prepared bilingual privacy/support pages. The existing
  dedicated support alias is `coderappskrazel@gmail.com`.
- DSA trader status is already configured in App Store Connect. Decide launch
  territories and complete the recommended 13+/12+ age questionnaire,
  regulated-medical-device declaration, Health & Fitness/Lifestyle categories,
  content rights, export compliance, and Data Not Collected privacy answers.
- The App Store version 1.0 record already exists and is empty. Supply and
  approve the final copyright, uncheck the incorrect login requirement, choose
  manual release, and select the final reviewed build. Capture and visually
  approve the six EN/ES runtime screenshots before uploading them. App preview
  video remains optional.
- Keep optional StoreKit support hidden until products and owner authorization
  exist. Run the complete App Review preflight on the exact submitted build.
- A public source repository and manual Local-QA unsigned IPA builds were
  authorized on 2026-08-26. App Store Connect app creation, dedicated signing
  secrets, and a TestFlight upload were authorized on 2026-08-27. App Review,
  IAP creation, and public App Store release remain explicitly unauthorized.
