# Dungeon Master --- Game Design Document

> **Status:** Living design specification\
> **Purpose:** Source of truth for development agents and contributors.\
> **Prototype baseline:** Godot 4.x, GDScript, mobile + desktop.
> **Last implementation audit:** 2026-10-03, mobile/2.5D prototype.
>
> **Reading rule:** Section 0 specifies the implemented game, including
> temporary playtest settings and known limitations. It takes precedence
> over broad intentions in sections 1-31. Parties, campaigns, research,
> additional classes and other explicitly future features are not promises
> about the current build. Visual assets alone do not imply implemented AI.
>
> **Maintenance rule:** Every change to gameplay, balance, state transitions,
> controls, persistence or test overrides must update this document in the
> same change. Update the relevant rule, not just a change log. Preserve the
> distinction between implemented behavior, future design and known issues.

## 0. Implemented prototype rules and states

This section describes the current mobile interface, also used by the desktop
2.5D build. Older desktop test harnesses still exercise some legacy commands.
The authoritative implementation is in `scripts/game/dungeon_sim.gd`,
`scripts/game/raid_director.gd`, `scripts/game/game_types.gd`,
`scripts/game/core_progression.gd` and `scripts/mobile/`.

### 0.1 Scope and active test configuration

- One persistent dungeon on a 16 x 16 grid; one adventurer per raid.
- Four simulated classes: Vulpin Thief, Lithide Paladin, Batrafian Ranger,
  and Sable Mage (rendered using the Mycean mage model).
- `testing/vulpin_only=true` currently forces every new raid to use the
  Vulpin. This does not change its traits, stats, loot or behavior. A hero
  already in a running raid is not replaced. Disable the setting to restore
  the normal roster; restart the application after editing project settings.
- `testing/unlock_defenses=true` currently bypasses level requirements for
  defenses. Costs, charges and effects remain normal. This override does not
  grant XP and is not saved as permanent progression.
- Nocturne Priest, Saurian Warrior/Scalelord and other preview models do not
  currently spawn through the raid director. They have no additional raid
  rules. Generic Warrior, Priest, Barbarian and Sapper rules remain future
  design, not implemented classes.
- Persistent individual visitors earn expedition XP and can return at higher
  levels; death is permanent. Details are in section 0.5.
- No parties, defensive creatures, research simulation, kingdom generation,
  multiple active dungeons or offline raids.

### 0.2 Session state machine

| State | Entry and available actions | Exit |
| --- | --- | --- |
| Core anchoring | New dungeon: all rock, 320 gold, 100 Core HP, no entrance or vault. Preview a 2 x 2 Core at an even grid origin, entirely inside the map. Placement is free and requires confirmation. | Confirm a valid Core footprint. |
| Dormant preparation | Core placed; excavate outward and build storage/defenses. No raid while the entrance is absent or storage capacity is below total gold. | Core + entrance + enough storage makes the dungeon raid-ready. |
| Ready preparation | 25-second raid countdown. Build, repair, collect loot, absorb corpses or transfer gold. Manual Raid command uses the same readiness requirements. An active placement selection suspends the automatic countdown. | Timer expires or player starts a raid. |
| Raid | One hero enters at the entrance. Building, digging, repair, transfers, collection and corpse absorption are locked. Camera observation and pause remain available. | Hero dies, departs, is banished or destroys the Core. |
| Result | Show killed/escaped, gold carried out, remaining loot, damage, Core HP and progression rewards. Rewards are granted once per raid ID. Countdown is stopped. | Preparation, or new dungeon after defeat. |
| Pause / focus loss | Cancel pointer gestures; stop gameplay timers and hero simulation. Returning focus does not silently resume. | Resume the paused game. |
| Chest transfer dialog | Preparation only. Pauses the countdown while choosing a destination and amount. | Confirm transfer or close without moving gold. |
| Defeat | Core reaches 0 HP. Construction and normal raid progression stop. | Start a new dungeon, keeping persistent XP/unlocks. |
| Restart confirmation | Right-side restart command opens a confirmation; no immediate reset. | Cancel resumes; confirm clears layout, treasury state, corpses, loot and raid knowledge, then returns to Core anchoring. XP and level remain. |

Closing the application does not simulate elapsed raids. There is no saved
mid-animation continuation: loading restores a saved dungeon snapshot in
preparation (or defeat recovery), not the active hero and its timers.

### 0.3 Construction and interaction rules

| Action / structure | Gold cost | Initial state / constraint |
| --- | ---: | --- |
| Dig rock | 5 per cell | Cardinally adjacent to an open cell; protected rock beside the entrance cannot be dug. |
| Vault / chest | 0 | 150 gold capacity, on excavated ground. |
| Locked chest | 40 | Same 150 capacity; Vulpin must pick its lock before stealing. |
| Magically sealed chest | 80 | Same 150 capacity; only a Mage can remove the seal; normally Core level 4. |
| Spikes | 35 | 3 charges. |
| Snare | 30 | 3 charges; normally Core level 2. |
| Void | 45 | 1 charge; normally Core level 3. |
| Normal door | 40 | 60 HP. |
| Magic door | 80 | 60 HP; normally Core level 4. |
| Entrance | 0 | One permanent entrance, backed by rock/map boundary with an open passage in front. |
| Targeted door repair | 15 | Restore 60 HP and close/reseal an opened or broken door. |
| Chest protection restoration | 15 | Relock/reseal an opened protected chest; never changes its capacity or moves its contents. |
| Trap repair | 10 per restored charge | Restore as many missing charges as available gold permits. |

Placing the 2 x 2 Core also excavates a mandatory one-cell-wide access ring,
including the four diagonal corners, for free. The preview includes this floor
and its enclosing walls. The ring is clipped to the map: 12 floor cells in the
interior, 8 at an edge, 5 in a corner. Existing map boundaries remain solid;
no out-of-map cells are added. Heroes can reach the opposite side without
crossing the solid Core. Normal/magic doors and the directional entrance are
forbidden on this ring. Walkable vaults and traps remain allowed. Clearing a
structure leaves floor, never rock, so it cannot close the passage.

Core and entrance cannot be overwritten. Selecting a building on rock does
not silently excavate it. A new door requires opposite solid neighbors on
one axis; map edges count as solid walls. A valid corridor gap must not be
rejected merely because it is near the map boundary. Structures occupy one
logical cell; the Core occupies four. Replacing a structure clears its old
door/trap state and charges the new construction cost, without refund.

During preparation, with no construction tool selected, all currently diggable
rock cells are marked with four small gold corner brackets (no continuous green
grid, repeated pickaxes or repeated price labels). All brackets share one world
height, independent of the individual rock mesh: wall height when walls are shown,
cutaway height when hidden, plus a 0.025 visual offset. Hover, clicks and drag
target the displayed marker polygons; chest interaction retains priority.
A click digs valid rock immediately for 5 gold,
without selecting a digging tool or confirming. Holding and
dragging digs successive valid cells; revisiting an already dug cell does
not charge again. It stops making changes without sufficient gold. A drag
does not demolish existing structures, dig through interface panels or move
the camera. Right-button dragging still pans; pinch zoom is not a dig gesture.
Choosing a construction tool suspends excavation and its highlights; returning
to the category menu cancels placement and restores direct digging. Opening a
category without selecting a tool does not suspend digging. Pause, raid, defeat,
result and transfer dialogs disable excavation. Highlights share the exact dig
validation (adjacency, entrance supports and available gold). Chest clicks open
transfers first; ground loot remains collectible and clicking a corpse offers
explicit absorption confirmation without a Core menu.
Other construction tools retain preview and confirmation. Trap placement previews
reuse the actual armed mechanism and floor artwork in world space, translucent
and at final scale/orientation, without spending gold or modifying the grid.
The outline projects the four real tile corners at floor height rather than a
fixed screen diamond. Cancel, raid start or tool changes hide the preview.
Trap menu icons are never stretched over the selected tile. Legacy/single-cell
clearing of an existing structure is distinct from continuous excavation.

Dig hover uses the same picked cell and validity check as excavation. Only a
currently diggable target has brighter gold corners, a faint fill and a compact
pickaxe + "5 or" hint. Invalid rock, including inaccessible cells and insufficient
funds, shows neither a red marker nor a price on hover or click. Invalid clicks
do not open confirmation or change the dungeon. The hint ignores pointer input
and avoids screen edges/UI panels.
The corner marks follow camera projection and block height. Hover feedback
disappears over UI/outside digging mode and never opens confirmation.

### 0.4 Gold, vaults, loot and transfers

