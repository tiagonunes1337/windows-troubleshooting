# 1. Definir o domínio base automaticamente
$DomainDN = (Get-ADDomain).DistinguishedName # Retorna: DC=hrbr,DC=com

# 2. Criar a estrutura base de OUs (com proteção contra exclusão acidental)
$TopOU = "HRBR" # Nome da OU principal
New-ADOrganizationalUnit -Name $TopOU -Path $DomainDN -ProtectedFromAccidentalDeletion $true

# Sub-OUs padrão de mercado
$SubOUs = @("Departamentos", "Computadores", "Servidores", "Grupos", "Contas_Servico")
foreach ($ou in $SubOUs) {
    New-ADOrganizationalUnit -Name $ou -Path "OU=$TopOU,$DomainDN" -ProtectedFromAccidentalDeletion $true
}

# Sub-OU do setor (ex: TI dentro de Departamentos)
New-ADOrganizationalUnit -Name "TI" -Path "OU=Departamentos,OU=$TopOU,$DomainDN" -ProtectedFromAccidentalDeletion $true

# 3. Definir o caminho final onde o usuário vai morar
$TargetOU = "OU=TI,OU=Departamentos,OU=$TopOU,$DomainDN"

# 4. Criar o Usuário apontando direto para a OU com o parâmetro -Path
$Password = Read-Host "Digite a senha inicial do usuário Tiago de Oliveira" -AsSecureString

# --- USUÁRIO 1: Tiago Oliveira ---
New-ADUser -Name "Tiago de Oliveira" `
           -DisplayName "Tiago Oliveira" `
           -GivenName "Tiago" `
           -Surname "de Oliveira" `
           -SamAccountName "tiago.oliveira" `
           -UserPrincipalName "tiago.oliveira@hrbr.com" `
           -Path $TargetOU `
           -AccountPassword $Password `
           -Enabled $true `
           -ChangePasswordAtLogon $true `
           -Department "TI" `
           -Title "Gestor de SysAdmin"

