$fichier="C:\users.txt"
$logfile="C:\logfile.log"

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

# Exécution
lire_fichier($fichier)