- All three chest types occupy the same traversable VAULT cell and provide 150
  capacity. Protection does not block corridors or the mandatory Core access ring.
  Standard chests remain free; locked and magically sealed variants cost 40/80.
  Existing chests can be upgraded in place: standard to locked costs 40, standard
  to magic 80, locked to magic 40. Purchases debit the normal treasury; they never
  relocate the chest or redistribute its contents beyond normal expense debits.
  Downgrades and repeated purchases of the same tier are rejected. An upgrade
  installs an intact protection; rebuilding the same tier cannot relock for free.
- Protection states are standard/unprotected, locked/intact, magic/intact, and
  opened (with the purchased tier retained). An opened protection stays open after
  the raid and through save/load. During preparation, the chest management dialog
  offers relocking/resealing for 15 gold, only when needed and affordable. Upgrades
  and repairs are blocked during raids/defeat. Removing a chest clears its lock
  state; restarting clears all chest protections. Owner transfers stay free and
  work regardless of protection, without opening or resetting it.
  Opened chest protections count in the raid's damaged-structure summary.
- Starting gold is 320, but no vault is prebuilt. Until the player builds
  enough free vaults, some starting gold is unstored and raids are disabled.
  This is a setup exception, not an invisible loot pile that heroes can rob.
- Each vault has its own persistent balance, between 0 and 150. Initial/legacy
  allocation fills vaults in grid order. Once assigned, balances are preserved;
  treasury gains, spending and vault removal are reconciled in grid order.
- Paid actions spend the dungeon treasury; the player does not choose a
  payment chest. Removing needed storage spills gold exceeding remaining
  capacity into a loot bag on the removed cell. Remaining capacity may receive
  reallocated gold. No gold is created by a transfer.
- Click a chest's visible image or its gold badge, even with Bâtir open, to
  manage it. Picking respects the sprite's opaque area, including the lid,
  rather than selecting a neighboring rock behind it.
- Transfer: select another vault and an integer quantity, or use Tout transférer.
  The actual amount is limited by source balance and destination free space.
  Empty source, full destination, identical/invalid cells or nonpositive amount
  move nothing. Transfers are free, preparation-only and saved immediately.
- Vault sprites distinguish empty/nonempty stock; the gold amount and circular
  gold-to-gray gauge show the exact balance and remaining proportion.
- Hero-carried starting loot, stolen gold and ground bags are distinct from
  the player's stored treasury. A corpse leaves a separate bag at its location.
  Player collection deposits only what fits; excess stays in the bag.
- Every hero can pick up bags on its current cell. This is currently immediate
  and not limited by the Vulpin's chest-stealing capacity.
- There is no Essence currency implementation despite its appearance in concept art.

### 0.5 Shared hero rules and selection

Each visitor has a persistent unique ID and personal name, class, trait, rolled
base stats, cumulative XP and personally discovered cells. Recruits start at
level 1 with zero XP. Surviving visitors can return; dead individuals are removed
permanently and their IDs are never reused within the dungeon.

Each raid has a 50% return branch and a 50% recruit branch. Returning candidates
exclude the previous raid's ID; if none are eligible, recruit instead. Two distinct
heroes of the same class may visit consecutively, but one individual cannot.
Returns select among nonempty class groups with weights 1/1/1/(1+mage pressure),
then uniformly within that class. New recruits use the existing class roll below.
Returners start at full HP, with their original stat rolls and personality. Each
visit rolls fresh starting gold and resets route/action timers, ignored targets,
lock attempts and loot counters. Old stolen gold is not a persistent wallet.

For recruits without the Vulpin-only override, each class has 25% probability at zero mage
pressure. With pressure P >= 0, Vulpin, Lithide and Batrafian each have
probability 1/(4+P), and Mage has (1+P)/(4+P). Selecting a Mage consumes the
pressure. A non-Mage who leaves after being blocked by a magical door adds
one pressure. A Vulpin abandoning a magically sealed chest sets the same blocker
flag and contributes the same single pressure on escape, not one per chest.
Vulpin-only testing filters both recruits and returners without consuming pressure
or deleting other classes' profiles. Any actual Mage entry consumes pressure.

Base values before individual variation:

| Hero | HP | Starting carried gold | Chest steal capacity | Fear weight | Trap weight | Flee HP fraction | Patience turns | Normal-door damage |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Vulpin Thief | 68 | 80-150 | 90-160 before greed multiplier | 1.20 | 1.00 | 0.45 | 90 | 18, normally uses lockpicking instead |
| Lithide Paladin | 115 | 140-240 | No chest theft | -0.25 | 0.55 | 0.15 | 140 | 34 |
| Batrafian Ranger | 82 | 95-175 | No chest theft | 0.75 | 1.55 | 0.40 | 70 | 20, normally avoids closed doors |
| Sable/Mycean Mage | 74 | 110-190 | No chest theft | 0.45 | 0.85 | 0.30 | 110 | 8 |

Every new recruit selects one trait with equal probability (returns retain it):

| Trait | Fear modifier | Trap modifier | Greed multiplier | Flee fraction modifier | Patience modifier |
| --- | ---: | ---: | ---: | ---: | ---: |
| Greedy | -0.30 | -0.20 | 1.40 | -0.08 | +15 |
| Cautious | +0.50 | +0.40 | 0.85 | +0.10 | -10 |
| Stubborn | -0.20 | -0.10 | 1.00 | -0.12 | +35 |
| Cowardly | +0.70 | +0.50 | 0.90 | +0.15 | -25 |

Recruit variation: HP +/-6 (minimum 20); fear/trap weights +/-0.20 after trait
modifiers (trap weight minimum 0.05); greed +/-0.15 (minimum 0.15); normal-door
damage +/-3 (minimum 4); flee fraction +/-0.05, clamped to 0.05-0.80; patience
+/-10 after its trait modifier, minimum 25. Vulpin steal capacity is the rounded
base roll multiplied by greed. Non-thief classes never rob vaults, irrespective
of their unused internal capacity value.

All heroes move cardinally, normally one cell per 0.48-second decision interval.
Walking/running clips loop and their playback rate follows actual horizontal
travel speed and rendered hero scale (1.4 in the mobile view), so planted feet
do not slide along with the character. This also applies to timed approaches
to traps/chests/the entrance and the exit threshold. Stationary heroes hold
their locomotion pose; interaction, jump and death clips keep their own timing.
Each walking step records its source cell, so the first rendered frame starts
at the entrance even if simulation has already selected the adjacent cell.
New raid visuals reset their interpolation rather than reusing the previous hero.
They inherit the kingdom's remembered tile types and discover a square radius
of 2 cells, or 3 for Ranger. Current perception is not wall-occluded line of sight:
nearby tile types can be learned through walls. There is no fully implemented
wealth-signal/uncertain-value perception model yet.

Navigation first routes toward a remembered objective, then unexplored frontiers,
then least-visited cells, with local fallback. Routes use known cells, while actual
walkability checks enforce physical walls, entrance direction and solid Core.
The route cost is at least 0.05 and consists of base 1, revisit penalty
min(visits * 1.5, 6), trap cost 6 * trap weight, door cost 2.5, corpse danger *
fear weight and a per-cell random bias of 0-1.2. The trap cost depends on
remembered trap type, not remaining charges, but a trap already triggered during
this raid has no hazard surcharge. Costs discourage hazards but
do not make them impassable. Corpses with fear 18 contribute danger 1.8 on
their cell and 0.9 one cardinal cell away. Negative fear can attract a hero.

Heroes flee toward the entrance when HP/max HP reaches their individual flee
threshold, or hidden morale reaches 20 or less. Fleeing is sticky for that raid.
Completing an objective (including the final useful theft or a Core strike),
or having no useful exploration step, also starts the return on foot. The hero
routes directly to the known entrance and no longer seeks or opens chests.
There is no morale-based teleport. The unchanged raid map retains the way in;
an invalid/debug layout without a known return path aborts the raid without
counting an escape, carried-out gold or hero XP, rather than inventing an exit.
Arrival at the entrance takes the normal 0.48 seconds, followed by 0.48 seconds
of movement through the threshold, with no town portal. Only then are escaped,
carried-out gold and individual XP committed. A return can cross a fresh trap
and end in death, leaving the carried gold on the floor. Void absorption is the
sole magical-departure exception. Core destruction ends the defeated run at
once, without granting a successful hero departure. Successful departures merge map
knowledge; death does not. Changed constructions/repairs/transfers invalidate
the relevant remembered cells, rather than erasing all kingdom knowledge.

#### Hidden morale and personality

Each hero begins every raid at 100 morale, including returning veterans. Morale
is clamped to 0-100, has no passive regeneration and no level modifier. It is
transient raid state, not saved in the persistent roster, and never shown as a
player-facing bar or number. The permanent personality still affects routing
and the independent low-HP retreat threshold. Fear costs decide which route to
take; morale decides whether to continue the expedition.

