#############################################################################
# Modul 02: Erstellung von Skript-Modulen
# PowerShell Expertenkurs - Tag 1
#############################################################################

<#
LERNZIELE:
- Verstehen was ein PowerShell-Modul ist
- Script Module (.psm1) erstellen
- Module Manifest (.psd1) erstellen
- Funktionen exportieren und verbergen
- Module laden, testen und verteilen

DEMO-DAUER: ca. 45-60 Minuten
#>

#region VORBEREITUNG: Demo-Ordner erstellen
#############################################################################

# Demo-Ordner für unsere Module erstellen
$ModuleDemoPath = Join-Path $env:TEMP "ModuleDemo"
if (-not (Test-Path $ModuleDemoPath)) {
    New-Item -Path $ModuleDemoPath -ItemType Directory -Force | Out-Null
}
Write-Host "Demo-Pfad: $ModuleDemoPath" -ForegroundColor Cyan

#endregion

#region TEIL 1: Was ist ein PowerShell-Modul?
#############################################################################

Write-Host "`n=== TEIL 1: Modul-Grundlagen ===" -ForegroundColor Cyan

# === DEMO 1.1: Module Pfade anzeigen ===
Write-Host "`nModul-Suchpfade:" -ForegroundColor Yellow
$env:PSModulePath -split ';' | ForEach-Object {
    $exists = Test-Path $_
    $color = if ($exists) { 'Green' } else { 'Red' }
    Write-Host "  $_ [Existiert: $exists]" -ForegroundColor $color
}

# === DEMO 1.2: Installierte Module anzeigen ===
Write-Host "`nBeispiele installierter Module:" -ForegroundColor Yellow
Get-Module -ListAvailable | 
    Select-Object Name, Version, ModuleType, Path -First 10 | 
    Format-Table -AutoSize

# === DEMO 1.3: Modul-Typen ===
Write-Host @"

MODUL-TYPEN IN POWERSHELL:
==========================
1. Script Module (.psm1)    - PowerShell-Skriptdateien
2. Binary Module (.dll)     - Kompilierte .NET Assemblies  
3. Manifest Module (.psd1)  - Metadaten-Datei ohne Code
4. Dynamic Module           - Im Speicher erstellt mit New-Module

Wir konzentrieren uns auf Script Module - die häufigste Form.
"@ -ForegroundColor White

#endregion

#region TEIL 2: Ein einfaches Script Module erstellen
#############################################################################

Write-Host "`n=== TEIL 2: Script Module erstellen ===" -ForegroundColor Cyan

# === DEMO 2.1: Modul-Ordner erstellen ===
$SimpleModulePath = Join-Path $ModuleDemoPath "SimpleTools"
New-Item -Path $SimpleModulePath -ItemType Directory -Force | Out-Null

# === DEMO 2.2: .psm1 Datei erstellen ===
$Psm1Content = @'
#############################################################################
# SimpleTools.psm1 - Ein einfaches Demo-Modul
#############################################################################

# Private Hilfsfunktion (wird NICHT exportiert)
function Get-CurrentTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Öffentliche Funktion 1
function Get-SystemUptime {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        LastBootTime = $os.LastBootUpTime
        UptimeDays = [math]::Round($uptime.TotalDays, 2)
        UptimeHours = [math]::Round($uptime.TotalHours, 2)
        Timestamp = Get-CurrentTimestamp  # Nutzt private Funktion
    }
}

# Öffentliche Funktion 2
function Get-MemoryUsage {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMemoryGB = $totalMemoryGB - $freeMemoryGB
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        TotalMemoryGB = $totalMemoryGB
        UsedMemoryGB = $usedMemoryGB
        FreeMemoryGB = $freeMemoryGB
        PercentUsed = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
        Timestamp = Get-CurrentTimestamp
    }
}

# Öffentliche Funktion 3
function Get-DiskUsage {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DriveLetter = 'C'
    )
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${DriveLetter}:'"
    
    if ($disk) {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Drive = $disk.DeviceID
            TotalGB = [math]::Round($disk.Size / 1GB, 2)
            FreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            UsedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
            PercentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
            Timestamp = Get-CurrentTimestamp
        }
    }
}

