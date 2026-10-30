# Living master eye

Implements the seven reactions/gaze behaviors specified on page 14 of the user's mobile v2 PDF. Later-approved C masonry, ten HP runes, v15 typography/icons and violet gauges remain current. Current circular iris is retained rather than restoring the rejected vortex-looking pupil. No new runtime bitmap or atlas: the shader animates the existing central PNG.

## Runtime
- `master_eye_behavior.gd`: presentation clock, deterministic 6–10s idle blink, smoothed gaze and state transitions. Damage > kill > theft > poverty; transient reactions expire. Loading takes a baseline; reset clears prior reactions. Does not consume gameplay RNG.
- `hud_master_header.gd`: passive pointer/touch observer, bounded viewport-to-eye gaze, multi-touch cancellation, resize/focus/app-background cancellation. Pause freezes. Reactions may finish behind the result sheet. Zero health closes/dims the iris, while runes still reflect actual HP.
- `game_hud.gd`: uses the existing interpolated actor anchor; converts through the world SubViewport container and HUD canvas, so panning and orientation remain correct. Construction uses selected cell or recent pointer; tracking ignores pointer during raid.
- `game_session.gd`: optional presentation events for successful pose and rejected purchase. Fixed-cost catalogue objects can react on selection. Digging/clearing, repairs and vault upgrades wait for actual cell affordability: a funded isolated dry run distinguishes insufficient funds from invalid geometry, levels or full health. No economy/saving/simulation timing changed.
- Counters from actual raid actions trigger hurt/theft/kill, including the synchronous result that clears the hero. No trap-disarm action exists in the current simulation: consuming a trap charge must not be mislabeled as disarming it.
- `master_eye.gdshader`: bounded inner-eye displacement, pupil scale, curved lids, tint, pulse and small internal shudder. Rune annulus and housing stay fixed. No rotating health ring or shaking numeric labels. This deliberately adapts the old PDF's whole-lintel shake to the compact approved header.

## Review and reproduction
Open `scenes/MasterEyePreview.tscn` and F6: choose seven states, replay, pause, change HP, move pointer/touch. Traque follows its moving diamond target. This is an isolated no-save scene, not a second gameplay implementation. Finite reactions return to rest; replay repeats them.

Run native graphical Godot with `--path . --script res://tools/capture_master_eye.gd`, then `node tools/prepare_eye_review.cjs` with bundled sharp available. Outputs in `native/`, review-only WebPs and `media.json`; raw frames stay in ignored `artifacts/master-eye/`. `index.html` plays native recordings, not a JavaScript imitation of the shader. Tests explicitly simulate focus in offscreen fixtures because the real eye correctly freezes when the app loses focus.

Checks:
- `tools/verify_master_eye.gd`: real action feedback, finite reactions and priorities, actual vault withdrawal/core damage/kill producers, reset, no RNG consumption, blink timing, free clearing and discounted upgrade cases.
- `tools/capture_master_eye.gd`: native expression pixels preserve outer eye/stone/runes/lip, touch vs raid target, multitouch, focus loss, five preview sizes.
- `tools/verify_master_eye_world.gd`: actual actor targeting across five sizes and both camera offsets, rotation during held touch, real world pan, eye click pauses without construction.
- Existing header/rune, mobile layout/rotation/interaction checks and headless gameplay probes remain applicable.

Independent review found and reproduced catalogue contextual-price false positives and stale touch after rotation. Both received failing regression cases before correction. Unchanged player saves, no Android package, no commit/push. Desktop native verification does not prove phone GPU/touch/DPI performance or artistic approval of every expression.
