# App Store Connect audit — 2026-08-31

Read-only inspection of app 6805943178. No value was saved and the version was
not added to review.

## Already present

- iOS App Store version 1.0 in **Prepare for Submission** state.
- Primary language: English (U.S.).
- Bundle ID and SKU match the release repository.
- Apple Standard EULA selected.
- Digital Services Act status identifies the developer as a trader.
- Public distribution is the current distribution method.

## Empty or incomplete in App Store Connect

- English subtitle and Spanish app-info localization.
- English and Spanish descriptions, keywords, support URLs, and privacy URLs.
- Screenshots: 0/10 in the displayed 6.5-inch iPhone set. No preview video.
- Primary and secondary categories.
- Content-rights declaration.
- Age-rating questionnaire.
- Regulated-medical-device declaration.
- App Privacy questionnaire; it still shows **Start** and no privacy URL.
- Accessibility feature declaration; it still shows **Start**.
- Price schedule and country/region availability.
- Copyright.
- Build selection for version 1.0.
- App Review contact details and review notes.

## Incorrect or risky defaults to change before submission

- **Login required** is selected even though Gentle Note has no account or
  login. It must be cleared.
- **Automatic release after approval** is selected. Use manual release for the
  first public version so approval cannot publish the app unexpectedly.
- Mac with Apple silicon availability should be decided only after Mac-specific
  QA; iPhone-first does not imply Mac distribution.

## Prepared locally, not uploaded

- Bilingual metadata and review notes.
- Bilingual privacy and support pages.
- Data Not Collected, age, category, medical-device, content-rights, and export
  compliance answers.
- A manual CI workflow for six actual-runtime screenshots in English and
  Spanish at the exact accepted 6.5-inch size.
- A protected workflow that can audit or, after approval, upload metadata and
  approved screenshots without submitting the version for review.
