#############################################################################
# Modul 04: Multiple Objects und Pipeline Input
# PowerShell Expertenkurs - Tag 1
#############################################################################

<#
LERNZIELE:
- Funktionen für Multiple Objects entwickeln
- Pipeline-Input korrekt verarbeiten
- Begin/Process/End-Blöcke verstehen und nutzen
- ValueFromPipeline vs ValueFromPipelineByPropertyName
- Streaming vs. Collecting

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Grundlagen - Multiple Objects verarbeiten
#############################################################################

Write-Host "=== TEIL 1: Multiple Objects verarbeiten ===" -ForegroundColor Cyan

# === DEMO 1.1: Problem mit einfacher Funktion ===

function Get-ServiceStatus-Simple {
    param(
        [string[]]$ServiceName
    )
    
    # PROBLEM: Gibt nur EIN Ergebnis zurück!
    Get-Service -Name $ServiceName | Select-Object Name, Status
}

Write-Host "`nEinfache Funktion - gibt Array zurück:" -ForegroundColor Yellow
Get-ServiceStatus-Simple -ServiceName "Spooler", "WinRM", "W32Time" | Format-Table


# === DEMO 1.2: Korrekte Verarbeitung mit foreach ===

function Get-ServiceStatus-Loop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceName
    )
    
    foreach ($name in $ServiceName) {
        Write-Verbose "Verarbeite: $name"
        
        try {
            $service = Get-Service -Name $name -ErrorAction Stop
            
            [PSCustomObject]@{
                Name = $service.Name
                DisplayName = $service.DisplayName
                Status = $service.Status
                StartType = $service.StartType
            }
        }
        catch {
            Write-Warning "Service '$name' nicht gefunden: $_"
        }
    }
}

Write-Host "`nMit foreach-Schleife:" -ForegroundColor Yellow
Get-ServiceStatus-Loop -ServiceName "Spooler", "WinRM", "NichtExistent" -Verbose | Format-Table

#endregion

#region TEIL 2: Pipeline Input - ValueFromPipeline
#############################################################################

Write-Host "`n=== TEIL 2: Pipeline Input ===" -ForegroundColor Cyan

# === DEMO 2.1: ValueFromPipeline - Das ganze Objekt ===

function Get-ProcessMemory-Pipeline {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true  # Akzeptiert komplettes Pipeline-Objekt
        )]
        [System.Diagnostics.Process]$Process
    )
    
    # ACHTUNG: Ohne process{} Block wird nur das LETZTE Objekt verarbeitet!
    process {
        Write-Verbose "Verarbeite Prozess: $($Process.Name)"
        
        [PSCustomObject]@{
            Name = $Process.Name
            Id = $Process.Id
            MemoryMB = [math]::Round($Process.WorkingSet64 / 1MB, 2)
            CPU = [math]::Round($Process.CPU, 2)
        }
    }
}

Write-Host "Pipeline mit kompletten Objekten:" -ForegroundColor Yellow
Get-Process | Where-Object CPU -gt 10 | 
    Get-ProcessMemory-Pipeline -Verbose | 
    Sort-Object MemoryMB -Descending |
    Select-Object -First 5 |
    Format-Table


# === DEMO 2.2: ValueFromPipelineByPropertyName - Einzelne Eigenschaften ===

function Get-ServiceByName-Pipeline {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName = $true  # Sucht Property "Name"
        )]
        [Alias('ServiceName')]  # Erlaubt auch Property "ServiceName"
        [string]$Name
    )
    
    process {
        Write-Verbose "Suche Service: $Name"
        
        try {
            $svc = Get-Service -Name $Name -ErrorAction Stop
            
            [PSCustomObject]@{
                ServiceName = $svc.Name
                DisplayName = $svc.DisplayName
                Status = $svc.Status
            }
        }
        catch {
            Write-Warning "Service nicht gefunden: $Name"
        }
    }
}

Write-Host "`nPipeline mit PropertyName:" -ForegroundColor Yellow

# Methode 1: Array von Strings
"Spooler", "WinRM" | Get-ServiceByName-Pipeline -Verbose | Format-Table

# Methode 2: Objekte mit Name-Property
@(
    [PSCustomObject]@{ Name = "Spooler" }
    [PSCustomObject]@{ ServiceName = "WinRM" }  # Funktioniert dank Alias
) | Get-ServiceByName-Pipeline | Format-Table


# === DEMO 2.3: Beide Methoden kombinieren ===

