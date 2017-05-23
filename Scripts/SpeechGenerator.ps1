#
# Script de genération de fichier audio pour SCSM
# Crée par Berret Luca (LUB)
# Dernière modification le 28.03.2017
#
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-IR-Portal.wav")
$speak.Speak("Un nouvel incident a été réalisé depuis le portail")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-IR.wav")
$speak.Speak("Un nouvel incident a été créé")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-SR-Portal.wav")
$speak.Speak("Une nouvelle demande de service a été réalisé depuis le portail")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Warning.wav")
$speak.Speak("Un incident est en avertissement. Veuillez le prendre en charge rapidement. ")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Violation.wav")
$speak.Speak("Un incident est en violation. Veuillez le traiter en urgence.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-1.wav")
$speak.Speak("Il y a 1 incident encore non attribué. Veuillez le prendre en charge sans délai.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-1.wav")
$speak.Speak("Il y a une demande de service encore non attribué. Veuillez la prendre en charge sans délai.")

for ($i=2; $i -le 5; $i++)  { 
    $speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-$i.wav")
    $speak.Speak("Il y a $i incidents encore non attribués. Veuillez les prendre en charge sans délai.")

    $speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-$i.wav")
    $speak.Speak("Il y a $i demande de service encore non attribués. Veuillez les prendre en charge sans délai.")
}

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-More.wav")
$speak.Speak("Il y a plus de 5 incidents encore non attribués. Veuillez les prendre en charge sans délai.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-More.wav")
$speak.Speak("Il y a plus de 5 demandes de services encore non attribués. Veuillez les prendre en charge sans délai.")

$speak.SetOutputToNull()
$speak.Speak("null")