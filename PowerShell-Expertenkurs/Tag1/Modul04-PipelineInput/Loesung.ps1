#############################################################################
# Modul 04: Multiple Objects und Pipeline Input - LÖSUNGEN
# PowerShell Expertenkurs - Tag 1
#############################################################################

#region LÖSUNG AUFGABE 1: Get-FileInfo
#############################################################################

Write-Host "=== LÖSUNG AUFGABE 1: Get-FileInfo ===" -ForegroundColor Cyan

function Get-FileInfo {
    <#
    .SYNOPSIS
        Sammelt detaillierte Informationen über Dateien.
    .DESCRIPTION
        Akzeptiert Dateipfade per Parameter oder Pipeline und gibt
        strukturierte Informationen zurück.
    .PARAMETER Path
        Pfad zur Datei. Akzeptiert Strings oder FileInfo-Objekte.
    .EXAMPLE
        Get-FileInfo -Path "C:\Windows\notepad.exe"
    .EXAMPLE
        Get-ChildItem C:\Windows\*.exe | Get-FileInfo
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FilePath', 'FullName')]
        [string[]]$Path
    )
    
    process {
        foreach ($filePath in $Path) {
            Write-Verbose "Verarbeite: $filePath"
            
            try {
                # Prüfen ob es eine Datei ist
                if (-not (Test-Path $filePath -PathType Leaf)) {
                    Write-Warning "'$filePath' ist keine Datei oder existiert nicht"
                    continue
                }
                
                $file = Get-Item $filePath -ErrorAction Stop
                
                [PSCustomObject]@{
                    Name = $file.Name
                    FullPath = $file.FullName
                    SizeMB = [math]::Round($file.Length / 1MB, 2)
                    SizeBytes = $file.Length
                    Extension = $file.Extension
                    LastModified = $file.LastWriteTime
                    Created = $file.CreationTime
                    IsReadOnly = $file.IsReadOnly
                    Attributes = $file.Attributes.ToString()
                }
            }
            catch {
                Write-Warning "Fehler bei '$filePath': $($_.Exception.Message)"
            }
        }
    }
}

# Tests
Write-Host "`nTest 1: Als Parameter-Array:" -ForegroundColor Yellow
$testFiles = @(
    "$env:SystemRoot\notepad.exe"
    "$env:SystemRoot\regedit.exe"
)
Get-FileInfo -Path $testFiles -Verbose | Format-Table Name, SizeMB, LastModified

Write-Host "Test 2: Per Pipeline (Strings):" -ForegroundColor Yellow
$testFiles | Get-FileInfo | Format-Table Name, SizeMB, Extension

Write-Host "Test 3: Per Pipeline (FileInfo):" -ForegroundColor Yellow
Get-ChildItem "$env:SystemRoot\System32\*.dll" | 
    Select-Object -First 5 | 
    Get-FileInfo -Verbose | 
    Sort-Object SizeMB -Descending |
    Format-Table

Write-Host "Test 4: Fehlerbehandlung:" -ForegroundColor Yellow
"C:\NichtExistent.txt", "$env:SystemRoot\notepad.exe" | Get-FileInfo | Format-Table

#endregion

#region LÖSUNG AUFGABE 2: Measure-FolderContents
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 2: Measure-FolderContents ===" -ForegroundColor Cyan

