#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Executa limpeza de temporários de todos os perfis, lixeira e otimização TRIM.
#>

Write-Host "Iniciando limpeza e otimização corporativa..." -ForegroundColor Cyan

# 1. Limpar Temp de todos os perfis de usuários da máquina
Write-Host "[1/4] Limpando pastas Temp de todos os usuários..." -ForegroundColor Yellow
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Limpar arquivos temporários do sistema Windows
Write-Host "[2/4] Limpando C:\Windows\Temp..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Esvaziar Lixeira de todas as unidades
Write-Host "[3/4] Esvaziando a Lixeira..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# 4. Executar TRIM no SSD
Write-Host "[4/4] Executando otimização (TRIM) na unidade C:..." -ForegroundColor Yellow
Optimize-Volume -DriveLetter C -ReTrim -Verbose

Write-Host "Manutenção concluída com sucesso!" -ForegroundColor Green