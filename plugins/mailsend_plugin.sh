#!/bin/bash
 
MAILSEND_DIR=backup/plugins/bin

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

dominio=`hostname`

if [ "$DEBUG" ]
then
	echo "echo -e \"$MENSAGEM\" | xargs -0  $MAILSEND_DIR/mailsend -f $MAIL_FROM -d $dominio -smtp $SMTP -t $EMAILS -sub \"$ASSUNTO\" +cc +bcc -M"
else
	junk=`echo -e \"$MENSAGEM\" | xargs -0  $MAILSEND_DIR/mailsend -f $MAIL_FROM -d $dominio -smtp $SMTP -t $EMAILS -sub "$ASSUNTO" +cc +bcc -M`
	exit $?
fi