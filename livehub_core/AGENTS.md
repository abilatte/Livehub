# LIVEHUB CORE GUIDE

## OVERVIEW
`livehub_core` is the pure Dart aggregation layer for platform room data, play URLs, danmaku, shared models, and protocol helpers. The app imports this package rather than duplicating site logic.

## STRUCTURE
```text
livehub_core/
├── lib/livehub_core.dart  # public export surface
├── lib/src/                   # site adapters, models, common utils, danmaku
├── packages/tars_dart/        # embedded protocol subpackage
├── test/                      # pure Dart tests / live API checks
└── example/, demo/            # package-local extras
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Public API surface | `lib/livehub_core.dart` | Export contract for consumers |
| Site-specific implementations | `lib/src/*_site.dart` | Bilibili/Douyu/Huya/Douyin |
| Shared contracts | `lib/src/interface/` | `LiveSite`, `LiveDanmaku` |
| Shared models | `lib/src/model/` | Cross-site data shapes |
| Common utilities | `lib/src/common/` | HTTP, logging, websocket helpers |
| Embedded protocol code | `packages/tars_dart/` | Minimize scope of edits |
| Core tests | `test/` | Uses pure Dart `test` package |

## CONVENTIONS
- Keep app concerns out of this package; it should stay consumable as a core library.
- This package owns site adapters, normalized cross-site models, danmaku/protocol handling, and network-facing core logic; app UI and route behavior belong in `livehub_app`.
- New site behavior should conform to shared interfaces and models before app integration.
- Tests here use `package:test`, not `flutter_test`.
- Some tests exercise live platform APIs; avoid brittle assumptions about external service stability.
- `packages/tars_dart` is an embedded dependency boundary, not ordinary app code.

## ANTI-PATTERNS
- Do not import Flutter UI concepts into core.
- Do not bypass shared models/contracts for one-off site return types unless the user explicitly wants a redesign.
- Do not casually refactor `packages/tars_dart`; keep vendor-like changes minimal and well-justified.
- Do not assume failures in core tests are always local bugs; some tests touch live upstream behavior.

## NOTES
- `lib/src/` contains most implementation rules and has its own local guide; defer there for internal folder-level conventions.
- `livehub_core.dart` is the clearest place to verify what the app is expected to consume.
