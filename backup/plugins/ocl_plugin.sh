#!/bin/bash
 
export ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export NLS_DATE_FORMAT='DD/MM/YYYY HH24:MI:SS'




function modo_usar
{
	echo "Gera dump do banco de dados, modo de usar"
	echo "$0 -u [USUARIO ORACLE] -p <SENHA ORACLE> -s <SID> -f <NOME DO ARQUIVO>"
	exit 65
}


while getopts “s:f:u:p:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         s)
             SID=$OPTARG
             ;;
         f)
             ARQUIVO=$OPTARG
             ;;
         u)
             USUARIO_ORACLE=$OPTARG
             ;;
         p)
             PW_ORACLE=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done

args=" $*"
SID=`expr match "$args" '.*[[:blank:]]-s\(.[[:graph:]]*\).*'`
ARQUIVO=`expr match "$args" '.*[[:blank:]]-f\(.[[:graph:]]*\).*'`
USUARIO_ORACLE=`expr match "$args" '.*[[:blank:]]-u\(.[[:graph:]]*\).*'`
PW_ORACLE=`expr match "$args" '.*[[:blank:]]-p\(.[[:graph:]]*\).*'`

#sneqdg06

if [ ! "$PW_ORACLE" ]
then
 echo "SENHA ORACLE não definida"
 modo_usar
fi

if [ ! "$USUARIO_ORACLE" ]
then
 USUARIO_ORACLE=oracle
fi


if [ ! "$SID" ]
then
 modo_usar
fi

if [ ! "$ARQUIVO" ]
then
	modo_usar
fi

export ORACLE_SID=$SID

if [ "$DEBUG" ]
then
	echo su - $USUARIO_ORACLE -c "$ORACLE_HOME/bin/exp \"system/$PW_ORACLE file=/tmp/exp_backup_full.dmp log=/tmp/exp_backup_full.log full=yes consistent=yes\"" 
else
	su - $USUARIO_ORACLE -c "$ORACLE_HOME/bin/exp \"system/$PW_ORACLE file=/tmp/exp_backup_full.dmp log=/tmp/exp_backup_full.log full=yes consistent=yes\" >/dev/null "
	if [ "$?" = "0" ]
	then
		tar cvjf $ARQUIVO /tmp/exp_backup_full.dmp
		rm -f /tmp/exp_backup_full.dmp
		rm -f /tmp/exp_backup_full.log
	else 
		exit $?
	fi
fi