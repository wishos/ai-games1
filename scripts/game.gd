extends Node2D

# 游戏状态
enum State { TITLE, EXPLORE, BATTLE, DIALOG, SHOP, CLASS_SELECT }
var game_state = State.CLASS_SELECT

# 玩家数据
var player_data: PlayerData
var player: CharacterBody2D

# 地图
var tile_map: TileMap
var current_floor: int = 1
var fog_map: Dictionary = {}

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
var battle_cry_team_boost: int = 0  # 战吼队友ATK加成（对玩家=自身）
# 法师T2状态
var meteor_burn_turns: int = 0     # 流星火雨灼烧回合
var meteor_burn_dmg: int = 0        # 流星火雨每回合灼烧伤害
var frost_slow_turns: int = 0       # 霜冻领域减速回合
var arcane_shield_mp: int = 0      # 魔法盾MP值
var spell_pierce_turns: int = 0     # 法术穿透回合（无视DEF）
var mana_drain_turns: int = 0       # 魔力回旋回合
var mana_drain_amount: int = 0      # 魔力回旋每次吸取量

# 猎人T2状态
var hunter_evasion_turns: int = 0    # 猎豹加速闪避回合
var hunter_speed_boost_turns: int = 0  # 猎豹加速速度加成回合
var hunter_armor_pierce_turns: int = 0  # 穿甲箭穿透回合
var hunter_trap_dot_dmg: int = 0     # 致命陷阱每回合伤害
var hunter_trap_turns: int = 0        # 致命陷阱持续回合
var hunter_trap_slow: int = 0         # 致命陷阱减速量
# 盗贼T2状态
var thief_poison_turns: int = 0      # 淬毒利刃回合
var thief_poison_dmg: int = 0         # 淬毒利刃伤害
var thief_choke_turns: int = 0        # 锁喉眩晕回合
var thief_combo_count: int = 0         # 致命连击连击计数
var thief_combo_dmg: int = 0           # 致命连击累计伤害
# 牧师T2状态
var priest_mass_heal_mp: int = 0      # 群体治疗MP量（用于分摊护盾）
var priest_dispel_done: bool = false  # 驱散本回合已用
var priest_smite_turns: int = 0        # 神圣仲裁atk降低回合
var priest_smite_defdebuff: int = 0    # 神圣仲裁降低def量
# 骑士T2状态
var knight_shield_bang_dmg: int = 0   # 盾击伤害量（溢出为盾）
var knight_judgment_turns: int = 0     # 圣光审判降低防御回合
var knight_judgment_defdebuff: int = 0 # 圣光审判降低防御量
var knight_iron_wall_turns: int = 0    # 钢铁壁垒持续回合
var knight_iron_wall_defboost: int = 0 # 钢铁壁垒防御加成
# 吟游诗人T2状态
var bard_song_atk_turns: int = 0       # 战斗乐章atk提升回合
var bard_song_atk_boost: int = 0        # 战斗乐章提升量
var bard_rhythm_turns: int = 0          # 疯狂节拍减速回合
var bard_healing_melody_mp: int = 0     # 天籁之音治疗量
# 召唤师T2状态
var summoner_contract_boost_turns: int = 0  # 契约强化回合
var summoner_contract_boost_dmg: int = 0    # 契约强化伤害加成
var summoner_soul_link_turns: int = 0        # 灵魂连接回合
var summoner_soul_link_dmg: int = 0          # 灵魂连接每回合伤害
var summoner_beast_boost_turns: int = 0       # 召唤兽强化回合

# 技能冷却系统
var skill_cooldowns: Dictionary = {}  # {skill_name: remaining_turns}
var battle_started: bool = false     # 战斗是否已开始（用于陷阱被动）

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
var selected_shop_tab: int = 0  # 0=武器 1=防具 2=饰品 3=药水
var shop_tabs: Array = ["⚔️ 武器", "🛡️ 防具", "💍 饰品", "🧪 药水"]
var shop_item_buttons: Array = []
var shop_nearby: bool = false
var shop_sign_pos: Vector2 = Vector2(0, 0)

# 背包
var inventory_ui: Control
var inventory_item_buttons: Array = []
var inventory_open: bool = false

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
]

# 音频管理器
var audio_manager: Node

# 调色板 (Octopath风格)
const PALETTE = {
	"sky_top": Color("#1a1528"),
	"sky_bottom": Color("#3d2a4a"),
	"grass_1": Color("#3a5a2a"),
	"grass_2": Color("#4a6a35"),
	"wall": Color("#4a4a5a"),
	"wall_top": Color("#6a6a7a"),
	"path": Color("#8a7a5a"),
	"hero_cape": Color("#8b2942"),
	"hero_armor": Color("#4a6a8a"),
	"hero_skin": Color("#e8c8a0"),
	"gold": Color("#c9a227")
}

# Boss数据 (第1/3/5/7/8层)
const BOSS_DATA = {
	1: {
		"name": "哥布林王 Grak",
		"title": "第1层Boss",
		"hp": 350, "atk": 25, "def": 12, "spd": 5, "luk": 5,
		"exp": 500, "gold": 300,
		"color": Color(0.3, 0.7, 0.2),
		"phase_hp": 0.3,  # 30%血量触发狂暴
		"skills": ["普通攻击", "怒吼", "召唤哥布林", "狂暴化"],
		"description": "盘踞在地牢入口的哥布林首领，贪婪而狡猾，手下众多。"
	},
	3: {
		"name": "巫妖领主 Lich Lord",
		"title": "第3层Boss",
		"hp": 600, "atk": 45, "def": 15, "spd": 6, "luk": 8,
		"exp": 1200, "gold": 800,
		"color": Color(0.4, 0.4, 0.8),
		"phase_hp": 0.2,  # 20%血量触发不死之身
		"skills": ["暗影冲击", "亡灵大军", "生命虹吸", "灵魂收割", "不死之身"],
		"description": "曾是大陆上最伟大的亡灵法师，因追求永生而堕落为巫妖。"
	},
	5: {
		"name": "熔岩巨魔 Magmato",
		"title": "第5层Boss",
		"hp": 1200, "atk": 55, "def": 35, "spd": 3, "luk": 2,
		"exp": 2500, "gold": 1500,
		"color": Color(0.9, 0.3, 0.1),
		"phase_hp": 0.0,
		"skills": ["岩浆之拳", "熔岩喷射", "碎地重击", "熔岩护甲"],
		"description": "沉睡于火山深处的远古巨魔，体内流淌着岩浆。"
	},
	7: {
		"name": "堕落天使 Seraphiel",
		"title": "第7层Boss",
		"hp": 2000, "atk": 70, "def": 30, "spd": 8, "luk": 12,
		"exp": 5000, "gold": 3000,
		"color": Color(0.8, 0.8, 1.0),
		"phase_hp": 0.0,
		"skills": ["天罚之剑", "神圣裁决", "堕落之光", "命运之手", "羽翼护盾"],
		"description": "曾是天界最强大的守护天使，因质疑神谕而被逐出天堂。"
	},
	8: {
		"name": "远古巨龙 Zephyranthes",
		"title": "最终Boss",
		"hp": 5000, "atk": 100, "def": 50, "spd": 10, "luk": 15,
		"exp": 15000, "gold": 10000,
		"color": Color(0.2, 0.05, 0.4),
		"phase_hp": 0.6,  # 60%进入第二阶段
		"phase2_hp": 0.3,  # 30%进入第三阶段
		"skills": ["龙息", "飓风降临", "召唤雷云", "毁天灭地", "龙鳞护体", "湮灭"],
		"description": "传说中太古时代便存在的巨龙，掌管着天空与风暴的力量。"
	}
}

# 转换状态
var is_transitioning: bool = false
var transition_overlay: ColorRect
var current_boss_data: Dictionary = {}
var boss_phase: int = 1  # Boss战阶段
var boss_enraged: bool = false  # Boss狂暴标记
var boss_shield_stacks: int = 0  # 堕落天使护盾层数
var boss_revived: bool = false  # 巫妖复活标记

# 墙壁碰撞区 (简化)
var wall_rects: Array = []

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

func _show_title_screen():
	# 全屏背景
	var bg = ColorRect.new()
	bg.name = "TitleBG"
	bg.size = Vector2(1280, 720)
	bg.color = PALETTE.sky_top
	add_child(bg)
	
	# 半透明遮罩
	var overlay = ColorRect.new()
	overlay.name = "TitleOverlay"
	overlay.size = Vector2(1280, 720)
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
	
	# 选择职业标签
	var select_label = Label.new()
	select_label.position = Vector2(0, 115)
	select_label.size = Vector2(1000, 35)
	select_label.text = "━━━━━━  选择你的职业  ━━━━━━"
	select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
	select_label.add_theme_font_size_override("font_size", 16)
	title_panel.add_child(select_label)
	
	# 职业数据
	var job_list: Array = [
		{"id": PlayerData.Job.WARRIOR, "name": "⚔️ 战士", "desc": "高血量 · 猛击/防御/冲锋", "color": Color(0.9, 0.3, 0.3)},
		{"id": PlayerData.Job.MAGE, "name": "🔮 法师", "desc": "高魔攻 · 火球/冰霜/闪电", "color": Color(0.3, 0.3, 1.0)},
		{"id": PlayerData.Job.HUNTER, "name": "🏹 猎人", "desc": "高速度 · 狙击/陷阱/毒箭", "color": Color(0.3, 0.8, 0.3)},
		{"id": PlayerData.Job.THIEF, "name": "🗡️ 盗贼", "desc": "高暴击 · 背刺/暗影/消失", "color": Color(0.6, 0.3, 0.8)},
		{"id": PlayerData.Job.PRIEST, "name": "💚 牧师", "desc": "治疗 · 治疗/护盾/复活", "color": Color(0.3, 0.9, 0.5)},
		{"id": PlayerData.Job.KNIGHT, "name": "🛡️ 骑士", "desc": "高防御 · 格挡/斩击/神圣", "color": Color(0.5, 0.7, 0.9)},
		{"id": PlayerData.Job.BARD, "name": "🎵 吟游诗人", "desc": "辅助 · 鼓舞/旋律/沉默", "color": Color(0.9, 0.6, 0.2)},
		{"id": PlayerData.Job.SUMMONER, "name": "🔥 召唤师", "desc": "召唤 · 召唤/契约/共鸣", "color": Color(1.0, 0.4, 0.2)},
	]
	
	# 职业按钮网格 (4×2)
	var start_x = 60
	var start_y = 160
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
		
		# 职业名称
		var jname = Label.new()
		jname.position = Vector2(10, 8)
		jname.text = job["name"]
		jname.add_theme_color_override("font_color", job["color"])
		jname.add_theme_font_size_override("font_size", 16)
		job_btn.add_child(jname)
		
		# 职业描述
		var jdesc = Label.new()
		jdesc.position = Vector2(10, 38)
		jdesc.text = job["desc"]
		jdesc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
		jdesc.add_theme_font_size_override("font_size", 12)
		job_btn.add_child(jdesc)
		
		# 提示
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
	tip.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · F2存档"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	tip.add_theme_font_size_override("font_size", 13)
	title_panel.add_child(tip)

