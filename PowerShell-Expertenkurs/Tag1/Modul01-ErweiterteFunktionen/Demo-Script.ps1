#############################################################################
# Modul 01: Erweiterte Funktionen - Grundlagen
# PowerShell Expertenkurs - Tag 1
#############################################################################

<#
LERNZIELE:
- Unterschied zwischen einfachen und erweiterten Funktionen verstehen
- Befehle in erweiterte Funktionen konvertieren
- CmdletBinding-Attribut verstehen und nutzen
- Common Parameters nutzen

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Einfache Funktion vs. Erweiterte Funktion
#############################################################################

# === DEMO 1.1: Eine einfache Funktion ===
Write-Host "`n=== DEMO 1.1: Einfache Funktion ===" -ForegroundColor Cyan

function Get-SimpleServiceInfo {
    param(
        $ServiceName
    )
    
    $service = Get-Service -Name $ServiceName
    Write-Output "Service: $($service.Name) - Status: $($service.Status)"
}

# Testen der einfachen Funktion
Get-SimpleServiceInfo -ServiceName "Spooler"

# Problem: Keine Common Parameters verfügbar
# Get-SimpleServiceInfo -ServiceName "Spooler" -Verbose  # Funktioniert, aber -Verbose wird ignoriert


# === DEMO 1.2: Dieselbe Funktion als erweiterte Funktion ===
Write-Host "`n=== DEMO 1.2: Erweiterte Funktion ===" -ForegroundColor Cyan

function Get-AdvancedServiceInfo {
    [CmdletBinding()]  # DAS macht den Unterschied!
    param(
        [Parameter()]
        [string]$ServiceName
    )
    
    Write-Verbose "Suche Service: $ServiceName"
    $service = Get-Service -Name $ServiceName
    Write-Verbose "Service gefunden: $($service.DisplayName)"
    
    Write-Output "Service: $($service.Name) - Status: $($service.Status)"
}

# Testen mit -Verbose
Get-AdvancedServiceInfo -ServiceName "Spooler" -Verbose

# Zeigen: Welche Common Parameters sind jetzt verfügbar?
Write-Host "`nVerfügbare Parameter für einfache Funktion:" -ForegroundColor Yellow
(Get-Command Get-SimpleServiceInfo).Parameters.Keys

Write-Host "`nVerfügbare Parameter für erweiterte Funktion:" -ForegroundColor Yellow
(Get-Command Get-AdvancedServiceInfo).Parameters.Keys

#endregion

#region TEIL 2: CmdletBinding im Detail
#############################################################################

Write-Host "`n=== TEIL 2: CmdletBinding Optionen ===" -ForegroundColor Cyan

# === DEMO 2.1: CmdletBinding mit allen wichtigen Optionen ===

function Get-ProcessMemory {
    [CmdletBinding(
        SupportsShouldProcess = $true,      # Aktiviert -WhatIf und -Confirm
        ConfirmImpact = 'Medium',            # Low, Medium, High
        DefaultParameterSetName = 'ByName'   # Standard-Parameterset
    )]
    param(
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name = '*',
        
        [Parameter(ParameterSetName = 'ById')]
        [int]$Id
    )
    
    Write-Verbose "ParameterSetName: $($PSCmdlet.ParameterSetName)"
    
    switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            Get-Process -Name $Name | Select-Object Name, Id, 
            @{N = 'MemoryMB'; E = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
        }
        'ById' {
            Get-Process -Id $Id | Select-Object Name, Id,
            @{N = 'MemoryMB'; E = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
        }
    }
}

# Testen
Get-ProcessMemory -Name "pwsh" -Verbose
Get-ProcessMemory -Id $PID -Verbose


# === DEMO 2.2: $PSCmdlet Automatic Variable ===
Write-Host "`n=== DEMO 2.2: `$PSCmdlet Variable ===" -ForegroundColor Cyan

function Show-PSCmdletInfo {
    [CmdletBinding()]
    param()
    
    Write-Host "MyInvocation.MyCommand: $($PSCmdlet.MyInvocation.MyCommand)" -ForegroundColor Green
    Write-Host "CommandRuntime Type: $($PSCmdlet.CommandRuntime.GetType().Name)" -ForegroundColor Green
    Write-Host "ParameterSetName: $($PSCmdlet.ParameterSetName)" -ForegroundColor Green
    
    # Wichtige Methoden von $PSCmdlet:
    # - $PSCmdlet.ShouldProcess()
    # - $PSCmdlet.ShouldContinue()
    # - $PSCmdlet.ThrowTerminatingError()
    # - $PSCmdlet.WriteError()
    # - $PSCmdlet.WriteVerbose()
}

Show-PSCmdletInfo

#endregion

#region TEIL 3: Konvertierung eines Befehls in eine erweiterte Funktion
#############################################################################

Write-Host "`n=== TEIL 3: Befehl zu Funktion konvertieren ===" -ForegroundColor Cyan

# === DEMO 3.1: Ausgangspunkt - Ein komplexer Einzeiler ===

# Dieser Befehl zeigt alle gestoppten Services mit ihren Abhängigkeiten
# Get-Service | Where-Object Status -eq 'Stopped' | ForEach-Object {
#     [PSCustomObject]@{
#         Name = $_.Name
#         DisplayName = $_.DisplayName
#         Status = $_.Status
#         DependentServices = ($_.DependentServices.Name -join ', ')
#     }
# }


