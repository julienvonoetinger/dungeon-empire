# Dungeon Master --- Game Design Document

> **Status:** Living design specification\
> **Purpose:** Source of truth for development agents and contributors.\
> **Prototype baseline:** Godot 4.x, GDScript, mobile + desktop.

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

-   the Dungeon Core already exists;
-   a small area of empty, already-excavated tiles surrounds the Core;
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
-   activates the raid system when it is placed.

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

Once the Dungeon Entrance has been placed, the normal raid countdown
begins and future preparation phases occur under that countdown.

### Raid phase

When the timer expires:

1.  The dungeon locks.
2.  One adventurer or an adventuring party enters.
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

At dungeon creation, enough starter storage is placed around the Core to
hold the starting treasury. Building costs are paid from that stored
gold. When a hero dies, carried loot stays on the body: it becomes
dungeon gold only after the player deposits it into storage with free
capacity. If every storage is full, the loot remains on the corpse until
more storage is built (or an existing chest is emptied).

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

Primary goal: steal wealth/valuable objects and escape/teleport.

### Warrior

Primary behavior: direct combat and protection of the group.

### Paladin

Primary goal: destroy corruption, Sanctuaries or the Core.

### Mage

Interested in magical objects and capable of interacting with magical
defenses.

### Ranger/Scout

Better perception and trap detection; helps map the dungeon.

### Priest

Supports/heals allies and may eventually purify or resurrect corpses.

### Barbarian

Direct, aggressive, relatively insensitive to danger.

### Sapper

Attacks doors, walls or structural obstacles.

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

Each save should contain at least:

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
