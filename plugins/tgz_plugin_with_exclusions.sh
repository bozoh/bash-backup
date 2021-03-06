#/bin/bash
#
# Gera um Dump de um bacno postgres
#
#

function modo_usar
{
	echo "Modo de usar: `basename $0` -e <EXCLUSIONS> -s <ARQUIVO/DIRETORIO ORIGEM> -f <NOME ARQUIVO>"
  	exit 65
}

while getopts “s:f:e:d” OPTION
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
         e)
         	 EXCLUSIONS=$OPTARG
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
if [ ! -n "$EXCLUSIONS" ]
then
	echo "Nome das exclusoes não definido"
	modo_usar
fi

if [ "$DEBUG" ]
then
	echo "tar cvzf $ARQUIVO --exclude='$EXCLUSIONS'  $SOURCE"
else
	if [ -f "${SOURCE}" ]
	then
		junk=`tar cvzf $ARQUIVO --exclude=\'$EXCLUSIONS\' -C $SOURCE`
		exit $?
	else
		junk=`tar cvzf $ARQUIVO --exclude=\'$EXCLUSIONS\' -C $SOURCE .`
		exit $?
	fi
fi