Base events (only real outcomes, not animation starts):

| Event | Morale change |
| --- | ---: |
| Damage actually suffered | -1 per percentage point of maximum HP lost |
| Snare immobilization | -8 in addition to its damage |
| Discover a corpse | -10 once per body per raid |
| Failed ordinary door/chest lockpick | -6 per failed attempt |
| Successful ordinary lockpick or magical unsealing | +5 |
| Actually withdraw chest gold | +10 per theft action, none for an empty chest |
| Deal positive damage to the Core | +10 |
| Ten movements without progress | -3, then restart the ten-movement count |

| Permanent trait | Morale modifiers |
| --- | --- |
| Greedy | All losses x0.85; successful theft gives +20 instead of +10 |
| Cautious | Damage, snare and corpse losses x1.2; stagnation x1.5 |
| Stubborn | All losses x0.7, except failed lockpicks which cost exactly 2 |
| Cowardly | Damage, snare and corpse losses x1.5; gains unchanged |

Corpses use the existing square perception radius (2, or 3 for Ranger), without
wall occlusion. Previously inherited map knowledge does not mean the hero has
already seen a body this raid. Multiple bodies on one cell count separately;
revisiting a body does not apply its loss again. Traps already sprung this raid
do not apply damage or morale loss again. Void retains its expulsion behavior.

Progress resets stagnation without restoring morale: discovering a cell this
raid, first traversing a cell, damaging/opening an obstacle, taking actual gold
(including a ground bag), or damaging the Core. Repeated walks over familiar
cells without such progress count toward stagnation. A Ranger jump counts as
one movement; animation frames, immobilization and lockpick waiting do not.
Discovery on the tenth movement resets the counter before any penalty.

Morale at or below 20 immediately commits the hero to retreat, cancelling further
lockpick retries; recovery cannot reverse that decision. Existing animations
and snare immobilization finish normally, then the hero returns on foot. Fresh
traps on the way out still work. Death takes precedence over retreat. Objective
completion/full bags and low HP retain their own retreat rules.
Both route planning and local choices exclude doors the hero has abandoned
(and intact doors a Ranger will not open). Retreat uses already traversable
passages rather than trying a new locked-door shortcut, even when the detour
has a higher revisit cost. This prevents a failed lock from stalling a raid.

The legacy `patience` values in the tables above are still generated and saved
for roster compatibility, but no longer trigger retreat. Stagnation replaces
that fixed turn limit. Neither morale nor corpse/stagnation memories persist
between raids; personality and existing XP/identity rules remain unchanged.

#### Individual expedition XP

Commit XP exactly once when departure alive completes, never when a theft,
lockpick, return walk or threshold animation starts. Death grants none of the pending XP.
Void banishment is still a living departure with carried loot, not death, and
therefore grants XP and permits a later return. An aborted/reset raid grants none.

| Completed accomplishment | Hero XP |
| --- | ---: |
| Departure alive | 10 |
| Gold acquired inside the dungeon and carried out | floor(amount / 5) |
| Door/chest successfully picked | 15 per lock |
| Door destroyed or magical seal removed | 15 per obstacle |
| Actual Core HP removed | 1 per HP |
| Personally newly perceived cell | 1, at most 20 per raid |

Starting possessions and previously stolen gold give no gold XP. Both vault
withdrawals and recovered ground bags count, once, only if actually carried out.
Failed attempts, empty vaults and repeated callbacks give no action XP. One
obstacle cannot pay twice in a raid. There is no XP simply for triggering traps.
Discovery is personal, separate from inherited kingdom navigation knowledge:
only cells actually perceived by this hero count. All observations are retained,
including those beyond the 20 XP cap, so revisits and rebuilt cells cannot farm
discovery XP. Perception still uses the current square radius, not wall occlusion.

Advancing from level L to L+1 costs 50*L additional XP. Cumulative thresholds
are 0, 50, 150, 300, 500, 750, ... (25*L*(L-1)). Retain excess XP and allow
multiple gains on one departure; new abilities apply next raid. Vulpin lockpick
progression is the only current level-based skill. Other classes earn levels but
have no new HP, damage or speed scaling. Core/player XP and rewards are separate.

### 0.6 Vulpin Thief

Objective is vaults, never attacking the Core. The solid Core is not a route
through the room. Empty vaults are marked ignored for that raid. If no known
vault objective and no unexplored frontier remain, the Vulpin heads for the exit.

A normal door on the route triggers a 3.0333333-second lockpick attempt.
Doors are obstacles, not independent objectives: reachable known treasure takes
priority over unrelated doors. Success sets door HP to 0 and marks it opened,
not smashed. Normal doors and locked chests share this level progression:

| Hero level | Attempts per lock per raid | Success per attempt |
| --- | --- | --- |
| 1 | 1 | 50% |
| 2 | 1 | 55% |
| 3 | 2 | 55% |
| 4 | 2 | 60% |
| 5 | 3 | 60% |
| 6 | 3 | 65% |
| 7 | 4 | 65% |
| 8 | 4 | 70% |
| 9 | 5 | 70% |
| 10 | 5 | 75% |

Attempts = 1 + floor((max(1, level) - 1) / 2). Success probability =
min(75%, 50% + 5% * floor(max(1, level) / 2)). Odd levels keep adding an
attempt beyond level 10; probability stays capped at 75%. Missing level means 1.
Each failed attempt consumes that lock's budget. Revisiting does not reset it;
a new raid does. Different locks have independent budgets. After exhaustion,
the door is avoided and another route is sought. Magical doors cannot be
picked at any level; they are avoided and remembered as blockers.

A locked chest uses the same duration and progression. No chest gold is removed
during lockpicking, and the hero stays still until the attempt completes.
Success opens the protection, then normal theft rules apply. Exhausting its
budget marks that chest ignored for the rest of the raid, without making its
tile impassable. Magic chests are
ignored while their seal is intact; the Vulpin can cross their tile but cannot
steal from them. With Vulpin-only testing enabled, those seals cannot be opened
by a spawned hero. Opening an empty chest never starts a collection animation.

Vulpin cannot jump or disarm traps at any level. It walks across unavoidable
traps and triggers them only after the normal 0.48-second visual arrival.
Imported Vulpin jump assets may remain for animation previews, not gameplay.

Walking into a vault waits for the 0.48-second visual arrival before resolving
its interaction. There is no additional movement recovery on arrival: empty
vaults and vaults crossed during retreat do not interrupt walking. Collection,
lockpicking and magic-opening actions retain their own timers. Theft reads the
actual balance of that vault, not the total treasury or another vault.
When an interaction is possible, arrival interpolates directly to the position
0.34 cell before the vault center along the approach direction. The same position
is retained through lockpicking and collection until the first return step; the hero does
not walk to the center then snap backward. Empty/unusable vaults remain normal
walk-through cells. Mage approaches to sealed chests use the same arrival anchor.

| Vault encounter | Current result |
| --- | --- |
| Empty | Ignore it and continue; no collection animation and no gold change. |
| Some gold, but not enough to fill the remaining bag and not the last treasury gold | Take that amount immediately, debit that vault, update carried/stolen counters and continue toward another vault. No long collection animation in this partial-theft branch yet. |
| Enough to fill the bag, or taking the last treasury gold | Start 181/30 seconds (about 6.033 s) of collection after arrival. Keep gold visible in the vault during the gesture. At completion withdraw the pending amount once, update stolen/carried counters and begin walking back to the entrance. It is not yet carried out or a successful escape. |
| Bag already full on encountering a nonempty vault | Begin the return walk without pretending to collect more. |

Starting carried loot does not consume the separate chest-steal allowance.
Ground bags also bypass that allowance. HP/morale can cause an earlier retreat.
Once fleeing, a Vulpin does not start a new chest theft or lockpick, even when
standing on a chest. Ground bags encountered on its return route are still
picked up, but it does not detour to seek them.
At zero HP, Vulpin plays a 1.5-second death animation before producing body/loot.

### 0.7 Lithide Paladin

Objective is the Core. It does not steal from vaults, but can pick up ground bags.
It cannot jump traps. Spikes deal 20 rather than 30 damage; snare/void rules are
otherwise shared. Its base negative fear weight can favor corpse-marked routes,
but a cautious/cowardly trait can change that preference.

At an intact normal door it performs a 76/30-second hammer attack (about 2.533 s),
then applies its rolled door damage. Before locating the Core it limits attempts
on an unknown door to two; after a Core objective is known this exploratory limit
does not apply. It cannot open an intact magic door and searches elsewhere.

From beside the solid Core, it plays the same strike duration, deals 42 integrity
damage, then departs. This is one Core strike per successful raid, not repeated
attacks until the Core dies. Its death restores 5 Core HP.

### 0.8 Batrafian Ranger

