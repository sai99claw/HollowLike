# v0.30 bird mantle redraw

## Review and integration

Previous v29 images have upright humanoid tube collars, rendered42worldpixels high on a51pxpigeon. Fixed foot-relative mounting and oversized collar silhouettes caused floating or obscuring cloth. Four new images remove the tube collar and use flat clasps and shallow bird mantles. Pigeon walk/air-wall artwork was viewed before drawing. The new four strips were visually inspected, with manually measured clasp pivots checked against alpha>16.

Files: assets/v30/cloaks/{street,future,medieval,cute}.png, catalog.json and lossless1024px .png.import settings. Each original PNG2172x724, three724squareframes, real transparent RGBA. Original appearance has no overlay; its catalog texture references v29 solely for menu preview.

Use constant style-wide scale min(22/visible_height,36/visible_width). Pivots local to each cell. Mirror entire local transform. Attach to anatomical nape / original scarf point per pose, not constant feet-relative offset. Neutral starting point(-6*face,-32) fromfeet, parent must verify actor transforms. Prefer cloth behind frontwing/body. Review idle/walk/air/wall/landing after integration; this asset task does not claim runtime visual verification.

## Provenance

Builtin imagegen, separate call per style. These are new regenerations after previous unpushed outputs were lost during environment reset, not identical recoveries. No old cloak recoloring.

## Exact prompts

Shared prompt:

> Use case: stylized-concept. Asset type: transparent 2D platform-game cosmetic sprite strip. Draw THREE horizontal animation frames of ONLY a TINY BIRD SHOULDER MANTLE / SHORT SCARF-CAPE for a round pigeon facing right. Handpainted dark gothic fairy-tale game art, crisp dark outline, soft painted cloth. Canvas2172x724, three equal724x724cells with generous transparent separation. In each cell the small SOFT FLAT CLASP attachment is at local[600,250]. Fabric trails LEFT and only slightly DOWN, shallow miniature triangular mantle silhouette. Frames: relaxed, gently lifts tail, settles; clasp never moves. NOT humanoid clothing. NO tube collar, NO upright collar, NO cylindrical opening, NO neck ring, NO torso, NO bird, NO mannequin, NO head, NO arms, NO body, NO weapon. Upper-right clasp is just a tiny flat fabric knot/pin. Whole mantle only22pxhigh36pxwide runtime on51pxpigeon, so minimal details. Transparent RGBA. No text/shadow/floor.

Suffixes:

- street: Charcoal cloth, one broad red stripe, ivory piping, tiny flat silver clasp.
- future: Ink blue cloth, two thin cyan luminous seams, tiny flat cyan clasp; no armor.
- medieval: Burgundy cloth, antique gold border, flat gold pin, compact scalloped tail.
- cute: Dusty rose cloth, ivory scalloped trim, tiny flat ribbon knot, no giant bow or dress.

