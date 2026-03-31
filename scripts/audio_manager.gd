extends Node

# 音频管理器 - 完整的程序化音频系统
# 使用AudioStreamGenerator实现BGM + 音效

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var bgm_volume: float = 0.35
var sfx_volume: float = 0.65

# 当前BGM状态
var current_bgm: String = ""
var bgm_playing: bool = false

# 音频生成器状态
var bgm_generator: Node
var bgm_samples: PackedFloat32Array = PackedFloat32Array()
var bgm_sample_rate: int = 22050
var bgm_buffer_secs: float = 2.0
var bgm_buffer: PackedFloat32Array = PackedFloat32Array()
var bgm_buffer_pos: int = 0
var bgm_loop_count: int = 0
var bgm_max_loops: int = 0  # 0=无限循环

# SFX生成
var sfx_sample_rate: int = 22050

# 音符频率表 (C4-C6)
const NOTE_FREQ = {
	"C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.0, "A3": 220.0, "B3": 246.94,
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.0, "A4": 440.0, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.0, "B5": 987.77,
	"C6": 1046.5, "D6": 1174.66, "E6": 1318.51, "F6": 1396.91, "G6": 1567.98, "A6": 1760.0, "B6": 1975.53,
}

func _ready():
	_setup_audio_players()
	print("AudioManager: 音频系统初始化完成")

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
	
	# BGM生成器节点
	bgm_generator = Node.new()
	bgm_generator.name = "BGMGenerator"
	bgm_generator.set_process(false)
	add_child(bgm_generator)

# ==================== BGM 系统 ====================

func play_bgm(bgm_name: String, max_loops: int = 0):
	"""播放背景音乐"""
	if current_bgm == bgm_name and bgm_playing:
		return
	
	_stop_bgm_immediate()
	current_bgm = bgm_name
	bgm_playing = true
	bgm_max_loops = max_loops
	bgm_loop_count = 0
	
	# 根据场景选择BGM
	bgm_samples = _generate_bgm_samples(bgm_name)
	if bgm_samples.is_empty():
		return
	
	# 构建循环缓冲区
	bgm_buffer = PackedFloat32Array()
	var total_samples = bgm_samples.size()
	bgm_buffer_secs = float(total_samples) / float(bgm_sample_rate)
	
	# 预生成几个循环的buffer用于播放
	for _i in range(4):
		for s in bgm_samples:
			bgm_buffer.append(s)
	
	bgm_buffer_pos = 0
	
	# 创建AudioStreamGenerator
	var stream = AudioStreamGenerator.new()
	stream.mixin_rate = bgm_sample_rate
	stream.mixin_buffer_size = 1024
	
	bgm_player.stream = stream
	bgm_player.volume_db = linear_to_db(bgm_volume * 0.4)
	bgm_player.play()
	
	# 启动生成循环
	bgm_generator.set_process(true)

func _stop_bgm_immediate():
	bgm_playing = false
	bgm_generator.set_process(false)
	bgm_buffer.clear()
	bgm_sample_rate = 22050
	bgm_buffer = PackedFloat32Array()
	bgm_buffer_pos = 0
	if bgm_player:
		bgm_player.stop()

func stop_bgm(fade_time: float = 1.0):
	"""停止背景音乐（淡出）"""
	if not bgm_playing:
		return
	# 简单淡出
	var tween = create_tween()
	tween.tween_method(_set_bgm_volume_fade.bind(bgm_volume), bgm_volume, 0.0, fade_time)
	await tween.finished
	_stop_bgm_immediate()
	bgm_player.volume_db = linear_to_db(bgm_volume * 0.4)

func _set_bgm_volume_fade(vol: float):
	bgm_volume = vol
	if bgm_player:
		bgm_player.volume_db = linear_to_db(vol * 0.4)

