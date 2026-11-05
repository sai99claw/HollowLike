#!/usr/bin/env python3
"""Render the game cues and their audio direction notes with no source recordings."""

from array import array
from hashlib import sha256
from math import exp, sin, cos, tau
from pathlib import Path
from random import Random
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave

RATE = 24000

# Material, start Hz, end Hz, duration in seconds, amplitude, optional onset.
def air(start, end, duration, gain=.36, onset=0):
    return "air", start, end, duration, gain, onset


def metal(start, end, duration, gain=.24, onset=0):
    return "metal", start, end, duration, gain, onset


def reed(start, end, duration, gain=.25, onset=0):
    return "reed", start, end, duration, gain, onset


def thud(start, duration, gain=.33, onset=0):
    return "sine", start, start * .53, duration, gain, onset


# Cue ID, brief, then synthesis instructions.
CUES = {
    "jump": ("腳尖短叩後接上揚羽風", thud(151,.09,.24), air(1100,2600,.17,.33,.014)),
    "double_jump": ("更高、更亮的兩層拍翼風", air(1700,4100,.16,.45), air(2100,800,.15,.25,.055), reed(280,425,.14,.15)),
    "wall_jump": ("硬面一蹬後往反方向甩羽風", thud(205,.11,.30), air(2400,890,.11), air(950,2500,.12,.28,.04)),
    "wall_attach": ("很短的爪尖摩擦", thud(250,.07,.17), air(2800,1300,.09,.24)),
    "mantle": ("向上拉時衣料先擦後提", air(1650,710,.18,.24), thud(165,.11,.16), air(850,1800,.11,.20,.09)),
    "drop_through": ("短風快速下沉", air(1300,440,.12,.24), reed(320,173,.10,.12)),
    "land": ("輕觸地面帶小撮灰", thud(135,.09,.22), air(1160,490,.075,.24)),
    "heavy_land": ("重落地的低撞與貼地砂聲", thud(77,.30,.48), air(1700,450,.19,.44), metal(191,130,.21,.16)),
    "mushroom_bounce": ("柔軟蘑菇彈簧上彈", reed(128,383,.23,.34), air(950,2000,.19,.25)),
    "mushroom_pogo": ("下砍彈得更高，帶第二拍羽風", reed(108,505,.29,.42), air(1300,3100,.25,.34), reed(270,420,.13,.13,.095)),
    "flight_boost": ("浮翼第一次補上升力的輕拍翅", air(1800,3450,.23,.28), reed(175,331,.17,.18)),
    "water_splash": ("短濺水點和氣泡", air(3400,700,.22,.28), reed(232,423,.14,.16)),
    "dash_wind": ("單 C 輕、短風切", air(3600,690,.20,.48), thud(152,.13,.20)),
    "double_dash_wind": ("雙 C 穿刺有硬質金屬破風和低推力", air(4500,1210,.25,.46), metal(431,128,.21,.26), thud(105,.21,.32)),
    "slam_wind": ("下 CC 開始的下墜低鳴，撞地另有震波", air(2300,310,.33,.48), reed(322,73,.28,.24), thud(128,.22,.25)),
    "attack_heavy": ("厚重刃身低頻帶短刀鳴", air(2100,560,.27,.42), metal(234,184,.23,.27), thud(114,.20,.22)),
    "heal_build": ("安靜的回血聚氣", reed(284,351,.39,.19), air(720,1250,.28,.19)),
    "heal_finish": ("回血成功的兩層柔響", reed(330,418,.20,.23), metal(528,510,.24,.19,.07), air(1270,2230,.23,.18)),
    "hurt": ("低頓加短促下降鴿音", thud(182,.18,.36), reed(465,153,.17,.24), air(1540,650,.12,.26)),
    "death": ("沉下來的輪廓與向後散開的羽風", thud(111,.36,.38), reed(408,121,.32,.25), air(1700,420,.46,.30)),
    "dream_burst": ("向外擴展的低頻壓力波", thud(108,.52,.43), air(790,3700,.47,.40), metal(266,594,.37,.24,.06)),
    "dream_slash": ("滿能量寬幅刀鳴與延展氣流", air(2900,870,.40,.39), metal(446,271,.33,.26), thud(118,.28,.23)),
    "item_energy": ("晨露瓶快速上揚的清亮短音", reed(340,715,.25,.23), metal(590,722,.22,.18,.065)),
    "item_shield": ("環羽盾先後兩個金屬環共鳴", metal(291,366,.26,.30), metal(424,496,.27,.24,.048), air(940,2240,.24,.18)),
    "item_power": ("強攻的低音往上推起暖風", thud(102,.28,.31), reed(143,342,.30,.23), air(1360,3120,.27,.27)),
    "item_freeze": ("霜葉兩層細冰顫裂", metal(1200,728,.22,.22), metal(852,619,.28,.18,.048), air(4800,1120,.36,.33)),
    "item_shock": ("衝擊波以低厚脈衝向外推", thud(94,.35,.43), air(3000,540,.36,.40), reed(225,65,.28,.20)),
    "projectile_bounce": ("投射物確實碰壁時的玻璃細響", metal(924,778,.14,.22), thud(281,.065,.15)),
    "trap_land": ("種莢戳入泥土的短聲", thud(152,.15,.32), air(1700,720,.16,.27)),
    "fire_land": ("燃燒瓶落地，玻璃裂開後噴焰", thud(143,.11,.26), metal(1170,810,.15,.21), air(3100,850,.35,.37)),
    "enemy_melee": ("小怪近身爪斬的乾爪風", air(1950,630,.18,.35), metal(294,176,.13,.18)),
    "enemy_ram": ("怪物起跑時低撞點和沙塵", thud(125,.25,.36), air(1600,540,.25,.35)),
    "enemy_poison": ("較低頻且顫動的短噴氣", air(1700,510,.38,.41), reed(238,87,.20,.22)),
    "enemy_defeat": ("小怪落地的短落塵", thud(120,.14,.28), air(2000,590,.16,.31)),
    "enemy_jump": ("小怪起跳的輕撐地點", thud(176,.11,.23), air(1350,670,.12,.25)),
    "boss_jump": ("首領起跳的厚重撐地", thud(113,.23,.38), air(1210,450,.23,.30)),
    "boss_warning": ("高威力引導線的低音預告", metal(199,247,.36,.18), air(610,1780,.29,.21)),
    "boss_summon": ("召喚時的低吟與較高響應", reed(132,216,.38,.31), metal(304,398,.30,.26,.09), air(1060,2230,.33,.28)),
    "boss_defeat": ("首領倒地的獨立沉響", thud(102,.42,.45), metal(251,117,.39,.25), air(1810,420,.43,.32)),
    "boss_phase": ("首領進入新階段，先低沉後張開", thud(103,.37,.37), metal(242,381,.42,.28), air(1010,3750,.45,.28)),
    "boss_move_sky": ("隼王衝鋒的風切", air(3500,1000,.41,.43), metal(317,188,.31,.24)),
    "boss_move_canopy": ("螳后衝鋒的鐮刃刮音", metal(440,179,.30,.30), air(3060,660,.34,.41)),
    "boss_move_trunk": ("鍬皇衝鋒的碎木重點", thud(105,.40,.42), air(1850,580,.38,.43)),
    "boss_move_underground": ("盲根衝鋒的掘土低砂聲", thud(79,.45,.44), air(1260,410,.40,.45)),
    "shot_needle": ("翠羽飛針的細尖風與短金屬尾尖", air(4700,1500,.14,.42), metal(1112,843,.09,.22)),
    "shot_scatter": ("橡實散射的一個木質起音與兩個錯開的殼點", thud(269,.09,.23), air(2800,1150,.12,.26), metal(623,505,.12,.16,.034), metal(752,637,.09,.14,.060)),
    "shot_stone": ("流星果實的有重量離手聲與短下墜風", thud(169,.16,.37), air(1110,510,.22,.35)),
    "shot_moonblade": ("月翎刀的明亮金屬月牙和寬刃風", metal(583,401,.25,.29), air(3400,1020,.22,.34)),
    "shot_ricochet": ("迴響彈珠兩顆玻璃珠先後磕響", metal(739,822,.19,.30), metal(1040,882,.16,.22,.039)),
    "shot_sunray": ("晨光束以清亮音高快速上揚，帶風擦", reed(425,925,.18,.29), air(3800,2100,.22,.33)),
    "shot_multibounce": ("星籽三次錯拍、越來越亮的珠音", metal(714,662,.16,.27), metal(858,785,.15,.24,.033), metal(1139,1013,.14,.20,.069)),
    "shot_impact_bomb": ("熾果爆裂砲由厚果殼低點推出", thud(146,.22,.39), air(1460,620,.26,.36), metal(334,188,.14,.17)),
    "shot_piercing_laser": ("穿星雷射快速鎖定後以金屬高頻拉成直線", reed(208,534,.29,.32), metal(874,727,.25,.23), air(4800,1750,.32,.30)),
    "shot_shockwave": ("裂枝衝擊波以低頻壓力帶木塵展開", thud(87,.29,.39), air(1170,440,.28,.41), reed(211,91,.19,.19)),
    "shot_chain_staff": ("連鎖杖由第一次通電到下一個乾電爆點", metal(489,617,.17,.28), air(4600,1540,.26,.40), metal(746,506,.17,.25,.054)),
    "shot_homing_missile": ("逐燈飛彈持續偏移的蜂鳴和低噴流", reed(188,363,.33,.34), air(1510,990,.32,.34)),
    "shot_trap_pod": ("棘種陷阱匣用乾種莢離手聲", thud(237,.16,.30), air(1650,730,.22,.33)),
    "shot_fire_flask": ("燼根瓶空心玻璃振響與翻轉風", metal(811,569,.17,.26), air(2500,630,.28,.39), thud(152,.13,.23)),
    "shot_bee": ("符文蜜蜂輕短、低音量的振翅脈衝", reed(229,347,.16,.13), air(1780,830,.16,.19)),
    "shot_linear": ("通用生物直射的細破空聲", air(3300,1100,.14,.36), reed(643,461,.10,.17)),
    "shot_arc": ("通用生物拋投的木質落點", thud(228,.10,.28), air(1670,720,.19,.31)),
    "shot_trap": ("通用布陷的短氣囊落音", reed(304,188,.14,.23), air(1520,565,.24,.30)),
    "shot_flying_slash": ("通用飛行刃波的中頻刀刃風", air(2830,910,.21,.38), metal(373,275,.20,.20)),
    "shot_hail": ("冰雹的硬冰脆音加墜風", metal(962,705,.17,.23), air(3170,770,.21,.34), thud(293,.09,.18)),
    "shot_storm_pod": ("雷暴囊的低囊體帶跳電", thud(178,.18,.28), air(2950,640,.25,.37), metal(555,232,.16,.22)),
    "shot_spore_pod": ("地下孢子囊噴出後抖動", reed(214,138,.17,.23), air(1780,620,.29,.35)),
    "shot_acorn": ("單顆橡實的木質殼聲", thud(256,.15,.30), air(1850,790,.16,.28), metal(425,287,.105,.17)),
    "shot_moth_needle": ("薄暮獵蛾的翅振裡有一發細射針", air(3950,1250,.15,.36), reed(728,376,.13,.18)),
    "shot_guardian_acorn": ("古枝守衛三顆低低錯拍的殼音", thud(211,.14,.30), thud(276,.12,.22,.024), metal(379,294,.10,.16,.052), air(2150,880,.20,.31)),
    "shot_sound_crescent": ("聲刃有顫動金屬共鳴的寬刃風", metal(699,351,.27,.29), air(3200,960,.24,.39)),
    "shot_mineral_dart": ("礦晶飛鏢以礦片擦響加銳風", metal(1115,725,.14,.27), air(3620,1140,.15,.37)),
    "shot_resin_orb": ("黏重樹脂球啵地離開", thud(191,.16,.31), reed(325,163,.20,.22), air(850,535,.19,.28)),
    "shot_seed_needle": ("乾種籽尖刺後接短破風", metal(690,455,.11,.23), air(3060,1100,.14,.39)),
    "shot_web_seed": ("蛛絲擠出後忽然鬆開", air(2450,490,.23,.35), reed(363,211,.18,.18,.045)),
    "shot_leaf_crescent": ("寬葉切過空氣帶輕刃鳴", air(2400,1240,.22,.37), metal(602,461,.20,.19)),
    "shot_feather": ("輕拍亮羽出手", air(3740,1450,.19,.39), reed(618,809,.10,.16)),
    "shot_storm_dart": ("雷暴飛鏢以電花泛音帶銳風", metal(1250,636,.17,.22), air(4300,1040,.23,.36)),
    "shot_moss_shard": ("苔殼裂點伴木質薄片離手", thud(240,.12,.24), air(2210,700,.18,.36), metal(466,265,.11,.16)),
    "shot_spring_seed": ("彈枝種籽彈性上滑", reed(145,368,.17,.23), air(1640,710,.18,.31)),
    "shot_lamp_pollen": ("守燈光塵有微亮顆粒鳴響", metal(846,1070,.22,.21), air(1400,780,.23,.22)),
    "shot_mist_spore": ("流霧孢囊有散粉低風", air(1320,440,.24,.30), reed(230,142,.19,.19)),
    "shot_root_spear": ("厚根離枝後切風", thud(192,.13,.29), air(3150,580,.21,.39), metal(431,270,.14,.18)),
}

