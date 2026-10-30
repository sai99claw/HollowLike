# v0.28 高處落地蹲伏美術

使用內建 `image_gen.imagegen` 生成並精修，均要求 `transparent_background: true`。原始生成輸出留在生成位置，最終專案圖檔為 `assets/v28/player/heavy-landing.png`，未改動既有主角美術。

- 最終原圖：RGBA 2048×768，4個512×768橫向cell，alpha0–254；畫布角落透明。
- 四幀：落地壓縮、低蹲、低蹲保持、半起身。後兩個低蹲姿態的身體明顯下壓，腿收在腹部下，恢復幀保持膝蓋彎曲以接回原本站姿。
- 建議時間：0–0.08秒／0.08–0.34秒／0.34–0.44秒／0.44–0.50秒，非循環。
- Source rect：第i幀為 `[i*512,0,512,768]`。共同像素比例 `50.9375/323 = 0.15770123839009288`，不得按各幀外框獨立fit，以免人物蹲下時被放大。
- 四幀腳掌中央、鞋底pivot：`[317,643]`、`[280,641]`、`[277,642]`、`[293,640]`。
- alpha≥8的局部可見範圍：`[41,321,452,323]`、`[53,406,457,236]`、`[40,389,468,254]`、`[40,326,429,315]`。
- Godot import：無損，`process/size_limit=1024`。原圖保留2048px；runtime source rectangles乘上 `texture.get_size()/Vector2(2048,768)`，destination與pivot繼續使用原圖單位再乘共同比例。
- 檔案映射、時間、pivot與SHA-256另記於 `assets/v28/player/heavy-landing.json`。

## 完整生成提示

```text
Use case: stylized-concept. Asset type: production transparent 2D game high-fall landing sprite sheet, FOUR equal cells in one horizontal row. Input image1 is the canonical grey-blue pigeon identity reference; image2 is additional protagonist identity reference only. Create the exact same pigeon with golden-orange eye, short dark beak, cream belly, layered grey-blue feathers, iridescent teal-purple neck, dark navy scarf trailing left. Hand-painted gothic fantasy with crisp dark ink contours and readable soft feather brushwork matching the references. All four full-body poses face RIGHT in side profile. Animate a HEAVY LANDING with a clear low CROUCH: frame1 impact compression, knees deeply bent and body lowered; frame2 lowest crouch, belly nearly touching feet and folded legs compressed beneath the body, head lowered with the torso; frame3 hold the same low crouch with tiny settling change in scarf; frame4 rise back to a normal upright standing pose. Preserve the same anatomical head diameter and torso volume in every frame; achieve lower height through articulated knees and body tilt, NOT scaling down the entire bird. Feet soles remain planted on the exact same ground baseline y=640 within each cell; the torso and head move vertically for crouch. Shared head diameter about90 pixels, standing foot-to-crown height about330 pixels. Original character anatomy and scarf must remain unchanged. Canvas exactly2048x768 with four512x768 cells. Whole bird, tail, scarf and feet fully visible inside each cell with generous transparent margin; no between-cell overlap. True transparent alpha background. No floor, no environment, no cast ground shadow, no dust, no shock waves, no labels, no text, no numbers, no grid lines, no watermark.
```

## 完整精修提示

```text
Use case: precise-object-edit. Image1 is the existing FOUR-frame landing animation sheet to refine. Image2 is the canonical pigeon body-proportion reference. Preserve image1 canvas2048x768, four512x768 cells, true transparent alpha, same grey-blue pigeon identity, navy scarf, RIGHT-facing orientation, art style, feet baseline at y640 and original frames1/2/3 crouching poses. Change ONLY frame4, the rightmost bird: make it a compact HALF-RISE recovery pose transitioning out of crouch, with deeply bent knees still beneath belly, compact rounded torso and head upright; reduce the excessive long upright legs and vertical torso. In frame4 the crown should be at approximately y320, feet soles at y640, matching the approximately320px foot-to-crown size of frame1. Keep its anatomical head diameter, eye, beak, feather-detail density and body volume consistent with the other frames and canonical reference; do not scale down the whole bird. Keep frame4 fully inside localx36..480. Remove any soft grey aura, shadow, glow or haze outside every bird silhouette so the entire backdrop is pure transparent alpha. No scenery, floor, shadows, particles, labels, text, grids, watermark. Keep the first THREE crouch frames unchanged.
```

