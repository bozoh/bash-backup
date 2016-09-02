#!/bin/bash

BCKP_SCRIPTS_DIR=`dirname $0`
CONF_DIR=$BCKP_SCRIPTS_DIR/conf
PLUNGIN_DIR=$BCKP_SCRIPTS_DIR/plugins
TMP_DIR=/tmp
ARQUIVO_LOG=$BCKP_SCRIPTS_DIR/backup.log
ARQUIVO_LOG_ERRO=$ARQUIVO_LOG
BACKUP_FILE_PERMISSION=0660
BACKUP_DIR_PERMISSION=2770
BACKP_USERNAME=backup
BACKP_GROUP=backup
MAX_BACKUP_RUNS=5
COPY_RETRY_TIMES=500

SEND_MAIL_WARN=yes
SEND_MAIL_INFO=no
SEND_MAIL_SUCESS=no

####### Fim da configuração

VERSION=3.4
### Coloca o backup em debug mod,
## opçoes enabled ou vazio 
MASTER_DEBUG=''

while getopts “vd” OPTION
do
     case $OPTION in
         v)
			echo "Versão: $VERSION"
			exit 0
			;;
         d)
			MASTER_DEBUG="enabled"
			;;            
     esac
done


DATA_ATUAL=`date +%F`
EXECUTION_TIMEOUT=86400
#DISABLE_BACKUP_STR=Running
REPLY=''
ERRO_LOG=''
WARN_LOG=''
INFO_LOG=''
TIPO_BACKUP=''
ARQUIVO_ATUAL=''
ARQUIVO_PID='';


function mensagem
{
	local msg=$1
	local type=$2
	local data_hora=`date +'%d/%m/%Y %H:%M'`
	
	if [ ! "$type" ]
	then
		type="INFO"
	fi
	
	case $type in
		ERRO)
			ERRO_LOG="$ERRO_LOG\n$type: $data_hora [${MODULO}]: $msg"	
		;;
		WARN)
			WARN_LOG="$WARN_LOG\n$type: $data_hora [${MODULO}]: $msg"
		;;
		INFO)
			INFO_LOG="$INFO_LOG\n$type: $data_hora [${MODULO}]: $msg"
		;;
	esac			
	echo -e "$type: $data_hora [${MODULO}]: $msg" >> $ARQUIVO_LOG
}

function obtem_variavel
{
	local variavel=$1
	local padrao=$2

	#Para corrigir o erra se a variavel aparecer 2 vezes no arquivo, pega a que estiver mais próxima ao fim
	#do arquivo 
	REPLY=`cat $ARQUIVO_ATUAL | grep -nw $variavel | sort -r | grep -m1 -w $variavel | cut -f2 -d'='`
	if [ ! "$REPLY" ]
	then
		if [ "$padrao" ]
		then
			REPLY=$padrao
		else
			erro "Variavel $variavel está vazia" 
		fi	
	fi
	if [ "$DEBUG" = "yes" ]
	then
		echo ">> $variavel = $REPLY"
	fi
}

function manda_email
{
	local msg=$1

	obtem_variavel "COMANDO_EMAIL" "mail_plugin.sh -e root -a erro"
	
	if [ "$DEBUG" = "yes" ]
	then
		echo "$PLUNGIN_DIR/$REPLY -m \"$msg\""
	else
		sh -c "$PLUNGIN_DIR/$REPLY -m \"$msg\" 2>>$ARQUIVO_LOG_ERRO >>$ARQUIVO_LOG"
	fi
}

function erro
{
	local msg=$1
	
	if [ ! "$msg" ]
	then
		msg="Não especificado"
	fi
	
	if [ "$TIPO_BACKUP" ]
	then
		atualiza_proximo_backup $TIPO_BACKUP 0
	fi
	
	mensagem "$msg" ERRO
	return			 
}

function verifica_execucao
{
	local status=$1
	local msg=$2
	local tipo_msg=$3
	
	if [ ! "$tipo_msg" ]
	then
		tipo_msg="ERRO"
	fi
	
	if [ $status -ne 0 ]
	then
		if [ "$tipo_msg" = "ERRO" ]
		then
			erro "$msg"
			return 1
		else
			mensagem "$msg" WARN
		fi
	fi
}