# Expliziter Export (Best Practice!)
Export-ModuleMember -Function Get-SystemUptime, Get-MemoryUsage, Get-DiskUsage
'@

$Psm1Path = Join-Path $SimpleModulePath "SimpleTools.psm1"
$Psm1Content | Out-File -FilePath $Psm1Path -Encoding UTF8
Write-Host "Modul erstellt: $Psm1Path" -ForegroundColor Green

# === DEMO 2.3: Modul laden und testen ===
Write-Host "`nModul laden und testen:" -ForegroundColor Yellow

# Altes Modul entfernen falls geladen
Remove-Module SimpleTools -ErrorAction SilentlyContinue

# Modul importieren
Import-Module $Psm1Path -Verbose

# Prüfen welche Funktionen exportiert wurden
Write-Host "`nExportierte Funktionen:" -ForegroundColor Yellow
Get-Command -Module SimpleTools

# Private Funktion ist NICHT verfügbar
Write-Host "`nTest: Private Funktion aufrufen (sollte Fehler geben):" -ForegroundColor Yellow
try {
    Get-CurrentTimestamp
} catch {
    Write-Host "  Erwarteter Fehler: Die Funktion ist privat!" -ForegroundColor Red
}

# Öffentliche Funktionen testen
Write-Host "`nTest: Öffentliche Funktionen:" -ForegroundColor Yellow
Get-SystemUptime
Get-MemoryUsage
Get-DiskUsage -DriveLetter C

#endregion

#region TEIL 3: Module Manifest erstellen
#############################################################################

Write-Host "`n=== TEIL 3: Module Manifest (.psd1) ===" -ForegroundColor Cyan

# === DEMO 3.1: Manifest mit New-ModuleManifest erstellen ===

$ManifestPath = Join-Path $SimpleModulePath "SimpleTools.psd1"

$ManifestParams = @{
    Path              = $ManifestPath
    RootModule        = 'SimpleTools.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = (New-Guid).Guid
    Author            = 'PowerShell Trainer'
    CompanyName       = 'Training Company'
    Copyright         = "(c) $(Get-Date -Format yyyy). All rights reserved."
    Description       = 'Ein Demo-Modul mit System-Informations-Tools'
    PowerShellVersion = '5.1'
    
    # Explizit exportierte Funktionen
    FunctionsToExport = @(
        'Get-SystemUptime',
        'Get-MemoryUsage', 
        'Get-DiskUsage'
    )
    
    # Keine Cmdlets, Variablen oder Aliase exportieren
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    
    # Tags für PowerShell Gallery
    Tags              = @('System', 'Monitoring', 'Tools')
    
    # Projekt-Links
    ProjectUri        = 'https://github.com/example/SimpleTools'
}

New-ModuleManifest @ManifestParams
Write-Host "Manifest erstellt: $ManifestPath" -ForegroundColor Green

# === DEMO 3.2: Manifest anzeigen ===
Write-Host "`nManifest-Inhalt (Auszug):" -ForegroundColor Yellow
Get-Content $ManifestPath | Select-Object -First 50

# === DEMO 3.3: Manifest testen ===
Write-Host "`nManifest validieren:" -ForegroundColor Yellow
Test-ModuleManifest -Path $ManifestPath

#endregion

#region TEIL 4: Fortgeschrittenes Modul mit mehreren Dateien
#############################################################################

Write-Host "`n=== TEIL 4: Fortgeschrittenes Modul ===" -ForegroundColor Cyan

# === DEMO 4.1: Modul-Struktur erstellen ===
$AdvancedModulePath = Join-Path $ModuleDemoPath "ServerTools"

# Ordnerstruktur
@(
    "$AdvancedModulePath\Public"
    "$AdvancedModulePath\Private"
    "$AdvancedModulePath\Classes"
    "$AdvancedModulePath\Data"
) | ForEach-Object {
    New-Item -Path $_ -ItemType Directory -Force | Out-Null
}

