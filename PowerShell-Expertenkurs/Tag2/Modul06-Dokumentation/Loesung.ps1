#############################################################################
# Modul 06 - Dokumentation mit Comment-Based Help
# LÖSUNGEN
#############################################################################

#region Übung 1: Get-DiskSpaceReport - Vollständig dokumentierte Funktion

function Get-DiskSpaceReport {
    <#
    .SYNOPSIS
        Erstellt einen detaillierten Festplatten-Bericht für lokale und Remote-Computer.
    
    .DESCRIPTION
        Die Funktion Get-DiskSpaceReport sammelt Informationen über alle verfügbaren
        Festplatten auf einem oder mehreren Computern. Sie kann lokale Festplatten,
        Netzlaufwerke oder alle Laufwerke abfragen.
        
        Die Funktion unterstützt Pipeline-Eingaben und kann Warnungen ausgeben,
        wenn der freie Speicherplatz unter einen definierten Schwellenwert fällt.
        Dies ist besonders nützlich für proaktives Kapazitätsmanagement.
    
    .PARAMETER ComputerName
        Der Name eines oder mehrerer Computer, von denen der Bericht erstellt werden soll.
        Unterstützt Pipeline-Eingaben nach Wert oder nach Eigenschaftsname.
        
        Standard: Lokaler Computer ($env:COMPUTERNAME)
        
        Typ: String[]
        Pflicht: Nein
        Position: 0
    
    .PARAMETER DriveType
        Der Typ der abzufragenden Laufwerke.
        
        | Wert    | Beschreibung                        |
        |---------|-------------------------------------|
        | All     | Alle Laufwerke (Standard)          |
        | Local   | Nur lokale Festplatten             |
        | Network | Nur Netzlaufwerke                  |
        
        Standard: All
    
    .PARAMETER ThresholdPercent
        Der Schwellenwert für freien Speicherplatz in Prozent.
        Wenn der freie Speicher darunter fällt, wird eine Warnung ausgegeben.
        
        Gültige Werte: 1-100
        Standard: 10
    
    .INPUTS
        System.String[]
        Sie können Computernamen als Pipeline-Eingabe übergeben.
        
        System.Management.Automation.PSObject
        Objekte mit einer 'ComputerName'-Eigenschaft werden akzeptiert.
    
    .OUTPUTS
        PSCustomObject
        Ein Objekt für jedes gefundene Laufwerk mit folgenden Eigenschaften:
        - ComputerName: Name des Computers
        - DriveLetter: Laufwerksbuchstabe
        - DriveType: Typ des Laufwerks
        - Label: Datenträgerbezeichnung
        - SizeGB: Gesamtgröße in GB
        - FreeGB: Freier Speicher in GB
        - FreePercent: Freier Speicher in Prozent
        - Status: OK, Warning oder Critical
    
    .EXAMPLE
        Get-DiskSpaceReport
        
        Erstellt einen Festplatten-Bericht für den lokalen Computer mit Standardeinstellungen.
    
    .EXAMPLE
        Get-DiskSpaceReport -ComputerName "Server01" -DriveType Local
        
        Erstellt einen Bericht nur für lokale Festplatten auf Server01.
    
    .EXAMPLE
        "Server01", "Server02", "Server03" | Get-DiskSpaceReport -ThresholdPercent 20
        
        Pipeline-Beispiel: Erstellt Berichte für drei Server und warnt wenn 
        weniger als 20% frei sind.
    
    .EXAMPLE
        # Alle Server aus AD abfragen und kritische Laufwerke finden
        
        Get-ADComputer -Filter { OperatingSystem -like "*Server*" } |
            Select-Object -ExpandProperty Name |
            Get-DiskSpaceReport -ThresholdPercent 15 |
            Where-Object Status -ne 'OK' |
            Export-Csv -Path "C:\Reports\CriticalDisks.csv" -NoTypeInformation
        
        Komplexes Beispiel: Findet alle Server in AD, erstellt Festplatten-Berichte
        und exportiert nur die problematischen Laufwerke.
    
    .NOTES
        Autor: PowerShell Trainer
        Version: 1.0.0
        Datum: Dezember 2025
        
        Änderungshistorie:
        1.0.0 - Initiale Version
        
        Voraussetzungen:
        - WMI/CIM-Zugriff auf Zielcomputer
        - Für Remote-Abfragen: Admin-Rechte oder entsprechende WMI-Berechtigungen
    
    .LINK
        Get-CimInstance
    
    .LINK
        https://docs.microsoft.com/powershell/module/cimcmdlets/get-ciminstance
    
    .COMPONENT
        Storage Management
    
    .FUNCTIONALITY
        Disk Monitoring
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('CN', 'Server', 'Name')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [ValidateSet('All', 'Local', 'Network')]
        [string]$DriveType = 'All',
        
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$ThresholdPercent = 10
    )
    
    begin {
        Write-Verbose "Starte Festplatten-Bericht (DriveType: $DriveType, Threshold: $ThresholdPercent%)"
        
        # DriveType-Filter für WMI
        $driveTypeFilter = switch ($DriveType) {
            'Local'   { 'DriveType = 3' }
            'Network' { 'DriveType = 4' }
            'All'     { 'DriveType = 3 OR DriveType = 4' }
        }
    }
    
    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Abfrage Computer: $computer"
            
            try {
                $disks = Get-CimInstance -ClassName Win32_LogicalDisk `
                    -ComputerName $computer `
                    -Filter $driveTypeFilter `
                    -ErrorAction Stop
                
                foreach ($disk in $disks) {
                    if ($disk.Size -gt 0) {
                        $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                        
                        $status = switch ($freePercent) {
                            { $_ -lt 5 }                { 'Critical' }
                            { $_ -lt $ThresholdPercent } { 'Warning' }
                            default                     { 'OK' }
                        }
                        
                        if ($status -ne 'OK') {
                            Write-Warning "$computer - $($disk.DeviceID): Nur $freePercent% frei!"
                        }
                        
                        [PSCustomObject]@{
                            ComputerName = $computer
                            DriveLetter  = $disk.DeviceID
                            DriveType    = $(if ($disk.DriveType -eq 3) { 'Local' } else { 'Network' })
                            Label        = $disk.VolumeName
                            SizeGB       = [math]::Round($disk.Size / 1GB, 2)
                            FreeGB       = [math]::Round($disk.FreeSpace / 1GB, 2)
                            FreePercent  = $freePercent
                            Status       = $status
                        }
                    }
                }
            }
            catch {
                Write-Error "Fehler bei $computer : $_"
            }
        }
    }
    
    end {
        Write-Verbose "Festplatten-Bericht abgeschlossen"
    }
}

# Test
Write-Host "=== Übung 1: Get-DiskSpaceReport ===" -ForegroundColor Green
Get-DiskSpaceReport | Format-Table
Get-Help Get-DiskSpaceReport -Full | Select-Object -First 80

#endregion

#region Übung 2: New-UserAccount - Detaillierte Parameter-Dokumentation

function New-UserAccount {
    <#
    .SYNOPSIS
        Erstellt ein neues Benutzerkonto im System.
    
    .DESCRIPTION
        Die Funktion New-UserAccount erstellt ein neues Benutzerkonto mit 
        konfigurierbaren Eigenschaften wie Abteilung, Rolle und Gruppenmitgliedschaften.
        
        Die Funktion validiert alle Eingaben und erstellt das Konto nur,
        wenn alle Voraussetzungen erfüllt sind.
    
    .PARAMETER Username
        Der Benutzername für das neue Konto.
        
        Anforderungen:
        - Muss alphanumerisch sein (a-z, A-Z, 0-9)
        - Mindestens 3 Zeichen, maximal 20 Zeichen
        - Darf keine Sonderzeichen oder Leerzeichen enthalten
        - Muss im System eindeutig sein
        
        Typ: String
        Pflicht: Ja
        Position: 0
    
    .PARAMETER Email
        Die E-Mail-Adresse des Benutzers.
        
        Anforderungen:
        - Muss gültiges E-Mail-Format haben (name@domain.tld)
        - Domain muss gültig sein
        
        Beispiele:
        - max.mustermann@firma.de ✓
        - max@firma ✗ (keine TLD)
        - @firma.de ✗ (kein Name)
        
        Typ: String
        Pflicht: Ja
        Position: 1
    
    .PARAMETER Department
        Die Abteilung des Benutzers.
        
        Gültige Werte:
        | Abteilung    | Beschreibung              |
        |--------------|---------------------------|
        | IT           | IT-Abteilung              |
        | HR           | Personalabteilung         |
        | Finance      | Finanzen & Controlling    |
        | Sales        | Vertrieb                  |
        | Marketing    | Marketing & Kommunikation |
        | Operations   | Betrieb & Produktion      |
        
        Typ: String
        Pflicht: Nein
        Standard: Operations
    
    .PARAMETER Role
        Die Berechtigungsrolle des Benutzers.
        
        Rollenübersicht:
        | Rolle     | Lesen | Schreiben | Löschen | Admin |
        |-----------|-------|-----------|---------|-------|
        | User      | Ja    | Nein      | Nein    | Nein  |
        | PowerUser | Ja    | Ja        | Nein    | Nein  |
        | Admin     | Ja    | Ja        | Ja      | Ja    |
        
        - User: Standardbenutzer, nur Lesezugriff auf allgemeine Ressourcen
        - PowerUser: Erweiterter Benutzer, kann Dokumente erstellen/bearbeiten
        - Admin: Voller Zugriff, kann Benutzer und Einstellungen verwalten
        
        Typ: String
        Pflicht: Nein
        Standard: User
    
    .PARAMETER ExpirationDate
        Das Ablaufdatum des Kontos.
        
        - Wenn nicht angegeben, läuft das Konto nicht ab
        - Muss in der Zukunft liegen
        - Nützlich für Praktikanten, Externe, oder temporäre Accounts
        
        Beispiele:
        - (Get-Date).AddMonths(6) - Konto für 6 Monate
        - [DateTime]"2025-12-31" - Konto bis Jahresende
        
        Typ: DateTime
        Pflicht: Nein
        Standard: Kein Ablauf
    
    .PARAMETER Groups
        Die Gruppenmitgliedschaften des Benutzers.
        
        - Mehrere Gruppen als Array übergeben
        - Gruppen müssen im System existieren
        - Abteilungsgruppen werden automatisch hinzugefügt
        
        Standard-Gruppen nach Rolle:
        - User: "All-Users"
        - PowerUser: "All-Users", "Power-Users"
        - Admin: "All-Users", "Administrators"
        
        Typ: String[]
        Pflicht: Nein
    
    .INPUTS
        None
        Diese Funktion akzeptiert keine Pipeline-Eingaben.
    
    .OUTPUTS
        PSCustomObject
        Ein Objekt mit den Details des erstellten Benutzerkontos.
    
    .EXAMPLE
        New-UserAccount -Username "mmustermann" -Email "max.mustermann@firma.de"
        
        Erstellt einen Standardbenutzer mit minimalen Angaben.
    
    .EXAMPLE
        New-UserAccount -Username "aadmin" -Email "admin@firma.de" -Role Admin -Department IT
        
        Erstellt einen Administrator in der IT-Abteilung.
    
    .EXAMPLE
        $newUser = @{
            Username = "praktikant01"
            Email = "praktikant@firma.de"
            Department = "Marketing"
            Role = "User"
            ExpirationDate = (Get-Date).AddMonths(3)
            Groups = @("Marketing-Team", "Praktikanten")
        }
        New-UserAccount @newUser
        
        Erstellt ein temporäres Praktikantenkonto mit Splatting.
    
    .NOTES
        Autor: PowerShell Trainer
        Version: 1.0.0
        Datum: Dezember 2025
        
        Voraussetzungen:
        - Schreibrechte auf Benutzer-Datenbank
        - Für Admin-Erstellung: Admin-Berechtigung erforderlich
    
    .LINK
        Get-UserAccount
    
    .LINK
        Remove-UserAccount
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9]{3,20}$')]
        [ValidateScript({ 
            if ($_ -match '^\d') { throw "Username darf nicht mit Zahl beginnen" }
            $true
        })]
        [string]$Username,
        
        [Parameter(Mandatory, Position = 1)]
        [ValidatePattern('^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$')]
        [string]$Email,
        
        [Parameter()]
        [ValidateSet('IT', 'HR', 'Finance', 'Sales', 'Marketing', 'Operations')]
        [string]$Department = 'Operations',
        
        [Parameter()]
        [ValidateSet('User', 'PowerUser', 'Admin')]
        [string]$Role = 'User',
        
        [Parameter()]
        [ValidateScript({
            if ($_ -le (Get-Date)) { throw "ExpirationDate muss in der Zukunft liegen" }
            $true
        })]
        [DateTime]$ExpirationDate,
        
        [Parameter()]
        [string[]]$Groups = @()
    )
    
    if ($PSCmdlet.ShouldProcess($Username, "Create user account")) {
        # Standard-Gruppen basierend auf Rolle
        $defaultGroups = switch ($Role) {
            'Admin'     { @('All-Users', 'Administrators') }
            'PowerUser' { @('All-Users', 'Power-Users') }
            default     { @('All-Users') }
        }
        
        $allGroups = @($defaultGroups) + @($Groups) + @("$Department-Team") | Select-Object -Unique
        
        [PSCustomObject]@{
            Username        = $Username
            Email          = $Email
            Department     = $Department
            Role           = $Role
            Groups         = $allGroups
            ExpirationDate = $ExpirationDate
            CreatedAt      = Get-Date
            Status         = 'Active'
        }
    }
}

# Test
Write-Host "`n=== Übung 2: New-UserAccount ===" -ForegroundColor Green
Get-Help New-UserAccount -Parameter Role
Get-Help New-UserAccount -Parameter Department

#endregion

#region Übung 3: Send-AlertNotification - Beispiel-Bibliothek

function Send-AlertNotification {
    <#
    .SYNOPSIS
        Sendet Benachrichtigungen über verschiedene Kanäle.
    
    .DESCRIPTION
        Diese Funktion sendet Warnmeldungen und Benachrichtigungen über
        Email, Microsoft Teams, Slack oder alle Kanäle gleichzeitig.
    
    .PARAMETER Message
        Die zu sendende Nachricht.
    
    .PARAMETER Severity
        Der Schweregrad der Nachricht.
    
    .PARAMETER Channel
        Der Benachrichtigungskanal.
    
    .PARAMETER Recipients
        Die Empfänger der Nachricht.
    
    .PARAMETER Attachments
        Optionale Dateianhänge.
    
    .EXAMPLE
        Send-AlertNotification -Message "Test"
        
        Einfachstes Beispiel: Sendet eine Info-Nachricht über den Standard-Kanal (Email).
    
    .EXAMPLE
        Send-AlertNotification -Message "Festplatte fast voll!" -Severity Warning -Recipients "admin@firma.de"
        
        Typisches Beispiel: Sendet eine Warnung an einen bestimmten Administrator.
    
    .EXAMPLE
        Send-AlertNotification -Message "System ausgefallen!" -Severity Critical -Channel All
        
        Multi-Channel: Sendet eine kritische Nachricht an alle verfügbaren Kanäle
        gleichzeitig (Email, Teams, Slack).
    
    .EXAMPLE
        Send-AlertNotification -Message "Backup abgeschlossen" -Severity Info -Attachments "C:\Logs\backup.log"
        
        Mit Attachment: Sendet eine Info-Nachricht mit angehängter Log-Datei.
        Nützlich für automatische Reports.
    
    .EXAMPLE
        # Pipeline-Integration mit Monitoring
        
        Get-DiskSpaceReport | 
            Where-Object { $_.FreePercent -lt 15 } |
            ForEach-Object {
                Send-AlertNotification -Message "Warnung: $($_.DriveLetter) auf $($_.ComputerName) hat nur $($_.FreePercent)% frei!" `
                    -Severity Warning `
                    -Channel Teams
            }
        
        Pipeline-Beispiel: Integriert die Benachrichtigung mit dem Festplatten-Monitoring.
        Findet Laufwerke mit wenig Platz und sendet Teams-Nachrichten.
    
    .EXAMPLE
        # Produktions-Skript mit vollständiger Fehlerbehandlung
        
        function Send-MonitoringAlert {
            param($ComputerName, $AlertType, $Details)
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $message = @"
        ⚠️ Monitoring Alert
        
        Zeit: $timestamp
        Computer: $ComputerName
        Typ: $AlertType
        
        Details:
        $Details
        "@
            
            try {
                # Primärer Kanal: Teams
                Send-AlertNotification -Message $message `
                    -Severity $(if ($AlertType -eq "Critical") { "Critical" } else { "Warning" }) `
                    -Channel Teams `
                    -ErrorAction Stop
                
                Write-Verbose "Alert gesendet an Teams"
            }
            catch {
                # Fallback: Email
                Write-Warning "Teams fehlgeschlagen, versuche Email..."
                
                try {
                    Send-AlertNotification -Message $message `
                        -Severity Warning `
                        -Channel Email `
                        -Recipients "oncall@firma.de" `
                        -ErrorAction Stop
                }
                catch {
                    # Letzte Instanz: Lokales Log
                    $message | Out-File "C:\Logs\FailedAlerts.log" -Append
                    Write-Error "Alle Benachrichtigungskanäle fehlgeschlagen!"
                }
            }
        }
        
        # Verwendung
        Send-MonitoringAlert -ComputerName "Server01" `
            -AlertType "DiskSpace" `
            -Details "C: hat nur noch 5% freien Speicher"
        
        Produktions-Beispiel: Vollständiges Skript mit Fallback-Logik und Fehlerbehandlung.
        Bei Ausfall eines Kanals wird automatisch auf den nächsten gewechselt.
    
    .NOTES
        Autor: PowerShell Trainer
        Version: 1.0.0
        Datum: Dezember 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Critical')]
        [string]$Severity = 'Info',
        
        [Parameter()]
        [ValidateSet('Email', 'Teams', 'Slack', 'All')]
        [string]$Channel = 'Email',
        
        [Parameter()]
        [string[]]$Recipients = @(),
        
        [Parameter()]
        [ValidateScript({ 
            foreach ($path in $_) {
                if (-not (Test-Path $path)) { 
                    throw "Datei nicht gefunden: $path" 
                }
            }
            $true
        })]
        [string[]]$Attachments = @()
    )
    
    $severityEmoji = switch ($Severity) {
        'Info'     { 'ℹ️' }
        'Warning'  { '⚠️' }
        'Error'    { '❌' }
        'Critical' { '🚨' }
    }
    
    $channels = if ($Channel -eq 'All') { @('Email', 'Teams', 'Slack') } else { @($Channel) }
    
    foreach ($ch in $channels) {
        Write-Verbose "Sende über $ch : $severityEmoji $Message"
        
        [PSCustomObject]@{
            Channel     = $ch
            Severity    = $Severity
            Message     = $Message
            Recipients  = $Recipients
            Attachments = $Attachments
            SentAt      = Get-Date
            Status      = 'Sent'
        }
    }
}

# Test
Write-Host "`n=== Übung 3: Send-AlertNotification ===" -ForegroundColor Green
Get-Help Send-AlertNotification -Examples

#endregion

#region Übung 4 (Bonus): About-Topic für Modul

# Inhalt der Datei: about_AlertingSystem.help.txt
$aboutAlertingSystem = @'
TOPIC
    about_AlertingSystem

SHORT DESCRIPTION
    Das AlertingSystem-Modul bietet Funktionen für Benachrichtigungen 
    und Monitoring-Alerts über verschiedene Kommunikationskanäle.

LONG DESCRIPTION
    Das AlertingSystem-Modul ist eine Sammlung von PowerShell-Funktionen,
    die es ermöglichen, automatisierte Benachrichtigungen über Email, 
    Microsoft Teams, und Slack zu versenden.

    Das Modul ist ideal für:
    - Server-Monitoring und Alerting
    - Automatisierte Statusberichte
    - Incident-Management
    - DevOps-Pipelines

    FUNKTIONEN
    ----------
    Das Modul enthält folgende Funktionen:

    Send-AlertNotification
        Sendet Benachrichtigungen über konfigurierte Kanäle.
        Unterstützt Email, Teams, Slack und paralleles Senden.

    Get-AlertConfiguration
        Zeigt die aktuelle Konfiguration der Benachrichtigungskanäle.

    Set-AlertConfiguration
        Konfiguriert Benachrichtigungskanäle und Standardwerte.

    Test-AlertChannel
        Testet ob ein Benachrichtigungskanal funktioniert.

    KONFIGURATION
    -------------
    Das Modul speichert seine Konfiguration unter:
    $env:APPDATA\AlertingSystem\config.json

    Konfigurationsbeispiel:
    {
        "DefaultChannel": "Teams",
        "TeamsWebhookUrl": "https://...",
        "SlackWebhookUrl": "https://...",
        "SmtpServer": "mail.firma.de",
        "DefaultRecipients": ["admin@firma.de"]
    }

    Initialisierung:
    Set-AlertConfiguration -Channel Teams -WebhookUrl "https://..."

    BEST PRACTICES
    --------------
    1. Testen Sie Kanäle nach der Konfiguration:
       Test-AlertChannel -Channel Teams

    2. Verwenden Sie Severity-Level konsistent:
       - Info: Routine-Meldungen
       - Warning: Potentielle Probleme
       - Error: Fehler, die Aufmerksamkeit brauchen
       - Critical: Sofortige Aktion erforderlich

    3. Implementieren Sie Fallback-Logik:
       Wenn Teams fehlschlägt, auf Email ausweichen.

    4. Vermeiden Sie Alert-Überflutung:
       Gruppieren Sie ähnliche Alerts.

EXAMPLES
    # Modul importieren
    Import-Module AlertingSystem

    # Konfiguration anzeigen
    Get-AlertConfiguration

    # Einfache Benachrichtigung
    Send-AlertNotification -Message "Server gestartet" -Severity Info

    # Kritischer Alert an alle Kanäle
    Send-AlertNotification -Message "Ausfall erkannt!" -Severity Critical -Channel All

    # Integration mit Monitoring
    Get-Service | Where-Object Status -eq 'Stopped' | ForEach-Object {
        Send-AlertNotification -Message "Dienst $($_.Name) gestoppt!" -Severity Warning
    }

TROUBLESHOOTING
    Problem: "Teams-Webhook antwortet nicht"
    Lösung: Prüfen Sie die Webhook-URL und Firewall-Einstellungen.

    Problem: "Email wird nicht gesendet"
    Lösung: Prüfen Sie SMTP-Server-Einstellungen und Authentifizierung.

SEE ALSO
    about_Functions_Advanced
    Send-MailMessage
    Invoke-RestMethod
    https://github.com/example/AlertingSystem

KEYWORDS
    Alert, Notification, Monitoring, Teams, Slack, Email
'@

Write-Host "`n=== Übung 4 (Bonus): About-Topic ===" -ForegroundColor Green
Write-Host "Inhalt von about_AlertingSystem.help.txt:" -ForegroundColor Yellow
Write-Host $aboutAlertingSystem

# Speicherort für About-Topics
Write-Host "`nUm das About-Topic zu nutzen:" -ForegroundColor Yellow
Write-Host @"
1. Erstellen Sie im Modul-Ordner einen Unterordner 'en-US' oder 'de-DE'
2. Speichern Sie die Datei als 'about_AlertingSystem.help.txt'
3. Importieren Sie das Modul neu

Struktur:
ModuleName/
├── ModuleName.psd1
├── ModuleName.psm1
└── en-US/
    └── about_AlertingSystem.help.txt

Dann funktioniert: Get-Help about_AlertingSystem
"@ -ForegroundColor White

#endregion

#region Zusammenfassung
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALLE LÖSUNGEN GELADEN" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

Verfügbare Funktionen zum Testen:
  - Get-DiskSpaceReport (Übung 1)
  - New-UserAccount (Übung 2)
  - Send-AlertNotification (Übung 3)

Testen Sie die Dokumentation:
  Get-Help <FunktionName> -Full
  Get-Help <FunktionName> -Examples
  Get-Help <FunktionName> -Parameter *

"@ -ForegroundColor White
#endregion
