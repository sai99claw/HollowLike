# RD美術檢視房資產目錄

`scripts/art_catalog_v16.gd`集中列出可播放、可逐格檢視的遊戲圖像。開啟檢視房時只建立一次文字與影格描述，不會預先解碼所有圖片。只在選取動畫、播放或拖曳影格時讀取當前影格，來源圖片和AtlasTexture共用最多24筆的LRU快取。

## 介面

- `all_entries()`或`entries()`：回傳共享的目錄中繼資料，呼叫端應視為唯讀。
- `categories()`：取得分類名稱。
- `search(query, category)`：依名稱、ID和說明過濾；空字串表示不限制。
- `entry(id)`：取得單筆資料。
- `frame(entry, index)`：延遲取得當前Texture2D，圖集會切成AtlasTexture；沒有圖片時回傳null。
- `sequence(entry, phase)`：取得影格索引順序。預設`all`播放所有格；`idle`、`break`或動作的`windup/active/recovery`依原中繼資料選取；沒有對應階段時回退完整順序。
- `clear_cache()`：離開RD房時可清除圖片參照；目錄文字仍保留，第二次進入不用重新掃描。
- `cache_size()`：供效能及回歸測試檢查快取數量。

每筆資料包含`id/label/category/fps/frame_count/frames/sequence/phases/loop/notes/kind`。`fps`為該素材原本播放速度，RD介面可讓使用者更改預覽fps而不改動原始遊戲資料。`frame_count`就是手動影格滑桿的上限加一。`loop`如有值，是原動畫的迴圈起訖格；`complete_release`代表釋放動畫應完整播放。

## 素材涵蓋

- combat_v05、illustrated、bosses、walk_v2的所有動畫、單格地形及背景。
- 武器、投射物、陷阱、主角、一般與強力符文、消耗品、技能圖示。
- 16個各怪物專用的投射物／地面陷阱切片。
- 三個生態系各三層景圖、六種物件的完整及破壞五格、四種地形材質。
- 商店與溫泉場景切片、貓頭鷹商人四格、鳥巢睡眠起身四格與大門。
- 單C噴射、雙C風形、下衝12格接地動畫、遠景飛鳥及前景蜻蜓。
- v16的貼面爆炸與空中爆炸，各為4欄×2列八格、16fps。貼面爆炸保留85%接觸基準資訊；在RD顯示完整原畫布，遊戲中由爆炸繪製器負責平面限制。
- 其他尚未登記的PNG、WEBP及JPG等原圖會自動補入目錄。新的圖集若要逐格檢視，應像爆炸素材一樣加入明確的欄列資料，避免只顯示整張圖集。

目錄顯示的是實際資產原圖；由程式生成的水面波紋、門光束等幾何效果不會偽裝成原畫格，應由RD預覽Canvas另行調用原繪製器。

## 檢視房控制項

`scripts/rd_room_v16.gd`為獨立的全螢幕Control，加入CanvasLayer後會自行建立介面；父節點應監聽`closed`訊號以恢復首頁。滑鼠可搜尋、切換分類、選動畫、播放／暫停、逐格切換、拖曳影格，以及在1～60fps之間即時調速。下方每頁最多顯示24張依時間排序的縮圖，點擊縮圖會暫停並定位該格。Escape與「返回鳥巢」都會關閉檢視房、停用處理並清除圖片快取。

可供整合測試呼叫`select_entry(id或Dictionary或索引)`、`seek_frame(index)`、`set_fps(value)`、`play()`及`pause()`。目前狀態由`current_entry`、`frame_index`、`fps`、`playing`公開。圖像只在影格變化時更新，靜態畫面不反覆建立Texture。