func _on_job_selected(job_id: int):
	# 清理标题画面
	var title_bg = get_node_or_null("TitleBG")
	var title_ov = get_node_or_null("TitleOverlay")
	var title_pn = get_node_or_null("TitlePanel")
	if title_bg: title_bg.queue_free()
	if title_ov: title_ov.queue_free()
	if title_pn: title_pn.queue_free()
	
	# 设置职业
	_setup_player_data(job_id)
	_setup_ui()
	_generate_map()
	_setup_walls()
	_setup_player()
	game_state = State.EXPLORE
	_update_minimap()  # 初始化小地图
	# 切换到探索BGM
	if audio_manager:
		audio_manager.play_bgm("explore")
	print("八方旅人 - Octopath Adventure 已启动!")
	print("当前职业: " + player_data.get_job_name())
	print("技能: " + str(player_data.skills))
	show_message("欢迎，%s！你的冒险开始了..." % player_data.get_job_name())

func _setup_player_data(job_id: int = PlayerData.Job.WARRIOR):
	player_data = PlayerData.new()
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
	
	floor_label = Label.new()
	floor_label.position = Vector2(15, 104)
	floor_label.add_theme_color_override("font_color", Color.WHITE)
	ui_panel.add_child(floor_label)
	
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
	hint_label.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · F2存档"
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
	var texture = _create_job_texture(player_data.job)
	sprite.texture = texture
	player.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	player.add_child(col)
	
	add_child(player)
	show_message("WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I) · F2存档")

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
		PlayerData.Job.WARRIOR: return _create_knight_texture()
		PlayerData.Job.MAGE: return _create_mage_texture()
		PlayerData.Job.HUNTER: return _create_hunter_texture()
		PlayerData.Job.THIEF: return _create_thief_texture()
		PlayerData.Job.PRIEST: return _create_priest_texture()
		PlayerData.Job.KNIGHT: return _create_knight_texture()
		PlayerData.Job.BARD: return _create_bard_texture()
		PlayerData.Job.SUMMONER: return _create_summoner_texture()
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

func _generate_map():
	# 背景
	map_bg = ColorRect.new()
	map_bg.size = Vector2(1280, 720)
	map_bg.position = Vector2(0, 0)
	map_bg.color = PALETTE.sky_top
	add_child(map_bg)
	
	# 地面
	map_ground = ColorRect.new()
	map_ground.size = Vector2(1280, 500)
	map_ground.position = Vector2(0, 200)
	map_ground.color = PALETTE.grass_1
	add_child(map_ground)
	
	# 迷雾
	for x in range(0, 80):
		for y in range(0, 45):
			var fog = ColorRect.new()
			fog.size = Vector2(16, 16)
			fog.position = Vector2(x * 16, y * 16)
			fog.color = Color(0.02, 0.02, 0.04, 0.95)
			fog.name = "fog_%d_%d" % [x, y]
			add_child(fog)
			fog_map[str(x) + "_" + str(y)] = fog
	
	_reveal_area(40, 25, 5)

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
						var alpha = 0.95 - (dist / radius) * 0.85
						fog.color = Color(0.02, 0.02, 0.04, max(0, alpha))

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
	if moved and randf() < 0.003 and is_player_turn:
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
	
	_update_ui()
	_update_minimap()

	# F2 存档/读档快捷键
	if Input.is_key_pressed(KEY_F2) and is_player_turn and game_state == State.EXPLORE:
		_open_save_ui()

func _next_floor():
	if current_floor >= 8:
		show_message("这是最后一层！")
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
	
	# 如果是Boss层，短暂提示后开始Boss战
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
		transition_overlay.size = Vector2(1280, 720)
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
		"hp": int(boss_def["hp"] * mult),
		"max_hp": int(boss_def["hp"] * mult),
		"atk": int(boss_def["atk"] * mult),
		"def": int(boss_def["def"] * mult),
		"spd": boss_def["spd"],
		"exp": boss_def["exp"],
		"gold": boss_def["gold"],
		"color": boss_def["color"],
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
	overlay.size = Vector2(1280, 720)
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
	overlay.size = Vector2(1280, 720)
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
	
	# 角色装备信息（底部）
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
		
		show_message("使用了 %s！" % item_name)
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
		show_message("状态已满，无法使用！")

# ==================== 小地图系统 ====================

# 小地图尺寸 (80x45 地图，缩小显示)
const MINIMAP_COLS: int = 80
const MINIMAP_ROWS: int = 45
const MINIMAP_CELL: int = 2  # 每个小地图格子的像素大小

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

# ==================== 商店系统 ====================

func _get_shop_items_by_tab(tab: int) -> Array:
	match tab:
		0: return SHOP_WEAPONS
		1: return SHOP_ARMORS
		2: return SHOP_ACCESSORIES
		3: return SHOP_POTIONS
	return []

func _open_shop():
	game_state = State.SHOP
	if minimap_container:
		minimap_container.visible = false
	_create_shop_ui()
	show_message("欢迎光临商店！")
	if audio_manager:
		audio_manager.play_bgm("shop")

func _close_shop():
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
	show_message("下次再来！")
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
	overlay.size = Vector2(1280, 720)
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
	
	for i in range(4):
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
	
	# 玩家装备信息（右侧）
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
		for i in range(4):
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

func _on_shop_item_clicked(item: Dictionary):
	if player_data.gold < item["price"]:
		show_message("金钱不足！")
		return
	
	player_data.gold -= item["price"]
	
	if item.has("heal_hp"):
		# 药水：加入背包
		var found = false
		for inv in player_data.inventory:
			if inv.get("type") == item["name"]:
				inv["count"] += 1
				found = true
				break
		if not found:
			player_data.inventory.append({"type": item["name"], "count": 1, "heal_hp": item["heal_hp"], "heal_mp": item["heal_mp"]})
		show_message("购买了 %s ×1" % item["name"])
	else:
		# 装备：直接穿上
		match selected_shop_tab:
			0: # 武器
				player_data.weapon = item
			1: # 防具
				player_data.armor = item
			2: # 饰品
				player_data.accessory = item
		show_message("购买了 %s 并装备！" % item["name"])
	if audio_manager:
		audio_manager.play_sfx("purchase")
	
	# 更新商店UI金币显示
	var shop_panel = shop_ui.get_node_or_null("ShopPanel")
	if shop_panel:
		var gold_disp = shop_panel.get_node_or_null("ShopGold")
		if gold_disp:
			gold_disp.text = "💰 %d 金币" % player_data.gold
		_draw_shop_items(shop_panel)
	
	_update_ui()

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
	vanish_turns = 0
	berserk_turns = 0
	berserk_atk_boost = 0
	battle_cry_turns = 0
	battle_cry_atk_boost = 0
	battle_cry_team_boost = 0
	# 法师T2状态重置
	meteor_burn_turns = 0
	meteor_burn_dmg = 0
	frost_slow_turns = 0
	arcane_shield_mp = 0
	spell_pierce_turns = 0
	mana_drain_turns = 0
	mana_drain_amount = 0
	# 猎人T2状态重置
	hunter_evasion_turns = 0
	hunter_speed_boost_turns = 0
	hunter_armor_pierce_turns = 0
	hunter_trap_dot_dmg = 0
	hunter_trap_turns = 0
	hunter_trap_slow = 0
	# 盗贼T2状态重置
	thief_poison_turns = 0
	thief_poison_dmg = 0
	thief_choke_turns = 0
	thief_combo_count = 0
	thief_combo_dmg = 0
	# 牧师T2状态重置
	priest_mass_heal_mp = 0
	priest_dispel_done = false
	priest_smite_turns = 0
	priest_smite_defdebuff = 0
	# 骑士T2状态重置
	knight_shield_bang_dmg = 0
	knight_judgment_turns = 0
	knight_judgment_defdebuff = 0
	knight_iron_wall_turns = 0
	knight_iron_wall_defboost = 0
	# 吟游诗人T2状态重置
	bard_song_atk_turns = 0
	bard_song_atk_boost = 0
	bard_rhythm_turns = 0
	bard_healing_melody_mp = 0
	# 召唤师T2状态重置
	summoner_contract_boost_turns = 0
	summoner_contract_boost_dmg = 0
	summoner_soul_link_turns = 0
	summoner_soul_link_dmg = 0
	summoner_beast_boost_turns = 0
	
	# 生成敌人（根据层数选择敌人类型）
	var enemy_pool = EnemyData.get_floor_enemies(current_floor)
	var etype = enemy_pool[randi() % enemy_pool.size()]
	var edata = EnemyData.new(etype, current_floor)
	current_enemy = {
		"name": edata.name,
		"hp": edata.hp,
		"max_hp": edata.max_hp,
		"atk": edata.atk,
		"def": edata.def,
		"spd": edata.spd,
		"exp": edata.exp_reward,
		"gold": edata.gold_reward,
		"color": edata.color,
		"is_boss": false
	}
	
	show_message("遭遇了 " + current_enemy["name"] + "！")
	_create_battle_ui()
	# 重置技能冷却
	skill_cooldowns.clear()
	battle_started = true
	# 切换到战斗BGM
	if audio_manager:
		if current_floor >= 7 or current_enemy["name"] == "远古巨龙":
			audio_manager.play_bgm("boss")
		else:
			audio_manager.play_bgm("battle")
	
	# 重置召唤师状态
	resonance_stacks = 0
	contract_active = false
	contract_turns = 0
	
	# 猎人陷阱被动检测
	if player_data.job == PlayerData.Job.HUNTER and player_data.skills.has("陷阱"):
		trapped = true
		await get_tree().create_timer(0.5).timeout
		var trap_dmg = int(player_data.attack_power() * 1.5)
		current_enemy["hp"] -= trap_dmg
		_battle_add_log("⚡ 陷阱触发！造成 %d 伤害" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -25))
		_update_enemy_hp_bar()
		_check_battle_end()

