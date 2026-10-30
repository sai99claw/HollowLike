# v27 second-jump wing flap art

Production files:

- `assets/v27/player/double-jump-flap.png` — original RGBA2172×724 transparent sprite sheet, four equal543×724 cells.
- `assets/v27/player/double-jump-flap.json` — frame source rectangles, anatomy pivots, visible bounds and timing.
- `assets/v27/player/double-jump-flap.png.import` — lossless engine import, size limit1024 for the entire strip.

Generated with the built-in `image_gen.imagegen` tool, using `transparent_background:true`. No image pixels were edited, cropped or resampled after generation. The engine import scales only the runtime texture; the original remains in source.

The canonical reference is `assets/walk_v2/common/pigeon/walk_00.png`; supporting air-pose reference is `assets/v23/pigeon-air-wall.png`. Identity inspected: grey-blue pigeon, golden-orange eye, cream belly, iridescent neck, navy scarf, pink tucked feet. All frames face right. Wings are entirely inside the corresponding cell. This adds one complete wing flap, not a continuously flying character.

## Runtime mapping

| Frame | Action | Source rectangle | Foot/body pivot |
| --- | --- | --- | --- |
|0|Folded / prepare|0,0,543,724|284,594|
|1|Upstroke|543,0,543,724|329,594|
|2|Forceful downstroke|1086,0,543,724|317,594|
|3|Folded / recover|1629,0,543,724|317,594|

Use one fixed scale `50.9375/333 =0.15296546546546547` for every frame, matching the existing visible standing body height. Do not fit each wing-expanded silhouette to a box; that would shrink the protagonist during a flap. Suggested playback:12.5fps, non-looping,0.32s. The generated body has small horizontal layout offsets; the supplied pivots compensate them using the same head/eye landmark, while keeping the common foot baseline y594. The folded frame and wing-up / wing-down frames have the same head pixel diameter.

When the texture is imported at a smaller runtime size, scale source rectangles by `texture.get_size()/Vector2(2172,724)`; keep destination rectangles and pivots in original pixel units before applying the shared scale. Mirroring should apply to the whole local transform, including pivot.

The asset import adds a small runtime texture suitable for a roughly51px-tall hero; actual Web expanded archive size must still be checked by the release build.

## Exact prompt

```text
Use case: stylized-concept. Asset type: production transparent 2D game animation sprite sheet, a single horizontal row of FOUR equal square cells. Input image1 is the canonical protagonist identity reference (walking pigeon); image2 is supporting air-pose reference only. Create this exact grey-blue pigeon with the same golden-orange eye, short dark beak, cream belly, layered grey feathers with white highlights, iridescent teal-purple neck and dark navy scarf trailing left. Hand-painted gothic fantasy with crisp dark ink contour matching the reference. All four frames face RIGHT in side profile. Animate ONE quick wing flap for the second jump: frame1 folded wing preparing, frame2 wings lifted high in an upstroke, frame3 wings forcefully extended down in a downstroke, frame4 wings folded returning to normal. Keep head, neck, belly, torso, feet and scarf neck knot in EXACTLY the same local position and same pixel size in each equal cell; only the articulated wings and subtle scarf tip change. Tuck the pink feet as in the ascent reference, same feet pivot per cell. Large readable wings must be fully visible inside each cell without touching cell boundary. Composition: FOUR separate full-body birds across one wide strip, aligned body centers and feet baseline, ample transparent margin above and below for wing motion. Exactly four frames, no duplicate extra birds, no grid lines. True transparent alpha background. No ground, no backdrop, no cast shadow, no arrows, no wind rings, no text, no labels, no numbers, no watermark. Original protagonist anatomy and palette must remain unchanged; do not make a chibi or larger-headed variant.
```