function remove_backup
{
	local arquivo=$1
	local count=$2
	
	if [ ! "$count" ]
	then
		count=0
	fi
	
	if [ "$DEBUG" = "yes" ]
	then
		echo rm -rf $arquivo
	else
		rm -rf $arquivo
		if [ $? -ne 0 ]
		then
			if [ $count -gt $COPY_RETRY_TIMES ]
			then
				erro "Erro ao remover $arquivo [$count]"
				return 1
			else
				mensagem "Erro ao remover $arquivo [$count]"  "WARN"
				count=$(($count+5))
				sleep $count
				remove_backup $arquivo $count
			fi
		fi
	fi
} 

function move_backup
{
	local src=$1
	local trg=$2
	local count=$3
	
	if [ ! "$count" ]
	then
		count=0
	fi
	
	if [ "$DEBUG" = "yes" ]
	then
		echo mv $src $trg
	else
		if [ -s "$src" ]
		then
			mv $src $trg
		else
			erro "Tentando mover um arquivo vazio de $src para $trg"
			return 1
		fi
		if [ $? -ne 0 ]
		then
			if [ $count -gt $COPY_RETRY_TIMES ]
			then
				erro "Erro ao mover $src para $trg [$count]"
				return 1
			else
				mensagem "Erro ao mover $src para $trg [$count]"  "WARN"
				count=$(($count+5))
				sleep $count
				move_backup $src $trg $count
			fi
		fi
	fi
} 

function copy_backup
{
	local src=$1
	local trg=$2
	local count=$3
	
	if [ ! "$count" ]
	then
		count=0
	fi
	
	if [ "$DEBUG" = "yes" ]
	then
		echo cp $src $trg
	else
		if [ -s "$src" ]
		then
			cp $src $trg
		else
			erro "Tentando copiar um arquivo vazio de $src para $trg"
			return 1
		fi
		if [ $? -ne 0 ]
		then
			if [ $count -gt $COPY_RETRY_TIMES ]
			then
				erro "Erro ao copiar $src para $trg [$count]"
				return 1
			else
				mensagem "Erro ao copiar $src para $trg [$count]"  "WARN"
				count=$(($count+5))
				sleep $count
				copy_backup $src $trg $count
			fi
		fi
	fi
}


function atualiza_permissao_backup
{
	local arquivo=$1
	local permissao=$2
	
	if [ "$DEBUG" = "yes" ]
	then
		echo "chmod $permissao $arquivo"
	else
		chmod $permissao $arquivo
	fi
}

function atualiza_grupo_backup
{
	local arquivo=$1
	
	obtem_variavel "BACKUP_GROUP" "backup"
	BACKUP_GROUP=$REPLY
	if [ "$DEBUG" = "yes" ]
	then
		echo "chgrp $BACKUP_GROUP $arquivo"
	else
		chgrp $BACKUP_GROUP $arquivo
	fi
}


function verifica_diretorio
{
	local dir=$1
	
	if [ ! -d $dir ]
	then
		if [ "$DEBUG" = "yes" ]
		then
			echo "mkdir -p $dir"
		else
			mkdir -p $dir
		fi
		atualiza_permissao_backup $dir $BACKUP_DIR_PERMISSION
		atualiza_grupo_backup $dir
	fi 
		
}

function clear_backup 
{
	local tipo=$1
	
	obtem_nome_arquivo $tipo
	local arquivo=$REPLY
	if [ -e "$arquivo" ]
	then
		remove_arquivo $arquivo
	fi
}


function interrupt
{
	#Limpando os arquivos temporários
	if [ "$ARQUIVO_PID" ]
	then
		rm $ARQUIVO_PID
	fi
	
	if [ "$LAST_BACKUP_FILENAME" ]
	then
		rm $LAST_BACKUP_FILENAME
	fi
	
	if [ "$TIPO_BACKUP" ]
	then
		atualiza_proximo_backup $TIPO_BACKUP 0
	fi
	erro "Srcipt abortado"
	manda_email "Erro no backup $TIPO_BACKUP do $MODULO devido aos seguintes erros:\n$ERRO_LOG"
	exit 1
}