Objective is exploration rather than a fixed treasure/Core goal. Perception
radius is 3 instead of 2. It uses the shared frontier/least-visited routing and
has a higher base trap avoidance weight. It alone can jump a known, charged
adjacent trap when the planned route continues straight beyond it. The landing
must be walkable, not behind an intact door, not solid Core and not another
charged trap. The jump skips one tile, moving two cell centers; it cannot skip
a turn. Two consecutive active traps prevent this shortcut.

Jump state lasts 1 second. The logical destination is recorded at takeoff;
landing effects wait for reception. Rendering interpolates from jump_from,
removing imported horizontal hip travel to prevent double movement. The skipped
trap loses no charge. Reception clears the old movement cooldown, with no extra
0.48-second walk-in-place delay. It refuses intact doors rather than
forcing them; opened/broken passages remain usable. It does not rob vaults.

Important current behavior: exploration is not immunity from Core aggression.
Unlike Vulpin, Ranger is allowed to attack the Core if its movement brings it
into contact with the target. That contact deals the generic 24 damage, followed
by departure. It has no special delayed Core-strike animation. Death restores
3 Core HP. Surviving departure reports its explored map to kingdom knowledge.

### 0.9 Sable/Mycean Mage

Objective is the Core. It does not jump traps or rob vaults. Normal doors take
its rolled damage on each attack opportunity, without the Paladin strike hold.
It opens an intact magical door with a 1.5-second ritual, sets HP to 0 and the
opened flag, and clears mage pressure. Core contact deals 24 integrity damage,
then it departs. Death restores 2 Core HP. There are no ranged damage spells,
healing allies or projectile combat mechanics in the current raid simulation.

On encountering an intact magically sealed chest along its route, the Mage waits
for visual arrival, then channels the same 1.5-second arcane-opening ritual.
Completion removes the seal and clears mage pressure, but takes no chest gold.
The Mage continues toward the Core; it does not specifically hunt chests and
does not pick normal chest locks. An opened chest can be robbed by a later
Vulpin unless the player restores its protection in preparation.

### 0.10 Defenses, death and action sequencing

| Defense | Trigger / result |
| --- | --- |
| Spikes | First activation of the raid consumes one of 3 charges and deals 30 HP, or 20 to Paladin. |
| Snare | First activation of the raid consumes one of 3 charges, deals 16 HP and holds movement for 3 seconds. The hold does not repeatedly consume charges. |
| Void | Arrival consumes its single charge, starts absorption/portal departure and removes the hero with all carried gold. Counted as escaped, not killed; no corpse or healing. |
| Already activated this raid | Remains visibly sprung until raid end. Further passages cause no damage, hold or charge consumption. Rangers do not jump over it. |
| Exhausted trap | Remains on the floor but inert until repaired. Its last-charge activation remains visibly sprung until raid end, then becomes spent. |
| Normal door | Intact HP blocks movement. Damage reduces HP; destruction opens passage. Vulpin opening uses the separate opened flag. |
| Magic door | Blocks non-Mages; a Mage ritual opens it. Opened/broken doors remain passable until repaired. |

Normal movement onto a trap uses a 0.48-second arrival timer: no damage, charge
use or active trap effect before the hero visually reaches the tile. Spike arrival
has no movement recovery: survivors keep walking, whether the spikes are armed,
already sprung or exhausted. Lethal damage still interrupts movement for death.
Other trap arrivals retain a 0.12-second recovery, replaced by the 3-second snare
hold where applicable. Ground bags are picked up before the tile's trap is resolved.
Per-raid activation memory is transient and clears with the hero at raid end or
reset; it is not saved. At the next raid, traps with remaining charges are armed
again. Charges themselves remain spent across raids. Fresh traps on the return
route use the same arrival, damage, hold or banishment rules as on the way in.

Logical action states are: moving/exploring, fleeing, awaiting trap/vault arrival,
jumping, snared, lockpicking, door striking, arcane opening, Core striking,
collecting, dying, returning to the entrance, crossing its threshold, and void
absorption. Timed actions suspend normal
route decisions. No collection may overlap a jump. Arrival/landing must finish
before its destination effect; after completion the next action resumes without
replaying the previous one. Void absorption lasts 1.15 seconds.

Non-Vulpin lethal trap damage immediately creates a corpse and loot bag; Vulpin
does so after its death animation. Automatic death healing is Vulpin/Mage +2,
Ranger +3, Paladin +5, capped at 100. Absorbing a corpse in preparation removes it
and grants another +2 Core HP; it does not automatically collect its separate bag.
Corpses cannot be freely dragged. Core HP reaching 0 is defeat, not negative HP.

Targeted repair buttons are preparation-only and disabled without funds. A trap's
badge exposes repair when exhausted; the underlying repair command can refill
any missing charges. Door badges expose repair when broken or opened, restoring
and closing either door type. The older global Repair action differs: it repairs
damaged, non-destroyed normal doors and refills traps; it is not the targeted
broken/magic-door repair contract.

### 0.11 Progression, results and persistence

Core levels use cumulative XP thresholds 0, 60, 150 and 280 (levels 1-4).
Level 4 is currently maximum. Normal unlocks are Snare at 2, Void at 3 and
Magic Door and magically sealed chest at 4; current playtest override makes them
all selectable immediately.

Each unique raid result grants XP: +20 if Core survives, +25 if a hero was killed,
+10 if carried_out is zero, +10 if Core lost no HP, and +5 per trap charge spent
up to three charges. These XP conditions are additive, not mutually exclusive.
Raids never grant automatic gold rewards, regardless of survival, kills or
protected treasure. Hero deaths leave only their actual carried gold as ground
loot, which must be collected; no kill bonus is added to the treasury.
Carried_out includes a hero's original possessions, not only stolen player gold.
Zero treasury gold is not defeat and does not prevent raids when the usual Core,
entrance and storage prerequisites are met. Heroes may still die and leave
recoverable gold. The result shows available treasury gold separately from ground
loot, with no gold reward line. Existing saves retain their current balances;
previously awarded gold is not retroactively removed. Result IDs prevent double
claiming XP; restarting preserves XP and last rewarded raid ID.

`MobileSave` version 1 stores grid, total gold, per-vault balances (`vault_gold`),
Core HP, door HP/open flags, trap charges, corpses, loot bags, game_over, kingdom
knowledge, raid index, mage pressure and progression. It validates types, bounds,
and optional `hero_roster` data (living profiles, next ID, previous visitor ID).
Profiles store personal discoveries and base stats; level is derived from XP.
An absent roster in a legacy save means no returning visitors. Invalid roster
data rejects the entire load before mutating the game. A previous ID may identify
a dead hero without requiring a living profile. File limits remain enforced;
save failure is surfaced rather than silently dropping survivors. It also validates
and optional chest protection dictionaries (`vault_locks`: tier 1/2,
`vault_opened`: boolean for a protected chest). Missing dictionaries in legacy
saves mean standard, unprotected chests. Opening is saved with raid results;
upgrading/relocking is saved immediately. Invalid tiers, keys, or orphan opened
flags reject the save before mutating the simulation. Existing validation covers
tile/structure consistency and treasury balances. Old saves without vault_gold
load with grid-order allocation. Loading opens missing Core access-ring floor
for free. Doors on the ring become floor; their original construction cost
(40/80 gold) becomes recoverable loot on that cell, without changing vault
balances. Trap/vault contents remain intact. Changed cells are removed from
kingdom memory. This migration is idempotent. A legacy entrance on the ring,
or another invalid legacy entrance placement, is relocated outside the ring
to an available wall-backed floor, or removed if none exists, without overwriting
a paid structure. Saves use a temporary file and backup recovery.

Meaningful preparation edits, transfers, targeted repairs and raid results are
saved; a preparation snapshot is saved before a raid. The hero's transient action
state is not serialized. Resume after process exit therefore does not continue a
half-finished jump/theft. Camera, selection and test overrides are not permanent
hero progression; tray preference is a separate local UI setting.
Reloading mid-raid restores the pre-raid roster too: no partial XP is committed.
Permanent death is recorded with completed saved results; this is not an ironman
anti-reload system. Restarting the dungeon clears visitor identities, personal
discoveries and the previous visitor, while retaining existing Core progression.

### 0.12 UI, camera and visual-state contract

- Top panels present gold/capacity, Core HP/level/XP and preparation/raid status;
  header panels align in height. Right-side tools have spacing between buttons.
- Portes/Coffres/Pièges navigation occupies a single bottom row; there is no
  Bâtir or Core category. Portes contains normal doors, magic seals and entrance;
  Coffres contains the free vault, locked chest and magically sealed chest;
  Pièges contains spikes, snare and void.
  Opening a category
  replaces that row with its commands and a back arrow, not a second stacked row.
  A compact collapse control preserves dungeon visibility. Icons have normalized
  visible bounds; the door icon is frontal and depicts one leaf.
