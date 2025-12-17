#############################################################################
# Modul 02: Skript-Module erstellen - LÖSUNGEN
# PowerShell Expertenkurs - Tag 1
#############################################################################

#region VORBEREITUNG
#############################################################################

# Löschung vorheriger Versionen
$ModulePaths = @("C:\Temp\NetworkTools", "C:\Temp\ProcessManager")
foreach ($path in $ModulePaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
    }
    New-Item -Path $path -ItemType Directory -Force | Out-Null
}

#endregion

#region LÖSUNG AUFGABE 1: NetworkTools Modul
#############################################################################

Write-Host "=== LÖSUNG AUFGABE 1: NetworkTools ===" -ForegroundColor Cyan

$NetworkToolsPath = "C:\Temp\NetworkTools"

# NetworkTools.psm1 erstellen
$NetworkToolsContent = @'
#############################################################################
# NetworkTools.psm1 - Netzwerk-Utility Modul
#############################################################################

#region PRIVATE FUNKTIONEN
#############################################################################

function Format-Timestamp {
    <#
    .SYNOPSIS
        Private Hilfsfunktion für Zeitstempel-Formatierung.
    #>
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

#endregion

#region ÖFFENTLICHE FUNKTIONEN
#############################################################################

function Test-PortConnection {
    <#
    .SYNOPSIS
        Testet ob ein TCP-Port erreichbar ist.
    .PARAMETER ComputerName
        Der Zielhost.
    .PARAMETER Port
        Der zu testende Port.
    .PARAMETER Timeout
        Timeout in Sekunden. Standard: 3
    .EXAMPLE
        Test-PortConnection -ComputerName "google.com" -Port 443
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ComputerName,
        
        [Parameter(Mandatory, Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port,
        
        [Parameter()]
        [ValidateRange(1, 30)]
        [int]$Timeout = 3
    )
    
    Write-Verbose "Teste Port $Port auf $ComputerName (Timeout: ${Timeout}s)"
    
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $asyncResult = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $success = $asyncResult.AsyncWaitHandle.WaitOne($Timeout * 1000, $false)
        $stopwatch.Stop()
        
        if ($success) {
            $tcpClient.EndConnect($asyncResult)
        }
        
        [PSCustomObject]@{
            ComputerName = $ComputerName
            Port = $Port
            IsOpen = $success
            ResponseTimeMs = if ($success) { $stopwatch.ElapsedMilliseconds } else { $null }
            Timestamp = Format-Timestamp
        }
    }
    catch {
        Write-Warning "Verbindungsfehler: $_"
        
        [PSCustomObject]@{
            ComputerName = $ComputerName
            Port = $Port
            IsOpen = $false
            ResponseTimeMs = $null
            Timestamp = Format-Timestamp
        }
    }
    finally {
        $tcpClient.Close()
        $tcpClient.Dispose()
    }
}

function Get-PublicIPAddress {
    <#
    .SYNOPSIS
        Ermittelt die öffentliche IP-Adresse.
    .EXAMPLE
        Get-PublicIPAddress
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    Write-Verbose "Rufe öffentliche IP-Adresse ab..."
    
    $services = @(
        'https://api.ipify.org'
        'https://icanhazip.com'
        'https://checkip.amazonaws.com'
    )
    
    $ipAddress = $null
    
    foreach ($service in $services) {
        try {
            Write-Verbose "Versuche Service: $service"
            $ipAddress = (Invoke-RestMethod -Uri $service -TimeoutSec 5).Trim()
            
            if ($ipAddress -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                Write-Verbose "IP erfolgreich ermittelt: $ipAddress"
                break
            }
        }
        catch {
            Write-Verbose "Service $service nicht erreichbar: $_"
        }
    }
    
    [PSCustomObject]@{
        IPAddress = $ipAddress
        Service = $service
        CheckTime = Format-Timestamp
    }
}

function Get-DNSInfo {
    <#
    .SYNOPSIS
        Löst DNS-Namen auf und zeigt Informationen an.
    .PARAMETER DomainName
        Der aufzulösende Domain-Name.
    .EXAMPLE
        Get-DNSInfo -DomainName "microsoft.com"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName
    )
    
    Write-Verbose "Löse DNS für: $DomainName"
    
    try {
        $dnsResult = Resolve-DnsName -Name $DomainName -ErrorAction Stop
        
        # Gruppieren nach Record-Typ
        $aRecords = $dnsResult | Where-Object Type -eq 'A'
        $aaaaRecords = $dnsResult | Where-Object Type -eq 'AAAA'
        $cnameRecords = $dnsResult | Where-Object Type -eq 'CNAME'
        
        [PSCustomObject]@{
            DomainName = $DomainName
            IPv4Addresses = @($aRecords.IPAddress)
            IPv6Addresses = @($aaaaRecords.IPAddress)
            CNAMEs = @($cnameRecords.NameHost)
            RecordCount = $dnsResult.Count
            QueryTime = Format-Timestamp
        }
    }
    catch {
        Write-Warning "DNS-Auflösung fehlgeschlagen: $_"
        
        [PSCustomObject]@{
            DomainName = $DomainName
            IPv4Addresses = @()
            IPv6Addresses = @()
            CNAMEs = @()
            RecordCount = 0
            QueryTime = Format-Timestamp
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region MODUL-EXPORT
#############################################################################

# Nur öffentliche Funktionen exportieren!
Export-ModuleMember -Function @(
    'Test-PortConnection',
    'Get-PublicIPAddress',
    'Get-DNSInfo'
)

#endregion
'@

$NetworkToolsContent | Out-File "$NetworkToolsPath\NetworkTools.psm1" -Encoding UTF8
Write-Host "NetworkTools.psm1 erstellt" -ForegroundColor Green

# Test des Moduls
Remove-Module NetworkTools -ErrorAction SilentlyContinue
Import-Module "$NetworkToolsPath\NetworkTools.psm1" -Verbose

Write-Host "`nExportierte Funktionen:" -ForegroundColor Yellow
Get-Command -Module NetworkTools

Write-Host "`nTest Test-PortConnection:" -ForegroundColor Yellow
Test-PortConnection -ComputerName "google.com" -Port 443 -Verbose

Write-Host "`nTest Get-PublicIPAddress:" -ForegroundColor Yellow
Get-PublicIPAddress -Verbose

Write-Host "`nTest Get-DNSInfo:" -ForegroundColor Yellow
Get-DNSInfo -DomainName "microsoft.com" -Verbose

# Prüfen ob private Funktion versteckt ist
Write-Host "`nTest private Funktion (sollte Fehler geben):" -ForegroundColor Yellow
try {
    Format-Timestamp
} catch {
    Write-Host "  Korrekt! Format-Timestamp ist nicht exportiert." -ForegroundColor Green
}

#endregion

#region LÖSUNG AUFGABE 2: Module Manifest
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 2: Module Manifest ===" -ForegroundColor Cyan

$ManifestParams = @{
    Path              = "$NetworkToolsPath\NetworkTools.psd1"
    RootModule        = 'NetworkTools.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = (New-Guid).Guid
    Author            = 'PowerShell Kursteilnehmer'
    CompanyName       = 'Training GmbH'
    Copyright         = "(c) $(Get-Date -Format yyyy) Training GmbH. Alle Rechte vorbehalten."
    Description       = 'Sammlung von Netzwerk-Diagnose-Tools für PowerShell. Enthält Funktionen für Port-Tests, IP-Ermittlung und DNS-Abfragen.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Test-PortConnection',
        'Get-PublicIPAddress',
        'Get-DNSInfo'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    Tags              = @('Network', 'Diagnostic', 'DNS', 'TCP', 'IP')
    ProjectUri        = 'https://github.com/example/NetworkTools'
    LicenseUri        = 'https://github.com/example/NetworkTools/LICENSE'
}

New-ModuleManifest @ManifestParams
Write-Host "NetworkTools.psd1 erstellt" -ForegroundColor Green

# Manifest validieren
Write-Host "`nManifest validieren:" -ForegroundColor Yellow
$manifestTest = Test-ModuleManifest -Path "$NetworkToolsPath\NetworkTools.psd1"
$manifestTest | Format-List Name, Version, Author, Description

# Modul über Manifest neu laden
Remove-Module NetworkTools -Force -ErrorAction SilentlyContinue
Import-Module "$NetworkToolsPath\NetworkTools.psd1" -Verbose

Write-Host "`nModul-Info nach Import über Manifest:" -ForegroundColor Yellow
Get-Module NetworkTools | Format-List Name, Version, Author, ExportedFunctions

#endregion

#region LÖSUNG AUFGABE 3: ProcessManager (Fortgeschrittenes Modul)
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 3: ProcessManager ===" -ForegroundColor Cyan

$ProcessManagerPath = "C:\Temp\ProcessManager"

# Ordnerstruktur erstellen
@(
    "$ProcessManagerPath\Public"
    "$ProcessManagerPath\Private"
    "$ProcessManagerPath\Classes"
    "$ProcessManagerPath\Data"
) | ForEach-Object {
    New-Item -Path $_ -ItemType Directory -Force | Out-Null
}

# --- config.json ---
$ConfigContent = @'
{
    "DefaultThresholdMB": 100,
    "DefaultExcludeProcesses": ["System", "Idle", "Registry"],
    "LoggingEnabled": true,
    "MaxResults": 50
}
'@
$ConfigContent | Out-File "$ProcessManagerPath\Data\config.json" -Encoding UTF8

# --- Private\ConvertTo-SizeString.ps1 ---
$PrivateConvertSize = @'
function ConvertTo-SizeString {
    <#
    .SYNOPSIS
        Konvertiert Bytes in lesbare Größenangaben.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [long]$Bytes
    )
    
    process {
        switch ($Bytes) {
            { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB); break }
            { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB); break }
            { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB); break }
            default { "$_ Bytes" }
        }
    }
}
'@
$PrivateConvertSize | Out-File "$ProcessManagerPath\Private\ConvertTo-SizeString.ps1" -Encoding UTF8

