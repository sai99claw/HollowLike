# v0.27 地面燃燒美術

使用內建 image_gen.imagegen 工具生成一張四格動畫圖集，transparent_background=true。原圖完整保留，沒有用程式改繪或去背。

- 圖檔：`assets/v27/fire/ground-flame.png`
- 動畫與裁切資料：`assets/v27/fire/ground-flame.json`
- 原始尺寸：2048 × 768，RGBA；四格橫排，每格512 × 768。
- 每格使用同一局部裁切：`[8,288,496,354]`，第i格x加上`512*i`；可見地面基線約y640–641。以裁切圖底部中央貼地，避免原始大片透明區使火焰浮空。
- 建議10fps循環。四格的火舌形狀不同、炭床位置與寬度一致。
- 建議Godot無損匯入`process/size_limit=1024`，原圖保留2048px。引擎中實際大小會變成1024 × 384，需按比例縮放source rect；裁切後單格寬248px，於100–120世界像素顯示仍有2倍以上來源像素密度。
- 檢查：原圖alpha範圍0–254，三個畫布角落alpha皆0。微弱alpha殘留位於可見火焰外側，使用上述統一裁切即可；沒有白底或棋盤底。alpha≥8的可見地面最底部四格為640／639／640／640（零基像素）。
- 此圖為貼地持續燃燒，應由落地事件產生地面危險區；不是彈丸或燃燒瓶。粒子系統可在炭床寬度內向上噴發餘燼，火星顏色以琥珀與淡黃為主。

## 完整生成提示

```text
Use case: stylized-concept. Asset type: one production 2D game VFX sprite sheet on genuinely transparent alpha. Canvas exactly 2048 by 768 pixels. Four equal cells in one horizontal row, each 512 by 768 pixels, no grid lines. Subject: the same small wide patch of fire BURNING ALONG THE GROUND in four consecutive animation frames, left to right. This is NOT a fireball, NOT a projectile, NOT a bottle, NOT a floating orb. A low horizontal bed of charred embers and blackened roots touches an identical horizontal floor baseline at y=650 in every cell. Broad flickering orange/amber flame tongues rise directly from that bed; bright pale-yellow hot cores, dark reddish ink outlines, a few tiny rising embers and restrained thin smoke wisps. Four distinct flowing flame shapes for a seamless looping flicker, while the ground footprint, apparent scale and baseline stay fixed. Each flame patch stays inside local x=36..476 and y=220..650; leave the rest transparent, no flames crossing between cells. Match hand-painted gothic dark fantasy side-scroller art: rich brush textures, crisp readable silhouettes, restrained detail at tiny game scale. Isolated complete effects only. No scenery, no fake checkerboard, no solid-color background, no cast shadow outside the patch, no text, no labels, no letters, no UI, no borders, no watermark. Side view orthographic, planted firmly on a surface implied only by the ember bed.
```

