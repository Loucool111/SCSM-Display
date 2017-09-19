<?php
//debug
error_reporting(-1);

// CONFIG

$config_file = fopen("..\SCSM-Config.json", "r") or die("Unable to open SCSM-Config.json file!");
$config_content = fread($config_file, filesize("..\SCSM-Config.json"));
fclose($config_file);

$config = json_decode($config_content, true);

//Définition de la timezone par défaut
date_default_timezone_set('Europe/Zurich');

// CONSTANTES

$SCRIPTS_PATH = $config["script_output"];

$IR_FILE_PATH = $SCRIPTS_PATH . $config["ir_csv_file"];
$SR_FILE_PATH = $SCRIPTS_PATH . $config["sr_csv_file"];

$LATEST_UPDATE_FILE_PATH = $SCRIPTS_PATH . $config["log_file"];

$SCSM_PRIORITY = "Priority";
$SCSM_STATUS_ACTIVE = "SLAInstance.Status.Active";
$SCSM_STATUS_WARNING = "SLAInstance.Status.Warning";
$SCSM_STATUS_VIOLATION = "SLAInstance.Status.Breached";
$SCSM_UNASSIGNED = "Non attribué";
$SCSM_SOURCE_PORTAL = "ServiceRequestSourceEnum.Portal";

$SCSM_PRIORITY_TRANSLATIONS = array("ServiceRequestPriorityEnum.Low" => "Faible",
                                    "ServiceRequestPriorityEnum.Medium" => "Moyenne",
                                    "ServiceRequestPriorityEnum.High" => "Élevée");

// VARIABLES GLOBALES

$HTML_IR_Unassigned_Table = "";
$HTML_IR_SLA_Table = "";
$HTML_SR_Unassigned_Table = "";
$HTML_SR_Assigned_Table = "";
$HTML_Default_refresh_time = $config['refresh_time'];

//Fonction qui convertit les dates unix en dates normales et qui change et timezone locale
function convertTime($timestamp) {
    if ($timestamp !== '') {
        $date = new DateTime();
        $date->setTimestamp($timestamp);
        $date->setTimezone(new DateTimeZone(date_default_timezone_get()));
        return $date->format('d.m.Y H:i:s');
    } else {
        return "Aucunes SLA";
    }
}

//Création des tables pour les incidents
if (($handle = fopen($IR_FILE_PATH, "r")) !== FALSE) {
    while (($data = fgetcsv($handle, 0, ";")) !== FALSE) {
        if ($data[2] != $SCSM_PRIORITY) {  //way to ignore the header
            if ($data[7] == $SCSM_STATUS_WARNING) {
                $HTML_IR_SLA_Table .= "<tr class=\"alert-warning\" data-source=\"$data[8]\" data-effectivetimestamp=\"$data[9]\">";
                foreach ($data as $key => $value) {
                    if ($value == $SCSM_UNASSIGNED) {
                        $HTML_IR_SLA_Table .= "<td class=\"IncidentUnassigned\">$value</td>";
                    } elseif ($value == $SCSM_STATUS_WARNING) {
                        $HTML_IR_SLA_Table .= '<td class="IncidentWarning"><i class="fa fa-exclamation-triangle fa-2x fa-align-center" aria-hidden="true"></i></td>';
                    } elseif ($key === 5 || $key === 6) {
                        $HTML_IR_SLA_Table .= "<td data-timestamp=\"$value\">" . convertTime($value) . "</td>";
                    } elseif ($key !== 8 && $key !== 9) {
                        $HTML_IR_SLA_Table .= "<td>$value</td>";
                    }
                }
                $HTML_IR_SLA_Table .= '</tr>';
            } elseif ($data[7] == $SCSM_STATUS_VIOLATION) {
                $HTML_IR_SLA_Table .= "<tr class=\"alert-danger\" data-source=\"$data[8]\" data-effectivetimestamp=\"$data[9]\">";
                foreach ($data as $key => $value) {
                    if ($value == $SCSM_UNASSIGNED) {
                        $HTML_IR_SLA_Table .= "<td class=\"IncidentUnassigned\">$value</td>";
                    } elseif ($value == $SCSM_STATUS_VIOLATION) {
                        $HTML_IR_SLA_Table .= '<td class="IncidentViolation"><i class="fa fa-exclamation-circle fa-2x fa-align-center" aria-hidden="true"></i></td>';
                    } elseif ($key === 5 || $key === 6) {
                        $HTML_IR_SLA_Table .= "<td data-timestamp=\"$value\">" . convertTime($value) . "</td>";
                    } elseif ($key !== 8 && $key !== 9) {
                        $HTML_IR_SLA_Table .= "<td>$value</td>";
                    }
                }
                $HTML_IR_SLA_Table .= '</tr>';
            } elseif ($data[3] == $SCSM_UNASSIGNED) {
                $HTML_IR_Unassigned_Table .= "<tr data-source=\"$data[8]\" data-effectivetimestamp=\"$data[9]\">";
                foreach ($data as $key => $value) {
                    if ($value == $SCSM_STATUS_ACTIVE) {
                        $HTML_IR_Unassigned_Table .= '<td><i class="fa fa-check-circle fa-2x fa-align-center" aria-hidden="true"></i></td>';
                    } elseif ($key === 5 || $key === 6) {
                        $HTML_IR_Unassigned_Table .= "<td data-timestamp=\"$value\">" . convertTime($value) . "</td>";
                    } elseif ($key !== 8 && $key !== 9) {
                        $HTML_IR_Unassigned_Table .= "<td class=\"IncidentUnassigned\">$value</td>";
                    }
                }
                $HTML_IR_Unassigned_Table .= '</tr>';
            }
        }
    }
}

