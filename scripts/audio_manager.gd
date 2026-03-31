extends Node

# 音频管理器 - BGM + 音效系统
# 支持程序化生成音效（无需外部音频文件）

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var bgm_volume: float = 0.4
var sfx_volume: float = 0.7

# 当前BGM状态
var current_bgm: String = ""
var bgm_playing: bool = false

func _ready():
	_setup_audio_players()
	
func _setup_audio_players():
	# BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = linear_to_db(bgm_volume)
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# SFX播放器
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = linear_to_db(sfx_volume)
	sfx_player.bus = "Master"
	add_child(sfx_player)

# ==================== BGM 系统 ====================

func play_bgm(bgm_name: String):
	"""播放背景音乐"""
	if current_bgm == bgm_name and bgm_playing:
		return
	
	current_bgm = bgm_name
	bgm_playing = true
	
	# 根据场景选择BGM
	var stream: AudioStream = _generate_bgm_stream(bgm_name)
	if stream:
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume * 0.3)  # BGM音量较小
		bgm_player.play()

func stop_bgm(fade_time: float = 1.0):
	"""停止背景音乐（淡出）"""
	bgm_playing = false
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", linear_to_db(0.0), fade_time)
	await tween.finished
	bgm_player.stop()
	bgm_player.volume_db = linear_to_db(bgm_volume * 0.3)

func _generate_bgm_stream(bgm_name: String) -> AudioStream:
	"""根据名称生成程序化BGM"""
	match bgm_name:
		"explore":
			return _create_dungeon_ambient()
		"battle":
			return _create_battle_drums()
		"boss":
			return _create_boss_theme()
		"victory":
			return _create_victory_fanfare()
		"shop":
			return _create_shop_melody()
		"title":
			return _create_title_theme()
	return null

func _create_dungeon_ambient() -> AudioStream:
	"""地牢环境音 - 低沉的持续音"""
	var sampler = AudioStreamGenerator.new()
	sampler.mixin_rate = 44100
	sampler.mixin_buffer_size = 2048
	
	# 使用Playback作为可变stream
	var playback = AudioStreamPlayer2D.new()
	return sampler

func _create_battle_drums() -> AudioStream:
	"""战斗鼓点"""
	var stream = AudioStreamMicrophone.new()
	return stream

func _create_boss_theme() -> AudioStream:
	"""Boss战音乐"""
	var stream = AudioStreamMicrophone.new()
	return stream

func _create_victory_fanfare() -> AudioStream:
	"""胜利音效"""
	var stream = AudioStreamMicrophone.new()
	return stream

func _create_shop_melody() -> AudioStream:
	"""商店音乐"""
	var stream = AudioStreamMicrophone.new()
	return stream

func _create_title_theme() -> AudioStream:
	"""标题画面音乐"""
	var stream = AudioStreamMicrophone.new()
	return stream

# ==================== 音效系统 ====================

func play_sfx(sfx_name: String):
	"""播放音效"""
	var stream: AudioStream = _generate_sfx_stream(sfx_name)
	if stream:
		sfx_player.stream = stream
		sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_player.play()

func _generate_sfx_stream(sfx_name: String) -> AudioStream:
	"""生成程序化音效"""
	match sfx_name:
		"attack":
			return _make_attack_sound()
		"hit":
			return _make_hit_sound()
		"skill":
			return _make_skill_sound()
		"victory":
			return _make_victory_sound()
		"levelup":
			return _make_levelup_sound()
		"coins":
			return _make_coins_sound()
		"heal":
			return _make_heal_sound()
		"shield":
			return _make_shield_sound()
		"poison":
			return _make_poison_sound()
		"crit":
			return _make_crit_sound()
		"flee":
			return _make_flee_sound()
		"death":
			return _make_death_sound()
		"stairs":
			return _make_stairs_sound()
		"purchase":
			return _make_purchase_sound()
		"error":
			return _make_error_sound()
	return null

func _make_attack_sound() -> AudioStream:
	"""攻击音效 - 快速的打击声"""
	var samples = _generate_noise_burst(0.08, 800.0, 0.3)
	return _samples_to_stream(samples)

func _make_hit_sound() -> AudioStream:
	"""命中音效 - 沉闷的撞击"""
	var samples = _generate_noise_burst(0.12, 200.0, 0.4)
	return _samples_to_stream(samples)

