# Repository instructions

## Shared painted stone menus — 2026-10-30

- User approves v18 radial direction and requests matching menus. v19 integrates
  shared slate/violet painted surfaces in radial, catalog, selection/transfer,
  pause/results, placement notices and utility buttons. Keep English copy,
  native icons/live prices, existing padding/geometry and central Close.
- Three ImageGen native-alpha sources/prompts retained. prepare_stone_ui.cjs
  makes4 cropped/uniformly reduced PNGs:359859bytes,0.75MiB RGBA. No painting
  by script. Horizontal button art avoids stretching square facets into grain.
  docs/.gdignore excludes source/review assets from export; runtime art shared.
- Variable radial sectors use quiet stone faces and narrow painted rims;
  inset price sockets turn violet. Before11 pixel failures, after1594 checks
  pass. Native mobile interactions, rotation227 and header health32 pass;
  import/fixtures exit0 with empty stderr. No player saves or APK.
- capture_master_mobile now disables persistence before tree entry, accepts
  --output and defaults to ignored artifacts.133 states/7sizes have no clipped
  nonwrapping labels; small portrait/landscape menus inspected. Review found no
  actionable regression. Native before/after: interface-review/v19-stone-menus.
  No physical-phone profiling, commit or push.

## Radial centre closes the menu — 2026-10-30

- User requests Close at the centre instead of All. Keep the circular hit
  area, replace the catalog icon with the existing cross, remove the external
  close button and centre the caption in its freed space. The full catalog
  remains available from the regular HUD button after closing the radial.
- Existing native fixture now verifies centre mouse/touch dismissal, cleared
  selection and no purchase/tool activation. Before2 failures, after1594
  checks/0 failures across11 sizes; empty stderr. Small portrait and landscape
  captures inspected in artifacts/radial-review. No APK, commit or push.

## English player-facing language — 2026-10-30

- User requests English instead of French. Runtime HUD, catalog, radial,
  selection/transfer/repair, notices/errors, raid results, hero/world labels
  and native preview scenes now use English. Keep Core, Vulpin, Snare, Void,
  Arcane door, gold, HP and Lv. terminology consistent. Internal eye state IDs,
  gameplay constants and save schema are unchanged. Historical review pages
  and production documentation retain their original language.
- Removed the French display adapter; simulator/session notices are English
  at their source and saves do not persist those messages. Radial fallback
  prices now parse gold/Free/Varies; three regression cases cover rejected
  priced/free/variable actions. Updated active capture fixtures and assertions.
- All7 headless scenarios pass. Native radial1592, rotation227, door badges87,
  header856, health32, joins40 and mobile interactions pass/empty stderr.
  Captured95 native UI states at5 sizes with no clipped nonwrapping labels;
  small portrait catalog/transfer and short landscape menu inspected. Evidence
  in artifacts/english-ui. No player saves, APK, commit or push.
- Updated only the8 translated preview entries in the hero preservation
  manifest. Its2 documentation hash mismatches already exist in HEAD and
  are recorded in artifacts/english-ui/preservation-audit.json; art/source
  hashes are unchanged.

## Header stone joins no longer expose a vertical slit — 2026-10-30

- User sees a vertical line beside the eye. Native transparent-background
  captures reproduce10 failures across20 size/scale combinations: the source
  stone is opaque, but independently snapped Control origins expose a pixel
  between the scaled wing and center. Both wings now extend1 layout unit under
  the central slice; eye aspect, artwork, labels, gauges and outer width stay.
- tools/verify_header_seams.gd checks both joins:40 pass after the fix. Existing
  header856/health32/gauges40 checks pass with empty stderr. Five native sizes
  captured; desktop, portrait and short landscape inspected. Evidence in
  artifacts/header-seams. No player saves, new art, APK, commit or push.

## Commit validation for accumulated UI and Vulpin work — 2026-10-30

- User requests commit/push of current work. Fresh import and all7 headless
  scenarios pass; probe API68, Vulpin367/retreat12/recoil39/stairs1787/traps160,
  header856/health32/gauges40/radial1589/eye29/eye-world34/rotation227 and mobile
  interaction checks pass with empty stderr. No APK or player-save access.
- Run graphical fixture processes sequentially on Windows: simultaneous
  windows triggered the normal focus-loss pause during the radial pixel check
  (667x375 screenshot showed the pause panel). Serial rerun passed unchanged.
  Logs are in ignored artifacts/commit-validation; no runtime workaround added.

## Vulpin remains still throughout trap recoil — 2026-10-28

- User sees damage pose travelling off a trap. Passive probes reproduce four
  failures: spikes resume after17ms at1x/33ms at2x while the clip lasts720ms.
- Surviving thief hits record hurt_started_at in RaidDirector and clamp move_cd
  to at least GameTypes.VULPIN_HURT_HOLD=.72. Native actor uses that timestamp,
  including fresh reconstruction and the first2x substep, plus shared duration.
  Snare's3s includes recoil rather than adding it. Lethal/void/spent/repeated
  traps bypass the new hold; existing death/charge/once-per-raid rules preserved.
- verify_vulpin_trap_reaction:29 headless probe checks,39 native checks pass;
  tests/scenarios/trap-recoil.json observes fixed tile, pause, resumed motion
  and full raid. All7 probe recipes,367 Vulpin and160 trap checks pass/empty
  stderr. Native hit/recovery captures inspected; focused review no finding.
- Documentation updated. No new art, player-save access, APK, commit or push;
  no physical-phone validation.

## Vulpin follows staircase height on entry and exit — 2026-10-28

- User sees hero flicker through stairs. Actor formerly stayed at z0 and could
  sort behind the merged treads. stair_traversal.gd samples the actual five-step
  geometry in four mouth orientations, smooths only risers, raises root/support/
  contact shadow and explicitly sorts supporting treads behind the actor.
- Raid starts with entering/enter_t for TURN_TIME before exploration. Existing
  exit_arrival_t/exiting/exit_t preserve full return/ascent before removal. Fade
  confined by distance to .1064 case near the top. Whole-character art unchanged.
- Review reproduced adjacent-door failed-pick retreat snap (~89.6 native px):
  preserve the held contact as ascent start, keep fade near top on longer path.
  Four red failures then green. Native full fixture1787 checks/0 failures;
  gameplay367/retreat12 and six headless probe scenarios pass, empty stderr.
- stair-traversal.json observes timed phases/position/pause/complete departure.
  Probe equality now compares nested JSON numeric values without confusing int
  coordinates with floats; strict string/bool distinctions retained, API68pass.
  No unresolved focused review finding. Not independent foot IK/new climbing
  sprites or phone validation. No player saves, APK, commit or push.

## Heart percentage fits the carved header lip — 2026-10-28

- User reports100% outside its painted area. Header-wide label checks missed
  the issue: actual glyph ink began above the lip. Layout now uses the interior
  of the prepared230x192 centre slice (x76,y166,w78,h18), font12/10 for96/84-high
  headers, with a one-unit optical correction at96. Remove only health outline/
  shadow; keep full percentage, font family, stone and rune artwork unchanged.
- No-save GPU verify_header_health:16 overflowing cases reproduced, then32checks
  pass for100/60/9/0 at four sizes. Bounds use actual rendered alpha, not just the
  Label rectangle.856 existing header and1589 radial checks pass/empty stderr.
  v17 review captures refreshed. No phone test, APK, commit or push.

## Build radial restores the approved size and outer price strip — 2026-10-28

- User reports tiny radial and costs unlike mobile-v2 PDF. Preferred diameter
  252→352 units; fixed family directions, aspect-preserved larger icons, separate
  24-unit outer price band (20 on shortest screens),16/14pt prices. Valid hovered
  or pressed cost band turns gold and shares the action's hit region. Real game
  costs retained; no invented PDF traps/prices. Tout has centred catalogue icon.
- Fit evaluates footer/side-help at each radius; native480×320 regression caught
  by review is fixed. HUD pan uses dynamic menu_center. RoundButton._has_point
  excludes its square corners from family sectors; four viewport failures were
  reproduced then fixed. Direct ScreenTouch/Drag now works; synthetic mouse is
  ignored, out-and-back drag cannot purchase. Cancel/rotation/multitouch preserved.
- No-save verify_build_radial:1589 checks/0failures,11sizes, native viewport touch
  purchase, live price agreement, outer-rim pixels, four world corners/camera fit.
  Master mobile fixture and227rotation checks pass; stderr empty. Focused review
  findings resolved. Native captures in interface-review/v17-radial-prices.
  No player saves, runtime artwork, APK, commit or push; physical phone untested.

## Vulpin stops revisiting an unreachable locked route — 2026-10-28

- User sees repeated stairs/door trips for over30s. Passive probes reproduce
  after a failed pick:35s active,65state changes, fleeing=false. Not an animation
  reversal. _choose_next_step tested whether goals/frontiers existed, not whether
  any route to them survived avoided_doors, then fell back to revisiting cells.
- A thief now retreats after both goal and frontier path searches fail. Reachable
  alternate paths are tried first; authorised lockpick retries remain intact.
  Already at the entrance, the no-route branch invokes normal timed departure
  instead of aborting the raid. Other classes keep their revisit behaviour.
- New no-save tools/verify_vulpin_retreat.gd:12checks, red5failures→green0,
  actual failed pick, level3retries, success/theft, alternative frontier/treasure
  route, and already-at-entrance case. Single failed-door raid now ends at5.067s
  (includes3.033s attempt); two attempts at8.1s. Snapshots in artifacts/vulpin-retreat.
- Five probe recipes and20seeded complete raids pass; native Vulpin367checks
  still pass/empty stderr. Focused independent review found no important issue.
  No player-save access, artwork/animation edits, APK, commit or push.

## Vulpin sprites connected to actual raids — 2026-10-28

- User still sees the orange Rusk pawn after Vulpin-only filtering. Rusk is a
  thief name; filter was correct but gameplay unconditionally created Marker.
  isometric_game_view now uses vulpin_actor for thief, reusing all approved
  whole-mesh SpriteFrames directly. No image edits/duplication or new art.
- Idle/walk15fps/run16fps/hurt720ms/door and chest picking/collect/death550ms
  follow real raid state/time, including pause/2x. Actor retained across door/
  chest rebuilds; original .85 scale and anchors. Contact calibration and pose
  bounds packed by prepare_vulpin_gameplay.gd into native registration.tres;
  exports require no reference docs/JSON. No AI, speed, action timer changes.
- Corpses retain optional kind/facing and show final fox pose; save validator
  accepts old three-field corpses. Missing historical class keeps old marker.
  All fixtures persistence_enabled=false before tree entry; no player saves.
- Fresh review reproduced legal adjacent chests putting feet into rock. Final
  fallback constrains the pose envelope to the chest's walkable cell when no
  accessible front exists; hands/lock remain approximate in that dense case.
  Red3failures to green, actual raid reproduction now stays in VAULT cell.
- verify_vulpin_gameplay:367checks/0failures, real seed21 raid visits six states,
  all four facings, every walk/run center-arch pose, contacts, pause/rate, rebuild,
  save compatibility, corpse and mobile rotation. Native captures inspected.
  Five probe recipes, trap160/open-door84/eye-world34/probeAPI63 pass; import
  clean. Eye/open-door headless attempts timed out awaiting GPU, graphical
  reruns passed. No further important review finding. Hurt/death bounds remain
  approximate; perfect foot locking, arbitrary collision and phone performance
  unproven. No APK, commit or push. See docs/production/vulpin-gameplay.md.

## Temporarily restrict raids to the Vulpin — 2026-10-28

- User requests Vulpin-only raids until other hero sprites are ready. Enable
  the existing testing/vulpin_only=true in project.godot. RaidDirector already
  applies it to recruits and HeroRoster to returning profiles; keep saved
  non-Vulpin profiles intact. Set false later to restore all four classes.
- Existing5probe scenarios pass;10complete raids (seeds1–10) all spawn thief,
  confirmed from probes. Reports artifacts/vulpin-only. No new gameplay logic,
  player-save access, APK, commit or push. Restart a running game to reload setting.

## Used traps stay visually triggered through the raid — 2026-10-28

- User reports spikes returning to ready despite once-per-raid activation.
  Cause: visual state depended only on the short VFX clock (.65s for spikes),
  while RaidDirector already retained hero.triggered_traps and blocked reuse.
  _trap_state now reads that same authoritative ledger while raid_active.
  Applies to spike/snare/void, including zero charges; no gameplay rule change.
- Keep bounded presentation cache for final lethal hit/results. Expiring it or
  rebuilding the renderer cannot re-arm a trap during the raid. Next raid uses
  the fresh hero ledger: remaining charges => ready; no charges => spent.
- verify_trap_raid_state.gd:160native checks,0failures, empty stderr; real trap
  activation,30s expiry, layer IDs, cache loss/rebuild, pause, repeat activation,
  next preparation/raid and reset. Native spike/snare/void captures inspected.
  Existing painted-trap harness11records and5headless gameplay recipes pass.
  Evidence artifacts/trap-raid-state. No player-save access, APK, commit/push.

## Living header eye and seven contextual states — 2026-10-28

- User accepts v15 insignia and requests missing eye tracking/variants. v16-living-eye
  implements PDF page14: veille/observe/traque/jubile/blessé/fauché/colère on current
  C art, with smooth pointer/touch or actual rendered-hero tracking. Existing ten
  clockwise HP runes and stone remain fixed. Inner pupil/lids/tint/pulse/shudder
  are shader effects, no new runtime PNGs. Current radial iris stays an eye.
- master_eye_behavior.gd owns deterministic cosmetic clock,6–10s blink, finite
  prioritized reactions. Does not use gameplay RNG. Pause/focus loss freeze;
  results let kill reaction finish. Reset clears old snapshots/events. Zero HP
  settles closed. Headless game still works without any presentation consumer.
- Header observes input passively. Touch wins over emulated mouse, multitouch
  cancels, rotation/focus/app pause clear stale touch. HUD converts interpolated
  actor anchor through world viewport/container to header coordinates; selected
  cell and recent pointer drive Observe. No zoom, camera-follow or gameplay edit.
- Optional session presentation_event reports successful pose/poor attempts.
  Only fixed-cost catalogue tools can signal on selection; free DIG clearing,
  repairs and discounted vault upgrades require actual-cell affordability.
  Funded dry run distinguishes money from invalid geometry/level/full health.
  Raid HP/stolen/killed counters trigger real reactions, even immediate results.
  No trap-disarm mechanic exists; ordinary trap activation is NOT anger.
- MasterEyePreview.tscn is isolated/no-save, seven modes/replay/pause/HP selector,
  live pointer and moving tracking target. v16 index contains native recordings.
  Review WebPs are not runtime assets. Production font/icons/header sizes retained.
- Native29behavior+10pixel/input+34world checks pass,856existing header checks,
  227rotation checks/mobile interaction fixture and5headless recipes pass, empty
  stderr. Five sizes including320portrait/568short inspected. Independent review
  caught contextual-price false positives and rotation stale-touch; red/green
  regression cases retained. No phone profiling/art approval, APK, commit/push.

## Header numerals and insignia darkened — 2026-10-28

- User still finds text/icons too heroic. v15-dark-insignia runtime uses bold
  pale-lavender Grenze numbers, painted slate/violet hourglass and raid skull,
  worn gold coins. No titles. C masonry/ten runes/violet gauges unchanged.
  New art is a visual iteration, not automatic user approval. Header-only;
  world coin badges and other HUD glyphs stay as they were.
- Built-in ImageGen3native-alpha originals/prompts retained. Uniform64px PNGs
  total25031bytes/49152RGBA; no repaint. prepare_header_icons.cjs stores crop/
  SHA and copies unmodified Grenze variable font+OFL license. Main UI preparer
  delegates to it. Google Fonts upstream/license URLs recorded in v15 README.
- Font700 uses lining/tabular numbers. Optical offset -11% replaces Cinzel+9%
  because tall line metrics otherwise put digits below the icons/onto rails.
  Existing856native checks pass;5game sizes+raid header inspected, exit0/empty
  stderr. V14 captures retained; current capture/check scripts write v15.
  No phone validation, player saves, APK, commit or push.

## Approved C stone header and ten HP runes — 2026-10-28

- Follow-up removes redundant OR and awkward PROCHAINES PROIES titles. Keep
  only coin/value and hourglass/timer, crossed swords during active raids.
  Rows vertically recentered, phase descriptions remain in tooltip in ordinary
  French. Focused checks adapted to the removed labels:856pass/empty stderr;
  five native sizes and raid-header capture refreshed. No APK/commit/push.
  Vertical placement now follows painted fissure/groove bounds y84..230 of the
  342px crop, plus a small Cinzel digit-ink correction; do not use arbitrary
  whole-header centering that puts numbers above the center of the stone face.
  Both progress fills are now violet #b66af2 at user request; keep their clipped,
  borderless geometry. Gauge pixel verifier uses violet detection,40cases pass.
- User selects C, restores ten heart-health runes, then approves. v14-header-c-
  integrated replaces the runtime header with two stone wings and one fixed-
  aspect angular eye housing. Existing96/84height budget retained. Native text,
  icons and clipped borderless gauges; percent sits on carved lip, no extra box.
- ImageGen native-alpha source/prompt/hash retained. prepare_header_c.cjs makes
  adjacent cuts and uniform192px-height reduction:415602PNG bytes/918528RGBA.
  prepare_master_ui now delegates to it; never restore v10/v11 art as current.
  Old eye remains Android launcher source. No manual pixel paint or new APK.
- Source-calibrated shader:ten clockwise sectors from12o'clock,ceil(HP/10).
  Dim only rune annulus; preserve housing/pupil/lip. Apply vertex tint once,
  not fragment COLOR times texture (that squares/darkens the artwork).
- Native1144checks,40gaugecases,227rotationchecks and mobile interactions pass;
  exit0/empty stderr. Five gameplay sizes incl320portrait/568short inspected.
  Captures disable persistence and explicitly refresh after resize because
  session processing is paused. Independent review found no important defect.
  No phone/DPI validation, player-save access, APK, commit or push.

## Headless gameplay probes and scenarios — 2026-10-28

- User requests simulations/tests through probes without UI. `scripts/testing`
  provides passive state snapshots with stable IDs and per-tick invariants;
  ScenarioRunner drives the actual game_session commands and shared
  advance_simulation at fixed .05s. No renderer, scene UI or player-save I/O.
  persistence_enabled defaults true in normal game; disable BEFORE tree entry
  for tests. Keep Save.capture balance reconciliation even with disk disabled.
- `tools/run-probes.ps1` runs five JSON recipes under tests/scenarios; reports
  in artifacts/probes, exit0 success/1 observed failure/2 invalid input or engine
  error. Checks stderr because Godot can return0 after a script error. Retain
  native process handle, correct Windows trailing-backslash quoting and protect
  scenario inputs from report overwrite. `docs/testing/probes.md` is the guide.
- Seeded runs are sequential/synchronous; global RNG is reset. Parallel runs
  require separate processes. Reproduction requires same code/settings/engine;
  seed21 recipe specifically tests Vulpin unlock/trap/theft/repair. Generic
  raid-cycle supports varied seeds/classes. Timeout240s accounts for existing
  Stubborn Vulpin morale (~195s after failed lockpick); no AI behavior changed.
- Validation:63 native checks,14 CLI checks,5 recipes and40 raids across all
  four hero classes pass; headless import exit0/empty stderr. Independent review
  findings fixed and reproduced by tests. Queries do not repair observations.
  Logical/grid checks do not prove sprite occlusion/art/HUD correctness; old F3
  overlay not restored. No APK, player-save access, commit or push.

## Door passage uses independent jamb supports — 2026-10-28

- User reports Vulpin clipped by open doorway. Old two horizontal sprite layers
  each merged both jambs; one depth support cannot surround an actor. v14 keeps
  exact v11/v12 geometry and v13 paint, but partitions final pixels into left jamb
  (legacy -leaf), crown above .92 (-arch), right jamb and closed-only panel.
  companions/door_part metadata uses existing shared renderer expansion. Do not
  regress to a single hollow arch bounding box; geometric clearance is not a
  proof of correct sprite occlusion.
- Pre-fix24 partition failures and four native jamb failures retained. Current
  partition preserves full paint/alpha with no seam. Native49positions×4views,
  16center walk/run poses:863checks0failures. Game opening/cached actor insertion
  84checks, badges87, lockpick32contacts/four sizes pass, empty stderr. Independent
  focused review found no actionable defect. Arbitrary-layout pixel depth and
  continuous 3D collisions are not proven.
- 171 kit entries;143 non-door sprites/metadata and37 hero resources unchanged.
  PNG2096585bytes (10589less thanv13),13MiB RGBA unchanged. v14 index shows native
  before/after traversal with slider. No art regeneration, APK, player saves,
  commit or push. V12/v13 capture pages are historical.

## Menacing door leaf and unified hinge lattice — 2026-10-28

- User rejects plain v12 wood, then requests fusing hinges and iron cross into
  a # framework. v13-malefic-leaf uses ImageGen for two connected crossbars,
  pointed uprights and a violet seal. Black keyhole stays at source512,1138 /
  worldZ.32. New appearance is a proposal awaiting user feedback.
- Shared projector reads a separate leafPainting only on leaf* faces. Exact
  approved v11/v12 geometry, UV fit, masonry and hinge barrels remain frozen;
  no new geometry or Vulpin poses. Active game/scenes use the refreshed atlas.
- 159 IDs/all metadata unchanged;151 regions including8 open-frame parts are
  pixel-identical. Four silhouettes and masonry away from leaf filtering are
  unchanged;37 hero resource hashes unchanged. PNG+13080bytes;13MiB RGBA same.
  Native import/capture exit0, empty stderr,32 contacts/4views/64 passage poses
  with0 failures. v13 index retains before/after and native review. No phone
  validation, opening animation, player save, APK, commit or push.

## Approved compact door integrated — 2026-10-28