func _start_boss_battle():
	game_state = State.BATTLE
	is_player_turn = true
	player_defending = false
	player_shield = 0
	poison_stacks = 0
	poison_turns = 0
	trapped = false
	enemy_stun_turns = 0
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
	# 猎人T2状态重置
	hunter_evasion_turns = 0
	hunter_speed_boost_turns = 0
	hunter_armor_pierce_turns = 0
	hunter_trap_dot_dmg = 0
	hunter_trap_turns = 0
	hunter_trap_slow = 0
	# 盗贼T2状态重置
	thief_poison_turns = 0
	thief_poison_dmg = 0
	thief_choke_turns = 0
	thief_combo_count = 0
	thief_combo_dmg = 0
	# 牧师T2状态重置
	priest_mass_heal_mp = 0
	priest_dispel_done = false
	priest_smite_turns = 0
	priest_smite_defdebuff = 0
	# 骑士T2状态重置
	knight_shield_bang_dmg = 0
	knight_judgment_turns = 0
	knight_judgment_defdebuff = 0
	knight_iron_wall_turns = 0
	knight_iron_wall_defboost = 0
	# 吟游诗人T2状态重置
	bard_song_atk_turns = 0
	bard_song_atk_boost = 0
	bard_rhythm_turns = 0
	bard_healing_melody_mp = 0
	# 召唤师T2状态重置
	summoner_contract_boost_turns = 0
	summoner_contract_boost_dmg = 0
	summoner_soul_link_turns = 0
	summoner_soul_link_dmg = 0
	summoner_beast_boost_turns = 0
	boss_phase = 1
	boss_enraged = false
	boss_shield_stacks = 0
	boss_revived = false
	
	# 使用Boss数据
	current_enemy = current_boss_data.duplicate()
	current_enemy["is_boss"] = true
	
	show_message("⚠️ Boss战: " + current_enemy["name"] + "！")
	_create_battle_ui()
	# 重置技能冷却
	skill_cooldowns.clear()
	battle_started = true
	if audio_manager:
		audio_manager.play_bgm("boss")
	
	# 猎人陷阱对Boss也有效
	if player_data.job == PlayerData.Job.HUNTER and player_data.skills.has("陷阱"):
		trapped = true
		await get_tree().create_timer(0.5).timeout
		var trap_dmg = int(player_data.attack_power() * 1.0)  # Boss战陷阱伤害降低
		current_enemy["hp"] -= trap_dmg
		_battle_add_log("⚡ 陷阱触发！对Boss造成 %d 伤害" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -25))
		_update_enemy_hp_bar()
		_check_battle_end()

func _create_battle_ui():
	# 隐藏小地图
	if minimap_container:
		minimap_container.visible = false
	# 暗色遮罩
	var overlay = ColorRect.new()
	overlay.name = "BattleOverlay"
	overlay.size = Vector2(1280, 720)
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
	enemy_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	enemy_panel.add_theme_stylebox_override("panel", _create_stylebox())
	battle_ui.add_child(enemy_panel)
	
	# 敌人名称
	enemy_name_label = Label.new()
	enemy_name_label.position = Vector2(20, 15)
	enemy_name_label.text = current_enemy["name"]
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.5))
	enemy_panel.add_child(enemy_name_label)
	
	# 敌人精灵
	enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.texture = _create_enemy_texture(current_enemy["color"])
	enemy_sprite.position = Vector2(200, 100)
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
	battle_log.text = ">>> 战斗开始！\n"
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

func _create_battle_portrait_panel(parent: Control):
	# 整体肖像面板 (右上角，敌方面板下方)
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
	
	# 内部装饰背景（肖像区域）
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
	
	# 肖像精灵容器（用于动画）
	var portrait_container = Node2D.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.position = Vector2(75, 75)
	portrait_bg.add_child(portrait_container)
	
	# 肖像底层阴影
	var portrait_shadow = Sprite2D.new()
	portrait_shadow.name = "PortraitShadow"
	portrait_shadow.texture = _create_portrait_shadow()
	portrait_shadow.position = Vector2(0, 35)
	portrait_container.add_child(portrait_shadow)
	
	# 肖像主精灵
	var portrait_sprite = Sprite2D.new()
	portrait_sprite.name = "PortraitSprite"
	portrait_sprite.texture = _create_job_portrait_texture(player_data.job)
	portrait_sprite.position = Vector2(0, 0)
	portrait_container.add_child(portrait_sprite)
	
	# 受伤/治疗闪红特效
	var portrait_flash = Sprite2D.new()
	portrait_flash.name = "PortraitFlash"
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
	
	# 状态效果标签（文字版，备用）
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
		PlayerData.Job.WARRIOR:
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
		PlayerData.Job.MAGE:
			# 法师: 蓝袍，手持法杖
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
		PlayerData.Job.HUNTER:
			# 猎人: 绿棕猎装，背弓
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
		PlayerData.Job.THIEF:
			# 盗贼: 黑色夜行衣，双刃
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
		PlayerData.Job.PRIEST:
			# 牧师: 白色长袍，金色圣徽
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
		PlayerData.Job.KNIGHT:
			# 骑士: 全身板甲，蓝披风
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
		PlayerData.Job.BARD:
			# 吟游诗人: 彩色斗篷，琵琶
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
		PlayerData.Job.SUMMONER:
			# 召唤师: 暗紫袍，符文，魔法球
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