function atualiza_proximo_backup 
{
	local tipo=$1
	local time=$2
	local count=$3
	
	if [ "$DEBUG" = "yes" ]
	then
		echo "cat $ARQUIVO_ATUAL | grep -v -w PROXIMO_BACKUP_$tipo > $ARQUIVO_ATUAL.tmp"
		echo "echo "PROXIMO_BACKUP_$tipo=$time" >>  $ARQUIVO_ATUAL.tmp"
		echo "move_backup $ARQUIVO_ATUAL.tmp $ARQUIVO_ATUAL"
	else
		cat $ARQUIVO_ATUAL | grep -v -w PROXIMO_BACKUP_$tipo > $ARQUIVO_ATUAL.tmp
		echo "PROXIMO_BACKUP_$tipo=$time" >>  $ARQUIVO_ATUAL.tmp
		##Verifica se o arquivo .tmp tem mais de uma linha, para evitar que a 
		##configuração seja apagada
		local lines_in_file=`cat ${ARQUIVO_ATUAL}.tmp | wc -l`
		if [ "$lines_in_file" -le "10" ]
		then
			if [ $count -gt $COPY_RETRY_TIMES ]
			then
				erro "Falha ao atualizar o próximo backup [${ARQUIVO_ATUAL}] [$count]"
				rm -rf ${ARQUIVO_ATUAL}.tmp 
				clear_backup $tipo
				return 1
			else
				mensagem "Falha ao atualizar o próximo backup [${ARQUIVO_ATUAL}] [$count]" WARN
				rm -rf ${ARQUIVO_ATUAL}.tmp
				count=$(($count+5))
				sleep $count
				atualiza_proximo_backup $tipo $time $count
			fi
		else
			move_backup ${ARQUIVO_ATUAL}.tmp $ARQUIVO_ATUAL
		fi
	fi
}

function faz_backup
{
	local tipo_backup=$1

	obtem_variavel "BACKUP_$tipo_backup" "no"
	if [ "$REPLY" = "no" ]
	then
		REPLY=false
		return
	fi
	
	ARQUIVO_PID=${TMP_DIR}/backup_${tipo_backup}_${MODULO}.pid
	#Verificar se o pid existe
	if [ -f "$ARQUIVO_PID" ]
	then
		local pid=`cat $ARQUIVO_PID`
		local is_running=`ps -p ${pid} -o pid=`
		if [ $is_running ]
		then
			mensagem "Backup em execução" INFO
			#Existe, então verifico o tempo de execução pela data do arquivo
			local exec_times=`date -r $ARQUIVO_PID +%s`
			local time_delta=`expr $now - $pid_time`
			if [ $time_delta -ge $EXECUTION_TIMEOUT ]
			then
				#Tempo de execução superou o máximo repetido, matando o processo
				local pid_group=`ps -p ${pid} -o ppid=`
				atualiza_proximo_backup $tipo_backup 0
				proximo_backup=0
				mensagem "O script ultrapassou o tempo máximo de execução" ERRO
				local junk=`kill -${pid_group} 2>>$ARQUIVO_LOG`
			else
				REPLY="false"
				return
			fi
		else
			#Não existe, limpo o arquivo pid
			remove_backup $ARQUIVO_PID
		fi
	fi
	
	#Verificando a data do ultimo backup			
	local now=`date +%s`
	obtem_variavel "PROXIMO_BACKUP_$tipo_backup" "0"
	local proximo_backup=$REPLY
	
	if [ $now -ge "$proximo_backup" ]
	then
		mensagem "Iniciando o backup $tipo do $COMANDO_BACKUP" INFO
		if [ "$DEBUG" = "yes" ]
		then
			echo echo $$ > $ARQUIVO_PID
			#echo "atualiza_proximo_backup $tipo_backup $DISABLE_BACKUP_STR"
		else
			#Escrevendo o pid do backup
			echo $$ > $ARQUIVO_PID
			#atualiza_proximo_backup $tipo_backup $DISABLE_BACKUP_STR
		fi
		TIPO_BACKUP=$tipo_backup
		REPLY="true"
	else
		REPLY="false"
	fi
}

function transfere_backup
{
	local dir=$1
	
	obtem_variavel "TRANSFERE_BACKUP"
	if [ "$REPLY" = "yes" ]
	then
		obtem_variavel "COMANDO_TRANSFERE_BACKUP"
		mensagem "Transferindo backup $REPLY $dir"
		if [ "$DEBUG" = "yes" ]
		then
			echo "$PLUNGIN_DIR/$REPLY $dir"
		else
			comando=`$PLUNGIN_DIR/$REPLY -l $dir 2>>$ARQUIVO_LOG_ERRO`
		fi
		return $?
	fi
}

