# LIVE ROOM MODULE GUIDE

## OVERVIEW
`live_room` is the densest app feature area: room page layout, controller state, player integration, history/follow side panels, SC handling, and several utility modules all converge here.

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Main feature orchestration | `live_room_controller.dart` | Room state, tab behavior, lifecycle |
| Page layout | `live_room_page.dart` | Desktop room UI composition |
| Player internals | `player/` | Full-screen, controls, playback UX |
| Follow/history panel behavior | `follow_history_panel.dart` + tab utils | Right-side supporting views |
| SC behavior | `super_chat_utils.dart` + widgets in app | Shared countdown/retention logic |
| Utility-only behavior | `*_utils.dart` | Preferred place for testable pure logic |

## CONVENTIONS
- Keep feature-specific pure logic in focused `*_utils.dart` files when practical; tests already follow that pattern.
- Treat `player/` as part of the same feature boundary, not a separate package.
- Preserve Windows desktop layout assumptions: left video, right sidebar, desktop full-screen and ESC behavior.
- Cross-platform tab mismatches and Bilibili-specific room behavior already have dedicated utility coverage; extend those patterns instead of inlining ad hoc fixes.

## ANTI-PATTERNS
- Do not do broad right-sidebar rewrites unless the user explicitly asks.
- Do not scatter full-screen escape / back-button behavior outside the existing controller-shell-player path.
- Do not bury new room-specific state in generic app services if it only matters inside live room.
- Do not skip utility tests when touching countdown, layout threshold, sidebar mapping, or room metrics logic.

## NOTES
- `player_controls.dart` and `player_controller.dart` are large hotspots; prefer surgical edits.
- This module has the strongest desktop UX constraints in the app.
