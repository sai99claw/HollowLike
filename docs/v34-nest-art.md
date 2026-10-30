# v0.34 homepage nest artwork

Built-in image generation, RGBA transparency. Final source is `assets/v34/home/nest.png`; original image bytes preserved. Two prompts were used: original generation followed by a targeted simplification/edge-padding edit. References were the existing nest (function/composition only) and v0.33 home background (environment style).

## Prompt 1

Use case: stylized-concept. Asset type: transparent side-view platformer game sprite, an empty pigeon nest for a hand-painted gothic dark fantasy homepage. Reference images: the old nest indicates function and approximate wide silhouette only; the forest homepage supplies atmospheric ink-painted environment style. Primary request: redraw this nest as a complete, elegant low wide cradle woven from a few flowing dark branches, restrained emerald moss and a small canopy of two broad dark green leaves over the LEFT quarter only. Warm ivory feather lining gently curls around a visibly empty central resting space for a small pigeon that will be rendered separately. Strong clean readable silhouette at 260 x 100 game pixels, broad shapes, delicate ink outlines, controlled painterly shading, subtle feather linework. Overall object width about 2.7 times its height, with modest empty transparent padding on all sides; full silhouette contained. The lower third is the front woven rim and will be drawn over the separate bird. Orthographic side view with slight visibility into the bowl, low camera. No bird, no egg, no text, no symbols, no background, no environment, no cast shadow outside the silhouette, no photorealistic straw, no bright yellow outlines, no glow, no cut-off tips. Actual RGBA transparency.

## Prompt 2

Edit only this game nest asset for production readiness: add generous real transparent padding around ALL sides (about 6% canvas width and height) so every branch, leaf and feather fits completely inside canvas with no clipped tips and every outermost edge is transparent. Preserve the side-view low wide nest, empty center, dark green leaf canopy on left, warm ivory feather lining, silhouette and composition. Simplify the tiny bark and straw texture into broader hand-painted ink shapes suited to a small gothic fantasy game sprite; keep delicate feather edges. Reduce the gold/yellow rim lighting to muted cream. No bird, no eggs, no text, no background; genuine RGBA transparency.

## Validation and use

Inspected final image. Empty central feather lining, left leaf shelter, full side-view woven nest, no bird or eggs, painterly ink outline, restrained dark emerald leaves and ivory feather lining. Final PNG is 2025×777 RGBA; borders alpha at most 1. Visible bounds and base pivot are recorded in `nest.json` using alpha threshold 8. Import maximum edge is 512 with lossless compression; original PNG stays unchanged. Runtime should preserve aspect, use about260px width (about100px height), and render the lower30% over the sleeping pigeon. The central bed is near70% of source height. Align the base to the home branch, retaining the separate existing sleep animation.

Generated source1: `/workspace/scratch/04706064e0ec/generated_images/exec-65ecff74-e571-452b-a844-decc066751b3.png` (not consumed).

Final source2: `/workspace/scratch/04706064e0ec/generated_images/exec-50a7e199-4a46-499a-9d31-5342e36f7e8d.png`.

