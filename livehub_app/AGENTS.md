# LIVEHUB APP GUIDE

## OVERVIEW
`livehub_app` is the active Flutter Windows desktop client. It depends on `../livehub_core`, uses GetX for routing/state wiring, and keeps most tests as package-local unit tests.

## STRUCTURE
```text
livehub_app/
├── lib/app/        # app-wide controllers, constants, style, utilities
├── lib/modules/    # feature pages and controllers
├── lib/services/   # app-side persistence, account, follow, diagnostics
├── lib/routes/     # GetX route table + paths
├── lib/widgets/    # shared UI building blocks
├── test/           # flutter_test unit-style coverage
└── windows/        # desktop shell
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| App startup / service registration | `lib/main.dart` | Window init, Hive, Get.put |
| Global controllers / settings | `lib/app/` | Cross-feature app state |
| Route wiring | `lib/routes/` | GetPage bindings live here |
| Feature work | `lib/modules/` | Most UI/controller changes |
| Shared persistence or integration logic | `lib/services/` | Backup, follow, storage, diagnostics |
| Reusable UI pieces | `lib/widgets/` | Desktop title bar, status widgets, cards |
| Unit tests | `test/` | Mostly utility/service tests |

## CONVENTIONS
- This package is Windows-first even though Flutter remains cross-platform underneath.
- This package owns UI, routing, desktop/window behavior, and app-side persistence glue; site protocol logic belongs in `livehub_core`.
- Tests use `flutter_test`; prefer package-local unit tests around utilities, services, and controller helpers.
- Route additions usually require touching both `lib/routes/route_path.dart` and `lib/routes/app_pages.dart`.
- Shared site behavior is usually bridged through `lib/app/sites.dart` and `livehub_core` contracts.
- Desktop window behavior, ESC handling, title bar logic, and full-screen interactions are centralized rather than scattered across pages.

## ANTI-PATTERNS
- Do not add mobile-only settings or copy that make Windows feel like a phone app.
- Do not duplicate route constants inline; use `RoutePath`.
- Do not put cross-feature state into random feature controllers when it belongs in `lib/app/` or a service.
- Do not treat widget tests and pure Dart tests interchangeably; this package is Flutter-bound.

## NOTES
- `lib/modules/live_room/` has its own local guide; defer to it for room/player-specific constraints.
- Other hotspot areas: `lib/services/` and `lib/app/controller/`.
- `lib/modules/settings/` is product-facing copy-heavy work; keep wording desktop-oriented and explicit.
