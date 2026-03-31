#!/bin/bash
# 数据库备份脚本
# 使用 MySQL 5.5 mysqldump 导出远程数据库

MYSQL_DUMP="/opt/local/var/macports/software/mysql55/mysql55-5.5.62_3.darwin_22.x86_64/opt/local/lib/mysql55/bin/mysqldump"
HOST="bdm123604631.my3w.com"
USER="bdm123604631"
PASS="6767C9505"
DBNAME="bdm123604631_db"

BACKUP_DIR="$HOME/.openclaw/workspace/wishos/colormax-backup/colormax-db"
DATE=$(date +%Y-%m-%d)
SQL_FILE="$BACKUP_DIR/backup.sql"

echo "[$(date)] 开始备份数据库..."

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 导出数据库
$MYSQL_DUMP -h "$HOST" -u "$USER" -p"$PASS" "$DBNAME" > "$SQL_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] 备份成功: $SQL_FILE"
    
    # 进入目录提交并推送
    cd "$BACKUP_DIR"
    git add backup.sql
    git commit -m "backup: $(date +%Y-%m-%d)"
    git push
    
    echo "[$(date)] Git 提交并推送完成"
else
    echo "[$(date)] 备份失败"
    cat "$SQL_FILE"
fi
