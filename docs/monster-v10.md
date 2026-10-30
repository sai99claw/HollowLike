# 怪物設計 v0.10

2026-10-22。一般怪招式改由物種決定；隨機武器庫仍供戰利品與融合使用。小怪攻擊與接觸傷害均為 1，菁英也保留物種材質與招式身份。

| 外觀／物種 | 固定主招 | visual_id | 行為 |
| --- | --- | --- | --- |
| 苔甲步蟲 | 苔甲鉗斬 | moss_shard | 靠近、停步鉗斬 |
| 彈枝跳蟲 | 彈枝種籽 | spring_seed | 穩定遊盪、跳躍拋籽 |
| 守燈懸蛾 | 守燈光塵 | lamp_pollen | 懸浮、緩速波動光塵 |
| 流霧漂蛾 | 流霧孢子囊 | mist_spore | 漂浮遊盪、拋投孢子；落地 pollen_flower |
| 疾根衝蟲 | 疾根角刺 | root_spear | 蓄勢衝鋒、角刺遠射 |
| 葉帽糯糯蟲 | 無 | cute_pillbug | 可愛被動遊盪者；不攻擊、不造成接觸傷害 |

菁英固定附加另一移動方式（包含衝鋒）與一個同物種材質的人工副武器，不再從無關外觀的武器池任意抽取。一般怪仍各有一個生物主招，保留既有資料介面。

六隻 Boss 保留原有近戰、遠程與陷阱，新增清楚的 0.8 秒蓄勢、0.52 秒方向鎖定衝鋒、0.8 秒恢復與 4.6 秒冷卻。天空隼王為空中斜向俯衝；其餘為地面衝鋒。衝鋒中不能插入一般攻擊，撞牆立即進入恢復，蓄勢與衝鋒期間不切換移動模式。每種 Boss 的投射物仍對應自身雷羽、葉鐮、絲繭、琥珀、露泡、根鑽，而非共用任意武器。

## AI 修正

近身採停步與恢復移動兩個不同距離，避免跨過玩家後反覆折返。面向有 28 像素死區與 0.18 秒反向持續判斷；Boss 使用較大的 40 像素死區。遊盪每次選擇距出生點一定距離的目標，保持 2.4–4 秒，不因接近目標而每幀重選。地面遊盪不隨機抽取垂直目標。

## 接入契約

- `Armament.enemy(mode,rng,elite,passive)` 保留原簽名。
- `Armament.cute_wanderer(rng)` 產生被動葉帽糯糯蟲；場景需補入和其他怪相同的 runtime `pos/vel/attack/uid` 等欄位。
- 場景不要再以 `sign(player.x-enemy.x)` 或 `sign(velocity.x)` 每幀覆蓋面向。`EnemyMotion.velocity` 已用實際追逐／遊盪目標執行朝向遲滯。
- 出招前檢查 `EnemyMotion.can_attack(en)`。
- 世界碰撞求解後呼叫 `EnemyMotion.resolve_collision(en,requested_velocity,resolved_velocity)`。
- Boss 隨機覺醒產生攻擊後呼叫 `MonsterDesign.decorate_adaptation(attack,en)`，讓新增招式也沿用該 Boss 的專屬材質。
- 生成投射物時傳遞 `visual_id`；陷阱載體到落地陷阱亦需傳遞 `hazard_visual_id`。
- `MonsterDesign.draw_projectile(c,pr,time,base)`、`draw_hazard(c,h,time,base)` 回傳是否已畫出。優先嘗試此繪製，再回退既有特效。
- `MonsterDesign.draw_actor(c,en,time,base)` 僅接管 `cute=true` 的新物種；`draw_charge(c,en,time,base)` 在既有怪物／Boss 上疊加收束光塵與衝鋒氣流。
- 狀態欄位 `charge_phase=idle/windup/active/recovery`、`charge_left`、`charge_vector`、`charge_hit_wall` 可供渲染與調試。舊 `motion_dash_left/wait/dir` 同步保留。

## 美術與驗證

`assets/monster_v10/projectile-atlas.png` 由內建 imagegen 製作，真透明 4×4 水彩圖集。16 格包含五種小怪、六種 Boss 的專屬彈體、四個地面陷阱與可愛遊盪蟲；同一材質可同時支援近戰殘影與投射物。完整生成提示與格位見旁邊的 `manifest.json`。紋理使用延遲載入，16 格共用一張圖集。

`tests/test_monster_v10.gd` 驗證跨種子物種招式穩定、五種彈體身份不同、傷害為1、600幀近身不抖動、持續反向能轉身、遊盪目標固定、被動小怪實際行走、六隻 Boss 實際蓄勢後衝鋒、空中斜向鎖定、真實世界碰撞中止衝鋒與冷卻，以及16格圖集匯入。舊 `test_v05.gd` 的隨機生物武器假設更新為固定物種契約。