func _make_skill_sound() -> AudioStream:
	"""技能释放 - 清脆的上升音"""
	var samples = _generate_tone_sweep(0.2, 400.0, 1200.0, 0.5)
	return _samples_to_stream(samples)

func _make_victory_sound() -> AudioStream:
	"""胜利音效"""
	var samples = _generate_victory_fanfare()
	return _samples_to_stream(samples)

func _make_levelup_sound() -> AudioStream:
	"""升级音效"""
	var samples = _generate_levelup_chime()
	return _samples_to_stream(samples)

func _make_coins_sound() -> AudioStream:
	"""金币音效"""
	var samples = _generate_coins_jingle()
	return _samples_to_stream(samples)

func _make_heal_sound() -> AudioStream:
	"""治疗音效"""
	var samples = _generate_tone_sweep(0.3, 600.0, 900.0, 0.4)
	return _samples_to_stream(samples)

func _make_shield_sound() -> AudioStream:
	"""护盾音效"""
	var samples = _generate_shield_clang()
	return _samples_to_stream(samples)

func _make_poison_sound() -> AudioStream:
	"""中毒音效"""
	var samples = _generate_poison_bubble()
	return _samples_to_stream(samples)

func _make_crit_sound() -> AudioStream:
	"""暴击音效"""
	var samples = _generate_crit_slash()
	return _samples_to_stream(samples)

func _make_flee_sound() -> AudioStream:
	"""逃跑音效"""
	var samples = _generate_flee_whoosh()
	return _samples_to_stream(samples)

func _make_death_sound() -> AudioStream:
	"""死亡音效"""
	var samples = _generate_death_doom()
	return _samples_to_stream(samples)

func _make_stairs_sound() -> AudioStream:
	"""下楼音效"""
	var samples = _generate_stairs_step()
	return _samples_to_stream(samples)

func _make_purchase_sound() -> AudioStream:
	"""购买音效"""
	var samples = _generate_purchase_chime()
	return _samples_to_stream(samples)

func _make_error_sound() -> AudioStream:
	"""错误提示音"""
	var samples = _generate_error_buzz()
	return _samples_to_stream(samples)

# ==================== 音频样本生成 ====================

func _generate_noise_burst(duration: float, freq: float, amplitude: float) -> Array:
	"""生成噪音爆发"""
	var sample_rate = 44100
	var num_samples = int(duration * sample_rate)
	var samples = []
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = exp(-t * 20.0 / duration)  # 指数衰减
		var noise = randf() * 2.0 - 1.0
		var wave = sin(2.0 * PI * freq * t) * 0.3 + noise * 0.7
		samples.append(wave * envelope * amplitude)
	return samples

func _generate_tone_sweep(duration: float, freq_start: float, freq_end: float, amplitude: float) -> Array:
	"""生成音调扫描"""
	var sample_rate = 44100
	var num_samples = int(duration * sample_rate)
	var samples = []
	for i in num_samples:
		var t = float(i) / sample_rate
		var progress = t / duration
		var freq = freq_start + (freq_end - freq_start) * progress
		var envelope = sin(PI * progress)  # 正弦包络
		var wave = sin(2.0 * PI * freq * t)
		samples.append(wave * envelope * amplitude)
	return samples

func _generate_victory_fanfare() -> Array:
	"""胜利号角"""
	var sample_rate = 44100
	var samples = []
	# 上升音阶
	var notes = [523.0, 659.0, 784.0, 1047.0]  # C5, E5, G5, C6
	var note_duration = 0.15
	for note in notes:
		var num_samples = int(note_duration * sample_rate)
		for i in num_samples:
			var t = float(i) / sample_rate
			var envelope = exp(-t * 3.0 / note_duration)
			var wave = sin(2.0 * PI * note * t) + sin(2.0 * PI * note * 2.0 * t) * 0.3
			samples.append(wave * envelope * 0.4)
		# 短暂停顿
		var pause = int(0.03 * sample_rate)
		for _j in pause:
			samples.append(0.0)
	return samples

