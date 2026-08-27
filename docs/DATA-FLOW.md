# Release data-flow inventory — source candidate 0.3 (1)

| Data | Source | Storage | Transmission | Retention/control | Recipient |
|---|---|---|---|---|---|
| Journal text and template answers | User typing | AES-GCM encrypted local vault; complete file protection; excluded from backup | None unless explicit export | Until item/all-data deletion or app removal | User-selected export destination only |
| Library note text and metadata | User typing/organization | Same encrypted vault | None unless explicit export | Same | User-selected export destination only |
| Video | Camera + microphone after just-in-time permission | AES-GCM encrypted local media file; protected temp only for playback/export | None unless explicit export | Until item/all-data deletion or app removal | User-selected export destination only |
| Audio | Microphone after just-in-time permission | Same as video | None unless explicit export | Same | User-selected export destination only |
| Search terms | User typing | In memory only; no persisted query history | None | Cleared with UI/process | None |
| App preferences | User controls | AES-GCM encrypted local preferences | None | Until reset/app removal | None |
| Optional trusted contact | User types a name and phone number; no Contacts access | AES-GCM encrypted local preferences | Recipient and localized preset text are passed to Apple’s Messages composer only after explicit tap | Until contact removal, erase-all, or app removal | User-selected contact through Apple Messages |
| Authentication | Face ID/Touch ID/passcode through iOS | App stores only enabled/delay preference | No biometric data received | iOS-controlled | Apple OS only |
| Optional support transaction | StoreKit; feature flag off in 0.3 | Transaction state only when activated | Apple StoreKit | Apple policy | Apple |
| Help links/calls | Explicit tap; resources selected from iPhone region | Not stored by Gentle Note | Destination receives normal request/phone metadata, never journal content | Destination policy | Spain: 112/024/Ministry of Health; US: 911/988/support websites |

No account, developer backend, CloudKit, iCloud Documents, HealthKit, Photos,
Contacts, Location, advertising, analytics, crash SDK, attribution, push,
tracking, AI, social/community, or third-party runtime SDK exists.

Before release, verify this table against the exact archive, network traffic,
backup/restore behavior, privacy manifest, and App Privacy questionnaire.
