#!/bin/bash

function modo_usar 
{
	echo
	echo "$0 -u<USUARIO> -s<SERVIDOR> -r<DIRETORIO_REMOTO> -l<DIRETORIO_LOCAL>"
	echo
	exit 65
} 
DIR_CHAR=false

while getopts “u:s:r:l:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         u)
             USUARIO=$OPTARG
             ;;
         s)
             SERVIDOR=$OPTARG
             ;;              
         r)
         	 DIR_REMOTO=$OPTARG
			 len=`expr length $DIR_REMOTO`
			 last_char=${DIR_REMOTO:$len-1}
			 if [ "$last_char" = "/" ]
			 then 
             	DIR_CHAR=true
			 fi
             ;;
		 l)
             DIR_LOCAL=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done

if [ ! "$USUARIO" ]
then
	echo "Erro: Usuário não especificado"
	modo_usar
fi

if [ ! "$SERVIDOR" ]
then
	echo "Erro: Servidor não especificado"
	modo_usar
fi


if [ ! "$DIR_REMOTO" ]
then
	echo "Erro: Diretório remoto não especificado"
	modo_usar
fi

if [ ! "$DIR_LOCAL" ]
then
	echo "Erro: Diretório local não especificado"
	modo_usar
fi

if [ "$DIR_CHAR" = "true" ]
then
	DIR_LOCAL="${DIR_LOCAL}/"
fi
 
if [ "$DEBUG" ]
then
	echo rsync -rlcvz -e ssh --delete $DIR_LOCAL $USUARIO@$SERVIDOR:$DIR_REMOTO
else
	junk=`rsync -rlcvz -e ssh --delete $DIR_LOCAL $USUARIO@$SERVIDOR:$DIR_REMOTO`
	exit $?
fi
