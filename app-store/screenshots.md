# Store screenshot plan

The source must be the actual simulator build, never a concept board. The
manual workflow `capture-app-store-screenshots.yml` captures six portrait
screens in English and Spanish in the 6.5-inch iPhone set requested by this
App Store Connect version (1284x2778, with 1242x2688 accepted as a fallback)
and exports opaque JPEG files.

Order for both `en-US` and `es-ES`:

1. Journal home with safe, deterministic sample entries.
2. Template chooser with each template’s purpose summary.
3. Library with private sample notes and its memory-purpose introduction.
4. Intakes introduction and camera/Photos actions.
5. Privacy Notice showing the local-only design.
6. Settings showing language and section controls.

The fixture exists only under `#if DEBUG`, uses production views and does not
enter the App Store binary. Screenshots contain no real user data. Before upload,
compare every image with the current Quiet Linen approvals and verify English,
Spanish, status bar, clipping, Dynamic Type default, absence of permission
dialogs, accepted dimensions, opaque output, and truthful feature depiction.

Apple permits one to ten screenshots. App preview video is optional; do not
create one merely to fill the optional field. A later preview video would need
its own runtime capture, poster frame, localization review, and owner approval.
