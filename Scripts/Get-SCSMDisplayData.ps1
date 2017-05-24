<#
  Script de récupération de données pour SCSM
  Crée par Berret Luca (LUB)
  Dernière modification le 22.05.2017
#>

#Récupération du chemin où le script est exéctué.
$ScriptPath = Split-Path -Parent $PSScriptRoot
$Config = Get-Content -Path $ScriptPath\SCSM-Config.json | Out-String | ConvertFrom-Json    #Récupération des données de config depuis le fichier .json

#Importation du module SMLetls si il n'est pas déja chargé
if (Get-Module -Name SMLets) {
    Import-Module -Name $Config.smlets_path -Force
    Write-Host "Module imported"
} else {
    Write-Host "Module already imported"
}

#Assignation des constantes depuis la config
$SERVER = $Config.servername

$OUTPUT_PATH = $Config.script_output
$LOGFILEPATH = $OUTPUT_PATH + $Config.log_file

$IR_FILE = $OUTPUT_PATH + $Config.ir_csv_file
$SR_FILE = $OUTPUT_PATH + $Config.sr_csv_file

$PSDefaultParameterValues = @{ "Get-SCSM*:ComputerName" = $SERVER }

#Variables Globales : Etat des SR
$SRStatusNew = Get-SCSMEnumeration -Name "ServiceRequestStatusEnum.New"
$SRStatusInProgress = Get-SCSMEnumeration -Name "ServiceRequestStatusEnum.InProgress"

#Récupération de toutes les données BRUT et des classes qui permettront de lier les données ensembles.
try {
    $IRClass = Get-SCSMClass -Name "System.WorkItem.Incident$"                               #Classe des IR
    $SRClass = Get-SCSMClass -Name "System.WorkItem.ServiceRequest$"                         #Classe des SR
	
    $AffectedUserRelClass = Get-SCSMRelationshipClass System.WorkItemAffectedUser$           #Classe de relation : utilisateur affecté
    $AssignedUserRelClass = Get-SCSMRelationshipClass System.WorkItemAssignedToUser$         #Classe de relation : attribué à
    $SLARelClass = Get-SCSMRelationshipClass System.WorkItemHasSLAInstanceInformation$       #Classe de relation : SLA

    $IRStatusEnumActive = Get-SCSMEnumeration -Name IncidentStatusEnum.Active                #Statis d'un IR : "Actif"
    $SRStatusEnumInProgress = Get-SCSMEnumeration -Name ServiceRequestStatusEnum.InProgress  #Status d'une SR : "En cours"

	#Récuperation de tous les IR BRUTS qui sont actifs
    $AllIncidents = Get-SCSMObject -Class $IRClass | Where-Object { $_.Status.Ordinal -eq $IRStatusEnumActive[0].Ordinal}
	#Récuperation de toutes les SR qui sont en cours
    $AllServiceRequests = Get-SCSMObject -Class $SRClass | Where-Object { $_.Status.Ordinal -eq $SRStatusEnumInProgress[0].Ordinal }
} catch [Exception] {
	#En cas d'erreur -> écrire l'erreur dans le log et quitter le script pour éviter les dégats
    Clear-Content -Path $LOGFILEPATH
    Add-Content -Path $LOGFILEPATH -Value "Impossible de mettre à jour les données."
    $CurrentDate = Get-Date -Format dd.MM.yyy-hh_mm_ss
    $ErrorFileName = $OUTPUT_PATH + "errors\error-$CurrentDate.txt"
    New-Item -ItemType File -Path $ErrorFileName -Value $_.Exception | Out-Null
    Add-Content -Path $ErrorFileName -Value (([Environment]::NewLine) + "Config : $Config")
    Write-Host "Erreur Fatale ! voir log $ErrorFileName"
    exit
}

#Fonction qui permet de sortir les données pour les SR
Function Get-SRData
{
    Param([Object[]]$Collection) #En param -> tableau de toutes les SR BRUT.
    Process
    {
		#Création du tableau de sortie
        $Output = @()
		
		#Boucle à travers toutes les SR BRUTES
        foreach ($Item in $Collection)
        {
			#Création de l'object qui sera inséré dans le tableau
            $CurrentSR = New-Object System.Object
			
			#Récupération de l'utilisateur attribué
			$CurrentAssignedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AssignedUserRelClass -ErrorAction Stop
			
			#Récupération des données
            $CurrentSR | Add-Member -Type NoteProperty -Name ID -Value $Item.Id                                 #ID
            $CurrentSR | Add-Member -Type NoteProperty -Name Title -Value $Item.Title                           #Titre
            $CurrentSR | Add-Member -Type NoteProperty -Name AssignedUser -Value $CurrentAssignedUser.DisplayName  #Utilisateur attribué
            $CurrentSR | Add-Member -Type NoteProperty -Name Priority -Value $Item.Priority.Name                #Priorité
            $CurrentSR | Add-Member -Type NoteProperty -Name Source -Value $Item.Source.Name                    #Source

            #Pour la date de création, il faut la convertir en TimeZone locale puis, en format UNIX
            $CreatedDateTimestamp = [Math]::Floor([double]::Parse((Get-Date($Item.CreatedDate) -UFormat "%s")))
            $CurrentSR | Add-Member -Type NoteProperty -Name CreatedDate -Value $CreatedDateTimestamp

            $History = Get-SCSMObjectHistory -Object $Item
            $EffectiveCreatedDate = ($History.History | Where-Object { ($_.Changes.OldValue.Value -eq $SRStatusNew) -and ($_.Changes.NewValue.Value -eq $SRStatusInProgress) }).LastModified
            $EffectiveCreatedDateTimestamp = [Math]::Floor([double]::Parse((Get-Date($EffectiveCreatedDate) -UFormat "%s")))

            $CurrentSR | Add-Member -Type NoteProperty -Name EffectiveCreatedDate -Value $EffectiveCreatedDateTimestamp

			#Ajoute de l'objet dans le tableau
            $Output += $CurrentSR
        }
		#La fonction retourne le tableau
        return $Output
    }
}

