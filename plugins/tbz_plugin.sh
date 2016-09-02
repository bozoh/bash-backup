#!/bin/bash
#
#
#

function modo_usar
{
	echo "Modo de usar: `basename $0` -s <ARQUIVO/DIRETORIO ORIGEM> -f <NOME ARQUIVO>"
  	exit 65
}

while getopts “s:f:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         s)
             SOURCE=$OPTARG
             ;;
		 f)
             ARQUIVO=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done


if [ ! -n "$SOURCE" ]
then
	echo "ARQUIVO/DIRETORIO ORIGEM não definido"
	modo_usar 
fi

if [ ! -n "$ARQUIVO" ]
then
	echo "Nome do arquivo não definido"
	modo_usar
fi

if [ "$DEBUG" ]
then
	echo "tar cvjf $ARQUIVO $SOURCE"
else
	if [ -f "${SOURCE}" ]
	then
		junk=`tar cvjf $ARQUIVO -C $SOURCE`
		exit $?
	else
		junk=`tar cvjf $ARQUIVO -C $SOURCE .`
		exit $?
	fi
fi