# --- Public\Get-ProcessReport.ps1 ---
$PublicGetReport = @'
function Get-ProcessReport {
    <#
    .SYNOPSIS
        Erstellt einen detaillierten Prozess-Report.
    .PARAMETER Name
        Prozessname (Wildcards erlaubt). Standard: *
    .PARAMETER MinMemoryMB
        Mindest-Speicherverbrauch in MB. Standard: 0
    .EXAMPLE
        Get-ProcessReport -MinMemoryMB 50
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [string]$Name = '*',
        
        [Parameter(Position = 1)]
        [ValidateRange(0, [int]::MaxValue)]
        [double]$MinMemoryMB = 0
    )
    
    Write-Verbose "Erstelle Prozess-Report: Name='$Name', MinMemoryMB=$MinMemoryMB"
    
    $processes = Get-Process -Name $Name -ErrorAction SilentlyContinue |
        Where-Object { ($_.WorkingSet64 / 1MB) -ge $MinMemoryMB }
    
    Write-Verbose "Gefundene Prozesse: $($processes.Count)"
    
    $processes | 
        Sort-Object WorkingSet64 -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Id = $_.Id
                CPUSeconds = [math]::Round($_.CPU, 2)
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
                MemoryFormatted = ConvertTo-SizeString -Bytes $_.WorkingSet64
                StartTime = $_.StartTime
                Handles = $_.HandleCount
                Threads = $_.Threads.Count
            }
        }
}
'@
$PublicGetReport | Out-File "$ProcessManagerPath\Public\Get-ProcessReport.ps1" -Encoding UTF8

