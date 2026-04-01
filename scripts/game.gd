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
	tip.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I)"
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
	hint_label.text = "WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I)"
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
	show_message("WASD移动 · 撞墙遇敌 · 下楼梯(F) · 商店(E) · 背包(I)")

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
	
	# 生成敌人
	var enemy_types = ["slime", "skeleton", "demon"]
	if current_floor >= 7:
		enemy_types.append("dragon")
	var etype = enemy_types[randi() % enemy_types.size()]
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
	resonance_stacks = 0
	contract_active = false
	contract_turns = 0
	boss_phase = 1
	boss_enraged = false
	boss_shield_stacks = 0
	boss_revived = false
	
	# 使用Boss数据
	current_enemy = current_boss_data.duplicate()
	current_enemy["is_boss"] = true
	
	show_message("⚠️ Boss战: " + current_enemy["name"] + "！")
	_create_battle_ui()
	if audio_manager:
		audio_manager.play_bgm("boss")
	
	# 猎人陷阱对Boss也有效
	if player_data.job == PlayerData.Job.HUNTER and player_data.skills.has("陷阱"):
		trapped = true
		await get_tree().create_timer(0.5).timeout
		var trap_dmg = int(player_data.attack_power() * 1.0)  # Boss战陷阱伤害降低
		current_enemy["hp"] -= trap_dmg
		_battle_add_log("⚡ 陷阱触发！对Boss造成 %d 伤害" % trap_dmg)
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
	
	# 技能列表
	var skill_list_label = Label.new()
	skill_list_label.position = Vector2(20, 130)
	skill_list_label.text = "技能: " + ", ".join(player_data.skills)
	skill_list_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	player_panel.add_child(skill_list_label)

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

