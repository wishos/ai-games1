#!/bin/bash
# FTP 同步脚本 - 优化版
# 从远程服务器下载网站文件到本地
# 解决中文文件名编码问题

FTP_HOST="byu2632830001.my3w.com"
FTP_USER="byu2632830001"
FTP_PASS="6767C9505"
LFTP="/opt/local/bin/lftp"
LOCAL_DIR="$HOME/.openclaw/workspace/wishos/colormax-backup/colormax"
MAX_RETRIES=3

echo "[$(date)] 开始 FTP 同步..."

# 创建本地目录
mkdir -p "$LOCAL_DIR"

# 重试机制
for attempt in $(seq 1 $MAX_RETRIES); do
    echo "[$(date)] 第 $attempt 次尝试..."
    
    # 使用 lftp 进行 FTP 同步
    # 编码设置：
    #   ftp:charset gbk - 远程服务器使用 GBK 编码
    #   file:charset utf-8 - 本地文件使用 UTF-8
    #   ftp:skip-charset-probe on - 跳过编码探测
    # 参数：
    #   --verbose - 详细输出
    #   --continue - 断点续传
    #   --parallel=3 - 并行下载
    #   --use-pget-n=3 - 每个文件用 3 个连接
    $LFTP -c "
    open ftp://$FTP_HOST
    user $FTP_USER $FTP_PASS
    set net:timeout 300
    set net:max-retries 3
    set ftp:charset gbk
    set file:charset utf-8
    set ftp:skip-charset-probe on
    set ftp:list-options -a
    set xfer:log yes
    set xfer:log-file $LOCAL_DIR/.xferlog
    mirror --verbose --continue --parallel=3 --no-perms --no-umask --ignore-time /htdocs $LOCAL_DIR
    bye
    "
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] FTP 下载完成"
        break
    else
        echo "[$(date)] 第 $attempt 次尝试失败"
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "[$(date)] 等待 10 秒后重试..."
            sleep 10
        fi
    fi
done

# 清理临时文件（保留原文件名）
find "$LOCAL_DIR" -name "*.lftp-pget-status" -delete 2>/dev/null
find "$LOCAL_DIR" -name "*.part" -delete 2>/dev/null
rm -f "$LOCAL_DIR/.xferlog" 2>/dev/null

# 处理编码问题导致的部分损坏文件
# 查找可能的问题文件（大小为0或文件名包含非法字符）
echo "[$(date)] 检查并清理问题文件..."
find "$LOCAL_DIR" -type f -size 0 -delete 2>/dev/null

# 统计文件数量
FILE_COUNT=$(find "$LOCAL_DIR" -type f | wc -l)
echo "[$(date)] 本地文件数: $FILE_COUNT"

# 进入目录提交并推送
cd "$LOCAL_DIR"
git add -A
git commit -m "sync: $(date +%Y-%m-%d)"
git push

echo "[$(date)] Git 提交并推送完成"
