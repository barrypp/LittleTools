# LittleTools


## Other
```
pwd;ls | select-object name #前面的pwd会改变分号后面命令的输出格式
ls -Directory | % {copy .\desktop.ini $_} #把子目录配置为相同的类型

Get-Process GPUTweakII | % { $_.CloseMainWindow() | Out-Null; stop-process -Force -Name $_.Name } #CloseUnwantedProcess
Start-Process -Credential ([pscredential]::new('test', ('test' | ConvertTo-SecureString -AsPlainText -Force))) -WorkingDirectory ./ ./1.EXE #runas
cmd /c start /min "" powershell -WindowStyle Hidden -File "1.ps1" #run script Hidden
crontab -e

(Get-PSDrive).Name -match '^[a-z]$' | % {manage-bde.exe ("$_"+":") -protectors -get -Type Certificate } | sls -Pattern "[0-9a-f]{40}" #get bitlocker drive Certificate
Get-Childitem -r -Path ./* -Include *.exe | % {"`"{0}`" " -f (Resolve-Path -Relative $_) | Write-Host -NoNewline} #get-all-exe-path
lsof -i -sTCP:LISTEN

New-VirtualDisk -StoragePoolFriendlyName 存储池 -FriendlyName T4 -ResiliencySettingName simple -Size 1GB -ProvisioningType Thin -NumberOfColumns 4 #storage pool

Set-VMSwitch WSL -NetAdapterName '以太网' #bridge wsl to LAN
```

## powershell wake-on-lan
```
#based on https://www.pdq.com/blog/wake-on-lan-wol-magic-packet-powershell/
$Mac = "FF:FF:FF:FF:FF:FF"
$MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect(([System.Net.IPAddress]("192.168.1.255")),7)
$UdpClient.Send($MagicPacket,$MagicPacket.Length)
$UdpClient.Close()
```

## nftables router
```
/etc/nftables.conf

nft flush ruleset
nft add table nat
nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
nft add rule nat postrouting ip saddr 192.168.1.0/24 iif eth0 masquerade
nft list ruleset

table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		ip saddr 192.168.1.0/24 iif "eth0" masquerade
	}
}
```

## set mtu
```
netsh interface ipv4 show subinterface
netsh interface ipv4 set subinterface "以太网" mtu=1500
ip link set dev eth0 mtu 1500
```

## ykman
```
$key=Read-Host -MaskInput
$pin=Read-Host -MaskInput
$slot = ""
$pin_policy = ""
$touch_policy = ""

ykman piv info

#bitlocker cert (cannot use "--pin-policy ALWAYS")
ykman piv certificates delete -P $pin -m $key $slot
ykman piv keys generate -P $pin -m $key -a RSA2048 -F PEM --touch-policy $touch_policy $slot pub.pem
ykman piv certificates generate -P $pin -m $key -s "Barrypp.zzx's bitlocker" -d 36500 -a SHA512 $slot pub.pem
rm pub.pem

#SSH cert
ykman piv certificates delete -P $pin -m $key $slot
ykman piv keys generate -P $pin -m $key -a ECCP384 -F PEM --pin-policy $pin_policy --touch-policy $touch_policy $slot pub.pem
ykman piv certificates generate -P $pin -m $key -s "Barrypp" -d 36500 -a SHA512 $slot pub.pem
rm pub.pem
```


## png jpg webp
```
parallel zopflipng -m --keepchunks=iTXt --prefix ::: *.png
parallel mogrify -quality 99 -format jpg ::: *.png
wsl identify -verbose *.jpg `| grep 'Qua'
mogrify -resize 3840x2160 -format jpg -quality 99 *.jpg
```

## png to jpg quality99 in zip (webp解码比jpg慢，体积比jpg小)
```
$env:Path = 'C:\Program Files\7-Zip;' + $env:Path
$a = ls -Filter '*.zip'
mv -LiteralPath $a -Destination from.zip
7z x from.zip -ofrom
mkdir to
wsl parallel mogrify -path ./to -quality 99 -format jpg ::: ./from/*/*/*
7z a -mx0 -tzip "$a" ./to/*
```

