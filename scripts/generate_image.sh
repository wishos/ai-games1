#!/bin/bash
# MiniMax Image Generation Script
# 用法: bash generate_image.sh "prompt" [output.png]
#
# 注意: MiniMax API (api.minimax.chat) 目前返回 insufficient balance
# 改用程序化生成像素精灵图 (node generate_sprite.js)

PROMPT="$1"
OUTPUT="${2:-./output.png}"

if [ -z "$PROMPT" ]; then
    echo "用法: $0 \"prompt\" [output.png]"
    echo "注意: MiniMax图片API余额不足，改用程序化像素生成"
    echo ""
    echo "可用像素精灵类型:"
    echo "  knight    - 骑士 (银色盔甲+红披风)"
    echo "  slime     - 史莱姆 (绿色凝胶)"
    echo "  skeleton  - 骷髅战士"
    echo "  demon     - 深渊恶魔"
    echo ""
    echo "示例:"
    echo "  node scripts/generate_sprite.js knight assets/knight.png"
    exit 1
fi

# 检查提示词是否匹配已知类型
if echo "$PROMPT" | grep -qi "knight\|骑士\|战士"; then
    TYPE="knight"
elif echo "$PROMPT" | grep -qi "slime\|史莱姆\|史莱"; then
    TYPE="slime"
elif echo "$PROMPT" | grep -qi "skeleton\|骷髅\|骨"; then
    TYPE="skeleton"
elif echo "$PROMPT" | grep -qi "demon\|恶魔\|魔"; then
    TYPE="demon"
else
    TYPE="knight"
fi

node scripts/generate_sprite.js "$TYPE" "$OUTPUT"