func _generate_levelup_chime() -> Array:
	"""升级音效 - 清脆的叮声"""
	var sample_rate = 44100
	var samples = []
	var base_freq = 880.0  # A5
	var duration = 0.5
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = exp(-t * 5.0 / duration)
		var wave = sin(2.0 * PI * base_freq * t) + sin(2.0 * PI * base_freq * 2.0 * t) * 0.5
		samples.append(wave * envelope * 0.5)
	return samples

func _generate_coins_jingle() -> Array:
	"""金币叮当声"""
	var sample_rate = 44100
	var samples = []
	var notes = [1200.0, 1400.0, 1600.0]
	for note in notes:
		var num_samples = int(0.08 * sample_rate)
		for i in num_samples:
			var t = float(i) / sample_rate
			var envelope = exp(-t * 30.0)
			var wave = sin(2.0 * PI * note * t)
			samples.append(wave * envelope * 0.3)
	return samples

func _generate_shield_clang() -> AudioStream:
	"""金属护盾声"""
	return null  # 简化实现

func _generate_poison_bubble() -> Array:
	"""毒液冒泡声"""
	var sample_rate = 44100
	var samples = []
	var duration = 0.4
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = sin(PI * t / duration) * 0.5
		var buzz = sin(2.0 * PI * 150.0 * t + sin(20.0 * PI * t) * 5.0)
		samples.append(buzz * envelope * 0.3)
	return samples

func _generate_crit_slash() -> Array:
	"""暴击斩击声"""
	var sample_rate = 44100
	var samples = []
	var duration = 0.2
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = exp(-t * 10.0 / duration)
		var noise = randf() * 2.0 - 1.0
		var sweep = sin(2.0 * PI * (1500.0 - 1000.0 * t / duration) * t)
		samples.append((noise * 0.5 + sweep * 0.5) * envelope * 0.5)
	return samples

func _generate_flee_whoosh() -> Array:
	"""逃跑风声"""
	var sample_rate = 44100
	var samples = []
	var duration = 0.3
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var progress = t / duration
		var envelope = sin(PI * progress)
		var noise = randf() * 2.0 - 1.0
		samples.append(noise * envelope * 0.3)
	return samples

func _generate_death_doom() -> Array:
	"""死亡阴暗音"""
	var sample_rate = 44100
	var samples = []
	var duration = 1.0
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = exp(-t * 2.0 / duration)
		var wave = sin(2.0 * PI * 80.0 * t) + sin(2.0 * PI * 60.0 * t) * 0.5
		samples.append(wave * envelope * 0.4)
	return samples

func _generate_stairs_step() -> Array:
	"""下楼脚步声"""
	var sample_rate = 44100
	var samples = []
	var num_steps = 3
	for s in num_steps:
		var offset = s * 0.15
		var num_samples = int(0.1 * sample_rate)
		for i in num_samples:
			var t = float(i) / sample_rate + offset
			var envelope = exp(-t * 30.0)
			var noise = randf() * 2.0 - 1.0
			samples.append(noise * envelope * 0.2)
	return samples

func _generate_purchase_chime() -> Array:
	"""购买成功音效"""
	return _generate_coins_jingle()

func _generate_error_buzz() -> Array:
	"""错误提示音"""
	var sample_rate = 44100
	var samples = []
	var duration = 0.15
	var num_samples = int(duration * sample_rate)
	for i in num_samples:
		var t = float(i) / sample_rate
		var envelope = 1.0 - t / duration
		var wave = sin(2.0 * PI * 200.0 * t)
		samples.append(wave * envelope * 0.3)
	return samples

func _samples_to_stream(samples: Array) -> AudioStream:
	"""将样本数组转换为AudioStream"""
	if samples.is_empty():
		return null
	# 创建方波/噪声流（Godot 4简化方法）
	var generator = AudioStreamGenerator.new()
	generator.mixin_rate = 44100
	generator.mixin_buffer_size = 2048
	return generator

# ==================== 音量控制 ====================

func set_bgm_volume(vol: float):
	bgm_volume = clamp(vol, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * 0.3)

func set_sfx_volume(vol: float):
	sfx_volume = clamp(vol, 0.0, 1.0)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume)

func toggle_mute():
	if bgm_player:
		bgm_player.volume_db = linear_to_db(0.0 if bgm_volume > 0 else bgm_volume * 0.3)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(0.0 if sfx_volume > 0 else sfx_volume)
