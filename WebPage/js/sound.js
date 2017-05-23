var IRUnassigned = $("#IR-Unassigned")[0];
var SRUnassigned = $("#SR-Unassigned")[0];
var IRViolation = $("#IR-Violation")[0];
var IRWarning = $("#IR-Warning")[0];
var NewIR = $("#New-IR")[0];
var NewIRPortal = $("#New-IR-Portal")[0];
var NewSRPortal = $("#New-SR-Portal")[0];

//Récup le nombre d'IR et SR non-attribués.
var numberUnassignedIR = 0;
var numberUnassignedSR = 0;

//Récup des violations et warning
var numberViolation = 0;
var numberWarning = 0;

//Variable qui définit si il y a des nouveaux incidents afin de ne pas jouer le son "il y a x incident encore non attribués...."
var areNewIR = false;
var areNewIRPortal = false;
var areNewSR = false;

function checkNewIR() {
    $("#IRUnassignedBody > tr").each(function () {
        var IRDate = $(this).data("effectivetimestamp");

        var Now = new Date();
        var NowUTC = Math.floor(Date.UTC(Now.getFullYear(), Now.getMonth(), Now.getDate(), Now.getHours(), Now.getMinutes(), Now.getSeconds(), Now.getMilliseconds()) / 1000);

        var IRID = $(this).children().eq(0).html();
        var IRSource = $(this).data("source");

        console.log("IRID : " + IRID + ", IRDate : " + IRDate + ", NowUTC : " + NowUTC + ", diff : " + (NowUTC - IRDate) + ", IRSource : " + IRSource);

        if ((NowUTC - IRDate) < 60) {
            if (IRSource === "IncidentSourceEnum.Portal") {
                areNewIRPortal = true;
            } else {
                areNewIR = true;
            }
        }
    });
}

function checkNewSR() {
    $("#SRUnassignedBody > tr").each(function () {
        var SRDate = $(this).data("timestamp");        
        
        var Now = new Date();
        var NowUTC = Math.floor(Date.UTC(Now.getFullYear(), Now.getMonth(), Now.getDate(), Now.getHours(), Now.getMinutes(), Now.getSeconds(), Now.getMilliseconds()) / 1000);
        
        var SRID = $(this).children().eq(0).html();
        
        console.log("SRID : " + SRID + ", SRDate : " + SRDate + ", NowUTC : " + NowUTC + ", diff : " + (NowUTC - SRDate));
        
        if ((NowUTC - SRDate) < 60) {
            areNewSR = true;
        }
    });
}

function initAllAudio() {

    numberUnassignedIR = $("#IRUnassignedBody > tr").length;
    numberUnassignedSR = $("#SRUnassignedBody > tr").length;
    numberViolation = $(".IncidentViolation").length;
    numberWarning = $(".IncidentWarning").length;

    onAudioEnded("INIT");
}

function playSound(audio) {
    if (audio.id === "IR-Violation") {
        if (numberViolation > 0) {
            audio.play();
            console.log("IR-Violation played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Violation skiped");
        }
        console.log("IR-Violation done");
    } else if (audio.id === "IR-Warning") {
        if (numberWarning > 0) {
            audio.play();
            console.log("IR-Warning played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Warning skiped");
        }
        console.log("IR-Warning done");
    } else if (audio.id === "New-IR") {
        checkNewIR();
        if (areNewIR) {
            audio.play();
            console.log("New-IR played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-IR skiped");
        }
        console.log("New-IR done");
    } else if (audio.id === "New-IR-Portal") {
        checkNewIR();
        if (areNewIRPortal) {
            audio.play();
            console.log("New-IR-Portal played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-IR-Portal skiped");
        }
        console.log("New-IR-Portal done");
    } else if (audio.id === "New-SR-Portal") {
        checkNewSR();
        if (areNewSR) {
            audio.play();
            console.log("New-SR-Portal played");
        } else {
            onAudioEnded(audio.id);
            console.log("New-SR-Portal skiped");
        }
        console.log("New-SR-Portal done");
    } else if (audio.id === "IR-Unassigned") {
        if (numberUnassignedIR >= 1 && numberUnassignedIR <= 5) {
            $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-" + numberUnassignedIR + ".wav";
            audio.load();
            audio.play();
            console.log("IR-Unassigned 1-5 played");
        } else if (numberUnassignedIR > 5) {
            $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-More.wav";
            audio.load();
            audio.play();
            console.log("IR-Unassigned 5+ played");
        } else {
            onAudioEnded(audio.id);
            console.log("IR-Unassigned skiped");
        }
        console.log("IR-Unassigned done");
    } else if (audio.id === "SR-Unassigned") {
        if (numberUnassignedSR >= 1 && numberUnassignedSR <= 5) {
            $("#SR-Unassigned-src")[0].src = "Sounds/SR-Unassigned-" + numberUnassignedSR + ".wav";
            audio.load();
            audio.play();
            console.log("SR-Unassigned 1-5 played");
        } else if (numberUnassignedSR > 5) {
            $("#SR-Unassigned-src")[0].src = "Sounds/SR-Unassigned-More.wav";
            audio.load();
            audio.play();
            console.log("SR-Unassigned 5+ played");
        } else {
            onAudioEnded(audio.id);
            console.log("SR-Unassigned skiped");
        }
        console.log("SR-Unassigned done");
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
/*
 IRUnassigned.volume = 0.1;
 SRUnassigned.volume = 0.1;
 
 if (numberUnassignedIR >= 1 && numberUnassignedIR <= 5) {
 $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-" + numberUnassignedIR + ".wav";
 IRUnassigned.load();
 //IRUnassignedSound.play();
 } else if (numberUnassignedIR > 5) {
 $("#IR-Unassigned-src")[0].src = "Sounds/IR-Unassigned-More.wav";
 IRUnassigned.load();
 //IRUnassignedSound.play();
 }
 */