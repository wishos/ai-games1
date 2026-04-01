extends Node2D

# 主游戏场景脚本

# 游戏状态枚举
enum GameState { TITLE, CHAPTER_INTRO, EXPLORE, BATTLE, DIALOG, SHOP, INVENTORY, QUEST, SAVE_LOAD, GAME_OVER }

# 当前状态
var current_state: GameState = GameState.TITLE
var current_chapter: int = 1
var current_scene_name: String = "临安城"
var is_player_turn: bool = true
var battle_in_progress: bool = false

# 玩家数据引用
var player: CharacterBody2D
var player_sprite: Sprite2D
var player_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var move_speed: float = 150.0
var dash_speed: float = 350.0
var can_dash: bool = true
var dash_cooldown: float = 0.0
var dash_duration: float = 0.15
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# 相机
var main_camera: Camera2D
var camera_smoothing: float = 0.1

# UI元素
var ui_layer: CanvasLayer
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var qi_bar: ProgressBar
var gold_label: Label
var level_label: Label
var chapter_label: Label
var scene_label: Label
var message_label: Label
var message_timer: float = 0.0
var displayed_message: String = ""
var target_message: String = ""
var message_char_index: int = 0

# 战斗UI
var battle_ui: Control
var battle_log: Label
var enemy_sprite: Sprite2D
var enemy_hp_bar: ProgressBar
var enemy_name_label: Label
var battle_action_buttons: Array = []
var skill_menu_open: bool = false
var skill_menu_buttons: Array = []

# 当前敌人数据
var current_enemy: Dictionary = {}

# 场景元素
var npcs: Array = []
var interactables: Array = []
var light_sources: Array = []
var god_ray_container: Node2D

# 迷雾系统
var fog_container: Node2D
var fog_tiles: Dictionary = {}
var fog_tile_size: int = 32
var fog_grid_width: int = 50
var fog_grid_height: int = 40
var player_fog_tile: Vector2i = Vector2i.ZERO

# 背景层
var bg_layer: Node2D
var ground_layer: Node2D
var object_layer: Node2D
var entity_layer: Node2D
var light_layer: Node2D

# 调色板
const PALETTE = GlobalData.PALETTE

# 场景配置
var current_scene_config: Dictionary = {
	"name": "临安城",
	"type": "town",
	"music": "explore",
	"enemies": [],
	"npcs": [
		{"id": "inn_keeper", "name": "客栈掌柜", "pos": Vector2(400, 300), "sprite": "npc_inn_keeper", "dialog": ["客官里边请！", "最近江湖不太平啊...", "听说城外出事了..."]},
		{"id": "weapon_merchant", "name": "铁匠", "pos": Vector2(800, 400), "sprite": "npc_weapon", "dialog": ["客官要打造兵器吗？", "这可是上好的镔铁！"]},
		{"id": "quest_giver", "name": "江湖人士", "pos": Vector2(600, 500), "sprite": "npc_wanderer", "dialog": ["最近江湖上有邪教出没...", "你知道吗？", "小心为上！"]}
	],
	"interactables": [
		{"id": "shop_sign", "name": "杂货铺", "pos": Vector2(300, 350), "type": "shop", "action": "open_shop"},
		{"id": "dojo_door", "name": "门派大殿", "pos": Vector2(900, 200), "type": "dojo", "action": "enter_dojo"},
		{"id": "tavern_door", "name": "酒馆", "pos": Vector2(500, 450), "type": "tavern", "action": "enter_tavern"},
		{"id": "dungeon_entrance", "name": "城外山道", "pos": Vector2(1100, 600), "type": "dungeon", "action": "enter_dungeon"}
	]
}

func _ready():
	randomize()
	_setup_layers()
	_setup_camera()
	_create_title_screen()

func _setup_layers():
	bg_layer = Node2D.new()
	bg_layer.name = "BGLayer"
	add_child(bg_layer)
	
	ground_layer = Node2D.new()
	ground_layer.name = "GroundLayer"
	add_child(ground_layer)
	
	object_layer = Node2D.new()
	object_layer.name = "ObjectLayer"
	add_child(object_layer)
	
	entity_layer = Node2D.new()
	entity_layer.name = "EntityLayer"
	add_child(entity_layer)
	
	light_layer = Node2D.new()
	light_layer.name = "LightLayer"
	light_layer.show_behind_parent = true
	add_child(light_layer)
	
	god_ray_container = Node2D.new()
	god_ray_container.name = "GodRays"
	add_child(god_ray_container)
	
	fog_container = Node2D.new()
	fog_container.name = "FogContainer"
	add_child(fog_container)
	
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

func _setup_camera():
	main_camera = Camera2D.new()
	main_camera.name = "MainCamera"
	main_camera.zoom = Vector2(1.0, 1.0)
	main_camera.limit_left = -200
	main_camera.limit_right = 1480
	main_camera.limit_top = -200
	main_camera.limit_bottom = 920
	main_camera.position = Vector2(640, 360)
	add_child(main_camera)
	main_camera.make_current()

# ==================== 标题画面 ====================

