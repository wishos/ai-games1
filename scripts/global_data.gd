extends Node

# 全局游戏数据 - Autoload

# 调色板 (武侠风格)
const PALETTE = {
	"sky_top": Color("#0a1520"),
	"sky_bottom": Color("#2a3a4a"),
	"grass_1": Color("#2a4a2a"),
	"grass_2": Color("#3a5a35"),
	"wall": Color("#3a3a4a"),
	"wall_top": Color("#5a5a6a"),
	"path": Color("#6a5a4a"),
	"hero_cape": Color("#8b2942"),
	"hero_armor": Color("#4a6a8a"),
	"hero_skin": Color("#e8c8a0"),
	"gold": Color("#c9a227"),
	"blood": Color("#8b0000"),
	"magic": Color("#4a2a8b"),
	"poison": Color("#2a8b2a"),
	"ice": Color("#2ab8ff"),
	"fire": Color("#ff4a2a"),
	"lightning": Color("#ffff2a")
}

# 章节定义
const CHAPTERS = {
	1: {
		"name": "初入江湖",
		"description": "少年侠客初出茅庐，踏入这纷争不断的江湖...",
		"unlocks": ["临安城", "清风寨外围"],
		"boss": null
	},
	2: {
		"name": "江湖风波",
		"description": "邪教势力逐渐浮出水面，江湖各派人心惶惶...",
		"unlocks": ["临安城", "清风寨", "魔教分坛"],
		"boss": "清风寨主"
	},
	3: {
		"name": "邪教阴谋",
		"description": "邪教总坛现身，幕后黑手终于露出真面目...",
		"unlocks": ["临安城", "清风寨", "魔教总坛"],
		"boss": "邪教护法"
	},
	4: {
		"name": "武林至尊",
		"description": "终极对决，一战定江湖！",
		"unlocks": ["临安城", "魔教总坛", "武林大会"],
		"boss": "邪教教主"
	}
}

# 武器类型
const WEAPON_TYPES = {
	"sword": {"name": "剑", "atk_scale": 1.0, "desc": "均衡型武器，适合新手"},
	"blade": {"name": "刀", "atk_scale": 1.2, "desc": "攻击力较高，但稍逊技巧"},
	"staff": {"name": "棍", "atk_scale": 0.9, "desc": "攻击范围广，攻速较慢"},
	"fist": {"name": "拳", "atk_scale": 0.8, "desc": "攻速快，暴击率高"},
	"dagger": {"name": "匕首", "atk_scale": 0.7, "desc": "高暴击，可背刺"},
	"spear": {"name": "长枪", "atk_scale": 1.1, "desc": "攻击距离远"}
}

# 场景定义
const SCENES = {
	"title": {"name": "标题画面", "type": "menu"},
	"chapter_select": {"name": "章节选择", "type": "menu"},
	"inn": {"name": "客栈", "type": "social", "services": ["休息", "传闻", "任务"]},
	"tavern": {"name": "酒馆", "type": "social", "services": ["打听消息", "接任务", "喝酒"]},
	"dojo": {"name": "门派", "type": "social", "services": ["学习技能", "升级", "请教"]},
	"market": {"name": "集市", "type": "shop", "services": ["购买装备", "购买药水", "出售物品"]},
	"dungeon_entrance": {"name": "副本入口", "type": "dungeon"},
	"dungeon_floor": {"name": "副本层", "type": "battle"},
	"boss_arena": {"name": "BOSS战场", "type": "boss"}
}

# 当前游戏状态
var current_chapter: int = 1
var current_scene: String = "title"
var player_data: Dictionary = {}
var quest_log: Array = []
var save_slots: Array = [null, null, null]

# 游戏设置
var master_volume: float = 0.8
var bgm_volume: float = 0.6
var sfx_volume: float = 0.7
var text_speed: float = 1.0
var battle_speed: float = 1.0

func _ready():
	load_settings()
	# 初始化3个存档槽
	for i in range(3):
		if save_slots[i] == null:
			save_slots[i] = {"exists": false}