# --- Public\Stop-ProcessByMemory.ps1 ---
$PublicStopProcess = @'
function Stop-ProcessByMemory {
    <#
    .SYNOPSIS
        Stoppt Prozesse basierend auf Speicherverbrauch.
    .PARAMETER ThresholdMB
        Speicher-Schwellwert in MB.
    .PARAMETER Exclude
        Liste von Prozessnamen die ausgeschlossen werden.
    .EXAMPLE
        Stop-ProcessByMemory -ThresholdMB 500 -WhatIf
    .EXAMPLE
        Stop-ProcessByMemory -ThresholdMB 1000 -Exclude "explorer","dwm" -Confirm
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [double]$ThresholdMB,
        
        [Parameter()]
        [string[]]$Exclude = @()
    )
    
    # Config laden für Standard-Ausschlüsse
    $configPath = Join-Path $PSScriptRoot "..\Data\config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        $Exclude += $config.DefaultExcludeProcesses
    }
    
    Write-Verbose "Schwellwert: $ThresholdMB MB"
    Write-Verbose "Ausgeschlossene Prozesse: $($Exclude -join ', ')"
    
    $processes = Get-Process | 
        Where-Object { 
            ($_.WorkingSet64 / 1MB) -gt $ThresholdMB -and 
            $_.Name -notin $Exclude 
        } |
        Sort-Object WorkingSet64 -Descending
    
    Write-Verbose "Gefundene Prozesse über Schwellwert: $($processes.Count)"
    
    foreach ($proc in $processes) {
        $memoryMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        $message = "Prozess '$($proc.Name)' (ID: $($proc.Id), Memory: $memoryMB MB)"
        
        if ($PSCmdlet.ShouldProcess($message, "Beenden")) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-Verbose "Beendet: $message"
                
                [PSCustomObject]@{
                    ProcessName = $proc.Name
                    ProcessId = $proc.Id
                    MemoryMB = $memoryMB
                    Action = 'Stopped'
                    Time = Get-Date
                }
            }
            catch {
                Write-Warning "Konnte Prozess nicht beenden: $($proc.Name) - $_"
                
                [PSCustomObject]@{
                    ProcessName = $proc.Name
                    ProcessId = $proc.Id
                    MemoryMB = $memoryMB
                    Action = 'Failed'
                    Time = Get-Date
                    Error = $_.Exception.Message
                }
            }
        }
    }
}
'@
$PublicStopProcess | Out-File "$ProcessManagerPath\Public\Stop-ProcessByMemory.ps1" -Encoding UTF8

