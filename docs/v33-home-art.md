# v0.33 初始樹冠場景美術

使用內建 imagegen 生成，原始 PNG 逐位元複製進專案，沒有重新取樣、去背腳本或像素編修。根據遊戲三生態的手繪哥德式幻想風格延伸，主色為暗青藍／翡翠，少量象牙色與古金色點綴。

## 檔案與整合

- `assets/v33/home/background.png`：1536×1024 RGB，3:2。連續中央可玩樹枝的約略腳底基準為來源 y730；`background.json` 提供 `authored_floor_y`、比例與建議定位。1280px 寬時，繪製 top ≈−8.33 可對齊遊戲 y600。左右樹幹可提供牆面視覺，中間開放供跳躍。
- `framing.png`：1536×1024 RGBA，兩側上方樹枝／樹葉獨立景層。實際可見 alpha>8 範圍為來源 y0～392；建議原點 y−100，使主體留在畫面上方。中央與下方遊戲區為透明；來源有少數 alpha1 噪點，保持原圖未改。
- `props.png`：1254×1254 RGBA，2×2 四格，`props.json` 含 `musou`、`rogue`、`records`、`bounce`。前兩個共用根木＋羽毛拱門輪廓，分別古金綠與藍象牙色；第三個為冒險紀錄書架；第四個為葉菇彈跳物。兩扇門內部透明。
- `leaves.png`：1254×1254 RGBA，四種獨立葉子。`leaves.json` 的 ID 為數字字串 `0`～`3`，供前後景粒子使用。

每個 atlas metadata 的 `original_size` 皆為原始 PNG 尺寸，`rect` 為整格來源區域，`pivot` 與 `bounds` 為格內局部座標。道具 pivot 位於完整根部底部；葉子 pivot 位於可見輪廓中心。執行時應依匯入貼圖／原始尺寸比換算 source rect，避免 size_limit 造成裁切偏移。

Godot lossless 匯入上限：背景與道具 1024px；樹枝景層與葉子 512px。透明邊界與色彩使用原畫 alpha；沒有將陰影或粒子烘焙進道具。

## 檢查與修正

已逐張檢視四張選定 PNG。第一版道具太貼近格界，已用內建 imagegen 針對縮小／補留白修正，最終四格皆完整、互不截斷。樹枝景層同樣進行單項布局修正，並以 alpha>8 的實際範圍供引擎定位。整體保留清楚輪廓、較柔遠景與克制細節；背景不含角色、模式入口、互動站點或文字，所有互動物件由引擎獨立擺放。

## 完整生成提示詞

### background

Use case: stylized-concept. Asset type: finished background painting for a 2D side-view gothic fantasy pigeon platformer. Landscape3:2 composition. Majestic ancient TREE CROWN sanctuary at dusk, hand-painted with elegant inked silhouettes and restrained painterly shading, cohesive dark teal-blue and emerald palette with very sparse warm ivory highlights. Layered distant cathedral-shaped tree crowns receding into blue teal mist, deep parallax-friendly spatial depth. Open calm central80%play area. A strong broad gently level tree branch crosses the entire width at about76%ofimageheight, with readable top support edge, enough open air above it for jumping. Thin distant branch architecture only in background, no false foreground platforms. Stronger dark silhouettes toward sides, brighter softened distance. No gateways, no portals, no stations, no objects for interaction, no characters, no birds, no people, no text, no logos, no watermark. Production background artwork, not a mockup, not a screenshot, no UI. Original gothic fantasy elegance, compact forms and clear broad value groups rather than noisy texture.

### framing

Use case: stylized-concept. Asset type: transparent foreground framing for a hand-painted gothic fantasy 2D tree-crown platform game. Landscape3:2 transparent RGBA canvas. Two sparse complete organically curving tree BOUGHS with small elegant teal emerald leaves, one occupies ONLY upper-left corner and one ONLY upper-right corner. They frame the top edge like a light canopy, each tapering inward, very thin and sparse, not a heavy border. Entire middle80%ofcanvas and entire bottom75%ofcanvas absolutely transparent; no foliage at bottom or side below topquarter. Elegant ink outlines, handpainted restrained shading, cool dark teal wood and subtly emerald leaves with ivory edge accents. All branch silhouettes complete within canvas margin, no cropped sawed edges. No environment background, no haze/backdrop, no drop shadows, no text, no characters, no UI. Original dark gothic fantasy tree silhouettes.

