# Adicionar usuário no Active Directory

O script `adicionarusuario.ps1` cria uma estrutura inicial de Unidades Organizacionais (OUs) no domínio atual e adiciona um usuário de exemplo diretamente na OU de TI. Os nomes abaixo são fictícios.

## Pré-requisitos

- Windows Server ou computador com as ferramentas de administração do Active Directory instaladas.
- Módulo PowerShell `ActiveDirectory` disponível.
- Permissão para criar OUs e usuários no domínio.
- Execução em uma sessão autenticada no domínio correto.

O módulo pode ser carregado manualmente com:

```powershell
Import-Module ActiveDirectory
```

## Estrutura criada

O domínio base é obtido automaticamente com `Get-ADDomain`. Usando `example.com` apenas como exemplo, a estrutura seria:

```text
OU=ORG,DC=example,DC=com
├── OU=Departamentos
│   └── OU=TI
├── OU=Computadores
├── OU=Servidores
├── OU=Grupos
└── OU=Contas_Servico
```

Todas as OUs são criadas com `ProtectedFromAccidentalDeletion` habilitado.

## Usuário criado

O usuário é criado em:

```text
OU=TI,OU=Departamentos,OU=ORG,DC=example,DC=com
```

| Propriedade | Valor |
| --- | --- |
| Nome | Usuario Exemplo |
| Display name | Usuario Exemplo |
| Nome de login | `usuario.exemplo` |
| UPN (exemplo) | `usuario.exemplo@example.com` |
| Departamento | TI |
| Cargo | Gestor de SysAdmin |
| Estado | Habilitado |
| Alteração de senha | Obrigatória no primeiro logon |

## Execução

Abra o PowerShell como administrador, navegue até a pasta do script e execute:

```powershell
Set-Location "C:\caminho\adicionar_usuarios"
Import-Module ActiveDirectory
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\adicionarusuario.ps1
```

Para confirmar o domínio antes de executar o provisionamento:

```powershell
Get-ADDomain | Select-Object DNSRoot, DistinguishedName
```

## Senhas

As senhas não ficam armazenadas no script. Durante a execução, o PowerShell solicita a senha inicial de forma segura. No caso do usuário do Active Directory, a troca continua obrigatória no primeiro logon.

Como o script não verifica se as OUs ou o usuário já existem, uma segunda execução pode gerar erros de objeto duplicado. Confirme a estrutura atual antes de executá-lo novamente.
