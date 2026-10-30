# v26 station artwork

Generated with the built-in `image_gen.imagegen` tool in three separate calls, with `transparent_background: true`. Each original production sprite is RGBA PNG at 1254 × 1254. No existing art was overwritten; no text labels are embedded in the artwork. The original tool outputs remain outside the checkout; these three project copies are the production assets.

The art was inspected against `assets/v21/props-trunk.png` and the existing delivery-station sprite. The visual direction is hand-painted gothic fantasy, charcoal timber/stone, aged brass and a restrained jade/teal accent. The three stations have distinct silhouettes, and the reforge altar has three empty rune sockets.

## Integration bounds

The source images preserve genuine generated alpha, including a faint, almost transparent edge residue. To align visible feet with the floor, render a source rectangle rather than fitting the full square texture. Suggested source rectangles at alpha ≥ 8:

| Asset | Source rectangle (x, y, width, height) |
| --- | --- |
| `assets/v26/stations/blueprint-forge.png` | `15, 151, 1210, 950` |
| `assets/v26/stations/rune-reforge.png` | `26, 54, 1206, 1131` |
| `assets/v26/stations/warehouse.png` | `38, 14, 1178, 1198` |

Scale the source rectangle proportionally and anchor its bottom center to the station position. Keep a persistent texture reference, as with the v25 texture-lifetime fix.

## Exact generation prompts

### blueprint-forge.png

```text
Use case: stylized-concept. Asset type: transparent 2D side-scrolling game station sprite. Primary request: one blueprint forging workbench for a hand-painted gothic dark fantasy pigeon adventure. Subject: squat ancient carved dark wooden workbench with compact jade-lit forge, small anvil, rolled pale blueprint parchment and feather-shaped metal tools, arched wrought-brass support, roots around feet. Style: richly hand-painted ink outlines, storybook gothic fantasy, readable bold silhouette and restrained fine detail. Palette: charcoal timber, aged warm brass, a vivid but restrained jade/teal main accent, ivory blueprint, tiny amber forge center. Composition: single isolated complete prop, front-facing with slight view of bench top, orthographic 2D platformer side-view; ground baseline horizontal; object entirely visible with generous transparent padding; no character. Lighting: dramatic soft jade highlights, crisp dark contours; no cast ground shadow outside the object. Constraints: real transparent alpha background, no scenery, no floor, no text, no letters, no labels, no watermark, no white outline, no cropped edges. Production sprite approximately 1024 square.
```

### rune-reforge.png

```text
Use case: stylized-concept. Asset type: transparent 2D side-scrolling game station sprite. Primary request: one rune reforging altar for a hand-painted gothic dark fantasy pigeon adventure. Subject: low ancient dark-stone altar, three large round empty rune sockets in a clear horizontal row on its sloped top surface; three thin jade magical arcs converge above the sockets into a small central crucible, gothic brass fittings, carved feather motifs, roots wrapping short legs. Make the three hollow circular sockets immediately readable, fully empty black recesses with jade rim accents. Style: richly hand-painted ink outlines, storybook gothic fantasy, strong readable silhouette and restrained fine detail matching an ancient jade-lit timber forge. Palette: charcoal stone, aged warm brass, vivid but restrained jade/teal single main accent. Composition: single isolated complete prop, front-facing with slight view of altar top, orthographic 2D platformer side-view; horizontal ground baseline; all edges visible with generous transparent margin; no character. Lighting: soft jade light at socket rims and upper magic arcs, crisp dark contours; no cast ground shadow outside object. Constraints: actual transparent alpha background, no scenery, no floor, no text, no letters, no labels, no watermark, no white outline, no cropped edges. Production sprite square.
```

### warehouse.png

```text
Use case: stylized-concept. Asset type: transparent 2D side-scrolling game station sprite. Primary request: one home warehouse storage cabinet for a hand-painted gothic dark fantasy pigeon adventure. Subject: stout ancient dark wooden storage cabinet with an arched gothic crown, several clearly separated drawers and open pigeonhole shelves displaying small jade rune stones, a rolled blueprint, a potion flask, a sheathed small weapon, and a small closed brass-bound chest at its feet. Feather-shaped brass lock on central door; short twisted roots wrap its base. Style: richly hand-painted ink outlines, storybook gothic fantasy, readable bold silhouette and restrained fine detail, matching an ancient jade-lit forge. Palette: charcoal timber, aged warm brass, ivory tiny accents, vivid but restrained jade/teal dominant magical accent. Composition: single isolated complete cabinet, front-facing with slight side depth, orthographic 2D platformer side-view; horizontal ground baseline; fully visible with generous transparent padding; no character. Lighting: subtle jade glow inside compartments, crisp dark contours; no cast ground shadow outside object. Constraints: actual transparent alpha background, no scenery, no floor, no text, no letters, no labels, no watermark, no white outline, no cropped edges. Production sprite square.
```



## Web texture import budget

The full 1254px originals remain in source. Godot imports the three world props losslessly with `process/size_limit=512`. At their maximum144×116 world display this retains more than two source pixels per world pixel, while keeping the expanded Web deployment within the hosting256MiB limit. `StationArtV26` rescales the measured original source rectangles to actual imported texture dimensions before drawing.
