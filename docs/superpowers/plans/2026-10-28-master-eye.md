# Living master eye implementation plan

> Execute inline using superpowers:executing-plans. User requests the missing eye tracking and variants; approved C housing and v15 insignia stay in place. No extra approval, commit/push or APK.

**Goal:** Implement the seven expressive eye states and contextual gaze from page 14 of the user-supplied mobile v2 PDF.

**Architecture:** A presentation-only controller owns smooth gaze, reaction priorities and blink timing. Header supplies screen targets and real session observations; a bounded shader animates only the inner eye, independently of the ten HP runes. Explicit action feedback distinguishes rejected purchases from normal spending. No simulation timing or economy changes.

**Tech stack:** Godot 4.7, GDScript, existing PNG, canvas shader. No additional bitmap dependency.

**Spec:** `.codex-remote-attachments/01a15ce9-67f0-77e2-a485-14b09d65f5da/6bd9caee-bd59-49f9-b8ba-d67e5acb5e6b/1-Dungeon-Empire-refonte-mobile-v2.pdf`, page 14, plus later approved C masonry/runes and radial iris (not spiral).

## Decisions and constraints
- Veille: follow recent pointer/touch, delayed motion, 6–10s blink; return to rest after release. Observe: selected cell then current gesture/catalog item. Traque: rendered hero position, ignores pointer.
- Jubile: kill, amber iris/dilated pupil/one glow pulse. Blessé: actual HP loss, red squint/brief inner shake. Fauché: explicit unaffordable attempt, desaturated constricted eye looking at gold. Colère: actual theft, magenta constriction/shudder. No trap-disarm mechanic exists today; do not mislabel normal trap activation as disarm.
- Later C visual approval supersedes old PDF iron rails and spinning pupil. Move/deform the iris inside its socket; preserve the stationary circular pupil character, rune identities and rune mask. Keep tremble inside the eye so numbers/readability remain stable.
- Single current hero is the raid target. Use existing rendered actor position (including travel interpolation), converted through world viewport and HUD transforms.
- Pure cosmetic controller, local deterministic blink schedule (do not consume gameplay RNG). Pause freezes it. Result reactions may finish behind the result panel; defeat settles closed/dim. Restart clears stale events and pointers.
- Passive input listener, never accepts/consumes events; mobile touch takes priority over synthesized mouse. Clear on multitouch/focus loss; UI state cannot spend gold or advance gameplay.

## Review focus
1. Real input/viewport scaling, panning/rotation and no pointer capture or duplicate clicks.
2. Priority and finite lifetime: damage wins over kill/theft; no repeated replay on refresh, reset or loading baseline.
3. Rune/stone pixels stay unchanged by expressions and tracking; no eye leaks outside socket.
4. Poor state only on attempted spending, not ordinary low gold, invalid placement, spending or repairs.
5. Current native layout, interaction and probe checks stay green; never read player saves.

## Tasks
- [x] Add failing native behavioral tests and preserve baseline evidence.
- [x] Implement controller/shader/target projection and real action feedback.
- [x] Add isolated interactive native review scene, seven states and real-size/detailed eye.
- [x] Verify native event flows, inputs, state lifetime, pixels, layouts; inspect captured states/mobile screens.
- [x] Fresh independent code review, document results/limits and show review.

## Execution ledger
- Baseline fails because no expressive controller exists (`artifacts/master-eye/red.*`). Current native behavior29 checks, pixel/input10, real game/viewport34, existing header856, rotation227 and mobile interaction fixture all pass with empty stderr. Five headless simulation recipes pass. Shader colors/lids inspected at detailed and actual phone-size layouts.
- Reviewer independently reproduced false poverty for free DIG clearing and discounted vault upgrade, plus held gaze surviving rotation. Regression cases failed first, then passed. Selection-time feedback now uses only fixed-cost tools; contextual commands use actual funded-copy validation. Header clears touch state on window resize, focus loss and application pause.
- Review captures explicitly simulate focus in hidden windows. The actual app correctly freezes when backgrounded; no changes to production focus handling were needed to make hidden-window capture deterministic.
- No trap disarm mechanic is present. Colère currently reacts to actual stolen-gold counters only. No invented disarm events, new runtime images, player-save access, Android build, commit or push.
