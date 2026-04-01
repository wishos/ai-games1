# 玩家角色数据
class_name PlayerData extends RefCounted

var hp: int = 120
var max_hp: int = 120
var mp: int = 30
var max_mp: int = 30
var level: int = 1
var exp: int = 0
var gold: int = 0
var atk: int = 14
var def: int = 6
var spd: int = 5
var luk: int = 3

# 职业定义
enum Job { WARRIOR, MAGE, HUNTER, THIEF, PRIEST, KNIGHT, BARD, SUMMONER }

var job: Job = Job.WARRIOR
var job_name: Array = ["战士", "法师", "猎人", "盗贼", "牧师", "骑士", "吟游诗人", "召唤师"]

# 技能
var skills: Array = []

# 装备
var weapon: Dictionary = {}
var armor: Dictionary = {}
var accessory: Dictionary = {}

# 背包
var inventory: Array = [
	{"type": "小血药", "count": 2, "heal_hp": 30, "heal_mp": 0},
	{"type": "小蓝药", "count": 1, "heal_hp": 0, "heal_mp": 30}
]

func _init():
	_setup_job_skills()

func _setup_job_skills():
	match job:
		Job.WARRIOR:
			skills = ["猛击", "防御", "冲锋", "血之狂暴", "旋风斩", "战吼"]
		Job.MAGE:
			skills = ["火球", "冰霜", "闪电"]
		Job.HUNTER:
			skills = ["狙击", "陷阱", "毒箭"]
		Job.THIEF:
			skills = ["背刺", "暗影", "消失"]
		Job.PRIEST:
			skills = ["治疗", "护盾", "复活"]
		Job.KNIGHT:
			skills = ["格挡", "斩击", "神圣"]
		Job.BARD:
			skills = ["鼓舞", "旋律", "沉默"]
		Job.SUMMONER:
			skills = ["召唤", "契约", "共鸣"]

func get_job_name() -> String:
	return job_name[job]

func attack_power() -> int:
	var wpn_atk = weapon.get("atk", 0)
	return atk + wpn_atk

func defense() -> int:
	var arm_def = armor.get("def", 0)
	return def + arm_def

func level_up_requirement() -> int:
	return int(pow(level, 1.5) * 60)