func _create_hp_bar_fill_mp() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.35, 0.85)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_enemy_texture(col: Color) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match current_enemy["name"]:
		# ===== 1-2层：新手区 =====
		"史莱姆":
			# 史莱姆形状
			for x in range(8, 24):
				img.set_pixel(x, 20, col)
				img.set_pixel(x, 22, col)
				img.set_pixel(x, 24, col)
			for x in range(10, 22):
				img.set_pixel(x, 18, col)
				img.set_pixel(x, 16, col)
			for x in range(12, 20):
				img.set_pixel(x, 14, col)
			img.set_pixel(14, 18, Color.WHITE)
			img.set_pixel(18, 18, Color.WHITE)
			img.set_pixel(15, 19, Color.BLACK)
			img.set_pixel(19, 19, Color.BLACK)
		"洞穴蝙蝠":
			# 蝙蝠（翅膀展开）
			img.set_pixel(14, 8, col)   # 头
			img.set_pixel(18, 8, col)
			img.set_pixel(14, 10, Color.RED)  # 眼睛
			img.set_pixel(18, 10, Color.RED)
			_set_pixel_line(img, 2, 14, 14, 14, col)  # 左翼
			_set_pixel_line(img, 18, 14, 30, 14, col)  # 右翼
			_set_pixel_line(img, 4, 18, 12, 18, col)  # 左翼下
			_set_pixel_line(img, 20, 18, 28, 18, col)  # 右翼下
			img.set_pixel(15, 12, col)  # 身体
			img.set_pixel(17, 12, col)
			img.set_pixel(16, 14, col)
		"野猪":
			# 野猪
			_set_pixel_line(img, 8, 14, 22, 14, col)  # 头顶
			img.set_pixel(10, 12, col)   # 獠牙上
			img.set_pixel(24, 14, col)  # 獠牙下
			img.set_pixel(12, 14, Color.RED)  # 眼睛
			img.set_pixel(18, 14, Color.RED)  # 眼睛
			_set_pixel_line(img, 8, 18, 22, 18, col)  # 身
			_set_pixel_line(img, 6, 22, 10, 22, col)  # 腿前
			_set_pixel_line(img, 18, 22, 22, 22, col)  # 腿后
			img.set_pixel(6, 26, col)   # 蹄
			img.set_pixel(22, 26, col)  # 蹄
		# ===== 3-4层：中级区 =====
		"骷髅战士":
			# 骷髅
			_set_pixel_line(img, 14, 6, 18, 6, col)  # 头顶
			_set_pixel_line(img, 12, 10, 20, 10, col)  # 眼窝
			img.set_pixel(14, 10, Color.RED)
			img.set_pixel(18, 10, Color.RED)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 下巴
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 颈
			_set_pixel_line(img, 10, 20, 22, 20, col)  # 身体
			_set_pixel_line(img, 8, 24, 24, 24, col)   # 骨盆
			_set_pixel_line(img, 8, 28, 10, 28, col)  # 腿左
			_set_pixel_line(img, 22, 28, 24, 28, col)  # 腿右
		"哥布林":
			# 哥布林（小绿怪）
			img.set_pixel(12, 6, col)   # 左耳
			img.set_pixel(20, 6, col)  # 右耳
			_set_pixel_line(img, 10, 8, 22, 8, col)  # 头顶
			img.set_pixel(13, 11, Color.YELLOW)  # 眼睛
			img.set_pixel(19, 11, Color.YELLOW)
			img.set_pixel(14, 12, Color.BLACK)
			img.set_pixel(18, 12, Color.BLACK)
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 嘴（狞笑）
			img.set_pixel(13, 16, Color.BLACK)
			img.set_pixel(19, 16, Color.BLACK)
			_set_pixel_line(img, 10, 18, 22, 18, col)  # 身
			_set_pixel_line(img, 8, 24, 24, 24, col)  # 腿
		"幽灵":
			# 幽灵（半透明效果用淡色）
			var ghost_col = Color(col.r, col.g, col.b, 0.7)
			_set_pixel_line(img, 12, 6, 20, 6, ghost_col)  # 头顶
			img.set_pixel(14, 10, Color.BLACK)  # 眼
			img.set_pixel(18, 10, Color.BLACK)
			_set_pixel_line(img, 10, 12, 22, 12, ghost_col)  # 脸
			_set_pixel_line(img, 8, 16, 24, 16, ghost_col)  # 身
			_set_pixel_line(img, 8, 20, 24, 20, ghost_col)  # 下摆（波浪）
			img.set_pixel(10, 22, ghost_col)
			img.set_pixel(16, 24, ghost_col)
			img.set_pixel(22, 22, ghost_col)
		# ===== 5-6层：高级区 =====
		"深渊恶魔":
			# 恶魔
			_set_pixel_line(img, 8, 6, 12, 6, col)   # 角左
			_set_pixel_line(img, 20, 6, 24, 6, col)  # 角右
			_set_pixel_line(img, 10, 8, 22, 8, col)   # 头顶
			_set_pixel_line(img, 10, 12, 22, 12, col)  # 眼线
			img.set_pixel(13, 12, Color.YELLOW)
			img.set_pixel(19, 12, Color.YELLOW)
			img.set_pixel(13, 13, Color.BLACK)
			img.set_pixel(19, 13, Color.BLACK)
			_set_pixel_line(img, 10, 16, 22, 16, col)  # 颧骨
			_set_pixel_line(img, 12, 20, 20, 20, col)  # 嘴
			img.set_pixel(14, 20, Color.BLACK)
			img.set_pixel(15, 20, Color.BLACK)
			img.set_pixel(17, 20, Color.BLACK)
			img.set_pixel(18, 20, Color.BLACK)
			_set_pixel_line(img, 8, 22, 24, 22, col)  # 身
			_set_pixel_line(img, 8, 26, 24, 26, col)   # 腿
		"兽人战士":
			# 兽人（粗壮）
			_set_pixel_line(img, 10, 6, 22, 6, col)  # 头顶
			img.set_pixel(8, 8, col)   # 獠牙
			img.set_pixel(24, 8, col)
			img.set_pixel(13, 10, Color.RED)  # 眼睛
			img.set_pixel(19, 10, Color.RED)
			_set_pixel_line(img, 10, 14, 22, 14, col)  # 脸
			_set_pixel_line(img, 8, 18, 24, 18, col)  # 身（宽）
			_set_pixel_line(img, 4, 26, 12, 26, col)  # 粗腿左
			_set_pixel_line(img, 20, 26, 28, 26, col)  # 粗腿右
		"暗黑骷髅":
			# 暗黑骷髅（蓝黑色调）
			_set_pixel_line(img, 14, 4, 18, 4, col)  # 冠
			_set_pixel_line(img, 12, 8, 20, 8, col)  # 头顶
			_set_pixel_line(img, 10, 12, 22, 12, col)  # 眼窝
			img.set_pixel(14, 12, Color.BLUE)  # 幽蓝眼火
			img.set_pixel(18, 12, Color.BLUE)
			_set_pixel_line(img, 12, 16, 20, 16, col)  # 下巴
			_set_pixel_line(img, 10, 20, 22, 20, col)  # 身体
			_set_pixel_line(img, 6, 26, 12, 26, col)  # 腿（左持剑）
			_set_pixel_line(img, 20, 26, 26, 26, col)  # 腿右
			_set_pixel_line(img, 4, 18, 6, 26, col)  # 剑柄
		# ===== 7-8层：精英区 =====
		"暗影刺客":
			# 暗影刺客（黑衣人）
			_set_pixel_line(img, 12, 4, 20, 4, col)  # 兜帽顶
			_set_pixel_line(img, 10, 8, 22, 8, col)  # 兜帽
			img.set_pixel(14, 11, Color.RED)  # 眼睛（杀气）
			img.set_pixel(18, 11, Color.RED)
			_set_pixel_line(img, 12, 14, 20, 14, col)  # 脸（暗）
			_set_pixel_line(img, 10, 16, 22, 16, col)  # 披风
			_set_pixel_line(img, 8, 20, 24, 20, col)  # 身
			_set_pixel_line(img, 6, 28, 12, 28, col)  # 腿（蹲伏）
			_set_pixel_line(img, 20, 28, 26, 28, col)
		"暗黑骑士":
			# 暗黑骑士（重甲）
			_set_pixel_line(img, 10, 4, 22, 4, col)  # 头盔顶
			_set_pixel_line(img, 8, 8, 24, 8, col)  # 头盔
			img.set_pixel(14, 10, Color.RED)  # 眼缝
			img.set_pixel(18, 10, Color.RED)
			_set_pixel_line(img, 8, 14, 24, 14, col)  # 肩甲
			_set_pixel_line(img, 10, 18, 22, 18, col)  # 胸甲
			_set_pixel_line(img, 10, 22, 22, 22, col)  # 腰甲
			_set_pixel_line(img, 6, 28, 14, 28, col)  # 腿甲左
			_set_pixel_line(img, 18, 28, 26, 28, col)  # 腿甲右
			img.set_pixel(4, 14, col)   # 剑柄
			img.set_pixel(2, 14, col)
		"远古巨龙":
			# 巨龙
			_set_pixel_line(img, 6, 8, 10, 8, col)   # 角
			_set_pixel_line(img, 22, 8, 26, 8, col)  # 角
			_set_pixel_line(img, 8, 10, 24, 10, col)
			img.set_pixel(12, 12, Color.YELLOW)
			img.set_pixel(20, 12, Color.YELLOW)
			img.set_pixel(12, 13, Color.BLACK)
			img.set_pixel(20, 13, Color.BLACK)
			_set_pixel_line(img, 10, 16, 22, 16, col)
			_set_pixel_line(img, 8, 20, 24, 20, col)
			_set_pixel_line(img, 6, 24, 26, 24, col)
			_set_pixel_line(img, 4, 28, 8, 28, col)  # 尾
			_set_pixel_line(img, 24, 28, 28, 28, col) # 尾
	
	var texture = ImageTexture.create_from_image(img)
	return texture

var _skill_menu_open: bool = false

# 技能冷却数据（回合数，0=无冷却）
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
	# 盗贼 T2
	"影遁": 4, "淬毒利刃": 3, "锁喉": 4,
	# 牧师 T2
	"群体治疗": 5, "驱散": 3, "神圣仲裁": 4,
	# 骑士 T2
	"盾击": 3, "圣光审判": 4, "钢铁壁垒": 5,
	# 吟游诗人 T2
	"战斗乐章": 3, "疯狂节拍": 4, "天籁之音": 5,
	# 召唤师 T2
	"契约强化": 4, "灵魂连接": 3, "召唤兽强化": 4
}

# 计算战斗中有效的攻击力（含buff加成）
func _get_effective_atk() -> int:
	var atk = player_data.attack_power()
	atk += battle_cry_atk_boost  # 战吼ATK加成
	atk += berserk_atk_boost     # 狂暴ATK加成
	atk += bard_song_atk_boost    # 战斗乐章ATK加成
	return atk

# 法术穿透：无视敌人防御，消耗1层
func _consume_spell_pierce() -> int:
	# 穿甲箭：无视防御
	if hunter_armor_pierce_turns > 0:
		return 0
	# 法术穿透：无视防御
	if spell_pierce_turns > 0:
		spell_pierce_turns -= 1
		if spell_pierce_turns <= 0:
			_battle_add_log("💠 法术穿透效果消失")
		return 0  # 无视防御
	return current_enemy["def"]  # 正常防御

func _get_skill_cooldown(skill: String) -> int:
	return _SKILL_COOLDOWNS.get(skill, 1)
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
		"影遁": 25, "淬毒利刃": 25, "锁喉": 30,
		"群体治疗": 35, "驱散": 20, "神圣仲裁": 35,
		"盾击": 15, "圣光审判": 30, "钢铁壁垒": 25,
		"战斗乐章": 20, "疯狂节拍": 35, "天籁之音": 40,
		"契约强化": 30, "灵魂连接": 30, "召唤兽强化": 25
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
			"契约强化", "灵魂连接", "召唤兽强化"
		]
		var is_t2 = t2_skills.has(skill)
		var level_locked = is_t2 and player_data.level < 10
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
		var level_text = " Lv10" if is_t2 else ""
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

