//Récupération des objets audio
var IRUnassigned = $("#IR-Unassigned")[0];
var SRUnassigned = $("#SR-Unassigned")[0];
var IRViolation = $("#IR-Violation")[0];
var IRWarning = $("#IR-Warning")[0];
var NewIR = $("#New-IR")[0];
var NewIRPortal = $("#New-IR-Portal")[0];
var NewSRPortal = $("#New-SR-Portal")[0];

//Création de variables pour le nombre de IR, SR non attribués.
var IRUnassignedCount = 0;
var SRUnassignedCount = 0;

//Création de variables pour le nombre de IR et avertissement / violation.
var IRViolationCount = 0;
var IRWarningCount = 0;

//Variable qui définit si il y a des nouveaux incidents afin de ne pas jouer le son "il y a x incident encore non attribués...."
var AreNewIR = false;
var AreNewIRPortal = false;
var AreNewSR = false;

function checkNewIR() {
    //Pour chaque item dans le tableau
    $("#IRUnassignedBody > tr").each(function () {
        //Récup de la date de création effective
        var IRDate = $(this).data("effectivetimestamp");
        
        //Récup de l'heure actuelle en temps UNIX
        var Now = new Date();
        var NowUTC = Math.floor(Date.UTC(Now.getFullYear(), Now.getMonth(), Now.getDate(), Now.getHours(), Now.getMinutes(), Now.getSeconds(), Now.getMilliseconds()) / 1000);

        var IRID = $(this).children().eq(0).html();
        var IRSource = $(this).data("source");

        console.log("IRID : " + IRID + ", IRDate : " + IRDate + ", NowUTC : " + NowUTC + ", diff : " + (NowUTC - IRDate) + ", IRSource : " + IRSource);

        var LatestUpdate = $("#latest-update").data('timestamp');
        console.log("Latest Update Server : " + LatestUpdate);
        console.log("Latest Update Client : " + NowUTC);
        var DiffCltSrv = (NowUTC - LatestUpdate);
        console.log("Diff srv-ctl : " + DiffCltSrv);

        //Prise en compte du décalage entre le client et le serveur
        if (DiffCltSrv < 60) {
            //Si moins de 60 secondes de décalage client-serveur on soustrait la différence de l'heure atuelle
            NowUTC -= DiffCltSrv;
            console.log("Diff. Ctl-Srv prise en compte.");
        } else {
            console.log("Diff. Ctl-Srv trop grande -> pas prise en compte.");
        }

        //Test que la date de création effective de l'incident est moins de 60 secondes (décalage déjà soustrait)
        if ((NowUTC - IRDate) < 60) {
            if (IRSource === "IncidentSourceEnum.Portal") {
                //Si l'incident vient du portail
                AreNewIRPortal = true;
            } else {
                //Si l'incident possède une autre source
                AreNewIR = true;
            }
        }
    });
}

function checkNewSR() {
    $("#SRUnassignedBody > tr").each(function () {
        var SRDate = $(this).data("timestamp");

        var Now = new Date();
        var NowUTC = Math.floor(Date.UTC(Now.getFullYear(), Now.getMonth(), Now.getDate(), Now.getHours(), Now.getMinutes(), Now.getSeconds(), Now.getMilliseconds()) / 1000);

        //var SRID = $(this).children().eq(0).html();
        //console.log("SRID : " + SRID + ", SRDate : " + SRDate + ", NowUTC : " + NowUTC + ", diff : " + (NowUTC - SRDate));

        var LatestUpdate = $("#latest-update").data('timestamp');
        var DiffCltSrv = (NowUTC - LatestUpdate);
        
        //Prise en compte du décalage entre le client et le serveur
        if (DiffCltSrv < 60) {
            //Si moins de 60 secondes de décalage client-serveur on soustrait la différence de l'heure atuelle
            NowUTC -= DiffCltSrv;
        }

        if ((NowUTC - SRDate) < 60) {
            //Si la différence de temps entre la date de création effective de la SR et l'heure actuelle est moins de 60
            AreNewSR = true;
        }
    });
}

function InitAllAudio() {

    //Récup du nombre de IR, SR non assignés et IR en avertissement / violation
    IRUnassignedCount = $("#IRUnassignedBody > tr").length;
    SRUnassignedCount = $("#SRUnassignedBody > tr").length;
    IRViolationCount = $(".IncidentViolation").length;
    IRWarningCount = $(".IncidentWarning").length;

    //On lance l'initialisation des audios
    onAudioEnded("INIT");
}

function playSound(audio) {
    if (audio.id === "IR-Violation") {
        if (IRViolationCount > 0) {
            audio.play();
            console.log("IR-Violation played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Violation skiped");
        }
    } else if (audio.id === "IR-Warning") {
        if (IRWarningCount > 0) {
            audio.play();
            console.log("IR-Warning played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Warning skiped");
        }
    } else if (audio.id === "New-IR") {
        checkNewIR();
        if (AreNewIR) {
            audio.play();
            console.log("New-IR played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-IR skiped");
        }
    } else if (audio.id === "New-IR-Portal") {
        checkNewIR();
        if (AreNewIRPortal) {
            audio.play();
            console.log("New-IR-Portal played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-IR-Portal skiped");
        }
    } else if (audio.id === "New-SR-Portal") {
        checkNewSR();
        if (AreNewSR) {
            audio.play();
            console.log("New-SR-Portal played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-SR-Portal skiped");
        }
    } else if (audio.id === "IR-Unassigned") {
        if (IRUnassignedCount >= 1 && IRUnassignedCount <= 5) {
            $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-" + IRUnassignedCount + ".wav";
            audio.load();
            audio.play();
            console.log("IR-Unassigned 1-5 played");
        } else if (IRUnassignedCount > 5) {
            $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-More.wav";
            audio.load();
            audio.play();
            console.log("IR-Unassigned 5+ played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Unassigned skiped");
        }
    } else if (audio.id === "SR-Unassigned") {
        if (SRUnassignedCount >= 1 && SRUnassignedCount <= 5) {
            $("#SR-Unassigned-src")[0].src = "Sounds/SR-Unassigned-" + SRUnassignedCount + ".wav";
            audio.load();
            audio.play();
            console.log("SR-Unassigned 1-5 played");
        } else if (SRUnassignedCount > 5) {
            $("#SR-Unassigned-src")[0].src = "Sounds/SR-Unassigned-More.wav";
            audio.load();
            audio.play();
            console.log("SR-Unassigned 5+ played");
        } else {
            onAudioEnded(audio.id);
            console.log("SR-Unassigned skiped");
        }
    }
}

function onAudioEnded(audio) {
    switch (audio) {
        case "INIT":
            playSound(IRViolation);
            break;
        case "IR-Violation":
            playSound(IRWarning);
            break;
        case "IR-Warning":
            playSound(NewIR);
            break;
        case "New-IR":
            playSound(NewIRPortal);
            break;
        case "New-IR-Portal":
            playSound(NewSRPortal);
            break;
        case "New-SR-Portal":
            playSound(IRUnassigned);
            break;
        case "IR-Unassigned":
            playSound(SRUnassigned);
            break;
        case "SR-Unassigned":
            //Plus de son a jouer
            break;
        default:
            alert("unknown sound : " + audio.id);
    }
}