func _process(delta):
	if not bgm_playing or not bgm_player.playing:
		return
	
	var playback = bgm_player.get_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	
	# 填充buffer直到可写空间足够
	while playback.get_frames_available() > 0:
		var frames_to_push = playback.get_frames_available()
		var buffer = PackedFloat32Array()
		
		for _f in range(frames_to_push):
			var sample = 0.0
			if bgm_buffer_pos < bgm_buffer.size():
				sample = bgm_buffer[bgm_buffer_pos]
				bgm_buffer_pos += 1
			else:
				# 循环
				bgm_buffer_pos = 0
				bgm_loop_count += 1
				if bgm_max_loops > 0 and bgm_loop_count >= bgm_max_loops:
					_stop_bgm_immediate()
					return
				if bgm_buffer.size() > 0:
					sample = bgm_buffer[0]
					bgm_buffer_pos = 1
			buffer.append(sample * 0.5)  # 防止削波
		
		playback.push_buffer(buffer)

func _generate_bgm_samples(bgm_name: String) -> PackedFloat32Array:
	"""根据名称生成程序化BGM样本"""
	bgm_sample_rate = 22050
	match bgm_name:
		"explore":   return _create_explore_theme()
		"battle":    return _create_battle_theme()
		"boss":      return _create_boss_theme()
		"victory":   return _create_victory_theme()
		"shop":      return _create_shop_theme()
		"title":     return _create_title_theme()
	return PackedFloat32Array()

# ==================== BGM 主题生成 ====================

func _create_explore_theme() -> PackedFloat32Array:
	"""地牢探索BGM - 低沉神秘的环境音 + 简单旋律"""
	var samples = PackedFloat32Array()
	var bpm = 80
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	
	# 4小节，每小节4拍
	var measures = 4
	var notes = [
		["C3", "E3", "G3", "E3"],   # Am
		["C3", "F3", "A3", "F3"],   # F
		["C3", "G3", "B3", "G3"],   # G
		["A3", "E3", "G3", "E3"],   # Am
	]
	
	for m in range(measures):
		var chord_notes = notes[m % notes.size()]
		for beat in range(4):
			var note_idx = beat % chord_notes.size()
			var freq = NOTE_FREQ.get(chord_notes[note_idx], 220.0)
			var note_samples = _generate_pad_note(freq, beat_samples * 0.9, 0.3)
			for s in note_samples:
				samples.append(s)
			# 添加一点高音点缀
			if beat == 1 or beat == 3:
				var melody_freq = freq * 2.0
				var melody_samples = _generate_melody_note(melody_freq, int(beat_samples * 0.3), 0.15)
				for s in melody_samples:
					samples.append(s * 0.4)
	return samples

func _create_battle_theme() -> PackedFloat32Array:
	"""战斗BGM - 紧张的鼓点 + 战斗旋律"""
	var samples = PackedFloat32Array()
	var bpm = 140
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	var half_beat = int(beat_samples / 2)
	
	# 8小节战斗主题
	var measures = 8
	var melody = [
		"E4", "G4", "A4", "G4", "E4", "D4", "C4", "D4",
		"E4", "G4", "A4", "B4", "C5", "B4", "A4", "G4",
	]
	
	for m in range(measures):
		# 鼓点 - 每拍
		for beat in range(4):
			# 底鼓
			var kick_samples = _generate_kick(beat_samples / 2)
			for s in kick_samples:
				samples.append(s)
			# 军鼓
			if beat == 1 or beat == 3:
				var snare_samples = _generate_snare(half_beat)
				for s in snare_samples:
					samples.append(s)
			# 踩镲
			var hihat_samples = _generate_hihat(int(half_beat), 0.2)
			for s in hihat_samples:
				samples.append(s)
		
		# 旋律
		for note_idx in range(4):
			var note_str = melody[(m * 4 + note_idx) % melody.size()]
			var freq = NOTE_FREQ.get(note_str, 330.0)
			var note_samples = _generate_square_note(freq, int(beat_samples * 0.8), 0.2)
			for s in note_samples:
				samples.append(s * 0.35)
	
	return samples