func _on_skill_selected(skill_name: String):
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
		"影遁": 25, "淬毒利刃": 25, "锁喉": 30,
		"群体治疗": 35, "驱散": 20, "神圣仲裁": 35,
		"盾击": 15, "圣光审判": 30, "钢铁壁垒": 25,
		"战斗乐章": 20, "疯狂节拍": 35, "天籁之音": 40,
		"契约强化": 30, "灵魂连接": 30, "召唤兽强化": 25
	}
	var cost = mp_cost.get(skill_name, 0)
	if player_data.mp < cost:
		_battle_add_log("MP不足！")
		return
	player_data.mp -= cost
	pending_skill_index = -1
	
	# 检查冷却
	var cd = _get_skill_cooldown(skill_name)
	if cd > 0 and skill_cooldowns.get(skill_name, 0) > 0:
		player_data.mp += cost  #  refunded
		_battle_add_log("⚠️ %s 冷却中（还需%d回合）！" % [skill_name, skill_cooldowns[skill_name]])
		return
	
	match skill_name:
		# 战士
		"猛击":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 1.5 - pierce_def + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 猛击！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg)
		"防御":
			player_defending = true
			player_shield = int(player_data.defense() * 0.5)
			player_data.mp = min(player_data.max_mp, player_data.mp + 5)
			_battle_add_log("🛡️ 防御姿态！伤害减半，回复5MP")
		"冲锋":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 2.5 - pierce_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			enemy_stun_turns = 1
			_battle_add_log("🐎 冲锋！造成 %d 伤害，敌人眩晕！" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -25))
		# 战士 T2 (狂战士路线)
		"血之狂暴":
			berserk_turns = 3
			berserk_atk_boost = int(_get_effective_atk() * 0.3)
			_battle_add_log("💢 血之狂暴！ATK+30%，每回合自损10HP，持续3回合")
			_spawn_player_damage("BERSERK!", "buff")
		"旋风斩":
			var hits = 2 + randi() % 3  # 2-4次攻击
			var total_dmg = 0
			for i in range(hits):
				var pierce_def = _consume_spell_pierce()
				var hit_dmg = int(_get_effective_atk() * 1.2 - pierce_def + randi() % 7 - 3)
				hit_dmg = max(1, hit_dmg)
				current_enemy["hp"] -= hit_dmg
				total_dmg += hit_dmg
				await get_tree().create_timer(0.2).timeout
			_battle_add_log("🌀 旋风斩！连续攻击%d次，造成 %d 伤害！" % [hits, total_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % total_dmg, "crit", Vector2(0, -35))
		"战吼":
			battle_cry_turns = 2
			battle_cry_atk_boost = int(_get_effective_atk() * 0.4)
			battle_cry_team_boost = int(_get_effective_atk() * 0.15)
			_battle_add_log("📢 战吼！自身ATK+40%，持续2回合")
			_spawn_player_damage("ATK+40%", "buff")
		# 法师
		"火球":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 2.0 - pierce_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🔥 火球术！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(randi()%20-10, -30))
		"冰霜":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 1.8 - pierce_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			current_enemy["spd"] = max(1, current_enemy["spd"] - 2)
			_battle_add_log("❄️ 冰霜术！造成 %d 伤害，敌人速度降低！" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -20))
		"闪电":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 3.0 - pierce_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚡ 闪电术！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "crit", Vector2(0, -35))
		# 法师 T2 (元素大师路线)
		"流星火雨":
			var pierce_def = _consume_spell_pierce()
			var burn_dmg = int(_get_effective_atk() * 0.8)
			current_enemy["hp"] -= burn_dmg
			meteor_burn_turns = 3
			meteor_burn_dmg = burn_dmg
			_battle_add_log("🌠 流星火雨！立即造成 %d 伤害，灼烧 %d 伤害/回合×3回合" % [burn_dmg, burn_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % burn_dmg, "crit", Vector2(0, -40))
		"霜冻领域":
			var pierce_def = _consume_spell_pierce()
			var f_dmg = int(_get_effective_atk() * 1.5 - pierce_def + randi() % 11 - 5)
			f_dmg = max(1, f_dmg)
			current_enemy["hp"] -= f_dmg
			frost_slow_turns = 2
			_battle_add_log("❄️ 霜冻领域！造成 %d 伤害，敌人速度-50%%持续2回合" % f_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % f_dmg, "damage", Vector2(0, -25))
		"连锁闪电":
			var pierce_def = _consume_spell_pierce()
			var chain_dmg1 = int(_get_effective_atk() * 2.5 - pierce_def + randi() % 7 - 3)
			chain_dmg1 = max(1, chain_dmg1)
			current_enemy["hp"] -= chain_dmg1
			_battle_add_log("⚡ 连锁闪电！造成 %d 伤害" % chain_dmg1)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % chain_dmg1, "crit", Vector2(0, -35))
			# 连锁效果：本回合内额外造成递减伤害
			await get_tree().create_timer(0.3).timeout
			var chain_dmg2 = int(_get_effective_atk() * 1.5 - _consume_spell_pierce() + randi() % 5 - 2)
			chain_dmg2 = max(1, chain_dmg2)
			current_enemy["hp"] -= chain_dmg2
			_battle_add_log("⚡⚡ 闪电连锁！追加 %d 伤害" % chain_dmg2)
			_spawn_enemy_damage("%d" % chain_dmg2, "crit", Vector2(15, -20))
		# 法师 T2 (奥术师路线)
		"魔法盾":
			arcane_shield_mp = int(player_data.max_mp * 0.8)
			player_shield += arcane_shield_mp
			_battle_add_log("🔮 魔法盾！消耗 %d MP，护盾值+%d（下次受击时优先消耗）" % [arcane_shield_mp, arcane_shield_mp])
			_spawn_player_damage("+%d" % arcane_shield_mp, "shield")
		"法术穿透":
			spell_pierce_turns = 2
			_battle_add_log("💠 法术穿透！下2次攻击无视敌人防御")
			_spawn_player_damage("SPIERCE!", "buff")
		"魔力回旋":
			mana_drain_turns = 3
			mana_drain_amount = int(player_data.max_mp * 0.15)
			_battle_add_log("🌀 魔力回旋！持续3回合，每回合吸取 %d MP并恢复等量HP" % mana_drain_amount)
			_spawn_player_damage("DRAIN x3", "buff")
		# 猎人
		"狙击":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 2.0 - pierce_def + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🎯 狙击！必定命中，造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "crit", Vector2(0, -30))
		"毒箭":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 1.5 - pierce_def + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			poison_stacks += 1
			poison_damage = 5
			poison_turns = 3
			_battle_add_log("🏹 毒箭！造成 %d 伤害+每回合5毒性伤害×3回合" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "poison", Vector2(0, -25))
		# 盗贼
		"背刺":
			var is_crit = randi() % 100 < player_data.luk * 3
			var pierce_def = _consume_spell_pierce()
			var base_dmg = int(_get_effective_atk() * 2.2 - pierce_def + randi() % 7 - 3)
			var dmg = max(1, base_dmg) * (2 if is_crit else 1)
			current_enemy["hp"] -= dmg
			var backstab_msg = "暴击！" if is_crit else ""
			_battle_add_log("🗡️ 背刺！" + backstab_msg + "造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			var backstab_dmg_type = "crit" if is_crit else "damage"
			var backstab_offset_x = (randi() % 15) - 7
			var backstab_offset_y = -30 if is_crit else -20
			_spawn_enemy_damage("%d" % dmg, backstab_dmg_type, Vector2(backstab_offset_x, backstab_offset_y))
		"暗影":
			var dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= dmg
			_battle_add_log("💀 暗影攻击！无视防御，造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "damage", Vector2(0, -25))
		"消失":
			# 下回合必定先手+闪避
			vanish_turns = 1
			_battle_add_log("👤 消失！下回合敌人攻击时50%%几率闪避")
		# 牧师
		"治疗":
			var heal = int(player_data.max_hp * 0.4)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_trigger_portrait_heal_glow()
			_battle_add_log("💚 治疗！恢复 %d HP" % heal)
			_spawn_player_damage("+%d" % heal, "heal")
		"护盾":
			player_shield = int(player_data.defense() * 1.5)
			_battle_add_log("🛡️ 神圣护盾！获得 %d 护盾值" % player_shield)
			_spawn_player_damage("+%d" % player_shield, "shield")
		"复活":
			if player_data.hp <= 0:
				player_data.hp = int(player_data.max_hp * 0.5)
				_trigger_portrait_heal_glow()
				_battle_add_log("✨ 复活！恢复50% HP")
				_spawn_player_damage("REVIVE!", "heal")
			else:
				player_data.mp -= 10
				_battle_add_log("💀 复活需要处于濒死状态！")
		# 骑士
		"格挡":
			player_defending = true
			player_shield = int(player_data.defense() * 1.2)
			_battle_add_log("⚔️ 格挡！伤害减少，护盾+%d" % player_shield)
			_spawn_player_damage("+%d" % player_shield, "shield")
		"斩击":
			var pierce_def = _consume_spell_pierce()
			var dmg = int(_get_effective_atk() * 1.8 - pierce_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 神圣斩击！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg)
		"神圣":
			var effective_def = int(_consume_spell_pierce() * 0.5)
			var dmg = int(_get_effective_atk() * 2.5 - effective_def + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			var heal = int(player_data.max_hp * 0.15)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_battle_add_log("✨ 神圣制裁！造成 %d 伤害并恢复 %d HP" % [dmg, heal])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % dmg, "buff", Vector2(0, -25))
			_spawn_player_damage("+%d" % heal, "heal")
		# 吟游诗人
		"鼓舞":
			var boost = 5
			player_data.atk += boost
			_battle_add_log("🎵 鼓舞！攻击力+%d 本场战斗" % boost)
			_spawn_player_damage("ATK+%d" % boost, "buff")
		"旋律":
			var heal = int(player_data.max_hp * 0.2)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			var heal2 = int(player_data.max_mp * 0.2)
			player_data.mp = min(player_data.max_mp, player_data.mp + heal2)
			_trigger_portrait_heal_glow()
			_battle_add_log("🎶 治疗旋律！恢复 %d HP 和 %d MP" % [heal, heal2])
			_spawn_player_damage("+%d HP" % heal, "heal")
		"沉默":
			enemy_stun_turns = 2
			_battle_add_log("🎵 沉默旋律！敌人无法使用技能2回合")
		# 召唤师
		"召唤":
			var summon_dmg = int(_get_effective_atk() * 1.3 + player_data.luk * 2)
			current_enemy["hp"] -= summon_dmg
			resonance_stacks += 1
			_battle_add_log("🔥 召唤兽攻击！造成 %d 伤害（共鸣+%d层）" % [summon_dmg, resonance_stacks])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % summon_dmg, "buff", Vector2(0, -25))
		"契约":
			contract_active = true
			contract_turns = 3
			var contract_dmg = int(_get_effective_atk() * 1.2)
			current_enemy["hp"] -= contract_dmg
			current_enemy["atk"] = max(1, int(current_enemy["atk"] * 0.7))
			_battle_add_log("📜 契约诅咒！造成 %d 伤害，敌人ATK降至70%%，持续3回合" % contract_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % contract_dmg, "debuff", Vector2(0, -25))
		"共鸣":
			if resonance_stacks < 1:
				resonance_stacks = 1
			var reso_dmg = int(current_enemy["max_hp"] * 0.15 * resonance_stacks)
			var self_cost = int(player_data.max_hp * 0.05 * resonance_stacks)
			current_enemy["hp"] -= reso_dmg
			player_data.hp = max(1, player_data.hp - self_cost)
			_battle_add_log("⚡ 共鸣爆发！造成 %d 伤害（%d层），自身消耗 %d HP" % [reso_dmg, resonance_stacks, self_cost])
			resonance_stacks = 0
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % reso_dmg, "crit", Vector2(0, -30))
		# 猎人 T2
		"致命陷阱":
			var trap_dmg = int(_get_effective_atk() * 1.0)
			current_enemy["hp"] -= trap_dmg
			hunter_trap_dot_dmg = int(_get_effective_atk() * 0.4)
			hunter_trap_turns = 3
			hunter_trap_slow = 3
			current_enemy["spd"] = max(1, current_enemy["spd"] - hunter_trap_slow)
			_battle_add_log("🪤 致命陷阱！造成 %d 伤害，敌人速度-%d持续3回合，此后每回合受到 %d 灼烧伤害" % [trap_dmg, hunter_trap_slow, hunter_trap_dot_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % trap_dmg, "crit", Vector2(0, -35))
		"猎豹加速":
			hunter_evasion_turns = 2
			hunter_speed_boost_turns = 2
			_battle_add_log("🦌 猎豹加速！闪避率+50%%持续2回合，移速提升")
			_spawn_player_damage("EVASION+50%", "buff")
		"穿甲箭":
			hunter_armor_pierce_turns = 2
			var pierce_dmg = int(_get_effective_atk() * 2.5)
			current_enemy["hp"] -= pierce_dmg
			_battle_add_log("🏹 穿甲箭！无视防御，造成 %d 伤害，持续2回合穿透" % pierce_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % pierce_dmg, "crit", Vector2(0, -35))
		# 盗贼 T2
		"影遁":
			var vanish_dmg = int(_get_effective_atk() * 3.0)
			current_enemy["hp"] -= vanish_dmg
			vanish_turns = 2
			_battle_add_log("💨 影遁！造成 %d 伤害，2回合内50%%闪避" % vanish_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % vanish_dmg, "crit", Vector2(0, -40))
		"淬毒利刃":
			var poison_dmg = int(_get_effective_atk() * 1.5)
			current_enemy["hp"] -= poison_dmg
			thief_poison_turns = 4
			thief_poison_dmg = int(_get_effective_atk() * 0.3)
			_battle_add_log("🗡️ 淬毒利刃！造成 %d 伤害，4回合内每回合受到 %d 中毒伤害" % [poison_dmg, thief_poison_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % poison_dmg, "poison", Vector2(0, -30))
		"锁喉":
			var choke_dmg = int(_get_effective_atk() * 2.2)
			current_enemy["hp"] -= choke_dmg
			thief_choke_turns = 2
			_battle_add_log("🗡️ 锁喉！造成 %d 伤害，敌人眩晕2回合" % choke_dmg)
			_enemy_hit_effect()
			enemy_stun_turns = max(enemy_stun_turns, 2)
			_spawn_enemy_damage("%d" % choke_dmg, "debuff", Vector2(0, -35))
		# 牧师 T2
		"群体治疗":
			var heal_amt = int(player_data.max_hp * 0.5)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
			priest_mass_heal_mp = heal_amt
			player_shield += int(heal_amt * 0.3)
			_trigger_portrait_heal_glow()
			_battle_add_log("💚 群体治疗！恢复 %d HP，护盾+%d" % [heal_amt, int(heal_amt * 0.3)])
			_spawn_player_damage("+%d" % heal_amt, "heal")
		"驱散":
			priest_dispel_done = true
			var def_debuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - def_debuff)
			# 驱散敌人增益
			_battle_add_log("✨ 驱散！敌人防御-%d" % def_debuff)
			_spawn_enemy_damage("DEF-%d" % def_debuff, "debuff")
		"神圣仲裁":
			var smite_dmg = int(_get_effective_atk() * 2.8)
			current_enemy["hp"] -= smite_dmg
			priest_smite_turns = 2
			priest_smite_defdebuff = int(current_enemy["def"] * 0.25)
			current_enemy["def"] = max(1, current_enemy["def"] - priest_smite_defdebuff)
			var smite_heal = int(player_data.max_hp * 0.1)
			player_data.hp = min(player_data.max_hp, player_data.hp + smite_heal)
			_battle_add_log("⚖️ 神圣仲裁！造成 %d 伤害，敌人DEF-%d持续2回合，恢复 %d HP" % [smite_dmg, priest_smite_defdebuff, smite_heal])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % smite_dmg, "crit", Vector2(0, -40))
			_spawn_player_damage("+%d" % smite_heal, "heal")
		# 骑士 T2
		"盾击":
			var shield_bang = int(player_data.defense() * 1.8)
			current_enemy["hp"] -= shield_bang
			knight_shield_bang_dmg = shield_bang
			enemy_stun_turns = 1
			_battle_add_log("🛡️ 盾击！造成 %d 伤害，敌人眩晕1回合" % shield_bang)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % shield_bang, "damage", Vector2(0, -25))
		"圣光审判":
			var judgment_dmg = int(_get_effective_atk() * 2.5)
			current_enemy["hp"] -= judgment_dmg
			knight_judgment_turns = 2
			knight_judgment_defdebuff = int(current_enemy["def"] * 0.3)
			current_enemy["def"] = max(1, current_enemy["def"] - knight_judgment_defdebuff)
			_battle_add_log("⚔️ 圣光审判！造成 %d 伤害，敌人DEF-%d持续2回合" % [judgment_dmg, knight_judgment_defdebuff])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % judgment_dmg, "crit", Vector2(0, -40))
		"钢铁壁垒":
			knight_iron_wall_turns = 3
			knight_iron_wall_defboost = int(player_data.defense() * 1.0)
			player_shield += int(player_data.defense() * 2.0)
			_battle_add_log("🏰 钢铁壁垒！自身DEF+%d持续3回合，护盾+%d" % [knight_iron_wall_defboost, int(player_data.defense() * 2.0)])
			_spawn_player_damage("+%d" % int(player_data.defense() * 2.0), "shield")
		# 吟游诗人 T2
		"战斗乐章":
			bard_song_atk_turns = 3
			bard_song_atk_boost = int(_get_effective_atk() * 0.25)
			_battle_add_log("🎵 战斗乐章！攻击力+%d持续3回合" % bard_song_atk_boost)
			_spawn_player_damage("ATK+%d" % bard_song_atk_boost, "buff")
		"疯狂节拍":
			var rhythm_dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= rhythm_dmg
			bard_rhythm_turns = 2
			_battle_add_log("🥁 疯狂节拍！造成 %d 伤害，敌人速度-40%%持续2回合" % rhythm_dmg)
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % rhythm_dmg, "crit", Vector2(0, -35))
		"天籁之音":
			var hm_heal = int(player_data.max_hp * 0.35)
			player_data.hp = min(player_data.max_hp, player_data.hp + hm_heal)
			var hm_mp = int(player_data.max_mp * 0.2)
			player_data.mp = min(player_data.max_mp, player_data.mp + hm_mp)
			bard_healing_melody_mp = hm_mp
			_trigger_portrait_heal_glow()
			_battle_add_log("🎶 天籁之音！恢复 %d HP 和 %d MP" % [hm_heal, hm_mp])
			_spawn_player_damage("+%d HP" % hm_heal, "heal")
		# 召唤师 T2
		"契约强化":
			summoner_contract_boost_turns = 3
			summoner_contract_boost_dmg = int(_get_effective_atk() * 0.5)
			var contract_boost_dmg = int(_get_effective_atk() * 1.8)
			current_enemy["hp"] -= contract_boost_dmg
			_battle_add_log("📜 契约强化！造成 %d 伤害，召唤兽伤害+%d/次持续3回合" % [contract_boost_dmg, summoner_contract_boost_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % contract_boost_dmg, "buff", Vector2(0, -30))
		"灵魂连接":
			summoner_soul_link_turns = 4
			summoner_soul_link_dmg = int(player_data.max_hp * 0.08)
			_battle_add_log("🔗 灵魂连接！每回合对敌人造成 %d 伤害，持续4回合" % summoner_soul_link_dmg)
			_spawn_player_damage("LINK x4", "buff")
		"召唤兽强化":
			summoner_beast_boost_turns = 3
			var beast_dmg = int(_get_effective_atk() * 1.5 + player_data.luk * 3)
			current_enemy["hp"] -= beast_dmg
			_battle_add_log("🐉 召唤兽强化！召唤兽攻击力+%d，额外造成 %d 伤害" % [_get_effective_atk() / 3, beast_dmg])
			_enemy_hit_effect()
			_spawn_enemy_damage("%d" % beast_dmg, "crit", Vector2(0, -35))
	
	_update_enemy_hp_bar()
	_update_battle_player_ui()
	_check_battle_end()
	# 应用冷却
	var cd_to_set = _get_skill_cooldown(skill_name)
	if cd_to_set > 0:
		skill_cooldowns[skill_name] = cd_to_set
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

# 在玩家位置生成浮动文字（血条附近）
func _spawn_player_damage(text: String, type: String = "damage"):
	if not battle_ui:
		return
	var player_panel = battle_ui.get_node_or_null("PlayerPanel")
	if not player_panel:
		return
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
	# 字体放大效果（先大后正常）
	var scale_tween = parent.create_tween()
	scale_tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.1)
	scale_tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.2)

	await parent.create_timer(duration + 0.1).timeout
	if lbl and is_instance_valid(lbl):
		lbl.queue_free()