CUES.update({
    "boss_sky_0": ("掠空雙爪，兩次不等距爪風", air(2600,760,.16,.42), air(3100,1040,.21,.39,.09), metal(451,340,.26,.18)),
    "boss_sky_1": ("暴風翎槍，電金屬加一發銳風", metal(904,403,.32,.34), air(4500,990,.36,.45), thud(133,.23,.30)),
    "boss_sky_2": ("散翼風刃，扇形風加二層尾音", air(3600,1200,.36,.44), metal(562,243,.29,.28), air(2200,800,.18,.20,.11)),
    "boss_sky_3": ("折翼雷列，重雷底與錯開電火", thud(110,.32,.36), air(5200,870,.38,.45), metal(1153,468,.16,.21,.060), metal(893,569,.19,.22,.117)),
    "boss_canopy_0": ("剪冠雙鐮，兩個刀齒碰響", metal(467,340,.16,.30), metal(510,265,.19,.27,.09), air(2620,665,.30,.39)),
    "boss_canopy_1": ("折返葉刃，遠去風後轉高回旋", air(3100,1050,.37,.41), metal(510,242,.28,.31), air(1120,2400,.18,.20,.12)),
    "boss_canopy_2": ("伏鐮穿冠，沉重低撞接長刃切風", thud(121,.34,.38), air(3200,580,.41,.45), metal(351,138,.34,.30)),
    "boss_canopy_3": ("雙層返刃，雙金屬輪廓與拉長風", air(2750,840,.43,.41), metal(582,415,.25,.27), metal(392,211,.28,.24,.12)),
    "boss_branches_0": ("撐足刺擊，硬節點和短木擦", thud(200,.16,.29), air(1980,620,.24,.39), metal(355,271,.16,.23,.08)),
    "boss_branches_1": ("穿枝束絲，張緊繩響加雙發風", reed(248,590,.24,.30), air(2420,480,.29,.40), metal(499,387,.16,.17,.11)),
    "boss_branches_2": ("三節封網，織絲抖動和網節落點", air(1900,620,.33,.37), thud(172,.16,.26), reed(313,204,.17,.18,.10)),
    "boss_branches_3": ("蛛絲流星，較重繭彈甩出後拉絲尾", thud(169,.22,.35), air(2620,640,.35,.41), reed(354,182,.19,.23,.11)),
    "boss_trunk_0": ("鍬角夾擊，低沉夾碰伴硬殼", thud(124,.23,.42), metal(365,235,.18,.27), air(1800,500,.18,.38)),
    "boss_trunk_1": ("碎琥珀榴彈，實心拋響與晶片尾音", thud(139,.28,.40), metal(373,187,.23,.31), air(1730,580,.29,.38)),
    "boss_trunk_2": ("低角破木，木屑風伴低重音", thud(104,.41,.44), air(1580,460,.41,.43), metal(266,134,.24,.23)),
    "boss_trunk_3": ("琥珀碎槍，兩枚琥珀先後擦裂", metal(722,357,.20,.33), air(3980,1260,.26,.41), metal(546,242,.22,.23,.068)),
    "boss_grass_0": ("長舌點刺，彈性下降滑音", reed(272,130,.23,.33), air(2180,430,.21,.41), thud(169,.12,.27)),
    "boss_grass_1": ("浮沫氣泡，三顆錯開的柔泡", reed(176,390,.15,.31), reed(233,514,.14,.23,.069), reed(287,468,.19,.26,.11), air(1190,690,.29,.28)),
    "boss_grass_2": ("鼓腹震地，腹腔低擊和泥水聲", thud(75,.43,.46), air(1260,310,.42,.44), reed(156,70,.28,.24)),
    "boss_grass_3": ("落露泥沼，黏液長氣和濕土落點", reed(238,101,.21,.31), air(1750,440,.34,.37), thud(127,.14,.24)),
    "boss_underground_0": ("翻岩掘爪，沙石碎裂", thud(108,.29,.42), air(2670,490,.28,.41), metal(287,202,.18,.24)),
    "boss_underground_1": ("雙向裂地，長低頻沿地表展開", thud(86,.38,.41), air(1270,380,.39,.44), metal(225,136,.32,.27)),
    "boss_underground_2": ("鑽土根陣，粗根破土後帶落礫", thud(131,.29,.40), air(1690,590,.30,.38), metal(309,166,.16,.23,.10)),
    "boss_underground_3": ("潛鑽破根，持續顫動的重土摩擦", thud(89,.44,.42), air(1990,390,.45,.42), reed(254,93,.36,.28)),
})


