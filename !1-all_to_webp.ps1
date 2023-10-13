$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path

ls -Filter '1/*.cbz' | ForEach-Object {
    7z x $_.FullName -o"2/tmp"
    mkdir 3/tmp99
    mkdir 3/tmp100
    mkdir 3/tmp

    ls -Filter '2/tmp/*' | foreach-Object -Parallel {
        mogrify -path ./3/tmp99 -quality 99 -format webp "2/tmp/$($_.Name)"
        mogrify -path ./3/tmp100 -quality 100 -format webp "2/tmp/$($_.Name)"
        $a = Split-Path $_ -LeafBase
        echo "$a.webp $((ls ./3/tmp99/$a.webp).length) $((ls ./3/tmp100/$a.webp).length)"
    } -ThrottleLimit 8

    echo "2/tmp    $((ls 2/tmp | measure length -sum).Sum)"
    echo "3/tmp99  $((ls 3/tmp99 | measure length -sum).Sum)"
    echo "3/tmp100 $((ls 3/tmp100 | measure length -sum).Sum)"
    
    ls -Filter '3/tmp99/*' | foreach-Object {
        $other = "3/tmp100/$($_.Name)"
        if ($_.Length -gt (ls $other).Length){
            mv $other 3/tmp
        }
        else {
            mv $_ 3/tmp
        }     
    }

    echo "3/tmp    $((ls 3/tmp | measure length -sum).Sum)"

    7z a -mx0 -tzip "3/$($_.Name)" ./3/tmp/*

    rm -R -Force 2/tmp
    rm -R -Force 3/tmp99
    rm -R -Force 3/tmp100
    rm -R -Force 3/tmp
}

Read-Host -Prompt "Press any key to continue"