func _end_player_turn():
	is_player_turn = false
	# 猎人消失技能：下回合后SPD恢复正常
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
	if enemy_stun_turns > 0:
		enemy_stun_turns -= 1
		_battle_add_log("敌人仍然眩晕！")
		await get_tree().create_timer(0.5).timeout
		_start_player_turn()
		return
	
	# 中毒伤害
	if poison_turns > 0:
		var total_poison = poison_stacks * poison_damage
		current_enemy["hp"] -= total_poison
		_battle_add_log("毒素发作！受到 %d 伤害（%d层）" % [total_poison, poison_stacks])
		_spawn_enemy_damage("%d" % total_poison, "poison", Vector2(20, -10))
		poison_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 流星火雨灼烧
	if meteor_burn_turns > 0:
		current_enemy["hp"] -= meteor_burn_dmg
		_battle_add_log("🔥 灼烧！流星火雨造成 %d 伤害（剩余%d回合）" % [meteor_burn_dmg, meteor_burn_turns])
		_spawn_enemy_damage("%d" % meteor_burn_dmg, "poison", Vector2(-20, -10))
		meteor_burn_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 霜冻领域减速效果
	if frost_slow_turns > 0:
		frost_slow_turns -= 1
		if frost_slow_turns <= 0:
			_battle_add_log("❄️ 霜冻领域效果结束")
	
	# 法术穿透buff（减少）
	if spell_pierce_turns > 0:
		spell_pierce_turns -= 1
		if spell_pierce_turns <= 0:
			_battle_add_log("💠 法术穿透效果结束")
	
	# 魔力回旋（回合开始时触发：吸MP+回HP）
	if mana_drain_turns > 0:
		mana_drain_turns -= 1
		player_data.mp = min(player_data.max_mp, player_data.mp + mana_drain_amount)
		var drain_heal = int(player_data.max_hp * 0.05)
		player_data.hp = min(player_data.max_hp, player_data.hp + drain_heal)
		_battle_add_log("🌀 魔力回旋！回复 %d MP 和 %d HP（剩余%d回合）" % [mana_drain_amount, drain_heal, mana_drain_turns])
		_spawn_player_damage("+%d MP" % mana_drain_amount, "heal")
		if mana_drain_turns <= 0:
			_battle_add_log("🌀 魔力回旋结束")
	
	# 血之狂暴debuff（每回合自损10HP）
	if berserk_turns > 0:
		player_data.hp -= 10
		berserk_turns -= 1
		_battle_add_log("💢 血之狂暴反噬！受到 10 伤害（剩余%d回合）" % berserk_turns)
		_spawn_player_damage("-10", "debuff")
		if player_data.hp <= 0:
			player_data.hp = 1  # 不会倒下，但很危险
			_battle_add_log("💢 血之狂暴！濒死状态！")
		if _check_battle_end():
			return
	
	# 战吼buff处理（回合开始时减少）
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
	
	# 猎人T2: 穿甲箭（穿透效果已在内置，穿透减少在_on_skill_selected里处理）
	if hunter_armor_pierce_turns > 0:
		hunter_armor_pierce_turns -= 1
		if hunter_armor_pierce_turns <= 0:
			_battle_add_log("🏹 穿甲箭效果结束")
	
	# 契约诅咒（生命吸取）
	if contract_active:
		var drain_dmg = int(player_data.attack_power() * 0.4)
		current_enemy["hp"] -= drain_dmg
		var heal_amt = int(drain_dmg * 0.5)
		player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
		contract_turns -= 1
		_battle_add_log("📜 契约吸取！对敌人造成 %d 伤害，回复 %d HP（剩余%d回合）" % [drain_dmg, heal_amt, contract_turns])
		_spawn_enemy_damage("%d" % drain_dmg, "debuff", Vector2(30, -10))
		if contract_turns <= 0:
			contract_active = false
			_battle_add_log("📜 契约诅咒结束")
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 猎人T2: 致命陷阱DOT
	if hunter_trap_turns > 0:
		current_enemy["hp"] -= hunter_trap_dot_dmg
		_battle_add_log("🪤 陷阱灼烧！受到 %d 伤害（剩余%d回合）" % [hunter_trap_dot_dmg, hunter_trap_turns])
		_spawn_enemy_damage("%d" % hunter_trap_dot_dmg, "poison", Vector2(-10, -10))
		hunter_trap_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 盗贼T2: 淬毒利刃DOT
	if thief_poison_turns > 0:
		current_enemy["hp"] -= thief_poison_dmg
		_battle_add_log("🗡️ 中毒！淬毒利刃造成 %d 伤害（剩余%d回合）" % [thief_poison_dmg, thief_poison_turns])
		_spawn_enemy_damage("%d" % thief_poison_dmg, "poison", Vector2(10, -10))
		thief_poison_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 召唤师T2: 灵魂连接DOT
	if summoner_soul_link_turns > 0:
		current_enemy["hp"] -= summoner_soul_link_dmg
		_battle_add_log("🔗 灵魂连接！受到 %d 伤害（剩余%d回合）" % [summoner_soul_link_dmg, summoner_soul_link_turns])
		_spawn_enemy_damage("%d" % summoner_soul_link_dmg, "debuff", Vector2(20, -10))
		summoner_soul_link_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	await get_tree().create_timer(0.5).timeout
	
	# 陷阱触发：敌人被困住，无法攻击并受到伤害
	if trapped:
		var trap_dmg = int(player_data.attack_power() * 1.2)
		current_enemy["hp"] -= trap_dmg
		trapped = false
		_battle_add_log("🪤 陷阱触发！敌人被困住，受到 %d 伤害！" % trap_dmg)
		_spawn_enemy_damage("%d" % trap_dmg, "damage", Vector2(0, -30))
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
		await get_tree().create_timer(0.4).timeout
		_start_player_turn()
		return
	
	# 消失/猎豹加速闪避检测
	if vanish_turns > 0 or hunter_evasion_turns > 0:
		if vanish_turns > 0:
			vanish_turns -= 1
		if hunter_evasion_turns > 0:
			hunter_evasion_turns -= 1
		if randf() < 0.5:
			var evade_name = "消失" if vanish_turns >= 0 else "猎豹加速"
			_battle_add_log("💨 %s！完美闪避了敌人攻击！" % evade_name)
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
	var e_dmg = current_enemy["atk"] + randi() % 5 - 2
	if player_defending or player_shield > 0:
		e_dmg = int(e_dmg * 0.5)
	if player_shield > 0:
		if player_shield >= e_dmg:
			player_shield -= e_dmg
			e_dmg = 0
			_battle_add_log("🛡️ 护盾吸收了伤害！")
		else:
			e_dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	e_dmg = max(1, e_dmg)
	player_data.hp -= e_dmg
	_trigger_portrait_damage_flash()
	_battle_add_log("👹 %s 攻击！造成 %d 伤害" % [current_enemy["name"], e_dmg])
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
	
	# 第8层远古巨龙多阶段处理
	if boss_key == 8:
		if boss_phase == 1 and hp_ratio <= 0.6:
			boss_phase = 2
			_show_boss_phase_announcement("第二阶段: 龙魂觉醒！ATK+30%！")
			current_enemy["atk"] = int(current_enemy["atk"] * 1.3)
			_battle_add_log("🐉 【阶段2】龙魂觉醒！Boss攻击力大幅提升！")
			_update_enemy_hp_bar()
			await get_tree().create_timer(1.0).timeout
		elif boss_phase == 2 and hp_ratio <= 0.3:
			boss_phase = 3
			_show_boss_phase_announcement("最终阶段: 湮灭！")
			_battle_add_log("🔥 【最终阶段】Boss进入最终形态！")
			_update_enemy_hp_bar()
			await get_tree().create_timer(1.0).timeout
	
	# Boss狂暴检测 (30%血量)
	var phase_hp = current_enemy.get("phase_hp", 0.0)
	if phase_hp > 0 and not boss_enraged and hp_ratio <= phase_hp:
		boss_enraged = true
		var boss_name = current_enemy["name"]
		if boss_key == 1:  # 哥布林王狂暴
			current_enemy["atk"] = int(current_enemy["atk"] * 1.5)
			current_enemy["spd"] += 3
			_show_boss_phase_announcement("狂暴化！ATK+50%！SPD+3！")
			_battle_add_log("👹 %s 狂暴化！ATK+50%%，速度提升！但每回合自残10HP！")
		elif boss_key == 3:  # 巫妖复活
			boss_revived = true
			current_enemy["hp"] = int(current_enemy["max_hp"] * 0.5)
			_show_boss_phase_announcement("不死之身！复活！")
			_battle_add_log("💀 %s 触发【不死之身】！回复50%% HP！")
		else:
			_show_boss_phase_announcement("Boss狂暴！")
			_battle_add_log("👹 %s 进入狂暴状态！")
		_update_enemy_hp_bar()
		await get_tree().create_timer(1.0).timeout
	
	boss_action_counter += 1
	
	# 根据Boss类型执行特殊技能
	match boss_key:
		1: _boss_grak_action(hp_ratio)
		3: _boss_lich_action(hp_ratio)
		5: _boss_magmato_action(hp_ratio)
		7: _boss_seraphiel_action(hp_ratio)
		8: _boss_dragon_action(hp_ratio)
		_: _boss_default_attack()

