# Dungeon Master — Integrated Art Bible

> **Status:** Canonical living visual specification  
> **Purpose:** Single source of truth for concept art, image generation, Meshy image→3D work, Godot implementation, and future art contributors.  
> **Companion documents:** `../GAME_DESIGN.md` and the production manifests under `../production/manifests/`.

---

## 1. Core visual direction

**Stylized dark fantasy + supernatural dungeon + highly readable mobile/desktop presentation.**

Three guiding words:

**Supernatural · Readable · Stylized**

The game should feel mysterious and uncanny rather than horrific. The dungeon is alive with an unseen supernatural intelligence, but the visual language should remain clear, elegant, and readable.

### Avoid
- photorealism;
- excessive gore;
- generic red-demon / lava / pentagram evil aesthetics;
- direct visual imitation of Dungeon Keeper or another existing property;
- overly comedic chibi proportions;
- making every object purple;
- noisy micro-detail that disappears at game camera distance;
- realistic grime that destroys silhouettes;
- contact sheets as production source assets;
- changing an asset's identity between gameplay states.

---

## 2. Camera and readability

### In-game camera
- Stylized 3D.
- Fixed or mostly fixed elevated orthographic / near-orthographic camera.
- Target inclination: approximately **35–45°**.
- Assets must remain identifiable on small screens.

### Meshy source images
Every source image used for image→3D must contain:
- **one object only**;
- the full object visible with margin on every side;
- a neutral 3/4 or isometric angle;
- plain dark neutral background;
- no environment;
- no labels;
- no filename text;
- no grid;
- no multiple states;
- no unrelated props.

For multi-state objects, generate one canonical `*_reference.png` first. Every other state must be made by **editing that exact canonical image**, not by asking for “another object in the same style.”

---

## 3. Shape language

The dungeon is not conventional masonry decorated with magic. It should look as though natural rock is gradually reorganized by an impossible intelligence.

### Uncontrolled rock
- irregular;
- natural;
- cool gray;
- broken silhouettes;
- low supernatural influence.

### Controlled territory
- darker;
- subtly ordered;
- more geometric without becoming clean architecture;
- mineral / root-like structures;
- restrained violet veins;
- shapes appear *grown into order* rather than manufactured.

### Strong influence
- increasing geometric impossibility;
- levitating fragments;
- subtle spatial distortion;
- brighter supernatural energy;
- architecture starts behaving in ways normal stone should not.

---

## 4. Material language

### Dungeon Stone
Broad low-poly planes with hand-painted/PBR-inspired response. Avoid excessive surface noise.

- Anthracite — `#25232A`
- Blue Gray — `#3B414C`
- Mid Stone — `#555765`
- Pale Stone — `#858895`

### Dungeon Influence
Used selectively.

- Deep Violet — `#40204F`
- Influence Purple — `#683276`
- Arcane Violet — `#9B4DB5`
- Energy Magenta — `#CE72DF`

### Wealth
- Dark Gold — `#80652A`
- Warm Gold — `#D4A83E`
- Treasure Highlight — `#FFD878`

### Surface World
- Forest Green — `#56724C`
- Moss Green — `#819568`
- Sky Blue — `#7399B6`
- Warm Sand — `#C9AC7A`
- Village Beige — `#B99570`

### Danger
- Red — `#A74747`
- Orange — `#D9783C`

**Important:** violet identifies supernatural influence; it is not the default material color for everything.

---

## 5. Lighting

Readability comes first.

- Never rely on pitch-black corridors.
- Use soft directional readability lighting plus localized emissive influence.
- Purple energy should create accents, not flatten the whole object into neon.
- Wealth uses warm highlights and should contrast clearly with the colder dungeon.
- Surface environments should feel warmer and more familiar than the dungeon.

---

## 6. The Dungeon Master

The Dungeon Master is **never directly shown**.

The player is a presence expressed through:
- transformed rock;
- moving supernatural veins;
- Core pulses;
- floating fragments;
- localized distortion;
- structures that seem shaped by invisible influence.

