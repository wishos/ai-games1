extends Node

# 音频管理器 - Autoload

var current_bgm: String = ""
var bgm_playing: bool = false
var sfx_playing: bool = false

# 模拟音频系统 (实际项目应使用真实音频文件)
const BGM_FILES = {
	"title": "title_theme",
	"explore": "explore_theme",
	"battle": "battle_theme",
	"boss": "boss_theme",
	"victory": "victory_theme",
	"inn": "inn_theme",
	"shop": "shop_theme",
	"chapter_intro": "chapter_intro_theme"
}

const SFX_FILES = {
	"attack": "sword_slash",
	"crit": "crit_hit",
	"skill": "skill_cast",
	"hit": "enemy_hit",
	"death": "player_death",
	"levelup": "level_up",
	"purchase": "purchase",
	"flee": "flee",
	"quest_complete": "quest_complete",
	"door": "door_open",
	"footstep": "footstep",
	"coin": "coin",
	"potion": "potion",
	"equip": "equip",
	"heal": "heal",
	"shield": "shield",
	"buff": "buff",
	"debuff": "debuff",
	"enemy_death": "enemy_death",
	"boss_intro": "boss_intro"
}

func _ready():
	# 初始化音频
	pass

func play_bgm(name: String):
	if current_bgm == name and bgm_playing:
		return
	current_bgm = name
	bgm_playing = true
	# 实际项目中这里会播放音频文件
	# AudioStreamPlayer.stream = load("res://audio/bgm/%s.ogg" % BGM_FILES.get(name, "explore"))
	# AudioStreamPlayer.play()
	print("[BGM] Playing: %s" % name)

func stop_bgm():
	bgm_playing = false
	print("[BGM] Stopped")

func play_sfx(name: String):
	# 实际项目中这里会播放音效文件
	# var stream = load("res://audio/sfx/%s.ogg" % SFX_FILES.get(name, "hit"))
	# AudioStreamPlayer.stream = stream
	# AudioStreamPlayer.play()
	print("[SFX] Playing: %s" % name)

func set_master_volume(vol: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(vol))

func set_bgm_volume(vol: float):
	pass

func set_sfx_volume(vol: float):
	pass
