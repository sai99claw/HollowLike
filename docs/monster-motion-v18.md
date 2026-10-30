# 怪物八幀動作更新

12 種外觀各自使用新畫的 8 幀移動循環，共 96 個不同姿態。普通怪與菁英共用正確的同種生物外觀；六隻首領各自有獨立圖集。主角的走路與死亡羽化未修改。

圖集使用內建 image_gen，以原本該生物的貼圖當作外觀參考。原始透明 PNG 直接保留；沒有用影像插補、重複舊圖或逐幀縮放冒充新動作。八幀以關節動作、足部交替、翅膀拍動構成循環。飛行物的軀幹錨點與地面生物的腳底錨點分開，整種生物只使用一個固定縮放比例，不會隨姿態外框忽大忽小。跳蟲的空中上升與下落各保持一個明確姿勢。

## 檔案

- `assets/v18/monster-motion-{walk,jump,hover,drift,dash,pillbug,sky,canopy,branches,trunk,grass,underground}.png`：12 張全新的透明圖集。
- `assets/v18/monster-motion-manifest.json`：各幀原圖區域、尺寸、錨點、透明外框、像素雜湊、播放速度與固定比例。
- `assets/v18/monster-motion-prompts.json`：完整生成提示詞；模式為內建 image_gen，附圖僅作外觀與筆觸參考。
- `scripts/monster_motion_v18.gd`：延遲載入圖集、AtlasTexture 切片及移動播放。
- `tests/test_monster_motion_v18.gd`：逐種檢查八個不同圖格，以及普通怪、菁英、可愛小怪與首領的實際播放路徑。

## 動作分層

移動改由 `MonsterMotionV18` 畫出；原本各生物自己的攻擊、受傷、死亡圖仍留在原來的美術庫。首領的近戰、遠攻與招式預備姿勢也保持原本物種。材質閃白由上層角色 Canvas 控制，無須修改原始貼圖。

生成圖的總尺寸為 1774×887；透明間隙經量測後存為 `source_rect`，沒有把非整數網格硬切而截斷翅膀、觸角或前爪。RD 美術室應直接使用這些來源區域播放。
