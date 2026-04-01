extends SceneTree

# Godot 项目调试脚本
# 运行方式: Godot --headless --path <project_path> --script <this_script>

var errors: Array = []
var warnings: Array = []
var checks_passed: int = 0
var checks_failed: int = 0

func _init():
    print("=".repeat(50))
    print("🔍 Godot 项目调试检查")
    print("=".repeat(50))
    
    # 1. 检查项目文件
    _check_project_file()
    
    # 2. 检查所有脚本
    _check_all_scripts()
    
    # 3. 检查场景文件
    _check_scenes()
    
    # 4. 检查资源
    _check_assets()
    
    # 5. 尝试加载主场景
    _try_load_main_scene()
    
    # 输出结果
    _print_summary()
    
    quit()

func _check_project_file():
    print("\n📁 检查 project.godot...")
    var f = FileAccess.file_exists("res://project.godot")
    if f:
        print("  ✅ project.godot 存在")
        checks_passed += 1
    else:
        print("  ❌ project.godot 不存在!")
        errors.append("project.godot 不存在")
        checks_failed += 1

func _check_all_scripts():
    print("\n📝 检查所有脚本...")
    var scripts_dir = DirAccess.open("res://scripts")
    if scripts_dir:
        scripts_dir.list_dir_begin()
        var file_name = scripts_dir.get_next()
        var script_count = 0
        while file_name != "":
            if file_name.ends_with(".gd"):
                var path = "res://scripts/" + file_name
                var script = load(path)
                if script:
                    print("  ✅ " + file_name)
                    checks_passed += 1
                else:
                    print("  ❌ " + file_name + " 加载失败!")
                    errors.append(file_name + " 加载失败")
                    checks_failed += 1
                script_count += 1
            file_name = scripts_dir.get_next()
        print("  共检查 " + str(script_count) + " 个脚本")
    else:
        print("  ❌ scripts 目录不存在!")
        errors.append("scripts 目录不存在")
        checks_failed += 1

func _check_scenes():
    print("\n🎮 检查场景文件...")
    var scenes_dir = DirAccess.open("res://scenes")
    if scenes_dir:
        scenes_dir.list_dir_begin()
        var file_name = scenes_dir.get_next()
        var scene_count = 0
        while file_name != "":
            if file_name.ends_with(".tscn"):
                var path = "res://scenes/" + file_name
                var scene = load(path)
                if scene:
                    print("  ✅ " + file_name)
                    checks_passed += 1
                else:
                    print("  ❌ " + file_name + " 加载失败!")
                    errors.append(file_name + " 加载失败")
                    checks_failed += 1
                scene_count += 1
            file_name = scenes_dir.get_next()
        print("  共检查 " + str(scene_count) + " 个场景")
    else:
        print("  ❌ scenes 目录不存在!")
        errors.append("scenes 目录不存在")
        checks_failed += 1

func _check_assets():
    print("\n🖼️ 检查资源文件...")
    var assets_dir = DirAccess.open("res://assets")
    if assets_dir:
        assets_dir.list_dir_begin()
        var file_name = assets_dir.get_next()
        var asset_count = 0
        while file_name != "":
            if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
                var path = "res://assets/" + file_name
                var tex = load(path)
                if tex:
                    asset_count += 1
                else:
                    print("  ⚠️ " + file_name + " 可能有问题")
                    warnings.append(file_name)
            file_name = assets_dir.get_next()
        print("  ✅ 共 " + str(asset_count) + " 个图片资源")
        checks_passed += 1
    else:
        print("  ⚠️ assets 目录不存在或为空")
        warnings.append("assets 目录可能缺失")

func _try_load_main_scene():
    print("\n🎯 尝试加载主场景...")
    var main_scene_path = "res://scenes/main.tscn"
    var scene = load(main_scene_path)
    if scene:
        print("  ✅ main.tscn 加载成功")
        checks_passed += 1
        
        # 尝试实例化
        var instance = scene.instantiate()
        if instance:
            print("  ✅ main.tscn 实例化成功")
            checks_passed += 1
            instance.queue_free()
        else:
            print("  ❌ main.tscn 实例化失败")
            errors.append("main.tscn 实例化失败")
            checks_failed += 1
    else:
        print("  ❌ main.tscn 加载失败!")
        errors.append("main.tscn 加载失败")
        checks_failed += 1

func _print_summary():
    print("\n" + "=".repeat(50))
    print("📊 检查结果汇总")
    print("=".repeat(50))
    print("✅ 通过: " + str(checks_passed))
    print("❌ 失败: " + str(checks_failed))
    print("⚠️ 警告: " + str(warnings.size()))
    
    if errors.size() > 0:
        print("\n❌ 错误列表:")
        for e in errors:
            print("  - " + str(e))
    
    if warnings.size() > 0:
        print("\n⚠️ 警告列表:")
        for w in warnings:
            print("  - " + str(w))
    
    if checks_failed == 0:
        print("\n🎉 所有检查通过! 项目可以正常运行。")
    else:
        print("\n💥 有 " + str(checks_failed) + " 项检查失败，需要修复。")
    
    print("=".repeat(50))
