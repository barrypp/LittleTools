$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path
Import-Module ./5-plot.psm1
#ffmpeg -hide_banner -h encoder=hevc_nvenc
#ffmpeg -hide_banner -filters
#ffprobe -v error -select_streams v:0 -show_entries stream -i 1.mkv
#ls 1/*.mkv | % { $a = Split-Path $_ -LeafBase; ffmpeg -hide_banner -y -i "$_" -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K -cq 26 "3/$a.mkv" }

$a = (ls 1/*)[0]
ffmpeg -v warning -stats -y -hwaccel d3d11va -ss "00:00:30" -t "00:00:10" -i $a -map 0:v -c:v hevc_nvenc -preset p7 -tune lossless -pix_fmt p010le -profile:v main10 2/test.mkv
ffmpeg -v warning -stats -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K 3/p7_cq__.mkv
ffmpeg -v warning -stats -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K -cq 26 3/p7_cq26.mkv
ffmpeg -v warning -stats -y -i 2/test.mkv -c:a copy -c:s copy -c:v libx265 -crf 18 -preset slow 3/slow_crf18.mkv

$bit_rate = ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of csv=s=x:p=0 -i 2/test.mkv
"2/test.mkv {0:F}Mbps" -f ($bit_rate/1Mb)

$vmaf = @{}
ls 3/*.mkv | sort | ForEach-Object {
    $bit_rate = ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of csv=s=x:p=0 -i $_
    $height = ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 -i $_
    $model = if ([int]$height -gt 1620) {":model=path='model/vmaf_4k_v0.6.1.json'"} else {""}
    ffmpeg -v warning -stats -i $_ -i 2/test.mkv  -lavfi "[0:v]setpts=PTS-STARTPTS[dis];[1:v]setpts=PTS-STARTPTS[ref];[dis][ref]libvmaf=n_threads=8'$($model):log_fmt=csv:log_path=3/$($_.name).vmaf.csv" -f null -
    $b = Import-Csv 3/$($_.name).vmaf.csv
    $vmaf[$_.Name] = $b
    "$($_.Name) {0:F}Mbps {1} $model" -f ($bit_rate/1Mb),(($b.vmaf | Sort-Object)[[int](($b.vmaf.count -1) /2)])
}

plot_vmaf($vmaf)
#Read-Host -Prompt "Press any key to continue"