# v0.29

- Screen-space virtual joystick lower-left; lower-right rows secondary/primary and dash/jump; heal upper-right. Web controls use fixed CSS positioning and safe-area insets, independent of game camera/letterboxing. Saved toggle in Settings → Controls. Independent pointer capture, cancellation and focus-loss cleanup.
- E rune page first Down focuses random auto-equip. Confirmation randomizes up to16 small and3 distinct large runes; preparation room may draw required copies from home stock. No rune is consumed.
- All secondary weapons have zero startup, including grounded attacks and Musou salvo.
- Dedicated ornate free-weapon pedestal; cloak changing station in home and preparation rooms.
- Five cloak choices: original (existing scarf), street, future, medieval, cute. Other cosmetics overlay cloak sprites only; no body tint or combat-stat changes. Three flutter frames per cloak; preview on original bird.
- Four-frame downward gust texture on double jump; detailed handpainted feather texture for death cache and slow falling feather particles. All dropped runes have a white radial halo.

Artwork prompts and builtin imagegen provenance: v29-cloak-art.md, v29-station-art.md, v29-wind-feather-art.md.

Validation: all29 exported-resource regression suites passed before final cloak downsampling; browser input JavaScript test passed for simultaneous pointer holds, independent release, pointer cancellation, menu hiding, focus loss and viewport resizing. Browser gameplay verification remains unavailable in the remote preview because WebGL2 and secure context are absent. Final build rechecks exported-resource suites and SHA256 chunk manifests.

Additional combat feedback changes: five original procedural PCM effects (44.1kHz mono) for explosion, ground impact, single dash wind, deeper double-dash wind and primary attack whoosh. Generator: scripts/generate_sfx_v29.py. Noise filtering, falling pitch and layered transients distinguish the five actions; no external recordings. Up to12 concurrent effect voices keep wind and impacts from cutting each other off. Impact atlas remains; procedural hit rings, circular glow and screen-length geometric glare are no longer drawn. Brief actor hit tint and charge feedback remain.