func _create_title_screen():
	_clear_scene()
	current_state = GameState.TITLE
	AudioManager.play_bgm("title")
	
	# 背景
	var bg = ColorRect.new()
	bg.name = "TitleBG"
	bg.size = Vector2(1280, 720)
	bg.color = PALETTE.sky_top
	bg_layer.add_child(bg)
	
	# 装饰性背景元素
	_add_title_decorations()
	
	# 标题面板
	var title_panel = Panel.new()
	title_panel.name = "TitlePanel"
	title_panel.position = Vector2(190, 30)
	title_panel.size = Vector2(900, 660)
	title_panel.self_modulate = Color(0.05, 0.05, 0.1, 0.95)
	title_panel.add_theme_stylebox_override("panel", _create_panel_style())
	ui_layer.add_child(title_panel)
	
	# 游戏标题
	var game_title = Label.new()
	game_title.name = "GameTitle"
	game_title.position = Vector2(0, 30)
	game_title.size = Vector2(900, 80)
	game_title.text = "⚔️ 剑 侠 情 缘 ⚔️"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_color_override("font_color", PALETTE.gold)
	game_title.add_theme_font_size_override("font_size", 48)
	title_panel.add_child(game_title)
	
	var subtitle = Label.new()
	subtitle.position = Vector2(0, 105)
	subtitle.size = Vector2(900, 35)
	subtitle.text = "WUXIA CHRONICLES"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	subtitle.add_theme_font_size_override("font_size", 18)
	title_panel.add_child(subtitle)
	
	# 分割线
	var separator = ColorRect.new()
	separator.position = Vector2(100, 150)
	separator.size = Vector2(700, 2)
	separator.color = PALETTE.gold * Color(0.5, 0.5, 0.5, 0.5)
	title_panel.add_child(separator)
	
	# 章节选择标签
	var chapter_label_text = Label.new()
	chapter_label_text.position = Vector2(0, 165)
	chapter_label_text.size = Vector2(900, 30)
	chapter_label_text.text = "━━━━━━  选择你的门派  ━━━━━━"
	chapter_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label_text.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
	chapter_label_text.add_theme_font_size_override("font_size", 16)
	title_panel.add_child(chapter_label_text)
	
	# 门派选择网格 (4x2)
	var jobs = [
		{"id": 0, "name": "少林寺", "desc": "金钟罩 · 罗汉拳", "color": Color(0.9, 0.7, 0.3), "icon": "🏯"},
		{"id": 1, "name": "武当派", "desc": "太极剑 · 太极拳", "color": Color(0.3, 0.7, 0.9), "icon": "☯️"},
		{"id": 2, "name": "峨眉派", "desc": "素女剑 · 九阴爪", "color": Color(0.9, 0.4, 0.7), "icon": "🌸"},
		{"id": 3, "name": "丐帮", "desc": "打狗棒 · 降龙掌", "color": Color(0.6, 0.5, 0.3), "icon": "🍶"},
		{"id": 4, "name": "唐门", "desc": "暴雨针 · 夺魂箭", "color": Color(0.4, 0.8, 0.4), "icon": "🎯"},
		{"id": 5, "name": "明教", "desc": "圣火令 · 乾坤挪", "color": Color(0.9, 0.3, 0.2), "icon": "🔥"},
		{"id": 6, "name": "华山派", "desc": "独孤剑 · 华山剑", "color": Color(0.4, 0.6, 0.9), "icon": "⛰️"},
		{"id": 7, "name": "嵩山派", "desc": "寒冰真 · 嵩山剑", "color": Color(0.5, 0.9, 0.5), "icon": "❄️"}
	]
	
	var start_x = 100
	var start_y = 210
	var btn_w = 170
	var btn_h = 100
	var cols = 4
	
	for i in range(jobs.size()):
		var job = jobs[i]
		var row = i / cols
		var col = i % cols
		var bx = start_x + col * (btn_w + 20)
		var by = start_y + row * (btn_h + 15)
		
		var job_btn = _create_job_button(job, Vector2(bx, by), Vector2(btn_w, btn_h))
		job_btn.pressed.connect(_on_job_selected.bind(job["id"]))
		title_panel.add_child(job_btn)
	
	# 已有存档
	var saves_label = Label.new()
	saves_label.position = Vector2(0, 440)
	saves_label.size = Vector2(900, 30)
	saves_label.text = "━━━━━━  继续游戏  ━━━━━━"
	saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saves_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
	saves_label.add_theme_font_size_override("font_size", 16)
	title_panel.add_child(saves_label)
	
	# 存档槽按钮
	for slot in range(3):
		var save_btn = _create_save_slot_button(slot, Vector2(100 + slot * 230, 480))
		title_panel.add_child(save_btn)
	
	# 操作说明
	var controls = Label.new()
	controls.position = Vector2(0, 570)
	controls.size = Vector2(900, 70)
	controls.text = "【操作说明】\nWASD移动 · 鼠标左键攻击 · 1-4技能 · E交互 · I背包 · Q任务 · F2保存"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	controls.add_theme_font_size_override("font_size", 12)
	title_panel.add_child(controls)

func _add_title_decorations():
	# 添加装饰性光效
	var god_ray = _create_god_ray(Vector2(640, 0), Vector2(0.5, 1.0), 60)
	god_ray_container.add_child(god_ray)