func _boss_grak_action(hp_ratio: float):
	# 哥布林王: 普通攻击/怒吼/召唤/狂暴
	var roll = randi() % 100
	if roll < 30:
		_boss_default_attack("战棍敲击")
	elif roll < 55:
		# 怒吼：全体攻击
		var dmg = int(current_enemy["atk"] * 0.8)
		_apply_player_damage(dmg)
		_battle_add_log("⚡ 怒吼！全体受到 %d 伤害，恐惧2回合！" % dmg)
		# 恐惧效果：降低逃跑成功率（本游戏暂不实现）
	elif roll < 80 and boss_action_counter > 2:
		# 召唤哥布林
		var summon_dmg = int(player_data.attack_power() * 0.5)
		_apply_player_damage(summon_dmg)
		_battle_add_log("👺 召唤哥布林！两只哥布林战士参战，造成 %d 伤害！" % summon_dmg)
	else:
		# 狂暴自残+攻击
		var self_dmg = 10
		current_enemy["hp"] -= self_dmg
		var atk_dmg = int(current_enemy["atk"] * 1.5)
		_apply_player_damage(atk_dmg)
		_battle_add_log("🔥 狂暴化！自残%d HP，造成 %d 伤害！" % [self_dmg, atk_dmg])
		_spawn_enemy_damage("-%d" % self_dmg, "poison", Vector2(0, -20))
	_update_enemy_hp_bar()

func _boss_lich_action(hp_ratio: float):
	# 巫妖王: 暗影冲击/亡灵大军/生命虹吸/灵魂收割/不死之身
	var roll = randi() % 100
	if roll < 25:
		# 暗影冲击+诅咒
		var dmg = int(current_enemy["atk"] * 1.3)
		_apply_player_damage(dmg)
		_battle_add_log("💀 暗影冲击！造成 %d 伤害，附带诅咒！" % dmg)
	elif roll < 45 and boss_action_counter > 3:
		# 亡灵大军
		var drain = int(current_enemy["atk"] * 2.0)
		_apply_player_damage(int(drain * 0.5))
		var heal = int(drain * 0.5)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		_battle_add_log("💀 亡灵大军！造成 %d 伤害，回复 %d HP！" % [int(drain*0.5), heal])
	elif roll < 65:
		# 生命虹吸
		var dmg = int(current_enemy["atk"] * 2.0)
		_apply_player_damage(dmg)
		var heal = int(dmg * 0.5)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		_battle_add_log("🩸 生命虹吸！造成 %d 伤害，回复 %d HP！" % [dmg, heal])
	elif roll < 80 and hp_ratio < 0.3:
		# 灵魂收割（斩杀）
		var dmg = int(current_enemy["atk"] * 1.5)
		_apply_player_damage(dmg)
		_battle_add_log("💀 灵魂收割！全体 %d 伤害！" % dmg)
	else:
		_boss_default_attack("暗影攻击")

func _boss_magmato_action(hp_ratio: float):
	# 熔岩巨魔: 岩浆之拳/熔岩喷射/碎地重击/熔岩护甲
	var roll = randi() % 100
	if roll < 30:
		# 岩浆之拳+燃烧
		var dmg = int(current_enemy["atk"] * 1.4)
		_apply_player_damage(dmg)
		_battle_add_log("🌋 岩浆之拳！造成 %d 伤害，附带灼烧！" % dmg)
	elif roll < 55:
		# 熔岩喷射（全体）
		var dmg = int(current_enemy["atk"] * 1.2)
		_apply_player_damage(dmg)
		_battle_add_log("🌋 熔岩喷射！全体受到 %d 伤害！" % dmg)
	elif roll < 75:
		# 碎地重击（高伤害+眩晕）
		var dmg = int(current_enemy["atk"] * 2.5)
		_apply_player_damage(dmg)
		enemy_stun_turns = 1
		_battle_add_log("💥 碎地重击！造成 %d 伤害，眩晕1回合！" % dmg)
	elif roll < 90:
		# 熔岩护甲
		var shield_gain = 50
		player_shield += shield_gain
		_battle_add_log("🛡️ 熔岩护甲！获得 %d 临时HP！" % shield_gain)
	else:
		_boss_default_attack("岩浆之拳")