$OutputIR = @()

#Pour chaque incident -> Récupération des données et sortie dans un tableau.
foreach ($Item in $AllIncidents) {
	#Récupération de l'utilisateur affecté, de l'utilisateur attribué et des objets SLA sur l'incident
    $CurrentAffectedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AffectedUserRelClass -ErrorAction Stop
    $CurrentAssignedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AssignedUserRelClass -ErrorAction Stop
    $CurrentSLA = Get-SCSMRelatedObject -SMObject $Item -Relationship $SLARelClass -ErrorAction Stop

    #Création de l'object qui sera inséré dans le tableau
    $CurrentIncident = New-Object System.Object
    
    #Ajout des propriétés à l'objet

    $CurrentIncident | Add-Member -Type NoteProperty -Name ID -Value $Item.Id                               #ID
    $CurrentIncident | Add-Member -Type NoteProperty -Name Title -Value $Item.Title                         #Title
    $CurrentIncident | Add-Member -Type NoteProperty -Name Priority -Value $Item.Priority                   #Priorité

    #Pour l'utilisateur attribué, remplacement du texte par "Non attribué" si texte = null
    if ($CurrentAssignedUser -eq $null) {
        $CurrentIncident | Add-Member -Type NoteProperty -Name AssignedUser -Value "Non attribué"
    } else {
        $CurrentIncident | Add-Member -Type NoteProperty -Name AssignedUser -Value $CurrentAssignedUser.DisplayName #Assigned User
    }

    $CurrentIncident | Add-Member -Type NoteProperty -Name AffectedUser -Value $CurrentAffectedUser.DisplayName     #Affected User

    #Pour la date de création, il faut la convertir en TimeZone locale puis, en temps UNIX
    $CreatedDateTimestamp = [Math]::Floor([double]::Parse((Get-Date($Item.CreatedDate) -UFormat "%s")))
    $CurrentIncident | Add-Member -Type NoteProperty -Name CreatedDate -Value $CreatedDateTimestamp

    #Pour les SLA, si il y en a plusieurs, prendre celle qui est actuellement active.
    $ActiveSLA = $null

    if ($CurrentSLA -ne $null -and $CurrentSLA.GetType() -eq [Object[]]) {
        foreach ($ItemSLA in $CurrentSLA)
        {
            if (-not $ItemSLA.IsCancelled) #Si plusieurs SLAs, prendre celle qui n'est pas "Annulée"
            {
                $ActiveSLA = $ItemSLA
            }
        }
    } else {
        $ActiveSLA = $CurrentSLA
    }

    $ActiveSLATimestamp = [Math]::Floor([double]::Parse((Get-Date($ActiveSLA.TargetEndDate) -UFormat "%s")))
    $CurrentIncident | Add-Member -Type NoteProperty -Name SLAEndDate -Value $ActiveSLATimestamp           #Date de fin prévue
    $CurrentIncident | Add-Member -Type NoteProperty -Name SLAStatus -Value $ActiveSLA.Status.Name         #Status SLA

    $CurrentIncident | Add-Member -Type NoteProperty -Name Source -Value $Item.Source                      #Source

    #Pour la notification sonore du nouvel incident -> il faut récuperer l'heure à laquelle le serveur à reçu les données.
    $History = Get-SCSMObjectHistory -Object $Item
    $EffectiveCreateDate = $History[0].History[0].LastModified
    $EffectiveCreateTimestamp = [Math]::Floor([double]::Parse((Get-Date($EffectiveCreateDate) -UFormat "%s")))

    #Ajout de l'objet de la date de création effective dans le tableau.
    $CurrentIncident | Add-Member -Type NoteProperty -Name EffectiveCreateDate -Value $EffectiveCreateTimestamp         #Date de création effective

    #Ajout de l'objet dans le tableau des incidents
    $OutputIR += $CurrentIncident
}

#Tri des incidents, par date de création descendante et si même date de création, par priorité ascendante
$OutputIR = $OutputIR | Sort-Object @{Expression={$_.CreatedDate.Date};Descending=$true},@{Expression={$_.Priority};Ascending=$true}

#Exportation des IR en CSV
$OutputIR | Export-Csv $IR_FILE -Delimiter ";" -Encoding UTF8 -NoTypeInformation
Write-Host "Requête, tri et export des IR terminé sans erreurs."

#Exportation des SR en CSV
$OutputSR = Get-SRData -Collection $AllServiceRequests
$OutputSR | Export-Csv $SR_FILE -Delimiter ";" -Encoding UTF8 -NoTypeInformation
Write-Host "Requête, tri et export des SR terminé dans erreurs."

#Création (si existe pas) et ajout de la DateTime::Now dans le fichier log
if (Test-Path -Path $LOGFILEPATH)
{
    Clear-Content -Path $LOGFILEPATH
    Add-Content -Path $LOGFILEPATH -Value ([DateTime]::Now)
}
else
{
    New-Item -Path $LOGFILEPATH -ItemType File | Out-Null
    Add-Content -Path $LOGFILEPATH -Value ([DateTime]::Now)
}

#Suppressions du module SMLets
Remove-Module SMLets -Force -ErrorAction SilentlyContinue