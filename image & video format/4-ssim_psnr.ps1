$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path

$a = (ls 1/*)[0]

ffmpeg -hide_banner -loglevel warning -y -hwaccel d3d11va -ss "00:16:05" -t "00:00:10" -i $a -c copy 2/test.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K 3/p7.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 05M 3/p7_05M.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 10M 3/p7_10M.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 25M 3/p7_25M.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 50M 3/p7_50M.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v libx265 -preset slow 3/slow.mkv
ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v libx265 -crf 18 -preset slow 3/slow_crf18.mkv

"2/test.mkv"
ffprobe -hide_banner  -i 2/test.mkv 2>&1 | sls bitrate

ls 3/*.mkv | ForEach-Object {
    $_.FullName
    ffprobe -hide_banner -i $_ 2>&1 | sls bitrate
    ffmpeg -hide_banner -i $_ -i 2/test.mkv -lavfi "ssim;[0:v][1:v]psnr;" -f null - 2>&1 | sls Parsed
}

Read-Host -Prompt "Press any key to continue"