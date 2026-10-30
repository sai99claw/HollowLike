# v33 spring art

Generated using the builtin imagegen tool, three independent calls. Original transparent PNG outputs were copied unchanged into the project; no raster transformations or Python image editing. Python was used only to inspect alpha, bounds, and coordinate metadata.

## Assets and runtime contract

- `assets/v33/springs/sky.png`: pale stone, feather/cloud relief, sky-blue water.
- `assets/v33/springs/trunk.png`: rooted stone, moss and fern corners, jade-green water.
- `assets/v33/springs/underground.png`: basalt, gothic tracery and amber crystals, gold water.
- All three originals are1774×887 RGBA. PNG imports are lossless with `process/size_limit=512`; original files remain untouched.
- Per-asset JSON includes `original_size`, `body_bounds` (alpha>20), `pivot_source`, `water_rect_source`, `water_surface_source`, `world_body_width`, `world_scale`, `water_offset_world` and SHA-256. Very low-alpha generated padding is excluded from physical body measurements, never cropped off the bitmap.
- Use uniform scale180/body_bounds.width for180worldpx visible width, anchor `pivot_source` at the ground. The three water surfaces align approximately35worldpx above ground; maintain this anchor for contact/particle origin. Actual full silhouette heights are about61/64/71worldpx, within the requested low-basin footprint.
- Complete oval silhouettes and clear water surfaces were visually inspected. No baked splash, droplets, steam, jets, impact or particle effects; attack response must use native water-droplet particles.

## Exact prompts

### sky

Use case: stylized-concept. Asset type: production transparent 2D side-view game sprite, one small restorative spring. A low oval basin of pale blue-grey weathered stone, gently scalloped feather/cloud carvings along front rim, clear luminous sky-blue water in a broad shallow ellipse. A few small blue crystals on the back lip, no tall fountain sculpture. Hand-painted gothic dark fantasy, elegant ink outline, simple readable shapes and controlled shading, restrained single blue accent with ivory rim light, suitable for tiny 180-world-pixel width by90-world-pixel height in a side-scrolling game. Front-facing side view with slight view onto water surface. Centered on a wide landscape canvas; full basin uncut, generous truly transparent RGBA padding on ALL sides. Water calm and unobstructed, no splash, no floating droplets, no water jets, no steam cloud, no particles or effects baked in. No scenery, floor plane, backing glow, text, labels, frame border, characters or tools. Exactly one complete object. Clear grounded bottom anchor and visible central water surface.

### trunk

Use case: stylized-concept. Asset type: production transparent 2D side-view game sprite, one small restorative spring. A low oval basin built of dark carved living tree roots and weathered grey stone, emerald moss tucked around the lower rim and only two small fern fronds at rear corners, clear luminous green-jade water in a broad shallow ellipse. Same readable low oval bowl silhouette as a small stone bathing spring, no tall fountain sculpture. Hand-painted gothic dark fantasy, elegant ink outline, simple readable shapes and controlled shading, restrained emerald green accent with muted ivory rim light, suitable for tiny180-world-pixel width by90-world-pixel height in a side-scrolling game. Front-facing side view with slight view onto water surface. Centered on a wide landscape canvas; entire basin uncut, generous truly transparent RGBA padding on ALL sides. Water calm and unobstructed, no splash, no floating droplets, no water jets, no steam cloud, no particles or effects baked in. No scenery, floor plane, backing glow, text, labels, frame border, characters or tools. Exactly one complete object. Clear grounded bottom anchor and visible central water surface.

### underground

Use case: stylized-concept. Asset type: production transparent 2D side-view game sprite, one small restorative spring. A low oval basin of dark basalt and weathered warm grey stone, three small honey-amber crystals embedded in the back lip, clear luminous amber-gold spring water in a broad shallow ellipse. Front rim has simple gothic root tracery. Same readable low oval bowl silhouette as a small stone bathing spring, no tall fountain sculpture. Hand-painted gothic dark fantasy, elegant ink outline, simple readable shapes and controlled shading, restrained single amber main accent with ivory rim light, suitable for tiny180-world-pixel width by90-world-pixel height in a side-scrolling game. Front-facing side view with slight view onto water surface. Centered on a wide landscape canvas; full basin uncut, generous truly transparent RGBA padding on ALL sides. Water calm and unobstructed, no splash, no floating droplets, no water jets, no steam cloud, no particles or effects baked in. No scenery, floor plane, backing glow, text, labels, frame border, characters or tools. Exactly one complete object. Clear grounded bottom anchor and visible central water surface.