function obtem_proximo_backup_semanal
{
	local dia_semana=$1
	local hora=$2
	
	local data_backup=`date -d"$dia_semana" +%F`
	if [ "$DATA_ATUAL" = "$data_backup" ]
	then
		REPLY=`date -d"+1 Week $hora" +%s`
	else
		REPLY=`date -d"$dia_semana $hora" +%s`
	fi
}

function obtem_data_antiga_backup_semanal
{
	local dia_semana_backup=$1
	local manter_backup=$2
	
	local num_dia_semana=`date -d" $DATA_ATUAL" +%w`
	local num_dia_semana_backup=`date -d" $dia_semana_backup" +%w`
	local delta_dias=`expr $num_dia_semana_backup - $num_dia_semana`
	if [ "$delta_dias" = "0" ]
	then
		REPLY=`date -d" $DATA_ATUAL -$manter_backup Week" +%F`
	fi
	if [ $delta_dias -gt 0 ]
	then
		delta_dias=`expr $delta_dias - 7`
		REPLY=`date -d" $DATA_ATUAL -$manter_backup Week $delta_dias Day" +%F`
	else
		REPLY=`date -d" $DATA_ATUAL -$manter_backup Week $delta_dias Day" +%F`
	fi
}

function obtem_data_atual_backup_semanal 
{
	local dia_semana_backup=$1
	
	local num_dia_semana=`date -d" $DATA_ATUAL" +%w`
	local num_dia_semana_backup=`date -d" $dia_semana_backup" +%w`
	local delta_dias=`expr $num_dia_semana_backup - $num_dia_semana`
	if [ "$delta_dias" = "0" ]
	then
		REPLY=$DATA_ATUAL
		return
	fi
	if [ $delta_dias -gt 0 ]
	then
		delta_dias=`expr $delta_dias - 7`
		REPLY=`date -d" $DATA_ATUAL $delta_dias Day" +%F`
	else
		REPLY=`date -d" $DATA_ATUAL $delta_dias Day" +%F`
	fi
}

function obtem_data_backup_mensal 
{
	local dia_mes_backup=$1
		
	local dia_atual=`date +%d`
	local mes_atual=`date +%m`
	local ano_atual=`date +%Y`
	local data="$ano_atual"-"$mes_atual"-"$dia_mes_backup"
	if [ $dia_atual -ge $dia_mes_backup ]
	then	
		REPLY=$data
	else
		REPLY=`date -d "$data -1 Month" +%F`	
	fi
}


function obtem_data_backup_anual 
{
	local data_anual_backup=$1
	
	local dia=`echo $data_anual_backup | cut -f1 -d/`
	local mes=`echo $data_anual_backup | cut -f2 -d/`
	local ano=`date +%Y`
	local data_backup=$ano-$mes-$dia
	local data_backup_time=`date -d"$data_backup" +%s`
	local data_atual=`date +%s`
	local delta_data=`expr $data_atual - $data_backup_time`
	
	if [ $delta_data -ge 0 ]
	then
		REPLY=$data_backup
	else
		REPLY=`date -d"$data_backup -1 Year" +%F`
	fi 
}

function obtem_data_proximo_backup
{
	local tipo=$1
	obtem_variavel "HORA_BACKUP" "00:00"
	local hora_backup=$REPLY
	case "$tipo" in
		"DIARIO")
			REPLY=`date -d"+1 Day $hora_backup" +%s`
		;;
		"SEMANAL")
			obtem_variavel "DIA_SEMANA_BACKUP" ""
			dia_semana=$REPLY
			obtem_proximo_backup_semanal $dia_semana $hora_backup
			REPLY=$REPLY
		;;
		"MENSAL")
			obtem_variavel "DIA_MES_BACKUP" "20"
			local dia_mes_backup=$REPLY
			obtem_data_backup_mensal $dia_mes_backup
			local data=$REPLY
			REPLY=`date -d "$data +1 Month $hora_backup" +%s`
		;;
		"ANUAL")
			obtem_variavel "DATA_BACKUP_ANUAL" "31/12"
			local data_anual_backup=$REPLY
			obtem_data_backup_anual $data_anual_backup
			local data=$REPLY
			REPLY=`date -d "$data +1Year $hora_backup" +%s`
		;;
		*)
			erro "Tipo de backup vazio ou inválido: $tipo"
		;;
	esac
}

