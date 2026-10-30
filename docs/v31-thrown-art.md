# v31 thrown projectile atlases

Generated with built-in imagegen, genuine transparent backgrounds. Originals copied into the project without raster transformations. Three separate production assets, each eight frames in a4×2 sheet. Each PNG is1774×887; integer cell partitions alternate443/444px. Runtime must apply actual texture/original-size ratios after the1024px lossless import.

`impact_bomb`: compact dark iron/gold cage grenade with orange rune and fuse, clockwise end-over-end rotation. A first draft showed yaw instead of the requested screen-plane rotation; it was rejected and regenerated with explicit fuse clock positions.

`trap_pod`: thornwood seed pod and green core, counterclockwise rotation. `fire_flask`: compact detached ruby vial/gold cage, clockwise rotation at a suggested slower cycle. The old fire weapon shaft/long chain is intentionally absent from the projectile.

Frames2 and6 (zero-based) include short baked rotational brush smears. Other frames remain crisp. No baked trajectory or dust: parent runtime adds translation and limited dust/shadow trails.

Each JSON includes original dimensions, eight frame rects, stable per-frame body pivots, sharp-frame extent metadata, source SHA256, direction and suggested cycle period. Pivots were measured as the largest solid-body interior point from alpha>200; this avoids off-center fuses, necks and smear tails destabilizing the animation. `max_body_extent` is a stable body-scale reference; `max_visible_extent` also includes necks/fuses. Keep one scale per type rather than fitting every frame separately.

These are handpainted gothic fantasy materials with a strong compact silhouette and restrained accent colors: orange bomb, green pod, red flask. Small runtime size requires silhouette/readability to take precedence over fine cage detail.

## Exact prompts

### impact_bomb

```text
Use case: stylized-concept. Exactly EIGHT pictures of ONE grenade rotating CLOCKWISE in the SCREEN PLANE like a spinning coin, NOT yawing around vertical axis. Production2D animation sheet: 4columns2rows uniform cells on transparent background. Spherical black iron bomb, simple antique gold cage ribs, one orange diamond rune, SHORT FUSE sticks out radially. EVERY frame must have the FUSE at specified clock-face direction: top row LEFT TO RIGHT fuse at 12 o'clock,1:30 o'clock,3 o'clock,4:30 o'clock; bottom row LEFT TO RIGHT fuse at6 o'clock,7:30 o'clock,9 o'clock,10:30 o'clock. The orange rune and cage rotate together with the fuse, rigidly. Do NOT keep bomb upright in different views; ROTATE entire object. Bomb center fixed at each cell center, round body diameter halfcell, strong dark handink silhouette, restrained orange accent and ivory rim, handpainted gothic fantasy. Six frames sharp; frame3(fuse exactlyright)andframe7(fuse exactlyleft) alone have light short rotational brush smear. Same scale acrosscells. No text,no numbers,no clocks,no grid,no backdrop,no trail/no dust. Canvas2048x1024 with eight512square cells.
```

### trap_pod

```text
Use case: stylized-concept. Asset type: production 2D gothic fantasy game projectile animation atlas. ONE 4-column by 2-row sprite sheet, exactly EIGHT equal square cells on genuinely transparent background. No grid borders or text. Subject identical compact thornwood seed pod: tapered almond silhouette, simple crossing brown thorn ribs around bright green seed core, two tiny leaves near rear, NO long flame tail. Strong clean ink silhouette, painterly shading, restrained moss-green accent, small pale edge highlights. Stable center every cell, stable object extent about half cell width, large transparent separation. Eight COUNTERCLOCKWISE end-over-end orientations in the screen plane, row-major order 0,-45,-90,-135,-180,-225,-270,-315 degrees. The sharp almond tip revolves counterclockwise. Six crisp key poses; only third and seventh frame have a short subtle dark green rotational brush smear behind the pod while core stays clear. No backdrop, no full-cell glow, no trail, no dust, no trajectory, no extra objects, no shadows on background. Aim2048x1024 with eight512square cells. Clear and recognizable at tiny gameplay size.
```

### fire_flask

```text
Use case: stylized-concept. Asset type: production 2D gothic fantasy game projectile animation atlas. ONE 4-column by 2-row sprite sheet, exactly EIGHT equal square cells, truly transparent background, no grid lines or labels. Subject identical compact incendiary flask: squat round ruby-red glass vial in simple antique gold filigree cage, short narrow neck and sealed gold cap, warm orange liquid inside. NO weapon shaft, NO long chain, NO hanging straps, NO flames extending away. Clear compact silhouette and strong black ink contour with bright ivory rim; restrained deep red dominant accent, painterly gold surfaces. Center of flask body exactly at cell center across all eight cells, stable size about half a cell, large transparent gaps. Row-major eight CLOCKWISE tumbling orientations: cap upright,45degree clockwise,cap right,135degree,cap down,225degree,cap left,315degree. Liquid may shift subtly with gravity, but bottle shape remains identical. Six sharp poses, ONLY third and seventh frame have a restrained short translucent red-gold rotation smear behind the flask. No background, no full-cell glow, no dust or trajectory or explosion. Aim2048x1024 eight512squarecells. Must read as a small thrown object, not an equipped weapon.
```


