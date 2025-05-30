# PowerShell Zertifikatstool mit Step-CA und OpenSSL

$ConfigDir = Join-Path $PSScriptRoot "config"
$OutputDir = Join-Path $PSScriptRoot "output"
$StepExe = Join-Path $PSScriptRoot "step\step.exe"
$OpenSSLExe = Join-Path $PSScriptRoot "openssl\openssl.exe"

$CAUrlFile = Join-Path $ConfigDir "ca-url.txt"
$FingerprintFile = Join-Path $ConfigDir "fingerprint.txt"

# Ordner anlegen
New-Item -ItemType Directory -Force -Path $ConfigDir, $OutputDir | Out-Null

# CA-URL abfragen oder laden
if (!(Test-Path $CAUrlFile)) {
    $read = Read-Host "Bitte CA-URL eingeben"
    $CAUrl = "`"$read`""
    $CAUrl | Out-File -Encoding utf8 $CAUrlFile
} else {
    $read = Get-Content $CAUrlFile -Raw
    $CAUrl = '"' +$read.Trim() + '"'
}

# Fingerprint abfragen oder laden
if (!(Test-Path $FingerprintFile)) {
    $Fingerprint = (Read-Host 'Bitte CA-Fingerprint eingeben')
    $Fingerprint | Out-File -Encoding utf8 $FingerprintFile
} else {
    $Fingerprint = Get-Content $FingerprintFile -Raw
}

# CA Bootstrap
& $StepExe ca bootstrap --ca-url $CAUrl --fingerprint $Fingerprint --install | Out-String

# Name für Zertifikat eingeben
$Name = Read-Host "Bitte Namen für das Zertifikat eingeben"

$CrtFile = Join-Path $OutputDir "$Name.crt"
$KeyFile = Join-Path $OutputDir "$Name.key"
$PfxFile = Join-Path $OutputDir "$Name.pfx"
$TokenFile = Join-Path $OutputDir "$Name.token"

# Token generieren
Write-Host "Generiere Token..." -ForegroundColor Cyan
& $StepExe ca token $Name > $TokenFile | Out-String
$Token = Get-Content $TokenFile -Raw

# Zertifikat anfordern
Write-Host "Fordere Zertifikat an..." -ForegroundColor Cyan
& $StepExe ca certificate $Name $CrtFile $KeyFile --token $Token | Out-String


# PFX erstellen
Write-Host "Erstelle PFX-Datei..." -ForegroundColor Cyan
& $OpenSSLExe pkcs12 -export -out $PfxFile -inkey $KeyFile -in $CrtFile -passout pass:TEST

# PFX importieren
Write-Host "Importiere PFX..." -ForegroundColor Cyan
certutil -user -f -p "TEST" -importPFX $PfxFile 

Write-Host "Zertifikat wurde erfolgreich erstellt und installiert." -ForegroundColor Green
Read-Host "Zum Beenden Enter drücken"
