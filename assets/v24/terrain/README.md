# v24 environment artwork

Generated using built-in image_gen. Source prompts are in prompts.json.

All three biomes use source_pixels_per_world=2.0. Materials are cropped losslessly to 512×512 and map to 256×256 world pixels; shader must handle repeating continuity. Four authored platforms per biome share style and brush density. Use their measured body_span and surface_y; keep both 48-source-pixel caps, use center crop/repeat to fill exactly 1/2/3/4×96world; do not stretch. Natural foliage may overhang outside body_span.

Original atlases preserved. middle-objects.png and the six middle-* crops contain complete medium object silhouettes, natural root feet, no hard-cut scene background. Their native density is 2 source/world. The transparent PNG stores colored RGB under alpha zero; an image viewer that ignores alpha may show a glow, while RGBA compositing does not.

The generated material alpha minima are 248–249: draw an opaque biome base underneath the material or force material alpha to 1 in the shader. The material images have no alpha holes.
