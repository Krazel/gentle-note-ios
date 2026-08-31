# Gentle Note — canonical visual approvals

Approved by the owner on 2026-08-26. Direction: **A — Quiet Linen**. Target:
iPhone portrait, English-only MVP. Each board is a 1536 × 1024 landscape
presentation containing six complete iPhone surfaces. The device mockups are
the visual specification; runtime captures will be linked after macOS/Xcode QA.

| Board | Canonical screens and states | Reference | SHA-256 | Status |
|---|---|---|---|---|
| 01 | Welcome; local privacy; care limits; lock setup; Journal empty; Journal with draft/history | `design/approved/ui-01-onboarding-journal.png` | `F94224325FB6A9977AF58CAAAE25DA82E10EE38DC489A106ECADFEF6EECCF5D0` | Current visual language; v0.4 interaction amendment below |
| 02 | Template library; Gentle Check-In; Balanced Thought; Self-Compassion Pause; Values Compass; Present-Moment Reflection | `design/approved/ui-02-journal-templates.png` | `23FFE05AABB29E22FE0538C673E9C39B41605900A9AC72CC353F354BBF76CB51` | Current visual language; v0.4 copy amendment below |
| 03 | Blank Entry; Prepare to Talk; Notice Something Small; Journal History; Journal Search; Journal Entry detail | `design/approved/ui-03-journal-history.png` | `E645F69C42B70D732FB7DB703E35316F214034160096CA411ABD8C4E6592EE94` | Current with copy correction below |
| 04 | Library empty; Library populated/hidden previews; New Note; Organize; legacy Collections/Edit Collection reference | `design/approved/ui-04-library-notes-organize.png` | `58580B82DF523B0CC40573B96D83246EC2884B27E32851CE46F83B0FB36BC698` | Quiet Linen remains current; runtime tags and capture/import amendments below supersede the legacy collection surfaces |
| 05 | Video permission primer; video ready; video recording; review/save video; audio primer; audio recording/review | `design/approved/ui-05-video-audio-create.png` | `7F61B655D21496228A96850EAA2D42F49D107CBDEC8CFDDB01F12FB47C9ACDD1` | Current |
| 06 | Video detail; audio detail; Library search; tags; permission denial; storage/interruption error | `design/approved/ui-06-media-search-errors.png` | `2A50800B3193D53014BFCF7CCCAD789FD19152EDC692D97A3BCA5F7CC882996F` | Current |
| 07 | Settings; Privacy & Lock; media permissions; storage; export selection; export warning/success | `design/approved/ui-07-settings-export.png` | `B44BBADE22225DF56477D2364CAD8546A492A32E6E2F102FC959E2E3BD8F7AC6` | Current visual language; v0.4 Settings additions below; storage values are illustrative only |
| 08 | Locked; delete item; erase all; Help & Safety; optional support; Privacy Notice | `design/approved/ui-08-lock-delete-help.png` | `69AFFF70B5B28324743F5B1C06C1096D80B5389ED7C4DBEF2F5F2B5BF29BD345` | Current; clinical/crisis copy still requires specialist review |
| 09 | Independent Meal Reflections home; camera-first main photo; photo review; layered editor; multi-attachment state | `design/approved/ui-09-meal-reflections-creation-en.png` | `D5E8275130EA36D979E766DF1CC7957CB7DBF3672E22E090F7587AC3C836D753` | Approved by owner on 2026-08-28; English creation reference |
| 10 | Reflection history; full detail; deliberate playback; edit; reflection privacy/export; single-item deletion | `design/approved/ui-10-meal-reflections-review-en.png` | `A08229FDA378184D438C57239E07633DCF612FFA503E3A064833BF58057D2092` | Approved by owner on 2026-08-28; English review reference |
| 11 | Spanish localization of independent creation and multi-attachment flow | `design/approved/ui-11-meal-reflections-creation-es.png` | `1EE628BF165AACC4E80F12B7377325940EF7F1669C01011D1AC1E6EBFFE8C4C8` | Approved by owner on 2026-08-28; Spanish creation reference |
| 12 | Spanish localization of history, detail, playback, edit, privacy and deletion | `design/approved/ui-12-meal-reflections-review-es.png` | `C80F099BDE4B2FBE0F7DED7520F679A0153319F9D1F100F4FF577047DCDB7C3B` | Approved by owner on 2026-08-28; Spanish review reference |
| 13 | Internal calendar; selected-day reflections; editable date; optional quick meal-moment selector; calendar-linked detail | `design/approved/ui-13-meal-reflections-calendar-en.png` | `4CB081F0508F7535D294490491D50C358818E31A0F81F8CFE425389BCEF0DDE5` | Approved by owner on 2026-08-28; English calendar amendment |
| 14 | Spanish localization of calendar and optional Desayuno/Tentempié/Comida/Merienda/Cena selector | `design/approved/ui-14-meal-reflections-calendar-es.png` | `5F1FEDD0ACA9A4A46E98C6C7B0F56BA19CD2C2BE1EE46F906E2931F589FDF0AF` | Approved by owner on 2026-08-28; Spanish calendar amendment |
| 15 | First-run overview between Welcome and optional App Lock; Journal, Library and Meal Reflections always shown | `design/approved/ui-15-first-run-overview-es.png` | `12D373601C4344C4735CC17BFA766A5D74024D389511771D7E73E09F7AA2BF5F` | Approved by owner on 2026-08-28; 1041 × 1510 portrait Spanish reference; English uses the approved equivalent copy |

