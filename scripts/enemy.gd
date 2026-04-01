# 敌人数据
class_name EnemyData extends RefCounted

var name: String = ""
var hp: int = 0
var max_hp: int = 0
var atk: int = 0
var def: int = 0
var spd: int = 0
var exp_reward: int = 0
var gold_reward: int = 0
var color: Color = Color.WHITE

func _init(type: String = "slime", floor: int = 1):
	_setup_enemy(type, floor)

func _setup_enemy(type: String, floor: int):
	var mult = 1.0 + floor * 0.12
	
	match type:
		# ===== 1-2层：新手区 =====
		"slime":
			name = "史莱姆"
			hp = int(25 * mult); max_hp = hp
			atk = int(6 * mult); def = 2
			spd = 3; exp_reward = 12; gold_reward = 8
			color = Color(0.4, 0.7, 0.4)  # 绿色
		"bat":
			name = "洞穴蝙蝠"
			hp = int(18 * mult); max_hp = hp
			atk = int(8 * mult); def = 1
			spd = 8; exp_reward = 10; gold_reward = 6
			color = Color(0.45, 0.3, 0.55)  # 暗紫
		"wild_boar":
			name = "野猪"
			hp = int(35 * mult); max_hp = hp
			atk = int(10 * mult); def = 4
			spd = 5; exp_reward = 18; gold_reward = 10
			color = Color(0.55, 0.35, 0.2)  # 棕色
		
		# ===== 3-4层：中级区 =====
		"skeleton":
			name = "骷髅战士"
			hp = int(40 * mult); max_hp = hp
			atk = int(12 * mult); def = 5
			spd = 4; exp_reward = 25; gold_reward = 15
			color = Color(0.85, 0.85, 0.75)  # 骨白色
		"goblin":
			name = "哥布林"
			hp = int(32 * mult); max_hp = hp
			atk = int(14 * mult); def = 4
			spd = 6; exp_reward = 22; gold_reward = 18
			color = Color(0.5, 0.65, 0.3)  # 绿褐
		"ghost":
			name = "幽灵"
			hp = int(28 * mult); max_hp = hp
			atk = int(16 * mult); def = 2
			spd = 7; exp_reward = 30; gold_reward = 20
			color = Color(0.7, 0.8, 1.0)  # 幽蓝白
		
		# ===== 5-6层：高级区 =====
		"demon":
			name = "深渊恶魔"
			hp = int(80 * mult); max_hp = hp
			atk = int(22 * mult); def = 8
			spd = 5; exp_reward = 60; gold_reward = 45
			color = Color(0.65, 0.15, 0.25)  # 深红
		"orc":
			name = "兽人战士"
			hp = int(95 * mult); max_hp = hp
			atk = int(20 * mult); def = 10
			spd = 4; exp_reward = 55; gold_reward = 40
			color = Color(0.4, 0.55, 0.35)  # 暗绿褐
		"dark_skeleton":
			name = "暗黑骷髅"
			hp = int(60 * mult); max_hp = hp
			atk = int(18 * mult); def = 8
			spd = 5; exp_reward = 48; gold_reward = 35
			color = Color(0.3, 0.3, 0.45)  # 深灰蓝
		
		# ===== 7-8层：精英区 =====
		"shadow_assassin":
			name = "暗影刺客"
			hp = int(50 * mult); max_hp = hp
			atk = int(28 * mult); def = 5
			spd = 12; exp_reward = 80; gold_reward = 60
			color = Color(0.15, 0.1, 0.2)  # 近黑紫
		"dark_knight":
			name = "暗黑骑士"
			hp = int(120 * mult); max_hp = hp
			atk = int(25 * mult); def = 15
			spd = 4; exp_reward = 90; gold_reward = 70
			color = Color(0.2, 0.2, 0.35)  # 铁灰蓝
		"dragon":
			name = "远古巨龙"
			hp = int(300 * mult); max_hp = hp
			atk = int(40 * mult); def = 20
			spd = 6; exp_reward = 300; gold_reward = 500
			color = Color(0.4, 0.05, 0.15)  # 暗红

# 获取每层可用的敌人类型列表
static func get_floor_enemies(floor: int) -> Array:
	if floor <= 2:
		return ["slime", "bat", "wild_boar"]
	elif floor <= 4:
		return ["skeleton", "goblin", "ghost"]
	elif floor <= 6:
		return ["demon", "orc", "dark_skeleton"]
	else:
		return ["shadow_assassin", "dark_knight", "demon"]

func get_sprite_color() -> Color:
	return color
