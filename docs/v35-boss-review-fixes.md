# Boss review fixes

The rapid-hit review exposed a shared enemy rule: every tiny hit refreshed a
0.12 second stun and 0.18 second push, preventing every Boss from starting an
attack. Bosses now use a separate damage-based posture budget. Breaking that
budget interrupts the current attack or charge for 0.65 seconds, then a 5.5
second protection period prevents repeated hit interruption. Ordinary enemies
and intentional parries retain their existing response. Damage, flash, impact
sound and hit effects still apply to every hit.

The six existing Bosses now enter phase II at 65% HP and phase III at 30% HP.
Transitions wait for the current attack or charge to finish, occur once each,
and provide a 0.9 second pause. Phase II adds one fixed ecology attack rather
than assigning unrelated random movements on the first engaged frame. Later
phases shorten decision idle time without shortening authored windup or recovery.
HP and player damage were not increased. The Boss room retains its three elites.

Selection now considers horizontal/vertical distance and recent attack history.
The blind-root mole follows root traps with a spreading root projectile and
selects its claw against a close target; later phases use a wider fan. Boss
attack and trap tells are visible with debug hitboxes disabled. Hurt poses no
longer conceal an attack telegraph on every minor hit. The Boss bar shows phase,
phase thresholds, and posture accumulation.

Validation: `test_boss_director_v35.gd` reproduces 20-second rapid micro-hit
pressure for all six Bosses, checks deferred/once-only health phases, death
guards, posture breaks and recovery, and the mole's contextual attack branches.
Existing monster, combat and progression suites are run separately. These are
mechanical checks, not evidence of a human difficulty or enjoyment target.

Remaining: authored arena interactions, coordinated elite roles, distinct new
phase-transition animation/audio, and human playtesting of the experimental
65%/30% thresholds and posture budget. This change deliberately establishes
working combat pacing before adding those encounter-specific systems.
