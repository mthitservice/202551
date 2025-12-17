#############################################################################
# Modul 06: Dokumentation mit Comment-Based Help
# PowerShell Expertenkurs - Tag 2
#############################################################################

<#
LERNZIELE:
- Comment-Based Help verstehen und nutzen
- Alle Help-Keywords kennenlernen
- Beispiele effektiv dokumentieren
- Help für Module erstellen
- External Help Files (MAML)

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Grundlagen Comment-Based Help
#############################################################################

Write-Host "=== TEIL 1: Comment-Based Help Grundlagen ===" -ForegroundColor Cyan

# === DEMO 1.1: Vollständig dokumentierte Funktion ===

function Get-SystemReport {
    <#
    .SYNOPSIS
        Erstellt einen umfassenden Systembericht.
    
    .DESCRIPTION
        Die Funktion Get-SystemReport sammelt System-Informationen wie
        Betriebssystem, Hardware, Speicher und Netzwerk-Konfiguration
        und erstellt einen strukturierten Bericht.
        
        Die Funktion unterstützt lokale und Remote-Abfragen und kann
        die Ergebnisse in verschiedenen Formaten ausgeben.
    
    .PARAMETER ComputerName
        Der Name des Computers, von dem der Bericht erstellt werden soll.
        Standard ist der lokale Computer.
        
        Akzeptiert Pipeline-Eingaben.
    
    .PARAMETER IncludeNetwork
        Wenn angegeben, werden auch Netzwerk-Informationen gesammelt.
        Dies kann die Ausführung verlangsamen.
    
    .PARAMETER OutputFormat
        Das Ausgabeformat des Berichts.
        Mögliche Werte: Object, HTML, JSON
        Standard: Object
    
    .PARAMETER Credential
        Anmeldeinformationen für Remote-Abfragen.
        Nur erforderlich wenn ComputerName ein Remote-System ist.
    
    .INPUTS
        System.String
        Sie können Computernamen als Pipeline-Eingabe übergeben.
    
    .OUTPUTS
        PSCustomObject
        Ein Objekt mit den gesammelten System-Informationen.
        
        System.String
        Bei OutputFormat HTML oder JSON wird ein String zurückgegeben.
    
    .EXAMPLE
        Get-SystemReport
        
        Erstellt einen Systembericht für den lokalen Computer.
    
    .EXAMPLE
        Get-SystemReport -ComputerName "Server01" -IncludeNetwork
        
        Erstellt einen Systembericht für Server01 inklusive Netzwerk-Info.
    
    .EXAMPLE
        "Server01", "Server02" | Get-SystemReport | Export-Csv report.csv
        
        Erstellt Berichte für mehrere Server und exportiert nach CSV.
    
    .EXAMPLE
        Get-SystemReport -OutputFormat HTML | Out-File report.html
        
        Erstellt einen HTML-Bericht und speichert ihn als Datei.
    
    .NOTES
        Autor: PowerShell Trainer
        Version: 1.0.0
        Datum: Dezember 2025
        
        Änderungshistorie:
        1.0.0 - Initiale Version
    
    .LINK
        https://docs.microsoft.com/powershell
    
    .LINK
        Get-ComputerInfo
    
    .LINK
        Get-CimInstance
    
    .COMPONENT
        SystemManagement
    
    .ROLE
        Administrator
    
    .FUNCTIONALITY
        System Monitoring
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([PSCustomObject], ParameterSetName = 'Default')]
    [OutputType([string], ParameterSetName = 'HTML')]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Geben Sie den Computernamen ein"
        )]
        [Alias('CN', 'Server')]
        [string]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [switch]$IncludeNetwork,
        
        [Parameter()]
        [ValidateSet('Object', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Object',
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    process {
        Write-Verbose "Erstelle Bericht für: $ComputerName"
        
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        
        $report = [PSCustomObject]@{
            ComputerName = $ComputerName
            OS = $os.Caption
            OSVersion = $os.Version
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            FreeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            ReportTime = Get-Date
        }
        
        if ($IncludeNetwork) {
            $network = Get-NetAdapter | Where-Object Status -eq 'Up' | 
                Select-Object Name, Status, MacAddress
            $report | Add-Member -NotePropertyName 'NetworkAdapters' -NotePropertyValue $network
        }
        
        switch ($OutputFormat) {
            'HTML' { $report | ConvertTo-Html -As List | Out-String }
            'JSON' { $report | ConvertTo-Json }
            default { $report }
        }
    }
}

# Help anzeigen
Write-Host "Basis-Hilfe:" -ForegroundColor Yellow
Get-Help Get-SystemReport

Write-Host "`nDetaillierte Hilfe:" -ForegroundColor Yellow
Get-Help Get-SystemReport -Detailed | Select-Object -First 50

Write-Host "`nBeispiele:" -ForegroundColor Yellow
Get-Help Get-SystemReport -Examples

#endregion

#region TEIL 2: Alle Help-Keywords
#############################################################################

Write-Host "`n=== TEIL 2: Help-Keywords Übersicht ===" -ForegroundColor Cyan

Write-Host @"

ALLE COMMENT-BASED HELP KEYWORDS:
==================================

PFLICHT (mindestens eines):
  .SYNOPSIS      - Kurze Beschreibung (1-2 Sätze)
  .DESCRIPTION   - Ausführliche Beschreibung

PARAMETER:
  .PARAMETER     - Beschreibung für jeden Parameter

INPUT/OUTPUT:
  .INPUTS        - Akzeptierte Pipeline-Input-Typen
  .OUTPUTS       - Rückgabe-Typen
  .RETURNVALUE   - Alias für .OUTPUTS

BEISPIELE:
  .EXAMPLE       - Nutzungsbeispiele (kann mehrfach vorkommen)

ZUSATZINFO:
  .NOTES         - Autor, Version, Änderungshistorie
  .LINK          - Verwandte Hilfe-Themen oder URLs
  .COMPONENT     - Technologie-Komponente
  .ROLE          - Benutzerrolle
  .FUNCTIONALITY - Funktionskategorie

EXTERNAL HELP:
  .EXTERNALHELP  - Pfad zu XML-Help-Datei
  .FORWARDHELPTARGETNAME  - Weiterleitung zu anderer Hilfe
  .FORWARDHELPCATEGORY    - Kategorie der Weiterleitung
  .REMOTEHELPRUNSPACE     - Runspace für Remote-Hilfe

"@ -ForegroundColor White

#endregion

#region TEIL 3: Parameter-Dokumentation
#############################################################################

Write-Host "`n=== TEIL 3: Parameter-Dokumentation ===" -ForegroundColor Cyan

function Set-Configuration {
    <#
    .SYNOPSIS
        Setzt Konfigurationswerte.
    
    .DESCRIPTION
        Erlaubt das Setzen von Konfigurationswerten mit verschiedenen
        Optionen und Validierungen.
    
    .PARAMETER Name
        Der Name der Konfiguration.
        
        Muss alphanumerisch sein und darf keine Sonderzeichen enthalten.
        Groß-/Kleinschreibung wird ignoriert.
        
        Typ: String
        Position: 0
        Pflicht: Ja
    
    .PARAMETER Value
        Der zu setzende Wert.
        
        Kann jeden Datentyp haben. Komplexe Objekte werden serialisiert.
        
        Typ: Object
        Position: 1
        Pflicht: Ja
    
    .PARAMETER Scope
        Der Gültigkeitsbereich der Konfiguration.
        
        | Wert    | Beschreibung                     |
        |---------|----------------------------------|
        | User    | Nur für aktuellen Benutzer      |
        | Machine | Für alle Benutzer (Admin nötig) |
        | Process | Nur für aktuellen Prozess       |
        
        Standard: User
    
    .PARAMETER Force
        Überschreibt existierende Konfiguration ohne Nachfrage.
        
        WARNUNG: Kann zu Datenverlust führen!
    
    .PARAMETER PassThru
        Gibt die gesetzte Konfiguration als Objekt zurück.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9]+$')]
        [string]$Name,
        
        [Parameter(Mandatory, Position = 1)]
        [object]$Value,
        
        [Parameter()]
        [ValidateSet('User', 'Machine', 'Process')]
        [string]$Scope = 'User',
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    if ($PSCmdlet.ShouldProcess("$Name in $Scope", "Set configuration")) {
        Write-Verbose "Setze $Name = $Value (Scope: $Scope)"
        
        $config = [PSCustomObject]@{
            Name = $Name
            Value = $Value
            Scope = $Scope
            SetAt = Get-Date
        }
        
        if ($PassThru) {
            $config
        }
    }
}

