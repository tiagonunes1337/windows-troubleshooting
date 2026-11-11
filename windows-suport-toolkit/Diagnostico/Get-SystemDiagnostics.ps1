#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Coleta informações de diagnóstico rápido de hardware, eventos de queda, disco e drivers.
.DESCRIPTION
    Script somente-leitura para triagem N1/N2. Exibe o relatório na tela e salva cópia em C:\Temp.
#>

$LogDir = "C:\Temp"
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$LogFile = "$LogDir\Diagnostico_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

Start-Transcript -Path $LogFile -NoClobber | Out-Null

$StartDate = (Get-Date).AddDays(-30)
$Bios = Get-CimInstance Win32_BIOS
$Os = Get-CimInstance Win32_OperatingSystem
$Cs = Get-CimInstance Win32_ComputerSystem

Write-Output "=== MAQUINA ==="
Write-Output "$env:COMPUTERNAME | $($Cs.Model) | Tag: $($Bios.SerialNumber) | BIOS: $($Bios.SMBIOSBIOSVersion) | Ligado desde: $($Os.LastBootUpTime)"

Write-Output "`n=== REINICIOS E TELAS AZUIS (30 dias) === 41=desligou seco | 6008=inesperado | 1001=tela azul"
Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,6008,1001; StartTime=$StartDate} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, @{Name='Msg'; Expression={($_.Message -split "`n")[0]}} |
    Format-Table -AutoSize -Wrap

Write-Output "`n=== ERROS DE HARDWARE (WHEA) ==="
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; StartTime=$StartDate} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id |
    Format-Table -AutoSize

Write-Output "`n=== DUMPS (Minidump) ==="
Get-ChildItem -Path "C:\Windows\Minidump" -ErrorAction SilentlyContinue |
    Select-Object Name, LastWriteTime |
    Format-Table -AutoSize

Write-Output "`n=== DISCO ==="
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus | Format-Table -AutoSize

Write-Output "`n=== BITLOCKER ==="
Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue |
    Select-Object VolumeStatus, ProtectionStatus |
    Format-Table -AutoSize

Write-Output "`n=== DRIVERS COM PROBLEMA ==="
Get-PnpDevice -Status ERROR, DEGRADED -ErrorAction SilentlyContinue |
    Select-Object Class, FriendlyName, Status |
    Format-Table -AutoSize

Stop-Transcript | Out-Null
Write-Host "`nRelatório salvo em: $LogFile" -ForegroundColor Cyan