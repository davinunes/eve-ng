# eveunl

EVE / Unified Net Labs, scripts, addons, plugins, etc...

Script automatizador interativo. Instalar principais ferramentas no Linux
e atualiza todo o sistema (pode demorar dependendo da sua banda internacional)

### Como rodar:

1 - Baixe o EVE-NG Community Edition

2 - Instale-o e configure-o na rede, garanta o funcionamento dele na Internet

3 - Execute:

```

  wget https://raw.githubusercontent.com/davinunes/eve-ng/master/eve-prepare.sh -O /root/eve-prepare.sh

  chmod +x /root/eve-prepare.sh

  /root/eve-prepare.sh

```

4 - Ative o IOURC antes de criar ou executar qualquer roteador Cisco IOL:

```
  cd /root/
  wget https://raw.githubusercontent.com/patrickbrandao/eveunl/master/CiscoKeyGen.py -O /root/CiscoKeyGen.py
  chmod +x /root/CiscoKeyGen.py
  
  # Execute:
  /root/CiscoKeyGen.py
  
  # Observe a saida na tela, copie os comandos que começam com:
  # "echo -e" e "grep -q"
  # e cole-os na linha de comando

```

5 - Pronto. Pode usar normalmente.


### Criando imagem VyOS para EVE-NG no MACOS

####	Gerando arquivo VDI no VirtualBox

1 - Crie uma maquina virtual no VirtualBox com apenas 1 interface de rede

2 - De boot pela ISO do VyOS, usaremos a versao 1.2.3 como exemplo

3 - Ative servico basico:

```
  configure
  set service ssh
  commit; save
  exit
``` 

4 - Instale o VyOS:
``` 
  install image
``` 

5 - Desligue a VM:
``` 
  sudo poweroff
``` 

6 - Entre na pasta das VMs do VirtualBox ( ~/VirtualBox\ VMs/) e entre na pasta da VM criada

7 - Localize o arquivo com extensao .vdi (virtual box disk image) e execute:
``` 
  VBoxManage clonehd --format RAW NOME-DO-ARQUIVO.vdi vyos-1.2.3-amd64.img
``` 

8 - Converta o arquivo .img gerado acima para qcow2:

  MACOS: /Applications/GNS3.app/Contents/Resources/qemu/bin/qemu-img
  
  Caso nao possua o qemu-img no MACOS, envie o HD no formato .img para o servidor
  EVE-NG e converta-o lá. Faça compressão maxima antes de transferir:

``` 
  tar cvf - vyos-1.2.3-amd64.img | xz -T 4 -9 -e -c - > vyos-1.2.3-amd64.img.txz
  # scp vyos-1.2.3-amd64.img.txz root@x.y.z.w:/root/
``` 
  No servidor:

``` 
  # tar -xvf vyos-1.2.3-amd64.img.txz
  qemu-img convert -f raw -O qcow2 vyos-1.2.3-amd64.img vyos-1.2.3-amd64.qcow2
``` 
  Se o arquivo qcow2 for gerado, apague o arquivo .img

9 - Crie um template (pasta), mova o arquivo .qcow2 gerado para o repositorio do EVE-NG.
  É importante que o arquivo do HD se chame hda.qcow2

``` 
  mkdir -p /opt/unetlab/addons/qemu/vyos-1.2.3-amd64
  cp vyos-1.2.3-amd64.qcow2 /opt/unetlab/addons/qemu/vyos-1.2.3-amd64/hda.qcow2
``` 

10 - Concluindo, arrume as permissões:
``` 
  /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
``` 

11 - Adicione a imagem em algum lab e teste.

12 - O MAC usado no virtualbox ficou associado a eth0, e não
existe na copia gerada no EVE, entre no VyOS e execute:

``` 
id=0 
ip link show | egrep 'link.ether' | awk '{print $2}' | sort -n | while read mac; do
 eth="eth$id" 
 echo "# $eth = $mac"
 id=$(($id+1))
 echo "set interfaces ethernet $eth hw-id '$mac'"
done
``` 

Copie a saida do comando acima e cole dentro da sessao "configure", de commit, save e reinicie o VyOS