Write-Host "Parameter-Hilfe:" -ForegroundColor Yellow
Get-Help Set-Configuration -Parameter * | Format-List name, description

#endregion

#region TEIL 4: Effektive Beispiele schreiben
#############################################################################

Write-Host "`n=== TEIL 4: Effektive Beispiele ===" -ForegroundColor Cyan

function Invoke-DataProcessing {
    <#
    .SYNOPSIS
        Verarbeitet Daten mit verschiedenen Optionen.
    
    .DESCRIPTION
        Diese Funktion demonstriert effektive Beispiel-Dokumentation.
    
    .EXAMPLE
        Invoke-DataProcessing -InputPath "C:\Data\input.csv"
        
        Einfachster Aufruf: Verarbeitet eine CSV-Datei mit Standardeinstellungen.
    
    .EXAMPLE
        Invoke-DataProcessing -InputPath "C:\Data\*.csv" -Recurse
        
        Verarbeitet alle CSV-Dateien rekursiv.
        
        Hinweis: Wildcards werden unterstützt.
    
    .EXAMPLE
        PS C:\> $results = Get-ChildItem *.csv | Invoke-DataProcessing -PassThru
        PS C:\> $results | Export-Csv summary.csv
        
        Pipeline-Beispiel: Findet CSV-Dateien, verarbeitet sie und exportiert
        die Ergebnisse.
        
        - Schritt 1: CSV-Dateien finden
        - Schritt 2: Durch Pipeline an Funktion übergeben
        - Schritt 3: Ergebnisse exportieren
    
    .EXAMPLE
        # Batch-Verarbeitung mit Fehlerprotokoll
        
        $errors = @()
        Get-ChildItem C:\Data -Filter *.csv | ForEach-Object {
            try {
                Invoke-DataProcessing -InputPath $_.FullName -ErrorAction Stop
            }
            catch {
                $errors += [PSCustomObject]@{
                    File = $_.Name
                    Error = $_.Exception.Message
                }
            }
        }
        
        if ($errors) {
            $errors | Export-Csv errors.csv
            Write-Warning "$($errors.Count) Fehler aufgetreten"
        }
        
        Komplexes Beispiel mit Fehlerbehandlung für Produktionsumgebungen.
    
    .EXAMPLE
        # Vergleich verschiedener Modi
        
        # Modus 1: Schnell, weniger genau
        Invoke-DataProcessing -InputPath data.csv -Mode Fast
        
        # Modus 2: Präzise, langsamer
        Invoke-DataProcessing -InputPath data.csv -Mode Precise
        
        # Modus 3: Balanciert (Standard)
        Invoke-DataProcessing -InputPath data.csv -Mode Balanced
        
        Zeigt die verschiedenen Verarbeitungsmodi.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName', 'Path')]
        [string]$InputPath,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [ValidateSet('Fast', 'Balanced', 'Precise')]
        [string]$Mode = 'Balanced',
        
        [Parameter()]
        [switch]$PassThru
    )
    
    process {
        Write-Verbose "Verarbeite: $InputPath (Mode: $Mode)"
        # Simulierte Verarbeitung
        [PSCustomObject]@{
            InputPath = $InputPath
            Mode = $Mode
            ProcessedAt = Get-Date
        }
    }
}

