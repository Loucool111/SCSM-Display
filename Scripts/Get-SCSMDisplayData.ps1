<#
  Script de récupération de données pour SCSM
  Crée par Berret Luca (LUB)
  Dernière modification le 05.10.2017
#>

#Fonction qui écrit un log d'erreur
function Log-Error
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ErrorRecord]
        $ErrorItem
	)
	
	Process
	{
		$TimeStamp = Get-Date -Format 'yyy.MM.dd HH:mm:ss'
        $Line = "$TimeStamp -> " + $ErrorItem.ToString() + " : " + $ErrorItem.InvocationInfo.PositionMessage
        
        $CurrentDate = Get-Date -Format yyy-MM-dd
        $ErrorFileName = $LOGPATH + "Error-$CurrentDate.log"

        if (!(Test-Path $ErrorFileName)) {
            New-Item -ItemType File -Path $ErrorFileName -Value $Line | Out-Null
        } else {
            Add-Content -Path $ErrorFileName -Value (([Environment]::NewLine) + $Line)
        }
	}
}

#Fonction qui change les datetime en unix time
function Convert-ToUnixTimeSeconds
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [DateTime]
        $Date
    )

    Process
    {
        $Result = [Math]::Floor([double]::Parse((Get-Date($Date) -UFormat "%s")))

        Write-Output -InputObject $Result
    }
}

#On clear les erreurs avant le script
$Error.Clear()

#Récupération du chemin où le script est exéctué.
$ScriptPath = Split-Path -Parent $PSScriptRoot

#Récupération des données de config depuis le fichier .json
$Config = Get-Content -Path $ScriptPath\SCSM-Config.json | Out-String | ConvertFrom-Json

#Importation du module SMLetls si il n'est pas déja chargé
if (!(Get-Module -Name SMLets)) {
    Import-Module -Name SMLets -ErrorAction Stop
    Write-Host "Module imported"
} else {
    Write-Host "Module already imported"
}

#Assignation des constantes depuis la config
$SERVER = $Config.SCSMManagementServerFQDN

$CACHEPATH = $Config.CachePath
$LOGPATH = $Config.LogPath

$LOGFILEPATH = $LOGPATH + $Config.LogFile

$IRCACHEFILE = $CACHEPATH + $Config.IncidentRequestCacheFile
$SRCACHEFILE = $CACHEPATH + $Config.ServiceRequestCacheFile

#Cette variable permet de forcer des propriétés par défaut sur certaines commandes
$PSDefaultParameterValues = @{ "Get-SCSM*:ComputerName" = $SERVER }

#Récupération de toutes les données BRUT et des classes qui permettront de lier les données ensembles.
$IRClass = Get-SCSMClass -Name 'System.WorkItem.Incident$'              #Classe des IR
$SRClass = Get-SCSMClass -Name 'System.WorkItem.ServiceRequest$'        #Classe des SR

$AffectedUserRelClass = Get-SCSMRelationshipClass -Name 'System.WorkItemAffectedUser$'     #Classe de relation : utilisateur affecté
$AssignedUserRelClass = Get-SCSMRelationshipClass -Name 'System.WorkItemAssignedToUser$'   #Classe de relation : attribué à
$SLARelClass = Get-SCSMRelationshipClass -Name 'System.WorkItemHasSLAInstanceInformation$' #Classe de relation : SLA

$IRStatusActive = Get-SCSMEnumeration -Name 'IncidentStatusEnum.Active'                    #Status d'un IR : "Actif"
$SRStatusInProgress = Get-SCSMEnumeration -Name 'ServiceRequestStatusEnum.InProgress'      #Status d'une SR : "En cours"
$SRStatusNew = Get-SCSMEnumeration -Name 'ServiceRequestStatusEnum.New'                    #Status d'une SR : "Nouveau"

#Récuperation de tous les IR qui sont actifs
$AllIncidents = Get-SCSMObject -Class $IRClass | Where-Object { $_.Status.Ordinal -eq $IRStatusActive[0].Ordinal}
#Récuperation de toutes les SR qui sont en cours
$AllServiceRequests = Get-SCSMObject -Class $SRClass | Where-Object { $_.Status.Ordinal -eq $SRStatusInProgress[0].Ordinal }

