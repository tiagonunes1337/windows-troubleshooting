@echo off
:: ===================================================================
:: Script de reparo - Perfil corrompido + TPM + canal de dominio
:: Rodar como administrador LOCAL (nao logado como o usuario afetado)
:: ===================================================================

setlocal
set /p USUARIO="Digite o nome do usuario (ex: usuario.exemplo): "

echo.
echo === 1. Finalizando processos do Teams ===
taskkill /f /im ms-teams.exe
taskkill /f /im Teams.exe

echo.
echo === 2. Verificando entrada do perfil no registro ===
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s | findstr /i "%USUARIO%"
echo.
echo Anote o SID (S-1-5-21-...) que aparecer ACIMA da linha ProfileImagePath, se houver.
pause

echo.
echo === 3. Removendo permissoes e apagando pasta do perfil ===
takeown /f "C:\Users\%USUARIO%" /r /d y
icacls "C:\Users\%USUARIO%" /grant administrators:F /t
rmdir /s /q "C:\Users\%USUARIO%"

echo.
echo === 4. Confirmando remocao ===
dir C:\Users
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s | findstr /i "%USUARIO%"

echo.
echo Se ainda retornou alguma linha acima, rode manualmente:
echo reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\SID_AQUI" /f
pause

echo.
echo === 5. Limpando cache residual do Teams ===
rmdir /s /q "%localappdata%\Microsoft\Teams"
rmdir /s /q "%appdata%\Microsoft\Teams"
rmdir /s /q "%localappdata%\Packages\MSTeams_8wekyb3d8bbwe"
rmdir /s /q "%localappdata%\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"

echo.
echo === 6. Verificando canal de confianca com o dominio ===
powershell -Command "Test-ComputerSecureChannel"

echo.
echo Se retornou False, rode manualmente no PowerShell:
echo Reset-ComputerMachinePassword -Credential (Get-Credential)
echo (use credencial de admin de dominio)
pause

echo.
echo === 7. Verificando estado do TPM ===
echo Abrindo tpm.msc - confira se esta "pronto para uso"
echo Se necessario, va em Acoes - Limpar TPM (CONFIRME SE HA BITLOCKER ANTES)
manage-bde -status
start tpm.msc
pause

echo.
echo === CONCLUIDO ===
echo Proximos passos manuais:
echo 1. Reiniciar a maquina
echo 2. Logar com %USUARIO% (dominio) - perfil sera criado do zero
echo 3. Testar login no Teams
echo 4. Reconfigurar Windows Hello (PIN) se necessario

endlocal
