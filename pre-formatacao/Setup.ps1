# --- CONFIGURAÇÃO ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Dominio = "hrbr.com" 
$UsuariosAD = @("tiago.oliveira") # Lista de usuários que serão adicionados ao grupo de administradores locais

# ATENÇÃO: Em produção, utilize credenciais criptografadas.
$CredencialJoin = Get-Credential -Message "Digite seu usuario e senha do AD para ingressar no dominio"

try {
    # 1. DEFINIÇÃO DO NOME
    $NovoNome = Read-Host "[ACAO] Digite o nome desta maquina (Ex: NTBK-001)"
    if ([string]::IsNullOrWhiteSpace($NovoNome)) { throw "O nome não pode ficar em branco." }
    $NomeAtual = $env:COMPUTERNAME

    # 2. VALIDAÇÃO DE REDE E DNS (Com Timeout de 60 segundos)
    Write-Host "`n[ACAO] Aguardando rede e comunicação com $Dominio..." -ForegroundColor Cyan
    $Timeout = 20
    $Tentativa = 0
    while (!(Test-Connection $Dominio -Count 1 -Quiet)) {
        Start-Sleep -Seconds 3
        $Tentativa++
        if ($Tentativa -ge $Timeout) { throw "Não foi possível alcançar o domínio $Dominio após 60 segundos." }
    }
    Clear-DnsClientCache
    Write-Host "[OK] Rede conectada." -ForegroundColor Green

    # 3. CRIAÇÃO DO USUÁRIO 'SUPORTE'
    Write-Host "[ACAO] Criando conta Suporte..." -ForegroundColor Cyan
    $UserName = "suporte"
    $PasswordPlain = Read-Host "Digite a senha da conta local de suporte" -AsSecureString
    $GrupoAdministradores = (Get-LocalGroup -SID "S-1-5-32-544" -ErrorAction Stop).Name

    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $Username `
                  -Password $PasswordPlain `
                  -FullName "suporte" `
                  -Description "suporte" `
                  -PasswordNeverExpires
    Add-LocalGroupMember -Group $GrupoAdministradores -Member $UserName -ErrorAction Stop
    
    Write-Host "[OK] Usuário '$Username' criado." -ForegroundColor Green
}
    else {
        Set-LocalUser -Name $UserName -Password $PasswordPlain -PasswordNeverExpires:$true
        Add-LocalGroupMember -Group $GrupoAdministradores -Member $UserName -ErrorAction SilentlyContinue
        Write-Host "[OK] Conta Suporte ja existia. Senha e permissoes atualizadas." -ForegroundColor Yellow
    }

    # 4. PREPARAÇÃO PÓS-REBOOT (RUNONCE) - CORRIGIDO DOMÍNIO
    Write-Host "`n[ACAO] Agendando permissões AD pós-reboot..." -ForegroundColor Cyan
    $CaminhoScriptTemp = "C:\Windows\Temp\Add-AdminsAD.ps1"
    $ScriptRunOnce = @"
    `$suporte = @("$($UsuariosAD -join '", "')")
    `$grupoAdmin = (Get-LocalGroup -SID "S-1-5-32-544").Name
    foreach (`$user in `$suporte) { Add-LocalGroupMember -Group `$grupoAdmin -Member "$Dominio\`$user" -ErrorAction SilentlyContinue }
    Remove-Item -Path `$PSCommandPath -Force
"@
    $ScriptRunOnce | Out-File -FilePath $CaminhoScriptTemp -Encoding UTF8 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "AdicionarSuporteAD" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $CaminhoScriptTemp"

    # 5. INGRESSO NO DOMÍNIO E RENAME
    Write-Host "`n[ACAO] Processando ingresso no domínio $Dominio..." -ForegroundColor Cyan
    Add-Computer -DomainName $Dominio -Credential $CredencialJoin -Force -ErrorAction Stop
    Write-Host "[OK] Máquina ingressada no domínio." -ForegroundColor Green

    if ($NovoNome -ne $NomeAtual) {
        Write-Host "[ACAO] Renomeando de '$NomeAtual' para '$NovoNome'..." -ForegroundColor Cyan
        try {
            Rename-Computer -NewName $NovoNome -Force -ErrorAction Stop
            Write-Host "[OK] Nome da máquina alterado para '$NovoNome'." -ForegroundColor Green
        }
        catch {
            Write-Host "[AVISO] Ingresso concluído, mas não foi possível renomear a máquina: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "[INFO] O script continuará; o nome poderá ser alterado posteriormente." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[INFO] Nome igual ao atual; nenhuma renomeação necessária." -ForegroundColor Yellow
    }

    # 6. BYPASS DEFINITIVO DO OOBE
    Write-Host "`n[ACAO] Quebrando processo de instalação (OOBE Bypass)..." -ForegroundColor Cyan
    
    $RegSetup = "HKLM:\SYSTEM\Setup"
    Set-ItemProperty -Path $RegSetup -Name "OOBEInProgress" -Value 0 -Force
    Set-ItemProperty -Path $RegSetup -Name "SetupType" -Value 0 -Force
    Set-ItemProperty -Path $RegSetup -Name "SetupPhase" -Value 0 -Force
    Set-ItemProperty -Path $RegSetup -Name "CmdLine" -Value "" -Force

    # Marca o carregador do OOBE como concluído para evitar que ele seja retomado
    $RegChildCompletion = "HKLM:\SYSTEM\Setup\Status\ChildCompletion"
    if (!(Test-Path $RegChildCompletion)) { New-Item -Path $RegChildCompletion -Force | Out-Null }
    New-ItemProperty -Path $RegChildCompletion -Name "oobeldr.exe" -PropertyType DWord -Value 3 -Force | Out-Null

    $RegState = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
    if (!(Test-Path $RegState)) { New-Item -Path $RegState -Force | Out-Null }
    Set-ItemProperty -Path $RegState -Name "IMAGESTATE" -Value "IMAGE_STATE_COMPLETE" -Force

    $RegOobe = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
    if (!(Test-Path $RegOobe)) { New-Item -Path $RegOobe -Force | Out-Null }
    New-ItemProperty -Path $RegOobe -Name "BypassNRO" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $RegOobe -Name "SkipMachineOOBE" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $RegOobe -Name "SkipUserOOBE" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $RegOobe -Name "HideOnlineAccountScreens" -PropertyType DWord -Value 1 -Force | Out-Null

    # Encerra os processos que podem manter a interface do OOBE aberta
    Get-Process -Name "msoobe", "wwahost", "CloudExperienceHost", "CloudExperienceHostBroker" -ErrorAction SilentlyContinue | Stop-Process -Force

    Write-Host "`n[OK] Tudo pronto! Forçando reboot em 5 segundos..." -ForegroundColor Green
    shutdown.exe /r /t 5 /f

}
catch {
    Write-Host "`n[ERRO CRITICO] $($_.Exception.Message)" -ForegroundColor Red
    Pause
}