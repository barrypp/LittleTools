$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path
Import-Module ./5-plot.psm1

$vmaf = @{}
ls -Filter '1/*.cbz' | ForEach-Object {
    7z x $_.FullName -o"2/tmp"
    mkdir 3/tmp

    mv 2/tmp/*.mkv 3/tmp/
    mv 2/tmp/*.gif 3/tmp/
#    mv 2/tmp/*.jxl 3/tmp/

    $vmaf[$_.Name] = @{Frame=@();vmaf=@()}
    $key = $_.Name;
    ls -Filter '2/tmp/*' | foreach-Object -Parallel {
        $vmaf = $using:vmaf
        $key = $using:key
        mogrify -path ./3/tmp -quality 90 -format jxl "2/tmp/$($_.Name)"
        $a = Split-Path $_ -LeafBase
        $b = Split-Path $_ -Leaf
        ffmpeg -hide_banner -loglevel warning -i "./3/tmp/$a.jxl" -i "$_" -lavfi "[0:v]setpts=PTS-STARTPTS[dis];[1:v]setpts=PTS-STARTPTS[ref];[dis][ref]libvmaf=n_threads=8:feature='name=psnr|name=float_ssim':model=path='model/vmaf_4k_v0.6.1.json':log_fmt=csv:log_path=3/1.vmaf.csv" -f null -
        $c = Import-Csv 3/1.vmaf.csv
        "$b to jxl {0:F}kB {1:F}kB $($c.vmaf)" -f ($_.length/1kB),((ls "./3/tmp/$a.jxl").length/1kB)
        $vmaf[$key].Frame = $vmaf[$key].Frame + $c.Frame # thread non safe ?
        $vmaf[$key].vmaf = $vmaf[$key].vmaf + $c.vmaf
    } -ThrottleLimit 4
    

    "2/tmp {0:F}MB" -f ((ls 2/tmp | measure length -sum).Sum/1MB)
    "3/tmp {0:F}MB" -f ((ls 3/tmp | measure length -sum).Sum/1MB)

    7z a -mx0 -tzip "3/$($_.Name)" ./3/tmp/*

    rm -R -Force 2/tmp
    rm -R -Force 3/tmp
}

plot_vmaf($vmaf)
#Read-Host -Prompt "Press any key to continue"