Write-Host "Beispiele anzeigen:" -ForegroundColor Yellow
Get-Help Invoke-DataProcessing -Examples

#endregion

#region TEIL 5: Help für Module
#############################################################################

Write-Host "`n=== TEIL 5: Modul-Hilfe ===" -ForegroundColor Cyan

# About-Topic erstellen
$aboutTopic = @'
TOPIC
    about_DemoModule

SHORT DESCRIPTION
    Beschreibt das DemoModule und seine Funktionen.

LONG DESCRIPTION
    Das DemoModule ist eine Sammlung von PowerShell-Funktionen für
    System-Administration und Monitoring.

    FUNKTIONEN
    ----------
    Get-SystemReport    - Erstellt System-Berichte
    Set-Configuration   - Setzt Konfigurationswerte
    
    INSTALLATION
    ------------
    Install-Module DemoModule -Scope CurrentUser
    
    ERSTE SCHRITTE
    --------------
    Nach der Installation können Sie mit folgendem Befehl starten:
    
        Import-Module DemoModule
        Get-Command -Module DemoModule
    
    KONFIGURATION
    -------------
    Das Modul speichert Einstellungen unter:
    $env:APPDATA\DemoModule\config.json

EXAMPLES
    # Alle Funktionen des Moduls auflisten
    Get-Command -Module DemoModule
    
    # Hilfe zu einer bestimmten Funktion
    Get-Help Get-SystemReport -Full