func _create_job_button(job: Dictionary, pos: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.name = "JobBtn_%d" % job["id"]
	btn.position = pos
	btn.size = size
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	normal_style.border_color = job["color"]
	normal_style.border_width_left = 2; normal_style.border_width_top = 2
	normal_style.border_width_right = 2; normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 5; normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_right = 5; normal_style.corner_radius_bottom_left = 5
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
	hover_style.border_color = PALETTE.gold
	hover_style.border_width_left = 2; hover_style.border_width_top = 2
	hover_style.border_width_right = 2; hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 5; hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_right = 5; hover_style.corner_radius_bottom_left = 5
	btn.add_theme_stylebox_override("hover", hover_style)
	
	# 门派图标
	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(size.x / 2 - 30, 8)
	icon_lbl.text = job["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 28)
	btn.add_child(icon_lbl)
	
	# 门派名称
	var name_lbl = Label.new()
	name_lbl.position = Vector2(0, 45)
	name_lbl.size = Vector2(size.x, 25)
	name_lbl.text = job["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", job["color"])
	name_lbl.add_theme_font_size_override("font_size", 16)
	btn.add_child(name_lbl)
	
	# 技能描述
	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(0, 70)
	desc_lbl.size = Vector2(size.x, 25)
	desc_lbl.text = job["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	btn.add_child(desc_lbl)
	
	return btn

func _create_save_slot_button(slot: int, pos: Vector2) -> Button:
	var has_save = GlobalData.has_save(slot)
	var save_data = GlobalData.save_slots[slot] if has_save else null
	
	var btn = Button.new()
	btn.name = "SaveSlot_%d" % slot
	btn.position = pos
	btn.size = Vector2(210, 65)
	
	var normal_style = StyleBoxFlat.new()
	if has_save:
		normal_style.bg_color = Color(0.08, 0.12, 0.08, 0.95)
		normal_style.border_color = Color(0.3, 0.5, 0.3)
	else:
		normal_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		normal_style.border_color = Color(0.3, 0.3, 0.35)
	normal_style.border_width_left = 1; normal_style.border_width_top = 1
	normal_style.border_width_right = 1; normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 3; normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_right = 3; normal_style.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("normal", normal_style)
	
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75) if has_save else Color(0.4, 0.4, 0.45))
	
	if has_save:
		btn.text = "存档 %d\n%s Lv.%d\n第%d章" % [slot + 1, GlobalData.get_job_name(save_data.get("job", 0)), save_data.get("level", 1), save_data.get("chapter", 1)]
	else:
		btn.text = "存档 %d\n空" % (slot + 1)
	btn.pressed.connect(_on_save_slot_selected.bind(slot))
	return btn

func _on_job_selected(job_id: int):
	# 清理标题画面
	_clear_ui_layer()
	
	# 创建新游戏
	GlobalData.create_new_game(job_id, "sword")
	current_chapter = 1
	current_scene_name = "临安城"
	
	# 显示章节介绍
	_show_chapter_intro()

func _on_save_slot_selected(slot: int):
	if Input.is_key_pressed(KEY_SHIFT):
		# 删除存档
		GlobalData.delete_save(slot)
		_create_title_screen()
		return
	
	if GlobalData.has_save(slot):
		GlobalData.load_game(slot)
		current_chapter = GlobalData.player_data.get("chapter", 1)
		current_scene_name = GlobalData.player_data.get("current_scene", "临安城")
		_show_chapter_intro()
	else:
		# 创建新游戏到该槽位
		GlobalData.create_new_game(0, "sword")
		GlobalData.save_game(slot)
		current_chapter = 1
		current_scene_name = "临安城"
		_show_chapter_intro()

func _show_chapter_intro():
	current_state = GameState.CHAPTER_INTRO
	
	# 章节信息
	var chapter_data = GlobalData.CHAPTERS.get(current_chapter, GlobalData.CHAPTERS[1])
	
	# 背景
	var overlay = ColorRect.new()
	overlay.name = "ChapterOverlay"
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0, 0, 0, 0.95)
	overlay.position = Vector2(0, 0)
	ui_layer.add_child(overlay)
	
	# 章节面板
	var panel = Panel.new()
	panel.name = "ChapterPanel"
	panel.position = Vector2(240, 160)
	panel.size = Vector2(800, 400)
	panel.self_modulate = Color(0.03, 0.03, 0.06, 0.98)
	panel.add_theme_stylebox_override("panel", _create_panel_style())
	ui_layer.add_child(panel)
	
	# 章节标题
	var chapter_num = Label.new()
	chapter_num.position = Vector2(0, 30)
	chapter_num.size = Vector2(800, 50)
	chapter_num.text = "第 %d 章" % current_chapter
	chapter_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_num.add_theme_color_override("font_color", PALETTE.gold)
	chapter_num.add_theme_font_size_override("font_size", 36)
	panel.add_child(chapter_num)
	
	# 章节名称
	var chapter_name = Label.new()
	chapter_name.position = Vector2(0, 90)
	chapter_name.size = Vector2(800, 40)
	chapter_name.text = chapter_data["name"]
	chapter_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_name.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	chapter_name.add_theme_font_size_override("font_size", 28)
	panel.add_child(chapter_name)
	
	# 分割线
	var sep = ColorRect.new()
	sep.position = Vector2(150, 140)
	sep.size = Vector2(500, 2)
	sep.color = PALETTE.gold * Color(0.4, 0.4, 0.4, 0.5)
	panel.add_child(sep)
	
	# 章节描述
	var desc = Label.new()
	desc.position = Vector2(50, 160)
	desc.size = Vector2(700, 150)
	desc.text = chapter_data["description"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.add_theme_font_size_override("font_size", 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(desc)
	
	# 开始按钮
	var start_btn = Button.new()
	start_btn.name = "StartBtn"
	start_btn.position = Vector2(300, 320)
	start_btn.size = Vector2(200, 50)
	start_btn.text = "开始游戏"
	start_btn.add_theme_font_size_override("font_size", 18)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
	btn_style.border_color = PALETTE.gold
	btn_style.border_width_left = 2; btn_style.border_width_top = 2
	btn_style.border_width_right = 2; btn_style.border_width_bottom = 2
	btn_style.corner_radius_top_left = 5; btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_right = 5; btn_style.corner_radius_bottom_left = 5
	start_btn.add_theme_stylebox_override("normal", btn_style)
	start_btn.add_theme_color_override("font_color", PALETTE.gold)
	start_btn.pressed.connect(_start_gameplay)
	panel.add_child(start_btn)

func _start_gameplay():
	_clear_ui_layer()
	AudioManager.play_bgm("explore")
	_build_explore_scene()

func _build_explore_scene():
	current_state = GameState.EXPLORE
	
	# 绘制场景背景
	_draw_scene_bg()
	
	# 绘制地面
	_draw_ground()
	
	# 添加God Rays
	_add_god_rays()
	
	# 添加光源
	_add_light_sources()
	
	# 创建玩家
	_create_player()
	
	# 创建NPC和可交互物
	_create_npcs()
	_create_interactables()
	
	# 创建迷雾
	_create_fog()
	
	# 创建UI
	_create_explore_ui()
	
	# 初始化迷雾
	_update_fog_around_player()

func _draw_scene_bg():
	# 清除旧背景
	for child in bg_layer.get_children():
		child.queue_free()
	
	var bg = ColorRect.new()
	bg.name = "SceneBG"
	bg.size = Vector2(1280, 720)
	bg.color = PALETTE.sky_top
	bg_layer.add_child(bg)
	
	# 添加装饰性建筑轮廓
	match current_scene_name:
		"临安城":
			_draw_building_outlines()
		"清风寨外围":
			_draw_forest_outlines()
		_:
			_draw_building_outlines()

func _draw_building_outlines():
	# 简化的建筑轮廓
	var buildings = [
		{"x": 100, "y": 150, "w": 120, "h": 200},
		{"x": 300, "y": 100, "w": 150, "h": 250},
		{"x": 500, "y": 180, "w": 100, "h": 170},
		{"x": 700, "y": 120, "w": 130, "h": 230},
		{"x": 900, "y": 160, "w": 110, "h": 190},
		{"x": 1050, "y": 140, "w": 140, "h": 210}
	]
	
	for b in buildings:
		var building = ColorRect.new()
		building.size = Vector2(b["w"], b["h"])
		building.position = Vector2(b["x"], b["y"])
		building.color = PALETTE.wall
		bg_layer.add_child(building)
		
		# 屋顶
		var roof = ColorRect.new()
		roof.size = Vector2(b["w"] + 20, 30)
		roof.position = Vector2(b["x"] - 10, b["y"])
		roof.color = PALETTE.wall_top
		bg_layer.add_child(roof)

func _draw_forest_outlines():
	# 森林树冠
	for i in range(20):
		var x = randi() % 1200 + 40
		var y = randi() % 300 + 50
		var size = randi() % 60 + 40
		var tree = ColorRect.new()
		tree.size = Vector2(size, size)
		tree.position = Vector2(x, y)
		tree.color = Color(0.15, 0.3, 0.15, 0.8)
		bg_layer.add_child(tree)

func _draw_ground():
	for child in ground_layer.get_children():
		child.queue_free()
	
	var ground = ColorRect.new()
	ground.name = "MainGround"
	ground.size = Vector2(1280, 500)
	ground.position = Vector2(0, 200)
	ground.color = PALETTE.grass_1
	ground_layer.add_child(ground)
	
	# 添加草地纹理
	for i in range(50):
		var x = randi() % 1200 + 40
		var y = randi() % 450 + 225
		var grass = ColorRect.new()
		grass.size = Vector2(randi() % 20 + 10, randi() % 15 + 5)
		grass.position = Vector2(x, y)
		grass.color = PALETTE.grass_2
		ground_layer.add_child(grass)

func _add_god_rays():
	for child in god_ray_container.get_children():
		child.queue_free()
	
	# 从顶部射入的光线
	var ray_count = 5
	for i in range(ray_count):
		var start_x = 200 + i * 220
		var ray = _create_god_ray(
			Vector2(start_x, -50),
			Vector2(0.3 + randf() * 0.2, 1.0),
			40 + randi() % 30
		)
		god_ray_container.add_child(ray)

func _create_god_ray(pos: Vector2, scale: Vector2, width: int) -> Node2D:
	var ray = Node2D.new()
	ray.position = pos
	
	var rays = [
		{"offset": 0, "alpha": 0.15},
		{"offset": 8, "alpha": 0.1},
		{"offset": -8, "alpha": 0.08}
	]
	
	for r in rays:
		var ray_rect = ColorRect.new()
		ray_rect.size = Vector2(width, 800)
		ray_rect.position = Vector2(r["offset"], 0)
		var col = PALETTE.gold
		col.a = r["alpha"]
		ray_rect.color = col
		ray.add_child(ray_rect)
	
	return ray

func _add_light_sources():
	for child in light_layer.get_children():
		child.queue_free()
	light_sources.clear()
	
	# 场景光源
	match current_scene_name:
		"临安城":
			_add_torch_light(Vector2(200, 350))
			_add_torch_light(Vector2(600, 350))
			_add_torch_light(Vector2(1000, 350))
		"清风寨外围":
			_add_torch_light(Vector2(400, 400))
			_add_torch_light(Vector2(800, 400))

func _add_torch_light(pos: Vector2):
	var light = PointLight2D.new()
	light.position = pos
	light.texture = _create_light_texture()
	light.texture_scale = 2.0
	light.energy = 0.8
	light.color = Color(1.0, 0.7, 0.3, 1.0)
	light_layer.add_child(light)
	light_sources.append(light)

func _create_light_texture() -> GradientTexture2D:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 0.8, 0.4, 1))
	gradient.set_color(1, Color(1, 0.8, 0.4, 0))
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 128
	tex.height = 128
	return tex