修正提示：

Precise layout correction preserving these two elegant gothic hand-painted teal leafy bough designs. Put ALL branches and leaves ENTIRELY inside the TOP20%ofthis landscape3:2 RGBAcanvas, sparse upperleft andupperright corners only, thinner branches. The bottom80%ofcanvas must have alpha0 everywhere, and the middle40%width must also have alpha0 everywhere. Eliminate all backdrop haze and tinted panels: only actual wood and leaves have alpha, all empty space completely transparent. Keep clear hand-inked darkteal shapes with subtle ivory leafedge highlights. No extra objects,no text,nodrop shadow,no environment,no crop boundary through any branch tip. Exactly two boughs.

### props

Use case: stylized-concept. Asset type: production transparent game prop sprite atlas, handpainted gothic fantasy. Exactly FOUR detached complete objects on a STRICT2columns by2rows equal-cell grid, RGBA transparent canvas, square. Top-left: ornate feather-and-root ARCH GATEWAY for Musou, antique gold-green accents. Top-right: same base arch gateway SILHOUETTE and proportions, blue-ivory accents, for Roguelike. Both arches have elegant root/branch supports, feather finial, wide OPEN interior completely transparent, no solid door slab, no glow wall. Bottom-left: elegant adventure record LECTERN with open ivory book atop narrow rooted carved wood stand. Bottom-right: springy mushroom-leaf POD bounce object, broad jade leaf cap with warm ivory underside and compact rooted stem. Side-view2D gameplay props, grounded bottom-center eachcell, complete bases and finials, wide transparent margin around EVERY object, no chopped object edges. Shared old-tree gothic visual family, visible brushwork and crisp ink silhouettes, simple readable overall shapes not excessive microdetail. Root wood dark teal, restrained emerald/ivory/gold accent. No text, no letters, no gridlines, no UI, no scenery, no castshadow panels. EXACTLY4objects total.

修正提示：

Precise sprite atlas layout correction. Preserve these exact four gothic hand-painted prop designs, their colors, ink style and object silhouettes. Correct ONLY their spacing and scale: STRICT2columns2rows equal cells on square transparent RGBAcanvas. Shrink and recenter EACH ofthe4objects so that its ENTIRE shape including top feather tips and all roots fits within the central78%width and78%height ofits OWN cell, with at least10%cell transparent padding on EVERY side. No object may touch an image outer edge or overlap a neighborcell. Top-left goldgreen arch, top-right blueivory arch, bottom-left openbooklectern,bottom-right mushroomleafbouncepod. Both arch interiors fullytransparent. Keep four separate complete objects. No text,no grid,no scenery.

### leaves

Use case: stylized-concept. Asset type: transparent leaf particle texture atlas for handpainted gothic forest game. ExactlyFOUR small detached leaves in strict2by2equalcellgrid on square RGBAcanvas. One narrow darkteal willowleaf with ivory vein, one curled emerald oakleaf with restrained goldedge, one soft jade ovalleaf with ivory vein, one folded darkteal feather-shaped leaf. Four distinct readable simple leafsilhouettes, subtle handpainted shading and fine but clear inkline. Each leaf fits central60%ofitscell with generous transparent padding on EVERY side, full tips and stems visible, all leaves separated. No branch,no background,no haze,no particles baked in,no shadows,no text,no numerals,no gridlines. Intended to tumble gently in foreground and background of a majestic gothic treecrown at dusk.

## 原始生成來源

- background：`exec-5ea07ce2-5536-456e-9366-d1c90305ee37.png`
- framing：`exec-5053f51f-cf22-476a-b66c-c8e703db3ed0.png`（初稿 `exec-d591ded5-63c3-4e0c-864d-9f5f5d492474.png` 未整合）
- props：`exec-6d8d6f4a-58a2-464e-84b9-b608420a30c0.png`（初稿 `exec-538afce8-e20b-43f5-8614-ab00120d51af.png` 未整合）
- leaves：`exec-f29dd6ae-60df-4add-83a4-257f0d18087a.png`