## Owner-requested and safety corrections

- Root navigation is `Journal`, `Library`, optional `Reflections`, `Settings`.
  Home is the Journal.
- `View Journal History` is the explicit path back to previous entries.
- Library contains private Notes, Images, Videos, and Audio. A single Tags
  system handles organization and filtering; legacy Collections are migrated
  into tags. Images, videos, and audio each offer an in-app capture/record path
  and a system-picker import path.
- Board 03 sample text `I'll take a short walk...` is not canonical product
  copy. Runtime fixtures use the neutral sentence `I'll message someone I trust
  and give myself some quiet time.`
- Tag counts and storage values shown in boards are illustrative; runtime values
  are dynamic and never presented as recovery metrics.
- Native permission sheets, keyboards, share sheets, media controls, Dynamic
  Type reflow, VoiceOver focus, and system authentication may adapt to iOS.
- Dark Mode is supported semantically, while the approved boards define the
  primary Light appearance.
- Owner-directed v0.4 amendments on 2026-08-27 preserve Quiet Linen but
  supersede specific board details: Journal offers two distinct actions (`Start
  Blank` and `Choose a Template`) instead of a redundant generic new-entry
  action; template rows include short purpose summaries and no therapy/medical
  footer; `Cancel` is always reachable; Library has a dismissible explanation
  about preserving things that may become harder to remember; Settings can
  restore that explanation and choose System Default, English, or Spanish; the
  former bottom account/ads/analytics footer is removed. Runtime captures, not
  regenerated concept boards, will verify these approved owner corrections.
- Owner-directed v0.5 amendments on 2026-08-28 merge Collections and Tags under
  the more familiar `Tags` name, preserve legacy assignments through migration,
  add capture and import choices for image/video/audio, replace unavailable SF
  Symbols, shorten the open Help title to `Need support?`, and remove its opening
  explanatory block. The Library introduction retains only its memory-purpose
  copy and no longer mentions organization systems.
- Owner-approved Meal Reflections direction on 2026-08-28 adds a fourth root
  destination, `Reflections`, independent of Journal and Library. Every saved
  reflection is anchored by one main photo and may combine optional text,
  multiple audio recordings or chosen audio files, multiple recorded or chosen
  videos, and multiple additional captured or chosen images. Its own list and
  calendar provide review by date. The optional, reversible quick label is one
  of Breakfast, Morning snack, Lunch, Afternoon snack, or Dinner (localized as
  Desayuno, Tentempié, Comida, Merienda, or Cena). Calendar dots indicate saved
  content only; they are not completion, streak, schedule, or progress UI.
- Owner-approved first-run amendment on 2026-08-28 inserts one Quiet Linen
  overview between the existing Welcome and optional App Lock pages. It always
  presents Journal, Library, and Meal Reflections in that order; Meal
  Reflections is described as optional to use. `Skip tour` skips only this
  explanation and advances to App Lock. It never completes onboarding or
  changes the lock preference. Settings and Help & Safety are not included in
  this overview, and the retired privacy/care pages remain absent.
- Owner-directed v0.7.1 refinements on 2026-08-28 retain the approved Quiet
  Linen compositions while moving the overview content closer to its progress
  indicator, replacing the three card descriptions, adding a visible meal
  icon, and allowing the Reflections destination to be hidden from that page.
  In the Reflections root, the calendar replaces the privacy control at top
  right, the Moments/Calendar switch is removed, the introduction is
  dismissible, multi-photo selection is explicit, and attachment actions use
  complete labelled controls. Runtime captures, rather than altered concept
  boards, will verify these direct owner corrections.

- Owner-directed v0.8 amendment on 2026-08-31 renames the visible Meal
  Reflections destination to `Intakes` / `Ingestas` across onboarding,
  navigation, history, calendar, editor, privacy, export and Settings. The
  existing approved Quiet Linen compositions remain authoritative. Inside the
  approved words card, an inline disclosure reuses the existing secondary
  control and `LinenTextEditor` components to reveal a five-question guided
  intake check-in; it is not a new destination or full-screen composition.
  Journal/template/Library copy is shortened as requested, with no change to
  the approved hierarchy or assets.

## Runtime comparison

Pending. This Windows host cannot run Xcode or an iOS Simulator. Store same-size
captures in `design/runtime/` and add paths here before calling the visual gate
complete.
