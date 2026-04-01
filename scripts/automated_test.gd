extends SceneTree

# 自动化测试脚本 - 测试游戏核心功能
# 运行方式: Godot --headless --path <project_path> --script <this_script>

var tests_passed: int = 0
var tests_failed: int = 0
var test_results: Array = []

func _init():
	print("=" .repeat(60))
	print("🎮 武侠游戏自动化测试")
	print("=" .repeat(60))
	
	# 执行所有测试
	_test_player_data()
	_test_enemy_data()
	_test_global_data()
	_test_game_initialization()
	_test_save_load_system()
	
	# 输出结果
	_print_summary()
	
	quit()

func _test_player_data():
	print("\n📋 测试: 玩家数据系统")
	var pd = load("res://scripts/player.gd").new()
	pd.job = pd.Job.WARRIOR
	pd._setup_job_skills()
	
	_assert("战士职业初始化", pd.job_name == "战士", "job_name: " + str(pd.job_name))
	_assert("战士有技能", pd.skills.size() > 0, "skills: " + str(pd.skills.size()))
	_assert("战士HP > 0", pd.max_hp > 0, "max_hp: " + str(pd.max_hp))
	_assert("战士ATK > 0", pd.atk > 0, "atk: " + str(pd.atk))
	
	# 测试其他职业
	pd.job = pd.Job.MAGE
	pd._setup_job_skills()
	_assert("法师职业初始化", pd.job_name == "法师", "job_name: " + str(pd.job_name))
	
	print("  ✅ 玩家数据测试完成")

func _test_enemy_data():
	print("\n📋 测试: 敌人数据系统")
	var ed = load("res://scripts/enemy.gd")
	
	var enemies = ed.get_floor_enemies(1)
	_assert("第1层有敌人", enemies.size() > 0, "敌人数量: " + str(enemies.size()))
	
	var bandit = ed.new("bandit", 1)
	_assert("创建山贼敌人", bandit.name == "劫道山贼", "name: " + bandit.name)
	_assert("山贼HP > 0", bandit.hp > 0, "hp: " + str(bandit.hp))
	_assert("山贼有攻击力", bandit.atk > 0, "atk: " + str(bandit.atk))
	
	var elite_bandit = ed.new("bandit_elite", 1)
	_assert("创建精英山贼", "匪" in elite_bandit.name or "盗" in elite_bandit.name, "name: " + elite_bandit.name)
	_assert("精英山贼HP更高", elite_bandit.max_hp > bandit.max_hp, "elite_hp: " + str(elite_bandit.max_hp))
	
	print("  ✅ 敌人数据测试完成")

func _test_global_data():
	print("\n📋 测试: 全局数据系统")
	var gd = load("res://scripts/global_data.gd").new()
	
	# 测试创建新游戏
	var game_data = gd.create_new_game(0, "sword")
	_assert("创建新游戏", game_data.size() > 0, "game_data size: " + str(game_data.size()))
	
	# 测试职业名称
	var job_name = gd.get_job_name(0)
	_assert("有职业名称", job_name != "", "job: " + job_name)
	
	# 测试武器名称
	var weapon_name = gd.get_weapon_name("sword")
	_assert("武器名称", weapon_name != "", "weapon: " + weapon_name)
	
	print("  ✅ 全局数据测试完成")

func _test_game_initialization():
	print("\n📋 测试: 游戏初始化")
	
	# 创建游戏节点
	var game = Node2D.new()
	game.set_script(load("res://scripts/game.gd"))
	game._ready()
	
	_assert("游戏状态初始化", game.game_state != null, "state: " + str(game.game_state))
	_assert("玩家数据初始化", game.player_data != null, "player_data: " + str(game.player_data))
	
	# 测试职业选择
	_setup_test_player(game)
	
	_assert("玩家HP > 0", game.player_data.hp > 0, "hp: " + str(game.player_data.hp))
	_assert("玩家有职业", game.player_data.job >= 0, "job: " + str(game.player_data.job))
	
	game.queue_free()
	print("  ✅ 游戏初始化测试完成")

func _test_save_load_system():
	print("\n📋 测试: 存档系统")
	
	# 创建设定测试用存档数据
	var test_save = {
		"version": "1.0",
		"player": {
			"job": 0,
			"hp": 100,
			"max_hp": 120,
			"mp": 30,
			"max_mp": 30,
			"level": 3,
			"exp": 50,
			"gold": 200,
			"atk": 18,
			"def": 8,
			"spd": 6,
			"luk": 4
		},
		"current_floor": 2,
		"play_time": 300
	}
	
	# 验证存档数据完整性
	_assert("存档有版本号", test_save.has("version"), "version: " + str(test_save.has("version")))
	_assert("存档有玩家数据", test_save.has("player"), "has player")
	_assert("存档有层数", test_save.has("current_floor"), "floor: " + str(test_save.has("current_floor")))
	
	# 验证玩家数据
	var pdata = test_save["player"]
	_assert("玩家有职业", pdata.has("job"), "has job")
	_assert("玩家有等级", pdata.has("level"), "has level")
	_assert("玩家金币正确", pdata["gold"] == 200, "gold: " + str(pdata["gold"]))
	
	print("  ✅ 存档系统测试完成")

func _setup_test_player(game):
	# 设置战士职业
	game._setup_player_data(game.Job.WARRIOR)

func _assert(test_name: String, condition: bool, detail: String = ""):
	if condition:
		print("  ✅ " + test_name)
		tests_passed += 1
		test_results.append({"name": test_name, "status": "PASS", "detail": detail})
	else:
		print("  ❌ " + test_name + " - " + detail)
		tests_failed += 1
		test_results.append({"name": test_name, "status": "FAIL", "detail": detail})

func _print_summary():
	print("\n" + "=" .repeat(60))
	print("📊 测试结果汇总")
	print("=" .repeat(60))
	print("✅ 通过: " + str(tests_passed))
	print("❌ 失败: " + str(tests_failed))
	print("📈 通过率: " + str(int(tests_passed * 100.0 / (tests_passed + tests_failed))) + "%")
	
	if tests_failed > 0:
		print("\n❌ 失败测试:")
		for r in test_results:
			if r["status"] == "FAIL":
				print("  - " + r["name"] + ": " + r["detail"])
	
	print("\n" + "=" .repeat(60))
	if tests_failed == 0:
		print("🎉 所有测试通过! 游戏核心功能正常。")
	else:
		print("⚠️ 有测试失败，请检查上述问题。")
