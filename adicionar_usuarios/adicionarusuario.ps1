# 1. Definir o domínio base automaticamente
$Domain = Get-ADDomain
$DomainDN = $Domain.DistinguishedName

# 2. Criar a estrutura base de OUs (com proteção contra exclusão acidental)
$TopOU = "ORG" # Nome de exemplo da OU principal
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
$Password = Read-Host "Digite a senha inicial do usuário de exemplo" -AsSecureString

# --- Usuário fictício de exemplo ---
New-ADUser -Name "Usuario Exemplo" `
           -DisplayName "Usuario Exemplo" `
           -GivenName "Usuario" `
           -Surname "Exemplo" `
           -SamAccountName "usuario.exemplo" `
           -UserPrincipalName "usuario.exemplo@$($Domain.DNSRoot)" `
           -Path $TargetOU `
           -AccountPassword $Password `
           -Enabled $true `
           -ChangePasswordAtLogon $true `
           -Department "TI" `
           -Title "Gestor de SysAdmin"
