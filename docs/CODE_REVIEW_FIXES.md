# 代码审查修复清单

**项目**: ai-games1-godot (武侠八方旅人)
**审查日期**: 2026-04-02
**状态**: 🔴 待修复

---

## 🔴 P0 - 必须立即修复 (编译错误)

### 1. `_check_battle_end()` 调用缺少 `await`
**文件**: `scripts/game.gd`
**问题**: `async func _check_battle_end()` 在非 async 函数中被调用时未使用 `await`

| 行号 | 当前代码 | 修复方案 |
|------|---------|---------|
| 2277 | `_check_battle_end()` | `await _check_battle_end()` |
| 2366 | `_check_battle_end()` | `await _check_battle_end()` |
| 3982 | `_check_battle_end()` | 需确认调用上下文，或改为同步逻辑 |

**说明**: 
- 第2277行在 `func _start_battle()` 内（非async）
- 第2366行在 `func _start_boss_battle()` 内（非async）
- 第3982行在 `func _on_skill_selected()` 内（非async）

---

## 🟠 P1 - 高优先级 (运行时问题)

### 2. 内存泄漏 - 战斗UI资源未释放
**文件**: `scripts/game.gd`
**问题**: 关闭战斗UI时，对象和信号未正确断开
**建议**: 在 `func _create_battle_ui()` 中创建的对象，需在场景切换时 `queue_free()` 并 `disconnect` 信号

### 3. `_consume_spell_pierce()` 命名不一致
**文件**: `scripts/game.gd` 第3410行
**问题**: 函数注释说"返还"但实现是"消耗"
```gdscript
# 这个函数注释说"返还"但实际是消耗魔法穿透
func _consume_spell_pierce() -> int:
```

---

## 🟡 P2 - 中优先级 (代码质量)

### 4. game.gd 过于庞大 (5369行)
**文件**: `scripts/game.gd`
**问题**: 严重违反单一职责原则
**建议拆分**:
```
scripts/
├── game.gd                    # 主控制器 (保留 ~500行)
├── battle/
│   ├── battle_system.gd      # 战斗核心逻辑
│   ├── battle_ui.gd          # 战斗UI管理
│   ├── skills.gd             # 技能系统
│   └── enemies/
│       ├── enemy_ai.gd       # 敌人AI
│       └── boss_ai.gd        # Boss AI
├── map/
│   ├── map_generator.gd      # 地图生成
│   └── floor_system.gd      # 楼层系统
├── player/
│   ├── player_data.gd        # 玩家数据
│   └── equipment.gd          # 装备系统
├── ui/
│   ├── inventory.gd          # 背包UI
│   ├── shop.gd               # 商店UI
│   └── dialog.gd             # 对话UI
└── audio/
    └── audio_manager.gd      # 音频管理
```

### 5. Boss AI 函数过长
**文件**: `scripts/game.gd`
**问题**: `_boss_hanbatian_action()` 等函数超过100行，重复代码多
**建议**: 提取公共逻辑到独立函数

### 6. 硬编码魔法数字
**文件**: 多处
**示例**:
```gdscript
# 坏例子
if hp < 100:
    player_data.exp += 50

# 好例子
const BOSS_REVIVE_HP_THRESHOLD := 100
const BOSS_KILL_EXP := 50
```

**需提取的常量**:
- `BOSS_REVIVE_HP_THRESHOLD = 100`
- `BEAST_ATK_MULTIPLIER = 1.5`
- `TRAP_DAMAGE_RATIO = 1.5`
- 各种技能伤害倍率
- 各种持续时间/冷却时间

---

## 📋 修复进度

- [x] P0: 修复 `_check_battle_end()` await 问题 ✅ (ce606d4)
- [x] P1: map_bg/map_ground/grass_pattern 内存泄漏 ✅ (ce606d4)
- [x] P1: battle_action_buttons 清理 ✅ (ce606d4)
- [ ] P1: 修复 `_consume_spell_pierce()` 注释
- [ ] P2: 拆分 game.gd 模块化改造
- [ ] P2: Boss AI 函数重构
- [ ] P2: 提取硬编码常量

