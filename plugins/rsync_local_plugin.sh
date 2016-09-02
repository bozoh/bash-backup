#!/bin/bash
 
function modo_usar 
{
	echo
	echo "$0 -r<DIRETORIO_REMOTO> -l<DIRETORIO_LOCAL>"
	echo
	exit 65
} 


while getopts “r:l:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
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
	echo rsync -rlcvz --delete $DIR_LOCAL $DIR_REMOTO
else
	junk=`rsync -rlcvz --delete $DIR_LOCAL $DIR_REMOTO`
	exit $?
fi
