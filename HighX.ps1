#Requires -Version 5.1
# =============================================================================
#  HighX  -  Premium Launcher UI  (blank shell / landing screen)
#  A clean, dark, rounded-corner window. This is the front page the user sees
#  first; later a button will be added here to enter the main program.
# =============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Native helpers: rounded window region + frameless window dragging.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HsNative {
    [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int l,int t,int r,int b,int w,int h);
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr h,int m,int w,int l);
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
}
"@

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$W = 520
$H = 760

$form = New-Object System.Windows.Forms.Form
$form.Text = 'HighX'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.ClientSize = New-Object System.Drawing.Size($W, $H)
$form.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 12)
$form.ShowInTaskbar = $true

# smooth (double-buffered) painting
$form.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'Instance,NonPublic').SetValue($form, $true, $null)

# rounded corners
$form.Region = [System.Drawing.Region]::FromHrgn([HsNative]::CreateRoundRectRgn(0, 0, $W + 1, $H + 1, 36, 36))

# hover state for the top-right window buttons
$script:hover = ''
$closeRect = New-Object System.Drawing.Rectangle(($W - 46), 16, 30, 30)
$minRect   = New-Object System.Drawing.Rectangle(($W - 86), 16, 30, 30)

# -----------------------------------------------------------------------------
#  PAINT : gradient backdrop, hairline border, wordmark, buttons, footer hint
# -----------------------------------------------------------------------------
$form.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
    $c1 = [System.Drawing.Color]::FromArgb(22, 22, 27)
    $c2 = [System.Drawing.Color]::FromArgb(7, 7, 9)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 90)
    $g.FillRectangle($bg, $rect); $bg.Dispose()

    # soft top glow
    $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glowPath.AddEllipse(($W / 2 - 260), -320, 520, 480)
    $pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glowPath)
    $pgb.CenterColor = [System.Drawing.Color]::FromArgb(40, 130, 160, 200)
    $pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.FillPath($pgb, $glowPath); $pgb.Dispose(); $glowPath.Dispose()

    # hairline border
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(55, 255, 255, 255), 1)
    $g.DrawRectangle($pen, 1, 1, $W - 3, $H - 3); $pen.Dispose()

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    # wordmark
    $logoFont = New-Object System.Drawing.Font('Segoe UI', 34, [System.Drawing.FontStyle]::Bold)
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(238, 240, 245))
    $logoRect = New-Object System.Drawing.RectangleF(0, ($H / 2 - 70), $W, 60)
    $g.DrawString('H I G H X', $logoFont, $white, $logoRect, $sf)
    $logoFont.Dispose()

    # subtitle
    $subFont = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Regular)
    $gray = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 170, 180, 195))
    $subRect = New-Object System.Drawing.RectangleF(0, ($H / 2 - 8), $W, 24)
    $g.DrawString('P R E M I U M   S U I T E', $subFont, $gray, $subRect, $sf)
    $subFont.Dispose()

    # accent divider
    $dpen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 130, 160, 200), 1)
    $g.DrawLine($dpen, ($W / 2 - 70), ($H / 2 + 26), ($W / 2 + 70), ($H / 2 + 26)); $dpen.Dispose()

    # footer hint (placeholder for the future 'enter' button)
    $footFont = New-Object System.Drawing.Font('Segoe UI', 8.5, [System.Drawing.FontStyle]::Regular)
    $foot = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 150, 160, 175))
    $footRect = New-Object System.Drawing.RectangleF(0, ($H - 54), $W, 24)
    $g.DrawString('awaiting launch module', $footFont, $foot, $footRect, $sf)
    $footFont.Dispose(); $foot.Dispose()

    # window buttons (close / minimize) with hover highlight
    $glyphFont = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Regular)
    $cCol = if ($script:hover -eq 'close') { [System.Drawing.Color]::FromArgb(240, 90, 90) } else { [System.Drawing.Color]::FromArgb(150, 200, 205, 215) }
    $mCol = if ($script:hover -eq 'min')   { [System.Drawing.Color]::FromArgb(240, 240, 245) } else { [System.Drawing.Color]::FromArgb(150, 200, 205, 215) }
    $cBr = New-Object System.Drawing.SolidBrush($cCol)
    $mBr = New-Object System.Drawing.SolidBrush($mCol)
    $g.DrawString([char]0x2715, $glyphFont, $cBr, $closeRect, $sf)
    $g.DrawString([char]0x2015, $glyphFont, $mBr, $minRect, $sf)
    $glyphFont.Dispose(); $cBr.Dispose(); $mBr.Dispose()
    $white.Dispose(); $gray.Dispose(); $sf.Dispose()
})

# -----------------------------------------------------------------------------
#  INTERACTION : hover the window buttons, drag from anywhere else, close/min
# -----------------------------------------------------------------------------
$form.Add_MouseMove({
    param($s, $e)
    $h = ''
    if ($closeRect.Contains($e.Location)) { $h = 'close' }
    elseif ($minRect.Contains($e.Location)) { $h = 'min' }
    if ($h -ne $script:hover) {
        $script:hover = $h
        $form.Invalidate((New-Object System.Drawing.Rectangle(($W - 96), 10, 92, 42)))
    }
})

$form.Add_MouseDown({
    param($s, $e)
    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
    if ($closeRect.Contains($e.Location)) { $form.Close(); return }
    if ($minRect.Contains($e.Location)) { $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized; return }
    # drag the frameless window (WM_NCLBUTTONDOWN / HTCAPTION)
    [void][HsNative]::ReleaseCapture()
    [void][HsNative]::SendMessage($form.Handle, 0xA1, 0x2, 0)
})

# Esc closes the window (handy while testing)
$form.KeyPreview = $true
$form.Add_KeyDown({ param($s, $e) if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

[void]$form.ShowDialog()
$form.Dispose()
