# Automação de Provisionamento de Estações de Trabalho (Post-Image/OOBE)

## Visão Geral
Este repositório contém um script de automação em PowerShell (`Setup.ps1`) projetado para padronizar a configuração inicial de estações de trabalho Windows em ambientes corporativos. O objetivo é reduzir a intervenção manual durante o processo de *Out-Of-Box Experience* (OOBE), garantindo que os ativos sejam configurados de acordo com os padrões de rede e domínio estabelecidos.

## Funcionalidades
- **Configuração de Identidade**: Solicitação e aplicação de hostname seguindo a convenção de nomenclatura corporativa.
- **Validação de Conectividade**: Verificação automática de comunicação com o controlador de domínio via DNS/Rede.
- **Configuração de Acesso Administrativo Local**: Criação de conta de suporte para gerenciamento de emergência e provisionamento de privilégios para usuários/grupos definidos pela política corporativa.
- **Integração ao Domínio**: Automação do processo de ingresso no Active Directory.
- **Finalização de Instalação (OOBE Bypass)**: Otimização do fluxo de trabalho ao suprimir assistentes de configuração inicial e telas de telemetria desnecessárias.

## Pré-requisitos
- Execução do script em sessão PowerShell com privilégios elevados (*Run as Administrator*).
- Conectividade ativa com a rede corporativa.
- Credenciais válidas de um usuário com permissões delegadas para ingresso de computadores no domínio.


## Considerações de Segurança

### Gestão de Credenciais
- **Aviso:** O script utiliza uma senha para a conta de suporte local. É altamente recomendado que a mesma seja rotacionada imediatamente após a implantação ou gerenciada via ferramentas de acesso privilegiado.
- **Boas Práticas:** A utilização de credenciais em texto claro dentro de scripts deve ser evitada em produção. Recomenda-se a transição para métodos de autenticação baseados em *Group Managed Service Accounts* (gMSA) ou a integração com cofres de senhas (*Vaults*).

### Gestão de Administradores Locais
- **Recomendação de Auditoria:** Para fortalecer a postura de segurança, recomenda-se a implementação do **Microsoft LAPS (Local Administrator Password Solution)** ou sucessores, para garantir senhas de administrador local exclusivas e rotacionadas para cada máquina.
- **Governança:** A gestão de membros nos grupos de administradores locais deve ser preferencialmente centralizada através de **GPOs (Group Policy Objects)** ou políticas de **Intune/MDM**, garantindo um ciclo de vida e auditoria conforme as normas de conformidade corporativa.

### Auditoria e Compliance
- Todas as alterações realizadas por este script (renomeação, ingresso em domínio e modificação de membros de grupos) geram eventos de log no Visualizador de Eventos do Windows. Recomenda-se o encaminhamento destes logs para um SIEM centralizado para fins de monitoramento e auditoria de segurança.
## Instruções de Uso

### Método 1: Execução Automatizada via Mídia Removível (Tela OOBE)
Durante a fase inicial de boas-vindas do Windows (*OOBE*), abra o Prompt de Comando elevado com o atalho **Shift + F10** e execute:

```cmd
for %i in (C D E F G) do @if exist %i:\Setup.ps1 powershell.exe -ExecutionPolicy Bypass -File %i:\Setup.ps1
```

### Método 2: Execução Manual (PowerShell)

1. Abra o PowerShell como **Administrador**.
2. Navegue até o diretório do script e execute:

```powershell
.\Setup.ps1
```

3. Digite o hostname do ativo conforme solicitado pelo console (ex: `CORP-WS-001`).
4. Insira as credenciais autorizadas para concluir o ingresso no domínio.
5. O sistema efetuará o reinício automático após a conclusão das etapas.


