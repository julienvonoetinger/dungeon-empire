# Trap junction routing

Android Vulkan 0.2.11-trap-route, code 22.

Reproduction: an agile hero routes through a trapped T junction toward a vault
on the perpendicular branch. The old executor unconditionally jumps over the
junction onto the straight continuation. Replanning sends it back through the
same trap, triggering another jump past the turn. This repeats until the old
patience/safety mechanisms eventually intervene.

The route planner now retains its second step. Automatic jumping is permitted
only if the landing equals that step. A turn requires entering the trap normally;
a straight segment still allows a jump with existing collision/landing checks.
Failed routes and new decisions clear stale second-step intent. No shortened
timeout, teleport workaround, trap immunity or changes to trap damage are used.

Regression test: `tests/mobile_trap_route_test.gd` exercises thief and ranger
routing at four rotated junctions. Before: repeated two-cell oscillation in all
eight fixtures. After: junction then goal in two moves. The ranger fixture uses
a vault routing objective purely to isolate shared locomotion (it does not steal).
Additional checks cover a two-trap corner, preserved straight jumps, actual trap
charges and clearing old route intent. Simulation behavior is tested through
`_update_hero`, not only direct jump calls.
