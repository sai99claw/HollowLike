# v0.63 音效盤點與製作規格

舊版的一段跳、二段跳、踢牆和蘑菇共用跳躍音，橫向穿刺和下砸共用雙 C 音。投射物常會疊加通用揮刀聲，五種舊存檔副武器缺專用發射音。這輪按動作時點和材質分配音色，首領六種造型各有四個獨立招式音效。

木、石、草腳步維持各四個變體，走路、跑步、蓄刀移動按實際步距發聲。原有羽毛刀、集氣、擊中、格擋、爆炸及獎勵音效維持用途。待機、轉身、牆面持續滑動、小怪行走與懸飛沒有持續播放的短音。

音效由固定種子合成器 `scripts/generate_audio_v63.py` 渲染為單聲道 24 kHz Vorbis。每個發射事件只播放一次，不依彈體數疊加。戰鬥短音使用 12 個保留聲道，蜜蜂、命中和彈牆有重播節流。音高使用獨立亂數，靜音立即停止短音。

## 動作、道具與接觸

| 音效 ID | 聲音規格 |
|---|---|
| `jump` | 腳尖短叩後接上揚羽風 |
| `double_jump` | 更高、更亮的兩層拍翼風 |
| `wall_jump` | 硬面一蹬後往反方向甩羽風 |
| `wall_attach` | 很短的爪尖摩擦 |
| `mantle` | 向上拉時衣料先擦後提 |
| `drop_through` | 短風快速下沉 |
| `land` | 輕觸地面帶小撮灰 |
| `heavy_land` | 重落地的低撞與貼地砂聲 |
| `mushroom_bounce` | 柔軟蘑菇彈簧上彈 |
| `mushroom_pogo` | 下砍彈得更高，帶第二拍羽風 |
| `flight_boost` | 浮翼第一次補上升力的輕拍翅 |
| `water_splash` | 短濺水點和氣泡 |
| `dash_wind` | 單 C 輕、短風切 |
| `double_dash_wind` | 雙 C 穿刺有硬質金屬破風和低推力 |
| `slam_wind` | 下 CC 開始的下墜低鳴，撞地另有震波 |
| `attack_heavy` | 厚重刃身低頻帶短刀鳴 |
| `heal_build` | 安靜的回血聚氣 |
| `heal_finish` | 回血成功的兩層柔響 |
| `hurt` | 低頓加短促下降鴿音 |
| `death` | 沉下來的輪廓與向後散開的羽風 |
| `dream_burst` | 向外擴展的低頻壓力波 |
| `dream_slash` | 滿能量寬幅刀鳴與延展氣流 |
| `item_energy` | 晨露瓶快速上揚的清亮短音 |
| `item_shield` | 環羽盾先後兩個金屬環共鳴 |
| `item_power` | 強攻的低音往上推起暖風 |
| `item_freeze` | 霜葉兩層細冰顫裂 |
| `item_shock` | 衝擊波以低厚脈衝向外推 |
| `projectile_bounce` | 投射物確實碰壁時的玻璃細響 |
| `trap_land` | 種莢戳入泥土的短聲 |
| `fire_land` | 燃燒瓶落地，玻璃裂開後噴焰 |
| `enemy_melee` | 小怪近身爪斬的乾爪風 |
| `enemy_ram` | 怪物起跑時低撞點和沙塵 |
| `enemy_poison` | 較低頻且顫動的短噴氣 |
| `enemy_defeat` | 小怪落地的短落塵 |
| `enemy_jump` | 小怪起跳的輕撐地點 |
| `boss_jump` | 首領起跳的厚重撐地 |
| `boss_warning` | 高威力引導線的低音預告 |
| `boss_summon` | 召喚時的低吟與較高響應 |
| `boss_defeat` | 首領倒地的獨立沉響 |
| `boss_phase` | 首領進入新階段，先低沉後張開 |
| `boss_move_sky` | 隼王衝鋒的風切 |
| `boss_move_canopy` | 螳后衝鋒的鐮刃刮音 |
| `boss_move_trunk` | 鍬皇衝鋒的碎木重點 |
| `boss_move_underground` | 盲根衝鋒的掘土低砂聲 |

## 副武器與生物投射物

