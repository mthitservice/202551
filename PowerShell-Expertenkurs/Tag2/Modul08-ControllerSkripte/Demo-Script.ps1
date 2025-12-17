#############################################################################
# Modul 08: Controller Skripte
# PowerShell Expertenkurs - Tag 2
#############################################################################

<#
LERNZIELE:
- Controller-Skript Pattern verstehen
- Menüsysteme erstellen
- Benutzerinteraktion gestalten
- Module orchestrieren
- Logging und Reporting integrieren

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Was sind Controller Skripte?
#############################################################################

Write-Host "=== TEIL 1: Controller Skript Konzept ===" -ForegroundColor Cyan

Write-Host @"

CONTROLLER SKRIPT PATTERN:
==========================

Ein Controller Skript ist das "Hauptprogramm", das:
- Module und Funktionen lädt
- Benutzerinteraktion steuert
- Workflow orchestriert
- Logging/Reporting übernimmt

Typische Struktur:
┌─────────────────────────────────────────┐
│           Controller.ps1                │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐       │
│  │  Module A   │  │  Module B   │       │
│  │ (Funktionen)│  │ (Funktionen)│       │
│  └─────────────┘  └─────────────┘       │
│           │              │              │
│           ▼              ▼              │
│  ┌─────────────────────────────────┐    │
│  │      Menü / Workflow            │    │
│  │   (Benutzerinteraktion)         │    │
│  └─────────────────────────────────┘    │
│                  │                      │
│                  ▼                      │
│  ┌─────────────────────────────────┐    │
│  │    Logging / Reporting          │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘

"@ -ForegroundColor White

#endregion

#region TEIL 2: Einfaches Menüsystem
#############################################################################

Write-Host "=== TEIL 2: Einfaches Menüsystem ===" -ForegroundColor Cyan

function Show-SimpleMenu {
    <#
    .SYNOPSIS
        Zeigt ein einfaches Textmenü an.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [string[]]$Options
    )
    
    Clear-Host
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Options[$i])"
    }
    
    Write-Host ""
    Write-Host "  [0] Beenden" -ForegroundColor Yellow
    Write-Host ""
    
    $selection = Read-Host "Auswahl"
    return $selection
}

# Demo
Write-Host "Einfaches Menü erstellt:" -ForegroundColor Yellow
Write-Host @'
$menuOptions = @(
    "System-Info anzeigen"
    "Dienste verwalten"
    "Logs analysieren"
    "Einstellungen"
)

do {
    $choice = Show-SimpleMenu -Title "Server Management" -Options $menuOptions
    
    switch ($choice) {
        "1" { Get-ComputerInfo | Select-Object CsName, OsName }
        "2" { Get-Service | Out-GridView }
        "3" { Get-EventLog -LogName System -Newest 10 }
        "4" { Write-Host "Einstellungen..." }
        "0" { break }
    }
    
    if ($choice -ne "0") { Read-Host "Enter zum Fortfahren" }
    
} while ($choice -ne "0")
'@

#endregion

#region TEIL 3: Erweitertes Menüsystem mit Objekten
#############################################################################

Write-Host "`n=== TEIL 3: Erweitertes Menüsystem ===" -ForegroundColor Cyan

