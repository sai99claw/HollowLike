# v33 安全屋背景與站點美術

以內建 imagegen 生成；沒有使用 CLI/API fallback。所有選定 PNG 直接複製到專案，未做裁切、縮放、去背或像素編輯。Godot 的 lossless import size_limit=1024 控制執行時體積；原始 PNG 都保留1536×1024。

## 交付

- `assets/v33/safehouses/sky-background.png`：藍灰石造天空拱廳，羽毛窗飾與雲海。
- `assets/v33/safehouses/trunk-background.png`：綠色樹幹根木拱廳、蕨葉與苔蘚。
- `assets/v33/safehouses/underground-background.png`：琥珀玄武岩地底拱廳、晶礦與樹根。
- 同目錄三張 `{biome}-stations.png`：3欄×2列透明圖集，共18件同功能、同類輪廓的生態變體。
- 每張 PNG 附 `.json` 和 `.png.import`。JSON 包含來源尺寸與 SHA-256；站點另有逐格來源rect、local pivot、alpha>=32的完整bounds。

站點順序：第一列 `aid`（十字小聖壇）、`forge`（雙角鐵砧）、`reforge`（三孔重鑄台）；第二列 `mail`（倉庫箱）、`energy_infinite`（直立能量晶柱）、`wardrobe`（拱形披風衣架）。藍色石銀、綠色木根與青銅、琥珀玄武岩與古銅分別符合三種生態。輪廓種類、主要結構與功能標記一致，材質裝飾不同。

背景保留3:2原始比例。繪製時可用附帶的 `floor_y_source` 作後景地平線參考：sky740、trunk670、underground670；實際碰撞與站點位置仍由遊戲管理。

圖集引用原始rect時應乘 imported texture size / original_size；pivot與bounds仍是每格local來源座標。完整物件等比例縮放到站點框，不可把整個透明格誤當主體。

## 檢視與修正

第一輪站點生成有幾件太貼近名義格線，部分晶柱越過列界。因此以imagegen對三圖集分別做同一項布局修正：縮小並置中每件、保留設計與配色，加入充分透明間距。最終六格每個可見主體都離左右格線至少20px、離上下格線至少10px；未截斷鐵砧角、箱腳或衣架頂端。背景及修正後三張圖集均逐張檢視。最終站點PNG的alpha範圍0–254，透明格線沒有實體物件；來源與複製檔雜湊相同。

## 原始生成提示詞

### Sky background

Use case: stylized-concept. Asset type: finished production 2D side-view game safehouse BACKGROUND. Landscape 3:2 composition. Elegant hand-painted gothic dark fantasy interior in a sanctuary high above clouds, with pointed blue-gray stone arches, airy carved feather tracery and distant blue sky seen through tall windows. Strong simple ink outlines but soft restrained painterly shading, rich controlled single dominant azure/icy blue palette with tiny ivory highlights. Architecture belongs to a sky ecology. Left and right edges contain unobstructed open arched passage recesses at the SAME low floor level; the middle lower 45 percent is an OPEN, uncluttered playable room. A thin rear balcony at 45 percent height across central room is only a background silhouette, not a bold foreground platform. Front view with very little perspective. All architecture must read as distant backdrop with low contrast; no bright focal glows competing with player. No foreground furniture, no stations, no anvil, no chest, no actors, no text, no labels, no interface, no watermark. Safe and beautiful, detailed at edges but clear negative space in central room. Entire painting fills canvas; opaque background.

### Trunk background

Use case: stylized-concept. Asset type: production 2D side-view game safehouse BACKGROUND, opaque landscape3:2. Hand-painted inked gothic fantasy interior carved into the hollow of an immense living tree: elegant pointed arches made of braided wood roots, emerald moss, fern details, distant cool green forest through windows. Restrained rich EMERALD GREEN dominant palette, muted olive wood, very small ivory daylight accents. Low contrast rear architecture, simple broad silhouettes and refined controlled painterly texture rather than photorealism. Open arched passage recesses at BOTH left and right edges at SAME low floor level. Lower central45percent is a spacious clear playable room; a delicate rear balcony silhouette at45percent height behind future game stations. All furniture and game stations will be separate sprites; do not paint any in. No foreground obstacles, no characters, no chest, no anvil, no stations, no signage, no text, no interface. Nearly flat front view, no strong converging perspective, clear lateral room navigation. Warm safe mood, elegant dark fantasy, distant luminous forest atmosphere, no large bright focal lamp.

### Underground background

Use case: stylized-concept. Asset type: production 2D side-view game safehouse BACKGROUND, opaque landscape3:2. Hand-painted inked gothic dark fantasy sanctuary beneath an enormous tree, spacious underground cavern hall with pointed arches carved from warm basalt, root buttresses and subtle amber crystal inlays; soft distant amber-lit cave ruins visible through arch windows. Restrained rich AMBER/OCHRE dominant palette, warm charcoal stone, tiny ivory highlights. Low contrast background architecture, clear broad silhouettes and elegant controlled painterly shading. Open arched passage recesses at BOTH left and right edges at SAME low floor level. Lower central45percent is open uncluttered playable space. A delicate rear balcony silhouette at45percent height behind future game stations. All furniture and game stations are separate sprites and must not be painted here. No foreground rocks or obstacles, no characters, no chest, no anvil, no stations, no text, no labels, no UI. Flat side-view room, little perspective. Safe and quiet, sophisticated dark fairy-tale architectural painting, no big central light bloom.

### Sky station atlas

