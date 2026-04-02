# 敌人数据 - 武侠江湖主题
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
var faction: String = ""  # 势力: 草寇/邪派/散人/正派/叛门

func _init(type: String = "bandit", floor: int = 1):
	_setup_enemy(type, floor)

func _setup_enemy(type: String, floor: int):
	var mult = 1.0 + floor * 0.12
	
	match type:
		# ===== 1-2层：草寇势力 =====
		"bandit":
			name = "劫道山贼"
			hp = int(40 * mult); max_hp = hp
			atk = int(12 * mult); def = 4
			spd = 4; exp_reward = 15; gold_reward = 10
			color = Color(0.55, 0.35, 0.2)  # 褐色
			faction = "草寇"
		"bandit_elite":
			name = "荒野土匪"
			hp = int(60 * mult); max_hp = hp
			atk = int(18 * mult); def = 6
			spd = 7; exp_reward = 30; gold_reward = 20
			color = Color(0.6, 0.25, 0.15)  # 深褐
			faction = "草寇"
		"deserter":
			name = "逃兵"
			hp = int(50 * mult); max_hp = hp
			atk = int(15 * mult); def = 8
			spd = 5; exp_reward = 25; gold_reward = 15
			color = Color(0.4, 0.4, 0.45)  # 灰褐
			faction = "草寇"
		
		# ===== 3-4层：邪派势力 =====
		"blood_sect_disciple":
			name = "血刀门弟子"
			hp = int(55 * mult); max_hp = hp
			atk = int(20 * mult); def = 6
			spd = 6; exp_reward = 40; gold_reward = 30
			color = Color(0.7, 0.15, 0.15)  # 血红
			faction = "邪派"
		"riyue_follower":
			name = "日月神教教徒"
			hp = int(80 * mult); max_hp = hp
			atk = int(24 * mult); def = 8
			spd = 5; exp_reward = 60; gold_reward = 50
			color = Color(0.6, 0.5, 0.1)  # 金黄
			faction = "邪派"
		"wudu_disciple":
			name = "五毒教教徒"
			hp = int(45 * mult); max_hp = hp
			atk = int(22 * mult); def = 4
			spd = 8; exp_reward = 50; gold_reward = 40
			color = Color(0.3, 0.5, 0.2)  # 毒绿
			faction = "邪派"
		
		# ===== 5-6层：江湖散人 =====
		"assassin":
			name = "江湖刺客"
			hp = int(60 * mult); max_hp = hp
			atk = int(35 * mult); def = 6
			spd = 14; exp_reward = 80; gold_reward = 80
			color = Color(0.15, 0.1, 0.2)  # 夜行黑
			faction = "散人"
		"bounty_hunter":
			name = "赏金猎人"
			hp = int(110 * mult); max_hp = hp
			atk = int(32 * mult); def = 14
			spd = 9; exp_reward = 120; gold_reward = 100
			color = Color(0.5, 0.45, 0.3)  # 皮甲棕
			faction = "散人"
		"arena_champion":
			name = "擂台霸主"
			hp = int(100 * mult); max_hp = hp
			atk = int(28 * mult); def = 12
			spd = 6; exp_reward = 100; gold_reward = 90
			color = Color(0.7, 0.35, 0.1)  # 拳套橙
			faction = "散人"
		
		# ===== 7-8层：门派精英 =====
		"shaolin_disciple":
			name = "少林弟子"
			hp = int(90 * mult); max_hp = hp
			atk = int(26 * mult); def = 16
			spd = 5; exp_reward = 100; gold_reward = 70
			color = Color(0.85, 0.65, 0.2)  # 僧袍黄
			faction = "正派"
		"wudang_disciple":
			name = "武当弟子"
			hp = int(70 * mult); max_hp = hp
			atk = int(24 * mult); def = 10
			spd = 8; exp_reward = 100; gold_reward = 70
			color = Color(0.7, 0.8, 0.9)  # 道袍青白
			faction = "正派"
		"hidden_master":
			name = "隐世高手"
			hp = int(130 * mult); max_hp = hp
			atk = int(38 * mult); def = 18
			spd = 10; exp_reward = 150; gold_reward = 120
			color = Color(0.3, 0.25, 0.5)  # 锦袍紫
			faction = "散人"
		"skeleton_warrior":
			name = "骷髅战士"
			hp = int(80 * mult); max_hp = hp
			atk = int(22 * mult); def = 8
			spd = 6; exp_reward = 60; gold_reward = 40
			color = Color(0.9, 0.9, 0.9)  # 骨白色
			faction = "邪派"
		"demon_red":
			name = "赤焰魔"
			hp = int(120 * mult); max_hp = hp
			atk = int(30 * mult); def = 12
			spd = 8; exp_reward = 100; gold_reward = 80
			color = Color(0.9, 0.2, 0.1)  # 赤红色
			faction = "邪派"

# 获取每层可用的敌人类型列表
static func get_floor_enemies(floor: int) -> Array:
	if floor <= 2:
		return ["bandit", "bandit_elite", "deserter"]
	elif floor <= 4:
		return ["blood_sect_disciple", "riyue_follower", "wudu_disciple", "skeleton_warrior"]
	elif floor <= 6:
		return ["assassin", "bounty_hunter", "arena_champion", "demon_red"]
	else:
		return ["shaolin_disciple", "wudang_disciple", "hidden_master", "skeleton_warrior", "demon_red"]

func get_sprite_color() -> Color:
	return color
