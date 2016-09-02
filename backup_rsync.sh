rsync -avzrc --exclude *.gz --delete -e ssh s8eadcop@ead.coppead.ufrj.br:backup-files/ /backup/coppead-ead/ 2>>/var/log/backup.log >>/var/log/backup.log
