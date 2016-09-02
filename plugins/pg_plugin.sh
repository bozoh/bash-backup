#!/bin/bash
# 
# Gera um Dump de um bacno postgres
#
#

function modo_usar
{
	echo "Modo de usar: `basename $0` -u [USUARIO POSTGRES] -b <BANCO> -s [ESQUEMA DO BANCO] -e [ENCONDING] -h [HOST] -f <ARQUIVO DO DUMP>"
  	exit 65
}

while getopts “b:f:s:e:h:u:d” OPTION
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
         s)
             ESQUEMA=$OPTARG
             ;;
         e)
             ENCONDING=$OPTARG
             ;;
		 u)
             USUARIO_POSTGRES=$OPTARG
             ;;
		 h)
             HOST=$OPTARG
             ;;
         ?)
             modo_usar
             ;;
     esac
done

if [ ! -n "$USUARIO_POSTGRES" ]
then
	USUARIO_POSTGRES=postgres
fi


if [ ! -n "$BANCO" ]
then
	echo "Nome do Banco não definido"
	modo_usar
fi

if [ ! -n "$ARQUIVO" ]
then
	echo "Nome do arquivo do dump não definido"
	modo_usar
fi

if [ ! -n "$ESQUEMA" ]
then
	ESQUEMA="public"
fi

if [ ! -n "$HOST" ]
then
	HOST="localhost"
fi

if [ ! -n "$ENCONDING" ]
then
	ENCODING="UTF-8"
fi

PG_VERSION=`psql --version`
PG_VERSION=`echo $PG_VERSION | cut -d" " -f3 |cut -d"." -f1` 

if [ "$DEBUG" ]
then
	if [ $PG_VERSION -le 8 ]
	then
		echo "pg_dump $BANCO -On$ESQUEMA -d -E$ENCONDING -Fc -U$USUARIO_POSTGRES -h$HOST -f$ARQUIVO"
	else
		echo "pg_dump $BANCO -On$ESQUEMA --inserts -E$ENCONDING -Fc -U$USUARIO_POSTGRES -h$HOST -f$ARQUIVO"
	fi
else
	#dependendo da versão do postgres, não aceita a opção -E no dump
	if [ $PG_VERSION -le 8 ]
	then
		pg_dump $BANCO -On$ESQUEMA -d -E$ENCONDING -Fc -U$USUARIO_POSTGRES -h$HOST -f$ARQUIVO
	else
		pg_dump $BANCO -On$ESQUEMA --inserts -E$ENCONDING -Fc -U$USUARIO_POSTGRES -h$HOST -f$ARQUIVO
	fi
	
	exit $?
fi




