#!/bin/sh

# Funcoes
	_abort(){ echo; echo "** Falhou: $1"; echo; exit $2; }

# Constantes
	allrosversions="
		7.6
		7.7beta3
		7.3.1
		6.49.6
		5.25
		4.17
		3.30
	"

# x - pre-requisitos
	[ -x /opt/qemu/bin/qemu-img ] || _abort "Binario vital nao encontrado: /opt/qemu/bin/qemu-img"

# 0 - processar parametros
	rosver=""
	forceyes=2
	for arg in $@; do
		# opcoes
		[ "$arg" = "yes" -o "$arg" = "-y" -o "$arg" = "renew" ] && forceyes=1 && continue
		[ "$arg" = "add" -o "$arg" = "-a" ] && forceyes=2 && continue

		# numero de versao
		# - instalar todas as versoes
		[ "$arg" = "all" ] && rosver="$rosver $allrosversions" && continue
		# - versao sugerida
		echo "$arg" | egrep '^[0-9]+\.[0-9]+(\.[0-9]+)?' >/dev/null || _abort "O que significa isso: [$arg] ??"
		rosver="$rosver $arg"
	done
	rosver=$(echo $rosver)
	[ "x$rosver" = "x" ] && _abort "Informe pelo menos uma versao, exemplo: 6.34.1" 6

	_install_version(){
	ver="$1"
	[ "x$ver" = "x" ] && return 99

	# 1 - verificar se ja existe
		rundir="/opt/unetlab/addons/qemu/mikrotik-$ver"
		if [ -d "$rundir" ]; then
			if [ "$forceyes" = "2" ]; then
				echo "** IMAGEM JA INSTALADA: $ver"
				return 1
			fi
			if [ "$forceyes" = "0" ]; then
				echo
				echo "** O diretorio $rundir ja existe."
				echo "** Deseja remove-lo e instalar novamente?"
				echo -n "** Responsa SIM ou NAO: "; read rp
				r="nao"
				[ "$rp" = "s" -o "$rp" = "y" -o "$rp" = "S" -o "$rp" = "Y" ] && r="sim"
				[ "$rp" = "si" -o "$rp" = "ye" -o "$rp" = "SI" -o "$rp" = "YE" ] && r="sim"
				[ "$rp" = "sim" -o "$rp" = "yes" -o "$rp" = "SIM" -o "$rp" = "YES" ] && r="sim"
				[ "$rp" = "nao" ] && return 2
			fi
		fi
		# apagar se existir
		rm -rf "$rundir" 2>/dev/null

	# 2 - download da imagem do site da mititiki
		url="https://download.mikrotik.com/routeros/$ver/chr-$ver.vmdk"

		echo "** Versao: $ver"
		echo "** URL...: $url"
		sleep 1

		echo "** Baixando..."
		outfile="/tmp/chr-$ver.vmdk"
		rm -f $outfile 2>/dev/null
		wget --tries=9 --read-timeout=5 \
			$url \
			-O $outfile; wr="$?"
    if [ "$wr" != "0" ]; then
      echo "** Erro $? ao baixar [$url] para [$outfile]"
      return 3
		fi

		echo "** Download concluido: $outfile"

	# 3 - converter para qCow2
		echo "** Criando diretorio do profile"
		mkdir -p "$rundir" || _abort "Erro $? ao criar diretorio [$rundir]"
		qcow2file="$rundir/hda.acow2"
		echo "** Convertendo [$outfile] para [$qcow2file]"
		/opt/qemu/bin/qemu-img convert -f vmdk -O qcow2 "$outfile" "$qcow2file" || _abort "Erro $? ao converter vmdk"

	# 4 - ajustando permissoes
		echo "** Ajustando permissoes"
		/opt/unetlab/wrappers/unl_wrapper -a fixpermissions
	}

# Instalar versoes instruidas pelo usuario
	echo "Iniciando"
	for rosv in $rosver; do
		echo "* Instalando: $rosv"
		_install_version "$rosv"
	done
	echo "Concluido"


