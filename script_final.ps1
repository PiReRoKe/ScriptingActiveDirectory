$fichier="C:\users.txt"
$logfile="C:\logfile.log"
$date=Get-Date -UFormat "%Y-%m-%d %H:%M"

#Creation d'une OU
function create_ou {
    param([string]$nom)
    Import-Module ActiveDirectory
    $folderpath="F:\DATA\DATA\Stages\$nom\commun"
    $sharename="Commun"
    $shares=[WMICLASS]'WIN32_Share'

    #Creation de l'OU
    If ([ADSI]::Exists("LDAP://OU=$nom,OU=stages,DC=newyork,DC=domain"))
    {
        Write "[$date] OU $nom already exist" >> $logfile
    }
    else {
        New-ADOrganizationalUnit -Name $nom -Path "ou=stages,dc=newyork,dc=domain"
        Write "[$date] OU $nom added successfully" >> $logfile
    }

    #Creation du dossier partage de l'OU
    If (Test-Path $folderpath)
    {
        Write "[$date] Folder $folderpath already exists" >> $logfile
    }
    else {
        New-Item -type directory -Path $folderpath
        Write "[$date] Folder $folderpath successfully created" >> $logfile
        #Permissions
        $trustee=([wmiclass]'Win32_trustee').psbase.CreateInstance()
        $trustee.Domain="newyork"
        $trustee.Name="stagiaires"

        $ace=([wmiclass]'Win32_ACE').psbase.CreateInstance()
        $ace.AccessMask=2032127
        $ace.AceFlags=3
        $ace.AceType=0
        $ace.Trustee=$trustee

        $trustee2=([wmiclass]'Win32_trustee').psbase.CreateInstance()
        $trustee2.Domain="newyork"
        $trustee2.Name="Administrateurs"

        $ace2=([wmiclass]'Win32_ACE').psbase.CreateInstance()
        $ace2.AccessMask=2032127
        $ace2.AceFlags=3
        $ace2.AceType=0
        $ace2.Trustee=$trustee2

        #Definition des propriétaires
        $sd=([wmiclass]'Win32_SecurityDescriptor').psbase.CreateInstance()
        $sd.ControlFlags=4
        $sd.DACL=$ace
        $sd.owner=$trustee2

        #Creation du partage
        $shares.create($folderpath, $sharename, 0, 100, "Description", "", $sd) | Out-Null

        #Permissions NTFS
        $Acl = Get-Acl $folderpath
        $Acl.SetAccessRuleProtection($True, $False)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrateurs','FullControl','ContainerInherit, ObjectInherit', 'None', 'Allow')
        $Acl.AddAccessRule($rule)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("stagiaires",'FullControl', 'ContainerInherit, ObjectInherit', 'None', "Allow")
        $Acl.AddAccessRule($rule)

        Set-Acl $folderpath $Acl

        Write "[$date] Set permissions to $folderpath : success" >> $logfile
    }
}

#Creation utilisateur sur AD
function adduser {
    param([string[]]$params)
    Import-Module ActiveDirectory
    $nom=$params[0]
    $prenom=$params[1]
    $description=$params[2]
    $ou=$params[3]

    create_ou($ou)

    If (dsquery user -samid "$prenom.$nom")
    {
        Write "[$date] User $nom already exist" >> $logfile
    }
    else {
        New-ADUser -name $prenom" "$nom -ChangePasswordAtLogon 1 -Path "ou=$ou,ou=stages,dc=newyork,dc=domain" -Description $description -DisplayName $prenom" "$nom -Enabled $true -GivenName $prenom -SamAccountName $prenom"."$nom -AccountPassword (ConvertTo-SecureString "P@ssword" -AsPlainText -force) -ScriptPath "boot.bat"
        Write "[$date] Add user $prenom.$nom : success" >> $logfile
    }
    Add-ADGroupMember -Identity "stagiaires" -Member $prenom"."$nom
    Write "[$date] Added $prenom.$nom to group stagiaires" >> $logfile
}

function create_folder {
    param([string[]]$params)
    $nom=$params[0]
    $prenom=$params[1]
    $nom_formation=$params[3]
    $folderpath="F:\DATA\DATA\Stages\$nom_formation\$prenom.$nom"
    $shares=[WMICLASS]'WIN32_Share'
    $sharename="$prenom.$nom"

    #Creation du dossier
    New-Item -type directory -Path $folderpath

    #Définitions des permissions
    $trustee=([wmiclass]'Win32_trustee').psbase.CreateInstance()
    $trustee.Domain="newyork"
    $trustee.Name="$prenom.$nom"

    $ace=([wmiclass]'Win32_ACE').psbase.CreateInstance()
    $ace.AccessMask=2032127
    $ace.AceFlags=3
    $ace.AceType=0
    $ace.Trustee=$trustee

    $trustee2=([wmiclass]'Win32_trustee').psbase.CreateInstance()
    $trustee2.Domain="newyork"
    $trustee2.Name="Administrateurs"

    $ace2=([wmiclass]'Win32_ACE').psbase.CreateInstance()
    $ace2.AccessMask=2032127
    $ace2.AceFlags=3
    $ace2.AceType=0
    $ace2.Trustee=$trustee2

    #Definition des propriétaires
    $sd=([wmiclass]'Win32_SecurityDescriptor').psbase.CreateInstance()
    $sd.ControlFlags=4
    $sd.DACL=$ace
    $sd.owner=$trustee2

    #Creation du partage
    $shares.create($folderpath, $sharename, 0, 100, "Description", "", $sd) | Out-Null

    #Permissions NTFS
    $Acl = Get-Acl $folderpath
    $Acl.SetAccessRuleProtection($True, $False)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrateurs','FullControl','ContainerInherit, ObjectInherit', 'None', 'Allow')
    $Acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$prenom.$nom",'FullControl', 'ContainerInherit, ObjectInherit', 'None', "Allow")
    $Acl.AddAccessRule($rule)

    Set-Acl $folderpath $Acl

    Write "[$date] Set permissions to $folderpath : success" >> $logfile
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
            create_folder($tabCompte)
        }
    }
    else {
        Write "File $file_path does not exist" >> $logfile
    }
}

#Execute
lire_fichier($fichier)

#Reinitialise le fichier utilisateur
#del $fichier
#new-item $fichier -type file