def render(name, layers, target):
    rng = Random(int.from_bytes(sha256(name.encode()).digest()[:8], "big"))
    mixed = [0.0] * max(round((layer[3] + layer[5]) * RATE) for layer in layers)
    for material, start, end, duration, gain, onset in layers:
        count = round(duration * RATE)
        offset = round(onset * RATE)
        phase = low = high = 0.0
        attack = .018 if material == "air" else .008
        for index in range(count):
            progress = index / count
            hz = start * (end / start) ** progress
            phase += tau * hz / RATE
            envelope = min(index / (RATE * attack), 1.0) * (1.0 - progress) ** 2.3
            if material == "air":
                white = rng.uniform(-1, 1)
                high += (white - high) * (1.0 - exp(-tau * hz / RATE))
                low += (white - low) * (1.0 - exp(-tau * hz * .24 / RATE))
                tone = 1.8 * (high - low) * (.77 + .23 * cos(tau * (10 + start % 13) * index / RATE))
            elif material == "metal":
                tone = .53 * sin(phase) + .31 * sin(1.61 * phase) + .16 * sin(2.33 * phase)
            elif material == "reed":
                tone = .75 * sin(phase) + .25 * sin(2 * phase + .6)
            else:
                tone = sin(phase)
            mixed[offset + index] += tone * gain * envelope
    peak = max(map(abs, mixed))
    if not .03 < peak < 1:
        raise ValueError(f"{name}: unexpected peak {peak:.3f}")
    gain = min(1.0, .68 / peak)
    pcm = array("h", (round(sample * gain * 32767) for sample in mixed))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(target), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())


def main():
    project = Path(__file__).resolve().parents[1]
    folder = project / "assets/v63/audio"
    folder.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory() as temporary:
        source = Path(temporary) / "cue.wav"
        for name, (_, *layers) in CUES.items():
            render(name, layers, source)
            subprocess.run(
                ["ffmpeg", "-nostdin", "-v", "error", "-y", "-fflags", "+bitexact", "-i", str(source),
                 "-c:a", "libvorbis", "-flags:a", "+bitexact", "-q:a", "2", str(folder / f"{name}.ogg")],
                check=True,
            )
    print(f"Rendered {len(CUES)} game cues")


if __name__ == "__main__":
    main()