func _create_player():
	if player:
		player.queue_free()
	
	player = CharacterBody2D.new()
	player.name = "Player"
	var start_pos = GlobalData.player_data.get("position", Vector2(640, 400))
	player.position = start_pos
	
	# 玩家精灵
	player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.texture = _create_player_texture()
	player_sprite.hframes = 4
	player_sprite.vframes = 4
	player_sprite.frame = 0
	player.add_child(player_sprite)
	
	# 碰撞
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	player.add_child(col)
	
	entity_layer.add_child(player)

func _create_player_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var job = GlobalData.player_data.get("job", 0)
	var cape = PALETTE.hero_cape
	var armor = PALETTE.hero_armor
	var skin = PALETTE.hero_skin
	var hair = Color("#3a2a1a")
	var sword = Color("#c0c0c0")
	var gold = PALETTE.gold
	
	# 根据职业调整颜色
	match job:
		0: armor = Color(0.8, 0.6, 0.3)  # 少林 - 金色
		1: armor = Color(0.3, 0.6, 0.8)  # 武当 - 蓝色
		2: armor = Color(0.8, 0.3, 0.6)  # 峨眉 - 粉色
		3: armor = Color(0.5, 0.4, 0.3)  # 丐帮 - 棕色
		4: armor = Color(0.3, 0.7, 0.3) # 唐门 - 绿色
		5: armor = Color(0.8, 0.2, 0.2) # 明教 - 红色
		6: armor = Color(0.3, 0.5, 0.8) # 华山 - 蓝白
		7: armor = Color(0.4, 0.8, 0.4) # 嵩山 - 寒绿
	
	# 身体
	_set_pixel_box(img, 20, 24, 44, 52, armor)  # 身体
	_set_pixel_box(img, 24, 20, 40, 23, cape)  # 披风领口
	
	# 头部
	_set_pixel_box(img, 22, 8, 42, 20, skin)  # 脸
	_set_pixel_box(img, 22, 4, 42, 8, hair)   # 头发
	
	# 眼睛
	img.set_pixel(28, 12, Color.BLACK)
	img.set_pixel(36, 12, Color.BLACK)
	
	# 武器
	_set_pixel_line(img, 46, 16, 46, 48, sword)
	img.set_pixel(46, 14, gold)
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _set_pixel_box(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			img.set_pixel(x, y, col)

func _set_pixel_line(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color):
	for x in range(min(x1, x2), max(x1, x2) + 1):
		for y in range(min(y1, y2), max(y1, y2) + 1):
			img.set_pixel(x, y, col)

func _create_npcs():
	npcs.clear()
	for child in object_layer.get_children():
		child.queue_free()
	
	for npc_data in current_scene_config.get("npcs", []):
		var npc = _create_npc_sprite(npc_data)
		object_layer.add_child(npc)
		npcs.append(npc)

func _create_npc_sprite(data: Dictionary) -> Node2D:
	var npc = CharacterBody2D.new()
	npc.name = data["id"]
	npc.position = data["pos"]
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = _create_npc_texture(data.get("sprite", "npc_default"))
	sprite.frame = randi() % 4
	npc.add_child(sprite)
	
	# 名称标签
	var label = Label.new()
	label.name = "NameLabel"
	label.text = data["name"]
	label.position = Vector2(-20, -40)
	label.add_theme_color_override("font_color", PALETTE.gold)
	label.add_theme_font_size_override("font_size", 12)
	npc.add_child(label)
	
	# 交互提示
	var hint = Label.new()
	hint.name = "InteractHint"
	hint.text = "[E] 对话"
	hint.position = Vector2(-25, -55)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 10)
	hint.visible = false
	npc.add_child(hint)
	
	return npc

