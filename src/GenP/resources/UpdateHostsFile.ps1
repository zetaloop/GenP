$scriptDir = "C:\Windows\System32\drivers\etc"
$logDirectory = "C:\Windows\System32\drivers\etc"
$logFile = "$logDirectory\UpdateHostsFile.log"
if (-not (Test-Path -Path $logDirectory)) { New-Item -ItemType Directory -Path $logDirectory -Force }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Content -Path $logFile -Value $null
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}
function Test-IsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "此脚本需要管理员权限，请以管理员身份运行 PowerShell。"
        Write-Output "此脚本需要管理员权限，请以管理员身份运行 PowerShell。"
        exit
    }
}
function SafeFileOperation {
    param (
        [string]$Action,
        [string]$Source,
        [string]$Destination
    )
    try {
        switch ($Action) {
            "Copy" { Copy-Item -Path $Source -Destination $Destination -Force }
            "Rename" { Rename-Item -Path $Source -NewName $Destination -Force }
        }
        $actionLabel = if ($Action -eq "Copy") { "复制" } else { "重命名" }
        Write-Log "$actionLabel 操作成功：$Source -> $Destination"
    } catch {
        Write-Log "文件操作失败：请确认源文件存在并具有所需权限。"
    }
}
Test-IsAdmin
Write-Log "脚本开始执行。"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$backupCurrent = "C:\Windows\System32\drivers\etc\hosts.bak"
$plainBackup = "C:\Windows\System32\drivers\etc\hosts.plain"
$tempFile = "$scriptDir\hosts_temp"
$primaryGenPPath = "__GENP_PATH__"
if (-not (Test-Path $hostsFile)) {
    Write-Log "指定路径中不存在 hosts 文件：$hostsFile"
    exit
}
if (-not (Test-Path $primaryGenPPath)) {
    Write-Log "指定路径中不存在 GenP 程序：$primaryGenPPath"
    exit
}
if ((Get-Item $hostsFile).Attributes -band [System.IO.FileAttributes]::ReadOnly) {
    Write-Log "hosts 文件当前为只读，正在移除只读属性。"
    try {
        Set-ItemProperty -Path $hostsFile -Name IsReadOnly -Value $false
        Write-Log "已移除 hosts 文件的只读属性。"
    } catch {
        Write-Log "无法更改 hosts 文件的只读状态，请检查权限。"
    }
}
$currentContent = Get-Content -Path $hostsFile -Raw -ErrorAction SilentlyContinue
if (-not (Test-Path $backupCurrent) -or ($currentContent -ne (Get-Content -Path $backupCurrent -Raw -ErrorAction SilentlyContinue))) {
    Write-Log "正在创建 hosts 文件的最新有效备份。"
    SafeFileOperation -Action "Copy" -Source $hostsFile -Destination $backupCurrent
} else {
    Write-Log "当前 hosts 文件与最新有效备份一致，跳过创建备份。"
}
$hostsContent = Get-Content -Path $hostsFile -Raw -ErrorAction SilentlyContinue
Write-Log "已读取 hosts 文件内容。"
$maxRetries = 3
$retryDelay = 2
$newBlocklist = @()
Write-Log "正在运行 GenP.exe 获取屏蔽列表。"
try {
    Start-Process -FilePath $primaryGenPPath -ArgumentList "-updatehosts" -NoNewWindow -Wait
    Write-Log "GenP.exe 执行成功。"
    $hostsContent = Get-Content -Path $hostsFile -Raw
    if ($hostsContent -match "^0\.0\.0\.0") {
        Write-Log "已检测到 GenP.exe 输出，结构有效。"
        $newBlocklist = $hostsContent -split "`n" | Where-Object { $_.Trim() -match '^0\.0\.0\.0' }
    } else {
        Write-Log "GenP.exe 输出缺失或无效。"
        throw "GenP.exe 输出无效。"
    }
} catch {
    Write-Log "无法运行 GenP 获取屏蔽列表，请确认程序存在后重试。"
}
if (-not $newBlocklist.Count) {
    Write-Log "正在从备用地址获取屏蔽列表。"
    $encodedUrls = @(
        "aHR0cHM6Ly9hLmRvdmUuaXNkdW1iLm9uZS9saXN0LnR4dA==", 
        "aHR0cHM6Ly9hLmRvdmUuaXNkdW1iLm9uZS93aW5ob3N0cy50eHQ=",
        "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2lnbmFjaW9jYXN0cm8vYS1kb3ZlLWlzLWR1bWIvcmVmcy9oZWFkcy9tYWluL2xpc3QudHh0",
        "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2lnbmFjaW9jYXN0cm8vYS1kb3ZlLWlzLWR1bWIvcmVmcy9oZWFkcy9tYWluL3dpbmhvc3RzLnR4dA=="
    )
    foreach ($encodedUrl in $encodedUrls) {
        $decodedUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUrl))
        Write-Log "正在访问备用地址。"
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                Write-Log "正在从备用地址获取屏蔽列表内容。"
                $response = Invoke-WebRequest -Uri $decodedUrl -UseBasicParsing -ErrorAction Stop
                if ($response.Content) {
                    Write-Log "第 $attempt 次尝试成功从备用地址获取内容。"
                    $newBlocklist += $response.Content -split "`n" | Where-Object { $_ -match "^0\.0\.0\.0|^# Last update:" }
                    break
                }
            } catch {
                Write-Log "无法连接到指定地址，请检查网络连接或地址本身。"
                if ($attempt -lt $maxRetries) {
                    Write-Log "$retryDelay 秒后重试。"
                    Start-Sleep -Seconds $retryDelay
                }
            }
        }
        if ($newBlocklist.Count -gt 0) { break }
    }
}
if ($newBlocklist.Count -eq 0) {
    Write-Log "未从任何来源取得屏蔽条目，正在尝试从 hosts.plain 还原 hosts 文件。"
    if (Test-Path $plainBackup) {
        Write-Log "正在从 hosts.plain 还原 hosts 文件。"
        $plainContent = Get-Content -Path $plainBackup -Raw -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($plainContent)) {
            Write-Log "正在还原 hosts 文件。"
            Set-Content -Path $hostsFile -Value $plainContent -NoNewline
            Write-Log "已从 hosts.plain 成功还原 hosts 文件。"
        } else {
            Write-Log "hosts.plain 为空或无效，无法还原 hosts 文件。"
        }
    } else {
        Write-Log "hosts.plain 不存在，无法从中还原 hosts 文件。"
        Write-Log "正在从备份还原 hosts 文件。"
        SafeFileOperation -Action "Copy" -Source $backupCurrent -Destination $hostsFile
    }
    Write-Log "脚本即将退出。"
    exit
}
Write-Log "共获取 $($newBlocklist.Count) 个有效屏蔽条目。"
$blocklistHeader = "# START - Adobe Blocklist"
$blocklistFooter = "# END - Adobe Blocklist"
$lastUpdateComment = ""
foreach ($line in $newBlocklist) {
    if ($line.Trim().StartsWith("# Last update:")) {
        $lastUpdateComment = "`n$($line.Trim())"
    }
}
$filteredBlocklist = $newBlocklist | Where-Object { -not ($_.Trim().StartsWith("# Last update:")) -and $_.Trim() -ne "" }
$finalContent = ""
if (Test-Path $plainBackup) {
    $plainContent = Get-Content -Path $plainBackup -Raw -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($plainContent)) {
        Write-Log "正在将 hosts.plain 的内容写入 hosts 文件顶部。"
        $finalContent += $plainContent.Trim() + "`n"
    } else {
        Write-Log "hosts.plain 为空，不会写入。"
    }
}
$finalContent += "$blocklistHeader$lastUpdateComment`n$($filteredBlocklist -join "`n")`n$blocklistFooter".Trim()
$finalContent = $finalContent -replace "`r?`n`r?`n", "`n"
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        Start-Sleep -Seconds 1
        Write-Log "第 $attempt 次尝试写入 $tempFile"
        if ((Get-Item $hostsFile).Attributes -band [System.IO.FileAttributes]::ReadOnly) {
            Write-Log "hosts 文件当前为只读，正在移除只读属性。"
            Set-ItemProperty -Path $hostsFile -Name IsReadOnly -Value $false
            Write-Log "已移除 hosts 文件的只读属性。"
        }
        Set-Content -Path $tempFile -Value $finalContent -NoNewline
        Write-Log "临时文件创建成功。"
        SafeFileOperation -Action "Copy" -Source $tempFile -Destination $hostsFile
        Write-Log "已使用临时文件成功更新 hosts 文件。"
        break
    } catch {
        Write-Log "更新 hosts 文件时出错，请确认具有足够权限。"
        if ($errorMsg -like "*denied*") {
            Write-Log "访问 $hostsFile 被拒绝，$retryDelay 秒后重试..."
            Start-Sleep -Seconds $retryDelay
        } else {
            Write-Log "发生意外错误：$errorMsg"
            break
        }
    }
}
Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
Write-Log "脚本执行完毕，hosts 文件已更新完成。"
