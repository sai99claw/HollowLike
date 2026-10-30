# v29 station artwork

Generated with the built-in `image_gen.imagegen` tool, two separate calls, `transparent_background: true`. Both production PNGs preserve generated RGBA transparency. No previous art was overwritten.

Style reference inspected: `assets/v26/stations/blueprint-forge.png`. Direction: hand-painted gothic fantasy with crisp ink contour, aged gold, carved wood or ivory stone and restrained cyan/teal accents. The pedestal deliberately contains no weapon so the selected free weapon can float over the top in the game.

## Source geometry

Use original-source coordinates below, scaled by the actual imported texture size / original size when drawing. Bounds use alpha > 8 to exclude invisible generated edge residue. These crops do not cut opaque art.

| Asset | Original size | Source rectangle (x, y, width, height) | Bottom-center pivot | Suggested world size |
| --- | --- | --- | --- | --- |
| free-weapon-pedestal.png | 1536 × 1024 | 205, 365, 1127, 596 | 768.5, 961 | 112.7 × 59.6 |
| cloak-wardrobe.png | 1312 × 1199 | 89, 1, 1141, 1160 | 659.5, 1161 | 112 × 113.9 |

The pedestal's top center is approximately (768, 421) in the original source. This point is about54 world pixels above its bottom when displayed at112.7px wide. Float the weapon centered 12–20px above that top support.

Both source images are intentionally imported losslessly at a maximum512px dimension. This leaves around4source pixels per world pixel at suggested world sizes and limits the Web texture budget. Reuse cached textures; do not load every frame.

## Final prompts

### free-weapon-pedestal.png

```text
Use case: stylized-concept. Asset type: transparent-background 2D side-view fantasy platformer prop sprite, SINGLE ornate reward weapon pedestal. Primary request: a beautiful small gothic ivory-stone pedestal for displaying one floating secondary weapon, but draw NO WEAPON. Hand-painted intricate dark fantasy game art with crisp ink contour, brush-shaded carved ivory stone, aged restrained gold filigree, small cool cyan gemstone accents. Front/side orthographic view suitable 2D platformer, modest top-down visibility only on its small flat horizontal top support. Pedestal has an elegant symmetrical flared foot and carved pointed-arch motifs. Top support roughly upper-third of object with CLEAR EMPTY TRANSPARENT SPACE above it for runtime weapon sprite. Compact low platform not a towering column; width slightly more than height. Center object on canvas with generous transparent margins all sides. No text, no runes lettering, no characters, no weapon, no floor plane, no background, no checkerboard baked in, no contact shadow beyond object. Actual RGBA alpha transparency. Match a mature hand-painted gothic fantasy game with controlled gold/ivory single-color emphasis, not cartoon plastic or photoreal 3D.
```

### cloak-wardrobe.png

```text
Use case: stylized-concept. Asset type: transparent-background 2D side-view fantasy platformer interactive wardrobe station sprite, ONE self-contained dressing alcove prop. Primary request: ornate gothic cloak changing station, carved dark walnut frame with restrained aged gold trim, pointed arch, an elegant central cloak hanging on a mannequin stand (no head, no person) and two folded fabric bolts on a low cabinet; small cool teal glass lantern on one side, small oval antique mirror on the other side. Readable silhouette with a stable flat floor base. Hand-painted dark fantasy game art with fine ink contour, painterly fabric folds and material shading, detailed but readable at small scale, controlled teal accent and muted warm browns/gold. Front-facing orthographic view for 2D side-scroller, slight top visibility only, not isometric. Full object centered, generous transparent margin on every side. No character, no weapons, no text, no lettering, no symbols pretending text, no UI, no floor plane, no background, no checkerboard baked in. Actual alpha transparency. Mature gothic fantasy not plastic 3D. Cloak accents should be dark teal/cyan.
```

