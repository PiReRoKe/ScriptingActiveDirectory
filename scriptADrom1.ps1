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
    
    If ([ADSI]::Exists("LDAP://OU=$ou,OU=stages,DC=newyork,DC=domain"))
    {
        Write "[$date] OU $ou already exist" >> $logfile
    }
    else {
        create_ou($ou)
        Write "[$date] OU $ou added successfully" >> $logfile
    }
    
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

function lire_fichier {
    param([string]$file_path)
    If (Test-Path $file_path)
    {
        $colLignes=Get-Content $file_path

        Foreach ($ligne in $colLignes)
        {
            $tabCompte=$ligne.Split("/")
            adduser($tabCompte)
        }
    }
    else {
        Write "File $file_path does not exist" >> $logfile
    }
}

#Execute
lire_fichier($fichier)