- UI uses dedicated artwork rather than dungeon sprites. Menus use illustrated
  fantasy objects matching the mockup: single-leaf doors and their magic variant,
  an open arch, normal/locked/sealed chests, spike mechanism, clawed grasp, void
  plate and violet crystal. Small badges instead use white pictograms: three
  points for spikes, a clawed hand for snare, a spiral for void, a padlock for normal
  doors and a faceted diamond for magic doors and the Core. Gold is the exception:
  the header and chest badges keep the illustrated gold coins with embossed
  diamonds, preserving their proportions rather than using abstract circles.
  Icons dim when depleted; repair tabs and protection markers remain unchanged.
  Menu art has normalized visible bounds and preserved proportions; smooth
  mipmapped filtering also applies to the 28-pixel symbols inside status rings.
  Dungeon artwork and hero portraits remain unchanged; ring colors, depletion
  states, repair actions, costs and save data are unaffected.
- Raid status uses a centered black trapezoid flush with the top viewport edge
  (no decorative top margin), with a thin gold border, an orange
  illustrated skull and one-line `RAID mm:ss` elapsed time, not the raid index.
  The clock resets at each raid start and advances only with the active simulation;
  pause freezes it. It is transient and not saved. Preparation uses the same frame
  with `Prochain raid dans` above `mm:ss`, counting down to the next raid;
  missing entrance/storage and Core anchoring retain their explicit status text.
  On compact viewports the centered banner sits below resources to avoid overlap.
- Gold badges show amount and a gold remaining-stock ring that grays as it empties.
  Protected chests add a small gold lock or violet seal marker, gray when opened.
  The chest itself has a closed locked/sealed sprite while protection is intact;
  opening selects its own stock-dependent full/empty open sprite at the same
  ground anchor. The locked variant keeps a visibly unfastened padlock; the magic
  variant keeps a cracked, inactive gem and non-glowing runes. Neither reverts to
  the standard chest artwork. Relocking/resealing restores the closed sprite;
  transfers change visible contents without reactivating protection.
  Clicking any chest or its badge opens management (transfer, tier upgrades and
  restoration), rather than replacing it with the currently selected structure.
  Traps show a copper charge ring without a number; the repair tab appears when
  spent. Doors show their health ring and repair when open/broken. Core has a
  violet health ring. Badges update after actions and avoid obstructing UI panels.
- The mobile hero HUD is one world-anchored badge above the moving hero: its
  class portrait, a green remaining-HP ring over a gray empty ring, and a tab
  with the hero name and level. The tab fits the measured text with small margins.
  Generated identity suffixes are hidden: `Neris 8` displays as `Neris`, alongside
  a numeric level in a separate muted-gold compartment at the right (no `Niv.`).
  The compartment stays 32 pixels wide as levels change; longer numbers use smaller
  text to fit without moving the name or portrait. Raid messages also use the
  personal name without the identity number.
  Roster IDs and stored names remain unchanged for save compatibility and tracking;
  different individuals may share a visible name without sharing XP or history.
  Long names are ellipsized, the level stays visible, and the portrait remains
  the same size. HP changes do not resize the tab. No numeric HP, top-left hero panel, ground
  selection circle or rectangular health bar. The badge follows interpolated
  movement/jumps, ignores pointer input, hides outside raids and avoids UI panels.
  Structure badges covered by the moving hero badge hide temporarily, then return
  once clear, rather than drawing through its portrait or name.
  Recruits start at level 1; returning individuals display their earned level and
  personal name with their class portrait. Hero XP, its source breakdown and
  level-gain announcements are internal only, not shown in the raid result.
  Player/Core rewards remain visible. No level-based HP/damage
  scaling exists yet. Vulpin lockpicking uses section 0.6. Hero level remains
  independent of Core level and raid index.
- Raid camera does not automatically jump to each hero cell. Following is opt-in;
  Core recenter and hero-follow icons are horizontally centered in their right-menu buttons.
  manual pan disables it. Zoom/orbit remain available; orbit steps are 90 degrees.
  The pre-raid view is restored when leaving the result screen.
- Wall visibility is a viewing mode, not a change to the dungeon grid or routes.
  Cutaway rocks use reduced transforms for picking; exterior rock height variation
  belongs to the full-wall view, not a fake hole around a hidden-wall corridor.
- Exterior rocks use varied modules/formations instead of one repeated block;
  dungeon edges have separation from outer geology. Stone floors/walls, entry,
  single-leaf door frame and Core must read as one material family. Door supports
  align with the flanking walls, not intrude into the traversable corridor. Torches
  should fit their supports without clipping or dominating the entrance.
- A vault has a distinctive full-cell floor treatment blended into adjacent paving.
  Its chest is grounded and centered across camera angles; gold scatter is only
  visible for nonempty stock. It must not appear to float on a detached shadow.
- Spikes, Snare and Void each have a dedicated integrated floor tile. Spikes fit
  their sockets; Snare is a mechanism rather than a fissure decal; Void's inner
  effect fits its floor opening rather than placing a separate rim on the paving.
  Armed, active and exhausted visuals must agree with simulation charge state.

### 0.13 Limits and validation obligations

This is a documented prototype, not a claim that every long-term goal is done.
Notable limits: square-radius perception through walls, immediate partial theft,
no resumed in-flight raid, single dungeon/hero,
and no actual party/creature/research simulation. Do not silently describe these
as more sophisticated systems or change their rules during documentation work.

Behavioral fixes must reproduce the player's layout and state. Use node/skeleton/
animation probes for movement and action timing, with a full visual capture where
relevant. A passing open-room fixture is not sufficient for a wall-backed chest,
door or trap bug. In particular, regression checks cover:

- Zero-cost chest placement, source/destination balances, transfer guards and saves.
- Chest body/lid picking with Bâtir open, multiple camera angles and wall modes.
- Dig click/drag, hover target/validity, UI/pinch protection and per-cell costs.
- All hero/trap arrivals, snare hold, jump landing and no extra post-jump cooldown.
- First-frame entrance placement and continuous chest approach/action transitions
  in four directions, including locked chests (`tests/hero_arrival_motion_probe_test.gd`).
- Vulpin walking trap arrivals (no jump), delayed final withdrawal and no empty-vault theft.
- Alternating level-based lockpicking, independent per-lock raid budgets and
  budget reset on a real new raid (`tests/vulpin_progression_test.gd`).
- Persistent identities, nonconsecutive returns, permanent death, expedition XP,
  personal discovery, save migration and result UI (`tests/hero_roster_test.gd`,
  `tests/hero_return_test.gd`, `tests/hero_experience_test.gd`,
  `tests/hero_roster_save_test.gd`, `tests/hero_progression_ui_test.gd`).
- Normal roster/trait variety independently of manual Vulpin-only test settings.
- Badge state, targeted repairs, raid camera, restart and save migration.

Representative suites: `tests/vulpin_sequence_probe_test.gd`,
`tests/trap_arrival_probe_test.gd`, `tests/mobile_jump_motion_test.gd`,
`tests/vault_transfer_test.gd`, `tests/vault_click_test.gd`,
`tests/mobile_dig_gesture_test.gd`, `tests/mobile_save_test.gd`,
`tests/labyrinth_integration_test.gd`. Run the full suite with
`tools/test-mobile.ps1 -All` after behavior changes. Documentation-only changes
need source/number/link checks; they do not require changing gameplay to fit prose.

## 1. High concept

A stylized dark-fantasy dungeon-building strategy/simulation game in
which the player embodies an unseen Dungeon Master.

The player builds persistent labyrinthine dungeons, stores local wealth
and valuables inside them, prepares defenses, and then watches
autonomous adventurers raid them. During raids the player cannot
intervene. Success therefore comes from architecture, preparation,
deception, risk management, and adapting the dungeon between raids.

The player expands across procedurally generated kingdoms by creating
additional dungeons. Each dungeon has its own resources and persistent
physical state. Losing every dungeon ultimately means game over.

The core fantasy is:

**Build → Prepare → Risk → Observe → Learn → Repair → Expand**

## 2. Design pillars

### 2.1 The dungeon is the player's strategy

The principal strategic object is the dungeon itself. The player should
spend time thinking about:

-   corridors;
-   branches;
-   dead ends;
-   rooms;
-   doors;
-   traps;
-   treasure placement;
-   defensive creatures;
-   vertical floors later in progression;
-   how adventurers perceive and navigate the layout.

There should not be one universally optimal dungeon.

### 2.2 Raids are simulations, not action sequences

Once a raid begins, the dungeon is locked.

The player cannot:

