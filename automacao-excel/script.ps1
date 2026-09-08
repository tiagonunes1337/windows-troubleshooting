$ErrorActionPreference = "Stop"
$DryRun = $true
$SiteUrl = "https://seu-tenant.sharepoint.com/sites/SeuSite"
$PastaFuncionarios = "Documentos Compartilhados/SubpastaDestino"
$CsvPath = ".\modelo_exemplo.csv"
$LogPath = ".\logs\execucao.log"
$InvalidChars = '[~"#%&*:<>`?/\\{|}]'
$TotalLidos = 0
$TotalCriadas = 0
$TotalSimuladas = 0
$TotalExistentes = 0
$TotalDuplicados = 0
$TotalIgnorados = 0
$TotalErros = 0
$LogDirectory = Split-Path $LogPath
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$Utf8SemBOM = New-Object System.Text.UTF8Encoding($false)
$LogWriter = New-Object System.IO.StreamWriter($LogPath, $false, $Utf8SemBOM)
$LogWriter.AutoFlush = $true
function Escrever-Log {
    param([string]$Mensagem)
    $LogWriter.WriteLine("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensagem")
    Write-Host $Mensagem
}
try {
    Escrever-Log "Início da execução. DryRun=$DryRun"
    Connect-PnPOnline -Url $SiteUrl -UseWebLogin
    $CsvLines = @(Get-Content -Path $CsvPath -Encoding UTF8)
    if ($CsvLines.Count -lt 2) { throw "CSV sem linha de cabeçalho ou dados" }
    $Funcionarios = @($CsvLines | Select-Object -Skip 1 | ConvertFrom-Csv)
    $TotalLidos = $Funcionarios.Count
    if ($TotalLidos -gt 0) {
        $Colunas = @($Funcionarios[0].PSObject.Properties.Name)
        $NomeColuna = @($Colunas | Where-Object { $_ -match '^(Nome|Local|USU.*RIO DO EQUIPAMENTO)$' } | Select-Object -First 1)
        $CpfColuna = @($Colunas | Where-Object { $_ -eq 'CPF' } | Select-Object -First 1)
        if (-not $NomeColuna -or -not $CpfColuna) { throw "CSV sem colunas de nome e CPF" }
    }
    $PastasExistentes = @(Get-PnPFolderItem -FolderSiteRelativeUrl $PastaFuncionarios -ItemType Folder)
    $NomesExistentes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($Pasta in $PastasExistentes) { [void]$NomesExistentes.Add($Pasta.Name) }
    $ChavesProcessadas = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $Linha = 1
    foreach ($Funcionario in $Funcionarios) {
        $Linha++
        try {
            $Nome = ([string]$Funcionario.$NomeColuna) -replace $InvalidChars, ' '
            $Nome = ($Nome -replace '\s+', ' ').Trim().TrimEnd('.')
            $Cpf = ([string]$Funcionario.$CpfColuna).Trim()
            if ([string]::IsNullOrWhiteSpace($Nome)) { $TotalIgnorados++; Escrever-Log "[IGNORADO] Linha ${Linha} sem Nome"; continue }
            $NomePasta = if ([string]::IsNullOrWhiteSpace($Cpf)) { $Nome } else { "$Nome - $Cpf" }
            if (-not $ChavesProcessadas.Add($NomePasta)) { $TotalDuplicados++; Escrever-Log "[DUPLICADO] Linha ${Linha} já tratada"; continue }
            if ($NomesExistentes.Contains($NomePasta)) { $TotalExistentes++; Escrever-Log "[EXISTE] Linha ${Linha}: pasta já existente"; continue }
            if ($DryRun) { $TotalSimuladas++; Escrever-Log "[SIMULAÇÃO] Linha ${Linha}: pasta seria criada"; continue }
            Add-PnPFolder -Name $NomePasta -Folder $PastaFuncionarios
            $TotalCriadas++
            [void]$NomesExistentes.Add($NomePasta)
            Escrever-Log "[CRIADA] Linha ${Linha}: pasta criada"
        }
        catch {
            $TotalErros++
            Escrever-Log "[ERRO] Linha ${Linha}: falha técnica ($($_.Exception.GetType().Name))"
        }
    }
}
catch {
    $TotalErros++
    Escrever-Log "[ERRO FATAL] Falha geral na execução ($($_.Exception.GetType().Name))"
}
finally {
    Escrever-Log "Resumo:"
    Escrever-Log "Total de registros lidos: $TotalLidos"
    Escrever-Log "Total de pastas criadas: $TotalCriadas"
    Escrever-Log "Total de pastas simuladas: $TotalSimuladas"
    Escrever-Log "Total de pastas já existentes: $TotalExistentes"
    Escrever-Log "Total de duplicados filtrados: $TotalDuplicados"
    Escrever-Log "Total de registros ignorados: $TotalIgnorados"
    Escrever-Log "Total de erros: $TotalErros"
    $LogWriter.Dispose()
}
