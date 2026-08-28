# Release data-flow inventory — source candidate 0.7.1 (1)

| Data | Source | Storage | Transmission | Retention/control | Recipient |
|---|---|---|---|---|---|
| Journal text and template answers | User typing | AES-GCM encrypted local vault; complete file protection; excluded from backup | None unless explicit export | Until item/all-data deletion or app removal | User-selected export destination only |
| Library note text and metadata | User typing/organization | Same encrypted vault | None unless explicit export | Same | User-selected export destination only |
| Meal Reflection date, optional moment label, and text | User choice/typing; date defaults to the current moment and remains editable | AES-GCM encrypted local vault | None unless explicit export | Until reflection/all-data deletion or app removal; hiding the section does not delete it | User-selected export destination only |
| Meal Reflection main photo and optional additional images | Camera after just-in-time permission, or iOS system photo picker; only chosen items transfer | Separate AES-GCM encrypted local media files; protected temporary copies only for display/export | None unless explicit export | Until reflection/all-data deletion or app removal | User-selected export destination only |
| Meal Reflection optional audio/video attachments | In-app recording after just-in-time permission, or user-chosen audio/video | Separate AES-GCM encrypted local media files; protected temporary copies only for playback/export | None unless explicit export | Until reflection/all-data deletion or app removal | User-selected export destination only |
| Image | Camera after just-in-time permission, or iOS system photo picker; only the chosen item is transferred | AES-GCM encrypted local media file; protected temp only for viewing/export | None unless explicit export | Until item/all-data deletion or app removal | User-selected export destination only |
| Video | Camera + microphone after just-in-time permission, or iOS system photo picker | AES-GCM encrypted local media file; protected temp only for playback/export | None unless explicit export | Until item/all-data deletion or app removal | User-selected export destination only |
| Audio | Microphone after just-in-time permission, or a user-chosen file from the iOS document picker | Same as video | None unless explicit export | Same | User-selected export destination only |
| Search terms | User typing | In memory only; no persisted query history | None | Cleared with UI/process | None |
| App preferences, including language, Library introduction, Meal Reflections visibility, and reflection-preview visibility | User controls | AES-GCM encrypted local preferences | None | Until reset/app removal; language is retained through erase-all so the completion UI remains understandable | None |
| Optional trusted contact | User types a name and phone number; no Contacts access | AES-GCM encrypted local preferences | Recipient and localized preset text are passed to Apple’s Messages composer only after explicit tap | Until contact removal, erase-all, or app removal | User-selected contact through Apple Messages |
| Authentication | Face ID/Touch ID/passcode through iOS | App stores only enabled/delay preference | No biometric data received | iOS-controlled | Apple OS only |
| Optional support transaction | StoreKit; feature flag off in 0.7.1 | Transaction state only when activated | Apple StoreKit | Apple policy | Apple |
| Help links/calls | Explicit tap; resources selected from iPhone region | Not stored by Gentle Note | Destination receives normal request/phone metadata, never journal content | Destination policy | Spain: 112/024/Ministry of Health; US: 911/988/support websites |

No account, developer backend, CloudKit, iCloud Documents, HealthKit, Photos,
Contacts, Location, advertising, analytics, crash SDK, attribution, push,
tracking, AI, social/community, or third-party runtime SDK exists.

Before release, verify this table against the exact archive, network traffic,
backup/restore behavior, privacy manifest, and App Privacy questionnaire.