Do not design a humanoid “Dungeon Master avatar” as the central visual identity.

---

## 7. The Dungeon Core

The Core is one of the project's most important visual signatures.

### Canonical identity
**Do not use a generic crystal.**

The Core is a suspended spatial anomaly:
- a perfectly dark central sphere / void;
- an impossible absence of light;
- floating stone fragments around it;
- a restrained violet/magenta distortion halo;
- supernatural dungeon veins converging toward it;
- the surrounding structure appears pulled toward the anomaly.

The visual should read as **space itself becoming wrong**, not “big magic gem.”

### Gameplay states
- `core_healthy`
- `core_damaged`
- `core_critical`
- `core_destroyed`

All states must remain recognizably the **same Core**. Damage changes surrounding fragments, integrity, cracks and VFX. It must not turn into a different crystal design.

### Animation/VFX
- slow Core pulse;
- orbiting / floating fragments;
- moving veins;
- life-essence absorption traveling toward the Core;
- controlled distortion;
- intensity linked to health/state where useful.

---

## 8. Dungeon architecture

### Floors
Modules should tile cleanly while retaining irregularity.

Families:
- uncontrolled stone;
- controlled stone;
- strong-influence stone;
- cracked/damaged variants.

### Walls
- broad readable blocks;
- clear corner modules;
- subtle supernatural ordering in controlled areas;
- strong-influence areas may bend expected geometry.

### Pillars, stairs, bridges
All structural modules must share:
- stone scale;
- bevel language;
- texel density;
- controlled-territory influence patterns.

Avoid designing every module as a unique monument. The kit must remain modular.

---

## 9. Doors

Doors are persistent gameplay objects, not decorative scenery.

### Standard states
- `closed`
- `open`
- `damaged`
- `destroyed`

The open state should normally be the **same 3D mesh with hinge animation**. Destroyed state can use a topology variant.

### Later variants
- reinforced;
- locked;
- trapped;
- magically sealed.

Each variant has its own canonical reference. State variants must preserve the exact frame, ornaments, material balance and proportions of that reference.

### Readability
At gameplay distance, the player should immediately understand:
- can heroes pass?
- is it intact?
- is it damaged?
- is it destroyed?

---

## 10. Storage and treasure

Dungeon wealth is physically local and at risk.

Dedicated structures include:
- Cache;
- Reliquary;
- Vault;
- Vault Chest / storage chest where appropriate.

Storage must visually communicate:
- empty;
- partially filled;
- full;
- destroyed / looted when applicable.

### Canonical-state rule
For a chest:
- closed/open should preserve the same hinge, body, lock, ornaments and proportions;
- empty/full should ideally use a detachable treasure-content mesh;
- destroyed can use an alternate mesh.

Do not regenerate a visually different chest for each state.

### Treasure
Treasure should use warm gold and occasional rare-item accents. It must contrast clearly against the cold dungeon.

---

## 11. Signature traps

The initial supernatural trap identity should feel created by the dungeon rather than purchased from a medieval trap catalogue.

### Spines
A supernatural spike mechanism integrated into stone.
States:
- armed;
- triggered;
- broken.

### Grasp
A supernatural hand / grasping mechanism emerging from the dungeon itself.
States:
- hidden;
- active;
- broken.

### Void
A spatial rift trap.
States:
- inactive;
- active;
- collapsed.

The portal itself should largely be shader/VFX-driven in Godot; the ring/base is the primary 3D mesh.

### Watcher
An eerie dungeon-made watcher idol / construct.
States:
- idle;
- alert;
- firing;
- destroyed.

Avoid making it simply a conventional turret.

### Future traps
Pit, boulder, arrow, flame, ice and acid traps may appear later, but they must be visually reconciled with the same supernatural dungeon identity.

---

## 12. Dungeon creatures

Dungeon defenders should feel **created by the dungeon**, not like generic fantasy minions.

Preferred concepts:

### Shardling
- small creature made from floating rock fragments;
- supernatural energy holds it together;
- fast readable silhouette.

### Hollow
- animated empty shell / armor-like form;
- visibly hollow;
- uncanny rather than undead-gory.

### Maw
- wall-integrated ambush creature;
- architecture and creature merge;
- avoid generic demon anatomy.

### Wraith
- supernatural dungeon spirit;
- readable floating silhouette;
- restrained violet energy.

Avoid default goblins/orcs/demons as the core faction identity.

---

## 13. Adventurer species

The surface world is populated by multiple fantasy peoples. Humans exist but should not be the default visual majority.

### Vulpins
Fox-like humanoids.
- agile;
- curious;
- expressive ears and tail;
- strong silhouette.

### Batrafians
Frog/amphibian humanoids.
- compact;
- agile;
- unusual leg/body proportions;
- highly readable head silhouette.

### Lithides
Living stone people.
- large;
- heavy;
- angular;
- glowing mineral seams/runes;
- powerful mass.

### Nocturnes
Owl/bird-inspired people.
- scholarly;
- observant;
- feathered visual identity.

### Myceans
Fungal humanoids.
- mushroom/fungal silhouette;
- soft bioluminescence;
- organic magical forms.

### Saurians
Reptilian people.
- practical, robust silhouettes;
- avoid generic “dragonborn clone” presentation.

### Forged
Artificial fantasy beings.
- stone / metal / ceramic;
- magical construction;
- visibly made rather than born.

### Humans
Present, but a minority rather than the default species.

### Insectoid note
**No insectoid model is currently canonical.**
Earlier concepts drifted into a bird-beak silhouette. If insectoids return later, they must use clearly arthropod mouthparts/head anatomy and must not resemble avian characters.

---

## 14. Hero class silhouette language

**Species = physical/perceptual identity.**  
**Class = what the hero wants / does.**  
**Trait = personality variation.**

Class should be readable without erasing species identity.

### Thief
- compact/agile equipment;
- daggers;
- loot bag;
- lock interaction gear.

Canonical example: **Vulpin Thief**.

### Warrior
- direct combat silhouette;
- protection / group frontline.

### Paladin
- large shield / purification identity;
- strong heroic geometry;
- seeks corruption, Sanctuaries and Core.

Canonical example: **Lithide Paladin**.

### Mage
- magical focus / staff;
- readable channeling silhouette.

Canonical example: **Mycean Mage**.

### Ranger / Scout
- ranged weapon;
- exploration/perception cues;
- lighter equipment.

Canonical example: **Batrafian Ranger**.

### Priest
- support / purification silhouette;
- healing/purification focus.

Suggested species: Nocturne.

### Barbarian
- direct aggressive silhouette;
- simple large weapon;
- minimal caution.

### Sapper
- structural-destruction tools;
- visibly equipped to attack doors/walls.

Suggested species: Forged.

---

## 15. Hero proportions

- Stylized low-poly.
- Approximately **5–6 heads tall**.
- Exaggerated for readability.
- Not chibi.
- Hands, weapons, shields and class-defining props may be slightly oversized.
- Species silhouettes must remain distinguishable at mobile gameplay size.

---

## 16. Animation direction

Prefer reusable skeletal rigs.

### Shared base set
- Idle
- Walk
- Attack
- Hit
- Death
- Interact
- Fear / Surprise

### Class additions
- Thief: steal / loot / lockpick
- Paladin: purification / heavy door strike
- Mage: channel / cast
- Priest: heal / purify
- Sapper: structure attack

### Environmental animation
- Core pulse
- floating fragments
- moving veins
- storage glow
- trap anticipation
- essence absorption

Animation readability is more important than realism.

---

## 17. Corpses and remains

Corpses are persistent gameplay objects but should be presented without gore.

- A body remains where the adventurer died.
- Equipment/loot may remain associated with that location.
- Visual state should read clearly without graphic injury.
- Different species need readable “fallen” silhouettes.
- Corpses are psychological pathfinding information for future heroes.