func _create_enemy_texture(col: Color) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match current_enemy["name"]:
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
		"火球": 15, "冰霜": 15, "闪电": 25,
		"狙击": 10, "陷阱": 15, "毒箭": 20,
		"背刺": 15, "暗影": 20, "消失": 25,
		"治疗": 15, "护盾": 10, "复活": 50,
		"格挡": 0, "斩击": 15, "神圣": 25,
		"鼓舞": 10, "旋律": 15, "沉默": 20,
		"召唤": 20, "契约": 20, "共鸣": 25
	}
	
	var skill_idx = 0
	for skill in player_data.skills:
		var cost = mp_cost.get(skill, 0)
		var can_use = player_data.mp >= cost
		var row = skill_idx / 2
		var col = skill_idx % 2
		var sx = 15 + col * 140
		var sy = 45 + row * 55
		var sbtn = Button.new()
		sbtn.text = skill + " (MP:" + str(cost) + ")"
		sbtn.position = Vector2(sx, sy)
		sbtn.size = Vector2(130, 48)
		sbtn.add_theme_font_size_override("font_size", 13)
		var sstyle = StyleBoxFlat.new()
		sstyle.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		sstyle.border_color = PALETTE.gold if can_use else Color(0.3, 0.3, 0.3)
		sstyle.border_width_left = 1; sstyle.border_width_top = 1
		sstyle.border_width_right = 1; sstyle.border_width_bottom = 1
		sstyle.corner_radius_top_left = 3; sstyle.corner_radius_top_right = 3
		sstyle.corner_radius_bottom_right = 3; sstyle.corner_radius_bottom_left = 3
		sbtn.add_theme_stylebox_override("normal", sstyle)
		sbtn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75) if can_use else Color(0.35, 0.35, 0.35))
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
		"火球": 15, "冰霜": 15, "闪电": 25,
		"狙击": 10, "陷阱": 15, "毒箭": 20,
		"背刺": 15, "暗影": 20, "消失": 25,
		"治疗": 15, "护盾": 10, "复活": 50,
		"格挡": 0, "斩击": 15, "神圣": 25,
		"鼓舞": 10, "旋律": 15, "沉默": 20,
		"召唤": 20, "契约": 20, "共鸣": 25
	}
	var cost = mp_cost.get(skill_name, 0)
	if player_data.mp < cost:
		_battle_add_log("MP不足！")
		return
	player_data.mp -= cost
	pending_skill_index = -1
	
	match skill_name:
		# 战士
		"猛击":
			var dmg = int(player_data.attack_power() * 1.5 - current_enemy["def"] + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 猛击！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		"防御":
			player_defending = true
			player_shield = int(player_data.defense() * 0.5)
			player_data.mp = min(player_data.max_mp, player_data.mp + 5)
			_battle_add_log("🛡️ 防御姿态！伤害减半，回复5MP")
		"冲锋":
			var dmg = int(player_data.attack_power() * 2.5 - current_enemy["def"] + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			enemy_stun_turns = 1
			_battle_add_log("🐎 冲锋！造成 %d 伤害，敌人眩晕！" % dmg)
			_enemy_hit_effect()
		# 法师
		"火球":
			var dmg = int(player_data.attack_power() * 2.0 - current_enemy["def"] + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🔥 火球术！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		"冰霜":
			var dmg = int(player_data.attack_power() * 1.8 - current_enemy["def"] + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			current_enemy["spd"] = max(1, current_enemy["spd"] - 2)
			_battle_add_log("❄️ 冰霜术！造成 %d 伤害，敌人速度降低！" % dmg)
			_enemy_hit_effect()
		"闪电":
			var dmg = int(player_data.attack_power() * 3.0 - current_enemy["def"] + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚡ 闪电术！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		# 猎人
		"狙击":
			var dmg = int(player_data.attack_power() * 2.0 - current_enemy["def"] + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("🎯 狙击！必定命中，造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		"毒箭":
			var dmg = int(player_data.attack_power() * 1.5 - current_enemy["def"] + randi() % 7 - 3)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			poison_stacks += 1
			poison_damage = 5
			poison_turns = 3
			_battle_add_log("🏹 毒箭！造成 %d 伤害+每回合5毒性伤害×3回合" % dmg)
			_enemy_hit_effect()
		# 盗贼
		"背刺":
			var is_crit = randi() % 100 < player_data.luk * 3
			var base_dmg = int(player_data.attack_power() * 2.2 - current_enemy["def"] + randi() % 7 - 3)
			var dmg = max(1, base_dmg) * (2 if is_crit else 1)
			current_enemy["hp"] -= dmg
			_battle_add_log("🗡️ 背刺！%s造成 %d 伤害" % ("暴击！" if is_crit else "", dmg))
			_enemy_hit_effect()
		"暗影":
			var dmg = int(player_data.attack_power() * 1.8)
			current_enemy["hp"] -= dmg
			_battle_add_log("💀 暗影攻击！无视防御，造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		"消失":
			# 下回合必定先手+闪避
			vanish_turns = 1
			_battle_add_log("👤 消失！下回合敌人攻击时50%%几率闪避")
		# 牧师
		"治疗":
			var heal = int(player_data.max_hp * 0.4)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_battle_add_log("💚 治疗！恢复 %d HP" % heal)
		"护盾":
			player_shield = int(player_data.defense() * 1.5)
			_battle_add_log("🛡️ 神圣护盾！获得 %d 护盾值" % player_shield)
		"复活":
			if player_data.hp <= 0:
				player_data.hp = int(player_data.max_hp * 0.5)
				_battle_add_log("✨ 复活！恢复50% HP")
			else:
				player_data.mp -= 10  # 不消耗额外MP已消耗
				_battle_add_log("💀 复活需要处于濒死状态！")
		# 骑士
		"格挡":
			player_defending = true
			player_shield = int(player_data.defense() * 1.2)
			_battle_add_log("⚔️ 格挡！伤害减少，护盾+%d" % player_shield)
		"斩击":
			var dmg = int(player_data.attack_power() * 1.8 - current_enemy["def"] + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			_battle_add_log("⚔️ 神圣斩击！造成 %d 伤害" % dmg)
			_enemy_hit_effect()
		"神圣":
			var dmg = int(player_data.attack_power() * 2.5 - current_enemy["def"] * 0.5 + randi() % 11 - 5)
			dmg = max(1, dmg)
			current_enemy["hp"] -= dmg
			var heal = int(player_data.max_hp * 0.15)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			_battle_add_log("✨ 神圣制裁！造成 %d 伤害并恢复 %d HP" % [dmg, heal])
			_enemy_hit_effect()
		# 吟游诗人
		"鼓舞":
			var boost = 5
			player_data.atk += boost
			_battle_add_log("🎵 鼓舞！攻击力+%d 本场战斗" % boost)
		"旋律":
			var heal = int(player_data.max_hp * 0.2)
			player_data.hp = min(player_data.max_hp, player_data.hp + heal)
			var heal2 = int(player_data.max_mp * 0.2)
			player_data.mp = min(player_data.max_mp, player_data.mp + heal2)
			_battle_add_log("🎶 治疗旋律！恢复 %d HP 和 %d MP" % [heal, heal2])
		"沉默":
			enemy_stun_turns = 2
			_battle_add_log("🎵 沉默旋律！敌人无法使用技能2回合")
		# 召唤师
		"召唤":
			var summon_dmg = int(player_data.attack_power() * 1.3 + player_data.luk * 2)
			current_enemy["hp"] -= summon_dmg
			resonance_stacks += 1
			_battle_add_log("🔥 召唤兽攻击！造成 %d 伤害（共鸣+%d层）" % [summon_dmg, resonance_stacks])
			_enemy_hit_effect()
		"契约":
			contract_active = true
			contract_turns = 3
			var contract_dmg = int(player_data.attack_power() * 1.2)
			current_enemy["hp"] -= contract_dmg
			current_enemy["atk"] = max(1, int(current_enemy["atk"] * 0.7))
			_battle_add_log("📜 契约诅咒！造成 %d 伤害，敌人ATK降至70%%，持续3回合" % contract_dmg)
			_enemy_hit_effect()
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
	
	_update_enemy_hp_bar()
	_update_battle_player_ui()
	_check_battle_end()
	if audio_manager:
		audio_manager.play_sfx("skill")
	if game_state == State.BATTLE:
		await get_tree().create_timer(0.4).timeout
		_end_player_turn()

func _enemy_hit_effect():
	enemy_sprite_target = enemy_sprite.position + Vector2(15, 0)

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
		poison_turns -= 1
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
	
	# 契约诅咒（生命吸取）
	if contract_active:
		var drain_dmg = int(player_data.attack_power() * 0.4)
		current_enemy["hp"] -= drain_dmg
		var heal_amt = int(drain_dmg * 0.5)
		player_data.hp = min(player_data.max_hp, player_data.hp + heal_amt)
		contract_turns -= 1
		_battle_add_log("📜 契约吸取！对敌人造成 %d 伤害，回复 %d HP（剩余%d回合）" % [drain_dmg, heal_amt, contract_turns])
		if contract_turns <= 0:
			contract_active = false
			_battle_add_log("📜 契约诅咒结束")
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
		_update_enemy_hp_bar()
		if _check_battle_end():
			return
		await get_tree().create_timer(0.4).timeout
		_start_player_turn()
		return
	
	# 消失闪避检测
	if vanish_turns > 0:
		vanish_turns -= 1
		if randf() < 0.5:
			_battle_add_log("💨 消失！完美闪避了敌人攻击！")
			_start_player_turn()
			return
		else:
			_battle_add_log("💨 消失！闪避失败...")
	
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
	_battle_add_log("👹 %s 攻击！造成 %d 伤害" % [current_enemy["name"], e_dmg])
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
	if audio_manager:
		audio_manager.play_sfx("hit")
	_update_battle_player_ui()
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
	_update_battle_player_ui()

func _on_attack():
	if not is_player_turn or game_state != State.BATTLE:
		return
	is_player_turn = false
	var is_crit = randi() % 100 < player_data.luk * 2
	var base_dmg = player_data.attack_power() - current_enemy["def"] + randi() % 7 - 3
	var dmg = max(1, base_dmg) * (2 if is_crit else 1)
	current_enemy["hp"] -= dmg
	_battle_add_log("⚔️ 攻击！%s造成 %d 伤害" % ("暴击！" if is_crit else "", dmg))
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
	player_shield += int(player_data.defense() * 0.3)
	player_data.mp = min(player_data.max_mp, player_data.mp + 3)
	_battle_add_log("🛡️ 防御！受伤-50%%，获得护盾，回复3MP")
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
			if poison_turns > 0: parts.append("☠️中毒×%d" % poison_stacks)
			if contract_active: parts.append("📜契约×%d" % contract_turns)
			if resonance_stacks > 0: parts.append("⚡共鸣×%d" % resonance_stacks)
			status_lbl.text = " ".join(parts) if parts.size() > 0 else ""

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