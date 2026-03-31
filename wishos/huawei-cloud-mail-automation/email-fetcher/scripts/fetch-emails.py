#!/usr/bin/env python3
"""
邮件收取脚本
被 cron 每分钟调用
"""

import imaplib
import email
import os
import json
from datetime import datetime

# 配置
IMAP_SERVER = "imap.qiye.aliyun.com"
IMAP_PORT = 993
EMAIL = "openclaw@wishos.com"
PASSWORD = "7392136xYz"
DOWNLOAD_DIR = os.path.expanduser("~/.openclaw/workspace/wishos/huawei-cloud-mail-automation/email-fetcher/attachments")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

def fetch_emails():
    """收取未读邮件"""
    try:
        mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
        mail.login(EMAIL, PASSWORD)
        mail.select('INBOX')
        
        status, messages = mail.search(None, 'UNSEEN')
        if status != 'OK':
            return []
        
        email_ids = messages[0].split()
        if not email_ids:
            mail.logout()
            return []
        
        print(f"Found {len(email_ids)} unread emails")
        
        email_info_list = []
        
        for num in email_ids:
            status, msg_data = mail.fetch(num, '(RFC822)')
            if status != 'OK':
                continue
            
            msg = email.message_from_bytes(msg_data[0][1])
            from_addr = email.utils.parseaddr(msg.get('from', ''))[1]
            subject = msg.get('subject', '')
            
            attachments = []
            for part in msg.walk():
                if part.get_content_disposition() == 'attachment':
                    filename = part.get_filename()
                    if filename:
                        filename = email.header.decode_header(filename)[0][0]
                        if isinstance(filename, bytes):
                            filename = filename.decode('utf-8')
                        
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                        safe_filename = f"{timestamp}_{filename}"
                        filepath = os.path.join(DOWNLOAD_DIR, safe_filename)
                        
                        with open(filepath, 'wb') as f:
                            f.write(part.get_payload(decode=True))
                        
                        attachments.append(filename)
            
            email_info_list.append({
                'from': from_addr,
                'subject': subject,
                'attachments': attachments
            })
            
            # 标记为已读
            mail.store(num, '+FLAGS', '\\Seen')
        
        mail.close()
        mail.logout()
        
        return email_info_list
        
    except Exception as e:
        print(f"Error: {e}")
        return []

if __name__ == "__main__":
    emails = fetch_emails()
    if emails:
        print("---EMAIL_JSON_START---")
        print(json.dumps(emails, ensure_ascii=False))
        print("---EMAIL_JSON_END---")
