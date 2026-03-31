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
		"slime":
			name = "史莱姆"
			hp = int(25 * mult); max_hp = hp
			atk = int(6 * mult); def = 2
			spd = 3; exp_reward = 12; gold_reward = 8
			color = Color(0.4, 0.7, 0.4)  # 绿色
		"skeleton":
			name = "骷髅战士"
			hp = int(40 * mult); max_hp = hp
			atk = int(12 * mult); def = 5
			spd = 4; exp_reward = 25; gold_reward = 15
			color = Color(0.85, 0.85, 0.75)  # 骨白色
		"demon":
			name = "深渊恶魔"
			hp = int(80 * mult); max_hp = hp
			atk = int(22 * mult); def = 8
			spd = 5; exp_reward = 60; gold_reward = 45
			color = Color(0.65, 0.15, 0.25)  # 深红
		"dragon":
			name = "远古巨龙"
			hp = int(300 * mult); max_hp = hp
			atk = int(40 * mult); def = 20
			spd = 6; exp_reward = 300; gold_reward = 500
			color = Color(0.4, 0.05, 0.15)  # 暗红

func get_sprite_color() -> Color:
	return color