# --- Public\Get-ProcessTree.ps1 ---
$PublicGetTree = @'
function Get-ProcessTree {
    <#
    .SYNOPSIS
        Zeigt Parent- und Child-Prozesse an.
    .PARAMETER ProcessId
        Die Prozess-ID.
    .PARAMETER Name
        Der Prozessname.
    .EXAMPLE
        Get-ProcessTree -ProcessId 1234
    .EXAMPLE
        Get-ProcessTree -Name "pwsh"
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById', Position = 0)]
        [int]$ProcessId,
        
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string]$Name
    )
    
    Write-Verbose "ParameterSet: $($PSCmdlet.ParameterSetName)"
    
    # Prozess ermitteln
    $targetProcess = switch ($PSCmdlet.ParameterSetName) {
        'ById'   { Get-Process -Id $ProcessId -ErrorAction SilentlyContinue }
        'ByName' { Get-Process -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1 }
    }
    
    if (-not $targetProcess) {
        Write-Warning "Prozess nicht gefunden"
        return
    }
    
    Write-Verbose "Ziel-Prozess: $($targetProcess.Name) (ID: $($targetProcess.Id))"
    
    # WMI für Parent-Prozess-Info nutzen
    $wmiProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($targetProcess.Id)"
    
    $parentProcess = $null
    if ($wmiProcess.ParentProcessId) {
        $parentProcess = Get-Process -Id $wmiProcess.ParentProcessId -ErrorAction SilentlyContinue
    }
    
    # Child-Prozesse finden
    $childProcesses = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($targetProcess.Id)" |
        ForEach-Object {
            Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
        }
    
    [PSCustomObject]@{
        ProcessName = $targetProcess.Name
        ProcessId = $targetProcess.Id
        MemoryMB = [math]::Round($targetProcess.WorkingSet64 / 1MB, 2)
        ParentName = $parentProcess.Name
        ParentId = $wmiProcess.ParentProcessId
        ChildCount = @($childProcesses).Count
        Children = @($childProcesses | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Id = $_.Id
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
            }
        })
    }
}
'@
$PublicGetTree | Out-File "$ProcessManagerPath\Public\Get-ProcessTree.ps1" -Encoding UTF8

# --- ProcessManager.psm1 (Haupt-Modul) ---
$MainModule = @'
#############################################################################
# ProcessManager.psm1 - Prozess-Management-Modul
#############################################################################