func _create_boss_theme() -> PackedFloat32Array:
	"""Boss战BGM - 压迫感强的低频 + 紧张旋律"""
	var samples = PackedFloat32Array()
	var bpm = 100
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	
	var measures = 8
	var bass_line = ["C3", "C3", "G3", "A3", "C3", "C3", "G3", "B3"]
	var melody = ["E4", "E4", "D4", "C4", "E4", "E4", "D4", "B3"]
	
	for m in range(measures):
		# 低音bass - 每拍
		var bass_freq = NOTE_FREQ.get(bass_line[m % bass_line.size()], 65.41)
		for beat in range(4):
			var bass_s = _generate_saw_note(bass_freq, beat_samples * 0.8, 0.4)
			for s in bass_s:
				samples.append(s * 0.5)
		
		# 旋律
		var melody_freq = NOTE_FREQ.get(melody[m % melody.size()], 329.63)
		var melody_s = _generate_lead_note(melody_freq, beat_samples * 3, 0.35)
		for s in melody_s:
			samples.append(s * 0.4)
		
		# 紧张感 - 低频嗡鸣
		var drone_s = _generate_drone(65.41, beat_samples)
		for s in drone_s:
			samples.append(s * 0.15)
	
	return samples

func _create_victory_theme() -> PackedFloat32Array:
	"""胜利BGM - 明亮振奋的号角"""
	var samples = PackedFloat32Array()
	var bpm = 120
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	
	# 胜利旋律: C5-E5-G5-C6 (上行分解和弦)
	var fanfare_notes = [
		("C5", 1.0), ("E5", 1.0), ("G5", 1.0), ("C6", 2.0),
		("G5", 1.0), ("C6", 1.0), ("E6", 1.0), ("G6", 2.0),
	]
	
	for note_str in fanfare_notes:
		var freq = NOTE_FREQ.get(note_str[0], 523.25)
		var duration_mult = note_str[1]
		var note_s = _generate_fanfare_note(freq, int(beat_samples * duration_mult), 0.4)
		for s in note_s:
			samples.append(s * 0.6)
		# 短暂停顿
		for _i in range(int(beat_samples * 0.1)):
			samples.append(0.0)
	
	# 和弦伴奏
	var chords = [
		["C4", "E4", "G4"],
		["G4", "B4", "D5"],
	]
	for chord_idx in range(2):
		for _repeat in range(2):
			for beat in range(4):
				for note_str in chords[chord_idx]:
					var freq = NOTE_FREQ.get(note_str, 261.63)
					var chord_s = _generate_pad_note(freq, beat_samples, 0.25)
					for s in chord_s:
						samples.append(s * 0.2)
	
	return samples

func _create_shop_theme() -> PackedFloat32Array:
	"""商店BGM - 轻松愉快的旋律"""
	var samples = PackedFloat32Array()
	var bpm = 100
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	
	# 简单愉快的旋律
	var melody = [
		"C4", "D4", "E4", "G4", "E4", "C4", "D4", "E4",
		"F4", "G4", "A4", "G4", "E4", "D4", "C4", "E4",
	]
	
	var measures = 4
	for m in range(measures):
		for note_idx in range(4):
			var note_str = melody[(m * 4 + note_idx) % melody.size()]
			var freq = NOTE_FREQ.get(note_str, 261.63)
			# 八分音符
			var note_s = _generate_bell_note(freq, int(beat_samples * 0.45), 0.3)
			for s in note_s:
				samples.append(s * 0.4)
			# 短暂停顿
			for _i in range(int(beat_samples * 0.05)):
				samples.append(0.0)
	
	return samples