| 音效 ID | 聲音規格 |
|---|---|
| `shot_needle` | 翠羽飛針的細尖風與短金屬尾尖 |
| `shot_scatter` | 橡實散射的一個木質起音與兩個錯開的殼點 |
| `shot_stone` | 流星果實的有重量離手聲與短下墜風 |
| `shot_moonblade` | 月翎刀的明亮金屬月牙和寬刃風 |
| `shot_ricochet` | 迴響彈珠兩顆玻璃珠先後磕響 |
| `shot_sunray` | 晨光束以清亮音高快速上揚，帶風擦 |
| `shot_multibounce` | 星籽三次錯拍、越來越亮的珠音 |
| `shot_impact_bomb` | 熾果爆裂砲由厚果殼低點推出 |
| `shot_piercing_laser` | 穿星雷射快速鎖定後以金屬高頻拉成直線 |
| `shot_shockwave` | 裂枝衝擊波以低頻壓力帶木塵展開 |
| `shot_chain_staff` | 連鎖杖由第一次通電到下一個乾電爆點 |
| `shot_homing_missile` | 逐燈飛彈持續偏移的蜂鳴和低噴流 |
| `shot_trap_pod` | 棘種陷阱匣用乾種莢離手聲 |
| `shot_fire_flask` | 燼根瓶空心玻璃振響與翻轉風 |
| `shot_bee` | 符文蜜蜂輕短、低音量的振翅脈衝 |
| `shot_linear` | 通用生物直射的細破空聲 |
| `shot_arc` | 通用生物拋投的木質落點 |
| `shot_trap` | 通用布陷的短氣囊落音 |
| `shot_flying_slash` | 通用飛行刃波的中頻刀刃風 |
| `shot_hail` | 冰雹的硬冰脆音加墜風 |
| `shot_storm_pod` | 雷暴囊的低囊體帶跳電 |
| `shot_spore_pod` | 地下孢子囊噴出後抖動 |
| `shot_acorn` | 單顆橡實的木質殼聲 |
| `shot_moth_needle` | 薄暮獵蛾的翅振裡有一發細射針 |
| `shot_guardian_acorn` | 古枝守衛三顆低低錯拍的殼音 |
| `shot_sound_crescent` | 聲刃有顫動金屬共鳴的寬刃風 |
| `shot_mineral_dart` | 礦晶飛鏢以礦片擦響加銳風 |
| `shot_resin_orb` | 黏重樹脂球啵地離開 |
| `shot_seed_needle` | 乾種籽尖刺後接短破風 |
| `shot_web_seed` | 蛛絲擠出後忽然鬆開 |
| `shot_leaf_crescent` | 寬葉切過空氣帶輕刃鳴 |
| `shot_feather` | 輕拍亮羽出手 |
| `shot_storm_dart` | 雷暴飛鏢以電花泛音帶銳風 |
| `shot_moss_shard` | 苔殼裂點伴木質薄片離手 |
| `shot_spring_seed` | 彈枝種籽彈性上滑 |
| `shot_lamp_pollen` | 守燈光塵有微亮顆粒鳴響 |
| `shot_mist_spore` | 流霧孢囊有散粉低風 |
| `shot_root_spear` | 厚根離枝後切風 |

## 首領招式

| 音效 ID | 聲音規格 |
|---|---|
| `boss_sky_0` | 掠空雙爪，兩次不等距爪風 |
| `boss_sky_1` | 暴風翎槍，電金屬加一發銳風 |
| `boss_sky_2` | 散翼風刃，扇形風加二層尾音 |
| `boss_sky_3` | 折翼雷列，重雷底與錯開電火 |
| `boss_canopy_0` | 剪冠雙鐮，兩個刀齒碰響 |
| `boss_canopy_1` | 折返葉刃，遠去風後轉高回旋 |
| `boss_canopy_2` | 伏鐮穿冠，沉重低撞接長刃切風 |
| `boss_canopy_3` | 雙層返刃，雙金屬輪廓與拉長風 |
| `boss_branches_0` | 撐足刺擊，硬節點和短木擦 |
| `boss_branches_1` | 穿枝束絲，張緊繩響加雙發風 |
| `boss_branches_2` | 三節封網，織絲抖動和網節落點 |
| `boss_branches_3` | 蛛絲流星，較重繭彈甩出後拉絲尾 |
| `boss_trunk_0` | 鍬角夾擊，低沉夾碰伴硬殼 |
| `boss_trunk_1` | 碎琥珀榴彈，實心拋響與晶片尾音 |
| `boss_trunk_2` | 低角破木，木屑風伴低重音 |
| `boss_trunk_3` | 琥珀碎槍，兩枚琥珀先後擦裂 |
| `boss_grass_0` | 長舌點刺，彈性下降滑音 |
| `boss_grass_1` | 浮沫氣泡，三顆錯開的柔泡 |
| `boss_grass_2` | 鼓腹震地，腹腔低擊和泥水聲 |
| `boss_grass_3` | 落露泥沼，黏液長氣和濕土落點 |
| `boss_underground_0` | 翻岩掘爪，沙石碎裂 |
| `boss_underground_1` | 雙向裂地，長低頻沿地表展開 |
| `boss_underground_2` | 鑽土根陣，粗根破土後帶落礫 |
| `boss_underground_3` | 潛鑽破根，持續顫動的重土摩擦 |