function Measure-FolderContents {
    <#
    .SYNOPSIS
        Analysiert Ordnerinhalte und erstellt Statistiken.
    .DESCRIPTION
        Nutzt Begin/Process/End für effiziente Verarbeitung mit
        Zusammenfassung am Ende.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('Path', 'FullName')]
        [string]$FolderPath,
        
        [Parameter()]
        [switch]$IncludeSubfolders,
        
        [Parameter()]
        [int]$MinSizeKB = 0
    )
    
    begin {
        Write-Verbose "Initialisiere Statistik-Sammlung..."
        
        $stats = @{
            TotalFiles = 0
            TotalFolders = 0
            TotalSizeBytes = [long]0
            ExtensionCount = @{}
            ProcessedFolders = @()
            StartTime = Get-Date
        }
    }
    
    process {
        Write-Verbose "Verarbeite Ordner: $FolderPath"
        
        if (-not (Test-Path $FolderPath -PathType Container)) {
            Write-Warning "'$FolderPath' ist kein gültiger Ordner"
            return
        }
        
        $stats.ProcessedFolders += $FolderPath
        $stats.TotalFolders++
        
        # Parameter für Get-ChildItem
        $gciParams = @{
            Path = $FolderPath
            File = $true
            ErrorAction = 'SilentlyContinue'
        }
        if ($IncludeSubfolders) {
            $gciParams['Recurse'] = $true
        }
        
        $files = Get-ChildItem @gciParams
        
        # Dateien filtern
        if ($MinSizeKB -gt 0) {
            $files = $files | Where-Object { $_.Length -ge ($MinSizeKB * 1KB) }
        }
        
        # Statistiken aktualisieren und Streaming-Output
        foreach ($file in $files) {
            $stats.TotalFiles++
            $stats.TotalSizeBytes += $file.Length
            
            # Extension-Statistik
            $ext = if ($file.Extension) { $file.Extension.ToLower() } else { '(keine)' }
            if (-not $stats.ExtensionCount.ContainsKey($ext)) {
                $stats.ExtensionCount[$ext] = 0
            }
            $stats.ExtensionCount[$ext]++
            
            # Streaming-Output für jeden gefundenen Eintrag
            [PSCustomObject]@{
                FolderPath = $FolderPath
                FileName = $file.Name
                SizeKB = [math]::Round($file.Length / 1KB, 2)
                Extension = $ext
                LastModified = $file.LastWriteTime
            }
        }
    }
    
    end {
        $endTime = Get-Date
        $duration = $endTime - $stats.StartTime
        
        Write-Host "`n" + "="*60 -ForegroundColor Cyan
        Write-Host "ZUSAMMENFASSUNG" -ForegroundColor Cyan
        Write-Host "="*60 -ForegroundColor Cyan
        
        Write-Host "`nVerarbeitete Ordner: $($stats.TotalFolders)" -ForegroundColor White
        $stats.ProcessedFolders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        
        Write-Host "`nDatei-Statistik:" -ForegroundColor White
        Write-Host "  Gesamtanzahl Dateien: $($stats.TotalFiles)"
        
        $sizeMB = [math]::Round($stats.TotalSizeBytes / 1MB, 2)
        $sizeGB = [math]::Round($stats.TotalSizeBytes / 1GB, 2)
        $sizeDisplay = if ($sizeGB -ge 1) { "$sizeGB GB" } else { "$sizeMB MB" }
        Write-Host "  Gesamtgröße: $sizeDisplay ($($stats.TotalSizeBytes) Bytes)"
        
        if ($stats.TotalFiles -gt 0) {
            $avgSize = [math]::Round(($stats.TotalSizeBytes / $stats.TotalFiles) / 1KB, 2)
            Write-Host "  Durchschnittsgröße: $avgSize KB"
        }
        
        Write-Host "`nTop 5 Dateitypen:" -ForegroundColor White
        $stats.ExtensionCount.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value) Dateien"
            }
        
        Write-Host "`nVerarbeitungsdauer: $($duration.TotalSeconds.ToString('F2')) Sekunden" -ForegroundColor Gray
    }
}

# Tests
Write-Host "Test Measure-FolderContents:" -ForegroundColor Yellow
$testFolder = $env:TEMP
Measure-FolderContents -FolderPath $testFolder -MinSizeKB 10 -Verbose | 
    Select-Object -First 10 | 
    Format-Table

#endregion

#region LÖSUNG AUFGABE 3: Get-RemoteSystemInfo
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 3: Get-RemoteSystemInfo ===" -ForegroundColor Cyan

