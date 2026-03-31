# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## 饮食记录
- 文档: `meal.md` (workspace 根目录)
- 格式: 按日期分组，记录早饭/午饭/晚饭

## 体重记录
- 文档: `weight.md` (workspace 根目录)
- 格式: 日期 + 体重 + 备注
- **当前**: 96.4kg (2026-03-30)
- **3月目标**: 95kg ❌ 未达成（最终96.0kg）
- **4月目标**: 90kg（距目标 -4.8kg）

## 信用卡消费
- 位置: `~/.openclaw/workspace/wishos/wishos-stuff/credit-card/`
- 文件: `records.csv`
- 规则: 每年每卡至少消费 10 次

## 密码管理
- 位置: `~/.openclaw/workspace/wishos/wishos-stuff/password/`

## 软件安装
- macOS: 使用 macport (`sudo port install xxx`)

## GIF转MP4
- 使用PIL读取GIF获取每帧的原始时长（毫ms）
- 按每帧时长展开帧数，转换为30fps的视频
- 不要用固定fps直接转换，否则会压缩时间

## ZionLadder VPN
- SOCKS5代理: 127.0.0.1:1097
- curl使用: curl -x socks5://127.0.0.1:1097 https://...

## Google热搜
- 无法抓取（需要JS渲染）
- 可替代: 百度热搜 / 微博热搜 / Bing News

---

## 房贷管理

### 文件位置
- 基本信息: `~/.openclaw/workspace/wishos/finance-management/mortgage/房贷.md`
- 还款记录: `~/.openclaw/workspace/wishos/finance-management/mortgage/房贷_还款记录.md`
- 还款计划: `~/.openclaw/workspace/wishos/finance-management/mortgage/房贷_还款计划.md`

### 数据来源
- **基本信息**：固定值，由用户设置
- **已还款情况**：从 `房贷_还款记录.md` 统计计算
- **当前剩余本金**：总额 - 已还本金
- **当前月供**：根据剩余本金和剩余期数计算

### 更新规则
用户每月提供还款数据后，按以下顺序更新：

**第一步：更新还款记录**
- 在 `房贷_还款记录.md` 中添加新一条还款记录
- 统计已还本金和利息总和

**第二步：更新房贷.md**
- 更新"已还款情况"（已还期数、已还本金、已还利息、已还总额）
- 更新"当前剩余本金"（总额 - 已还本金）
- 重新计算"当前月供"（根据剩余本金和剩余期数）

**第三步：更新还款计划**
- 根据新的剩余本金和剩余期数重新计算月供
- 生成新的还款计划保存到 `房贷_还款计划.md`

**第三步：更新贷款基本信息**
- 更新 `房贷.md` 中的：
  - 已还期数
  - 已还本金、已还利息
  - 当前剩余本金（总额 - 已还本金）
  - 剩余期数
  - 当前月供

### 手动更新命令
```bash
python scripts/update_mortgage.py \
  --商贷本金 <数值> \
  --商贷利息 <数值> \
  --公积金本金 <数值> \
  --公积金利息 <数值> \
  --日期 <YYYY-MM-DD>
```

---

## 个人邮箱
- 56300414@qq.com

## 工作目录结构
```
~/.openclaw/workspace/wishos/
├── huawei-cloud-mail-automation/   # 华为云邮件自动化处理
│   └── email-fetcher/
├── wishos-daily-news/              # wishos每日新闻网站
│   └── wishos.github.io.src/
├── finance-management/              # 财务管理
│   ├── credit-card/                # 信用卡消费
│   └── password/                  # 密码管理
├── personal-health/                # 个人健康记录
│   ├── weight.md                  # 体重记录
│   └── meal.md                    # 饮食记录
├── colormax-backup/               # Colormax数据库备份脚本
└── wishos-stuff/                 # 其他杂项
```

- Default email: 56300414@qq.com
- SMTP Server: smtp.qiye.aliyun.com
- Port: 465 (SSL)
- Account: openclaw@wishos.com
- Password: 7392136xYz

## 邮件收取 (Email Fetcher)

### 目录结构
```
~/.openclaw/workspace/wishos/huawei-cloud-mail-automation/email-fetcher/
├── scripts/
│   ├── fetch-emails.py       # 通用邮件收取
│   └── handlers/
│       └── huawei_cloud.py  # 华为云处理器
├── attachments/               # 下载的附件
└── data/                   # 处理后的数据
```

### 飞书表格
- 地址: https://rkzav3pcv4.feishu.cn/wiki/ZxDmwxKzIi6BkUk6pUGctmf7nWe
- 字段: 月份、模板ID、模板名称、客户签名、成功解析数、曝光PV/UV、点击PV/UV

### 定时任务
- 每分钟检查一次
- 无新邮件时不通知

## AI游戏项目 (ai-games1)

### 项目位置
- `~/.openclaw/workspace/ai-games1/`
- Git: git@github.com:wishos/ai-games1.git

### 游戏文件
- `octopath-adventure.html` — 八方旅人HD-2D风格（主游戏）
- `index.html` — 经典像素地牢冒险

### 自动开发Cron
- 每分钟自动迭代一次（job id: 0192577e-35c8-4d4e-b11f-9442109356e8）
- 凌晨持续开发，明早查看进度

### MiniMax 图片生成
- 环境变量: `MINIMAX_API_KEY`
- 脚本: `~/.openclaw/workspace/ai-games1/scripts/generate_image.sh`
- 用法: `MINIMAX_API_KEY=xxx bash generate_image.sh "prompt" output.png`
- 模型: MiniMax-Image-01
- 张吉彬套餐: minimax 99高速套餐

### 迭代方向
- 八方旅人HD-2D风格
- 像素角色 + 油画风景背景
- 新职业/角色系统
- 装备/商店系统
- 剧情对话

## 临时文件目录

```
~/.openclaw/workspace/temp/
├── captcha/   # 验证码处理临时文件
└── video/     # 视频处理临时文件
```

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
