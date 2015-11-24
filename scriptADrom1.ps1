$fichier="C:\users.txt"
$logfile="C:\logfile.log"
$date=Get-Date -UFormat "%Y-%m-%d %H:%M"

#Creation d'une OU
function create_ou {
    param([string]$nom)
    Import-Module ActiveDirectory
    New-ADOrganizationalUnit -Name $nom -Path "ou=stages,dc=newyork,dc=domain"
}

#Creation utilisateur sur AD
function adduser {
    param([string[]]$params)
    Import-Module ActiveDirectory
    $nom=$params[0]
    $prenom=$params[1]
    $description=$params[2]
    $ou=$params[3]
    If (dsquery user -samid "$prenom.$nom")
    {
        Write "[$date] User $nom already exist" >> $logfile
    }
    else {
        New-ADUser -name $prenom" "$nom -ChangePasswordAtLogon 1 -Path "ou=$ou,ou=stages,dc=newyork,dc=domain" -Description $description -DisplayName $prenom" "$nom -Enabled $true -GivenName $prenom -SamAccountName $prenom"."$nom -AccountPassword (ConvertTo-SecureString "P@ssword" -AsPlainText -force)
        Write "[$date] Add user $prenom.$nom : success" >> $logfile
    }
    #Add-ADGroupMember -Identity "$ou" -Member $prenom"."$nom
}

# Ex�cution
$nom=Read-Host -Prompt "Utilisateur - Nom :"
$prenom=Read-Host -Prompt "Utilisateur - Prénom"
$description=Read-Host -Prompt "Utilisateur - Description"
$ou=Read-Host -Prompt "Dans quelle unité d'organisation doit figurer l'utilisateur ?"
If ([ADSI]::Exists("LDAP://OU=$ou,OU=stages,DC=newyork,DC=domain"))
{
    Write "[$date] OU $ou already exist" >> $logfile
}
else {
    create_ou($ou)
    Write "[$date] OU $ou added successfully" >> $logfile
}
adduser(@($nom,$prenom,$description,$ou))
