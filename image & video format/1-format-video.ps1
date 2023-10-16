$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path
Import-Module ./5-plot.psm1
#ffmpeg -hide_banner -h encoder=hevc_nvenc
#ffmpeg -hide_banner -filters
#ffprobe -show_frames p7.mkv > 1.txt

$a = (ls 1/*)[0]
ffmpeg -hide_banner -loglevel warning -y -hwaccel d3d11va -ss "00:00:00" -t "00:00:1" -i $a -map 0:v -c:v hevc_nvenc -preset p7 -tune lossless -pix_fmt p010le -profile:v main10 2/test.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K 3/p7_cq__.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K -cq 26 3/p7_cq26.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v libx265 -crf 18 -preset slow 3/slow_crf18.mkv

"2/test.mkv"
ffprobe -hide_banner  -i 2/test.mkv 2>&1 | sls bitrate

$vmaf = @{}
ls 3/*.mkv | ForEach-Object {
    $_.FullName
    ffprobe -hide_banner -i $_ 2>&1 | sls bitrate
    ffmpeg -hide_banner -i $_ -i 2/test.mkv -lavfi "[0:v]setpts=PTS-STARTPTS[dis];[1:v]setpts=PTS-STARTPTS[ref];[dis][ref]libvmaf=n_threads=8:feature='name=psnr|name=float_ssim':model=path='model/vmaf_4k_v0.6.1.json':log_fmt=csv:log_path=3/$($_.name).vmaf.csv" -f null - 2>&1 | sls -Pattern '(Parsed|error)'
    $b = Import-Csv 3/$($_.name).vmaf.csv
    $vmaf[$_.Name] = $b
}

plot_vmaf($vmaf)
#Read-Host -Prompt "Press any key to continue"