#Fonction qui permet de filtrer les données pour les SR
Function Filter-SRData
{
    [CmdletBinding()]
    Param (
        #En param -> tableau de toutes les SR brut.
        [Parameter(Mandatory=$true)]
        [Object[]]
        $Collection
    ) 
    Process
    {
		#Création du tableau de sortie
        $OutputSR = @()
		
		#Boucle à travers toutes les SR bruts
        foreach ($Item in $Collection)
        {
			#Récupération de l'utilisateur attribué
			$CurrentAssignedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AssignedUserRelClass -ErrorAction Stop

            #Pour la date de création, il faut la convertir en TimeZone locale puis, en format UNIX
            $CreatedDateTimestamp = Convert-ToUnixTimeSeconds -Date $Item.CreatedDate

            #Récupération de l'historique
            $History = Get-SCSMObjectHistory -Object $Item
            #Réupération de la date de modification de l'élément de l'historique changement du statut de Nouveau à En cours
            $EffectiveCreatedDate = ($History.History | Where-Object { ($_.Changes.OldValue.Value -eq $SRStatusNew) -and ($_.Changes.NewValue.Value -eq $SRStatusInProgress) }).LastModified
            #Transformation en temps UNIX
            $EffectiveCreatedDateTimestamp = Convert-ToUnixTimeSeconds -Date $EffectiveCreatedDate
            
            #On ajoute toutes les propriétés dans une OrderedDictionary  
            $SRProperties = [Ordered]@{
                'ID' = $Item.Id;
                'Title' = $Item.Title;
                'AssignedUser' = if ($CurrentAssignedUser.Initials -ne $null) { $CurrentAssignedUser.Initials.ToUpper() } else { "Non attribué" };
                'Priority' = $Item.Priority.Name;
                'Source' = $Item.Source.Name;
                'CreatedDate' = $CreatedDateTimestamp;
                'EffectiveCreatedDate' = $EffectiveCreatedDateTimestamp
            }

            #On convertit le dictionnaire en PSCustomObject
            $CurrentSR = New-Object -TypeName PSCustomObject -Property $SRProperties

			#Finalement, on ajoute le PSCustomObject dans le tableau
            $OutputSR += $CurrentSR
        }
		#On retourne le tableau
        return $OutputSR
    }
}

#Fonction qui permet de filtrer les données pour les IR
Function Filter-IRData
{
    [CmdletBinding()]
	Param (
        #En param -> tableau de tout les IR BRUT.
        [Parameter(Mandatory=$true)]
        [Object[]]
        $Collection
    )
	Process
	{
        #Création du tableau de sortie
		$OutputIR = @()
		
		#Pour chaque incident -> Récupération des données et sortie dans un tableau.
		foreach ($Item in $Collection)
		{
			#Récupération de l'utilisateur affecté, de l'utilisateur attribué et des objets SLA sur l'incident
			$CurrentAffectedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AffectedUserRelClass -ErrorAction Stop
			$CurrentAssignedUser = Get-SCSMRelatedObject -SMObject $Item -Relationship $AssignedUserRelClass -ErrorAction Stop
			$CurrentSLA = Get-SCSMRelatedObject -SMObject $Item -Relationship $SLARelClass -ErrorAction Stop
            
            #Si il n'y a pas d'utilisateur assigné, on affiche "Non attribué"
            $AssignedUser = if ($CurrentAssignedUser -eq $null) { "Non attribué" } else { $CurrentAssignedUser.DisplayName }

			#Pour la date de création, il faut la convertir en TimeZone locale puis, en temps UNIX
			$CreatedDateTimestamp = Convert-ToUnixTimeSeconds -Date $Item.CreatedDate
			
			#Pour les SLA, si il y en a plusieurs, prendre celle qui est actuellement active.
			$ActiveSLA = $null
			
			if ($CurrentSLA -ne $null -and $CurrentSLA.GetType() -eq [Object[]]) {
				foreach ($ItemSLA in $CurrentSLA) {
					if (-not $ItemSLA.IsCancelled) {
                        #Si plusieurs SLAs, prendre celle qui n'est pas "Annulée"
						$ActiveSLA = $ItemSLA
					}
				}
			} else {
				$ActiveSLA = $CurrentSLA
			}
			
            #Quand les SLA n'ont pas étés appliqués, on n'exporte pas ces 2 propriétés.
            if ($ActiveSLA) {
			    $ActiveSLATimestamp = Convert-ToUnixTimeSeconds -Date $ActiveSLA.TargetEndDate
			    $ActiveSLAStatus =  $ActiveSLA.Status.Name
			}
			
			#Pour la notification sonore du nouvel incident -> il faut récuperer l'heure à laquelle le serveur à reçu les données.
			$History = Get-SCSMObjectHistory -Object $Item
			$EffectiveCreateDate = $History[0].History[0].LastModified
			$EffectiveCreateTimestamp = Convert-ToUnixTimeSeconds -Date $EffectiveCreateDate
			
            #On ajoute toutes les propriétés dans une OrderedDictionary
            $IRProperties = [Ordered]@{
                'ID' = $Item.Id;
                'Title' = $Item.Title;
                'Priority' = $Item.Priority;
                'AssignedUser' = $AssignedUser;
                'AffectedUser' = $CurrentAffectedUser.DisplayName;
                'CreatedDate' = $CreatedDateTimestamp;
                'SLAEndDate' = $ActiveSLATimestamp;
                'SLAStatus' = $ActiveSLAStatus;
                'Source' = $Item.Source;
                'EffectiveCreateDate' = $EffectiveCreateTimestamp
            }

            #On convertit le dictionnaire en PSCustomObject
            $CurrentIncident = New-Object -TypeName PSCustomObject -Property $IRProperties

			#Ajout de l'objet dans le tableau des incidents
			$OutputIR += $CurrentIncident
		}
		#On retourne le tableau
		return $OutputIR
	}
}