Write-Host "Modul-Struktur:" -ForegroundColor Yellow
Get-ChildItem $AdvancedModulePath -Recurse | 
    Select-Object FullName | 
    ForEach-Object { Write-Host "  $($_.FullName)" }

# === DEMO 4.2: Private Funktionen ===
$PrivateFunction = @'
# Private Helper-Funktion
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info'    { Write-Verbose $logEntry }
        'Warning' { Write-Warning $logEntry }
        'Error'   { Write-Error $logEntry }
    }
}
'@
$PrivateFunction | Out-File "$AdvancedModulePath\Private\Write-LogMessage.ps1" -Encoding UTF8

# === DEMO 4.3: Public Funktionen ===
$PublicFunction1 = @'
function Get-ServerHealth {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    process {
        Write-LogMessage "Prüfe Server: $ComputerName" -Level Info
        
        try {
            $cpu = (Get-CimInstance Win32_Processor -ComputerName $ComputerName).LoadPercentage
            $os = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName
            $memUsed = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
            
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Status = 'Online'
                CPUPercent = $cpu
                MemoryPercent = $memUsed
                LastBootTime = $os.LastBootUpTime
                CheckTime = Get-Date
            }
        }
        catch {
            Write-LogMessage "Fehler bei $ComputerName : $_" -Level Warning
            
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Status = 'Offline'
                CPUPercent = $null
                MemoryPercent = $null
                LastBootTime = $null
                CheckTime = Get-Date
            }
        }
    }
}
'@
$PublicFunction1 | Out-File "$AdvancedModulePath\Public\Get-ServerHealth.ps1" -Encoding UTF8

$PublicFunction2 = @'
function Test-ServerConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$ComputerName,
        
        [Parameter()]
        [int]$Port = 5985,
        
        [Parameter()]
        [int]$TimeoutSeconds = 5
    )
    
    process {
        foreach ($computer in $ComputerName) {
            Write-LogMessage "Teste Verbindung zu $computer auf Port $Port" -Level Info
            
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            
            try {
                $asyncResult = $tcpClient.BeginConnect($computer, $Port, $null, $null)
                $wait = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000, $false)
                
                [PSCustomObject]@{
                    ComputerName = $computer
                    Port = $Port
                    Connected = $wait
                    ResponseTime = if ($wait) { 'OK' } else { 'Timeout' }
                }
            }
            catch {
                Write-LogMessage "Verbindungsfehler: $_" -Level Warning
                
                [PSCustomObject]@{
                    ComputerName = $computer
                    Port = $Port
                    Connected = $false
                    ResponseTime = 'Error'
                }
            }
            finally {
                $tcpClient.Close()
            }
        }
    }
}
'@
$PublicFunction2 | Out-File "$AdvancedModulePath\Public\Test-ServerConnectivity.ps1" -Encoding UTF8

# === DEMO 4.4: Haupt-.psm1 Datei (Dot-Sourcing) ===
$MainPsm1 = @'
#############################################################################
# ServerTools.psm1 - Fortgeschrittenes Modul mit Dot-Sourcing
#############################################################################

# Modul-Variablen
$script:ModuleName = 'ServerTools'
$script:ModuleVersion = '1.0.0'

# Alle .ps1 Dateien in Private und Public laden
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)

# Dot-Sourcing aller Funktionen
foreach ($import in @($Private + $Public)) {
    try {
        Write-Verbose "Lade: $($import.FullName)"
        . $import.FullName
    }
    catch {
        Write-Error "Fehler beim Laden von $($import.FullName): $_"
    }
}

# Nur Public Funktionen exportieren
Export-ModuleMember -Function $Public.BaseName
'@
$MainPsm1 | Out-File "$AdvancedModulePath\ServerTools.psm1" -Encoding UTF8

# === DEMO 4.5: Manifest für fortgeschrittenes Modul ===
$AdvManifestPath = "$AdvancedModulePath\ServerTools.psd1"