func _create_npc_texture(sprite_type: String) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match sprite_type:
		"npc_inn_keeper":
			_set_pixel_box(img, 8, 12, 24, 28, Color(0.4, 0.3, 0.2))  # 棕色衣服
			_set_pixel_box(img, 10, 4, 22, 12,			_set_pixel_box(img, 10, 4, 22, 12, Color("#e8c8a0"))  # 脸
			img.set_pixel(14, 8, Color.BLACK)
			img.set_pixel(18, 8, Color.BLACK)
		"npc_weapon":
			_set_pixel_box(img, 8, 12, 24, 28, Color(0.3, 0.3, 0.4))  # 铁匠围裙
			_set_pixel_box(img, 10, 4, 22, 12, Color("#d0a080"))  # 晒黑的脸
			img.set_pixel(14, 8, Color.BLACK)
			img.set_pixel(18, 8, Color.BLACK)
			_set_pixel_line(img, 26, 10, 26, 26, Color("#808080"))  # 锤子
		"npc_wanderer":
			_set_pixel_box(img, 8, 12, 24, 28, Color(0.2, 0.4, 0.2))  # 绿袍
			_set_pixel_box(img, 10, 4, 22, 12, Color("#e8c8a0"))  # 脸
			img.set_pixel(14, 8, Color.BLACK)
			img.set_pixel(18, 8, Color.BLACK)
		_:
			_set_pixel_box(img, 8, 12, 24, 28, Color(0.5, 0.5, 0.5))
			_set_pixel_box(img, 10, 4, 22, 12, Color("#e8c8a0"))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _create_interactables():
	interactables.clear()
	
	for item_data in current_scene_config.get("interactables", []):
		var obj = _create_interactable_object(item_data)
		object_layer.add_child(obj)
		interactables.append(obj)

func _create_interactable_object(data: Dictionary) -> Node2D:
	var obj = Node2D.new()
	obj.name = data["id"]
	obj.position = data["pos"]
	
	match data.get("type", "door"):
		"shop":
			var sign = ColorRect.new()
			sign.size = Vector2(60, 40)
			sign.color = Color(0.4, 0.25, 0.1, 1.0)
			obj.add_child(sign)
			
			var lbl = Label.new()
			lbl.text = data["name"]
			lbl.add_theme_color_override("font_color", PALETTE.gold)
			lbl.position = Vector2(5, 10)
			obj.add_child(lbl)
		"door":
			var door = ColorRect.new()
			door.size = Vector2(50, 70)
			door.color = PALETTE.wall
			obj.add_child(door)
			
			var lbl = Label.new()
			lbl.text = data["name"]
			lbl.add_theme_color_override("font_color", PALETTE.gold)
			lbl.position = Vector2(-10, -25)
			obj.add_child(lbl)
		"dungeon":
			var portal = ColorRect.new()
			portal.size = Vector2(80, 100)
			portal.color = Color(0.2, 0.1, 0.3, 0.8)
			obj.add_child(portal)
			
			var lbl = Label.new()
			lbl.text = data["name"]
			lbl.add_theme_color_override("font_color", PALETTE.magic)
			lbl.position = Vector2(-10, -25)
			obj.add_child(lbl)
		"tavern":
			var sign = ColorRect.new()
			sign.size = Vector2(60, 50)
			sign.color = Color(0.5, 0.3, 0.1, 1.0)
			obj.add_child(sign)
			
			var lbl = Label.new()
			lbl.text = "酒"
			lbl.add_theme_color_override("font_color", PALETTE.gold)
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.position = Vector2(20, 10)
			obj.add_child(lbl)
	
	return obj

func _create_fog():
	for child in fog_container.get_children():
		child.queue_free()
	fog_tiles.clear()
	
	for x in range(fog_grid_width):
		for y in range(fog_grid_height):
			var fog = ColorRect.new()
			fog.name = "fog_%d_%d" % [x, y]
			fog.size = Vector2(fog_tile_size, fog_tile_size)
			fog.position = Vector2(x * fog_tile_size, y * fog_tile_size)
			fog.color = Color(0.02, 0.02, 0.05, 0.95)
			fog_container.add_child(fog)
			fog_tiles[str(x) + "_" + str(y)] = fog

func _update_fog_around_player():
	if not player:
		return
	
	var px = int(player.position.x / fog_tile_size)
	var py = int(player.position.y / fog_tile_size)
	var radius = 5
	
	for x in range(px - radius, px + radius + 1):
		for y in range(py - radius, py + radius + 1):
			if x >= 0 and x < fog_grid_width and y >= 0 and y < fog_grid_height:
				var dist = sqrt(pow(x - px, 2) + pow(y - py, 2))
				if dist <= radius:
					var key = str(x) + "_" + str(y)
					if fog_tiles.has(key):
						var fog = fog_tiles[key]
						var alpha = max(0.0, 0.95 - (dist / radius) * 0.9)
						fog.color = Color(0.02, 0.02, 0.05, alpha)

func _create_explore_ui():
	for child in ui_layer.get_children():
		if child.name != "ChapterOverlay" and child.name != "ChapterPanel":
			child.queue_free()
	
	# 左上角状态面板
	var status_panel = Panel.new()
	status_panel.name = "StatusPanel"
	status_panel.position = Vector2(10, 10)
	status_panel.size = Vector2(250, 160)
	status_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.88)
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())
	ui_layer.add_child(status_panel)
	
	# 角色名称和等级
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(15, 12)
	name_label.text = "%s Lv.%d" % [GlobalData.get_job_name(GlobalData.player_data.get("job", 0)), GlobalData.player_data.get("level", 1)]
	name_label.add_theme_color_override("font_color", PALETTE.gold)
	name_label.add_theme_font_size_override("font_size", 14)
	status_panel.add_child(name_label)
	
	# HP条
	var hp_title = Label.new()
	hp_title.position = Vector2(15, 38)
	hp_title.text = "HP"
	hp_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hp_title.add_theme_font_size_override("font_size", 11)
	status_panel.add_child(hp_title)
	
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(40, 36)
	hp_bar.size = Vector2(195, 18)
	hp_bar.min_value = 0
	hp_bar.max_value = GlobalData.player_data.get("max_hp", 100)
	hp_bar.value = GlobalData.player_data.get("hp", 100)
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	hp_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill(Color(0.85, 0.15, 0.15)))
	status_panel.add_child(hp_bar)
	
	# MP条
	var mp_title = Label.new()
	mp_title.position = Vector2(15, 60)
	mp_title.text = "MP"
	mp_title.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	mp_title.add_theme_font_size_override("font_size", 11)
	status_panel.add_child(mp_title)
	
	mp_bar = ProgressBar.new()
	mp_bar.name = "MPBar"
	mp_bar.position = Vector2(40, 58)
	mp_bar.size = Vector2(195, 18)
	mp_bar.min_value = 0
	mp_bar.max_value = GlobalData.player_data.get("max_mp", 30)
	mp_bar.value = GlobalData.player_data.get("mp", 30)
	mp_bar.show_percentage = false
	mp_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	mp_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill(Color(0.15, 0.35, 0.85)))
	status_panel.add_child(mp_bar)
	
	# 内力条
	var qi_title = Label.new()
	qi_title.position = Vector2(15, 82)
	qi_title.text = "内力"
	qi_title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	qi_title.add_theme_font_size_override("font_size", 11)
	status_panel.add_child(qi_title)
	
	qi_bar = ProgressBar.new()
	qi_bar.name = "QiBar"
	qi_bar.position = Vector2(55, 80)
	qi_bar.size = Vector2(180, 14)
	qi_bar.min_value = 0
	qi_bar.max_value = GlobalData.player_data.get("max_qi", 50)
	qi_bar.value = GlobalData.player_data.get("qi", 50)
	qi_bar.show_percentage = false
	qi_bar.add_theme_stylebox_override("background", _create_hp_bar_bg())
	qi_bar.add_theme_stylebox_override("fill", _create_hp_bar_fill(Color(0.8, 0.6, 0.2)))
	status_panel.add_child(qi_bar)
	
	# 金币
	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.position = Vector2(15, 105)
	gold_label.text = "💰 %d 金" % GlobalData.player_data.get("gold", 0)
	gold_label.add_theme_color_override("font_color", PALETTE.gold)
	gold_label.add_theme_font_size_override("font_size", 12)
	status_panel.add_child(gold_label)
	
	# 章节和场景
	chapter_label = Label.new()
	chapter_label.name = "ChapterLabel"
	chapter_label.position = Vector2(15, 128)
	chapter_label.text = "第%d章 %s" % [current_chapter, GlobalData.CHAPTERS.get(current_chapter, {}).get("name", "")]
	chapter_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	chapter_label.add_theme_font_size_override("font_size", 11)
	status_panel.add_child(chapter_label)
	
	# 右上角场景名称
	scene_label = Label.new()
	scene_label.name = "SceneLabel"
	scene_label.position = Vector2(1000, 15)
	scene_label.text = "📍 %s" % current_scene_name
	scene_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	scene_label.add_theme_font_size_override("font_size", 14)
	ui_layer.add_child(scene_label)
	
	# 消息显示
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.position = Vector2(10, 640)
	message_label.size = Vector2(1260, 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(message_label)
	
	# 技能快捷栏
	_create_skill_bar()
	
	# 提示信息
	var hint = Label.new()
	hint.name = "ControlHint"
	hint.position = Vector2(950, 680)
	hint.text = "WASD移动 · 鼠标攻击 · 1-4技能 · E交互 · I背包 · Q任务"
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	hint.add_theme_font_size_override("font_size", 11)
	ui_layer.add_child(hint)

func _create_skill_bar():
	var skill_panel = Panel.new()
	skill_panel.name = "SkillBar"
	skill_panel.position = Vector2(540, 655)
	skill_panel.size = Vector2(200, 55)
	skill_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.88)
	skill_panel.add_theme_stylebox_override("panel", _create_panel_style())
	ui_layer.add_child(skill_panel)
	
	var skills = GlobalData.player_data.get("skills", [])
	for i in range(min(4, skills.size())):
		var skill_name = skills[i]
		var btn = Button.new()
		btn.name = "SkillBtn_%d" % i
		btn.position = Vector2(5 + i * 48, 5)
		btn.size = Vector2(45, 45)
		btn.text = "%d\n%s" % [i + 1, skill_name]
		btn.add_theme_font_size_override("font_size", 10)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		style.border_color = PALETTE.gold
		style.border_width_left = 1; style.border_width_top = 1
		style.border_width_right = 1; style.border_width_bottom = 1
		style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
		style.corner_radius_bottom_right = 3; style.corner_radius_bottom_left = 3
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
		skill_panel.add_child(btn)

