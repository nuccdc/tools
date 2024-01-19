#!/bin/bash

sed -e '/<!-- Directories to check  (perform all possible verifications) -->/a\' -e '<directories realtime="yes" report_changes="yes">/etc/passwd,/etc/shadow,/etc/sudoers,/home/*/.bashrc,/home/*/.ssh/authorized_keys,/etc/cron.*</directories>' /var/ossec/etc/ossec.conf
systemctl restart wazuh-agent