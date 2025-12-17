#############################################################################
# Modul 01: Erweiterte Funktionen - LÖSUNGEN
# PowerShell Expertenkurs - Tag 1
#############################################################################

#region LÖSUNG AUFGABE 1: Get-HighCpuProcess
#############################################################################

<#
.SYNOPSIS
    Zeigt Prozesse mit hoher CPU-Nutzung an.
.DESCRIPTION
    Diese Funktion filtert Prozesse basierend auf ihrer CPU-Zeit
    und zeigt die Top-N Prozesse mit dem höchsten CPU-Verbrauch.
.PARAMETER MinimumCPU
    Minimale CPU-Zeit in Sekunden. Standard: 10
.PARAMETER Top
    Anzahl der anzuzeigenden Prozesse. Standard: 10
.EXAMPLE
    Get-HighCpuProcess -MinimumCPU 5 -Top 5 -Verbose
#>
function Get-HighCpuProcess {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MinimumCPU = 10,
        
        [Parameter(Position = 1)]
        [ValidateRange(1, 100)]
        [int]$Top = 10
    )
    
    Write-Verbose "Suche Prozesse mit CPU-Zeit > $MinimumCPU Sekunden"
    Write-Verbose "Zeige Top $Top Ergebnisse"
    
    $processes = Get-Process | Where-Object { $_.CPU -gt $MinimumCPU }
    
    Write-Verbose "Gefunden: $($processes.Count) Prozesse über dem Schwellwert"
    
    $processes | 
    Sort-Object CPU -Descending | 
    Select-Object -First $Top |
    ForEach-Object {
        [PSCustomObject]@{
            Name         = $_.Name
            Id           = $_.Id
            CPUSeconds   = [math]::Round($_.CPU, 2)
            WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
            StartTime    = $_.StartTime
        }
    }
    
    Write-Verbose "Ausgabe abgeschlossen"
}

# Test der Lösung
Write-Host "=== Test Aufgabe 1 ===" -ForegroundColor Cyan
Get-HighCpuProcess -MinimumCPU 1 -Top 5 -Verbose | Format-Table -AutoSize

#endregion

#region LÖSUNG AUFGABE 2: Get-ServiceHealthReport
#############################################################################

<#
.SYNOPSIS
    Erstellt einen Gesundheitsbericht für Windows Services.
.DESCRIPTION
    Analysiert Services basierend auf Status und StartType
    und ermittelt, ob sie "gesund" sind (Running wenn Automatic).
.PARAMETER ComputerName
    Der Zielcomputer. Standard: Lokaler Computer
.PARAMETER Status
    Filter für Service-Status: Running, Stopped, All
.PARAMETER StartType
    Filter für StartType: Automatic, Manual, Disabled, All
.EXAMPLE
    Get-ServiceHealthReport -Status Running -StartType Automatic -Verbose
#>
function Get-ServiceHealthReport {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Position = 1)]
        [ValidateSet('Running', 'Stopped', 'All')]
        [string]$Status = 'All',
        
        [Parameter(Position = 2)]
        [ValidateSet('Automatic', 'Manual', 'Disabled', 'All')]
        [string]$StartType = 'All'
    )
    
    Write-Verbose "Analysiere Services auf Computer: $ComputerName"
    Write-Verbose "Filter - Status: $Status, StartType: $StartType"
    
    # Services abrufen
    $services = Get-Service
    $originalCount = $services.Count
    Write-Verbose "Gesamtanzahl Services: $originalCount"
    
    # Status-Filter anwenden
    if ($Status -ne 'All') {
        $services = $services | Where-Object Status -eq $Status
        Write-Verbose "Nach Status-Filter: $($services.Count) Services"
    }
    
    # StartType-Filter anwenden
    if ($StartType -ne 'All') {
        $services = $services | Where-Object StartType -eq $StartType
        Write-Verbose "Nach StartType-Filter: $($services.Count) Services"
    }
    
    # Ergebnis-Counter
    $healthyCount = 0
    $unhealthyCount = 0
    
    foreach ($svc in $services) {
        # IsHealthy: True wenn Service läuft bei Automatic StartType
        # oder wenn Service nicht Automatic ist (dann ist Stopped OK)
        $isHealthy = if ($svc.StartType -eq 'Automatic') {
            $svc.Status -eq 'Running'
        }
        else {
            $true  # Non-Automatic Services sind immer "gesund"
        }
        
        if ($isHealthy) { $healthyCount++ } else { $unhealthyCount++ }
        
        [PSCustomObject]@{
            ServiceName = $svc.Name
            DisplayName = $svc.DisplayName
            Status      = $svc.Status
            StartType   = $svc.StartType
            IsHealthy   = $isHealthy
        }
    }
    
    Write-Verbose "Analyse abgeschlossen:"
    Write-Verbose "  - Gesunde Services: $healthyCount"
    Write-Verbose "  - Ungesunde Services: $unhealthyCount"
    Write-Verbose "  - Gesamt: $($services.Count)"
}

