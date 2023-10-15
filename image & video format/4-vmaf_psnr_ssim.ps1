$env:Path = 'C:\Program Files\7-Zip;C:\ProgramFiles\mpv;' + $env:Path
#ffmpeg -hide_banner -h encoder=hevc_nvenc
#ffmpeg -hide_banner -filters
#ffprobe -show_frames p7.mkv > 1.txt
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class NativeMethods {
        [DllImport("dwmapi.dll", PreserveSig = false)]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
        public static void dark(IntPtr Hwnd) //Hwnd is the handle to your window
        {
            int renderPolicy = 1;
            DwmSetWindowAttribute(Hwnd, 20, ref renderPolicy, sizeof(int));
        }        
    }
"@
$Black = [System.Drawing.Color]::Black
$White = [System.Drawing.Color]::White

#$a = (ls 1/*)[0]
#ffmpeg -hide_banner -loglevel warning -y -hwaccel d3d11va -ss "00:06:40" -t "00:00:10" -i $a -an -c copy 2/test.mkv
#ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K 3/p7.mkv
#ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v hevc_nvenc -preset p7 -pix_fmt p010le -profile:v main10 -b:v 0K -cq 27 3/p7_cq27.mkv
#ffmpeg -hide_banner -loglevel warning -y -i 2/test.mkv -c:a copy -c:s copy -c:v libx265 -crf 18 -preset slow 3/slow_crf18.mkv

"2/test.mkv"
ffprobe -hide_banner  -i 2/test.mkv 2>&1 | sls bitrate

$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart_area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
$chart.ChartAreas.Add($chart_area)
$chart.Legends.Add($legend)
$chart.Dock = [System.Windows.Forms.DockStyle]::Fill
$chart_area.BackColor = $Black
$chart_area.AxisX.LineColor = $chart_area.AxisX.MajorGrid.LineColor = $chart_area.AxisX.LabelStyle.ForeColor = $White
$chart_area.AxisY.LineColor = $chart_area.AxisY.MajorGrid.LineColor = $chart_area.AxisY.LabelStyle.ForeColor = $White
$chart.BackColor = $legend.BackColor = $Black
$chart.ForeColor = $legend.ForeColor = $White

ls 3/*.mkv | ForEach-Object {
    $_.FullName
    ffprobe -hide_banner -i $_ 2>&1 | sls bitrate
    #ffmpeg -hide_banner -i $_ -i 2/test.mkv -lavfi "libvmaf=n_threads=8:feature='name=psnr|name=float_ssim':log_fmt=csv:log_path=3/$($_.name).vmaf.csv" -f null - 2>&1 | sls -Pattern '(Parsed|error)'
    $b = Import-Csv 3/$($_.name).vmaf.csv
    $chart.Series.Add($_.name) | out-null
    $chart.Series[$_.name].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $chart.Series[$_.name].Points.DataBindXY($b.Frame, $b.vmaf)
    $chart.Series[$_.name].MarkerStyle = 2;
}

$window = New-Object System.Windows.Forms.Form
[NativeMethods]::dark($window.Handle)
$window.Controls.Add($chart)
$window.Size = [System.Drawing.Size]::new(800,500)
$window.ShowDialog()

#Read-Host -Prompt "Press any key to continue"