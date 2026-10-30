# v29 Wind and feather art

Mode: built-in `image_gen.imagegen`; all project PNGs are unmodified generated RGBA originals, copied into the repository. No CLI or programmatic image painting/editing was used.

## Final runtime assets

- `assets/v29/effects/downward-gust.png`: 2048 × 768, four 512 × 768 cells in a horizontal row. Recommended source-cell pivot (256, 100), source-to-world scale 0.18, duration 0.36 s, emission at player feet + (0, -12). `downward-gust.json` supplies exact frame rectangles and alpha > 16 visible bounds.
- `assets/v29/effects/refined-feather.png`: 1254 × 1254, single diagonal white feather. Recommended center pivot (627, 627), 56 × 56 world units for the main death cache or 10–22 world units for slow falling sprites. `refined-feather.json` supplies original size and visible bounds.

Suggested Godot import: lossless, size limit 1024 for gust and 512 for feather. Apply source UV coordinate ratios if the importer shrinks the wind sheet.

## Wind final prompt

Use case: stylized-concept. Transparent 2D action-game effect sprite sheet: four ISOLATED compact WIND GUSTS in one row, each centered in an equal quarter of a wide 2048x768 transparent canvas. Draw painted air currents as two or three simple smooth curved pale ivory cyan brush ribbons per frame. They should resemble a small downward air swoosh or curling descending air wake after a wing clap, NOT feathers, NOT wings, NOT a plume of feather barbs. All strokes flow from top center DOWN and curl outward near the bottom. Frame1 tiny short smooth tapered swoosh; frame2 three curved tapered descending ribbons; frame3 lower curling dissipating ribbons; frame4 two faint separated fading curls. Each of the four effects occupies only the central 260px width of its 512px quarter; leave the other 252px totally empty transparent gutter. Maximum effect height 450px. Hand-painted gothic fantasy, graceful fine gouache brush edges. No outer glow, no fog, no bloom, no cloud, no broad blue haze, no particles, no black backdrop, no matte, no text, no grid, no border, no character. Truly transparent alpha everywhere outside the narrow painted wind strokes. Subtle translucent white/icy cyan ribbons with restrained blue-gray ink undersides, clean readable miniature game VFX.

## Feather final prompt

Use case: stylized-concept. Asset type: one premium transparent 2D game feather sprite, square 1024 by 1024 canvas. Primary request: a single elegant fine white pigeon feather as a lingering death memory collectible in a hand-painted gothic fantasy game. Entire feather clearly visible with large transparent margins. Feather floats diagonally from a thin lower-left quill toward a gently curved upper-right tip, slender long teardrop silhouette, refined densely painted ivory barbs and fine pale silver-blue filaments, a few softly separated barbs near the tip, delicate dark silver central quill, luminous ivory highlights and restrained cool-gray shadows, exquisite but readable at small game scale. Fine ink-and-gouache brushwork, graceful understated melancholy, no heavy outline. No ground, no pedestal, no character, no object besides ONE feather. Real transparent alpha; no solid background, no frame, no text, no watermark, no particle halo baked into the texture. Not a leaf, not a wing, not a flat icon. Keep the tip and shaft intact inside the canvas.

## Wind iterations

The first wing-shaped generation and its targeted revision produced overly feathery silhouettes and overlapping glow. They were rejected rather than exported. The final clean generation uses separate curved air ribbons and intact cell gutters.

Initial rejected prompt:

Use case: stylized-concept. Asset type: transparent 2D game VFX sprite sheet, exactly FOUR animation frames in ONE horizontal row, equal-sized cells, 2048 by 768 canvas. Primary request: a soft downward gust produced by a bird's double-jump wing flap. No bird, no character, only painted wind. Hand-painted gothic dark-fantasy aesthetic, elegant fine ink-edged ivory and cool pale cyan translucent flowing ribbons. Each frame shows a coherent rounded wing-shaped air current pressing DOWN from a narrow upper origin and opening into a wider low curved wake. Readable downward motion: frame 1 tight newborn small downward plume, frame 2 widest curved descending gust, frame 3 longer lower fading ribbon, frame 4 thin fading lower curls. Keep all four frames centered in their own cells with generous 40px transparent margins and no overlap across cell boundaries. Same upper emission point near top center in each frame. Air should feel like a brief graceful push downward, not smoke, not fire, not a tornado, not explosion, no spark particles as main subject. Crisp brush-painted shapes with soft translucent edges, no black opaque background, no white background, real transparent alpha. No words, no numbers, no border, no grid, no watermark.

Rejected revision prompt:

Edit this wind sprite sheet to fix its cell layout and alpha edges. Keep hand-painted pale ivory/cyan flowing downward wind style and FOUR different progressive gust poses. EXACT layout: ONE row of FOUR equal 512 by 768 cells on 2048 by 768 transparent canvas. In each cell keep all visible painted wind inside local x=70..442 and y=80..650 with a completely empty transparent gap around it. Each narrow upper origin must be exactly at local (256,100). Remove the broad fog/glow background entirely. Outside the painted thin wind ribbons must be truly zero-alpha, no matte, no smoky haze. Four isolated compact gusts, all point DOWN and expand toward their lower ends, with gently curving ribbons. Frame 1 short subtle gust ending y=400; frame 2 broad gust ending y=520; frame 3 longer lower gust ending y=590; frame 4 thin fading curls ending y=650. The four sprites must not cross cell boundaries. No text, no grid, no character, no particles, no borders. Preserve real transparent background.