-   build;
-   dig;
-   move objects;
-   repair structures;
-   move corpses;
-   secure loot;
-   change the path while enemies are present.

The player observes the consequences of decisions made during
preparation.

This guarantees that a player watching the raid has no mechanical
advantage over a player who is temporarily unavailable.

### 2.3 Persistent consequences

A raid should leave physical consequences:

-   damaged or destroyed doors;
-   damaged defenses;
-   reduced Core health;
-   dead adventurers;
-   unsecured loot;
-   stolen resources;
-   discovered dungeon information.

The next raid starts from the resulting dungeon state unless the player
repairs or reorganizes it first.

### 2.4 Low-pressure mobile design

The game must respect players who play infrequently.

**Application closed = Dungeon Master absent = dungeon influence dormant
= no raids.**

There are no destructive offline raids.

Non-dangerous timers such as research may continue offline.

Playing more should allow faster progression and more voluntarily
accepted risk. Playing less should slow progression, not destroy
previous work.

Avoid FOMO-based design and mandatory login streaks.

## 3. Core gameplay loop

### Initial dormant state

A newly created dungeon does **not** begin with an entrance.

At the start of a dungeon:

-   the player places the free 2 x 2 Dungeon Core on an initially rocky map;
-   confirmation opens a free one-cell floor ring around that footprint,
    clipped to the map; paid excavation begins outward from this ring;
-   there is no predefined starter dungeon layout;
-   there is no connection to the surface;
-   no raid countdown is active;
-   no adventurer can enter the dungeon.

This gives the player a safe initial construction space without requiring
the game to generate a default dungeon.

The player decides when the dungeon becomes accessible by placing the
**Dungeon Entrance**, represented by a staircase connecting the dungeon
to the surface.

The Dungeon Entrance:

-   costs **no resources**;
-   is placed deliberately by the player on a valid excavated tile;
-   defines the point from which adventurers enter the dungeon;
-   enables the raid system once storage capacity also covers the treasury.

Placing the entrance is therefore the player's explicit decision that the
dungeon is ready to receive raids.

### Preparation phase

Before the entrance exists, preparation has no raid deadline.

The player may:

-   dig corridors;
-   create branches and dead ends;
-   build rooms;
-   place or modify defenses;
-   place treasure/storage;
-   repair doors;
-   repair damaged structures;
-   manage corpses;
-   collect/manage loot from previous raids;
-   launch research;
-   prepare expansion;
-   inspect upcoming threat information when available;
-   place the free Dungeon Entrance when ready.

Once the Dungeon Entrance has been placed and storage is sufficient, the
normal raid countdown begins. See section 0.2 for pause/selection exceptions.

### Raid phase

When the timer expires:

1.  The dungeon locks.
2.  One adventurer enters (parties are a future extension).
3.  Adventurers explore using incomplete information.
4.  They pursue individual and/or group goals.
5.  Doors, traps and defenders interact with them.
6.  Heroes may die, flee, steal valuables, destroy targets, or reach the
    Core.
7.  Dead heroes leave persistent bodies and possessions.
8.  Hero deaths restore some Core health.
9.  When no hostile adventurer remains, the raid ends.

### Post-raid phase

Display a short report such as:

-   heroes killed;
-   heroes escaped;
-   resources stolen;
-   loot remaining;
-   structures damaged;
-   doors destroyed;
-   Core integrity.

Then return control to the player.

## 4. The Dungeon Core

The Core represents the life/influence of a dungeon.

If destroyed, that dungeon is lost.

If all player dungeons are lost, the campaign ends in defeat.

### Core healing

When an adventurer dies inside the Core's influence, part of their life
essence is automatically absorbed by the Core.

Example balancing direction:

-   weak adventurer: +1--2% Core integrity;
-   experienced adventurer: approximately +3%;
-   Champion: approximately +5%.

Values are provisional and require playtesting.

Core integrity cannot exceed 100%.

This should be visually represented by energy travelling through
supernatural veins in the dungeon toward the Core.

## 5. Resources and treasure

There is **no universal global resource stockpile** for normal dungeon
wealth.

Each dungeon owns its own resources.

This is important because local resources are physically at risk.

A dungeon's wealth can be stored in dedicated structures such as:

-   Cache;
-   Reliquary;
-   Vault.

Do not reproduce Dungeon Keeper's gold-piles-on-the-floor system for the
treasury. **Every coin the dungeon owns must sit in a storage
structure.** There is no invisible surplus beside the Core.

In the current prototype no storage is placed automatically. The player
starts with 320 gold and builds free 150-capacity vaults; raids remain
disabled while treasury exceeds storage capacity. This initial setup
exception is not loot beside the Core. Building costs are paid from the
treasury. Vault balances and free preparation-only transfers are detailed
in section 0.4. When a hero dies, carried loot stays in a bag at the body:
it becomes dungeon gold only after the player deposits it into storage
with free capacity. If storage is full, uncollected loot remains there.

Clearing a storage that is needed to hold the treasury spills the
overflow back onto that tile as a loot bag.

Storage should be visually readable: empty, partially filled and full
states should be distinguishable.

### Adventurer loot

Heroes carry possessions.

When a hero dies:

-   their body remains;
-   their carried loot remains associated with the corpse or location;
-   it is not automatically transferred to the player;
-   subsequent adventurers can potentially steal it.

The player manages the loot only outside raids.

## 6. Corpses

Corpses are persistent gameplay objects, not decorative effects.

A corpse remains where the adventurer died.

The player should **not** be able to freely drag corpses around the
dungeon, because that would make them trivial tools for manipulating AI.

Between raids, the player can eventually choose actions such as:

### Leave

Keep the corpse where it is.

Possible effects:

-   increases perceived danger;
-   may frighten cautious heroes;
-   can influence route selection;
-   may attract looters;
-   may affect Paladins/Priests differently.

### Absorb

Consume the corpse for an additional Core/Essence benefit.

The corpse disappears.

### Future possibilities

Later progression may introduce:

-   necromancy;
-   corpse-based research;
-   creature creation;
-   purification by enemy Priests;
-   resurrection.

These are not MVP requirements.

### Psychological pathfinding

Corpses contribute to perceived danger.

Different heroes respond differently.

Examples:

-   cautious hero: likely to avoid a corridor containing multiple
    corpses;
-   greedy thief: fear may be outweighed by visible loot;
-   Paladin: corpses may increase determination;
-   Barbarian: largely ignores them.

This allows previous raids to alter the psychological topology of the
dungeon.

## 7. Doors

Rooms can have doors.

Doors should preferably be created automatically when a corridor
connects to an enclosed room rather than requiring tedious manual
placement.

Possible door states:

-   intact;
-   damaged;
-   destroyed.

Destroyed doors remain destroyed after the raid.

### Repair rule

**No door or structure can be repaired while an enemy is present in the
dungeon.**

Repairs happen only during preparation.

Possible later upgrades:

-   reinforced doors;
-   locked doors;
-   trapped doors;
-   magically sealed doors.

Different classes may interact differently:

-   Thief: lockpicking;
-   Sapper: destruction;
-   Paladin/Warrior: forcing;
-   Mage: magical interaction.

## 8. Adventurer identity

Adventurers are not exclusively human.

The surface world contains multiple fantasy species.

Possible species include:

-   Humans;
-   Vulpins;
-   Batrafians;
-   Lithides;
-   Nocturnes;
-   Myceans;
-   Saurians;
-   Forged/artificial beings.

Humans should probably be a minority rather than the visual default.

### Species × Class × Trait

Hero behavior is composed from three layers:

**Species = how the hero operates physically/perceptually.**

**Class = what the hero wants.**

**Trait = personality and individual variation.**

Example:

**Vulpin / Thief / Greedy**

-   Vulpin: curious/agile species behavior;
-   Thief: seeks valuables;
-   Greedy: accepts greater danger for better loot.

Another:

**Lithide / Paladin / Stubborn**

-   Lithide: resilient to physical hazards;
-   Paladin: seeks corruption/Core/sanctuaries;
-   Stubborn: rarely changes objective.

## 9. Initial hero classes

Candidate roster:

### Thief

Primary goal: steal wealth/valuable objects and escape through the entrance.

Implemented Vulpin rules, including no trap jumping, lockpicking and collection states:
see section 0.6. Shared stats and personality modifiers are in section 0.5.

### Warrior

Primary behavior: direct combat and protection of the group.

Future class; no distinct raid AI currently implemented.

### Paladin

Primary goal: destroy corruption, Sanctuaries or the Core.

Implemented Lithide rules are in section 0.7; Sanctuaries are future design.

### Mage

Interested in magical objects and capable of interacting with magical
defenses.

Implemented Sable/Mycean rules are in section 0.9.

### Ranger/Scout

