# SharePoint Automated Folder Creator (PnP PowerShell)

Uma solução robusta e automatizada em **PowerShell** para criação em lote de pastas no **Microsoft SharePoint Online** a partir de dados estruturados (CSV/Excel).

O script conta com **dupla camada de proteção contra duplicidade**, modo de simulação (`DryRun`), registros de log detalhados e tratamento contínuo de exceções.

---

## 🚀 Funcionalidades

- **Criação em Lote:** Processa centenas de registros automaticamente no SharePoint Online.
- **Modo DryRun (Simulação):** Valida a leitura de dados, inconsistências e duplicações sem alterar o ambiente de produção.
- **Proteção Dupla Contra Duplicados:**
  - **Filtro Local:** Ignora ocorrências repetidas na própria planilha de entrada.
  - **Validação Remota:** Mapeia a estrutura existente no SharePoint e pula diretórios já criados.
- **Logging Avançado:** Gera arquivo de log estruturado com carimbo de data/hora (`YYYY-MM-DD HH:mm:ss`), contabilizando acertos, duplicados e inconsistências.
- **Resiliência:** Tratamento individual com `try/catch` por registro, garantindo que falhas em itens isolados não interrompam o fluxo global.

---

## 🛠️ Pré-requisitos

1. **PowerShell 7+** (Recomendado) ou PowerShell 5.1.
2. Módulo **PnP.PowerShell**:
   ```powershell
   Install-Module -Name PnP.PowerShell -Scope CurrentUser
   ```
3. Permissões de escrita (`Edit` ou `Full Control`) na biblioteca de documentos do SharePoint.

---

## 📂 Estrutura do Repositório

```text
.
├── script.ps1           # Script principal de automação
├── modelo_exemplo.csv   # Estrutura de exemplo para dados de entrada
├── .gitignore           # Arquivos ignorados pelo Git (logs e dados reais)
└── README.md            # Documentação da ferramenta
```

---

## 📝 Formato do CSV (`modelo_exemplo.csv`)

O arquivo CSV de entrada deve conter cabeçalhos correspondentes à chave usada no script:

```csv
ID_Funcionario,Nome_Completo,Departamento
1001,Ana Silva,RH
1002,Bruno Costa,TI
1003,Carla Souza,Financeiro
```

---

## ⚙️ Como Usar

### 1. Configuração Inicial
Abra o script `script.ps1` e configure as variáveis principais:
```powershell
$SiteUrl = "https://seu-tenant.sharepoint.com/sites/SeuSite"
$Biblioteca = "Documentos Compartilhados/SubpastaDestino"
$CsvPath = ".\modelo_exemplo.csv"
$DryRun = $true  # Defina $false apenas para execução real
```

### 2. Execução de Teste (Simulação)
Mantenha `$DryRun = $true` e execute:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\script.ps1
```
Confira o resumo impresso no console e o arquivo `.log` gerado na pasta.

### 3. Execução em Produção
Altere a variável para `$DryRun = $false` e execute o script novamente.

---

## 📊 Métricas de Log

Ao final do processamento, a ferramenta exibe uma síntese da operação:

| Métrica | Descrição |
| :--- | :--- |
| **Total Lidos** | Registros processados do CSV. |
| **Pastas a Criar / Criadas** | Total de diretórios afetados com sucesso. |
| **Duplicados Filtrados** | Ocorrências repetidas na planilha ignoradas. |
| **Pastas Já Existentes** | Diretórios mantidos sem alteração na nuvem. |
| **Linhas Sem Nome** | Registros inconsistentes/vazios descartados. |
| **Total de Erros** | Exceções ocorridas durante o processo. |

---

## 🛡️ Segurança de Dados

Por boas práticas de governança e **LGPD/GDPR**:
- **Nunca** envie arquivos CSV/XLSX com dados pessoais reais de colaboradores para este repositório.
- Utilize o arquivo `.gitignore` fornecido para prevenir commits acidentais de arquivos sensíveis.

---

## 📄 Licença

Este projeto está sob a licença [MIT](LICENSE).

