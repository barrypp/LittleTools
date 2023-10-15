$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path

mkdir 2/tmp_dir

ls 2/*.cbz | ForEach-Object {
    mv -LiteralPath "$_" ./2/tmp_dir
    $a = Split-Path $_ -Leaf
    mkdir 2/tmp
    7z x ./2/tmp_dir/$a -o"2/tmp"
    7z a -mx0 -tzip "2/$a" "$((ls ./2/tmp/*)[0])/*"
    rm -R -Force ./2/tmp
}

Read-Host -Prompt "Press any key to continue"