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
| 04 | Library empty; Library populated/hidden previews; New Note; Organize; Collections; Edit Collection | `design/approved/ui-04-library-notes-organize.png` | `58580B82DF523B0CC40573B96D83246EC2884B27E32851CE46F83B0FB36BC698` | Current visual language; v0.4 dismissible introduction below |
| 05 | Video permission primer; video ready; video recording; review/save video; audio primer; audio recording/review | `design/approved/ui-05-video-audio-create.png` | `7F61B655D21496228A96850EAA2D42F49D107CBDEC8CFDDB01F12FB47C9ACDD1` | Current |
| 06 | Video detail; audio detail; Library search; tags; permission denial; storage/interruption error | `design/approved/ui-06-media-search-errors.png` | `2A50800B3193D53014BFCF7CCCAD789FD19152EDC692D97A3BCA5F7CC882996F` | Current |
| 07 | Settings; Privacy & Lock; media permissions; storage; export selection; export warning/success | `design/approved/ui-07-settings-export.png` | `B44BBADE22225DF56477D2364CAD8546A492A32E6E2F102FC959E2E3BD8F7AC6` | Current visual language; v0.4 Settings additions below; storage values are illustrative only |
| 08 | Locked; delete item; erase all; Help & Safety; optional support; Privacy Notice | `design/approved/ui-08-lock-delete-help.png` | `69AFFF70B5B28324743F5B1C06C1096D80B5389ED7C4DBEF2F5F2B5BF29BD345` | Current; clinical/crisis copy still requires specialist review |

## Owner-requested and safety corrections

- Root navigation is `Journal`, `Library`, `Settings`. Home is the Journal.
- `View Journal History` is the explicit path back to previous entries.
- Library contains private Notes, Videos, and Audio; it is separate from Journal.
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

## Runtime comparison

Pending. This Windows host cannot run Xcode or an iOS Simulator. Store same-size
captures in `design/runtime/` and add paths here before calling the visual gate
complete.
