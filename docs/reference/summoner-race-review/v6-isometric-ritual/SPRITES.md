# Baking the Oculin ritual

The mobile game loads the painted clearing and a transparent 6 × 8 summoner sprite sheet and an independently painted Dungeon Master from assets/game/introduction. The working 3D project is kept here under docs/.gdignore.

To regenerate the poses, use Godot 4.7.2 with the Compatibility renderer. From the repository root in PowerShell, run the following with Godot on the path.

    $sourceProject = 'docs/reference/summoner-race-review/v6-isometric-ritual/source_project'
    $frames = (New-Item -ItemType Directory -Force artifacts/introduction/sprite-bake).FullName
    godot --headless --path $sourceProject --editor --import
    godot --path $sourceProject --resolution 320x240 --script res://bake_sprites.gd -- $frames
    python docs/reference/summoner-race-review/v6-isometric-ritual/pack_sprites.py

The bake renders a 1536 px square covering 14 world units. Its clean plate was the reference for the hand-painted-style ImageGen background. The approved painting is stored as ritual-painted.webp. All 46 transparent foreground frames use the same camera and crop, including the Oculin, rift, shards and motes. The separate sovereign sprite emerges in front of the rift and sinks into the altar on descent. Frames 0–32 summon, 33–40 sustain and 41–45 descend. The 2D runtime applies framing, animated ground light and the threshold reveal.

The original rig and environment remain in source_project. To rebuild that GLB from the immutable Meshy input, run build_glade.py in background Blender.