# === DEMO 3.2: Schritt-für-Schritt Konvertierung ===

# SCHRITT 1: Grundgerüst mit CmdletBinding
function Get-StoppedServiceDependency {
    [CmdletBinding()]
    param()
    
    Get-Service | Where-Object Status -eq 'Stopped' | ForEach-Object {
        [PSCustomObject]@{
            Name              = $_.Name
            DisplayName       = $_.DisplayName
            Status            = $_.Status
            DependentServices = ($_.DependentServices.Name -join ', ')
        }
    }
}

# SCHRITT 2: Parameter hinzufügen für Flexibilität
function Get-ServiceDependencyInfo {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Running', 'Stopped', 'All')]
        [string]$Status = 'All',
        
        [Parameter()]
        [string]$Name = '*'
    )
    
    Write-Verbose "Filter: Status=$Status, Name=$Name"
    
    $services = Get-Service -Name $Name -ErrorAction SilentlyContinue
    
    if ($Status -ne 'All') {
        $services = $services | Where-Object Status -eq $Status
    }
    
    foreach ($svc in $services) {
        Write-Verbose "Verarbeite Service: $($svc.Name)"
        
        [PSCustomObject]@{
            Name              = $svc.Name
            DisplayName       = $svc.DisplayName
            Status            = $svc.Status
            StartType         = $svc.StartType
            DependentServices = ($svc.DependentServices.Name -join ', ')
            RequiredServices  = ($svc.ServicesDependedOn.Name -join ', ')
        }
    }
}

# Testen
Get-ServiceDependencyInfo -Status Stopped -Verbose | Select-Object -First 5
Get-ServiceDependencyInfo -Name "Spooler" -Verbose

#endregion

#region TEIL 4: Best Practices für erweiterte Funktionen
#############################################################################

Write-Host "`n=== TEIL 4: Best Practices ===" -ForegroundColor Cyan

# === DEMO 4.1: Vollständige erweiterte Funktion mit Best Practices ===

function Get-DiskSpaceReport {
    <#
    .SYNOPSIS
        Erstellt einen Festplatten-Speicherplatz-Report.
    .DESCRIPTION
        Diese Funktion sammelt Informationen über verfügbaren Speicherplatz
        auf lokalen oder Remote-Computern.
    .PARAMETER ComputerName
        Der Name des Computers. Standard ist der lokale Computer.
    .PARAMETER DriveType
        Der Laufwerkstyp (Fixed, Removable, Network).
    .EXAMPLE
        Get-DiskSpaceReport -ComputerName "Server01"
    .EXAMPLE
        Get-DiskSpaceReport -DriveType Fixed
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('CN', 'Server')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Position = 1)]
        [ValidateSet('Fixed', 'Removable', 'Network', 'All')]
        [string]$DriveType = 'Fixed'
    )
    
    begin {
        Write-Verbose "Starte Disk Space Report"
        Write-Verbose "DriveType Filter: $DriveType"
        
        $driveTypeMap = @{
            'Fixed'     = 3
            'Removable' = 2
            'Network'   = 4
        }
    }
    
    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Verarbeite Computer: $computer"
            
            try {
                $filter = if ($DriveType -eq 'All') {
                    "DriveType=2 OR DriveType=3 OR DriveType=4"
                }
                else {
                    "DriveType=$($driveTypeMap[$DriveType])"
                }
                
                $disks = Get-CimInstance -ClassName Win32_LogicalDisk `
                    -ComputerName $computer `
                    -Filter $filter `
                    -ErrorAction Stop
                
                foreach ($disk in $disks) {
                    [PSCustomObject]@{
                        PSTypeName   = 'DiskSpaceReport'
                        ComputerName = $computer
                        Drive        = $disk.DeviceID
                        VolumeName   = $disk.VolumeName
                        SizeGB       = [math]::Round($disk.Size / 1GB, 2)
                        FreeSpaceGB  = [math]::Round($disk.FreeSpace / 1GB, 2)
                        UsedSpaceGB  = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                        PercentFree  = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                    }
                }
            }
            catch {
                Write-Warning "Fehler bei Computer '$computer': $_"
            }
        }
    }
    
    end {
        Write-Verbose "Disk Space Report abgeschlossen"
    }
}

# Testen der Funktion
Get-DiskSpaceReport -Verbose
Get-DiskSpaceReport -DriveType All | Format-Table -AutoSize

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 01" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. [CmdletBinding()] macht aus einer einfachen Funktion eine erweiterte Funktion
   - Aktiviert Common Parameters (-Verbose, -Debug, -ErrorAction, etc.)
   - Ermöglicht Zugriff auf `$PSCmdlet

2. Wichtige CmdletBinding-Optionen:
   - SupportsShouldProcess = Aktiviert -WhatIf/-Confirm
   - DefaultParameterSetName = Standard-Parameterset
   - ConfirmImpact = Wann automatisch bestätigen

3. Best Practices:
   - Immer [CmdletBinding()] verwenden
   - Write-Verbose für Debug-Ausgaben nutzen
   - Parameter typisieren
   - Comment-Based Help schreiben
   - [OutputType()] angeben

4. Konvertierungsschritte:
   a) [CmdletBinding()] hinzufügen
   b) param() Block erstellen
   c) Hardcodierte Werte durch Parameter ersetzen
   d) Write-Verbose für Logging hinzufügen
   e) Fehlerbehandlung einbauen

"@ -ForegroundColor White

#endregion