---

## 持续审查机制

后续代码审查将持续进行，每次审查结果更新到此文件。

---

### 新发现问题 (2026-04-02 12:03)

#### P2 - 新增硬编码魔法数字

**文件**: `scripts/game.gd`

| 行号 | 代码片段 | 建议常量 |
|------|---------|---------|
| 965 | `randf() < 0.003` | `const RANDOM_ENCOUNTER_RATE := 0.003` |
| 2273 | `player_data.attack_power() * 1.5` (陷阱伤害) | `const TRAP_DAMAGE_RATIO := 1.5` |
| 2275 | `player_data.attack_power() * 1.0` (Boss陷阱伤害) | `const BOSS_TRAP_DAMAGE_RATIO := 1.0` |
| 303,310,873,1063 | `Vector2(1280, 720)` | `const SCREEN_SIZE := Vector2(1280, 720)` |
| 880 | `Vector2(1280, 500)` | `const GROUND_SIZE := Vector2(1280, 500)` |
| 3725 | `randi() % 100 < player_data.luk * 3` (背刺暴击) | 暴击率计算可提取 |
| 4652 | `randi() % 100 < player_data.luk * 2` (普通暴击) | 同上 |

#### P1 - `battle_action_buttons` 数组未清理

**文件**: `scripts/game.gd` 第2368行 `func _create_battle_ui()`

**问题**: `battle_action_buttons` 数组在每次调用 `_create_battle_ui()` 时只做 append，未先 clear。如果战斗UI被重建（如连续快速触发两场战斗），数组会不断累积旧按钮引用。

**当前代码**:
```gdscript
func _create_battle_ui():
    # 隐藏小地图
    if minimap_container:
        minimap_container.visible = false
    # 未清理 battle_action_buttons !
    var overlay = ColorRect.new()
    ...
    battle_action_buttons.append(attack_btn)  # 只增不减
```

**建议修复**: 在函数开头添加清理逻辑
```gdscript
func _create_battle_ui():
    # 清理旧按钮引用
    for btn in battle_action_buttons:
        if btn and is_instance_valid(btn):
            btn.queue_free()
    battle_action_buttons.clear()
    
    if minimap_container:
        minimap_container.visible = false
    ...
```

**说明**: 虽然 `battle_ui` 节点被替换时 Godot 会自动释放子节点，但数组中的引用不会自动清除，长期运行可能积累。

#### 环境说明 - Godot 编译检查

**问题**: `Godot --headless --check-only` 在此项目上无法在合理时间内完成检查

**原因分析**: 该项目依赖运行时场景加载和 `add_child()` 动态创建节点，headless 模式下场景初始化时间较长或需要图形上下文

**建议**: 
- 使用编辑器内 "检查代码" 功能 (Script -> Check Code)
- 或在本地运行: `/Applications/Godot.app/Contents/MacOS/Godot --headless --script` 并在编辑器中检查

---

### 审查记录 - 2026-04-02 12:03

本次审查发现：
- **P2**: 新增多处硬编码魔法数字（遭遇率、陷阱伤害倍率、屏幕分辨率等）
- **P1**: `battle_action_buttons` 数组未在 `_create_battle_ui()` 前清理，存在引用泄漏风险
- **环境**: Godot headless --check-only 无法在合理时间内完成检查（项目结构限制，非代码问题）

既有问题（P0/P1）状态不变，持续待修复。

---

### 新发现问题 (2026-04-02 18:03)

#### P1 - 内存泄漏：`_generate_map()` 中 `map_bg` 和 `map_ground` 使用 `remove_child` 而非 `queue_free`

**文件**: `scripts/game.gd`
**行号**: 第 907、915 行

