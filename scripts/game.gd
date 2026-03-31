extends Node2D

# 游戏状态
enum State { EXPLORE, BATTLE, DIALOG, SHOP }
var game_state = State.EXPLORE

# 玩家
var player: CharacterBody2D

# 地图
var tile_map: TileMap
var current_floor: int = 1
var fog_map: Dictionary = {}

# 战斗
var current_enemy: Dictionary = {}
var battle_ui: Control

# UI
var hp_label: Label
var mp_label: Label
var gold_label: Label
var floor_label: Label
var message_label: Label

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

func _ready():
	randomize()
	_setup_ui()
	_generate_map()
	_setup_player()
	print("八方旅人 - Octopath Adventure 已启动!")

func _setup_ui():
	# 创建UI面板
	var ui_panel = Panel.new()
	ui_panel.position = Vector2(10, 10)
	ui_panel.size = Vector2(200, 120)
	ui_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.85)
	ui_panel.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(ui_panel)
	
	# 标签
	hp_label = Label.new()
	hp_label.position = Vector2(20, 20)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	ui_panel.add_child(hp_label)
	
	mp_label = Label.new()
	mp_label.position = Vector2(20, 45)
	mp_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	ui_panel.add_child(mp_label)
	
	gold_label = Label.new()
	gold_label.position = Vector2(20, 70)
	gold_label.add_theme_color_override("font_color", PALETTE.gold)
	ui_panel.add_child(gold_label)
	
	floor_label = Label.new()
	floor_label.position = Vector2(20, 95)
	floor_label.add_theme_color_override("font_color", Color.WHITE)
	ui_panel.add_child(floor_label)
	
	# 消息标签
	message_label = Label.new()
	message_label.position = Vector2(10, 650)
	message_label.size = Vector2(1260, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(message_label)
	
	# 右上面板
	var ui_right = Panel.new()
	ui_right.position = Vector2(1070, 10)
	ui_right.size = Vector2(200, 80)
	ui_right.self_modulate = Color(0.04, 0.04, 0.08, 0.85)
	ui_right.add_theme_stylebox_override("panel", _create_stylebox())
	add_child(ui_right)
	
	var title_label = Label.new()
	title_label.position = Vector2(20, 15)
	title_label.text = "探索"
	title_label.add_theme_color_override("font_color", PALETTE.gold)
	ui_right.add_child(title_label)
	
	floor_label = Label.new()
	floor_label.position = Vector2(20, 40)
	floor_label.add_theme_color_override("font_color", Color.WHITE)
	ui_right.add_child(floor_label)

func _create_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.85)
	style.border_color = PALETTE.gold
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style

func _setup_player():
	player = CharacterBody2D.new()
	player.position = Vector2(200, 200)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# 创建像素画布
	var texture = _create_knight_texture()
	sprite.texture = texture
	player.add_child(sprite)
	
	# 碰撞
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	player.add_child(col)
	
	add_child(player)
	show_message("WASD移动 · 撞墙遇敌")

func _create_knight_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# 骑士像素绘制
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

func _set_pixel_line(img: Image, x1: int, y: int, x2: int, y2: int, col: Color):
	for x in range(x1, x2 + 1):
		img.set_pixel(x, y, col)

func _generate_map():
	# 创建背景
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.position = Vector2(0, 0)
	var grad = Gradient.new()
	grad.set_color(0, PALETTE.sky_top)
	grad.set_color(1, PALETTE.sky_bottom)
	# 使用纯色背景
	bg.color = PALETTE.sky_top
	add_child(bg)
	
	# 创建地面
	var ground = ColorRect.new()
	ground.size = Vector2(1280, 400)
	ground.position = Vector2(0, 200)
	ground.color = PALETTE.grass_1
	add_child(ground)
	
	# 创建迷雾覆盖层
	for x in range(0, 80):
		for y in range(0, 45):
			var fog = ColorRect.new()
			fog.size = Vector2(16, 16)
			fog.position = Vector2(x * 16, y * 16)
			fog.color = Color(0.02, 0.02, 0.04, 0.95)
			fog.name = "fog_%d_%d" % [x, y]
			add_child(fog)
			fog_map[str(x) + "_" + str(y)] = fog
	
	# 初始化玩家周围可见
	_reveal_area(12, 12, 5)

func _reveal_area(cx: int, cy: int, radius: int):
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			if x >= 0 and x < 80 and y >= 0 and y < 45:
				var dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
				if dist <= radius:
					var key = str(x) + "_" + str(y)
					if fog_map.has(key):
						var fog = fog_map[key]
						var alpha = 0.95 - (dist / radius) * 0.8
						fog.color = Color(0.02, 0.02, 0.04, max(0, alpha))

var player_tile_x: int = 12
var player_tile_y: int = 12

func _process(delta):
	if game_state != State.EXPLORE:
		return
	
	var speed = 200 * delta
	var moved = false
	
	if Input.is_action_pressed("ui_up"):
		player.position.y -= speed
		moved = true
	elif Input.is_action_pressed("ui_down"):
		player.position.y += speed
		moved = true
	elif Input.is_action_pressed("ui_left"):
		player.position.x -= speed
		moved = true
	elif Input.is_action_pressed("ui_right"):
		player.position.x += speed
		moved = true
	
	if moved:
		# 边界检查
		player.position.x = clamp(player.position.x, 8, 1272)
		player.position.y = clamp(player.position.y, 8, 712)
		
		# 更新迷雾
		var new_tile_x = int(player.position.x / 16)
		var new_tile_y = int(player.position.y / 16)
		if new_tile_x != player_tile_x or new_tile_y != player_tile_y:
			player_tile_x = new_tile_x
			player_tile_y = new_tile_y
			_reveal_area(player_tile_x, player_tile_y, 4)
	
	# 更新UI
	_update_ui()

func _update_ui():
	hp_label.text = "HP: 120/120"
	mp_label.text = "MP: 30/30"
	gold_label.text = "金币: 0"

func show_message(msg: String):
	message_label.text = msg

# 碰撞检测 (简化)
func _physics_process(delta):
	pass