func _create_title_theme() -> PackedFloat32Array:
	"""标题画面BGM - 庄重神秘的开场"""
	var samples = PackedFloat32Array()
	var bpm = 60
	var beat_samples = int(float(bgm_sample_rate) * 60.0 / bpm)
	
	# 缓慢的开场和弦
	var chords = [
		["C3", "E3", "G3", "C4"],
		["A3", "C4", "E4", "G4"],
		["F3", "A3", "C4", "E4"],
		["G3", "B3", "D4", "G4"],
	]
	
	var measures = 4
	for m in range(measures):
		var chord = chords[m % chords.size()]
		# 每个和弦持续2拍
		for sample_idx in range(beat_samples * 2):
			var sample = 0.0
			for note_str in chord:
				var freq = NOTE_FREQ.get(note_str, 130.81)
				sample += sin(2.0 * PI * freq * float(sample_idx) / float(bgm_sample_rate))
			sample /= chord.size()
			# 淡入淡出
			var envelope = 1.0
			if sample_idx < beat_samples * 0.2:
				envelope = float(sample_idx) / (beat_samples * 0.2)
			elif sample_idx > beat_samples * 1.8:
				envelope = float(beat_samples * 2 - sample_idx) / (beat_samples * 0.2)
			samples.append(sample * envelope * 0.3)
		# 停顿1拍
		for _i in range(beat_samples):
			samples.append(0.0)
	
	return samples

# ==================== 音频合成工具 ====================

func _generate_sine_wave(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.05, 0.1, 0.7, 0.2)
		var s = sin(2.0 * PI * freq * t) * env
		samples.append(s * amplitude)
	return samples

func _generate_square_wave(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.02, 0.1, 0.6, 0.3)
		var s = sign(sin(2.0 * PI * freq * t))
		samples.append(s * env * amplitude * 0.3)
	return samples

func _generate_saw_wave(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.02, 0.15, 0.5, 0.35)
		var phase = fmod(freq * t, 1.0)
		var s = 2.0 * phase - 1.0
		samples.append(s * env * amplitude * 0.3)
	return samples

func _adsr(t: float, a: float, d: float, s: float, r: float) -> float:
	if t < a:
		return t / a
	elif t < a + d:
		return 1.0 - (1.0 - s) * (t - a) / d
	elif t < 1.0 - r:
		return s
	else:
		return s * (1.0 - (t - (1.0 - r)) / r)

func _generate_pad_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""柔和的铺底音色 - 多个谐波"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.3, 0.3, 0.7, 0.2)
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 1.0
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.3
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.1
		s /= 1.4
		samples.append(s * env * amplitude)
	return samples

func _generate_melody_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""清脆的旋律音色"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.05, 0.2, 0.5, 0.3)
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 0.6
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.25
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.1
		s += sin(2.0 * PI * freq * 4.0 * t) * 0.05
		samples.append(s * env * amplitude)
	return samples

func _generate_lead_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""主旋律音色"""
	return _generate_melody_note(freq, num_samples, amplitude)

func _generate_square_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""方波音色 - 复古游戏风格"""
	return _generate_square_wave(freq, num_samples, amplitude)

func _generate_saw_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""锯齿波音色 - 低音"""
	return _generate_saw_wave(freq, num_samples, amplitude)

func _generate_bell_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""钟声音色 - 清脆悦耳"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.01, 0.1, 0.6, 0.3)
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 0.5
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.25
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.15
		s += sin(2.0 * PI * freq * 4.3 * t) * 0.1  # 非谐波产生金属感
		samples.append(s * env * amplitude)
	return samples

func _generate_fanfare_note(freq: float, num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""号角音色 - 明亮有力"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = _adsr(float(i) / float(num_samples), 0.08, 0.15, 0.8, 0.15)
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 0.4
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.3
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.2
		s += sin(2.0 * PI * freq * 4.0 * t) * 0.1
		samples.append(s * env * amplitude)
	return samples

func _generate_drone(freq: float, num_samples: int) -> PackedFloat32Array:
	"""持续低音 - 营造氛围"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = 0.8 + 0.2 * sin(2.0 * PI * 0.5 * t)  # 轻微颤动
		var s = sin(2.0 * PI * freq * t) * 0.5
		s += sin(2.0 * PI * freq * 0.5 * t) * 0.3
		samples.append(s * env * 0.15)
	return samples

