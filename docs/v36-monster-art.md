# v0.36 authored monster animation integration

The three frozen ecology briefs precede image production. Each ecology has five
regular species and two chapter elites. Regular animations use twelve columns:
three movement poses, three windup poses, three active poses and three recovery
poses. The two elites each own two rows so their two attacks use different
anatomical preparation and execution. Projectile and effect rows contain eight
model-authored views, including their painted trailing dust and selective motion
blur. Axial projectiles follow velocity; tumbling projectiles retain the launch
axis while their authored frames supply rotation.

`prepare_monster_art_v36.py` retains original PNGs in `assets/v36/monsters/source`
and makes compact runtime atlases plus exact region/pivot metadata. Every row
shares one scale; feet are aligned and transparent padding is added without
scaling each animation pose independently. Actor body height remains50.9375 world
units, with elites using sqrt(2) times that height. Runtime imports must retain
the prepared atlas dimensions; tests check that exact contract in source/PCK.

New monster projectiles use their painted sprites and a small dust emitter.
Legacy glowing polyline trails and circular cues are bypassed only for these
assets. Planted traps use their own growth/armed sprite sequence at the floor.
RD lists actual phase sequences and their runtime usage.

Limitation: separate death sheets were not requested in this batch. Corpses keep
the correct new species, using the final recovery pose compressed into a resting
silhouette during the existing physical fall; dedicated death art remains a
future polish task. Old species are never substituted for a new species corpse.


The final source actor sheets use six columns and two rows per action (movement
plus windup, then active plus recovery). The extractor remaps them into the
unchanged twelve-column runtime layout. Trunk poses use artist-measured source
rectangles; other actor rows use measured alpha bands instead of assuming equal
row spacing. Whole-source projectile components are selected before cropping,
so an authored arrow tip crossing a nominal cell boundary is retained. Effect
dissipation preserves multiple owned particles. Runtime cells have an absolute
transparent guard border and source images remain untouched. The producer uses
Pillow, NumPy and SciPy; prebuilt runtime images do not require these in game.
