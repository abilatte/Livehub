# TARS_DART SUBPACKAGE GUIDE

## OVERVIEW
`tars_dart` is an embedded subpackage fork used by `livehub_core` for Tars RPC/protocol support. Treat it as vendor-like code with a narrow local maintenance surface.

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Package metadata | `pubspec.yaml` | Dependency + SDK bounds |
| Main implementation | `lib/tars/` | Codec, net, and TUP helpers |
| Stream/codecs | `lib/tars/codec/` | Serialization primitives |
| TUP utilities | `lib/tars/tup/` | Heaviest local logic |
| Package notes | `README.md`, `CHANGELOG.md` | Fork provenance is minimal |

## CONVENTIONS
- Keep edits minimal and scoped to confirmed protocol needs.
- Preserve package-level isolation: changes here should not depend on app-layer code.
- Follow the existing folder split (`codec/`, `net/`, `tup/`) instead of flattening.

## ANTI-PATTERNS
- Do not refactor this package just to match surrounding app style.
- Do not mix unrelated cleanup with protocol bug fixes.
- Do not move code out of this subpackage into core unless the dependency boundary is intentionally being redesigned.

## NOTES
- This folder behaves more like an embedded library than a normal feature module.
- If a change is not clearly required by current protocol behavior, prefer leaving this package untouched.
