$fichier="C:\users.txt"
$logfile="C:\logfile.log"

#Creation user basic
function create_users {
    param([string[]]$params)
    $local=[ADSI]"WinNT://."
    $nom=$params[0]
    $nom_complet=$params[1]
    $description=$params[2]
    $compte=[ADSI]"WinNT://./$nom"
    $date=Get-Date -UFormat "%Y-%m-%d %H:%M"
    If (!$compte.path)
    {
        $utilisateur=$local.create("user",$nom)
        $utilisateur.InvokeSet("Description",$description)
        $utilisateur.InvokeSet("FullName",$nom_complet)
        $utilisateur.CommitChanges()
        Write "Add $nom : success" >> $logfile
    }
    else {
        Write "[$date] User $nom already exist" >> $logfile
    }
}

function lire_fichier {
    param([string]$file_path)
    If (Test-Path $file_path)
    {
        $colLignes=Get-Content $file_path

        Foreach ($ligne in $colLignes)
        {
            $tabCompte=$ligne.Split("/")
            create_users($tabCompte)
        }
    }
    else {
        Write "File $file_path does not exist" >> $logfile
    }
}

#Creation d'une OU
function create_ou {
    param([string]$name)
    Import-Module ActiveDirectory
    New-ADOrganizationalUnit -Name $nom -Path "OU=stages,DC=newyork.domain,DC=LOC"
}

#Creation utilisateur sur AD [a tester]
function adduser {
    Import-Module ActiveDirectory
    param([string[]]$params)
    $nom=$params[0]
    $prenom=$params[1]
    $description=$params[2]
    $ou=$params[3]
    New-ADUser -name $prenom" "$nom -ChangePasswordAtLogon 1 -Path "OU=stage,OU=$ou,DC=newyork.domain,DC=LOC" -Description $description -DisplayName $prenom" "$nom -Enabled $true -GivenName $prenom -SamAccountName $prenom"."$nom -AccountPassword (ConvertTo-SecureString "P@ssword" -AsPlainText -force)
    Add-ADGroupMember -Identity "$ou" -Member $prenom"."$nom
}

# Exécution
#lire_fichier($fichier)
create_ou("test")