function obtem_nome_arquivo
{
	local tipo=$1
	local modulo=$MODULO
	local extensao=$EXTENSAO_BACKUP
	
	case "$tipo" in
		"DIARIO")
			local dia_semana=`date +%A`
			local str_data="Diario-$DATA_ATUAL-$dia_semana"
			REPLY=bck_"$modulo"_"$str_data"."$extensao"
		;;
		"SEMANAL")
			#Obtendo o rótulo do backup
			obtem_variavel "DIA_SEMANA_BACKUP" ""
			local dia_semana_backup=$REPLY
			obtem_variavel "DIA_SEMANA_BACKUP" ""
			obtem_data_atual_backup_semanal $dia_semana_backup
			local str_data="Semanal-$REPLY-$dia_semana_backup"
			REPLY=bck_"$modulo"_"$str_data"."$extensao"
		;;
		"MENSAL")
			obtem_variavel "DIA_MES_BACKUP" "20"
			local dia_mes_backup=$REPLY
			obtem_data_backup_mensal $dia_mes_backup
			local data=$REPLY
			local nome_mes=`date -d"$data" +%B`
			local str_data="Mensal-$data-$nome_mes"
			REPLY=bck_"$modulo"_"$str_data"."$extensao"
		;;
		"ANUAL")
			obtem_variavel "DATA_BACKUP_ANUAL" "31/12"
			local data_anual_backup=$REPLY
			obtem_data_backup_anual $data_anual_backup
			local data=$REPLY
			local str_data="Anual-$data"
			REPLY=bck_"$modulo"_"$str_data"."$extensao"
		;;
		*)
			erro "Tipo de backup vazio ou inválido: $tipo"
		;;
	esac
}

function remove_backup_antigo
{
	local tipo=$1
	local bckp_dir=$2
	local nome_arquivo_atual=$3
	local modulo=$MODULO
	local extensao=$EXTENSAO_BACKUP
	
	case "$tipo" in
		"DIARIO")
			obtem_variavel "MANTER_BACKUP_DIARIO" "7"
			local manter_backup_diario=$REPLY
			#local data_antiga=`date -d"$DATA_ATUAL -$manter_backup_diario Days" +%F`
			local dia_semana_antiga=`date -d"$DATA_ATUAL -$manter_backup_diario Days" +%A`
			#local str_data_antiga="Diario-$data_antiga-$dia_semana_antiga"
			local str_data_antiga="Diario-*-$dia_semana_antiga"
			local nome_arquivo_antigo=bck_"$modulo"_"$str_data_antiga"."$extensao"
		;;
		"SEMANAL")
			obtem_variavel "DIA_SEMANA_BACKUP" ""
			local dia_semana_backup=$REPLY
			obtem_variavel "MANTER_BACKUP_SEMANAL" "4"
			obtem_data_antiga_backup_semanal $dia_semana_backup $REPLY 
			local data_antiga=$REPLY
			local str_data_antiga="Semanal-$data_antiga-$dia_semana_backup"
			local nome_arquivo_antigo=bck_"$modulo"_"$str_data_antiga"."$extensao"
		;;
		"MENSAL")
			obtem_variavel "DIA_MES_BACKUP"
			local dia_mes_backup=$REPLY
			obtem_data_backup_mensal $dia_mes_backup
			local data=$REPLY
			obtem_variavel "MANTER_BACKUP_MENSAL" "12"
			local manter_backup_mensal=$REPLY
			#local data_antiga=`date -d "$data -$manter_backup_mensal Month" +%F`
			#local nome_mes_antigo=`date -d"$data_antiga" +%B`
			local nome_mes_antigo=`date -d "$data -$manter_backup_mensal Month" +%B`
			local str_data_antiga="Mensal-*-$nome_mes_antigo"
			#local str_data_antiga="Mensal-$data_antiga-$nome_mes_antigo"
			local nome_arquivo_antigo=bck_"$modulo"_"$str_data_antiga"."$extensao"
		;;
		"ANUAL")
			obtem_variavel "DATA_BACKUP_ANUAL" "31/12"
			local data_anual_backup=$REPLY
			obtem_data_backup_anual $data_anual_backup
			local data=$REPLY
			obtem_variavel "MANTER_BACKUP_ANUAL" "3"
			local data_antiga=`date -d "$data -$REPLY Year" +%F`
			local str_data_antiga="Anual-$data_antiga"
			local nome_arquivo_antigo=bck_"$modulo"_"$str_data_antiga"."$extensao"
		;;
		*)
			erro "Tipo de backup vazio ou inválido: $tipo"
		;;
	esac
	if [ ! "$nome_arquivo_antigo" ]
	then
		erro "Não foi possivel obter o nome do backup antigo"
	fi
	for i in `ls $bckp_dir/$nome_arquivo_antigo 2>>$ARQUIVO_LOG | grep -v $nome_arquivo_atual`
	do
		mensagem "Removendo backup antigo $i" INFO
		remove_backup $i
		verifica_execucao $? "Erro ao remover $bckp_dir/$nome_arquivo_antigo do Módulo $modulo" "WARN"
	done
}