# Test der Lösung
Write-Host "`n=== Test Aufgabe 2 ===" -ForegroundColor Cyan
Get-ServiceHealthReport -Status Stopped -StartType Automatic -Verbose | 
Where-Object { -not $_.IsHealthy } | 
Select-Object -First 5 |
Format-Table -AutoSize

#endregion

#region LÖSUNG AUFGABE 3: Get-FolderSizeReport
#############################################################################

<#
.SYNOPSIS
    Analysiert Ordnergrößen in einem angegebenen Pfad.
.DESCRIPTION
    Berechnet die Größe von Ordnern und optional Dateien
    in einem angegebenen Pfad mit konfigurierbarer Tiefe.
.PARAMETER Path
    Der zu analysierende Pfad (Pflichtparameter).
.PARAMETER MinimumSizeMB
    Nur Elemente über dieser Größe anzeigen. Standard: 0
.PARAMETER Depth
    Rekursionstiefe. Standard: 1
.PARAMETER IncludeFiles
    Switch um auch große Einzeldateien anzuzeigen.
.EXAMPLE
    Get-FolderSizeReport -Path "C:\Windows" -Depth 1 -MinimumSizeMB 100 -Verbose
.EXAMPLE
    Get-FolderSizeReport -Path "C:\Users" -IncludeFiles -MinimumSizeMB 50
#>
function Get-FolderSizeReport {
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'ByPath',
            HelpMessage = "Geben Sie den zu analysierenden Pfad an"
        )]
        [ValidateScript({
                if (Test-Path $_) { $true }
                else { throw "Pfad '$_' existiert nicht!" }
            })]
        [string]$Path,
        
        [Parameter(Position = 1)]
        [ValidateRange(0, [int]::MaxValue)]
        [double]$MinimumSizeMB = 0,
        
        [Parameter(Position = 2)]
        [ValidateRange(1, 10)]
        [int]$Depth = 1,
        
        [Parameter()]
        [switch]$IncludeFiles
    )
    
    Write-Verbose "Starte Analyse von: $Path"
    Write-Verbose "Parameter: MinimumSizeMB=$MinimumSizeMB, Depth=$Depth, IncludeFiles=$IncludeFiles"
    
    $results = @()
    
    # Ordner analysieren
    try {
        $folders = Get-ChildItem -Path $Path -Directory -Depth ($Depth - 1) -ErrorAction Stop
        Write-Verbose "Gefundene Ordner: $($folders.Count)"
        
        foreach ($folder in $folders) {
            Write-Verbose "Analysiere Ordner: $($folder.Name)"
            
            try {
                $folderItems = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue
                $folderSize = ($folderItems | Measure-Object -Property Length -Sum).Sum
                $sizeMB = [math]::Round($folderSize / 1MB, 2)
                
                if ($sizeMB -ge $MinimumSizeMB) {
                    $results += [PSCustomObject]@{
                        Name      = $folder.Name
                        FullPath  = $folder.FullName
                        Type      = 'Folder'
                        SizeMB    = $sizeMB
                        ItemCount = $folderItems.Count
                    }
                }
            }
            catch {
                Write-Warning "Zugriffsfehler bei Ordner '$($folder.FullName)': $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Warning "Fehler beim Lesen des Pfads: $($_.Exception.Message)"
    }
    
    # Optional: Dateien analysieren
    if ($IncludeFiles) {
        Write-Verbose "Analysiere auch Dateien..."
        
        try {
            $files = Get-ChildItem -Path $Path -File -Depth ($Depth - 1) -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $sizeMB = [math]::Round($file.Length / 1MB, 2)
                
                if ($sizeMB -ge $MinimumSizeMB) {
                    $results += [PSCustomObject]@{
                        Name      = $file.Name
                        FullPath  = $file.FullName
                        Type      = 'File'
                        SizeMB    = $sizeMB
                        ItemCount = $null
                    }
                }
            }
        }
        catch {
            Write-Warning "Fehler beim Lesen der Dateien: $($_.Exception.Message)"
        }
    }
    
    Write-Verbose "Analyse abgeschlossen. Gefundene Elemente: $($results.Count)"
    
    # Sortiert nach Größe ausgeben
    $results | Sort-Object SizeMB -Descending
}

# Test der Lösung
Write-Host "`n=== Test Aufgabe 3 ===" -ForegroundColor Cyan
Get-FolderSizeReport -Path $env:USERPROFILE -Depth 1 -MinimumSizeMB 10 -Verbose | 
Select-Object -First 10 |
Format-Table -AutoSize

#endregion

#region LÖSUNG BONUSAUFGABE: Parameter Sets
#############################################################################

<#
.SYNOPSIS
    Erweiterte Version mit Parameter Sets.
.DESCRIPTION
    Unterstützt sowohl Pfad- als auch Laufwerksbuchstaben-Eingabe.
