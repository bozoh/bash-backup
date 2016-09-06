# bash-backup

Simple backup rotine scripts with schedule, remote transfer, e-mail report




#Log rotate sample:
```
/backup/*.log {
        daily
        missingok
        rotate 4
        compress
        delaycompress
        notifempty
        create 640 root backup
}   
```

#Cron  sample
15 0-23 * * * /backup/backup.sh 2>/dev/null >/dev/null

