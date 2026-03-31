#!/usr/bin/env python3
"""
华为云邮件处理模块
"""

import pandas as pd
import json
import os
import requests

# 飞书配置
FEISHU_APP_TOKEN = "BaTnbzFSjagElvsuExAccQFanTf"
FEISHU_TABLE_ID = "tblZknyX5oxeq3yc"

def process_huawei_cloud_email(attachment_path):
    """处理华为云曝光点击数据"""
    try:
        df = pd.read_excel(attachment_path)
        
        # 转换时间列并提取月份
        if '时间' in df.columns:
            df['时间'] = pd.to_datetime(df['时间'])
            df['月份'] = df['时间'].dt.month
        else:
            return None, "No '时间' column"
        
        # 按月份+模板ID汇总
        summary = df.groupby(['月份', '模板ID', '模板名称', '客户签名']).agg({
            '成功解析数': 'sum',
            '曝光PV': 'sum',
            '曝光UV': 'sum',
            '点击PV': 'sum',
            '点击UV': 'sum'
        }).reset_index()
        
        # 格式化月份为 YYYYMM
        records = summary.to_dict('records')
        for r in records:
            r['模板ID'] = str(r['模板ID'])
            r['月份'] = f"2023{r['月份']:02d}"
            for k, v in r.items():
                if pd.isna(v):
                    r[k] = ''
        
        return records, records[0]['月份'] if records else None
        
    except Exception as e:
        return None, str(e)

def batch_write_to_feishu(records):
    """批量写入飞书"""
    # 获取token
    resp = requests.post(
        'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
        json={
            "app_id": "cli_a914f14df2781cc2",
            "app_secret": "MZIwvEVeBSlqDJfn9xXdkgaMsdB0qjAB"
        }
    )
    token = resp.json().get('tenant_access_token')
    if not token:
        return False, "Failed to get token"
    
    # 批量写入
    url = f"https://open.feishu.cn/open-apis/bitable/v1/apps/{FEISHU_APP_TOKEN}/tables/{FEISHU_TABLE_ID}/records/batch_create"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    batch = [{"fields": r} for r in records]
    resp = requests.post(url, headers=headers, json={"records": batch})
    
    if resp.status_code == 200:
        result = resp.json()
        return result.get('code') == 0, f"Written {len(records)} records"
    else:
        return False, resp.text

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        attachment_path = sys.argv[1]
        records, month = process_huawei_cloud_email(attachment_path)
        if records:
            success, msg = batch_write_to_feishu(records)
            print(f"{'OK' if success else 'FAIL'}: {msg}")
        else:
            print(f"ERROR: {month}")
