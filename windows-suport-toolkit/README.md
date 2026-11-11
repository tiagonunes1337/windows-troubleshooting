# Windows Support Toolkit (PowerShell)

Coleção de scripts em PowerShell desenvolvidos para agilizar o diagnóstico N1/N2, triagem de hardware e manutenção preventiva em ambientes Windows corporativos.

## Estrutura do Projeto

* **`Diagnostico/Get-SystemDiagnostics.ps1`**: Script *read-only* que coleta dados do ativo (Service Tag, BIOS, Uptime), histórico de desligamentos inesperados (Event IDs 41, 6008, 1001), erros físicos de hardware (WHEA-Logger), arquivos Minidump, saúde do SSD/HDD, status do BitLocker e drivers com falha. Exporta log automático em `C:\Temp`.
* **`Manutencao/Invoke-SystemCleanup.ps1`**: Rotina de higienização que limpa diretórios temporários de todos os perfis locais/domínio (`C:\Users\*\AppData\Local\Temp`), temporários do sistema (`C:\Windows\Temp`), lixeira e executa otimização `ReTrim` em unidades SSD.

## Como Executar

Abra o **PowerShell como Administrador** e execute:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Diagnostico\Get-SystemDiagnostics.ps1