function Get-RemoteSystemInfo {
    <#
    .SYNOPSIS
        Sammelt System-Informationen von Computern.
    .DESCRIPTION
        Akzeptiert Computer-Namen per Pipeline und gibt strukturierte
        System-Informationen zurück.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('CN', 'Server', 'Hostname', 'Name', 'DNSHostName')]
        [string]$ComputerName,
        
        [Parameter()]
        [switch]$IncludeDisks,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    begin {
        Write-Verbose "Starte System-Info Sammlung..."
        Write-Verbose "IncludeDisks: $IncludeDisks"
    }
    
    process {
        Write-Verbose "Abfrage Computer: $ComputerName"
        
        try {
            # Für Demo nutzen wir lokale Daten
            # In Produktion würde hier Invoke-Command oder CIM verwendet
            $isLocal = ($ComputerName -eq $env:COMPUTERNAME) -or 
                       ($ComputerName -eq 'localhost') -or 
                       ($ComputerName -eq '.')
            
            if (-not $isLocal) {
                Write-Verbose "Simuliere Remote-Abfrage für: $ComputerName"
            }
            
            # OS-Info
            $os = Get-CimInstance Win32_OperatingSystem
            
            # Uptime berechnen
            $uptime = (Get-Date) - $os.LastBootUpTime
            
            # Basis-Objekt erstellen
            $result = [PSCustomObject]@{
                ComputerName = $ComputerName
                OperatingSystem = $os.Caption
                OSVersion = $os.Version
                OSArchitecture = $os.OSArchitecture
                LastBootTime = $os.LastBootUpTime
                UptimeDays = [math]::Round($uptime.TotalDays, 2)
                UptimeString = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
                TotalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                FreeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                UsedMemoryGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
                MemoryUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
                QueryTime = Get-Date
            }
            
            # Optional: Disk-Informationen
            if ($IncludeDisks) {
                Write-Verbose "Sammle Disk-Informationen..."
                
                $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Drive = $_.DeviceID
                            VolumeName = $_.VolumeName
                            TotalGB = [math]::Round($_.Size / 1GB, 2)
                            FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                            UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
                            PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                        }
                    }
                
                $result | Add-Member -NotePropertyName 'Disks' -NotePropertyValue $disks
                $result | Add-Member -NotePropertyName 'DiskCount' -NotePropertyValue $disks.Count
            }
            
            # Output
            $result
        }
        catch {
            Write-Warning "Fehler bei Computer '$ComputerName': $($_.Exception.Message)"
            
            # Fehler-Objekt ausgeben
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Error = $_.Exception.Message
                QueryTime = Get-Date
            }
        }
    }
    
    end {
        Write-Verbose "System-Info Sammlung abgeschlossen"
    }
}

# Tests
Write-Host "Test 1: Lokaler Computer:" -ForegroundColor Yellow
Get-RemoteSystemInfo -ComputerName $env:COMPUTERNAME -Verbose | Format-List

Write-Host "`nTest 2: Mit Disks:" -ForegroundColor Yellow
$info = Get-RemoteSystemInfo -ComputerName "localhost" -IncludeDisks -Verbose
$info | Format-List ComputerName, OperatingSystem, UptimeString, MemoryUsedPercent
$info.Disks | Format-Table

Write-Host "`nTest 3: Multiple Computer per Pipeline:" -ForegroundColor Yellow
@(
    [PSCustomObject]@{ Name = "localhost" }
    [PSCustomObject]@{ ComputerName = $env:COMPUTERNAME }
    [PSCustomObject]@{ Server = "localhost" }
) | Get-RemoteSystemInfo | Format-Table ComputerName, UptimeString, MemoryUsedPercent

#endregion

#region LÖSUNG AUFGABE 4: ConvertTo-HashedObject
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 4: ConvertTo-HashedObject ===" -ForegroundColor Cyan

