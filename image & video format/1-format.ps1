$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path

ls -Filter '1/*.cbz' | ForEach-Object {
    7z x $_.FullName -o"2/tmp"
    mkdir 3/tmp

    mv 2/tmp/*.mkv 3/tmp/
    mv 2/tmp/*.gif 3/tmp/
#    mv 2/tmp/*.jxl 3/tmp/

    ls -Filter '2/tmp/*' | foreach-Object -Parallel {
        mogrify -path ./3/tmp -quality 90 -define jxl:effort -format jxl "2/tmp/$($_.Name)"
        $a = Split-Path $_ -LeafBase
        $b = Split-Path $_ -Leaf
        "$b to jxl {0:F}kB {1:F}kB" -f ($_.length/1kB),((ls ./3/tmp/$a.jxl).length/1kB)
    } -ThrottleLimit 4

    "2/tmp {0:F}MB" -f ((ls 2/tmp | measure length -sum).Sum/1MB)
    "3/tmp {0:F}MB" -f ((ls 3/tmp | measure length -sum).Sum/1MB)

    7z a -mx0 -tzip "3/$($_.Name)" ./3/tmp/*

    rm -R -Force 2/tmp
    rm -R -Force 3/tmp
}

Read-Host -Prompt "Press any key to continue"