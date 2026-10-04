# Persistent heroes and expedition XP

Status: approved and implemented 2026-10-03. GAME_DESIGN.md section 0 records
the current implementation; this document records the approved design.

## Goal and approved rules

Heroes are individuals who can survive, gain experience and return stronger.
Preserve identity, name, class, traits, experience and level across raids and saves.
Death is permanent: a dead individual can never be selected again.
New recruits start at level 1 with zero XP.

At each raid, choose a returning survivor with 50% probability or a new recruit
with 50% probability. Exclude the previous raid's individual from return selection.
If no eligible survivor exists, recruit instead. A survivor can return after at
least one intervening raid by someone else. Eligibility is based on identity,
not name or class; two different Vulpins can visit consecutively.

XP is awarded only when departure alive actually completes, not when its
animation starts. Levels gained apply to the next expedition.

| Accomplishment | XP |
| --- | ---: |
| Completed departure alive | 10 |
| Gold acquired inside this dungeon and carried out | floor(gold / 5) |
| Successfully unlocked door or chest | 15 per lock |
| Destroyed door or removed magical seal | 15 per obstacle |
| Actual Core HP removed | 1 per HP |
| Cell personally discovered for the first time | 1, capped at 20 per raid |

No credit for starting possessions, failed attempts or repeated action on the
same obstacle during a raid. Count actual results, not requested damage or loot.
Gold picked up from ground bags is acquired in the dungeon and qualifies when
carried out; do not double count it as both picked-up gold and stolen chest gold.

Cost to advance from level L to L+1 is 50 * L XP. Cumulative minimum XP for
level L is 25 * L * (L - 1): 0, 50, 150, 300, 500, 750, ... . Retain all XP;
allow multiple level gains from one expedition. No gameplay level cap is added.
Example: departure plus 150 stolen gold plus one unlocked lock gives 55 XP,
enough for level 2 even without exploration credit.

Vulpin lockpicking uses the already implemented progression: attempts are
1 + floor((level - 1) / 2), chance is min(0.75, 0.50 + 0.05 * floor(level / 2)).
Vulpins still cannot jump traps or unlock magical protections.

## Proposed supporting decisions for review

- Returning heroes arrive at full HP. Their rolled base stats and personality
  stay fixed; do not reroll the individual on every visit.
- No new HP, damage, movement or class-skill scaling in this change. All classes
  earn XP; Vulpin's existing lockpicking is the first level-sensitive ability.
- Starting carried gold remains a fresh class-based roll each visit. Loot from
  prior raids is not a persistent wallet or additional XP on subsequent raids.
- Void banishment preserves existing behavior: departure alive with carried
  loot, therefore survival, XP and eligibility to return. It is not death.
- Explicitly restarting the dungeon clears its visitor roster, identities,
  personal exploration and previous visitor, alongside existing map knowledge.
  Existing player/Core progression retention remains unchanged.
- Keep the current pre-raid checkpoint model. Closing mid-raid resumes the last
  saved preparation state, with no partial XP or half-finished hero action.
  Permanent death applies to completed, saved deaths; this is not an anti-reload
  or ironman save system.

## Selection and identity

Use a dedicated HeroRoster object owned by RaidDirector, rather than storing
persistent data in the transient hero action dictionary. Allocate monotonically
increasing IDs and unique visible personal names (deterministic suffix if needed).
Dead IDs are never reused within the dungeon. Do not store dead heroes as eligible
profiles or add a cemetery UI in this change.

For new recruits, preserve existing class selection and mage-pressure rules.
For returns, group eligible survivors by class, select a nonempty class with
existing weights (Mage 1 + pressure, other classes 1), then uniformly select
an individual in that class. This avoids a large class cohort dominating returns.
Consume mage pressure only when a Mage actually enters. Vulpin-only testing
filters both recruits and returning candidates to Vulpins, without deleting other
profiles or consuming mage pressure.

Record the previous visitor when a raid starts; persist it with the completed
raid. Transient combat state, lock budgets, route visits, ignored objectives,
timers, stolen gold and pending awards always reset for a new expedition.

## Personal discovery and award integrity

Keep personally discovered cells separate from shared kingdom navigation memory.
Shared knowledge alone grants no XP. Record cells actually perceived by the hero
using current perception rules; no new visibility or wall-occlusion system.
Track all discoveries even after reaching the 20 XP cap, so a future raid cannot
claim overflow discoveries. Previously seen cells never earn XP again for that
individual, including after rebuilding the same cell. A new recruit can discover
them independently.

Track successful lock/obstacle events once per cell per raid, actual Core damage,
and newly acquired carried gold. Clear the ledger on new raid. Commit XP,
discoveries, roster changes and the report exactly once before clearing hero.
Use the existing completed-raid guard; repeated portal or result callbacks cannot
duplicate XP. Death removes the hero without granting pending awards. Aborted
simulation/reset is not survival and must not grant XP.

## Persistence and UI

Add optional validated roster data to version 1 saves for backward compatibility:
living profiles, next identity and previous visitor ID. Missing roster means an
empty roster, not inferred heroes from kingdom memory. Derive level from total XP
to avoid contradictory saved values. Validate IDs, classes, traits, numeric bounds,
profile stats and discovered map coordinates before applying any save. Previous
visitor may reference a dead individual; it need not exist in the living roster.
Honor existing file-size safeguards and backup behavior; never silently discard
survivors to meet a limit or silently ignore save failures.

Continue using the compact portrait/name/level badge. Distinguish personal name
from class identity without adding another top HUD bar. Extend the existing raid
result with hero ID/name, XP breakdown, total XP and old/new levels. No new roster
management screen in this iteration.

## Implementation boundaries

- Add scripts/game/hero_roster.gd for identity, eligibility, profiles and XP math.
- Integrate spawn, observation, successful actions and terminal outcomes in
  scripts/game/raid_director.gd.
- Extend scripts/mobile/mobile_save.gd validation/capture/restore and existing
  session reset/result integration as needed.
- Adapt existing hero badge and raid result views only where name/XP require it.
- Update GAME_DESIGN.md section 0 in the same implementation, preserving the
  distinction between implemented rules and future abilities.
- Leave unrelated world rendering, art, economy and Core progression untouched.

Alternatives considered: class-wide XP would lose individual history and make
permanent death meaningless; persisting the full runtime hero dictionary would
retain stale timers, lock budgets and route state. Use explicit durable profiles.

## Verification

Deterministic tests cover both selection branches, empty pool, only-last-visitor
pool, distinct same-class heroes, no consecutive identity, dead hero exclusion,
mage pressure and Vulpin-only filtering. Verify exact XP boundaries, multiple
level gains, every reward source, repeated events, starting gold exclusion,
empty chests, exploration cap/history and inherited knowledge giving no XP.

Probe full real raid completion for survival, portal, void and death; verify
awards only after departure, reset lock quotas, retained personality and level,
and no Vulpin jump. Test save round trips, legacy saves, malformed roster rejection
without mutation, checkpoint reload, restart and duplicate result callbacks.
Use isolated test saves, never the user's actual save. Run the complete
tools/test-mobile.ps1 -All suite and check compact badge/result layout with long
names and multi-digit levels before declaring implementation complete.