Better perception and trap detection; helps map the dungeon.

Implemented Batrafian rules are in section 0.8; current raids have no party
members to assist directly.

### Priest

Supports/heals allies and may eventually purify or resurrect corpses.

Future gameplay; the Nocturne preview model does not implement these abilities.

### Barbarian

Direct, aggressive, relatively insensitive to danger.

Future class; no distinct raid AI currently implemented.

### Sapper

Attacks doors, walls or structural obstacles.

Future class; heroes currently do not excavate or demolish rock walls.

More classes can be introduced progressively by kingdom.

## 10. Hero AI

Do not use a runtime LLM or machine-learning model for normal hero
behavior.

Use deterministic game systems with controlled probabilistic variation.

Recommended architecture:

``` text
Hero
 ├── Stats
 ├── Species
 ├── Class
 ├── Personality/Traits
 ├── KnowledgeMap
 ├── Perception
 ├── GoalEvaluator
 └── Navigator
```

### Partial knowledge

Heroes must not know the full dungeon.

Each hero maintains a mental/knowledge map containing discovered
information.

They can:

-   remember explored corridors;
-   remember dead ends;
-   discover rooms;
-   detect some objectives from limited distance;
-   learn about detected traps;
-   receive information from party members.

### Goal scoring

Available goals receive utility scores.

Simplified conceptual formula:

``` text
utility =
    target_value * desire
    - perceived_danger * caution
    - distance_cost
    + curiosity
    + situational_modifiers
```

Weights differ by species, class and traits.

### Navigation

Use grid pathfinding such as `AStarGrid2D` or a custom A\*/BFS layer.

High-level AI decides **what it wants**.

Pathfinding decides **how to reach what it currently knows**.

Do not give pathfinding omniscient access to undiscovered information.

### Imperfect perception

AI decisions should be based on estimates rather than perfect values.

A thief may perceive:

``` text
strong wealth signal west
unknown path south
dangerous corridor north
```

rather than exact treasure quantities and exact trap locations.

### Controlled randomness

Avoid deterministic "always choose highest score."

Convert close utility scores into weighted probabilities.

Example:

``` text
Path A score: 76 -> ~54%
Path B score: 72 -> ~43%
Path C score: 31 -> ~3%
```

If one choice is overwhelmingly superior, it should remain
overwhelmingly likely.

The goal is:

**predictable tendencies, unpredictable exact outcomes.**

### Hidden numerical values

Players should not see exact internal AI weights.

Display readable traits such as:

-   Greedy;
-   Cautious;
-   Loyal;
-   Cowardly;
-   Stubborn.

Players should reason about personalities, not solve formulas with
spreadsheets.

## 11. Kingdom knowledge

The kingdom can gradually learn from successful expeditions.

Examples:

-   partial maps;
-   known traps;
-   rumors about treasure bait;
-   knowledge of common defensive patterns.

Surviving heroes and Scouts can transmit information.

Future heroes may therefore become somewhat better prepared.

Changing the dungeon can invalidate old information.

This helps prevent one solved dungeon layout from remaining optimal
forever.

## 12. Adventuring parties

Parties require two AI layers:

``` text
GroupBrain
 ├── leader
 ├── group_objective
 ├── cohesion
 ├── shared_knowledge
 └── members[]

HeroBrain
 ├── species
 ├── class
 ├── personality
 ├── personal_goal
 ├── loyalty
 └── fear
```

### GroupBrain

Responsible primarily for:

-   expedition objective;
-   general route;
-   leader;
-   cohesion;
-   shared information.

### HeroBrain

Determines whether an individual continues following the party or acts
independently.

### Roles

Possible party roles:

-   Leader;
-   Vanguard;
-   Support;
-   Specialist.

### Contradictory goals

Contradictions are intentional.

A Thief may detect a valuable Vault while a Paladin leader is heading
toward a Sanctum.

The Thief compares:

-   personal treasure utility;
-   group cohesion/loyalty;
-   danger;
-   distance.

If the personal goal significantly exceeds cohesion, the hero can split
from the group.

### Regrouping

Distance from the group affects utility.

Support heroes should strongly prioritize returning when too far away.

### Leader death

If the leader dies:

1.  recalculate leadership;
2.  select a replacement if appropriate;
3.  possibly reconsider the group objective.

A party that loses its Paladin may abandon a purification objective and
switch to survival/loot.

### Shared information

Party members share some discoveries.

Examples:

-   Ranger detects trap -\> group learns it;
-   Scout maps corridor -\> group learns it.

Some information may remain private depending on personality.

A greedy Thief might conceal treasure information.

## 13. Hero persistence

Some surviving heroes may persist in the world.

Example:

A thief successfully steals from the player and returns in a later raid
at a higher level.

They may retain partial knowledge of the dungeon and potentially carry
previously stolen objects.

This creates emergent personal rivals.

Not required for the earliest MVP.

## 14. Raid scheduling and offline behavior

### Online

Raids happen only while the game is active and the Dungeon Master is
considered present.

A visible timer leads to the next raid.

### Offline

**No raids occur while the application is closed.**

Narrative explanation:

The Dungeon Master's active influence attracts attention. When the
Master sleeps, the dungeon's influence becomes dormant and effectively
disappears from the kingdom's awareness.

This eliminates:

-   destructive offline progression;
-   overnight losses;
-   pressure to check notifications;
-   complex offline raid simulation.

### Non-dangerous offline progression

Research and other safe timers may continue while offline.

Use persisted timestamps to calculate elapsed safe progress when the
player returns.

## 15. Player activity and difficulty

Players who play more may progress faster, but players who play less
should not be punished.

Potential voluntary activity mechanic:

### Intensify Influence

For a limited period:

-   raids become more frequent;
-   adventurers may carry better loot;
-   raids may be more dangerous.

This lets active players explicitly request more gameplay and accept
greater risk.

Do not make high activity mandatory for survival.

## 16. Expansion and multiple dungeons

The player eventually controls multiple dungeons on a world map.

Each dungeon has independent:

-   Core;
-   architecture;
-   resources;
-   treasure;
-   damage;
-   defenses;
-   raid state.

There is no easy global pool that removes the strategic risk of where
wealth is stored.

### Creating a new dungeon

Expansion requires a special room/structure in an existing dungeon.

It starts a timed research/ritual.

During this process:

-   the dungeon attracts more adventurers;
-   the structure becomes an important target;
-   if heroes destroy/disrupt it, expansion can be interrupted.

Completing the process allows creation of a new dungeon elsewhere in the
kingdom.

A newly created dungeon begins in the same dormant state as the first
dungeon:

-   the Core is already present;
-   a small area around it is already excavated;
-   no entrance exists yet;
-   no raid timer runs until the player places the free entrance staircase.

The player therefore designs the initial layout before deciding when that
new dungeon becomes exposed to adventurers.

## 17. Dungeon architecture

Players must be able to create:

-   branching corridors;
-   dead ends;
-   loops;
-   rooms;
-   misleading routes;
-   eventually multiple floors.

The construction system itself should be satisfying enough to constitute
a major part of gameplay.

Multi-floor dungeons are a later feature, not an MVP requirement.

## 18. Kingdom progression

The player begins with:

-   a small dungeon;
-   limited dungeon size;
-   limited rooms;
-   limited defenses;
-   few hero species/classes;
-   one floor;
-   one dungeon.

Each kingdom has an objective that must be completed before moving to a
harder kingdom.

Possible objectives:

-   accumulate a target amount of wealth;
-   survive a number of raids;
-   protect an artifact;
-   maintain several dungeons;
-   complete expansion rituals;
-   survive a Crusade;
-   defeat a Champion.

New mechanics are introduced gradually between kingdoms.

This acts as organic onboarding rather than exposing every system
immediately.

## 19. Procedural kingdoms

Kingdoms should be procedurally generated from a seed.

A kingdom seed determines elements such as:

-   geography;
-   regions;
-   civilizations/species;
-   factions;
-   wealth;
-   hostility;
-   special modifiers;
-   campaign objective.

The player's dungeon layouts themselves are not procedurally generated;
building them is the player's core activity.

### Region examples

-   fungal forest;
-   merchant town;
-   religious sanctuary;
-   mountains;
-   trade road;
-   magical region.

Regions influence hero composition and available resources.

### Kingdom modifiers

Examples:

-   Greedy King;
-   Theocracy;
-   Kingdom at War;
-   Age of Magic;
-   Great Trade Route.

Modifiers should alter behavior/composition, not merely inflate enemy
HP.

### Difficulty envelope

Procedural generation is constrained by progression.

Early kingdoms cannot generate late-game complexity.

## 20. End condition

The game needs meaningful campaign progression rather than endless
expansion without purpose.

A kingdom is completed by satisfying its campaign objective.