if ($AllIncidents -ne $null) {
    #Filtre des IR grâce à la fonction ci-dessus
    $FilteredIR = Filter-IRData -Collection $AllIncidents
}

if ($AllServiceRequests -ne $null) {
    #Filtre des SR grâce à la fonction ci-dessus
    $FilteredSR = Filter-SRData -Collection $AllServiceRequests
}

#Tri des incidents, par date de création descendante et si même date de création, par priorité ascendante
$FilteredIR = $FilteredIR | Sort-Object @{Expression={$_.CreatedDate.Date};Descending=$true},@{Expression={$_.Priority};Ascending=$true}

#Création de l'objet UTF8Encoding sans BOM
$UTF8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false

#Exportation des IR en CSV (Encodage UTF-8 sans BOM)
$FilteredIRCSV = $FilteredIR | ConvertTo-Csv -Delimiter ";" -NoTypeInformation

#Si le tableau est vide, il faut quand même écrire le fichier alors on exporte String.Empty
if ($FilteredIRCSV) {
    [System.IO.File]::WriteAllLines($IRCACHEFILE, $FilteredIRCSV, $UTF8NoBomEncoding)
} else {
    Clear-Content -Path $IRCACHEFILE
}

#Message de succès pour l'utilisateur
Write-Host "Requête, tri et export des IR terminé sans erreurs."

#Exportation des SR en CSV (Encodage UTF-8 sans BOM)
$FilteredSRCSV = $FilteredSR | ConvertTo-Csv -Delimiter ";" -NoTypeInformation

#Si le tableau est vide, on vide le fichier
if ($FilteredSRCSV) {
    [System.IO.File]::WriteAllLines($SRCACHEFILE, $FilteredSRCSV, $UTF8NoBomEncoding)
} else {
    Clear-Content -Path $SRCACHEFILE
}

#Message de succès pour l'utilisateur
Write-Host "Requête, tri et export des SR terminé sans erreurs."

#Création (si existe pas) et ajout de la DateTime::Now dans le fichier log
if (Test-Path -Path $LOGFILEPATH) {
    Clear-Content -Path $LOGFILEPATH
    $Date = "{0}={1}" -f [Math]::Floor([double]::Parse((Get-Date -UFormat %s))), [DateTime]::Now
    Add-Content -Path $LOGFILEPATH -Value $Date
} else {
    New-Item -Path $LOGFILEPATH -ItemType File | Out-Null
    $Date = "{0}={1}" -f [Math]::Floor([double]::Parse((Get-Date -UFormat %s))), [DateTime]::Now
    Add-Content -Path $LOGFILEPATH -Value $Date
}

#Log de toutes les erreurs
foreach ($Item in $Error) {
    Log-Error -ErrorItem $Item
}

#Clean
Remove-Variable -Name 'AllIncidents', 'AllServiceRequests', 'FilteredIR', 'FilteredSR', 'FilteredIRCSV', 'FilteredSRCSV'
[GC]::Collect()

#Suppression du module SMLets
Remove-Module SMLets -Force -ErrorAction SilentlyContinue