New-ModuleManifest -Path $AdvManifestPath `
    -RootModule 'ServerTools.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'PowerShell Trainer' `
    -Description 'Server-Monitoring und Verwaltungs-Tools' `
    -PowerShellVersion '5.1' `
    -FunctionsToExport @('Get-ServerHealth', 'Test-ServerConnectivity') `
    -CmdletsToExport @() `
    -AliasesToExport @()

Write-Host "Fortgeschrittenes Modul erstellt!" -ForegroundColor Green

# === DEMO 4.6: Modul laden und testen ===
Remove-Module ServerTools -ErrorAction SilentlyContinue
Import-Module $AdvancedModulePath -Verbose

Write-Host "`nExportierte Funktionen:" -ForegroundColor Yellow
Get-Command -Module ServerTools

Write-Host "`nTest Get-ServerHealth:" -ForegroundColor Yellow
Get-ServerHealth -Verbose

#endregion

#region TEIL 5: Module installieren und verteilen
#############################################################################

Write-Host "`n=== TEIL 5: Module installieren ===" -ForegroundColor Cyan

# === DEMO 5.1: Modul in PSModulePath installieren ===
Write-Host "Mögliche Installationspfade:" -ForegroundColor Yellow

$userModulePath = Join-Path $HOME "Documents\PowerShell\Modules"
$systemModulePath = "$env:ProgramFiles\PowerShell\Modules"

Write-Host "  User-Pfad:   $userModulePath" -ForegroundColor White
Write-Host "  System-Pfad: $systemModulePath (erfordert Admin)" -ForegroundColor White

# Modul in User-Pfad kopieren (Demo)
$targetPath = Join-Path $userModulePath "ServerTools"
Write-Host "`nInstallationsziel wäre: $targetPath" -ForegroundColor Yellow

# Eigentlicher Kopierbefehl (auskommentiert für Demo):
# Copy-Item -Path $AdvancedModulePath -Destination $targetPath -Recurse -Force

Write-Host @"

INSTALLATIONS-METHODEN:
=======================
1. Manuell kopieren in PSModulePath
2. Install-Module aus PowerShell Gallery
3. Unternehmensinterne Repository (NuGet)
4. Copy-Item über Netzwerk-Share

"@ -ForegroundColor White

# === DEMO 5.2: Modul für PowerShell Gallery vorbereiten ===
Write-Host "Für PowerShell Gallery benötigt:" -ForegroundColor Yellow
Write-Host @"
  - Gültige .psd1 Manifest-Datei
  - Unique GUID
  - Version nach Semantic Versioning
  - LicenseUri und ProjectUri (empfohlen)
  - Tags für Suchbarkeit
  - README.md (empfohlen)
  - API-Key von PowerShellGallery.com

  # Publish-Module -Path $AdvancedModulePath -NuGetApiKey "xxx"
"@

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 02" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. MODUL-DATEIEN:
   - .psm1 = Script Module (Code)
   - .psd1 = Manifest (Metadaten)

2. MODUL-STRUKTUR (Best Practice):
   ModuleName/
   ├── ModuleName.psd1
   ├── ModuleName.psm1
   ├── Public/       (Exportierte Funktionen)
   ├── Private/      (Interne Helper)
   └── Classes/      (PowerShell Klassen)

3. EXPORT-KONTROLLE:
   - Export-ModuleMember im .psm1
   - FunctionsToExport im .psd1 (überschreibt!)
   - Nicht exportierte Funktionen = Private

4. DOT-SOURCING PATTERN:
   `$Public = Get-ChildItem -Path `$PSScriptRoot\Public\*.ps1
   foreach (`$file in `$Public) { . `$file.FullName }
   Export-ModuleMember -Function `$Public.BaseName

5. MANIFEST ERSTELLEN:
   New-ModuleManifest -Path "Module.psd1" -RootModule "Module.psm1"
   Test-ModuleManifest -Path "Module.psd1"

DEMO-DATEIEN ERSTELLT IN:
$ModuleDemoPath

"@ -ForegroundColor White

#endregion