function Get-DetailedServiceInfo {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('ServiceName', 'Service')]
        [string[]]$Name
    )
    
    process {
        foreach ($serviceName in $Name) {
            Write-Verbose "Verarbeite: $serviceName"
            
            try {
                $svc = Get-Service -Name $serviceName -ErrorAction Stop
                
                [PSCustomObject]@{
                    Name = $svc.Name
                    DisplayName = $svc.DisplayName
                    Status = $svc.Status
                    StartType = $svc.StartType
                    DependsOn = ($svc.ServicesDependedOn.Name -join ', ')
                }
            }
            catch {
                Write-Warning "Service '$serviceName' nicht gefunden"
            }
        }
    }
}

Write-Host "`nKombinierte Pipeline-Unterstützung:" -ForegroundColor Yellow
# Als Parameter
Get-DetailedServiceInfo -Name "Spooler", "WinRM" | Format-Table
# Als Pipeline
"Spooler" | Get-DetailedServiceInfo | Format-Table
# Als Pipeline mit Objekten
Get-Service "Sp*" | Get-DetailedServiceInfo | Format-Table

#endregion

#region TEIL 3: Begin/Process/End Blöcke
#############################################################################

Write-Host "`n=== TEIL 3: Begin/Process/End Blöcke ===" -ForegroundColor Cyan

# === DEMO 3.1: Die drei Blöcke verstehen ===

function Show-PipelineBlocks {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [int]$Number
    )
    
    begin {
        Write-Host "BEGIN: Wird EINMAL am Anfang ausgeführt" -ForegroundColor Cyan
        $sum = 0
        $count = 0
    }
    
    process {
        Write-Host "PROCESS: Verarbeite $Number" -ForegroundColor Yellow
        $sum += $Number
        $count++
    }
    
    end {
        Write-Host "END: Wird EINMAL am Ende ausgeführt" -ForegroundColor Green
        Write-Host "Summe: $sum, Anzahl: $count, Durchschnitt: $($sum / $count)"
    }
}

Write-Host "Demo der Pipeline-Blöcke:" -ForegroundColor White
1..5 | Show-PipelineBlocks


# === DEMO 3.2: Praktisches Beispiel - Statistiken sammeln ===

function Get-ProcessStatistics {
    <#
    .SYNOPSIS
        Sammelt Statistiken über Prozesse und gibt Zusammenfassung aus.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Diagnostics.Process]$Process
    )
    
    begin {
        Write-Verbose "Initialisiere Statistik-Sammlung..."
        $statistics = @{
            TotalProcesses = 0
            TotalMemoryMB = 0
            TotalCPU = 0
            MaxMemoryProcess = $null
            MaxMemoryMB = 0
        }
    }
    
    process {
        $statistics.TotalProcesses++
        $memoryMB = $Process.WorkingSet64 / 1MB
        $statistics.TotalMemoryMB += $memoryMB
        $statistics.TotalCPU += $Process.CPU
        
        if ($memoryMB -gt $statistics.MaxMemoryMB) {
            $statistics.MaxMemoryMB = $memoryMB
            $statistics.MaxMemoryProcess = $Process.Name
        }
        
        # Auch einzelne Objekte ausgeben (Streaming)
        [PSCustomObject]@{
            Name = $Process.Name
            MemoryMB = [math]::Round($memoryMB, 2)
            CPU = [math]::Round($Process.CPU, 2)
        }
    }
    
    end {
        Write-Verbose "Erstelle Zusammenfassung..."
        
        # Am Ende die Statistik ausgeben
        Write-Host "`n=== Zusammenfassung ===" -ForegroundColor Cyan
        Write-Host "Verarbeitete Prozesse: $($statistics.TotalProcesses)"
        Write-Host "Gesamter Speicher: $([math]::Round($statistics.TotalMemoryMB, 0)) MB"
        Write-Host "Durchschnitt pro Prozess: $([math]::Round($statistics.TotalMemoryMB / $statistics.TotalProcesses, 0)) MB"
        Write-Host "Größter Prozess: $($statistics.MaxMemoryProcess) ($([math]::Round($statistics.MaxMemoryMB, 0)) MB)"
    }
}

Write-Host "`nProzess-Statistiken:" -ForegroundColor Yellow
Get-Process | Where-Object CPU -gt 5 | Get-ProcessStatistics | Format-Table

#endregion

#region TEIL 4: Streaming vs. Collecting
#############################################################################

Write-Host "`n=== TEIL 4: Streaming vs. Collecting ===" -ForegroundColor Cyan

