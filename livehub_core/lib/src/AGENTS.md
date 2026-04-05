# CORE SRC GUIDE

## OVERVIEW
`lib/src` is the implementation heart of `livehub_core`: site adapters, danmaku handlers, shared contracts, models, and low-level helpers live here.

## STRUCTURE
```text
src/
├── *_site.dart     # per-platform room/detail/search adapters
├── common/         # logging, HTTP, websocket, conversion helpers
├── danmaku/        # per-platform danmaku handlers + generated proto
├── interface/      # shared abstractions
├── model/          # shared DTOs
└── scripts/        # sign / helper logic for specific platforms
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Shared transport/logging behavior | `common/` | Affects all platforms |
| Contract changes | `interface/` | Breaks all implementations if wrong |
| Data shape changes | `model/` | App-facing payload contract |
| Platform-specific room logic | `*_site.dart` | One file per site |
| Danmaku protocol handling | `danmaku/` | Includes generated proto baggage |
| Signing scripts | `scripts/` | Platform-specific helper code |

## CONVENTIONS
- Prefer extending shared models/interfaces over inventing site-private app-facing structures.
- Keep cross-site utilities in `common/`, not copied into each `*_site.dart`.
- Generated proto outputs inside `danmaku/proto/` are not hand-crafted style exemplars.
- Site adapters should keep platform quirks localized while still returning normalized shared models.

## ANTI-PATTERNS
- Do not mix generated proto cleanup with business logic changes in one pass.
- Do not leak script/signing internals into shared model or interface layers.
- Do not spread HTTP/header fallback logic across multiple layers if one adapter owns it.

## NOTES
- `bilibili_site.dart` is historically a hotspot because it carries the most fallback logic.
- `common/` and `interface/` changes have wide blast radius; verify dependents carefully.
