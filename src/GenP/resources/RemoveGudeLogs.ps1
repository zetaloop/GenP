# GenP — Gude Log Cleanup
# Removes Adobe gude-*.log files that accumulate when the Good patch is active.
# These files are harmless side effects of the Good patch blocking Adobe network calls.
# Drives: __DRIVES__

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile   = Join-Path $ScriptDir "RemoveGudeLogs.log"

Set-Content -Path $LogFile -Value ((Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " - Gude 日志清理已开始") -Encoding UTF8

function Write-Log {
    param ([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$ts - $Message" -Encoding UTF8
}

function Test-IsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "此脚本需要管理员权限，请以管理员身份运行。"
        exit
    }
}

Test-IsAdmin
Write-Log "正在以管理员身份运行。"

# Parse drive list from embedded placeholder
$Drives = @("__DRIVES__" -split ",") |
    ForEach-Object { $_.Trim().TrimEnd(':').TrimEnd('\') } |
    Where-Object { $_ -ne "" }

$SearchPaths = [System.Collections.Generic.List[string]]::new()

# All user AppData\Roaming\Adobe paths (gude logs land here)
if (Test-Path "C:\Users") {
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Join-Path $_.FullName "AppData\Roaming\Adobe"
        if (Test-Path $p) { $SearchPaths.Add($p) }
    }
}

# Common AppData Adobe path (C:\ProgramData\Adobe)
$CommonAdobe = Join-Path $env:ProgramData "Adobe"
if (Test-Path $CommonAdobe) { $SearchPaths.Add($CommonAdobe) }

# Adobe folder on each selected drive (e.g. E:\Adobe)
foreach ($D in $Drives) {
    $AdobePath = "${D}:\Adobe"
    if (Test-Path $AdobePath) { $SearchPaths.Add($AdobePath) }
}

if ($SearchPaths.Count -eq 0) {
    Write-Log "没有找到可供扫描的 Adobe 路径。"
    Write-Log "=== 已完成 ==="
    exit
}

Write-Log "正在扫描 $($SearchPaths.Count) 个路径..."

$GudeLogs = @(
    foreach ($Path in $SearchPaths) {
        Get-ChildItem -Path $Path -Recurse -Filter "gude*.log" -File -ErrorAction SilentlyContinue
    }
)

if ($GudeLogs.Count -eq 0) {
    Write-Log "没有找到 Gude 日志文件。"
    Write-Log "=== 已完成 ==="
    exit
}

Write-Log "找到 $($GudeLogs.Count) 个 Gude 日志文件。"

$Deleted = 0
$Skipped = 0

foreach ($log in $GudeLogs) {
    try {
        Remove-Item $log.FullName -Force -ErrorAction Stop
        Write-Log "已删除：$($log.FullName)"
        $Deleted++
    } catch {
        Write-Log "已跳过（正在使用）：$($log.FullName)"
        $Skipped++
    }
}

Write-Log "清理完成：已删除 $Deleted 个，已跳过 $Skipped 个"
Write-Log "=== 已完成 ==="
