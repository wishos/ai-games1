extends Node2D

# 强制预加载类定义 (解决class_name编译顺序问题)
const _PlayerDataClass = preload("res://scripts/player.gd")
const _EnemyDataClass = preload("res://scripts/enemy.gd")

# 游戏状态
enum State { TITLE, EXPLORE, BATTLE, DIALOG, SHOP, CLASS_SELECT }
var game_state = State.CLASS_SELECT

# 职业枚举 (从PlayerData复制)
enum Job { WARRIOR, MAGE, HUNTER, THIEF, PRIEST, KNIGHT, BARD, SUMMONER }

# 玩家数据
var player_data
var player: CharacterBody2D

# 地图
var tile_map: TileMap
var current_floor: int = 1
var fog_map: Dictionary = {}
var fog_container: Node2D  # 迷雾容器,统一管理所有迷雾节点,避免逐个queue_free

# 战斗
var current_enemy: Dictionary = {}
var battle_ui: Control
var battle_log: Label
var battle_action_buttons: Array = []
var is_player_turn: bool = true
var battle_message: String = ""
var battle_message_timer: float = 0.0
var pending_skill_index: int = -1
var enemy_stun_turns: int = 0
var player_stun_turns: int = 0  # 玩家被眩晕回合数
var player_defending: bool = false
var player_shield: int = 0  # 护盾值
var poison_stacks: int = 0   # 中毒层数
var poison_damage: int = 0    # 每层中毒伤害
var poison_turns: int = 0     # 中毒剩余回合
var trapped: bool = false     # 陷阱触发标记
var contract_active: bool = false  # 契约标记
var contract_turns: int = 0   # 契约剩余回合
var resonance_stacks: int = 0  # 共鸣积累层数
var silenced: bool = false     # 沉默标记
var vanish_turns: int = 0      # 消失buff回合数
var berserk_turns: int = 0      # 血之狂暴buff回合数
var berserk_atk_boost: int = 0  # 狂暴ATK加成值
var battle_cry_turns: int = 0   # 战吼buff回合数
var battle_cry_atk_boost: int = 0  # 战吼自身ATK加成
var battle_cry_team_boost: int = 0  # 战吼队友ATK加成(对玩家=自身)
# 法师T2状态
var meteor_burn_turns: int = 0     # 流星火雨灼烧回合
var meteor_burn_dmg: int = 0        # 流星火雨每回合灼烧伤害
var frost_slow_turns: int = 0       # 霜冻领域减速回合
var arcane_shield_mp: int = 0      # 魔法盾MP值
var spell_pierce_turns: int = 0     # 法术穿透回合(无视DEF)
var mana_drain_turns: int = 0       # 魔力回旋回合
var mana_drain_amount: int = 0      # 魔力回旋每次吸取量
# 法师T3状态
var absolute_zero_turns: int = 0    # 绝对零度冰冻回合
var meteor_turns: int = 0           # 陨石术灼烧回合(独立标记)
var meteor_dmg: int = 0             # 陨石术每回合灼烧伤害
var elemental_storm_turns: int = 0   # 元素风暴持续回合
var elemental_storm_dmg: int = 0     # 元素风暴每回合元素伤害
var time_stop_active: bool = false  # 时间静止激活(本回合敌人跳过)
var time_stop_turns: int = 0        # 时间静止剩余回合
var arcane_truth_turns: int = 0     # 奥术真理持续回合(所有属性伤害+50%)
var arcane_truth_active: bool = false  # 奥术真理本场战斗标记
# 法师T4状态
var arcane_weaving_history: Array = []  # 秘法编织:记录最后使用的技能(最多3个)
var elemental_annihilation_weak_mult: float = 2.0  # 元素湮灭:弱点伤害倍率(持续到战斗结束)

# 猎人T2状态
var hunter_evasion_turns: int = 0    # 猎豹加速闪避回合
var hunter_speed_boost_turns: int = 0  # 猎豹加速速度加成回合
var hunter_armor_pierce_turns: int = 0  # 穿甲箭穿透回合
var hunter_trap_dot_dmg: int = 0     # 致命陷阱每回合伤害
var hunter_trap_turns: int = 0        # 致命陷阱持续回合
var hunter_trap_slow: int = 0         # 致命陷阱减速量
# 猎人T3状态
var hunter_one_hit_escape: bool = false  # 一击脱离:下次攻击必闪避
var hunter_mark_turns: int = 0          # 猎杀时刻标记回合
var hunter_mark_mult: float = 1.0       # 猎杀时刻伤害倍率
var hunter_beast_turns: int = 0        # 野兽之力召唤回合
var hunter_beast_dmg: int = 0           # 野兽之力每回合伤害
var hunter_death_mark_turns: int = 0    # 死标记持续回合
var hunter_death_mark_dmg: float = 1.0  # 死标记当前伤害倍率
var hunter_nature_power_turns: int = 0  # 自然之力持续回合
var hunter_nature_power_bonus: float = 1.0  # 自然之力每召唤物加成
var hunter_hunting_field_turns: int = 0 # 狩猎领域持续回合
# 盗贼T2状态
var thief_poison_turns: int = 0      # 淬毒利刃回合
var thief_poison_dmg: int = 0         # 淬毒利刃伤害
var thief_choke_turns: int = 0        # 锁喉眩晕回合
var thief_combo_count: int = 0         # 致命连击连击计数
var thief_combo_dmg: int = 0           # 致命连击累计伤害
# 盗贼T3状态
var thief_shadow_clone_turns: int = 0  # 影分身:分身持续回合
var thief_shadow_fang_turns: int = 0   # 暗影之牙:敌人DEF降低回合
var thief_shadow_fang_defdebuff: int = 0 # 暗影之牙:DEF降低量
# 盗贼T4状态
var thief_thousand_faces_turns: int = 0  # 千面杀手:持续回合
var thief_shadow_devour_turns: int = 0   # 暗影吞噬:持续回合
var thief_illusion_domain_turns: int = 0  # 幻惑领域:持续回合
# 牧师T2状态
var priest_mass_heal_mp: int = 0      # 群体治疗MP量(用于分摊护盾)
var priest_dispel_done: bool = false  # 驱散本回合已用
var priest_smite_turns: int = 0        # 神圣仲裁atk降低回合
var priest_smite_defdebuff: int = 0    # 神圣仲裁降低def量
# 牧师T3状态
var priest_resurrection_uses: int = 0     # 复活术:剩余复活次数(每战斗2次)
var priest_divine_domain_turns: int = 0   # 神圣领域:持续回合
var priest_divine_domain_heal: int = 0  # 神圣领域:每回合治疗量
var priest_life_fountain_turns: int = 0  # 生命之泉:持续回合
var priest_life_fountain_heal: int = 0   # 生命之泉:每回合治疗量
var priest_divine_judgment_turns: int = 0  # 神圣裁定:持续回合(对邪恶生物增伤)
# 牧师T4状态
var priest_divine_miracle_used: bool = false  # 神迹:是否已使用
var priest_holy_sentinel_active: bool = false  # 永恒庇护:是否激活
var priest_holy_sentinel_hp_threshold: int = 0  # 永恒庇护:触发阈值
# 骑士T2状态
var knight_shield_bang_dmg: int = 0   # 盾击伤害量(溢出为盾)
var knight_judgment_turns: int = 0     # 圣光审判降低防御回合
var knight_judgment_defdebuff: int = 0 # 圣光审判降低防御量
var knight_iron_wall_turns: int = 0    # 钢铁壁垒持续回合
var knight_iron_wall_defboost: int = 0 # 钢铁壁垒防御加成
var knight_holy_avenger_turns: int = 0  # 神圣复仇持续回合(DOT)
var knight_holy_avenger_dmg: int = 0    # 神圣复仇每回合伤害
var knight_eternal_guard_turns: int = 0  # 永恒守卫:替队友承受伤害的回合数
var knight_eternal_guard_target: int = -1  # 永恒守卫保护的目标队友索引
var knight_judgment_aoe_turns: int = 0  # 圣光审判AOE持续回合
var knight_judgment_aoe_dmg: int = 0    # 圣光审判AOE每回合伤害
var knight_angel_guard_turns: int = 0    # 天使守护:全队HP不降至1以下
var knight_angel_guard_triggered: bool = false  # 天使守护是否已触发过
var knight_holy_hammer_turns: int = 0   # 神圣之锤印记回合
var knight_holy_hammer_mult: float = 2.0  # 神圣之锤暴击倍率
var knight_execution_turns: int = 0      # 正义执行:斩杀生效回合
# 吟游诗人T2状态
var bard_song_atk_turns: int = 0       # 战斗乐章atk提升回合
var bard_song_atk_boost: int = 0        # 战斗乐章提升量
var bard_rhythm_turns: int = 0          # 疯狂节拍减速回合
var bard_healing_melody_mp: int = 0     # 天籁之音治疗量
# 吟游诗人 T2 路线B 幻术师状态
var bard_hypno_turns: int = 0           # 催眠曲沉睡回合
var bard_hallucinate_turns: int = 0     # 幻听闪避提升回合
var bard_chaos_turns: int = 0           # 混乱之音回合
var bard_chaos_active: bool = false     # 混乱之音激活标记(用于先手判定)

# 吟游诗人T3/T4状态
var bard_perfect_chord_turns: int = 0   # 完美和弦buff回合
var bard_perfect_chord_atk_boost: int = 0
var bard_perfect_chord_crit_boost: int = 0
var bard_requiem_turns: int = 0         # 终末安魂曲禁止回复回合
var bard_requiem_used: bool = false     # 终末安魂曲是否已用
var bard_void_aria_turns: int = 0       # 虚空咏叹调debuff回合
var bard_void_aria_stat_debuff: int = 0 # 虚空咏叹调属性削弱量
var bard_legendary_song_atk_boost: int = 0  # 传奇之歌永久ATK
var bard_legendary_song_def_boost: int = 0  # 传奇之歌永久DEF
var bard_life_song_used: bool = false   # 生命赞歌每战斗限1次
# 召唤师T2状态
var summoner_contract_boost_turns: int = 0  # 契约强化回合
var summoner_contract_boost_dmg: int = 0    # 契约强化伤害加成
var summoner_soul_link_turns: int = 0        # 灵魂连接回合
var summoner_soul_link_dmg: int = 0          # 灵魂连接每回合伤害
var summoner_beast_boost_turns: int = 0       # 召唤兽强化回合
# 召唤师T3/T4状态 - 召唤物系统
var active_summons: Array = []  # [{name, hp, max_hp, atk, turns, type}]
var summoner_fusion_active: bool = false  # 召唤融合:当前是否处于融合状态
var summoner_fusion_turns: int = 0        # 召唤融合持续回合
var summoner_fusion_power: int = 0         # 融合召唤物的攻击力
var summoner_fusion_hp: int = 0            # 融合召唤物的HP
var summoner_soul_contract_turns: int = 0   # 契约之魂:召唤物自动攻击持续回合
var summoner_soul_contract_dmg_boost: int = 0  # 契约之魂:召唤物伤害加成
# 战士T3状态
var warrior_shatter_turns: int = 0          # 碎甲:敌人DEF降低回合
var warrior_shatter_defdebuff: int = 0       # 碎甲:敌人DEF降低量
var warrior_shatter_orig_def: int = 0         # 碎甲:敌人原始DEF(用于恢复)
var warrior_domain_turns: int = 0            # 战神领域持续回合
var warrior_domain_atk_boost: int = 0        # 战神领域ATK加成
var warrior_domain_def_boost: int = 0        # 战神领域DEF加成
var warrior_guard_active: bool = false       # 援护:是否已援护过
var warrior_guard_target_hp_pct: float = 0.0  # 援护:目标HP百分比
var warrior_undying_used: bool = false       # 不死不灭:是否已触发
var warrior_bloodlust_active: bool = false  # 浴血奋战:激活状态
var warrior_wargod_mark_turns: int = 0      # 战神之力:战神印记持续回合
var warrior_wargod_mark_dmg_boost: int = 0   # 战神之力:受伤加成量
var warrior_absolute_def_turns: int = 0      # 绝对防御:持续回合
var warrior_conqueror_fear_turns: int = 0   # 征服者怒吼:恐惧持续回合
var warrior_conqueror_fear_atkdebuff: int = 0  # 征服者怒吼:ATK降低量

# 技能冷却系统
var skill_cooldowns: Dictionary = {}  # {skill_name: remaining_turns}
var battle_started: bool = false     # 战斗是否已开始(用于陷阱被动)
var enemy_hit_this_battle: bool = false  # 敌人本场战斗是否命中过玩家

# 相机抖动
var camera_shake_intensity: float = 0.0
var camera_shake_duration: float = 0.0
var camera_shake_timer: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO
var battle_camera: Camera2D

# 粒子效果系统
var particle_container: Node2D

# UI
var hp_label: Label
var mp_label: Label
var gold_label: Label
var floor_label: Label
var message_label: Label
var job_label: Label

# 小地图
var minimap_container: Control
var minimap_tiles: Array = []  # 2D array of ColorRects

# 商店
var shop_ui: Control
var shop_items: Array = []
var selected_shop_tab: int = 0  # 0=武器 1=防具 2=饰品 3=药水 4=强化
var shop_tabs: Array = ["⚔️ 武器", "🛡️ 防具", "💍 饰品", "🧪 药水", "🔨 强化"]
var shop_item_buttons: Array = []
var shop_nearby: bool = false
var shop_sign_pos: Vector2 = Vector2(0, 0)

# 背包
var inventory_ui: Control
var inventory_item_buttons: Array = []
var inventory_open: bool = false

# 任务日志
var quest_log_ui: Control
var quest_log_buttons: Array = []
var quest_log_open: bool = false

# 商店数据
const SHOP_WEAPONS = [
	{"name": "铁剑 ★",      "atk": 5,  "def": 0,  "hp": 20,  "mp": 5,  "spd": 1, "luk": 1, "price": 100,  "grade": 1, "icon": "⚔️"},
	{"name": "钢剑 ★★",     "atk": 12, "def": 0,  "hp": 50,  "mp": 12, "spd": 2, "luk": 2, "price": 300,  "grade": 2, "icon": "⚔️"},
	{"name": "秘银剑 ★★★",  "atk": 25, "def": 0,  "hp": 100, "mp": 25, "spd": 4, "luk": 4, "price": 800,  "grade": 3, "icon": "⚔️"},
	{"name": "龙鳞剑 ★★★★", "atk": 50, "def": 0,  "hp": 200, "mp": 50, "spd": 8, "luk": 8, "price": 2000, "grade": 4, "icon": "⚔️"},
	{"name": "神圣长剑 ★★★★★","atk":100,"def": 0,  "hp": 400, "mp": 100,"spd":15, "luk":15, "price": 5000, "grade": 5, "icon": "⚔️"},
]
const SHOP_ARMORS = [
	{"name": "皮甲 ★",      "atk": 0,  "def": 3,  "hp": 20,  "mp": 5,  "spd": 1, "luk": 1, "price": 80,   "grade": 1, "icon": "🛡️"},
	{"name": "锁甲 ★★",     "atk": 0,  "def": 8,  "hp": 50,  "mp": 12, "spd": 2, "luk": 2, "price": 250,  "grade": 2, "icon": "🛡️"},
	{"name": "板甲 ★★★",    "atk": 0,  "def": 18, "hp": 100, "mp": 25, "spd": 4, "luk": 4, "price": 600,  "grade": 3, "icon": "🛡️"},
	{"name": "龙鳞甲 ★★★★", "atk": 0,  "def": 35, "hp": 200, "mp": 50, "spd": 8, "luk": 8, "price": 1500, "grade": 4, "icon": "🛡️"},
	{"name": "神圣铠甲 ★★★★★","atk":0, "def":70, "hp": 400, "mp": 100,"spd":15, "luk":15, "price": 4000, "grade": 5, "icon": "🛡️"},
]
const SHOP_ACCESSORIES = [
	{"name": "幸运戒指 ★",      "atk": 1,  "def": 1,  "hp": 20,  "mp": 5,  "spd": 1, "luk": 3, "price": 60,   "grade": 1, "icon": "💍"},
	{"name": "敏捷护符 ★★",     "atk": 2,  "def": 2,  "hp": 50,  "mp": 12, "spd": 4, "luk": 2, "price": 200,  "grade": 2, "icon": "📿"},
	{"name": "魔力挂坠 ★★★",    "atk": 4,  "def": 4,  "hp": 100, "mp": 50, "spd": 4, "luk": 4, "price": 400,  "grade": 3, "icon": "💎"},
	{"name": "龙之心 ★★★★",     "atk": 8,  "def": 8,  "hp": 200, "mp": 100,"spd": 8, "luk": 8, "price": 1000, "grade": 4, "icon": "🔥"},
	{"name": "神圣护符 ★★★★★",  "atk":15, "def":15, "hp": 400, "mp": 200,"spd":15, "luk":15, "price": 3000, "grade": 5, "icon": "✨"},
]
const SHOP_POTIONS = [
	{"name": "小血药",  "heal_hp": 30, "heal_mp": 0,  "price": 20,  "icon": "❤️"},
	{"name": "大血药",  "heal_hp": 80, "heal_mp": 0,  "price": 80,  "icon": "💗"},
	{"name": "小蓝药",  "heal_hp": 0,  "heal_mp": 30, "price": 30,  "icon": "💙"},
	{"name": "大蓝药",  "heal_hp": 0,  "heal_mp": 80, "price": 100, "icon": "💘"},
	{"name": "普通强化石",  "material": "普通强化石", "price": 80,  "icon": "💎"},
	{"name": "优秀强化石",  "material": "优秀强化石", "price": 200, "icon": "💠"},
	{"name": "稀有强化石",  "material": "稀有强化石", "price": 500, "icon": "🔷"},
]

# 装备强化系统
# 强化成功率(+10开始有失败风险)
const ENHANCE_SUCCESS_RATES = {
	10: 80, 11: 65, 12: 50, 13: 35, 14: 20, 15: 10
}
# 强化费用(金币)
const ENHANCE_COSTS = {
	1: 100, 2: 100, 3: 100, 4: 300, 5: 300, 6: 300,
	7: 600, 8: 600, 9: 600, 10: 1200, 11: 1800,
	12: 2500, 13: 3500, 14: 5000, 15: 8000
}
# 强化所需材料(按装备品质grade)
const ENHANCE_MATERIALS = {
	# grade: [材料名称, 数量]
	1: ["普通强化石", 1],
	2: ["优秀强化石", 1],
	3: ["稀有强化石", 1],
	4: ["史诗强化石", 1],
	5: ["传说强化石", 1],
}

# 音频管理器
var audio_manager: Node

# 调色板 (Octopath风格)
const PALETTE = {
	"sky_top": Color("#1a1528"),
	"sky_bottom": Color("#3d2a4a"),
	"grass_1": Color("#5a8a3a"),  # 调亮
	"grass_2": Color("#6a9a4a"),  # 调亮
	"wall": Color("#4a4a5a"),
	"wall_top": Color("#6a6a7a"),
	"path": Color("#8a7a5a"),
	"hero_cape": Color("#8b2942"),
	"hero_armor": Color("#4a6a8a"),
	"hero_skin": Color("#e8c8a0"),
	"gold": Color("#c9a227")
}

# ============================================================
# 成就系统
# ============================================================

# 成就定义
const ACHIEVEMENTS = {
	# === 探索成就 ===
	"first_step": {
		"name": "初出茅庐",
		"desc": "首次击败敌人",
		"icon": "⚔️",
		"category": "explore",
		"condition": "enemies_defeated >= 1"
	},
	"slayer_10": {
		"name": "江湖新秀",
		"desc": "累计击败10个敌人",
		"icon": "🗡️",
		"category": "explore",
		"condition": "enemies_defeated >= 10"
	},
	"slayer_50": {
		"name": "江湖高手",
		"desc": "累计击败50个敌人",
		"icon": "🔪",
		"category": "explore",
		"condition": "enemies_defeated >= 50"
	},
	"slayer_100": {
		"name": "一代宗师",
		"desc": "累计击败100个敌人",
		"icon": "🏆",
		"category": "explore",
		"condition": "enemies_defeated >= 100"
	},
	"floor_2": {
		"name": "初窥门径",
		"desc": "抵达第2层",
		"icon": "🚪",
		"category": "explore",
		"condition": "max_floor_reached >= 2"
	},
	"floor_4": {
		"name": "渐入佳境",
		"desc": "抵达第4层",
		"icon": "🌿",
		"category": "explore",
		"condition": "max_floor_reached >= 4"
	},
	"floor_6": {
		"name": "登堂入室",
		"desc": "抵达第6层",
		"icon": "⛰️",
		"category": "explore",
		"condition": "max_floor_reached >= 6"
	},
	"floor_8": {
		"name": "江湖至尊",
		"desc": "抵达第8层(通关)",
		"icon": "👑",
		"category": "explore",
		"condition": "max_floor_reached >= 8"
	},
	# === Boss成就 ===
	"boss_1": {
		"name": "首战告捷",
		"desc": "击败山贼王·韩霸天",
		"icon": "💀",
		"category": "boss",
		"condition": "bosses_defeated >= 1"
	},
	"boss_3": {
		"name": "除暴安良",
		"desc": "击败血刀门护法",
		"icon": "🩸",
		"category": "boss",
		"condition": "bosses_defeated >= 2"
	},
	"boss_5": {
		"name": "替天行道",
		"desc": "击败门派叛徒",
		"icon": "⚡",
		"category": "boss",
		"condition": "bosses_defeated >= 3"
	},
	"boss_7": {
		"name": "武林盟主",
		"desc": "击败华山掌门",
		"icon": "🌟",
		"category": "boss",
		"condition": "bosses_defeated >= 4"
	},
	"boss_final": {
		"name": "天下无敌",
		"desc": "击败武当真人·张三丰,通关游戏",
		"icon": "🏮",
		"category": "boss",
		"condition": "bosses_defeated >= 5"
	},
	# === 职业成就 ===
	"warrior_win": {
		"name": "战士之道",
		"desc": "使用战士职业击败Boss",
		"icon": "⚔️",
		"category": "job",
		"condition": "warrior_boss_wins >= 1"
	},
	"mage_win": {
		"name": "法师之道",
		"desc": "使用法师职业击败Boss",
		"icon": "🔮",
		"category": "job",
		"condition": "mage_boss_wins >= 1"
	},
	"all_jobs": {
		"name": "八大门派",
		"desc": "使用全部8个职业各击败至少1个Boss",
		"icon": "🎭",
		"category": "job",
		"condition": "unique_jobs_boss_wins >= 8"
	},
	# === 财富成就 ===
	"rich_1000": {
		"name": "小有身家",
		"desc": "累计获得1000金币",
		"icon": "💰",
		"category": "wealth",
		"condition": "total_gold_earned >= 1000"
	},
	"rich_5000": {
		"name": "富甲一方",
		"desc": "累计获得5000金币",
		"icon": "💎",
		"category": "wealth",
		"condition": "total_gold_earned >= 5000"
	},
	"rich_10000": {
		"name": "江湖首富",
		"desc": "累计获得10000金币",
		"icon": "👛",
		"category": "wealth",
		"condition": "total_gold_earned >= 10000"
	},
	# === 战斗成就 ===
	"elite_slayer": {
		"name": "精英猎手",
		"desc": "击败3个精英敌人",
		"icon": "⭐",
		"category": "battle",
		"condition": "elite_enemies_defeated >= 3"
	},
	"no_damage_floor": {
		"name": "毫发无损",
		"desc": "单层地牢不受到任何伤害通关",
		"icon": "🌟",
		"category": "battle",
		"condition": "no_damage_floors >= 1"
	},
	"perfect_victory": {
		"name": "完美胜利",
		"desc": "在敌人未命中任何攻击的情况下击败敌人",
		"icon": "✨",
		"category": "battle",
		"condition": "perfect_victories >= 1"
	},
	# === 特殊成就 ===
	"level_10": {
		"name": "小有所成",
		"desc": "角色等级达到10级",
		"icon": "📈",
		"category": "special",
		"condition": "max_level_reached >= 10"
	},
	"level_20": {
		"name": "登峰造极",
		"desc": "角色等级达到20级",
		"icon": "📊",
		"category": "special",
		"condition": "max_level_reached >= 20"
	},
	"all_quests": {
		"name": "江湖游侠",
		"desc": "累计完成10个任务",
		"icon": "📜",
		"category": "special",
		"condition": "quests_completed >= 10"
	},
	"shop_master": {
		"name": "挥金如土",
		"desc": "在商店消费累计5000金币",
		"icon": "🛒",
		"category": "special",
		"condition": "total_gold_spent >= 5000"
	}
}

# Boss数据 (第1/3/5/7/8层) - 武侠江湖主题
const BOSS_DATA = {
	1: {
		"id": "boss_bandit_king",
		"name": "山贼王·韩霸天",
		"title": "第1层Boss",
		"hp": 350, "atk": 25, "def": 12, "spd": 5, "luk": 5,
		"exp": 500, "gold": 300,
		"color": Color(0.55, 0.25, 0.1),
		"phase_hp": 0.3,  # 30%血量触发狂暴
		"skills": ["普通攻击", "战吼", "召集喽啰", "狂暴化"],
		"description": "盘踞在黑风寨的山贼首领,刀法霸道,据说曾是某个门派的弃徒。"
	},
	3: {
		"id": "boss_blood_sect",
		"name": "血刀门护法·血手赫连铁树",
		"title": "第3层Boss",
		"hp": 600, "atk": 45, "def": 15, "spd": 6, "luk": 8,
		"exp": 1200, "gold": 800,
		"color": Color(0.65, 0.1, 0.1),
		"phase_hp": 0.2,  # 20%血量触发血战到底
		"skills": ["一线斩", "血雾", "血刀斩", "嗜血狂刀", "血战到底"],
		"description": "血刀门四大护法之一,双手染满江湖人士的鲜血,绝学「血战到底」一旦施展必死无疑。"
	},
	5: {
		"id": "boss_traitors",
		"name": "门派叛徒·司马青云",
		"title": "第5层Boss",
		"hp": 1200, "atk": 55, "def": 35, "spd": 3, "luk": 2,
		"exp": 2500, "gold": 1500,
		"color": Color(0.25, 0.2, 0.5),
		"phase_hp": 0.0,
		"skills": ["御剑术", "剑气纵横", "夺命十三剑", "金蝉脱壳"],
		"description": "原为某正派长老,盗取门派秘籍叛逃江湖,所学武功已入化境。"
	},
	7: {
		"id": "boss_yue_bucun",
		"name": "华山掌门·岳不群",
		"title": "第7层Boss",
		"hp": 2000, "atk": 70, "def": 30, "spd": 8, "luk": 12,
		"exp": 5000, "gold": 3000,
		"color": Color(0.85, 0.7, 0.3),
		"phase_hp": 0.0,
		"skills": ["紫霞神功", "独孤九剑", "吸星大法", "辟邪剑法", "伪君子真面目"],
		"description": "华山派掌门,外号「君子剑」,实则城府极深,为夺葵花宝典不择手段。"
	},
	8: {
		"id": "boss_zhang_sanfeng",
		"name": "武当真人·张三丰",
		"title": "最终Boss",
		"hp": 5000, "atk": 100, "def": 50, "spd": 10, "luk": 15,
		"exp": 15000, "gold": 10000,
		"color": Color(0.7, 0.85, 1.0),
		"phase_hp": 0.6,  # 60%进入第二阶段
		"phase2_hp": 0.3,  # 30%进入第三阶段
		"skills": ["太极拳", "太极剑", "梯云纵", "纯阳无极功", "武当九阳功", "一代宗师"],
		"description": "武当派开山祖师,百年修为已臻化境,一套太极拳法无敌于天下。今日亲临,是考验也是收徒。"
	}
}

# ============================================================
# 普通敌人技能系统
# ============================================================

# 敌人原型 -> 战斗风格映射
const ENEMY_ARCHETYPE = {
	# 草寇势力 - 粗暴型
	"bandit": "brute",
	"bandit_elite": "brute",
	"deserter": "guardian",
	# 邪派势力 - 阴狠型
	"blood_sect_disciple": "rogue",
	"riyue_follower": "mystic",
	"wudu_disciple": "rogue",
	"skeleton_warrior": "guardian",
	"demon_red": "brute",
	# 散人势力 - 敏捷型
	"assassin": "rogue",
	"bounty_hunter": "guardian",
	"arena_champion": "brute",
	"hidden_master": "mystic",
	# 正派势力 - 均衡型
	"shaolin_disciple": "guardian",
	"wudang_disciple": "mystic"
}

# 各风格敌人的特殊技能列表
const ENEMY_SKILLS = {
	"brute": ["重击", "碎骨"],      # 高伤害+眩晕
	"rogue": ["淬毒", "锁喉"],      # 毒伤+眩晕
	"mystic": ["吸血", "噬魂"],     # 吸血+偷MP
	"guardian": ["盾击", "铁壁"],   # 眩晕+自护盾
	"beast": ["撕咬", "利爪"]        # 流血+连击
}

# 转换状态
var is_transitioning: bool = false
var transition_overlay: ColorRect
var current_boss_data: Dictionary = {}

# ============================================================
# 成就统计变量
# ============================================================
var achievement_stats: Dictionary = {
	"enemies_defeated": 0,
	"bosses_defeated": 0,
	"elite_enemies_defeated": 0,
	"max_floor_reached": 1,
	"total_gold_earned": 0,
	"total_gold_spent": 0,
	"perfect_victories": 0,
	"no_damage_floors": 0,
	"max_level_reached": 1,
	"quests_completed": 0,
	"warrior_boss_wins": 0,
	"mage_boss_wins": 0,
	"hunter_boss_wins": 0,
	"thief_boss_wins": 0,
	"priest_boss_wins": 0,
	"knight_boss_wins": 0,
	"bard_boss_wins": 0,
	"summoner_boss_wins": 0,
	"unique_jobs_boss_wins": 0
}
var unlocked_achievements: Array = []  # 已解锁成就ID列表
var achievement_notification_ui: Control = null  # 成就通知UI
var achievement_log_open: bool = false
var achievement_log_ui: Control = null
var achievement_log_buttons: Array = []
var _floor_damage_taken: int = 0  # 本层受到的伤害(用于计算无伤通关成就)
var boss_phase: int = 1  # Boss战阶段
var boss_enraged: bool = false  # Boss狂暴标记
var boss_shield_stacks: int = 0  # Boss护盾层数
var boss_revived: bool = false  # 巫妖复活标记

# 墙壁碰撞区 (简化)
var wall_rects: Array = []

# 动态加载EnemyData类 (解决class_name编译顺序问题)
func _get_enemy_data():
	return load("res://scripts/enemy.gd")

# 动态加载PlayerData类
func _get_player_data():
	return load("res://scripts/player.gd")

# 消息显示函数
func show_message(msg: String):
	if message_label:
		message_label.text = msg
	else:
		print("消息: ", msg)

# 相机抖动更新
func _update_camera_shake(delta: float):
	if camera_shake_timer > 0:
		camera_shake_timer -= delta
		var intensity = camera_shake_intensity * (camera_shake_timer / camera_shake_duration)
		camera_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	else:
		camera_offset = Vector2.ZERO

func _ready():
	randomize()
	# 初始化粒子容器
	particle_container = Node2D.new()
	particle_container.name = "ParticleContainer"
	add_child(particle_container)
	# 初始化音频管理器
	_setup_audio()
	_show_title_screen()

func _setup_audio():
	audio_manager = preload("res://scripts/audio_manager.gd").new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	# 播放标题音乐
	audio_manager.play_bgm("title")

# ==================== 标题画面系统 ====================
# 标题画面子状态
enum TitleState { MAIN_MENU, SLOT_SELECT, HOW_TO_PLAY, CLASS_SELECT, SLOT_CONFIRM }
var _title_state: TitleState = TitleState.MAIN_MENU
var _slot_select_is_new_game: bool = true  # true=新的江湖, false=继续游戏
var _confirm_slot: int = -1  # 确认覆盖的存档槽
var _init_slot: int = 0      # 当前选择的存档槽

func _show_title_screen():
	# 全屏背景
	var bg = ColorRect.new()
	bg.name = "TitleBG"
	bg.size = SCREEN_SIZE
	bg.color = PALETTE.sky_top
	add_child(bg)

	# 半透明遮罩
	var overlay = ColorRect.new()
	overlay.name = "TitleOverlay"
	overlay.size = SCREEN_SIZE
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	# 标题面板
	var title_panel = Panel.new()
	title_panel.name = "TitlePanel"
	title_panel.position = Vector2(140, 20)
	title_panel.size = Vector2(1000, 680)
	title_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	title_panel.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(title_panel)

	# 游戏标题
	var game_title = Label.new()
	game_title.name = "GameTitle"
	game_title.position = Vector2(0, 20)
	game_title.size = Vector2(1000, 60)
	game_title.text = "⚔️ 八方旅人 ⚔️"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_color_override("font_color", PALETTE.gold)
	game_title.add_theme_font_size_override("font_size", 36)
	title_panel.add_child(game_title)

	var subtitle = Label.new()
	subtitle.position = Vector2(0, 75)
	subtitle.size = Vector2(1000, 30)
	subtitle.text = "OCTOPATH ADVENTURE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	subtitle.add_theme_font_size_override("font_size", 14)
	title_panel.add_child(subtitle)

	_title_state = TitleState.MAIN_MENU
	_show_main_menu(title_panel)

func _show_main_menu(parent: Panel):
	# 清空现有子节点
	for child in parent.get_children():
		child.queue_free()

	# 装饰线
	var sep1 = Label.new()
	sep1.position = Vector2(0, 100)
	sep1.size = Vector2(1000, 20)
	sep1.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	sep1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep1.add_theme_color_override("font_color", Color(0.4, 0.35, 0.2))
	sep1.add_theme_font_size_override("font_size", 12)
	parent.add_child(sep1)

	# 版本信息
	var version = Label.new()
	version.position = Vector2(0, 580)
	version.size = Vector2(1000, 25)
	version.text = "v0.4 · 武侠Roguelike · HD-2D像素风格"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", Color(0.35, 0.35, 0.38))
	version.add_theme_font_size_override("font_size", 12)
	parent.add_child(version)

	var credit = Label.new()
	credit.position = Vector2(0, 605)
	credit.size = Vector2(1000, 20)
	credit.text = "制作: 张吉彬 · 引擎: Godot 4"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_color_override("font_color", Color(0.3, 0.3, 0.33))
	credit.add_theme_font_size_override("font_size", 11)
	parent.add_child(credit)

	# 菜单按钮
	var menu_start_y = 140
	var btn_w = 320
	var btn_h = 60
	var start_x = (1000 - btn_w) / 2

	# 按钮1: 新的江湖
	var new_btn = _create_menu_button("🗡️ 新的江湖", Vector2(start_x, menu_start_y), Vector2(btn_w, btn_h), PALETTE.gold)
	new_btn.pressed.connect(_on_new_game_pressed)
	parent.add_child(new_btn)

	var new_desc = Label.new()
	new_desc.position = Vector2(start_x + 20, menu_start_y + 62)
	new_desc.size = Vector2(btn_w - 40, 20)
	new_desc.text = "开始全新的江湖冒险"
	new_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	new_desc.add_theme_font_size_override("font_size", 11)
	parent.add_child(new_desc)

	# 按钮2: 江湖旧梦(继续)
	var has_any_save = has_save(0) or has_save(1) or has_save(2)
	var cont_btn = _create_menu_button("📜 江湖旧梦", Vector2(start_x, menu_start_y + 100), Vector2(btn_w, btn_h), Color(0.3, 0.7, 0.9))
	cont_btn.pressed.connect(_on_continue_pressed)
	if not has_any_save:
		# 无存档时显示为禁用
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
		disabled_style.border_color = Color(0.2, 0.2, 0.25)
		disabled_style.border_width_left = 1; disabled_style.border_width_top = 1
		disabled_style.border_width_right = 1; disabled_style.border_width_bottom = 1
		disabled_style.corner_radius_top_left = 5; disabled_style.corner_radius_top_right = 5
		disabled_style.corner_radius_bottom_right = 5; disabled_style.corner_radius_bottom_left = 5
		cont_btn.add_theme_stylebox_override("disabled", disabled_style)
		cont_btn.disabled = true
	parent.add_child(cont_btn)

	var cont_desc = Label.new()
	cont_desc.position = Vector2(start_x + 20, menu_start_y + 162)
	cont_desc.size = Vector2(btn_w - 40, 20)
	cont_desc.text = "继续上次的冒险" if has_any_save else "(暂无存档)"
	cont_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cont_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	cont_desc.add_theme_font_size_override("font_size", 11)
	parent.add_child(cont_desc)

	# 按钮3: 江湖秘籍(游戏说明)
	var how_btn = _create_menu_button("📖 江湖秘籍", Vector2(start_x, menu_start_y + 200), Vector2(btn_w, btn_h), Color(0.5, 0.8, 0.5))
	how_btn.pressed.connect(_on_how_to_play_pressed)
	parent.add_child(how_btn)

	var how_desc = Label.new()
	how_desc.position = Vector2(start_x + 20, menu_start_y + 262)
	how_desc.size = Vector2(btn_w - 40, 20)
	how_desc.text = "查看操作说明与游戏指南"
	how_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	how_desc.add_theme_font_size_override("font_size", 11)
	parent.add_child(how_desc)

	# 装饰线
	var sep2 = Label.new()
	sep2.position = Vector2(0, 340)
	sep2.size = Vector2(1000, 20)
	sep2.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	sep2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep2.add_theme_color_override("font_color", Color(0.4, 0.35, 0.2))
	sep2.add_theme_font_size_override("font_size", 12)
	parent.add_child(sep2)

	# 底部提示
	var hint = Label.new()
	hint.position = Vector2(0, 360)
	hint.size = Vector2(1000, 30)
	hint.text = "↑↓ 选择  ·  Enter确认  ·  ESC返回"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	hint.add_theme_font_size_override("font_size", 12)
	parent.add_child(hint)

	# 底部说明
	var tip = Label.new()
	tip.position = Vector2(0, 560)
	tip.size = Vector2(1000, 25)
	tip.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · 任务(Q) · 成就(K) · F2存档"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	tip.add_theme_font_size_override("font_size", 13)
	parent.add_child(tip)

func _create_menu_button(text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = size
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)

	var nstyle = StyleBoxFlat.new()
	nstyle.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	nstyle.border_color = color
	nstyle.border_width_left = 2; nstyle.border_width_top = 2
	nstyle.border_width_right = 2; nstyle.border_width_bottom = 2
	nstyle.corner_radius_top_left = 6; nstyle.corner_radius_top_right = 6
	nstyle.corner_radius_bottom_right = 6; nstyle.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", nstyle)

	var hstyle = StyleBoxFlat.new()
	hstyle.bg_color = Color(0.12, 0.10, 0.04, 0.95)
	hstyle.border_color = PALETTE.gold
	hstyle.border_width_left = 2; hstyle.border_width_top = 2
	hstyle.border_width_right = 2; hstyle.border_width_bottom = 2
	hstyle.corner_radius_top_left = 6; hstyle.corner_radius_top_right = 6
	hstyle.corner_radius_bottom_right = 6; hstyle.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("hover", hstyle)

	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	pstyle.border_color = PALETTE.gold
	pstyle.border_width_left = 2; pstyle.border_width_top = 2
	pstyle.border_width_right = 2; pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left = 6; pstyle.corner_radius_top_right = 6
	pstyle.corner_radius_bottom_right = 6; pstyle.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("pressed", pstyle)

	return btn

func _on_new_game_pressed():
	_slot_select_is_new_game = true
	_title_state = TitleState.SLOT_SELECT
	_show_slot_select(true)

func _on_continue_pressed():
	_slot_select_is_new_game = false
	_title_state = TitleState.SLOT_SELECT
	_show_slot_select(false)

func _on_how_to_play_pressed():
	_title_state = TitleState.HOW_TO_PLAY
	_show_how_to_play()

func _show_slot_select(is_new_game: bool):
	var title_panel = get_node("TitlePanel")
	# 清空面板
	for child in title_panel.get_children():
		child.queue_free()

	# 标题
	var title_lbl = Label.new()
	title_lbl.position = Vector2(0, 15)
	title_lbl.size = Vector2(1000, 40)
	title_lbl.text = "🗂️ 选择存档位" if is_new_game else "📜 继续冒险"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", PALETTE.gold)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_panel.add_child(title_lbl)

	var sub = Label.new()
	sub.position = Vector2(0, 55)
	sub.size = Vector2(1000, 25)
	sub.text = "选择要覆盖的存档" if is_new_game else "选择要读取的存档"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	sub.add_theme_font_size_override("font_size", 13)
	title_panel.add_child(sub)

	# 装饰线
	var sep = Label.new()
	sep.position = Vector2(0, 85)
	sep.size = Vector2(1000, 15)
	sep.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_color_override("font_color", Color(0.35, 0.3, 0.18))
	sep.add_theme_font_size_override("font_size", 11)
	title_panel.add_child(sep)

	# 存档槽列表
	var slots_per_col = 3
	var slot_w = 280
	var slot_h = 120
	var start_x = (1000 - slot_w * 3 - 40) / 2
	var start_y = 115

	for i in range(SAVE_SLOTS):
		var col = i % 3
		var row = i / 3
		var sx = start_x + col * (slot_w + 20)
		var sy = start_y + row * (slot_h + 15)

		var slot_exists = has_save(i)
		var slot_color = PALETTE.gold if slot_exists else Color(0.25, 0.25, 0.3)
		var slot_bg = Color(0.04, 0.04, 0.07, 0.95) if slot_exists else Color(0.03, 0.03, 0.05, 0.85)

		var slot_btn = Button.new()
		slot_btn.name = "SlotBtn_%d" % i
		slot_btn.position = Vector2(sx, sy)
		slot_btn.size = Vector2(slot_w, slot_h)

		var sn = StyleBoxFlat.new()
		sn.bg_color = slot_bg
		sn.border_color = slot_color
		sn.border_width_left = 2; sn.border_width_top = 2
		sn.border_width_right = 2; sn.border_width_bottom = 2
		sn.corner_radius_top_left = 6; sn.corner_radius_top_right = 6
		sn.corner_radius_bottom_right = 6; sn.corner_radius_bottom_left = 6
		slot_btn.add_theme_stylebox_override("normal", sn)

		var sh = StyleBoxFlat.new()
		sh.bg_color = Color(0.1, 0.08, 0.03, 0.95)
		sh.border_color = PALETTE.gold
		sh.border_width_left = 2; sh.border_width_top = 2
		sh.border_width_right = 2; sh.border_width_bottom = 2
		sh.corner_radius_top_left = 6; sh.corner_radius_top_right = 6
		sh.corner_radius_bottom_right = 6; sh.corner_radius_bottom_left = 6
		slot_btn.add_theme_stylebox_override("hover", sh)

		var sp = StyleBoxFlat.new()
		sp.bg_color = Color(0.03, 0.03, 0.06, 0.95)
		sp.border_color = PALETTE.gold
		sp.border_width_left = 2; sp.border_width_top = 2
		sp.border_width_right = 2; sp.border_width_bottom = 2
		sp.corner_radius_top_left = 6; sp.corner_radius_top_right = 6
		sp.corner_radius_bottom_right = 6; sp.corner_radius_bottom_left = 6
		slot_btn.add_theme_stylebox_override("pressed", sp)

		slot_btn.pressed.connect(_on_slot_selected.bind(i))
		title_panel.add_child(slot_btn)

		# 槽位标签
		var slot_lbl = Label.new()
		slot_lbl.name = "SlotLbl_%d" % i
		slot_lbl.position = Vector2(sx + 10, sy + 8)
		slot_lbl.size = Vector2(slot_w - 20, 22)
		slot_lbl.text = "存档位 %d" % (i + 1)
		slot_lbl.add_theme_color_override("font_color", slot_color)
		slot_lbl.add_theme_font_size_override("font_size", 14)
		title_panel.add_child(slot_lbl)

		# 存档信息
		if slot_exists:
			var save_info = _get_save_info_text(i)
			var info_lbl = Label.new()
			info_lbl.name = "SlotInfo_%d" % i
			info_lbl.position = Vector2(sx + 10, sy + 35)
			info_lbl.size = Vector2(slot_w - 20, 70)
			info_lbl.text = save_info
			info_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
			info_lbl.add_theme_font_size_override("font_size", 12)
			info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			title_panel.add_child(info_lbl)
		else:
			var empty_lbl = Label.new()
			empty_lbl.name = "SlotEmpty_%d" % i
			empty_lbl.position = Vector2(sx + 10, sy + 40)
			empty_lbl.size = Vector2(slot_w - 20, 60)
			empty_lbl.text = "(空)\n尚未在此存档"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
			empty_lbl.add_theme_font_size_override("font_size", 12)
			title_panel.add_child(empty_lbl)

	# 返回按钮
	var back_btn = _create_small_button("← 返回", Vector2(20, 630))
	back_btn.pressed.connect(_on_slot_back_pressed)
	title_panel.add_child(back_btn)

	var hint_lbl = Label.new()
	hint_lbl.position = Vector2(0, 630)
	hint_lbl.size = Vector2(1000, 25)
	hint_lbl.text = "点击存档位进入游戏"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	hint_lbl.add_theme_font_size_override("font_size", 12)
	title_panel.add_child(hint_lbl)

func _get_save_info_text(slot: int) -> String:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return "(空)"
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return "(读取失败)"
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return "(数据损坏)"
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return "(格式错误)"
	var pdata = data.get("player", {})
	var progress = data.get("progress", {})
	var ts = data.get("timestamp", "")
	var job_name = pdata.get("job_name", "?")
	var level = pdata.get("level", 1)
	var floor = progress.get("current_floor", 1)
	var gold = pdata.get("gold", 0)
	# 简化时间戳
	var short_ts = ts.substr(5, 11) if ts.length() > 11 else ts
	return "%s Lv.%d · 第%d层 · %d金\n%s" % [job_name, level, floor, gold, short_ts]

func _show_save_confirm(slot: int):
	_confirm_slot = slot
	_title_state = TitleState.SLOT_CONFIRM
	var title_panel = get_node("TitlePanel")
	# 清空面板
	for child in title_panel.get_children():
		child.queue_free()

	var confirm_lbl = Label.new()
	confirm_lbl.position = Vector2(0, 200)
	confirm_lbl.size = Vector2(1000, 50)
	confirm_lbl.text = "⚠️ 确认覆盖存档?"
	confirm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	confirm_lbl.add_theme_font_size_override("font_size", 22)
	title_panel.add_child(confirm_lbl)

	var info_lbl = Label.new()
	info_lbl.position = Vector2(0, 270)
	info_lbl.size = Vector2(1000, 30)
	info_lbl.text = "存档位 %d 的数据将被永久覆盖!" % (slot + 1)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
	info_lbl.add_theme_font_size_override("font_size", 14)
	title_panel.add_child(info_lbl)

	var old_save = _get_save_info_text(slot)
	var old_lbl = Label.new()
	old_lbl.position = Vector2(200, 320)
	old_lbl.size = Vector2(600, 80)
	old_lbl.text = "当前存档:\n" + old_save
	old_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	old_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	old_lbl.add_theme_font_size_override("font_size", 13)
	old_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_panel.add_child(old_lbl)

	var btn_y = 430
	var yes_btn = _create_menu_button("⚔️ 确认,开始新的江湖!", Vector2(250, btn_y), Vector2(500, 55), Color(0.9, 0.3, 0.3))
	yes_btn.pressed.connect(_on_confirm_new_game.bind(slot))
	title_panel.add_child(yes_btn)

	var no_btn = _create_small_button("← 返回", Vector2(20, 630))
	no_btn.pressed.connect(_on_slot_back_pressed)
	title_panel.add_child(no_btn)

func _on_slot_selected(slot: int):
	_init_slot = slot
	if _slot_select_is_new_game:
		if has_save(slot):
			# 有存档,弹出确认
			_show_save_confirm(slot)
		else:
			# 空存档,先选职业再开始
			_title_state = TitleState.CLASS_SELECT
			_show_class_select_for_new_game()
	else:
		# 继续游戏,直接加载
		_start_continue_game(slot)

func _on_confirm_new_game(slot: int):
	_init_slot = slot
	_title_state = TitleState.CLASS_SELECT
	_show_class_select_for_new_game()

func _show_class_select_for_new_game():
	# 创建新的标题面板(替换存档选择面板)
	var old_panel = get_node_or_null("TitlePanel")
	if old_panel:
		old_panel.queue_free()
	var bg = get_node_or_null("TitleBG")
	var ov = get_node_or_null("TitleOverlay")
	# 保留背景和遮罩
	var title_panel = Panel.new()
	title_panel.name = "TitlePanel"
	title_panel.position = Vector2(140, 20)
	title_panel.size = Vector2(1000, 680)
	title_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	title_panel.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(title_panel)

	# 调用通用的职业选择界面
	_show_class_select_ui(title_panel)

func _on_slot_back_pressed():
	_title_state = TitleState.MAIN_MENU
	var title_panel = get_node("TitlePanel")
	for child in title_panel.get_children():
		child.queue_free()
	_show_main_menu(title_panel)

func _start_new_game(slot: int, job_id: int = Job.WARRIOR):
	# 清空标题画面
	var title_bg = get_node_or_null("TitleBG")
	var title_ov = get_node_or_null("TitleOverlay")
	var title_pn = get_node_or_null("TitlePanel")
	if title_bg: title_bg.queue_free()
	if title_ov: title_ov.queue_free()
	if title_pn: title_pn.queue_free()

	# 清理旧游戏
	if particle_container:
		particle_container.queue_free()
	if audio_manager:
		audio_manager.queue_free()

	# 重新初始化
	particle_container = Node2D.new()
	particle_container.name = "ParticleContainer"
	add_child(particle_container)
	_setup_audio()

	# 重置游戏数据
	_reset_game_data()
	_setup_ui()
	_generate_map()
	_setup_walls()
	_setup_player_data(job_id)  # 使用选定的职业
	_setup_player()

	# 保存新存档
	save_game(slot)

	game_state = State.EXPLORE
	_update_minimap()
	audio_manager.play_bgm("explore")
	show_message("欢迎,%s!你的冒险开始了..." % player_data.get_job_name())

func _start_continue_game(slot: int):
	# 清空标题画面
	var title_bg = get_node_or_null("TitleBG")
	var title_ov = get_node_or_null("TitleOverlay")
	var title_pn = get_node_or_null("TitlePanel")
	if title_bg: title_bg.queue_free()
	if title_ov: title_ov.queue_free()
	if title_pn: title_pn.queue_free()

	if not load_game(slot):
		# 加载失败,回到标题
		get_tree().reload_current_scene()
		return

	# 清理旧游戏
	if particle_container:
		particle_container.queue_free()
	if audio_manager:
		audio_manager.queue_free()

	particle_container = Node2D.new()
	particle_container.name = "ParticleContainer"
	add_child(particle_container)
	_setup_audio()
	_setup_ui()
	_generate_map()
	_setup_walls()
	_setup_player()
	_update_minimap()

	game_state = State.EXPLORE
	audio_manager.play_bgm("explore")
	show_message("继续冒险... %s (第%d层)" % [player_data.get_job_name(), current_floor])

func _reset_game_data():
	"""重置游戏数据(新游戏时调用)"""
	achievement_stats = {
		"enemies_defeated": 0, "bosses_defeated": 0, "elite_enemies_defeated": 0,
		"max_floor_reached": 1, "total_gold_earned": 0, "total_gold_spent": 0,
		"perfect_victories": 0, "no_damage_floors": 0, "max_level_reached": 1,
		"quests_completed": 0,
		"warrior_boss_wins": 0, "mage_boss_wins": 0,
		"hunter_boss_wins": 0, "thief_boss_wins": 0,
		"priest_boss_wins": 0, "knight_boss_wins": 0,
		"bard_boss_wins": 0, "summoner_boss_wins": 0,
		"unique_jobs_boss_wins": 0
	}
	unlocked_achievements = []
	_floor_damage_taken = 0

func _show_how_to_play():
	var title_panel = get_node("TitlePanel")
	for child in title_panel.get_children():
		child.queue_free()

	# 标题
	var title_lbl = Label.new()
	title_lbl.position = Vector2(0, 10)
	title_lbl.size = Vector2(1000, 40)
	title_lbl.text = "📖 江湖秘籍"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", PALETTE.gold)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_panel.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.position = Vector2(0, 50)
	sub_lbl.size = Vector2(1000, 22)
	sub_lbl.text = "八方旅人 · 操作指南"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	sub_lbl.add_theme_font_size_override("font_size", 13)
	title_panel.add_child(sub_lbl)

	var sep = Label.new()
	sep.position = Vector2(0, 78)
	sep.size = Vector2(1000, 12)
	sep.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_color_override("font_color", Color(0.35, 0.3, 0.18))
	sep.add_theme_font_size_override("font_size", 11)
	title_panel.add_child(sep)

	# 说明内容(两栏布局)
	var content = [
		["【基础操作】", [
			"WASD ··· 移动角色",
			"F ······ 进入下一层(踩楼梯点)",
			"E ······ 打开商店",
			"I ······ 打开背包/道具",
			"Q ······ 任务日志",
			"K ······ 成就面板",
			"F2 ····· 存档/读档",
		]],
		["【战斗操作】", [
			"点击 ⚔️攻击 · 普通攻击",
			"点击 ✨技能 · 打开技能菜单",
			"点击 💚道具 · 使用背包道具",
			"点击 🛡️防御 · 减少50%%伤害+回蓝",
			"点击 🏃逃跑 · 尝试脱离战斗",
		]],
		["【游戏目标】", [
			"· 挑战8层地牢,击败各层Boss",
			"· 从草寇山贼到武当真人,逐层深入",
			"· 收集装备、强化道具、提升等级",
			"· 完成途中遭遇的任务与事件",
		]],
		["【职业系统】", [
			"战士:高血量,物理伤害",
			"法师:高魔攻,元素魔法",
			"猎人:高速度,陷阱狙击",
			"盗贼:高暴击,暗影刺杀",
			"牧师:治疗与辅助复活",
			"骑士:高防御,格挡反击",
			"吟游诗人:战斗乐章辅助",
			"召唤师:契约召唤兽助战",
		]],
	]

	var col_w = 440
	var col_start_x = [80, 540]
	var row_start_y = 98
	var row_h = 105

	for idx in range(content.size()):
		var col = idx % 2
		var row = idx / 2
		var cx = col_start_x[col]
		var cy = row_start_y + row * row_h

		# 小标题
		var heading = Label.new()
		heading.position = Vector2(cx, cy)
		heading.size = Vector2(col_w, 20)
		heading.text = content[idx][0]
		heading.add_theme_color_override("font_color", PALETTE.gold)
		heading.add_theme_font_size_override("font_size", 13)
		title_panel.add_child(heading)

		# 内容
		for j in range(content[idx][1].size()):
			var line_lbl = Label.new()
			line_lbl.position = Vector2(cx, cy + 22 + j * 18)
			line_lbl.size = Vector2(col_w, 18)
			line_lbl.text = content[idx][1][j]
			line_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
			line_lbl.add_theme_font_size_override("font_size", 12)
			title_panel.add_child(line_lbl)

	# 返回按钮
	var back_btn = _create_small_button("← 返回", Vector2(20, 630))
	back_btn.pressed.connect(_on_slot_back_pressed)
	title_panel.add_child(back_btn)

func _create_small_button(text: String, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(120, 36)
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	var nstyle = StyleBoxFlat.new()
	nstyle.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	nstyle.border_color = Color(0.4, 0.35, 0.3)
	nstyle.border_width_left = 1; nstyle.border_width_top = 1
	nstyle.border_width_right = 1; nstyle.border_width_bottom = 1
	nstyle.corner_radius_top_left = 4; nstyle.corner_radius_top_right = 4
	nstyle.corner_radius_bottom_right = 4; nstyle.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("normal", nstyle)
	var hstyle = StyleBoxFlat.new()
	hstyle.bg_color = Color(0.1, 0.08, 0.03, 0.95)
	hstyle.border_color = PALETTE.gold
	hstyle.border_width_left = 1; hstyle.border_width_top = 1
	hstyle.border_width_right = 1; hstyle.border_width_bottom = 1
	hstyle.corner_radius_top_left = 4; hstyle.corner_radius_top_right = 4
	hstyle.corner_radius_bottom_right = 4; hstyle.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("hover", hstyle)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	pstyle.border_color = PALETTE.gold
	pstyle.border_width_left = 1; pstyle.border_width_top = 1
	pstyle.border_width_right = 1; pstyle.border_width_bottom = 1
	pstyle.corner_radius_top_left = 4; pstyle.corner_radius_top_right = 4
	pstyle.corner_radius_bottom_right = 4; pstyle.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("pressed", pstyle)
	return btn

func _show_class_select():
	"""显示职业选择界面(从存档选择后调用)- 兼容旧调用"""
	var title_panel = get_node_or_null("TitlePanel")
	if not title_panel:
		return
	# 清空面板
	for child in title_panel.get_children():
		child.queue_free()
	_show_class_select_ui(title_panel)

func _show_class_select_ui(title_panel: Panel):
	"""填充职业选择界面到给定面板"""
	# 清空面板(确保干净)
	for child in title_panel.get_children():
		child.queue_free()

	# 标题
	var game_title = Label.new()
	game_title.position = Vector2(0, 15)
	game_title.size = Vector2(1000, 50)
	game_title.text = "⚔️ 八方旅人 ⚔️"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_color_override("font_color", PALETTE.gold)
	game_title.add_theme_font_size_override("font_size", 30)
	title_panel.add_child(game_title)

	var subtitle = Label.new()
	subtitle.position = Vector2(0, 60)
	subtitle.size = Vector2(1000, 25)
	subtitle.text = "选择你的职业"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
	subtitle.add_theme_font_size_override("font_size", 15)
	title_panel.add_child(subtitle)

	var sep = Label.new()
	sep.position = Vector2(0, 90)
	sep.size = Vector2(1000, 15)
	sep.text = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_color_override("font_color", Color(0.35, 0.3, 0.18))
	sep.add_theme_font_size_override("font_size", 11)
	title_panel.add_child(sep)

	# 职业数据
	var job_list: Array = [
		{"id": Job.WARRIOR, "name": "⚔️ 战士", "desc": "高血量 · 猛击/防御/冲锋", "color": Color(0.9, 0.3, 0.3)},
		{"id": Job.MAGE, "name": "🔮 法师", "desc": "高魔攻 · 火球/冰霜/闪电", "color": Color(0.3, 0.3, 1.0)},
		{"id": Job.HUNTER, "name": "🏹 猎人", "desc": "高速度 · 狙击/陷阱/毒箭", "color": Color(0.3, 0.8, 0.3)},
		{"id": Job.THIEF, "name": "🗡️ 盗贼", "desc": "高暴击 · 背刺/暗影/消失", "color": Color(0.6, 0.3, 0.8)},
		{"id": Job.PRIEST, "name": "💚 牧师", "desc": "治疗 · 治疗/护盾/复活", "color": Color(0.3, 0.9, 0.5)},
		{"id": Job.KNIGHT, "name": "🛡️ 骑士", "desc": "高防御 · 格挡/斩击/神圣", "color": Color(0.5, 0.7, 0.9)},
		{"id": Job.BARD, "name": "🎵 吟游诗人", "desc": "辅助 · 鼓舞/旋律/沉默", "color": Color(0.9, 0.6, 0.2)},
		{"id": Job.SUMMONER, "name": "🔥 召唤师", "desc": "召唤 · 召唤/契约/共鸣", "color": Color(1.0, 0.4, 0.2)},
	]

	# 职业按钮网格 (4×2)
	var start_x = 60
	var start_y = 120
	var btn_w = 210
	var btn_h = 110
	var cols = 4

	for i in range(job_list.size()):
		var job = job_list[i]
		var row = i / cols
		var col = i % cols
		var bx = start_x + col * (btn_w + 20)
		var by = start_y + row * (btn_h + 15)

		var job_btn = Button.new()
		job_btn.name = "JobBtn_%d" % job["id"]
		job_btn.position = Vector2(bx, by)
		job_btn.size = Vector2(btn_w, btn_h)
		job_btn.add_theme_font_size_override("font_size", 15)
		var jstyle = StyleBoxFlat.new()
		jstyle.bg_color = Color(0.06, 0.06, 0.1, 0.95)
		jstyle.border_color = job["color"]
		jstyle.border_width_left = 2; jstyle.border_width_top = 2
		jstyle.border_width_right = 2; jstyle.border_width_bottom = 2
		jstyle.corner_radius_top_left = 5; jstyle.corner_radius_top_right = 5
		jstyle.corner_radius_bottom_right = 5; jstyle.corner_radius_bottom_left = 5
		job_btn.add_theme_stylebox_override("normal", jstyle)
		var hstyle = StyleBoxFlat.new()
		hstyle.bg_color = Color(0.15, 0.12, 0.05, 0.95)
		hstyle.border_color = PALETTE.gold
		hstyle.border_width_left = 2; hstyle.border_width_top = 2
		hstyle.border_width_right = 2; hstyle.border_width_bottom = 2
		hstyle.corner_radius_top_left = 5; hstyle.corner_radius_top_right = 5
		hstyle.corner_radius_bottom_right = 5; hstyle.corner_radius_bottom_left = 5
		job_btn.add_theme_stylebox_override("hover", hstyle)
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.03, 0.03, 0.06, 0.95)
		pstyle.border_color = PALETTE.gold
		pstyle.border_width_left = 2; pstyle.border_width_top = 2
		pstyle.border_width_right = 2; pstyle.border_width_bottom = 2
		pstyle.corner_radius_top_left = 5; pstyle.corner_radius_top_right = 5
		pstyle.corner_radius_bottom_right = 5; pstyle.corner_radius_bottom_left = 5
		job_btn.add_theme_stylebox_override("pressed", pstyle)

		var jname = Label.new()
		jname.position = Vector2(10, 8)
		jname.text = job["name"]
		jname.add_theme_color_override("font_color", job["color"])
		jname.add_theme_font_size_override("font_size", 16)
		job_btn.add_child(jname)

		var jdesc = Label.new()
		jdesc.position = Vector2(10, 38)
		jdesc.text = job["desc"]
		jdesc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
		jdesc.add_theme_font_size_override("font_size", 12)
		job_btn.add_child(jdesc)

		var jhint = Label.new()
		jhint.position = Vector2(10, 75)
		jhint.text = "[ 点击选择 ]"
		jhint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		jhint.add_theme_font_size_override("font_size", 11)
		job_btn.add_child(jhint)

		job_btn.pressed.connect(_on_job_selected.bind(job["id"]))
		title_panel.add_child(job_btn)

	# 底部说明
	var tip = Label.new()
	tip.position = Vector2(0, 420)
	tip.size = Vector2(1000, 25)
	tip.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · 任务(Q) · 成就(K) · F2存档"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	tip.add_theme_font_size_override("font_size", 13)
	title_panel.add_child(tip)

func _on_job_selected(job_id: int):
	# 从职业选择界面启动新游戏(使用已选的存档槽)
	_start_new_game(_init_slot, job_id)

func _setup_player_data(job_id: int = Job.WARRIOR):
	player_data = _get_player_data().new()
	player_data.job = job_id
	player_data._setup_job_skills()

func _setup_ui():
	# 创建左上状态面板
	var ui_panel = Panel.new()
	ui_panel.position = Vector2(10, 10)
	ui_panel.size = Vector2(220, 140)
	ui_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.88)
	ui_panel.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(ui_panel)

	job_label = Label.new()
	job_label.position = Vector2(15, 12)
	job_label.text = "战士"
	job_label.add_theme_color_override("font_color", PALETTE.gold)
	job_label.add_theme_font_size_override("font_size", 14)
	ui_panel.add_child(job_label)

	hp_label = Label.new()
	hp_label.position = Vector2(15, 35)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	ui_panel.add_child(hp_label)

	mp_label = Label.new()
	mp_label.position = Vector2(15, 58)
	mp_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	ui_panel.add_child(mp_label)

	gold_label = Label.new()
	gold_label.position = Vector2(15, 81)
	gold_label.add_theme_color_override("font_color", PALETTE.gold)
	ui_panel.add_child(gold_label)

	# 消息标签
	message_label = Label.new()
	message_label.position = Vector2(10, 640)
	message_label.size = Vector2(1260, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(message_label)

	# 右上面板
	var ui_right = Panel.new()
	ui_right.position = Vector2(1070, 10)
	ui_right.size = Vector2(200, 60)
	ui_right.self_modulate = Color(0.04, 0.04, 0.08, 0.88)
	ui_right.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(ui_right)

	var title_label = Label.new()
	title_label.position = Vector2(20, 15)
	title_label.text = "第 1 层"
	title_label.add_theme_color_override("font_color", PALETTE.gold)
	ui_right.add_child(title_label)

	floor_label = Label.new()
	floor_label.position = Vector2(20, 38)
	floor_label.text = "探索中..."
	floor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	ui_right.add_child(floor_label)

	# 提示操作
	var hint_label = Label.new()
	hint_label.position = Vector2(1070, 80)
	hint_label.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · 任务(Q) · 成就(K) · F2存档"
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(hint_label)

	# 小地图面板 (右下角)
	_create_minimap()

	_update_ui()

func _create_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.88)
	style.border_color = PALETTE.gold
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style

func _create_elite_stylebox() -> StyleBoxFlat:
	# 精英敌人专用样式 - 金色发光边框
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.02, 0.92)
	style.border_color = Color(1.0, 0.85, 0.2)  # 更亮的金色
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style

func _setup_walls():
	# 创建简化墙壁碰撞区 (地图边缘)
	wall_rects = [
		Rect2(0, 0, 1280, 200),       # 顶部天空
		Rect2(0, 600, 1280, 120),     # 底部
		Rect2(0, 0, 50, 720),         # 左侧
		Rect2(1230, 0, 50, 720),      # 右侧
	]
	# 添加一些随机墙壁块
	for i in range(8):
		var wx = randi() % 50 + 10
		var wy = randi() % 15 + 18
		wall_rects.append(Rect2(wx * 16, wy * 16, 48, 48))

	# 添加商店招牌
	shop_sign_pos = Vector2(30 * 16, 22 * 16)
	var shop_sign = ColorRect.new()
	shop_sign.name = "ShopSign"
	shop_sign.size = Vector2(80, 64)
	shop_sign.position = shop_sign_pos
	shop_sign.color = Color(0.35, 0.25, 0.1, 1.0)
	add_child(shop_sign)

	var shop_label = Label.new()
	shop_label.name = "ShopLabel"
	shop_label.text = "商店 [E]"
	shop_label.position = shop_sign_pos + Vector2(8, 20)
	shop_label.add_theme_color_override("font_color", PALETTE.gold)
	add_child(shop_label)

func _setup_player():
	player = CharacterBody2D.new()
	player.position = Vector2(640, 400)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-16, -16)  # 居中偏移

	# 使用PNG素材(256x256缩小到32x32)
	var tex = _load_job_texture(player_data.job)
	if tex:
		sprite.texture = tex
		sprite.scale = Vector2(0.125, 0.125)  # 256/32 = 8, 所以缩小8倍
	else:
		# 回退到程序生成的32x32纹理
		sprite.texture = _create_job_texture(player_data.job)
		sprite.scale = Vector2(1, 1)
	player.add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	player.add_child(col)

	add_child(player)
	show_message("WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · 任务(Q) · 成就(K) · F2存档")


func _load_job_texture(job: int) -> Texture2D:
	# 映射职业到PNG文件
	var texture_path = {
		Job.WARRIOR: "res://assets/warrior.png",
		Job.MAGE: "res://assets/mage.png",
		Job.HUNTER: "res://assets/archer.png",
		Job.THIEF: "res://assets/ninja.png",
		Job.PRIEST: "res://assets/knight.png",  # 暂时用knight
		Job.KNIGHT: "res://assets/knight.png",
		Job.BARD: "res://assets/warrior.png",    # 暂时用warrior
		Job.SUMMONER: "res://assets/warrior.png"  # 暂时用warrior
	}

	var path = texture_path.get(job, "res://assets/warrior.png")
	var tex = load(path)
	if tex:
		return tex
	return null

func _create_knight_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cape = Color("#8b2942")
	var armor = Color("#4a6a8a")
	var skin = Color("#e8c8a0")
	var hair = Color("#3a2a1a")
	var sword = Color("#c0c0c0")
	var gold = Color("#c9a227")

	# Cape
	_set_pixel_line(img, 8, 18, 15, 18, cape)
	_set_pixel_line(img, 6, 22, 9, 22, cape)
	_set_pixel_line(img, 6, 24, 7, 24, cape)
	_set_pixel_line(img, 5, 26, 6, 26, cape)
	_set_pixel_line(img, 6, 28, 7, 28, cape)

	# Armor body
	_set_pixel_line(img, 9, 16, 22, 16, armor)
	_set_pixel_line(img, 8, 18, 23, 18, armor)
	_set_pixel_line(img, 8, 20, 23, 20, armor)
	_set_pixel_line(img, 8, 22, 23, 22, armor)
	_set_pixel_line(img, 9, 24, 22, 24, armor)
	_set_pixel_line(img, 10, 26, 21, 26, armor)

	# Head
	_set_pixel_line(img, 12, 4, 19, 4, hair)
	_set_pixel_line(img, 12, 6, 19, 6, hair)
	_set_pixel_line(img, 12, 8, 19, 8, skin)
	_set_pixel_line(img, 12, 10, 19, 10, skin)
	_set_pixel_line(img, 12, 12, 19, 12, skin)
	_set_pixel_line(img, 13, 14, 18, 14, skin)

	# Eyes
	img.set_pixel(14, 10, Color.BLACK)
	img.set_pixel(18, 10, Color.BLACK)

	# Sword
	_set_pixel_line(img, 24, 8, 24, 24, sword)
	_set_pixel_line(img, 22, 10, 22, 10, gold)
	_set_pixel_line(img, 26, 10, 26, 10, gold)
	_set_pixel_line(img, 22, 12, 26, 12, gold)

	var texture = ImageTexture.create_from_image(img)
	return texture

func _create_job_texture(job: int) -> ImageTexture:
	match job:
		Job.WARRIOR: return _create_knight_texture()
		Job.MAGE: return _create_mage_texture()
		Job.HUNTER: return _create_hunter_texture()
		Job.THIEF: return _create_thief_texture()
		Job.PRIEST: return _create_priest_texture()
		Job.KNIGHT: return _create_knight_texture()
		Job.BARD: return _create_bard_texture()
		Job.SUMMONER: return _create_summoner_texture()
	return _create_knight_texture()

func _create_mage_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var robe = Color("#3a2a6a")
	var skin = Color("#e8c8a0")
	var hair = Color("#8a6a2a")
	var staff = Color("#6a4a2a")
	var orb = Color("#4a9fff")
	# Robe
	_set_pixel_line(img, 10, 14, 22, 14, robe)
	_set_pixel_line(img, 9, 16, 23, 16, robe)
	_set_pixel_line(img, 9, 18, 23, 18, robe)
	_set_pixel_line(img, 9, 20, 23, 20, robe)
	_set_pixel_line(img, 9, 22, 23, 22, robe)
	_set_pixel_line(img, 10, 24, 22, 24, robe)
	_set_pixel_line(img, 11, 26, 21, 26, robe)
	_set_pixel_line(img, 12, 28, 20, 28, robe)
	# Head
	_set_pixel_line(img, 12, 4, 20, 4, hair)
	_set_pixel_line(img, 12, 6, 20, 6, hair)
	_set_pixel_line(img, 12, 8, 20, 8, skin)
	_set_pixel_line(img, 12, 10, 20, 10, skin)
	_set_pixel_line(img, 13, 12, 19, 12, skin)
	img.set_pixel(14, 10, Color.BLUE)
	img.set_pixel(18, 10, Color.BLUE)
	# Staff
	_set_pixel_line(img, 25, 4, 25, 28, staff)
	img.set_pixel(25, 3, orb)
	img.set_pixel(24, 4, orb)
	img.set_pixel(26, 4, orb)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_hunter_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cloak = Color("#4a6a2a")
	var leather = Color("#8a6a3a")
	var skin = Color("#e8c8a0")
	var bow = Color("#6a4a2a")
	# Cloak
	_set_pixel_line(img, 8, 16, 23, 16, cloak)
	_set_pixel_line(img, 7, 18, 24, 18, cloak)
	_set_pixel_line(img, 7, 20, 24, 20, cloak)
	_set_pixel_line(img, 7, 22, 24, 22, cloak)
	_set_pixel_line(img, 8, 24, 23, 24, cloak)
	_set_pixel_line(img, 9, 26, 22, 26, cloak)
	# Leather armor
	_set_pixel_line(img, 10, 14, 22, 14, leather)
	_set_pixel_line(img, 10, 16, 22, 16, leather)
	_set_pixel_line(img, 10, 18, 22, 18, leather)
	_set_pixel_line(img, 10, 20, 22, 20, leather)
	# Head
	_set_pixel_line(img, 12, 4, 20, 4, Color("#5a3a1a"))
	_set_pixel_line(img, 12, 6, 20, 6, Color("#5a3a1a"))
	_set_pixel_line(img, 13, 8, 19, 8, skin)
	_set_pixel_line(img, 13, 10, 19, 10, skin)
	img.set_pixel(14, 9, Color.BLACK)
	img.set_pixel(18, 9, Color.BLACK)
	# Bow
	_set_pixel_line(img, 26, 6, 26, 26, bow)
	_set_pixel_line(img, 24, 8, 24, 24, bow)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_thief_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark = Color("#2a2a3a")
	var cloak = Color("#3a3a5a")
	var skin = Color("#e8c8a0")
	var dagger = Color("#c0c0c0")
	# Dark cloak
	_set_pixel_line(img, 8, 16, 23, 16, dark)
	_set_pixel_line(img, 7, 18, 24, 18, dark)
	_set_pixel_line(img, 7, 20, 24, 20, dark)
	_set_pixel_line(img, 7, 22, 24, 22, dark)
	_set_pixel_line(img, 7, 24, 24, 24, dark)
	_set_pixel_line(img, 8, 26, 23, 26, dark)
	# Hood
	_set_pixel_line(img, 10, 4, 22, 4, dark)
	_set_pixel_line(img, 10, 6, 22, 6, dark)
	_set_pixel_line(img, 10, 8, 22, 8, dark)
	_set_pixel_line(img, 11, 10, 21, 10, skin)
	_set_pixel_line(img, 11, 12, 21, 12, skin)
	img.set_pixel(14, 10, Color.YELLOW)
	img.set_pixel(18, 10, Color.YELLOW)
	# Daggers
	_set_pixel_line(img, 26, 14, 26, 22, dagger)
	_set_pixel_line(img, 5, 14, 5, 22, dagger)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_priest_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var robe = Color("#e8e8f0")
	var accent = Color("#c9a227")
	var skin = Color("#e8c8a0")
	var staff = Color("#c0c0c0")
	var heal = Color("#80ff80")
	# White robe
	_set_pixel_line(img, 10, 14, 22, 14, robe)
	_set_pixel_line(img, 9, 16, 23, 16, robe)
	_set_pixel_line(img, 9, 18, 23, 18, robe)
	_set_pixel_line(img, 9, 20, 23, 20, robe)
	_set_pixel_line(img, 9, 22, 23, 22, robe)
	_set_pixel_line(img, 10, 24, 22, 24, robe)
	_set_pixel_line(img, 11, 26, 21, 26, robe)
	# Head w/ halo
	_set_pixel_line(img, 12, 4, 20, 4, accent)
	_set_pixel_line(img, 12, 6, 20, 6, Color("#f0e8c0"))
	_set_pixel_line(img, 13, 8, 19, 8, skin)
	_set_pixel_line(img, 13, 10, 19, 10, skin)
	img.set_pixel(15, 9, Color.BLACK)
	img.set_pixel(17, 9, Color.BLACK)
	# Staff
	_set_pixel_line(img, 25, 2, 25, 28, staff)
	img.set_pixel(25, 2, heal)
	img.set_pixel(24, 3, heal)
	img.set_pixel(26, 3, heal)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_bard_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var coat = Color("#8a4a2a")
	var shirt = Color("#c9a227")
	var skin = Color("#e8c8a0")
	var lute = Color("#6a3a1a")
	# Colorful coat
	_set_pixel_line(img, 9, 14, 23, 14, coat)
	_set_pixel_line(img, 8, 16, 24, 16, coat)
	_set_pixel_line(img, 8, 18, 24, 18, coat)
	_set_pixel_line(img, 8, 20, 24, 20, coat)
	_set_pixel_line(img, 8, 22, 24, 22, coat)
	_set_pixel_line(img, 9, 24, 23, 24, coat)
	_set_pixel_line(img, 10, 26, 22, 26, coat)
	# Shirt accent
	_set_pixel_line(img, 13, 16, 19, 16, shirt)
	_set_pixel_line(img, 13, 18, 19, 18, shirt)
	# Head
	_set_pixel_line(img, 12, 4, 20, 4, Color("#8a6a2a"))
	_set_pixel_line(img, 12, 6, 20, 6, Color("#8a6a2a"))
	_set_pixel_line(img, 13, 8, 19, 8, skin)
	_set_pixel_line(img, 13, 10, 19, 10, skin)
	img.set_pixel(14, 9, Color.BLACK)
	img.set_pixel(18, 9, Color.BLACK)
	# Lute
	_set_pixel_line(img, 26, 14, 26, 22, lute)
	img.set_pixel(27, 18, lute)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_summoner_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var robe = Color("#4a1a4a")
	var rune = Color("#ff4aff")
	var skin = Color("#e8c8a0")
	var staff = Color("#3a2a1a")
	var demon = Color("#ff4040")
	# Dark robe
	_set_pixel_line(img, 10, 14, 22, 14, robe)
	_set_pixel_line(img, 9, 16, 23, 16, robe)
	_set_pixel_line(img, 9, 18, 23, 18, robe)
	_set_pixel_line(img, 9, 20, 23, 20, robe)
	_set_pixel_line(img, 9, 22, 23, 22, robe)
	_set_pixel_line(img, 10, 24, 22, 24, robe)
	_set_pixel_line(img, 11, 26, 21, 26, robe)
	# Rune collar
	_set_pixel_line(img, 11, 14, 21, 14, rune)
	# Head
	_set_pixel_line(img, 12, 4, 20, 4, Color("#2a1a3a"))
	_set_pixel_line(img, 12, 6, 20, 6, Color("#2a1a3a"))
	_set_pixel_line(img, 13, 8, 19, 8, skin)
	_set_pixel_line(img, 13, 10, 19, 10, skin)
	img.set_pixel(14, 9, demon)
	img.set_pixel(18, 9, demon)
	# Staff w/ orb
	_set_pixel_line(img, 25, 4, 25, 28, staff)
	img.set_pixel(25, 3, rune)
	img.set_pixel(24, 4, rune)
	img.set_pixel(26, 4, rune)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _set_pixel_line(img: Image, x1: int, y: int, x2: int, y2: int, col: Color):
	for x in range(x1, x2 + 1):
		img.set_pixel(x, y, col)

var map_bg: ColorRect
var map_ground: ColorRect
var grass_pattern: Node2D  # 草地纹理节点

func _generate_map():
	# 清理旧地图资源(防止内存泄漏)
	if map_bg:
		map_bg.queue_free()
	if map_ground:
		map_ground.queue_free()
	if grass_pattern:
		grass_pattern.queue_free()

	# 背景(天空)
	map_bg = ColorRect.new()
	map_bg.size = SCREEN_SIZE
	map_bg.position = Vector2(0, 0)
	map_bg.color = PALETTE.sky_top
	add_child(map_bg)

	# 地面(草地)
	map_ground = ColorRect.new()
	map_ground.size = SCREEN_SIZE
	map_ground.position = Vector2(0, 0)
	map_ground.color = PALETTE.grass_1
	add_child(map_ground)

	# 草地纹理
	grass_pattern = _create_grass_pattern()
	grass_pattern.position = Vector2(0, 0)
	add_child(grass_pattern)

	# 迷雾(使用fog_container统一管理,一次queue_free即可释放所有子节点)
	_clear_fog()
	fog_container = Node2D.new()
	fog_container.name = "FogContainer"
	add_child(fog_container)
	for x in range(0, 80):
		for y in range(0, 45):
			var fog = ColorRect.new()
			fog.size = Vector2(16, 16)
			fog.position = Vector2(x * 16, y * 16)
			fog.color = Color(0.02, 0.02, 0.04, 0.95)
			fog.name = "fog_%d_%d" % [x, y]
			fog_container.add_child(fog)
			fog_map[str(x) + "_" + str(y)] = fog

	_reveal_area(40, 25, 8)  # 初始可见范围调大


func _create_grass_pattern() -> Node2D:
	var container = Node2D.new()

	# 创建草地纹理(16x16像素砖块排列)
	for tx in range(0, 80):
		for ty in range(0, 45):
			var tile = ColorRect.new()
			tile.size = Vector2(16, 16)
			tile.position = Vector2(tx * 16, ty * 16)
			# 交替草色增加变化
			if (tx + ty) % 3 == 0:
				tile.color = PALETTE.grass_2
			else:
				tile.color = PALETTE.grass_1
			container.add_child(tile)

	return container


func _clear_fog():
	# 使用fog_container统一释放,一次queue_free即可释放所有子节点
	if fog_container and is_instance_valid(fog_container):
		fog_container.queue_free()
	fog_container = null
	fog_map.clear()


var player_tile_x: int = 40
var player_tile_y: int = 25

func _reveal_area(cx: int, cy: int, radius: int):
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			if x >= 0 and x < 80 and y >= 0 and y < 45:
				var dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
				if dist <= radius:
					var key = str(x) + "_" + str(y)
					if fog_map.has(key):
						var fog = fog_map[key]
						# 完全透明在中心,边缘渐变到50%不透明度
						var alpha = max(0.0, 0.5 - (dist / radius) * 0.5)
						fog.color = Color(0.02, 0.02, 0.04, alpha)

func _process(delta):
	_update_camera_shake(delta)
	if game_state == State.EXPLORE:
		_process_explore(delta)
	elif game_state == State.BATTLE:
		_process_battle(delta)
	elif game_state == State.SHOP:
		_process_shop(delta)

func _process_explore(delta):
	var speed = 180 * delta
	var moved = false
	var vx = 0.0
	var vy = 0.0

	if Input.is_action_pressed("ui_up"):
		vy -= speed; moved = true
	elif Input.is_action_pressed("ui_down"):
		vy += speed; moved = true
	elif Input.is_action_pressed("ui_left"):
		vx -= speed; moved = true
	elif Input.is_action_pressed("ui_right"):
		vx += speed; moved = true

	# 尝试移动
	var new_pos = player.position + Vector2(vx, vy)
	new_pos.x = clamp(new_pos.x, 24, 1256)
	new_pos.y = clamp(new_pos.y, 210, 690)

	# 墙壁碰撞检测
	var collided = false
	for rect in wall_rects:
		if rect.has_point(new_pos):
			collided = true
			break

	if not collided:
		player.position = new_pos

	if moved and collided and is_player_turn:
		_start_battle()
		return

	# 持续按住时随机触发战斗
	if moved and randf() < RANDOM_ENCOUNTER_RATE and is_player_turn:
		_start_battle()
		return

	# 更新迷雾
	var new_tile_x = int(player.position.x / 16)
	var new_tile_y = int(player.position.y / 16)
	if new_tile_x != player_tile_x or new_tile_y != player_tile_y:
		player_tile_x = new_tile_x
		player_tile_y = new_tile_y
		_reveal_area(player_tile_x, player_tile_y, 4)

	# 按F下楼梯
	if Input.is_action_pressed("ui_accept") and is_player_turn:
		_next_floor()

	# 商店检测 (E键)
	var dist_to_shop = player.position.distance_to(shop_sign_pos + Vector2(40, 32))
	shop_nearby = dist_to_shop < 80
	if shop_nearby and Input.is_action_pressed("ui_select") and is_player_turn:
		_open_shop()

	# 背包检测 (I键)
	if Input.is_key_pressed(KEY_I) and is_player_turn and not inventory_open and game_state == State.EXPLORE:
		_open_inventory()
		return

	# 关闭背包 (I键或ESC)
	if inventory_open and (Input.is_key_pressed(KEY_I) or Input.is_key_pressed(KEY_ESCAPE)):
		_close_inventory()
		return

	# 任务日志 (Q键)
	if Input.is_key_pressed(KEY_Q) and is_player_turn and not quest_log_open and game_state == State.EXPLORE:
		_open_quest_log()
		return

	# 关闭任务日志 (Q键或ESC)
	if quest_log_open and (Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_ESCAPE)):
		_close_quest_log()
		return

	# 成就日志 (K键)
	if Input.is_key_pressed(KEY_K) and is_player_turn and not achievement_log_open and game_state == State.EXPLORE:
		_open_achievement_log()
		return

	# 关闭成就日志 (K键或ESC)
	if achievement_log_open and (Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_ESCAPE)):
		_close_achievement_log()
		return

	_update_ui()
	_update_minimap()

	# F2 存档/读档快捷键
	if Input.is_key_pressed(KEY_F2) and is_player_turn and game_state == State.EXPLORE:
		_open_save_ui()

func _next_floor():
	if current_floor >= 8:
		show_message("这是最后一层!")
		return
	if is_transitioning:
		return

	is_transitioning = true
	is_player_turn = false

	# 淡出
	_show_transition_overlay()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.5)

	await tween.finished
	await get_tree().create_timer(0.3).timeout

	# 执行楼层切换
	current_floor += 1
	player.position = Vector2(640, 400)
	_check_quest_objectives("explore_floor", {"floor": current_floor})

	# 成就追踪:探索新层
	if current_floor > achievement_stats["max_floor_reached"]:
		achievement_stats["max_floor_reached"] = current_floor

		# 检查无伤通关成就(从上一层切换时检测)
		if _floor_damage_taken == 0 and current_floor > 1:
			achievement_stats["no_damage_floors"] += 1

		# 重置本层受伤计数
		_floor_damage_taken = 0
	_check_achievements()
	player_tile_x = 40
	player_tile_y = 25
	for key in fog_map:
		var fog = fog_map[key]
		fog.color = Color(0.02, 0.02, 0.04, 0.95)
	_reveal_area(player_tile_x, player_tile_y, 5)
	_update_minimap()

	# 检查是否是Boss层
	var boss_key = _get_boss_floor_key()
	if boss_key > 0:
		# 显示Boss名字公告
		_show_floor_announcement("第 %d 层" % current_floor)
		# 更新floor_label
		floor_label.text = "第 %d 层 · BOSS!" % current_floor
	else:
		_show_floor_announcement("第 %d 层" % current_floor)
		floor_label.text = "第 %d 层" % current_floor

	# 淡入
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.5)
	await tween.finished

	_hide_transition_overlay()
	is_transitioning = false
	is_player_turn = true

	# 如果是Boss层,短暂提示后开始Boss战
	if boss_key > 0:
		await get_tree().create_timer(1.5).timeout
		_start_boss_encounter()

func _get_boss_floor_key() -> int:
	# 检查是否是Boss层
	if BOSS_DATA.has(current_floor):
		return current_floor
	return 0

func _show_transition_overlay():
	if transition_overlay == null:
		transition_overlay = ColorRect.new()
		transition_overlay.name = "TransitionOverlay"
		transition_overlay.size = SCREEN_SIZE
		transition_overlay.position = Vector2(0, 0)
		transition_overlay.color = Color(0, 0, 0, 0.0)
		add_child(transition_overlay)
	transition_overlay.visible = true

func _hide_transition_overlay():
	if transition_overlay:
		transition_overlay.visible = false

func _show_floor_announcement(text: String):
	# 创建楼层公告
	var announce = Label.new()
	announce.name = "FloorAnnounce"
	announce.text = text
	announce.position = Vector2(0, 300)
	announce.size = Vector2(1280, 80)
	announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announce.add_theme_color_override("font_color", PALETTE.gold)
	announce.add_theme_font_size_override("font_size", 48)
	announce.modulate = Color(1, 1, 1, 0)
	add_child(announce)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(announce, "modulate:a", 1.0, 0.3)
	tween.tween_property(announce, "scale", Vector2(1.1, 1.1), 0.3)
	await get_tree().create_timer(1.2).timeout
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(announce, "modulate:a", 0.0, 0.4)
	tween.tween_property(announce, "scale", Vector2(1.2, 1.2), 0.4)
	await tween.finished
	announce.queue_free()

func _start_boss_encounter():
	if not BOSS_DATA.has(current_floor):
		return

	var boss_def = BOSS_DATA[current_floor]
	var mult = 1.0 + current_floor * 0.12

	current_boss_data = {
		"name": boss_def["name"],
		"id": boss_def.get("id", boss_def["name"]),  # 任务追踪用
		"type": boss_def.get("id", boss_def["name"]),
		"hp": int(boss_def["hp"] * mult),
		"max_hp": int(boss_def["hp"] * mult),
		"atk": int(boss_def["atk"] * mult),
		"def": int(boss_def["def"] * mult),
		"spd": boss_def["spd"],
		"exp": boss_def["exp"],
		"gold": boss_def["gold"],
		"color": boss_def["color"],
		"faction": "Boss",
		"phase_hp": boss_def.get("phase_hp", 0.0),
		"phase2_hp": boss_def.get("phase2_hp", 0.0),
		"description": boss_def["description"]
	}
	boss_phase = 1
	boss_enraged = false
	boss_shield_stacks = 0
	boss_revived = false

	# 显示Boss登场画面
	_show_boss_intro(boss_def)

func _show_boss_intro(boss_def: Dictionary):
	# 暗色遮罩
	var overlay = ColorRect.new()
	overlay.name = "BossIntroOverlay"
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.95)
	overlay.position = Vector2(0, 0)
	overlay.modulate = Color(1, 1, 1, 0)
	add_child(overlay)

	# Boss名称面板
	var panel = Panel.new()
	panel.name = "BossIntroPanel"
	panel.position = Vector2(290, 200)
	panel.size = Vector2(700, 320)
	panel.self_modulate = Color(0.03, 0.03, 0.06, 0.98)
	panel.add_theme_stylebox_override("panel", _create_stylebox())
	panel.modulate = Color(1, 1, 1, 0)
	add_child(panel)

	# Boss标题
	var title = Label.new()
	title.name = "BossTitle"
	title.position = Vector2(0, 20)
	title.size = Vector2(700, 50)
	title.text = "⚠️ BOSS出现! ⚠️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 32)
	panel.add_child(title)

	# Boss名称
	var boss_name = Label.new()
	boss_name.name = "BossName"
	boss_name.position = Vector2(0, 80)
	boss_name.size = Vector2(700, 50)
	boss_name.text = boss_def["name"]
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_color_override("font_color", PALETTE.gold)
	boss_name.add_theme_font_size_override("font_size", 40)
	panel.add_child(boss_name)

	# 分割线
	var sep = ColorRect.new()
	sep.position = Vector2(100, 135)
	sep.size = Vector2(500, 2)
	sep.color = PALETTE.gold * Color(0.5, 0.5, 0.5, 0.5)
	panel.add_child(sep)

	# 描述
	var desc = Label.new()
	desc.name = "BossDesc"
	desc.position = Vector2(50, 150)
	desc.size = Vector2(600, 80)
	desc.text = boss_def["description"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.add_theme_font_size_override("font_size", 16)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(desc)

	# 技能列表
	var skills_text = "技能: " + ", ".join(boss_def["skills"])
	var skills_lbl = Label.new()
	skills_lbl.name = "BossSkills"
	skills_lbl.position = Vector2(50, 230)
	skills_lbl.size = Vector2(600, 40)
	skills_lbl.text = skills_text
	skills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	skills_lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(skills_lbl)

	# 警告
	var warn = Label.new()
	warn.name = "BossWarn"
	warn.position = Vector2(0, 270)
	warn.size = Vector2(700, 40)
	warn.text = ">>> 准备战斗! <<<"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	warn.add_theme_font_size_override("font_size", 24)
	panel.add_child(warn)

	# 动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.5).timeout

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.6)
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.6)
	await get_tree().create_timer(2.5).timeout

	# 淡出并清理
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	overlay.queue_free()
	panel.queue_free()

	# 开始Boss战斗
	_start_boss_battle()

func _update_ui():
	job_label.text = player_data.get_job_name()
	hp_label.text = "HP: %d/%d" % [player_data.hp, player_data.max_hp]
	mp_label.text = "MP: %d/%d" % [player_data.mp, player_data.max_mp]
	gold_label.text = "💰 %d" % player_data.gold
	floor_label.text = "第 %d 层 · 探索中" % current_floor

# ==================== 背包系统 ====================

func _open_inventory():
	if inventory_open:
		return
	inventory_open = true
	if minimap_container:
		minimap_container.visible = false
	_create_inventory_ui()
	show_message("背包 (按 I 或 ESC 关闭)")

func _close_inventory():
	if inventory_ui != null:
		inventory_ui.queue_free()
		inventory_ui = null
	for btn in inventory_item_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	inventory_item_buttons.clear()
	inventory_open = false
	if minimap_container:
		minimap_container.visible = true
	show_message("")

func _create_inventory_ui():
	if inventory_ui != null:
		inventory_ui.queue_free()
	inventory_item_buttons.clear()

	inventory_ui = Control.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(inventory_ui)

	# 背景遮罩
	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.position = Vector2(0, 0)
	overlay.gui_input.connect(_on_inventory_overlay_click)
	inventory_ui.add_child(overlay)

	# 背包面板
	var inv_panel = Panel.new()
	inv_panel.name = "InventoryPanel"
	inv_panel.position = Vector2(340, 80)
	inv_panel.size = Vector2(600, 560)
	inv_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	inv_panel.add_theme_stylebox_override("panel", _create_stylebox())
	inventory_ui.add_child(inv_panel)

	# 标题
	var title = Label.new()
	title.position = Vector2(20, 15)
	title.text = "🎒 背包"
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 20)
	inv_panel.add_child(title)

	# 金币显示
	var gold_disp = Label.new()
	gold_disp.name = "InvGold"
	gold_disp.position = Vector2(400, 15)
	gold_disp.text = "💰 %d 金币" % player_data.gold
	gold_disp.add_theme_color_override("font_color", PALETTE.gold)
	inv_panel.add_child(gold_disp)

	# 物品数量显示
	var count_lbl = Label.new()
	count_lbl.name = "ItemCount"
	count_lbl.position = Vector2(20, 50)
	count_lbl.text = "物品数: %d" % player_data.inventory.size()
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	inv_panel.add_child(count_lbl)

	# 物品列表区域
	var item_area = Panel.new()
	item_area.name = "ItemArea"
	item_area.position = Vector2(20, 85)
	item_area.size = Vector2(560, 320)
	item_area.self_modulate = Color(0, 0, 0, 0.3)
	item_area.add_theme_stylebox_override("panel", _create_stylebox())
	inv_panel.add_child(item_area)

	# 绘制物品列表
	_draw_inventory_items(item_area)

	# 关闭按钮
	var close_btn = _create_action_button("❌ 关闭 (I)", Vector2(220, 460))
	close_btn.pressed.connect(_close_inventory)
	close_btn.size = Vector2(160, 55)
	inv_panel.add_child(close_btn)

	# 角色装备信息(底部)
	var equip_panel = Panel.new()
	equip_panel.name = "EquipPanel"
	equip_panel.position = Vector2(20, 420)
	equip_panel.size = Vector2(560, 100)
	equip_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	equip_panel.add_theme_stylebox_override("panel", _create_stylebox())
	inv_panel.add_child(equip_panel)

	var eq_title = Label.new()
	eq_title.position = Vector2(15, 10)
	eq_title.text = "当前装备"
	eq_title.add_theme_color_override("font_color", PALETTE.gold)
	equip_panel.add_child(eq_title)

	var wpn = player_data.weapon
	var arm = player_data.armor
	var acc = player_data.accessory

	var wpn_text = "⚔️ " + (wpn.get("name", "无") if wpn.size() > 0 else "无")
	var arm_text = "🛡️ " + (arm.get("name", "无") if arm.size() > 0 else "无")
	var acc_text = "💍 " + (acc.get("name", "无") if acc.size() > 0 else "无")

	var wpn_lbl = Label.new()
	wpn_lbl.position = Vector2(15, 38)
	wpn_lbl.text = wpn_text
	wpn_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(wpn_lbl)

	var arm_lbl = Label.new()
	arm_lbl.position = Vector2(220, 38)
	arm_lbl.text = arm_text
	arm_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(arm_lbl)

	var acc_lbl = Label.new()
	acc_lbl.position = Vector2(420, 38)
	acc_lbl.text = acc_text
	acc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(acc_lbl)

	# 属性显示
	var stat_lbl = Label.new()
	stat_lbl.position = Vector2(15, 65)
	stat_lbl.text = "ATK: %d  |  DEF: %d  |  SPD: %d  |  LUK: %d" % [
		player_data.attack_power(), player_data.defense(),
		player_data.spd + player_data.accessory.get("spd", 0),
		player_data.luk + player_data.accessory.get("luk", 0)
	]
	stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	equip_panel.add_child(stat_lbl)

func _on_inventory_overlay_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_inventory()

func _draw_inventory_items(item_area: Panel):
	for btn in inventory_item_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	inventory_item_buttons.clear()

	if player_data.inventory.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.name = "EmptyLabel"
		empty_lbl.text = "背包是空的"
		empty_lbl.position = Vector2(200, 140)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty_lbl.add_theme_font_size_override("font_size", 16)
		item_area.add_child(empty_lbl)
		inventory_item_buttons.append(empty_lbl)
		return

	var start_x = 15
	var start_y = 15
	var cols = 3
	var idx = 0

	for inv_item in player_data.inventory:
		var row = idx / cols
		var col = idx % cols
		var bx = start_x + col * 175
		var by = start_y + row * 85
		var btn = _create_inventory_item_button(inv_item, Vector2(bx, by))
		item_area.add_child(btn)
		inventory_item_buttons.append(btn)
		idx += 1

func _create_inventory_item_button(inv_item: Dictionary, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(170, 78)

	var item_name = inv_item.get("type", "???")
	var count = inv_item.get("count", 1)
	var heal_hp = inv_item.get("heal_hp", 0)
	var heal_mp = inv_item.get("heal_mp", 0)

	var icon = "❤️"
	if heal_mp > 0:
		icon = "💙"

	var desc_text = ""
	if heal_hp > 0:
		desc_text = "恢复 %d%% HP" % heal_hp
	elif heal_mp > 0:
		desc_text = "恢复 %d%% MP" % heal_mp
	else:
		desc_text = "稀有物品"

	var can_use = (heal_hp > 0 or heal_mp > 0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = PALETTE.gold if can_use else Color(0.3, 0.3, 0.3)
	style.border_width_left = 1; style.border_width_top = 1
	style.border_width_right = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3; style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75) if can_use else Color(0.4, 0.4, 0.4))

	# 物品图标和名称
	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(10, 8)
	icon_lbl.text = icon + " " + item_name
	icon_lbl.add_theme_color_override("font_color", PALETTE.gold if can_use else Color(0.4, 0.4, 0.4))
	icon_lbl.add_theme_font_size_override("font_size", 14)
	btn.add_child(icon_lbl)

	# 数量
	var count_lbl = Label.new()
	count_lbl.position = Vector2(10, 32)
	count_lbl.text = "× %d" % count
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	count_lbl.add_theme_font_size_override("font_size", 13)
	btn.add_child(count_lbl)

	# 描述
	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(10, 52)
	desc_lbl.text = desc_text
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if can_use else Color(0.4, 0.4, 0.4))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	btn.add_child(desc_lbl)

	if can_use:
		btn.pressed.connect(_on_inventory_item_used.bind(inv_item))

	return btn

func _on_inventory_item_used(inv_item: Dictionary):
	var heal_hp = inv_item.get("heal_hp", 0)
	var heal_mp = inv_item.get("heal_mp", 0)

	# 检查是否能使用
	var used = false

	if heal_hp > 0 and player_data.hp < player_data.max_hp:
		player_data.hp = min(player_data.max_hp, player_data.hp + int(player_data.max_hp * heal_hp / 100.0))
		used = true
	if heal_mp > 0 and player_data.mp < player_data.max_mp:
		player_data.mp = min(player_data.max_mp, player_data.mp + int(player_data.max_mp * heal_mp / 100.0))
		used = true

	if used:
		# 减少数量
		var item_name = inv_item.get("type", "???")
		var item_idx = -1
		for i in range(player_data.inventory.size()):
			if player_data.inventory[i].get("type") == item_name:
				item_idx = i
				break

		if item_idx >= 0:
			player_data.inventory[item_idx]["count"] -= 1
			if player_data.inventory[item_idx]["count"] <= 0:
				player_data.inventory.remove_at(item_idx)

		show_message("使用了 %s!" % item_name)
		_update_ui()

		# 刷新背包UI
		var inv_panel = inventory_ui.get_node_or_null("InventoryPanel")
		if inv_panel:
			var item_area = inv_panel.get_node_or_null("ItemArea")
			if item_area:
				_draw_inventory_items(item_area)
			var gold_disp = inv_panel.get_node_or_null("InvGold")
			if gold_disp:
				gold_disp.text = "💰 %d 金币" % player_data.gold
			var count_lbl = inv_panel.get_node_or_null("ItemCount")
			if count_lbl:
				count_lbl.text = "物品数: %d" % player_data.inventory.size()
	else:
		show_message("状态已满,无法使用!")

# ==================== 小地图系统 ====================

# 小地图尺寸 (80x45 地图,缩小显示)
const MINIMAP_COLS: int = 80
const MINIMAP_ROWS: int = 45
const MINIMAP_CELL: int = 2  # 每个小地图格子的像素大小

# 素材纹理尺寸常量
const ASSET_TEX_SIZE: float = 2048.0  # 敌人/商店等素材纹理尺寸
const ENEMY_SPRITE_DISPLAY_SIZE: float = 200.0  # 敌人精灵显示尺寸

# 屏幕/场景尺寸常量
const SCREEN_SIZE: Vector2 = Vector2(1280, 720)

# 探索与战斗概率常量
const RANDOM_ENCOUNTER_RATE: float = 0.003  # 探索随机遇敌率
const VANISH_EVASION_CHANCE: float = 0.5   # 消失/猎豹闪避成功率
const FLEE_SUCCESS_CHANCE: float = 0.6      # 逃跑成功率

# Boss技能伤害倍率常量
const BOSS_SKILL_MULT_HIGH: float = 2.0   # 高伤害倍率
const BOSS_SKILL_MULT_MED: float = 1.5    # 中等伤害倍率
const BOSS_SKILL_MULT_LOW: float = 0.8     # 低伤害倍率
const BOSS_SKILL_MULT_XLOW: float = 0.7   # 极低伤害倍率
const BOSS_SKILL_MULT_MED2: float = 1.2   # 中等伤害倍率(v2)
const BOSS_SKILL_MULT_1D3: float = 1.3   # 1.3倍
const BOSS_SKILL_MULT_2D5: float = 2.5   # 2.5倍
const BOSS_SKILL_MULT_2D8: float = 2.8   # 2.8倍
const BOSS_SKILL_MULT_3D0: float = 3.0   # 3.0倍
const BOSS_SKILL_MULT_1D8: float = 1.8   # 1.8倍
const BOSS_SKILL_MULT_0D6: float = 0.6   # 0.6倍

# 精英敌人参数
const ELITE_SPAWN_CHANCE: float = 0.15      # 精英生成概率
const ELITE_HP_MULT: float = 1.5            # 精英HP倍率
const ELITE_ATK_MULT: float = 1.3           # 精英ATK倍率
const ELITE_DEF_MULT: float = 1.2           # 精英DEF倍率
const ELITE_EXP_MULT: float = 1.5           # 精英EXP倍率
const ELITE_GOLD_MULT: float = 1.5          # 精英GOLD倍率
const ELITE_FLOOR_MAX: int = 7              # BOSS层(7+)不出精英

# 伤害方差辅助函数 (避免硬编码散落)
## base_dmg ±2 波动 (用于敌人普攻/连锁闪电第2段)
func _roll_dmg_var_small(base_dmg: int) -> int:
	return base_dmg + randi() % 5 - 2

## base_dmg ±3 波动 (用于大多数技能)
func _roll_dmg_var_medium(base_dmg: int) -> int:
	return base_dmg + randi() % 7 - 3

## base_dmg ±5 波动 (用于重型技能)
func _roll_dmg_var_large(base_dmg: int) -> int:
	return base_dmg + randi() % 11 - 5

## base_dmg ±1 波动 (用于Boss技能)
func _roll_dmg_var_tiny(base_dmg: int) -> int:
	return base_dmg + randi() % 3 - 1

func _create_minimap():
	minimap_container = Control.new()
	minimap_container.name = "MinimapContainer"
	minimap_container.position = Vector2(1060, 575)
	minimap_container.size = Vector2(MINIMAP_COLS * MINIMAP_CELL + 20, MINIMAP_ROWS * MINIMAP_CELL + 35)
	minimap_container.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	minimap_container.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(minimap_container)

	# 小地图标题
	var mm_title = Label.new()
	mm_title.name = "MinimapTitle"
	mm_title.position = Vector2(8, 6)
	mm_title.text = "🗺️ 小地图"
	mm_title.add_theme_color_override("font_color", PALETTE.gold)
	mm_title.add_theme_font_size_override("font_size", 11)
	minimap_container.add_child(mm_title)

	# 小地图格子区域
	var mm_grid = Control.new()
	mm_grid.name = "MinimapGrid"
	mm_grid.position = Vector2(8, 26)
	mm_grid.size = Vector2(MINIMAP_COLS * MINIMAP_CELL, MINIMAP_ROWS * MINIMAP_CELL)
	mm_grid.set_anchors_preset(Control.PRESET_TOP_LEFT)
	minimap_container.add_child(mm_grid)

	# 预创建所有小地图格子 (2x2像素 each = 160x90 display)
	minimap_tiles.clear()
	for y in range(MINIMAP_ROWS):
		minimap_tiles.append([])
		for x in range(MINIMAP_COLS):
			var cell = ColorRect.new()
			cell.name = "mc_%d_%d" % [x, y]
			cell.size = Vector2(MINIMAP_CELL, MINIMAP_CELL)
			cell.position = Vector2(x * MINIMAP_CELL, y * MINIMAP_CELL)
			cell.color = Color(0.02, 0.02, 0.04, 0.95)  # 初始全黑(未探索)
			mm_grid.add_child(cell)
			minimap_tiles[y].append(cell)

func _update_minimap():
	if minimap_tiles.size() == 0:
		return

	# 临时存储玩家和商店位置
	var player_mx: int = -1
	var player_my: int = -1
	var shop_mx: int = -1
	var shop_my: int = -1

	# 商店位置 (tile坐标30,22)
	shop_mx = 30 * MINIMAP_CELL
	shop_my = 22 * MINIMAP_CELL

	# 玩家位置
	var px = int(player.position.x / 16)
	var py = int((player.position.y - 200) / 16)  # 偏移200是地面起始y
	px = clamp(px, 0, MINIMAP_COLS - 1)
	py = clamp(py, 0, MINIMAP_ROWS - 1)
	player_mx = px * MINIMAP_CELL
	player_my = py * MINIMAP_CELL

	# 更新每个格子
	for y in range(MINIMAP_ROWS):
		for x in range(MINIMAP_COLS):
			var key = str(x) + "_" + str(y)
			var cell = minimap_tiles[y][x]

			# 检查是否探索过 (fog alpha < 0.5 表示已探索)
			var explored = false
			if fog_map.has(key):
				var fog = fog_map[key]
				if fog.color.a < 0.5:
					explored = true

			# 判断是否是玩家或商店位置
			var is_player = (x * MINIMAP_CELL == player_mx and y * MINIMAP_CELL == player_my)
			var is_shop = (x * MINIMAP_CELL == shop_mx and y * MINIMAP_CELL == shop_my)

			if is_player:
				cell.color = PALETTE.gold  # 玩家: 金色
			elif is_shop:
				cell.color = Color(1.0, 0.6, 0.1, 1.0)  # 商店: 琥珀色
			elif explored:
				# 已探索区域: 草绿色
				cell.color = PALETTE.grass_1
			else:
				# 未探索: 深黑色
				cell.color = Color(0.02, 0.02, 0.04, 0.95)

# ==================== 任务进度检测 ====================

func _check_quest_objectives(event_type: String, event_data: Dictionary):
	"""检测并更新任务目标完成状态"""
	var quests = player_data.quest_log
	var updated = false

	for quest in quests:
		if quest.get("completed", false) or not quest.get("active", true):
			continue

		var objectives = quest.get("objectives", [])
		for obj in objectives:
			if obj.get("completed", false):
				continue

			var obj_type = obj.get("type", "")
			var obj_target = obj.get("target", "")
			var obj_done = false

			match obj_type:
				"defeat_enemy":
					# 击败特定敌人或敌人类型
					if event_type == "defeat_enemy":
						var enemy_id = event_data.get("enemy_id", "")
						var enemy_name = event_data.get("enemy_name", "")
						var enemy_type = event_data.get("enemy_type", "")
						if obj_target == enemy_id or obj_target == enemy_type or obj_target == enemy_name or obj_target == "any":
							# 检查是否需要计数
							if obj.has("required") and obj.get("required", 1) > 1:
								obj["count"] = obj.get("count", 0) + 1
								obj_done = obj["count"] >= obj.get("required", 1)
							else:
								obj_done = true

				"defeat_boss":
					if event_type == "defeat_enemy" and event_data.get("is_boss", false):
						if obj_target == event_data.get("enemy_id", "") or obj_target == "any":
							obj_done = true

				"goto":
					# 前往特定场景/位置(目前通过探索触发)
					if event_type == "goto" and obj_target == event_data.get("target", ""):
						obj_done = true

				"interact":
					# 与NPC对话
					if event_type == "interact" and obj_target == event_data.get("npc_id", ""):
						obj_done = true

				"accept_quest":
					# 接受任务目标
					if event_type == "accept_quest" and obj_target == event_data.get("quest_id", ""):
						obj_done = true

				"explore_floor":
					# 探索特定层数
					if event_type == "explore_floor":
						var target_floor = int(obj_target) if obj_target.is_valid_int() else -1
						if target_floor > 0 and event_data.get("floor", 0) >= target_floor:
							obj_done = true

				"collect_item":
					# 收集物品
					if event_type == "collect_item" and obj_target == event_data.get("item_type", ""):
						obj_done = true

			if obj_done:
				obj["completed"] = true
			updated = true

		# 检查是否所有目标都完成
		if updated:
			var all_done = true
			for obj in objectives:
				if not obj.get("completed", false):
					all_done = false
					break
			if all_done:
				quest["completed"] = true
				var quest_title = quest.get("title", "未知任务")
				show_message("📜 任务完成: %s" % quest_title)

	# 如果有已完成的自动接受任务,触发它们
	if updated:
		_trigger_accepted_quests()

func _trigger_accepted_quests():
	"""检查并自动接受任务链中的下一步任务"""
	# 查找所有已完成但未领取奖励的任务
	var quests = player_data.quest_log
	for quest in quests:
		if quest.get("completed", false) and not quest.get("reward_claimed", false):
			# 发放奖励
			var rewards = quest.get("rewards", {})
			if rewards.get("exp", 0) > 0:
				player_data.exp += rewards["exp"]
			if rewards.get("gold", 0) > 0:
				player_data.gold += rewards["gold"]
			# 标记奖励已领取
			quest["reward_claimed"] = true
			# 更新成就统计
			achievement_stats["quests_completed"] += 1
			_check_achievements()

# ==================== 成就系统 ====================

func _check_achievements():
	"""检查所有成就是否达成"""
	for ach_id in ACHIEVEMENTS.keys():
		if ach_id in unlocked_achievements:
			continue  # 已解锁
		var ach = ACHIEVEMENTS[ach_id]
		var cond = ach["condition"]
		if _eval_achievement_condition(cond):
			_unlock_achievement(ach_id)

func _eval_achievement_condition(cond: String) -> bool:
	"""求值成就条件表达式"""
	# 解析形如 "enemies_defeated >= 10" 的表达式
	var parts = cond.split(" ")
	if parts.size() < 3:
		return false
	var stat_name = parts[0]
	var op = parts[1]
	var threshold = int(parts[2])
	var value = achievement_stats.get(stat_name, 0)
	match op:
		">=":
			return value >= threshold
		"==":
			return value == threshold
		">":
			return value > threshold
		"<":
			return value < threshold
	return false

func _unlock_achievement(ach_id: String):
	"""解锁成就并显示通知"""
	if ach_id in unlocked_achievements:
		return
	unlocked_achievements.append(ach_id)
	var ach = ACHIEVEMENTS[ach_id]
	_show_achievement_notification(ach)

func _show_achievement_notification(ach: Dictionary):
	"""显示成就解锁通知(屏幕中央弹出)"""
	# 移除已有通知
	if achievement_notification_ui != null:
		achievement_notification_ui.queue_free()
	achievement_notification_ui = Control.new()
	achievement_notification_ui.name = "AchievementNotification"
	achievement_notification_ui.set_anchors_preset(Control.PRESET_CENTER)
	achievement_notification_ui.position = Vector2(-200, -40)
	achievement_notification_ui.size = Vector2(400, 80)
	add_child(achievement_notification_ui)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.self_modulate = Color(0.05, 0.04, 0.02, 0.97)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.04, 0.02, 0.97)
	ps.border_color = PALETTE.gold
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", ps)
	achievement_notification_ui.add_child(panel)

	var icon_lbl = Label.new()
	icon_lbl.set_anchors_preset(Control.PRESET_CENTER)
	icon_lbl.position = Vector2(-165, 0)
	icon_lbl.text = ach["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 28)
	panel.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.set_anchors_preset(Control.PRESET_CENTER)
	name_lbl.position = Vector2(-10, -15)
	name_lbl.text = "🏆 成就解锁: " + ach["name"]
	name_lbl.add_theme_color_override("font_color", PALETTE.gold)
	name_lbl.add_theme_font_size_override("font_size", 16)
	panel.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.set_anchors_preset(Control.PRESET_CENTER)
	desc_lbl.position = Vector2(-10, 12)
	desc_lbl.text = ach["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.65))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	panel.add_child(desc_lbl)

	# 3秒后自动消失
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(Callable(self, "_dismiss_achievement_notification"))

func _dismiss_achievement_notification():
	if achievement_notification_ui != null:
		achievement_notification_ui.queue_free()
		achievement_notification_ui = null

func _open_achievement_log():
	if achievement_log_open:
		return
	achievement_log_open = true
	if minimap_container:
		minimap_container.visible = false
	_create_achievement_log_ui()
	show_message("成就 (按 K 或 ESC 关闭)")

func _close_achievement_log():
	if achievement_log_ui != null:
		achievement_log_ui.queue_free()
		achievement_log_ui = null
	for btn in achievement_log_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	achievement_log_buttons.clear()
	achievement_log_open = false
	if minimap_container:
		minimap_container.visible = true
	show_message("")

func _create_achievement_log_ui():
	if achievement_log_ui != null:
		achievement_log_ui.queue_free()
	achievement_log_buttons.clear()

	achievement_log_ui = Control.new()
	achievement_log_ui.name = "AchievementLogUI"
	achievement_log_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(achievement_log_ui)

	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.gui_input.connect(_on_achievement_overlay_click)
	achievement_log_ui.add_child(overlay)

	var ach_panel = Panel.new()
	ach_panel.name = "AchievementPanel"
	ach_panel.position = Vector2(280, 50)
	ach_panel.size = Vector2(720, 660)
	ach_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	ps.border_color = PALETTE.gold
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ach_panel.add_theme_stylebox_override("panel", ps)
	achievement_log_ui.add_child(ach_panel)

	var title = Label.new()
	title.position = Vector2(20, 15)
	title.text = "🏆 成就 (%d/%d)" % [unlocked_achievements.size(), ACHIEVEMENTS.size()]
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 22)
	ach_panel.add_child(title)

	# 成就列表(滚动区域)
	var scroll = ScrollContainer.new()
	scroll.name = "AchievementScroll"
	scroll.position = Vector2(20, 55)
	scroll.size = Vector2(680, 585)
	ach_panel.add_child(scroll)

	var list_container = VBoxContainer.new()
	list_container.name = "ListContainer"
	scroll.add_child(list_container)

	var y_offset = 10
	for ach_id in ACHIEVEMENTS.keys():
		var ach = ACHIEVEMENTS[ach_id]
		var unlocked = ach_id in unlocked_achievements
		var row = HBoxContainer.new()
		row.name = "AchRow_" + ach_id
		list_container.add_child(row)

		var icon_lbl = Label.new()
		icon_lbl.text = ach["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_lbl.custom_minimum_size = Vector2(40, 30)
		row.add_child(icon_lbl)

		var name_lbl = Label.new()
		name_lbl.text = ach["name"]
		name_lbl.add_theme_color_override("font_color", PALETTE.gold if unlocked else Color(0.3, 0.3, 0.3))
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ach["desc"]
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5) if unlocked else Color(0.25, 0.25, 0.25))
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.custom_minimum_size = Vector2(320, 0)
		row.add_child(desc_lbl)

		var status_lbl = Label.new()
		status_lbl.text = "✓" if unlocked else "🔒"
		status_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if unlocked else Color(0.3, 0.3, 0.3))
		status_lbl.add_theme_font_size_override("font_size", 16)
		status_lbl.custom_minimum_size = Vector2(30, 0)
		row.add_child(status_lbl)

		y_offset += 35

func _on_achievement_overlay_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_achievement_log()

# ==================== 任务日志系统 ====================

func _open_quest_log():
	if quest_log_open:
		return
	quest_log_open = true
	if minimap_container:
		minimap_container.visible = false
	_create_quest_log_ui()
	show_message("任务日志 (按 Q 或 ESC 关闭)")

func _close_quest_log():
	if quest_log_ui != null:
		quest_log_ui.queue_free()
		quest_log_ui = null
	for btn in quest_log_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	quest_log_buttons.clear()
	quest_log_open = false
	if minimap_container:
		minimap_container.visible = true
	show_message("")

func _create_quest_log_ui():
	if quest_log_ui != null:
		quest_log_ui.queue_free()
	quest_log_buttons.clear()

	quest_log_ui = Control.new()
	quest_log_ui.name = "QuestLogUI"
	quest_log_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(quest_log_ui)

	# 背景遮罩
	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.position = Vector2(0, 0)
	overlay.gui_input.connect(_on_quest_overlay_click)
	quest_log_ui.add_child(overlay)

	# 任务面板
	var quest_panel = Panel.new()
	quest_panel.name = "QuestPanel"
	quest_panel.position = Vector2(320, 60)
	quest_panel.size = Vector2(640, 600)
	quest_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	quest_panel.add_theme_stylebox_override("panel", _create_stylebox())
	quest_log_ui.add_child(quest_panel)

	# 标题
	var title = Label.new()
	title.position = Vector2(20, 15)
	title.text = "📜 任务日志"
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 22)
	quest_panel.add_child(title)

	# 副标题
	var sub_title = Label.new()
	sub_title.position = Vector2(20, 48)
	sub_title.text = "进行中的任务"
	sub_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	quest_panel.add_child(sub_title)

	# 任务列表区域
	var quest_area = Panel.new()
	quest_area.name = "QuestArea"
	quest_area.position = Vector2(20, 80)
	quest_area.size = Vector2(600, 400)
	quest_area.self_modulate = Color(0, 0, 0, 0.3)
	quest_area.add_theme_stylebox_override("panel", _create_stylebox())
	quest_panel.add_child(quest_area)

	_draw_quest_list(quest_area)

	# 提示信息
	var hint_lbl = Label.new()
	hint_lbl.position = Vector2(20, 495)
	hint_lbl.text = "按 Q 或 ESC 关闭"
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	quest_panel.add_child(hint_lbl)

func _on_quest_overlay_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_quest_log()

func _draw_quest_list(quest_area: Panel):
	for btn in quest_log_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	quest_log_buttons.clear()

	var quests = player_data.quest_log
	if quests.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.name = "EmptyQuestLabel"
		empty_lbl.text = "暂无进行中的任务\n去客栈打听消息,获得新任务"
		empty_lbl.position = Vector2(150, 100)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty_lbl.add_theme_font_size_override("font_size", 16)
		quest_area.add_child(empty_lbl)
		quest_log_buttons.append(empty_lbl)
		return

	var start_x = 15
	var start_y = 15
	var row_height = 110
	var idx = 0

	for quest in quests:
		if not quest.get("active", true):
			continue

		var by = start_y + idx * row_height

		# 任务标题背景
		var quest_bg = ColorRect.new()
		quest_bg.name = "quest_bg_%d" % idx
		quest_bg.size = Vector2(570, 100)
		quest_bg.position = Vector2(start_x, by)
		if quest.get("completed", false):
			quest_bg.color = Color(0.1, 0.25, 0.1, 0.5)
		else:
			quest_bg.color = Color(0.08, 0.08, 0.15, 0.5)
		quest_area.add_child(quest_bg)
		quest_log_buttons.append(quest_bg)

		# 任务ID标签 (用于识别)
		var qid_lbl = Label.new()
		qid_lbl.name = "qid_%d" % idx
		qid_lbl.text = quest.get("id", "?")
		qid_lbl.visible = false  # 隐藏,只用于标识
		qid_lbl.position = Vector2(start_x, by)
		quest_area.add_child(qid_lbl)

		# 任务标题
		var quest_title = Label.new()
		quest_title.name = "quest_title_%d" % idx
		var title_text = "📋 " + quest.get("title", "未知任务")
		if quest.get("completed", false):
			title_text = "✅ " + quest.get("title", "未知任务")
		quest_title.text = title_text
		quest_title.position = Vector2(start_x + 10, by + 8)
		if quest.get("completed", false):
			quest_title.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
		else:
			quest_title.add_theme_color_override("font_color", PALETTE.gold)
		quest_title.add_theme_font_size_override("font_size", 16)
		quest_area.add_child(quest_title)
		quest_log_buttons.append(quest_title)

		# 任务描述
		var quest_desc = Label.new()
		quest_desc.name = "quest_desc_%d" % idx
		quest_desc.text = quest.get("desc", "")
		quest_desc.position = Vector2(start_x + 10, by + 32)
		quest_desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.55))
		quest_desc.add_theme_font_size_override("font_size", 12)
		quest_area.add_child(quest_desc)
		quest_log_buttons.append(quest_desc)

		# 目标列表
		var objectives = quest.get("objectives", [])
		var obj_text = ""
		var all_done = true
		for obj in objectives:
			var done_mark = "☑" if obj.get("completed", false) else "☐"
			obj_text += done_mark + " " + obj.get("text", "?") + "\n"
			if not obj.get("completed", false):
				all_done = false

		var obj_lbl = Label.new()
		obj_lbl.name = "quest_obj_%d" % idx
		obj_lbl.text = obj_text
		obj_lbl.position = Vector2(start_x + 10, by + 55)
		if all_done and not quest.get("completed", false):
			obj_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			obj_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4))
		obj_lbl.add_theme_font_size_override("font_size", 12)
		quest_area.add_child(obj_lbl)
		quest_log_buttons.append(obj_lbl)

		# 奖励信息
		var rewards = quest.get("rewards", {})
		var reward_text = ""
		if rewards.get("exp", 0) > 0:
			reward_text += "经验+%d " % rewards["exp"]
		if rewards.get("gold", 0) > 0:
			reward_text += "金币+%d" % rewards["gold"]
		if reward_text != "":
			var reward_lbl = Label.new()
			reward_lbl.name = "quest_reward_%d" % idx
			reward_lbl.text = "奖励: " + reward_text
			reward_lbl.position = Vector2(start_x + 380, by + 8)
			reward_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.3))
			reward_lbl.add_theme_font_size_override("font_size", 12)
			quest_area.add_child(reward_lbl)
			quest_log_buttons.append(reward_lbl)

		idx += 1

	# 已完成任务
	var completed_quests = player_data.completed_quests
	if completed_quests.size() > 0:
		var comp_label = Label.new()
		comp_label.name = "CompletedSection"
		comp_label.text = "\n已完成任务 (%d)" % completed_quests.size()
		comp_label.position = Vector2(start_x, by + 115)
		comp_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		quest_area.add_child(comp_label)
		quest_log_buttons.append(comp_label)

# ==================== 商店系统 ====================

func _get_shop_items_by_tab(tab: int) -> Array:
	match tab:
		0: return SHOP_WEAPONS
		1: return SHOP_ARMORS
		2: return SHOP_ACCESSORIES
		3: return SHOP_POTIONS
		4: return []  # 强化面板自行处理
	return []

var shop_bg_sprite: Sprite2D  # 商店背景精灵
var shop_bg_fallback: ColorRect  # 商店背景fallback(加载失败时使用)

func _open_shop():
	game_state = State.SHOP
	if minimap_container:
		minimap_container.visible = false
	_create_shop_bg()  # 添加商店背景
	_create_shop_ui()
	show_message("欢迎光临商店!")
	if audio_manager:
		audio_manager.play_bgm("shop")


func _create_shop_bg():
	# 移除旧背景
	if shop_bg_sprite:
		shop_bg_sprite.queue_free()

	# 创建背景精灵(使用酒馆场景)
	shop_bg_sprite = Sprite2D.new()
	shop_bg_sprite.name = "ShopBG"
	shop_bg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop_bg_sprite.centered = false
	shop_bg_sprite.position = Vector2(0, 0)

	var bg_tex = load("res://assets/doubao/tavern_scene.png")
	if bg_tex:
		shop_bg_sprite.texture = bg_tex
		# 缩放到屏幕尺寸 (ASSET_TEX_SIZE -> 1280x720 保持比例裁切)
		var scale_x = 1280.0 / ASSET_TEX_SIZE
		var scale_y = 720.0 / ASSET_TEX_SIZE
		var scale = max(scale_x, scale_y)  # 用更大的缩放保证覆盖
		shop_bg_sprite.scale = Vector2(scale, scale)
		# 居中
		var scaled_w = ASSET_TEX_SIZE * scale
		var scaled_h = ASSET_TEX_SIZE * scale
		shop_bg_sprite.position = Vector2((1280 - scaled_w) / 2, (720 - scaled_h) / 2)
	else:
		# 回退到纯色背景
		shop_bg_fallback = ColorRect.new()
		shop_bg_fallback.size = SCREEN_SIZE
		shop_bg_fallback.color = Color(0.15, 0.1, 0.05, 1)
		shop_bg_fallback.z_index = -10
		add_child(shop_bg_fallback)
		shop_bg_sprite = null
		return

	add_child(shop_bg_sprite)
	# 确保背景在最底层
	shop_bg_sprite.z_index = -10

func _close_shop():
	if shop_bg_sprite:
		shop_bg_sprite.queue_free()
		shop_bg_sprite = null
	if shop_bg_fallback:
		shop_bg_fallback.queue_free()
		shop_bg_fallback = null
	if shop_ui != null:
		shop_ui.queue_free()
		shop_ui = null
	for btn in shop_item_buttons:
		if btn != null:
			btn.queue_free()
	shop_item_buttons.clear()
	game_state = State.EXPLORE
	if minimap_container:
		minimap_container.visible = true
	show_message("下次再来!")
	if audio_manager:
		audio_manager.play_bgm("explore")

func _process_shop(delta):
	if Input.is_action_pressed("ui_cancel"):
		_close_shop()

func _create_shop_ui():
	if shop_ui != null:
		shop_ui.queue_free()
	shop_item_buttons.clear()

	shop_ui = Control.new()
	shop_ui.name = "ShopUI"
	shop_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shop_ui)

	# 背景遮罩
	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.position = Vector2(0, 0)
	shop_ui.add_child(overlay)

	# 商店面板
	var shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.position = Vector2(140, 60)
	shop_panel.size = Vector2(1000, 600)
	shop_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	shop_panel.add_theme_stylebox_override("panel", _create_stylebox())
	shop_ui.add_child(shop_panel)

	# 标题
	var title = Label.new()
	title.position = Vector2(20, 15)
	title.text = "🏪 商店"
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 20)
	shop_panel.add_child(title)

	# 金币显示
	var gold_disp = Label.new()
	gold_disp.name = "ShopGold"
	gold_disp.position = Vector2(800, 15)
	gold_disp.text = "💰 %d 金币" % player_data.gold
	gold_disp.add_theme_color_override("font_color", PALETTE.gold)
	gold_disp.add_theme_font_size_override("font_size", 16)
	shop_panel.add_child(gold_disp)

	# Tab 按钮
	var tab_panel = Panel.new()
	tab_panel.name = "TabPanel"
	tab_panel.position = Vector2(20, 55)
	tab_panel.size = Vector2(960, 55)
	tab_panel.self_modulate = Color(0, 0, 0, 0)
	shop_panel.add_child(tab_panel)

	for i in range(5):
		var tab_btn = _create_tab_button(shop_tabs[i], Vector2(i * 140, 0), i == selected_shop_tab)
		tab_btn.pressed.connect(_on_shop_tab_selected.bind(i))
		tab_panel.add_child(tab_btn)

	# 商品列表
	_draw_shop_items(shop_panel)

	# 关闭按钮
	var close_btn = _create_action_button("❌ 离开商店", Vector2(400, 520))
	close_btn.pressed.connect(_close_shop)
	close_btn.size = Vector2(180, 55)
	shop_panel.add_child(close_btn)

	# 玩家装备信息(右侧)
	var equip_panel = Panel.new()
	equip_panel.name = "EquipPanel"
	equip_panel.position = Vector2(780, 120)
	equip_panel.size = Vector2(200, 380)
	equip_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	equip_panel.add_theme_stylebox_override("panel", _create_stylebox())
	shop_panel.add_child(equip_panel)

	var eq_title = Label.new()
	eq_title.position = Vector2(15, 10)
	eq_title.text = "当前装备"
	eq_title.add_theme_color_override("font_color", PALETTE.gold)
	equip_panel.add_child(eq_title)

	var wpn = player_data.weapon
	var arm = player_data.armor
	var acc = player_data.accessory

	var wpn_text = "武器: " + (wpn.get("name", "无") if wpn else "无")
	var arm_text = "防具: " + (arm.get("name", "无") if arm else "无")
	var acc_text = "饰品: " + (acc.get("name", "无") if acc else "无")

	var wpn_lbl = Label.new()
	wpn_lbl.position = Vector2(15, 45)
	wpn_lbl.text = wpn_text
	wpn_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(wpn_lbl)

	var arm_lbl = Label.new()
	arm_lbl.position = Vector2(15, 70)
	arm_lbl.text = arm_text
	arm_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(arm_lbl)

	var acc_lbl = Label.new()
	acc_lbl.position = Vector2(15, 95)
	acc_lbl.text = acc_text
	acc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	equip_panel.add_child(acc_lbl)

	# 属性显示
	var stat_lbl = Label.new()
	stat_lbl.position = Vector2(15, 130)
	stat_lbl.text = "ATK: %d\nDEF: %d\nSPD: %d\nLUK: %d" % [
		player_data.attack_power(), player_data.defense(),
		player_data.spd + player_data.accessory.get("spd", 0),
		player_data.luk + player_data.accessory.get("luk", 0)
	]
	stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	equip_panel.add_child(stat_lbl)

func _create_tab_button(text: String, pos: Vector2, selected: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(130, 45)
	btn.add_theme_font_size_override("font_size", 14)
	var n_style = StyleBoxFlat.new()
	n_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	n_style.border_color = PALETTE.gold
	n_style.border_width_left = 1
	n_style.border_width_top = 1
	n_style.border_width_right = 1
	n_style.border_width_bottom = 1
	n_style.corner_radius_top_left = 3
	n_style.corner_radius_top_right = 3
	n_style.corner_radius_bottom_right = 3
	n_style.corner_radius_bottom_left = 3
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.2, 0.18, 0.05, 0.95)
	s_style.border_color = PALETTE.gold
	s_style.border_width_left = 1
	s_style.border_width_top = 2
	s_style.border_width_right = 1
	s_style.border_width_bottom = 1
	s_style.corner_radius_top_left = 3
	s_style.corner_radius_top_right = 3
	s_style.corner_radius_bottom_right = 3
	s_style.corner_radius_bottom_left = 3
	if selected:
		btn.add_theme_stylebox_override("normal", s_style)
		btn.add_theme_color_override("font_color", PALETTE.gold)
	else:
		btn.add_theme_stylebox_override("normal", n_style)
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	return btn

func _on_shop_tab_selected(tab: int):
	selected_shop_tab = tab
	# 刷新 tab 样式
	var tab_panel = shop_ui.get_node_or_null("ShopPanel/TabPanel")
	if tab_panel:
		for i in range(5):
			var btn = tab_panel.get_child(i)
			var is_sel = (i == tab)
			var n_style = StyleBoxFlat.new()
			n_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
			n_style.border_color = PALETTE.gold
			n_style.border_width_left = 1; n_style.border_width_top = 1
			n_style.border_width_right = 1; n_style.border_width_bottom = 1
			n_style.corner_radius_top_left = 3; n_style.corner_radius_top_right = 3
			n_style.corner_radius_bottom_right = 3; n_style.corner_radius_bottom_left = 3
			var s_style = StyleBoxFlat.new()
			s_style.bg_color = Color(0.2, 0.18, 0.05, 0.95)
			s_style.border_color = PALETTE.gold
			s_style.border_width_left = 1; s_style.border_width_top = 2
			s_style.border_width_right = 1; s_style.border_width_bottom = 1
			s_style.corner_radius_top_left = 3; s_style.corner_radius_top_right = 3
			s_style.corner_radius_bottom_right = 3; s_style.corner_radius_bottom_left = 3
			if is_sel:
				btn.add_theme_stylebox_override("normal", s_style)
				btn.add_theme_color_override("font_color", PALETTE.gold)
			else:
				btn.add_theme_stylebox_override("normal", n_style)
				btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	# 重绘商品
	_draw_shop_items(shop_ui.get_node("ShopPanel"))

func _draw_shop_items(shop_panel: Panel):
	# 清除旧商品按钮
	for btn in shop_item_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	shop_item_buttons.clear()

	# 强化面板自行处理
	if selected_shop_tab == 4:
		_draw_enhance_items(shop_panel)
		return

	var items = _get_shop_items_by_tab(selected_shop_tab)
	var start_x = 20
	var start_y = 120
	var cols = 4 if selected_shop_tab < 3 else 4
	var idx = 0

	for item in items:
		var row = idx / cols
		var col = idx % cols
		var bx = start_x + col * 235
		var by = start_y + row * 90
		var btn = _create_item_button(item, Vector2(bx, by))
		shop_panel.add_child(btn)
		shop_item_buttons.append(btn)
		idx += 1

func _create_item_button(item: Dictionary, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(225, 80)

	var item_name = item.get("icon", "📦") + " " + item.get("name", "???")
	var stats_text = ""

	if item.has("heal_hp"):
		# 药水
		if item["heal_hp"] > 0:
			stats_text = "恢复 %d HP" % item["heal_hp"]
		else:
			stats_text = "恢复 %d MP" % item["heal_mp"]
		stats_text += " | %d 金币" % item["price"]
	elif item.has("material"):
		# 强化材料
		stats_text = "强化材料 | %d 金币" % item["price"]
	else:
		# 装备
		var parts = []
		if item.get("atk", 0) > 0: parts.append("ATK+%d" % item["atk"])
		if item.get("def", 0) > 0: parts.append("DEF+%d" % item["def"])
		if item.get("hp", 0) > 0: parts.append("HP+%d" % item["hp"])
		if item.get("spd", 0) > 0: parts.append("SPD+%d" % item["spd"])
		if item.get("luk", 0) > 0: parts.append("LUK+%d" % item["luk"])
		stats_text = " ".join(parts) + " | %d 金币" % item["price"]

	var can_afford = player_data.gold >= item["price"]

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = PALETTE.gold if can_afford else Color(0.3, 0.3, 0.3)
	style.border_width_left = 1; style.border_width_top = 1
	style.border_width_right = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3; style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75) if can_afford else Color(0.4, 0.4, 0.4))

	# 自定义文本
	var lbl = Label.new()
	lbl.position = Vector2(10, 8)
	lbl.text = item_name
	lbl.add_theme_color_override("font_color", PALETTE.gold if can_afford else Color(0.4, 0.4, 0.4))
	lbl.add_theme_font_size_override("font_size", 14)
	btn.add_child(lbl)

	var stat_lbl = Label.new()
	stat_lbl.position = Vector2(10, 32)
	stat_lbl.text = stats_text
	stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6) if can_afford else Color(0.35, 0.35, 0.35))
	stat_lbl.add_theme_font_size_override("font_size", 12)
	btn.add_child(stat_lbl)

	var hint_lbl = Label.new()
	hint_lbl.position = Vector2(10, 55)
	hint_lbl.text = "[ 点击购买 ]" if can_afford else "[ 金钱不足 ]"
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4) if can_afford else Color(0.7, 0.2, 0.2))
	hint_lbl.add_theme_font_size_override("font_size", 11)
	btn.add_child(hint_lbl)

	btn.pressed.connect(_on_shop_item_clicked.bind(item))
	return btn

var _selected_shop_item: Dictionary = {}  # 当前选中的待购物品
var _shop_compare_panel: Panel = null  # 比较面板

func _on_shop_item_clicked(item: Dictionary):
	# 药水直接购买
	if item.has("heal_hp"):
		if player_data.gold < item["price"]:
			show_message("金钱不足!")
			return
		player_data.gold -= item["price"]
		achievement_stats["total_gold_spent"] += item["price"]
		var found = false
		for inv in player_data.inventory:
			if inv.get("type") == item["name"]:
				inv["count"] += 1
				found = true
				break
		if not found:
			player_data.inventory.append({"type": item["name"], "count": 1, "heal_hp": item["heal_hp"], "heal_mp": item["heal_mp"]})
		show_message("购买了 %s ×1" % item["name"])
		if audio_manager:
			audio_manager.play_sfx("purchase")
		_update_shop_ui()
	_check_achievements()
	return

	# 强化材料购买
	if item.has("material"):
		if player_data.gold < item["price"]:
			show_message("金钱不足!")
			return
		player_data.gold -= item["price"]
		achievement_stats["total_gold_spent"] += item["price"]
		var mat_name = item["material"]
		var found = false
		for inv in player_data.inventory:
			if inv.get("type") == mat_name:
				inv["count"] += 1
				found = true
				break
		if not found:
			player_data.inventory.append({"type": mat_name, "count": 1})
		show_message("购买了 %s ×1" % mat_name)
		if audio_manager:
			audio_manager.play_sfx("purchase")
		_update_shop_ui()
		_check_achievements()
		return

	# 装备:显示比较面板
	if player_data.gold < item["price"]:
		show_message("金钱不足!")
		return

	_selected_shop_item = item
	_show_equipment_compare_panel(item)

func _show_equipment_compare_panel(item: Dictionary):
	# 清除旧比较面板
	if _shop_compare_panel and is_instance_valid(_shop_compare_panel):
		_shop_compare_panel.queue_free()

	var shop_panel = shop_ui.get_node_or_null("ShopPanel")
	if not shop_panel:
		return

	_shop_compare_panel = Panel.new()
	_shop_compare_panel.name = "ComparePanel"
	_shop_compare_panel.position = Vector2(560, 130)
	_shop_compare_panel.size = Vector2(210, 380)
	_shop_compare_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	_shop_compare_panel.add_theme_stylebox_override("panel", _create_stylebox())
	shop_panel.add_child(_shop_compare_panel)

	# 标题
	var title = Label.new()
	title.position = Vector2(15, 10)
	title.text = "📊 属性对比"
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 14)
	_shop_compare_panel.add_child(title)

	# 当前装备
	var current_item: Dictionary
	match selected_shop_tab:
		0: current_item = player_data.weapon
		1: current_item = player_data.armor
		2: current_item = player_data.accessory

	var current_name = "无" if current_item.size() == 0 else current_item.get("name", "???")
	var new_name = item.get("name", "???")

	# 新装备名称
	var new_lbl = Label.new()
	new_lbl.position = Vector2(15, 38)
	new_lbl.text = "▶ %s" % new_name
	new_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	new_lbl.add_theme_font_size_override("font_size", 12)
	_shop_compare_panel.add_child(new_lbl)

	# 当前装备名称
	var cur_lbl = Label.new()
	cur_lbl.position = Vector2(15, 58)
	cur_lbl.text = "  当前: %s" % current_name
	cur_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	cur_lbl.add_theme_font_size_override("font_size", 11)
	_shop_compare_panel.add_child(cur_lbl)

	# 属性对比
	var y_pos = 90
	var stats = [
		{"key": "atk", "name": "ATK", "cur": player_data.atk, "wpn": current_item.get("atk", 0), "arm": 0, "acc": 0, "new": item.get("atk", 0)},
		{"key": "def", "name": "DEF", "cur": player_data.def, "wpn": 0, "arm": current_item.get("def", 0), "acc": 0, "new": item.get("def", 0)},
		{"key": "hp", "name": "HP", "cur": player_data.max_hp, "wpn": current_item.get("hp", 0), "arm": 0, "acc": current_item.get("hp", 0), "new": item.get("hp", 0)},
		{"key": "spd", "name": "SPD", "cur": player_data.spd, "wpn": 0, "arm": 0, "acc": current_item.get("spd", 0), "new": item.get("spd", 0)},
		{"key": "luk", "name": "LUK", "cur": player_data.luk, "wpn": 0, "arm": 0, "acc": current_item.get("luk", 0), "new": item.get("luk", 0)}
	]

	# 计算当前总属性
	var cur_atk_total = player_data.atk + current_item.get("atk", 0)
	var cur_def_total = player_data.def + current_item.get("def", 0)
	var cur_hp_total = player_data.max_hp + current_item.get("hp", 0)
	var cur_spd_total = player_data.spd + current_item.get("spd", 0)
	var cur_luk_total = player_data.luk + current_item.get("luk", 0)

	# 计算新装备后的总属性
	var new_atk_total = player_data.atk + item.get("atk", 0)
	var new_def_total = player_data.def + item.get("def", 0)
	var new_hp_total = player_data.max_hp + item.get("hp", 0)
	var new_spd_total = player_data.spd + item.get("spd", 0)
	var new_luk_total = player_data.luk + item.get("luk", 0)

	var compare_stats = [
		{"name": "ATK", "cur": cur_atk_total, "new": new_atk_total},
		{"name": "DEF", "cur": cur_def_total, "new": new_def_total},
		{"name": "HP", "cur": cur_hp_total, "new": new_hp_total},
		{"name": "SPD", "cur": cur_spd_total, "new": new_spd_total},
		{"name": "LUK", "cur": cur_luk_total, "new": new_luk_total}
	]

	for stat in compare_stats:
		var diff = stat["new"] - stat["cur"]
		var stat_lbl = Label.new()
		stat_lbl.position = Vector2(15, y_pos)

		var diff_str = ""
		var diff_color = Color(0.7, 0.7, 0.6)
		if diff > 0:
			diff_str = " ↑+%d" % diff
			diff_color = Color(0.3, 0.9, 0.3)
		elif diff < 0:
			diff_str = " ↓%d" % diff
			diff_color = Color(0.9, 0.3, 0.3)
		else:
			diff_str = " ="
			diff_color = Color(0.5, 0.5, 0.5)

		stat_lbl.text = "%s: %d%s" % [stat["name"], stat["cur"], diff_str]
		stat_lbl.add_theme_color_override("font_color", diff_color)
		stat_lbl.add_theme_font_size_override("font_size", 12)
		_shop_compare_panel.add_child(stat_lbl)
		y_pos += 24

	# 分割线
	var sep = ColorRect.new()
	sep.position = Vector2(15, y_pos + 5)
	sep.size = Vector2(180, 1)
	sep.color = PALETTE.gold * Color(0.3, 0.3, 0.3, 0.5)
	_shop_compare_panel.add_child(sep)
	y_pos += 20

	# 价格
	var price_lbl = Label.new()
	price_lbl.position = Vector2(15, y_pos)
	price_lbl.text = "价格: %d 金币" % item["price"]
	price_lbl.add_theme_color_override("font_color", PALETTE.gold if player_data.gold >= item["price"] else Color(0.9, 0.3, 0.3))
	price_lbl.add_theme_font_size_override("font_size", 13)
	_shop_compare_panel.add_child(price_lbl)
	y_pos += 30

	# 确认购买按钮
	var confirm_btn = Button.new()
	confirm_btn.position = Vector2(15, y_pos)
	confirm_btn.size = Vector2(180, 45)
	confirm_btn.text = "✅ 确认购买"
	var cstyle = StyleBoxFlat.new()
	cstyle.bg_color = Color(0.1, 0.3, 0.1, 0.95)
	cstyle.border_color = Color(0.3, 0.9, 0.3)
	cstyle.border_width_left = 1; cstyle.border_width_top = 1
	cstyle.border_width_right = 1; cstyle.border_width_bottom = 1
	cstyle.corner_radius_top_left = 3; cstyle.corner_radius_top_right = 3
	cstyle.corner_radius_bottom_right = 3; cstyle.corner_radius_bottom_left = 3
	confirm_btn.add_theme_stylebox_override("normal", cstyle)
	confirm_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(_confirm_equipment_purchase)
	_shop_compare_panel.add_child(confirm_btn)
	y_pos += 55

	# 取消按钮
	var cancel_btn = Button.new()
	cancel_btn.position = Vector2(15, y_pos)
	cancel_btn.size = Vector2(180, 40)
	cancel_btn.text = "❌ 取消"
	var cstyle2 = StyleBoxFlat.new()
	cstyle2.bg_color = Color(0.2, 0.08, 0.08, 0.95)
	cstyle2.border_color = Color(0.7, 0.2, 0.2)
	cstyle2.border_width_left = 1; cstyle2.border_width_top = 1
	cstyle2.border_width_right = 1; cstyle2.border_width_bottom = 1
	cstyle2.corner_radius_top_left = 3; cstyle2.corner_radius_top_right = 3
	cstyle2.corner_radius_bottom_right = 3; cstyle2.corner_radius_bottom_left = 3
	cancel_btn.add_theme_stylebox_override("normal", cstyle2)
	cancel_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(_close_compare_panel)
	_shop_compare_panel.add_child(cancel_btn)

func _confirm_equipment_purchase():
	if _selected_shop_item.size() == 0:
		return
	var item = _selected_shop_item
	if player_data.gold < item["price"]:
		show_message("金钱不足!")
		_close_compare_panel()
		return

	player_data.gold -= item["price"]
	achievement_stats["total_gold_spent"] += item["price"]
	match selected_shop_tab:
		0: player_data.weapon = item
		1: player_data.armor = item
		2: player_data.accessory = item
	show_message("购买了 %s 并装备!" % item["name"])
	if audio_manager:
		audio_manager.play_sfx("purchase")
	_close_compare_panel()
	_update_shop_ui()
	_update_ui()
	_check_achievements()

func _close_compare_panel():
	_selected_shop_item = {}
	if _shop_compare_panel and is_instance_valid(_shop_compare_panel):
		_shop_compare_panel.queue_free()
		_shop_compare_panel = null

func _update_shop_ui():
	var shop_panel = shop_ui.get_node_or_null("ShopPanel")
	if shop_panel:
		var gold_disp = shop_panel.get_node_or_null("ShopGold")
		if gold_disp:
			gold_disp.text = "💰 %d 金币" % player_data.gold
		_draw_shop_items(shop_panel)

# ==================== 装备强化系统 ====================

func _draw_enhance_items(shop_panel: Panel):
	# 清除旧强化界面
	for btn in shop_item_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()
	shop_item_buttons.clear()

	# 强化说明
	var info_lbl = Label.new()
	info_lbl.name = "EnhanceInfo"
	info_lbl.position = Vector2(20, 120)
	info_lbl.text = "🔨 装备强化\n\n强化可提升装备的基础属性\n+1~+9 强化成功率 100%%\n+10 开始有失败风险(失败不退级)\n所需材料由装备品质决定"
	info_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	info_lbl.add_theme_font_size_override("font_size", 13)
	shop_panel.add_child(info_lbl)
	shop_item_buttons.append(info_lbl)

	# 绘制三个装备的强化面板
	var equip_slots = [
		{"slot": "weapon", "data": player_data.weapon, "label": "⚔️ 武器", "enhance": player_data.weapon_enhance},
		{"slot": "armor", "data": player_data.armor, "label": "🛡️ 防具", "enhance": player_data.armor_enhance},
		{"slot": "accessory", "data": player_data.accessory, "label": "💍 饰品", "enhance": player_data.accessory_enhance},
	]

	var start_y = 290
	for i in range(equip_slots.size()):
		var eq = equip_slots[i]
		var eq_data = eq["data"]
		var enhance_lvl = eq["enhance"]
		var eq_y = start_y + i * 100

		if eq_data.size() == 0:
			# 无装备时显示空槽
			var empty_lbl = Label.new()
			empty_lbl.position = Vector2(20, eq_y)
			empty_lbl.text = "%s: 无装备" % eq["label"]
			empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			empty_lbl.add_theme_font_size_override("font_size", 13)
			shop_panel.add_child(empty_lbl)
			shop_item_buttons.append(empty_lbl)
			continue

		var eq_name = eq_data.get("name", "???")
		var eq_grade = eq_data.get("grade", 1)
		var next_lvl = enhance_lvl + 1
		var can_enhance = true
		var reason = ""

		# 检查是否已达最大强化
		if next_lvl > 15:
			can_enhance = false
			reason = "已达最大强化等级!"
		else:
			# 检查金币
			var cost = ENHANCE_COSTS.get(next_lvl, 1000)
			if player_data.gold < cost:
				can_enhance = false
				reason = "金币不足(需 %d)" % cost
			# 检查材料
			var mat_info = ENHANCE_MATERIALS.get(eq_grade, ["未知材料", 1])
			var mat_name = mat_info[0]
			var mat_count = _count_inventory(mat_name)
			if mat_count < mat_info[1]:
				can_enhance = false
				reason = "缺少%s(持有 %d/%d)" % [mat_name, mat_count, mat_info[1]]

		# 成功率
		var success_rate = 100
		if next_lvl >= 10:
			success_rate = ENHANCE_SUCCESS_RATES.get(next_lvl, 50)

		# 构建显示文本
		var eq_lbl = Label.new()
		eq_lbl.position = Vector2(20, eq_y)
		eq_lbl.add_theme_font_size_override("font_size", 13)

		var mat_info = ENHANCE_MATERIALS.get(eq_grade, ["普通强化石", 1])
		var cost = ENHANCE_COSTS.get(next_lvl, 1000)

		var text = "%s %s [+%d]\n  成功率: %d%% | 费用: %d金币 | 材料: %s×%d" % [
			eq_data.get("icon", "📦"), eq_name, enhance_lvl,
			success_rate, cost, mat_info[0], mat_info[1]
		]

		if not can_enhance:
			text += "\n  ⚠️ %s" % reason
			eq_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			text += "\n  ➡️ 点击强化至 +%d" % next_lvl
			eq_lbl.add_theme_color_override("font_color", PALETTE.gold)

		eq_lbl.text = text
		shop_panel.add_child(eq_lbl)
		shop_item_buttons.append(eq_lbl)

		# 强化按钮
		if can_enhance:
			var btn = Button.new()
			btn.position = Vector2(700, eq_y - 5)
			btn.size = Vector2(140, 50)
			btn.text = "🔨 强化"
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.08, 0.2, 0.08, 0.95)
			btn_style.border_color = PALETTE.gold
			btn_style.border_width_left = 1; btn_style.border_width_top = 1
			btn_style.border_width_right = 1; btn_style.border_width_bottom = 1
			btn_style.corner_radius_top_left = 3; btn_style.corner_radius_top_right = 3
			btn_style.corner_radius_bottom_right = 3; btn_style.corner_radius_bottom_left = 3
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_color_override("font_color", PALETTE.gold)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(_on_enhance_clicked.bind(eq["slot"]))
			shop_panel.add_child(btn)
			shop_item_buttons.append(btn)

func _on_enhance_clicked(slot: String):
	# 获取当前强化等级
	var enhance_lvl = 0
	var eq_data: Dictionary
	match slot:
		"weapon":
			eq_data = player_data.weapon
			enhance_lvl = player_data.weapon_enhance
		"armor":
			eq_data = player_data.armor
			enhance_lvl = player_data.armor_enhance
		"accessory":
			eq_data = player_data.accessory
			enhance_lvl = player_data.accessory_enhance

	if eq_data.size() == 0:
		show_message("该装备栏为空!")
		return

	var next_lvl = enhance_lvl + 1
	if next_lvl > 15:
		show_message("已达最大强化等级!")
		return

	var eq_grade = eq_data.get("grade", 1)
	var cost = ENHANCE_COSTS.get(next_lvl, 1000)
	var mat_info = ENHANCE_MATERIALS.get(eq_grade, ["普通强化石", 1])
	var mat_name = mat_info[0]

	# 扣钱扣材料
	player_data.gold -= cost
	achievement_stats["total_gold_spent"] += cost
	_remove_inventory_item(mat_name, mat_info[1])

	# 判定成功率
	var success_rate = 100
	if next_lvl >= 10:
		success_rate = ENHANCE_SUCCESS_RATES.get(next_lvl, 50)

	var roll = randi() % 100
	var success = roll < success_rate

	if success:
		match slot:
			"weapon": player_data.weapon_enhance = next_lvl
			"armor": player_data.armor_enhance = next_lvl
			"accessory": player_data.accessory_enhance = next_lvl

		# 计算强化后属性变化
		var old_atk_def = 0
		var new_atk_def = 0
		if slot == "weapon":
			old_atk_def = player_data.attack_power()
			new_atk_def = player_data.atk + eq_data.get("atk", 0) + _calc_enhance_bonus(eq_grade, next_lvl)
		elif slot == "armor":
			old_atk_def = player_data.defense()
			new_atk_def = player_data.def + eq_data.get("def", 0) + _calc_enhance_bonus(eq_grade, next_lvl)

		show_message("🎉 强化成功!%s → +%d" % [eq_data.get("name", "装备"), next_lvl])
		if audio_manager:
			audio_manager.play_sfx("enhance_success")
	else:
		show_message("💨 强化失败... %s 强化等级不变" % eq_data.get("name", "装备"))
		if audio_manager:
			audio_manager.play_sfx("enhance_fail")

	_update_shop_ui()
	_update_ui()
	_check_achievements()

func _calc_enhance_bonus(grade: int, enhance_level: int) -> int:
	# 复刻 player.gd 中的强化属性加成计算
	var base = 20
	if grade >= 5: base = 100
	elif grade >= 3: base = 50
	var bonus = 0
	for i in range(1, enhance_level + 1):
		if i <= 5: bonus += int(base * 0.03)
		elif i <= 10: bonus += int(base * 0.05)
		else: bonus += int(base * 0.08)
	return bonus

func _count_inventory(mat_name: String) -> int:
	for item in player_data.inventory:
		if item.get("type") == mat_name:
			return item.get("count", 0)
	return 0

func _remove_inventory_item(mat_name: String, count: int):
	for item in player_data.inventory:
		if item.get("type") == mat_name:
			item["count"] -= count
			if item["count"] <= 0:
				player_data.inventory.erase(item)
			return

# ==================== 战斗系统 ====================

var enemy_sprite: Sprite2D
var enemy_hp_bar: ProgressBar
var enemy_name_label: Label
var battle_enemy_hp_label: Label
var enemy_sprite_pos: Vector2
var enemy_sprite_target: Vector2

func _start_battle():
	game_state = State.BATTLE
	is_player_turn = true
	player_defending = false
	player_shield = 0
	poison_stacks = 0
	poison_turns = 0
	trapped = false
	enemy_stun_turns = 0
	player_stun_turns = 0
	vanish_turns = 0
	berserk_turns = 0
	berserk_atk_boost = 0
	battle_cry_turns = 0
	battle_cry_atk_boost = 0
	battle_cry_team_boost = 0
	enemy_hit_this_battle = false  # 重置本场战斗命中记录
	# 法师T2状态重置
	meteor_burn_turns = 0
	meteor_burn_dmg = 0
	frost_slow_turns = 0
	arcane_shield_mp = 0
	spell_pierce_turns = 0
	mana_drain_turns = 0
	mana_drain_amount = 0
	# 法师T3状态重置
	absolute_zero_turns = 0
	meteor_turns = 0
	meteor_dmg = 0
	elemental_storm_turns = 0
	elemental_storm_dmg = 0
	time_stop_active = false
	time_stop_turns = 0
	# 法师T4状态重置
	arcane_truth_turns = 0
	arcane_truth_active = false
	arcane_weaving_history.clear()
	elemental_annihilation_weak_mult = 2.0
	# 猎人T2状态重置
	hunter_evasion_turns = 0
	hunter_speed_boost_turns = 0
	hunter_armor_pierce_turns = 0
	hunter_trap_dot_dmg = 0
	hunter_trap_turns = 0
	hunter_trap_slow = 0
	# 猎人T3状态重置
	hunter_one_hit_escape = false
	hunter_mark_turns = 0
	hunter_mark_mult = 1.0
	hunter_beast_turns = 0
	hunter_beast_dmg = 0
	hunter_death_mark_turns = 0
	hunter_death_mark_dmg = 1.0
	hunter_nature_power_turns = 0
	hunter_nature_power_bonus = 1.0
	hunter_hunting_field_turns = 0
	# 盗贼T2状态重置
	thief_poison_turns = 0
	thief_poison_dmg = 0
	thief_choke_turns = 0
	thief_combo_count = 0
	thief_combo_dmg = 0
	# 盗贼T3状态重置
	thief_shadow_clone_turns = 0
	thief_shadow_fang_turns = 0
	thief_shadow_fang_defdebuff = 0
	# 盗贼T4状态重置
	thief_thousand_faces_turns = 0
	thief_shadow_devour_turns = 0
	thief_illusion_domain_turns = 0
	# 牧师T2状态重置
	priest_mass_heal_mp = 0
	priest_dispel_done = false
	priest_smite_turns = 0
	priest_smite_defdebuff = 0
	# 牧师T3状态重置
	priest_resurrection_uses = 2
	priest_divine_domain_turns = 0
	priest_divine_domain_heal = 0
	priest_life_fountain_turns = 0
	priest_life_fountain_heal = 0
	priest_divine_judgment_turns = 0
	# 牧师T4状态重置
	priest_divine_miracle_used = false
	priest_holy_sentinel_active = false
	priest_holy_sentinel_hp_threshold = 0
	# 骑士T2状态重置
	knight_shield_bang_dmg = 0
	knight_judgment_turns = 0
	knight_judgment_defdebuff = 0
	knight_iron_wall_turns = 0
	knight_iron_wall_defboost = 0
	knight_holy_avenger_turns = 0
	knight_holy_avenger_dmg = 0
	knight_eternal_guard_turns = 0
	knight_eternal_guard_target = -1
	knight_judgment_aoe_turns = 0
	knight_judgment_aoe_dmg = 0
	knight_angel_guard_turns = 0
	knight_angel_guard_triggered = false
	knight_holy_hammer_turns = 0
	knight_holy_hammer_mult = 2.0
	knight_execution_turns = 0
	# 吟游诗人T2状态重置
	bard_song_atk_turns = 0
	bard_song_atk_boost = 0
	bard_rhythm_turns = 0
	bard_healing_melody_mp = 0
	# 吟游诗人T2路线B幻术师状态重置
	bard_hypno_turns = 0
	bard_hallucinate_turns = 0
	bard_chaos_turns = 0
	# 吟游诗人T3/T4状态重置(传奇之歌为永久,不重置)
	bard_perfect_chord_turns = 0
	bard_perfect_chord_atk_boost = 0
	bard_perfect_chord_crit_boost = 0
	bard_requiem_turns = 0
	bard_requiem_used = false
	bard_void_aria_turns = 0
	bard_void_aria_stat_debuff = 0
	bard_life_song_used = false
	# 召唤师T2状态重置
	summoner_contract_boost_turns = 0
	summoner_contract_boost_dmg = 0
	summoner_soul_link_turns = 0
	summoner_soul_link_dmg = 0
	summoner_beast_boost_turns = 0
	active_summons.clear()
	summoner_fusion_active = false
	summoner_fusion_turns = 0
	summoner_soul_contract_turns = 0
	summoner_soul_contract_dmg_boost = 0
	# 战士T3状态重置
	warrior_shatter_turns = 0
	warrior_shatter_defdebuff = 0
	warrior_shatter_orig_def = 0
	warrior_domain_turns = 0
	warrior_domain_atk_boost = 0
	warrior_domain_def_boost = 0
	warrior_guard_active = false
	warrior_guard_target_hp_pct = 0.0
	warrior_undying_used = false
	warrior_bloodlust_active = false
	# 战士T4状态重置
	warrior_wargod_mark_turns = 0
	warrior_wargod_mark_dmg_boost = 0
	warrior_absolute_def_turns = 0
	warrior_conqueror_fear_turns = 0
	warrior_conqueror_fear_atkdebuff = 0

	# 生成敌人(根据层数选择敌人类型)
	var enemy_data_class = _get_enemy_data()
	var enemy_pool = enemy_data_class.get_floor_enemies(current_floor)
	var etype = enemy_pool[randi() % enemy_pool.size()]
	var edata = enemy_data_class.new(etype, current_floor)

	# 精英敌人检测（15%概率，BOSS层除外）
	var is_elite = false
	var elite_mult: float = 1.0
	if current_floor < ELITE_FLOOR_MAX and randf() < ELITE_SPAWN_CHANCE:
		is_elite = true
		elite_mult = ELITE_HP_MULT

	var elite_name_prefix = "" if not is_elite else "精英·"
	var elite_exp_mult: float = ELITE_EXP_MULT if is_elite else 1.0
	var elite_gold_mult: float = ELITE_GOLD_MULT if is_elite else 1.0

	current_enemy = {
		"name": elite_name_prefix + edata.name,
		"id": etype,  # 敌人类型ID，用于任务追踪
		"type": etype,  # 保存敌人类型用于选择素材
		"hp": int(edata.hp * elite_mult),
		"max_hp": int(edata.hp * elite_mult),
		"atk": int(edata.atk * (ELITE_ATK_MULT if is_elite else 1.0)),
		"def": int(edata.def * (ELITE_DEF_MULT if is_elite else 1.0)),
		"spd": edata.spd,
		"exp": int(edata.exp_reward * elite_exp_mult),
		"gold": int(edata.gold_reward * elite_gold_mult),
		"color": edata.color,
		"faction": edata.faction,
		"is_boss": false,
		"is_elite": is_elite
	}

	if is_elite:
		show_message("⚠️ 遭遇了精英敌人 " + current_enemy["name"] + "!")
	else:
		show_message("遭遇了 " + current_enemy["name"] + "!")
	_create_battle_ui()
	# 重置技能冷却
	skill_cooldowns.clear()
	current_enemy["_last_skill"] = ""
	battle_started = true
	# 切换到战斗BGM
	if audio_manager:
		if current_floor >= 7 or current_enemy["name"] == "武当真人·张三丰":
			audio_manager.play_bgm("boss")
		else:
			audio_manager.play_bgm("battle")

	# 重置召唤师状态
	resonance_stacks = 0
	contract_active = false
	contract_turns = 0

	# 猎人陷阱被动检测
	if player_data.job == Job.HUNTER and player_data.skills.has("陷阱"):
		trapped = true
		await get_tree().create_timer(0.5).timeout
		var trap_dmg = int(player_data.attack_power() * 1.5)
		current_enemy["hp"] -= trap_dmg
		_battle_add_log("⚡ 陷阱触发!造成 %d 伤害" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -25))
		_update_enemy_hp_bar()
		await _check_battle_end()

func _start_boss_battle():
	game_state = State.BATTLE
	is_player_turn = true
	player_defending = false
	player_shield = 0
	poison_stacks = 0
	poison_turns = 0
	trapped = false
	enemy_stun_turns = 0
	player_stun_turns = 0
	vanish_turns = 0
	berserk_turns = 0
	berserk_atk_boost = 0
	battle_cry_turns = 0
	battle_cry_atk_boost = 0
	battle_cry_team_boost = 0
	resonance_stacks = 0
	contract_active = false
	contract_turns = 0
	# 法师T2状态重置
	meteor_burn_turns = 0
	meteor_burn_dmg = 0
	frost_slow_turns = 0
	arcane_shield_mp = 0
	spell_pierce_turns = 0
	mana_drain_turns = 0
	mana_drain_amount = 0
	# 法师T3状态重置
	absolute_zero_turns = 0
	meteor_turns = 0
	meteor_dmg = 0
	elemental_storm_turns = 0
	elemental_storm_dmg = 0
	time_stop_active = false
	time_stop_turns = 0
	# 法师T4状态重置
	arcane_truth_turns = 0
	arcane_truth_active = false
	arcane_weaving_history.clear()
	elemental_annihilation_weak_mult = 2.0
	# 猎人T2状态重置
	hunter_evasion_turns = 0
	hunter_speed_boost_turns = 0
	hunter_armor_pierce_turns = 0
	hunter_trap_dot_dmg = 0
	hunter_trap_turns = 0
	hunter_trap_slow = 0
	# 猎人T3状态重置
	hunter_one_hit_escape = false
	hunter_mark_turns = 0
	hunter_mark_mult = 1.0
	hunter_beast_turns = 0
	hunter_beast_dmg = 0
	hunter_death_mark_turns = 0
	hunter_death_mark_dmg = 1.0
	hunter_nature_power_turns = 0
	hunter_nature_power_bonus = 1.0
	hunter_hunting_field_turns = 0
	# 盗贼T2状态重置
	thief_poison_turns = 0
	thief_poison_dmg = 0
	thief_choke_turns = 0
	thief_combo_count = 0
	thief_combo_dmg = 0
	# 盗贼T3状态重置
	thief_shadow_clone_turns = 0
	thief_shadow_fang_turns = 0
	thief_shadow_fang_defdebuff = 0
	# 盗贼T4状态重置
	thief_thousand_faces_turns = 0
	thief_shadow_devour_turns = 0
	thief_illusion_domain_turns = 0
	# 牧师T2状态重置
	priest_mass_heal_mp = 0
	priest_dispel_done = false
	priest_smite_turns = 0
	priest_smite_defdebuff = 0
	# 牧师T3状态重置
	priest_resurrection_uses = 2
	priest_divine_domain_turns = 0
	priest_divine_domain_heal = 0
	priest_life_fountain_turns = 0
	priest_life_fountain_heal = 0
	priest_divine_judgment_turns = 0
	# 牧师T4状态重置
	priest_divine_miracle_used = false
	priest_holy_sentinel_active = false
	priest_holy_sentinel_hp_threshold = 0
	# 骑士T2状态重置
	knight_shield_bang_dmg = 0
	knight_judgment_turns = 0
	knight_judgment_defdebuff = 0
	knight_iron_wall_turns = 0
	knight_iron_wall_defboost = 0
	knight_holy_avenger_turns = 0
	knight_holy_avenger_dmg = 0
	knight_eternal_guard_turns = 0
	knight_eternal_guard_target = -1
	knight_judgment_aoe_turns = 0
	knight_judgment_aoe_dmg = 0
	knight_angel_guard_turns = 0
	knight_angel_guard_triggered = false
	knight_holy_hammer_turns = 0
	knight_holy_hammer_mult = 2.0
	knight_execution_turns = 0
	# 吟游诗人T2状态重置
	bard_song_atk_turns = 0
	bard_song_atk_boost = 0
	bard_rhythm_turns = 0
	bard_healing_melody_mp = 0
	# 吟游诗人T2路线B幻术师状态重置
	bard_hypno_turns = 0
	bard_hallucinate_turns = 0
	bard_chaos_turns = 0
	# 吟游诗人T3/T4状态重置(传奇之歌为永久,不重置)
	bard_perfect_chord_turns = 0
	bard_perfect_chord_atk_boost = 0
	bard_perfect_chord_crit_boost = 0
	bard_requiem_turns = 0
	bard_requiem_used = false
	bard_void_aria_turns = 0
	bard_void_aria_stat_debuff = 0
	bard_life_song_used = false
	# 召唤师T2状态重置
	summoner_contract_boost_turns = 0
	summoner_contract_boost_dmg = 0
	summoner_soul_link_turns = 0
	summoner_soul_link_dmg = 0
	summoner_beast_boost_turns = 0
	active_summons.clear()
	summoner_fusion_active = false
	summoner_fusion_turns = 0
	summoner_soul_contract_turns = 0
	summoner_soul_contract_dmg_boost = 0
	# 战士T3状态重置
	warrior_shatter_turns = 0
	warrior_shatter_defdebuff = 0
	warrior_domain_turns = 0
	warrior_domain_atk_boost = 0
	warrior_domain_def_boost = 0
	warrior_guard_active = false
	warrior_guard_target_hp_pct = 0.0
	warrior_undying_used = false
	warrior_bloodlust_active = false
	# 战士T4状态重置
	warrior_wargod_mark_turns = 0
	warrior_wargod_mark_dmg_boost = 0
	warrior_absolute_def_turns = 0
	warrior_conqueror_fear_turns = 0
	warrior_conqueror_fear_atkdebuff = 0
	boss_phase = 1
	boss_enraged = false
	boss_shield_stacks = 0
	boss_revived = false

	# 使用Boss数据
	current_enemy = current_boss_data.duplicate()
	current_enemy["is_boss"] = true

	show_message("⚠️ Boss战: " + current_enemy["name"] + "!")
	_create_battle_ui()
	# 重置技能冷却
	skill_cooldowns.clear()
	current_enemy["_last_skill"] = ""
	battle_started = true
	if audio_manager:
		audio_manager.play_bgm("boss")

	# 猎人陷阱对Boss也有效
	if player_data.job == Job.HUNTER and player_data.skills.has("陷阱"):
		trapped = true
		await get_tree().create_timer(0.5).timeout
		var trap_dmg = int(player_data.attack_power() * 1.0)  # Boss战陷阱伤害降低
		current_enemy["hp"] -= trap_dmg
		_battle_add_log("⚡ 陷阱触发!对Boss造成 %d 伤害" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -25))
		_update_enemy_hp_bar()
		await _check_battle_end()

func _create_battle_ui():
	# 清理旧战斗按钮引用
	for btn in battle_action_buttons:
		if btn and is_instance_valid(btn):
			btn.queue_free()
	battle_action_buttons.clear()

	# 隐藏小地图
	if minimap_container:
		minimap_container.visible = false
	# 暗色遮罩
	var overlay = ColorRect.new()
	overlay.name = "BattleOverlay"
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.position = Vector2(0, 0)
	add_child(overlay)

	battle_ui = Control.new()
	battle_ui.name = "BattleUI"
	battle_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(battle_ui)

	# 敌人区域 (上方)
	var enemy_panel = Panel.new()
	enemy_panel.name = "EnemyPanel"
	enemy_panel.position = Vector2(440, 80)
	enemy_panel.size = Vector2(400, 200)
	enemy_panel.self_modulate = Color(0.15, 0.12, 0.1, 0.95)  # 调亮背景以便看清sprite
	var is_elite_enemy = current_enemy.get("is_elite", false)
	if is_elite_enemy:
		enemy_panel.add_theme_stylebox_override("panel", _create_elite_stylebox())
	else:
		enemy_panel.add_theme_stylebox_override("panel", _create_stylebox())
	battle_ui.add_child(enemy_panel)

	# 敌人名称
	enemy_name_label = Label.new()
	enemy_name_label.position = Vector2(20, 15)
	enemy_name_label.text = current_enemy["name"]
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_elite_enemy:
		enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # 金色用于精英
	else:
		enemy_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.5))
	enemy_panel.add_child(enemy_name_label)

	# 精英标签
	if is_elite_enemy:
		var elite_label = Label.new()
		elite_label.name = "EliteLabel"
		elite_label.position = Vector2(20, 38)
		elite_label.text = "★ 精英敌人 ★"
		elite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elite_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
		elite_label.add_theme_font_size_override("font_size", 14)
		enemy_panel.add_child(elite_label)

	# 敌人精灵
	enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_sprite.centered = false  # 从左上角开始渲染

	# 尝试使用豆包素材
	var enemy_type = current_enemy.get("type", "")
	var loaded_tex = _load_enemy_texture(enemy_type)
	if loaded_tex:
		enemy_sprite.texture = loaded_tex
		# ASSET_TEX_SIZE -> ENEMY_SPRITE_DISPLAY_SIZE 显示 (约1/10)
		enemy_sprite.scale = Vector2(ENEMY_SPRITE_DISPLAY_SIZE/ASSET_TEX_SIZE, ENEMY_SPRITE_DISPLAY_SIZE/ASSET_TEX_SIZE)
		enemy_sprite.position = Vector2(100, 0)  # 居中偏左
	else:
		enemy_sprite.texture = _create_enemy_texture(current_enemy["color"])
		enemy_sprite.scale = Vector2(1, 1)
		enemy_sprite.position = Vector2(184, 20)  # 32x32居中

	enemy_sprite_target = enemy_sprite.position
	enemy_sprite_pos = enemy_sprite.position
	enemy_panel.add_child(enemy_sprite)

	# 敌人HP条
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.name = "EnemyHPBar"
	enemy_hp_bar.min_value = 0
	enemy_hp_bar.max_value = current_enemy["max_hp"]
	enemy_hp_bar.value = current_enemy["hp"]
	enemy_hp_bar.position = Vector2(20, 150)
	enemy_hp_bar.size = Vector2(360, 16)
	enemy_hp_bar.show_percentage = false
	enemy_hp_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	if is_elite_enemy:
		enemy_hp_bar.add_theme_stylebox_override("fill", _create_elite_hp_bar_fill())
	else:
		enemy_hp_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill())
	enemy_panel.add_child(enemy_hp_bar)

	battle_enemy_hp_label = Label.new()
	battle_enemy_hp_label.position = Vector2(20, 168)
	battle_enemy_hp_label.text = "%d / %d" % [current_enemy["hp"], current_enemy["max_hp"]]
	battle_enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_enemy_hp_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_panel.add_child(battle_enemy_hp_label)

	# 战斗日志
	var log_panel = Panel.new()
	log_panel.name = "LogPanel"
	log_panel.position = Vector2(440, 290)
	log_panel.size = Vector2(400, 160)
	log_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	log_panel.add_theme_stylebox_override("panel", _create_stylebox())
	battle_ui.add_child(log_panel)

	battle_log = Label.new()
	battle_log.position = Vector2(15, 15)
	battle_log.size = Vector2(370, 130)
	if is_elite_enemy:
		battle_log.text = ">>> ⚠️精英战斗!\n"
	else:
		battle_log.text = ">>> 战斗开始!\n"
	battle_log.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_panel.add_child(battle_log)

	# ===== 角色肖像面板 =====
	_create_battle_portrait_panel(battle_ui)

	# 玩家行动按钮区域
	var action_panel = Panel.new()
	action_panel.name = "ActionPanel"
	action_panel.position = Vector2(40, 420)
	action_panel.size = Vector2(500, 250)
	action_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	action_panel.add_theme_stylebox_override("panel", _create_stylebox())
	battle_ui.add_child(action_panel)

	# 攻击按钮
	var attack_btn = _create_action_button("⚔️ 攻击", Vector2(20, 20))
	attack_btn.pressed.connect(_on_attack)
	action_panel.add_child(attack_btn)
	battle_action_buttons.append(attack_btn)

	# 技能按钮
	var skill_btn = _create_action_button("✨ 技能", Vector2(160, 20))
	skill_btn.pressed.connect(_on_skill_menu)
	action_panel.add_child(skill_btn)
	battle_action_buttons.append(skill_btn)

	# 防御按钮
	var defend_btn = _create_action_button("🛡️ 防御", Vector2(300, 20))
	defend_btn.pressed.connect(_on_defend)
	action_panel.add_child(defend_btn)
	battle_action_buttons.append(defend_btn)

	# 逃跑按钮
	var flee_btn = _create_action_button("🏃 逃跑", Vector2(20, 90))
	flee_btn.pressed.connect(_on_flee)
	action_panel.add_child(flee_btn)
	battle_action_buttons.append(flee_btn)

	# 道具按钮
	var item_btn = _create_action_button("🧪 道具", Vector2(160, 90))
	item_btn.pressed.connect(_on_item)
	action_panel.add_child(item_btn)
	battle_action_buttons.append(item_btn)

	# 玩家状态显示
	var player_panel = Panel.new()
	player_panel.name = "PlayerPanel"
	player_panel.position = Vector2(560, 420)
	player_panel.size = Vector2(300, 250)
	player_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	player_panel.add_theme_stylebox_override("panel", _create_stylebox())
	battle_ui.add_child(player_panel)

	var pname = Label.new()
	pname.position = Vector2(20, 15)
	pname.text = "【%s】" % player_data.get_job_name()
	pname.add_theme_color_override("font_color", PALETTE.gold)
	player_panel.add_child(pname)

	var php = Label.new()
	php.position = Vector2(20, 45)
	php.name = "BattleHP"
	php.text = "HP: %d/%d" % [player_data.hp, player_data.max_hp]
	php.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	player_panel.add_child(php)

	var pmp = Label.new()
	pmp.position = Vector2(20, 70)
	pmp.name = "BattleMP"
	pmp.text = "MP: %d/%d" % [player_data.mp, player_data.max_mp]
	pmp.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	player_panel.add_child(pmp)

	# 状态效果标签
	var status_label = Label.new()
	status_label.position = Vector2(20, 100)
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	player_panel.add_child(status_label)

	# 技能冷却显示
	var cd_label = Label.new()
	cd_label.position = Vector2(20, 200)
	cd_label.name = "CDLabel"
	cd_label.text = ""
	cd_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	player_panel.add_child(cd_label)

	# 技能列表
	var skill_list_label = Label.new()
	skill_list_label.position = Vector2(20, 130)
	skill_list_label.text = "技能: " + ", ".join(player_data.skills)
	skill_list_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	player_panel.add_child(skill_list_label)

# ==================== 角色肖像面板 ====================
# 肖像动画状态
var portrait_breath_time: float = 0.0
var portrait_damage_flash: float = 0.0  # 受伤害闪红
var portrait_heal_glow: float = 0.0     # 治疗绿光
var _last_portrait_hp_ratio: float = -1.0  # HP阈值追踪,避免每帧重建StyleBoxFlat

func _create_battle_portrait_panel(parent: Control):
	# 整体肖像面板 (右上角,敌方面板下方)
	var portrait_panel = Panel.new()
	portrait_panel.name = "PortraitPanel"
	portrait_panel.position = Vector2(560, 155)
	portrait_panel.size = Vector2(300, 255)
	portrait_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.92)

	# 华丽边框
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.04, 0.04, 0.08, 0.92)
	var job_color = _get_job_color(player_data.job)
	frame_style.border_color = job_color
	frame_style.border_width_left = 3; frame_style.border_width_top = 3
	frame_style.border_width_right = 3; frame_style.border_width_bottom = 3
	frame_style.corner_radius_top_left = 6; frame_style.corner_radius_top_right = 6
	frame_style.corner_radius_bottom_right = 6; frame_style.corner_radius_bottom_left = 6
	portrait_panel.add_theme_stylebox_override("panel", frame_style)
	parent.add_child(portrait_panel)

	# 内部装饰背景(肖像区域)
	var portrait_bg = Panel.new()
	portrait_bg.name = "PortraitBG"
	portrait_bg.position = Vector2(10, 10)
	portrait_bg.size = Vector2(130, 130)
	portrait_bg.self_modulate = Color(0.02, 0.02, 0.04, 0.95)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.02, 0.02, 0.04, 0.95)
	bg_style.border_color = job_color * Color(0.5, 0.5, 0.5, 0.5)
	bg_style.border_width_left = 1; bg_style.border_width_top = 1
	bg_style.border_width_right = 1; bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 4; bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_right = 4; bg_style.corner_radius_bottom_left = 4
	portrait_bg.add_theme_stylebox_override("panel", bg_style)
	portrait_panel.add_child(portrait_bg)

	# 肖像精灵容器(用于动画)
	var portrait_container = Node2D.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.position = Vector2(75, 75)
	portrait_bg.add_child(portrait_container)

	# 肖像底层阴影
	var portrait_shadow = Sprite2D.new()
	portrait_shadow.name = "PortraitShadow"
	portrait_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_shadow.texture = _create_portrait_shadow()
	portrait_shadow.position = Vector2(0, 35)
	portrait_container.add_child(portrait_shadow)

	# 肖像主精灵
	var portrait_sprite = Sprite2D.new()
	portrait_sprite.name = "PortraitSprite"
	portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_sprite.texture = _create_job_portrait_texture(player_data.job)
	portrait_sprite.position = Vector2(0, 0)
	portrait_container.add_child(portrait_sprite)

	# 受伤/治疗闪红特效
	var portrait_flash = Sprite2D.new()
	portrait_flash.name = "PortraitFlash"
	portrait_flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var flash_tex = _create_portrait_flash(job_color)
	portrait_flash.texture = flash_tex
	portrait_flash.position = Vector2(0, 0)
	portrait_flash.modulate = Color(1, 1, 1, 0)  # 初始不可见
	portrait_container.add_child(portrait_flash)

	# 职业名称 + 等级标签
	var name_lbl = Label.new()
	name_lbl.name = "PortraitName"
	name_lbl.position = Vector2(10, 150)
	name_lbl.size = Vector2(280, 22)
	name_lbl.text = "【%s】 Lv.%d" % [player_data.get_job_name(), player_data.level]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", job_color)
	name_lbl.add_theme_font_size_override("font_size", 15)
	portrait_panel.add_child(name_lbl)

	# HP条
	var php_title = Label.new()
	php_title.position = Vector2(148, 14)
	php_title.text = "HP"
	php_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	php_title.add_theme_font_size_override("font_size", 11)
	portrait_panel.add_child(php_title)

	var php_bar = ProgressBar.new()
	php_bar.name = "PortraitHP"
	php_bar.position = Vector2(148, 32)
	php_bar.size = Vector2(142, 18)
	php_bar.min_value = 0
	php_bar.max_value = player_data.max_hp
	php_bar.value = player_data.hp
	php_bar.show_percentage = false
	php_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	php_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill())
	portrait_panel.add_child(php_bar)

	# HP数值
	var php_val = Label.new()
	php_val.name = "PortraitHPVal"
	php_val.position = Vector2(148, 52)
	php_val.size = Vector2(142, 18)
	php_val.text = "%d / %d" % [player_data.hp, player_data.max_hp]
	php_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	php_val.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
	php_val.add_theme_font_size_override("font_size", 11)
	portrait_panel.add_child(php_val)

	# MP条
	var pmp_title = Label.new()
	pmp_title.position = Vector2(148, 76)
	pmp_title.text = "MP"
	pmp_title.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	pmp_title.add_theme_font_size_override("font_size", 11)
	portrait_panel.add_child(pmp_title)

	var pmp_bar = ProgressBar.new()
	pmp_bar.name = "PortraitMP"
	pmp_bar.position = Vector2(148, 94)
	pmp_bar.size = Vector2(142, 18)
	pmp_bar.min_value = 0
	pmp_bar.max_value = player_data.max_mp
	pmp_bar.value = player_data.mp
	pmp_bar.show_percentage = false
	pmp_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	pmp_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill_mp())
	portrait_panel.add_child(pmp_bar)

	# MP数值
	var pmp_val = Label.new()
	pmp_val.name = "PortraitMPVal"
	pmp_val.position = Vector2(148, 114)
	pmp_val.size = Vector2(142, 18)
	pmp_val.text = "%d / %d" % [player_data.mp, player_data.max_mp]
	pmp_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pmp_val.add_theme_color_override("font_color", Color(0.6, 0.7, 1))
	pmp_val.add_theme_font_size_override("font_size", 11)
	portrait_panel.add_child(pmp_val)

	# 状态效果图标区域
	var status_container = Panel.new()
	status_container.name = "StatusContainer"
	status_container.position = Vector2(148, 138)
	status_container.size = Vector2(142, 35)
	status_container.self_modulate = Color(0, 0, 0, 0.3)
	var sc_style = StyleBoxFlat.new()
	sc_style.bg_color = Color(0.02, 0.02, 0.04, 0.3)
	sc_style.border_color = Color(0.3, 0.3, 0.3, 0.3)
	sc_style.border_width_left = 1; sc_style.border_width_top = 1
	sc_style.border_width_right = 1; sc_style.border_width_bottom = 1
	sc_style.corner_radius_top_left = 3; sc_style.corner_radius_top_right = 3
	sc_style.corner_radius_bottom_right = 3; sc_style.corner_radius_bottom_left = 3
	status_container.add_theme_stylebox_override("panel", sc_style)
	portrait_panel.add_child(status_container)

	# 职业属性标签
	var attr_lbl = Label.new()
	attr_lbl.name = "PortraitAttr"
	attr_lbl.position = Vector2(10, 180)
	attr_lbl.size = Vector2(280, 70)
	var attr_text = "⚔️%d  🛡️%d  ⚡%d  🍀%d" % [
		player_data.attack_power(), player_data.defense(),
		player_data.spd + player_data.accessory.get("spd", 0),
		player_data.luk + player_data.accessory.get("luk", 0)
	]
	attr_lbl.text = attr_text
	attr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65))
	attr_lbl.add_theme_font_size_override("font_size", 12)
	portrait_panel.add_child(attr_lbl)

	# 状态效果标签(文字版,备用)
	var effect_lbl = Label.new()
	effect_lbl.name = "PortraitEffect"
	effect_lbl.position = Vector2(10, 215)
	effect_lbl.size = Vector2(280, 35)
	effect_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	effect_lbl.add_theme_font_size_override("font_size", 11)
	effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_lbl.text = ""
	portrait_panel.add_child(effect_lbl)

	# 初始化动画状态
	portrait_breath_time = 0.0
	portrait_damage_flash = 0.0
	portrait_heal_glow = 0.0

# 职业对应颜色
func _get_job_color(job: int) -> Color:
	var colors = [
		Color(0.9, 0.3, 0.3),   # 战士 - 红色
		Color(0.3, 0.3, 1.0),   # 法师 - 蓝色
		Color(0.3, 0.8, 0.3),   # 猎人 - 绿色
		Color(0.7, 0.3, 0.9),   # 盗贼 - 紫色
		Color(0.3, 0.9, 0.5),   # 牧师 - 翠绿
		Color(0.5, 0.7, 0.95),  # 骑士 - 银蓝
		Color(0.95, 0.7, 0.2),  # 吟游诗人 - 金色
		Color(1.0, 0.4, 0.2)    # 召唤师 - 橙红
	]
	return colors[job] if job < colors.size() else PALETTE.gold

# 创建职业肖像纹理 (80×80像素艺术)
func _create_job_portrait_texture(job: int) -> ImageTexture:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cape_col = _get_job_color(job)  # 用职业色作为主色调
	var armor_col = _get_job_color(job) * Color(0.5, 0.5, 0.5, 1) + Color(0.5, 0.5, 0.5, 0)
	var skin_col = Color("#e8c8a0")
	var hair_col = Color("#2a1a0a")
	var white = Color.WHITE
	var black = Color.BLACK

	match job:
		Job.WARRIOR:
			# 战士: 重甲红披风
			_set_box(img, 20, 35, 60, 72, Color(0.4, 0.4, 0.5))  # 铠甲身体
			_set_box(img, 24, 38, 56, 68, Color(0.5, 0.5, 0.6))  # 铠甲高光
			_set_box(img, 15, 40, 22, 70, cape_col)  # 红色披风
			_set_box(img, 14, 42, 20, 65, cape_col * Color(0.8, 0.8, 0.8, 1))  # 披风褶皱
			_set_box(img, 58, 40, 65, 70, cape_col)  # 披风右
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 4, 52, 12, hair_col)  # 头发
			_set_box(img, 33, 14, 37, 16, black)  # 左眼
			_set_box(img, 43, 14, 47, 16, black)  # 右眼
			_set_box(img, 34, 15, 36, 15, white)  # 左眼高光
			_set_box(img, 44, 15, 46, 15, white)  # 右眼高光
			_set_line(img, 25, 35, 28, 35, Color(0.6, 0.6, 0.7))  # 肩甲
			_set_line(img, 52, 35, 55, 35, Color(0.6, 0.6, 0.7))  # 肩甲
			# 剑柄
			_set_line(img, 62, 20, 68, 14, Color(0.7, 0.7, 0.8))
			_set_line(img, 63, 21, 67, 21, Color(1.0, 0.8, 0.2))  # 剑格
		Job.MAGE:
			# 法师: 蓝袍,手持法杖
			_set_box(img, 22, 35, 58, 74, Color(0.15, 0.15, 0.45))  # 深蓝法袍
			_set_box(img, 24, 37, 56, 72, Color(0.2, 0.2, 0.55))  # 法袍高光
			_set_box(img, 18, 36, 26, 73, Color(0.15, 0.15, 0.4))  # 左侧袍
			_set_box(img, 54, 36, 62, 73, Color(0.15, 0.15, 0.4))  # 右侧袍
			_set_box(img, 26, 8, 54, 32, skin_col)  # 脸
			_set_box(img, 26, 3, 54, 10, hair_col)  # 头发(深色)
			_set_box(img, 32, 13, 36, 15, Color(0.2, 0.4, 1.0))  # 左眼蓝
			_set_box(img, 44, 13, 48, 15, Color(0.2, 0.4, 1.0))  # 右眼蓝
			_set_box(img, 33, 14, 35, 14, white)  # 左眼高光
			_set_box(img, 45, 14, 47, 14, white)  # 右眼高光
			# 魔法帽
			_set_triangle(img, 26, 8, 54, 8, 40, -8, Color(0.15, 0.15, 0.45))
			# 法杖
			_set_line(img, 65, 10, 65, 70, Color(0.5, 0.3, 0.1))
			_set_circle(img, 65, 8, 5, Color(0.3, 0.6, 1.0))  # 魔法球
			_set_circle(img, 65, 8, 3, white)  # 魔法球高光
		Job.HUNTER:
			# 猎人: 绿棕猎装,背弓
			_set_box(img, 24, 35, 56, 72, Color(0.25, 0.4, 0.2))  # 绿色猎装
			_set_box(img, 26, 37, 54, 70, Color(0.3, 0.45, 0.25))
			_set_box(img, 24, 35, 56, 72, Color(0.35, 0.25, 0.15))  # 棕色皮甲
			_set_box(img, 18, 38, 24, 65, Color(0.25, 0.4, 0.2))  # 斗篷左
			_set_box(img, 56, 38, 62, 65, Color(0.25, 0.4, 0.2))  # 斗篷右
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 4, 52, 10, Color(0.3, 0.2, 0.1))  # 棕色头发
			_set_box(img, 33, 14, 37, 16, black)  # 左眼
			_set_box(img, 43, 14, 47, 16, black)  # 右眼
			_set_box(img, 34, 15, 36, 15, white)
			_set_box(img, 44, 15, 46, 15, white)
			# 弓
			_set_line(img, 2, 15, 2, 65, Color(0.4, 0.25, 0.1))
			_set_line(img, 2, 15, 2, 65, Color(0.5, 0.35, 0.15), 2)  # 弓弦
		Job.THIEF:
			# 盗贼: 黑色夜行衣,双刃
			_set_box(img, 24, 35, 56, 72, Color(0.12, 0.12, 0.2))  # 黑色夜衣
			_set_box(img, 26, 37, 54, 70, Color(0.18, 0.18, 0.28))  # 夜衣高光
			_set_box(img, 16, 38, 24, 68, Color(0.15, 0.15, 0.25))  # 斗篷左
			_set_box(img, 56, 38, 64, 68, Color(0.15, 0.15, 0.25))  # 斗篷右
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 4, 52, 10, Color(0.1, 0.1, 0.15))  # 深色头发
			_set_box(img, 26, 5, 30, 8, Color(0.05, 0.05, 0.1))  # 兜帽
			_set_box(img, 50, 5, 54, 8, Color(0.05, 0.05, 0.1))  # 兜帽
			_set_box(img, 33, 14, 37, 16, Color(0.9, 0.7, 0.1))  # 左眼(金色)
			_set_box(img, 43, 14, 47, 16, Color(0.9, 0.7, 0.1))  # 右眼(金色)
			_set_box(img, 34, 15, 36, 15, white)
			_set_box(img, 44, 15, 46, 15, white)
			# 双匕首
			_set_line(img, 6, 35, 6, 55, Color(0.7, 0.7, 0.8))
			_set_line(img, 74, 35, 74, 55, Color(0.7, 0.7, 0.8))
		Job.PRIEST:
			# 牧师: 白色长袍,金色圣徽
			_set_box(img, 22, 35, 58, 74, Color(0.9, 0.9, 0.95))  # 白色法袍
			_set_box(img, 24, 37, 56, 72, Color(0.95, 0.95, 1.0))  # 法袍高光
			_set_box(img, 18, 36, 26, 73, Color(0.85, 0.85, 0.9))  # 左袖
			_set_box(img, 54, 36, 62, 73, Color(0.85, 0.85, 0.9))  # 右袖
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 4, 52, 10, Color(0.8, 0.7, 0.4))  # 金发
			# 圣环
			_set_circle_line(img, 40, 6, 18, Color(1.0, 0.85, 0.3), 2)
			_set_box(img, 33, 14, 37, 16, Color(0.2, 0.4, 1.0))  # 左眼蓝
			_set_box(img, 43, 14, 47, 16, Color(0.2, 0.4, 1.0))  # 右眼蓝
			_set_box(img, 34, 15, 36, 15, white)
			_set_box(img, 44, 15, 46, 15, white)
			# 圣徽
			_set_box(img, 35, 36, 45, 48, Color(1.0, 0.85, 0.2))
			_set_box(img, 37, 38, 43, 46, Color(1.0, 0.9, 0.4))
			# 十字架
			_set_line(img, 40, 37, 40, 47, Color(1.0, 0.85, 0.2), 3)
			_set_line(img, 36, 41, 44, 41, Color(1.0, 0.85, 0.2), 3)
		Job.KNIGHT:
			# 骑士: 全身板甲,蓝披风
			_set_box(img, 20, 35, 60, 74, Color(0.4, 0.45, 0.55))  # 银色板甲
			_set_box(img, 22, 37, 58, 72, Color(0.5, 0.55, 0.65))  # 板甲高光
			_set_box(img, 15, 40, 22, 72, cape_col)  # 蓝色披风
			_set_box(img, 14, 42, 20, 68, cape_col * Color(0.7, 0.7, 0.7, 1))  # 披风褶皱
			_set_box(img, 58, 40, 65, 72, cape_col)  # 披风右
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 3, 52, 10, Color(0.3, 0.3, 0.35))  # 头发
			_set_box(img, 28, 4, 52, 6, Color(0.4, 0.4, 0.45))  # 头盔顶
			_set_box(img, 33, 14, 37, 16, black)  # 左眼(头盔缝)
			_set_box(img, 43, 14, 47, 16, black)  # 右眼
			_set_line(img, 25, 35, 28, 35, Color(0.6, 0.65, 0.75))  # 肩甲
			_set_line(img, 52, 35, 55, 35, Color(0.6, 0.65, 0.75))
			# 盾牌
			_set_line(img, 2, 40, 2, 65, Color(0.35, 0.4, 0.5), 10)
			_set_line(img, 4, 42, 4, 63, cape_col, 6)  # 盾牌蓝心
		Job.BARD:
			# 吟游诗人: 彩色斗篷,琵琶
			_set_box(img, 22, 35, 58, 74, Color(0.7, 0.35, 0.2))  # 棕色外套
			_set_box(img, 24, 37, 56, 72, Color(0.8, 0.4, 0.25))  # 外套高光
			_set_box(img, 18, 38, 26, 72, cape_col)  # 彩色斗篷
			_set_box(img, 54, 38, 62, 72, cape_col * Color(0.6, 0.6, 0.8, 1))  # 斗篷另一色
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 4, 52, 10, Color(0.5, 0.35, 0.2))  # 棕色头发
			_set_box(img, 33, 14, 37, 16, black)  # 左眼
			_set_box(img, 43, 14, 47, 16, black)  # 右眼
			_set_box(img, 34, 15, 36, 15, white)
			_set_box(img, 44, 15, 46, 15, white)
			# 琵琶
			_set_line(img, 65, 25, 68, 60, Color(0.4, 0.25, 0.1))
			_set_circle(img, 66, 62, 8, Color(0.5, 0.3, 0.15))  # 琴身
			_set_line(img, 66, 54, 66, 62, Color(0.3, 0.2, 0.1), 2)
			# 音符装饰
			_set_circle(img, 8, 15, 4, Color(0.8, 0.7, 0.2))
			_set_line(img, 12, 11, 12, 18, Color(0.8, 0.7, 0.2), 2)
			_set_circle(img, 16, 22, 3, Color(0.8, 0.7, 0.2))
			_set_line(img, 19, 19, 19, 24, Color(0.8, 0.7, 0.2), 2)
		Job.SUMMONER:
			# 召唤师: 暗紫袍,符文,魔法球
			_set_box(img, 22, 35, 58, 74, Color(0.3, 0.1, 0.35))  # 暗紫色袍
			_set_box(img, 24, 37, 56, 72, Color(0.4, 0.15, 0.45))  # 紫袍高光
			_set_box(img, 18, 36, 26, 73, Color(0.25, 0.08, 0.3))  # 左侧袍
			_set_box(img, 54, 36, 62, 73, Color(0.25, 0.08, 0.3))  # 右侧袍
			_set_box(img, 28, 8, 52, 32, skin_col)  # 脸
			_set_box(img, 28, 3, 52, 10, Color(0.15, 0.05, 0.2))  # 深紫发
			_set_box(img, 33, 14, 37, 16, Color(0.9, 0.2, 0.8))  # 左眼紫红
			_set_box(img, 43, 14, 47, 16, Color(0.9, 0.2, 0.8))  # 右眼紫红
			_set_box(img, 34, 15, 36, 15, white)
			_set_box(img, 44, 15, 46, 15, white)
			# 符文项链
			_set_line(img, 30, 33, 50, 33, Color(0.8, 0.2, 0.9), 2)
			_set_circle(img, 40, 33, 4, Color(0.6, 0.1, 0.7))
			_set_circle(img, 40, 33, 2, Color(1.0, 0.5, 1.0))
			# 法杖 + 魔法球
			_set_line(img, 64, 10, 64, 68, Color(0.3, 0.2, 0.1))
			_set_circle(img, 64, 8, 6, Color(0.8, 0.2, 0.9))  # 紫色魔法球
			_set_circle(img, 64, 8, 4, Color(1.0, 0.5, 1.0))  # 高光
			# 魔法符文装饰
			_set_line(img, 10, 25, 15, 20, Color(0.7, 0.2, 0.8), 2)
			_set_line(img, 15, 25, 10, 20, Color(0.7, 0.2, 0.8), 2)
			_set_circle(img, 12, 22, 2, Color(0.5, 0.1, 0.6))

	var tex = ImageTexture.create_from_image(img)
	return tex

# 肖像阴影纹理
func _create_portrait_shadow() -> ImageTexture:
	var img = Image.create(80, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx = 40; var cy = 10
	var rx = 30; var ry = 8
	for x in range(80):
		for y in range(20):
			var dx = float(x - cx) / rx
			var dy = float(y - cy) / ry
			var d = dx*dx + dy*dy
			if d <= 1.0:
				var alpha = max(0.0, 1.0 - d) * 0.25
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	var tex = ImageTexture.create_from_image(img)
	return tex

# 肖像闪红/绿特效
func _create_portrait_flash(col: Color) -> ImageTexture:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 红色叠加层
	for x in range(80):
		for y in range(80):
			var dist = sqrt(pow(x-40, 2) + pow(y-40, 2))
			if dist < 35:
				var alpha = (1.0 - dist/35.0) * 0.6
				img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
	var tex = ImageTexture.create_from_image(img)
	return tex

# 辅助绘图函数
func _set_box(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color):
	for x in range(max(0,x1), min(80,x2+1)):
		for y in range(max(0,y1), min(80,y2+1)):
			img.set_pixel(x, y, col)

func _set_triangle(img: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, col: Color):
	# 三角形填充 (x1,y1)-(x2,y2)-(x3,y3)
	var min_y = int(min(y1, min(y2, y3)))
	var max_y = int(max(y1, max(y2, y3)))
	for y in range(max(0, min_y), min(80, max_y + 1)):
		var intersections: Array = []
		# 与边的交点
		if y1 != y2:
			var t = float(y - y1) / float(y2 - y1)
			if t >= 0 and t <= 1:
				intersections.append(x1 + (x2 - x1) * t)
		if y1 != y3:
			var t = float(y - y1) / float(y3 - y1)
			if t >= 0 and t <= 1:
				intersections.append(x1 + (x3 - x1) * t)
		if y2 != y3:
			var t = float(y - y2) / float(y3 - y2)
			if t >= 0 and t <= 1:
				intersections.append(x2 + (x3 - x2) * t)
		if intersections.size() >= 2:
			var x_start = int(min(intersections[0], intersections[1]))
			var x_end = int(max(intersections[0], intersections[1]))
			for x in range(max(0, x_start), min(80, x_end + 1)):
				img.set_pixel(x, y, col)

func _set_line(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color, thick: int = 1):
	var dx = x2 - x1; var dy = y2 - y1
	var steps = max(abs(dx), abs(dy))
	for i in range(steps + 1):
		var t = float(i) / max(1, steps)
		var x = int(x1 + dx * t)
		var y = int(y1 + dy * t)
		for tx in range(-thick+1, thick):
			for ty in range(-thick+1, thick):
				var px = x + tx; var py = y + ty
				if px >= 0 and px < 80 and py >= 0 and py < 80:
					img.set_pixel(px, py, col)

func _set_circle(img: Image, cx: int, cy: int, r: int, col: Color):
	for x in range(cx-r-1, cx+r+2):
		for y in range(cy-r-1, cy+r+2):
			var dist = sqrt(pow(x-cx, 2) + pow(y-cy, 2))
			if dist <= r:
				img.set_pixel(x, y, col)

func _set_circle_line(img: Image, cx: int, cy: int, r: int, col: Color, thick: int = 1):
	for x in range(cx-r-1, cx+r+2):
		for y in range(cy-r-1, cy+r+2):
			var dist = sqrt(pow(x-cx, 2) + pow(y-cy, 2))
			if abs(dist - r) <= thick:
				img.set_pixel(x, y, col)



func _create_action_button(text: String, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(120, 55)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", PALETTE.gold)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = PALETTE.gold
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("normal", style)
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	hover_style.border_color = PALETTE.gold
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.corner_radius_top_left = 3
	hover_style.corner_radius_top_right = 3
	hover_style.corner_radius_bottom_right = 3
	hover_style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("hover", hover_style)
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	pressed_style.border_color = PALETTE.gold
	pressed_style.border_width_left = 1
	pressed_style.border_width_top = 1
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	pressed_style.corner_radius_top_left = 3
	pressed_style.corner_radius_top_right = 3
	pressed_style.corner_radius_bottom_right = 3
	pressed_style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("pressed", pressed_style)
	return btn

func _create_hp_bar_bg() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.05)
	style.border_color = Color(0.4, 0.2, 0.2)
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_hp_bar_fill() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.15, 0.15)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_elite_hp_bar_fill() -> StyleBoxFlat:
	# 精英敌人HP条 - 金色渐变
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.7, 0.1)  # 金色
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_hp_bar_fill_mp() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.35, 0.85)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

# 敌人类型到豆包素材的映射
const ENEMY_ASSETS = {
	"skeleton_warrior": "res://assets/doubao/skeleton_warrior.png",
	"demon_red": "res://assets/doubao/demon_red.png",
	# 其他敌人使用默认程序生成
}


func _load_enemy_texture(enemy_type: String) -> Texture2D:
	# 尝试加载豆包素材
	var path = ENEMY_ASSETS.get(enemy_type, "")
	if path != "":
		var tex = load(path)
		if tex:
			return tex
	return null


func _create_enemy_texture(col: Color) -> Texture2D:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match current_enemy["name"]:
		# ===== 1-2层:草寇势力 =====
		"劫道山贼":
			# 劫道山贼(粗犷黑衣人)
			_set_pixel_line(img, 10, 4, 22, 4, col)  # 头巾
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 10, Color.BLACK)  # 眉毛(凶)
			img.set_pixel(18, 10, Color.BLACK)
			img.set_pixel(14, 12, Color.YELLOW)  # 眼睛
			img.set_pixel(18, 12, Color.YELLOW)
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 络腮胡
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 身(短打)
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(2, 22, col)  # 朴刀
			img.set_pixel(4, 20, col)
			img.set_pixel(4, 24, col)
		"荒野土匪":
			# 荒野土匪(体毛旺盛的大汉)
			_set_pixel_line(img, 8, 4, 24, 4, col)  # 乱发
			_set_pixel_line(img, 10, 8, 22, 8, col)  # 头顶
			img.set_pixel(13, 10, Color.RED)  # 凶狠眼
			img.set_pixel(19, 10, Color.RED)
			_set_pixel_line(img, 8, 14, 24, 14, col)  # 络腮胡
			_set_pixel_line(img, 6, 18, 26, 18, col)  # 宽肩
			_set_pixel_line(img, 4, 28, 12, 28, col)  # 粗腿
			_set_pixel_line(img, 20, 28, 28, 28, col)
			img.set_pixel(0, 16, col)  # 双刀
			img.set_pixel(2, 14, col)
			img.set_pixel(2, 18, col)
			img.set_pixel(30, 16, col)
			img.set_pixel(28, 14, col)
			img.set_pixel(28, 18, col)
		"逃兵":
			# 逃兵(破损铠甲的士兵)
			_set_pixel_line(img, 12, 4, 20, 4, col)  # 头盔(歪)
			img.set_pixel(10, 6, col)
			_set_pixel_line(img, 10, 10, 22, 10, col)  # 脸
			img.set_pixel(13, 12, Color.GRAY)  # 惊恐眼神
			img.set_pixel(19, 12, Color.GRAY)
			_set_pixel_line(img, 8, 16, 24, 16, col)  # 破甲
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 身
			_set_pixel_line(img, 6, 24, 12, 24, col)  # 断腿甲
			_set_pixel_line(img, 20, 24, 26, 24, col)
			img.set_pixel(14, 28, col)  # 跛脚
			img.set_pixel(16, 28, col)
		# ===== 3-4层:邪派势力 =====
		"血刀门弟子":
			# 血刀门弟子(血红披风)
			_set_pixel_line(img, 14, 4, 18, 4, col)  # 发髻
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.BLACK)  # 眼
			img.set_pixel(18, 11, Color.BLACK)
			img.set_pixel(14, 12, Color.ORANGE)  # 杀气
			img.set_pixel(18, 12, Color.ORANGE)
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 脸
			_set_pixel_line(img, 8, 18, 12, 18, Color.DARK_RED)  # 血红围巾
			_set_pixel_line(img, 20, 18, 24, 18, Color.DARK_RED)
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 身
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(2, 18, Color.SILVER)  # 血刀
			img.set_pixel(4, 16, Color.SILVER)
			img.set_pixel(4, 20, Color.SILVER)
		"日月神教教徒":
			# 日月神教教徒(金黑袍)
			_set_pixel_line(img, 14, 4, 18, 4, Color.GOLD)  # 金冠
			img.set_pixel(14, 4, Color.GOLD)
			img.set_pixel(18, 4, Color.GOLD)
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.YELLOW)  # 眼睛
			img.set_pixel(18, 11, Color.YELLOW)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 10, 18, 22, 18, Color.GOLD)  # 金腰带
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 袍子
			_set_pixel_line(img, 6, 26, 26, 26, col)  # 袍下
			img.set_pixel(16, 8, Color.GOLD)  # 太阳纹
		"五毒教教徒":
			# 五毒教教徒(青绿毒师)
			_set_pixel_line(img, 12, 4, 20, 4, col)  # 蛇形头饰
			img.set_pixel(10, 4, col)
			img.set_pixel(22, 4, col)
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.LIME_GREEN)  # 毒眼
			img.set_pixel(18, 11, Color.LIME_GREEN)
			img.set_pixel(14, 12, Color.BLACK)
			img.set_pixel(18, 12, Color.BLACK)
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 脸
			_set_pixel_line(img, 8, 18, 24, 18, col)  # 身
			_set_pixel_line(img, 6, 24, 12, 24, col)  # 袍
			_set_pixel_line(img, 20, 24, 26, 24, col)
			img.set_pixel(16, 4, Color.LIME_GREEN)  # 蛇眼
		# ===== 5-6层:江湖散人 =====
		"江湖刺客":
			# 江湖刺客(黑衣蒙面)
			_set_pixel_line(img, 12, 4, 20, 4, col)  # 兜帽顶
			_set_pixel_line(img, 10, 8, 22, 8, col)  # 兜帽
			img.set_pixel(14, 11, Color.RED)  # 杀气红眼
			img.set_pixel(18, 11, Color.RED)
			_set_pixel_line(img, 12, 14, 20, 14, Color.DIM_GRAY)  # 蒙面
			_set_pixel_line(img, 10, 16, 22, 16, col)  # 披风
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 身
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 蹲伏腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(0, 20, Color.SILVER)  # 双匕首
			img.set_pixel(2, 18, Color.SILVER)
			img.set_pixel(30, 20, Color.SILVER)
			img.set_pixel(28, 18, Color.SILVER)
		"赏金猎人":
			# 赏金猎人(皮甲猎装)
			_set_pixel_line(img, 12, 4, 20, 4, Color.BROWN)  # 皮帽
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.GREEN)  # 锐利眼
			img.set_pixel(18, 11, Color.GREEN)
			_set_pixel_line(img, 12, 14, 20, 14, Color.BROWN)  # 皮甲
			_set_pixel_line(img, 8, 18, 24, 18, Color.BROWN)  # 皮背心
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(28, 14, Color.GRAY)  # 弩
			img.set_pixel(30, 12, Color.GRAY)
			img.set_pixel(30, 16, Color.GRAY)
		"擂台霸主":
			# 擂台霸主(肌肉猛男)
			_set_pixel_line(img, 14, 4, 18, 4, col)  # 短发
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 10, Color.ORANGE)  # 怒目
			img.set_pixel(18, 10, Color.ORANGE)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 10, 18, 22, 18, col)  # 肌肉上身
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 宽腰
			_set_pixel_line(img, 6, 26, 26, 26, col)  # 短裤
			img.set_pixel(4, 22, col)  # 缠手绷带
			img.set_pixel(4, 24, col)
			img.set_pixel(26, 22, col)
			img.set_pixel(26, 24, col)
		# ===== 7-8层:门派精英 =====
		"少林弟子":
			# 少林弟子(黄色僧袍)
			_set_pixel_line(img, 14, 4, 18, 4, Color.GOLD)  # 僧帽
			img.set_pixel(12, 4, Color.GOLD)
			img.set_pixel(20, 4, Color.GOLD)
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.BLACK)  # 眼
			img.set_pixel(18, 11, Color.BLACK)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 10, 18, 22, 18, Color.GOLD)  # 袈裟
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 僧袍
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(4, 16, Color.BROWN)  # 少林棍
			img.set_pixel(4, 18, Color.BROWN)
			img.set_pixel(4, 20, Color.BROWN)
			img.set_pixel(4, 22, Color.BROWN)
		"武当弟子":
			# 武当弟子(青白道袍)
			_set_pixel_line(img, 14, 4, 18, 4, col)  # 发髻
			img.set_pixel(16, 4, Color.WHITE)
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			img.set_pixel(14, 11, Color.CYAN)  # 清澈眼
			img.set_pixel(18, 11, Color.CYAN)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 10, 18, 22, 18, Color.WHITE)  # 白腰带
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 道袍
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(2, 18, Color.SILVER)  # 剑柄
			img.set_pixel(0, 16, Color.SILVER)
			img.set_pixel(0, 20, Color.SILVER)
		"隐世高手":
			# 隐世高手(锦袍白发老者)
			_set_pixel_line(img, 12, 4, 20, 4, Color.WHITE)  # 白发
			img.set_pixel(10, 4, Color.WHITE)
			img.set_pixel(22, 4, Color.WHITE)
			_set_pixel_line(img, 12, 8, 20, 8, Color.WHITE)
			img.set_pixel(14, 10, Color.PURPLE)  # 深邃眼
			img.set_pixel(18, 10, Color.PURPLE)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 8, 18, 24, 18, Color.GOLD)  # 金纹
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 锦袍
			_set_pixel_line(img, 6, 28, 26, 28, col)  # 宽袍下
			img.set_pixel(4, 18, Color.GOLD)  # 折扇
			img.set_pixel(6, 16, Color.GOLD)
			img.set_pixel(6, 20, Color.GOLD)
		# ===== Boss敌人 =====
		"山贼王·韩霸天":
			# 山贼王(巨型光头大汉)
			_set_pixel_line(img, 10, 4, 22, 4, Color.BROWN)  # 头巾
			_set_pixel_line(img, 8, 8, 24, 8, col)  # 光头
			img.set_pixel(12, 10, Color.RED)  # 怒目
			img.set_pixel(20, 10, Color.RED)
			_set_pixel_line(img, 8, 14, 24, 14, col)  # 络腮胡
			_set_pixel_line(img, 4, 18, 28, 18, col)  # 虎背
			_set_pixel_line(img, 2, 24, 30, 24, col)  # 宽腰
			_set_pixel_line(img, 0, 28, 14, 28, col)  # 粗腿
			_set_pixel_line(img, 18, 28, 31, 28, col)
			img.set_pixel(0, 14, Color.GRAY)  # 开山刀
			img.set_pixel(2, 12, Color.GRAY)
			img.set_pixel(2, 16, Color.GRAY)
		"血刀门护法·血手赫连铁树":
			# 血刀门护法(血红色霸气)
			_set_pixel_line(img, 12, 4, 20, 4, Color.BLACK)  # 发髻
			img.set_pixel(16, 4, col)
			_set_pixel_line(img, 10, 8, 22, 8, col)  # 头顶
			img.set_pixel(13, 11, Color.ORANGE)  # 血红眼
			img.set_pixel(19, 11, Color.ORANGE)
			img.set_pixel(13, 12, Color.RED)
			img.set_pixel(19, 12, Color.RED)
			_set_pixel_line(img, 10, 16, 22, 16, col)  # 脸
			_set_pixel_line(img, 6, 18, 26, 18, Color.DARK_RED)  # 血围巾
			_set_pixel_line(img, 4, 22, 28, 22, col)  # 身
			_set_pixel_line(img, 2, 28, 14, 28, col)  # 腿
			_set_pixel_line(img, 18, 28, 30, 28, col)
			img.set_pixel(0, 18, Color.SILVER)  # 血刀(巨)
			img.set_pixel(2, 14, Color.SILVER)
			img.set_pixel(2, 16, Color.SILVER)
			img.set_pixel(2, 20, Color.SILVER)
			img.set_pixel(2, 22, Color.SILVER)
		"门派叛徒·司马青云":
			# 门派叛徒(紫袍飘逸)
			_set_pixel_line(img, 14, 4, 18, 4, Color.PURPLE)  # 发冠
			_set_pixel_line(img, 12, 8, 20, 8, Color.PURPLE)  # 头顶
			img.set_pixel(14, 11, Color.PURPLE)  # 阴沉眼
			img.set_pixel(18, 11, Color.PURPLE)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸
			_set_pixel_line(img, 8, 18, 24, 18, Color.PURPLE)  # 紫袍
			_set_pixel_line(img, 6, 22, 26, 22, col)  # 袍身
			_set_pixel_line(img, 4, 28, 28, 28, col)  # 飘带效果
			img.set_pixel(30, 24, Color.PURPLE)  # 飘带
			img.set_pixel(30, 26, Color.PURPLE)
			img.set_pixel(28, 22, Color.SILVER)  # 剑柄
			img.set_pixel(30, 20, Color.SILVER)
		"华山掌门·岳不群":
			# 华山掌门(君子剑外表)
			_set_pixel_line(img, 14, 4, 18, 4, Color.GOLD)  # 发冠
			img.set_pixel(16, 4, Color.WHITE)
			_set_pixel_line(img, 12, 8, 20, 8, Color.GOLD)  # 头顶
			img.set_pixel(14, 11, Color.CYAN)  # 正派眼神
			img.set_pixel(18, 11, Color.CYAN)
			img.set_pixel(14, 12, Color.WHITE)
			img.set_pixel(18, 12, Color.WHITE)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸(和善)
			_set_pixel_line(img, 10, 18, 22, 18, Color.WHITE)  # 白衫
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 君子袍
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿
			_set_pixel_line(img, 20, 28, 26, 28, col)
			img.set_pixel(2, 18, Color.SILVER)  # 君子剑
			img.set_pixel(0, 16, Color.SILVER)
			img.set_pixel(0, 20, Color.SILVER)
			img.set_pixel(0, 22, Color.SILVER)
		"武当真人·张三丰":
			# 武当真人·张三丰(白发道袍仙风道骨)
			_set_pixel_line(img, 10, 4, 22, 4, Color.WHITE)  # 白发
			img.set_pixel(8, 4, Color.WHITE)
			img.set_pixel(24, 4, Color.WHITE)
			img.set_pixel(16, 4, Color.GOLD)  # 道簪
			_set_pixel_line(img, 10, 8, 22, 8, Color.WHITE)  # 头顶
			img.set_pixel(14, 10, Color.CYAN)  # 仙风眼
			img.set_pixel(18, 10, Color.CYAN)
			img.set_pixel(14, 11, Color.WHITE)
			img.set_pixel(18, 11, Color.WHITE)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸(长须)
			_set_pixel_line(img, 12, 16, 20, 16, Color.WHITE)  # 胡须
			_set_pixel_line(img, 8, 18, 24, 18, Color.WHITE)  # 白道袍
			_set_pixel_line(img, 6, 22, 26, 22, col)  # 青道袍
			_set_pixel_line(img, 4, 28, 28, 28, col)  # 袍下
			img.set_pixel(2, 20, Color.SILVER)  # 拂尘柄
			img.set_pixel(0, 18, Color.WHITE)  # 拂尘毛
			img.set_pixel(0, 22, Color.WHITE)
			img.set_pixel(4, 16, Color.GOLD)  # 腰带扣
			img.set_pixel(4, 18, Color.GOLD)

	var texture = ImageTexture.create_from_image(img)
	return texture

var _skill_menu_open: bool = false

# 技能冷却数据(回合数,0=无冷却)
var _SKILL_COOLDOWNS: Dictionary = {
	# 战士 T1
	"猛击": 1, "防御": 0, "冲锋": 3,
	# 战士 T2 (狂战士路线)
	"血之狂暴": 4, "旋风斩": 3, "战吼": 3,
	# 法师 T1
	"火球": 1, "冰霜": 1, "闪电": 2,
	# 法师 T2 (元素大师)
	"流星火雨": 4, "霜冻领域": 3, "连锁闪电": 3,
	# 法师 T2 (奥术师)
	"魔法盾": 3, "法术穿透": 3, "魔力回旋": 4,
	# 猎人 T1
	"狙击": 1, "陷阱": 0, "毒箭": 2,
	# 盗贼 T1
	"背刺": 1, "暗影": 2, "消失": 4,
	# 牧师 T1
	"治疗": 2, "护盾": 3, "复活": 6,
	# 骑士 T1
	"格挡": 1, "斩击": 1, "神圣": 3,
	# 吟游诗人 T1
	"鼓舞": 3, "旋律": 3, "沉默": 3,
	# 召唤师 T1
	"召唤": 3, "契约": 4, "共鸣": 2,
	# 猎人 T2
	"致命陷阱": 4, "猎豹加速": 3, "穿甲箭": 3,
	# 猎人 T3
	"一击脱离": 4, "万箭齐发": 4, "猎杀时刻": 5, "野兽之力": 6,
	# 盗贼 T2
	"影遁": 4, "淬毒利刃": 3, "锁喉": 4,
	# 盗贼 T3
	"影分身": 5, "绝杀": 4, "暗影之牙": 5,
	# 盗贼 T4 (觉醒技能)
	"千面杀手": 7, "暗影吞噬": 6, "幻惑领域": 6,
	# 牧师 T2
	"群体治疗": 5, "驱散": 3, "神圣仲裁": 4,
	# 骑士 T2
	"盾击": 3, "圣光审判": 4, "钢铁壁垒": 5,
	# 吟游诗人 T2
	"战斗乐章": 3, "疯狂节拍": 4, "天籁之音": 5,
	# 吟游诗人 T2 路线B 幻术师
	"催眠曲": 4, "幻听": 3, "混乱之音": 5,
	# 吟游诗人 T3
	"完美和弦": 5, "命运交响曲": 6, "终末安魂曲": 6,
	# 吟游诗人 T4
	"传奇之歌": 7, "虚空咏叹调": 6, "生命赞歌": 6,
	# 召唤师 T2
	"契约强化": 4, "灵魂连接": 3, "召唤兽强化": 4,
	# 法师 T3
	"陨石术": 6, "绝对零度": 5, "元素风暴": 5, "时间静止": 7,
	# 战士 T3 (毁灭者路线)
	"毁天灭地": 5, "不死不灭": 6, "碎甲": 3,
	# 战士 T3 (团队领袖路线)
	"战神领域": 5, "浴血奋战": 4, "援护": 2,
	# 战士 T4 (觉醒技能)
	"战神之力": 6, "绝对防御": 8, "征服者怒吼": 5,
	# 法师 T4 (觉醒技能)
	"元素湮灭": 8, "奥术真理": 6, "秘法编织": 7,
	# 牧师 T3
	"复活术": 6, "神圣领域": 5, "神圣裁定": 5, "生命之泉": 6,
	# 牧师 T4 (觉醒技能)
	"神迹": 8, "神圣审判": 7, "永恒庇护": 6,
	# 召唤师 T3 (终极技能·Lv25解锁)
	"究极召唤·天使": 7, "究极召唤·恶魔": 7, "召唤融合": 6,
	# 召唤师 T4 (觉醒技能·Lv40解锁)
	"万灵召唤": 8, "灵魂献祭": 7, "契约之魂": 7,
	# 骑士 T3 (终极技能·Lv25解锁)
	"神圣复仇": 5, "永恒守卫": 4, "圣光审判(全)": 5,
	# 骑士 T4 (觉醒技能·Lv40解锁)
	"天使守护": 7, "神圣之锤": 7, "正义执行": 6,
	# 猎人 T4 (觉醒技能·Lv40解锁)
	"死标记": 7, "自然之力": 5, "狩猎领域": 6
}

# 计算战斗中有效的攻击力(含buff加成)
func _get_effective_atk() -> int:
	var atk = player_data.attack_power()
	atk += battle_cry_atk_boost  # 战吼ATK加成
	atk += berserk_atk_boost     # 狂暴ATK加成
	atk += bard_song_atk_boost    # 战斗乐章ATK加成
	atk += bard_perfect_chord_atk_boost  # 完美和弦ATK+40%
	atk += bard_legendary_song_atk_boost  # 传奇之歌永久ATK+20
	atk += warrior_domain_atk_boost  # 战神领域ATK加成
	if arcane_truth_turns > 0:
		atk = int(atk * 1.5)  # 奥术真理:所有属性伤害+50%
	if hunter_nature_power_turns > 0:
		atk = int(atk * hunter_nature_power_bonus)  # 自然之力:每召唤物+30%伤害
	if knight_holy_hammer_turns > 0:
		atk = int(atk * knight_holy_hammer_mult)  # 神圣之锤:伤害×2持续3回合
	return atk

# 应用猎人标记伤害倍率
func _apply_hunter_mark(base_dmg: int) -> int:
	if hunter_mark_turns > 0:
		return int(base_dmg * hunter_mark_mult)
	return base_dmg

# 获取穿透后的防御值(法术穿透:无视敌人防御,消耗1层)
func _get_pierced_defense() -> int:
	# 穿甲箭:无视防御
	if hunter_armor_pierce_turns > 0:
		return 0
	# 法术穿透:无视防御
	if spell_pierce_turns > 0:
		spell_pierce_turns -= 1
		if spell_pierce_turns <= 0:
			_battle_add_log("💠 法术穿透效果消失")
		return 0  # 无视防御
	return current_enemy["def"]  # 正常防御

func _get_skill_cooldown(skill: String) -> int:
	return _SKILL_COOLDOWNS.get(skill, 1)

# 获取生命值最低的队友索引(用于骑士永恒守卫)
func _get_lowest_hp_ally_index() -> int:
	var lowest_idx = -1
	var lowest_hp_ratio = 999.0
	# 检查队伍成员(player是索引0)
	var allies = []
	if player_data.hp > 0:
		allies.append([0, float(player_data.hp) / player_data.max_hp])
	# 检查召唤物
	for i in range(active_summons.size()):
		var s = active_summons[i]
		if s.hp > 0:
			allies.append([10 + i, float(s.hp) / s.max_hp])
	for ally in allies:
		if ally[1] < lowest_hp_ratio:
			lowest_hp_ratio = ally[1]
			lowest_idx = ally[0]
	return lowest_idx

var _skill_menu_buttons: Array = []

func _on_skill_menu():
	if _skill_menu_open:
		_close_skill_menu()
		return
	_close_skill_menu()
	_skill_menu_open = true

	var action_panel = battle_ui.get_node("ActionPanel")
	var menu_panel = Panel.new()
	menu_panel.name = "SkillMenu"
	menu_panel.position = Vector2(170, -10)
	menu_panel.size = Vector2(300, 200)
	menu_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	menu_panel.add_theme_stylebox_override("panel", _create_stylebox())
	action_panel.add_child(menu_panel)

	var title = Label.new()
	title.position = Vector2(15, 10)
	title.text = "选择技能"
	title.add_theme_color_override("font_color", PALETTE.gold)
	menu_panel.add_child(title)

	var mp_cost: Dictionary = {
		"猛击": 10, "防御": 0, "冲锋": 20,
		"血之狂暴": 15, "旋风斩": 25, "战吼": 15,
		"火球": 15, "冰霜": 15, "闪电": 25,
		"流星火雨": 35, "霜冻领域": 30, "连锁闪电": 40,
		"魔法盾": 20, "法术穿透": 25, "魔力回旋": 30,
		"狙击": 10, "陷阱": 15, "毒箭": 20,
		"背刺": 15, "暗影": 20, "消失": 25,
		"治疗": 15, "护盾": 10, "复活": 50,
		"格挡": 0, "斩击": 15, "神圣": 25,
		"鼓舞": 10, "旋律": 15, "沉默": 20,
		"召唤": 20, "契约": 20, "共鸣": 25,
		"致命陷阱": 25, "猎豹加速": 20, "穿甲箭": 30,
		"一击脱离": 35, "万箭齐发": 50, "猎杀时刻": 40, "野兽之力": 45,
		"影遁": 25, "淬毒利刃": 25, "锁喉": 30,
		"影分身": 40, "绝杀": 45, "暗影之牙": 50,
		"千面杀手": 60, "暗影吞噬": 55, "幻惑领域": 50,
		"群体治疗": 35, "驱散": 20, "神圣仲裁": 35,
		"盾击": 15, "圣光审判": 30, "钢铁壁垒": 25,
		"战斗乐章": 20, "疯狂节拍": 35, "天籁之音": 40,
		"催眠曲": 25, "幻听": 30, "混乱之音": 40,
		"完美和弦": 50, "命运交响曲": 55, "终末安魂曲": 60,
		"传奇之歌": 70, "虚空咏叹调": 65, "生命赞歌": 60,
		"契约强化": 30, "灵魂连接": 30, "召唤兽强化": 25,
		# 法师 T3
		"陨石术": 60, "绝对零度": 55, "元素风暴": 70, "时间静止": 80,
		# 法师 T4 (觉醒技能)
		"元素湮灭": 100, "奥术真理": 60, "秘法编织": 50,
		# 牧师 T3
		"复活术": 60, "神圣领域": 55, "神圣裁定": 50, "生命之泉": 45,
		# 牧师 T4 (觉醒技能)
		"神迹": 80, "神圣审判": 70, "永恒庇护": 60,
		# 召唤师 T3 (终极技能·Lv25解锁)
		"究极召唤·天使": 60, "究极召唤·恶魔": 60, "召唤融合": 55,
		# 召唤师 T4 (觉醒技能·Lv40解锁)
		"万灵召唤": 80, "灵魂献祭": 70, "契约之魂": 75,
		# 骑士 T3 (终极技能·Lv25解锁)
		"神圣复仇": 50, "永恒守卫": 45, "圣光审判(全)": 55,
		# 骑士 T4 (觉醒技能·Lv40解锁)
		"天使守护": 70, "神圣之锤": 65, "正义执行": 60,
		# 猎人 T4 (觉醒技能·Lv40解锁)
		"死标记": 60, "自然之力": 55, "狩猎领域": 50
	}

	var skill_idx = 0
	for skill in player_data.skills:
		var cost = mp_cost.get(skill, 0)
		var cd_remaining = skill_cooldowns.get(skill, 0)
		var cd_total = _get_skill_cooldown(skill)
		# T2技能需要Lv10
		var t2_skills = [
			"血之狂暴", "旋风斩", "战吼",
			"流星火雨", "霜冻领域", "连锁闪电", "魔法盾", "法术穿透", "魔力回旋",
			"致命陷阱", "猎豹加速", "穿甲箭",
			"影遁", "淬毒利刃", "锁喉",
			"群体治疗", "驱散", "神圣仲裁",
			"盾击", "圣光审判", "钢铁壁垒",
			"战斗乐章", "疯狂节拍", "天籁之音",
			"催眠曲", "幻听", "混乱之音",
			"契约强化", "灵魂连接", "召唤兽强化"
		]
		var t3_skills = [
			"一击脱离", "万箭齐发", "猎杀时刻", "野兽之力",
			"影分身", "绝杀", "暗影之牙",
			"毁天灭地", "不死不灭", "碎甲",
			"战神领域", "浴血奋战", "援护",
			"陨石术", "绝对零度", "元素风暴", "时间静止",
			"完美和弦", "命运交响曲", "终末安魂曲",
			"复活术", "神圣领域", "神圣裁定", "生命之泉",
			"究极召唤·天使", "究极召唤·恶魔", "召唤融合",
			"神圣复仇", "永恒守卫", "圣光审判(全)"
		]
		var t4_skills = ["战神之力", "绝对防御", "征服者怒吼", "传奇之歌", "虚空咏叹调", "生命赞歌", "元素湮灭", "奥术真理", "秘法编织", "千面杀手", "暗影吞噬", "幻惑领域", "神迹", "神圣审判", "永恒庇护", "万灵召唤", "灵魂献祭", "契约之魂", "天使守护", "神圣之锤", "正义执行", "死标记", "自然之力", "狩猎领域"]
		var is_t2 = t2_skills.has(skill)
		var is_t3 = t3_skills.has(skill)
		var is_t4 = t4_skills.has(skill)
		var level_locked = (is_t2 and player_data.level < 10) or (is_t3 and player_data.level < 25) or (is_t4 and player_data.level < 40)
		var can_use = player_data.mp >= cost and cd_remaining <= 0 and not level_locked
		var row = skill_idx / 2
		var col = skill_idx % 2
		var sx = 15 + col * 140
		var sy = 45 + row * 55
		var sbtn = Button.new()
		var cd_text = ""
		if cd_total > 0:
			if cd_remaining > 0:
				cd_text = " [CD:%d]" % cd_remaining
			else:
				cd_text = " [OK]"
		var level_text = "Lv40" if is_t4 else ("Lv25" if is_t3 else (" Lv10" if is_t2 else ""))
		sbtn.text = skill + level_text + " (MP:" + str(cost) + ")" + cd_text
		sbtn.position = Vector2(sx, sy)
		sbtn.size = Vector2(130, 48)
		sbtn.add_theme_font_size_override("font_size", 13)
		var sstyle = StyleBoxFlat.new()
		sstyle.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		if level_locked:
			sstyle.border_color = Color(0.2, 0.2, 0.4)  # 深蓝色=等级不够
		elif cd_remaining > 0:
			sstyle.border_color = Color(0.5, 0.1, 0.1)  # 深红色=冷却中
		elif can_use:
			sstyle.border_color = PALETTE.gold
		else:
			sstyle.border_color = Color(0.3, 0.3, 0.3)
		sstyle.border_width_left = 1; sstyle.border_width_top = 1
		sstyle.border_width_right = 1; sstyle.border_width_bottom = 1
		sstyle.corner_radius_top_left = 3; sstyle.corner_radius_top_right = 3
		sstyle.corner_radius_bottom_right = 3; sstyle.corner_radius_bottom_left = 3
		sbtn.add_theme_stylebox_override("normal", sstyle)
		if level_locked:
			sbtn.add_theme_color_override("font_color", Color(0.25, 0.25, 0.5))  # 深蓝色=等级不够
		elif cd_remaining > 0:
			sbtn.add_theme_color_override("font_color", Color(0.5, 0.2, 0.2))  # 红色=冷却中
		elif can_use:
			sbtn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
		else:
			sbtn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))  # 灰色=MP不足
		if can_use:
			sbtn.pressed.connect(_on_skill_selected.bind(skill))
		menu_panel.add_child(sbtn)
		_skill_menu_buttons.append(sbtn)
		skill_idx += 1

func _close_skill_menu():
	_skill_menu_open = false
	var action_panel = battle_ui.get_node_or_null("ActionPanel")
	if action_panel:
		var menu = action_panel.get_node_or_null("SkillMenu")
		if menu:
			menu.queue_free()
	_skill_menu_buttons.clear()

async func _on_skill_selected(skill_name: String):
	_close_skill_menu()
	if not is_player_turn:
		return
	# 消耗MP
	var mp_cost: Dictionary = {
		"猛击": 10, "防御": 0, "冲锋": 20,
		"血之狂暴": 15, "旋风斩": 25, "战吼": 15,
		"火球": 15, "冰霜": 15, "闪电": 25,
		"流星火雨": 35, "霜冻领域": 30, "连锁闪电": 40,
		"魔法盾": 20, "法术穿透": 25, "魔力回旋": 30,
		"狙击": 10, "陷阱": 15, "毒箭": 20,
		"背刺": 15, "暗影": 20, "消失": 25,
		"治疗": 15, "护盾": 10, "复活": 50,
		"格挡": 0, "斩击": 15, "神圣": 25,
		"鼓舞": 10, "旋律": 15, "沉默": 20,
		"召唤": 20, "契约": 20, "共鸣": 25,
		"致命陷阱": 25, "猎豹加速": 20, "穿甲箭": 30,
		"一击脱离": 35, "万箭齐发": 50, "猎杀时刻": 40, "野兽之力": 45,
		"影遁": 25, "淬毒利刃": 25, "锁喉": 30,
		"群体治疗": 35, "驱散": 20, "神圣仲裁": 35,
		"盾击": 15, "圣光审判": 30, "钢铁壁垒": 25,
		"战斗乐章": 20, "疯狂节拍": 35, "天籁之音": 40,
		"催眠曲": 25, "幻听": 30, "混乱之音": 40,
		"完美和弦": 50, "命运交响曲": 55, "终末安魂曲": 60,
		"传奇之歌": 70, "虚空咏叹调": 65, "生命赞歌": 60,
		"契约强化": 30, "灵魂连接": 30, "召唤兽强化": 25,
		# 盗贼 T3
		"影分身": 40, "绝杀": 45, "暗影之牙": 50,
		# 盗贼 T4 (觉醒技能)
		"千面杀手": 60, "暗影吞噬": 55, "幻惑领域": 50,
		# 战士 T3 (毁灭者路线)
		"毁天灭地": 50, "不死不灭": 40, "碎甲": 30,
		# 战士 T3 (团队领袖路线)
		"战神领域": 45, "浴血奋战": 35, "援护": 20,
		# 战士 T4 (觉醒技能)
		"战神之力": 60, "绝对防御": 50, "征服者怒吼": 40,
		# 法师 T3
		"陨石术": 60, "绝对零度": 55, "元素风暴": 70, "时间静止": 80,
		# 法师 T4 (觉醒技能)
		"元素湮灭": 100, "奥术真理": 60, "秘法编织": 50,
		# 牧师 T3
		"复活术": 60, "神圣领域": 55, "神圣裁定": 50, "生命之泉": 45,
		# 牧师 T4 (觉醒技能)
		"神迹": 80, "神圣审判": 70, "永恒庇护": 60
	}
	var cost = mp_cost.get(skill_name, 0)
	if player_data.mp < cost:
		_battle_add_log("MP不足!")
		return
	player_data.mp -= cost
	pending_skill_index = -1

	# 检查冷却
	var cd = _get_skill_cooldown(skill_name)
	if cd > 0 and skill_cooldowns.get(skill_name, 0) > 0:
		player_data.mp += cost  #  refunded
		_battle_add_log("⚠️ %s 冷却中(还需%d回合)!" % [skill_name, skill_cooldowns[skill_name]])
		return

	match skill_name:
		# 战士
		"猛击":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_medium(int(_get_effective_atk() * 1.5)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 猛击!造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg)
		"防御":
			player_defending = true
			player_shield = int(player_data.defense() * 0.5)
			player_data.mp = min(player_data.max_mp, player_data.mp + 5)
			_battle_add_log("🛡️ 防御姿态!伤害减半,回复5MP")
		"冲锋":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 2.5)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			enemy_stun_turns = 1
			_battle_add_log("🐎 冲锋!造成 %d 伤害,敌人眩晕!" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -25))
		# 战士 T2 (狂战士路线)
		"血之狂暴":
			berserk_turns = 3
			berserk_atk_boost = int(_get_effective_atk() * 0.3)
			_battle_add_log("💢 血之狂暴!ATK+30%,每回合自损10HP,持续3回合")
			_spawn_player_damage("BERSERK!", "buff")
		"旋风斩":
			var hits = 2 + randi() % 3  # 2-4次攻击
			var total_dmg = 0
			for i in range(hits):
				var pierce_def = _get_pierced_defense()
				var hit_dmg = _roll_dmg_var_medium(int(_get_effective_atk() * 1.2)) - pierce_def
				hit_dmg = max(1, hit_dmg)
				current_enemy["hp"] -= hit_dmg
				total_dmg += hit_dmg
				await get_tree().create_timer(0.2).timeout
			_battle_add_log("🌀 旋风斩!连续攻击%d次,造成 %d 伤害!" % [hits, total_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % total_dmg, "crit", Vector2(0, -35))
		"战吼":
			battle_cry_turns = 2
			battle_cry_atk_boost = int(_get_effective_atk() * 0.4)
			battle_cry_team_boost = int(_get_effective_atk() * 0.15)
			_battle_add_log("📢 战吼!自身ATK+40%,持续2回合")
			_spawn_player_damage("ATK+40%", "buff")
		# 战士 T3 (毁灭者路线)
		"毁天灭地":
			var pierce_def = _get_pierced_defense()
			var base_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 4.0)) - pierce_def
			# 战神T4: 战神印记 - 目标受伤+30%
			if warrior_wargod_mark_turns > 0:
				base_dmg = int(base_dmg * 1.3)
			var dmg = max(1, base_dmg)
			# 30%概率秒杀HP<20%敌人
			var execute_chance = 30
			if current_enemy["hp"] < current_enemy["max_hp"] * 0.2 and randi() % 100 < execute_chance:
				current_enemy["hp"] = 0
				_battle_add_log("💀 毁天灭地!%s HP过低,被秒杀!" % current_enemy["name"])
				_critical_hit_effect()
				_spawn_enemy_damage("秒杀!", "crit", Vector2(0, -40))
			else:
				current_enemy["hp"] -= dmg
				_battle_add_log("💥 毁天灭地!造成 %d 伤害" % dmg)
				_enemy_hit_effect()
				_spawn_enemy_damage("%d" % dmg, "crit", Vector2(0, -35))
		"不死不灭":
			if warrior_undying_used:
				_battle_add_log("⚠️ 不死不灭本场战斗已触发!")
			else:
				warrior_undying_used = true
				_battle_add_log("🛡️ 不死不灭!设置完成:本场战斗中HP降至1时自动回复30%%HP(限1次)")
				_spawn_player_damage("不!死!", "shield")
		"碎甲":
			var pierce_def = _get_pierced_defense()
			var shatk = _get_effective_atk()
			# 战神领域加成
			shatk += warrior_domain_atk_boost
			# 战神T4: 战神印记 - 目标受伤+30%
			if warrior_wargod_mark_turns > 0:
				shatk = int(shatk * 1.3)
			var s_dmg = _roll_dmg_var_medium(int(shatk * 2.0)) - pierce_def
			s_dmg = max(1, s_dmg)
			current_enemy["hp"] -= s_dmg
			# 敌人DEF降低50%持续2回合
			warrior_shatter_turns = 2
			warrior_shatter_orig_def = current_enemy["def"]
			warrior_shatter_defdebuff = int(warrior_shatter_orig_def * 0.5)
			current_enemy["def"] = max(1, warrior_shatter_orig_def - warrior_shatter_defdebuff)
			_battle_add_log("⚔️ 碎甲!造成 %d 伤害,敌人DEF-50%%持续2回合" % s_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % s_dmg, "crit", Vector2(0, -35))
		# 战士 T3 (团队领袖路线)
		"战神领域":
			warrior_domain_turns = 3
			warrior_domain_atk_boost = int(_get_effective_atk() * 0.25)
			warrior_domain_def_boost = int(player_data.defense() * 0.15)
			_battle_add_log("⚔️ 战神领域!ATK+25%%、DEF+15%%持续3回合")
			_spawn_player_damage("战神领域!", "buff")
		"浴血奋战":
			warrior_bloodlust_active = true
			var hp_pct = float(player_data.hp) / float(player_data.max_hp)
			var bloodlust_mult = 1.0 + (1.0 - hp_pct) * 2.0  # HP越低倍率越高,最大3.0
			var batk = _get_effective_atk() + warrior_domain_atk_boost
			# 战神T4: 战神印记 - 目标受伤+30%
			if warrior_wargod_mark_turns > 0:
				batk = int(batk * 1.3)
			var b_dmg = _roll_dmg_var_medium(int(batk * bloodlust_mult)) - _get_pierced_defense()
			b_dmg = max(1, b_dmg)
			current_enemy["hp"] -= b_dmg
			_battle_add_log("🩸 浴血奋战!HP%d%%时ATK×%.1f,造成 %d 伤害" % [int(hp_pct*100), bloodlust_mult, b_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % b_dmg, "crit", Vector2(0, -35))
		"援护":
			warrior_guard_active = true
			warrior_guard_target_hp_pct = float(player_data.hp) / float(player_data.max_hp)
			_battle_add_log("🛡️ 援护!已锁定目标,下一次致命伤害由你承受")
			_spawn_player_damage("援护!", "shield")
		# ===== 战士 T4 (觉醒技能·Lv40解锁) =====
		"战神之力":
			# ATK × 6.0,附带"战神印记"(使目标受伤+30%持续3回合)
			var wg_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 6.0)) - _get_pierced_defense()
			wg_dmg = max(1, wg_dmg)
			# 战神印记在受到伤害时额外加成,这里首次打击也附带标记
			current_enemy["hp"] -= wg_dmg
			warrior_wargod_mark_turns = 3
			warrior_wargod_mark_dmg_boost = int(wg_dmg * 0.3)
			_battle_add_log("⚔️💥 战神之力!造成 %d 伤害,敌人获得「战神印记」受伤+30%%持续3回合" % wg_dmg)
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % wg_dmg, "crit", Vector2(0, -55))
		"绝对防御":
			# 5回合内免疫所有伤害,但无法行动
			warrior_absolute_def_turns = 5
			player_data.hp = max(1, player_data.hp)  # 确保HP不为0
			_battle_add_log("🏰⚔️ 绝对防御!5回合内免疫所有伤害,但无法行动")
			_spawn_player_damage("绝对防御!", "shield")
		"征服者怒吼":
			# ATK × 2.5 全体,恐惧效果:敌人-30%ATK持续3回合
			var conqueror_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 2.5)) - _get_pierced_defense()
			# 战神T4: 战神印记 - 目标受伤+30%
			if warrior_wargod_mark_turns > 0:
				conqueror_dmg = int(conqueror_dmg * 1.3)
			conqueror_dmg = max(1, conqueror_dmg)
			current_enemy["hp"] -= conqueror_dmg
			warrior_conqueror_fear_turns = 3
			warrior_conqueror_fear_atkdebuff = int(current_enemy["atk"] * 0.3)
			current_enemy["atk"] = max(1, current_enemy["atk"] - warrior_conqueror_fear_atkdebuff)
			_battle_add_log("😱⚔️ 征服者怒吼!造成 %d 伤害,敌人ATK-%d持续3回合,陷入恐惧!" % [conqueror_dmg, warrior_conqueror_fear_atkdebuff])
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % conqueror_dmg, "crit", Vector2(0, -50))
		# 法师
		"火球":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 2.0)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🔥 火球术!造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(randi()%20-10, -30))
		"冰霜":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 1.8)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			current_enemy["spd"] = max(1, current_enemy["spd"] - 2)
			_battle_add_log("❄️ 冰霜术!造成 %d 伤害,敌人速度降低!" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -20))
		"闪电":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 3.0)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚡ 闪电术!造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "crit", Vector2(0, -35))
		# 法师 T2 (元素大师路线)
		"流星火雨":
			var pierce_def = _get_pierced_defense()
			var burn_dmg = int(_get_effective_atk() * 0.8)
			current_enemy["hp"] -= burn_dmg
			meteor_burn_turns = 3
			meteor_burn_dmg = burn_dmg
			_battle_add_log("🌠 流星火雨!立即造成 %d 伤害,灼烧 %d 伤害/回合×3回合" % [burn_dmg, burn_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % burn_dmg, "crit", Vector2(0, -40))
		"霜冻领域":
			var pierce_def = _get_pierced_defense()
			var f_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 1.5)) - pierce_def
			f_dmg = max(1, f_dmg)
			current_enemy["hp"] -= f_dmg
			frost_slow_turns = 2
			_battle_add_log("❄️ 霜冻领域!造成 %d 伤害,敌人速度-50%%持续2回合" % f_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % f_dmg, "damage", Vector2(0, -25))
		"连锁闪电":
			var pierce_def = _get_pierced_defense()
			var chain_dmg1 = _roll_dmg_var_medium(int(_get_effective_atk() * 2.5)) - pierce_def
			chain_dmg1 = max(1, chain_dmg1)
			current_enemy["hp"] -= chain_dmg1
			_battle_add_log("⚡ 连锁闪电!造成 %d 伤害" % chain_dmg1)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % chain_dmg1, "crit", Vector2(0, -35))
			# 连锁效果:本回合内额外造成递减伤害
			await get_tree().create_timer(0.3).timeout
			var chain_dmg2_base = int(_get_effective_atk() * 1.5)
			chain_dmg2 = _roll_dmg_var_small(chain_dmg2_base) - _get_pierced_defense()
			chain_dmg2 = max(1, chain_dmg2)
			current_enemy["hp"] -= chain_dmg2
			_battle_add_log("⚡⚡ 闪电连锁!追加 %d 伤害" % chain_dmg2)
			_spawn_enemy_damage("%d" % chain_dmg2, "crit", Vector2(15, -20))
		# 法师 T2 (奥术师路线)
		"魔法盾":
			arcane_shield_mp = int(player_data.max_mp * 0.8)
			player_shield += arcane_shield_mp
			_battle_add_log("🔮 魔法盾!消耗 %d MP,护盾值+%d(下次受击时优先消耗)" % [arcane_shield_mp, arcane_shield_mp])
			_spawn_player_damage("+%d" % arcane_shield_mp, "shield")
		"法术穿透":
			spell_pierce_turns = 2
			_battle_add_log("💠 法术穿透!下2次攻击无视敌人防御")
			_spawn_player_damage("SPIERCE!", "buff")
		"魔力回旋":
			mana_drain_turns = 3
			mana_drain_amount = int(player_data.max_mp * 0.15)
			_battle_add_log("🌀 魔力回旋!持续3回合,每回合吸取 %d MP并恢复等量HP" % mana_drain_amount)
			_spawn_player_damage("DRAIN x3", "buff")
		# 猎人
		"狙击":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_medium(int(_get_effective_atk() * 2.0)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🎯 狙击!必定命中,造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "crit", Vector2(0, -30))
		"毒箭":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_medium(int(_get_effective_atk() * 1.5)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			poison_stacks += 1
			poison_damage = 5
			poison_turns = 3
			_battle_add_log("🏹 毒箭!造成 %d 伤害+每回合5毒性伤害×3回合" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "poison", Vector2(0, -25))
		# 盗贼
		"背刺":
			var is_crit = randi() % 100 < player_data.luk * 3
			var pierce_def = _get_pierced_defense()
			var base_dmg = _roll_dmg_var_medium(int(_get_effective_atk() * 2.2)) - pierce_def
			var dmg = max(1, base_dmg) * (2 if is_crit else 1)
			current_enemy["hp"] -= dmg
			var backstab_msg = "暴击!" if is_crit else ""
			_battle_add_log("🗡️ 背刺!" + backstab_msg + "造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			var backstab_dmg_type = "crit" if is_crit else "damage"
			var backstab_offset_x = (randi() % 15) - 7
			var backstab_offset_y = -30 if is_crit else -20
			_spawn_enemy_damage("%d" % dmg, backstab_dmg_type, Vector2(backstab_offset_x, backstab_offset_y))
		"暗影":
			var dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= dmg
			_battle_add_log("💀 暗影攻击!无视防御,造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -25))
		"消失":
			# 下回合必定先手+闪避
			vanish_turns = 1
			_battle_add_log("👤 消失!下回合敌人攻击时50%%几率闪避")
		# 牧师
		"治疗":
			var heal = int(player_data.max_hp * 0.4)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_trigger_portrait_heal_glow()
			_battle_add_log("💚 治疗!恢复 %d HP" % heal)
			_spawn_player_damage("+%d" % heal, "heal")
		"护盾":
			player_shield = int(player_data.defense() * 1.5)
			_battle_add_log("🛡️ 神圣护盾!获得 %d 护盾值" % player_shield)
			_spawn_player_damage("+%d" % player_shield, "shield")
		"复活":
			if player_data.hp <= 0:
				player_data.hp = int(player_data.max_hp * 0.5)
				_trigger_portrait_heal_glow()
				_battle_add_log("✨ 复活!恢复50% HP")
				_spawn_player_damage("REVIVE!", "heal")
			else:
				player_data.mp -= 10
				_battle_add_log("💀 复活需要处于濒死状态!")
		# ===== 牧师 T3 =====
		"复活术":
			# 每战斗限2次复活,当前HP≤0时使用,满HP后恢复100%
			if priest_resurrection_uses <= 0:
				_battle_add_log("⚠️ 复活次数已用尽!")
			elif player_data.hp > 0:
				_battle_add_log("💀 复活术需要处于濒死状态!")
			else:
				priest_resurrection_uses -= 1
				player_data.hp = player_data.max_hp  # 满HP复活
				_trigger_portrait_heal_glow()
				_battle_add_log("✨✨ 复活术!满HP复活!剩余%d次" % priest_resurrection_uses)
				_spawn_player_damage("REVIVE 100%!", "heal")
		"神圣领域":
			# 3回合内每回合回复HP上限10%,清除所有debuff
			priest_divine_domain_turns = 3
			priest_divine_domain_heal = int(player_data.max_hp * 0.1)
			player_data.hp = min(player_data.max_hp, player_data.hp + priest_divine_domain_heal)
			_trigger_portrait_heal_glow()
			_battle_add_log("⛪ 神圣领域!每回合回复%d HP持续3回合(清除所有debuff)" % priest_divine_domain_heal)
			_spawn_player_damage("+%d/回合!" % priest_divine_domain_heal, "heal")
		"神圣裁定":
			# ATK×3.5,对邪恶生物(邪派/叛门)+100%
			var is_evil = current_enemy.get("faction", "") in ["邪派", "叛门"]
			var sj_base = 3.5 if not is_evil else 7.0
			var sj_dmg = int(_get_effective_atk() * sj_base)
			current_enemy["hp"] -= sj_dmg
			priest_divine_judgment_turns = 3
			_battle_add_log("⚡⚡ 神圣裁定!造成 %d 伤害(%s+100%%)" % [sj_dmg, "对邪恶生物" if is_evil else "普通"])
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % sj_dmg, "crit", Vector2(0, -45))
		"生命之泉":
			# 每回合回复HP上限15%,持续4回合
			priest_life_fountain_turns = 4
			priest_life_fountain_heal = int(player_data.max_hp * 0.15)
			player_data.hp = min(player_data.max_hp, player_data.hp + priest_life_fountain_heal)
			_trigger_portrait_heal_glow()
			_battle_add_log("⛲ 生命之泉!每回合回复%d HP持续4回合" % priest_life_fountain_heal)
			_spawn_player_damage("+%d/回合!" % priest_life_fountain_heal, "heal")
		# ===== 牧师 T4 (觉醒技能·Lv40解锁) =====
		"神迹":
			# 全队HP回满,清除所有debuff,每战斗限1次
			if priest_divine_miracle_used:
				_battle_add_log("⚠️ 神迹本场战斗已使用!")
			else:
				priest_divine_miracle_used = true
				player_data.hp = player_data.max_hp
				_trigger_portrait_heal_glow()
				_battle_add_log("✨✨✨ 神迹!全队HP全满,清除所有 debuff!")
				_spawn_player_damage("神迹!!! 全满!", "heal")
		"神圣审判":
			# ATK×6.0全体,附加「神判」禁止敌人回复HP持续5回合
			var sj_all_dmg = int(_get_effective_atk() * 6.0)
			current_enemy["hp"] -= sj_all_dmg
			priest_divine_judgment_turns = 5
			_battle_add_log("⚡⚡⚡ 神圣审判!造成 %d 伤害全体,敌人无法回复HP持续5回合!" % sj_all_dmg)
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % sj_all_dmg, "crit", Vector2(0, -50))
		"永恒庇护":
			# 全队获得「神圣之魂」buff:死亡时自动复活(限1次/每角色)
			priest_holy_sentinel_active = true
			priest_holy_sentinel_hp_threshold = 1
			_battle_add_log("🛡️✨ 永恒庇护!全队获得「神圣之魂」,死亡时自动复活(限1次)!")
			_spawn_player_damage("🛡️ 神圣之魂!", "shield")
		# 骑士
		"格挡":
			player_defending = true
			player_shield = int(player_data.defense() * 1.2)
			_battle_add_log("⚔️ 格挡!伤害减少,护盾+%d" % player_shield)
			_spawn_player_damage("+%d" % player_shield, "shield")
		"斩击":
			var pierce_def = _get_pierced_defense()
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 1.8)) - pierce_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 神圣斩击!造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg)
		"神圣":
			var effective_def = int(_get_pierced_defense() * 0.5)
			var dmg = _roll_dmg_var_large(int(_get_effective_atk() * 2.5)) - effective_def
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			var heal = int(player_data.max_hp * 0.15)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_battle_add_log("✨ 神圣制裁!造成 %d 伤害并恢复 %d HP" % [dmg, heal])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "buff", Vector2(0, -25))
			_spawn_player_damage("+%d" % heal, "heal")
		# 吟游诗人
		"鼓舞":
			var boost = 5
			player_data.atk += boost
			_battle_add_log("🎵 鼓舞!攻击力+%d 本场战斗" % boost)
			_spawn_player_damage("ATK+%d" % boost, "buff")
		"旋律":
			var heal = int(player_data.max_hp * 0.2)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			var heal2 = int(player_data.max_mp * 0.2)
			player_data.mp = min(player_data.max_mp, player_data.mp + heal2)
			_trigger_portrait_heal_glow()
			_battle_add_log("🎶 治疗旋律!恢复 %d HP 和 %d MP" % [heal, heal2])
			_spawn_player_damage("+%d HP" % heal, "heal")
		"沉默":
			enemy_stun_turns = 2
			_battle_add_log("🎵 沉默旋律!敌人无法使用技能2回合")
		# 召唤师
		"召唤":
			var summon_dmg = int(_get_effective_atk() * 1.3 + player_data.luk * 2)
			current_enemy["hp"] -= summon_dmg
			resonance_stacks += 1
			_battle_add_log("🔥 召唤兽攻击!造成 %d 伤害(共鸣+%d层)" % [summon_dmg, resonance_stacks])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % summon_dmg, "buff", Vector2(0, -25))
		"契约":
			contract_active = true
			contract_turns = 3
			var contract_dmg = int(_get_effective_atk() * 1.2)
			current_enemy["hp"] -= contract_dmg
			current_enemy["atk"] = max(1, int(current_enemy["atk"] * BOSS_SKILL_MULT_XLOW))
			_battle_add_log("📜 契约诅咒!造成 %d 伤害,敌人ATK降至70%%,持续3回合" % contract_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % contract_dmg, "debuff", Vector2(0, -25))
		"共鸣":
			if resonance_stacks < 1:
				resonance_stacks = 1
			var reso_dmg = int(current_enemy["max_hp"] * 0.15 * resonance_stacks)
			var self_cost = int(player_data.max_hp * 0.05 * resonance_stacks)
			current_enemy["hp"] -= reso_dmg
			player_data.hp = max(1, player_data.hp - self_cost)
			_battle_add_log("⚡ 共鸣爆发!造成 %d 伤害(%d层),自身消耗 %d HP" % [reso_dmg, resonance_stacks, self_cost])
			resonance_stacks = 0
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % reso_dmg, "crit", Vector2(0, -30))
		# 猎人 T2
		"致命陷阱":
			var trap_dmg = _apply_hunter_mark(int(_get_effective_atk() * 1.0))
			current_enemy["hp"] -= trap_dmg
			hunter_trap_dot_dmg = int(_get_effective_atk() * 0.4)
			hunter_trap_turns = 3
			hunter_trap_slow = 3
			current_enemy["spd"] = max(1, current_enemy["spd"] - hunter_trap_slow)
			_battle_add_log("🪤 致命陷阱!造成 %d 伤害,敌人速度-%d持续3回合,此后每回合受到 %d 灼烧伤害" % [trap_dmg, hunter_trap_slow, hunter_trap_dot_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % trap_dmg, "crit", Vector2(0, -35))
		"猎豹加速":
			hunter_evasion_turns = 2
			hunter_speed_boost_turns = 2
			_battle_add_log("🦌 猎豹加速!闪避率+50%%持续2回合,移速提升")
			_spawn_player_damage("EVASION+50%", "buff")
		"穿甲箭":
			hunter_armor_pierce_turns = 2
			var pierce_dmg = _apply_hunter_mark(int(_get_effective_atk() * 2.5))
			current_enemy["hp"] -= pierce_dmg
			_battle_add_log("🏹 穿甲箭!无视防御,造成 %d 伤害,持续2回合穿透" % pierce_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % pierce_dmg, "crit", Vector2(0, -35))
		# 猎人 T3
		"一击脱离":
			var escape_dmg = _apply_hunter_mark(int(_get_effective_atk() * 4.0))
			current_enemy["hp"] -= escape_dmg
			hunter_one_hit_escape = true  # 下次敌人攻击必闪避
			_battle_add_log("⚡ 一击脱离!造成 %d 伤害,本回合100%%闪避敌人攻击" % escape_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % escape_dmg, "crit", Vector2(0, -40))
		"万箭齐发":
			var arrow_dmg = _apply_hunter_mark(int(_get_effective_atk() * 1.5))
			current_enemy["hp"] -= arrow_dmg
			# 标记:敌人受伤+20%持续3回合
			hunter_mark_turns = 3
			hunter_mark_mult = 1.2
			_battle_add_log("🏹 万箭齐发!造成 %d 伤害,标记敌人受到伤害+20%%持续3回合" % arrow_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % arrow_dmg, "crit", Vector2(0, -40))
		"猎杀时刻":
			if current_enemy["hp"] < current_enemy["max_hp"] * 0.5:
				hunter_mark_turns = 2
				hunter_mark_mult = 2.0
				_battle_add_log("🎯 猎杀时刻!敌人HP<50%%,伤害+100%%持续2回合")
				_spawn_player_damage("ATK×2.0!", "buff")
			else:
				# 敌人HP还高,改为造成较低伤害
				var hunt_dmg = _apply_hunter_mark(int(_get_effective_atk() * 1.5))
				current_enemy["hp"] -= hunt_dmg
				_battle_add_log("🎯 猎杀时刻!敌人HP仍高,造成 %d 伤害" % hunt_dmg)
				_enemy_hit_effect()
				_spawn_enemy_damage("%d" % hunt_dmg, "damage", Vector2(0, -30))
		"野兽之力":
			hunter_beast_turns = 4
			hunter_beast_dmg = int(player_data.attack_power() * 0.8)
			_battle_add_log("🐺 野兽之力!召唤巨狼,每回合对敌人造成 %d 伤害,持续4回合" % hunter_beast_dmg)
			_spawn_player_damage("🐺 野兽之力!", "buff")
		# ===== 猎人 T4 (觉醒技能·Lv40解锁) =====
		"死标记":
			# ATK×10.0,对HP>50%敌人伤害打折(×0.5);HP<50%时真实伤害
			var death_dmg = int(_get_effective_atk() * 10.0)
			if current_enemy["hp"] > current_enemy["max_hp"] * 0.5:
				death_dmg = int(death_dmg * 0.5)
				_battle_add_log("💀🏹 死标记!目标HP充足,伤害×0.5,造成 %d 伤害" % death_dmg)
			else:
				_battle_add_log("💀🏹💀 死标记!对HP<50%%目标造成真实伤害 %d !" % death_dmg)
			current_enemy["hp"] -= death_dmg
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % death_dmg, "crit", Vector2(0, -65))
		"自然之力":
			# 场上每有种草/陷阱/召唤物,伤害+30%
			hunter_nature_power_turns = 3
			hunter_nature_power_bonus = 1.0
			# 计算加成:巨狼+1,致命陷阱激活+1,猎豹+1等
			var nature_bonus = 1.0
			if hunter_beast_turns > 0:
				nature_bonus += 0.3
			if hunter_trap_turns > 0:
				nature_bonus += 0.3
			if hunter_evasion_turns > 0:
				nature_bonus += 0.3
			hunter_nature_power_bonus = nature_bonus
			_battle_add_log("🌿✨ 自然之力!当前伤害加成×%.1f,持续3回合" % nature_bonus)
			_spawn_player_damage("自然之力!", "buff")
		"狩猎领域":
			# 全体队友SPD+5,先手率+50%,持续4回合
			hunter_hunting_field_turns = 4
			_battle_add_log("🏹🌲 狩猎领域!全体队友速度+5,先手率+50%%,持续4回合!")
			_spawn_player_damage("狩猎领域!", "buff")
		# ===== 法师 T3 =====
		"陨石术":
			# ATK × 5.0 单体 + 爆炸范围伤 ATK × 2.0 全体
			var meteor_dmg1 = int(_get_effective_atk() * 5.0)
			var meteor_dmg2 = int(_get_effective_atk() * 2.0)
			current_enemy["hp"] -= meteor_dmg1
			# 附加灼烧DOT
			meteor_turns = 3
			meteor_dmg = int(_get_effective_atk() * 0.8)
			_battle_add_log("☄️ 陨石术!造成 %d 伤害,并引发爆炸对全体造成 %d 伤害" % [meteor_dmg1, meteor_dmg2])
			_battle_add_log("🔥 陨石术灼烧!目标每回合受到 %d 伤害,持续3回合" % meteor_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % meteor_dmg1, "crit", Vector2(0, -45))
			_spawn_enemy_damage("爆!%d" % meteor_dmg2, "crit", Vector2(30, -20))
		"绝对零度":
			# ATK × 3.0 单体,冰冻3回合(Boss减半=1.5回合)
			var freeze_dmg = int(_get_effective_atk() * 3.0)
			current_enemy["hp"] -= freeze_dmg
			var freeze_turns = 3
			# Boss冰冻减半
			if current_enemy.get("is_boss", false):
				freeze_turns = 2
			absolute_zero_turns = freeze_turns
			_battle_add_log("❄️ 绝对零度!造成 %d 伤害,冰冻敌人 %d 回合!" % [freeze_dmg, freeze_turns])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % freeze_dmg, "crit", Vector2(0, -45))
		"元素风暴":
			# ATK × 2.5 全体,火+冰+雷三属性混合伤害
			var storm_dmg = int(_get_effective_atk() * 2.5)
			current_enemy["hp"] -= storm_dmg
			elemental_storm_turns = 3
			elemental_storm_dmg = int(_get_effective_atk() * 0.5)
			_battle_add_log("⚡🔥❄️ 元素风暴!火+冰+雷三系混合,造成 %d 伤害!" % storm_dmg)
			_battle_add_log("⚡ 元素风暴持续!每回合额外受到 %d 伤害,持续3回合" % elemental_storm_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % storm_dmg, "crit", Vector2(0, -45))
		"时间静止":
			# 使全体敌人暂停1回合(期间我方先手)
			time_stop_turns = 2
			time_stop_active = true
			_battle_add_log("⏰ 时间静止!敌人被冻结 %d 回合,我方获得先手优势!" % time_stop_turns)
			_spawn_player_damage("⏰ 时间静止!", "buff")
		# ===== 法师 T4 (觉醒技能·Lv40解锁) =====
		"元素湮灭":
			# ATK × 8.0 单体,目标属性弱点伤害翻倍
			var anni_dmg = int(_get_effective_atk() * 8.0)
			# 检查敌人是否有火/冰/雷属性弱点,有则伤害翻倍
			var enemy_weakness = current_enemy.get("weakness", "")
			var weakness_bonus = ""
			if enemy_weakness.find("火") >= 0 or enemy_weakness.find("冰") >= 0 or enemy_weakness.find("雷") >= 0:
				anni_dmg *= 2
				weakness_bonus = "(弱点加成!伤害翻倍!)"
			elemental_annihilation_weak_mult = 2.0  # 标记弱点翻倍(持续到战斗结束)
			current_enemy["hp"] -= anni_dmg
			_battle_add_log("💥💥💥 元素湮灭!造成 %d 伤害!%s" % [anni_dmg, weakness_bonus])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % anni_dmg, "crit", Vector2(0, -60))
		"奥术真理":
			# 本场战斗所有属性伤害+50%,所有属性抗性+30%
			arcane_truth_turns = 999  # 持续到战斗结束(用大数模拟)
			arcane_truth_active = true
			arcane_weaving_history.clear()  # 清除秘法编织记录
			_battle_add_log("🔮✨ 奥术真理!本场战斗所有属性伤害+50%%,所有属性抗性+30%%!")
			_spawn_player_damage("奥术真理!", "buff")
		"秘法编织":
			# 连续释放最后3个技能(各消耗50%MP)
			var history = arcane_weaving_history.duplicate()
			if history.size() == 0:
				_battle_add_log("⚠️ 秘法编织:无技能历史,无法编织!")
				_spawn_player_damage("无历史!", "debuff")
			else:
				_battle_add_log("🧶✨ 秘法编织!回放最近 %d 个技能..." % history.size())
				_spawn_player_damage("秘法编织!", "buff")
				# 回放技能(不消耗MP,不触发冷却,用reduced=true标记)
				for hist_skill in history:
					var hist_cost = int(mp_cost.get(hist_skill, 0) * 0.5)
					_battle_add_log("  → 【编织】%s (消耗50%%MP: %d)" % [hist_skill, hist_cost])
					# 直接复用技能执行逻辑,但不记录到历史(避免死循环)
					# 简化处理:以较低伤害再次触发技能效果
					var replay_dmg = int(_get_effective_atk() * 0.5)
					current_enemy["hp"] -= replay_dmg
					_spawn_enemy_damage("%d(编织)" % replay_dmg, "crit", Vector2(randi()%40-20, -30-randi()%20))
				# 清空历史防止重复使用
				arcane_weaving_history.clear()
		# 盗贼 T2
		"影遁":
			var vanish_dmg = int(_get_effective_atk() * 3.0)
			current_enemy["hp"] -= vanish_dmg
			vanish_turns = 2
			_battle_add_log("💨 影遁!造成 %d 伤害,2回合内50%%闪避" % vanish_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % vanish_dmg, "crit", Vector2(0, -40))
		"淬毒利刃":
			var poison_dmg = int(_get_effective_atk() * 1.5)
			current_enemy["hp"] -= poison_dmg
			thief_poison_turns = 4
			thief_poison_dmg = int(_get_effective_atk() * 0.3)
			_battle_add_log("🗡️ 淬毒利刃!造成 %d 伤害,4回合内每回合受到 %d 中毒伤害" % [poison_dmg, thief_poison_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % poison_dmg, "poison", Vector2(0, -30))
		"锁喉":
			var choke_dmg = int(_get_effective_atk() * 2.2)
			current_enemy["hp"] -= choke_dmg
			thief_choke_turns = 2
			_battle_add_log("🗡️ 锁喉!造成 %d 伤害,敌人眩晕2回合" % choke_dmg)
			_enemy_hit_effect()
			enemy_stun_turns = max(enemy_stun_turns, 2)
			_spawn_enemy_damage("%d" % choke_dmg, "debuff", Vector2(0, -35))
		# ===== 盗贼 T3 (终极技能·Lv25解锁) =====
		"影分身":
			# 制造2个分身(各30%HP,攻击无效),迷惑敌人,持续5回合
			thief_shadow_clone_turns = 5
			_battle_add_log("👤👤 影分身!制造2个分身迷惑敌人,持续5回合!分身各30%HP")
			_spawn_player_damage("影分身!", "buff")
		"绝杀":
			# ATK×6.0,仅对HP<30%目标生效
			var exe_dmg = int(_get_effective_atk() * 6.0)
			if current_enemy["hp"] > current_enemy["max_hp"] * 0.3:
				exe_dmg = int(exe_dmg * 0.5)
				_battle_add_log("🗡️💀 绝杀!目标HP>30%,伤害减半!造成 %d 伤害" % exe_dmg)
			else:
				_battle_add_log("🗡️💀 绝杀!对残血目标造成 %d 伤害!" % exe_dmg)
			current_enemy["hp"] -= exe_dmg
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % exe_dmg, "crit", Vector2(0, -55))
		"暗影之牙":
			# ATK×2.5全体,附带「影蚀」debuff(DEF-30%持续2回合)
			var fang_dmg = int(_get_effective_atk() * 2.5)
			current_enemy["hp"] -= fang_dmg
			thief_shadow_fang_turns = 2
			thief_shadow_fang_defdebuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - thief_shadow_fang_defdebuff)
			_battle_add_log("🌑🗡️ 暗影之牙!造成 %d 伤害,敌人DEF-%d持续2回合!" % [fang_dmg, thief_shadow_fang_defdebuff])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % fang_dmg, "crit", Vector2(0, -45))
		# ===== 盗贼 T4 (觉醒技能·Lv40解锁) =====
		"千面杀手":
			# 每回合自动攻击HP最低敌人(ATK×3.0),持续5回合
			thief_thousand_faces_turns = 5
			_battle_add_log("🎭💀 千面杀手!每回合自动攻击HP最低敌人,持续5回合!")
			_spawn_player_damage("千面杀手!", "crit")
		"暗影吞噬":
			# ATK×8.0,吸收敌人50%已损失HP转化为自身HP
			var devour_dmg = int(_get_effective_atk() * 8.0)
			var absorb_hp = int((current_enemy["max_hp"] - current_enemy["hp"]) * 0.5)
			current_enemy["hp"] -= devour_dmg
			var actual_heal = min(absorb_hp, devour_dmg)
			player_data.hp = min(player_data.max_hp, player_data.hp + actual_heal)
			_battle_add_log("🌑💜 暗影吞噬!造成 %d 伤害,吸收 %d HP转化为自身治疗!" % [devour_dmg, actual_heal])
			_enemy_hit_effect()
			_critical_hit_effect()
			_trigger_portrait_heal_glow()
			_spawn_enemy_damage("%d" % devour_dmg, "crit", Vector2(0, -60))
			_spawn_player_damage("+%d" % actual_heal, "heal")
		"幻惑领域":
			# 3回合内,敌人50%概率攻击自己人(精英/Boss为20%)
			thief_illusion_domain_turns = 3
			_battle_add_log("🌙✨ 幻惑领域!敌人30%概率混乱攻击自己人,持续3回合!")
			_spawn_player_damage("幻惑!", "buff")
		# ===== 骑士 T4 (觉醒技能·Lv40解锁) =====
		"天使守护":
			# 5回合内,全队HP不会降至1以下(最低保留1HP)
			knight_angel_guard_turns = 5
			knight_angel_guard_triggered = false
			_battle_add_log("👼✨ 天使守护!全队HP不会降至1以下,持续5回合!")
			_spawn_player_damage("天使守护!", "buff")
		"神圣之锤":
			# ATK×7.0单体,圣光属性,必然暴击
			knight_holy_hammer_turns = 3
			knight_holy_hammer_mult = 2.0
			var hammer_dmg = int(_get_effective_atk() * 7.0)
			current_enemy["hp"] -= hammer_dmg
			_battle_add_log("🔨⚡ 神圣之锤!必然暴击,造成 %d 圣光伤害,持续3回合内伤害×2!" % hammer_dmg)
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % hammer_dmg, "crit", Vector2(0, -65))
		"正义执行":
			# 对HP<30%敌人立即斩杀(无视免死),否则ATK×4.0
			knight_execution_turns = 2
			var exe_dmg2 = int(_get_effective_atk() * 4.0)
			if current_enemy["hp"] > current_enemy["max_hp"] * 0.3:
				current_enemy["hp"] -= exe_dmg2
				_battle_add_log("⚖️ 正义执行!对 %d 敌人造成 %d 伤害,斩杀生效中..." % (current_enemy["hp"], exe_dmg2))
				_spawn_enemy_damage("%d" % exe_dmg2, "crit", Vector2(0, -50))
			else:
				current_enemy["hp"] = 0
				_battle_add_log("💀⚖️ 正义执行!敌人HP<30%%,立即处决!")
				_spawn_enemy_damage("斩杀!", "crit", Vector2(0, -65))
		# 牧师 T2
		"群体治疗":
			var heal_amt = int(player_data.max_hp * 0.5)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
			priest_mass_heal_mp = heal_amt
			player_shield += int(heal_amt * 0.3)
			_trigger_portrait_heal_glow()
			_battle_add_log("💚 群体治疗!恢复 %d HP,护盾+%d" % [heal_amt, int(heal_amt * 0.3)])
			_spawn_player_damage("+%d" % heal_amt, "heal")
		"驱散":
			priest_dispel_done = true
			var def_debuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - def_debuff)
			# 驱散敌人增益
			_battle_add_log("✨ 驱散!敌人防御-%d" % def_debuff)
			_spawn_enemy_damage("DEF-%d" % def_debuff, "debuff")
		"神圣仲裁":
			var smite_dmg = int(_get_effective_atk() * 2.8)
			current_enemy["hp"] -= smite_dmg
			priest_smite_turns = 2
			priest_smite_defdebuff = int(current_enemy["def"] * 0.25)
			current_enemy["def"] = max(1, current_enemy["def"] - priest_smite_defdebuff)
			var smite_heal = int(player_data.max_hp * 0.1)
			player_data.hp = min(player_data.max_hp, player_data.hp + smite_heal)
			_battle_add_log("⚖️ 神圣仲裁!造成 %d 伤害,敌人DEF-%d持续2回合,恢复 %d HP" % [smite_dmg, priest_smite_defdebuff, smite_heal])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % smite_dmg, "crit", Vector2(0, -40))
			_spawn_player_damage("+%d" % smite_heal, "heal")
		# 骑士 T2
		"盾击":
			var shield_bang = int(player_data.defense() * 1.8)
			current_enemy["hp"] -= shield_bang
			knight_shield_bang_dmg = shield_bang
			enemy_stun_turns = 1
			_battle_add_log("🛡️ 盾击!造成 %d 伤害,敌人眩晕1回合" % shield_bang)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % shield_bang, "damage", Vector2(0, -25))
		"圣光审判":
			var judgment_dmg = int(_get_effective_atk() * 2.5)
			current_enemy["hp"] -= judgment_dmg
			knight_judgment_turns = 2
			knight_judgment_defdebuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - knight_judgment_defdebuff)
			_battle_add_log("⚔️ 圣光审判!造成 %d 伤害,敌人DEF-%d持续2回合" % [judgment_dmg, knight_judgment_defdebuff])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % judgment_dmg, "crit", Vector2(0, -40))
		"钢铁壁垒":
			knight_iron_wall_turns = 3
			knight_iron_wall_defboost = int(player_data.defense() * 1.0)
			player_shield += int(player_data.defense() * 2.0)
			_battle_add_log("🏰 钢铁壁垒!自身DEF+%d持续3回合,护盾+%d" % [knight_iron_wall_defboost, int(player_data.defense() * 2.0)])
			_spawn_player_damage("+%d" % int(player_data.defense() * 2.0), "shield")
		# ===== 骑士 T3 (终极技能·Lv25解锁) =====
		"神圣复仇":
			# ATK×4.0,附带神圣DOT(无视抗性)持续3回合
			var avenger_dmg = int(_get_effective_atk() * 4.0)
			current_enemy["hp"] -= avenger_dmg
			knight_holy_avenger_turns = 3
			knight_holy_avenger_dmg = int(_get_effective_atk() * 0.8)
			_battle_add_log("⚔️✨ 神圣复仇!造成 %d 伤害,圣光灼烧每回合 %d 伤害持续3回合" % [avenger_dmg, knight_holy_avenger_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % avenger_dmg, "crit", Vector2(0, -50))
		"永恒守卫":
			# 为生命值最低队友附加「守卫」效果:替他承受所有伤害持续2回合
			knight_eternal_guard_turns = 2
			knight_eternal_guard_target = _get_lowest_hp_ally_index()
			_battle_add_log("🛡️🛡️ 永恒守卫!保护队友 #%d 替他承受所有伤害持续2回合" % (knight_eternal_guard_target + 1))
			_spawn_player_damage("守卫!", "buff")
		"圣光审判(全)":
			# ATK×3.5全体,附加「审判」DOT每回合ATK×0.5持续3回合
			var aoe_judgment_dmg = int(_get_effective_atk() * 3.5)
			knight_judgment_aoe_turns = 3
			knight_judgment_aoe_dmg = int(_get_effective_atk() * 0.5)
			_battle_add_log("⚖️⚖️ 圣光审判(全体)!对全体敌人造成 %d 伤害,审判每回合 %d 伤害持续3回合" % [aoe_judgment_dmg, knight_judgment_aoe_dmg])
			_spawn_enemy_damage("%d" % aoe_judgment_dmg, "crit", Vector2(0, -50))
		# ===== 吟游诗人 T2
		"战斗乐章":
			bard_song_atk_turns = 3
			bard_song_atk_boost = int(_get_effective_atk() * 0.25)
			_battle_add_log("🎵 战斗乐章!攻击力+%d持续3回合" % bard_song_atk_boost)
			_spawn_player_damage("ATK+%d" % bard_song_atk_boost, "buff")
		"疯狂节拍":
			var rhythm_dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= rhythm_dmg
			bard_rhythm_turns = 2
			_battle_add_log("🥁 疯狂节拍!造成 %d 伤害,敌人速度-40%%持续2回合" % rhythm_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % rhythm_dmg, "crit", Vector2(0, -35))
		"天籁之音":
			var hm_heal = int(player_data.max_hp * 0.35)
			player_data.hp = min(player_data.max_hp, player_data.hp + hm_heal)
			var hm_mp = int(player_data.max_mp * 0.2)
			player_data.mp = min(player_data.max_mp, player_data.mp + hm_mp)
			bard_healing_melody_mp = hm_mp
			_trigger_portrait_heal_glow()
			_battle_add_log("🎶 天籁之音!恢复 %d HP 和 %d MP" % [hm_heal, hm_mp])
			_spawn_player_damage("+%d HP" % hm_heal, "heal")
		# ===== 吟游诗人 T2 路线B 幻术师技能 =====
		"催眠曲":
			# 单体敌人「沉睡」2回合(受到攻击即苏醒);沉睡期间若未被攻击,第3回合自动进入「深度沉睡」(再受击才醒)
			# 精英/Boss为15%概率
			if randi() % 100 < 30:
				bard_hypno_turns = 3
				_battle_add_log("🌙💤 催眠曲!敌人陷入沉睡(3回合内受到攻击才苏醒)")
			else:
				_battle_add_log("🌙  催眠曲... 敌人意志坚定,未被催眠")
		"幻听":
			# 敌人攻击时30%概率打偏(闪避+50%),持续2回合;诗人和队友闪避+30%
			bard_hallucinate_turns = 2
			_battle_add_log("👁️🎭 幻听!敌人攻击30%%概率打偏,全队闪避+30%%持续2回合")
			_spawn_player_damage("闪避↑", "buff")
		"混乱之音":
			# ATK × 2.0 全体,附加「混乱」(敌人30%概率攻击自己人,持续2回合);精英/Boss混乱概率为15%
			var chaos_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 2.0)) - _get_pierced_defense()
			chaos_dmg = max(1, chaos_dmg)
			current_enemy["hp"] -= chaos_dmg
			bard_chaos_turns = 2
			# 先手效果:混乱之音命中时额外效果
			if randi() % 100 < 30:
				_battle_add_log("🎧🔀 混乱之音!敌人被迷惑,%s 将混乱攻击自己人2回合!" % current_enemy["name"])
			else:
				_battle_add_log("🎧🔀 混乱之音!造成 %d 伤害,敌人可能混乱(30%%概率)持续2回合" % chaos_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % chaos_dmg, "crit", Vector2(0, -45))
		# ===== 吟游诗人 T3 (终极技能·Lv25解锁) =====
		"完美和弦":
			# 全队ATK+40%,暴击+20%,持续4回合
			bard_perfect_chord_turns = 4
			bard_perfect_chord_atk_boost = int(_get_effective_atk() * 0.4)
			# 暴击率+20%,这里通过luk提升模拟
			_battle_add_log("🎵✨ 完美和弦!全队ATK+40%%,暴击+20%%持续4回合")
			_spawn_player_damage("完美和弦!", "buff")
		"命运交响曲":
			# 持续5回合,每回合:全队随机+buff,敌人随机-debuff
			# 第一回合立即生效
			_battle_add_log("🎻🎼 命运交响曲启动!持续5回合,命运之力轮转...")
			var symph_buffs = ["ATK+15%", "DEF+15%", "SPD+2", "LUK+5"]
			var symph_msg = symph_buffs[randi() % symph_buffs.size()]
			_battle_add_log("  → 第一乐章:%s" % symph_msg)
			_spawn_player_damage("命运!", "buff")
		"终末安魂曲":
			# ATK × 3.0 全体,附加"安魂"效果(敌人无法回复HP)持续5回合
			var requiem_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 3.0)) - _get_pierced_defense()
			requiem_dmg = max(1, requiem_dmg)
			current_enemy["hp"] -= requiem_dmg
			bard_requiem_turns = 5
			# 30%概率直接斩杀HP<30%敌人
			if current_enemy["hp"] < current_enemy["max_hp"] * 0.3 and randi() % 100 < 30:
				current_enemy["hp"] = 0
				_battle_add_log("🕯️⚰️ 终末安魂曲!%s 生命力枯竭,被安魂曲终结!" % current_enemy["name"])
				_critical_hit_effect()
				_spawn_enemy_damage("安魂!", "crit", Vector2(0, -50))
			else:
				_battle_add_log("🕯️⚰️ 终末安魂曲!造成 %d 伤害,敌人无法回复HP持续5回合" % requiem_dmg)
				_enemy_hit_effect()
				_spawn_enemy_damage("%d" % requiem_dmg, "crit", Vector2(0, -45))
		# ===== 吟游诗人 T4 (觉醒技能·Lv40解锁) =====
		"传奇之歌":
			# 全队永久ATK+20%,DEF+20%(不随战斗结束消失)
			if bard_legendary_song_atk_boost == 0:
				bard_legendary_song_atk_boost = int(_get_effective_atk() * 0.2)
				bard_legendary_song_def_boost = int(player_data.defense() * 0.2)
				_battle_add_log("🎤🌟 传奇之歌!ATK+20,DEF+20(永久生效,不随战斗结束消失)")
				_spawn_player_damage("传奇!", "buff")
			else:
				_battle_add_log("🎤🌟 传奇之歌已激活!ATK+20,DEF+20")
		"虚空咏叹调":
			# ATK × 5.0 单体,附加"虚空"效果(敌人所有属性-30%持续4回合)
			var void_dmg = _roll_dmg_var_large(int(_get_effective_atk() * 5.0)) - _get_pierced_defense()
			void_dmg = max(1, void_dmg)
			current_enemy["hp"] -= void_dmg
			bard_void_aria_turns = 4
			bard_void_aria_stat_debuff = int(current_enemy["atk"] * 0.3)
			current_enemy["atk"] = max(1, current_enemy["atk"] - bard_void_aria_stat_debuff)
			# 额外降低def和spd
			var void_def_debuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - void_def_debuff)
			var void_spd_debuff = int(current_enemy["spd"] * 0.3)
			current_enemy["spd"] = max(1, current_enemy["spd"] - void_spd_debuff)
			_battle_add_log("🌑🎭 虚空咏叹调!造成 %d 伤害,敌人全属性-30%%持续4回合" % void_dmg)
			_enemy_hit_effect()
			_critical_hit_effect()
			_spawn_enemy_damage("%d" % void_dmg, "crit", Vector2(0, -55))
		"生命赞歌":
			# 使一名已死亡队友复活并回复50%HP,同时全队获得30%伤害加成持续3回合
			if player_data.hp <= 0:
				player_data.hp = int(player_data.max_hp * 0.5)
				_trigger_portrait_heal_glow()
				_battle_add_log("🎵✨ 生命赞歌!%s 复活并恢复50%%HP,全队伤害+30%%持续3回合!" % player_data.get_job_name())
				_spawn_player_damage("REVIVE! +30%Dmg", "heal")
			else:
				_battle_add_log("🎵✨ 生命赞歌!复活已死亡的队友(当前无阵亡队友),全队伤害+30%%持续3回合")
				_spawn_player_damage("+30%Dmg x3", "buff")
		# 召唤师 T2
		"契约强化":
			summoner_contract_boost_turns = 3
			summoner_contract_boost_dmg = int(_get_effective_atk() * 0.5)
			var contract_boost_dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= contract_boost_dmg
			_battle_add_log("📜 契约强化!造成 %d 伤害,召唤兽伤害+%d/次持续3回合" % [contract_boost_dmg, summoner_contract_boost_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % contract_boost_dmg, "buff", Vector2(0, -30))
		"灵魂连接":
			summoner_soul_link_turns = 4
			summoner_soul_link_dmg = int(player_data.max_hp * 0.08)
			_battle_add_log("🔗 灵魂连接!每回合对敌人造成 %d 伤害,持续4回合" % summoner_soul_link_dmg)
			_spawn_player_damage("LINK x4", "buff")
		"召唤兽强化":
			summoner_beast_boost_turns = 3
			var beast_dmg = int(_get_effective_atk() * 1.5 + player_data.luk * 3)
			current_enemy["hp"] -= beast_dmg
			_battle_add_log("🐉 召唤兽强化!召唤兽攻击力+%d,额外造成 %d 伤害" % [_get_effective_atk() / 3, beast_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % beast_dmg, "crit", Vector2(0, -35))
		# 召唤师 T3 (终极技能·Lv25解锁)
		"究极召唤·天使":
			var angel_hp = int(player_data.max_hp * 1.5)
			var angel_atk = int(_get_effective_atk() * 1.2)
			active_summons.append({"name": "天使", "hp": angel_hp, "max_hp": angel_hp, "atk": angel_atk, "turns": 5, "type": "angel"})
			# 治疗全队30%HP
			var heal_amt = int(player_data.max_hp * 0.3)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
			_trigger_portrait_heal_glow()
			_battle_add_log("👼 究极召唤·天使!召唤天使(HP:%d ATK:%d)持续5回合,并治疗全队 %d HP" % [angel_hp, angel_atk, heal_amt])
			_spawn_player_damage("+%d HP" % heal_amt, "heal")
		"究极召唤·恶魔":
			var demon_hp = int(player_data.max_hp * 0.8)
			var demon_atk = int(_get_effective_atk() * 1.5)
			active_summons.append({"name": "恶魔", "hp": demon_hp, "max_hp": demon_hp, "atk": demon_atk, "turns": 5, "type": "demon"})
			# 恶魔造成范围伤害
			var demon_dmg = int(demon_atk * 1.2)
			current_enemy["hp"] -= demon_dmg
			_battle_add_log("😈 究极召唤·恶魔!召唤恶魔(HP:%d ATK:%d)持续5回合,造成 %d 范围伤害" % [demon_hp, demon_atk, demon_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % demon_dmg, "crit", Vector2(0, -35))
		"召唤融合":
			if active_summons.size() < 2:
				_battle_add_log("⚠️ 召唤融合需要至少2只召唤物!当前召唤物:%d" % active_summons.size())
			else:
				var total_hp = 0
				var total_atk = 0
				var names = []
				for s in active_summons:
					total_hp += s["hp"]
					total_atk += s["atk"]
					names.append(s["name"])
				var fused_hp = int(total_hp * 1.5)
				var fused_atk = int(total_atk * 1.5)
				active_summons.clear()
				active_summons.append({"name": "融合召唤", "hp": fused_hp, "max_hp": fused_hp, "atk": fused_atk, "turns": 3, "type": "fused"})
				summoner_fusion_active = true
				summoner_fusion_turns = 3
				_battle_add_log("🌀 召唤融合!融合 %s 为超级召唤物(HP:%d ATK:%d)持续3回合" % [names.join("+"), fused_hp, fused_atk])
				_spawn_player_damage("FUSED!", "buff")
		# 召唤师 T4 (觉醒技能·Lv40解锁)
		"万灵召唤":
			var summons_created = []
			# 使魔
			var imp_hp = int(player_data.max_hp * 0.6)
			var imp_atk = int(_get_effective_atk() * 0.6)
			active_summons.append({"name": "使魔", "hp": imp_hp, "max_hp": imp_hp, "atk": imp_atk, "turns": 6, "type": "normal"})
			summons_created.append("使魔")
			# 精灵
			var fairy_hp = int(player_data.max_hp * 0.5)
			var fairy_atk = int(_get_effective_atk() * 0.7)
			active_summons.append({"name": "精灵", "hp": fairy_hp, "max_hp": fairy_hp, "atk": fairy_atk, "turns": 6, "type": "normal"})
			summons_created.append("精灵")
			# 天使
			var angel_hp = int(player_data.max_hp * 1.5)
			var angel_atk = int(_get_effective_atk() * 1.2)
			active_summons.append({"name": "天使", "hp": angel_hp, "max_hp": angel_hp, "atk": angel_atk, "turns": 6, "type": "angel"})
			summons_created.append("天使")
			# 恶魔
			var demon_hp = int(player_data.max_hp * 0.8)
			var demon_atk = int(_get_effective_atk() * 1.5)
			active_summons.append({"name": "恶魔", "hp": demon_hp, "max_hp": demon_hp, "atk": demon_atk, "turns": 6, "type": "demon"})
			summons_created.append("恶魔")
			_battle_add_log("🌟 万灵召唤!召唤 %s,持续6回合" % summons_created.join("、"))
			_spawn_player_damage("万灵!", "buff")
		"灵魂献祭":
			if active_summons.size() == 0:
				_battle_add_log("⚠️ 灵魂献祭需要场上有召唤物!")
			else:
				var total_sac_hp = 0
				var names = []
				for s in active_summons:
					total_sac_hp += s["hp"]
					names.append(s["name"])
				var sac_dmg = int(total_sac_hp * 0.5)
				active_summons.clear()
				summoner_fusion_active = false
				summoner_fusion_turns = 0
				current_enemy["hp"] -= sac_dmg
				_battle_add_log("💀 灵魂献祭!牺牲 %s,对敌人造成 %d 真实伤害!" % [names.join("、"), sac_dmg])
				_enemy_hit_effect()
				_spawn_enemy_damage("%d" % sac_dmg, "crit", Vector2(0, -40))
		"契约之魂":
			summoner_soul_contract_turns = 5
			summoner_soul_contract_dmg_boost = int(_get_effective_atk() * 1.0)
			_battle_add_log("🔥 契约之魂!所有召唤物伤害+100%%,每回合自动攻击持续5回合")
			_spawn_player_damage("契约之魂!", "buff")

	_update_enemy_hp_bar()
	_update_battle_player_ui()
	await _check_battle_end()
	# 应用冷却
	var cd_to_set = _get_skill_cooldown(skill_name)
	if cd_to_set > 0:
		skill_cooldowns[skill_name] = cd_to_set
	# 秘法编织:记录技能使用历史(秘法编织和奥术真理不记录)
	if skill_name != "秘法编织" and skill_name != "奥术真理" and skill_name != "":
		arcane_weaving_history.append(skill_name)
		if arcane_weaving_history.size() > 3:
			arcane_weaving_history.pop_front()
	if audio_manager:
		audio_manager.play_sfx("skill")
	if game_state == State.BATTLE:
		await get_tree().create_timer(0.4).timeout
		_end_player_turn()

func _enemy_hit_effect():
	enemy_sprite_target = enemy_sprite.position + Vector2(15, 0)

# ==================== 浮动伤害文字系统 ====================
# 浮动伤害文字颜色配置
const FLOAT_COLORS = {
	"damage": Color(1.0, 0.9, 0.5),      # 橙黄 - 普通伤害
	"crit": Color(1.0, 0.4, 0.1, 1.0),    # 橙色 - 暴击
	"heal": Color(0.3, 1.0, 0.4, 1.0),    # 绿色 - 治疗
	"poison": Color(0.5, 1.0, 0.2, 1.0),   # 黄绿 - 中毒
	"shield": Color(0.4, 0.7, 1.0, 1.0),   # 蓝色 - 护盾
	"miss": Color(0.6, 0.6, 0.6, 0.8),    # 灰色 - 闪避
	"buff": Color(0.3, 0.8, 1.0, 1.0),    # 淡蓝 - 增益
	"debuff": Color(0.9, 0.3, 0.3, 1.0),   # 红色 - 减益
	"mp": Color(0.6, 0.4, 1.0, 1.0),       # 紫色 - MP
}

# 在敌人位置生成浮动伤害文字
func _spawn_enemy_damage(text: String, type: String = "damage", offset: Vector2 = Vector2(0, -20)):
	if not battle_ui or not enemy_sprite:
		return
	var enemy_panel = battle_ui.get_node_or_null("EnemyPanel")
	if not enemy_panel:
		return
	var base_pos = enemy_panel.position + enemy_sprite.position + offset
	_spawn_floating_text(battle_ui, base_pos, text, FLOAT_COLORS.get(type, FLOAT_COLORS["damage"]), 1.2)

# 在玩家位置生成浮动文字(血条附近)
func _spawn_player_damage(text: String, type: String = "damage"):
	if not battle_ui:
		return
	var player_panel = battle_ui.get_node_or_null("PlayerPanel")
	if not player_panel:
		return
	# 追踪本层受到的伤害和本场战斗命中(用于成就)
	if type == "damage" and text.is_valid_int():
		var dmg_val = text.to_int()
		if dmg_val > 0:
			_floor_damage_taken += dmg_val
			enemy_hit_this_battle = true  # 敌人命中了玩家
	var base_pos = player_panel.position + Vector2(100, 60)
	_spawn_floating_text(battle_ui, base_pos, text, FLOAT_COLORS.get(type, FLOAT_COLORS["damage"]), 1.2)

func _spawn_floating_text(parent: Control, pos: Vector2, text: String, col: Color, duration: float = 1.0):
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = Vector2(200, 40)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 1.0))
	lbl.z_index = 200
	parent.add_child(lbl)

	# 向上飘动动画
	var tween = parent.create_tween()
	tween.set_parallel(true)
	var target_y = pos.y - 60
	var target_x = pos.x + randf() * 20 - 10
	tween.tween_property(lbl, "position", Vector2(target_x, target_y), duration)
	# 透明度渐变
	var start_a = 1.0
	var mid_a = 0.7
	var end_a = 0.0
	tween.tween_method(func(v): lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, v)), start_a, mid_a, duration * 0.35)
	tween.tween_method(func(v): lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, v)), mid_a, end_a, duration * 0.65)
	# 字体放大效果(先大后正常)
	var scale_tween = parent.create_tween()
	scale_tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.1)
	scale_tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.2)

	await parent.create_timer(duration + 0.1).timeout
	if lbl and is_instance_valid(lbl):
		lbl.queue_free()

func _end_player_turn():
	is_player_turn = false
	# 猎人消失技能:下回合后SPD恢复正常
	# 盗贼消失buff在敌人回合后清除
	await get_tree().create_timer(0.4).timeout
	_process_battle(0)

# ==================== 战斗流程 ====================

func _process_battle(delta: float):
	# 敌人精灵动画
	if enemy_sprite:
		var diff = enemy_sprite_target.x - enemy_sprite.position.x
		if abs(diff) > 1:
			enemy_sprite.position.x += diff * 8 * delta
		else:
			enemy_sprite.position.x = enemy_sprite_pos.x

	# ===== 肖像面板动画 =====
	_update_portrait_animation(delta)

	# 战斗消息消失
	if battle_message_timer > 0:
		battle_message_timer -= delta
		if battle_message_timer <= 0:
			battle_message = ""

	if is_player_turn:
		return  # 等待玩家输入

	# 敌人回合
	# ===== 召唤师召唤物自动攻击 =====
	if active_summons.size() > 0 and not is_player_turn:
		# 每只召唤物攻击
		var summons_to_remove = []
		for i in range(active_summons.size()):
			var s = active_summons[i]
			s["turns"] -= 1
			if s["turns"] <= 0:
				summons_to_remove.append(i)
				_battle_add_log("⏰ %s消失了(持续时间结束)" % s["name"])
				continue
			# 计算召唤物伤害
			var s_atk = s["atk"]
			if summoner_soul_contract_turns > 0:
				s_atk += summoner_soul_contract_dmg_boost
			var s_base_dmg = _roll_dmg_var_medium(s_atk)
			var s_dmg = max(1, s_base_dmg - int(current_enemy["def"] * 0.5))
			current_enemy["hp"] -= s_dmg
			_battle_add_log("🌟 %s攻击!造成 %d 伤害(剩余%d回合)" % [s["name"], s_dmg, s["turns"])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % s_dmg, "buff", Vector2(0, -20))
			# 恶魔范围攻击
			if s["type"] == "demon":
				var demon_aoe = int(s_dmg * 0.4)
				current_enemy["hp"] -= demon_aoe
				_battle_add_log("😈 恶魔暗影!额外造成 %d 范围伤害" % demon_aoe)
				_spawn_enemy_damage("+%d" % demon_aoe, "debuff", Vector2(20, -10))
			# 召唤物受击(敌人反击,随机)
			if randf() < 0.25:
				var counter_dmg = int(current_enemy["atk"] * 0.3)
				s["hp"] -= counter_dmg
				_battle_add_log("⚔️ %s受到反击!损失 %d HP" % [s["name"], counter_dmg])
			# 召唤物死亡检测
			if s["hp"] <= 0:
				_battle_add_log("💀 %s被消灭了!" % s["name"])
				summons_to_remove.append(i)
		# 移除已消失/死亡的召唤物(倒序删除避免索引问题)
		for idx in range(summons_to_remove.size() - 1, -1, -1):
			active_summons.remove_at(summons_to_remove[idx])
		if active_summons.size() > 0:
			_battle_add_log("【召唤物: %d只】" % active_summons.size())
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return
		await get_tree().create_timer(0.3).timeout
	# ===== 契约之魂:回合递减 =====
	if summoner_soul_contract_turns > 0:
		summoner_soul_contract_turns -= 1
		if summoner_soul_contract_turns <= 0:
			summoner_soul_contract_dmg_boost = 0
			_battle_add_log("🔥 契约之魂效果结束!")
	# ===== 融合召唤持续时间递减 =====
	if summoner_fusion_turns > 0:
		summoner_fusion_turns -= 1
		if summoner_fusion_turns <= 0:
			summoner_fusion_active = false
			_battle_add_log("🌀 召唤融合效果结束!")
	# 时间静止:敌人被冻结
	if time_stop_turns > 0:
		time_stop_turns -= 1
		_battle_add_log("⏰ 时间静止!敌人无法行动!(剩余%d回合)" % time_stop_turns)
		await get_tree().create_timer(0.5).timeout
		if time_stop_turns <= 0:
			time_stop_active = false
		_start_player_turn()
		return

	if enemy_stun_turns > 0:
		enemy_stun_turns -= 1
		_battle_add_log("敌人仍然眩晕!")
		await get_tree().create_timer(0.5).timeout
		_start_player_turn()
		return

	# 中毒伤害
	if poison_turns > 0:
		var total_poison = poison_stacks * poison_damage
		current_enemy["hp"] -= total_poison
		_battle_add_log("毒素发作!受到 %d 伤害(%d层)" % [total_poison, poison_stacks])
		_spawn_enemy_damage("%d" % total_poison, "poison", Vector2(20, -10))
		poison_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 流星火雨灼烧
	if meteor_burn_turns > 0:
		current_enemy["hp"] -= meteor_burn_dmg
		_battle_add_log("🔥 灼烧!流星火雨造成 %d 伤害(剩余%d回合)" % [meteor_burn_dmg, meteor_burn_turns])
		_spawn_enemy_damage("%d" % meteor_burn_dmg, "poison", Vector2(-20, -10))
		meteor_burn_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 法师T3: 陨石术灼烧DOT
	if meteor_turns > 0:
		current_enemy["hp"] -= meteor_dmg
		_battle_add_log("☄️ 陨石灼烧!造成 %d 伤害(剩余%d回合)" % [meteor_dmg, meteor_turns])
		_spawn_enemy_damage("%d" % meteor_dmg, "poison", Vector2(-10, -15))
		meteor_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 法师T3: 元素风暴DOT
	if elemental_storm_turns > 0:
		current_enemy["hp"] -= elemental_storm_dmg
		_battle_add_log("⚡🔥❄️ 元素风暴!造成 %d 伤害(剩余%d回合)" % [elemental_storm_dmg, elemental_storm_turns])
		_spawn_enemy_damage("%d" % elemental_storm_dmg, "debuff", Vector2(10, -15))
		elemental_storm_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 霜冻领域减速效果
	if frost_slow_turns > 0:
		frost_slow_turns -= 1
		if frost_slow_turns <= 0:
			_battle_add_log("❄️ 霜冻领域效果结束")

	# 猎人T3: 猎杀时刻标记效果
	if hunter_mark_turns > 0:
		hunter_mark_turns -= 1
		if hunter_mark_turns <= 0:
			hunter_mark_mult = 1.0
			_battle_add_log("🎯 猎杀时刻标记效果结束")

	# 法术穿透buff(减少)
	if spell_pierce_turns > 0:
		spell_pierce_turns -= 1
		if spell_pierce_turns <= 0:
			_battle_add_log("💠 法术穿透效果结束")

	# 魔力回旋(回合开始时触发:吸MP+回HP)
	if mana_drain_turns > 0:
		mana_drain_turns -= 1
		player_data.mp = min(player_data.max_mp, player_data.mp + mana_drain_amount)
		var drain_heal = int(player_data.max_hp * 0.05)
		player_data.hp = min(player_data.max_hp, player_data.hp + drain_heal)
		_battle_add_log("🌀 魔力回旋!回复 %d MP 和 %d HP(剩余%d回合)" % [mana_drain_amount, drain_heal, mana_drain_turns])
		_spawn_player_damage("+%d MP" % mana_drain_amount, "heal")
		if mana_drain_turns <= 0:
			_battle_add_log("🌀 魔力回旋结束")

	# 血之狂暴debuff(每回合自损10HP)
	if berserk_turns > 0:
		player_data.hp -= 10
		berserk_turns -= 1
		_battle_add_log("💢 血之狂暴反噬!受到 10 伤害(剩余%d回合)" % berserk_turns)
		_spawn_player_damage("-10", "debuff")
		if player_data.hp <= 0:
			player_data.hp = 1  # 不会倒下,但很危险
			_battle_add_log("💢 血之狂暴!濒死状态!")
		if await _check_battle_end():
			return

	# 战吼buff处理(回合开始时减少)
	if battle_cry_turns > 0:
		battle_cry_turns -= 1
		if battle_cry_turns <= 0:
			battle_cry_atk_boost = 0
			battle_cry_team_boost = 0
			_battle_add_log("📢 战吼效果结束")

	# 吟游诗人T2: 战斗乐章ATK提升
	if bard_song_atk_turns > 0:
		bard_song_atk_turns -= 1
		if bard_song_atk_turns <= 0:
			_battle_add_log("🎵 战斗乐章效果结束")

	# 骑士T2: 钢铁壁垒DEF提升
	if knight_iron_wall_turns > 0:
		knight_iron_wall_turns -= 1
		if knight_iron_wall_turns <= 0:
			knight_iron_wall_defboost = 0
			_battle_add_log("🏰 钢铁壁垒效果结束")

	# 骑士T2: 圣光审判DEF debuff
	if knight_judgment_turns > 0:
		knight_judgment_turns -= 1
		if knight_judgment_turns <= 0:
			knight_judgment_defdebuff = 0
			_battle_add_log("⚔️ 圣光审判效果结束")

	# 牧师T2: 神圣仲裁DEF debuff
	if priest_smite_turns > 0:
		priest_smite_turns -= 1
		if priest_smite_turns <= 0:
			priest_smite_defdebuff = 0
			_battle_add_log("⚖️ 神圣仲裁效果结束")

	# 牧师T3: 神圣领域 - 每回合回复HP上限10%持续3回合
	if priest_divine_domain_turns > 0:
		priest_divine_domain_turns -= 1
		var dd_heal = priest_divine_domain_heal
		player_data.hp = min(player_data.max_hp, player_data.hp + dd_heal)
		_trigger_portrait_heal_glow()
		_battle_add_log("⛪ 神圣领域!回复 %d HP(剩余%d回合)" % [dd_heal, priest_divine_domain_turns])
		_spawn_player_damage("+%d" % dd_heal, "heal")
		if priest_divine_domain_turns <= 0:
			priest_divine_domain_heal = 0
			_battle_add_log("⛪ 神圣领域效果结束")

	# 牧师T3: 生命之泉 - 每回合回复HP上限15%持续4回合
	if priest_life_fountain_turns > 0:
		priest_life_fountain_turns -= 1
		var lf_heal = priest_life_fountain_heal
		player_data.hp = min(player_data.max_hp, player_data.hp + lf_heal)
		_trigger_portrait_heal_glow()
		_battle_add_log("⛲ 生命之泉!回复 %d HP(剩余%d回合)" % [lf_heal, priest_life_fountain_turns])
		_spawn_player_damage("+%d" % lf_heal, "heal")
		if priest_life_fountain_turns <= 0:
			priest_life_fountain_heal = 0
			_battle_add_log("⛲ 生命之泉效果结束")

	# 牧师T4: 神圣裁定/神圣审判的「神判」debuff回合递减
	if priest_divine_judgment_turns > 0:
		priest_divine_judgment_turns -= 1
		if priest_divine_judgment_turns <= 0:
			_battle_add_log("⚖️ 神圣裁定/审判效果结束")

	# 召唤师T2: 契约强化
	if summoner_contract_boost_turns > 0:
		summoner_contract_boost_turns -= 1
		if summoner_contract_boost_turns <= 0:
			summoner_contract_boost_dmg = 0
			_battle_add_log("📜 契约强化效果结束")

	# 召唤师T2: 召唤兽强化
	if summoner_beast_boost_turns > 0:
		summoner_beast_boost_turns -= 1
		if summoner_beast_boost_turns <= 0:
			_battle_add_log("🐉 召唤兽强化效果结束")

	# 战士T3: 战神领域buff
	if warrior_domain_turns > 0:
		warrior_domain_turns -= 1
		if warrior_domain_turns <= 0:
			warrior_domain_atk_boost = 0
			warrior_domain_def_boost = 0
			_battle_add_log("⚔️ 战神领域效果结束")

	# 战士T4: 战神印记 - 目标受伤+30%持续3回合
	if warrior_wargod_mark_turns > 0:
		warrior_wargod_mark_turns -= 1
		if warrior_wargod_mark_turns <= 0:
			warrior_wargod_mark_dmg_boost = 0
			_battle_add_log("⚔️ 战神印记消退!")

	# 战士T4: 征服者怒吼 - 敌人ATK降低恐惧效果
	if warrior_conqueror_fear_turns > 0:
		warrior_conqueror_fear_turns -= 1
		if warrior_conqueror_fear_turns <= 0:
			_battle_add_log("😨 征服者怒吼的恐惧效果结束!")

	# 战士T3: 碎甲敌人DEF debuff
	if warrior_shatter_turns > 0:
		warrior_shatter_turns -= 1
		if warrior_shatter_turns <= 0:
			current_enemy["def"] = warrior_shatter_orig_def
			_battle_add_log("⚔️ 碎甲效果结束,敌人DEF恢复")

	# 猎人T2: 穿甲箭(穿透效果已在内置,穿透减少在_on_skill_selected里处理)
	if hunter_armor_pierce_turns > 0:
		hunter_armor_pierce_turns -= 1
		if hunter_armor_pierce_turns <= 0:
			_battle_add_log("🏹 穿甲箭效果结束")

	# 契约诅咒(生命吸取)
	if contract_active:
		var drain_dmg = int(player_data.attack_power() * 0.4)
		current_enemy["hp"] -= drain_dmg
		var heal_amt = int(drain_dmg * 0.5)
		player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
		contract_turns -= 1
		_battle_add_log("📜 契约吸取!对敌人造成 %d 伤害,回复 %d HP(剩余%d回合)" % [drain_dmg, heal_amt, contract_turns])
		_spawn_enemy_damage("%d" % drain_dmg, "debuff", Vector2(30, -10))
		if contract_turns <= 0:
			contract_active = false
			_battle_add_log("📜 契约诅咒结束")
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 猎人T2: 致命陷阱DOT
	if hunter_trap_turns > 0:
		current_enemy["hp"] -= hunter_trap_dot_dmg
		_battle_add_log("🪤 陷阱灼烧!受到 %d 伤害(剩余%d回合)" % [hunter_trap_dot_dmg, hunter_trap_turns])
		_spawn_enemy_damage("%d" % hunter_trap_dot_dmg, "poison", Vector2(-10, -10))
		hunter_trap_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 盗贼T2: 淬毒利刃DOT
	if thief_poison_turns > 0:
		current_enemy["hp"] -= thief_poison_dmg
		_battle_add_log("🗡️ 中毒!淬毒利刃造成 %d 伤害(剩余%d回合)" % [thief_poison_dmg, thief_poison_turns])
		_spawn_enemy_damage("%d" % thief_poison_dmg, "poison", Vector2(10, -10))
		thief_poison_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 盗贼T3: 暗影之牙DEF debuff expiration
	if thief_shadow_fang_turns > 0:
		thief_shadow_fang_turns -= 1
		if thief_shadow_fang_turns <= 0:
			current_enemy["def"] += thief_shadow_fang_defdebuff
			thief_shadow_fang_defdebuff = 0
			_battle_add_log("🌑 暗影之牙的DEF减益效果结束!")

	# 盗贼T3: 影分身效果(持续时间递减)
	if thief_shadow_clone_turns > 0:
		thief_shadow_clone_turns -= 1
		if thief_shadow_clone_turns <= 0:
			_battle_add_log("👤 影分身消散!")

	# 盗贼T4: 千面杀手自动攻击(每回合开始时)
	if thief_thousand_faces_turns > 0:
		thief_thousand_faces_turns -= 1
		# 千面杀手:自动攻击HP最低的敌人
		var tf_dmg = int(_get_effective_atk() * 3.0)
		current_enemy["hp"] -= tf_dmg
		_battle_add_log("🎭💀 千面杀手!自动追踪残血目标,造成 %d 伤害!(剩余%d回合)" % [tf_dmg, thief_thousand_faces_turns])
		_enemy_hit_effect()
		_critical_hit_effect()
		_spawn_enemy_damage("%d" % tf_dmg, "crit", Vector2(0, -40))
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return
		if thief_thousand_faces_turns <= 0:
			_battle_add_log("🎭 千面杀手效果结束!")

	# 盗贼T4: 暗影吞噬(持续时间追踪)
	if thief_shadow_devour_turns > 0:
		thief_shadow_devour_turns -= 1
		if thief_shadow_devour_turns <= 0:
			_battle_add_log("🌑 暗影吞噬效果结束!")

	# 盗贼T4: 幻惑领域(持续时间递减)
	if thief_illusion_domain_turns > 0:
		thief_illusion_domain_turns -= 1
		if thief_illusion_domain_turns <= 0:
			_battle_add_log("🌙 幻惑领域效果结束!")

	# 召唤师T2: 灵魂连接DOT
	if summoner_soul_link_turns > 0:
		current_enemy["hp"] -= summoner_soul_link_dmg
		_battle_add_log("🔗 灵魂连接!受到 %d 伤害(剩余%d回合)" % [summoner_soul_link_dmg, summoner_soul_link_turns])
		_spawn_enemy_damage("%d" % summoner_soul_link_dmg, "debuff", Vector2(20, -10))
		summoner_soul_link_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 猎人T3: 野兽之力 召唤狼每回合伤害
	if hunter_beast_turns > 0:
		current_enemy["hp"] -= hunter_beast_dmg
		_battle_add_log("🐺 巨狼撕咬!对敌人造成 %d 伤害(剩余%d回合)" % [hunter_beast_dmg, hunter_beast_turns])
		_spawn_enemy_damage("%d" % hunter_beast_dmg, "damage", Vector2(30, -10))
		hunter_beast_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 骑士T3: 神圣复仇DOT(圣光灼烧,每回合额外伤害)
	if knight_holy_avenger_turns > 0:
		current_enemy["hp"] -= knight_holy_avenger_dmg
		_battle_add_log("⚔️✨ 圣光灼烧!神圣复仇造成 %d 伤害(剩余%d回合)" % [knight_holy_avenger_dmg, knight_holy_avenger_turns])
		_spawn_enemy_damage("%d" % knight_holy_avenger_dmg, "poison", Vector2(-15, -10))
		knight_holy_avenger_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 骑士T3: 圣光审判(全)AOE DOT
	if knight_judgment_aoe_turns > 0:
		var aoe_dmg2 = knight_judgment_aoe_dmg
		current_enemy["hp"] -= aoe_dmg2
		_battle_add_log("⚖️⚖️ 圣光审判!审判造成 %d 伤害(剩余%d回合)" % [aoe_dmg2, knight_judgment_aoe_turns])
		_spawn_enemy_damage("%d" % aoe_dmg2, "debuff", Vector2(15, -10))
		knight_judgment_aoe_turns -= 1
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return

	# 猎人T4: 自然之力持续时间
	if hunter_nature_power_turns > 0:
		hunter_nature_power_turns -= 1
		if hunter_nature_power_turns <= 0:
			_battle_add_log("🌿 自然之力效果结束!")

	# 猎人T4: 狩猎领域持续时间
	if hunter_hunting_field_turns > 0:
		hunter_hunting_field_turns -= 1
		if hunter_hunting_field_turns <= 0:
			_battle_add_log("🏹 狩猎领域效果结束!")

	# 骑士T4: 神圣之锤持续时间
	if knight_holy_hammer_turns > 0:
		knight_holy_hammer_turns -= 1
		if knight_holy_hammer_turns <= 0:
			_battle_add_log("🔨 神圣之锤效果结束!")

	# 骑士T4: 天使守护持续时间
	if knight_angel_guard_turns > 0:
		knight_angel_guard_turns -= 1
		if knight_angel_guard_turns <= 0:
			_battle_add_log("👼 天使守护效果结束!")

	await get_tree().create_timer(0.5).timeout

	# 陷阱触发:敌人被困住,无法攻击并受到伤害
	if trapped:
		var trap_dmg = int(player_data.attack_power() * 1.2)
		current_enemy["hp"] -= trap_dmg
		trapped = false
		_battle_add_log("🪤 陷阱触发!敌人被困住,受到 %d 伤害!" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -30))
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return
		await get_tree().create_timer(0.4).timeout
		_start_player_turn()
		return

	# 一击脱离:100%闪避
	if hunter_one_hit_escape:
		hunter_one_hit_escape = false
		_battle_add_log("⚡ 一击脱离!完美闪避了敌人攻击!")
		_spawn_player_damage("MISS!", "miss")
		_start_player_turn()
		return

	# 消失/猎豹加速闪避检测
	if vanish_turns > 0 or hunter_evasion_turns > 0:
		if vanish_turns > 0:
			vanish_turns -= 1
		if hunter_evasion_turns > 0:
			hunter_evasion_turns -= 1
		if randf() < VANISH_EVASION_CHANCE:
			var evade_name = "消失" if vanish_turns >= 0 else "猎豹加速"
			_battle_add_log("💨 %s!完美闪避了敌人攻击!" % evade_name)
			_spawn_player_damage("MISS!", "miss")
			_start_player_turn()
			return
		else:
			_battle_add_log("💨 闪避失败...")

	# Boss特殊能力处理
	if current_enemy.get("is_boss", false):
		_process_boss_turn()
		return

	# 普通敌人攻击
	var e_dmg = _roll_dmg_var_small(current_enemy["atk"])
	# 战士T4: 幻惑领域效果 - 敌人有概率混乱攻击自己
	if thief_illusion_domain_turns > 0 and not current_enemy.get("is_boss", false):
		if randf() < 0.3:
			# 敌人被幻惑,攻击自己
			var illusion_dmg = int(e_dmg * 0.8)
			current_enemy["hp"] -= illusion_dmg
			_battle_add_log("🌙✨ 幻惑领域!%s 被迷惑,攻击自己!受到 %d 伤害!" % [current_enemy["name"], illusion_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % illusion_dmg, "crit", Vector2(0, -30))
			_update_enemy_hp_bar()
			if await _check_battle_end():
				return
			_start_player_turn()
			return
	elif thief_illusion_domain_turns > 0 and current_enemy.get("is_boss", false):
		if randf() < 0.2:
			# Boss有更低概率混乱
			var illusion_dmg = int(e_dmg * 0.8)
			current_enemy["hp"] -= illusion_dmg
			_battle_add_log("🌙✨ 幻惑领域!Boss %s 被迷惑,攻击自己!受到 %d 伤害!" % [current_enemy["name"], illusion_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % illusion_dmg, "crit", Vector2(0, -30))
			_update_enemy_hp_bar()
			if await _check_battle_end():
				return
			_start_player_turn()
			return
	if player_defending or player_shield > 0:
		e_dmg = int(e_dmg * 0.5)
	if player_shield > 0:
		if player_shield >= e_dmg:
			player_shield -= e_dmg
			e_dmg = 0
			_battle_add_log("🛡️ 护盾吸收了伤害!")
		else:
			e_dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	e_dmg = max(1, e_dmg)
	# 战士T3: 援护效果 - 将伤害转移给敌人
	if warrior_guard_active:
		warrior_guard_active = false
		var guard_dmg = int(e_dmg * 1.5)
		current_enemy["hp"] -= guard_dmg
		_battle_add_log("🛡️ 援护生效!将 %d 伤害转移给敌人!" % guard_dmg)
		_spawn_enemy_damage("%d" % guard_dmg, "crit", Vector2(0, -30))
		_enemy_hit_effect()
		_update_enemy_hp_bar()
		if await _check_battle_end():
			return
		# 玩家本身不受伤
		_trigger_portrait_damage_flash()
		_battle_add_log("👹 %s 攻击!(援护)" % current_enemy["name"])
		_spawn_player_damage("援护!", "shield")
		_update_battle_player_ui()
		_start_player_turn()
		return
	# 战士T4: 绝对防御 - 免疫所有伤害
	if warrior_absolute_def_turns > 0:
		_battle_add_log("🏰⚔️ 绝对防御!免疫了 %s 的攻击!" % current_enemy["name"])
		_spawn_player_damage("免疫!", "shield")
		_update_battle_player_ui()
		await get_tree().create_timer(0.4).timeout
		_end_enemy_turn()
		return
	player_data.hp -= e_dmg
	# 战士T3: 不死不灭 - HP降至1时自动回复30%
	if player_data.hp <= 0 and warrior_undying_used:
		player_data.hp = int(player_data.max_hp * 0.3)
		warrior_undying_used = false
		_trigger_portrait_damage_flash()
		_battle_add_log("🛡️ 不死不灭触发!HP回复至30%%!")
		_spawn_player_damage("不死不灭!", "shield")
		_update_battle_player_ui()
		if await _check_battle_end():
			return
		_start_player_turn()
		return
	# 牧师T4: 永恒庇护 - 神圣之魂,死亡时自动复活(限1次)
	if player_data.hp <= 0 and priest_holy_sentinel_active:
		priest_holy_sentinel_active = false
		player_data.hp = int(player_data.max_hp * 0.5)
		_trigger_portrait_heal_glow()
		_battle_add_log("🛡️✨ 永恒庇护!神圣之魂触发!HP回复至50%%!")
		_spawn_player_damage("神圣之魂!", "heal")
		_update_battle_player_ui()
		if await _check_battle_end():
			return
		_start_player_turn()
		return
	# 骑士T4: 天使守护 - 全队HP不会降至1以下
	if player_data.hp <= 0 and knight_angel_guard_turns > 0 and not knight_angel_guard_triggered:
		player_data.hp = 1
		knight_angel_guard_triggered = true
		_trigger_portrait_heal_glow()
		_battle_add_log("👼✨ 天使守护!HP保留在1点!")
		_spawn_player_damage("天使守护!", "shield")
		_update_battle_player_ui()
		if await _check_battle_end():
			return
		_start_player_turn()
		return
	_trigger_portrait_damage_flash()
	_battle_add_log("👹 %s 攻击!造成 %d 伤害" % [current_enemy["name"], e_dmg])
	_spawn_player_damage("-%d" % e_dmg, "damage")
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()

	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return

	_start_player_turn()

# ==================== Boss战特殊处理 ====================
var boss_action_counter: int = 0  # Boss连续行动计数

func _process_boss_turn():
	# 检查Boss阶段转换
	var hp_ratio = float(current_enemy["hp"]) / float(current_enemy["max_hp"])
	var boss_key = _get_boss_floor_key()

	# 第8层武当真人张三丰多阶段处理
	if boss_key == 8:
		if boss_phase == 1 and hp_ratio <= 0.6:
			boss_phase = 2
			_show_boss_phase_announcement("第二阶段: 纯阳无极!ATK+30%!")
			current_enemy["atk"] = int(current_enemy["atk"] * 1.3)
			_battle_add_log("☯️ 【阶段2】纯阳无极!张三丰发动纯阳内力,攻击力大幅提升!")
			_update_enemy_hp_bar()
			await get_tree().create_timer(1.0).timeout
		elif boss_phase == 2 and hp_ratio <= 0.3:
			boss_phase = 3
			_show_boss_phase_announcement("最终阶段: 一代宗师!")
			_battle_add_log("🙏 【最终阶段】一代宗师降临!这是最后的考验!")
			_update_enemy_hp_bar()
			await get_tree().create_timer(1.0).timeout

	# Boss狂暴检测 (phase_hp血量触发)
	var phase_hp = current_enemy.get("phase_hp", 0.0)
	if phase_hp > 0 and not boss_enraged and hp_ratio <= phase_hp:
		boss_enraged = true
		var boss_name_str = current_enemy["name"]
		if boss_key == 1:  # 山贼王狂暴
			current_enemy["atk"] = int(current_enemy["atk"] * 1.5)
			current_enemy["spd"] += 3
			_show_boss_phase_announcement("狂暴化!ATK+50%!SPD+3!")
			_battle_add_log("👹 %s 狂暴化!ATK+50%%,速度提升!但每回合自残10HP!" % boss_name_str)
		elif boss_key == 3:  # 血刀门护法血战到底
			boss_revived = true
			current_enemy["atk"] = int(current_enemy["atk"] * 1.8)
			current_enemy["spd"] += 4
			_show_boss_phase_announcement("血战到底!ATK+80%!SPD+4!")
			_battle_add_log("🩸 %s 触发【血战到底】!ATK+80%%,SPD+4!每回合自残20HP!" % boss_name_str)
		else:
			_show_boss_phase_announcement("Boss狂暴!")
			_battle_add_log("👹 %s 进入狂暴状态!" % boss_name_str)
		_update_enemy_hp_bar()
		await get_tree().create_timer(1.0).timeout

	boss_action_counter += 1

	# 根据Boss类型执行特殊技能
	match boss_key:
		1: _boss_hanbatian_action(hp_ratio)
		3: _boss_helian_action(hp_ratio)
		5: _boss_sima_action(hp_ratio)
		7: _boss_yue_action(hp_ratio)
		8: _boss_zhang_action(hp_ratio)
		_: _enemy_execute_action()

func _enemy_execute_action():
	# 智能敌人AI系统 - 条件决策而非纯随机
	# 决策顺序: 1)HP危机 2)玩家护盾高 3)原型优先技能 4)普攻

	var enemy_type = current_enemy.get("type", "")
	var archetype = ENEMY_ARCHETYPE.get(enemy_type, "brute")
	var hp_ratio = float(current_enemy["hp"]) / float(current_enemy["max_hp"])
	var player_hp_ratio = float(player_data.hp) / float(player_data.max_hp)
	var shield_ratio = float(player_shield) / float(max(1, player_data.max_hp))

	# 追踪敌人已用技能(避免连续重复,80%概率避免重复)
	var last_skill = current_enemy.get("_last_skill", "")

	# === 决策节点1: HP危机时使用维持技能 ===
	if hp_ratio < 0.25:
		# 危机时刻:根据原型选择维持手段
		var sustain_roll = randi() % 100
		match archetype:
			"guardian":
				# 守护型: 优先铁壁自保,再考虑撤退反击
				if sustain_roll < 60:
					_ai_execute_skill_safe("铁壁", last_skill)
					return
			"mystic":
				# 神秘型: 优先吸血续航
				if sustain_roll < 70:
					_ai_execute_skill_safe("吸血", last_skill)
					return
			"brute":
				# 粗暴型: 狂暴反扑,高伤害赌一把
				if sustain_roll < 50:
					_ai_execute_skill_safe("重击", last_skill)
					return
			"rogue":
				# 盗贼型: 锁喉控制,试图翻盘
				if sustain_roll < 60:
					_ai_execute_skill_safe("锁喉", last_skill)
					return
		# 默认: 孤注一掷用最强技能
		_ai_execute_archetype_skill(archetype, last_skill)
		return

	# === 决策节点2: 玩家HP极低,激进收割 ===
	if player_hp_ratio < 0.20:
		var kill_roll = randi() % 100
		match archetype:
			"brute":
				# 粗暴型: 重击/碎骨直接斩杀
				if kill_roll < 55:
					_ai_execute_skill_safe("重击", last_skill)
					return
			"rogue":
				# 盗贼型: 淬毒持续伤害
				if kill_roll < 55:
					_ai_execute_skill_safe("淬毒", last_skill)
					return
			"mystic":
				# 神秘型: 吸血耗死
				if kill_roll < 60:
					_ai_execute_skill_safe("吸血", last_skill)
					return
		# 默认普攻收割
		_boss_default_attack("普通攻击")
		return

	# === 决策节点3: 玩家护盾极高,优先破盾 ===
	if shield_ratio > 0.5:
		var shield_break_roll = randi() % 100
		match archetype:
			"mystic":
				# 神秘型: 噬魂无视护盾吸血
				if shield_break_roll < 70:
					_ai_execute_skill_safe("噬魂", last_skill)
					return
			"rogue":
				# 盗贼型: 淬毒/锁喉DOT无视护盾
				if shield_break_roll < 55:
					_ai_execute_skill_safe("淬毒" if shield_break_roll < 28 else "锁喉", last_skill)
					return
			"brute":
				# 粗暴型: 碎骨无视护盾直接伤害
				if shield_break_roll < 50:
					_ai_execute_skill_safe("碎骨", last_skill)
					return

	# === 决策节点4: HP中高时,原型优先技能 (45%概率) ===
	var skill_roll = randi() % 100
	if skill_roll < 45:
		_ai_execute_archetype_skill(archetype, last_skill)
		return

	# === 默认: 普通攻击 ===
	_boss_default_attack("普通攻击")

func _ai_execute_archetype_skill(archetype: String, last_skill: String):
	# 根据原型选择代表性技能(带去重逻辑)
	var skills: Array
	match archetype:
		"brute":   skills = ["重击", "碎骨"]
		"rogue":   skills = ["淬毒", "锁喉"]
		"mystic":  skills = ["吸血", "噬魂"]
		"guardian": skills = ["盾击", "铁壁"]
		"beast":   skills = ["撕咬", "利爪"]
		_:          skills = ["重击"]

	# 去重:80%概率避免重复
	if not skills.is_empty():
		var available = skills.filter(func(s): return s != last_skill)
		if not available.is_empty() and randi() % 100 < 80:
			skills = available

	var chosen = skills[randi() % skills.size()]
	current_enemy["_last_skill"] = chosen
	_ai_dispatch_skill(chosen)

func _ai_execute_skill_safe(skill_name: String, last_skill: String):
	# 安全执行技能(含去重后备)
	if skill_name == last_skill and randi() % 100 < 80:
		_ai_execute_archetype_skill(ENEMY_ARCHETYPE.get(current_enemy.get("type", ""), "brute"), last_skill)
		return
	current_enemy["_last_skill"] = skill_name
	_ai_dispatch_skill(skill_name)

func _ai_dispatch_skill(skill_name: String):
	# 统一技能分发
	match skill_name:
		"重击": _enemy_skill_heavy_strike()
		"碎骨": _enemy_skill_bone_crusher()
		"淬毒": _enemy_skill_poison_thrust()
		"锁喉": _enemy_skill_strangle()
		"吸血": _enemy_skill_life_drain()
		"噬魂": _enemy_skill_soul_drain()
		"盾击": _enemy_skill_shield_bash()
		"铁壁": _enemy_skill_iron_wall()
		"撕咬": _enemy_skill_bite()
		"利爪": _enemy_skill_claw()
		_: _boss_default_attack(skill_name)

func _enemy_skill_heavy_strike():
	# 重击:2x伤害,降低玩家防御2点,持续2回合
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_HIGH))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	# 降低玩家防御2点(简化:下2回合受伤+20%)
	battle_cry_team_boost = max(battle_cry_team_boost, 2)  # 复用变量记录回合
	_battle_add_log("💥 【重击】!%s 发动重击,造成 %d 伤害,碎甲效果!" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "damage")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_bone_crusher():
	# 碎骨:1.5x伤害,30%几率眩晕玩家1回合
	var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_MED) + randi() % 5
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	var stun_chance = randi() % 100 < 30
	if stun_chance:
		player_stun_turns = max(player_stun_turns, 1)
		_battle_add_log("💀 【碎骨】!%s 发动碎骨,造成 %d 伤害,30%%几率眩晕!★眩晕成功!" % [current_enemy["name"], dmg])
	else:
		_battle_add_log("💀 【碎骨】!%s 发动碎骨,造成 %d 伤害!(眩晕未中)" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "damage")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_poison_thrust():
	# 淬毒:正常伤害 + 附加3层中毒(每层3伤害,持续3回合)
	var dmg = _roll_dmg_var_small(int(current_enemy["atk"]))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	poison_stacks += 3
	poison_damage = max(poison_damage, 3)
	poison_turns = max(poison_turns, 3)
	_battle_add_log("🗡️ 【淬毒】!%s 刺出淬毒一击,造成 %d 伤害并附加中毒!" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "poison")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_strangle():
	# 锁喉:0.8x伤害 + 必定眩晕1回合
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_LOW))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	player_stun_turns = max(player_stun_turns, 1)
	_battle_add_log("🤏 【锁喉】!%s 锁住咽喉,造成 %d 伤害,玩家眩晕1回合!" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "damage")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_life_drain():
	# 吸血:0.7x伤害,回复自身50%伤害量的HP
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_XLOW))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	var heal = int(dmg * 0.5)
	if priest_divine_judgment_turns <= 0:
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
	_battle_add_log("🩸 【吸血】!%s 吸取生命,造成 %d 伤害,%s!" % [current_enemy["name"], dmg, "回复被神判阻止!" if priest_divine_judgment_turns > 0 else ("回复 %d HP!" % heal)])
	_spawn_player_damage("-%d" % dmg, "damage")
	_spawn_enemy_damage("+%d" % heal, "heal", Vector2(0, -30))
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	_update_enemy_hp_bar()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_soul_drain():
	# 噬魂:0.6x伤害 + 偷取3点MP
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_0D6))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	var mp_steal = min(3, player_data.mp)
	player_data.mp -= mp_steal
	_battle_add_log("👻 【噬魂】!%s 吞噬灵魂,造成 %d 伤害,偷取 %d MP!" % [current_enemy["name"], dmg, mp_steal])
	_spawn_player_damage("-%d" % dmg, "damage")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_shield_bash():
	# 盾击:1.5x伤害,50%几率眩晕1回合
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_MED))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	var stun_chance = randi() % 100 < 50
	if stun_chance:
		player_stun_turns = max(player_stun_turns, 1)
		_battle_add_log("🛡️ 【盾击】!%s 盾牌重击,造成 %d 伤害!★眩晕成功!" % [current_enemy["name"], dmg])
	else:
		_battle_add_log("🛡️ 【盾击】!%s 盾牌重击,造成 %d 伤害!(眩晕未中)" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "damage")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_iron_wall():
	# 铁壁:给自己加护盾(30%最大HP),然后普攻
	var shield_gain = int(current_enemy["max_hp"] * 0.3)
	current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + shield_gain)
	_update_enemy_hp_bar()
	_battle_add_log("🛡️ 【铁壁】!%s 进入防御姿态,回复 %d HP!" % [current_enemy["name"], shield_gain])
	_spawn_enemy_damage("+%d" % shield_gain, "heal", Vector2(0, -30))
	await get_tree().create_timer(0.4).timeout
	_boss_default_attack("铁壁反击")

func _enemy_skill_bite():
	# 撕咬:1.2x伤害,附加2层流血(每回合3伤害,持续2回合)
	var dmg = _roll_dmg_var_tiny(int(current_enemy["atk"] * BOSS_SKILL_MULT_MED2))
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	poison_stacks += 2
	poison_damage = max(poison_damage, 3)
	poison_turns = max(poison_turns, 2)
	_battle_add_log("🐺 【撕咬】!%s 撕咬攻击,造成 %d 伤害,附加流血!" % [current_enemy["name"], dmg])
	_spawn_player_damage("-%d" % dmg, "poison")
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _enemy_skill_claw():
	# 利爪:1.3x伤害,连续攻击2次(各0.7x),但第二次必中
	var total_dmg = 0
	for i in range(2):
		var d = _roll_dmg_var_tiny(int(current_enemy["atk"] * (BOSS_SKILL_MULT_1D3 if i == 0 else BOSS_SKILL_MULT_XLOW)))
		if player_defending or player_shield > 0:
			d = int(d * 0.5)
		if player_shield > 0:
			if player_shield >= d:
				player_shield -= d
				d = 0
			else:
				d -= player_shield
				player_shield = 0
		if player_defending:
			player_defending = false
		d = max(1, d)
		player_data.hp -= d
		total_dmg += d
		_battle_add_log("🦴 【利爪%d】!%s 爪击,造成 %d 伤害" % [i+1, current_enemy["name"], d])
		_spawn_player_damage("-%d" % d, "damage")
		_trigger_portrait_damage_flash()
		if audio_manager:
			audio_manager.play_sfx("hit")
		_update_battle_player_ui()
		if player_data.hp <= 0:
			_battle_add_log("💀 你倒下了...")
			_game_over()
			return
		await get_tree().create_timer(0.3).timeout
	_battle_add_log("🦴 【利爪】!%s 共造成 %d 伤害!" % [current_enemy["name"], total_dmg])
	_start_player_turn()

func _boss_hanbatian_action(hp_ratio: float):
	# 山贼王·韩霸天: 普通攻击/战吼/召集喽啰/狂暴化
	var roll = randi() % 100
	if roll < 30:
		_boss_default_attack("开山刀斩")
	elif roll < 55:
		# 战吼:全体攻击+震慑
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_LOW)
		_apply_player_damage(dmg)
		_battle_add_log("⚡ 战吼!全体受到 %d 伤害震慑!" % dmg)
		enemy_stun_turns = max(enemy_stun_turns, 1)
	elif roll < 80 and boss_action_counter > 2:
		# 召集喽啰
		var summon_dmg = int(player_data.attack_power() * 0.5)
		_apply_player_damage(summon_dmg)
		_battle_add_log("👺 召集喽啰!两名山贼参战,造成 %d 伤害!" % summon_dmg)
	else:
		# 狂暴化:自残+高伤攻击
		var self_dmg = 10
		current_enemy["hp"] -= self_dmg
		var atk_dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_MED)
		_apply_player_damage(atk_dmg)
		_battle_add_log("🔥 狂暴化!自残%d HP,造成 %d 伤害!" % [self_dmg, atk_dmg])
		_spawn_enemy_damage("-%d" % self_dmg, "poison", Vector2(0, -20))
	_update_enemy_hp_bar()

func _boss_helian_action(hp_ratio: float):
	# 血刀门护法·血手赫连铁树: 一线斩/血雾/血刀斩/嗜血狂刀/血战到底
	var roll = randi() % 100
	if roll < 25:
		# 一线斩:高伤单体+破甲
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_3D0)
		_apply_player_damage(dmg)
		_battle_add_log("🗡️ 一线斩!造成 %d 伤害,斩断护甲!" % dmg)
	elif roll < 45:
		# 血雾:回复并进入强化状态
		var heal = int(current_enemy["max_hp"] * 0.15)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		current_enemy["atk"] = int(current_enemy["atk"] * 1.2)
		_battle_add_log("🩸 血雾!回复 %d HP,ATK+20%%!" % heal)
	elif roll < 65:
		# 血刀斩:持续掉血
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_1D8)
		_apply_player_damage(dmg)
		poison_stacks += 2
		poison_damage += 5
		poison_turns += 2
		_battle_add_log("🗡️ 血刀斩!造成 %d 伤害,附加流血!" % dmg)
	elif roll < 80 and hp_ratio < 0.3:
		# 嗜血狂刀:低血量斩杀
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_2D5)
		_apply_player_damage(dmg)
		var heal = int(dmg * 0.4)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		_battle_add_log("🩸 嗜血狂刀!造成 %d 伤害,吸血 %d HP!" % [dmg, heal])
	else:
		_boss_default_attack("血刀斩")

func _boss_sima_action(hp_ratio: float):
	# 门派叛徒·司马青云: 御剑术/剑气纵横/夺命十三剑/金蝉脱壳
	var roll = randi() % 100
	if roll < 30:
		# 御剑术:高伤单体+穿刺
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_MED)
		_apply_player_damage(dmg)
		_battle_add_log("🗡️ 御剑术!飞剑穿刺,造成 %d 伤害!" % dmg)
	elif roll < 55:
		# 剑气纵横:全体攻击
		var dmg = int(current_enemy["atk"] * 1.2)
		_apply_player_damage(dmg)
		_battle_add_log("⚡ 剑气纵横!全体受到 %d 剑气伤害!" % dmg)
	elif roll < 75:
		# 夺命十三剑:极高单体伤害
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_2D8)
		_apply_player_damage(dmg)
		enemy_stun_turns = max(enemy_stun_turns, 1)
		_battle_add_log("💀 夺命十三剑!连刺十三剑,%d 伤害,眩晕1回合!" % dmg)
	elif roll < 90:
		# 金蝉脱壳:闪避+反击
		vanish_turns = 2
		_battle_add_log("🌫️ 金蝉脱壳!隐身闪避2回合!")
	else:
		_boss_default_attack("夺命剑法")

func _boss_yue_action(hp_ratio: float):
	# 华山掌门·岳不群: 紫霞神功/独孤九剑/吸星大法/辟邪剑法/伪君子真面目
	var roll = randi() % 100
	if roll < 20:
		# 紫霞神功:全体+内功debuff
		var dmg = int(current_enemy["atk"] * 1.3)
		_apply_player_damage(dmg)
		player_data.atk = int(player_data.atk * 0.85)
		_battle_add_log("🌀 紫霞神功!全体 %d 伤害,我方ATK降低15%%!" % dmg)
	elif roll < 40:
		# 独孤九剑:破招极高伤
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_2D5)
		_apply_player_damage(dmg)
		_battle_add_log("⚔️ 独孤九剑!破尽天下招式,%d 伤害!" % dmg)
	elif roll < 55:
		# 吸星大法:吸玩家HP
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_MED)
		_apply_player_damage(dmg)
		var heal = int(dmg * 0.6)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		_battle_add_log("🖐️ 吸星大法!造成 %d 伤害,吸取 %d HP!" % [dmg, heal])
	elif roll < 75:
		# 辟邪剑法:连续攻击
		for i in range(3):
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_LOW)
			_apply_player_damage(dmg)
		_battle_add_log("🗡️ 辟邪剑法!快剑三连击,每击 %d 伤害!" % int(current_enemy["atk"] * BOSS_SKILL_MULT_LOW))
	else:
		# 伪君子真面目:爆发+护盾
		var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_HIGH)
		_apply_player_damage(dmg)
		player_shield += 80
		_battle_add_log("🎭 伪君子真面目!露出獠牙,%d 伤害,获得80护盾!" % dmg)

func _boss_zhang_action(hp_ratio: float):
	# 武当真人·张三丰: 太极拳/太极剑/梯云纵/纯阳无极功/武当九阳功/一代宗师
	if boss_phase == 1:
		# 第一阶段:太极以柔克刚
		var roll = randi() % 100
		if roll < 25:
			# 太极拳:借力打力,反弹伤害
			var dmg = int(current_enemy["atk"] * 1.2)
			_apply_player_damage(dmg)
			_battle_add_log("☯️ 太极拳!以柔克刚,%d 伤害并吸收攻势!" % dmg)
		elif roll < 50:
			# 太极剑:群体攻击
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_MED)
			_apply_player_damage(dmg)
			_battle_add_log("⚔️ 太极剑!剑意如风,%d 伤害!" % dmg)
		elif roll < 75:
			# 梯云纵:轻盈闪避+反击
			vanish_turns = 1
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_LOW)
			_apply_player_damage(dmg)
			_battle_add_log("🦶 梯云纵!纵云梯飞身闪避,顺手一击 %d 伤害!" % dmg)
		else:
			_boss_default_attack("太极推手")
	elif boss_phase == 2:
		# 第二阶段:纯阳无极功爆发
		var roll = randi() % 100
		if roll < 30:
			# 武当九阳功:全体高伤害
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_2D5)
			_apply_player_damage(dmg)
			_battle_add_log("🔥 武当九阳功!纯阳内力爆发,全体 %d 伤害!" % dmg)
		elif roll < 55:
			# 纯阳无极功:回复+强化
			var heal = int(current_enemy["max_hp"] * 0.2)
			current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
			current_enemy["atk"] = int(current_enemy["atk"] * 1.15)
			_battle_add_log("☯️ 纯阳无极功!回复 %d HP,ATK+15%%!" % heal)
		elif roll < 80:
			# 太极剑·连绵不绝
			for i in range(4):
				var dmg = int(current_enemy["atk"] * 0.7)
				_apply_player_damage(dmg)
			_battle_add_log("⚔️ 太极剑·连绵不绝!四剑连发,每击 %d 伤害!" % int(current_enemy["atk"] * BOSS_SKILL_MULT_XLOW))
		else:
			_boss_default_attack("武当剑法")
	else:
		# 第三阶段:一代宗师·收徒考验
		var roll = randi() % 100
		if roll < 35:
			# 太极拳·云手:全体+推退
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_3D0)
			_apply_player_damage(dmg)
			_battle_add_log("☯️ 太极拳·云手!一代宗师全力一击,%d 伤害!" % dmg)
		elif roll < 60:
			# 太极剑·无形:必中沉默
			var dmg = int(current_enemy["atk"] * BOSS_SKILL_MULT_HIGH)
			_apply_player_damage(dmg)
			silenced = true
			_battle_add_log("⚔️ 太极剑·无形!剑意无形,%d 伤害,我方沉默1回合!" % dmg)
		else:
			# 一代宗师:考验结束,回复
			var heal = int(current_enemy["max_hp"] * 0.25)
			current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
			_battle_add_log("🙏 一代宗师!张三丰:\"你已通过考验!\" 回复 %d HP!" % heal)
	_update_enemy_hp_bar()

func _boss_default_attack(skill_name: String = "攻击"):
	var e_dmg = _roll_dmg_var_small(current_enemy["atk"])
	if player_defending or player_shield > 0:
		e_dmg = int(e_dmg * 0.5)
	if player_shield > 0:
		if player_shield >= e_dmg:
			player_shield -= e_dmg
			e_dmg = 0
			_battle_add_log("🛡️ 护盾吸收了伤害!")
		else:
			e_dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	e_dmg = max(1, e_dmg)
	# 战士T4: 绝对防御 - 免疫Boss伤害
	if warrior_absolute_def_turns > 0:
		_battle_add_log("🏰⚔️ 绝对防御!免疫了 %s 的【%s】!" % [current_enemy["name"], skill_name])
		_spawn_player_damage("免疫!", "shield")
		_update_battle_player_ui()
		await get_tree().create_timer(0.4).timeout
		_start_player_turn()
		return
	player_data.hp -= e_dmg
	_battle_add_log("👹 %s 使用【%s】!造成 %d 伤害" % [current_enemy["name"], skill_name, e_dmg])
	_spawn_player_damage("-%d" % e_dmg, "damage")
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return
	_start_player_turn()

func _apply_player_damage(dmg: int):
	# 应用护盾和防御
	if player_defending or player_shield > 0:
		dmg = int(dmg * 0.5)
	if player_shield > 0:
		if player_shield >= dmg:
			player_shield -= dmg
			dmg = 0
			_battle_add_log("🛡️ 护盾吸收了伤害!")
		else:
			dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	dmg = max(1, dmg)
	player_data.hp -= dmg
	_trigger_portrait_damage_flash()
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
	_spawn_player_damage("-%d" % dmg, "damage")
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()

func _show_boss_phase_announcement(text: String):
	# 创建Boss阶段公告
	var announce = Label.new()
	announce.name = "BossPhaseAnnounce"
	announce.text = text
	announce.position = Vector2(0, 280)
	announce.size = Vector2(1280, 60)
	announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announce.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	announce.add_theme_font_size_override("font_size", 36)
	announce.modulate = Color(1, 1, 1, 0)
	add_child(announce)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(announce, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(1.5).timeout
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(announce, "modulate:a", 0.0, 0.4)
	await tween.finished
	announce.queue_free()

func _start_player_turn():
	# 战士T4: 绝对防御 - 无法行动但免疫伤害
	if warrior_absolute_def_turns > 0:
		warrior_absolute_def_turns -= 1
		_battle_add_log("🏰⚔️ 绝对防御!本回合免疫所有伤害!(剩余%d回合)" % warrior_absolute_def_turns)
		_spawn_player_damage("免疫!", "shield")
		# 绝对防御期间仍然触发敌人回合,但不扣血
		await get_tree().create_timer(0.3).timeout
		is_player_turn = false
		if warrior_absolute_def_turns > 0:
			_process_battle(0)
		else:
			_battle_add_log("🏰 绝对防御结束!")
		return
	# 检查玩家是否被眩晕
	if player_stun_turns > 0:
		player_stun_turns -= 1
		_battle_add_log("⏰ 玩家被眩晕!无法行动!(剩余%d回合)" % player_stun_turns)
		await get_tree().create_timer(0.5).timeout
		is_player_turn = false
		_process_battle(0)
		return
	is_player_turn = true
	# 递减所有技能冷却
	for skill in skill_cooldowns.keys():
		skill_cooldowns[skill] -= 1
		if skill_cooldowns[skill] <= 0:
			skill_cooldowns.erase(skill)
	_update_battle_player_ui()

func _on_attack():
	if not is_player_turn or game_state != State.BATTLE:
		return
	is_player_turn = false
	var is_crit = randi() % 100 < player_data.luk * 2
	var pierce_def = _get_pierced_defense()
	var base_dmg = _roll_dmg_var_medium(player_data.attack_power()) - pierce_def
	# 战神T4: 战神印记 - 目标受伤+30%
	if warrior_wargod_mark_turns > 0:
		base_dmg = int(base_dmg * 1.3)
	var dmg = max(1, base_dmg) * (2 if is_crit else 1)
	current_enemy["hp"] -= dmg
	var attack_msg = "暴击!" if is_crit else ""
	if warrior_wargod_mark_turns > 0:
		attack_msg += "【战神印记+30%】"
	_battle_add_log("⚔️ 攻击!" + attack_msg + "造成 %d 伤害" % dmg)
	var attack_dmg_type = "crit" if is_crit else "damage"
	var attack_offset_x = (randi() % 15) - 7
	var attack_offset_y = -25 if is_crit else -18
	_spawn_enemy_damage("%d" % dmg, attack_dmg_type, Vector2(attack_offset_x, attack_offset_y))
	if audio_manager:
		if is_crit:
			audio_manager.play_sfx("crit")
		else:
			audio_manager.play_sfx("attack")
	_enemy_hit_effect()
	_update_enemy_hp_bar()
	_update_battle_player_ui()
	if await _check_battle_end():
		return
	await get_tree().create_timer(0.4).timeout
	_process_battle(0)

func _on_defend():
	if not is_player_turn or game_state != State.BATTLE:
		return
	is_player_turn = false
	player_defending = true
	var shield_gain = int(player_data.defense() * 0.3)
	player_shield += shield_gain
	player_data.mp = min(player_data.max_mp, player_data.mp + 3)
	_battle_add_log("🛡️ 防御!受伤-50%%,获得护盾,回复3MP")
	_spawn_player_damage("+%d" % shield_gain, "shield")
	_update_battle_player_ui()
	await get_tree().create_timer(0.4).timeout
	_process_battle(0)

func _on_flee():
	if not is_player_turn or game_state != State.BATTLE:
		return
	if randf() < FLEE_SUCCESS_CHANCE:
		_battle_add_log("🏃 逃跑成功!")
		_close_battle_ui()
		game_state = State.EXPLORE
		is_player_turn = true
		show_message("逃离了战斗...")
		if audio_manager:
			audio_manager.play_sfx("flee")
			audio_manager.play_bgm("explore")
	else:
		_battle_add_log("❌ 逃跑失败!")
		is_player_turn = false
		await get_tree().create_timer(0.4).timeout
		_process_battle(0)

func _on_item():
	if not is_player_turn or game_state != State.BATTLE:
		return
	if player_data.inventory.size() == 0:
		_battle_add_log("背包是空的!")
		return
	# 简单实现:使用第一个药水
	var used_item = null
	var item_idx = -1
	for i in range(player_data.inventory.size()):
		var inv = player_data.inventory[i]
		if inv.get("heal_hp", 0) > 0 or inv.get("heal_mp", 0) > 0:
			used_item = inv
			item_idx = i
			break
	if used_item == null:
		_battle_add_log("没有可用的药水!")
		return
	var hhp = used_item.get("heal_hp", 0)
	var hmp = used_item.get("heal_mp", 0)
	var healed = false
	if hhp > 0 and player_data.hp < player_data.max_hp:
		player_data.hp = min(player_data.max_hp, player_data.hp + int(player_data.max_hp * hhp / 100.0))
		healed = true
	if hmp > 0 and player_data.mp < player_data.max_mp:
		player_data.mp = min(player_data.max_mp, player_data.mp + int(player_data.max_mp * hmp / 100.0))
		healed = true
	if healed:
		used_item["count"] -= 1
		if used_item["count"] <= 0:
			player_data.inventory.remove_at(item_idx)
		_battle_add_log("🧪 使用 %s!" % used_item["type"])
		is_player_turn = false
		_update_battle_player_ui()
		await get_tree().create_timer(0.4).timeout
		_process_battle(0)
	else:
		_battle_add_log("状态已经是满的!")

async func _check_battle_end() -> bool:
	if current_enemy["hp"] <= 0:
		var exp_gain = current_enemy["exp"]
		var gold_gain = current_enemy["gold"]
		player_data.exp += exp_gain
		player_data.gold += gold_gain
		_check_quest_objectives("defeat_enemy", {"enemy_id": current_enemy.get("id", ""), "enemy_name": current_enemy.get("name", ""), "floor": current_floor})

		# 成就追踪
		achievement_stats["enemies_defeated"] += 1
		achievement_stats["total_gold_earned"] += gold_gain
		if current_enemy.get("is_elite", false):
			achievement_stats["elite_enemies_defeated"] += 1

		# Boss击败成就
		if current_enemy.get("is_boss", false):
			achievement_stats["bosses_defeated"] += 1
			var job_id = player_data.job
			var job_boss_wins_key = ["warrior_boss_wins", "mage_boss_wins", "hunter_boss_wins", "thief_boss_wins", "priest_boss_wins", "knight_boss_wins", "bard_boss_wins", "summoner_boss_wins"][job_id]
			achievement_stats[job_boss_wins_key] += 1

			# 计算有多少个职业至少赢过一次Boss
			var unique_jobs = 0
			for k in ["warrior_boss_wins", "mage_boss_wins", "hunter_boss_wins", "thief_boss_wins", "priest_boss_wins", "knight_boss_wins", "bard_boss_wins", "summoner_boss_wins"]:
				if achievement_stats[k] >= 1:
					unique_jobs += 1
			achievement_stats["unique_jobs_boss_wins"] = unique_jobs

		# 完美胜利成就(敌人本回合没打中玩家)
		if current_enemy.get("is_boss", false) == false and not enemy_hit_this_battle:
			achievement_stats["perfect_victories"] += 1

		# 无伤通关成就检测(如果本层没受伤且击败了本层所有敌人则由下楼梯时触发)
		_check_achievements()

		# Boss击败特殊提示
		if current_enemy.get("is_boss", false):
			_battle_add_log("🏆⭐ BOSS击破!⭐+%d EXP,+%d 金币!" % [exp_gain, gold_gain])
			_show_boss_victory_screen()
		else:
			_battle_add_log("🏆 胜利!+%d EXP,+%d 金币" % [exp_gain, gold_gain])

		_exp_check()
		_close_battle_ui()
		game_state = State.EXPLORE
		is_player_turn = true
		# 播放胜利BGM并切换回探索
		if audio_manager:
			audio_manager.play_bgm("victory")
			await get_tree().create_timer(4.0).timeout
			audio_manager.play_bgm("explore")

		if current_enemy.get("is_boss", false):
			show_message("⭐ BOSS击破: %s!+%d EXP" % [current_enemy["name"], exp_gain])
		else:
			show_message("击败了 %s!获得 %d EXP" % [current_enemy["name"], exp_gain])
		return true
	if player_data.hp <= 0:
		_battle_add_log("💀 你倒下了...")
		_game_over()
		return true
	return false

func _show_boss_victory_screen():
	# Boss击败特别画面
	var overlay = ColorRect.new()
	overlay.name = "BossVictoryOverlay"
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.position = Vector2(0, 0)
	overlay.modulate = Color(1, 1, 1, 0)
	add_child(overlay)

	var panel = Panel.new()
	panel.name = "BossVictoryPanel"
	panel.position = Vector2(340, 220)
	panel.size = Vector2(600, 280)
	panel.self_modulate = Color(0.03, 0.03, 0.06, 0.98)
	panel.add_theme_stylebox_override("panel", _create_stylebox())
	panel.modulate = Color(1, 1, 1, 0)
	add_child(panel)

	var title = Label.new()
	title.position = Vector2(0, 20)
	title.size = Vector2(600, 50)
	title.text = "⭐ BOSS 击 破 ⭐"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)

	var boss_name = Label.new()
	boss_name.position = Vector2(0, 80)
	boss_name.size = Vector2(600, 40)
	boss_name.text = current_enemy["name"]
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	boss_name.add_theme_font_size_override("font_size", 28)
	panel.add_child(boss_name)

	var sep = ColorRect.new()
	sep.position = Vector2(100, 130)
	sep.size = Vector2(400, 2)
	sep.color = PALETTE.gold * Color(0.5, 0.5, 0.5, 0.5)
	panel.add_child(sep)

	var rewards = Label.new()
	rewards.position = Vector2(0, 150)
	rewards.size = Vector2(600, 60)
	rewards.text = "+%d 经验值\n+%d 金币" % [current_enemy["exp"], current_enemy["gold"]]
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	rewards.add_theme_font_size_override("font_size", 22)
	panel.add_child(rewards)

	var continue_lbl = Label.new()
	continue_lbl.position = Vector2(0, 230)
	continue_lbl.size = Vector2(600, 30)
	continue_lbl.text = ">>> 继续探索 <<<"
	continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	continue_lbl.add_theme_font_size_override("font_size", 16)
	panel.add_child(continue_lbl)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.3).timeout
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.5)
	await get_tree().create_timer(2.0).timeout
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	overlay.queue_free()
	panel.queue_free()

func _exp_check():
	while player_data.exp >= player_data.level_up_requirement() and player_data.exp > 0:
		player_data.exp -= player_data.level_up_requirement()
		player_data.level += 1
		player_data.max_hp += 10
		player_data.max_mp += 3
		player_data.hp = player_data.max_hp
		player_data.mp = player_data.max_mp
		player_data.atk += 2
		player_data.def += 1
		player_data.spd += 1
		player_data.luk += 1
		_battle_add_log("⬆️ 升级!Lv.%d → Lv.%d" % [player_data.level - 1, player_data.level])
		if audio_manager:
			audio_manager.play_sfx("levelup")
		# 成就追踪:最高等级
		if player_data.level > achievement_stats["max_level_reached"]:
			achievement_stats["max_level_reached"] = player_data.level
		_check_achievements()
	show_message("升级了!Lv.%d" % player_data.level)

# 肖像动画更新(每帧调用)
func _update_portrait_animation(delta: float):
	if not battle_ui:
		return
	var portrait_panel = battle_ui.get_node_or_null("PortraitPanel")
	if not portrait_panel:
		return

	# 更新呼吸动画
	portrait_breath_time += delta
	var breath_scale = 1.0 + sin(portrait_breath_time * 2.5) * 0.012  # 轻微上下浮动
	var portrait_container = portrait_panel.get_node_or_null("PortraitContainer")
	if portrait_container:
		portrait_container.scale = Vector2(breath_scale, breath_scale)

	# 更新受伤闪红
	if portrait_damage_flash > 0:
		portrait_damage_flash -= delta
		var portrait_sprite = portrait_container.get_node_or_null("PortraitSprite") if portrait_container else null
		if portrait_sprite:
			var flash = portrait_panel.get_node_or_null("PortraitBG/PortraitContainer/PortraitFlash")
			if flash:
				var alpha = max(0.0, portrait_damage_flash / 0.4) * 0.65
				flash.modulate = Color(1, 1, 1, alpha)
		if portrait_damage_flash <= 0:
			portrait_damage_flash = 0.0
			var flash_node = portrait_panel.get_node_or_null("PortraitBG/PortraitContainer/PortraitFlash")
			if flash_node:
				flash_node.modulate = Color(1, 1, 1, 0.0)

	# 更新治疗绿光
	if portrait_heal_glow > 0:
		portrait_heal_glow -= delta
		var heal_flash = portrait_panel.get_node_or_null("PortraitBG/PortraitContainer/PortraitFlash")
		if heal_flash:
			var alpha = max(0.0, portrait_heal_glow / 0.5) * 0.5
			heal_flash.modulate = Color(1, 1, 1, alpha)
		if portrait_heal_glow <= 0:
			portrait_heal_glow = 0.0
			var heal_flash_reset = portrait_panel.get_node_or_null("PortraitBG/PortraitContainer/PortraitFlash")
			if heal_flash_reset:
				heal_flash_reset.modulate = Color(1, 1, 1, 0.0)

	# 更新肖像面板的HP/MP条(每次动画帧都更新)
	_update_portrait_bars(portrait_panel)

func _update_portrait_bars(portrait_panel: Panel):
	if not portrait_panel:
		return
	var php_bar = portrait_panel.get_node_or_null("PortraitHP")
	var php_val = portrait_panel.get_node_or_null("PortraitHPVal")
	var pmp_bar = portrait_panel.get_node_or_null("PortraitMP")
	var pmp_val = portrait_panel.get_node_or_null("PortraitMPVal")
	if php_bar:
		php_bar.max_value = player_data.max_hp
		php_bar.value = max(0, player_data.hp)
		# HP条颜色随血量变化(仅在阈值跨越时重建StyleBoxFlat,避免每帧创建新对象)
		var hp_ratio = float(player_data.hp) / float(player_data.max_hp)
		var threshold_crossed = (
			(_last_portrait_hp_ratio > 0.5 and hp_ratio <= 0.5) or
			(_last_portrait_hp_ratio > 0.25 and hp_ratio <= 0.25) or
			(_last_portrait_hp_ratio <= 0.5 and hp_ratio > 0.5) or
			(_last_portrait_hp_ratio <= 0.25 and hp_ratio > 0.25) or
			_last_portrait_hp_ratio < 0  # 初始值
		)
		if threshold_crossed:
			var new_fill = StyleBoxFlat.new()
			if hp_ratio > 0.5:
				new_fill.bg_color = Color(0.85, 0.15, 0.15)
			elif hp_ratio > 0.25:
				new_fill.bg_color = Color(0.95, 0.55, 0.05)
			else:
				new_fill.bg_color = Color(0.85, 0.05, 0.05)
			new_fill.corner_radius_top_left = 2; new_fill.corner_radius_top_right = 2
			new_fill.corner_radius_bottom_right = 2; new_fill.corner_radius_bottom_left = 2
			php_bar.add_theme_stylebox_override("fill", new_fill)
		_last_portrait_hp_ratio = hp_ratio
	if php_val:
		php_val.text = "%d / %d" % [max(0, player_data.hp), player_data.max_hp]
	if pmp_bar:
		pmp_bar.max_value = player_data.max_mp
		pmp_bar.value = player_data.mp
	if pmp_val:
		pmp_val.text = "%d / %d" % [player_data.mp, player_data.max_mp]

# 触发肖像受伤闪红
func _trigger_portrait_damage_flash():
	portrait_damage_flash = 0.4  # 闪红持续0.4秒

# 触发肖像治疗绿光
func _trigger_portrait_heal_glow():
	portrait_heal_glow = 0.5  # 绿光持续0.5秒

func _update_enemy_hp_bar():
	if enemy_hp_bar:
		enemy_hp_bar.max_value = current_enemy["max_hp"]
		enemy_hp_bar.value = max(0, current_enemy["hp"])
	if battle_enemy_hp_label:
		battle_enemy_hp_label.text = "%d / %d" % [max(0, current_enemy["hp"]), current_enemy["max_hp"]]

func _update_battle_player_ui():
	if not battle_ui:
		return
	var player_panel = battle_ui.get_node_or_null("PlayerPanel")
	if player_panel:
		var php = player_panel.get_node_or_null("BattleHP")
		if php:
			php.text = "HP: %d/%d" % [max(0, player_data.hp), player_data.max_hp]
		var pmp = player_panel.get_node_or_null("BattleMP")
		if pmp:
			pmp.text = "MP: %d/%d" % [player_data.mp, player_data.max_mp]
		var status_lbl = player_panel.get_node_or_null("StatusLabel")
		if status_lbl:
			var parts = []
			if player_defending: parts.append("🛡️防御")
			if player_shield > 0: parts.append("护盾%d" % player_shield)
			if vanish_turns > 0: parts.append("👤消失×%d" % vanish_turns)
			if berserk_turns > 0: parts.append("💢狂暴×%d" % berserk_turns)
			if battle_cry_turns > 0: parts.append("📢战吼×%d" % battle_cry_turns)
			if warrior_domain_turns > 0: parts.append("⚔️战神领域×%d" % warrior_domain_turns)
			if warrior_guard_active: parts.append("🛡️援护")
			if warrior_undying_used: parts.append("💀不死不灭")
			if poison_turns > 0: parts.append("☠️中毒×%d" % poison_stacks)
			if contract_active: parts.append("📜契约×%d" % contract_turns)
			if resonance_stacks > 0: parts.append("⚡共鸣×%d" % resonance_stacks)
			status_lbl.text = " ".join(parts) if parts.size() > 0 else ""
		# 更新技能冷却显示
		var cd_lbl = player_panel.get_node_or_null("CDLabel")
		if cd_lbl:
			var cd_parts = []
			for skill in skill_cooldowns:
				cd_parts.append("%s:%d" % [skill, skill_cooldowns[skill]])
			cd_lbl.text = "⏱️冷却: " + (", ".join(cd_parts) if cd_parts.size() > 0 else "无")

func _battle_add_log(msg: String):
	if battle_log:
		var old = battle_log.text
		var lines = old.split("\n")
		if lines.size() >= 6:
			lines = lines.slice(1)
		lines.append(msg)
		battle_log.text = "\n".join(lines)

func _close_battle_ui():
	if battle_ui:
		battle_ui.queue_free()
		battle_ui = null
	var overlay = get_node_or_null("BattleOverlay")
	if overlay:
		overlay.queue_free()
	# 重置状态
	player_defending = false
	player_shield = 0
	poison_stacks = 0
	poison_turns = 0
	enemy_stun_turns = 0
	player_stun_turns = 0
	poison_damage = 0
	trapped = false
	_update_ui()
	if minimap_container:
		minimap_container.visible = true
	_update_minimap()

func _game_over():
	_close_battle_ui()
	game_state = State.EXPLORE
	is_player_turn = false
	show_message("💀 游戏结束!按R重新开始...")
	if audio_manager:
		audio_manager.play_sfx("death")
		audio_manager.play_bgm("explore")
	# 简单重置
	player_data.hp = player_data.max_hp
	player_data.mp = player_data.max_mp
	player_data.gold = max(0, player_data.gold - 100)
	current_floor = 1
	is_player_turn = true

# ==================== 存档系统 ====================

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "save_%d.json"
const SAVE_SLOTS = 3

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + (SAVE_FILE % slot)

func _ensure_save_dir():
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")

func has_save(slot: int) -> bool:
	_ensure_save_dir()
	return FileAccess.file_exists(_get_save_path(slot))

func save_game(slot: int) -> bool:
	_ensure_save_dir()
	var path = _get_save_path(slot)
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"slot": slot,
		"player": {
			"job": player_data.job,
			"job_name": player_data.get_job_name(),
			"hp": player_data.hp,
			"max_hp": player_data.max_hp,
			"mp": player_data.mp,
			"max_mp": player_data.max_mp,
			"level": player_data.level,
			"exp": player_data.exp,
			"gold": player_data.gold,
			"atk": player_data.atk,
			"def": player_data.def,
			"spd": player_data.spd,
			"luk": player_data.luk,
			"skills": player_data.skills,
			"weapon": player_data.weapon,
			"armor": player_data.armor,
			"accessory": player_data.accessory,
			"weapon_enhance": player_data.weapon_enhance,
			"armor_enhance": player_data.armor_enhance,
			"accessory_enhance": player_data.accessory_enhance,
			"inventory": player_data.inventory,
			"quest_log": player_data.quest_log,
			"completed_quests": player_data.completed_quests
		},
		"progress": {
			"current_floor": current_floor
		},
		"game_state": {
			"bard_legendary_song_atk_boost": bard_legendary_song_atk_boost,
			"bard_legendary_song_def_boost": bard_legendary_song_def_boost,
			"skill_cooldowns": skill_cooldowns,
			"summoner_fusion_active": summoner_fusion_active,
			"summoner_fusion_turns": summoner_fusion_turns,
			"summoner_fusion_power": summoner_fusion_power,
			"summoner_fusion_hp": summoner_fusion_hp
		},
		"achievements": {
			"stats": achievement_stats,
			"unlocked": unlocked_achievements
		}
	}

	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		show_message("💾 存档成功!存档槽 %d" % (slot + 1))
		if audio_manager:
			audio_manager.play_sfx("purchase")
		return true
	else:
		show_message("❌ 存档失败!")
		return false

func load_game(slot: int) -> bool:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		show_message("存档槽 %d 不存在!" % (slot + 1))
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		show_message("❌ 读取存档失败!")
		return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		show_message("❌ 存档数据损坏!")
		return false

	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		show_message("❌ 存档格式错误!")
		return false

	# 恢复玩家数据
	var pdata = save_data.get("player", {})
	player_data = _get_player_data().new()
	player_data.job = pdata.get("job", 0)
	player_data.hp = pdata.get("hp", 100)
	player_data.max_hp = pdata.get("max_hp", 100)
	player_data.mp = pdata.get("mp", 30)
	player_data.max_mp = pdata.get("max_mp", 30)
	player_data.level = pdata.get("level", 1)
	player_data.exp = pdata.get("exp", 0)
	player_data.gold = pdata.get("gold", 0)
	player_data.atk = pdata.get("atk", 14)
	player_data.def = pdata.get("def", 6)
	player_data.spd = pdata.get("spd", 5)
	player_data.luk = pdata.get("luk", 3)
	player_data.skills = pdata.get("skills", [])
	player_data.weapon = pdata.get("weapon", {})
	player_data.armor = pdata.get("armor", {})
	player_data.accessory = pdata.get("accessory", {})
	player_data.weapon_enhance = pdata.get("weapon_enhance", 0)
	player_data.armor_enhance = pdata.get("armor_enhance", 0)
	player_data.accessory_enhance = pdata.get("accessory_enhance", 0)
	player_data.inventory = pdata.get("inventory", [])
	player_data.quest_log = pdata.get("quest_log", [])
	player_data.completed_quests = pdata.get("completed_quests", [])

	# 恢复进度
	var prog = save_data.get("progress", {})
	current_floor = prog.get("current_floor", 1)

	# 恢复游戏状态(吟游诗人永久增益/技能冷却/召唤融合)
	var gst = save_data.get("game_state", {})
	bard_legendary_song_atk_boost = gst.get("bard_legendary_song_atk_boost", 0)
	bard_legendary_song_def_boost = gst.get("bard_legendary_song_def_boost", 0)
	skill_cooldowns = gst.get("skill_cooldowns", {})
	summoner_fusion_active = gst.get("summoner_fusion_active", false)
	summoner_fusion_turns = gst.get("summoner_fusion_turns", 0)
	summoner_fusion_power = gst.get("summoner_fusion_power", 0)
	summoner_fusion_hp = gst.get("summoner_fusion_hp", 0)

	# 恢复成就数据
	var ach_data = save_data.get("achievements", {})
	achievement_stats = ach_data.get("stats", achievement_stats.duplicate(true))
	unlocked_achievements = ach_data.get("unlocked", [])
	_floor_damage_taken = 0  # 重置本层受伤计数

	# 关闭可能残留的通知UI
	if achievement_notification_ui:
		achievement_notification_ui.queue_free()
		achievement_notification_ui = null

	show_message("📂 读档成功!%s Lv.%d" % [player_data.get_job_name(), player_data.level])
	if audio_manager:
		audio_manager.play_sfx("purchase")
	return true

func delete_save(slot: int) -> bool:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		show_message("🗑️ 删除存档 %d" % (slot + 1))
		return true
	return false

func _get_save_info(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return {}

	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		return {}

	var pdata = save_data.get("player", {})
	return {
		"job_name": pdata.get("job_name", "未知"),
		"level": pdata.get("level", 1),
		"floor": save_data.get("progress", {}).get("current_floor", 1),
		"gold": pdata.get("gold", 0),
		"timestamp": save_data.get("timestamp", ""),
		"exists": true
	}

# ==================== 存档UI ====================

var save_ui: Control = null
var _save_slot_buttons: Array = []

func _open_save_ui():
	if game_state == State.BATTLE or game_state == State.SHOP:
		return
	if save_ui != null:
		_close_save_ui()
		return
	_close_save_ui()

	save_ui = Control.new()
	save_ui.name = "SaveUI"
	save_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(save_ui)

	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.gui_input.connect(_on_save_overlay_click)
	save_ui.add_child(overlay)

	var panel = Panel.new()
	panel.name = "SavePanel"
	panel.position = Vector2(340, 160)
	panel.size = Vector2(600, 400)
	panel.self_modulate = Color(0.04, 0.04, 0.08, 0.95)
	panel.add_theme_stylebox_override("panel", _create_stylebox())
	save_ui.add_child(panel)

	var title = Label.new()
	title.position = Vector2(20, 15)
	title.text = "💾 存档 / 读档"
	title.add_theme_color_override("font_color", PALETTE.gold)
	title.add_theme_font_size_override("font_size", 20)
	panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.position = Vector2(550, 10)
	close_btn.size = Vector2(40, 40)
	close_btn.pressed.connect(_close_save_ui)
	panel.add_child(close_btn)

	# 存档槽
	_save_slot_buttons.clear()
	for slot in range(SAVE_SLOTS):
		var info = _get_save_info(slot)
		var sy = 70 + slot * 100
		var slot_panel = Panel.new()
		slot_panel.name = "Slot_%d" % slot
		slot_panel.position = Vector2(20, sy)
		slot_panel.size = Vector2(560, 85)
		var sstyle = StyleBoxFlat.new()
		if info.get("exists", false):
			sstyle.bg_color = Color(0.06, 0.08, 0.06, 0.95)
			sstyle.border_color = Color(0.3, 0.5, 0.3)
		else:
			sstyle.bg_color = Color(0.06, 0.06, 0.1, 0.95)
			sstyle.border_color = Color(0.3, 0.3, 0.35)
		sstyle.border_width_left = 1; sstyle.border_width_top = 1
		sstyle.border_width_right = 1; sstyle.border_width_bottom = 1
		sstyle.corner_radius_top_left = 3; sstyle.corner_radius_top_right = 3
		sstyle.corner_radius_bottom_right = 3; sstyle.corner_radius_bottom_left = 3
		slot_panel.add_theme_stylebox_override("panel", sstyle)
		panel.add_child(slot_panel)

		var slot_lbl = Label.new()
		slot_lbl.position = Vector2(15, 10)
		slot_lbl.text = "存档槽 %d" % (slot + 1)
		slot_lbl.add_theme_color_override("font_color", PALETTE.gold)
		slot_lbl.add_theme_font_size_override("font_size", 14)
		slot_panel.add_child(slot_lbl)

		if info.get("exists", false):
			var detail_lbl = Label.new()
			detail_lbl.position = Vector2(15, 35)
			detail_lbl.text = "%s Lv.%d | 第%d层 | %d金币\n%s" % [
				info.get("job_name", "?"), info.get("level", 1),
				info.get("floor", 1), info.get("gold", 0),
				info.get("timestamp", "")
			]
			detail_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
			detail_lbl.add_theme_font_size_override("font_size", 12)
			slot_panel.add_child(detail_lbl)

			var save_btn = Button.new()
			save_btn.text = "💾 覆盖"
			save_btn.position = Vector2(380, 10)
			save_btn.size = Vector2(80, 32)
			save_btn.add_theme_font_size_override("font_size", 12)
			save_btn.pressed.connect(_on_save_slot_write.bind(slot))
			slot_panel.add_child(save_btn)
			_save_slot_buttons.append(save_btn)

			var load_btn = Button.new()
			load_btn.text = "📂 读档"
			load_btn.position = Vector2(470, 10)
			load_btn.size = Vector2(80, 32)
			load_btn.add_theme_font_size_override("font_size", 12)
			load_btn.pressed.connect(_on_save_slot_read.bind(slot))
			slot_panel.add_child(load_btn)
			_save_slot_buttons.append(load_btn)

			var del_btn = Button.new()
			del_btn.text = "🗑️"
			del_btn.position = Vector2(470, 48)
			del_btn.size = Vector2(80, 32)
			del_btn.add_theme_font_size_override("font_size", 12)
			del_btn.pressed.connect(_on_save_slot_delete.bind(slot))
			slot_panel.add_child(del_btn)
		else:
			var empty_lbl = Label.new()
			empty_lbl.position = Vector2(15, 35)
			empty_lbl.text = "(空)"
			empty_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			slot_lbl.add_theme_font_size_override("font_size", 12)
			slot_panel.add_child(empty_lbl)

			var new_btn = Button.new()
			new_btn.text = "💾 新建存档"
			new_btn.position = Vector2(380, 25)
			new_btn.size = Vector2(160, 35)
			new_btn.add_theme_font_size_override("font_size", 13)
			new_btn.pressed.connect(_on_save_slot_write.bind(slot))
			slot_panel.add_child(new_btn)
			# 空槽追加3个占位元素保持数组对称(与有存档槽一致)
			_save_slot_buttons.append(new_btn)
			_save_slot_buttons.append(null)  # load_btn占位
			_save_slot_buttons.append(null)  # del_btn占位

func _close_save_ui():
	if save_ui != null:
		save_ui.queue_free()
		save_ui = null
	_save_slot_buttons.clear()

func _on_save_overlay_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_save_ui()

func _on_save_slot_write(slot: int):
	save_game(slot)
	_close_save_ui()

func _on_save_slot_read(slot: int):
	if load_game(slot):
		_close_save_ui()
		# 重建UI以反映加载的数据
		_rebuild_ui_from_player_data()
		# 重置迷雾和探索
		for key in fog_map:
			var fog = fog_map[key]
			fog.color = Color(0.02, 0.02, 0.04, 0.95)
		_reveal_area(player_tile_x, player_tile_y, 5)
		_update_minimap()
		_update_ui()

func _on_save_slot_delete(slot: int):
	delete_save(slot)
	_close_save_ui()

func _rebuild_ui_from_player_data():
	# 当读档后,重新设置玩家精灵
	if player:
		var sprite = player.get_node_or_null("Sprite")
		if sprite:
			sprite.texture = _create_job_texture(player_data.job)
	# 更新UI
	_update_ui()