func _create_panel_style() -> StyleBoxFlat:
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

func _create_hp_bar_bg() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.05)
	style.border_color = Color(0.3, 0.15, 0.15)
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _create_hp_bar_fill(col: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _clear_scene():
	# 清除所有场景层
	for child in bg_layer.get_children():
		child.queue_free()
	for child in ground_layer.get_children():
		child.queue_free()
	for child in object_layer.get_children():
		child.queue_free()
	for child in entity_layer.get_children():
		child.queue_free()
	for child in light_layer.get_children():
		child.queue_free()
	for child in god_ray_container.get_children():
		child.queue_free()
	for child in fog_container.get_children():
		child.queue_free()
	fog_tiles.clear()
	npcs.clear()
	interactables.clear()
	light_sources.clear()

func _clear_ui_layer():
	for child in ui_layer.get_children():
		child.queue_free()

# ==================== 游戏主循环 ====================

func _process(delta: float):
	match current_state:
		GameState.TITLE:
			pass
		GameState.CHAPTER_INTRO:
			pass
		GameState.EXPLORE:
			_process_explore(delta)
		GameState.BATTLE:
			_process_battle(delta)
		GameState.DIALOG:
			_process_dialog(delta)
		GameState.SHOP:
			pass
		GameState.INVENTORY:
			pass
		GameState.QUEST:
			pass
		GameState.SAVE_LOAD:
			pass
		GameState.GAME_OVER:
			pass
	
	# 更新消息显示
	_update_message_display(delta)
	
	# 更新相机
	_update_camera(delta)
	
	# 更新UI
	_update_explore_ui()

func _process_explore(delta: float):
	if not player:
		return
	
	# 冲刺
	if is_dashing:
		dash_timer -= delta
		player.position += dash_direction * dash_speed * delta
		if dash_timer <= 0:
			is_dashing = false
		return
	
	# 冲刺冷却
	if not can_dash:
		dash_cooldown -= delta
		if dash_cooldown <= 0:
			can_dash = true
	
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		velocity.y = -1
		player_direction = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 1
		player_direction = Vector2.DOWN
	
	if Input.is_action_pressed("ui_left"):
		velocity.x = -1
		player_direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		velocity.x = 1
		player_direction = Vector2.RIGHT
	
	if velocity.length() > 0:
		velocity = velocity.normalized()
		var current_speed = move_speed
		player.position += velocity * current_speed * delta
		
		# 边界限制
		player.position.x = clamp(player.position.x, 30, 1250)
		player.position.y = clamp(player.position.y, 230, 690)
		
		# 更新动画帧
		if player_sprite:
			var frame_x = 0
			if velocity.x > 0:
				frame_x = 2
			elif velocity.x < 0:
				frame_x = 1
			player_sprite.frame = frame_x + (int(Time.get_ticks_msec() / 200) % 2)
		
		# 更新迷雾
		_update_fog_around_player()
		is_moving = true
	else:
		is_moving = false
		if player_sprite:
			player_sprite.frame = player_direction.y < 0 ? 4 : 0
	
	# 冲刺
	if Input.is_action_pressed("dash") and can_dash and velocity.length() > 0:
		is_dashing = true
		can_dash = false
		dash_cooldown = 1.5
		dash_timer = dash_duration
		dash_direction = velocity.normalized()
		AudioManager.play_sfx("footstep")
	
	# 交互
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	
	# 背包
	if Input.is_key_pressed(KEY_I):
		_open_inventory()
	
	# 任务
	if Input.is_key_pressed(KEY_Q):
		_open_quest_log()
	
	# 保存
	if Input.is_key_pressed(KEY_F2):
		_show_save_menu()
	
	# 鼠标攻击检测
	if Input.is_action_pressed("attack"):
		_perform_attack()

func _update_camera(delta: float):
	if not player or not main_camera:
		return
	
	var target_pos = player.position
	main_camera.position = main_camera.position.lerp(target_pos, camera_smoothing)

func _update_explore_ui():
	if not GlobalData.player_data:
		return
	
	var pd = GlobalData.player_data
	
	if hp_bar:
		hp_bar.max_value = pd.get("max_hp", 100)
		hp_bar.value = pd.get("hp", 100)
	if mp_bar:
		mp_bar.max_value = pd.get("max_mp", 30)
		mp_bar.value = pd.get("mp", 30)
	if qi_bar:
		qi_bar.max_value = pd.get("max_qi", 50)
		qi_bar.value = pd.get("qi", 50)
	if gold_label:
		gold_label.text = "💰 %d 金" % pd.get("gold", 0)
	if chapter_label:
		chapter_label.text = "第%d章 %s" % [current_chapter, GlobalData.CHAPTERS.get(current_chapter, {}).get("name", "")]

func _update_message_display(delta: float):
	if not message_label:
		return
	
	if target_message != "" and displayed_message != target_message:
		message_char_index += delta * 30 * GlobalData.text_speed
		var char_count = int(message_char_index)
		displayed_message = target_message.substr(0, char_count)
		message_label.text = displayed_message
	elif target_message != "" and displayed_message == target_message:
		message_timer -= delta
		if message_timer <= 0:
			target_message = ""
			displayed_message = ""

func show_message(msg: String, duration: float = 3.0):
	target_message = msg
	displayed_message = ""
	message_char_index = 0
	message_timer = duration
	if message_label:
		message_label.text = ""

func _try_interact():
	if not player:
		return
	
	# 检测附近的NPC
	for npc in npcs:
		if npc and npc.position.distance_to(player.position) < 80:
			_interact_with_npc(npc)
			return
	
	# 检测附近的交互物
	for obj in interactables:
		if obj and obj.position.distance_to(player.position) < 80:
			_interact_with_object(obj)
			return

func _interact_with_npc(npc: Node2D):
	var npc_id = npc.name
	var npc_data = null
	for nd in current_scene_config.get("npcs", []):
		if nd["id"] == npc_id:
			npc_data = nd
			break
	
	if npc_data:
		_start_dialog(npc_data)
		AudioManager.play_sfx("door")

func _interact_with_object(obj: Node2D):
	var obj_id = obj.name
	var obj_data = null
	for od in current_scene_config.get("interactables", []):
		if od["id"] == obj_id:
			obj_data = od
			break
	
	if obj_data:
		match obj_data.get("action", ""):
			"open_shop":
				_open_shop()
			"enter_dungeon":
				_enter_dungeon()
			"enter_tavern":
				_enter_tavern()
			"enter_dojo":
				_enter_dojo()

func _perform_attack():
	# 简单的攻击检测
	AudioManager.play_sfx("attack")
	
	# 检测附近的敌人（在实际实现中会有敌人）
	var attack_range = 60.0
	var attack_dir = player_direction
	
	# 显示攻击特效
	_create_attack_effect(player.position + attack_dir * 30)
	
	# 查找范围内的敌人并造成伤害
	for npc in npcs:
		if npc and npc.position.distance_to(player.position + attack_dir * 30) < attack_range:
			# 如果是敌人则造成伤害
			pass

func _create_attack_effect(pos: Vector2):
	var effect = ColorRect.new()
	effect.size = Vector2(40, 40)
	effect.position = pos - Vector2(20, 20)
	effect.color = Color(1, 1, 0.5, 0.7)
	effect.modulate = Color(1, 1, 1, 1)
	entity_layer.add_child(effect)
	
	# 动画淡出
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)

