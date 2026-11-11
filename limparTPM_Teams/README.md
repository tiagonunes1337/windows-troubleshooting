# Limpeza de TPM e correção de problemas do Teams

Este diretório contém o script `Setup.bat`, desenvolvido para auxiliar na correção de problemas de perfil do Microsoft Teams em ambientes Windows corporativos, especialmente quando há indícios de:

- perfil do usuário corrompido;
- falhas de autenticação no domínio;
- problemas com o canal de confiança do computador;
- estado do TPM inconsistente ou não pronto para uso;
- erros de login, sincronização ou inicialização do Teams após reinstalação ou troca de máquina.

## Objetivo

O script automatiza uma sequência de verificações e limpezas que normalmente exigem várias etapas manuais. Em resumo, ele tenta:

1. encerrar processos do Teams;
2. localizar e remover o perfil local corrompido do usuário;
3. limpar caches e arquivos residuais do Teams;
4. verificar o canal de confiança com o domínio;
5. validar o estado do TPM;
6. orientar o próximo passo manual para que o usuário seja recriado e o Teams funcione novamente.

## Como ele funciona

### 1) Encerramento dos processos do Teams

O script executa:

```bat
 taskkill /f /im ms-teams.exe
 taskkill /f /im Teams.exe
```

Isso garante que o aplicativo não esteja em execução enquanto a limpeza e a recriação do perfil são feitas.

### 2) Verificação do perfil no Registro

O script solicita o nome do usuário e consulta o registro:

```bat
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s | findstr /i "%USUARIO%"
```

Essa etapa identifica se o perfil existe no registro do Windows e mostra o `SID` associado ao usuário. Isso é importante porque, em alguns casos, o perfil pode ficar parcialmente corrompido e continuar presente mesmo após a pasta do usuário ter sido removida.

### 3) Remoção do perfil local e do diretório do usuário

O script usa `takeown` e `icacls` para assumir posse da pasta do usuário e dar permissões de administração:

```bat
 takeown /f "C:\Users\%USUARIO%" /r /d y
 icacls "C:\Users\%USUARIO%" /grant administrators:F /t
 rmdir /s /q "C:\Users\%USUARIO%"
```

Isso remove o perfil local do Windows, forçando a criação de um novo ao fazer login novamente.

### 4) Limpeza do cache residual do Teams

O script apaga diretórios do Microsoft Teams e também de componentes do app package:

```bat
rmdir /s /q "%localappdata%\Microsoft\Teams"
rmdir /s /q "%appdata%\Microsoft\Teams"
rmdir /s /q "%localappdata%\Packages\MSTeams_8wekyb3d8bbwe"
rmdir /s /q "%localappdata%\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"
```

Isso remove dados locais que podem estar travados ou corrompidos.

### 5) Verificação do canal de confiança com o domínio

O script executa:

```bat
powershell -Command "Test-ComputerSecureChannel"
```

Esse comando verifica se o computador ainda consegue se autenticar corretamente com o controlador de domínio. Se retornar `False`, pode haver um problema de confiança entre o cliente e o domínio. Nesse caso, a correção manual sugerida é:

```powershell
Reset-ComputerMachinePassword -Credential (Get-Credential)
```

### 6) Verificação do TPM

A parte final do script faz:

```bat
manage-bde -status
start tpm.msc
```

Essa etapa valida o status do BitLocker e abre o console do TPM (`tpm.msc`) para verificar se ele está "pronto para uso". O script também alerta que, se for necessário limpar o TPM, isso deve ser feito com cuidado e somente após confirmar que não há BitLocker ativo ou que o usuário tenha a chave de recuperação disponível.

## Quando usar esse script

Esse tipo de correção é útil quando o usuário apresenta problemas como:

- Microsoft Teams travando ou fechando sozinho;
- erro ao entrar no Teams com conta corporativa;
- perfil local corrompido;
- problemas após troca de máquina ou reaproveitamento do dispositivo;
- falhas ao autenticar no domínio;
- erro relacionado a Windows Hello / PIN / TPM.

## Atenção

Antes de executar, tenha em mente:

- rode como administrador local;
- não execute como o usuário afetado;
- a remoção do perfil do usuário apaga dados locais do Windows daquela conta;
- se houver BitLocker habilitado, confirme a chave de recuperação antes de limpar o TPM;
- o script é uma correção operacional para diagnóstico e recuperação, não um substituto para uma análise completa da infraestrutura.

## Como executar

1. Abra o Prompt de Comando como Administrador.
2. Navegue até a pasta do script.
3. Execute:

```bat
Setup.bat
```

4. Informe o nome do usuário afetado (exemplo fictício: `usuario.exemplo`).
5. Siga as mensagens exibidas e confirme os passos manuais solicitados.
6. Reinicie o computador e faça login novamente.
7. Teste a autenticação do Teams e, se necessário, reconfigure o PIN/Windows Hello.

## Fluxo final esperado

Ao final da execução, o script orienta:

- reiniciar a máquina;
- logar novamente com o usuário do domínio;
- verificar se o perfil será recriado do zero;
- testar o login no Teams;
- reinstalar ou reconfigurar o PIN do Windows Hello, se necessário.

## Resumo

Este script é uma ferramenta de troubleshooting para quando o problema do Microsoft Teams está relacionado a um perfil local corrompido, mau funcionamento do canal de confiança com o domínio e/ou estado do TPM. Ele combina limpeza de perfil, exclusão de cache do Teams, checagem de autenticação no domínio e validação do módulo de segurança do computador.

Em outras palavras, ele tenta restaurar o ambiente do usuário para um estado limpo e funcional, permitindo que o Windows e o Teams consigam recriar o perfil e a autenticação corretamente.
