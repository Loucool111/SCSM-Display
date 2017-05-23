#
# Script de gen�ration de fichier audio pour SCSM
# Cr�e par Berret Luca (LUB)
# Derni�re modification le 28.03.2017
#
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-IR-Portal.wav")
$speak.Speak("Un nouvel incident a �t� r�alis� depuis le portail")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-IR.wav")
$speak.Speak("Un nouvel incident a �t� cr��")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\New-SR-Portal.wav")
$speak.Speak("Une nouvelle demande de service a �t� r�alis� depuis le portail")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Warning.wav")
$speak.Speak("Un incident est en avertissement. Veuillez le prendre en charge rapidement. ")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Violation.wav")
$speak.Speak("Un incident est en violation. Veuillez le traiter en urgence.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-1.wav")
$speak.Speak("Il y a 1 incident encore non attribu�. Veuillez le prendre en charge sans d�lai.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-1.wav")
$speak.Speak("Il y a une demande de service encore non attribu�. Veuillez la prendre en charge sans d�lai.")

for ($i=2; $i -le 5; $i++)  { 
    $speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-$i.wav")
    $speak.Speak("Il y a $i incidents encore non attribu�s. Veuillez les prendre en charge sans d�lai.")

    $speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-$i.wav")
    $speak.Speak("Il y a $i demande de service encore non attribu�s. Veuillez les prendre en charge sans d�lai.")
}

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\IR-Unassigned-More.wav")
$speak.Speak("Il y a plus de 5 incidents encore non attribu�s. Veuillez les prendre en charge sans d�lai.")

$speak.SetOutputToWaveFile("D:\SCSM-Display\Output\Sounds\SR-Unassigned-More.wav")
$speak.Speak("Il y a plus de 5 demandes de services encore non attribu�s. Veuillez les prendre en charge sans d�lai.")

$speak.SetOutputToNull()
$speak.Speak("null")