The player then moves to a harder procedural kingdom.

If all player dungeons are destroyed, the campaign ends.

Long-term meta-progression may allow some persistent Dungeon Master
upgrades between kingdoms.

## 21. Visual art bible

Canonical visual spec: `art_bible/ART_BIBLE.md`. Meshy stills, manifests
and generation queue: `production/` (see `production/README.md`).

### Core direction

**Stylized dark fantasy + supernatural dungeon + highly readable mobile
presentation.**

Three guiding words:

**Supernatural · Readable · Stylized**

Avoid:

-   photorealism;
-   excessive gore;
-   generic red-demon/lava aesthetic;
-   direct Dungeon Keeper visual imitation;
-   overly comedic chibi style.

### Camera

Stylized 3D with a fixed or mostly fixed orthographic elevated camera.

Target inclination approximately 35--45 degrees.

The game should remain readable on small screens.

### Dungeon

Uncontrolled rock:

-   cool gray;
-   irregular;
-   natural.

Controlled territory:

-   darker;
-   subtly more geometric;
-   mineral/root-like supernatural structures;
-   restrained violet energy veins.

Strong influence:

-   increasingly impossible geometry;
-   floating fragments;
-   brighter supernatural energy.

### Core visual

Avoid a generic crystal.

The Core should resemble a suspended spatial anomaly:

-   perfectly dark central sphere/void;
-   floating stone fragments;
-   surrounding supernatural distortion;
-   dungeon veins converging toward it.

### Color language

-   rock: anthracite / blue-gray;
-   Dungeon Master influence: deep violet;
-   supernatural energy: violet/magenta;
-   wealth: warm gold;
-   surface world: greens/blues/beige;
-   heroes: brighter warmer colors;
-   immediate danger: red/orange.

Do not make everything purple.

### Surface world

The surface should contrast strongly with the dungeon:

-   alive;
-   warm;
-   colorful;
-   familiar.

The world map can resemble a stylized 3D diorama.

As influence spreads, local surface elements become subtly
colder/stranger.

### Dungeon Master

The Dungeon Master is **never directly shown**.

The player is the presence.

Only its effects are visible:

-   transforming rock;
-   moving energy;
-   Core pulses;
-   supernatural veins;
-   spatial distortion.

## 22. Hero visual design

Heroes use stylized low-poly 3D models.

Proportions are exaggerated for readability but not chibi.

Silhouette must communicate class/species even at small screen size.

Examples:

-   Vulpin Thief: small, fast silhouette, cape, oversized loot bag,
    daggers;
-   Lithide Paladin: massive stone body, luminous runes, large shield;
-   Mycean Mage: fungal silhouette, magical bioluminescence;
-   Batrafian Ranger: agile amphibian silhouette, ranged weapon.

The diversity of non-human species is a core visual differentiator.

## 23. Animation direction

Prefer reusable skeletal animation for stylized low-poly 3D heroes.

Initial shared animation set:

-   Idle;
-   Walk;
-   Attack;
-   Hit;
-   Death;
-   Interact;
-   Fear/Surprise.

Class-specific additions:

-   Thief: steal/loot;
-   Paladin: purification;
-   Mage: channel/cast;
-   Priest: heal/purify.

Animations should prioritize readability over realism.

Environmental animation is also important:

-   Core pulse;
-   floating fragments;
-   storage glow;
-   moving veins;
-   trap anticipation;
-   essence absorption.

## 24. UI direction

Keep permanent UI minimal.

The dungeon should dominate the screen.

Use contextual information when selecting:

-   rooms;
-   heroes;
-   structures;
-   corpses.

Icons must remain identifiable around small mobile sizes.

Example semantic colors:

-   wealth: gold;
-   integrity: red;
-   raid: orange;
-   research: violet;
-   construction: light blue.

## 25. Platforms

Target architecture:

-   Android;
-   iOS;
-   Windows;
-   macOS;
-   Linux/Steam.

Use one gameplay codebase with input abstraction.

Conceptually:

``` text
Touch ───────┐
Mouse ───────┼── PlayerAction ── Gameplay
Controller ──┘
```

Do not embed core gameplay directly into mouse-only event handling.

Desktop may provide shortcuts and richer mouse controls while preserving
identical game rules.

## 26. Monetization philosophy

Avoid monetization that undermines the strategic economy.

Do not sell:

-   raw dungeon gold;
-   survival;
-   instant repairs;
-   pay-to-win hero weakening;
-   artificial timer frustration.

Possible models:

### Mobile

Free-to-start:

-   first kingdom free;
-   one-time purchase unlocks full base game.

Optional cosmetic purchases.

### Steam/Desktop

Premium purchase.

Potential future substantial DLC/expansions.

### Cosmetics

Potential cosmetic categories:

-   Core appearances;
-   corruption effects;
-   dungeon themes;
-   trap appearances;
-   UI themes;
-   visual effects.

The principle is:

**Players pay for the game/content/style, not relief from artificial
suffering.**

## 27. Save architecture

The following is the future campaign save architecture. The implemented
single-dungeon format and its reload semantics are specified in section 0.11.
An eventual campaign save should contain at least:

``` text
SaveGame
 ├── version
 ├── player_progress
 ├── current_kingdom
 ├── kingdom_seed
 ├── unlocked_features
 ├── dungeons[]
 │    ├── id
 │    ├── world_position
 │    ├── core_hp
 │    ├── local_resources
 │    ├── layout
 │    ├── rooms
 │    ├── doors
 │    ├── traps
 │    ├── storages
 │    ├── corpses
 │    └── unsecured_loot
 ├── hero_history
 └── settings
```

Use save versioning from the beginning to support migrations.

Procedural kingdoms should store the seed plus player/world
modifications rather than unnecessarily duplicating generated data.

Autosave after meaningful state changes.

Cloud save can be added later through platform services, while
maintaining a local save as the fundamental representation.

## 28. Technical direction

Current preferred engine:

**Godot 4.x**

Current preferred scripting language:

**GDScript**

Prototype hero navigation:

-   grid-based;
-   `AStarGrid2D`, A\*, or BFS depending on requirement.

The simulation logic should be independent from presentation wherever
possible.

Long-term structure should allow a raid to be simulated without
rendering it, even though current design disables destructive offline
raids. This is useful for tests, balancing and debugging.

## 29. MVP roadmap

### MVP 0.1 --- Fun prototype

Goal:

Validate whether building a labyrinth and watching an adventurer attempt
to defeat it is fun.

Include only:

-   one dungeon;
-   one floor;
-   grid;
-   Core present at game start;
-   a small pre-excavated area around the Core;
-   no predefined starter dungeon;
-   a player-placed free entrance staircase;
-   raids disabled until the entrance is placed;
-   diggable corridors;
-   branches/dead ends;
-   storage;
-   2--3 traps;
-   one Thief;
-   partial hero knowledge;
-   automatic raids after the entrance has been placed;
-   persistent layout;
-   loot/corpse consequences.

### MVP 0.2

Add:

-   preparation vs raid phase;
-   no player intervention during raid;
-   persistent corpses;
-   corpses influence perceived danger;
-   Core healing from hero deaths;
-   unsecured loot;
-   destructible doors;
-   repairs only outside raids;
-   no offline raids.

### Next validation milestones

Only proceed when the previous question is answered positively.

1.  **Is watching heroes navigate the player's labyrinth fun?**
2.  **Does the player want to redesign the dungeon after seeing
    failures?**
3.  **Are persistent consequences interesting rather than annoying?**
4.  **Can a new player understand the loop without a large tutorial?**
5.  **Does species × class × trait create noticeable variety?**
6.  **Do groups add interesting emergent behavior?**
7.  **Does multi-dungeon kingdom progression improve the game enough to
    justify its complexity?**

## 30. Scope discipline

Every proposed feature should answer at least one of these:

-   Does it make dungeon construction more interesting?
-   Does it make observing heroes more interesting?
-   Does it create a meaningful risk/reward decision?
-   Does it improve adaptation between raids?
-   Does it deepen kingdom expansion without overwhelming the player?

If not, strongly consider excluding it.

Avoid feature accumulation such as crafting systems, many currencies,
daily chores, decks/cards, guild systems, etc. unless future playtesting
demonstrates a concrete need.

The deck-building concept discussed early in design has deliberately
been removed to simplify the game.

## 31. Core design statement

The game should create stories from systems.

A player should be able to say:

> "I put the treasure behind the obvious corridor, but the cautious
> Vulpin saw the corpses and took my fake safe route. Then the Paladin
> smashed the eastern door, so on the next raid the Thief used the
> opening and stole the loot from the previous expedition."

That is the target experience.

The dungeon is not merely a collection of upgraded statistics.

**Its architecture remembers what happened.**