Do not make corpse art gruesome.

---

## 18. Surface world

The surface world must strongly contrast with the dungeon.

### Surface identity
- alive;
- warm;
- colorful;
- familiar;
- readable;
- stylized 3D diorama.

Potential regions:
- villages;
- merchant towns;
- forests;
- fungal forests;
- mountains;
- religious sanctuaries;
- trade roads;
- magical regions.

As dungeon influence spreads:
- colors become locally colder;
- small violet fissures may appear;
- rocks may float;
- geometry becomes subtly strange.

Do not turn the whole surface world into a purple wasteland.

---

## 19. World map

The world map should resemble a compact stylized 3D diorama.

Requirements:
- clear landmarks;
- readable regions;
- visually pleasant at zoomed-out scale;
- influence visible but subtle;
- generated kingdoms can reuse modular landmark families without appearing identical.

---

## 20. UI direction

Permanent UI should remain minimal so the dungeon dominates the screen.

### Semantic colors
- wealth: gold;
- integrity: red;
- raid: orange;
- research: violet;
- construction: light blue.

### Icons
- must remain identifiable around ~24 px;
- use simple silhouettes;
- avoid tiny interior details;
- use consistent perspective/stroke/material language.

UI reference assets are **2D assets** and should not be sent to Meshy.

---

## 21. Image generation rules

These rules are mandatory for production source images.

### One image = one asset
Never create:
- sprite sheets;
- contact sheets;
- comparison grids;
- multiple states in one frame.

### No text
Never place:
- asset names;
- filenames;
- labels;
- arrows;
- state names.

### Canonical identity
For state variants:
1. start from `*_reference.png`;
2. edit that exact image;
3. change only what the gameplay state requires;
4. preserve geometry, materials, proportions, ornaments and camera.

### Background
Use a plain dark neutral studio background suitable for segmentation/image→3D.

### Composition
- object centered;
- full silhouette visible;
- margin around entire object;
- no crop;
- no environment unless the asset itself is an environment module.

---

## 22. Meshy image→3D rules

Do not create separate meshes for every image state automatically.

### Prefer one mesh + animation/toggles
Use for:
- door open/closed;
- chest open/closed;
- chest empty/full via separate contents mesh;
- trap armed/triggered;
- watcher idle/alert/firing;
- portal active/inactive via VFX.

### Separate topology variant
Use for:
- destroyed doors;
- destroyed structures;
- broken traps;
- heavily damaged/critical Core assemblies where topology changes.

### Recommended export
- GLB/GLTF;
- consistent scale;
- pivot at sensible gameplay origin;
- no baked environment floor unless it is part of the asset;
- preserve material slots where practical.

---

## 23. Godot implementation principles

Presentation and gameplay state should remain separate.

Example family:

```text
VaultChest.tscn
├── VisualRoot
│   ├── ChestBase
│   ├── Lid
│   ├── TreasureContents
│   └── DestroyedVariant
├── AnimationPlayer
├── CollisionShape
├── InteractionArea
└── VFX
```

State changes should toggle/animate children rather than loading an unrelated art asset whenever possible.

---

## 24. Canonical references in this package

The folder `references/canonical/` contains the recovered low-poly artbook visual that summarizes the intended direction.

The production folder contains the individually generated and validated Batch 01 assets. Those validated individual files take precedence over older overview/contact-sheet concepts when there is a conflict.

Priority of truth:

1. **Validated individual canonical asset image**
2. **This Art Bible**
3. **Production manifest/instruction**
4. **Canonical artbook/reference sheet**
5. Older exploratory concepts

---

## 25. Production linkage

The production manifest under:

`../production/manifests/asset_manifest.csv`

lists:
- every planned image;
- state;
- status;
- canonical source reference;
- intended 3D strategy;
- expected model output.

The generation queue under:

`../production/manifests/image_generation_queue.jsonl`

must follow this Art Bible for every future image.

Do not generate an asset simply because it exists in a previous exploratory sheet if it is not listed in the canonical manifest.
