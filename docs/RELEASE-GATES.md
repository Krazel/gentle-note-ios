# Gates remaining before a publishable candidate

- Generate the Xcode project and compile/test on macOS with Xcode 16+.
- Run all unit and UI flows on iOS 16/17/18 hardware and simulator.
- On iOS 16 hardware, switch Settings between System Default, English, and
  Spanish; verify every visible surface refreshes immediately and System Default
  follows the iPhone language after relaunch.
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
- Verify image selection through the iOS system photo picker, encrypted local
  storage, detail rendering, export, deletion, and that the app receives only
  the item explicitly selected without requesting full photo-library access.
- Verify tapping every included and custom collection filters Library items,
  empty collections show an explicit empty result, clearing the filter restores
  all items, and the separate pencil action still edits custom collections.
- Test VoiceOver, Voice Control, Switch Control, AX5, Increase Contrast, Reduce
  Motion, Reduce Transparency, and both system appearances.
- Obtain eating-disorder clinical, crisis, ARFID/neurodivergence, and diverse
  lived-experience review of every prompt, safety sentence, asset, and store
  claim. Do not add a review credit until that work and permission exist.
- Approve and create a final app icon separately.
- Finalize dedicated support alias, privacy/support URLs, Terms/EULA, app name
  availability, signing, age rating, export compliance, and App Privacy.
- Keep optional StoreKit support hidden until products and owner authorization
  exist. Run the complete App Review preflight on the exact submitted build.
- A public source repository and one manual Local-QA unsigned IPA build were
  authorized on 2026-08-26. TestFlight, App Review, IAP creation, signing-secret
  use, and public App Store release remain explicitly unauthorized.