# ==================== 对话系统 ====================

var dialog_panel: Panel
var dialog_text: Label
var dialog_speaker: Label
var current_dialog_data: Dictionary
var dialog_index: int = 0
var dialog_responses: Array = []

func _start_dialog(npc_data: Dictionary):
	current_state = GameState.DIALOG
	dialog_index = 0
	current_dialog_data = npc_data
	
	# 创建对话UI
	dialog_panel = Panel.new()
	dialog_panel.name = "DialogPanel"
	dialog_panel.position = Vector2(140, 520)
	dialog_panel.size = Vector2(1000, 180)
	dialog_panel.self_modulate = Color(0.03, 0.03, 0.06, 0.95)
	dialog_panel.add_theme_stylebox_override("panel", _create_panel_style())
	ui_layer.add_child(dialog_panel)
	
	# 说话者
	dialog_speaker = Label.new()
	dialog_speaker.name = "DialogSpeaker"
	dialog_speaker.position = Vector2(20, 15)
	dialog_speaker.text = npc_data["name"]
	dialog_speaker.add_theme_color_override("font_color", PALETTE.gold)
	dialog_speaker.add_theme_font_size_override("font_size", 16)
	dialog_panel.add_child(dialog_speaker)
	
	# 对话内容
	dialog_text = Label.new()
	dialog_text.name = "DialogText"
	dialog_text.position = Vector2(20, 45)
	dialog_text.size = Vector2(960, 100)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	dialog_text.add_theme_font_size_override("font_size", 15)
	dialog_panel.add_child(dialog_text)
	
	_show_next_dialog_line()

func _show_next_dialog_line():
	var lines = current_dialog_data.get("dialog", ["..."])
	if dialog_index < lines.size():
		dialog_text.text = lines[dialog_index]
		dialog_index += 1
	else:
		_end_dialog()

func _process_dialog(delta: float):
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_show_next_dialog_line()

func _end_dialog():
	if dialog_panel:
		dialog_panel.queue_free()
		dialog_panel = null
	current_state = GameState.EXPLORE
	
	# 检查是否需要触发任务更新
	_check_quest_triggers()

func _check_quest_triggers():
	# 检查任务目标
	var quests = GlobalData.player_data.get("quest_log", [])
	for quest in quests:
		if quest.get("active", false) and not quest.get("completed", false):
			for obj in quest.get("objectives", []):
				if obj.get("type", "") == "interact" and obj.get("target", "") == "inn_keeper":
					if current_dialog_data.get("id", "") == "inn_keeper":
						obj["completed"] = true
						show_message("任务更新: %s" % obj["text"])
						AudioManager.play_sfx("quest_complete")

