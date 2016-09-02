#!/bin/bash
# 
# Gera um Dump de um banco mysql
#

MYSQLDUMP=`which mysqldump`

function modo_usar
{
	echo "Modo de usar: `basename $0` -u <USUARIO> -p <PASSWORD> -b <BANCO> -f <ARQUIVO DO DUMP>"
  	exit 65
}



while getopts “b:f:u:p:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         b)
             BANCO=$OPTARG
             ;;
         f)
             ARQUIVO=$OPTARG
             ;;
         p)
             PASS=$OPTARG
             ;;
		 u)
		 	 USER=$OPTARG
		 	 ;;         
         ?)
             modo_usar
             ;;
     esac
done

if [ ! -n "$USER" ]
then
	modo_usar
fi

if [ ! -n "$BANCO" ]
then
	modo_usar
fi

if [ ! -n "$ARQUIVO" ]
then
	modo_usar
fi

if [ ! -n "$PASS" ]
then
	modo_usar
fi

if [ "$DEBUG" = "yes" ]
then
	echo "sh -c \"$MYSQLDUMP -u$USER -p$PASS $BANCO > $ARQUIVO\""
else
	if [ ! -n "$MYSQLDUMP" ]
	then
		echo "Não foi possí­vel encontrar o comando mysqldump"
		exit 127
	fi
	sh -c "$MYSQLDUMP -u$USER -p$PASS $BANCO > $ARQUIVO"
	exit $?
fi