## resize linux virtual disk file
```
truncate -s 1G a.ext4; mkfs.ext4 a.ext4 #create
truncate -s 2G a.ext4; e2fsck -f a.ext4; resize2fs a.ext4 #extend 
e2fsck -f a.ext4; resize2fs a.ext4 500M; truncate -s 500M a.ext4; #shrink 
```

## wsl --unregister and --import and --set-default
```
wsl --unregister ubuntu-21.10
wsl --import ubuntu-21.10 . ubuntu-wsl_21.10.tar
wsl --set-default ubuntu-21.10
```

## all magnet
```
$("a.download-arrow").each((i,x)=>{console.log(x.href)})
$("i.fa-magnet").parent().each((i,x)=>{console.log(x.href)})
```

## subtitle.txt
```
zzx=$("[tm='Jons0']").children(".first").children("a")  
zzx.forEach((x)=>{window.open(x.href.replace("detail","dld"))})
$("div.title").text()
```
  
## subtitle2
```
z=$$("[id='aewf']")  
for (let i = 0; i != z.length; i++) {  
  setTimeout(() => z[i].click(), 5000 * i)  
}
```

## Disclosure
```
<div id="wrapper" style="position: relative; height: 6808px; overflow: hidden;" >
  ->
<div id="wrapper" style="position: relative; height: 6808px;" >
```

## Extended,右键菜单配置
```
HKEY_CLASSES_ROOT\Directory\Background\shell
```


# CA by Yubikey & openSSL

## usbip
```
usbipd list
usbipd bind --force -i 1050:0407
usbipd unbind --all

modprobe -a usbip_core usbip_host vhci_hcd
usbip attach -r barrypp -b 4-4
```

## ykman & openssl  
```
#
read -s pin
read -s key
systemctl start pcscd
ykman piv info

CA
ykman piv keys generate -P $pin -m $key -a ECCP384 -F PEM --pin-policy ALWAYS --touch-policy ALWAYS 9c CA-pub.pem
ykman piv certificates generate -P $pin -m $key -s "Barrypp.zzx's CA" -d 36500 -a SHA512 9c CA-pub.pem
ykman piv certificates export -F PEM 9c CA-cert.pem
openssl x509 -text < CA-cert.pem

EE
openssl genpkey -algorithm ED448 -out EE-private.pem
openssl req -sha512 -new -config EE-csr.conf -key EE-private.pem -out EE-csr.pem
openssl req -text -verify -in EE-csr.pem

EE2
openssl genrsa -out EE2-private.pem 4096
openssl req -sha256 -new -config EE-csr.conf -key EE2-private.pem -out EE2-csr.pem
openssl req -text -verify -in EE2-csr.pem

EE3
openssl req -x509 -newkey rsa:4096 -nodes -out EE3-cert.pem -keyout EE3-private.pem -days 365

Sign
PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl x509 -engine pkcs11 -CAkeyform engine -CAkey "pkcs11:object=Private key for Digital Signature;type=private"  -sha512 -CA CA-cert.pem -req -in EE-csr.pem -extfile EE-cert.conf -out EE-cert.pem  -days 365
PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl x509 -engine pkcs11 -CAkeyform engine -CAkey "pkcs11:object=Private key for Digital Signature;type=private"  -sha256 -CA CA-cert.pem -req -in EE2-csr.pem -extfile EE-cert.conf -out EE2-cert.pem  -days 365
openssl x509 -text < EE-cert.pem
```

# opensource-build-script

## gdb
```
export PATH=/opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin:$PATH
#
./configure --host=arm-none-linux-gnueabihf --prefix=/mnt/f/Others/gdb/gdb-10.1_ins
./configure --host=arm-none-linux-gnueabihf --prefix=/mnt/f/Others/gdb/gdb-10.1_ins_static CXXFLAGS="-static"
make -j 8
make install
```

## boost
```
# windows
bootstrap.bat
.\b2.exe -j 8 --prefix=../boost_1_77_0_win install
# wsl
bootstrap.sh
./b2 -j 8 --prefix=../boost_1_77_0_wsl install
```

# ubuntu base config

## other
```
sshd_config: AuthenticationMethods publickey
/etc/systemd/network: "Example 1. Static network configuration" (https://www.freedesktop.org/software/systemd/man/systemd.network.html)
/etc/systemd/resolved.conf: LLMNR=yes
/etc/sysctl.conf: net.ipv4.ip_forward=1
```