# ==================== 副本系统 ====================

func _enter_dungeon():
	show_message("进入副本...")
	AudioManager.play_bgm("battle")
	
	# 切换场景
	_clear_scene()
	current_scene_name = "清风寨外围"
	_draw_scene_bg()
	_draw_ground()
	_add_god_rays()
	_add_light_sources()
	_create_fog()
	
	# 重置玩家位置
	if player:
		player.position = Vector2(640, 500)
	
	# 随机遭遇敌人
	if randf() < 0.4:
		_start_battle()

func _enter_tavern():
	show_message("进入酒馆...")
	AudioManager.play_bgm("inn")
	# 酒馆特殊UI
	_show_tavern_menu()

func _enter_dojo():
	show_message("进入门派大殿...")
	_show_dojo_menu()

# ==================== 战斗系统 ====================

var battle_enemy: Dictionary = {}
var battle_player_hp_bar: ProgressBar
var battle_player_mp_bar: ProgressBar
var battle_enemy_hp_bar: ProgressBar
var battle_log_text: Label
var enemy_sprite_node: Sprite2D

func _start_battle():
	current_state = GameState.BATTLE
	battle_in_progress = true
	
	# 生成敌人
	var enemy_types = _get_enemy_types_for_scene()
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	battle_enemy = _generate_enemy(enemy_type)
	
	show_message("遭遇了 %s！" % battle_enemy["name"])
	
	# 创建战斗UI
	_create_battle_ui()
	
	AudioManager.play_bgm("battle")

func _get_enemy_types_for_scene() -> Array:
	match current_scene_name:
		"临安城":
			return ["土匪", "山贼"]
		"清风寨外围":
			return ["清风弟子", "清风刀客", "清风刺客"]
		"清风寨":
			return ["清风刀客", "清风刺客", "清风护卫"]
		"魔教分坛":
			return ["魔教弟子", "魔教术士", "魔教杀手"]
		"魔教总坛":
			return ["魔教杀手", "魔教护法", "魔教长老"]
		"武林大会":
			return ["各派高手", "掌门弟子"]
	return ["土匪", "山贼"]

func _generate_enemy(type: String) -> Dictionary:
	var floor = GlobalData.player_data.get("floor", 1)
	var mult = 1.0 + floor * 0.15
	
	var enemies = {
		"土匪": {"name": "土匪", "hp": int(30*mult), "atk": int(8*mult), "def": int(3*mult), "spd": 4, "exp": 15, "gold": 10, "color": Color(0.5, 0.3, 0.2)},
		"山贼": {"name": "山贼", "hp": int(40*mult), "atk": int(10*mult), "def": int(4*mult), "spd": 5, "exp": 20, "gold": 15, "color": Color(0.4, 0.3, 0.3)},
		"清风弟子": {"name": "清风寨弟子", "hp": int(50*mult), "atk": int(12*mult), "def": int(5*mult), "spd": 6, "exp": 30, "gold": 25, "color": Color(0.2, 0.5, 0.3)},
		"清风刀客": {"name": "清风寨刀客", "hp": int(70*mult), "atk": int(18*mult), "def": int(8*mult), "spd": 7, "exp": 50, "gold": 40, "color": Color(0.3, 0.4, 0.2)},
		"清风刺客": {"name": "清风寨刺客", "hp": int(45*mult), "atk": int(22*mult), "def": int(4*mult), "spd": 10, "exp": 60, "gold": 50, "color": Color(0.2, 0.2, 0.3)},
		"清风护卫": {"name": "清风寨护卫", "hp": int(100*mult), "atk": int(20*mult), "def": int(15*mult), "spd": 5, "exp": 80, "gold": 70, "color": Color(0.3, 0.3, 0.4)},
		"魔教弟子": {"name": "魔教弟子", "hp": int(60*mult), "atk": int(15*mult), "def": int(6*mult), "spd": 7, "exp": 45, "gold": 35, "color": Color(0.4, 0.1, 0.4)},
		"魔教术士": {"name": "魔教术士", "hp": int(40*mult), "atk": int(25*mult), "def": int(3*mult), "spd": 8, "exp": 70, "gold": 60, "color": Color(0.5, 0.2, 0.5)},
		"魔教杀手": {"name": "魔教杀手", "hp": int(55*mult), "atk": int(28*mult), "def": int(5*mult), "spd": 11, "exp": 90, "gold": 80, "color": Color(0.3, 0.1, 0.3)},
		"魔教护法": {"name": "魔教护法", "hp": int(200*mult), "atk": int(35*mult), "def": int(20*mult), "spd": 8, "exp": 200, "gold": 200, "color": Color(0.5, 0.05, 0.1)},
		"魔教长老": {"name": "魔教长老", "hp": int(300*mult), "atk": int(45*mult), "def": int(25*mult), "spd": 7, "exp": 350, "gold": 350, "color": Color(0.4, 0.0, 0.2)},
		"各派高手": {"name": "各派高手", "hp": int(80*mult), "atk": int(22*mult), "def": int(12*mult), "spd": 9, "exp": 100, "gold": 90, "color": Color(0.6, 0.5, 0.3)},
		"掌门弟子": {"name": "掌门弟子", "hp": int(120*mult), "atk": int(30*mult), "def": int(18*mult), "spd": 10, "exp": 150, "gold": 150, "color": Color(0.7, 0.6, 0.4)}
	}
	
	var enemy = enemies.get(type, enemies["土匪"]).duplicate()
	enemy["max_hp"] = enemy["hp"]
	return enemy

func _create_battle_ui():
	# 暗色背景
	var overlay = ColorRect.new()
	overlay.name = "BattleOverlay"
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.position = Vector2(0, 0)
	ui_layer.add_child(overlay)
	
	battle_ui = Control.new()
	battle_ui.name = "BattleUI"
	ui_layer.add_child(battle_ui)
	
	# 敌人面板
	var enemy_panel = Panel.new()
	enemy_panel.name = "EnemyPanel"
	enemy_panel.position = Vector2(440, 60)
	enemy_panel.size = Vector2(400, 220)
	enemy_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.9)
	enemy_panel.add_theme_stylebox_override("panel", _create_panel_style())
	battle_ui.add_child(enemy_panel)
	
	# 敌人名称
	enemy_name_label = Label.new()
	enemy_name_label.position = Vector2(20, 15)
	enemy_name_label.text = battle_enemy.get("name", "敌人")
	enemy_name_label