//Méthode qui trie entre les SRs attribués et non-attribués.
function SortSRByAssignation($arrayToFill, $data) {
    $arrayToFill .= "<tr data-timestamp=" . $data[6] . ">";
    foreach ($data as $key => $value) {
        if ($key == 2 && $value == null) {
            $arrayToFill .= "<td class=\"UnassignedCell\">Non attribué</td>"; // Remplacer le texte et mettre la classe.
        } elseif ($key != 4 && $key != 5 && $key != 6) {
            $arrayToFill .= "<td>$value</td>";
        }
    }
    $arrayToFill .= "</tr>";
    return $arrayToFill;
}

//Création des tables pour les SR
if (($handle = fopen($SR_FILE_PATH, "r")) !== FALSE) {
    while (($data = fgetcsv($handle, 0, ";")) !== FALSE) {
        if ($data[3] != $SCSM_PRIORITY) {
            if ($data[2] == null) {
                if ($data[4] == $SCSM_SOURCE_PORTAL) {
                    $HTML_SR_Unassigned_Table = SortSRByAssignation($HTML_SR_Unassigned_Table, $data);
                }
            } else {
                $HTML_SR_Assigned_Table = SortSRByAssignation($HTML_SR_Assigned_Table, $data);
            }
        }
    }
}

//Traduction de la priority
foreach ($SCSM_PRIORITY_TRANSLATIONS as $key => $value) {
    $HTML_SR_Unassigned_Table = str_replace($key, $value, $HTML_SR_Unassigned_Table);
    $HTML_SR_Assigned_Table = str_replace($key, $value, $HTML_SR_Assigned_Table);
}

//Affichage de la "Last Update"
$update_file = fopen($LATEST_UPDATE_FILE_PATH, "r") or die("Impossible d'ouvrir le fichier " . $LATEST_UPDATE_FILE_PATH . " ! Merci de vérifier que le fichier existe.");
$latest_update_text = fread($update_file, filesize($LATEST_UPDATE_FILE_PATH));
$latest_update_table = explode('=', $latest_update_text);
$latest_update_timestamp = $latest_update_table[0];
$latest_update_date = $latest_update_table[1];
fclose($update_file);

header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date dans le passé

