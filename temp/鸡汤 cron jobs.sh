#!/bin/bash
# 创建10个整点cron任务

for hour in 09 10 11 12 13 14 15 16 17 18; do
  openclaw cron add \
    --name "鸡汤-$hour:00" \
    --schedule '{"kind":"cron","expr":"0 '$hour' * * 1-5","tz":"Asia/Shanghai"}' \
    --payload '{"kind":"systemEvent","text":"鸡汤TIME"}' \
    --sessionTarget main
  echo "Created cron for $hour:00"
done
