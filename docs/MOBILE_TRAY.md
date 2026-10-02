# Collapsible mobile construction tray

The preparation tray has a chevron handle above its top edge. Toggling hides
the tool list and confirmation bar, leaving a 64-logical-pixel status strip.
The selected tool, category and target remain unchanged. Expanding restores
them. The handle and confirmation bar have separate rectangles.

The preference is stored separately from the run in user://mobile_ui.cfg.
Production preference reads/writes are gated by persistence_enabled; tests
use explicit isolated paths. Existing saves need no migration.

Core anchoring keeps its dedicated confirmation bar. Raids retain their
existing compact status bar and hide the handle. Preparation restores the
player's remembered choice. Hidden UI no longer intercepts map input, while
the handle's touch rectangle remains excluded from camera gestures.

tools/capture_tray.gd checks both tray states at 1280x720 and 960x540 with
Vulkan, then checks the confirmation bar and handle do not overlap.