# ==================== 鼓点合成 ====================

func _generate_kick(num_samples: int) -> PackedFloat32Array:
	"""底鼓 - 低频冲击"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var freq = 150.0 * exp(-t * 30.0) + 50.0  # 频率下降
		var env = exp(-t * 20.0)
		var s = sin(2.0 * PI * freq * t)
		samples.append(s * env * 0.8)
	return samples

func _generate_snare(num_samples: int) -> PackedFloat32Array:
	"""军鼓 - 噪声+音调混合"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = exp(-t * 15.0)
		var tone = sin(2.0 * PI * 200.0 * t) * 0.4
		var noise = (randf() * 2.0 - 1.0) * 0.6
		samples.append((tone + noise) * env * 0.6)
	return samples

func _generate_hihat(num_samples: int, amplitude: float) -> PackedFloat32Array:
	"""踩镲 - 高频噪声"""
	var samples = PackedFloat32Array()
	for i in num_samples:
		var t = float(i) / float(bgm_sample_rate)
		var env = exp(-t * 40.0)
		var noise = randf() * 2.0 - 1.0
		# 高通滤波效果
		var hpf = sin(2.0 * PI * 7000.0 * t)
		samples.append((noise * 0.7 + hpf * 0.3) * env * amplitude)
	return samples

# ==================== SFX 系统 ====================

func play_sfx(sfx_name: String):
	"""播放音效"""
	var sfx_data = _generate_sfx(sfx_name)
	if sfx_data.is_empty():
		return
	
	# 创建临时SFX播放器
	var sfx_stream = AudioStreamGenerator.new()
	sfx_stream.mixin_rate = sfx_sample_rate
	sfx_stream.mixin_buffer_size = 512
	
	var temp_player = AudioStreamPlayer.new()
	temp_player.name = "SFXTemp_" + sfx_name
	temp_player.stream = sfx_stream
	temp_player.volume_db = linear_to_db(sfx_volume * 0.5)
	temp_player.bus = "Master"
	add_child(temp_player)
	
	# 播放SFX
	temp_player.play()
	
	# 填充buffer
	var playback = temp_player.get_playback() as AudioStreamGeneratorPlayback
	if playback:
		var full_buffer = PackedFloat32Array()
		# 生成足够的数据
		var total_needed = sfx_sample_rate * 2  # 最多2秒
		var generated = 0
		var sfx_idx = 0
		while generated < total_needed and sfx_idx < sfx_data.size():
			var frames = playback.get_frames_available()
			if frames == 0:
				break
			var buf = PackedFloat32Array()
			for _f in range(min(frames, sfx_data.size() - sfx_idx)):
				buf.append(sfx_data[sfx_idx] * 0.5)
				sfx_idx += 1
				generated += 1
			if buf.size() > 0:
				playback.push_buffer(buf)
	
	# 自动清理
	await get_tree().create_timer(3.0).timeout
	if temp_player:
		temp_player.queue_free()

func _generate_sfx(sfx_name: String) -> PackedFloat32Array:
	"""生成音效数据"""
	match sfx_name:
		"attack":   return _sfx_attack()
		"hit":      return _sfx_hit()
		"skill":    return _sfx_skill()
		"victory":  return _sfx_victory()
		"levelup":  return _sfx_levelup()
		"coins":    return _sfx_coins()
		"heal":     return _sfx_heal()
		"shield":   return _sfx_shield()
		"poison":   return _sfx_poison()
		"crit":     return _sfx_crit()
		"flee":     return _sfx_flee()
		"death":    return _sfx_death()
		"stairs":   return _sfx_stairs()
		"purchase": return _sfx_purchase()
		"error":    return _sfx_error()
		"enemy_hit": return _sfx_enemy_hit()
		"stun":     return _sfx_stun()
		"buff":     return _sfx_buff()
	return PackedFloat32Array()

