# Android memory diagnosis

## Evidence (2026-09-29)

A user-supplied Pixel 10 report records seven foreground exits for
`org.dungeonempire.prototype` with `reason=3 (LOW_MEMORY)`, including 08:33:03.
The 08:33:14 exit followed a Back action and explicit Godot termination; it
must not be counted as another low-memory failure. Private system logs are
kept outside the repository and are not included in exports.

These exits confirm system memory pressure, not which resource or driver
caused it. The exit RSS values do not describe total GPU/system allocations.
An initial Compatibility run on a Windows NVIDIA GPU remained stable over
600 camera-motion frames: about 54 MiB Godot static memory and 152 MiB engine
video memory. This does not reproduce or rule out an Android driver issue.

## Targeted changes

`_sync_hero` allocated a new proxy material, health-bar mesh, and health-bar
material on every synchronization, even with the 3D health bar hidden on
mobile. Materials and geometry are now created once; desktop health uses
scale, and mobile skips updates to its hidden 3D health label/bar. A regression
test retains resource references across repeated hero updates.

Android debug builds emit a compact `[DungeonMemory]` JSON line every two
seconds: build marker, uptime, renderer, FPS, engine static/video/texture
memory, node/resource counts, and system available/free memory. No user
identifiers or unrelated device logs are collected or transmitted. These
lines can be captured with Android's bug report or `adb logcat`.

## Retest

Install version `0.1.1-memory` over the previous signed APK without clearing
data. First leave the camera still for 30 seconds, then pan/zoom/rotate for
30 seconds, then start a raid. Note when a slowdown or termination occurs.
If it terminates, capture a bug report immediately. Compare the diagnostic
series against the system exit reason before selecting further changes.

No physical Pixel retest has been performed here. The allocation regression
is fixed; the reported Android low-memory termination is not yet proven fixed.

## Pixel retest of 0.1.1-memory

The second user report confirms versionCode 2 / versionName 0.1.1-memory,
with new LOW_MEMORY exits at 09:11:21 and 09:13:29. At 09:13:25.786,
the `am_pss` event for the game's PID reports RSS=13,196,914,688 bytes,
roughly 12.29 GiB, shortly after launch at 09:13:15. This is evidence of
extreme memory use during execution, unlike the much smaller exit-time RSS.
The previous allocation change did not resolve the Android failure.

No `[DungeonMemory]` lines or Godot-tagged messages appear in that report.
The compiled mobile_session.gdc was extracted from the delivered APK and
loaded with Godot: its memory_diagnostics method exists. Missing log samples
must not be interpreted as flat engine memory or as proof of a driver leak.
Root attribution remains open: engine/application allocations versus driver
allocations require further isolation or device-side samples.

`tools/probe_mobile_memory.gd` provides a repeatable graphical desktop probe
with camera motion and a real active raid, with persistence disabled.

## A/B probes (0.1.2)

Run Godot with `--headless --script res://tools/android/configure-ab.gd` to
refresh the two diagnostic export presets from the original preset. Build
with `tools/android/build-debug.ps1 -Variant opengl` and `-Variant vulkan`.
`tools/android/audit-ab.ps1` compares all exported game resources by SHA-256
and verifies the actual command line embedded in each APK.

Both probes use versionCode 3 and the original package/signing identity, so
install one over the other without clearing data. They share saved progress
and the local diagnostic journal. Only backend arguments and version labels
differ; project.godot and the default renderer are unchanged. A failed Vulkan
initialization or fallback must be distinguished from a successful Vulkan test
using the recorded `renderer` and `driver`, not the filename alone.

Debug Android sessions retain at most 90 samples each for the current and
previous session in `user://mobile_memory_v2.json`. Each two-second sample is
flushed to a temporary file, then renamed over the journal. Linux process RSS
is sampled from /proc/self/status alongside engine and system counters; -1
means unavailable. Engine counters, particularly video counters, may be zero
or incomplete for a backend and must not be equated with true process memory.

The next launch opens Pause when a previous session exists. The 3D viewport
and world processing stop while this diagnostic pause menu is open. Copy
the previous diagnostic before resuming. Copy the current diagnostic from
Pause after a successful test. The clipboard contains only our sampled
metrics; no full Android report or device identifiers are included.

Test Vulkan first: 30 seconds stationary, then 30 seconds of camera movement,
then a raid. Repeat on OpenGL only if the phone remains responsive. Record
which stage failed. A faster/stable Vulkan result is evidence for a backend
difference, not proof of a specific driver defect.