function Show-InteractiveMenu {
    <#
    .SYNOPSIS
        Zeigt ein interaktives Menü mit Objekt-basierten Optionen.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [hashtable[]]$MenuItems,
        
        [Parameter()]
        [string]$FooterText = "Wählen Sie eine Option",
        
        [Parameter()]
        [ConsoleColor]$HeaderColor = 'Cyan',
        
        [Parameter()]
        [switch]$ClearScreen
    )
    
    if ($ClearScreen) { Clear-Host }
    
    # Header
    $width = 60
    Write-Host ("═" * $width) -ForegroundColor $HeaderColor
    Write-Host " $Title".PadRight($width - 1) -ForegroundColor $HeaderColor
    Write-Host ("═" * $width) -ForegroundColor $HeaderColor
    Write-Host ""
    
    # Menüpunkte
    foreach ($item in $MenuItems) {
        $key = "[$($item.Key)]".PadRight(6)
        $name = $item.Name
        
        if ($item.Disabled) {
            Write-Host "  $key $name" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  $key " -NoNewline -ForegroundColor Yellow
            Write-Host $name
            
            if ($item.Description) {
                Write-Host "        $($item.Description)" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host ""
    Write-Host ("─" * $width) -ForegroundColor DarkGray
    Write-Host "  [Q]  Beenden" -ForegroundColor Red
    Write-Host ""
    
    # Eingabe
    $selection = Read-Host $FooterText
    return $selection.ToUpper()
}

# Demo
$advancedMenu = @(
    @{
        Key = "1"
        Name = "System Status"
        Description = "CPU, RAM, Festplatten anzeigen"
        Action = { Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 }
    }
    @{
        Key = "2"
        Name = "Dienste verwalten"
        Description = "Windows-Dienste starten/stoppen"
        Action = { Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 10 }
    }
    @{
        Key = "3"
        Name = "Netzwerk-Info"
        Description = "IP-Adressen und Verbindungen"
        Action = { Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress }
    }
    @{
        Key = "4"
        Name = "Premium Feature"
        Description = "Nur mit Lizenz verfügbar"
        Disabled = $true
    }
)

Write-Host "Erweitertes Menü Demo:" -ForegroundColor Yellow
Write-Host @'
do {
    $choice = Show-InteractiveMenu -Title "Server Management Console" -MenuItems $advancedMenu
    
    $selected = $advancedMenu | Where-Object { $_.Key -eq $choice }
    
    if ($selected -and -not $selected.Disabled -and $selected.Action) {
        & $selected.Action | Format-Table
    }
} while ($choice -ne "Q")
'@

#endregion

#region TEIL 4: Benutzerinteraktion
#############################################################################

Write-Host "`n=== TEIL 4: Benutzerinteraktion ===" -ForegroundColor Cyan

function Read-UserInput {
    <#
    .SYNOPSIS
        Liest Benutzereingabe mit Validierung.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        
        [Parameter()]
        [string]$DefaultValue,
        
        [Parameter()]
        [string[]]$ValidValues,
        
        [Parameter()]
        [scriptblock]$Validation,
        
        [Parameter()]
        [switch]$Mandatory,
        
        [Parameter()]
        [switch]$AsSecureString
    )
    
    $promptText = $Prompt
    if ($DefaultValue) {
        $promptText += " [$DefaultValue]"
    }
    
    if ($ValidValues) {
        $promptText += " ($($ValidValues -join '/'))"
    }
    
    do {
        if ($AsSecureString) {
            $input = Read-Host -Prompt $promptText -AsSecureString
            # Für Validierung konvertieren
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($input)
            $plainInput = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        else {
            $rawInput = Read-Host -Prompt $promptText
            $plainInput = if ([string]::IsNullOrEmpty($rawInput) -and $DefaultValue) {
                $DefaultValue
            } else {
                $rawInput
            }
        }
        
        # Validierung
        $isValid = $true
        $errorMessage = ""
        
        if ($Mandatory -and [string]::IsNullOrEmpty($plainInput)) {
            $isValid = $false
            $errorMessage = "Eingabe ist erforderlich!"
        }
        elseif ($ValidValues -and $plainInput -notin $ValidValues) {
            $isValid = $false
            $errorMessage = "Ungültiger Wert. Erlaubt: $($ValidValues -join ', ')"
        }
        elseif ($Validation) {
            try {
                $isValid = & $Validation $plainInput
                if (-not $isValid) {
                    $errorMessage = "Validierung fehlgeschlagen"
                }
            }
            catch {
                $isValid = $false
                $errorMessage = $_.Exception.Message
            }
        }
        
        if (-not $isValid) {
            Write-Host "  ✗ $errorMessage" -ForegroundColor Red
        }
        
    } while (-not $isValid)
    
    if ($AsSecureString) {
        return $input
    }
    return $plainInput
}

function Read-Confirmation {
    <#
    .SYNOPSIS
        Fragt nach Ja/Nein-Bestätigung.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Question,
        
        [Parameter()]
        [bool]$DefaultYes = $true
    )
    
    $suffix = if ($DefaultYes) { "[J/n]" } else { "[j/N]" }
    $response = Read-Host "$Question $suffix"
    
    if ([string]::IsNullOrEmpty($response)) {
        return $DefaultYes
    }
    
    return $response -match '^[JjYy]'
}

# Demo
Write-Host "Benutzerinteraktion Beispiele:" -ForegroundColor Yellow
Write-Host @'

# Einfache Eingabe mit Default
$name = Read-UserInput -Prompt "Servername" -DefaultValue "localhost"

# Mit Validierung
$port = Read-UserInput -Prompt "Port" -DefaultValue "80" -Validation {
    param($value)
    [int]$value -ge 1 -and [int]$value -le 65535
}

# Mit erlaubten Werten
$env = Read-UserInput -Prompt "Umgebung" -ValidValues @('Dev', 'Test', 'Prod')

# Bestätigung
if (Read-Confirmation "Server wirklich neu starten?") {
    Restart-Computer -Force
}
'@

#endregion

#region TEIL 5: Vollständiges Controller Skript
#############################################################################

Write-Host "`n=== TEIL 5: Vollständiges Controller Skript ===" -ForegroundColor Cyan

# Simulierte Module (normalerweise aus .psm1 Dateien)
$script:LogPath = "$env:TEMP\Controller.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Konsole
    $color = switch ($Level) {
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Gray' }
    }
    Write-Host $logEntry -ForegroundColor $color
    
    # Datei
    Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Start-ServerMaintenanceController {
    <#
    .SYNOPSIS
        Hauptcontroller für Server-Wartung.
    
    .DESCRIPTION
        Demonstriert ein vollständiges Controller-Skript mit:
        - Menüsystem
        - Benutzerinteraktion
        - Logging
        - Modulintegration
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot\config.json",
        
        [Parameter()]
        [switch]$Verbose
    )
    
    # Initialisierung
    $startTime = Get-Date
    Write-Log "Controller gestartet" -Level Info
    
    # Konfiguration laden (simuliert)
    $config = @{
        ServerName = $env:COMPUTERNAME
        MaintenanceWindow = "Sunday 02:00-06:00"
        NotifyEmail = "admin@firma.de"
    }
    
    # Menü-Definition
    $mainMenu = @(
        @{
            Key = "1"
            Name = "System-Status"
            Description = "Aktuelle System-Informationen anzeigen"
            Action = {
                Write-Log "System-Status abgerufen"
                
                $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
                $os = Get-CimInstance Win32_OperatingSystem
                $mem = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1)
                
                [PSCustomObject]@{
                    ComputerName = $env:COMPUTERNAME
                    CPUUsage = "$cpu%"
                    MemoryUsage = "$mem%"
                    Uptime = (New-TimeSpan -Start $os.LastBootUpTime).ToString("d\.hh\:mm\:ss")
                    LastCheck = Get-Date -Format "HH:mm:ss"
                }
            }
        }
        @{
            Key = "2"
            Name = "Dienste verwalten"
            Description = "Windows-Dienste starten, stoppen, neustarten"
            Action = {
                Write-Host "`nDienste-Verwaltung:" -ForegroundColor Cyan
                Write-Host "  [1] Gestoppte Dienste anzeigen"
                Write-Host "  [2] Dienst starten"
                Write-Host "  [3] Dienst stoppen"
                Write-Host "  [0] Zurück"
                
                $serviceChoice = Read-Host "Auswahl"
                
                switch ($serviceChoice) {
                    "1" {
                        Get-Service | Where-Object Status -eq 'Stopped' | 
                            Select-Object Name, DisplayName, Status | 
                            Format-Table
                    }
                    "2" {
                        $svcName = Read-Host "Dienstname"
                        if ($svcName) {
                            Write-Log "Starte Dienst: $svcName"
                            # Start-Service -Name $svcName -WhatIf
                            Write-Host "Dienst $svcName würde gestartet werden" -ForegroundColor Yellow
                        }
                    }
                    "3" {
                        $svcName = Read-Host "Dienstname"
                        if ($svcName) {
                            Write-Log "Stoppe Dienst: $svcName"
                            # Stop-Service -Name $svcName -WhatIf
                            Write-Host "Dienst $svcName würde gestoppt werden" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }
        @{
            Key = "3"
            Name = "Wartung durchführen"
            Description = "Automatische Wartungsroutinen starten"
            Action = {
                Write-Host "`nWartungsoptionen:" -ForegroundColor Cyan
                $tasks = @(
                    "Temp-Dateien löschen"
                    "Log-Rotation"
                    "Windows-Updates prüfen"
                    "Festplatten-Check"
                )
                
                for ($i = 0; $i -lt $tasks.Count; $i++) {
                    Write-Host "  [$($i+1)] $($tasks[$i])"
                }
                
                $selection = Read-Host "Aufgaben auswählen (z.B. 1,2,3 oder 'alle')"
                
                $selectedTasks = if ($selection -eq 'alle') {
                    1..$tasks.Count
                } else {
                    $selection -split ',' | ForEach-Object { [int]$_.Trim() }
                }
                
                foreach ($idx in $selectedTasks) {
                    if ($idx -ge 1 -and $idx -le $tasks.Count) {
                        Write-Log "Starte: $($tasks[$idx-1])"
                        Write-Host "► $($tasks[$idx-1])..." -ForegroundColor Yellow
                        Start-Sleep -Milliseconds 500
                        Write-Host "  ✓ Abgeschlossen" -ForegroundColor Green
                    }
                }
            }
        }
        @{
            Key = "4"
            Name = "Berichte"
            Description = "Systemreporte erstellen und exportieren"
            Action = {
                Write-Host "`nBericht erstellen..." -ForegroundColor Cyan
                
                $report = @{
                    GeneratedAt = Get-Date
                    Server = $env:COMPUTERNAME
                    Services = (Get-Service).Count
                    RunningServices = (Get-Service | Where-Object Status -eq 'Running').Count
                    Processes = (Get-Process).Count
                    EventLogErrors = (Get-EventLog -LogName System -EntryType Error -Newest 100 -ErrorAction SilentlyContinue).Count
                }
                
                $reportPath = "$env:TEMP\ServerReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $report | ConvertTo-Json | Out-File $reportPath
                
                Write-Log "Bericht erstellt: $reportPath"
                Write-Host "Bericht gespeichert: $reportPath" -ForegroundColor Green
                
                $report | Format-List
            }
        }
        @{
            Key = "C"
            Name = "Konfiguration"
            Description = "Controller-Einstellungen anzeigen/ändern"
            Action = {
                Write-Host "`nAktuelle Konfiguration:" -ForegroundColor Cyan
                $config | Format-List
            }
        }
    )
    
    # Hauptschleife
    do {
        Write-Host ""
        $choice = Show-InteractiveMenu -Title "Server Wartungs-Controller" `
                                       -MenuItems $mainMenu `
                                       -ClearScreen
        
        if ($choice -eq 'Q') {
            break
        }
        
        $selected = $mainMenu | Where-Object { $_.Key -eq $choice }
        
        if ($selected -and $selected.Action) {
            try {
                & $selected.Action | Format-Table -AutoSize
            }
            catch {
                Write-Log "Fehler: $_" -Level Error
            }
            
            Write-Host ""
            Read-Host "Enter zum Fortfahren"
        }
        
    } while ($true)
    
    # Cleanup
    $duration = (Get-Date) - $startTime
    Write-Log "Controller beendet (Laufzeit: $($duration.ToString('hh\:mm\:ss')))" -Level Info
}

Write-Host "Controller-Skript definiert." -ForegroundColor Green
Write-Host "Starten mit: Start-ServerMaintenanceController" -ForegroundColor Yellow

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 08" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. CONTROLLER SKRIPT PATTERN:
   - Zentrales Steuerungs-Skript
   - Lädt Module und Funktionen
   - Orchestriert Workflow
   - Integriert Logging

2. MENÜSYSTEM:
   - Textbasierte Menüs mit Nummerierung
   - Objekt-basierte Menüdefinition
   - Unterstützung für Untermenüs
   - Deaktivierte Optionen

3. BENUTZERINTERAKTION:
   - Validierte Eingaben
   - Default-Werte
   - Bestätigungsdialoge
   - Sichere Passworteingabe

4. BEST PRACTICES:
   - Logging von Aktionen
   - Fehlerbehandlung
   - Konfigurationsdateien
   - Saubere Trennung der Logik

5. TYPISCHE STRUKTUR:
   Controller.ps1
   ├── Modul-Import
   ├── Konfiguration laden
   ├── Menü-Definition
   ├── Hauptschleife
   │   ├── Menü anzeigen
   │   ├── Eingabe verarbeiten
   │   └── Aktion ausführen
   └── Cleanup

"@ -ForegroundColor White

#endregion
