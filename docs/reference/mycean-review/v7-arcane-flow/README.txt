Mycean organic arcane spell — 2026-11-01

User finds the former straight laser too simplistic and not magical enough.
Only the procedural visual effect changes. Hero/door images, physical layer,
measured emitter/seal, 450–1500ms channel,1850ms clip and all gameplay stay.

New effect:
- Nine gathering spores orbit the staff cap during charge.
- Two misty intertwined filaments carry19spore motes toward the seal.
- Broken arc rings and six small rune shapes react in the door plane.
- Runes disperse on release, then all effects become silent by1700ms.

scripts/mycean_arcane_spell.gd owns deterministic native drawing and two mesh
instances sharing one static98vertex strip (48segments). Two strips total192
triangles per spell. shaders/mycean_arcane_flow.gdshader bends the static
topology and scrolls procedural mist. It uses explicit phase, never TIME.
No per-frame mesh generation or unbounded particles. Existing light-falloff
texture is reused; no new runtime PNGs or source image edits.

mycean_unlock_stage.gd calls refresh from the same seek/pause/speed clock.
Spell remains beside actor in physical paint order; far-side rays stay hidden
by near stone and closed panel. Layout includes22pxsource and42pxseal supports.
Shader displacement also updates ArrayMesh.custom_aabb with28pxpadding; see
https://docs.godotengine.org/en/stable/classes/class_arraymesh.html#class-arraymesh-property-custom-aabb
Without this, translating the unit mesh offscreen incorrectly culled the
visible displaced filaments. Native translated-image regression failed first,
then passed after explicit support registration.

Independent review found a one-frame gap exactly1500ms: channel was false and
release progression was0, so the seal reaction skipped that frame. A separate
releasing flag now makes the release interval inclusive at its start and
exclusive at1700ms. Target-region alpha regression failed then passed.

Evidence: tools/verify_mycean_spell.gd (23native checks), and the existing
tools/verify_mycean_unlock.gd (738native checks). Import and both suites pass,
stderr empty. First old-effect regression measured0off-axis pixels; new effect
has a visible non-linear volume. Pixel tests also cover same-time deterministic
seeking, frozen paused phase, evolving held pose, dormant/final silence and
finite padded rendering. Evidence is artifacts/mycean-unlock/spell/ and native/.
Desktop/portrait/short-landscape captures inspected. No physical-phone profile.

Reproduce from repository root with Godot4.7.2 and Node/sharp:
  Godot --path . --script tools/verify_mycean_spell.gd
  Godot --path . --script tools/verify_mycean_unlock.gd
  node docs/reference/mycean-review/v7-arcane-flow/assemble_review.cjs
On Windows, use Start-Process -WindowStyle Hidden -Wait for Godot and run
graphical processes sequentially. NODE_PATH and executable paths are documented
in ../v6-arcane-door/README.txt. assemble_review builds normal/slow native WebPs
from49actual screenshots. Native replay movies include a final1second pause.

previous-stage.gd and previous.webp retain the former simple effect for
comparison. Source model/sprite recipe remains in ../v6-arcane-door; its
historical page/images remain unchanged. Preview only; no raid/save/APK,
commit or push. Polished procedural effect, not newly painted spell sprites.
