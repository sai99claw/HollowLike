# Delivered v0.7 art adapter

Merged from the user's fifteen `v05-art-batchNN-*.zip` packages: 277 animation clips, 1193 RGBA frames. `manifest.json` is authoritative; each clip retains its frames, dimensions, pivot, authored phase information and analyzed alpha bounds. Original PNG bytes are preserved. Godot imports most frames at up to256px; six sets of far/middle/near environment layers use up to1024px. Rendering scales against original metadata and imported texture dimensions.

The separate `assets/walk_v2/manifest.json` supplies the new12-frame walking cycle. Existing `assets/illustrated/` backgrounds/platforms/locomotion fallbacks and `assets/bosses/` baseline Boss sheets remain available.

Runtime consumers: `combat_visual.gd`, `environment_art.gd`, `ui_asset_art.gd`, `boss_art.gd`, `atmosphere.gd`, `combat_feedback.gd`, and `main.gd`. Full mapping and remaining dedicated art requests: `docs/asset-audit.md`.
