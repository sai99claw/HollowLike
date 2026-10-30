# v0.8 專用角色貼圖

由內建 imagegen 產生，已實際由 `scripts/adventure_visual.gd` 使用；透明 PNG 保留 alpha。

- `owl_merchant.png`：2×2、4幀。小型奶油色面盤、琥珀眼、深色羽披風的森林貓頭鷹商人；放鬆、眨眼、展示羽毛刀、展示紫符文。
- `pigeon_actions.png`：16個角色姿態。以既有 `assets/walk_v2/runtime80/walk_00.png` 為角色參考，灰鴿、綠紫頸羽、深藍圍巾、鳥腳；回血4幀、跛腳4幀、橫向穿刺4幀、下砸4幀。實際非均勻留白使用明確裁切座標，沒有把其他列切入動畫。

Prompt：production transparent game animation atlas; same bird identity, head/body scale, ink outlines and soft painterly shading, no humanoid hands, no background, no lettering. Healing folds wings around a green heart glow; limping hunches the body with uneven alternating foot weight; dash coils then extends with wings swept back; slam tips into a vertical dive then crouched landing. Merchant presents weapons and glowing runes across four equal cells. Built-in tool mode，無CLI/API fallback。
