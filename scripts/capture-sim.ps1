# Save the Connect IQ simulator window (or a crop of it) as a PNG, even when other windows cover it.
#   .\scripts\capture-sim.ps1 out.png                       (whole window)
#   .\scripts\capture-sim.ps1 out.png -X 92 -Y 277 -W 420 -H 420   (vivoactive 5 watch, default window size 604x979)
param([Parameter(Mandatory = $true)][string]$Out, [int]$X = -1, [int]$Y = -1, [int]$W = 0, [int]$H = 0)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  public struct RECT { public int L, T, R, B; }
}
"@
[Win]::SetProcessDPIAware() | Out-Null
# The window briefly changes while an app loads; wait until it is big enough.
$r = New-Object Win+RECT
for ($i = 0; $i -lt 30; $i++) {
    $p = Get-Process simulator | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    $hwnd = $p.MainWindowHandle  # not $h: PowerShell names ignore case and $H is the height
    [Win]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    if (($r.R - $r.L) -ge ($X + $W) -and ($r.B - $r.T) -ge ($Y + $H) -and ($r.R - $r.L) -gt 300) { break }
    Start-Sleep -Milliseconds 500
}
$fw = $r.R - $r.L; $fh = $r.B - $r.T
$full = New-Object System.Drawing.Bitmap $fw, $fh
$g = [System.Drawing.Graphics]::FromImage($full)
$hdc = $g.GetHdc()
[Win]::PrintWindow($hwnd, $hdc, 2) | Out-Null  # 2 = PW_RENDERFULLCONTENT
$g.ReleaseHdc($hdc); $g.Dispose()
if ($W -le 0) { $X = 0; $Y = 0; $W = $fw; $H = $fh }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g2 = [System.Drawing.Graphics]::FromImage($bmp)
$g2.DrawImage($full, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), (New-Object System.Drawing.Rectangle $X, $Y, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
$g2.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"window $($r.L),$($r.T) $($r.R - $r.L)x$($r.B - $r.T) -> $Out"