# === DEMO 4.1: Streaming - Objekte sofort ausgeben ===

function Get-LargeDataset-Streaming {
    <#
    .SYNOPSIS
        Gibt Objekte per Streaming aus (speichereffizient).
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [int]$Number
    )
    
    process {
        # Jedes Objekt wird SOFORT ausgegeben
        # Pipeline-Nachfolger erhält es direkt
        [PSCustomObject]@{
            Original = $Number
            Squared = $Number * $Number
            Timestamp = Get-Date
        }
    }
}

Write-Host "Streaming-Ausgabe (Objekte erscheinen sofort):" -ForegroundColor Yellow
1..5 | Get-LargeDataset-Streaming | ForEach-Object {
    Write-Host "Empfangen: $($_.Original) -> $($_.Squared)"
    Start-Sleep -Milliseconds 200
}


# === DEMO 4.2: Collecting - Erst sammeln, dann ausgeben ===

function Get-LargeDataset-Collecting {
    <#
    .SYNOPSIS
        Sammelt alle Objekte und gibt sie am Ende aus.
    .DESCRIPTION
        ACHTUNG: Kann bei großen Datenmengen viel Speicher verbrauchen!
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [int]$Number
    )
    
    begin {
        $results = [System.Collections.ArrayList]::new()
    }
    
    process {
        # Objekte werden gesammelt, NICHT ausgegeben
        $null = $results.Add([PSCustomObject]@{
            Original = $Number
            Squared = $Number * $Number
            Timestamp = Get-Date
        })
    }
    
    end {
        # Erst hier kommt die Ausgabe
        Write-Verbose "Gesammelte Objekte: $($results.Count)"
        
        # Sortieren oder anders verarbeiten möglich
        $results | Sort-Object Squared -Descending
    }
}

Write-Host "`nCollecting-Ausgabe (alles am Ende):" -ForegroundColor Yellow
1..5 | Get-LargeDataset-Collecting -Verbose | ForEach-Object {
    Write-Host "Empfangen: $($_.Original) -> $($_.Squared)"
}


# === DEMO 4.3: Wann welchen Ansatz verwenden? ===

Write-Host @"

STREAMING vs. COLLECTING:

STREAMING (Empfohlen für große Datenmengen):
- Geringer Speicherverbrauch
- Ergebnisse erscheinen sofort
- Pipeline kann unterbrochen werden (Select-Object -First)
- Ideal für: Logs, große Dateien, Netzwerk-Streams

COLLECTING (Für Nachbearbeitung):
- Alle Daten im Speicher
- Sortierung/Aggregation möglich
- Ergebnisse erst am Ende
- Ideal für: Statistiken, Berichte, kleine Datenmengen

"@ -ForegroundColor White

#endregion

#region TEIL 5: Fortgeschrittene Pipeline-Techniken
#############################################################################

Write-Host "=== TEIL 5: Fortgeschrittene Techniken ===" -ForegroundColor Cyan

# === DEMO 5.1: Pipeline mit mehreren Input-Parametern ===

function Compare-ServiceStatus {
    <#
    .SYNOPSIS
        Vergleicht Service-Status zwischen zwei Computern.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('ServiceName')]
        [string]$Name,
        
        # Diese Parameter kommen NICHT aus der Pipeline
        [Parameter()]
        [string]$ReferenceComputer = $env:COMPUTERNAME,
        
        [Parameter()]
        [string]$DifferenceComputer = $env:COMPUTERNAME
    )
    
    begin {
        Write-Verbose "Vergleiche: $ReferenceComputer vs $DifferenceComputer"
    }
    
    process {
        Write-Verbose "Prüfe Service: $Name"
        
        try {
            $refService = Get-Service -Name $Name -ErrorAction Stop
            $diffService = Get-Service -Name $Name -ErrorAction Stop
            
            [PSCustomObject]@{
                ServiceName = $Name
                ReferenceStatus = $refService.Status
                DifferenceStatus = $diffService.Status
                StatusMatch = $refService.Status -eq $diffService.Status
            }
        }
        catch {
            Write-Warning "Fehler bei Service '$Name': $_"
        }
    }
}

Write-Host "Service-Vergleich per Pipeline:" -ForegroundColor Yellow
"Spooler", "WinRM", "W32Time" | Compare-ServiceStatus -Verbose | Format-Table


# === DEMO 5.2: Abbrechen der Pipeline ===