SEE ALSO
    about_Functions_Advanced
    about_Modules
    https://github.com/example/DemoModule

KEYWORDS
    DemoModule, SystemReport, Configuration
'@

Write-Host "About-Topic Beispiel:" -ForegroundColor Yellow
Write-Host $aboutTopic

Write-Host @"

MODUL-HILFE DATEIEN:
====================

Struktur für Modul-Hilfe:
    DemoModule/
    ├── DemoModule.psd1
    ├── DemoModule.psm1
    ├── en-US/
    │   └── about_DemoModule.help.txt
    └── de-DE/
        └── about_DemoModule.help.txt

Zugriff:
    Get-Help about_DemoModule

"@ -ForegroundColor White

#endregion

#region TEIL 6: Help testen und validieren
#############################################################################

Write-Host "`n=== TEIL 6: Help testen ===" -ForegroundColor Cyan

function Test-FunctionHelp {
    <#
    .SYNOPSIS
        Testet ob eine Funktion vollständig dokumentiert ist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName
    )
    
    $help = Get-Help $FunctionName -Full
    
    $checks = [ordered]@{
        'SYNOPSIS vorhanden' = [bool]$help.Synopsis -and $help.Synopsis -ne $FunctionName
        'DESCRIPTION vorhanden' = [bool]$help.Description
        'EXAMPLES vorhanden' = [bool]$help.Examples
        'PARAMETERS dokumentiert' = ($help.Parameters.Parameter | Where-Object { $_.Description }).Count -gt 0
        'INPUTS dokumentiert' = [bool]$help.inputTypes
        'OUTPUTS dokumentiert' = [bool]$help.returnValues
        'NOTES vorhanden' = [bool]$help.alertSet
        'LINKS vorhanden' = [bool]$help.relatedLinks
    }
    
    $passed = 0
    $total = $checks.Count
    
    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "✓"; $passed++ } else { "✗" }
        $color = if ($check.Value) { "Green" } else { "Red" }
        Write-Host "  $status $($check.Key)" -ForegroundColor $color
    }
    
    Write-Host "`nErgebnis: $passed/$total Checks bestanden" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
}

Write-Host "Help-Qualitätsprüfung für Get-SystemReport:" -ForegroundColor Yellow
Test-FunctionHelp -FunctionName "Get-SystemReport"

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 06" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. GRUNDSTRUKTUR:
   <#
   .SYNOPSIS
       Kurzbeschreibung
   .DESCRIPTION
       Ausführliche Beschreibung
   .PARAMETER ParamName
       Parameter-Beschreibung
   .EXAMPLE
       Nutzungsbeispiel
   #>

2. WICHTIGE KEYWORDS:
   - .SYNOPSIS, .DESCRIPTION (Beschreibung)
   - .PARAMETER (Parameter-Doku)
   - .INPUTS, .OUTPUTS (Typen)
   - .EXAMPLE (Beispiele)
   - .NOTES, .LINK (Metadaten)

3. BEISPIELE SCHREIBEN:
   - Einfach zu komplex
   - Erklärende Kommentare
   - Echte Anwendungsfälle
   - Multi-Line für komplexe Szenarien

4. BEST PRACTICES:
   - Jede öffentliche Funktion dokumentieren
   - Mindestens 2-3 Beispiele
   - Parameter vollständig beschreiben
   - About-Topics für Module

5. HILFE TESTEN:
   Get-Help FunctionName -Full
   Get-Help FunctionName -Examples
   Get-Help FunctionName -Parameter *

"@ -ForegroundColor White

#endregion
