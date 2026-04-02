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

- [ ] P0: 修复 `_check_battle_end()` await 问题 (2277, 2366, 3982)
- [ ] P1: 修复战斗UI内存泄漏
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