func create_new_game(job: int = 0, weapon_type: String = "sword") -> Dictionary:
	var pd = {
		"exists": true,
		"name": "江湖侠客",
		"job": job,
		"weapon_type": weapon_type,
		"level": 1,
		"exp": 0,
		"hp": 100,
		"max_hp": 100,
		"mp": 30,
		"max_mp": 30,
		"atk": 10,
		"def": 5,
		"spd": 5,
		"luk": 2,
		"qi": 50,  # 内力值
		"max_qi": 50,
		"gold": 100,
		"chapter": 1,
		"floor": 1,
		"position": Vector2(640, 400),
		"inventory": [
			{"type": "potion_hp_small", "count": 3, "name": "小血药", "heal_hp": 30, "heal_mp": 0, "desc": "恢复30%生命值"},
			{"type": "potion_mp_small", "count": 2, "name": "小蓝药", "heal_hp": 0, "heal_mp": 30, "desc": "恢复30%内力值"}
		],
		"equipment": {
			"weapon": null,
			"armor": null,
			"accessory1": null,
			"accessory2": null
		},
		"skills": [],
		"skill_levels": {},
		"quest_log": [],
		"completed_quests": [],
		"discovered_scenes": ["临安城"],
		"bosses_defeated": [],
		"play_time": 0.0,
		"created_at": Time.get_datetime_string_from_system()
	}
	
	# 根据职业设置初始技能
	match job:
		0: # 少林
			pd["skills"] = ["金钟罩", "罗汉拳", "狮子吼"]
		1: # 武当
			pd["skills"] = ["太极剑", "太极拳", "梯云纵"]
		2: # 峨眉
			pd["skills"] = ["九阴白骨爪", "素女剑法", "冰魄银针"]
		3: # 丐帮
			pd["skills"] = ["打狗棒法", "降龙十八掌", "醉拳"]
		4: # 唐门
			pd["skills"] = ["暴雨梨花针", "夺魂箭", "迷踪步"]
		5: # 明教
			pd["skills"] = ["圣火令", "乾坤大挪移", "九阳神功"]
		6: # 华山
			pd["skills"] = ["独孤九剑", "华山剑法", "紫霞神功"]
		7: # 嵩山
			pd["skills"] = ["寒冰真气", "嵩山剑法", "吸星大法"]
	
	for skill in pd["skills"]:
		pd["skill_levels"][skill] = 1
	
	# 初始装备
	pd["equipment"]["weapon"] = {
		"id": "wpn_001",
		"name": "新手木剑",
		"type": "weapon",
		"weapon_type": weapon_type,
		"rarity": 1,
		"atk": 5,
		"def": 0,
		"spd": 0,
		"luk": 0,
		"hp": 0,
		"mp": 0,
		"qi": 0,
		"price": 0,
		"desc": "新手入门武器",
		"icon": "⚔️"
	}
	
	# 初始任务
	pd["quest_log"] = [
		{
			"id": "q001",
			"title": "初识江湖",
			"desc": "去临安城客栈打听消息，了解当前江湖动态",
			"chapter": 1,
			"objectives": [
				{"id": "obj1", "text": "前往客栈", "completed": false, "type": "goto", "target": "inn"},
				{"id": "obj2", "text": "与掌柜对话", "completed": false, "type": "interact", "target": "inn_keeper"},
				{"id": "obj3", "text": "接受主线任务", "completed": false, "type": "accept_quest", "target": "q001"}
			],
			"rewards": {"exp": 100, "gold": 50, "items": []},
			"completed": false,
			"active": true
		}
	]
	
	player_data = pd
	return pd

func get_job_name(job: int) -> String:
	var names = ["少林弟子", "武当弟子", "峨眉弟子", "丐帮弟子", "唐门弟子", "明教弟子", "华山弟子", "嵩山弟子"]
	return names[job] if job < names.size() else "江湖侠客"

func get_weapon_name(wtype: String) -> String:
	return WEAPON_TYPES.get(wtype, {"name": "剑"}).get("name", "剑")

func level_up_requirement(level: int) -> int:
	return int(pow(level, 1.5) * 50)

func calculate_attack() -> int:
	var atk = player_data.get("atk", 10)
	var weapon = player_data.get("equipment", {}).get("weapon")
	if weapon:
		atk += weapon.get("atk", 0)
	# 武器类型加成
	var wtype = player_data.get("weapon_type", "sword")
	var scale = WEAPON_TYPES.get(wtype, {"atk_scale": 1.0}).get("atk_scale", 1.0)
	return int(atk * scale)

func calculate_defense() -> int:
	var def = player_data.get("def", 5)
	var armor = player_data.get("equipment", {}).get("armor")
	if armor:
		def += armor.get("def", 0)
	return def

func calculate_spd() -> int:
	var spd = player_data.get("spd", 5)
	var acc = player_data.get("equipment", {}).get("accessory1")
	if acc:
		spd += acc.get("spd", 0)
	return spd

func calculate_luk() -> int:
	var luk = player_data.get("luk", 2)
	var acc = player_data.get("equipment", {}).get("accessory2")
	if acc:
		luk += acc.get("luk", 0)
	return luk

func gain_exp(amount: int) -> bool:
	player_data["exp"] += amount
	var lvl = player_data.get("level", 1)
	var req = level_up_requirement(lvl)
	var leveled_up = false
	while player_data["exp"] >= req:
		player_data["exp"] -= req
		player_data["level"] += 1
		player_data["max_hp"] += 15
		player_data["max_mp"] += 5
		player_data["hp"] = player_data["max_hp"]
		player_data["mp"] = player_data["max_mp"]
		player_data["atk"] += 3
		player_data["def"] += 2
		player_data["spd"] += 1
		player_data["luk"] += 1
		leveled_up = true
		req = level_up_requirement(player_data["level"])
	return leveled_up

func save_game(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	var save_path = "user://save_slot_%d.json" % slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	var json_str = JSON.stringify(player_data)
	file.store_string(json_str)
	file.close()
	save_slots[slot] = player_data.duplicate(true)
	save_slots[slot]["exists"] = true
	save_settings()
	return true

func load_game(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	var save_path = "user://save_slot_%d.json" % slot
	if not FileAccess.file_exists(save_path):
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return false
	player_data = json.get_data()
	if typeof(player_data) != TYPE_DICTIONARY:
		return false
	save_slots[slot] = player_data.duplicate(true)
	return true

func has_save(slot: int) -> bool:
	return save_slots[slot] != null and save_slots[slot].get("exists", false)

func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	var save_path = "user://save_slot_%d.json" % slot
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	save_slots[slot] = {"exists": false}
	save_settings()
	return true

func save_settings():
	var settings = {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"text_speed": text_speed,
		"battle_speed": battle_speed
	}
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

func load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				master_volume = data.get("master_volume", 0.8)
				bgm_volume = data.get("bgm_volume", 0.6)
				sfx_volume = data.get("sfx_volume", 0.7)
				text_speed = data.get("text_speed", 1.0)
				battle_speed = data.get("battle_speed", 1.0)