func _sfx_attack() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var duration = 0.12
	var n = int(duration * float(sfx_sample_rate))
	for i in n:
		var t = float(i) / float(sfx_sample_rate)
		var env = exp(-t * 25.0)
		var freq_sweep = 800.0 - 600.0 * (t / duration)
		var s = sin(2.0 * PI * freq_sweep * t) * 0.5 + (randf() * 2.0 - 1.0) * 0.5
		samples.append(s * env * 0.5)
	return samples

func _sfx_enemy_hit() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var duration = 0.15
	var n = int(duration * float(sfx_sample_rate))
	for i in n:
		var t = float(i) / float(sfx_sample_rate)
		var env = exp(-t * 20.0)
		var noise = randf() * 2.0 - 1.0
		var s = noise * 0.7 + sin(2.0 * PI * 200.0 * t) * 0.3
		samples.append(s * env * 0.5)
	return samples

func _sfx_hit() -> PackedFloat32Array:
	return _sfx_enemy_hit()

func _sfx_skill() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var duration = 0.3
	var n = int(duration * float(sfx_sample_rate))
	for i in n:
		var t = float(i) / float(sfx_sample_rate)
		var env = sin(PI * t / duration) * exp(-t * 4.0)
		var freq = 400.0 + 800.0 * (t / duration)
		var s = sin(2.0 * PI * freq * t) + sin(2.0 * PI * freq * 1.5 * t) * 0.3
		samples.append(s * env * 0.4)
	return samples

func _sfx_victory() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var notes = [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
	var note_dur = 0.2
	for note in notes:
		var n = int(note_dur * float(sfx_sample_rate))
		for i in n:
			var t = float(i) / float(sfx_sample_rate)
			var env = exp(-t * 5.0)
			var s = sin(2.0 * PI * note * t) * 0.5 + sin(2.0 * PI * note * 2.0 * t) * 0.3
			samples.append(s * env * 0.5)
		for _j in range(int(0.05 * float(sfx_sample_rate))):
			samples.append(0.0)
	return samples

func _sfx_levelup() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var notes = [880.0, 1108.0, 1318.5, 1760.0]  # A5 C#6 E6 A6
	var note_dur = 0.15
	for note in notes:
		var n = int(note_dur * float(sfx_sample_rate))
		for i in n:
			var t = float(i) / float(sfx_sample_rate)
			var env = exp(-t * 6.0)
			var s = sin(2.0 * PI * note * t) + sin(2.0 * PI * note * 2.0 * t) * 0.5
			samples.append(s * env * 0.4)
	return samples

func _sfx_coins() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var notes = [1200.0, 1400.0, 1600.0]
	for note in notes:
		var n = int(0.08 * float(sfx_sample_rate))
		for i in n:
			var t = float(i) / float(sfx_sample_rate)
			var env = exp(-t * 30.0)
			var s = sin(2.0 * PI * note * t)
			samples.append(s * env * 0.3)
	return samples

func _sfx_heal() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var duration = 0.4
	var n = int(duration * float(sfx_sample_rate))
	for i in n:
		var t = float(i) / float(sfx_sample_rate)
		var env = sin(PI * t / duration) * exp(-t * 3.0)
		var freq = 600.0 + 300.0 * sin(2.0 * PI * 5.0 * t)
		var s = sin(2.0 * PI * freq * t)
		samples.append(s * env * 0.35)
	return samples

func _sfx_shield() -> PackedFloat32Array:
	var samples = PackedFloat32Array()
	var duration = 0.25
	var n = int(duration * float(sfx_sample_rate))
	for i in n:
		var t = float(i) / float(sfx_sample_rate)
		var env = exp(-t * 8.0)
		var s = sin(2.0 * PI * 800.0 * t) * 0.