function Get-FirstMatchingProcess {
    <#
    .SYNOPSIS
        Findet den ersten Prozess der ein Kriterium erfüllt.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Diagnostics.Process]$Process,
        
        [Parameter(Mandatory)]
        [int]$MinMemoryMB
    )
    
    begin {
        $found = $false
    }
    
    process {
        if ($found) { return }  # Weitere Objekte ignorieren
        
        $memoryMB = $Process.WorkingSet64 / 1MB
        
        if ($memoryMB -ge $MinMemoryMB) {
            Write-Verbose "Gefunden: $($Process.Name) mit $([math]::Round($memoryMB, 0)) MB"
            
            [PSCustomObject]@{
                Name = $Process.Name
                Id = $Process.Id
                MemoryMB = [math]::Round($memoryMB, 2)
            }
            
            $found = $true
        }
    }
}

Write-Host "`nErsten passenden Prozess finden:" -ForegroundColor Yellow
Get-Process | Get-FirstMatchingProcess -MinMemoryMB 100 -Verbose


# === DEMO 5.3: Komplexes Beispiel - Multi-Computer Pipeline ===

function Test-ServiceHealth {
    <#
    .SYNOPSIS
        Prüft die Gesundheit eines Services auf mehreren Computern.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('CN', 'Server', 'ComputerName')]
        [string]$Computer,
        
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ServiceName,
        
        [Parameter()]
        [switch]$IncludeHealthScore
    )
    
    begin {
        Write-Verbose "Prüfe Services: $($ServiceName -join ', ')"
        $allResults = @()
    }
    
    process {
        Write-Verbose "Verbinde zu: $Computer"
        
        foreach ($svc in $ServiceName) {
            try {
                # In echter Umgebung würde hier Invoke-Command verwendet
                $service = Get-Service -Name $svc -ErrorAction Stop
                
                $healthStatus = switch ($service.Status) {
                    'Running' { 'Healthy' }
                    'Stopped' { if ($service.StartType -eq 'Automatic') { 'Critical' } else { 'OK' } }
                    default { 'Warning' }
                }
                
                $result = [PSCustomObject]@{
                    ComputerName = $Computer
                    ServiceName = $service.Name
                    Status = $service.Status
                    StartType = $service.StartType
                    Health = $healthStatus
                }
                
                if ($IncludeHealthScore) {
                    $score = switch ($healthStatus) {
                        'Healthy' { 100 }
                        'OK' { 75 }
                        'Warning' { 50 }
                        'Critical' { 0 }
                    }
                    $result | Add-Member -NotePropertyName 'HealthScore' -NotePropertyValue $score
                }
                
                $result
                $allResults += $result
            }
            catch {
                Write-Warning "Fehler bei $svc auf $Computer"
            }
        }
    }
    
    end {
        if ($IncludeHealthScore -and $allResults.Count -gt 0) {
            $avgScore = ($allResults.HealthScore | Measure-Object -Average).Average
            Write-Host "`nDurchschnittlicher Health-Score: $([math]::Round($avgScore, 0))%" -ForegroundColor Cyan
        }
    }
}

Write-Host "`nService Health Check:" -ForegroundColor Yellow
"localhost" | Test-ServiceHealth -ServiceName "Spooler", "WinRM", "W32Time" -IncludeHealthScore -Verbose | Format-Table

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 04" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. PIPELINE-PARAMETER:
   [Parameter(ValueFromPipeline)]
   - Akzeptiert das komplette Pipeline-Objekt
   - Typprüfung erfolgt automatisch

   [Parameter(ValueFromPipelineByPropertyName)]
   - Sucht Property mit passendem Namen
   - Nutze [Alias()] für alternative Namen

2. BEGIN/PROCESS/END:
   begin   { } # Einmal vor dem ersten Objekt
   process { } # Für JEDES Pipeline-Objekt
   end     { } # Einmal nach dem letzten Objekt

3. STREAMING vs. COLLECTING:
   STREAMING: Sofort ausgeben, speichereffizient
   COLLECTING: Sammeln für Sortierung/Aggregation

4. BEST PRACTICES:
   - Immer process{} Block verwenden
   - Write-Verbose für Debugging
   - Fehler pro Objekt behandeln
   - Output per Streaming wenn möglich

5. TYPISCHE MUSTER:
   # Multiple Parameter-Werte
   foreach (`$item in `$Parameter) { ... }
   
   # Pipeline-Objekte
   process { `$_ oder benannter Parameter }

"@ -ForegroundColor White

#endregion
