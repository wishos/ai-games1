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

# 装备强化等级
var weapon_enhance: int = 0
var armor_enhance: int = 0
var accessory_enhance: int = 0

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
			skills = ["火球", "冰霜", "闪电", "流星火雨", "霜冻领域", "连锁闪电", "魔法盾", "法术穿透", "魔力回旋", "陨石术", "绝对零度", "元素风暴", "时间静止"]
		Job.HUNTER:
			skills = ["狙击", "陷阱", "毒箭", "致命陷阱", "猎豹加速", "穿甲箭", "一击脱离", "万箭齐发", "猎杀时刻", "野兽之力"]
		Job.THIEF:
			skills = ["背刺", "暗影", "消失", "影遁", "淬毒利刃", "锁喉"]
		Job.PRIEST:
			skills = ["治疗", "护盾", "复活", "群体治疗", "驱散", "神圣仲裁"]
		Job.KNIGHT:
			skills = ["格挡", "斩击", "神圣", "盾击", "圣光审判", "钢铁壁垒"]
		Job.BARD:
			skills = ["鼓舞", "旋律", "沉默", "战斗乐章", "疯狂节拍", "天籁之音"]
		Job.SUMMONER:
			skills = ["召唤", "契约", "共鸣", "契约强化", "灵魂连接", "召唤兽强化"]

func get_job_name() -> String:
	return job_name[job]

func attack_power() -> int:
	var wpn_atk = weapon.get("atk", 0)
	var wpn_grade = weapon.get("grade", 1)
	var enhance_bonus = _enhance_stat_bonus(wpn_grade, weapon_enhance)
	return atk + wpn_atk + enhance_bonus

func defense() -> int:
	var arm_def = armor.get("def", 0)
	var arm_grade = armor.get("grade", 1)
	var enhance_bonus = _enhance_stat_bonus(arm_grade, armor_enhance)
	return def + arm_def + enhance_bonus

func _enhance_stat_bonus(grade: int, enhance_level: int) -> int:
	# 每级强化根据等级提供不同加成
	# +1~+5: 每级+3%基础属性; +6~+10: 每级+5%; +11~+15: 每级+8%
	if enhance_level <= 0:
		return 0
	var base = 0
	if grade >= 5:
		base = 100  # 传说/神器基础值高
	elif grade >= 3:
		base = 50   # 稀有/史诗
	else:
		base = 20  # 普通/优秀
	var bonus = 0
	for i in range(1, enhance_level + 1):
		if i <= 5:
			bonus += int(base * 0.03)
		elif i <= 10:
			bonus += int(base * 0.05)
		else:
			bonus += int(base * 0.08)
	return bonus

func level_up_requirement() -> int:
	return int(pow(level, 1.5) * 60)