.PARAMETER Path
    Der zu analysierende Pfad (ParameterSet: ByPath)
.PARAMETER DriveLetter
    Der Laufwerksbuchstabe (ParameterSet: ByDrive)
.EXAMPLE
    Get-FolderSizeReportAdvanced -Path "C:\Users"
.EXAMPLE
    Get-FolderSizeReportAdvanced -DriveLetter C -Depth 2
#>
function Get-FolderSizeReportAdvanced {
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'ByPath'
        )]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,
        
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'ByDrive'
        )]
        [ValidatePattern('^[A-Z]$')]
        [string]$DriveLetter,
        
        [Parameter(Position = 1)]
        [ValidateRange(0, [int]::MaxValue)]
        [double]$MinimumSizeMB = 0,
        
        [Parameter(Position = 2)]
        [ValidateRange(1, 10)]
        [int]$Depth = 1,
        
        [Parameter()]
        [switch]$IncludeFiles
    )
    
    # Pfad aus ParameterSet ermitteln
    $targetPath = switch ($PSCmdlet.ParameterSetName) {
        'ByPath' { $Path }
        'ByDrive' { "${DriveLetter}:\" }
    }
    
    Write-Verbose "ParameterSet: $($PSCmdlet.ParameterSetName)"
    Write-Verbose "Ziel-Pfad: $targetPath"
    
    # Validieren
    if (-not (Test-Path $targetPath)) {
        Write-Error "Pfad '$targetPath' existiert nicht!"
        return
    }
    
    $results = @()
    
    # Ordner analysieren
    try {
        $folders = Get-ChildItem -Path $targetPath -Directory -Depth ($Depth - 1) -ErrorAction Stop
        Write-Verbose "Gefundene Ordner: $($folders.Count)"
        
        foreach ($folder in $folders) {
            Write-Verbose "Analysiere: $($folder.Name)"
            
            try {
                $folderItems = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue
                $sizeMB = [math]::Round(($folderItems | Measure-Object Length -Sum).Sum / 1MB, 2)
                
                if ($sizeMB -ge $MinimumSizeMB) {
                    $results += [PSCustomObject]@{
                        Name      = $folder.Name
                        FullPath  = $folder.FullName
                        Type      = 'Folder'
                        SizeMB    = $sizeMB
                        ItemCount = $folderItems.Count
                    }
                }
            }
            catch {
                Write-Warning "Zugriffsfehler: $($folder.FullName)"
            }
        }
    }
    catch {
        Write-Warning "Lesefehler: $_"
    }
    
    # Optional: Dateien
    if ($IncludeFiles) {
        $files = Get-ChildItem -Path $targetPath -File -Depth ($Depth - 1) -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            if ($sizeMB -ge $MinimumSizeMB) {
                $results += [PSCustomObject]@{
                    Name      = $file.Name
                    FullPath  = $file.FullName
                    Type      = 'File'
                    SizeMB    = $sizeMB
                    ItemCount = $null
                }
            }
        }
    }
    
    $results | Sort-Object SizeMB -Descending
}

# Test der Bonusaufgabe
Write-Host "`n=== Test Bonusaufgabe ===" -ForegroundColor Cyan
Write-Host "Syntax der Funktion:" -ForegroundColor Yellow
Get-Command Get-FolderSizeReportAdvanced -Syntax

Write-Host "`nTest mit -Path:" -ForegroundColor Yellow
Get-FolderSizeReportAdvanced -Path $env:USERPROFILE -Depth 1 -MinimumSizeMB 50 -Verbose | 
Select-Object -First 3 | Format-Table

Write-Host "Test mit -DriveLetter:" -ForegroundColor Yellow
# Get-FolderSizeReportAdvanced -DriveLetter C -Depth 1 -MinimumSizeMB 1000 -Verbose | 
#     Select-Object -First 3 | Format-Table

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ALLE LÖSUNGEN ERFOLGREICH DEMONSTRIERT" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

WICHTIGE LERNPUNKTE AUS DEN LÖSUNGEN:

1. Aufgabe 1 - Get-HighCpuProcess:
   - Einfache Konvertierung eines Einzeilers
   - ValidateRange für Parameterwerte
   - [math]::Round() für Formatierung

2. Aufgabe 2 - Get-ServiceHealthReport:
   - Berechnete Eigenschaften (IsHealthy)
   - Counter-Logik in Verbose-Ausgaben
   - Filtering mit mehreren Kriterien

3. Aufgabe 3 - Get-FolderSizeReport:
   - ValidateScript für komplexe Validierung
   - Fehlerbehandlung mit try/catch
   - Switch-Parameter für optionale Features

4. Bonusaufgabe - Parameter Sets:
   - Gegenseitig ausschließende Parameter
   - `$PSCmdlet.ParameterSetName` zur Unterscheidung
   - DefaultParameterSetName

"@ -ForegroundColor White

#endregion
