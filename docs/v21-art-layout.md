# v21 authored biome atlas notes

Generated using the built-in image_gen tool; six raw transparent PNG files, each actually1254×1254. Original image pixels and alpha preserved. No image editing/resizing/recoloring scripts were used. `analyze_metadata.py` only reads alpha and records regions, anchors and hashes.

`atlas-metadata.json` is authoritative for source regions. The generation did NOT honor equal256px cells: row heights and some column widths vary. Props row1–4 are the four destruction stages; each frame has its own feet anchor and the intact column supplies scaleReferenceHeight. Terrain row2 contains1/2/3cell one-way authored platforms. Row0 scenery objects are3large+3medium; some large neighboring silhouettes touch at their ground baseline and may show tiny adjacent-edge fragments if used as rectangular crops. They are intended for blurred midground placement.

Terrain contains distinct internal/top/bottom/side/convex/concave/standalone/column/platform/decor art. The painted edges are not proven pixel-seamless: the renderer must use exposed-edge masks and shared continuous material sampling for exact seams rather than asserting source texture borders already match. Never alternate mirrored1or2cell stamps; flip whole continuous landscape sections only.

All18small-object species have four visually distinct intact/impact/splinter/rubble frames; metadata hash uniqueness checked for all families. All6sources have alpha extrema0..255 and nonempty bounded regions.