func _boss_seraphiel_action(hp_ratio: float):
	# 堕落天使: 天罚之剑/神圣裁决/堕落之光/命运之手/羽翼护盾
	var roll = randi() % 100
	if roll < 20:
		# 天罚之剑（必定命中+沉默）
		var dmg = int(current_enemy["atk"] * 1.5)
		_apply_player_damage(dmg)
		enemy_stun_turns = max(enemy_stun_turns, 1)
		_battle_add_log("⚔️ 天罚之剑！造成 %d 伤害，20%%沉默！" % dmg)
	elif roll < 40:
		# 神圣裁决（全体+圣光）
		var dmg = int(current_enemy["atk"] * 1.8)
		_apply_player_damage(dmg)
		_battle_add_log("✨ 神圣裁决！全体受到 %d 圣光伤害！" % dmg)
	elif roll < 60 and hp_ratio > 0.5:
		# 堕落之光（治疗）
		var heal = int(current_enemy["max_hp"] * 0.3)
		current_enemy["hp"] = min(current_enemy["max_hp"], current_enemy["hp"] + heal)
		_battle_add_log("💚 堕落之光！回复 %d HP！" % heal)
	elif roll < 75:
		# 命运之手（HP降至1）
		_apply_player_damage(player_data.hp - 1)
		_battle_add_log("🖐️ 命运之手！将一名敌人HP降至1！")
	else:
		# 羽翼护盾
		boss_shield_stacks = 3
		_battle_add_log("🛡️ 羽翼护盾！获得3层护盾！")

func _boss_dragon_action(hp_ratio: float):
	# 远古巨龙: 三阶段Boss
	if boss_phase == 1:
		# 空中优势
		var roll = randi() % 100
		if roll < 30:
			var dmg = int(current_enemy["atk"] * 1.6)
			_apply_player_damage(dmg)
			_battle_add_log("🐉 龙息！造成 %d 伤害，附带风压减速！" % dmg)
		elif roll < 55:
			var dmg = int(current_enemy["atk"] * 1.3)
			_apply_player_damage(dmg)
			_battle_add_log("🌀 飓风降临！全体 %d 伤害！" % dmg)
		elif roll < 80:
			var dmg = int(current_enemy["atk"] * 1.2)
			_apply_player_damage(dmg)
			_battle_add_log("⚡ 召唤雷云！落雷造成 %d 不可躲避伤害！" % dmg)
		else:
			_boss_default_attack("龙息")
	elif boss_phase == 2:
		# 地面搏斗
		var roll = randi() % 100
		if roll < 30:
			var dmg = int(current_enemy["atk"] * 3.0)
			_apply_player_damage(dmg)
			_battle_add_log("💥 毁天灭地！造成 %d 全体伤害！" % dmg)
		elif roll < 55:
			var def_boost = int(current_enemy["def"] * 1.4)
			current_enemy["def"] += def_boost
			_battle_add_log("🐉 龙鳞护体！DEF+%d，持续5回合！" % def_boost)
		elif roll < 80:
			var dmg = int(current_enemy["atk"] * 1.0)
			_apply_player_damage(dmg * 3)
			_battle_add_log("🌀 暴风领域！三次空气刃，共 %d 伤害！" % (dmg*3))
		else:
			_boss_default_attack("毁天灭地")
	else:
		# 最终形态
		var roll = randi() % 100
		if roll < 40:
			var dmg = int(current_enemy["atk"] * 5.0)
			_apply_player_damage(dmg)
			_battle_add_log("💀 湮灭！造成 %d 真实伤害！" % dmg)
		elif roll < 80:
			# 狂暴自残+攻击
			var self_dmg = int(current_enemy["max_hp"] * 0.05)
			current_enemy["hp"] -= self_dmg
			var atk_dmg = int(current_enemy["atk"] * 1.5)
			_apply_player_damage(atk_dmg)
			current_enemy["atk"] = int(current_enemy["atk"] * 1.1)
			_battle_add_log("🔥 狂暴！自残%d HP，ATK永久+10%%！" % self_dmg)
			_spawn_enemy_damage("-%d" % self_dmg, "poison", Vector2(0, -20))
		else:
			_boss_default_attack("湮灭")
	_update_enemy_hp_bar()

func _boss_default_attack(skill_name: String = "攻击"):
	var e_dmg = current_enemy["atk"] + randi() % 5 - 2
	if player_defending or player_shield > 0:
		e_dmg = int(e_dmg * 0.5)
	if player_shield > 0:
		if player_shield >= e_dmg:
			player_shield -= e_dmg
			e_dmg = 0
			_battle_add_log("🛡️ 护盾吸收了伤害！")
		else:
			e_dmg -= player_shield
			player_shield = 0
	if player_defending:
		player_defending = false
	e_dmg = max(1, e_dmg)
	player_data.hp -= e_dmg
	_battle_add_log("👹 %s 使用【%s】！造成 %d 伤害" % [current_enemy["name"], skill_name, e_dmg])
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
			_battle_add_log("🛡️ 护盾吸收了伤害！")
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
	var pierce_def = _consume_spell_pierce()
	var base_dmg = player_data.attack_power() - pierce_def + randi() % 7 - 3
	var dmg = max(1, base_dmg) * (2 if is_crit else 1)
	current_enemy["hp"] -= dmg
	var attack_msg = "暴击！" if is_crit else ""
	_battle_add_log("⚔️ 攻击！" + attack_msg + "造成 %d 伤害" % dmg)
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
	if _check_battle_end():
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
	_battle_add_log("🛡️ 防御！受伤-50%%，获得护盾，回复3MP")
	_spawn_player_damage("+%d" % shield_gain, "shield")
	_update_battle_player_ui()
	await get_tree().create_timer(0.4).timeout
	_process_battle(0)

func _on_flee():
	if not is_player_turn or game_state != State.BATTLE:
		return
	if randf() < 0.6:
		_battle_add_log("🏃 逃跑成功！")
		_close_battle_ui()
		game_state = State.EXPLORE
		is_player_turn = true
		show_message("逃离了战斗...")
		if audio_manager:
			audio_manager.play_sfx("flee")
			audio_manager.play_bgm("explore")
	else:
		_battle_add_log("❌ 逃跑失败！")
		is_player_turn = false
		await get_tree().create_timer(0.4).timeout
		_process_battle(0)

func _on_item():
	if not is_player_turn or game_state != State.BATTLE:
		return
	if player_data.inventory.size() == 0:
		_battle_add_log("背包是空的！")
		return
	# 简单实现：使用第一个药水
	var used_item = null
	var item_idx = -1
	for i in range(player_data.inventory.size()):
		var inv = player_data.inventory[i]
		if inv.get("heal_hp", 0) > 0 or inv.get("heal_mp", 0) > 0:
			used_item = inv
			item_idx = i
			break
	if used_item == null:
		_battle_add_log("没有可用的药水！")
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
		_battle_add_log("🧪 使用 %s！" % used_item["type"])
		is_player_turn = false
		_update_battle_player_ui()
		await get_tree().create_timer(0.4).timeout
		_process_battle(0)
	else:
		_battle_add_log("状态已经是满的！")

func _check_battle_end() -> bool:
	if current_enemy["hp"] <= 0:
		var exp_gain = current_enemy["exp"]
		var gold_gain = current_enemy["gold"]
		player_data.exp += exp_gain
		player_data.gold += gold_gain
		
		# Boss击败特殊提示
		if current_enemy.get("is_boss", false):
			_battle_add_log("🏆⭐ BOSS击破！⭐+%d EXP，+%d 金币！" % [exp_gain, gold_gain])
			_show_boss_victory_screen()
		else:
			_battle_add_log("🏆 胜利！+%d EXP，+%d 金币" % [exp_gain, gold_gain])
		
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
			show_message("⭐ BOSS击破: %s！+%d EXP" % [current_enemy["name"], exp_gain])
		else:
			show_message("击败了 %s！获得 %d EXP" % [current_enemy["name"], exp_gain])
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
	overlay.size = Vector2(1280, 720)
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
		_battle_add_log("⬆️ 升级！Lv.%d → Lv.%d" % [player_data.level - 1, player_data.level])
		if audio_manager:
			audio_manager.play_sfx("levelup")
	show_message("升级了！Lv.%d" % player_data.level)

# 肖像动画更新（每帧调用）
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
	
	# 更新肖像面板的HP/MP条（每次动画帧都更新）
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
		# HP条颜色随血量变化
		var hp_ratio = float(player_data.hp) / float(player_data.max_hp)
		var hp_fill = php_bar.get_theme_stylebox("fill")
		if hp_fill:
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
	show_message("💀 游戏结束！按R重新开始...")
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
			"inventory": player_data.inventory
		},
		"progress": {
			"current_floor": current_floor
		}
	}
	
	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		show_message("💾 存档成功！存档槽 %d" % (slot + 1))
		if audio_manager:
			audio_manager.play_sfx("purchase")
		return true
	else:
		show_message("❌ 存档失败！")
		return false

func load_game(slot: int) -> bool:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		show_message("存档槽 %d 不存在！" % (slot + 1))
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		show_message("❌ 读取存档失败！")
		return false
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		show_message("❌ 存档数据损坏！")
		return false
	
	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		show_message("❌ 存档格式错误！")
		return false
	
	# 恢复玩家数据
	var pdata = save_data.get("player", {})
	player_data = PlayerData.new()
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
	player_data.inventory = pdata.get("inventory", [])
	
	# 恢复进度
	var prog = save_data.get("progress", {})
	current_floor = prog.get("current_floor", 1)
	
	show_message("📂 读档成功！%s Lv.%d" % [player_data.get_job_name(), player_data.level])
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
	overlay.size = Vector2(1280, 720)
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
	# 当读档后，重新设置玩家精灵
	if player:
		var sprite = player.get_node_or_null("Sprite")
		if sprite:
			sprite.texture = _create_job_texture(player_data.job)
	# 更新UI
	_update_ui()