# Modul-Variablen
$script:ModuleRoot = $PSScriptRoot
$script:Config = $null

# Config laden
$configPath = Join-Path $PSScriptRoot "Data\config.json"
if (Test-Path $configPath) {
    $script:Config = Get-Content $configPath | ConvertFrom-Json
    Write-Verbose "Config geladen: $configPath"
}

# Private Funktionen laden (Dot-Sourcing)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($file in $Private) {
    try {
        Write-Verbose "Lade Private: $($file.Name)"
        . $file.FullName
    }
    catch {
        Write-Error "Fehler beim Laden von $($file.Name): $_"
    }
}

# Public Funktionen laden (Dot-Sourcing)
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($file in $Public) {
    try {
        Write-Verbose "Lade Public: $($file.Name)"
        . $file.FullName
    }
    catch {
        Write-Error "Fehler beim Laden von $($file.Name): $_"
    }
}

# Nur Public Funktionen exportieren
Export-ModuleMember -Function $Public.BaseName

# Modul-Info ausgeben
Write-Verbose "ProcessManager geladen: $($Public.Count) öffentliche Funktionen"
'@
$MainModule | Out-File "$ProcessManagerPath\ProcessManager.psm1" -Encoding UTF8

# --- ProcessManager.psd1 (Manifest) ---
New-ModuleManifest -Path "$ProcessManagerPath\ProcessManager.psd1" `
    -RootModule 'ProcessManager.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'PowerShell Kursteilnehmer' `
    -Description 'Erweiterte Prozess-Management-Tools für PowerShell' `
    -PowerShellVersion '5.1' `
    -FunctionsToExport @('Get-ProcessReport', 'Stop-ProcessByMemory', 'Get-ProcessTree') `
    -CmdletsToExport @() `
    -AliasesToExport @()

Write-Host "ProcessManager Modul erstellt!" -ForegroundColor Green

# Modul laden und testen
Remove-Module ProcessManager -Force -ErrorAction SilentlyContinue
Import-Module $ProcessManagerPath -Verbose

Write-Host "`nExportierte Funktionen:" -ForegroundColor Yellow
Get-Command -Module ProcessManager

Write-Host "`nTest Get-ProcessReport:" -ForegroundColor Yellow
Get-ProcessReport -MinMemoryMB 50 -Verbose | Select-Object -First 5 | Format-Table

Write-Host "`nTest Stop-ProcessByMemory (WhatIf):" -ForegroundColor Yellow
Stop-ProcessByMemory -ThresholdMB 5000 -WhatIf

Write-Host "`nTest Get-ProcessTree:" -ForegroundColor Yellow
Get-ProcessTree -Name "pwsh" -Verbose

# Prüfen dass private Funktion nicht exportiert ist
Write-Host "`nPrüfe dass ConvertTo-SizeString privat ist:" -ForegroundColor Yellow
$exported = Get-Command -Module ProcessManager
if ("ConvertTo-SizeString" -notin $exported.Name) {
    Write-Host "  Korrekt! ConvertTo-SizeString ist nicht exportiert." -ForegroundColor Green
}

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ALLE LÖSUNGEN ERFOLGREICH ERSTELLT" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

ERSTELLTE MODULE:
=================

1. NetworkTools (C:\Temp\NetworkTools)
   - Test-PortConnection
   - Get-PublicIPAddress
   - Get-DNSInfo
   - (Private: Format-Timestamp)

2. ProcessManager (C:\Temp\ProcessManager)
   - Get-ProcessReport
   - Stop-ProcessByMemory (mit SupportsShouldProcess)
   - Get-ProcessTree (mit Parameter Sets)
   - (Private: ConvertTo-SizeString)
   - Config: Data\config.json

WICHTIGE LERNPUNKTE:
===================
- Export-ModuleMember kontrolliert was exportiert wird
- Dot-Sourcing (.ps1 Dateien) für modulare Struktur
- Config-Dateien für flexible Konfiguration
- Private Helper-Funktionen für interne Logik
- SupportsShouldProcess für sichere Operationen

"@ -ForegroundColor White

#endregion
