extends Node

# 音频管理器 - Autoload
# 支持 BGM 播放、SFX 播放、音量控制、淡入淡出
# 需要在项目设置中添加 AudioStreamPlayer 节点或预加载音频文件

var current_bgm: String = ""
var bgm_playing: bool = false
var sfx_playing: bool = false

# 音量设置
var master_volume: float = 1.0  # 0.0 - 1.0
var bgm_volume: float = 0.7      # 0.0 - 1.0
var sfx_volume: float = 0.8       # 0.0 - 1.0

# BGM 播放器（用于淡入淡出）
var bgm_player: AudioStreamPlayer = null
var bgm_crossfade_player: AudioStreamPlayer = null

# SFX 播放器池
var sfx_players: Array = []
const SFX_POOL_SIZE: int = 4

# 淡入淡出
var fade_tween: Tween = null
var fade_duration: float = 1.0

# 音频文件路径配置（将 "res://audio/" 替换为实际音频文件夹路径）
const BGM_BASE_PATH = "res://audio/bgm/"
const SFX_BASE_PATH = "res://audio/sfx/"

# BGM 文件映射
const BGM_FILES: Dictionary = {
	"title": "title_theme.ogg",
	"explore": "explore_theme.ogg",
	"battle": "battle_theme.ogg",
	"boss": "boss_theme.ogg",
	"victory": "victory_theme.ogg",
	"inn": "inn_theme.ogg",
	"shop": "shop_theme.ogg",
	"chapter_intro": "chapter_intro_theme.ogg",
	"game_over": "game_over_theme.ogg"
}

# SFX 文件映射
const SFX_FILES: Dictionary = {
	"attack": "sword_slash.ogg",
	"crit": "crit_hit.ogg",
	"skill": "skill_cast.ogg",
	"hit": "enemy_hit.ogg",
	"death": "player_death.ogg",
	"levelup": "level_up.ogg",
	"purchase": "purchase.ogg",
	"flee": "flee.ogg",
	"quest_complete": "quest_complete.ogg",
	"door": "door_open.ogg",
	"footstep": "footstep.ogg",
	"coin": "coin.ogg",
	"potion": "potion.ogg",
	"equip": "equip.ogg",
	"heal": "heal.ogg",
	"shield": "shield.ogg",
	"buff": "buff.ogg",
	"debuff": "debuff.ogg",
	"enemy_death": "enemy_death.ogg",
	"boss_intro": "boss_intro.ogg",
	"skill_ice": "skill_ice.ogg",
	"skill_fire": "skill_fire.ogg",
	"skill_lightning": "skill_lightning.ogg",
	"skill_poison": "skill_poison.ogg",
	"trap_trigger": "trap_trigger.ogg",
	"summon": "summon.ogg",
	"boss_victory": "boss_victory.ogg",
	"floor_transition": "floor_transition.ogg",
	"enhance_success": "enhance_success.ogg",
	"enhance_fail": "enhance_fail.ogg",
	"menu_select": "menu_select.ogg",
	"menu_confirm": "menu_confirm.ogg",
	"menu_cancel": "menu_cancel.ogg",
	"enemy_attack": "enemy_attack.ogg",
	"player_hurt": "player_hurt.ogg",
	"victory": "victory.ogg"
}

# 是否使用占位音频（无音频文件时使用）
var use_fallback_audio: bool = true

func _ready():
	_setup_audio_players()
	update_volume()

# 初始化音频播放器
func _setup_audio_players():
	# 创建 BGM 播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# 创建 BGM 交叉淡入播放器
	bgm_crossfade_player = AudioStreamPlayer.new()
	bgm_crossfade_player.name = "BGMCrossfadePlayer"
	bgm_crossfade_player.volume_db = linear_to_db(0)  # 初始为0，用于淡入
	bgm_crossfade_player.bus = "Master"
	add_child(bgm_crossfade_player)
	
	# 创建 SFX 播放器池
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

