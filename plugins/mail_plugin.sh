#!/bin/bash

function modo_usar 
{
	echo
	echo "$0 -e<EMAILS> -a<ASSUNTO> -m<MENSAGEM>"
	echo
	exit 65
} 

MAIL=`which mail`
DEBUG=no

while getopts “m:a:e:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         m)
             MENSAGEM=$OPTARG
             ;;
         a)
             ASSUNTO=$OPTARG
             ;;
         e)
             EMAILS=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done

if [ ! "$EMAILS" ]
then
	echo "Erro: EMAILS não especificado"
	modo_usar
fi

if [ ! "$ASSUNTO" ]
then
	echo "Erro: ASSUNTO não especificado"
	modo_usar
fi


if [ ! "$MENSAGEM" ]
then
	echo "Erro: MENSAGEM não especificado"
	modo_usar
fi

if [ "$DEBUG" = "yes" ]
then
	echo "echo -e \"$MENSAGEM\" | mail -s \"$ASSUNTO\" \"$EMAILS\""
else
	if [ ! "$MAIL" ]
	then
		echo "Comando mail não encotrado"
		exit 1
	fi
	junk=`echo -e "$MENSAGEM" | mail -s "$ASSUNTO" "$EMAILS" `
	exit $?
fi