function ConvertTo-HashedObject {
    <#
    .SYNOPSIS
        Fügt Hash-Werte für angegebene Eigenschaften hinzu.
    .DESCRIPTION
        Arbeitet per Streaming - keine Sammlung im Speicher.
        Original-Objekt bleibt erhalten.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [PSObject]$InputObject,
        
        [Parameter(Mandatory)]
        [string[]]$Property,
        
        [Parameter()]
        [ValidateSet('MD5', 'SHA1', 'SHA256')]
        [string]$Algorithm = 'SHA256'
    )
    
    begin {
        Write-Verbose "Initialisiere Hash-Algorithmus: $Algorithm"
        
        # Hash-Algorithmus erstellen
        $hasher = switch ($Algorithm) {
            'MD5'    { [System.Security.Cryptography.MD5]::Create() }
            'SHA1'   { [System.Security.Cryptography.SHA1]::Create() }
            'SHA256' { [System.Security.Cryptography.SHA256]::Create() }
        }
    }
    
    process {
        # Kein Sammeln - direkt verarbeiten und ausgeben
        
        # Kopie des Objekts erstellen um Original nicht zu verändern
        $outputObject = $InputObject.PSObject.Copy()
        
        foreach ($prop in $Property) {
            $propValue = $InputObject.$prop
            
            if ($null -ne $propValue) {
                # String in Bytes konvertieren
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($propValue.ToString())
                
                # Hash berechnen
                $hashBytes = $hasher.ComputeHash($bytes)
                
                # In Hex-String konvertieren
                $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
                
                # Neue Property mit Hash-Wert hinzufügen
                $hashPropertyName = "${prop}_${Algorithm}"
                $outputObject | Add-Member -NotePropertyName $hashPropertyName -NotePropertyValue $hashString -Force
            }
            else {
                Write-Verbose "Property '$prop' ist null für Objekt"
                $hashPropertyName = "${prop}_${Algorithm}"
                $outputObject | Add-Member -NotePropertyName $hashPropertyName -NotePropertyValue $null -Force
            }
        }
        
        # Streaming: Sofort ausgeben
        $outputObject
    }
    
    end {
        # Hasher aufräumen
        $hasher.Dispose()
        Write-Verbose "Hash-Verarbeitung abgeschlossen"
    }
}

# Tests
Write-Host "Test ConvertTo-HashedObject:" -ForegroundColor Yellow

# Test-Daten erstellen
$testUsers = @(
    [PSCustomObject]@{ Name = "Max Mustermann"; Email = "max@example.com"; Phone = "+49123456789" }
    [PSCustomObject]@{ Name = "Erika Musterfrau"; Email = "erika@example.com"; Phone = "+49987654321" }
    [PSCustomObject]@{ Name = "John Doe"; Email = "john@example.com"; Phone = $null }
)

Write-Host "`nOriginal-Daten:" -ForegroundColor Yellow
$testUsers | Format-Table

Write-Host "Mit gehashter Email (SHA256):" -ForegroundColor Yellow
$testUsers | ConvertTo-HashedObject -Property Email -Algorithm SHA256 -Verbose | 
    Format-Table Name, Email, Email_SHA256

Write-Host "`nMit mehreren gehashten Properties (MD5):" -ForegroundColor Yellow
$testUsers | ConvertTo-HashedObject -Property Email, Phone -Algorithm MD5 |
    Format-Table Name, Email_MD5, Phone_MD5

# Streaming-Demo
Write-Host "`nStreaming-Demo (Objekte erscheinen einzeln):" -ForegroundColor Yellow
1..3 | ForEach-Object {
    [PSCustomObject]@{ Id = $_; Data = "Value$_" }
} | ConvertTo-HashedObject -Property Data -Algorithm SHA1 | ForEach-Object {
    Write-Host "  Empfangen: Id=$($_.Id), Hash=$($_.Data_SHA1.Substring(0,8))..."
    Start-Sleep -Milliseconds 300
    $_
} | Out-Null

#endregion

#region LÖSUNG BONUSAUFGABE: Find-LargeFile
#############################################################################

Write-Host "`n=== LÖSUNG BONUSAUFGABE: Find-LargeFile ===" -ForegroundColor Cyan