?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

        <title>SCSM Display page</title>

        <!-- Bootstrap V.4 -->
        <link rel="stylesheet" href="css/bootstrap.min.css">
        <!-- Font-Awesome -->
        <link rel="stylesheet" href="css/font-awesome.min.css">
        <!-- style -->
        <link href="css/style.css" rel="stylesheet">
    </head>
    <body>
        <nav class="navbar navbar-toggleable-md navbar-inverse bg-inverse">
            <a class="navbar-brand" href="#"><i class="fa fa-windows"></i> SCSM Display</a>
            <div class="collapse navbar-collapse" id="navbarText">
                <span class="navbar-text"><i class="fa fa-clock-o" id="icon-navbar"></i> Prochaine MàJ de la page dans : <span id="refresh-time"><?= $HTML_Default_refresh_time ?></span>s</span>
                <ul class="navbar-nav mr-auto"></ul>
                <span class="navbar-text">Dernière MàJ des données : 
                    <span id="latest-update" data-timestamp="<?= $latest_update_timestamp; ?>">
                        <?= $latest_update_date; ?>
                    </span>
                </span>
            </div>
        </nav>
        <div class="container-fluid" style="height: 92%;">
            <div class="row" style="height: 100%;">
                <div class="col half-col">
                    <div class="card card-outline-info custom-card">
                        <h4 class="card-header">Incidents non attribués.</h4>
                        <div class="card-block table-animate" id="table-autoscroll-1">
                            <table class="table table-sm table-striped">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Titre</th>
                                        <th>Priorité</th>
                                        <th>Attribué à</th>
                                        <th>Utilisateur affecté</th>
                                        <th>Date de création</th>
                                        <th>Date de fin prévue</th>
                                        <th>Statut</th>
                                    </tr>
                                </thead>
                                <tbody id="IRUnassignedBody">
                                    <?= $HTML_IR_Unassigned_Table ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="col half-col">
                    <div class="card card-outline-info custom-card">
                        <h4 class="card-header">Incidents en avertissement / violation.</h4>
                        <div class="card-block table-animate" id="table-autoscroll-2">
                            <table class="table table-sm">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Titre</th>
                                        <th>Priorité</th>
                                        <th>Attribué à</th>
                                        <th>Utilisateur affecté</th>
                                        <th>Date de création</th>
                                        <th>Date de fin prévue</th>
                                        <th>Statut</th>
                                    </tr>
                                </thead>
                                <tbody id="IRSLABody">
                                    <?= $HTML_IR_SLA_Table; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="w-100"></div>
                <div class="col half-col">
                    <div class="card card-outline-info custom-card">
                        <h4 class="card-header">Demandes de services non attribuées en cours créés via le portail.</h4>
                        <div class="card-block table-animate" id="table-autoscroll-3"> 
                            <table class="table table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Titre</th>
                                        <th>Attribué à</th>
                                        <th>Priorité</th>
                                    </tr>
                                </thead>
                                <tbody id="SRUnassignedBody">
                                    <?= $HTML_SR_Unassigned_Table; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="col half-col">
                    <div class="card card-outline-info custom-card">
                        <h4 class="card-header">Demandes de services attribuées en cours.</h4>
                        <div class="card-block table-animate" id="table-autoscroll-4">
                            <table class="table table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Titre</th>
                                        <th>Attribué à</th>
                                        <th>Priorité</th>
                                    </tr>
                                </thead>
                                <tbody id="SRAssignedBody">
                                    <?= $HTML_SR_Assigned_Table; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Sounds -->
        <audio id="New-IR" onended="onAudioEnded('New-IR');"><source src="Sounds/New-IR.wav" type="audio/wav"></audio>
        <audio id="New-IR-Portal" onended="onAudioEnded('New-IR-Portal');"><source src="Sounds/New-IR-Portal.wav" type="audio/wav"></audio>
        <audio id="New-SR-Portal" onended="onAudioEnded('New-SR-Portal');"><source src="Sounds/New-SR-Portal.wav" type="audio/wav"></audio>
        <audio id="IR-Violation" onended="onAudioEnded('IR-Violation');"><source src="Sounds/IR-Violation.wav" type="audio/wav"></audio>
        <audio id="IR-Warning" onended="onAudioEnded('IR-Warning');"><source src="Sounds/IR-Warning.wav" type="audio/wav"></audio>
        <audio id="IR-Unassigned" onended="onAudioEnded('IR-Unassigned');">
            <source id="IR-Unassigned-src" src="Sounds/IR-Unassigned-More.wav" type="audio/wav">
        </audio>
        <audio id="SR-Unassigned" onended="onAudioEnded('SR-Unassigned');">
            <source id="SR-Unassigned-src" src="Sounds/SR-Unassigned-More.wav" type="audio/wav">
        </audio>

        <!-- Boostrap V.4 -->
        <script src="js/jquery-3.1.1.min.js"></script>
        <script src="js/tether.min.js"></script>
        <script src="js/bootstrap.min.js"></script>

        <!-- Sound -->
        <script src="js/sound.js"></script>

        <!-- autoscroll des tables -->
        <script src="js/table-autoscroll.js"></script>
    </body>
</html>
