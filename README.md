# LittleTools
Little Tools

## resize linux virtual disk file
```
### create
truncate -s 1G a.ext4; mkfs.ext4 a.ext4
### extend 
truncate -s 2G a.ext4; e2fsck -f a.ext4; resize2fs a.ext4
### shrink 
e2fsck -f a.ext4; resize2fs a.ext4 500M; truncate -s 500M a.ext4;
```

## wsl --unregister and --import and --set-default
```
wsl --unregister ubuntu-21.10
wsl --import ubuntu-21.10 . ubuntu-wsl_21.10.tar
wsl --set-default ubuntu-21.10
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

## CloseUnwantedProcess.txt
```
Get-Process GPUTweakII | Foreach-Object { $_.CloseMainWindow() | Out-Null; stop-process -Force -Name $_.Name }

powershell -windowstyle hidden -command "sleep 1; "
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