function Find-LargeFile {
    <#
    .SYNOPSIS
        Findet große Dateien mit effizienter Pipeline-Behandlung.
    .DESCRIPTION
        Erkennt Pipeline-Abbruch und führt Cleanup durch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [System.IO.FileInfo]$File,
        
        [Parameter()]
        [double]$MinSizeMB = 10
    )
    
    begin {
        Write-Verbose "Starte Suche nach Dateien >= $MinSizeMB MB"
        
        $statistics = @{
            Checked = 0
            Found = 0
            StartTime = Get-Date
        }
        
        $minSizeBytes = $MinSizeMB * 1MB
    }
    
    process {
        # Prüfen ob Pipeline abgebrochen wurde
        # (funktioniert mit Select-Object -First)
        
        $statistics.Checked++
        
        try {
            $sizeMB = $File.Length / 1MB
            
            if ($File.Length -ge $minSizeBytes) {
                $statistics.Found++
                
                Write-Verbose "Gefunden: $($File.Name) ($([math]::Round($sizeMB, 2)) MB)"
                
                [PSCustomObject]@{
                    Name = $File.Name
                    FullPath = $File.FullName
                    SizeMB = [math]::Round($sizeMB, 2)
                    LastModified = $File.LastWriteTime
                    Directory = $File.DirectoryName
                }
            }
        }
        catch {
            Write-Verbose "Fehler bei Datei: $($_.Exception.Message)"
        }
    }
    
    end {
        # Cleanup - wird auch bei Pipeline-Abbruch aufgerufen
        $duration = (Get-Date) - $statistics.StartTime
        
        Write-Verbose "=== Statistik ==="
        Write-Verbose "Geprüfte Dateien: $($statistics.Checked)"
        Write-Verbose "Gefundene Dateien: $($statistics.Found)"
        Write-Verbose "Dauer: $($duration.TotalSeconds.ToString('F2')) Sekunden"
    }
}

# Tests
Write-Host "Test Find-LargeFile:" -ForegroundColor Yellow

Write-Host "`nAlle großen Dateien in System32:" -ForegroundColor Yellow
Get-ChildItem "$env:SystemRoot\System32" -File -ErrorAction SilentlyContinue |
    Find-LargeFile -MinSizeMB 5 -Verbose |
    Select-Object -First 5 |
    Format-Table Name, SizeMB, LastModified

Write-Host "`nDemo Pipeline-Abbruch mit Select-Object -First:" -ForegroundColor Yellow
Write-Host "(Beachten Sie die Statistik im Verbose-Output)" -ForegroundColor Gray

Get-ChildItem "$env:SystemRoot" -File -Recurse -ErrorAction SilentlyContinue |
    Find-LargeFile -MinSizeMB 1 -Verbose |
    Select-Object -First 3 |
    Format-Table Name, SizeMB

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ALLE LÖSUNGEN ERFOLGREICH DEMONSTRIERT" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

WICHTIGE LERNPUNKTE:

1. AUFGABE 1 - Get-FileInfo:
   - ValueFromPipeline + ValueFromPipelineByPropertyName kombinieren
   - Mehrere Aliase für Flexibilität
   - foreach im process{} für Array-Parameter

2. AUFGABE 2 - Measure-FolderContents:
   - begin{} für Initialisierung
   - process{} für Streaming + Statistik-Update
   - end{} für Zusammenfassung

3. AUFGABE 3 - Get-RemoteSystemInfo:
   - Viele Aliase für Pipeline-Kompatibilität
   - Add-Member für optionale Properties
   - Verschachtelte Objekte möglich

4. AUFGABE 4 - ConvertTo-HashedObject:
   - Echtes Streaming ohne Sammlung
   - PSObject.Copy() für Objekt-Kopien
   - Dispose() im end{} Block

5. BONUS - Find-LargeFile:
   - Pipeline-Abbruch automatisch behandelt
   - end{} Block für garantiertes Cleanup
   - Statistiken trotz Abbruch verfügbar

"@ -ForegroundColor White

#endregion