function doBackup 
{
	local tipo=$1
	
	faz_backup $tipo
	if [ "$REPLY" = "true" ]
	then
		backup_runs=$(($backup_runs+1))
		local modulo=$MODULO
		local comando=$COMANDO_BACKUP
			
		#Obtendo o nome do arquivo do backup
		obtem_nome_arquivo $tipo
		local nome_arquivo=$REPLY
			
		if [ ! "$LAST_BACKUP_FILE_NAME" ]
		then				
			#Executando o comando de backup
			if [ "$DEBUG" = "yes" ]
			then
				echo "eval \"$PLUNGIN_DIR/$comando -f \"$TMP_DIR/${nome_arquivo}\""
			else
				mensagem "Executando $PLUNGIN_DIR/$comando -f $TMP_DIR/${nome_arquivo}"
				junk=`eval "$PLUNGIN_DIR/$comando -f \"$TMP_DIR/${nome_arquivo}\"" 2>>$ARQUIVO_LOG_ERRO >> $ARQUIVO_LOG`
				verifica_execucao $? "Erro ao executar $PLUNGIN_DIR/$comando -f $TMP_DIR/${nome_arquivo} do Módulo $modulo"
				if [ $? -ne 0 ]
				then
					return 1
				fi
				atualiza_permissao_backup $TMP_DIR/${nome_arquivo} $BACKUP_FILE_PERMISSION
				verifica_execucao $? "Erro ao atualizar permissões em $nome_arquivo do Módulo $modulo" "WARN"
				atualiza_grupo_backup $TMP_DIR/${nome_arquivo}
				verifica_execucao $? "Erro ao trocar o grupo de $nome_arquivo do Módulo $modulo" "WARN"
			fi
		else
			move_backup "$LAST_BACKUP_FILE_NAME" "$TMP_DIR/${nome_arquivo}"
			verifica_execucao $? "Erro ao mover $LAST_BACKUP_FILE_NAME para $TMP_DIR/${nome_arquivo}"
			if [ $? -ne 0 ]
			then
				return 1
			fi
			atualiza_permissao_backup $TMP_DIR/${nome_arquivo} $BACKUP_FILE_PERMISSION
			verifica_execucao $? "Erro ao atualizar permissões em $nome_arquivo do Módulo $modulo" "WARN"
			atualiza_grupo_backup $TMP_DIR/${nome_arquivo}
			verifica_execucao $? "Erro ao trocar o grupo de $nome_arquivo do Módulo $modulo" "WARN"
		fi
		
		mensagem "Execução Ok"
		
		#Verificando diretório de backup
		local bckp_dir=$BACKUP_DIR
		verifica_diretorio $bckp_dir
		
		#Copiando backup para o diretótio de backup
		copy_backup "$TMP_DIR/$nome_arquivo" "$bckp_dir"
		verifica_execucao $? "Erro ao copiar "$TMP_DIR/$nome_arquivo" para $bckp_dir" "ERRO"
		if [ $? -ne 0 ]
		then
			return 1
		fi
		
		#Removendo backup antigo
		remove_backup_antigo $tipo $bckp_dir $nome_arquivo
		
		LAST_BACKUP_FILE_NAME="$TMP_DIR/$nome_arquivo"
		
		#Tranferindo backup
		transfere_backup $bckp_dir
		verifica_execucao $? "Erro ao transferir $bckp_dir do Módulo $modulo" "WARN"
		
		#Agendando próximo Backup
		obtem_data_proximo_backup $tipo
		local proximo_backup=$REPLY
		atualiza_proximo_backup $tipo $proximo_backup 
		
		#Mandando email
		if [ "$ERRO_LOG" ]
		then
			manda_email "Erro no backup $tipo do $modulo devido aos seguintes erros:\n$ERRO_LOG"
			ERRO_LOG=''
		fi
		obtem_variavel MANDA_EMAIL_WARN "yes"
		local mail_warn=$REPLY
		obtem_variavel MANDA_EMAIL_INFO "no"
		local mail_info=$REPLY
		obtem_variavel MANDA_EMAIL_SUCESSO "no"
		local mail_success=$REPLY
		
		if [ "$mail_warn" = "yes" ]
		then
			if [ "$WARN_LOG" ]
			then
				manda_email "Backup $tipo do $modulo realizado, mas com os seguintes alertas\n$WARN_LOG"
			fi
		fi
		if [ "$mail_info" = "yes" ]
		then
		if [ "$INFO_LOG" ]
			then
				manda_email "Backup $tipo do $modulo realizado\n$INFO_LOG"
			fi
		fi
		if [ "$mail_success" = "yes" ]
		then
			manda_email "Backup $tipo do $modulo realizado com sucesso"
		fi
		
		#Finalizando o backup
		REPLY=''
		remove_backup $ARQUIVO_PID
		mensagem "Backup $tipo do $modulo finalizado com sucesso\n"
		WARN_LOG='';
		INFO_LOG='';
	fi
}
			
