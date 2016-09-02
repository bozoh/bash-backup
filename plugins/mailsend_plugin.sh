#!/bin/bash
#See more in https://github.com/muquit/mailsend
 
MAILSEND_DIR=../plugins/bin

function modo_usar 
{
	echo
	echo "$0 -f <MAIL FROM> -s <SERVIDOR SMTP> -t <EMAILS> -a <ASSUNTO> -m <MENSAGEM>"
	echo
	exit 65
} 


while getopts “f:s:t:a:m:d” OPTION
do
     case $OPTION in
         d)
             DEBUG=yes
             ;;
         f)
             MAIL_FROM=$OPTARG
             ;;
         s)
             SMTP=$OPTARG
             ;;
         t)
             EMAILS=$OPTARG
             ;;
		 a)
             ASSUNTO=$OPTARG
             ;;
		 m)
             MENSAGEM=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done

if [ ! "$MAIL_FROM" ]
then
	echo "Erro: MAIL FROM não especificado"
	modo_usar
	exit 0
fi

if [ ! "$SMTP" ]
then
	echo "Erro: SMTP não especificado"
	modo_usar
	exit 0
fi


if [ ! "$EMAILS" ]
then
	echo "Erro: EMAILS não especificado"
	modo_usar
	exit 0
fi

if [ ! "$MENSAGEM" ]
then
	echo "Erro: MENSAGEM não especificada"
	modo_usar
	exit 0
fi

if [ ! "$ASSUNTO" ]
then
	echo "Erro: ASSUNTO não especificado"
	modo_usar
	exit 0
fi



if [ "$DEBUG" ]
then
	echo "$MAILSEND_DIR/mailsend -f $MAIL_FROM -smtp $SMTP -t \"$EMAILS\" -sub \"$ASSUNTO\" +cc +bcc -M \"$MENSAGEM\""
else
	$MAILSEND_DIR/mailsend -f $MAIL_FROM -smtp $SMTP -t "$EMAILS" -sub "$ASSUNTO" +cc +bcc -M "$MENSAGEM" -cs "utf-8" -mime-type "text/plain"
	exit $?
fi