# 播放 BGM
func play_bgm(name: String, fade_in: float = 0.5):
	if current_bgm == name and bgm_playing:
		return
	
	# 停止当前 BGM
	if bgm_playing and bgm_player.get_stream():
		_fade_out_bgm(fade_in)
	
	current_bgm = name
	bgm_playing = true
	
	# 尝试加载音频文件
	var stream = _load_audio_stream(BGM_BASE_PATH + BGM_FILES.get(name, ""))
	
	if stream:
		# 有音频文件，正常播放
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(0)  # 从0开始淡入
		bgm_player.play()
		
		# 淡入音量
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume * master_volume), fade_in)
		print("[BGM] Playing: %s" % name)
	else:
		# 无音频文件，使用占位符
		print("[BGM] No audio file for: %s, using fallback" % name)
		bgm_playing = false

# 停止 BGM
func stop_bgm(fade_out: float = 0.5):
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	if fade_out > 0 and bgm_player.get_stream():
		_fade_out_bgm(fade_out)
	else:
		bgm_player.stop()
		bgm_crossfade_player.stop()
		bgm_playing = false
		current_bgm = ""

# 淡出当前 BGM
func _fade_out_bgm(duration: float):
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(bgm_player, "volume_db", linear_to_db(0), duration)
	fade_tween.tween_callback Callable(self, "_on_bgm_fade_out_complete")

func _on_bgm_fade_out_complete():
	bgm_player.stop()
	bgm_playing = false

# 播放 SFX
func play_sfx(name: String, volume_mod: float = 1.0):
	# 找到空闲的 SFX 播放器
	var player = _get_free_sfx_player()
	if not player:
		# 如果没有空闲的，使用第一个（可能中断正在播放的音效）
		player = sfx_players[0]
	
	# 尝试加载音频文件
	var stream = _load_audio_stream(SFX_BASE_PATH + SFX_FILES.get(name, ""))
	
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume * volume_mod)
		player.play()
		# print("[SFX] Playing: %s" % name)
	else:
		# 无音频文件时显示简短日志（避免控制台刷屏）
		if use_fallback_audio:
			_play_fallback_sfx(name, player, volume_mod)

# 获取空闲的 SFX 播放器
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.is_playing():
			return player
	return null

# 加载音频流
func _load_audio_stream(path: String) -> AudioStream:
	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		f.close()
		return load(path)
	return null

# 占位符 SFX（无音频文件时播放简单音效）
func _play_fallback_sfx(name: String, player: AudioStreamPlayer, volume_mod: float):
	# 使用简单的方波/正弦波作为占位符
	# 这里只是标记，实际项目中会使用真实音频文件
	print("[SFX] (fallback) %s" % name)

# 设置主音量
func set_master_volume(vol: float):
	master_volume = clamp(vol, 0.0, 1.0)
	update_volume()

# 设置 BGM 音量
func set_bgm_volume(vol: float):
	bgm_volume = clamp(vol, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

# 设置 SFX 音量
func set_sfx_volume(vol: float):
	sfx_volume = clamp(vol, 0.0, 1.0)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# 更新所有音量
func update_volume():
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	if bgm_crossfade_player:
		bgm_crossfade_player.volume_db = linear_to_db(bgm_volume * master_volume)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# 静音切换
var is_muted: bool = false
func toggle_mute():
	is_muted = not is_muted
	if is_muted:
		set_master_volume(0.0)
	else:
		set_master_volume(1.0)

# 播放脚步声（带节流）
var last_footstep_time: float = 0
var footstep_interval: float = 0.3  # 秒

func play_footstep():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_footstep_time >= footstep_interval:
		last_footstep_time = now
		play_sfx("footstep", 0.5)  # 脚步声音量稍低

# 播放背景音乐（带延迟开始）
func play_bgm_delayed(name: String, delay: float = 0.5):
	await get_tree().create_timer(delay).timeout
	play_bgm(name)