Use case: stylized-concept. Asset type: finished production 2D side-view gothic game STATION SPRITE ATLAS. Exactly SIX detached complete objects in a strict THREE columns by TWO rows equal grid, landscape3:2 transparent RGBA canvas. All six at same source pixel density, clear silhouettes and clean strong ink outer contours, hand-painted dark fantasy. Restrained azure blue, pale carved stone, antique silver, tiny ivory accents, appropriate for a sky safehouse. Top row left to right: (1) healing shrine: low pointed little reliquary with a pale ivory medical plus-shaped cross cutout at its center, NOT red; (2) forge: instantly recognizable heavy anvil on a broad squat stone stand, two raised anvil horns, blue feather scrollwork; (3) rune reforge altar: waist-high broad alchemy desk with exactly THREE circular empty socket holes clearly visible across its front. Bottom row left to right: (4) warehouse: squat broad closed storage chest with domed lid and center lock; (5) energy station: narrow tall upright luminous blue crystal on a small stepped pedestal; (6) cloak wardrobe: tall freestanding arch-shaped hanger with a small hanging blue cloak inside it. These six silhouettes must be distinct and reusable for matching green wood and amber stone variants. Front side view, objects roughly equal importance; each stays entirely inside central70percent of its own cell, ample transparent margins on all sides, no overlap, all bottoms align75percent down each cell. No environment, no floor plane, no ground shadows, no labels, no text, no grid lines, no actors, no weapons, no piles of loose items. Transparent background is essential. Exactly six objects total.

### Trunk station atlas (sky atlas as edit target)

Precise material-and-color variant of the referenced six-object station sprite atlas. Preserve EXACTLY the same 3 columns x2rows grid, object identities, outer silhouettes, proportions, object centers, occupied footprints and bottom anchors. Transparent RGBA background. Transform the SKY stone/silver/blue material family to a TREE-TRUNK safehouse family: carved dark wood and braided roots, emerald moss, green crystal, muted aged bronze trims. Dominant restrained EMERALD GREEN accent. Keep hand-painted gothic inked fantasy style. Top row same three objects: shrine with ivory PLUS cross; anvil with broad two-horn silhouette on squat stand; three-socket reforge desk with exactly3 dark circular holes. Bottom row same chest; tall upright energy crystal; arched freestanding hanging cloak station. The anvil remains dark metal; everything else may show rootwood and moss as material decoration WITHIN the preserved contour. Six distinct complete detached objects. NO backgrounds, NO dark or colored rectangle backing, NO connecting floor, NO ground shadow, NO text, NO labels, NO extra objects. Clean full transparency surrounding objects is essential.

### Underground station atlas (sky atlas as edit target)

Precise material-and-color variant of referenced six-object station sprite atlas. Preserve EXACTLY the same 3 columns x2rows equal grid, all six outer silhouettes, proportions, source pixel density, object centers, footprints and bottom anchors. Transparent RGBA. Transform SKY stone/silver/blue theme to UNDERGROUND safehouse theme: warm dark basalt, ochre mineral veining, amber crystal, restrained ancient bronze trim and small root engravings. Single rich AMBER/GOLD main accent, not rainbow. Retain refined hand-painted gothic fantasy black ink silhouette. Top row: ivory plus-cross healing shrine; dark-metal two-horn anvil on broad squat stone stand; wide reforge altar with EXACTLY3 empty round holes. Bottom row: storage chest; tall faceted amber energy crystal on narrow pedestal; arched freestanding cloak hanger holding an amber cloak. The same six contours must be recognizable across biome variants. NO colored or black background, NO glow backing, NO floor, NO ground shadows, NO text, NO labels, NO new objects. Generous truly transparent gaps around and between all objects.

### Final gutter correction (each biome atlas as separate edit target)

Production atlas layout correction ONLY. Preserve exactly these six station designs, colors, materials and outlines. Keep same 1536x1024 landscape3:2 canvas, three equal columns by two equal rows. IMPORTANT: SHRINK EVERY OBJECT by about25percent and recenter it WITHIN ITS OWN CELL. Objects must NOT touch cell boundaries. Top-row objects centered x256/768/1280, bottom-row x256/768/1280. Top row max occupied area x80..432 /592..944 /1104..1456 and y80..432. Bottom row same x windows, y592..944. This means every station fits entirely inside a352x352 pixel box, with generous fully transparent gutters. Tall energy crystal, cloak frame and shrine must shrink to fitheight352; wide anvil and chest must shrink to fitwidth352. Keep their aspect ratios. The six objects remain in current order: healing shrine, anvil,3socket altar; chest,crystal,cloak wardrobe. Preserve full complete silhouettes and do not cut any extremity. ABSOLUTELY NO PIXELS in thick transparent bands around x512, x1024 and y512. No glow backing, no black/colored backgrounds, no floor, no shadows, no labels, no text. Truly transparent RGBA background between all objects. Do not add objects or change shape. Extra transparent spacing is the primary correction.

## Selected generated source files

- sky background: `exec-12ebba30-25f8-4a2f-8572-b77d8b90ec9e.png`
- trunk background: `exec-7719a8ce-a7ec-4629-8a8e-5f4d6522c9e0.png`
- underground background: `exec-d1db30a4-85b4-4744-b0e3-ff6ba957cc22.png`
- sky station final: `exec-feb793ef-85f3-4430-8d3c-a2c1cf951f26.png`
- trunk station final: `exec-423a8eaa-bf01-4452-84a9-53a86780808c.png`
- underground station final: `exec-3fb880d7-5d54-41b4-85ff-3b81f89d6aed.png`

The discarded first station layouts are not referenced by the game and were not copied into the final asset directory.