- User validates v11 (“oui ça à l'air beaucoup mieux”), continuing the earlier
  request to integrate in game/scenes. v12 freezes exact v11 XYZ: height1.16,
  opening .96/.63, slim posts retain exterior/depth and original wall contacts.
  ImageGen face retains dark joints, plum wood, two hinges and black keyhole.
  Source contact (512,1138), uniform UV scale1/translation(0,-.4), lock Z=.32.
  The smooth receiver remains independent of painted hardware. Open removes
  only the wood; all four rotations use the same shared catalogue.
- V26 lower-lock whole poses are now active in VulpinLockpick. Same model,
  paint, feet, camera and .85 scale; wrists advance/flare, rather than raising
  hidden hands as rejected v25 did. Four sheets894106 PNG bytes /8MiB RGBA.
  prepare.cjs --install updates active sprites; default preserves local review.
- 159 kit entries;143 non-door regions and metadata byte-identical. Closed/open
  doors share the historical open-doors atlas page; total12->13MiB RGBA and
  PNG2015739->2094094 bytes, avoiding doubled architecture texture memory.
  Trap receiver export uses existing atomic file writer after Windows file-lock
  failure; trap pixels unchanged.
- Native import, four-door contacts, gameplay7 states, open doors40 checks,
  badges87 checks and lockpick32 projections/four sizes pass with empty stderr.
  v12/index.html links native images and validation. Sources, frozen guides,
  prompts, measurements and v26 replay retained. Full hero gameplay integration,
  continuous collision, swinging hinges and physical-phone profiling not claimed.
  No player saves, APK, commit or push.

## Compact door revision awaits wireframe approval — 2026-10-28

- User rejected v9/v10 height, v25 high lock/hidden arms and oversized posts.
  First compact trial also moved columns off their wall alignment; rejected.
  Current hero-fit-v11-compact keeps the exterior post face/depth and exact low
  junctions, thins toward passage, lowers total height 1.445 to 1.16, opening
  .96 high/.63 wide. Blank leaf; future lock .32 between hinges .16/.64.
- V26-lower-lock-review lowers wrists and advances them; unchanged Meshy paint,
  camera and feet. 32 whole sprites, eight held poses; local review only.
  Saved replay zero error; 17 meshes pass opening; eight picking meshes are
  XZ-disjoint from masonry face boxes. Native captures zero failures.
- User explicitly asks to see and validate the wireframe BEFORE further work.
  Open v11/index.html. Do not interpret test passes as approval. V10 production
  asset trial and v25 active sprites reverted; old assets preserved. Two default
  resource getters in the lockpick stage support isolated review overrides.
  No additional texture generation/integration before user validates. No APK.

## Door height review must precede painting — 2026-10-28

- User reports Vulpin lockpick scene door too small, missing readable lock and
  hinges; explicitly reiterates wireframe FIRST for approval. Isolated
  door-redesign/seal-v1/hero-fit-v9 is a proposal, not accepted production art.
- Raises upper arch .55 case, extends posts with three courses. Opening
  .513 -> 1.063 versus unchanged .852685 standing hero height/.85 native scale.
  Original low wall junctions/XY footprint remain exact. Blank leaf front/back
  plus perimeter only. Gold hinge/keyhole marks are future texture placements;
  keyhole retains existing tool contact at Z=.275. No hinge swing is simulated.
- First +.47 attempt failed two running meshes; retained as rejected evidence.
  Final Blender verification checks 17 complete held walk/run/idle meshes
  against the convex opening, with old profile as failing baseline. Width
  unchanged with tiny lateral margin; eight lockpick poses are checked against
  actual masonry front planes separately, after clipping body triangles to
  each face's XZ bounds (avoids treating the empty opening as a solid tier).
  Native four-view review preserves scale, contacts and normal solid ordering.
- Exploratory paint was generated before wireframe-first steering, archived
  source/paint-trial-not-integrated.png. It is not approved or used; do not
  integrate it automatically. Current accepted v6/v7 door and kit unchanged.
  README preserves reproduction and limits. No gameplay/save/APK/commit/push.

## Reusable hero animation documentation — 2026-10-28

- Start new hero animation work with docs/production/hero-animation-pipeline.md
  and hero-animation-reproduction.md. Current action sources, timings and
  superseded experiments are indexed in docs/reference/vulpin-review/README.md.
  These consolidate camera/anchor/rig/contact/packing/validation lessons;
  per-action scripts and JSON remain the numeric source of truth.
- Original Meshy GLB is archived byte-identically under vulpin-review/source,
  SHA035f4d448e60fefd99b5eb9c8a7f2ddd55405802dcc060018d0c9595d848e2b4.
  Current inspection/render recipes resolve this copy, not Downloads. The
  parent .gdignore keeps it out of Godot imports. Do not overwrite this input.
- tools/audit_hero_pipeline.cjs verifies the preservation manifest read-only;
  --record refreshes it only after intentional changes have been validated.
  It checks source existence/hashes and guide links, not artistic correctness.
  A local inventory is not a remote backup; include these sources and the
  manifest in authorized commits/pushes. No APK or animation-art change in this audit.
- For another hero, remap actual rig semantics and ground masks, recalibrate
  size/tool contacts, and review a walk pilot before multiplying renders.
  Never assume Meshy Bone_NNN names or Vulpin anatomy transfer automatically.

## Meshy Vulpin knee-first death preview — 2026-10-28

- User explicitly supersedes the old no-fall decision: knees first, then a
  forward fall with extended arms. Subsequent feedback rejects a push-up pose
  and requests the torso lowered and head turned sideways. v24-meshy-dead
  renders10 whole-mesh held poses in4 views, unchanged Meshy GLB/paint.
  First side-lying render_dead/render_side_pilot scripts are superseded pilots;
  render_fall.py is the current source. Eyes remain open: no facial rig.
- Chest bends independently of pelvis; knees receive weight before the head
  lowers. Final hands advanced from .184/.185 to .261/.263 model units ahead
  of shoulders, elbow angles171.45degrees. Reviewer/user push-up finding fixed
  and saved-pose arm check fails old art/passes new. Head turns78degrees sideways.
  Body/hand/head sampled floor clearances are approximate, not a physical
  contact or self-collision simulation; naturalness still needs visual feedback.
- User then selects the former2x as the new normal: timing is now550ms
  (previously1.1s), all rate controls relative to that base. Timing updated in
  source metadata/generator, resources and WebPs; atlas pixels unchanged.
- Ten held poses,550ms non-loop, then a persistent static corpse. Four
  dead-* clips share final fall frames. One trimmed atlas1024x1315:1,435,199PNG
  bytes /5,386,240RGBA bytes.384px virtual canvases retain original pixel density
  through increased camera canvas/scale; lower camera target requires new
  ground_anchor metadata. Do not apply the old standing numeric offset.
- scenes/VulpinDeath.tscn presents4 native floor views, pause/step/replay,
  .5x–2x and optional repeat (off by default). Native import/capture exit0,
  empty stderr,128 checks/0failures,12captures at3sizes. Packed Blender replays
  all10 bounds exactly;40 unclipped unique frames, source hash and24 previous
  sheets unchanged. New source/native/slow WebPs retained in v24. Preview only:
  no gameplay, player save, main scene, APK, commit or push changes.

## Vulpin static idle state — 2026-10-28

- User requests idle as a single fixed image, with no animation. New
  assets/previews/vulpin-idle/frames.tres has one non-loop frame per direction,
  referencing the neutral region of each existing v19 hurt sheet (also the
  final hurt frame). No new PNG, repaint, Blender render or moving idle pose.
- Resource metadata retains the shared ground anchor and .85 hero scale.
  Idle and hurt share Texture2D assets; loading idle alone still loads the
  four complete hurt sheets (8 MiB RGBA), not four separate small images.
- scenes/VulpinIdle.tscn uses four static Sprite2D views on existing paving,
  without animation controls or a clock. Native import and capture exit0,
  empty stderr; desktop, short landscape and portrait captures inspected in
  v23-static-idle. Production hero state machine unchanged. No APK/commit/push.

## Vulpin locked chest lockpicking — 2026-10-28

- User requests the separate chest lockpick action. v22-chest-lockpick renders
  eight whole-mesh crouched poses in4 directions from unchanged Meshy GLB/paint,
  with two small3D tools. Lower fixed stance, low hands and small wrist search;
  8fps/1second loop. Same256px camera/anchor/.85 scale.32 unique unclipped
  frames;4 sheets847,196PNG bytes/8MiB RGBA. Source hash unchanged.
- VulpinChestLockpick.tscn shows four native chest/floor stages with pause,
  step, restart, .5x–2x, guides and ghost chest. Exactly one CLOSED chest and
  matching shadow throughout attempts; no automatic unlock/open transition.
  Door lockpick and unlocked chest interaction remain separate and unchanged.
- Painted east/south keyhole centres measured in prepared textures; hidden
  rear contacts inferred through opposite grid offsets. Native projection
  uses projection_y.z=-.6123724357, matching the30degree Blender camera.
  Source tip reach increased from-.88 to-1.0Y for this visual registration.
- Replaced inappropriate infinite-plane guard with triangle separation below
  each chest's actual catalogue height.32 conservative bounds checks pass,
  min .0068831case clearance. Painted chest has no reconstructed3D geometry:
  this is a proxy check, not exact horn/lid collision proof or art approval.
- Native import/capture exit0, empty stderr,394 checks/0 failures,21 captures
  across4 sizes. Boards, normal/ghost contact and short/portrait inspected.
  Saved8pose replay has0 bounds/tool-tip error;20 prior sprite sheets unchanged.
  Fresh independent review found no important issue. No gameplay, save, APK,
  commit or push. Native animation: v22-chest-lockpick/native-loop.webp.

## Unlocked chest state correction — 2026-10-28

- User corrects v21: a non-locked chest is ALREADY AJAR. Never use the closed
  locked painting to simulate its opening. A locked chest requires a separate
  lockpicking action first; this action has not yet been authored for chests.
- VulpinChestOpen stage now contains only the appropriate prop-chest-open
  directional sprite and matching open shadow, throughout all8 poses, replay,
  step wrap and repeat. The Vulpin's existing gesture/32 sprites are unchanged.
  There is no access-state switch and no animated chest lid in this review.
  This supersedes the closed/open switch described in the original v21 entry.
- Regression check first failed96 times with the old two-state scene; final
  native run exit0/empty stderr,315 checks/0 failures.15 captures and animated
  preview regenerated; initial/grip/lift views inspected. Source metadata and
  preparation no longer expose an open-frame transition. No gameplay, save,
  APK, commit or push changes.

## Vulpin unlocked chest opening — 2026-10-28

- User requests the hero opening an unlocked chest. v21-chest-open renders
  eight held poses in four views from the unchanged Meshy GLB and paint:
  ready, bend, grip, start lift, lift, hold, release, recover. Empty hands;
  no lockpick, looting, fall or facial changes. Same256px camera/anchor/.85
  scale. One-shot1.08s; four sheets1,102,311PNG bytes/8MiB RGBA.
- scenes/VulpinChestOpen.tscn presents four native floor/chest stages with
  pause, step, replay, optional repeat, .5x–2x, guides and ghost chest. Existing
  closed/open paintings switch at pose4; final state stays open until replay.
  No intermediate chest lid art or continuous lid animation is claimed.
- Initial lift was too high for the painted lid; lowered hands while keeping
  a crouch. Pose0/7 knee bend fixed clamped ankle targets. Grounding/reach,
  32 unique unclipped frames, source hash and eight saved pose replay checked.
  Conservative container proxy has no interior mesh vertices; not proof of
  exact contact/collision with the painted lid, horns or hand surfaces.
- Native import/capture exit0, empty stderr,247 checks/0 failures. Fifteen
  captures across4 sizes include normal/ghost grip and opening. Boards,
  open/closed views, short and portrait inspected; fresh review found no
  important issue. Sixteen prior walk/run/hurt/lockpick sheets unchanged.
  Motion remains an artistic proposal. No gameplay/save change, APK, commit
  or push. Native preview: v21-chest-open/native-preview.webp.

## Vulpin lockpick loop and four-door positioning scene — 2026-10-27

- User requests attempting to pick a door, then a scene with doors in four
  directions to test placement. v20-door-lockpick renders8 whole-mesh held
  poses from unchanged Meshy GLB/paint, with two small3D lockpick props. Fixed
  feet, crouched lean, small wrist search;8fps/1second loop, four directions.
  Same256px canvas/camera/anchor/.85 scale. Four sheets890,913PNG bytes/8MiB
  RGBA.32 unique unclipped frames; source hash and saved8-pose replay checked.
- VulpinLockpick.tscn reuses native dungeon renderer/accepted doors and solid
  ordering. Four3-cell corridor cards; pause/step/.5x..2x, distance offset,
  Recaler, optional lock/feet/tool guides and ghost door. Default offset0;
  source tip projected by actual cameras is aligned to painted lock z=.275.
  Ghost mode is inspection only; normal mode keeps masonry occlusion.
- Focused independent review caught head/crown penetration despite leaf-plane
  contact passing. Source tool reach/setback increased from-.86 to-1.06Y;
  final mesh triangle separation against actual low-jamb/upper-crown planes
  passes16 checks (minimum .0094485case at zero offset). Red/green evidence
  retained. Saved tool tip fixed on all8 poses. Intentional distance controls
  can move away from this calibrated position.
- Final Godot import/capture exit0/empty stderr/0failures,21 native views:
  8normal/8ghost, guide/offset,4sizes. Overview/ghost/short/portrait inspected.
  Twelve old gait/hurt sheet hashes unchanged. No further important review
  finding. Hot reload, phone profile and naturalness not proven; no facial
  animation, gameplay unlocking, player saves, APK, commit or push.

## Vulpin damage motion revised after sneeze-like recoil — 2026-10-27

- User rejects v18's abrupt movement and supplies a backward-braced pose.
  V18 flipped torso -16 to +16 degrees after60ms, and head -14 to +28.
  V19-hurt-recoil replaces this with eight explicit held whole-mesh poses:
  backward recoil only, -25degree peak, raised hands, staggered fixed feet,
 120ms peak hold and progressive recovery. Head/torso adjacent pitch changes
  are at most9degrees. No facial rig/morphs: eyes and mouth still differ from
  the reference. New body motion is a proposal, not artistic approval.
- Four2048x256 sheets,32 unique256px frames:1,235,647PNG bytes/8MiB RGBA.
  Runtime order1..7,0 lasts720ms, loop=false; neutral pixels reused. Original
  GLB/materials, walk/run sheet hashes, camera and anchor unchanged. Saved
  Blender contains8 CONSTANT poses, replayed with zero bounds error.
- VulpinHurt scene now uses eight stages. Native capture/import exit0, empty
  stderr,0 failures across one-shot end, pause/step/retrigger, rates, repeat,
  live clock and3 sizes. Seven captures; peak/recovery/short/portrait and full
  pose board inspected. Export checks source hash,32 unclipped unique frames,
  fixed ankle targets, sampled grounded soles and backward pitch continuity.
  These do not prove anatomical correctness or naturalness. V18 retained as
  rejected history. No gameplay integration, player saves, APK, commit/push.

## Meshy Vulpin damage reaction and review scene — 2026-10-27

- User requests taking-damage animation. v18-meshy-hurt renders five new held
  whole-mesh poses in four directions from the unchanged Meshy GLB/materials.
  Brief recoil, contraction with bent knees/raised hands, recovery, then neutral.
  Feet targets remain fixed; no cell knockback, fall or death animation. Same
  isometric camera/anchor as walk/run. No facial morphs are available in the rig.
- Four1280x256 sheets,20 unique256px frames:771,174PNG bytes/5MiB RGBA.
  SpriteFrames one-shot order1,2,3,4,0 lasts480ms and reuses neutral pixels at
  the end; loop=false. Packed vulpin-hurt-poses.blend keeps5 CONSTANT poses.
  First subtle pilot is retained separately; final pose board inspected.
- scenes/VulpinHurt.tscn presents four views on existing paving. F6 plays with
  optional repetition/rest gap; Space/Subir un coup retriggers, pause/step and
 0.5x..2x available. Editor shows neutral. Preview only, no gameplay damage or
  player save instantiated. Walk/run scripts, frames and scenes untouched.
- Export checks20 unique unclipped frames, grounded sampled soles/fixed ankle
  targets and source hash. Reloaded Blender reproduces5 poses with zero bounds
  error. Native import/capture exit0, empty stderr,0 failures: one-shot ending,
  pause, step/wrap, retrigger, rates, repeat gap, live clock and3 viewport sizes.
  Endpoint comparison tolerates float resource-duration rounding (7ns observed).
  Six native captures inspected in v18/native-scene. No naturalness/collision
  guarantee, phone validation, APK, commit or push; visual feedback remains due.

## Meshy Vulpin running sprites and corridor scene — 2026-10-27

- User requests running and its own scene. v17-meshy-run renders eight new held
  full-mesh poses in four directions from the unchanged Meshy GLB/materials.
  Forward lean10degrees, bent arms, longer stride, raised recovery foot and two
  flight samples per cycle. Same30degree camera, scale and anchor as v16 walking.
  Packed vulpin-run-poses.blend retains CONSTANT keys; no runtime3D skeleton.
- Four2048x256 sheets (32 frames256px) in assets/previews/vulpin-run:1,138,660
  PNG bytes,8MiB RGBA.16fps/.5s cycle; model travel2units/s, about2.05x current
  normal walking. scenes/VulpinRun.tscn offers two corridor round trips and the
  same pause/step/restart/0.5x..2x controls. Preview scripts accept gait settings;
  VulpinWalk defaults remain15fps effective with unchanged walk PNGs.
- Original GLB hash verified; finite geometry, alpha bounds, distinct frames,
  sampled support/flight clearance and saved pose replay (8/0 error) checked.
  Full board/front/back and native scene views inspected. Native capture tool
  accepts --run, checks defaults/rate/pause/step/reversals/four directions and
  three sizes; both walk and run exit0/0 failures/empty stderr. Import exit0.
  Evidence: v17/native-corridors, validation.json, saved-pose-validation.json.
- This is a review scene, not a gameplay hero replacement. Naturalness and
  self-intersection are not guaranteed by sampled checks; visual feedback still
  required. No player saves, game rules, main scene, APK, commit or push changed.

## Vulpin walking preview changed to two corridors — 2026-10-27

- User replaces the four stationary views with two corridors and back-and-forth
  travel. VulpinWalk.tscn now shows two three-cell corridors along the native
  grid axes: SE/NW and SW/NE. User then selects the former1.5x as the new normal:
  15 poses/s and a reversal about every3.81s. Other rates are relative to this base.
  Existing v16 sheets unchanged. New preview-only vulpin_walk_corridor.gd
  reuses native floor/wall rendering and physical solid ordering for the actor.
- One clock drives travel and eight held frames; rate follows Blender's planted
  foot stride and original orthographic camera. Pause/step/restart/0.5x/1x/1.5x/2x
  controls. Instant direction swap at ends; no new turning animation. Two cards
  side by side in landscape, stacked in portrait. Editor static, F6 autoplay.
- Native capture harness checks live motion, pause, stepping, rate, both ends,
  repeated reversals, all four directions, centreline and unambiguous foreground
  wall ordering. Six captures/three sizes inspected. Capture/import exit0,
  empty stderr,0 failures; v16/native-corridors preserves native-scene history.
  Sorting check excludes diagonally disjoint bounds, not a pixel-depth oracle.
  No claim of perfect foot locking or artistic approval. No gameplay/save/main
  scene changes, artwork generation, APK, commit or push.

## Native four-direction Vulpin walking scene — 2026-10-27

- User requests a scene showing the four movements: context is four directions
  of the v16 walking trial. scenes/VulpinWalk.tscn presents four synchronized
  AnimatedSprite2D views on existing floor-b1 paving, in a responsive2x2 grid.
  Eight frames each; Play/Pause, next pose and0.5x/1x/1.5x controls. Space/right
  shortcuts. Editor tool shows static pose; F6 plays. No game/save instantiated.
- Four sheets copied byte-identically to assets/previews/vulpin-walk, imported
  natively with shared SpriteFrames resource. No artwork or GLB modification.
  Floor texture is resolved through current catalogue, not a frozen atlas rect.
- tools/capture_vulpin_walk_preview.gd checks four animations, autoplay, pause,
  step/wrap, speed and synchronized frame selection; native captures1280x720,
 844x390,720x960 inspected. Capture exit0,0 failures, empty stderr. Evidence in
  v16/native-scene. HTML/browser not needed. No main scene/export preset change,
  gameplay integration, APK, commit or push; prior unrelated edits preserved.

## Meshy Vulpin eight held walking poses rendered — 2026-10-27

- User approves fixed 3D poses rather than authoring a smooth Blender animation,
  then requests a walking-sprite trial. Isolated v16-meshy-walk renders the real
  user-supplied GLB, unchanged mesh/paint, with eight explicitly selected poses
  and four directions. No old image-card puppet, generated in-between art or
  runtime rig. Original GLB SHA unchanged. Hand/leg bones mapped from rest data;
  two-segment pose solving, alternating supports, small body bob/tail sway.
- Fixed 30degree orthographic camera gives2:1 ground projection; camera scale,
  root anchor and screen-relative studio lighting shared. Masters512px;32 PNGs
 256px and four2048x256 sprite sheets.10fps/.8s proposed loop. Sheets1,087,233
  PNG bytes /8MiB RGBA, no claimed final production memory optimization.
- Eight poses stored as CONSTANT keys in packed vulpin-walk-poses.blend. Reload
  verification reproduces all eight mesh bounds with zero error. Ground checks
  use rest-identified boot vertices: one support atz0, swing sole raised, finite
  geometry.32 unique-per-direction frames, alpha bounds and WebP timing checked.
  Contact sheet/front/rear details visually inspected; not proof of no clipping
  or of a natural gait. Artistic approval remains pending.
- index.html offers pause/step/rate; four-view animated WebP, pose board, sprites
  ZIP and source Blender retained. HTML syntax/local links checked without
  browser automation. No game integration, gameplay/save changes, native Godot
  run, phone validation, APK, commit or push. This is a visual trial only.

## User Meshy GLB imported and inspected — 2026-10-27

- User supplies C:/Users/A/Downloads/Meshy_AI_Character_output.glb and asks
  whether it is usable. Read-only inspection confirms glTF2 binary,15,644,004
  bytes, one character mesh/10,321triangles/13,590 exported vertices, UVs and
 57-bone SmartRigArmature with weights on every character vertex. Embedded
  textures:2048 color,2048 normal,4096 metallic/roughness. No animation clips.
- Blender5.2.1 imports successfully. A reversible5degree Bone_021 probe moves
 4,844 vertices and restores with zero error: confirms connection only, not
  gait/articulation quality. Bone_019..015 is a rearward/upward tail chain by
  rest positions. Generic bone names still need semantic mapping for animation.
- v15-meshy-inspection retains inspection script, JSON/log and front/isometric
  static transparent renders; visually inspected. Camera excludes the importer's
  hidden Icosphere bone-display helper. Source SHA verified unchanged. No model
  editing, animation creation, production integration, APK, commit or push.

## Vulpin four-view Meshy references prepared — 2026-10-27

- User will use Meshy to generate a real 3D character and asks for reference
  views. v14-meshy-turnaround supplies front/left/back/right PNGs, one figure
  per image, neutral A pose, level orthographic-looking views, native alpha.
  Based on approved v3 free-hands art, not v12 body pieces. No weapon.
- Built-in ImageGen made four views plus two corrections: tail hidden in front,
  clean rear heels. Right-hip pouch stays on the appropriate side; centered tail
  curls upward behind body. Back/hidden surfaces are proposed interpretations.
  These are independent illustrations, not calibrated renders of one 3D mesh;
  minor shape differences remain. No claim of tested Meshy reconstruction.
- meshy/ contains four1254px PNGs copied byte-identically from selected sources,
  each under1MB, native transparency checked; apercu.png visually inspected.
  Exact prompts, source originals and alpha/hash report retained. ZIP bundles
  only import PNGs and instructions. No model generation, external Meshy upload,
  game/runtime change, player-save access, APK, commit or push.

## Vulpin layered paint rejected; whole-frame approach under review — 2026-10-27

- User rejects v12 feet, joint overlaps and clipping, then explicitly requests
  whole-character sprite animation preserving the original illustration quality.
  V12 technical checks are not visual approval. Do not reuse its layered body
  as an accepted solution. Overlapping shin/boot paint and rigid bone cards are
  concrete causes; v3 free-hands and v4 action originals remain style references.
- Isolated v13-whole-sprites contains pose-only guides and a complete painted
  walk-0 source. The opposite-step attempt repeated essentially the same pose;
  it is retained as walk-4-rejected-same-step.png, not a usable cycle. No complete
  animation, atlas, native validation or production integration exists for v13.
- User proposes evaluating GenielabsOpenSource/spine-animation-ai. Documentation
  and code reviewed only: separated art, 2D skeleton, generic motion presets,
  optional Gemini separation. It is not whole-frame image generation. No tool
  installation, external image upload or adoption is authorized by that question.
  Repo declares PolyForm Noncommercial; commercial terms and separate Spine
  licensing need consideration before adoption. No new APK, commit or push.

## Vulpin body paint matched to head treatment — 2026-10-27

- User rejects v11's soft body versus crisp head. Cause: body turnaround
  projected onto proxy meshes with flat-color visibility blending, while the
  head retained its independent painted image. This supersedes v11 body art.
- New isolated v12-body-paint uses12 native-alpha painted body pieces per view,
  uniformly fitted to the existing rig and rendered as bone-attached cards.
  ImageGen sources/prompts retained: four sheets plus three targeted revisions
  for joint colors and wrong-facing boot/torso pieces. Source originals intact.
  Heads/expressions unchanged; four v11 corpse images reused byte-identically.
  No fall.8states/4views; all96 profile/clip timings match v11, including run.
- Tail is a single painted piece attached to tail.0, not the old3segment proxy;
  its outline/motion and joint overlaps remain artistic review points. Sheets
  approximate projected geometry; this is not exact3D texture reconstruction.
  No fallback color blending on the new body. Production hero stays untouched.
- Balanced320 unique images/336slots,3pages; PCK3,162,088 bytes vs3,208,744,
  RGBA11,419,648 bytes. Native1762 checks and viewer588 checks pass/empty stderr;
  96 native alpha/anchor cases0error, all three packs load independently.
 12 profile/direction corpse comparisons byte-identical, previous source hashes
  and historical APK verified unchanged. Comparisons at equal resolution,
  all-facing state sheets and native dungeon views inspected. No device test,
  player-save access, production integration, new APK, commit or push.

## First painted Vulpin sprites generated — 2026-10-27

- User asks to generate sprites from the approved fox designs. Isolated
  v11-painted-sprites retains v10's eight states/four directions and v9's
  .36s/.320cell run. No fall; four separately generated fixed corpse images.
  Four native-alpha ImageGen sheets: body turnaround, detached heads, hurt
  expressions and corpses. Originals/prompts/references and hashes retained.
- Offline Blender projects directional body paint onto the articulated proxy;
  head cards attached to the head bone preserve the facial drawing. Hidden
  body surfaces use fallback colors. Tail/clothing remain simplified and
  generated equipment is not guaranteed anatomically consistent across views.
  This is a first painted review, not exact source geometry or art approval.
  No 3D renderer is needed at runtime. Packed blend stores SE neutral rig;
  paint_rig.py regenerates actions, not a baked eight-action animation timeline.
- Balanced328 unique images/336 slots,32 clips,3pages. PCK3,208,744 bytes;
  RGBA11,649,024 bytes. CompactPCK1,537,288; reference7,775,336. Atlas packing
  preserves prepared pixels. Native1786 checks and viewer588 checks pass;
  96 native alpha/anchor cases0error, all three packs load independently.
  Motion metadata matches v10 in96 clip/profile cases. Sources and APK intact.
- Animated boards, four-direction state sheets, run phases and native desktop
  dungeon captures inspected. First painted appearance still needs feedback.
  No production hero/AI integration, player saves, physical-phone profiling,
  browser automation, new APK, commit or push. Current review: v11 index.html.

## Vulpin death simplified to four static sprites — 2026-10-27

- User approves removing the fall entirely and keeping one dead pose per
  orientation. This supersedes v9's fall sequence. v10-static-death retains
  four v9 final renders byte-identically; no new rig/render/paint generation.
  Eight states/four directions,32 clips. Death is a non-loop single-frame
  holder. Course .36s/.320cell and damage reaction remain unchanged.
- Regenerated all three atlas profiles without fall images; selector removes
  Chute and says "1 sprite fixe par vue" for Mort. Immediate hurt-to-dead
  selection and final holds verified in the isolated no-save native viewer.
  Balanced PCK2,438,984 bytes (v9:2,956,312; -17.5%),3pages instead of4,
  RGBA10,813,440 bytes (v9:13,320,192).4static source images, not4animated clips.
- Native1776 checks and viewer588 checks pass/empty stderr;96 alpha/anchor
  cases have0 error. Three independent pack-only loads verify32clips. All
  retained image/timing comparisons are recorded by validate.cjs. Native
  four-facing dead pose inspected. No production hero integration, rules,
  player saves, new APK, commit or push. No new physical phone validation.
  Prior reviews and APK remain historical; the next explicit APK request
  should use this simplified set, not the v8/v9 fall sequence.

## Vulpin run and collapse revised after Android feedback — 2026-10-27

- User rejects v8's slow run and rigid tree-like fall/death. New isolated
  v9-motion-correction changes only run/fall/corpse on the actual Blender rig.
  Run cycle .60→.36s, stride .256→.320 cell, demonstration speed ×2.0833;
  16 balanced run images retained, stronger flight/lean and bent-arm swing.
- Fall keeps1.5s but hips sink before side collapse. Separate knee, spine,
  arm, head and tail curves produce an asymmetric folded resting pose. Whole
  rig rotation stays zero; ground correction translates the entire hierarchy
  including IK targets, fixing a reproduced penetration during IK blending.
  Dead reuses the exact final fall image. Balanced fall13→19 images per view.
- 121 fall samples: worst floor error ~6e-8 model units, early hip drop.120;
  fixed limbs/contacts/loops checked for all states. 628 unrelated source PNGs
  byte-identical to v7. Prior v7/v8 sources and published APK unchanged.
- Native2091 checks plus590 viewer checks,0 failures/empty stderr.108 native
  alpha/anchor cases have0 error; three packs reload independently. Balanced
  PCK2,956,312 bytes (was2,766,328), RGBA13,320,192 (was12,255,232),4pages.
  Timed before/after WebPs, four-facing corpse and native captures inspected;
  index.html and validation.json retain evidence. No browser automation.
- Viewer now reads per-clip stride metadata; actual cycle displacement checked.
  No production hero/game speed integration, saves, new APK, commit or push.
  No new phone validation, soft-body/self-collision simulation or final paint.
  This revised motion remains a visual proposal, not automatic user approval.

## Explicitly requested Vulpin Android test — 2026-10-27

- User asks for an APK to inspect the animations live. v8-mobile-test builds
  a dedicated no-save app, org.dungeonempire.vulpinreview, "Vulpin — animations",
  separate from the installed game. Uses the actual static dungeon renderer,
  nine mannequin states/four views and three v7 profiles; default128/16.
- Native selectors, pause/replay/half speed/detail zoom and drag panning;
  portrait dock/landscape panel, 48-unit targets, safe-area/DPI adaptation.
  Short/narrow layouts corrected after two overflow failures. 578 final native
  checks pass at six sizes incl568x320 and320x568; real viewport touch included.
  Review travel follows rig stride and resets after four cycles. No gameplay
  integration, final painting or game save access.
- Fresh staging copies only renderer dependencies and review resources;
  production project/preset unchanged. Debug APK AndroidAPI24+, target36,
  ARM32+64, fullUser orientation13, versionCode1. Signaturev2/v3 verified.
  Exact final APK resources extracted into a separate pack;578 checks/0 failures
  again, empty stderr. No physical phone/DPI/sensor/performance verification.
- Public prerelease vulpin-animations-0.1 on existing repository, with APK and
  checksum. Download publication continues the user's earlier remote-download
  request. SHA256 f67a7a75416a3752243a8389e9d7e1581907b0ba45d813f28e6994bb58b09bd3.
  APK approximately70.8MB includes engine for both ABIs, dungeon and all3profiles;
  not the single-hero budget. Tag names base75c3212, uncommitted review sources
  included in binary and disclosed. No source commit/push. Future APK builds
  still require another explicit user request.

## Complete Vulpin mannequin animation budget — 2026-10-27

- User authorizes the complete animation/size study before multiplying heroes.
  Isolated v7-complete-budget extends the real v6 Blender rig with hand IK and
  nine states in four views: idle/walk/run/hurt/door pick/chest pick/loot/fall/dead.
  Empty hands outside tiny lockpicks; corpse reuses last fall image. Untextured
  proxy only, not approval of final silhouette, motion or painted production art.
- 121 rig samples per state verify constant limb lengths, contacts, targets and
  loop endpoints. Initial chest target was out of reach; corrected forward lean
  and reachable hand positions. Renders use shared isometric projection and
  overscan for prone poses. Trimmed atlas pixels are copied losslessly with2px
  margins; per-frame AtlasTexture margins retain a common ground anchor.
- Three complete lossless Godot resource packs, with independently reduced
  counts/resolution, reloaded in an empty project without source PNGs. Decimal
  bytes: reference160/24 walk-run:6,523,624 PCK /34,668,544 RGBA; balanced128/16:
  2,766,328 /12,255,232; compact96/12:1,445,032 /5,570,560. Balanced368 unique
  images,388 slots,4 pages; idle8,hurt7,pick/loot12,fall13,dead1 per direction.
  128/16 is a proposed compromise, not user-approved final settings.
- Native1999 checks/0 failures:108 alpha/anchor comparisons have0 error;
  durations, loops, pause and non-loop final holds checked. Three clean pack
  reloads verify decoded allocation. Missing importer metadata was caught by
  isolated reload and fixed by retaining .import mappings. Atlas pack size is
  not APK size, and RGBA excludes CPU copies, engine and other assets.
- Native49-frame dungeon fixture loads balanced pack and shows walk/run/pick/
  fall at existing camera scale; output saved to absolute paths because mounted
  res:// becomes packed. Empty stderr, no save. Demonstration travel follows
  rig stride; real gameplay speed remains unchanged and unsynchronized.
- Full/slow-cadence/resolution comparisons, all4 orientation boards, .blend,
  source scripts, packs and budget.json retained. Final paint may change disk
  compression; ten-hero totals are explicit linear mannequin estimates, not
  production predictions. Phone profiling, cloth/face, final hand/lock fitting
  and gameplay integration remain. HTML not browser-automated. No production
  art/rules/save changes, APK, commit or push; existing door badge edits kept.

## Articulated Vulpin mannequin walk review — 2026-10-27

- User approves proceeding with an untextured articulated mannequin after v5's
  inconsistent generated gait. v6-articulated-mannequin is an isolated prototype:
  real Blender armature, fixed limbs, two foot IK chains and knee poles, FK arms,
  head and3tail bones. Cyan/amber identify sides. No weapons or new ImageGen art.
- Blender connector was offline. Installed5.2.1 runs in a separate background
  factory-startup process; live user's scene not touched. Editable .blend and
  reproducible scripts retained. Four rotations use one model/action; coordinate
  swap matches native2:1 projection. Character silhouette remains simplified and
  unapproved; no painted or production hero integration is implied.
- Walk24frames/.8s, .44model-unit stride; modelToCell .4 gives .176cell/cycle.
 60% stance and40% swing; exact subframe boundary keys preserve foot locking.
 241 evaluated samples over2cycles: bone length error4.46e-7, stance drift2.53e-7,
  target error3.52e-7model units; loop0 and projection<.00006px. Flat soles, no
  heel-toe roll or hand IK yet. Geometry checks are not approval of the motion.
- Native Godot fixture:4directions,49captures, projected stance drift.000159px;
  exit0/empty stderr/no save. Native images, four views and actual-bone overlay
  inspected. Animated WebPs plus slow view delivered; HTML is a local review
  index, not browser-automated. Blender emits only a use_nodes deprecation.
- Review frames160px, fixedroot(80,140),96sprites/no border clipping, four
 960x640 atlases. This is unoptimized review packing, not a runtime budget change.
  Reproducible raw frames/captures ignored; selected media retained. No production
  file, gameplay speed, save, APK, commit or push change. Native movement uses
  rig stride for this fixture only; gait/simulation speed must be reconciled later.

## Vulpin state poses accepted; walk pilot remains provisional — 2026-10-27

- User answers "Ok" to v4 damage, door/chest lockpick and final dead poses.
  Those key poses are accepted; not approval of uncreated animations. Freeze
  v4 source95fb0f4af87e2bd8dc8d252b358003a07be032c1e1ba1c777c199c66ee01c95d.
- v5-walk-pilot produces a single-direction8-frame test using ImageGen. Initial
  and refined sheets retain inconsistent leg phases; a third guided painting
  improves presentation but still does not follow the geometric poses exactly.
  Torso/stance consistency needs work. Do NOT call this a production-ready walk,
  approve its gait, or multiply it into other directions without resolving this.
- Original sheets/prompts and code-native XYZ gait guide kept. Connected alpha
  silhouettes crop to common160px frames, same uniform scale, visually estimated
  ground roots. No warp, mirror, limb repaint or automatic pose deformation.
 640x320 atlas136316PNG bytes/800KiB RGBA; loop8frames/100ms,98362WebP bytes.
- Isolated native AnimatedSprite2D runs2cycles and pauses correctly,8GPU captures
  plus landscape; exit0/empty stderr/no save. Native captures and atlas inspected;
  no foot-slip oracle, world-speed calibration, phone or full gameplay test.
  CUA local-file browser automation was policy-blocked; no bypass attempted.
  HTML control page not browser-validated. Native animated WebP is the deliverable.
  No production hero/rules/art changes, APK, commit or push. Door badge work kept.

## Vulpin damage, lockpicking and death key poses — 2026-10-27

- User adds required states: taking damage, picking doors/chests, and death.
  Isolated ImageGen sheet in vulpin-review/v4-action-states proposes flinch,
  standing door lockpick, crouched chest lockpick, and final prone death pose.
  Same unarmed olive-hood fox; thin locksmith tools only while lockpicking.
- Original sheet and prompt retained, SHA95fb0f4af87e2bd8dc8d252b358003a07be032c1e1ba1c777c199c66ee01c95d.
  Four native-alpha silhouettes framed separately; common uniform reduction,
 160px review canvases, no repaint/warp. Labeled board and small views inspected.
  These are key poses in one direction, not animation frames registered to a
  shared foot anchor. Hand/lock alignment and other views remain pending.
- Existing lockpicking3.0333333s and dying1.5s plus persistent corpse confirmed
  in raid_director. Proposed hurt presentation must not add simulation knockback
  or delay. No runtime/simulation/save changes, native capture, APK, commit/push.
  Static artwork awaits feedback; v3 remains the unarmed identity reference.

## Vulpin carries no weapon — 2026-10-27

- User explicitly corrects the hero concept: Vulpin steals and does not attack
  the heart, so both hands must be empty. This supersedes the two daggers in
  the recovered October21 approved sheet. Retain olive hood, orange/cream fox,
  compact proportions and loot pouch; no combat stance in locomotion poses.
- ImageGen edits the isolated v2 proposal into vulpin-review/v3-free-hands.
  Original and exact prompt retained. Uniform128px preparation at the prior
  scale, native alpha, expanded crop by1–2px; no hand-painted pixel fixes or
  nonuniform warping. Source1306x1205, prepared20582bytes/64KiB RGBA.
- Three isolated native captures1280x720/844x390/390x844 inspected, exit0 and
  empty stderr, no save written. Boot anchor is visually estimated. Review
  index explains proposed four-direction walk/run cycles; no animation or
  runtime hero integration yet. Current exploration/flee speed remains equal.
  No rule, production art, APK, commit or push changes. V2 with daggers is history.

## Approved illustrated 2D hero concepts recovered — 2026-10-27

- User recalls earlier 2D hero mockups. Found in the beginning of this chat on
  2026-10-21: Vulpin accepted with "oui c'est parfait" at06:05:50UTC, four-hero
  sheet accepted at06:14:19UTC. Original generated PNGs copied byte-identically
  to docs/reference/hero-concepts-2d-2026-10-21/ with provenance and .gdignore.
- Sheet: compact green-hooded orange Vulpin/two daggers, living-stone Lithide
  shield/hammer, frog Batrafian bow/quiver, mushroom Mycean staff. This newer
  accepted illustrated direction supersedes the old main-branch low-poly
  "not chibi" proportions for the 2D heroes. Do not mistake old main concepts
  for the latest approved reference again. Recovered scenes predate calibrated
  2:1 migration: identity approved, directional animation/registration pending.
- The recent vulpin-review/v1 remains an unapproved new proposal. No new image
  generation, gameplay changes or APK in this recovery step.

## Vulpin hero first visual proposal — 2026-10-27

- User asks to create the Vulpin. ImageGen uses the original Neris mockup and
  current dungeon as references: orange fox thief, green hood, satchel, dagger.
  One three-quarter pose only; not approved, animated or integrated. Review:
  docs/reference/vulpin-review/v1/index.html. Original and exact prompt retained.
- Uniform prepared128x128 PNG is21209bytes/64KiB RGBA. Native source alpha
  preserved within alpha8-bounded crop plus8px margin; no warp or repaint.
- Isolated capture.gd reuses actual dungeon geometry/order/camera, showing the
  hero at84px/45px in1280x720,844x390,390x844. All three inspected, exit0/empty
  stderr. Boot midpoint is visually estimated; no calibrated 3D/animation claim.
  No runtime art/logic change, save write, APK, commit or push. Door badge work
  remains intact. Facing/animation work should use the user's visual feedback.

## APK builds require an explicit request — 2026-10-27

- User explicitly requests no APK build unless they ask for one. Do not treat
  previous upload/build authorizations as permission to create subsequent APKs.
  Native validation and implementation may continue without Android packaging.

## Door status uses the shared world ring — 2026-10-27

- User requests door status like chests/traps. One badge per closed/open arch,
  above its prepared silhouette, same32 screen units and z10/input transparency.
  Door icon and continuous copper resistance ring use live hp/DOOR_MAX_HP.
  Regular lock/magic seal retained while closed; green open padlock for unlocked,
  red cross for broken. No floating text/ground diamond. Selection sheet gives
  remaining PV or Déverrouillée/Brisée instead of ambiguous0PV for an open door.
- Reuses world_badge, existing art and native draw primitives. Chest/trap
  behavior, frame rendering, rules, saves and camera unchanged. Badges update on
  normal frame signals, so partial damage does not require rebuilding the scene.
- verify_door_badges.gd baseline12checks/5fail, final87/0: default/half/zero HP,
  unlocked/broken/repaired/removed, placement above arch, portrait size, precise
  selection wording and other badge regressions. Native portrait/landscape
  inspected; verify_open_doors40/0 and verify_master_mobile0. Empty stderr.
  Focused read-only review found no actionable defect. Isolated save path only.
  No APK build/upload, commit/push or physical phone validation.

## Open doors keep their stone frame — 2026-10-27

- User reports unlocked doors disappearing. View now emits door specials for
  every door tile, selects open-frame layers when !_door_intact, and retains
  wall junction cuts. Closed leaf/arch IDs are height splits, not material parts;
  hiding one was not sufficient. Removed obsolete open-door diamond/text marker.
- Same accepted v6 model/v7 paint: only terminal leaf/leaf-edge faces excluded
  for the open state. Original stone indices/UVs/materials preserved. No ImageGen
  call or source artwork changes. Repair restores the closed layers; actual
  tile removal removes the frame. Open and forced states share the empty frame.
- Added8 parts on a separate512x512 atlas:140335PNG bytes/1MiB RGBA. All151 prior
  entries/pixels and3 atlas page hashes unchanged; kit now159 parts/12MiB RGBA.
  1782 interior aperture pixels per direction verified transparent, excluding
  the Lanczos edge support. Runtime collision/rules/save format unchanged.
- verify_open_doors.gd baseline28 checks/6fail; final40/0 with actual thief/mage
  unlock, live structural refresh, in-memory save reconstruction, force/repair/
  removal. Both actor traversal axes visually inspected, no pixel-depth oracle.
  Seven existing contact states pass (forced frames now retain16segments).
  verify_master_mobile passes. Independent review found no actionable defect.
- Android0.1.3-test/code4 import/export/signature/packed-resource startup and40
  checks pass, empty Godot stderr. Same package/cert; public prerelease
  android-test-0.1.3 verified digest and HTTP200. SHA256:
  13793b9e2beb2bb70f3959761555caf8fe5a9d6fbddfced8f364c6fe2a6dfc7f.
  No normal player-save access, physical phone/profile check, commit or push.

## Android portrait and orientation changes — 2026-10-27

- User requests portrait and automatic orientation. project.godot now uses
  display/window/handheld/orientation=6 (SENSOR). Godot 4.7.2 exports fullUser13,
  respecting Android's rotation lock; configChanges0x3ff4 includes orientation,
  screenSize/screenLayout. Obsolete preset screen/orientation removed.
- Existing portrait HUD and fixed-scale compensation reused. Resize cancels
  world/palette/radial and ordinary button presses, retaining the session,
  camera centre, selected tool and open menu. Enabled BaseButtons are briefly
  disabled/re-enabled to clear press attempts without changing toggle state.
- First-open catalogue and placement panels had stale minimum sizes; their
  minimum-size changes now queue layout. No new art, game rules or save schema.
- verify_mobile_rotation.gd: baseline220 checks/6 failures; final227/0 across
  five size transitions/51 captures. Real viewport mouse/touch stale-release
  and fresh-input checks included. Existing verify_master_mobile:0 failures.
  Independent review raised retained BaseButton capture; reproduced, fixed,
  re-reviewed with no further actionable finding. Isolated artifact saves only.
- Android0.1.2-test/code3, same package/certificate. Import/export/signature and
  exact packed-resource smoke/227 rotation checks pass, empty Godot stderr.
  Published prerelease android-test-0.1.2; remote digest/local SHA256 match,
  anonymous download HTTP200. APK SHA256:
  125e53a19fe27b942233acb168946d872187364364269b27d020060150e09356.
  No physical sensor/DPI/safe-area/performance validation, commit or push.
  APK includes current uncommitted work; release tag is only the base commit.

## Android header fill containment — 2026-10-27

- User's phone capture shows gold vertical lines rising from both fill endpoints.
  The 3px rounded StyleBoxFlat fill with asymmetric top border/AA is implicated;
  exact device/driver cause was not reproduced on desktop. Do not claim otherwise.
- Header fill now uses a plain borderless non-AA rectangle; existing rounded
  tracks clip their children. Layout, values, game rules and saves unchanged.
- verify_header_gauges.gd checks 40 GPU cases: 8 fractional scales/oversampling
  factors, fill 0/1/54/99/100. No pixel leaks; fill visible and empty at zero.
  Baseline NVIDIA also passed containment. Evidence artifacts/header-gauges-*.
- Android 0.1.1-test/code2 uses the same org.dungeonempire.preview package and
  signing certificate as 0.1.0. Import/export/signature exit0; exact APK resources
  launch on native GPU through initial/prepared/four catalogue families/raid,
  isolated artifact save only. Fresh focused review found no runtime issue.
  Phone confirmation remains pending. No commit/push or engine upgrade.

## Accepted clean door geometry and texture integrated — 2026-10-27

- User approves v7 and explicitly requests integration. v8 selection.json freezes
  v6 geometry, magenta guide, v7 painting, registration and palette. Production
  isometric_seal_texture.cjs reproduces the accepted preview; isometric_seal_door
  retains existing IDs, two-layer split and .8 density. No new ImageGen call.
- Wall junction metadata is now 1/3..2/3, aligned with the two-course jambs.
  Existing segmented wall clipping/depth code is unchanged. Smooth leaf has only
  front/back planes plus perimeter thickness; no modelled leaf hardware returns.
- Export validation compares all four exact models and 75,972 visible interior
  pixels with the accepted preview: zero difference. Split alpha error zero,
  premultiplied rounding under one byte. 143 unrelated regions/pixels/metadata
  unchanged; total 151 sprites, 11MiB RGBA unchanged. PNG -11,135 bytes versus
  the immediately preceding v4 export. Source paintings/guides remain immutable.
- Evidence: door-redesign/seal-v1/painted-v8-integrated/index.html. Import and
  capture exit0/empty stderr; eleven static native views and four gameplay
  screenshots. Seven recorded states cover actors, destruction/restoration and
  unique depth groups. Near-threshold actor overlap inspected using real move
  interpolation. Static contacts: zero interior ownership errors; painted/filter
  boundaries excluded. No pixel-perfect actor oracle or phone/campaign profiling.
- Fresh read-only review found no actionable defect. No UI/economy/camera/save
  change or normal player-save access, commit or push. v6/v7's previous proposal
  and non-integrated statuses below are superseded by this accepted integration.

## Texture created from accepted clean door wireframe — 2026-10-27

- User accepts v6 and requests its texture. Built-in ImageGen uses the actual
  face-guide-magenta.png as edit target, surrounding walls as material reference
  and old painting only for plum wood/iron/violet theme. New native-alpha source,
  original path, exact prompt and reference roles retained under
  door-redesign/seal-v1/painted-v7-clean-leaf/source/. No original source overwritten.
- prepare_seal_clean_texture.cjs previews the exact accepted v6 XYZ in four
  orientations. Battant remains two smooth planes: all clasp/iron/wood/seal
  details on that area are painted, with no hardware geometry reintroduced.
  Junctions remain 1/3..2/3. Uniform source registration; generated stone fronts
  use the existing shared-wall palette transfer, side/top faces the shared B
  finish. Source aspect differs from guide by about 2.58%; prepared geometry and
  silhouette remain XYZ-defined. Original generated pixels/alpha unchanged.
- Current review: painted-v7-clean-leaf/index.html and painted-board.png; front
  source and two enlarged/four .75-scale projected views inspected. These are
  offline geometry renders, not native Godot screenshots or new artistic approval.
  Ten protected source/runtime hashes verified unchanged; no runtime export,
  gameplay, save access, commit or push. Prior v4 export remains active until
  the new appearance is integrated. V6's old proposal status is superseded by
  the user's request to paint it; the new v7 paint still awaits visual feedback.

## Clean door joins and interchangeable smooth leaf wireframe — 2026-10-27

- User requires removing v5's orange fragments and keeping the wooden leaf a
  smooth receiving surface: no modelled clasp, handle, planks or leaf seals.
  They also explicitly ask about the magenta guide. Historical paint used the
  colored frontal face-guide (with hardware), whereas runtime magenta guides
  were inspection output. Do not claim the new magenta guide has been painted.
- New isolated review: door-redesign/seal-v1/wireframe-v6-clean-leaf/index.html.
  prepare_seal_clean_wireframe.cjs moves jamb depth/cut limits to 1/3..2/3,
  coinciding with upper wall joints. Four small fragments removed; widened jamb
  faces fill their old space. Twelve contact endpoints checked, smallest retained
  wall stone 1/6. Frame/horns/upper seal otherwise retained from current geometry.
- 133 leaf hardware faces removed; the unchanged opening contour becomes one
  flat front and back plane with thickness. No inner leaf wire edges. Frontal
  magenta PNG/SVG and separate leaf mask share exact XYZ/mapping with four 2:1
  orientation guides. Board and frontal guide inspected. Future paint variations
  must fit this receiving surface, not reintroduce hard-coded hardware geometry.
- Thirteen source/runtime hashes unchanged by this review. No production
  integration, new paint, Godot run, save access, commit or push. V6 is the new
  geometry proposal; earlier in-progress v4 export remains the runtime state.
  Keep user feedback distinct from technical checks and await geometry review.

## Door junction wireframes requested after masonry/color rejection — 2026-10-27

- User still sees tiny bricks and bad joints at the door feet and explicitly
  requests wireframes. Suspend paint iterations; successful exports do not
  approve the geometry. Current review: door-redesign/seal-v1/wireframe-v5-junctions.
- prepare_seal_junction_wireframe.cjs renders the actual current door XYZ model,
  the base wall courses, and the runtime .365..635 rail cut. Four orange upper
  wall fragments remain between this cut and joints at 1/3 and 2/3: .0316667
  cell long, 9.5% of an upper brick. Two orientations, contact closeup and top
  plan inspected. This is a line/volume schematic; painted erosion, bevels and
  filtering fringes are intentionally absent. Six production hashes unchanged
  by the review generator. No new junction fix applied in this wireframe step.
- Earlier in this turn, uncommitted v4 masonry changes added jamb courses at H/2,
  shared soft-stone B finish on planar masonry, continuous slope grading and a
  stone keystone (formerly tagged metal). Source paintings remain immutable;
  143 non-door regions unchanged, 11MiB RGBA. Initial native captures/import
  passed before the final keystone change, but full final validation and artistic
  approval remain pending. Preserve earlier HUD/trap changes and segmented wall
  depth ordering. No save access, commit or push. Await geometry feedback.

## Approved larger trap square integrated — 2026-10-27

- User approves v11 with “voilà c'est correct”. v12-approved-square/selection.json
  freezes that geometry/board; v9 collar and v10 angled joints remain rejected
  history. The active receiver now uses the exact twelve approved rectangular
  stones around .16..84, z0, with the existing calm floor material.
- Resized slabs retain their original material anchors. A .06 boundary colour
  guard fades by .07, where the geometry is unchanged; this only reconciles
  rounded finish/filtering. A check rejected .10 because an old edge is at .92.
  No overlay collar or restored inner slab cuts. Original paintings unchanged.
- Support registration and raised XYZ grow uniformly by .68/.56 about the cell
  centre; no anisotropic sprite squeeze. All mechanism states share a derived
  padded frame and scaled conservative bounds. Entrave remains a 2.5D surface
  proxy; Pointes retains one shared 3x3 socket layout across its three states.
- Fifteen trap regions updated; two other pages/136 regions unchanged. Trap
  atlas stays512x1024/2MiB RGBA, PNG214176 bytes vs185182 before this turn.
  Derived UI trap icons regenerated; no HUD layout, game rules, state logic,
  save schema or player-save access changed.
- Geometry RED→GREEN (.22 rejected, .16 accepted); 12 exact rectangles,
  area .5376,45 registration round trips. Export checks:220428 identical B1
  border pixels,2600 identical state-ground samples,transparent mechanism
  margins. Godot import and two GPU captures exit0/empty stderr;11 state
  scenarios pass. Nine-state scene, neighbouring paving and actor views inspected.
- Independent read-only review found no actionable issue. Visible mechanism
  geometry fits bounds; invisible unmasked jaw tessellation corners do not
  affect it. B3/B4's single boundary-pixel difference from B1 predates this work.
  Native evidence and review in trap-review/v12-approved-square. Painted result
  is an integration adaptation, not automatic artistic approval. No exact actor
  depth oracle, phone/performance/full-campaign check, commit or push.

## Larger square socket with straight paving joints — 2026-10-27

- User rejects v10's angled joints and requests simply enlarging the central
  square. This supersedes that proposed geometry; remain in wireframe review.
- New isolated study: trap-review/v11-larger-square/index.html and
  wireframe-board.png, generated by prepare_trap_square_wireframe.cjs.
  Centred opening grows from .22..78 to .16..84 (side .56 to .68, +21.43%).
  The four inner B1 slabs are removed. Only two lower side stones change
  width; all stones remain rectangles, with existing joints elsewhere intact.
  No collar or angled/stepped joint is added. Same z0 and shared camera.
- Board shows the surrounding 3x3 paving and top view; a dashed inner square
  indicates the previous opening size. Whole-rectangle checks cover 96 stones,
  384 projected edges on the two 2:1 axes, exact coverage and zero overlap.
  Geometry outside the central cell is unchanged. Eight watched production
  and v10 evidence hashes verified unchanged; board visually inspected.
- This is an unapproved dimension/layout proposal, not texture integration.
  No source painting, active atlas/generator, scene, gameplay, save, Godot run,
  commit or push. Keep v10 as rejected historical evidence; await feedback.

## Trap paving wireframe revised before textures — 2026-10-26

- User rejects v9's added collar: it still visibly cuts the original outer
  stones. They explicitly request fixing the wireframe first. Do not treat
  v9's successful technical checks as approval of its paving appearance.
- Isolated proposal: trap-review/v10-paving-wireframe/wireframe-board.png.
  prepare_trap_paving_wireframe.cjs replaces the four inner B1 slabs with a
  square opening and reshapes twelve existing boundary-crossing stones up
  to that opening. Complete outlines include their unchanged neighbouring
  portions; there is no extra inner collar or seam at the logical cell edge.
- Slightly angled interior stone joints are a proposed design choice, not
  approved geometry. Same .22..78 opening, z0 and shared 2:1 projection.
  Board shows a 3x3 neighbourhood and top view with logical grid distinguished
  from real joints. Geometry JSON retains full outlines and original pieces.
- Checks: area .6864, no overlap or stone in opening, twelve connected closed
  outlines, 529200 sample comparisons of new outlines against intended unions
  and unchanged neighbouring geometry. Board visually inspected. No painted
  source, production generator, sprite, atlas, scene or gameplay changed in
  this wireframe step; no Godot run, save access, commit or push. Await visual
  feedback before texture work. V9 remains historical/current runtime evidence.

## Registered trap supports and purpose-built paving — 2026-10-26

- User rejects the apparent pasted/cut-out traps, then explicitly requires
  paving laid around the central square. This supersedes v7's intact B-floor
  crop around .22..78 as a satisfactory receiver. No new artwork generation.
- isometric_trap_receiver.cjs builds eight complete framing stones on z0:
  four sides/four corners, outer .10..90 and opening .22..78, using the same
  calm stone material. The outer .06 boundary strip stays pixel-identical to
  B1 for adjacency. No raised curb or deep pit; the thin seam is flush.
- isometric_trap_registration.cjs maps support paint into the exact2:1 floor
  plane, independently of raised parts. Pointes uses fixed3x3 empty sockets
  across states and projected pyramid facets textured from selected paint.
  Entrave uses a height-aware2.5D jaw surface, not reconstructed hidden volume.
  Raised paint is removed from the floor layer; original source hashes intact.
- All15 trap regions updated, same512x1024 page/2MiB RGBA (PNG185182 vs200743).
  136 unrelated regions and both other atlas pages unchanged. Derived HUD trap
  glyphs regenerated. State machine, charges, effects, saves and camera untouched.
- Native scene overview plus ready/triggered/spent closeups and actor views
  inspected in trap-review/v9-registered-sockets. Import/captures exit0/empty
  stderr; painted trap harness11 recorded checks passed, including repair,
  pause, lethal hit, live clock, rebuild and removal. Export validation checks
  eight nonoverlapping stones,220428 unchanged boundary pixels and2600 shared
  spike-ground pixels (5200 old cross-state differences,0 now in that interior).
  Actor overlap inspected visually, not a pixel-depth oracle. No phone/full
  campaign profiling, commit or push. Artistic feedback still belongs to user.

## All trap states presentation scene — 2026-10-26

- User requests one scene showing all traps and all their states. New
  scenes/DungeonTraps.tscn presents Pointes/Entrave/Néant in rows and
  ready/triggered/spent in columns, with French labels and frozen states.
- @tool trap_states_preview.gd reuses the native renderer, grid projection,
  socket paving and all15 existing prepared trap layers. No new paint, atlas,
  simulation session, save access or behavior changes. Shared preview camera
  stays.75 with drag panning. Visible both as an editor tool and when run viaF6.
- Native1280x720 capture inspected: nine examples,15 actual prepared layers,
  capture exit0/empty stderr. Import exit0/empty stderr. Evidence in
  trap-review/v8-state-scene; capture_trap_states_preview.gd regenerates it.
  Earlier uncommitted header corrections preserved. No commit/push.

## Header alignment, readable eye and raid hint — 2026-10-26

- User reports separated icons/values, floating gauges, portal-like eye and a
  construction hint during raids. Header footprint stays96/84; painted band
  uses its height, paired icon/value groups share measured baselines, gauges
  are inset into the lower iron rail. Eye84/72 instead of76/64; health plaque
  attached below it. Long captions and five-digit gold fit narrow layouts.
- Built-in ImageGen retouches only the intended inner-eye design with a radial
  iris/round pupil, preserving the ten-rune frame visually. Source/prompt and
  user reference retained in interface-review/v11-header-alignment/source;
  v10 sources immutable. Native alpha/uniform preparation via prepare_master_ui.
  Runtime eye192x194,93552bytes (-2710); other production art unchanged.
  Shader keeps pupil/reflection fixed with subtle pulse; life sectors retained.
- Hint refreshes from raid/access/preparation state, with no construction text
  during raids. Landscape hint reserves space for1x/2x buttons. No game rules,
  camera, economy, save schema or player-save access changes.
-30 final native captures/five sizes,150 header labels/no measured clipping;
  short landscape, portrait, five-digit totals and raid hint inspected.
  Import/capture exit0/empty stderr; verify_master_mobile exit0/0 failures with
  raid/access/return transitions included. Evidence and limits in v11. No
  physical phone/profile validation, commit or push. Appearance awaits feedback.

## Master mobile HUD first integration — 2026-10-26

- User requests implementation of Claude Design PDF v2 plus24818 header capture.
  Replaces permanent Forge rail with fullscreen world, painted stone/vortex band,
  contextual radial and temporary catalogue/selection sheets. Fixed camera and
  portrait compensation unchanged. Current review: interface-review/v10-master-mobile.
- Native-alpha ImageGen header/ten-rune eye reconstructed from screenshot;
  originals/prompts retained. This is an integration adaptation, not the original
  Claude export or automatic artistic approval. Uniform preparation in
  tools/prepare_master_ui.cjs; current painted trap atlas supplies new glyphs.
  Cinzel OFL bundled, MSDF enabled. New production files ~520KiB incl.font;
  HUD PNGs <.8MiB uncompressed RGBA. Dungeon atlas pixels unchanged.
- Four stable radial families, existing unlocked variants only, max5 quick
  wedges at48-unit thickness; Tout reaches all. Empty-cell choice places once
  and keeps tool armed. Pan/invalid taps preserve it; Back/Arrêter stops. Occupied
  replacements retain confirmation. Catalogue tabs, locked levels, repairs,
  exact transfers, initial heart, pause/reset/result/save guards remain native.
- Short landscape moves radial footer beside rings (420x208), header84 high;
  regular260x256/header96. Fullscreen HUD shields prevent click-through.
  Access dots show geometric access, not predicted AI routes. Floor guides draw
  after floor container atz0 and beneath z1 solids. Runtime1x/2x uses bounded
  simulation substeps, no save schema or balance changes.
- tools/verify_master_mobile.gd exercises transactions, real viewport taps/pan,
  four corners through568x299, cancellation/two-finger rearm, disk-write failure
  visibility and2x/pause. Final exit0/empty stderr. Native112captures/7sizes in
  v10, no measured label overflow; critical states and short/portrait inspected.
  Independent read-only review found save-error, multitouch, font and short
  radial issues; corrected and re-reviewed with no remaining concrete finding.
- Review uses isolated artifact paths; no normal player-save access. Import
  exit0/empty stderr; no hardware phone/multitouch/safe-area/performance profile
  or full campaign audit. Replay/sharing/new traps/multihero rewards, six eye
  emotion animations and catalogue long-press sheets are not included. Edge
  recenter is immediate. No commit/push. See v10/validation.md and plan ledger.

## Accepted painted traps and three runtime states integrated — 2026-10-26

- User authorizes integration after v6 centered Entrave. selection.json in
  trap-review/v7-integrated-paint freezes v5 Pointes/Néant and v6 Entrave sources.
  isometric_painted_traps.cjs replaces the old procedural preparation in export.
  Uniform fit, common cell-centre anchors, exact native flush aperture; source
  paintings immutable. Raised parts use separate source silhouette/support
  proxies; this is not reconstructed 3D geometry. No new ImageGen call.
- Receiver uses floor-b1, whose crossing stones match all current B variants.
  Legacy floor.png had incompatible joints. Outside paving271836 pixels checked
  identical; two earlier atlas pages and136 entries unchanged. Trap page now
  512x1024,15regions,200743PNG bytes/2MiB RGBA; total kit11MiB (+1MiB).
- RaidDirector emits trap_activated only after successful consumption/effects.
  Ready/triggered/spent swaps preserve sprite frames and support bounds. Short
  presentation clock survives lethal raid end, freezes in pause/results/guards,
  resumes afterward; repair/removal/new raid/reset clear stale effects. No
  economy, charge count, damage, save format, camera or HUD glyph/layout change.
- Independent review identified lethal-hit skip and inherited asset watcher
  disabling the new clock. Both reproduced red then green; view keeps processing
  while effects exist, including after rebuild. Native final capture exit0,
  empty stderr,11 recorded scenarios plus removal and actor overlap views.
  Sources/atlas checks and native board inspected. Evidence under v7; earlier
  captures retained. No phone profile/full campaign audit/player-save access,
  commit or push. Native art is an integration adaptation of selected paint.

## Entrave mechanism recentered on its paving — 2026-10-26

- User reports Entrave is too far forward in its cell. Isolated v6 review edits
  only this painted three-state sheet via built-in ImageGen. First relocation
  was too slight; second moves the mechanism and flush dark insert toward the
  cell centre. Same support placement across open/closed/exhausted views.
- Current comparison: docs/reference/trap-review/v6-centered-snare/comparison.png.
  Original native-alpha sources, both prompts and centering diagrams retained;
  prepare-review.cjs makes labeled before/after and reduced views, both inspected.
  Geometric guide is approximate illustration registration, not calibrated XYZ.
  Generated paving was locally repainted; this is not a pixel-exact translation.
- Final source matches the generated original; six production baseline hashes
  unchanged. Pointes/Néant and runtime untouched. Visual proposal only, not
  integrated or artistically approved. No game tests, commit or push.

## Entrave and Néant supports brought flush with paving — 2026-10-26

- User requires Entrave and Néant to sit at the same floor level as Pointes,
  rejecting v4's sunken appearance. This supersedes the visible pit-wall/deep
  recess interpretation for these painted proposals; preserve historical guides.
- v5-flush-states edits only those two sheets through built-in ImageGen using
  Pointes as the floor-contact reference. Three states retained; visible pit
  walls removed, dark insert/obsidian supports meet paving with a thin seam.
  Pointes source is copied byte-identically from v4. Originals and prompts saved.
- Current review: docs/reference/trap-review/v5-flush-states/comparison.png and
  index.html; generator prepare_painted_trap_states.cjs --flush. Full comparison
  inspected; source hashes/native alpha verified and production baseline unchanged.
  Appearance proposal only; no calibrated XYZ change or runtime integration,
  gameplay/save change, tests, commit or push. Triggered remains a proposed state.

## Trap paint rejected; full state sheets proposed — 2026-10-26

- User rejects v3 trap images and gray backing, says Entrave does not read as a
  trap, and requests seeing the different states. Keep the approved inset floor
  concept; do not treat the earlier "Ok" as continuing approval of v3's paint.
- New isolated appearance review: trap-review/v4-painted-states/index.html and
  comparison.png. Three built-in ImageGen sheets, each with armed/triggered/spent
  views. Dark recessed housings, polished steel facets, an articulated two-jaw
  Entrave with pedal/springs, and an inset obsidian seal/vortex for Néant.
- Armed spikes show retracted tips, triggered spikes extend, spent sockets are
  dark. Entrave opens when armed and closes when triggered; depleted stays
  latched with energy off. Néant is charged/open/extinguished. Triggered is a
  newly proposed transient visual state, not implemented animation or a rule change.
- Original generated PNGs and exact prompts/references retained in source/ and
  brief.json. Editorial framing only (alpha>32 bounding measurement plus24px
  padding), native alpha unchanged within crop, uniform resize; no raster warp,
  mirroring or repaint by code. Generated perspectives follow the guides visually
  but are not calibrated native XYZ/registration or approved production artwork.
- Inspected full sheets, labeled comparison and reduced views. Source copies
  match originals; production baseline hashes unchanged. These proposals are not
  integrated: existing v3 assets/runtime remain until the visual direction is
  settled. No Godot/gameplay/save change, automated tests, commit or push.

## Approved socket wireframe; three inset traps integrated — 2026-10-26

- User's latest "Ok" approves v2-inset-floor geometry, frozen by selection.json.
  This supersedes its old proposal status; it does not approve new painted art.
  Pointes, Entrave and Néant now replace the full floor tile with the same
  periodic paving cut around the .22.. .78 opening; insert remains at z=-.025.
- New geometry-native generator isometric_inset_traps.cjs uses the shared camera,
  original floor pixels and a built-in ImageGen iron material, retained with
  prompt/provenance under trap-review/v3-integrated/source. No raised stone base.
  Nine spikes / toothed jaws are separate physically ordered solids; the violet
  seal is recessed. Charge zero retracts the solids or extinguishes the seal.
- Game view swaps matching ready/spent floor textures without a scene rebuild;
  existing charge rings remain. No HUD redesign, economy, effects, charge counts,
  save schema, hero behavior or camera change. Old provisional triangles removed.
- Third atlas512x512:8 regions,106068PNG bytes/1MiB RGBA; total144 regions/10MiB.
  Two earlier PNG pages and136 region entries unchanged.174960 surrounding floor
  pixels checked identical. Existing door junction split/order preserved.
- Evidence: trap-review/v3-integrated/index.html and review-board.png (native GPU
  details at2x and game view at.75), export-validation.json/native-validation.json.
  Import exit0/empty stderr; isolated native capture exit0/empty stderr,8 states
  including missing-charge defaults, spent rebuild, repair, partial charge,
  actor and removal. Original red check failed on missing prepared trap floors.
- Focused independent review found no concrete actionable bug. Exact actor
  occlusion inspected visually, no pixel oracle/full raid/device performance
  claim. No player-save access, commit or push. Prior proposals remain history.

## Trap floor socket wireframe proposed — 2026-10-26

- User rejects the traps looking placed on top of the floor; requests a new
  floor tile with a central square into which the trap texture fits. V1's raised
  bases are superseded as an integration direction, not approved trap artwork.
- Isolated review: docs/reference/trap-review/v2-inset-floor/wireframe-board.png.
  One logical1x1 floor module, central .22.. .78 square cutout, chamfer to
  .235.. .765 at z=-.02, cavity bottom-.09, receiving insert-.025. Surrounding
  periodic stones remain at z0. No extra raised perimeter. Dimensions proposed.
- prepare_inset_trap_wireframe.cjs renders the actual shared XYZ projection with
  depth-tested cavity faces, empty/idle/raised-pointes diagrams and a section.
  Checks: no floor inside the opening; frame never above ground; square opening;
  exact2:1 ground projection; insert below ground. Nine spikes rooted in sockets.
- This is a geometric design review, not production integration or approved
  art. Same receiver is intended for Pointes/Entrave/Néant. No ImageGen call,
  raster art edit, active asset/script change, Godot run, save access, tests,
  commit or push. Old proposals are retained.

## First three trap appearances proposed — 2026-10-26

- User asks to make the traps. Scope question (three existing traps or Pointes
  first) was optional and unanswered; defaulted to the existing Pointes/Entrave/
  Néant trio, as an appearance review. No selection or production integration.
- Current board: docs/reference/trap-review/v1/revised/comparison.png; index.html
  includes source and prompt links. Six built-in ImageGen sources retained,
  native alpha, uniform resizing only, proposed96px width on existing paving.
- Shared blue slate/iron/violet; spike insert, open jaw mechanism, floor-plane
  banishment portal. Original proposals copied the UI spike icon's steep camera.
  Code-native XYZ guides use the exact shared2:1 camera; revised paintings use
  those guides but remain approximate, not validated exact projected geometry.
  Pointes source has eight spikes and a blank front pad despite the requested
  nine-spike guide; retain as an unselected design, don't claim exact matching.
- prepare_trap_guides.cjs uses a depth buffer; prepare_trap_review.cjs produces
  offline boards, not GPU captures. Guides themselves are proposals, not frozen
  approved geometry. Ready/triggered/spent states, support/contact fitting and
  native integration remain pending. No rules, charges, UI, game saves, active
  atlas, automated tests, commit or push changed. Review directory has .gdignore.

## Sceau interdit: far-jamb occlusion corrected — 2026-10-26

- User rejects v2 joins again. Its claimed successful join inspection below was
  incomplete: the far rail was drawn before the complete lower door, so the
  jamb overpainted the retained foreground rail. This is a depth-order defect,
  not a reason to repaint or lower the door. V2 images remain as before evidence.
- Split intersecting wall supports into retained ranges before/after .365..635
  after variant selection and before sorting. Preserve full texture anchors and
  rectangles, recompute each segment's physical bounds/depth. Ornaments inherit
  the clip; gameplay keeps separate solid groups. The shader clips each segment
  and reuses its original terminal paint; the door-alpha workaround is removed.
- No source image, geometry, prepared sprite, atlas, UI or gameplay rule changed.
  Adds two wall draw segments per door with both side rails; texture memory stays
  unchanged. Lookup and segments rebuild when a door is removed or restored.
- Evidence: door-redesign/seal-v1/painted-v3/. Exact XYZ ray-union comparison of
  the south contact:3622 legacy interior ownership errors,0 with native recorded
  segment order. Painted bevel/filter boundaries are excluded, not claimed exact.
  Eleven native static views cover four orientations; five isolated game states
  exercise actor insertion and destroyed/restored doors,16/0/16 segments and
  distinct solid groups. Two game-view captures inspected. Empty capture stderr.
- Focused independent review confirms the original occlusion defect and no
  further concrete issue in the fix. No player save access, phone/performance
  profiling, full raid simulation, commit or push.

## Sceau interdit: wall joins and stone corrected — 2026-10-26

- User rejects painted-v1 joins and stone style; this supersedes that appearance.
  Current evidence: door-redesign/seal-v1/painted-v2/index.html and native/.
- All stone now uses the same walls-planes material and B.materials profiles as
  the walls, with quiet edge finish. Generated paint retained only on wood,
  metal and seals. Upper/inner frame, horns and leaf geometry preserved.
- Outer masonry below H intentionally adapted to two closed flush jamb blocks:
  x=-T/2.. .17 and .83..1+T/2, y=.365..635, z=0..H. Original reviewed source
  remains immutable; this is the requested join correction, not a new approval.
  Junction top faces belong to the lower sprite. No notched cap or hidden foot
  in current four-direction native views. Existing local rail cut remains.
- Export/import/capture exit0 with empty stderr;8/0/8 cut rails on door
  present/removed/restored. Fresh focused review found no concrete regression.
  Refreshed projection check passes;128 unrelated region pixels/metadata stay
  unchanged.136 sprites,9MiB RGBA, PNG delta -43,535 bytes vs pre-door baseline.
- .gdignore excludes review sources from Godot; .gitignore excludes disposable
  packing studies. No player saves, UI/rule changes, phone/profile/full-raid
  checks, commit or push. New appearance still awaits the user's feedback.

## Sceau interdit door painted and integrated — 2026-10-26

- User selects concept C, then approves seal-v1 wireframe with "Ok go".
  Geometry/camera/source hashes frozen in door-redesign/seal-v1/painted-v1.
  New ImageGen frontal painting, original/prompt retained; dark plum wood,
  slate stone and restrained violet seals. New painting awaits artistic feedback.
- tools/isometric_seal_door.cjs maps paint onto the exact approved XYZ model,
  rotates four directions and splits final pixels at wall height with opaque
  filtering overlap. Existing door IDs and logical size retained; .8 source
  raster density avoids growing the main atlas. Historical sources unchanged.
- Approved corridor geometry requires rail gaps at .365..635. Door metadata
  declares the junction; renderer only cuts those adjoining rails/ornaments.
  door_wall_junction shader reconstructs the rail surface, reuses its painted
  terminal for the cut cap, and lets prepared door alpha occlude that cap.
  Lookup/materials rebuild with occupancy. No new runtime texture or game rule.
- Final export/import and11 native static captures exit0/empty stderr. Four
  orientations inspected; removing/restoring doors gives8/0/8 cut rails. Focused
  independent review found join/guide-provenance issues, now fixed; final review
  found no remaining concrete issue.128 unrelated regions retain pixels and
  metadata.136 sprites, total9MiB RGBA unchanged; PNG delta+14,164 bytes.
- Evidence: door-redesign/seal-v1/painted-v1/index.html and native-joined/.
  Native/ is earlier pre-junction evidence. Review source folder has .gdignore.
  No player save access, UI/economy changes, phone/performance/full-raid check,
  commit or push. Existing Claude UI work remains untouched.

## Forge UX pass 2: four families, portrait scale, faithful mocks — 2026-10-26

- Review of the pass-1 PDF: Trésors hidden at 844x390, Pièges cut at 740/667,
  small portrait dungeon, smooth generic mock panels, eye→cross morph. Keep the
  portrait dock, strict world/controls split, two-level catalogue, padding,
  persistent timer, separate resources, chest/trap rings, rock environment.
- game_hud.gd modes: column (landscape safe height >= 600, rail 136), wide
  (shorter landscape, rail 252: timer+resources side by side, families 2x2,
  Annuler/Observer row; catalogue/selection same width), dock (portrait).
  Placement bar in a reserved 64-unit slot: armed variant/cost or refusal plus
  labelled "Arrêter"; arming never resizes the world. Stable labelled tiles
  Annuler/Observer and Bâtir/Centrer/Pause. Clock building note "Délai suspendu".
- hud_notices.gd: display-only French wording of v1.0.0 sim messages; sim text
  and rules untouched. Do not translate inside dungeon_sim.gd for UI purposes.
- game_input.gd presentation_scale(): camera zoom .75 x max(1, short side x
  visible.x / (720 x window.x)); compensates canvas_items/expand in portrait
  (x1.78), 1 on landscape >= 16:9. Not dungeon-extent dependent; pan divides
  by camera.zoom. 4:3 landscape tablets would also get >1 (not captured).
- Evidence: interface-review/design-pass-2/. capture_forge_navigation.gd
  --design-pass-2: 78 states/6 sizes, incl. scale-before at identical size;
  geometry+ellipsis/line-count check 0 issues (649 labels measured).
  tools/review_forge_interactions.gd: synthetic taps through the real viewport,
  review slot user://forge_ux_review_v2.save removed after, player save SHA-256
  unchanged; 53 checks, 0 failures on 844x390/667x375/390x844/320x568.
- Claude Design canvas claude.ai/artifact/8jkFUgqyG3KxoqmUNmCiQx v8: pass-1
  boards kept, P2 boards added. tools/build_forge_review_boards.cjs writes the
  mocks (Godot-exported stone/icons in mock-kit/, layout mirrors game_hud.gd) and
  the print page; revue-ui-forge.pdf (13 pages, fonts/images embedded) printed
  by headless Chrome. artifact-assets.json maps repo files to canvas blobs.
- Import/capture/review exit0, empty stderr (import: Android build-tools notice
  only). No touch-device validation, DPI/safe-area or performance test, no rule,
  economy, save or sprite change, no automated test suite, commit or push.

## Forge UX pass: portrait dock and armed-tool feedback — 2026-10-26

- User requests a UX/UI diagnosis and coherent native improvement using Claude
  Design. Claude Design is available as the claude.ai Design Artifact type (no
  design system attached). Canvas: claude.ai/artifact/8jkFUgqyG3KxoqmUNmCiQx,
  diagnostic + landscape/portrait mocks + native results. Mocks are proposals.
- Portrait (height > width) now uses a full-width bottom dock: timer+resources
  in one 58-unit row, families 2x2 with undo/observe column, sheets (catalogue
  2 columns from 340 units, selection, menus) capped at 55% height. Landscape
  keeps the 136/244/56 rail; family rows 56 below 420 high so three fit at 390.
- Armed tool: family row shows variant icon/name/cost; observe becomes a cross
  "Arrêter la pose" (cancel_selection). Status line only for real notices, two
  lines max; default "Aménagement" no longer shown nor repeated in domain menu.
  New code-native undo.svg/eye.svg in assets/ui/forge. Selection header is one
  row (icon/title/close); transfer steps in a grid, "Tout" beside the amount.
- Evidence: capture_forge_navigation.gd --design-pass, 72 states/six sizes incl.
  667x375 into interface-review/design-pass. Import/capture exit0, capture
  stderr empty (import stderr: Android build-tools notice only). Geometry check:
  0 targets <48, overflow or HUD/world overlap (previous capture set: 14 panel
  overflows of 2-7 units). No rules/economy/save/sprite changes, no device touch
  test, no automated tests, commit or push.

## Tighter spacing between HUD blocks — 2026-10-26

- Removed the extra 4-unit layout gaps between timer, resources and menu;
  transparent padding in the stone art keeps their frames visibly separate.
  Interior padding and block dimensions unchanged. `--block-spacing` captures
  ten native views/five sizes plus extension in interface-review/block-spacing;
  exit0/empty stderr, landscape and portrait inspected. No tests or commit/push.

## Resource block horizontal spacing — 2026-10-26

- Gold and health now occupy expanding columns: on wide panels the gold group
  anchors left and health right, each icon stays 8 units from its number and
  outer padding stays 14. On narrow stacked rows values share the right edge.
- Focused native capture flag `--resource-spacing` writes ten views/five sizes
  plus extension under interface-review/resource-spacing, preserving prior
  captures. Exit0/empty stderr; wide/stacked/portrait views inspected. No tests,
  gameplay changes, user-save access, commit or push.

## Direct catalogue, persistent clock and mobile status rings — 2026-10-26

- User requests consistent menus, two construction levels, shorter centred
  catalogue cards, a visible raid timer and the previous mobile pie gauges.
  Main rail now offers Terrain/Portes/Pièges/Trésors directly, then a scrolling
  list of variants. Selecting one returns to repeated placement. No quick-tool
  shortcut layer. Cards are 72 units with horizontal icon/text and vertical
  centring. Family rows remain 58 units with 30-unit glyphs and 14/12 padding.
- A temporary small-screen square grid was rejected for crowding. It is removed:
  keep padded list rows and scroll on short screens. Widths remain 136/244/56;
  do not restore mini-buttons merely to fit everything above the fold.
- Timer is fixed above the menus, 12-unit insets, 60 high on short layouts and
  84 otherwise. Shows preparation countdown, elapsed raid time, pause or unmet
  prerequisites. Existing countdown suspension rules unchanged. Gold/health
  are a separate standalone block, retained in submenus, horizontal when wide;
  removed duplicated totals/health from the domain menu. Observation stays narrow.
- Transparent gaps show the existing world-mapped rock material via a cached
  four-vertex HUD backing quad. Same projection/camera, no room rendering under
  UI, no new terrain textures. All panels use the existing stone/violet skin.
- v1.0.0 vault/trap rings adapted into ui/world_badge.gd: gold fill ratio for
  vaults, copper remaining-charge ratio for traps, charge segments and lock
  state. User explicitly replaces the chest glyph with a gold coin pile;
  assets/ui/forge/coins.svg extends existing code-native utility art. No chest
  health is invented. Exact amounts/charges remain in cell selection.
- Rings stay 32 logical screen units through project stretch/DPI and render
  above masonry (z=10 relative); actual props/trap ground markers keep depth.
  No economy, save schema, raid AI, camera scale or approved painted art changes.
- Presentation evidence: interface-review/catalogue-direct/, static native
  capture tool capture_forge_navigation.gd, 80 states across five viewport sizes
  plus extension. No main player-save access, automated tests, phone gestures,
  performance profile, commit or push. Prior review captures remain untouched.
  Final native capture and headless import both exit0 with empty stderr;
  checked tall/narrow/short views, catalogue, domain and bottom scroll visually.

## Forge padding and resource icons aligned — 2026-10-25

- User requests more interior space, Catalogue icon equal to Door, and real
  gold/health symbols aligned with the tools. Shared rows now use30px icon boxes,
  14px horizontal/12px vertical padding and8px icon/text gap. Tool/Catalogue
  buttons stay58px high rather than expanding. Resource rows share the same
  columns with a gold coin and new code-native violet health-heart SVG.
- PNG canvas padding caused another mismatch (chest subject93px vs door138px
  in144px sources). Generated AtlasTexture regions normalize display framing
  without repainting PNGs; alpha8 measures bounds with3px padding. Generator:
  prepare_native_forge.cjs, metadata assets/ui/forge/icon_regions.gd. Shared
  theme caches these regions. Health glyph extends the existing utility SVG style.
- On short screens the tools/resources area scrolls, retaining readable padding;
  status and Undo/See remain fixed. Thin scrollbar preserves full Catalogue label.
  Rail width and dungeon viewport unchanged. No gameplay or camera changes.
- Evidence: interface-review/spacing-hud/,16 native static captures/four sizes,
  includes top/bottom scroll positions, catalogue and observation. Capture and
  import exit0/empty stderr. No player save, automated tests, phone gesture or
  performance validation, commit or push. Earlier compact captures preserved.

## Forge button stretch and heart label corrected — 2026-10-25

- User rejects tall construction buttons and reports the heart text on the
  bottom border. Native1280x720 reproduction: quick buttons168/169px high;
  treasury child minimum41px exceeded its35px available area.
- Quick buttons no longer expand vertically:52 logical units,48 below390px
  usable height. An empty spring takes extra rail height before Undo/See.
  Treasury height follows its text minimum plus11px padding on each side (63px
  with the current font). Short screens keep one ellipsized status line; full
  notice remains in its tooltip and domain menu. Rail width and world unchanged.
- capture_forge_compact_hud.gd preserves12 before and12 after native views in
  interface-review/compact-hud, including245 gold/58% heart, four screen sizes,
  tools/catalogue/observation. Both captures and final import exit0/empty stderr.
  Viewed all four tools captures and measured bounds. No new image generation,
  gameplay change, automated tests, user-save access, commit or push.

## Approved Forge and real rock cutout integrated — 2026-10-25

- User requested implementation of v9-rock-cutout. selection.json freezes that
  mock and supersedes its pending status; previous notes/captures stay immutable.
  Native appearance is an implementation adaptation, not newly approved pixels.
- DungeonGame now reserves a separate PlayArea/World SubViewport for the dungeon.
  Stone/violet rail uses 136 logical units, observation56, expanded244 maximum.
  Native painted build icons, MSDF text, 48-unit targets, scrolling panels and
  narrow catalogue fallback. Pause/treasury offers raid; UI never overlays world.
- Direct repeat placement on ordinary rock/floor; initial core and occupied
  replacement retain confirmation. Palette drag uses raised52-unit preview and
  validates both actual drop and raised target. World drag only pans; canceled
  touch, second finger, focus loss cancel placement. Fixed.75 camera unchanged.
- Transient undo stores up to32 construction snapshots, including affected raid
  knowledge/timer; cleared on raid/reset/collection/absorption/transfer, not saved.
  Preserve economy, progression and save schema. --forge-review uses a separate
  user://forge_review_v1.save; never the main player save for validation.
- Terrain union margin.90, cap z=.3133333333333333, raw ground z0, exposed faces;
  cached meshes rebuild only on excavated occupancy changes. Three world-mapped
  materials; 64x64-world coverage includes16x16 map/camera margin, not streaming.
  Shader patch distribution adapts the mock for GPU, not exact Canvas2D pixels.
- Thirteen native PNGs adopted by prepare_native_forge.cjs:12 unchanged copies
  and stone uniformly64px for11px slice margins. Provenance in assets/ui/forge.
  Existing dungeon atlases/approved artwork preserved; no new art generation.
- Import exit0/empty stderr. Native GPU captures:55 presentations across five
  sizes plus extended layout; see interface-review/implementation and capture
  logs. Manual isolated mouse review verified core confirm, repeated dig costs,
  undo refund/terrain, pan without purchase, palette placement/UI cancellation,
  catalogue retraction and observation/pause. Control window closed afterward.
- One independent code review found modal-priority, canceled-touch and actual
  drop-boundary defects; all corrected. Presentation refinements fixed small
  text scaling, long-card overflow and narrow contextual actions. No physical
  multitouch/DPI/safe-area test, full raid/save audit or phone profile. No
  automated tests, commit or push. Details: docs/gameplay/forge-integration-2026-10-25.md.

## Soft clearance rejected; geometric rock cutout proposed — 2026-10-25

- User explicitly requires a real cutout, not the v8 shadow-like band. Current
  isolated mock: docs/reference/interface-review/v9-rock-cutout/. Remove the
  soft clearance passes. Subtract an enlarged opening from the terrain alpha,
  exposing a separate raw ground plane at z=0 around the masonry.
- Opening is the union of cell rectangles expanded by 0.90 world cell, with
  bevelled corners and shallow deterministic edge chips. Cache the contour by
  cell occupancy and margin. This width/appearance remains a proposal.
- Visible inner rock faces connect z=0 to the unchanged masonry cap height
  0.3133333333333333. Texture coordinates follow world axes across adjacent
  face segments. Exterior never rises above walls. No new images or UI changes.
- Fresh offline render on three landscape sizes: no errors/layout failures.
  Extension: 36 cells, 34 valid boundaries, one joined cut contour. All 34
  sampled gap pixels have zero exterior-layer alpha; an exterior sample is
  opaque. Reset restores identical pixels; all 16 asset PNGs and production
  baseline hashes unchanged. Initial/extended/mobile captures inspected.
  Mock only, not artistic approval or Godot/device validation. No commit/push.

## Exterior texture clearance proposed — 2026-10-25

- User requests space between the masonry and exterior texture because v7 is
  too close. Current mock: docs/reference/interface-review/v8-wall-clearance/.
  A quiet dark stone strip extends 0.46 logical cell from the cell union, plus
  0.20 cell transition; masonry occupies part of that width. This spacing is
  a proposed visual choice, not an approved dimension or appearance.
- Apply one compound nonzero path per opacity pass so neighbouring cells do
  not accumulate darkness. The margin follows excavation, corners and room
  extensions in world coordinates. Same wall-cap plane and masks as v7; no
  raised rock, new sprites, generation, camera or UI changes.
- Fresh offline render: three landscape sizes, no errors/layout failures,
  36-cell expansion with 34 valid boundaries and exact reset pixels. Viewed
  initial and extended rooms. All 16 PNG assets and production baseline hashes
  unchanged. Mock only; no Godot integration, device profile, commit or push.

## Exterior piles and raised cutaway rejected; flush rock mock — 2026-10-25

- User rejects the v6 piles resting on the exterior texture and explicitly
  requires exterior rock not to be higher than the masonry. The liked image
  was a material/crystal reference, not approval of freestanding formations.
  This supersedes the placement interpretation below and the raised v5 faces.
- Current isolated proposal: docs/reference/interface-review/v7-flush-rock/.
  Remove outcrop/rubble sprites and raised rear faces. All exterior material,
  hole masks and border fringes share the actual catalogue wall-cap height,
  0.3133333333333333, on every side. Masonry, pillars, camera and UI unchanged.
- Quiet material and strata retain v6 pixels. Reuse the earlier top-down native
  alpha mineral-vein source, uniformly reduced to256px, in the same XY plane.
  Source/prompt/provenance retained; no new ImageGen call. This inclusion and
  the new transition are proposals, not user-approved appearances.
- Offline in-memory captures on three landscape sizes: no browser errors or
  layout failures.36-cell extension has34 valid boundary edges; exact pixels
  return on reset.31 shared mineral patches preserve world position/scale and
  follow a40x20px pan exactly. No elevated rock assets are loaded. Viewed initial
  build/observation and extended-room captures. Production baseline hashes
  unchanged. No Godot integration, game tests, device profile, commit or push.

## Rock variety and liked crystal outcrop mock — 2026-10-25

- User finds v5's rock texture too uniform and explicitly likes the existing
  v4 blue-rock cluster with violet crystals. Reuse that artwork; this does not
  revert their selected rooms-excavated-in-rock direction to an open cavern.
- Current isolated proposal: docs/reference/interface-review/v6-rock-variety/.
  New ImageGen calm top material256px and native-alpha strata384x192, prompts
  and originals retained. Uniform downsample only. Top material repeats every
  3world cells, rear faces keep v5's2cell material. Same cutaway and UI geometry.
- Coarse world-coordinate strata patches and broad ambient shadow pockets
  vary the texture density. v4 outcrop/rubble PNGs are reused byte-for-byte;
  one uniform screen scale, no mirroring or second isometric projection. Their
  hashed placements remain fixed in world coordinates. Conservative projected
  footprint exclusion keeps them away from playable cells and their borders.
- A thin vein was generated while the user's crystal preference was arriving;
  retained as an unused source study, not loaded in this mock. New distribution
  and geology remain unapproved, despite the preference for the outcrop itself.
- Offline in-memory browser captures/observations on3landscape sizes. Spacing,
  48px targets, no UI overlay, expansion and reset remain observed. Existing
  reliefs follow a40x20px pan exactly and preserve their world position/scale.
  Production hashes unchanged; no Godot integration, device profile, game tests,
  commit or push. Renderer only draws the design study; chunking remains open.

## Underground rock direction clarified; extensible cutaway UI mock — 2026-10-25

- User rejects v3's oversized texture/abrupt transition, then v4's open cavern
  appearance. They liked the cavern atmosphere but require an extensible grid,
  and explicitly choose rooms excavated in solid rock. This supersedes the
  earlier interpretation that cavern atmosphere itself was rejected.
- Current isolated proposal: docs/reference/interface-review/v5-subterranean/.
  New ImageGen compact-rock material, original/prompt retained,256px repeat
  every two logical cells. One XY projection; no full-scene fixed background.
  Boundary adjacency opens rock around dug cells; rear natural faces rise above
  masonry, foreground cut is lower for visibility. This is a cutaway convention
  study, not a physically complete terrain renderer or new approved artwork.
- Prepared native-alpha dust from v4 stays below masonry. Open-ground texture
  and scattered boulders are absent from v5. V4 is retained as rejected history;
  its validation snapshot predates the final spacing fix and is not a pass claim.
- Forge rail136px (previously116), observation56, catalogue244; more internal
  padding, taller catalogue cards. At844x390: world83.9%/93.4%/71.1%, no overlay.
  Three landscape sizes observed; targets>=48 CSSpx, checked label insets>=10px
  horizontal/7px vertical. Not a physical phone accessibility validation.
- Review excavation and36-cell expansion derive34 exposed edges. Pattern scale
  stays fixed; pan far outside the room remains covered. Reset restores identical
  world pixels. Captures/validation are offline in-memory browser observations,
  requests blocked, no user-app control or local URL navigation. Production
  hashes unchanged. No Godot integration, game tests, device profile, commit/push.
- Direction is selected; new appearance remains for user feedback. Production
  chunking, cutaway occlusion, terrain persistence and full wall joins remain open.

## Forge layout chosen; stone UI and integrated bedrock proposed — 2026-10-25

- User prefers v2 Forge's lateral layout, but rejects the generic UI skin,
  ambiguous outline icons and independent cavern backdrop. Priority: maximize
  the visible dungeon and keep controls from covering it. New isolated review:
  docs/reference/interface-review/v3-forge-stone/index.html. New art is unapproved.
- View and rail occupy separate grid columns, no top/bottom overlays. Rail116px
  for build,56px for observation,244px for catalogue/menu. At844x390, world owns
  86.3% /93.4% /71.1%. All nine layouts across740/844/1024 have >=48px controls,
  no overlap or offscreen controls. CSS pixels, not physical phone validation.
- New ImageGen pickaxe, spikes, stone nine-slice skin and bedrock material;
  originals/prompts retained in source/. Door/chest/decor icons reuse kit pixels.
  Bedrock uses common world projection at z=.20, moves with the camera, and
  hides exterior wall feet. Front receiving mask is specific to this review
  room; general layout integration remains open. The photographic v2 background
  and initial abstract triangle surface are not the current proposal.
- Browser mock only: repeated placement/undo, occupied rejection, pan, catalogue
  retraction and illustrative excavation observed. No game simulation or saves.
  In-memory offline rendering blocks requests and does not navigate local URLs
  or control user apps. Production hashes unchanged. No game tests/commit/push.

## Dungeon master UI mockups proposed — 2026-10-25

- User requests a more evil dungeon-master identity, fewer mobile construction
  and placement actions, and an environment surrounding the dungeon. Current
  proposals: docs/reference/interface-review/v2-dungeon-master/index.html.
- A Obsidian: persistent lower quick tools; B Forge: right-thumb rail; C Grimoire:
  visible families. Common repeated tap placement, optional drag from palette,
  pan without placement and undo. These are unselected disposable browser mocks,
  not Godot integration. Existing tool already persists; per-cell confirm is the
  step proposed for removal. Destructive/economic transactions need own design.
- Existing sprite atlas pixels retained. New ImageGen cavern background original
  and exact prompt retained under source/. Background is an atmosphere study,
  not optimized mobile terrain. Excavation mocks do not rebuild wall joins;
  decor economy, complete catalogue, native touch and raid simulation stay open.
- Nine browser layouts at740x360,844x390,1024x576 inspected: controls >=48 CSS px,
  no page overflow or JS error. Repeated placement, refund/undo, blocked occupied
  cell, pan, drag and raid history boundary observed in validation.json. Production
  files preserved. No game tests, commit or push. Automatic local-file opening
  rejected by browser security policy; deliver screenshots and local review file.

## Heart vortex animation integrated — 2026-10-25

- User accepts slow animated spiral and gentle violet pulse, with fixed pedestal,
  ring silhouette and neck. Implemented by isolating the interior in a shader
  mask within the existing atlas sprite. No new source art or physical layers.
- isometric_prop_paint emits vortex centre/radius in logical frame coordinates;
  export adds only this field to the heart entry. All136 prepared region pixels,
  positions and other metadata, both atlas files, ground shadow/glow and user
  project.godot remain unchanged. No extra sprite or texture memory (still9MiB).
- heart_vortex.gdshader samples only inside its atlas region. Interior flow ends
  before the ring; halo changes RGB gently and excludes the neck. Original alpha
  and vertex modulation retained; existing lighting mode/solid ordering retained.
  UV motion is now intentional ONLY inside this explicitly requested vortex mask.
- heart_vortex_animator owns a bounded12s phase, one controller per renderer,
  one material per heart. Three subtle light pulses per cycle; no TIME dependence.
  Rebuilds clear stale materials and retain phase, recover an existing controller,
  and stop processing without hearts. Gameplay pause/confirmation/result/save
  block/game-over freeze phase. Editor stays static; scenes animate when run.
  Inspector vortex_animation_enabled disables the effect.
- Evidence: docs/reference/heart-vortex-review/v1/. Final background export/import
  and17 static Godot observations exit0, empty stderr. Same fragment body runs
  in isolated headless WebGL2 for preview.html and144-frame/12s vortex.gif.
  Pixel inspection: no alpha/outside-mask differences; phase0/1 match static
  exactly. Browser declaration adapter does not modify the fragment body.
- Independent focused read-only review found no concrete issue. Preview is NOT
  a native Godot GPU capture; GPU lighting/compositing, device performance and
  full raid/save behavior remain unverified. New movement is subject to user
  feedback. No native UI control, automated tests, commit or push.

## Chest directions, persistent lock and smaller mobile scale — 2026-10-25

- User requests angle variants facing usable space, the same lock on open chests,
  matching lid hardware, and smaller scale. After rejecting straight lip/tab
  revisions, explicitly confirms the ORIGINAL closed metal chevron. Preserve it;
  one violet keyhole escutcheon on the lower body, none on the raised lid.
- Seven new ImageGen sources plus unchanged closed south under
  treasure-chest-review/v4-directions/. generation-complete.json stores prompts
  and provenance; source fits/hashes in tools/chest_direction_sources.json.
  Rejected tab images and accepted original selection remain intact. Appearance
  of new views/scale is subject to user feedback, not automatically approved.
- All eight prepared chest bodies reduced25%,96 to72px at.75, uniform source
  resize/native alpha. Support proxies and short static shadows scaled too.
  No raster mirroring/rotation, runtime geometry, or new light emitter.
- chest_orientation.gd excludes outside/ROCK, CORE, VAULT, ENTRANCE and intact
  doors. Prefer two-step clearance then lateral space, stable S/E/N/W ties.
  Rebuilds respond to grid/door/protection changes, not gold/camera/hero motion.
  Enclosed fallback stays south, accessible=false. Presentation only; no save,
  placement, pathfinding or economy changes. Captions use chest metadata.
- Main120 regions/pixels/metadata and1024x2048 atlas byte-identical. Chest page
  now256x1024,16regions,107001PNG bytes/1MiB RGBA; total136regions,
  1673184PNG bytes/9MiB RGBA. Delta63276PNG bytes/+768KiB RGBA vs prior page.
- Final hidden-process export/import and13 static Godot presentations exit0,
  empty stderr. Initial shell-piped Node exporter had native teardown assertion;
  final rerun via hidden Start-Process was clean. Source/selection/project
  integrity checks and focused independent review found no concrete issue.
  Boards are offline atlas composites of recorded placements, NOT GPU captures.
  No native UI control, automated tests, device/full-raid check, commit or push.

## Ritual chest gameplay integration and free variant — 2026-10-25

- User authorizes accepted closed chest integration, then asks to distinguish
  the free chest with an ajar lid/coins. Closed art remains immutable. New native
  ImageGen source: treasure-chest-review/v3-free/source/chest-open-coins-v2.png;
  first open version rejected for oversized coins. V2 has a small pile; its
  appearance remains subject to feedback, not recorded as user-approved.
- isometric_treasure_chest.cjs guards all six accepted selection hashes and the
  current open source. Uniform native-alpha crop/resize, measured lower contacts
  and common inverse ground projection; support proxies, not reconstructed3D.
  Both body widths approximately96px at.75. Shared ritual-prop shadow helper
  supplies separate short ambient cast/contact, with existing floor receivers.
- prop-chest/prop-chest-open and their shadows share a256x256 companion atlas:
  43725 PNG bytes/256KiB RGBA. Main1024x2048 atlas byte-identical; all120 regions
  retain pixels and metadata. Total124 regions,1609908 PNG bytes,8.25MiB RGBA.
  Catalogue entries can specify atlas_path; shared loader/watch handles both
  pages. Full exporter reproduces both. Failed packing changes were discarded.
- Gameplay selects closed iff vault_protected is true; free/forced use open.
  Protected state participates in structure hash, so raid unlocking redraws.
  Gold captions remain dynamic and grouped with prepared solids. No economy,
  save format or camera changes. Both paid tiers share closed appearance; open
  coins are fixed artwork, not a simulated count. No new point-light emitter.
- Evidence: treasure-chest-review/v2/integration/. Final headless import and
  eight static scene inventories exit0/empty stderr. Counts/update/removal,
  forced/restored lock and actor before/after order inspected. Comparison and
  layout-montage are offline composites, not GPU captures. Independent focused
  code reviews found no concrete remaining issue. No native UI control,
  automated test suite, full raid/device verification, commit or push.

## Ritual chest appearance accepted — 2026-10-25

- User replies "oui c'est beaucoup mieuux" to the ritual chest and mobile
  comparison. Retain this appearance: dark plum wood, claw-like slate fittings,
  short horn tips and violet seal. Do not regenerate it during integration.
- treasure-chest-review/v2/selection.json freezes six source/review/preparation
  files by SHA256. Earlier generation/review JSON remain pre-approval snapshots;
  this selection supersedes their pending artistic status.
- Appearance selection only. Production preparation/integration, calibrated
  support/contact/ordering and ground shadow remain pending. No new rendering,
  automated tests, gameplay edits, native UI control, commit or push.

## Ritual chest proposal after heroic styling rejection — 2026-10-25

- User rejects the burgundy/gold-lock chest as too heroic. New proposal in
  docs/reference/treasure-chest-review/v2/: dark plum wood, heavy slate/charcoal
  claw-like fittings, two short horn tips and a violet seal; no gold. Built-in
  ImageGen uses the accepted idol and dungeon capture as direct references.
- Original/source and exact prompt retained. prepare-review.cjs compares the
  previous chest, new chest and idol on actual paving at proposed96px width,
  plus2x. Native alpha unchanged, uniform resize only; source copy SHA256 matches.
  New silhouette has no visible external haze in this review. Perspective and
  contact anchors remain provisional, not recovered/calibrated support geometry.
- Appearance not approved or integrated. Old proposal/history, active kit and
  gameplay preserved. No automated tests, native UI control, commit or push.

## Treasure chest style proposal revised — 2026-10-25

- User asks for a treasure chest sprite, then rejects the first golden/orange
  chest as mismatched to the dungeon. Built-in ImageGen v2 uses the approved
  grimoire and current dungeon as references: muted burgundy wood, slate fittings,
  gold concentrated on the lock. This remains an unapproved appearance proposal.
- docs/reference/treasure-chest-review/v1 retains sources, exact prompts and
  cleanup provenance. Two subsequent cleanup attempts retained external haze;
  do not claim a clean production cutout. V2 is the current style candidate.
- prepare-review.cjs produces mobile-comparison.png on actual paving: proposed
  chest body96px wide at .75 zoom, plus2x enlargement and existing book reference.
  Uniform resize only, native alpha preserved; alpha128 only measures size.
  Scale-preview PNG is provisional. Anchors/source geometry are not calibrated.
- No chest integration, production art changes, automated tests, native UI
  control, commit or push. Preserve the existing gameplay/HUD/stair work.

## Gameplay stair orientation corrected — 2026-10-25

- User screenshot shows the high step facing the corridor. Gameplay view mapped
  the mouth direction to the opposite stair suffix. Frozen migration geometry
  confirms north/east/south/west descend toward UP/RIGHT/DOWN/LEFT respectively.
- isometric_game_view.gd now maps mouth directly using ENTRANCE_OPEN_SIDES.
  _wall_entrance_face returns the walkable mouth despite its legacy name. Keep
  simulation/pathfinding, saved cell, hero exit motion and prepared art unchanged.
- Source geometry inspected in all four directions; headless import and8-frame
  DungeonGame startup exit0/empty stderr. Logs: artifacts/stair-orientation-*.
  No automated tests, native UI control, GPU capture, commit or push.

## Native mobile black/gold HUD implemented — 2026-10-25

- User explicitly requests implementation of the HTML interface. DungeonGame
  now uses native Godot controls: top resources/phase, bottom Bâtir/Raid,
  retracting three-category catalogue, compact placement/context, visitor and
  guarded welcome/pause/result/defeat/reset dialogs. No world camera/art change.
- scripts/game/ui provides theme/catalogue/selection.19 SVGs under
  assets/ui/black-gold,12419 source bytes; prepare_game_hud_assets.cjs reproduces
  them from the retained HTML proposal. This is not GPU/APK size.
- Minimum48 UI-unit targets, main actions56 high; independent HUD canvas scale
  compensates viewport stretch, uses mobile DPI/safe area. Overflow contexts and
  dialogs scroll. Transfers retain exact integer amounts via ±1/±25/All.
- Session catalog_open pauses preparation countdown only. Existing rules/save
  guards remain. Input shields native HUD touches; Escape/Android Back route to
  HUD. SceneTree quit_on_go_back disabled here/restored on scene exit.
- Read-only independent review found recenter overlap and reduced transfer
  precision; both addressed. Geometry includes transfer+body+loot overflow.
  Evidence: docs/gameplay/mobile-hud-2026-10-25.md, artifacts/hud-layout.json.
  Forty-two static layouts/three sizes, no targets nominally under48. Headless
  import/startup checked; no native GPU visual/touch/device validation or tests.
- User still needs their computer: no native UI control/restart. Existing
  project.godot main scene preserved. No commit/push. Open DungeonGame/F6 later.

## Mobile interface appearance proposal — 2026-10-25

- User chooses black/gold close to the original mockup and stresses mobile
  usability. Local proposal: docs/reference/interface-review/v1/index.html.
  Top resources, bottom thumb actions, retracting category catalogue, compact
  placement bar, raid and result states. Layout remains a proposal for feedback.
- CSS/SVG HUD over an unchanged prior dungeon capture; illustrative values and
  navigation only, no live Godot HUD or gameplay edits. Eleven background Chrome
  renders at844x390/740x360/1280x720; no page errors/overflow/targets under48px.
  Small-screen views inspected. No device/touch validation or gameplay tests.
- Do not infer new camera scale from the fitted screenshot, or approval of this
  layout from the user's style choice. Later port must preserve all session
  guards, first-heart flow, chest transfers, reset confirmation and defeat states.
- Native UI control remains prohibited while the user needs their computer.
  No commit or push. Existing gameplay work and project.godot change preserved.

## First playable isometric loop; review complete, interactive validation partial — 2026-10-25

- User chooses the previous preparation/autonomous raid/result loop and explicitly
  accepts provisional hero/chest/trap markers. New scene: scenes/game/DungeonGame.tscn.
  Five simulation modules and the save adapter are restored from v1.0.0; no 3D
  Main/assets/HUD restoration. The existing 24 visual scenes and atlas stay unchanged.
- Grid16x16; solid heart1x1 at cell+.5 fits approved art. Keep .75 fixed zoom/free
  pan; tap/select/confirm, no drag digging. Four hero classes and normal progression
  gates retained; no Vulpin-only/unlock-defense override. Optional prepared starter
  has245gold, door+spikes+three vaults; normal start320gold/unexcavated.
- Session owns guarded phases, checkpoint and results. isometric_run_v1.save is
  separate from the old mobile slot. --review-session uses isometric_review_v1.save
  only; no AI/balance overrides. Preserve the user's normal save and running game.
- Independent source review found two issues, corrected: explicit step_started_at
  prevents replaying movement when decision/snare timers reset; confirmation_open
  blocks unpause/edit/simulation behind restart confirmation. Host+ornament groups
  stay together and actors insert into cached support order without repainting.
- Evidence/scope: docs/gameplay/validation-2026-10-25.md. Import and headless startup
  successful, final startup8frames exit0/empty stderr. Manual isolated session
  verified starter creation/render and raid entry; complete raid/bilan, economy UI,
  touch and full visual ordering remain unvalidated. Do not report them as passed.
- User needs their computer: STOP native UI control; continue background/source
  work only unless they authorize it again. No automated tests added/run, phone
  profile, commit or push. Existing project.godot local main-scene change preserved.
  Open DungeonGame and F6 later to load corrected scripts; don't restart user apps.

## All six selected ritual props integrated — 2026-10-25

- User authorizes preparation/integration with "ok vas-y". All six appearances
  remain unchanged as native sources; tools/isometric_ritual_props.cjs verifies
  all12 selection hashes. Uniform preparation only, .75 atlas density for props,
  .5 for separate soft shadows; no new art, mirroring or screen rotation.
- Source-space lower-edge contacts map through the shared 2:1 inverse ground
  projection. These are calibrated support/ordering proxies, not recovered 3D
  meshes. Six prepared shadows use floor receivers and precede all solids.
  Short fixed ambient cast/contact, no dynamic torch shadow simulation.
- wireframe_cell_study exposes decoration_positions (Vector2 -> prepared ID),
  decorations_enabled and decoration_lights_enabled. Stable authored placement
  rejects void/special cells and overlapping wall/heart/prop supports. Existing
  support order and rebuild lifecycle apply. Only candles add a small optional
  local light, independent of torch toggle. No automatic scatter or gameplay
  collision changes. Default positions remain empty.
- DungeonDecorations.tscn shows all six. DungeonPreview/SixRoomPreview include
  six near the heart; MobileReference has three. Existing layouts/camera stay.
  The project.godot main-scene setting changed separately during the operation;
  integration did not edit it and leaves that concurrent setting intact.
- Active atlas120 regions/1024x2048/1566183 PNG bytes/8 MiB RGBA: +62070 bytes,
  +0 RGBA. All108 retained regions preserve rawRGBA/non-region metadata.
- Evidence: isometric-prop-review/v1/integration/.13 focused captures including
  six intentional invalid-placement warnings; restored lights and torch-off
  gallery byte-identical. Runtime70/24 scenes exit0,empty stderr. Editor17/five
  exit0,1519 bytes native shutdown/window diagnostics on final pass. First-pass
  legacy script resolution diagnostic did not recur in parser-only/final editor
  runs; initial logs retained. No cache reset or legacy script modification.
- Resource ZIP1324453 bytes/53 dependencies/24 scenes; stage import/export and
  isolated startup exit0,empty stderr. Independent focused review found no
  concrete issue. Three older variant exporters now use existing atomic writes
  to avoid Windows in-use PNG failures; resulting old pixels remain identical.
- No automated tests, phone profile, commit or push. Integration README records
  authoring controls and limitations. Preserve original approval history.

## All six evil prop appearances selected — 2026-10-25

- User replies "Tous" to which of the six props to retain. Select A crystals,
  B idol, C stele, D offering bowl, E grimoire and F candles as shown, including
  the bowl swirl. This supersedes the pending appearance status below.
- isometric-prop-review/v1/selection.json freezes the six original PNGs,
  reviewed boards, provenance, preparation script and documentation. Preserve
  these appearances and original alpha; no regeneration in this selection step.
- This is appearance selection, not approval of exact support geometry or
  completed production integration. Retain the shared 2:1 camera and proposed
  small-scale readability when preparing supports, anchors, occlusion and shadows.
- generation.json and validation.json stay as pre-selection snapshots. No new
  rendering, production changes, automated tests, Godot import/export, commit
  or push. Selection hashes and eight active baseline hashes verified.

## Evil dungeon prop concepts; shared isometric camera required — 2026-10-25

- User selects evil decorations: crystals, idols and ritual objects, and
  explicitly stresses 2D isometry. Keep the common 2:1 projection, fixed .75
  zoom, upright verticals and prepared 2D sprites. No new camera or layout.
- Six built-in ImageGen proposals: A crystals, B stone idol, C ritual stele,
  D offering bowl, E sealed grimoire and F candles. Sources and exact prompts
  retained in isometric-prop-review/v1/. No appearance selection or integration.
- prepare_isometric_prop_review.cjs creates boards on actual B paving with
  an exact 192x96 logical-cell guide. Uniform resize only; preserve native
  alpha, crop alpha-zero margins, use alpha128 only for subject measurement.
  Proposed game heights 62/76/84/49/56/67px; inspected at small and large sizes.
- The guide verifies the ground grid, not generated prop geometry. Supports,
  anchors, occlusion and ground shadows still require explicit fitting/review.
  Do not treat these montages as Godot captures or mathematically fitted art.
  Bowl has a more pronounced swirl than prompted; appearance remains open.
- Six original hashes and eight production baseline hashes verified. Active
  108-region atlas remains unchanged. No production code/scenes, automated
  tests, Godot import/export, commit or push. Preserve all prior selections.

## Four approved floor damage appearances integrated — 2026-10-25

- User says "ok ajoutes les": accept all four floor proposals A/B/C/D. New
  isometric-floor-damage-review/v1/selection.json freezes9 files. Original art,
  earlier floor/wall selections and concept snapshots stay unchanged.
- isometric_floor_damage.cjs samples selected painted stone faces onto existing
  B rectangles offline, matching host colour. D extends the same source UV onto
  an interior joint to preserve its root/crystal. This is an appearance adaptation,
  not a pixel copy of the concepts or new ImageGen artwork.
- Four cropped patches have matching B backing. Changed pixels stay >=.10 cell
  from outer edges. Overlay alpha fades inside .06-.085, never over translucent
  host pixels;2px unchanged crop border supports filtering. This fixes an initial
  doubled-alpha defect. D stone mask .025-.060, joint .004-.022 are recorded.
- dungeon_floor_damage chooses once per rebuild by coordinates/seed, independent
  of Dictionary order.8-neighbour candidate exclusion, rare corruption, skip
  specials and actual heart XY support. Draw immediately after matching B host,
  before shadows/solids.20 layouts opt in; defaults/review plans remain disabled.
  Inspector floor_damage_seed=17 and floor_corruption are available.
- Evidence: floor-damage-review/v1/integration/.104 retained regions preserve
  rawRGBA/non-region metadata;9 accepted hashes match. Actual base+patch alpha
  identical, maxRGBdifference1/255;107424 boundary pixels unchanged.11 focused
  captures: seed restoration identical, negative coords and host/exclusion checks.
  SixRoom has38/256 decorated cells (A13/B16/C4/D5); MobileReference has2.
- Atlas108/1024x2048/1504113 PNG bytes/8 MiB RGBA, +41098 PNG bytes,+0 RGBA.
  Resource ZIP1271254 bytes,52 dependencies/23 scenes. Import/runtime68 captures,
  stage import/export/startup exit0,empty stderr. Editor19/five exit0,1520 native
  window/resource stderr bytes. Final independent focused review closes alpha
  and missing D joint-root findings. Metadata-only refresh retains atlas/catalogue
  hashes. No automated tests,phone profile,commit or push. Preserve editor state.

## Floor B cracks and corruption proposed — 2026-10-25

- User requests several floor variants with corruption or cracks. New appearance
  proposals in isometric-floor-damage-review/v1/: A short separate fissures,
  B local branched fracture, C restrained violet vein, D roots in mortar joints.
  This authorizes new concepts; do not restore the retired old damage overlays.
- Four built-in ImageGen native-alpha sources reference selected B, current floor
  palette and F2 wall corruption. Preserve originals; exact prompts/paths in
  generation.json. No appearance selection or production adoption yet.
- prepare_isometric_floor_damage_review.cjs only crops alpha-zero margins and
  scales uniformly for boards. Both large and192px previews inspected; cracks
  subtle, violet more perceptible. Small previews are indicative, not Godot captures.
- Exact B masks/geometry, shared edge joints, palette calibration and sparse
  distribution remain integration work. Do not tile the concept PNGs directly.
  Four original hashes,9 active baseline hashes and19 selection hashes verified.
  Active atlas104/1463015 bytes/8 MiB unchanged. No automated tests, Godot
  import/export, device profile, commit or push.

## Four compatible floor B arrangements integrated — 2026-10-25

- User said "ok go" after selecting B. tools/isometric_floor_variants.cjs
  rebuilds four B size/assembly layouts in the common planar2:1 geometry, with
  the unchanged calm material/rounded finish. It is a layout adaptation, not a
  pixel copy of the concept. Selection/source art and base migration stay frozen.
- floor-b1..b4 share complete crossing stones, UVs and finish seeds at all four
  borders. Geometry coverage/no overlap and all32 directed edge pairs checked.
  Full original ink and temporary6px colour guard avoid Lanczos alpha/fringe
  contamination; crop to unchanged270x138 frame and apply original2px geometric
  alpha after resizing. Historical Stone.paint default2px remains unchanged.
- dungeon_floor_variants.gd selects once on rebuild by logical coordinate/seed.
  Disjoint pairs avoid identical horizontal neighbours; upper hash bits avoid
  FNV low-bit parity. Negative coordinates work. Twenty layouts explicitly enable
  floor_variants; floor_variant_seed=17. Default/review plans stay disabled.
  No camera/layout/wall/prop changes; missing regions fall back to original floor.
- Evidence: isometric-floor-variation-review/v1/integration/. All100 retained
  atlas regions preserve rawRGBA/non-region metadata; six B selection hashes
  match.32 edge and32 diagonal pairs,8320 opaque shared pixels,maxRGBdelta1.
  Nine focused captures: seed17 restoration identical,seed43 differs,non-floor
  placements identical; SixRoomPreview counts60/67/63/66. Images inspected.
- Atlas104,1024x2048,1463015 PNG bytes/8 MiB RGBA: +42482 PNG bytes,+0 RGBA.
  Import/runtime68 captures/23 scenes,stage import/export/package startup exit0,
  empty stderr. Editor18/five exit0,1520 bytes native window/resource diagnostics.
  Resource ZIP1236542 bytes,51 dependencies. Independent focused review found no
  actionable issue. The initially missing stone helper baseline was recovered
  by exact SHA256 against an archived recipe; provenance saved beside it.
- No automated tests,APK/device profile,commit or push. Preserve user editor
  state and approval history; adapted appearance remains for user judgment.

## Floor concept B selected — 2026-10-25

- User says "oui je pense que B c'est mieux". Retain B formats varies: mixed
  slab sizes with staggered joints, calm smooth surfaces and the common dark
  slate-blue palette. This selects B alone, not the suggested A+B mixture.
- isometric-floor-variation-review/v1/selection.json freezes six source/review
  files. Preserve B's original native-alpha PNG and all proposal history.
  Generation/validation records remain pre-selection snapshots, superseded by
  selection.json for approval scope. A/C are excluded from the next step.
- Compatible wireframes, edge joints, filtering coverage, multiple arrangements
  and production integration remain future work. Do not tile the concept PNG
  directly or regenerate the selected source. Seven active files and all four
  compared source images unchanged. No rendering, tests, import/export,
  production changes, commit or push in this selection step.

## Floor shape variations proposed — 2026-10-25

- User requests floor variants like the walls. Current concept review:
  isometric-floor-variation-review/v1/. Three built-in ImageGen native-alpha
  sources: A subtle asymmetric outlines, B mixed slab sizes/assembly, C rounder
  corners with small mortar pockets. Calm surfaces, existing slate-blue palette
  target, no old damage overlays. These appearances are not selected/integrated.
- Exact prompts and original paths: generation.json. Preserve original source
  pixels/alpha. prepare_isometric_floor_variants_review.cjs builds comparisons
  using transparent-margin crops and uniform scaling; 192px-wide previews are
  approximate one-cell scale, not Godot captures or validated modular tiles.
- Final projection, common edge joints, complete stone painting/filter guards,
  palette matching and varied distribution still require prepared wireframes
  and integration. Do not tile these concept PNGs directly into production.
- Comparison inspected. Seven active file hashes and thirteen accepted wall
  references unchanged. No runtime/atlas/layout changes, automated tests,
  Godot import/export, commit or push.

## All old surface damage retired, including chipped stone — 2026-10-25

- User's screenshot identifies the retained chip-worn floor mark as unwanted.
  This supersedes keeping chips below: remove all three chip-worn projections
  from the active atlas, generated PNGs and automatic placement. No old damage
  overlays remain. Historical artwork/approvals are retained as archives only.
- Exporter no longer adopts isometric_approved_decorations. Renderer no longer
  places damage overlays; surface_details/seed properties and scene flags are
  removed. dungeon_surface_details retains only stable keys/ranks needed by the
  unchanged A/C/F selector. Preserve its quiet base slots and F wall ornaments.
- Evidence: isometric-decoration-review/remove-chip-2026-10-25/. Exactly three
  regions/copies removed (4526 prepared PNG bytes); all100 retained regions have
  identical rawRGBA/non-region metadata. Atlas1024x2048,1420533 PNG bytes/8 MiB.
- Import,68 runtime captures/23 scenes,stage import/export and isolated startup
  exit0,empty stderr. Package1176007 bytes,50 dependencies. MobileReference
  visually inspected. No new editor capture, automated tests, phone profile,
  commit or push. Original review snapshots remain historical.

## Old crack decorations removed — 2026-10-25

- User no longer wants the old cracks now that A/C/F walls are integrated.
  Remove corner-split, vertical-hairline, edge-fork and crack-corrupt from active
  adoption/placement: 12 atlas regions. Keep chip-worn on all three surfaces,
  at the exact prior positions; removed crack slots remain empty.
- isometric_approved_decorations.cjs now adopts only the three approved chip
  PNGs; no active dependency on the edge-crack selection. Keep historical review
  sources/approvals intact. Removed 18 generated copies from painted-v1/sprites,
  including six already-retired short/branched cracks; deleted-files.json records
  13375 bytes. Do not reintroduce old cracks when regenerating the active kit.
- Evidence: isometric-decoration-review/removal-2026-10-25/. All103 retained
  atlas regions preserve rawRGBA and metadata except packed coordinates. New
  A/C/F art, shapes, palette and distribution are unchanged. No retired motif
  references remain in runtime scripts or active catalogues.
- Current atlas103 regions,1024x2048,1424918 PNG bytes /8 MiB RGBA. Removing small
  cracks does not cross the atlas-size threshold. Package1182540 bytes,
  50 dependencies/23 scenes. Import/runtime68 captures, staged import/export and
  isolated startup: all exit0, empty stderr. MobileReference visually inspected.
  No new editor capture, automated tests, phone profile, commit or push.

## A/C/F wall variants integrated; common palette corrected — 2026-10-25

- User approved implementation of all nine concepts, then rejected their uneven
  stone colours. Current review: isometric-wall-variation-review/v2-subvariants/
  integration/. selection.json freezes 13 shown/source files; preserve originals.
- isometric_wall_variants.cjs maps accepted source planes onto common supports;
  C adds shallow rigid relief. Nine motifs x two axes x four pillar-end profiles
  = 72 regions. Longitudinal endpoints, height and old base geometry stay fixed.
  F is an optional surface skin INCLUDING masonry backing, not an isolated root
  cutout. Draw after its bare host; disabling it retains that same host.
- Rejected first palette retained in integration/palette-v2/before/. Current
  isometric_wall_palette.cjs grades stone luminance/hue per plane to the existing
  base wall, preserving violet accents. Source C3 median59.7 vs base39.6 explained
  the bright patchwork. No source PNG regeneration or alpha-based colour removal.
- dungeon_wall_variants.gd uses coordinate/seed selection, neighbour exclusion
  for accents, quiet torch/special supports and no identical neighbouring A motif.
  Old crack masks stay on compatible quiet walls, not new joints/reliefs.
  Twenty layout scenes opt in; inspector wall_variant_seed=17, wall_corruption=true.
  Review/default plans remain disabled. Camera, layouts, props and floor unchanged.
- Atlas115 regions, 1024x2048, 1430732 PNG bytes / 8 MiB RGBA (was4 MiB). New wall
  regions use .75 raster density with unchanged logical frames. All43 original
  regions retain rawRGBA/non-region metadata; all13 selection hashes match.
- Import/focused24/runtime68 captures across23 scenes: exit0, empty stderr.
  Editor19/five: exit0, 1520 stderr bytes of native window/resource diagnostics.
  Seed17 restoration byte-identical; nine motifs observed in SixRoomPreview.
  Resource ZIP1192581 bytes,50 dependencies/23 scenes; clean stage import/export/
  isolated startup exit0, empty stderr. Focused independent read-only review
  found no actionable issue. No automated tests, phone profile, commit or push.
  The adapted appearance and corrected palette remain subject to user judgment.

## A/C/F wall subvariants proposed — 2026-10-25

- User requests several variations within the selected A/C/F families. New
  review: docs/reference/isometric-wall-variation-review/v2-subvariants/.
  Nine concepts: original A1/C1/F1 plus six new built-in ImageGen sources.
- A2/A3 vary long-stone positions and staggered joints; C2 has two staggered
  relief blocks, C3 a dominant lower relief plus a smaller upper relief; F2 has
  spreading roots, F3 a compact crystal cluster. C3 did not fully flatten its
  upper course as prompted; retain the actual appearance description.
- Native-alpha originals and exact prompts retained. comparison.png and
  mobile-scale.png were inspected; 114px thumbnails are concept previews, not
  Godot captures. New appearances are not selected or production-integrated.
- Wireframe end-profile validation and both orientations remain future work.
  Roots/crystals are shown on hosts for review; separate overlays are not yet
  prepared. Keep two primary courses, shared isometry and pillar junctions.
- All eleven parent-selection reference hashes and ten active-file hashes
  unchanged. No production changes, gameplay tests, commit or push.

## Wall concepts A, C and F selected — 2026-10-25

- User says "je ne veux garder que A, C et F". Retain only A uneven masonry,
  C raised chamfered blocks and F roots/crystal corruption for subsequent work.
  B, D and E are excluded from the next step; preserve their originals as history.
- isometric-wall-variation-review/v1/selection.json records this selection and
  hashes the source art, prompts, references and shown comparison. This supersedes
  the six-concept mix suggested below; no placement frequencies are approved.
- These are selected concept directions. Shared end profiles and both visible
  orientations still require wireframe construction/validation before adoption.
  Preserve two wall courses, isometric projection and pillar junctions; keep
  corruption details separable from the bare structure.
- Selection record only: no new art, production changes, tests, commit or push.

## Wall-form variety: six visual proposals — 2026-10-25

- User requests more interesting wall shapes/arrangements to reduce repetition,
  referring to the original mockup and affordable mobile sprites. New review:
  docs/reference/isometric-wall-variation-review/v1/, not integrated or selected.
- Six built-in ImageGen concepts: A uneven masonry/joints; B worn rounded stone;
  C raised chamfered block; D repaired masonry; E shallow blind niche; F roots
  and amethyst corruption. Exact prompts, native-alpha originals and references
  retained. comparison.png includes enlarged and114px-wide thumbnails (not Godot).
- Suggested mix: A/B frequent, C/D occasional, E/F rare. Root/crystal details
  should remain separate optional overlays. These suggestions are not approval.
- Geometry/end profiles and both orientations need wireframe construction and
  validation after selection. Concept paintings are not proven seamless sprites.
  Preserve two primary courses, current isometric frame and pillar junctions.
- Outputs and board inspected; ten active source/asset hashes unchanged. No kit,
  scene, camera or renderer changes; no tests, commit or push.

## Accepted self-lit heart integrated — 2026-10-25

- User approved heart-self-light-v1 with "oui c'est bien". selection.json freezes
  eleven reviewed files. Active heart now uses its own accepted contact/cast and
  violet additive floor-light images, independent of torch placement/toggle.
  This supersedes v6 torch-selected heart shadows; keep prior approvals/history.
- isometric_approved_heart_light.cjs adopts the two PNGs, trimming only alpha-zero
  padding with compensating offsets, no repainting or scaling. Nine old shadow
  regions are replaced by two: 43 regions, 1024x1024, 602507 PNG bytes / 4 MiB RGBA.
  All 41 retained RGBA regions and non-effect metadata remain unchanged. Accepted
  crops match exactly; all 73 current selection file hashes remain unchanged.
- ground_effect_mask.gd computes a 4x4 receiving-cell bitmask on rebuild. Two
  unshaded mix/add canvas shaders clip prepared pixels using local VERTEX and
  inverse ground projection, excluding void/special cells. Export guard proves
  filtered nontransparent footprint fits +/-1.5 world units. No runtime geometry
  or image generation, extra PointLight2D, CPU per-frame selection or atlas growth.
- Common renderer draws effects after floors, before solids. Standalone heart is
  unmasked. Torch-independent parameters/rebuild stability, negative fractional
  edges, neighbouring special cells and multiple hearts pass focused rendered
  checks; zero pixels outside receiving floor beyond raster-edge tolerance .015.
- Evidence: heart-self-light-v1/integration/. Import/runtime68/23, focused checks,
  staged import/export and OpenGL startup from isolated ZIP: exit0, empty stderr.
  Shader-aware package has 49 dependencies, ZIP521921 bytes. Editor19/five: exit0,
  stderr1518 bytes of native window/RID/resource/shader shutdown diagnostics.
  Initial capture helper's typed-array assignment error was corrected; final
  focused run has zero failures. Do not call editor stderr clean.
- Integrated approved view differs by at most2/255 per channel from atlas/filter
  roundoff, mean .0049/255; appearance/geometry retained. Focused independent
  read-only code and visual review found no concrete issue. No APK/device profile,
  commit or push. Effects light the floor only; movable-prop lighting/occlusion
  and general torch light leakage remain outside this change.

## Heart as its own light source — isolated appearance study, 2026-10-25

- User finds contact-only DungeonPreview visually odd without torches and asks
  to treat the heart itself as the light source, independent of torches. This
  opens a new self-light direction; earlier v6 remains active pending review.
- Latest proposal: painted-v1/heart-self-light-v1/. Offline point projection from
  frozen orb centre [0,0,.56], nine area samples, actual rigid support blockers.
  Separate contact/cast PNG and occluded violet additive floor-light PNG. The
  luminous vortex is excluded from blockers. Heart/geometry/production unchanged.
- Actual Godot comparison on DungeonPreview, .75 zoom: current contact vs self-lit.
  Capture exit0, empty stderr, inspected. First stronger/harder attempt retained
  in first-pass; current version has softer relief shadows and subdued violet.
- This is a throwaway appearance study, not new selected art or integration.
  Floor clipping at void/specials, atlas packing and general placement remain
  integration work. No runtime geometry, PointLight2D, tests, commit or push.

## All accepted edge-crack variants integrated — 2026-10-25

- User replied "ok" to v2 edge/corner shapes, then explicitly requested all
  variants. v2-edge-cracks/selection.json freezes 27 review files. Retain all
  three new motifs (corner-split, vertical-hairline, edge-fork), each on floor
  and both wall faces, plus the prior chip-worn and violet crack-corrupt.
  The six old ordinary-crack sprites are replaced; rejected drafts stay history.
- approved-decorations loader verifies both selections and adopts prepared PNGs
  unchanged. Five motifs / 15 decorations; total 50 regions, 1024x1024,
  580419 PNG bytes / 4 MiB RGBA. The 41 retained regions have identical raw RGBA
  and non-region metadata; nine additions match selected review atlas pixels.
  Prepared copies are byte-identical; all 62 v1/v2 selected hashes unchanged.
- Existing placement hosts/density/exclusions remain. Motif weights are
  corner25, vertical25, lateral20, chip25, corrupt5. Same seed/rebuild behavior,
  no camera/layout/renderer change or per-frame work; all five motifs observed.
- Evidence: v2-edge-cracks/integration/. Import, 68 runtime/23 scenes, five focused
  captures, stage import/export and isolated startup: exit0, empty stderr.
  Seed17 restored image is identical. Resource ZIP486487 bytes, 46 dependencies.
- Editor21/five: exit0. First pass had an external-layout resolution diagnostic
  in historical capture_approved_heart.gd; second full pass without source changes
  did not reproduce it. Native window/RID/resource shutdown diagnostics remain
  (1399 stderr bytes); do not call editor stderr clean. Captures inspected.
- No automated tests, APK/device profile, commit or push. Prior review status
  files stay as historical snapshots; selection supersedes pending appearance.
- Focused independent read-only review verified preservation, catalogue/provenance,
  motif availability and captures; no concrete finding remained.

## Crack appearance correction: varied edge/corner shapes — 2026-10-25

- User finds v1 cracks coarse, then rejects the new thinner drafts because all
  repeat a left-to-right diagonal. References show short fine fissures starting
  at brick edges/corners. This reopens crack appearance; do not infer approval
  from the earlier v1 selection or technical integration review.
- Latest proposal: isometric-decoration-review/v2-edge-cracks/. Three distinct
  ImageGen motifs: corner-split, vertical-hairline, edge-fork. Nine projections
  on floor and both wall faces, anchored at real central stone boundaries.
  Native alpha sampled with uniform source-plane scale, physical stone/mortar
  masks; only exactly transparent padding trimmed. Existing geometry unchanged.
- Current vertical source is vertical-hairline-readable.png; the very thin
  replacement disappeared at game scale. Diagonal drafts and both original
  vertical candidates, prompts, hashes and user references are preserved.
  Chip-worn stays unchanged; no revised violet corruption style in this study.
- Reproduce with prepare_isometric_edge_cracks_review.cjs,
  capture_isometric_edge_cracks_review.gd and prepare_isometric_edge_cracks_boards.cjs.
  comparison.png shows actual .75 size and labelled x3 crops. Two Godot captures
  use identical hosts/camera/lighting, exit0, empty stderr; visually inspected.
- This is an isolated proposal, not a production correction or new approval.
  Active atlas/scenes/scripts and all v1 selection files remain unchanged.
  No automated tests, production export/import, commit or push. Await feedback
  on the varied shapes and how they join the stone edges before integration.

## Approved isometric damage decorations integrated — 2026-10-24

- User accepted the next step: integrate the four selected decorations with a
  sparse, varied distribution. isometric_approved_decorations.cjs verifies the
  selection hashes and adopts the twelve prepared PNGs without repainting.
- Active catalogue: 47 regions, 1024x1024, 583101 PNG bytes / 4 MiB RGBA. Prior
  35 regions preserve raw RGBA and all non-region metadata. New twelve regions
  exactly match the approved review atlas pixels; prepared PNGs are copied
  byte-for-byte. All 35 accepted selection file hashes remain unchanged.
- dungeon_surface_details.gd chooses existing floor/wall hosts from logical
  coordinates and seed, with candidate neighbour exclusion and rare corruption.
  Skip special cells, walls beside specials, torch mounts and floor cells under
  the heart support. Draw immediately after each host, before later solids and
  (for floors) ground shadows. No screen rotation, painting or per-frame work.
- Twenty production layout scenes explicitly enable surface_details. Inspector
  surface_detail_seed defaults to 17. Script/default plans stay disabled so old
  approved reviews do not gain extra decoration. Isolated props and the special
  entrance board remain bare. No layout, camera or existing sprite changes.
- Evidence: isometric-decoration-review/v1/integration/. Four focused captures:
  off=0, seed17=8, seed43=4 details; restoring17 yields identical image hash.
  Runtime 68 captures/23 scenes and import: exit0, empty stderr. Editor21/five:
  exit0, existing native progress/window/resource diagnostics (1399 stderr bytes).
- Resource ZIP489337 bytes, 46 dependencies/23 scenes; staged import, export and
  isolated startup exit0, empty stderr. Independent focused read-only code and
  visual review found no concrete issue. No automated tests, phone profile,
  commit or push. User judgment of the automatic distribution remains open;
  accepted art and earlier approval snapshots are preserved.

## Isometric damage decal appearance accepted — 2026-10-24

- User replied "Ok" to the four decoration proposals and linked Godot comparison.
  Retain short crack v2, branched crack, chipped patch v2 and restrained violet
  corruption, each projected onto floor and both visible wall planes.
- isometric-decoration-review/v1/selection.json freezes the selected artwork,
  12 prepared sprites, 256x256 atlas, boards, captures and preparation sources.
  Preserve these images and their scale; do not regenerate them for integration.
- This supersedes the pending appearance status below. Existing preparation and
  validation JSON remain pre-approval snapshots. Production integration is still
  pending; this step records selection only, with no new rendering, automated
  tests, production changes, commit or push.

## Isometric damage decal proposals — 2026-10-24

- User asks for cracks and other variants after accepting torch-oriented shadow.
  Continue bare base surfaces with separate optional details; no repeated neon
  Y mark or full copies of the architecture for every decoration.
- Current appearance review: docs/reference/isometric-decoration-review/v1/.
  Built-in ImageGen native-alpha sources: short crack, branched crack, chipped
  patch and restrained violet corruption. Originals/prompts retained; short and
  chip v2 refinements are current. No user selection of these appearances yet.
- prepare_isometric_decoration_review.cjs projects each source onto floor and
  both visible vertical wall planes, using the frozen isometric geometry. One
  uniform scale in each source plane; alpha128 only measures subject size.
  Preserve native alpha except geometric visibility and wall mortar masks.
- 12 sprites, 256x256 review atlas, 12874 PNG bytes / 256 KiB RGBA. Godot loads
  prepared pixels and draws immediately after the host, respecting foreground
  ordering and shared lights. No runtime image warp or new light/shadow source.
- Decorations.tscn is an isolated review under ignored docs, executable by
  explicit path. Space toggles overlays, fixed .75 zoom and pan. Sparse authored
  placements demonstrate the style; no production placement API/randomization.
- Six Godot captures exit 0, empty stderr; variants/scene-comparison/full scene
  visually inspected. Independent focused review found no concrete issue.
  Production kit/scenes unchanged, all 25 accepted v6 selection hashes match.
  No automated tests, production export, device profile, commit or push.

## Torch-oriented heart shadow v6 accepted — 2026-10-24

- User replied "Ok" after the placement comparison and explanation of eight
  directions, fixed length, contact-only fallback and unchanged 4 MiB atlas.
  Retain this approach and the presented appearance. This supersedes v6's
  pending feedback status below; production was already integrated.
- painted-v1/heart-shadow-v6/selection.json freezes the reviewed boards, shown
  captures, prepared effects, implementation and catalogue. Reviewed examples
  show directions 2, 7 and 1, not individual approval of every possible layout.
- This records the selection only: no new rendering, artwork, automated tests,
  commit or push. Preserve the original heart and prior approval history.

## Heart shadow follows authored torch placement — 2026-10-24

- User accepted v5 visually, questioned its orientation, then approved choosing
  the cast from nearby light. They explicitly note that torch positions cannot
  be known in advance. Do not bake a particular scene's torch placement.
- Current v6 prepares eight world-XY cast directions plus contact-only fallback
  from unchanged rigid geometry. Renderer chooses the nearest positive-energy
  active torch within its actual screen light radius and a floor path without
  void/specials, using new emitter_world metadata. Placement-property setters
  refresh both editor and runtime. Stable distance buckets break ties by key.
- Direction selection is discrete; cast length stays artistic/fixed. No screen
  rotation, runtime rasterization, multi-light simulation, or automatic tracking
  of directly moved generated PointLight2D nodes. Other props do not occlude the
  light path; general PointLight2D wall leakage remains outside this change.
- One prepared effect per heart. If disabled, out of range, absent, or the cast
  does not fit receiving floor, use contact only if that fits. Standalone heart
  uses contact only. Original actual footprint and emissive-vortex exclusion stay.
- All non-shadow prepared PNGs unchanged by hash. Eight new shadow regions and
  changed heart-shadow fallback; 35 regions, 1024x1024 atlas, 570722 PNG bytes,
  still 4 MiB RGBA. Diffuse effects use half-density atlas rasters; logical frame
  and support bounds stay unchanged. prepare_mobile_reference.pack defaults to
  full density for other entries; renderer uses declared logical size.
- Evidence: painted-v1/heart-shadow-v6/ with v5 snapshots, comparison, placement
  comparison, seven visual captures and source-selection observations. Reproduce
  with capture_isometric_shadow_orientation.gd and
  prepare_isometric_shadow_orientation_review.cjs. Current scene files unchanged.
- Import, 68 runtime captures / 23 scenes and seven placement captures: exit 0,
  empty stderr. Editor 21 / five: exit 0, native progress/resource diagnostics.
  Isolated resource export/startup results and current ZIP size: validation.json.
  Focused independent review found one minor near-tie inconsistency; corrected
  with one quantized-distance comparison, then repeated import/captures/export.
  No automated tests, APK/device profile, commit or push. Appearance remains for
  user feedback; prior v5 positive feedback is not approval of all v6 variants.

## Radial shadow rejected; directional v5 integrated — 2026-10-24

- User says an all-directions shadow is not credible. Reject v4 radial scaling;
  preserve heart artwork/material, geometry and position.
- isometric_ground_shadow now projects height onto z=0 with light [-2.1,-1.2,1],
  assuming ambient light from screen upper-left. Cast extends lower-right. All
  area-light samples share that direction; ground points stay fixed. Contact
  uses the real footprint and .7px softness. No enlargement around every side.
- Only heart-shadow.png differs: 251x170, 7496 PNG bytes. Atlas stays 27 regions,
  1024x1024, 550518 PNG bytes / 4 MiB. Existing receiving-floor/standalone rules,
  static-light limitation and exclusion of emissive vortex remain.
- Evidence: painted-v1/heart-shadow-v5/ with v4 snapshots. Reproduce comparison
  with prepare_isometric_large_shadow_review.cjs --directional after captures.
  New direction shown for feedback, not automatically artistically approved.
- Import/runtime: 68 captures / 23 scenes, exit 0, empty stderr. Editor: 21 / five,
  exit 0 with existing native progress/resource diagnostics. Isolated resource
  ZIP 453767 bytes; stage import/export/startup exit 0, empty stderr.
  No automated tests, device profiling, commit or push.

## Heart shadow size clarified; enlarged v4 integrated — 2026-10-24

- User says the problem is simply that the shadow is too small. This supersedes
  the v3 material hypothesis: preserve the heart artwork/material and geometry.
- isometric_ground_shadow.cjs now scales the full ground footprint by 1.5 about
  [0,0,0]. Keep light direction and opacities; scale edge softness proportionally.
  This is artistic ground-shadow enlargement, not a new physical support volume.
- Only heart-shadow.png changes among prepared PNGs. Frame 349x202, 8604 PNG
  bytes. Receiving bounds scale too; existing floor-fit and standalone rules stay.
  27 regions, 1024x1024, 533290 PNG bytes / 4 MiB RGBA. Heart unchanged by hash.
- Evidence: painted-v1/heart-shadow-v4/, with old generator/catalogue/hashes and
  before captures. prepare_isometric_large_shadow_review.cjs builds the comparison.
- Import/runtime: 68 captures / 23 scenes, exit 0, empty stderr. Editor: 21 / five,
  exit 0 with native progress/window/resource diagnostics. Resource ZIP 454207
  bytes; stage import/export/isolated startup exit 0, empty stderr. No automated
  tests, device profile, commit or push. New size shown for visual feedback.

## Shadow v2 rejected; heart material/contact diagnostic — 2026-10-24

- User rejects both v2 proposals and cannot easily describe the desired result.
  No shadow appearance is selected. Stop cycling shadow strength/blur alone.
- Offline diagnostic: painted-v1/heart-contact-diagnostic-v3/, reproduced by
  tools/prepare_isometric_heart_diagnostic.cjs. Same floor, anchor, rigid geometry
  and production shadow in three panels: existing heart; neutral material with
  identical approved vortex sampling/depth; neutral volume without vortex.
- Working visual hypothesis: dark, high-contrast lower pedestal material may
  contribute to floating. This is an interpretation, not proven root cause or
  artistic approval. Neutral volume is diagnostic, not replacement heart design.
  Any future material revision remains a proposal; preserve sculpted source art.
- Production atlas/catalogue/renderers/generators and frozen geometry unchanged.
  No new ImageGen source, automated tests, Godot import/export, commit or push.

## Heart shadow v1 rejected; v2 contact proposals — 2026-10-24

- User says the shadow is still wrong. Do not treat the previous technical review
  as visual approval. Clarification (floating, shape or direction) is pending.
- Current production contact blur is .7 source px, only .525 at zoom .75; most
  contact lies under the opaque support. An offline comparison shows stronger
  diffuse contact, then the same contact with a longer cast shadow.
- Evidence: painted-v1/heart-shadow-v2/, reproduce with
  tools/prepare_isometric_shadow_contact_review.cjs. The configurable helper
  is isolated in isometric_ground_shadow_study.cjs; production helper unchanged.
  Comparison uses identical floor/heart PNGs at .75 and no scene lighting.
- These are unselected appearance proposals, not integrated corrections. Atlas,
  catalogue, renderer, original art and geometry unchanged. No automated tests,
  production export/import, commit or push. Await visual preference before adoption.

## Ground shadow added for the heart — 2026-10-24

- User accepts perspective and requests a projected shadow to ground the support.
  tools/isometric_ground_shadow.cjs prepares a separate floor-only PNG from the
  frozen rigid heart faces, with a short soft cast and denser contact. Exclude
  the emissive vortex; no source artwork or geometry changes.
- heart-shadow is 233x134 / 4625 PNG bytes. New atlas: 27 regions, 1024x1024,
  497846 PNG bytes / 4 MiB RGBA. Prior prepared PNGs remain byte-identical.
- ground_shadow/ground_effect metadata selects the prepared effect. Renderer
  draws it after all floors, before all solids, with light_mask=0. Entire receiving
  bounds must fit floor outside specials in dungeon layouts; otherwise omit.
  Standalone DungeonHeart has no layout and also displays the shadow on its
  preview background. Static upper-left light,
  no dynamic torch response or projection onto walls.
- Evidence: painted-v1/heart-shadow-v1/, including before snapshots and comparison.
  Reproduce comparison with prepare_isometric_shadow_review.cjs after captures.
  Import/runtime: 68 captures / 23 scenes, exit 0, empty stderr. Editor: 21 / five,
  exit 0 with existing native diagnostics. Resource ZIP 439528 bytes; stage import,
  export and isolated startup exit 0, empty stderr. No automated tests, APK/device
  profile, commit or push. Focused independent review found no remaining issue
  after documenting the standalone exception. Retain prior correction snapshots.

## Isometric floor seams and heart contact corrected — 2026-10-24

- User reported flat bands/seams across paving and a black band under the heart.
  Evidence: isometric-review/painted-v1/floor-seams-v2/, frozen before snapshots
  and comparison.png. Reproduce comparison with prepare_isometric_floor_contact_review.cjs.
- Floor finish must use complete periodic stone edges, not the clipped visible
  guide (which suppressed 18 crossing edges). Visible guide coordinates stay.
  Two source pixels of periodic colour coverage outside the diamond prevent
  filtered alpha seams. Include neighbouring rows with unchanged seeds/UVs.
  Floor PNG frame is 270x138; logical bounds remain [0,0,0]–[1,1,0].
- Heart side fascia now samples source rows 242–252 above the old painted shadow,
  instead of rows 250–260. The previous shadow was stretched and made opaque on
  the side face. Ground remains z=0; geometry, vortex and source art unchanged.
- Only floor.png and heart.png differ among prepared sprites. Frozen geometry
  hash unchanged. Active atlas: 26 sprites, 1024x1024, 508995 PNG bytes / 4 MiB.
- 68 runtime captures / 23 scenes and import: exit 0, empty stderr. 21 editor
  captures / five scenes: exit 0; native progress/window/resource diagnostics
  remain. Resource ZIP 436713 bytes, 45 dependencies / 23 scenes; staged import,
  export and isolated startup exit 0, empty stderr. No APK/device profile.
- Independent focused code/visual review found no remaining issue. No automated
  tests, commit or push. Preserve original artwork approvals and editor state.

## Isometric painted migration implemented — 2026-10-24

- User requested applying/migrating textures after the wireframe phase. Active
  assets/dungeon/isometric-kit now contains 26 painted sprites, one 1024x1024
  atlas: 497604 PNG bytes / 4 MiB RGBA. All 23 scenes use this common catalogue.
  Shared light-falloff remains 128x128 / 5151 PNG bytes / 64 KiB RGBA.
- Reproduce with tools/export_isometric_painted_kit.cjs. It checks the immutable
  migration-v1/geometry.json SHA256 (316151de97888a6418dd156af75a10f29b63ce497dd5c2e48e07cf45fbf646f0),
  preserves 2:1 projection, logical 1x1, dimensions, two wall courses, .75 fixed
  zoom/free pan and layouts including SixRoomPreview's two-cell corridors.
- New evidence only in docs/reference/isometric-review/painted-v1/: sprites,
  per-item transparent magenta guides/overlays, recipe, captures and logs.
  Geometry and wireframe-v1/migration-v1 review snapshots remain unchanged.
  No ImageGen regeneration: prior approved materials/art remain immutable.
- Stone UVs follow XYZ planes, with quiet mobile materials and rounded B finish.
  Floor crossing stones are painted whole before cropping. Pillar base stays bare;
  optional pillar-top-carved maps its existing source within the original rim.
- Door v8 geometry and approved v2 face artwork are retained on both faces.
  Bake the complete nested assembly before splitting at wall height. Use final
  pixels with a 2px opaque interior colour overlap for linear filtering at .75;
  disjoint alpha masks alone cause a hairline after filtering. Do not enlarge
  outer alpha. Door canvases have 3px extra padding per side; support bounds stay.
- Heart is an APPEARANCE ADAPTATION: ritual-v3 cap/field/border details mapped
  onto frozen schematic rigid geometry, hidden back field mirrored from visible
  front, approved vortex spatially masked as a camera-facing layer. It is not a
  new approved artwork nor the identical old PNG. Preserve original approvals.
- Torches reuse approved metal and rounded flame-v3, one uniform screen scale,
  constant-x+y billboard with physical cup occlusion. Existing local lights return.
  No new wall orientations, dynamic geometry or runtime image generation.
- Import and runtime capture: 68 images / 23 scenes, exit 0, empty stderr.
  Editor: 21 images / five scenes, exit 0; native window/progress/RID/resource
  shutdown diagnostics remain. Do not call editor stderr clean.
- Resource export: 45 dependencies / 23 scenes, ZIP 432264 bytes. Fresh staged
  import/export/startup exit 0, empty stderr; not an APK or device profile.
  Final review closed the filtered door join and provenance omissions, with no
  remaining code finding. Artistic approval and light leakage were not inferred.
- Default capture/board/export inventory now targets painted-v1. Historical
  wireframe tools remain available (--wireframe for board/export, --output-root
  for captures). No automated tests, commit or push; preserve user editor state.

## Isometric wireframe migration implemented — 2026-10-24

- User requested migration and explicitly selected wireframes first, then textures.
  Active catalogue is assets/dungeon/isometric-kit/: 25 prepared sprites in one
  1024x1024 atlas, 99844 PNG bytes / 4 MiB RGBA. Prior painted kit/sources retained.
- tools/export_isometric_kit.cjs reproduces the current kit. Geometry uses the
  approved selection camera, logical 1x1 cells, two wall courses and existing
  door/stair/torch volumes. All 23 active scenes use the common renderer.
  Fixed .75 zoom, free pan, layouts and SixRoomPreview two-cell corridors remain.
- Doors preserve v8 geometry. Bake mutual visibility of both arches, recessed
  smooth wall and leaf together; split at wall height into lower (`leaf`) and
  upper (`arch`) prepared sprites without a drawn seam. Independent interlocking
  ring sprites cannot be correctly ordered using only their bounding boxes.
- Heart is still schematic, not new approved art. Torches are rigid mounts/cups
  only, without flame/light; pillars are bare. Adapt approved painted appearance
  later, after reviewing the complete wireframe. Do not regenerate approved art.
- Projection metadata on mobile_kit_definition drives grid_to_local/local_to_grid,
  positions and support depth. Historical catalogue defaults remain oblique.
  Godot creates no geometry or image pixels. Per-item transparent magenta guides,
  geometry, recipe and captures: docs/reference/isometric-review/migration-v1/.
- Runtime capture: 68 images / 23 scenes, import and capture exit 0, empty stderr.
  Editor: 21 images / five scenes, exit 0, but native window/progress/resource
  shutdown diagnostics remain; do not describe editor stderr as clean.
- Export graph: 45 dependencies / 23 scenes; resource ZIP 138791 bytes. Staged
  import, export and package startup exit 0, empty stderr. No APK/device profile,
  automated tests, commit or push. Preserve user editor/cache state.
- Old export_mobile_kit and painted review tools refer to historical appearance.
  New captures/export inventories go to migration-v1, never frozen approvals.
- Independent read-only review found one stale authored camera in SingleCellRoom;
  corrected to projected centre (0,64), zoom .75, then captured in editor/runtime.
  No Critical/Important code finding or deferred minor remains in this review.

## Isometric projection approved — 2026-10-24

- User replied that the isometric view fits better, removes the perspective
  conflict and keeps the wireframe logic. The proposed 2:1 projection and
  common geometric frame are APPROVED as the direction for subsequent work.
  This supersedes the old requirement to preserve oblique wall projection.
- docs/reference/isometric-review/wireframe-v1/selection.json records the exact
  reviewed geometry/boards and this approval scope. Preserve these references.
  geometry.json retains its pre-approval snapshot status; selection supersedes it.
- Continue with logical 1x1 cells, common projection for floor/architecture and
  rigid prop supports, offline wireframes/masks, then prepared sprites. The
  schematic heart is not a newly approved artwork/design. Existing approved
  artwork sources remain references for appearance when adapting the view.
- Approval records the direction. Full-kit reprojection, new painted exports
  and Godot migration remain to be implemented; do not describe them as done.
  No new rendering, automated tests, commit or push in this approval step.

## Initial isometric feasibility study — 2026-10-24

- User proposes 2D isometry, citing Jeeyoung Lee's ArtStation 4bevKn project,
  and asks whether our wireframes can use its diamond-grid approach. This opens
  a new whole-scene projection STUDY after the floor-only attempts; it does not
  approve migration of the active kit or undo prior artwork approvals.
- Latest: docs/reference/isometric-review/wireframe-v1/. Reproduce with
  prepare_isometric_wireframe_review.cjs. Proposed game isometry is 2:1
  (strictly dimetric): screen=256*((x-y)/2,(x+y)/4-sqrt(3/8)*z).
  This ratio is our proposal, not a measured claim about the linked artwork.
- Same 13 logical cells, 1x1 square coordinates/neighbours, two wall courses,
  physical wall/pillar dimensions. Each source diamond is 256x128, displayed
  192x96 at .75 zoom. Pink marks logical cells; small paving is decorative.
- Room-grid and logical-grid boards inspected after export. Heart remains a
  schematic support, not new approved art. This review has no production scene,
  atlas, input, draw-order or painting changes. Door/stair/torch reprojection,
  prop art and foreground-wall visibility remain later migration work.

## Floor-only correction; wall camera change rejected — 2026-10-24

- User explicitly corrected the scope: only the floor was to change. The v1
  35-degree camera changed the walls and is REJECTED. Preserve the original
  wall/pillar projection, dimensions, placement and room footprint.
- Latest study: ground-perspective-review/wireframe-v2-floor-only/. Reproduce
  with prepare_floor_only_wireframe_review.cjs. Only the short paving joints
  are inclined (dx/dy=.2); horizontal rows and stone widths remain unchanged.
  This is a stylized paving-pattern proposal, not a new physical ground camera.
- Both panels use the original (x-.18z,y-.9z) projection and the same schematic
  heart. Export guards require exactly identical solid faces and non-floor
  source/visible edges. No approved art, production scene or atlas was changed.
  Retain v1 as rejected history; do not treat its camera as awaiting adoption.

## Rejected global ground perspective wireframe proposal — 2026-10-24

- User now questions the floor/heart perspective and explicitly requests a new
  wireframe with a perspective floor. This supersedes the historical flat-floor
  restriction for this study; it does not approve a new production camera.
- Review: docs/reference/ground-perspective-review/wireframe-v1/. Reproduce with
  prepare_ground_perspective_review.cjs. Proposed orthographic elevation is 35°:
  screen=(x, sin(35°)*y-cos(35°)*z). The floor, walls and schematic heart support
  share this projection; logical cells remain 1x1 (192x110.13 displayed pixels).
- Same 13-cell MobileReference occupancy, physical wall/pillar dimensions and
  two facade courses. Heart is a schematic stepped .8125-square support with
  four corner stones and a circular socket; it is not the approved painted art.
  The vortex is a camera-facing outline. Ray/triangle visibility removes hidden
  edges; room-transparent contains only visible strokes with native SVG alpha.
- Room, side-by-side comparison and heart detail are offline review drawings,
  not Godot captures. Camera/art approval and production migration remain pending.
  Retain all approved painted sources and active kit/scenes. No runtime image
  warping, new painting, automated tests, commit or push in this proposal.

## Approved torches integrated — 2026-10-24

- User said "continuons" after appearance approval. Both approved complete PNGs
  are now adopted unchanged by mobile_approved_torches.cjs, guarded by selection
  hashes; no ImageGen regeneration or new perspective fitting during export.
- Kit: 50 sprites, 1024x2048 atlas, 991208 PNG bytes / 8 MiB RGBA. Prior 48
  regions retain exact pixels, offsets, bounds and companions after repacking.
  Shared light-falloff.png is separate: 128x128, 5151 PNG bytes / 64 KiB RGBA.
- Common renderer places north/west wall mounts using the approved offsets and
  support order. wireframe_cell_study exposes torch_north_cells, torch_west_cells
  (integer cell arrays), and torch_lights_enabled. Missing walls, openings,
  special door/stair cells and duplicates cannot create floating torches.
- MobileReference contains north (1,0) and west (0,1), with the existing heart.
  Other layouts stay undecorated by default. DungeonTorch is migrated to the same
  atlas and alpha_torch.gd with a selectable orientation. Other wall-facing art
  is not approved; do not mirror/rotate prepared torches to invent it.
- Per-torch metadata stores emitter, radius190, energy2.4 and orange colour.
  Painted torch sprites have light_mask=0; optional PointLight2D adds local light.
  Rebuilds retire old generated lights; editor refresh includes the falloff.
  Static lights have no animation/shadows; light leakage through other walls
  and mobile performance remain outside this integration's validated scope.
- Reproduce export_mobile_kit, Godot import, capture_approved_torches and
  prepare_approved_torch_review; capture_mobile_kit supplies scene/editor views.
  Evidence: docs/reference/mobile-light-review/painted-v2/integration/.
- Resource export now includes DungeonTorch: 45 source dependencies / 23 scenes.
  ZIP 726759 bytes, no authoring/rejected torch files. Staged import, resource
  export and package startup exit 0, empty stderr. It is not an APK/device profile.
- Runtime captures/import are clean. Custom editor capture exits 0 but emits
  native window/progress/resource shutdown diagnostics; do not call it clean.
  Independent read-only review found no actionable code findings; its pending
  staging reminder was completed. No automated tests, commit or push requested.

## Rounded torch flame base approved — 2026-10-24

- User replied "Ok" to the rounded-base gameplay comparison. Appearance is
  APPROVED. painted-v2/selection.json freezes source/metal, geometry, prepared
  sprites, recipe and reviewed capture hashes. Preserve this artwork and scale;
  do not regenerate it for future integration. This supersedes pending status.

- User rejects the pointed bottom of flame-v2. Its narrow neck/droplet made the
  fire look detached from the cup. Latest source is painted-v2/source/flame-v3.png:
  ImageGen redraws a full rounded base with no stem. Keep both previous sources.
  Exact prompt/provenance: painted-v2/flame-base-review/generation.json.
- prepare_mobile_torch_paint.cjs preserves ONE scale for both source axes, with
  the existing kit height shear. New height .215, base z=.20, root centre measured
  on the bottom 8%. The entire flame is uniformly smaller; never squeeze X alone.
  This supersedes v2's .27 height and .186 base. Depth masks place the rounded
  lower edge behind the cup rim; approved metal geometry/material stay unchanged.
- Current horizontal/vertical canvases: 58x84 / 56x108. Both rendered in Godot at
  .75 zoom and inspected; capture process exit 0, empty stderr. Comparison uses
  actual game pixels x2. The pointed previous version is frozen under
  flame-base-review/before/. Prior comparison boards remain historical snapshots.
- This selection records appearance only. Production integration is pending.
  No automated tests, production changes, commit or push in this approval step.

## Historical pointed flame v2; preserve source proportions — 2026-10-24

- User correctly flagged the previous flame as elongated: its width had been
  compressed independently of height. That fit is rejected and superseded here.
- Current source is painted-v2/source/flame-v2.png, redrawn with built-in ImageGen:
  narrower root, fuller upper body. Exact prompt/provenance is retained in
  painted-v2/flame-shape-review/generation.json. Keep the original source too.
- prepare_mobile_torch_paint.cjs uses ONE image scale: worldPerPixelX equals
  worldPerPixel, with the existing kit height shear. Centre the bottom 8% of the
  flame, set base z=.186 at the cavity floor, retain .27 world height. Never fit
  its horizontal axis independently again. Native alpha and depth occlusion stay.
- Approved metal vertices/materials and production assets are unchanged. Current
  horizontal/vertical canvases are 76x97 / 76x121. The squeezed proposal is frozen
  under flame-shape-review/before/; comparison.png shows actual Godot pixels x2.
- Both orientations captured and inspected; process exit 0, empty stderr.
  Appearance remains a proposal. No automated tests, production promotion,
  commit or push requested.

## Historical squeezed torch flame correction — 2026-10-24

- User reported flames spilling outside the painted cup. The height-derived
  scale made solid fire .181 cell wide at the rim versus its .120-cell opening.
  Depth occlusion alone cannot hide fire outside the metal volume.
- prepare_mobile_torch_paint.cjs now derives the approved inner rim radius from
  bowl vertices and fits horizontal flame sampling to 90% of the aperture.
  Maximum solid width .108 cell; source image, height .27, base z=.204, metal
  geometry/material and projection stay fixed. This is offline plane fitting,
  not runtime distortion or alpha thresholding. prepared.json records the fit.
- Current PNGs: horizontal 64x109 / 7672 bytes, vertical 64x133 / 9672 bytes.
  Previous sprites/captures/recipe are frozen under painted-v2/flame-fit-review/
  before/. --boards regenerates its before/after comparison when baseline exists.
- Both corrected Godot orientations inspected, capture exit 0, empty stderr.
  No automated tests, production promotion, commit or push requested. Painted
  appearance still awaits user feedback; the structural approval remains valid.

## Torch structure approved; painted review — 2026-10-24

- User replied "Oui" to the horizontal/vertical torch wireframe. This approves
  plate/arm/hollow-cup geometry and supersedes its pending status below.
  wireframe-v1/selection.json freezes geometry/comparison SHA256. Preserve them.
- Latest painted review: docs/reference/mobile-light-review/painted-v2/.
  ImageGen iron material + native-alpha flame originals/prompts are retained.
  Appearance, flame and production integration still await user review.
- prepare_mobile_torch_paint.cjs loads the approved faces without changing any
  vertex. Offline depth masks, shared local material coordinates and warm face
  shading paint both orientations. Dark strokes remain within the shape. The
  flame's vertical XZ plane follows the kit's height projection; source alpha
  is retained except for physical cup/wall occlusion. No runtime deformation.
- Prepared torch-horizontal is 90x109 / 8560 bytes; vertical 91x133 / 10553.
  One precomposed PNG per view, 256 px/cell, .75 zoom. Review renderer uses the
  common support order and optional local lights. No production atlas/scenes
  changed. Crystal and other orientations are not revised here.
- Reproduce: prepare_mobile_torch_paint.cjs, capture_mobile_torch_paint_review.gd,
  preparation --boards. game-view.png is an unscaled Godot crop; structure
  comparison includes a magenta guide over metal alone so the flame cannot hide
  structural edges. Two captures exit 0 with empty stderr; inspected visually.
  No automated tests, device profiling, commit or push requested. JSON under
  mobile-light-review retains exact bytes in Git for approval hash stability.

## Wall torch perspective wireframe proposal — 2026-10-24

- User rejected the front-facing light props' wall perspective and accepted
  a structural torch wireframe on horizontal and vertical walls before painting.
  Latest review: docs/reference/mobile-light-review/wireframe-v1/. Appearance
  and geometry remain pending; previous lit sprites are style references only.
- prepare_mobile_torch_wireframe.cjs uses the kit's exact project/T/H/PX exports.
  One volume rotates in world XY before projection. Plate rear v=0 contacts the
  wall facade; arm supports a hollow cup. Cyan=plate/arm, amber=cup, grey=wall.
  The wall retains two facade courses. No invented floor foreshortening; circles
  in a horizontal plane stay circular in this project's fixed projection.
- Hidden edges are clipped against triangulated surfaces along (.18,.9,1).
  Geometry and visible segments saved in geometry.json; transparent magenta
  context guides at 256 px/cell, native views at .75 and enlarged comparison.
- Flame omitted during rigid-structure approval. Crystal not yet revised.
  No painted image edit, runtime deformation or production asset/scene change.
  Two orientations/details inspected; exporter exit 0. No automated tests,
  commit or push requested. Obtain structural feedback before new painting.

## First light decoration appearance proposal — 2026-10-24

- User said "Ok go" after the proposal to start with an orange wall torch and
  an embedded purple crystal. Review: docs/reference/mobile-light-review/.
  Appearance is pending; production atlas/scenes remain unchanged.
- Native-alpha ImageGen originals and exact prompts are saved in source/ and
  generation.json. Whole-source uniform reduction preserves all alpha; alpha
  threshold 128 only measures solid subject height, never extracts a background.
- Prepared torch is 73x109 (7897 bytes), crystal 75x68 (5363 bytes). Subjects read
  at about 66/41 displayed px at fixed .75 zoom, 256 source px/cell. Mounting plate
  and chipped stone socket are painted with the props; evaluate in game-scale
  comparison.png, not enlarged source art. First frontal wall orientation only.
- tools/mobile_light_review.gd uses the shared architecture renderer and support
  ordering, prepared sprites and two local PointLight2D sources. Light falloff is
  prepared offline. No runtime paint or perspective warp. No shadows/animation
  in this review; neighbouring-room light leakage and device cost remain unproven.
- Reproduce with prepare_mobile_light_review.cjs, capture_mobile_light_review.gd,
  then the preparation tool's --boards option. Standalone LightReview.tscn is
  under ignored docs/, loaded by explicit path; Space toggles local lights.
  Two visual captures exit 0 with empty stderr; inspected at gameplay size.
  No automated tests, production promotion, commit or push requested.

## Approved heart integrated — 2026-10-24

- User explicitly said "Oui" to integrating the selected sculpted vortex heart
  into Godot. This supersedes proposal-only gates for ritual-v3. Appearance and
  selection are frozen; do not regenerate it during exports.
- mobile_approved_heart.cjs verifies selected hashes, native alpha and reviewed
  placement, then supplies the unchanged 289x289 prepared sprite to the common
  atlas. 48 sprites, 1024x2048, 974698 PNG bytes, still 8 MiB RGBA. All 47 prior
  atlas regions retain exact pixels and offsets/bounds/companions after repacking.
- Ground anchor [144.5,155.792663476874], .8125-square support, .98 high, 256 px/cell,
  .75 zoom and ~156 displayed px base. Heart is a painted prop on the flat floor;
  support bounds serve draw ordering, never perspective warping or gameplay collision.
- wireframe_cell_study.heart_positions exposes ground centres in cell units.
  MobileReference uses (1.5,1); SixRoomPreview and DungeonPreview use (12,14).
  Other layout studies stay empty by default. Whole support must lie on floor,
  outside stair/door cells. Heart shares physical ordering with walls/pillars.
  DungeonHeart/alpha_heart use the same atlas at ground origin; old large heart
  PNG remains historical and is no longer a runtime dependency. No extra dynamic
  light is added over the approved artwork.
- Evidence: docs/reference/mobile-heart-review/ritual-v3/integration/. 60 focused
  checks / 11 captures pass. Full runtime: 63 captures / 21 scenes, clean stderr.
  Three editor scenes / 11 captures; matching-camera heart views equal runtime.
  Editor capture process exits 0 but emits native resource/window shutdown
  diagnostics; do not call its stderr clean. Initial capture hit Windows locks
  on existing review files: use capture_mobile_kit -- --output-root=res://<fresh>
  and prepare_approved_heart_review.cjs --publish-captures --capture-root=<fresh>
  for atomic replacement. Capture helper now reports save failures and exits.
- Export graph: 42 active source dependencies / 22 scenes including DungeonHeart,
  one atlas. Resource ZIP 705339 bytes; staged import, export and package opening
  exit 0 with empty stderr. No old heart PNG, authoring sources or retired kits
  shipped. ZIP is not an APK/device profile. Independent focused review found no
  actionable issues. No commit/push requested; preserve user's editor/cache.

## Sculpted vortex heart appearance approved — 2026-10-24

- User replied "Ok" to ritual-v3's actual-game-size before/after. Retain the
  sculpted ritual pedestal, vortex and flat support orientation as the approved
  heart appearance. This supersedes pending appearance gates in the history below.
- Selection and exact source/prepared/comparison SHA256 hashes are frozen in
  docs/reference/mobile-heart-review/ritual-v3/selection.json. Preserve the art;
  generation.json and prepared.json remain snapshots from before approval.
- Approval records the visual choice. Production integration has not been
  performed in this selection step. No new tests, commit or push requested.

## Richer heart pedestal proposal — 2026-10-24

- User explicitly likes the vortex and accepts perspective-v2's corrected image,
  but finds its pedestal too simple for the dungeon heart. Preserve the flat
  support orientation and vortex; enrich the pedestal with readable sculpture.
  This supersedes the undecided A/style/perspective status in the history below.
- Latest appearance proposal: docs/reference/mobile-heart-review/ritual-v3/.
  ImageGen edits the corrected A source: four carved corner stones, concentric
  focus, recessed geometric stone field, violet channels and stepped border.
  Original native-alpha image and exact prompt are frozen in source/generation.
  New pedestal appearance still awaits user review; do not infer integration.
- prepare_heart_perspective_review.cjs --ritual-v3 prepares both densities;
  --ritual-v3 --boards compares with frozen perspective-v2 at actual game scale.
  capture_mobile_heart_review.gd -- --ritual-v3: six captures, 44 passing checks,
  exit 0, empty stderr. Actual-size comparison and front-wall occlusion inspected.
  Checks cover image loading/placement/draw order, not artistic approval.
- Keep complete native alpha, uniform reduction, ~156 displayed px base, .75
  zoom and square support bounds. Density 256 sprite is 289x289 / 137216 bytes;
  density 128 is 144x144 / 36536 bytes. No runtime painting or perspective warp.
  Active atlas/catalogue/heart/scene hashes match the frozen review baseline.
  Previous proposals retained. No production changes, commit or push requested.

## Heart perspective correction proposal — 2026-10-24

- User finds the three heart proposals' perspective incorrect. Their compressed
  top surface and elliptical socket copied the old front/three-quarter pedestal
  view. A 2D prop still needs its ground support to agree with the flat floor.
  Do not interpret freedom from architectural wireframes as arbitrary camera angle.
- Current review: docs/reference/mobile-heart-review/perspective-v2/. Only A is
  revised for a controlled comparison; the user has not selected A as the style.
  A simple square-top/circular-socket composition guide is painted by ImageGen.
  This is a screen-space guide, not a forced 3D projection of the entire prop.
  The first retouch remains insufficient; the second generated source is current.
- New source and full prompts preserved, complete native-alpha uniform resize,
  no recolour/threshold/warp. ~156 displayed px base, .75 zoom. Proposed support
  bounds now .8125 square; used only for occlusion. Keep generation's geometric
  approximation distinct from exact architectural geometry; await visual approval.
- prepare_heart_flat_layout.cjs creates the guide; prepare_heart_perspective_review.cjs
  prepares sprites and --boards compares with frozen A. Capture using
  capture_mobile_heart_review.gd -- --perspective-v2. Six captures, 44 passing
  checks, exit 0, empty stderr. These checks validate loading/placement/order,
  NOT artistic perspective. Before/after and front-wall overlap inspected.
- Preserve original A/B/C history, active atlas, existing heart and production
  scenes. No propagation, integration, commit or push requested in this correction.

## Heart sprite proposals and flat-floor distinction — 2026-10-24

- User clarified: floor slabs lie on a flat 2D grid; heroes and standalone props
  convey volume through their artwork. Do not impose the architectural wireframe
  projection on every object. For the heart, user accepted a complete transparent
  sprite approach and explicitly requested several proposals AND tests.
- Review: docs/reference/mobile-heart-review/. ImageGen A vortex, B fractured
  core, C eclipse all retain the square blue-slate pedestal, four short corner
  stones and dark floating orb. Original alpha sources and exact prompts are
  saved in source/ and generation.json. No appearance is selected yet.
- prepare_mobile_heart_review.cjs uniformly reduces complete sources to a common
  ~156 displayed px base width at .75 zoom (192 displayed px/cell). Alpha threshold
  only measures lower masonry bounds; no cutout, colour correction or perspective
  warp. Both 256/128 source densities keep the same proposed ground anchor/scale.
- mobile_heart_review.gd is an isolated renderer subclass, using approximate
  ground-support bounds for draw order only. It reads prepared PNGs directly
  because docs/.gdignore intentionally excludes authoring images from import.
  HeartProposals.tscn is a local review scene, not the main scene or export kit.
- capture_mobile_heart_review.gd: 18 captures, 128 checks, zero failures. Checks
  cover textures, uniform scale, fixed camera and near/far-wall order. Final
  import/capture exit 0 with empty stderr. Inspect gameplay-comparison.png,
  comparison.png (two densities), occlusion-comparison.png. No device profiling,
  hero passage, collisions or animation validation. User authorizes these local
  tests; do not infer blanket permission for unrelated test suites.
- Keep production heart/atlas/scenes unchanged until a proposal is selected and
  integration requested. No commit/push requested during this appearance study.

## Approved door integrated into the mobile kit — 2026-10-24

- User said "Vas-y" after approving art v2. This authorizes and completes the
  production integration, superseding pending/proposal-only gates below for
  this door. Use wireframe-v8 geometry and painted-art-v2 artwork unchanged.
- Active kit: 47 prepared sprites, one 1024x2048 atlas (820,667 PNG bytes,
  unchanged 8 MiB RGBA). Each of four doors uses eight parts: original main arch,
  leaf, inner arch, two jambs and three recessed smooth-wall portions. Keep the
  two arches and smooth masonry above/alongside the wood, at .8T depth; no third
  brick ring. Both leaf faces use the approved arched painting/inset hardware.
- mobile_approved_doors.cjs checks frozen appearance/geometry approvals and
  compares exports to approved PNGs/placements. Main arches are compared to
  frozen atlas pixels after equivalent alpha compositing, avoiding one-level
  partial-alpha RGB rounding differences. Never overwrite frozen approvals or
  reference captures to pass a guard. Production explicitly uses art revision 2.
- Each catalogue leaf declares six `companions`; mobile_dungeon_renderer places
  these prepared textures using the existing physical support-depth ordering.
  Historical review catalogues omit companions and keep their manual extra parts.
  No runtime pixels/materials/perspective generation. Preserve layouts, stairs,
  bare bases, integer grid, 256 px/cell, .75 fixed zoom and free panning.
- Reproduce with export_mobile_kit.cjs, Godot import, capture_mobile_kit.gd and
  prepare_mobile_kit_review.cjs. Then prepare_mobile_export.cjs, stage import and
  Android Mobile resource export. Still 40 runtime source dependencies; generated
  source painting, materials and review files are excluded. Resource ZIP 609,890
  bytes is not an APK. Do not reset the user's editor/cache or scene state.
- Evidence: docs/reference/mobile-door-frame-review/integration/. 28 approved
  components + 19 retained sprites match final atlas pixels/offsets/bounds.
  60 runtime captures / 21 scenes, imports/export/package opening: exit 0, empty
  stderr. 13 editor captures / three scenes; same-camera special views match
  runtime. Two native editor views have authored zoom 1 versus runtime .75.
  Editor helper exits 0 but emits native window/progress/resource diagnostics.
- Fresh independent code review: no actionable findings. No automated tests or
  Android device profiling. No commit/push requested in this integration step.

## Door art v2: inset straps and an arched source painting — 2026-10-24

- User subsequently replied "Ok" to the v2 correction: appearance APPROVED.
  selection.json beside the review freezes the exact source, fitted painting,
  gameplay boards and recipe hashes. Use this art for future door integration;
  v1 and the intermediate broad-strap edit are not the accepted appearance.
  This approval record does not itself migrate the active atlas or scenes.
- User rejects v1 straps too close to the edges and the rectangular source art.
  Paint the actual ROUND wooden crown, including its worn rim/highlights, with
  comfortably shorter inset iron straps. Do not merely crop a rectangular top.
- Current review: docs/reference/mobile-door-frame-review/painted-art-v2/.
  Two built-in ImageGen edits are recorded in generation.json. The first still
  had broad straps; source/door-artwork.png is the refined native-alpha result.
  Keep the original source unchanged. source/arch-template.png comes from the
  approved v8 profile, generated by prepare_mobile_door_art_template.cjs.
- prepare_mobile_door_arch_artwork.cjs fits the painted rim to that profile by
  resampling horizontal source rows. Source alpha >8 locates bounds only; saved
  pixels use premultiplied bilinear alpha, not thresholding/background removal.
  source/fit.json records hashes/bounds/method. No geometry or guide changes.
- Export with prepare_mobile_nested_door_review.cjs --art-v2, capture using
  capture_mobile_nested_door_review.gd -- --art-v2, then export --boards --art-v2.
  v1 remains reproducible with --art. v2 material brightness/saturation .82/.82
  keep the generated painting subdued in the dungeon. Both leaf faces have art.
- 28 parts, 12 captures, exit 0 and empty stderr. Guide files, leaf alpha and
  stone sprites match v8; export coverage reports zero differences/holes/excess.
  Active atlas unchanged. Appearance now approved; integration is still pending.
  No automated tests, commit or push in the approval-record step.

## Door artwork proposal on the approved smooth leaf — 2026-10-24

- User requests a more crafted door matching the dungeon atmosphere. Current
  appearance proposal: docs/reference/mobile-door-frame-review/painted-art-v1/.
  Built-in ImageGen painted broad dark wood, two forged straps, a substantial
  ring handle and one localized violet seal. Original art and exact prompt are
  preserved in source/door-artwork.png and generation.json. Not yet approved.
- The painting maps offline onto BOTH broad faces of the exact v8 leaf. All
  artwork, including hardware, belongs to this optional face texture; no new
  structural joints or hardware guide strokes. Thin edge surfaces retain quiet
  wood. Nested arches and recessed stone keep their previous geometry/paint.
- Reproduce: prepare_mobile_nested_door_review.cjs --art; Godot capture with
  capture_mobile_nested_door_review.gd -- --art; export script --boards --art.
  mobile_door_art_material.cjs supplies the face artwork and local UV mapping.
  Common compositor respects an explicit wood textureTransform; default wood
  mapping is unchanged. No production material recipe or atlas promotion.
- Review at fixed .75 zoom first. Small details in the source are not evidence
  of mobile readability. Gameplay captures and magenta overlays are included.
  Approval remains for appearance only; no commit/push or tests requested.

## Door v8 smooth leaf approved; painted review — 2026-10-24

- User replied "Ok" after the v8 wireframe. Its selection.json records the
  exact approved drawing/geometry hashes. Keep the leaf as one continuous
  surface; no plank or hardware outlines in the structural guide.
- Current appearance proposal: docs/reference/mobile-door-frame-review/painted-v8/.
  Same approved wood texture across the whole leaf, with no forced plank joints
  and no hardware in this bare-material review. Hardware can be separate artwork
  later, on both faces. Arches and recessed infill keep the v7 geometry/paint.
- The nested-door helper defaults to v8; export/capture accept --legacy-v7 for
  historical reproduction. In Godot pass that flag after --. Frozen painted-v7
  stays intact. Common material classification now accepts door.handle=null.
- 28 prepared parts and 12 Godot captures. Export reports: zero construction
  alpha differences, holes or excess pixels; capture exit 0, empty stderr.
  Captures inspected at .75 zoom with magenta guides. Active atlas hash unchanged.
  This is an appearance proposal; no scene/atlas promotion or commit/push.
  No automated tests added or run, no mobile profiling.

## Door leaf: structural outline only, proposal history — 2026-10-24

- User proposes a smooth wooden leaf so its artwork can vary freely. Current
  wireframe review: docs/reference/mobile-door-frame-review/wireframe-v8/.
  It keeps the exact v7 volumes, silhouette, projection, nested arches and
  recessed smooth infill. Only internal plank and handle guide strokes are
  removed; they are optional artwork, not structural constraints.
- Default reproduction: node tools/prepare_mobile_nested_arch_wireframe.cjs.
  --legacy-detailed-leaf reproduces the previous v7 drawing. Keep frozen v7
  geometry/selection and painted-v7 as the prior review, not the latest guide.
- A smooth guide does not require a featureless final texture. Future paint or
  prepared overlays may supply wood grain, planks, hardware or ornaments within
  the same mask/perspective. Preserve handles on both faces when adding them.
- This update prepares the wireframe only. The painted helper still reads v7;
  no new painted export, active atlas, Godot scene, commit or push in this step.

## Door v7 structure approved; painted appearance review — 2026-10-24

- User replied "Ok" to wireframe v7. Its two arches, smooth infill and 80%-depth
  centered wall are approved as the structure. selection.json beside the v7
  wireframe records the exact approved PNG/geometry hashes. This releases the
  wireframe-first gate for preparing the painted appearance.
- Current painted review: docs/reference/mobile-door-frame-review/painted-v7/.
  tools/mobile_nested_door_parts.cjs reads the approved geometry and exports
  leaf, inner arch, two jambs, and three smooth-wall portions per direction.
  Reuse the four ORIGINAL outer arches from the frozen baseline atlas, with
  identical anchors and regions. Never shrink or repaint the main arch.
- Shared mobile stone/wood/iron are reused. Smooth infill has no brick joints,
  texture opacity .20 and common canonical UVs across its three prepared parts.
  The cut at spring H closes paint regions only, with no ink or new end bevel.
  A redundant part mask caused an antialiased gap at that uninked cut; these
  single-material parts use the original fixed geometry silhouette without
  the redundant raster part mask. Common compositor behavior is unchanged.
- Original defaults in mobile_special_parts.cjs remain available; its generic
  paint helper now accepts review-only models/materials. The production special
  export does not invoke the nested-door proposal. Active atlas/scenes unchanged.
- Reproduce: node tools/prepare_mobile_nested_door_review.cjs, then Godot with
  tools/capture_mobile_nested_door_review.gd, then the first tool with --boards.
  The capture tool adds prepared parts using the common renderer and .75 zoom.
  Four directions, wood hardware on both faces; no runtime pixel painting.
- Evidence: 28 prepared new parts, export reports total zero construction-alpha
  differences/unpainted interior/excess pixels; 12 Godot captures exit 0 with
  empty stderr. Active atlas hash equals frozen baseline. Boards inspected at
  game distance with guide overlays. No automated tests or device profiling.
  Appearance awaits user review; no active-atlas promotion or commit/push here.

## Door correction: nested inner arch, wireframe first — 2026-10-24

- Latest user rejected revision 2 (side jambs only). KEEP THE MAIN ARCH and
  create a second, smaller arch inside it. There must be stone ABOVE the wood
  as well as on both sides. Keeping the old wooden crown and clipping only its
  width is not the requested design. This supersedes the jamb-only direction.
- User then corrected revision 3: its intermediate row of bricks reads as a
  THIRD arch. There must be two arches, with no extra brick row between them.
  Revision 4 incorrectly joined the arches. User explicitly corrected this:
  THERE MUST BE SPACE BETWEEN THE TWO ARCHES. Do not merge the two stone rings.
  Revision 5 wrongly left this space empty. Latest explicit correction:
  THE SPACE MUST BE A SOLID SMOOTH WALL, without brick joints. Revision 6 fills
  it with continuous wall geometry, preserving the two separate arch rings.
- User now requests a slightly thinner smooth wall than the arches. Revision 7
  proposes 80% of their depth, centered, with a .016667-cell recess on each face.
  This changes depth only; arch radii, wall band width and wood stay unchanged.
  The exact 80% was proposed, then accepted with wireframe v7 (see selection).
- User explicitly requested a WIREFRAME FOR DESIGN APPROVAL before further work.
  Do not paint this design, propagate it to four directions or promote it into
  the mobile atlas until the user approves the structure.
- Current proposal: docs/reference/mobile-door-frame-review/wireframe-v7/.
  Reproduce with node tools/prepare_mobile_nested_arch_wireframe.cjs. It creates
  a front elevation and the existing oblique projection, with hidden edges
  omitted. White = original main arch, cyan = added masonry and small arch,
  amber = reduced wooden leaf, flat gray = solid smooth wall (schematic fill,
  not a painted material). All output is offline review material only.
- Main arch uses the exact original source prisms and current radial expansion
  T/2: radii 5/12 and 7/12, spring H=1.88/6, depth T=1/6. The proposal's small
  arch radii are .27/.35; wood radius .26; all share spring H. A .066667-cell
  separation between the small arch and the main opening radius 5/12 is filled
  with a smooth wall above and on both sides, with no brick joints or horizontal
  seam at spring H. It occludes hidden lines. Main arch and wooden leaf geometry
  stay unchanged. geometry.json records volumes and edges.
  The smooth wall depth is .133333 cell against arch depth 1/6. Its plane is
  y=.433333..566667; both contact curves and flat-fill masks use that real depth.
  --legacy-three-rings, --legacy-joined and --legacy-open-gap reproduce rejected
  revisions 3/4/5; --legacy-flush-wall reproduces v6 before the depth refinement.
  No painting or active-kit promotion before validation.
- Revision 1 (whole arch reduced) and revision 2 (jambs only, old wooden crown)
  are rejected history. Their painted previews must not be used as approvals.
  Active scenes/catalogue/assets stay unchanged. No commit/push requested.

## Historical rejected door revision 2: original arch plus jambs — 2026-10-24

- User finds the mobile door oversized and requests stone framing between the
  wooden leaf and corridor walls. This supersedes the old direct-on-wall arch
  direction for the new proposal. Review: docs/reference/mobile-door-frame-review/.
- User rejected the smaller/lower arch proposal. They explicitly confirmed:
  KEEP THE CURRENT ARCH, reduce only the wood, add two real stone jambs between
  the wood and corridor walls. Do not shrink, lower or repaint the existing arch.
- Revision 2 keeps the original arch PNG/anchor/size byte-for-byte. The wood is
  clipped to +/- .29 cell horizontally, retaining the original curved crown and
  its height. Each new jamb occupies the side strip between +/- .30 and +/- 5/12,
  rising to the original inner arch curve; horizontal joints at H/2, H, 3H/2.
  Wood width drops 30.4%; outer width and total height are unchanged.
- All four directions are reprojected through the existing offline material/mask
  renderer, preserving double-sided leaf hardware and shared stone. insetDoorParts
  in mobile_special_parts.cjs adds this proposal without changing default exports.
- tools/prepare_mobile_door_frame_review.cjs generates twelve prepared parts
  (wood plus two jambs per direction), reusing the four original arches;
  tools/capture_mobile_door_frame_review.gd places them with the common renderer
  at zoom .75; --boards on the first tool assembles the comparisons. The rejected
  reduced-arch image and its recipe are clearly kept under rejected-v1/ only.
- This is an appearance proposal, not an active-atlas promotion. Frozen baseline
  atlas/catalogue keep before/after reproducible. No scene, entrance, floor or
  mobile-kit asset changes; no commit/push unless requested.

## Retired large assets removed — 2026-10-24

- User explicitly requests deleting obsolete large files after the mobile migration.
  This supersedes earlier instructions to retain retired generated PNGs and local
  archive copies. Keep the active mobile kit, props, material sources, geometry,
  selected reviews and original references.
- Removed painted-connected/, painted-cells/, their unused runtime catalogue and
  style selector, and 17 named obsolete cache/archive directories under artifacts/.
  Exact paths, sizes, SHA256, recovery commits and preserved dependency hashes:
  docs/cleanup/2026-10-24-retired-large-assets.json. No replacement archive copy.
- export_mobile_kit.cjs reads frozen legacy-catalog-inventory.json for historical
  comparisons; it must not require the retired PNG directories to exist.
  Their summed RGBA remains a historical catalogue measure, not old live VRAM.
- Shared materials, wireframe geometry, nw-material-review-v2/validation.json and
  the pillar cap source remain necessary. Historical tools/docs can mention retired
  paths; use the mobile export pipeline for current assets. Git history is retained.
- Do not remove/reset the user's .godot/ cache or editor state. No automated tests,
  commit or push without a user request. See docs/cleanup/README.md for the outcome.

## Full mobile architecture migration — 2026-10-24

- User asks to finish optimization with the rest of the kit. This authorizes
  production migration beyond the prototype and supersedes prototype-only gates.
  All 21 architecture scenes now share assets/dungeon/mobile-kit/catalog.tres
  and atlas-256.png: 23 prepared sprites in one 1024x2048 atlas (8 MiB RGBA).
- Keep 256 source px/cell, fixed .75 zoom, free finger/mouse panning, no user
  zoom, logical 1x1 grid, three calm floor rows, two wall facade courses and
  separate pillars. Existing layouts and wide SixRoomPreview corridors preserved.
- Common bare stone replaces the complete A/B/C/D2 variation families. The
  recessed pillar top is an optional separate patch, still a visual proposal.
  Do not reintroduce the rejected historical A/B/C medallions into the active kit.
- export_mobile_kit.cjs shares primitives/materials/packing with the prototype
  helper. mobile_special_parts.cjs adapts the four doors and stairs to walls
  centered on grid edges (inner side at T/2). Door arch radii increase by T/2,
  thickness T stays fixed. Reproject geometry, never rotate a raster sprite.
  Four complete stairs are composed offline; each door has separate arch/leaf.
- mobile_dungeon_renderer.gd only places prepared AtlasTextures. Physical support
  bounds order walls/pillars/stairs/leaf/arch; optional cap follows its pillar.
  Do not generate image pixels, materials or perspective at runtime. Preserve
  periodic complete floor stones before clipping, original wall/pillar contacts.
- The common renderer refreshes catalog regions and the external PNG together;
  watches imports after scanning completes; reconnects and checks timestamps on
  scene reentry. It narrowly removes old unowned generated Floor_/Walls_/Door_/
  Entrance_ children during renderer migration, preserving authored scene nodes.
- Reproduce: node tools/export_mobile_kit.cjs, Godot import,
  tools/capture_mobile_kit.gd, node tools/prepare_mobile_kit_review.cjs.
  Old direct prepare_mobile_reference.cjs invocation is historical only.
- Android Mobile preset explicitly selects 40 active dependencies. Use
  prepare_mobile_export.cjs to stage only them in a fresh ignored directory before
  export. Existing editor filesystem caches can retain retired dependencies even
  after import. Never reset/restart the user's editor or delete its cache.
  Material libraries and authoring sources are retained but not shipped. Retired
  large PNGs were subsequently deleted; see the cleanup section above. Heart/torch
  props remain separate and outside this architecture export.
- Evidence: docs/reference/mobile-kit/README.md, recipe.json, package-report.json,
  scene-inventory.json and captures. 60 captures / 21 scenes, import and resource
  export exit 0 with empty stderr. MobileReference editor/runtime images match.
  Custom editor capture has native screen/progress/shutdown warnings; don't call
  its stderr clean. No automated tests or Android device profiling performed.
  Independent review's migration cleanup and watcher findings are resolved.
- This source migration does not validate every future arbitrary layout or imply
  final artistic approval of the optional cap. Do not claim old catalogue summed
  RGBA was old live VRAM; contexts were loaded lazily. Do not count the resource
  ZIP as a complete APK. No commit/push until the user asks.


## Mobile editor atlas refresh — 2026-10-24

- User reported a broken MobileReference editor preview after atlas repacking.
  The script read catalog.json only at _ready and used cached AtlasTexture .tres
  and their external PNG dependencies. A persistent editor could mix generations
  while fresh runtime captures were correct. Do not repair geometry for this.
- scripts/mobile_reference.gd now refreshes catalog + used .tres + each external
  atlas PNG together. Editor loads use CACHE_MODE_REPLACE, once per resource
  path per refresh; runtime uses normal caches. Parameter-only rebuilds reuse
  loaded resources, and a newly selected density gets fresh editor resources.
- Computed Callable button "Actualiser le rendu" on the root MobileReference
  node. It also attaches the editor watcher for old hot-reloaded instances.
  EditorFileSystem reimport/reload events queue a refresh; filesystem changes
  check the catalog/image timestamps. Wait until scanning/importing finishes.
  Preserve current inspector options, scene edits and camera view. Never restart
  the user's editor to flush these caches. No runtime pixel generation.
- Capture utility accepts --editor and waits for editor import before producing
  editor-preview/ PNGs. The default 256 editor/game captures match exactly.
  The custom editor capture process emits native editor shutdown/progress-dialog
  warnings; record those, do not describe its stderr as empty. Runtime/import
  captures exit 0 with empty stderr. No automated tests were added or run.
- Details, original screenshot and scope: mobile-optimization/editor-preview/.

## Integrated pillar top proposal — 2026-10-24

- User rejected the detailed A/B/C ornaments at gameplay distance: tiny detail
  disappears and the relief looks pasted on. Their "ok" approves prototyping a
  simple large recessed diamond painted WITH its stone top background. This
  supersedes the proposal direction below, not the common bare-base architecture.
- Latest review: docs/reference/pillar-cap-review/. ImageGen original, exact
  prompt and previous state are frozen in source/ and generation.json. No tiny
  chipping, multiple rings or floating medallion silhouette. Judge at the actual
  ~46px-wide top first, not enlarged source art. Appearance awaits user review.
- tools/mobile_pillar_cap.cjs maps the generated opaque top into the existing
  top geometry using the approved offline material/mask workflow. Retain the
  original 3px rim and blend over the next 3px of quiet stone. No guide movement.
  Final density exports suppress cap pixels outside the opaque top interior;
  the bare pillar below retains its original bevel and silhouette alpha.
- pillar-top-carved is a prepared 68x68 top patch at density 256 (34x34 at 128),
  same ground anchor as pillar: (-50,-114). Godot overlays the whole prepared
  stone top at the support's depth. Do NOT add the old height translation again.
  This visually replaces the upper surface, reusing the common full bare pillar.
- MobileReference defaults to "Dessus creusé"; old A/B/C remain explicitly
  historical comparison choices, and old wall ornaments are disabled by default.
  Current prototype has 10 geometry + 4 detail images including those three old
  comparisons. Offline rectangle packing keeps atlases at 512x256 / 1024x512.
- Export audits at both densities: zero composed-alpha differences and zero RGB
  changes outside the top interior against the same transparent-overlay pipeline.
  Nine Godot captures/import exit 0, empty stderr. Review normal game scale and
  enlarged actual game pixels. No automated tests or phone-performance claim.
- Reproduce mobile export/import/captures, then tools/prepare_pillar_cap_review.cjs.
  The older A/B/C review uses frozen captures in its source/captures directory.

## Historical separate painted decoration proposals — 2026-10-24

- User confirms bare walls, floors and pillars with separate decoration sprites.
  The old thin procedural diamonds are rejected as appearance references. Keep
  the bare geometry and common paint; enrich the separate artwork instead.
- Three native-alpha ImageGen proposals in docs/reference/mobile-decoration-review/:
  A sculpted slate diamond, B ancient octagonal seal, C localized violet socket.
  Their application was rejected for small-scale readability and pasted-on look.
  A was the old default preview only, not an approval record.
  Original images and exact prompts are frozen in source/ and generation.json.
- tools/mobile_painted_decorations.cjs preserves the complete native-alpha source,
  uniformly resizes/pads it into a common centred 68x68 frame at density 256.
  Alpha >8 bounds measure centre/scale only; never threshold or remove alpha.
  The main subject is 44px tall, about 33 displayed px at the proposed game scale.
- Prototype IDs decor-a/b/c replace ornament-h/v/pillar. Pillar choice is exposed
  through historical detail_style choices in F6. Old wall examples use C at .72
  uniform scale. Their common horizontal top plane needs translation by the
  projected support height only; no runtime painting/perspective deformation.
- Retain support-depth drawing order: each decoration immediately follows its
  own wall/pillar so foreground geometry can hide it. Both decoration toggles
  off show the bare bases. No production-catalogue migration is implied.
- Reproduce atlas/captures with the mobile reference commands, then run
  tools/prepare_mobile_decoration_review.cjs. Comparison includes enlarged source
  art and unscaled Godot crops. Eight captures exported; stderr empty; reviewed
  A/B/C at game scale. No automated tests or mobile profiling performed.

## Mobile optimization direction — 2026-10-24

- User now targets mobile with a fixed viewing scale comparable to the original
  mockup. No user zoom; FREE camera panning by finger is explicitly selected.
  Do not fit the entire dungeon into the screen as the future gameplay framing.
- Simplify surfaces for that reading distance and reduce sprite resolution.
  Exact reference scale and pixel dimensions are still to be established visually.
- User proposes one common stone appearance plus separate prepared transparent
  decoration sprites (cracks/corruption), instead of complete painted style sets.
  This supersedes the prior single-complete-image restriction for decorative
  overlays. No runtime texture generation or perspective deformation.
- Distinct pillars like the mockup should terminate/join walls at corners.
  Use real geometric contacts/occlusion; remove the need for continuous painted
  stones turning around corners. Preserve the fixed projection and 1x1 grid.
- Latest correction: floor slabs are now too large relative to wall bricks.
  Match the mockup's proportions. The old approved C slab size is superseded as
  a constraint for the next proposal; retain calm floor surfaces and rounded corners.
- Decisions and exact user references: docs/reference/mobile-optimization/.
  This is the new design direction, NOT an implemented migration. Current
  A/B/C/D2 assets remain active from 6a6fcaa7. First establish a small reference
  scene and viewing scale before regenerating the production catalogue.
- No tests added/run without a user request.

## Mobile reference spike — 2026-10-24

- User accepted preparing the small reference scene ("ok"), not a production
  catalogue migration. New scene: scenes/MobileReference.tscn, separate script
  and assets/dungeon/mobile-reference/. Existing scene contents are not migrated.
  The local main_scene setting currently points at this prototype; preserve it.
- Proposed values: 192 displayed px/cell at 1280x720, zoom .75, free finger/mouse
  panning. 3x2 room plus east/south branches. Three floor rows, .32..35-cell slabs,
  quiet rounded finish; .24-cell pillars against 1/6-cell walls. Not yet approved.
- Offline exporter tools/prepare_mobile_reference.cjs reuses approved paint with
  local reduced contrast. Current fourteen logical sprites: floor, eight wall
  terminations, bare pillar, carved top, three historical decorations.
  One wall appearance; no runtime painting. pillar_details / Décors piliers
  toggles the separate pillar detail independently of walls. Do not rebake it.
- Two comparison atlases: 128 px/cell (512x256) and 256 px/cell (1024x512).
  Default 256 appears clearer; source resolution is still an appearance decision.
- Pillars must NOT have a global layer above walls. This caused the reported
  NW overlap. Walls/pillars now share a layer, sorted by ground-support depth
  along (.18,.9); each ornament follows its own wall. Freeze the before capture
  in mobile-optimization/join-review/. Recheck occlusion for future geometry.
- Physical wall ends meet pillars. New geometry is a proposal, not validated by
  old guides. Preserve integer grid, common projection, two facade courses.
- Reproduction, isolated magenta guides, scope and captures in
  docs/reference/mobile-optimization/. No automated tests or mobile profiling.
  Do not generalize this spike to all production variants without user review.

## Wall variants with D2: integration authorized — 2026-10-23

- User said "Go" after selecting D2. Integrate complementary A/B/C walls and
  selected D2 in Godot. This supersedes proposal-only gates for these materials.
- Active recipe: `shared-materials/active-recipe.json`, wallVariation section.
  Source `wall-variation-atlas-v1.png` is copied unchanged from the reviewed
  atlas. Exact crop hashes are checked by prepare_shared_stone_materials.cjs.
  The smooth rounded floor, wood, iron, B finish and geometry are preserved.
- `tools/wall_material_variation.cjs` paints whole local faces. Any stone
  touching a longitudinal cell boundary, leaving the centre cell, or belonging
  to a pillar keeps common quiet paint. Interior stones vary. D2 has one UV
  rectangle unfolded across top/upper facade, with per-face lighting preserved.
- `tools/export_connected_stone_contexts.cjs` exports complete A/B/C/D2 PNGs
  and deduplicates identical results. catalog.contextStyles maps a geometric
  context to four paths. Keep context/material/UV signatures and lazy loading.
  A material promotion needs a FULL export, not --specials-only.
- `painted_wall_selection.gd` deterministically chooses a prepared style per
  integer cell: base buckets A8/B4/C3/D2-1 out of 16. Only the lowest-hash
  neighbouring D2 candidate survives (eight neighbours, coordinate tie-break).
  It selects files only; never generate or recolor images in Godot.
- Re-export both kits and import Godot after material changes. The isolated
  references use D2 on eligible stones; assembled scenes use all four styles.
  Preserve layouts, wide SixRoomPreview corridors and all special orientations.
- Completed: 2,900 unique structural PNGs / 1,444 four-style contexts (161 empty),
  plus 57 isolated images / 146 aliases. Export audits report zero alpha or
  unpainted-interior differences; joints match. Shared floor hash unchanged.
  Godot import and 53 captures of all 20 scenes exit 0 with empty stderr.
  Boards and selected enlarged joins reviewed; future arbitrary joins unproven.
  641 unreferenced previous PNGs and their .import files are archived locally
  under artifacts/wall-variants-retired/; inventory is in the integration review.
- Current execution/evidence: docs/superpowers/plans/2026-10-23-wall-variants-d2.md,
  docs/reference/WALL_VARIATIONS.md and wall-variants-integration/. Reproduce
  boards with tools/prepare_wall_variants_integration_review.cjs after captures.
  No automated tests without user request.

## Corrupted wall D2 selected — 2026-10-23

- User selected "D2" from `wall-corruption-review-v2/comparison.png`.
  Retain D2 as the corrupted wall appearance; old D is rejected and D1 is an
  unselected comparison. This supersedes the pending D2 appearance status below.
- Exact material: `corruption-v2-1`, crop left 1070, top 390, width 170,
  height 220 from the existing `atlas-calm.png`. Preserve the continuous
  unfolded mapping across top and upper facade, not a repeated face-local motif.
- `docs/reference/wall-corruption-review-v2/selection.json` records the user's
  choice and selected PNG hashes. The corner in the original comparison shows
  D1 and is historical; do not use it as the selected D2 appearance reference.
- D2 appearance is approved. Full context-family propagation and Godot asset
  integration have not been performed by this selection record.

## Corrupted wall D rejected; continuous mapping proposal — 2026-10-23

- User rejected D because its motif repeats identically. Root cause: same
  material ID but face-local UV origin/scale, duplicating the violet centre
  on the top and upper facade. Sharing a material ID alone is insufficient.
- `tools/prepare_wall_corruption_review.cjs` produces a separate review under
  `docs/reference/wall-corruption-review-v2/`. D1 unwraps the existing patch
  continuously around one stone; D2 uses a different vein from the same atlas.
  A twelve-cell assembly shows D1/D2 sparsely among A/B/C. No new generation.
- One unfolded material rectangle maps top and upper facade, with identical
  UV along their common physical edge. Keep per-face lighting and fixed joints.
  The renderer's optional `face.textureTransform` is used only by this review;
  normal production export mapping remains unchanged unless opted in later.
- Four straight sprites, NW corner and magenta overlays are pending approval.
  No Godot catalog or asset replacement. Connection stones retain quiet common
  paint. Source before-images/recipe are frozen; previous D is rejected history.
  Do not interpret this correction as approval of the complete wall family.

## Wall variation appearance review — 2026-10-23

- User now asks to reduce wall repetition and create variants. Proposal:
  `docs/reference/wall-variation-review/`, reproduced by
  `tools/prepare_wall_variants_review.cjs`. Four complementary variants:
  A calm, B weathered, C chipped, D localized violet corruption.
- Eight prepared straight-wall PNGs (four horizontal, four vertical), mixed
  assemblies and a NW corner with magenta overlay. This is an appearance
  review awaiting approval, not an active Godot material/catalog replacement.
- Existing generated `proposals/variation-review/atlas-calm.png` supplies the
  shared paint. Three exact crops under the review's `materials/` keep quiet
  boundary stones and make chip/violet details visible on narrow wall faces.
  Crop recipes, hashes and tool inputs are recorded in `recipe.json`.
- Paint complete stones through the existing local context exporter. Stones
  touching a longitudinal cell boundary, including endpoints/filter guards,
  retain common quiet paint across all variants. Only interior stones vary.
  Top and upper facade share a material; no rotation, joint or alpha changes.
- The procedural violet Y stroke is disabled in this proposal. Preserve the
  active smooth rounded floor, wall finish B, projection and existing layouts.
  Frozen baselines and material catalogs under `source/` must not be replaced
  after promotion. No arbitrary corner/door/stair variant compatibility claim.
- Export audits report matching construction alpha and guide layers for the
  eight straight sprites and NW proposal. Horizontal, vertical, NW overlay and
  enlarged B/A join reviewed visually; no automated tests or Godot changes.

## Approved smooth rounded floor integration — 2026-10-23

- User answered "Oui" to integrating the smooth floor with rounded slab corners
  in Godot. This supersedes the proposal-only floor gates below; the proposed
  varied wall family remains a separate review.
- Active recipe: shared-materials/active-recipe.json. Exact accepted atlas copied
  unchanged to shared-materials/floor-smooth-atlas-v1.png. Four existing floor IDs
  select samples 6/2/4/3 from the eight-source atlas. They cover four complete
  periodic C stones; both boundary fragments share one ID. Legacy names such as
  floors-fine-crack are compatibility IDs, not descriptions of the new surface.
- floor.opacity=.55. Active recipe floorFinish has radius 10.5 and floorFactor
  .63; it applies only to ground slabs. Walls and stair tread rounding retain B.
  Stairs use the smooth palette through the existing shared floor material IDs.
  Dimensions, construction guides, alpha, anchors and layouts remain fixed.
- Production exporters explicitly pass floorFinish and floorPattern to models.
  Historical material reviews keep their explicit old recipes/default B finish.
  Reproduce with prepare_shared_stone_materials.cjs, export_painted_image_catalog.cjs
  and export_painted_connected_kit.cjs --specials-only (also refreshes shared floor),
  then Godot import. Special contexts need re-export because they contain stairs.
- Partial context exports preserve ordinary structures' sourceHashes and record
  updated specialSourceHashes; floor.sourceHashes remains separate. Godot still
  places prepared PNGs. No new runtime variation system or wall promotion here.

- Completed: 57 isolated images / 146 aliases; connected 737 images / 1444
  contexts. Godot import and five scene captures exit 0, stderr empty. Normal
  views inspected; no automated tests. Logs: artifacts/smooth-rounded-*.log.
  Isolated review sheets now use the same atomic writer as sprites to avoid
  truncating a Windows-locked PNG. Source review found no Important/Critical
  issues in the floor propagation. Existing editor refresh still requires the
  inspector button or F6 after import.

## Smooth rounded floor review history — 2026-10-23

- User accepted the smoother floor direction and requested rounded slab corners
  like the mockup. Keep its eight smooth samples and low contrast (.55 opacity).
- `tools/prepare_rounded_smooth_floor_c_review.cjs` prepares a floor-only finish
  proposal: radius 10.5 reference pixels, multiplied by the existing .63 floor
  factor (about 6.6 px at 256 px/cell). Inset, bevel width, material IDs and seeds
  stay fixed. Walls retain B; the active stone-finish.json is not changed.
- Outputs in material-variation-review/: `rounded-smooth-floor-detail.png`,
  `rounded-smooth-floor-comparison.png`, `rounded-smooth-c-comparison.png` with
  magenta overlay, and `rounded-smooth-floor-recipe.json`. The previous smooth
  images are frozen in source/*-before-rounding.png.
- The shared compositor accepts an optional model.floorFinish, recorded in the
  report. Production exports without this option retain their existing finish.
  Whole floor stones are rounded before framing; connection cuts must not gain
  a corner or bevel. Review images are not runtime assets. Corner rounding still
  awaits visual approval before propagation; no Godot scene change at this stage.

## Smoother floor material proposal — 2026-10-23

- User wants smoother, quieter floor surfaces like the original mockup so future
  objects remain distinguishable. Keep large slab C geometry and finish B.
- `tools/prepare_smooth_floor_c_review.cjs` revises only the proposed floor
  materials, keeping the proposed walls from `appearance-c-recipe.json`.
  Source: `shared-materials/proposals/variation-review/floor-smooth-v1.png`, eight
  generated smooth slate samples without large chips, holes or cracks. Floor
  texture opacity .55 softens contrast; all other floor profile values stay fixed.
- Review: `material-variation-review/smooth-floor-comparison.png` and
  `smooth-c-comparison.png` (NW corner with magenta overlay). Exact prompt,
  references and original path: `smooth-floor-generation.json`; complete material
  recipe: `smooth-floor-recipe.json`. Previous proposal PNGs are frozen in source/.
- This supersedes the scarred floor samples in the pending material proposal,
  not the active production family. No Godot propagation before appearance review.
  The corner retains 38 guide segments and matching construction alpha with no
  interior holes. This is not a gameplay legibility test or arbitrary join proof.

## Approved large floor C; material variety pending — 2026-10-23

- User dislikes the small violet branching stroke, repeated wall motifs and
  repetitive floor. Latest steering identifies floor slabs as too small versus
  the original mockup. User approved option C: "oui le C".
- Proposal: `docs/reference/material-variation-review/floor-size-comparison.png`
  compares 6 / 3 / 2 decorative rows per logical cell over the same 3x3 area.
  All three use the same proposed materials and finish B. The logical grid stays
  1x1. C is now active in `floor-periodic-cell.json`: row heights [2.5,2.5]
  and widths [[1.15,3.05,1.8],[2.3,3.15,.55]] in the normalized 6x5 frame.
  Two rows, six fragments, four complete periodic stones; full widths .475..525
  cells. The connected floor has six source segments and keeps its opaque frame.
- `tools/prepare_material_variation_review.cjs` reproduces the appearance study;
  `--floor-sizes-only` renders the size comparison alone. Whole stones crossing
  cell borders are painted before framing. The previews are not production room
  sprites or proof of arbitrary prepared tile compatibility. Frozen pre-C floor
  source/PNG live under the review's source/ directory for reproduction.
- Proposed source `shared-materials/proposals/variation-review/atlas-calm.png`
  has 8 wall and 8 floor samples. Earlier atlas.png is an overly rough intermediate.
  Generation provenance and prompts are beside the review. This new material
  family is not promoted by the C slab-size decision. Active materials remain
  the approved stylized family; all scenes receive the prepared large floor.
  Isolated PNGs and transparent guides are re-exported with C too. Connected
  structures contain no ground and stay unchanged; --floor-only preserves them.
  Floor input hashes are stored under catalog.floor.sourceHashes, leaving the
  retained structures' original provenance intact. The optional `drawAccent:false`
  renderer flag suppresses the purple doodle in proposals only.

- Latest material proposal after C: `corner-c-comparison.png` in the same review
  directory shows the NW corner before/after and its magenta overlay (38 source
  segments). `appearance-c-comparison.png` compares a six-cell wall and a 3x3 C
  floor field with 8 proposed wall / 8 floor materials. Floors favor calm samples;
  violet lives in rare painted crevices, with no added branch stroke.
  Reproduce with `node tools/prepare_material_variety_c_review.cjs`.
  The corner is a deliberately composed palette sample; field assignment uses
  whole stone identities. Both are appearance proposals, NOT a prepared runtime
  variant catalogue. Active textures remain unchanged pending this visual review.
  `appearance-c-recipe.json` stores inputs, profiles and export reports. The NW
  report records zero missing interior pixels and matching construction alpha;
  this does not prove arbitrary future tile joins. Baseline PNGs are frozen in
  the review's source/ directory so future regeneration retains the comparison.

## Approved wall join correction — 2026-10-23

- User found texture seams inside stones spanning cells after B. Root cause:
  fragment-local material IDs, UV framing and finish gradients. Floor wrapping
  did not cover walls; unchanged alpha alone did not prove texture continuity.
- User approved the enlarged horizontal/vertical comparison and requested
  generalization to the kit and Godot. Preserve the approved material crops,
  B finish, projection, wall geometry and scene layouts.
  `tools/prepare_wall_join_review.cjs` produces `docs/reference/wall-join-review/`;
  `tools/capture_wall_join_review.gd` captures its separate PNGs in Godot at 1x/2x.
- The proposal paints whole stones in a shared geometric context, then exports
  cell sprites. A single union mask and identical interior edge pixels prevent
  alpha/filter seams. See the review README for alpha changes and exact scope.
- Production export now uses reusable local contexts and stable stone identities
  in `tools/connected_stone_context.cjs`. The connected export selects complete
  face regions across the neighbour guides before painting/cutting cell PNGs.
  Material, UV, finish seed and accents must not depend on a fragment's bounds
  or the order of faces. Never bake a scene-sized production image.
- The baseline PNGs of the accepted comparison are frozen under
  `docs/reference/wall-join-review/source/` from ab9ebe7. Do not replace them
  with the promoted assets when reproducing the before/after comparison.
- Godot selects a prepared local-context PNG, with existing anchors and scale.
  Context paths load on demand; do not preload the entire context family into
  VRAM. Keep the floor image shared. Local special-neighbour configurations are
  inventoried by `tools/export_painted_scene_contexts.gd` before PNG export.
- Combined special contexts must also hide source lines behind neighbouring
  volumes before finding stone faces. ReferenceCalibration exposed stair lines
  painting across an arch; compare source depth against the combined model.
  Preserve the generic fallback warning for new, unexported special contexts.

## Approved soft stone B — 2026-10-23

- User approved B: "ok pour B". Apply its modest rounding to existing isolated
  and connected stone sprites with the accepted offline material-mask workflow.
- Durable recipe: `assets/dungeon/shared-materials/stone-finish.json`.
  Radius 3.8, inset .55, unevenness .12, bevel 2.2 reference pixels; floor factor
  .63 and proportional reduction for narrow faces. Do not replace this with C.
- `tools/stone_edge_finish.cjs` is shared by the production compositor. Retain
  source material crops, projection, silhouette alpha, grid and scene layouts.
  Wood/metal retain their finish. Godot places complete prepared PNGs as before.
- Periodic floor boundary fragments share one complete stone, texture mapping
  and finish seed. Uninked connection cuts receive no new inset, rounded corner
  or end bevel. Internal stone joint appearance changes intentionally; the
  construction overlay is a geometry reference, not every visible mortar pixel.
- `docs/reference/stone-edge-review/` preserves the A/B/C decision. Its generator
  now reads frozen A/report/guide/material metadata, never the promoted active B
  as a new baseline. Keep the accepted B image for comparison.
- After changing the finish, re-export BOTH kits and import in Godot. Existing
  scene references pick up the resulting PNGs. Record visual review limits in
  `docs/reference/PAINTED_GODOT.md`; approval of B does not prove arbitrary joins.

## Legacy asset cleanup — 2026-10-23

- User requested removal of failed architecture trials predating the wireframes.
  `alpha-kit`, old `entrances`, `modular-study`, `reference-study`,
  `single-cell-study`, loose original crop PNGs and three rejected gloom corners
  are retired. Their exclusive renderers, capture scripts and obsolete checks
  have been removed from the active tree too. Do not restore them from the
  historical instructions below.
- Active assets: `painted-connected`, `painted-cells`, `shared-materials` and
  the three `wireframe-*` directories. Keep accepted geometry sources and mask
  metadata, including `docs/reference/nw-material-review-v2/validation.json`.
- The unchanged native-alpha heart is now `assets/dungeon/heart/heart.png`;
  `alpha_heart.gd` loads it directly with the same region, scale and anchor.
  Keep the separate heart/torch scenes and original user mockups.
- Current commands: `README.md`, `assets/dungeon/README.md`, `PAINTED_GODOT.md`.
  `tools/test-mobile.ps1` and its pre-wireframe checks are retired; they are not
  valid checks for the current kit. Do not run/add tests without a user request.
- `docs/cleanup/2026-10-23-pre-wireframe.json` inventories the removed paths,
  hashes and recovery commit. Files are also retained in the ignored local
  `artifacts/pre-wireframe-archive-2026-10-23/`, excluded from Godot by .gdignore.
  The preexisting modified alpha-kit provenance is preserved byte-for-byte in
  `docs/cleanup/alpha-kit-generation-before-cleanup.json`. Older prose referring
  to retired paths is historical, not an active dependency.

## Approved active stylized family — 2026-10-23

- User approved the latest stylized preview: "oui utilise cette nouvelle gamme
  de texture". Apply its exact materials to all existing painted assets and Godot
  scenes. This supersedes the earlier proposal-only gates below.
- Active material recipe: `assets/dungeon/shared-materials/active-recipe.json`.
  Source: `stylized-atlas-v2.png`; exact reference: `stylized-reference.png`.
  `tools/prepare_shared_stone_materials.cjs` now reproduces these approved crops
  and profiles by default, checking their hashes. It must not restore old textures.
- Keep existing material IDs. Four wall variants use plain/corrupted painted
  stone; four floor variants use calm painted stone; wood is simplified. Iron is
  retained from the approved preview. Older realistic sources are historical only.
- Re-export isolated and connected kits after preparation. Preserve geometry,
  alpha, joints, floor periodicity, anchors, scale and scene layouts. Godot still
  places whole prepared PNGs; no generation or color correction at runtime.
- Editor preview refresh: `wireframe_cell_study.gd` keeps its computed Callable
  button and reloads used imported textures with `CACHE_MODE_REPLACE`, once per
  unique path, on manual refresh / scene entry. Parameter-only rebuilds and runtime
  retain normal preloads. After external PNG exports, finish import before clicking
  "Actualiser le rendu"; a second Godot import process cannot refresh the memory of
  the user's already-open editor. Do not restart that editor or discard its edits.

## Current style correction — 2026-10-23

- User finds the A/B/C corruption materials too realistic compared with the
  original mockup. Do not use their grain, pits or bark as style references.
  Prefer broad painted facets, a few deliberate scars, simplified wood grain
  and localized violet accents. Keep the approved masks, joints and projection.
- `docs/reference/stylized-material-review/` contains a new NW corner and north
  door proposal, overlays, comparison, recipe, prompt and the exact user reference.
  Its generated atlas is `assets/dungeon/shared-materials/proposals/stylized/atlas.png`.
  Reproduce with `node tools/prepare_stylized_material_review.cjs`.
  This preview is now approved and promoted to the active family described above.

## Pending corrupted material directions — 2026-10-23

- User finds ALL current materials too smooth/clean and asks for multiple evil,
  corrupted dungeon texture proposals. This broadens the earlier door-only review.
- Three generated material atlases: damp eroded crypt, cursed violet fissures,
  and embedded black roots. Sources: `assets/dungeon/shared-materials/proposals/corruption/`.
  Exact prompts and original outputs: `docs/reference/corruption-material-review/generation.json`.
- `tools/prepare_corruption_material_review.cjs --variant=01-humide` (or
  `02-fissures`, `03-racines`) exports one direction in a separate process.
  Run without arguments to rebuild `comparison.png` with current art + A/B/C.
  Each uses the same NW cell and north door geometry; masks/joints stay fixed.
  Different rectangular crops supply variation without mirroring or rotating art.
- These are unapproved appearance proposals only, with magenta overlays and
  recipes. Active Godot assets/material catalogs remain unchanged. A production
  library would need further variation and deliberate sparse corruption placement;
  these samples do not validate connected roots or glowing veins across modules.

## Pending door material review — 2026-10-23

- User reports that door textures do not integrate with the dungeon. The current
  oak is very orange with high-contrast grain. A muted aged grey-brown oak proposal
  is saved in `assets/dungeon/shared-materials/proposals/door-oak-v2.png`.
- `tools/prepare_door_material_review.cjs` applies it to all four existing door
  masks and produces `docs/reference/door-material-review-v2/comparison.png`,
  individual PNGs, magenta overlays and a reproducible recipe. Geometry, stone,
  floor and iron materials stay unchanged. This is an appearance proposal awaiting
  user review; active Godot assets and catalogs have NOT been replaced.

## Previous floor rhythm correction — superseded by C above

- User reports columns of long slabs caused by the wireframe subdivision.
  Paving source `docs/reference/floor-periodic-cell.json` previously superseded
  the historic 19-fragment motif. That intermediate version had six row heights,
  26 fragments / 20 full periodic stones, full widths .24..40 cells, staggered cuts.
  Count the left+right fragments as ONE stone when assessing width; the old
  pattern joined them into stones up to .78 cells and repeated a long-stone band.
- Preserve 1x1 grid, projection, wall geometry, opaque connected floor frame and
  continuous material at X boundaries. Re-export source wireframes, overlays,
  isolated painted images and connected PNGs together after a floor joint change.

## Current request: painted Godot scenes — 2026-10-23

- User now explicitly requests updating all Godot scenes with the new assets.
  This supersedes the previous image-only/no-integration gate below.
- Export connected structural images OFFLINE from the existing connected
  wireframes and shared material library. Keep the isolated review images.
  Godot places prepared floor/structure PNGs at uniform .25 scale on the same
  256-pixel square grid; no runtime image generation or appearance repair.
- Preserve the current room layouts, branch lengths, two-cell-wide corridors
  in SixRoomPreview, four door orientations and entrance stairs.
- Update older architecture demonstration scenes too. The standalone torch and
  heart props have no replacements in this architecture catalogue.

- Integration is now implemented in `scripts/painted_cell_catalog.gd` and the
  shared `wireframe_cell_study.gd`. All 20 architecture scenes use painted PNGs.
  `tools/export_painted_connected_kit.cjs` exports 96 unique structural PNGs,
  128 structural IDs, 16 empty states and one connected floor (26 revised joints).
  The three standalone floor closing contours must not become cell-grid borders.
- Connected floor boundary fragments must share ONE full stone across X=0/1,
  with the same material, UV coordinates and bevel seed. `wrapFloorX` in the
  offline compositor expands those fragments before clipping to the fixed cell.
  Removing only the outline leaves vertical bevel/texture seams (user-reported).
  Never shade an artificial cell boundary as a physical stone edge.
- Connected floor export is now an opaque 1024x1024 exact-cell frame, anchor
  (0,0), still displayed at .25 scale. Transparent floor gutters caused a second
  dark filtering seam even with continuous RGB. Repeat the next row's north
  joint into the bottom edge offline, retaining full joint width. Structural
  and isolated-review frames remain unchanged. See outputFrame/repeatInkY.
- See `docs/reference/PAINTED_GODOT.md` for scene inventory, export/import and
  capture commands. Connected doors/stairs omit the ground layer; every grid cell
  receives the same prepared floor before its structure. Isolated review sprites
  remain complete and are used only by EntranceVariants and the review boards.

## Previous request: remaining painted images — 2026-10-23

- User: "Ok tu peux faire les autres images ?" authorizes propagating the
  shared-material approach to the existing isolated wireframe image catalogue.
  This supersedes the NW-only propagation gate below. Prepare ordinary cells,
  floor, isolated pillar, four entrances and four double-sided doors for review.
- Reuse the approved slate material library and fixed projection. Add shared
  wood/metal materials for door leaves/hardware, based on the canonical mockup.
  Keep all source guide lines, framing, end faces and hidden-line visibility.
- Deliver PNGs, catalog/provenance and overview/overlay images. This request is
  for images; it does not request replacing the Godot scenes or their connected
  textures. Standalone end-face guides are not connected-runtime assets.
- Exporter: `tools/export_painted_image_catalog.cjs`, shared compositor:
  `tools/painted_material_renderer.cjs`. Output: `assets/dungeon/painted-cells/`,
  57 unique PNGs covering 146 isolated guide identifiers through catalog aliases.
  Includes 47 cell configurations, floor, pillar, four stairs and four doors.
  Review boards, magenta overlays and measurements: `docs/reference/painted-kit-review/`.
- Source lines and widths are copied unchanged. Independently projected volume
  alpha is checked against the exported PNG. Open uninked floor edges close
  MATERIAL masks only. Doors additionally use source-volume visibility masks
  so adjacent stone and wood never inherit each other's material across a
  missing inked intersection. Wood grain is projected from local leaf coordinates.
- Common wood/iron sources join the eight existing stone materials. Keep all
  material settings in `shared-materials/catalog.json` via its preparation script.
  Final artistic approval and connected-scene conversion remain separate work.

## Approved method: shared generated materials on fixed geometry — 2026-10-23

- The user approved retaining the masked-material method after the first test:
  "c'est une bonne méthode donc on peut l'autoriser". They explicitly want it
  preserved so all elements reuse the SAME textures. The one-time restriction
  in the historical section below is superseded for this method.
- Architecture may now be composed OFFLINE from shared AI-generated material
  swatches, clipped to approved wireframe faces. Geometry defines silhouettes,
  joints, anchors and projection. The output is a prepared PNG; Godot places it.
  This supersedes the older native-alpha/no-masks rules for this workflow only.
  Do not use generative painting to reposition joints or freely repair geometry.
- The first masked image is visually too simple. Current work enriches the
  shared material library with several coherent variants, following the canonical
  mockup: darker slate, painterly facets, sparse wear and violet accents. Floors
  must remain calmer than walls. Avoid unrelated color palettes per orientation.
- Validate the richer materials on the SAME NW corner before propagating the
  painted kit or updating scenes. Approval of the method is not approval of the
  current appearance or permission to skip overlay checks.
- Read `docs/reference/MATERIAL_WORKFLOW.md`. The pending library contains four
  wall and four floor materials in `assets/dungeon/shared-materials/`, with a
  shared renderProfile in catalog.json. `--materials-v2` on the NW prototype
  uses it and exports `nw-shared-materials-v2.png`; comparison and per-face
  material IDs are in `docs/reference/nw-material-review-v2/`. Never regenerate
  or tune materials independently per orientation. The general isolated exporter
  is now described above; no painted runtime integration exists yet.

## Historical one-time masked-material experiment — 2026-10-23

- The user explicitly authorized testing vector masks **for this time only**,
  on the single painted NW corner under review. This is a narrow exception to
  the native-alpha/no-programmatic-repair rules, not a general policy change.
- Scope: generate joint-free stone material from the canonical mockup, compose
  it offline inside the exact approved faces, and draw joints from the unchanged
  wireframe. Export one transparent review sprite and its magenta comparison.
  Do not integrate it into Godot or extend the technique to other variants.
- Preserve all generated originals and geometry. Record the source material,
  masks, composition script and validation. No other painted sprite is approved.
- This experiment has now been produced: `nw-masked-experiment.png`, with
  sources/review in `docs/reference/nw-mask-test/` and the deliberately NW-only
  `tools/prototype_nw_masked_material.cjs`. Its 51 guide segments are copied
  unchanged; decoded alpha matches the construction raster exactly. The result
  is more regular than the mockup and awaits artistic review. The one-time
  authorization does NOT permit more variants or scene integration.

## One painted NW corner under review — 2026-10-23

- The user explicitly requested ONE painted NW corner from the wireframe, with
  transparent magenta overlay validation. See docs/reference/painted-corner-review/
  for the exact prompts, generation.json, measurements and comparison images.
  No Godot integration or generation of the rest of the painted kit is approved.
- nw-cell-wireframe-v1.png was rejected for a false extra TOP course: its top
  planes looked like separate coping slabs. The top and upper-front faces must
  belong to the SAME stone; only two equal facade courses, no under-cap strip,
  added lip or overhang. The user's criticism was NOT about the narrow floor
  band at the wall foot; the assistant initially misidentified it.
- v2/v3 reduce the detached-cap effect but remain UNAPPROVED. The first top-face
  joint along the west wall is still too low (about y350 instead of y322 at
  1166x1349). Do not claim exact fidelity from silhouette overlap: v3 is 99.32%
  IoU yet has this visible internal mismatch. Preserve the source geometry.
- v4 restarts from the exact construction drawing, with the canonical mockup
  as material-only input. It also FAILS review: the floor strip at the north
  wall foot becomes a dark projecting facade, its joints move, and facade
  shading reads as horizontal slabs. Exterior contours still differ. Do not
  use any of v1-v4 as approved geometry, material or runtime images.
- The user requires exact contours AND joints to prevent connection defects.
  Free image generation has not met that requirement. A deterministic offline
  material composition inside fixed vector faces now has a ONE-TIME test
  authorization in the section above. The general prohibition remains in force
  for every other asset and for any further use outside this experiment.
- Built-in image_gen supplied native-alpha images, copied unchanged into
  assets/dungeon/gloom-kit/proposals/nw-cell-wireframe-v{1,2,3,4}.png. Review PNGs
  are separate, never runtime assets. Use tools/review_nw_corner_image.cjs with
  the image, version tag and requested WIDTHxHEIGHT; uniform whole-canvas scale,
  fixed origin, no fitted translation, clipping or repair of painted pixels.

## Transparent wireframe control guides — 2026-10-23

- The user wants transparent guides with conspicuous colored lines to overlay
  future painted sprites and compare geometry. The initial export uses magenta
  #ff00ff (assistant choice), keeping projection, framing, anchors and widths.
- IMPORTANT correction: review each piece ALONE with all VISIBLE end contours.
  Do not omit port/end faces as in the connected kit; do not reveal hidden edges.
  The user supplied the standalone south door as the explicit visual reference.
- `tools/export_wireframe_overlays.cjs --png` prepares 146 SVG/RGBA PNG guides
  in `docs/reference/wireframe-overlays/`: 136 complete cell variants, one floor,
  four entrances, four doors and one isolated pillar. PNG export needs sharp.
  Read its README and WIREFRAME_WORKFLOW.md section 12 before using/regenerating.
- Preserve existing white construction sources. The common cell geometry has
  an offline standalone mode retaining end faces; its runtime export is unchanged.
  Doors use the isolated studies' visibleEdges exactly; stairs use complete
  source edges with world rotation and fixed-camera visibility. Floor strokes
  are trimmed against vector faces before omitting fills. No painted pixel cleanup.
- Individual PNGs have transparent backgrounds; comparison.png alone includes
  a checkerboard. Complete ordinary guides use wall framing (304x352, anchor
  24,88), while the standalone floor keeps 264x264, anchor 4,4. Doors keep their
  taller 304x392 frame, anchor 24,128. Never auto-crop or shift guides to hide errors.
- The isolated pillar is T x T x H (1/6, 1/6, 1.88/6), one joint at .94/6,
  no floor or vertical joints; 96x144 canvas, anchor 24,88, same 256 px/cell scale.
  The user does not need a separate painted "floor + two pillars" asset; that
  composition reuses floor + pillar. Remove it from the production review sheet,
  preserve the technical catalogue variant. 146 guides are not 146 art commissions.
- These are ISOLATED review guides, not a Godot overlay mode or replacement for
  connected textures. Existing scenes and runtime
  textures remain unchanged by this export; no painted generation is authorized
  by a transparent-guide request alone.

## Six-room wireframe scene — 2026-10-23

- Latest user request migrates `scenes/SixRoomPreview.tscn` to the existing
  wireframe catalogue, replaces the entry door with stairs, and removes torches
  and the heart for visual review. The legacy probe overlay is also detached.
- Explicit width correction: KEEP THE ORIGINAL TWO-CELL-WIDE CORRIDORS.
  The user wants to inspect these joins and considers this a valid option for
  the future player-built dungeon. A cell remains square 1x1; corridor width
  may span several cells. Earlier one-cell studies remain valid examples,
  not a universal width restriction. No player construction editor exists yet.
- `assets/layouts/six_rooms_wireframe.tres` preserves all 255 occupied cells
  of `six_rooms.tres`, their locations and values, and adds only (3,2), just
  north of the old entry, for one south-opening stair. Grid 28x18, total 256.
  The original layout remains historical. The shared wireframe renderer uses
  pitch 256 and its normal occupancy/diagonal selection, without custom joins.
- `entrance_at_closed_ends=true` selects exactly one existing complete stair
  image (w11_p00_e00). No newly generated art or runtime geometry is introduced.
  F5 is unchanged; open SixRoomPreview and F6 for the current imported textures.
- Full/2x captures: `tools/capture_wireframe_cells.gd -- SixRoomPreview`.
  Entry and wide-connection details: `tools/capture_six_room_wireframe.gd`.
  Older stone-specific capture/probe helpers do not describe this migrated scene.

## Door cell wireframe review — 2026-10-23

- Latest user request authorizes GODOT INTEGRATION in a NEW PLUS-SHAPED SCENE.
  `scenes/WireframeDoorCross.tscn` uses the shared renderer: single-cell centre,
  four branches of length 3, closed ends, 13 cells. Door cells are (0,-2) north,
  (2,0) east, (0,2) south and (-2,0) west; direction names still mean front normal.
  `door_cells` is an exported cell-to-direction dictionary, empty by default.
  Only connected straight variants w10_p00_e00 (N/S doors) or w05_p00_e00 (E/W)
  are supported. Invalid placements warn and retain ordinary cell images.
- `tools/export_wireframe_doors.cjs` prepares four COMPLETE SVGs (floor, walls,
  arch, leaf, both hardware faces) in `assets/dungeon/wireframe-doors/` and
  `scripts/wireframe_door_catalog.gd`. Shared pitch 256; door anchor (24,128),
  image 304x392, with a taller transparent gutter for lateral arches. Both
  contact end faces are internal; the north/west masonry seam is retained.
  Godot replaces the ordinary floor/wall pair with one whole door Sprite2D.
  No runtime geometry, rotation, clipping or tint. Mipmaps enabled for all four.
- Capture the actual scene with `tools/capture_wireframe_cells.gd -- WireframeDoorCross`
  and its four close-ups with `tools/capture_wireframe_doors.gd`. This is a
  static visual scene: opening, interaction, collision and navigation are absent.
  F5 stays unchanged; open the new scene and use F6.
- Current correction: the door is DOUBLE-SIDED. Both faces need plank seams,
  two bands and a handle. The west view must contain the same closed leaf as
  the east view. The previous front-only hardware and deeply recessed back
  were rejected. The source now authors both complete faces before rotation.
- Prepare the FOUR WIREFRAME ORIENTATIONS. Reproduce
  the source, then run `tools/export_arched_door_orientations.cjs`. Four files
  `docs/reference/door-arch-facing-{north,east,south,west}-wireframe.*` and
  `door-arch-four-orientations.*` show the same volume under one fixed camera.
  Direction names identify the FRONT normal: N(1-x,1-y,z), E(y,1-x,z),
  S identity, W(1-y,x,z), all transformed before the unchanged projection.
- Keep the floor pattern in world axes. Recompute visibility AND the apparent
  contour from each transformed camera ray; never rotate source visible edges
  or its camera-dependent silhouette. North/west expose the wood's rear face
  with its own hardware; both handles share the same physical x/z spindle.
  Keep real occlusion: in the west view the arch masks the near-side handle,
  while the leaf and its plank seams remain visible. East/west are near-profile
  views with this camera, not artificially front-facing door drawings.
- The four source variants were standalone visual proposals before the latest
  integration request above. The common framing fits
  all projected bounds; the original viewport would crop the lateral arch.
- Latest correction: the arch must SPRING DIRECTLY FROM THE LEFT/RIGHT WALLS.
  Remove the added jambs inside the passage. The existing walls carry the arch
  across their full thickness. Keep the selected arched door, no torches,
  square 1x1, WEST/EAST walls, NORTH/SOUTH open and door centered at y=.5.
- Read `docs/reference/DOOR_CELLS.md`. Current exporter:
  `tools/export_arched_door_cell_wireframe.cjs`; SVG/JSON/PNG proposal:
  `docs/reference/door-arch-cell-west-east-wireframe.*`. Exact dimensions await
  visual approval. The connected exporter above reuses this reviewed geometry.
- Preserve square 1x1, projection (x-.18*z, y-.9*z), side-wall thickness 1/6,
  height H=1.88/6 and joint .94/6. Arch depth/thickness 1/6, inner radius 1/3,
  outer radius .5, seven stones, starting at H. Its bearings are x=0..1/6
  and x=5/6..1, y=.41666667.. .58333333 on the existing wall tops. The arch
  top is .81333333. Door width is the full clear passage width 2/3.
  The single arched leaf has equal .025 recess on BOTH sides: local
  y=.44166667.. .55833333, thickness .11666667. This keeps the existing front
  face and brings the rear out of the deep frame. No raised threshold.
- Construction and visibility use extruded convex profiles, including the arch
  ring and the arched leaf. Do not use an opaque bounding box across the curved
  opening. Draw radial stone joints and the camera-tangent silhouette of the
  extrusion; omit tessellation edges. Floor remains the normalized 19-slab
  motif at z=0. No mirroring, widened footprint, flared base or new camera.
- The previous rectangular proposal (`export_door_cell_wireframe.cjs` and
  `door-cell-west-east-wireframe.*`) remains historical, not the selected shape.
  The first arched version's .075-wide inner jambs are also superseded.

## Entrance stair wireframe review — 2026-10-23

- Current user request authorizes the OTHER THREE DIRECTIONS AND GODOT
  INTEGRATION after the north-end assembly looked correct. The earlier
  review-only restriction below is historical and is superseded for this task.
- `tools/export_wireframe_entrances.cjs` reads the reviewed south-opening
  source and prepares four complete floor/walls/stair SVG textures in
  `assets/dungeon/wireframe-entrances/`. Names identify the OPEN/downhill side.
  World transforms are N(1-x,1-y,z), E(y,1-x,z), S(x,y,z), W(1-y,x,z);
  all then use the same projection. Never rotate or mirror a projected image.
- `wireframe_entrance_catalog.gd` maps w14/w13/w11/w07 p00/e00 to N/E/S/W
  openings. `entrance_at_closed_ends=false` is the shared renderer default;
  `WireframeClosedCorridors.tscn` enables it, showing four entrances in its
  existing 17 cells. Each entrance replaces BOTH ordinary floor and wall
  textures with one complete Sprite2D, at the same (24,88) anchor/256 pitch.
  The floor motif remains world-aligned. Other scenes retain their old defaults.
- Fills include only visible top/+X/+Y faces and omit open-port faces. Internal
  end-face edges are absent. Real north/west contacts retain the same cap and
  upper-course masonry joints as the shared wall kit (the +X/+Y cell owns them).
  Do not lose these legitimate joints by rotating the isolated source alone.
  No runtime clipping, tint, generated geometry or sprite repair is introduced.
- Import all four SVGs with mipmaps. Actual Godot captures:
  `tools/capture_wireframe_cells.gd -- WireframeClosedCorridors 2x2CellRoom`,
  and `tools/capture_wireframe_entrances.gd` for four enlarged end views.
  Integration is for visual review; navigation and entrance gameplay are absent.

- Historical first assembly request: put the proposed entrance in the PREVIOUS TEST IMAGE,
  replacing its north terminal cell. `room-north-entrance-wireframe.svg`,
  `-north.svg` and JSON retain the 17-cell square room and place the entrance
  at (1,-2,0), opening south into the existing corridor at (1,-1,0).
  `tools/export_entrance_room_wireframe.cjs` reproduces this assembly offline.
  Omit the entrance's ten end-face edges on the shared wall contacts; all
  twelve sampled contact points match exactly. Review full and north detail.
  The room's original global paving continues through the landing; the isolated
  entrance's local catalogue floor motif is not substituted into that global
  pattern. This is an image assembly review, not Godot scene integration or
  final artistic approval of the staircase.
- The user requested four dungeon entrance orientations, starting with stairs
  descending from image top to bottom, enclosed by north/west/east walls and
  open to the south. This was the first direction reviewed before integration.
- Read `docs/reference/ENTRANCE_STAIRS.md`. Source/export tool:
  `tools/export_entrance_stair_wireframe.cjs`; outputs:
  `docs/reference/entrance-stairs-open-south-wireframe.svg` and JSON.
  The PNG is a preview of that vector drawing, not a painted sprite.
- Keep the current square 1x1 cell, wall thickness 1/6, height 1.88/6,
  joint .94/6 and common projection (x-.18*z, y-.9*z). The proposed five
  treads descend from z=.25 to the floor with .05 risers, across y=1/6..0.84.
  Stair width is 2/3; the remaining south landing is at z=0.
  These dimensions are retained for the authorized four-direction review.
- Visibility uses the combined wall AND stair volumes. Do not overlay an
  existing complete wall sprite above the staircase: that would incorrectly
  cover stair surfaces in front of the north wall. Prepare complete imagery
  offline. The current request authorizes the scene and catalogue update above.
- Future directions must be constructed in world coordinates with the SAME
  projection. Never rotate or mirror the projected drawing. No flared base.

## Active Godot integration — 2026-10-23

- Before changing or regenerating wireframes, read
  `docs/reference/WIREFRAME_WORKFLOW.md`. It records source files, construction
  logic, masks, piers, shared projection, anchors, offline export and review.
- The user explicitly authorized replacing the modular study rendering with the
  wireframe cells, and chose WIREFRAMES FIRST before painted sprites. The older
  review-only restrictions below describe previous stages, not a current ban
  on this integration. Artistic acceptance of the imported kit is still pending.
- Godot must NOT generate images, paving, wall geometry or masonry at runtime.
  `scripts/wireframe_cell_study.gd` only selects complete pre-imported textures
  and places Sprite2D nodes on an integer square grid. Ordinary cells use one
  floor image and at most one wall image; entrances and doors use one complete image.
  No stone fitting, clipping, mirroring or tinting.
- `assets/dungeon/wireframe-cells/` is a prepared SVG image catalogue, explicitly
  preloaded by `wireframe_cell_catalog.gd`. It has 136 wall records including
  blank states, covering the 16 cardinal combinations, concave pier combinations
  and exposed open ends. `wireframe_cell_layout.gd` reads cardinal and diagonal
  occupancy; pier geometry is ALREADY in the selected image, not drawn in Godot.
- `tools/export_wireframe_cell_kit.cjs` is an OFFLINE vector preparation tool.
  It is never invoked by Godot. Projection and wall dimensions come from the
  `after` model of `two-course-square-room.json`: true 1x1 grid, thickness 1/6,
  height 1.88/6, single joint at .94/6, height-up (-.18,-.9). The SVGs use neutral
  filled faces to hide rear lines; this is a geometry prototype, not painted art.
- The provisional invented paving pattern was withdrawn after user clarification.
  `floor.svg` uses the EXISTING 19-slab motif of `floor-only-cell-wireframe.json`,
  normalized from its historical 6x5 drawing bounds to a square image. This
  repeated cell motif is distinct from the earlier global whole-room paving.
  Never silently redesign that motif or claim the global study is pixel-identical.
- All 13 existing modular study/alias scenes now reference the new renderer.
  Dimensions, open endpoints and attachment settings are preserved. The explicit
  `WireframeClosedCorridors.tscn` example has a 3x3 room plus four length-two
  closed branches: 17 cells, eight junction piers. F6 opens this example.
  F5 still points to `5x5RoomVerticalCornerCorridors.tscn` in project.godot.
  SixRoomPreview now also uses this renderer; see the latest six-room section.
- Keep the computed refresh_action Callable getter. SVG files are imported as
  textures with mipmaps, including in editor previews. Use linear mipmap
  filtering to avoid disappearing wireframe strokes when the map is reduced.
  Floors and walls are separate layers;
  hero occlusion/ysorting, collision and navigation are NOT implemented by this.
- Human-review captures: `tools/capture_wireframe_cells.gd`, artifacts named
  `wireframe-<scene>.png` and `-2x.png`. The older stone-specific capture helpers
  target legacy renderer diagnostics; use the new helper for these studies.

## Current user review gate — 2026-10-23

- Latest grid constraint: cells must remain SQUARE 1 x 1 units so the dungeon
  can be assembled on a regular grid. The proposed 6 x 7.5 rectangular-cell
  comparison was explicitly rejected before any geometry changes were made.
  Do not adopt that proposal or treat the earlier 6 x 5 drawing dimensions as
  approval of rectangular logical cells. The user clarified that corridors must
  remain ONE CELL wide and authorized revising visible wall height. They then
  specifically requested removing the thin masonry level from every wall.
- Current requested study: SQUARE GRID WITH TWO WALL COURSES.
  `docs/reference/two-course-square-room.svg`, directional detail SVGs, JSON
  and `two-course-square-corridor-{before,after}.svg` use true 1 x 1 cells.
  Keep ground X/Y screen-aligned and height-up (-0.18,-0.9). Thickness is 1/6
  of a cell, using the former six-unit horizontal width as the common scale.
  Both comparison models share this square plan, paving, wall thickness and
  framing; the reference is a square reconstruction, not the old 6 x 5 image.
  Remove the former 0.32/6 thin top band: height drops from 2.2/6 to 1.88/6,
  leaving TWO equal 0.94/6 courses and one horizontal joint. Top-stone joints
  continue through the upper course. All wall orientations and all eight piers
  use the same height; piers retain horizontal joints only. The 17-module
  room keeps four closed corridors, each one cell wide. Eight terminal-wall
  interfaces remain internal (80 source edges omitted, vs 96 with the thin band).
  The horizontal visible floor band grows from 0.336667 to 0.384667 cell,
  approximately 14.3%, on the shared square plan. This is a modest gain, not
  proof of gameplay readability. The blue character is an indicative scale
  guide (height .30, width .18 cell), near the foreground wall at local y=.64;
  dashed portions are occluded. No production hero scale is approved by it.
  The default view shows the full room without the thin band. This remains a
  wireframe review proposal, without Godot or painted-asset changes.
- Previous requested variants: FOUR THREE-WALL CELLS, ONE OPEN SIDE EACH.
  `docs/reference/three-wall-cell-open-{north,east,south,west}.svg` and JSON
  define U-shaped prisms in the shared 6 x 5 cell, height 2.2, thickness 1.
  The suffix names the OPEN side. Floors: north [1,0,5,4], east [1,1,6,4],
  south [1,1,5,5], west [0,1,5,4], all z=0. Each variant retains the shared
  projection, course levels and masonry spacing; never rotate/mirror its
  projected drawing. The isolated floor rows retain the shared slab joints,
  trimmed at wall feet. Foreground-wall occlusion is intentional.
  `room-closed-corridors-wireframe.svg` and four directional detail views append
  one terminal cell to EACH existing corridor, giving 17 modules total. The
  opening faces the room: N-open at (6,20), S-open at (6,-10), E-open at (-12,5),
  W-open at (24,5). Eight full wall-end interfaces become internal (96 source
  edges omitted). Continuous wall runs and paving span those interfaces.
  The eight original square junction piers remain unchanged, with horizontal
  joints only. The assembled floor contains 170 slabs in 33 rows. Overall
  ground bounds are x=-12..30, y=-10..25. These are line-only review proposals,
  without Godot integration or painted-asset changes. The preceding open-ended
  room study is preserved separately.
- Previous requested assembly: 3 x 3 ROOM WITH FOUR CENTERED CORRIDORS.
  `docs/reference/room-four-corridors-wireframe.svg` and its north/east/south/west
  detail SVGs/JSON extend the previous south-corridor study with three branches.
  The 13 modules are the nine room cells plus west/east north-south-wall cells
  at (-6,5) and (18,5), and north/south west-east-wall cells at (6,-5)/(6,15).
  The four room edge-center cells have floor only. Eight identical 1 x 1 x 2.2
  piers bridge full faces: (6,0), (11,0), (0,5), (0,9), (17,5), (17,9),
  (6,14), (11,14). Piers retain horizontal joints only. All far ends are open;
  clear widths are 4 north/south and 3 west/east, from the shared 6 x 5 cell.
  The 142 slabs occupy 25 continuous rows. Room rows at y=6..9 extend across
  both horizontal corridors without cell-border seams. Preserve projection,
  wall height/thickness, masonry courses and staggered joints. This is a
  line-only review proposal, without Godot or painted-asset changes.
- Previous requested variant: ONE CELL WITH NORTH AND SOUTH WALLS ONLY.
  `docs/reference/north-south-cell-wireframe.svg` and construction SVG/JSON
  use two separate prisms at x=0..6, y=0..1 and y=4..5, height 2.2,
  thickness 1. Floor: x=0..6, y=1..4, z=0, nine staggered slabs in three
  rows of heights 1, 1.1 and 0.9. West/east remain open. Preserve the common
  projection and the recent masonry divisions (1.9 spacing, phases 0.7/1.65,
  cap joints continued down to z=1.88). The foreground wall occludes part
  of the floor. This is a line-only proposal, without scene integration.
- Previous requested study: CONTINUOUS PAVING AND MASONRY JOINTS.
  `docs/reference/masonry-floor-wireframe.svg` and its floor/junction/pillar
  views retain the 3 x 3 room, south corridor, square piers and common projection.
  The floor pattern now spans the whole usable floor, with no decorative seams
  at logical cell edges. The saved JSON records 111 slabs in 19 rows (13 room,
  6 corridor), staggered widths and slightly varied row heights. Floor remains
  at z=0 and meets the physical wall feet. This supersedes the old repeated
  per-cell paving pattern for the current proposal only.
  Lower wall courses have 1.9-unit brick spacing, with phases 0.7 and 1.65.
  Cap divisions continue down their 0.32-high front edges. Corner and pier caps
  remain whole square stones. User correction: piers have horizontal joints only,
  with no vertical subdivision of their small faces. Wall height
  2.2, thickness 1, course levels 0.94/1.88 and opening width 4 are unchanged.
  This remains line-only review work, without changes to Godot or painted assets.
- Previous requested piece: SQUARE JUNCTION PIER.
  `docs/reference/pillar-junction-wireframe.svg`, `-pillar.svg`, `-room.svg`
  and JSON propose a 1 x 1 x 2.2 prism, with the common projection and courses
  at z=0.94 and 1.88. Two identical instances at (6,14,0) and (11,14,0)
  bridge the south room walls and the corridor walls with full 1 x 2.2 faces.
  Their footprints cover two 1 x 1 patches of the bottom-center floor cell;
  the clear opening stays x=7..11, width 4. No projection mirroring, flared
  base or extra height. The accent stroke identifies the proposed piers only.
  This is a wireframe review proposal, without Godot or painted-asset changes.
- Previous requested assembly: 3 x 3 ROOM WITH A SOUTH CORRIDOR.
  `docs/reference/room-3x3-south-corridor-wireframe.svg` and JSON retain the
  nine-cell room but replace its bottom-center south-wall cell with floor only.
  A tenth cell with west/east walls is placed at (6,15), below the opening.
  Corridor bounds: x=6..12, y=15..20; clear floor: x=7..11. Preserve the
  common projection and dimensions. Six full wall interfaces remain internal
  (72 source edges omitted). The corridor walls touch the room's south walls
  only along vertical edges at (6,15) and (12,15): a full-thickness junction
  required the dedicated return proposed above. This preserves the earlier study,
  without scene integration or a claim of a validated junction.
- Previous requested variant: ONE CELL WITH WEST AND EAST WALLS.
  `docs/reference/side-walls-cell-wireframe.svg` and its construction SVG/JSON
  use two separate prisms at x=0..1 and x=5..6, y=0..5, height 2.2, thickness 1.
  Floor: x=1..5, y=0..5, z=0; 18 slabs retain the shared pattern's joints.
  Both walls use the same projection and height vector. North and south are
  open; hide occluded floor lines. This is a wireframe proposal only.
- Previous requested assembly: ROOM OF 3 x 3 CELLS (the user corrected 3 x 2).
  `docs/reference/room-3x3-wireframe.svg`, `-seams.svg` and JSON assemble all
  nine studies. Top: upper-left / north / upper-right; middle: west / floor /
  east; bottom: lower-left / south / lower-right. Cell offsets are multiples
  of (6,5), with room bounds x=0..18, y=0..15. Keep the common projection,
  wall height 2.2, thickness 1 and existing slab pattern. The eight shared wall
  end faces are internal (96 source edges omitted). Visibility uses the whole
  assembled volume. This is a wireframe proposal, without Godot integration.
- Previous requested variant: FLOOR-ONLY CELL, with no walls.
  `docs/reference/floor-only-cell-wireframe.svg` and JSON cover x=0..6, y=0..5
  at z=0, preserving the shared projection and the complete slab pattern before
  wall-foot trimming: 19 slabs in six rows (height 1 then five rows of 0.8).
  All four sides are open. This remains a line-only geometry proposal.
- Previous requested variant: LOWER-RIGHT CORNER CELL WITH FLOOR.
  `docs/reference/lower-right-cell-wireframe.svg` and its construction SVG/JSON
  join the east wall (x=5..6, y=0..5) and south wall (x=0..6, y=4..5) as
  one L-shaped prism, height 2.2 and thickness 1. Floor: z=0, x=0..5, y=0..4.
  Preserve the shared projection and slab joints; do not mirror the projected
  lower-left drawing. Hide occluded lines. Top and left remain open.
  This remains a line-only geometry proposal, without scene integration.
- Previous requested variant: LOWER-LEFT CORNER CELL WITH FLOOR.
  `docs/reference/lower-left-cell-wireframe.svg` and its construction SVG/JSON
  join the west wall (x=0..1, y=0..5) and south wall (x=0..6, y=4..5) as
  one L-shaped prism, height 2.2 and thickness 1. Floor: z=0, x=1..6, y=0..4.
  Preserve the shared projection and slab joints. Hide lines occluded by the
  combined volume; top and right remain open. This remains a line-only proposal.
- Previous requested variant: ONE CELL WITH ONLY A SOUTH WALL and floor.
  `docs/reference/south-wall-cell-wireframe.svg` and its construction SVG/JSON
  use wall bounds x=0..6, y=4..5, height 2.2, thickness 1; floor is z=0,
  x=0..6, y=0..4. Preserve the projection and height direction. The foreground
  wall occludes the floor behind it; hidden lines are optional. Top/left/right
  are open. This is still a line-only geometry proposal, without scene changes.
- Previous requested variant: ONE CELL WITH ONLY AN EAST WALL and floor.
  `docs/reference/east-wall-cell-wireframe.svg` and its construction SVG/JSON
  keep the unchanged projection, thickness 1 and height 2.2. Wall: x=5..6,
  y=0..5. Floor: z=0, x=0..5, y=0..5. Preserve the upper-right corner's slab
  joints for y=1..5 and add one row in y=0..1. Clip floor lines hidden by the
  wall volume. Do not mirror the west drawing; top/left/bottom remain open.
- Previous requested variant: ONE CELL WITH ONLY A WEST WALL and floor.
  `docs/reference/west-wall-cell-wireframe.svg` and its construction SVG/JSON
  preserve the same projection and cell bounds. Wall: x=0..1, y=0..5,
  height 2.2. Floor: z=0, x=1..6, y=0..5. Keep the corner's existing joints
  for y=1..5 and add one row in y=0..1 where the north wall was removed.
  Top/right/bottom are open; this remains a line-only geometry proposal.
- Previous requested assembly: THREE CELLS IN A ROW — upper-left corner,
  north-wall-only cell, then upper-right corner. See
  `docs/reference/three-cell-wireframe-join.svg`, `-seams.svg` and JSON.
  Offsets are (0,0,0), (6,0,0), (12,0,0); preserve all source dimensions,
  projection and slab joints. The shared wall end faces at x=6 and x=12 are
  internal (24 outline edges omitted); floor visibility uses the combined
  wall volume. The two continuous floor grout lines remain part of this study.
  This is a line-only assembly proposal, without scene integration.
- Previous requested variant: UPPER-RIGHT CORNER CELL WITH FLOOR, recorded in
  `docs/reference/upper-right-cell-wireframe.svg` and its construction SVG/JSON.
  Keep the accepted projection unchanged; move the return in world coordinates
  to x=5..6, y=0..5. Never mirror the projected upper-left image. The north wall
  stays x=0..6, y=0..1; floor is z=0, x=0..5, y=1..5. North-only slab joints
  are retained and trimmed at x=5. Hide floor lines occluded by the east wall.
  This remains a line-only proposal, without scene integration.
- Previous assembly review: place the upper-left corner cell A beside the
  north-wall-only cell B on its right. See `docs/reference/two-cell-wireframe-join.svg`
  and its JSON; `-seam.svg` marks the interface. B is translated by (6,0,0),
  with no rotation or scaling. The 12 wall edges on the shared end faces become
  internal and are omitted from the joined view. The existing slab layout is
  preserved, including its continuous grout line at x=6; this remains an artistic
  limitation to review. The focused report in `artifacts/two-cell-wireframe-join-report.json`
  checks 14 matching boundary points with zero projected mismatch. This is a
  wireframe assembly proposal, not approval of painted assets or Godot scenes.
- Previous variant: ONE CELL WITH ONLY A NORTH WALL and floor.
  `docs/reference/north-wall-cell-wireframe.svg` (plus construction SVG/JSON)
  derives from the corner study: keep the north wall, remove the west return,
  and extend floor coverage west to x=0. Cell bounds remain x=0..6, y=0..5;
  wall height, thickness, projection and framing are unchanged. Left/right/bottom
  are open. This is another line-only geometry proposal, not scene integration.
- APPROVED GEOMETRY: the user accepted `wall-wireframe-aligned.svg` ("ok très
  bien on avance") and designated it the UPPER-LEFT CORNER OF ONE CELL.
  Preserve that wall geometry and its projection exactly: ground X=(1,0),
  ground Y=(0,1), height-up=(-0.18,-0.9), height 2.2, thickness 1. This approval
  concerns the wireframe geometry, not any rejected painted sprite or live scene.
- Previous floor addition in the corner wireframe: see
  `docs/reference/corner-cell-floor-wireframe.svg`, its construction SVG and JSON.
  Floor is at z=0, x=1..6, y=1..5, touching the north/west WALL FEET. Its 16
  rectangular slabs use five staggered rows. Never align the floor to elevated
  wall-cap edges or change the accepted projection to fit the floor.
- Continue reviewing these wireframe variants before
  painted asset generation or scene integration unless the user directs otherwise.

### Orientation correction now accepted

- Latest correction: the LEFT WALL RUN must be vertical ON SCREEN, not diagonal.
  The two-point wireframe was rejected for its orientation. Current proposal:
  `docs/reference/wall-wireframe-aligned.svg` and
  `wall-wireframe-aligned-construction.svg`, metadata in
  `wall-wireframe-aligned.json`. It is a parallel oblique drawing with ground X
  horizontal and ground Y vertical. All faces share the same height offset.
  This is not a finite two-point camera. The user has now accepted this wireframe
  as the cell's upper-left corner; preserve its relief offset in the floor study.
- The user rejected `corner-parallel-courses.png` as still having
  incorrect perspective and asked for a LINE-ONLY WIREFRAME with correct geometry
  and vanishing lines. The first wireframe files `wall-wireframe.svg` and
  `wall-wireframe-construction.svg` are now rejected historical proposals.
- That rejected wireframe used a real level pinhole camera with two finite ground-plane
  vanishing points and parallel vertical edges. Its constant-section L prism and
  camera recorded in `wall-wireframe-two-point.json`. Do not use it as an
  approved reference for the game's screen-aligned floor plan.
- The old assistant-chosen oblique contract (+16,+96) is suspended for review.
  It was never artistically approved; do not treat it as a user requirement.
- The deterministic line drawing is explicitly requested by the user. It is
  a geometry guide, not a programmatically repaired production sprite.

### Previous sprite review (rejected)

- The user requested one proposed sprite for approval before any further kit
  generation or scene updates. Their latest feedback REJECTED
  `assets/dungeon/gloom-kit/proposals/corner-parallel-courses.png`.
- The user rejected `corner-straight-foot.png`: its base and perspectives were
  still wrong. Do not use that locally straightened end as geometry. The current
  proposal follows `docs/reference/corner-courses-guide.svg`, which draws each
  course with the same (+32,+192) top-to-foot displacement at 2x. The final PNG
  remains an image-generated interpretation, not proof of exact geometry.
- The user likes the material/color of the preceding `corner-review.png` but
  rejects its flaring foot. Preserve that second version's appearance; the wall
  must keep constant thickness down to the ground, with no spreading base.
- The sole palette/style reference is now `assets/dungeon/gloom-kit/reference.png`,
  copied unchanged from the latest user mockup. The user wants darker gloomy
  slate masonry and sparse localized violet luminous details. This supersedes
  cap-muted-v11 and all other previous generated color references.
- Full cleanup, regeneration and scene integration remain pending. See
  docs/superpowers/plans/2026-10-22-gloom-kit.md. The first gloom wall atlas was
  rejected for painting vertical top planes as facades; it must not be used.

## Previous perspective convention — suspended pending wireframe review

- Read `docs/reference/PERSPECTIVE.md` before any dungeon sprite generation or
  assembly correction. The user explicitly requested one remembered camera.
- Previous parallel oblique 2.5D proposal, contract `dungeon-parallel-v1` in
  `docs/reference/perspective-contract.json`. Ground axes stay screen-aligned.
  Top-to-foot projection is (+16,+96)
  at reference scale, uniformly scaled together; never mirror it for west/east.
  Painted lighting comes from image upper left for every orientation.
- Attach `docs/reference/perspective-geometry.png` as the geometry guide and
  the canonical material image to every generation. Include the prompt block
  from PERSPECTIVE.md and record the contract ID in generation provenance.
  Regenerate the guide with `tools/render_perspective_guide.gd` if the contract
  is explicitly revised. The guide is documentation, never production art.
- Use the latest original mockup's unlit wall tops as the color reference in every
  generation. Geometry inputs and color inputs have distinct roles. Do not
  progressively inherit a changed palette from generated variants.
- Check left wall, right wall, horizontal cap, full facade and corners together
  in Godot before propagating. No floating gaps; top and facade are one volume.
- The first lateral-relief experiment was rejected for opposing perspectives,
  different materials and open joints. Its prompts are archived in
  lateral-volume-generation.json; its code and all 14 trial PNGs are only in
  artifacts/lateral-volume-rejected. Never use compact-relief*, closed-relief*,
  shorts-relief*, lengths-relief*, elbows-relief* or paired-relief* from this
  rejected family as generation references or runtime assets. The recorded
  prompts contain the mistaken opposing directions; they are historical data.
  The active renderer has been returned to checkpoint 31e72bf while its replacement
  is calibrated. The checkpoint itself is not artistic approval.
- This convention supersedes all older projection descriptions below, including
  historical TOPS ONLY / exterior-backing and side-specific perspective rules.
  Older measurements describe their implementation, not this calibration contract.
  Native-alpha asset constraints
  and the prohibition on programmatic visual repairs still apply.

## Keep the game design synchronized

- Read `GAME_DESIGN.md` before changing gameplay, balance, hero AI, controls,
  progression, persistence, visual state feedback or playtest configuration.
- Update the corresponding rules in `GAME_DESIGN.md` in the same change as
  implementation. Include costs, defaults, prerequisites, state transitions,
  exceptional outcomes, save/load behavior and affected player feedback.
- Section 0 describes the implemented static 2D foundation. Keep implemented
  rules distinct from future design, legacy behavior and known limitations.
  A sprite, model or animation asset is not proof of an implemented hero class.
- Document temporary test overrides and their active values. Do not turn them
  into permanent progression or conceal them behind the normal balance rules.
- Verify written numbers against code and tests. Do not change gameplay merely
  to make it agree with documentation; surface any discrepancy instead.
- For bug fixes, add a regression reproducing the relevant player scenario;
  use simulation/node/animation probes and visual captures when appropriate.
- Before declaring a behavior change complete, check the design update and
  report verification. Run `tools/test-mobile.ps1 -All` for gameplay changes.
- Documentation-only edits require source and reference checks, not a full
  gameplay test run unless code also changes.

## Required asset workflow — native transparency

- Every dungeon element must use generated images with genuine alpha already
  present in the source. Never make silhouettes through programmatic cutouts,
  traced render polygons, masks, color/luminance removal or cutout shaders,
  either offline or at runtime. Baking those techniques into a PNG is forbidden.
- Generate additional complete sprites for missing orientations, corners, ends,
  intersections and transitions. Do not approximate missing art by clipping
  painted stones, stretching them or displaying a full-scene illustration.
- Preserve the approved slate-blue style, overhead/front-facade perspective,
  proportions and fixed layout. Uniform sprite scaling is allowed. Rectangular
  atlas regions select complete sprites and their existing transparent gutters;
  they must never trim the painted silhouette.
- The current main scene has completed this migration. Eight generated PNGs in
  `assets/dungeon/alpha-kit/` supply 27 sprite definitions; the existing separate
  torch PNG is retained. `generation.json` records prompts and original outputs.
  The unused `walls.png` is an initial generation draft, not a scene dependency.
- `scripts/alpha_kit.gd` stores full regions and body measurements. Measurements
  only determine anchors and uniform scale; they are never rendered masks.
- Transparency does not guarantee compatible joins. Inspect actual captures at
  normal scale and at least 2x. Sparse probes cannot establish artistic quality.

## Durable modular rendering direction — user clarification, 2026-10-22

- The goal is a coherent dungeon that the player can customize. Build reusable
  assembly rules from logical occupancy, exposed edges and neighboring modules.
  A new room size or connection must reuse those rules. Existing scenes are
  examples and visual regression references, not separate hard-coded renderers.
- Prefer generating a new complete native-alpha image over programmatic visual
  repairs. Generate as many orientations, lengths, corners, ends, intersections
  and transitions as needed. A dedicated sprite must represent a reusable local
  configuration, not an entire prepainted room or a patch tied to one scene.
- Reuse compatible approved sprites and existing assembly helpers first. When
  a configuration requires new art, register its source, orientation, dimensions,
  anchors, connection ports and selection rule in the shared kit and generation
  provenance. Every subsequent matching configuration must use that same entry.
  Keep scale, perspective, color, contours and connection geometry consistent.
- The stone color, bevels, edge highlights, shadows and outlines belong in the
  generated PNGs. Godot selects and places whole sprites, applies uniform scale
  and draw order; it must not repair their appearance with lights, glow, shaders,
  runtime RGB/alpha tinting, clipping, stretching or overlapping painted ends.
  This rule concerns dungeon architecture; separately authored gameplay lights
  such as torches are outside this asset correction.
- This direction supersedes older RGB instructions. The modular studies now use
  native palette PNGs with white modulation: floor-calm-v3, brick-muted-v3,
  cap-muted-v11, cap-square-v3, cap-tight-v13, wall-tight-v22/v23, cap-compact-pairs-v24,
  cap-elbows-square-v7, paired-cap-square-v7,
  narrow-separator-muted-v4 and solid-separator-muted-v9. Their geometry follows
  the former atlases listed below; floor-calm-support-v1 supplies shaded supports.
  No floor brightness multiplier, per-stone runtime tint, facade1.10 or support0.70
  remains in the modular renderer. Earlier six-room art is a separate legacy scene.
  Commit2584f57 preserves the state before this palette revision. Exact prompts,
  source mappings and visual-review scope: calm-palette-generation.json.
- Review each shared change against the existing small room/corridor scenes and
  connected configurations at normal scale and enlarged. Reopening connections
  must select the same shared art. Gaps, ledges and painted-end overlaps remain
  defects even if a technical check passes. Arbitrary player-built dungeons are
  the target; the current limited studies do not yet implement that system.

## Current rendering scope

- The modular `Dungeon` inspector refresh button uses a computed Callable getter,
  not a stored initializer: hot reload can leave the stored property Nil.
  Keep this in the shared modular_room_study.gd base for connected studies too.
  The isolated editor diagnosis in artifacts/editor-button-inspection.log invoked
  it before/after parent-script reload and retained302 sprites in3x3RoomCornerCorridors.
- The current modular art studies are the closed rooms `1x1CellRoom.tscn`,
  `2x2CellRoom.tscn`, `3x3CellRoom.tscn` and the OPEN corridors
  `1x2Corridor.tscn`, `2x1Corridor.tscn`, `1x3Corridor.tscn`,
  `3x1Corridor.tscn`. Dimensions mean columns x rows. Vertical corridors open
  north/south; horizontal corridors open west/east. These are isolated studies,
  not an arbitrary-layout system. A separate four-way connection study is below.
  The previous `SingleCellRoom.tscn` displayed four floor modules and was
  renamed to `2x2CellRoom.tscn` at the user's request.
- `scenes/3x3RoomFourCorridors.tscn` remains UNAPPROVED. It now rebuilds a 3x3
  room with centered branches: `connections` N1/E2/S4/W8, default15;
  `corridor_length` 1-3, script default2, scene override3 for west/east.
  `vertical_corridor_length` defaults0 (inherit corridor_length); positive values
  set north/south only, negatives clamp0. Scene override4 adds one more cell
  vertically for user-requested continuity inspection. Use the resolved vertical
  length for occupancy, end openings, floors, side walls and detail framing.
  Far ends remain open. The occupancy/perimeter
  resolver is `modular_connection_plan.gd`; floor assembly currently supports
  one odd rectangular room with configurable N/S attachment columns and W/E
  attachment rows, captured at3x3 and5x5. Empty horizontal_attachment_rows keeps centered ports;
  explicit rows are sorted/deduplicated, invalid indices ignored. All-invalid
  explicit list gives no horizontal branches. Floor extensions use each branch's
  own two paving rows and physical end bounds; supports follow its first row.
  No player editor, navigation, saving or arbitrary multi-room renderer exists.
  Branch logical length counts straight modules; their native corner arms add
  physical span. Do not claim these ports already fit a future navigation grid.
- `scenes/5x5RoomFourCorridors.tscn` is the new UNAPPROVED comparison: layout
  study_5x5 (25cells,10floor rows), same renderer/kit, horizontal3/vertical4,
  connections15. Physical anchor span2462x1449 atscale.29. Closed shoulders
  span2columns, so shared single corners/straight caps are used, not1column
  paired modules. Do not add scene-specific art repairs. Capture with
  `tools/capture_room_corridors.gd -- --scene=5x5RoomFourCorridors`.
  Review full/2x and12 individual corner-X-Y4x images plus corners-comparison.
  Corner centers derive from actual plan anchors; generic shoulder details do
  not fit all5x5 corners in one crop. F5 target stays3x3CellRoom.
- `scenes/5x5RoomVerticalCornerCorridors.tscn` is UNAPPROVED: shared5x5 layout,
  vertical_attachment_columns[0,4], connections5, corridor_length3, four open
  north/south far ends. The new shared column setting mirrors horizontal rows:
  empty centers, explicit indices normalize/sort/deduplicate, all-invalid disables
  vertical branches. Each column reuses the existing whole passage paving; central
  pavers remain fixed. No new art. Capture --scene=5x5RoomVerticalCornerCorridors
  and inspect1x/2x/four inner corners4x; shaft/corner contour differences remain.
- `scenes/5x5RoomCornerCorridors.tscn` is the UNAPPROVED5x5 counterpart:
  shared study_5x5 layout, horizontal_attachment_rows[0,4], connections10,
  corridor_length3. No renderer or asset changes. Capture with
  --scene=5x5RoomCornerCorridors; inspect full1x/2x and four inner corners4x.
- `scenes/3x3RoomCornerCorridors.tscn` is UNAPPROVED: shared3x3 layout,
  horizontal_attachment_rows[0,2], connections10 (E/W), length3, four open far ends.
  Capture with --scene=3x3RoomCornerCorridors and inspect its two separator tips
  in corners-comparison. Long open/open horizontal runs use native end bounds
  established by closed-turn runs; choose WHOLE count/origin at fixed476 cadence,
  never per-span compression. Opposing horizontal boundaries enclosing one empty
  logical row, with one common closed end and one open end, now select a shared
  separator. The two caps, two corner sprites and short side return are omitted;
  one broad cap and a complete solid terminal replace them. The original flat
  v5 ends were rejected: the facade looked like a curtain below a thin slab.
  `modular_separator_kit.gd` registers complete regions/ports from
  `narrow-separator-muted-v4.png` and `solid-separator-muted-v9.png`, with white tint,
  uniform scaling and476 straight cadence. Original open-end bounds are retained.
  The rule depends on exposed edges, not room size or scene name. Wider voids,
  enclosed islands and vertical dividers remain outside this new selection rule.
  The v7 oblique end face was rejected for inconsistent perspective. The v8 PNG
  includes two cap stones and both masonry courses in the shared orthographic
  projection: height runs straight down; the closed edge stays at the same x
  from cap to foot, without a diagonal side plane. Separate bricks stop at its connecting edge; none
  render below the terminal. Native top/course/base ports select whole brick
  counts for each straight course. Terminal regions are982x801 on1964x801;
  body bounds are(202,166,669,539)/(1094,166,671,539), cap height316.
  Two separator-tip details replace the four consumed corner details in this
  scene's capture. Provenance: `solid-separator-generation.json`. User visual
  approval remains pending; this does not validate arbitrary layouts.
- The current square-turn correction uses `paired-cap-square-v7.png`
  (four whole double-bend modules, slots768x512, anchor96,256) and existing
  `cap-elbows-square-v7.png` for compatible single corners. Earlier paired-v1
  and width/depth experiments cap-elbows-ports-v11/v12, paired-v2/v3/v5/v6 are unused.
  Paired-v4 was rejected for a high-alpha backdrop; no alpha cleanup attempted.
  The latter experiments displaced horizontal joins or made fronts too deep.
  Historical width provenance: `port-width-generation.json`; current native
  square turns: `square-corners-generation.json`. Visual approval pending.
- `modular_join_kit.gd` measures each paired shaft's horizontal extent and its
  actual vertical ends, plus the horizontal strip profile. `paired_fit` maps
  the TWO shaft centers to41/517 at476 spacing with ONE uniform transform;
  apply that SAME transform to y ports. Native profile fit remains approximate;
  the old0.55px estimate described muted-v8, not the new square atlas. Single corners use their measured
  shaft centers, not an assumed center41. Preserve complete original regions.
  Their native profiles remain NW/NE[-14,99], SW/SE[1,114]; raw y ports
  NW[-19,165], NE[-19,164], SW/SE[-61,120]. Full horizontal extents are in SHAFTS.
  Retain the calibrated compact profile frame: fitting its extra black rim
  as stone thickness shrinks the horizontal arms and opens their connections.
- Outside bends must continue the BLUE stone face to the outside end. Do not
  square an old chamfer by adding a black backing rectangle. This failed in
  cap-elbows-square-v4 and was explicitly rejected by the user. The active
  compact-v7, closed-v3 and paired-v7 native images extend the front face itself.
  Whole regions, uniform scale and white modulation remain mandatory. Inspect
  `5x5RoomVerticalCornerCorridors-north-span-2.5x.png` with both cap ends and
  the facade visible, plus the individual corner captures. The square closed-v2
  attempt shortened adjacent stones and broke the2x2 side cadence; it is unused.
- Short returns align signed gaps with absolute value at most82, shifting
  WHOLE horizontal runs by half the gap. This also separates negative gaps
  instead of leaving painted ends overlapped. No tiny spacer between shoulders.
- Small and connected studies retain the shared horizontal profile: north/south
  cap scale .99/.97, cadence476 and continuous staggered courses. Facade starts
  come from course_top:96 north,105 south, below the complete painted cap feet.
  Never reinstate per-span cap compression or per-scene facade heights. Stop
  facades at closed corner anchors (retain75 under NW/NE downward arms);
  -12/+14 extensions belong only to open ends. Central approved paving stays
  fixed; west/east continue its exact rows2/3. Supports remain whole pavers,
  y-40; their shade is now painted in floor-calm-support-v1.png, white modulation.
- `modular_side_kit.gd` uses two whole native pairs from cap-tight-v13,
  two compact pairs from cap-compact-pairs-v24, plus eight complementary
  singles from wall-tight-v22/v23. Compact pairs fill short spans without two
  isolated filler squares; they participate in the same shared length search.
  Pair indices0,1,10,11 cost2, singles cost5. The v16
  replacement was rejected for color and width differences; v17/v18 still left
  excessive dark end bands. Native blue color,
  bevels and outlines stay in the PNGs; white modulation only.
  Width is FIXED by the connected corner port (default94 for standalone
  passages). Never multiply it by a height-fit factor. A0.25-unit length search
  chooses whole sprites at that width, preferring the existing cap-atlas pairs.
  Remaining positive length is distributed over joints, with a strong penalty
  above2 source units per joint. There is no stretching or painted-end overlap.
  The short center plate is allowed only for gaps shorter than
  1.5 times target width, never repeated as a long wall cadence.
- Closed rooms, standalone vertical corridors and connected side runs now share
  make_run. The old315*.92 pair at256 cadence overlapped by33.8 source units;
  never restore that placement. Closed corner ports are top279/bottom-166,
  shaft width101, centers41.75 west/-38 east, in modular_wall_profile.gd.
  Width was calibrated from103 to101 for all closed-corner ports, never fitted
  per span. With square closed-v3, the2x2 span is236 and selects compact pair11:
  height234.496, each external gap0.752. The prior237-unit span selected pair10.
  Native dimensions,
  all generation attempts and capture scope: compact-pairs-generation.json.
  Complete silhouettes use uniform scale from width alone.
  cap-square-v3 supplies whole closed corners; cap-tight-v13 retains side pairs;
  horizontal straight strips remain cap-muted-v11. No painted edge is cropped.
  No filler is added for nonpositive gaps; the pre-existing1x1 corner-to-corner
  contact is unchanged. Provenance: tight-joints-generation.json; earlier attempts
  remain recorded in vertical-width-color-generation.json.
  Do not claim old captures unchanged: vertical art and facade starts change.
  Floors stay fixed. Alpha-native generation alone
  does not establish perfect joints or artistic approval.
- Connected sprite layers remain supportZ0/floorZ1/facadeZ2, etc., above the
  opaque background. Frame bounds use complete sprite rectangles plus40px
  margin, never rendered masks. Closed corner regions retain their original anchors.
  Inspect the isolated rooms' southwest-4x captures for the full first brick below
  the corner, plus west/east-4x for double end outlines and spacing.
- Inspect `3x3RoomFourCorridors.png`, its 2x version, four junctions and the
  focused west-floor/corridor-wall-foot/corner-style captures at4x with
  `tools/capture_room_corridors.gd`. `tools/capture_module_connections.gd`
  renders all16 masks, lengths1/2/3 and same-instance close/reopen. Review
  `connection-masks-comparison.png`, `connection-lengths-comparison.png`,
  `junction-perspective-comparison.png`, `junction-continuity-comparison.png`,
  `junction-profile-comparison.png`, `wall-profile-shared-comparison.png`.
  Inspect the entire four short runs in `junction-all-returns.png` and the
  before/after `junction-native-parts-comparison.png` / `vertical-material-comparison.png`.
  General west4x crops the lower short course; use west-lower-return4x explicitly.
  `junction-ports-{west-upper-return,west-lower-return,north,south}-comparison.png`
  compares the actual24721 baseline saved in artifacts/before-port-widths.
  Captures do not establish artistic acceptance or perfect arbitrary joins.
- Current `project.godot` F5 target is `3x3CellRoom.tscn`; `SixRoomPreview.tscn`
  still contains the six-room composition. Do not infer the launch target from
  historical F5 descriptions below.
- SMALL FLOOR TILES are correct. Each logical cell contributes two paving rows;
  mixed native widths vary the number of individual decorative pavers.
  `modular_room_study.gd` and `modular_study_kit.gd` share
  complete native-alpha sprites across all seven scenes; never create a room
  or half-room image instead of modular parts. The legacy six-room map stays separate.
- Latest perspective correction overrides earlier requests for dark inner faces:
  vertical sides show TOPS ONLY, no dark inner strip and no exterior backing.
  Straight caps use `cap-muted-v11.png`, closed corners use `cap-square-v3.png`;
  shared sides use cap-tight-v13, wall-tight-v22/v23 and compact-pairs-v24.
  Connected corners/transitions use the square-v7 atlases above.
  Horizontal stones retain their visible front thickness. The flattened v7
  caps were rejected; integrated v9 walls corrected the overhang but introduced
  course-height steps at module ends. The current cap preserves that flush
  front face while separate brick-muted-v3 courses run across the ENTIRE wall,
  starting at y=96 north/y=105 south relative to the cap anchor. Never restart them at corners.
  Side textures use white modulation and all straight sides use make_run.
  The legacy pair placement and its [0,3,-2,1] shifts are removed. No stair feet.
  Keep facade faces flush beneath the caps.
  Do not overlap painted cap ends to hide joints: that sliced the next stone.
  Thick black outer contours were corrected with ImageGen native alpha, never
  programmatic trimming. Retain the matching native outlines and complete ends.
- `floor-calm-v3.png` supplies twelve pavers in three native proportions:
  six quiet stones and six different cracks, with softer texture. The user
  rejected the busy texture and repeated identical sizes in floor-variants-v1.
  No engraved center tile. Seed173 and whole-row width ordering retain the
  approved arrangement. The new material is smoother and more uniform, with
  subdued cracks and native color variation. White modulation only: the former
  five tints and(1.74,1.61,1.40) correction are removed. Floor rows cross logical-cell
  boundaries without extra gutters. Each row scales uniformly to its span;
  open vertical passages fit the whole paving composition uniformly to their
  length. Native proportions are preserved. `brick-muted-v3.png` supplies four
  softer masonry variants in two lengths, white modulation. Cell pitch(476,256), scale0.29.
  Regions select whole sprites and their transparent gutters only.
- The user explicitly requested VISUAL inspection, not the old programmatic
  tests or probes, for this art correction. `capture_modular_room.gd` renders
  all seven cases at 1x/2x and four sides at 4x, without assertions or scores:
  `artifacts/<SceneName>.png`, `<SceneName>-2x.png`,
  `<SceneName>-{west,east,north,south}-4x.png`.
  Inspect `cell-rooms-comparison.png` and `corridors-comparison.png` too.
  The historical `verify_single_cell.gd` is outside the active suite and
  describes a rejected assembly. Do not revive it as artistic validation.
  These studies have no entrance, heart, torch, gameplay, collisions or saving.
  Current correction provenance is in
  `assets/dungeon/modular-study/continuous-courses-generation.json`.


- The user rejected the current native-alpha wall composition on 2026-10-21.
  It is NOT an approved perspective baseline: repeated cap blocks, upright
  pier faces and thin filler stones read as incompatible stacked objects.
  The current floor rendering also differs visibly from the original reference.
  Passing alpha, coverage or overlap checks does not resolve this rejection.
  Re-establish a coherent reference-matching wall/floor/corner study before
  propagating another asset revision across the six-room map.
- Latest user corrections: the entrance must share the other walls' height,
  stone scale and treatment; break long aligned joints in floors and masonry;
  cover exposed exterior edges even beside corners and piers. Determine those
  edges from the visible perimeter, not blanket rectangular pier exclusions.
  The user prioritizes visual fidelity and asked to set probes aside for now.
  Use actual rendering and direct comparison with the original as the acceptance
  method for this art calibration; technical probe passes are not the objective.
- `scenes/ReferenceCalibration.tscn` is a separate, UNAPPROVED visual study (F6),
  assembled from five complete PNGs in `assets/dungeon/reference-study/` plus
  the two existing torch sprites. `reference_calibration.gd` is not the six-room
  renderer. Inspect `reference-calibration.png`, `reference-calibration-2x.png`
  and `reference-calibration-comparison.png`; do not treat this study as an
  approved replacement kit or a completed six-room correction.
- The separate arch over fitted returns was rejected as pasted on. The study
  now uses `entry-masonry-v3.png`: wall courses, arch, inner reveals and threshold
  are drawn as ONE complete native-alpha masonry module, scale 0.44 at (27,-86),
  Z3. `door-leaf-v4.png` contains only the wooden leaf, scale 0.128 at (238,43),
  Z2, tint (0.78,0.80,0.85,1), behind the transparent aperture. Wall foot is near
  y=225, jamb feet near y=243. `east-corner-v1.png` joins under its existing pier
  at scale 0.75, position (0,-75), Z4, tint 0.9. All receive light mask 2.
  `door-masonry-comparison.png` shows original/rejected/current rendering;
  `door-integration-opening.png` hides ONLY the wooden leaf, retaining the arch.
  These review artifacts do not establish user approval or exact fidelity.
- The leaf v3 was rejected as stylistically detached from the masonry. The v4
  PNG repaints its wood in quieter brown planes and its fittings in darker,
  less reflective iron. Its whole native-alpha silhouette is uniformly scaled
  to the previous visible footprint. Inspect `door-style-comparison.png` and
  the 2x capture; style acceptance remains visual, not a numeric test result.
- The broad aperture was redrawn: measured alpha spans are now 107 x 119 px,
  versus the rejected 118 x 113 px. `door-proportions-comparison.png` shows
  original / broad doorway / current study at the same capture scale. The
  capture regression rejects an aperture width/height ratio outside 0.70–0.90;
  this geometric guard does not establish fidelity to the reference artwork.
- Study torch instances use uniform scale 0.36 (25% smaller), with feet
  at (160,225)/(460,225), symmetric at +/-150 px around the visible arch axis
  x=310. Their light centers follow at y=176.25. The focused capture checks
  spacing against both visible jamb edges (2 px tolerance), equal torch height
  and scale, and following lights. Inspect `torch-spacing-comparison.png`.
  This override
  belongs to ReferenceCalibration; the shared torch scene retains scale 0.48.
- `scenes/SixRoomPreview.tscn` is the main scene: six rooms, 255 floor cells,
  96 px logical cells, 3008 x 2048 px composition. It uses complete Sprite2D art,
  overlapping whole floor substrates and appropriately placed walls/piers.
  There is no gameplay, procedural generation, animation or save system.
- The artistic reference remains
  `assets/dungeon/perspective/reference-atlas.png`. Main production rendering
  no longer samples it. `scenes/PerspectiveRoom.tscn` preserves the historical
  source-frame (0, 120, 560, 510) study and its old polygons; do not reuse that
  cutout pipeline for production. The rejected low-wall/side-door experiments
  and `docs/reference/approved-scene.png` are historical, not perspective targets.
- Side-wall cores and outside backing MUST be separate sprites. The user rejected
  the baked side row because it crossed right-angle junctions. Cores are 68 px;
  outside stones are 24 px with 2 px overlap, only on exposed spans. Stop backing
  before horizontal facades and corner piers; it may continue behind straight-run
  buttresses. Do not restore a baked exterior row or rotate masonry faces.
- The rejected implementation repeats caps with south-facing lips and stops
  their runs at upright piers, filling gaps with short caps. Do not treat this
  assembly rule as an approved art requirement. Its current nominal wall body
  heights are 117 px north, 101 px south and 191 px at the entrance; corner piers
  are 68 px wide and side buttresses 76 px. These are implementation measurements,
  not validated reference proportions. Preserve uniform scale and open passages.
- The north entrance remains at logical cell (3,3). Door body bottom is (546,454).
  Preserve the 22 px continuous floor underlay. Whole entrance wall ends are
  hidden under corner columns and their middle join behind the arch.
- `DungeonTorch.tscn` uses true alpha, imported at 256 x 384, scale 0.48,
  offset (-128,-321), feet at (430,454)/(662,454). Two static lights use mask 2.
  Floors and walls receive that mask; fixtures/piers keep their painted light.
- `Dungeon/Heart` is the authored `DungeonHeart.tscn` at (2368,784).
  Its generated complete PNG depicts the approved square pedestal/vortex design.
  It has one sprite and one static light. Rebuilds preserve the authored instance.
- `stone_variation` defaults to true with seed 173. Six complete floor variants
  in three proportions and two north/south variants provide art variation.
  Per-stone tints are deterministic. Disabling variation selects variant zero
  and white top-surface tint; geometry and sprite count stay the same.
- Default counts: 852 generated sprites, two torches, one heart sprite and three
  lights = 858 inspectable elements. The masonry includes 99 side-core and 102
  separate outside sprites. F3 has 644 unchanged fixed spatial probes. Picking
  ignores alpha below 0.5; source PNG path, atlas region and local UVs are exported.
  The editor refresh interval is 0.5 s; no periodic inspection runs in play mode.
- For rendering changes run `tools/test-mobile.ps1 -All -Capture`; inspect
  `artifacts/dungeon-2d.png`, `six-room-details.png`,
  `vertical-wall-details.png`, `alpha-joins-2x.png`,
  `entrance-seams-detail.png`, `heart-detail.png`,
  `stone-variation-before-after.png`, `wall-projection-comparison.png` and
  `reference-comparison.png`. The wall comparison shows entry/upper room at
  the same camera scale; it is not a pixel comparison with the original art.
- `verify_wall_layers.gd` checks independent exterior layers, no overlap with
  corner/horizontal-facade spans, and no core stones underneath pier faces.
- Native-alpha regression checks source alpha, absence of production polygons,
  materials/clipping and nonuniform scales, plus transparent atlas boundaries.
  GPU checks compare alpha compositing at 599 map, 3828 entrance and 2809 heart
  samples with lights disabled, tolerance 4/255. These derive textures/transforms
  from the scene and are not independent proof of approved geometry. Fixed
  spatial probes and visual inspection are complementary.
- The reference comparison measures only the historical entrance study.
  Arbitrary layouts, side entrances, memory profiling, mobile exports and touch
  controls remain unvalidated. The old gameplay/assets are in Git at v1.0.0;
  do not restore them as dependencies of this foundation.