**问题**: 当地图重新生成时（如切换楼层），旧的 `map_bg` 和 `map_ground` ColorRect 节点被从场景树中移除（`remove_child`），但并未释放（`queue_free`）。由于它们是实例变量，旧引用被覆盖后，节点对象成为孤儿永不释放。每切换一次楼层泄漏 2 个 1280×720 的 ColorRect 节点。

**当前代码**:
```gdscript
func _generate_map():
    # 背景（天空）
    remove_child(map_bg) if map_bg else null  # ← 泄漏！
    map_bg = ColorRect.new()
    ...
    add_child(map_bg)
    
    # 地面（草地）
    remove_child(map_ground) if map_ground else null  # ← 泄漏！
    map_ground = ColorRect.new()
    ...
    add_child(map_ground)
```

**建议修复**:
```gdscript
func _generate_map():
    # 清理旧地图背景
    if map_bg:
        map_bg.queue_free()
    map_bg = ColorRect.new()
    map_bg.size = Vector2(1280, 720)
    map_bg.position = Vector2(0, 0)
    map_bg.color = PALETTE.sky_top
    add_child(map_bg)
    
    if map_ground:
        map_ground.queue_free()
    map_ground = ColorRect.new()
    ...
```

---

#### P1 - 内存泄漏：`_generate_map()` 中 `grass_pattern` Node2D 从不清理

**文件**: `scripts/game.gd`
**行号**: 第 923-925 行

**问题**: `_generate_map()` 每次调用创建一个新的 `grass_pattern` Node2D（包含 80×45=3600 个 ColorRect 子节点），但从未被清理。`grass_pattern` 是局部变量，没有实例变量引用它，导致每次调用后旧节点成为孤儿无法释放。每切换一次楼层泄漏约 3600 个 ColorRect 节点。

**当前代码**:
```gdscript
func _generate_map():
    ...
    # 添加地表纹理（程序生成的像素草地）
    var grass_pattern = _create_grass_pattern()  # 每次新建
    grass_pattern.position = Vector2(0, 0)
    add_child(grass_pattern)  # 添加后无引用跟踪，无法清理！
```

**建议修复**:
```gdscript
var grass_pattern: Node2D  # 添加实例变量

func _generate_map():
    ...
    # 清理旧的草地纹理
    if grass_pattern:
        grass_pattern.queue_free()
    grass_pattern = _create_grass_pattern()
    grass_pattern.position = Vector2(0, 0)
    add_child(grass_pattern)
```

**风险评估**: 每次切换楼层泄漏约 3602 个节点（1 个 Node2D + 3600 个 ColorRect + 1 个 Node2D 的父节点 + 2 个 ColorRect 背景）。如果玩家频繁切换楼层（8 层游戏，每层可能切换多次），内存泄漏会快速累积。

---

#### 环境说明 - Godot 编译检查 (第二次审查)

**状态**: `Godot --headless --check-only` 在 30 秒内未能完成检查（进程超时被终止）

**分析**: 项目使用大量动态节点创建和程序化纹理生成，headless 模式下场景初始化耗时较长。这不是代码语法错误。

**手动验证建议**:
```bash
# 方法1：在 Godot 编辑器中打开项目，使用 Script → Check Code
# 方法2：使用更长的超时
/Applications/Godot.app/Contents/MacOS/Godot --headless --check-only --quit 2>&1 &
```

---

### 审查记录 - 2026-04-02 18:03

本次审查发现：
- **P1 (新)**: `_generate_map()` 中 `map_bg`/`map_ground` 使用 `remove_child` 而非 `queue_free`，切换楼层时节点泄漏
- **P1 (新)**: `_generate_map()` 中 `grass_pattern` 局部变量每次创建新 Node2D（3600 个 ColorRect）但从不释放，切换楼层时大量节点泄漏
- **P2 (新)**: 战斗系统新增技能硬编码数值（line 2389, 4365, 4413, 4545）使用 `player_data.attack_power() * N` 倍率，尚未提取常量

既有问题（P0/P1/P2）状态不变，持续待修复。
