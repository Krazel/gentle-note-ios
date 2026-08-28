# Quiet Linen asset inventory

The implementation uses only reproducible, code-native assets so private
journal content never depends on a remote asset service.

| Asset | Source | Use |
|---|---|---|
| Warm ivory paper field | `PaperBackground` in `DesignSystem.swift` | Every app surface |
| Fine paper grain | deterministic Canvas strokes in `PaperBackground` | Subtle material depth |
| Botanical sprig | `BotanicalSprig` SwiftUI Shape | Headers and empty states |
| Leaf, lock, media and navigation marks | SF Symbols with explicit labels | Controls and status |
| Forest/sage/clay palette | `QuietLinen` color tokens | Hierarchy and semantic states |
| Editorial headings | New York system serif | Headings without font download |
| Body and controls | San Francisco system font | Legibility and Dynamic Type |
| App icon | Not final | Requires a separate visual approval before release |
| Reflections photo-frame mark | SF Symbols `photo` plus code-native `BotanicalSprig` composition | Independent Reflections navigation and headers |
| Calendar indicators | Quiet Linen clay dots and sage selection drawn with SwiftUI | Saved-reflection dates without photo comparison or progress semantics |
| Meal-moment chips | Native buttons using Quiet Linen line/clay states | Optional Breakfast/Morning snack/Lunch/Afternoon snack/Dinner label |
| Reflection layer rows | SF Symbols, native controls and LinenCard surfaces | Text, multiple audio/video attachments and additional images |
| First-run overview cards | Native `LinenCard` surfaces with `book.closed`, `books.vertical`, and `fork.knife` SF Symbols | Journal, Library, and optional Meal Reflections explanation and visibility control |

No image, font, analytics, ad, or UI dependency is fetched at runtime.