trap interrupt KILL TERM INT
backup_runs=0
for i in `ls $CONF_DIR/*.conf`
do
	##Máximo de 5 porcessos
	if [ "$backup_runs" -le "$MAX_BACKUP_RUNS" ]
	then

		ARQUIVO_ATUAL=$i
		##Carregando configuração geral	
		if [ ! "$MASTER_DEBUG" = "enabled" ]
		then
			obtem_variavel "DEBUG" "no"
			DEBUG=$REPLY
		else
			DEBUG=yes
			MAX_BACKUP_RUNS=5000
		fi
	
		obtem_variavel "LOCALE" "pt_BR.UTF-8"
		LOCALE=$REPLY
		export LANG=$LOCALE
		obtem_variavel "BACKUP_DIR"
		BACKUP_DIR=$REPLY
		obtem_variavel "MODULO" ""
		MODULO=$REPLY
		obtem_variavel "EXTENSAO_BACKUP" ""
		EXTENSAO_BACKUP=$REPLY
		obtem_variavel "COMANDO_BACKUP" ""
		COMANDO_BACKUP=$REPLY
	
		LAST_BACKUP_FILE_NAME=""
		TIPO_BACKUP=""
		TIPO_BACKUP=DIARIO 
		doBackup DIARIO 
		TIPO_BACKUP=SEMANAL
		doBackup SEMANAL
		TIPO_BACKUP=MENSAL
		doBackup MENSAL
		TIPO_BACKUP=ANUAL
		doBackup ANUAL
		TIPO_BACKUP=""
		if [ "$LAST_BACKUP_FILE_NAME" ]
		then
			rm -rf $LAST_BACKUP_FILE_NAME 2>> $ARQUIVO_LOG >> $ARQUIVO_LOG
		fi

		LAST_BACKUP_FILE_NAME=""
	
		if [ "$USER"=root ]
		then
			chown $BACKP_USERNAME:$BACKP_GROUP $ARQUIVO_ATUAL 2>>$ARQUIVO_LOG
    	fi
	fi
done

#Mandando email
if [ "$ERRO_LOG" ]
then
	manda_email "Erro no backup $tipo do $modulo devido aos seguintes erros:\n$ERRO_LOG"
	ERRO_LOG=''
fi
		
if [ "$SEND_MAIL_WARN" = "yes" ]
then
	if [ "$WARN_LOG" ]
	then
		manda_email "Backup $tipo do $modulo realizado, mas com os seguintes alertas\n$WARN_LOG"
	fi
fi

if [ "$SEND_MAIL_INFO" = "yes" ]
then
	if [ "$INFO_LOG" ]
	then
		manda_email "Backup $tipo do $modulo realizado\n$INFO_LOG"
	fi
fi
		
if [ "$SEND_MAIL_SUCESS" = "yes" ]
then
	manda_email "Backup $tipo do $modulo realizado com sucesso"
fi

ERRO_LOG=''
WARN_LOG=''
INFO_LOG=''
