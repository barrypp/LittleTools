# LittleTools
Little Tools

## resize linux virtual disk file
### create
truncate -s 1G a.ext4; mkfs.ext4 a.ext4
### extend 
truncate -s 2G a.ext4; e2fsck -f a.ext4; resize2fs a.ext4
### shrink 
e2fsck -f a.ext4; resize2fs a.ext4 500M; truncate -s 500M a.ext4;

## Google photo, 智能助理，图片方向，转变全部图片为原图
F9JLMc，Dlhxnf，p9Cv2

window.setInterval(()=>{document.querySelector(".p9Cv2").click();},100)  
  

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
Get-Process GPUTweakII | Foreach-Object { $_.CloseMainWindow() | Out-Null; stop-process -Force -Name $_.Name }

powershell -windowstyle hidden -command "sleep 1; "

## Disclosure
```
<div id="wrapper" style="position: relative; height: 6808px; overflow: hidden;" >
  ->
<div id="wrapper" style="position: relative; height: 6808px;" >
```
