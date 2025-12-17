#############################################################################
# Modul 09 - Fehlerbehandlung in Skripten
# LÖSUNGEN
#############################################################################

#region Übung 1: Try/Catch/Finally Grundlagen

function Get-ConfigurationFile {
    <#
    .SYNOPSIS
        Liest und parst Konfigurationsdateien sicher.
    
    .DESCRIPTION
        Liest Konfigurationsdateien in verschiedenen Formaten mit 
        umfassender Fehlerbehandlung.
    
    .EXAMPLE
        Get-ConfigurationFile -Path "C:\config.json" -Format JSON
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject], [hashtable], [xml])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('JSON', 'XML', 'INI')]
        [string]$Format = 'JSON'
    )
    
    try {
        Write-Verbose "Lese Konfiguration: $Path (Format: $Format)"
        
        # Datei lesen
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        
        # Format parsen
        $config = switch ($Format) {
            'JSON' {
                try {
                    $content | ConvertFrom-Json -ErrorAction Stop
                }
                catch [System.ArgumentException] {
                    throw [System.FormatException]::new("Ungültiges JSON-Format in: $Path")
                }
            }
            'XML' {
                try {
                    [xml]$content
                }
                catch [System.Xml.XmlException] {
                    throw [System.FormatException]::new("Ungültiges XML-Format in: $Path")
                }
            }
            'INI' {
                # Einfacher INI-Parser
                $ini = @{}
                $section = "Default"
                
                foreach ($line in ($content -split "`n")) {
                    $line = $line.Trim()
                    
                    if ($line -match '^\[(.+)\]$') {
                        $section = $matches[1]
                        $ini[$section] = @{}
                    }
                    elseif ($line -match '^([^=]+)=(.*)$') {
                        if (-not $ini[$section]) { $ini[$section] = @{} }
                        $ini[$section][$matches[1].Trim()] = $matches[2].Trim()
                    }
                }
                
                $ini
            }
        }
        
        Write-Verbose "Konfiguration erfolgreich geladen"
        return $config
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning "Datei nicht gefunden: $Path"
        return $null
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Zugriff verweigert: $Path"
        return $null
    }
    catch [System.FormatException] {
        Write-Warning $_.Exception.Message
        return $null
    }
    catch {
        Write-Warning "Unbekannter Fehler beim Lesen von $Path : $_"
        return $null
    }
    finally {
        Write-Host "Vorgang abgeschlossen für: $Path" -ForegroundColor DarkGray
    }
}

# Tests
Write-Host "=== Übung 1: Get-ConfigurationFile ===" -ForegroundColor Green

# Test-Dateien erstellen
$testJson = @{
    Name = "TestConfig"
    Version = "1.0"
    Settings = @{
        Debug = $true
        LogLevel = "Info"
    }
} | ConvertTo-Json

$testPath = "$env:TEMP\test-config.json"
$testJson | Out-File $testPath

Write-Host "`nTest: Gültige JSON-Datei" -ForegroundColor Yellow
$config = Get-ConfigurationFile -Path $testPath -Format JSON
$config | Format-List

Write-Host "`nTest: Datei nicht gefunden" -ForegroundColor Yellow
Get-ConfigurationFile -Path "C:\NichtExistent.json" -Format JSON

# Cleanup
Remove-Item $testPath -ErrorAction SilentlyContinue

#endregion

#region Übung 2: ErrorAction und ErrorVariable

function Test-ServerConnectivity {
    <#
    .SYNOPSIS
        Prüft die Erreichbarkeit mehrerer Server.
    
    .DESCRIPTION
        Testet Server-Konnektivität mit detaillierter Fehlerberichterstattung.
    
    .EXAMPLE
        Test-ServerConnectivity -ComputerName "server1", "server2" -Port 443
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('CN', 'Name')]
        [string[]]$ComputerName,
        
        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 80,
        
        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$TimeoutSeconds = 3
    )
    
    begin {
        $results = @()
        $allErrors = @()
        $startTime = Get-Date
    }
    
    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Teste: $computer`:$Port"
            
            # Test durchführen
            $testResult = Test-NetConnection -ComputerName $computer `
                -Port $Port `
                -WarningAction SilentlyContinue `
                -ErrorAction SilentlyContinue `
                -ErrorVariable connError
            
            if ($connError) {
                $allErrors += [PSCustomObject]@{
                    ComputerName = $computer
                    Error = $connError[0].Exception.Message
                }
            }
            
            # Ergebnis erstellen
            $result = [PSCustomObject]@{
                ComputerName = $computer
                Port = $Port
                Status = if ($testResult.TcpTestSucceeded) { "Online" } else { "Offline" }
                ResponseTime = if ($testResult.PingReplyDetails) {
                    "$($testResult.PingReplyDetails.RoundtripTime) ms"
                } else { "-" }
                Error = if ($connError) { $connError[0].Exception.Message } else { "" }
            }
            
            $results += $result
            
            # Status-Anzeige
            $statusColor = if ($result.Status -eq "Online") { "Green" } else { "Red" }
            Write-Host "  $computer`: " -NoNewline
            Write-Host $result.Status -ForegroundColor $statusColor
        }
    }
    
    end {
        $duration = (Get-Date) - $startTime
        
        # Ergebnisse ausgeben
        Write-Host ""
        $results | Format-Table -AutoSize
        
        # Zusammenfassung
        $offlineCount = ($results | Where-Object Status -eq "Offline").Count
        $onlineCount = ($results | Where-Object Status -eq "Online").Count
        $totalCount = $results.Count
        
        Write-Host "Zusammenfassung:" -ForegroundColor Cyan
        Write-Host "  Online:  $onlineCount von $totalCount"
        Write-Host "  Offline: $offlineCount von $totalCount"
        Write-Host "  Dauer:   $($duration.TotalSeconds.ToString('0.00')) Sekunden"
        
        if ($allErrors.Count -gt 0) {
            Write-Host "`nFehler-Details:" -ForegroundColor Yellow
            $allErrors | ForEach-Object {
                Write-Host "  $($_.ComputerName): $($_.Error)" -ForegroundColor Red
            }
        }
        
        return $results
    }
}

# Test
Write-Host "`n=== Übung 2: Test-ServerConnectivity ===" -ForegroundColor Green
$servers = @("localhost", "8.8.8.8", "nicht.existiert.local")
$results = Test-ServerConnectivity -ComputerName $servers -Port 80 -Verbose

#endregion

#region Übung 3: Professionelle Fehlerbehandlung

function Invoke-BackupOperation {
    <#
    .SYNOPSIS
        Führt Backup-Operationen mit professioneller Fehlerbehandlung durch.
    
    .DESCRIPTION
        Sichert Dateien mit Retry-Logik, Kompression und umfassender
        Fehlerbehandlung für Produktionsumgebungen.
    
    .EXAMPLE
        Invoke-BackupOperation -SourcePath "C:\Data" -DestinationPath "D:\Backup"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ 
            if (-not (Test-Path $_)) {
                throw "Quellpfad existiert nicht: $_"
            }
            $true
        })]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        
        [Parameter()]
        [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
        [string]$CompressionLevel = 'Optimal',
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3
    )
    
    begin {
        # Log-Funktion
        $logPath = "$env:TEMP\BackupOperation_$(Get-Date -Format 'yyyyMMdd').log"
        
        function Write-BackupLog {
            param(
                [string]$Message,
                [ValidateSet('Info', 'Warning', 'Error')]
                [string]$Level = 'Info'
            )
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $entry = "[$timestamp] [$Level] $Message"
            
            $color = switch ($Level) {
                'Warning' { 'Yellow' }
                'Error'   { 'Red' }
                default   { 'Gray' }
            }
            
            Write-Verbose $entry
            Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
        }
        
        # Temporäre Dateien tracken
        $tempFiles = @()
        $startTime = Get-Date
    }
    
    process {
        Write-BackupLog "Starte Backup: $SourcePath -> $DestinationPath"
        Write-BackupLog "Kompression: $CompressionLevel"
        
        try {
            # Zielverzeichnis erstellen
            $destDir = Split-Path $DestinationPath -Parent
            if ($destDir -and -not (Test-Path $destDir)) {
                Write-BackupLog "Erstelle Zielverzeichnis: $destDir"
                New-Item -Path $destDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            
            # Backup mit Retry-Logik
            $success = $false
            $lastError = $null
            
            for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
                try {
                    Write-BackupLog "Versuch $attempt von $MaxRetries..."
                    
                    # Quelldaten sammeln
                    $sourceItems = Get-ChildItem -Path $SourcePath -Recurse -ErrorAction Stop
                    $totalSize = ($sourceItems | Measure-Object -Property Length -Sum).Sum
                    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
                    
                    Write-BackupLog "Zu sichern: $($sourceItems.Count) Dateien, $totalSizeMB MB"
                    
                    # Backup erstellen (ZIP)
                    $zipPath = if ($DestinationPath -match '\.zip$') {
                        $DestinationPath
                    } else {
                        "$DestinationPath\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
                    }
                    
                    $tempFiles += $zipPath
                    
                    # Compression Level umwandeln
                    $compLevel = switch ($CompressionLevel) {
                        'Optimal'       { [System.IO.Compression.CompressionLevel]::Optimal }
                        'Fastest'       { [System.IO.Compression.CompressionLevel]::Fastest }
                        'NoCompression' { [System.IO.Compression.CompressionLevel]::NoCompression }
                    }
                    
                    # ZIP erstellen
                    Compress-Archive -Path $SourcePath -DestinationPath $zipPath -Force -ErrorAction Stop
                    
                    # Verifizierung
                    $zipInfo = Get-Item $zipPath -ErrorAction Stop
                    $zipSizeMB = [math]::Round($zipInfo.Length / 1MB, 2)
                    
                    Write-BackupLog "Backup erstellt: $zipPath ($zipSizeMB MB)"
                    $success = $true
                    break
                }
                catch [System.IO.IOException] {
                    $lastError = $_
                    Write-BackupLog "IO-Fehler (Datei möglicherweise in Verwendung): $($_.Exception.Message)" -Level Warning
                    
                    if ($attempt -lt $MaxRetries) {
                        $waitTime = 2 * $attempt  # Exponential backoff
                        Write-BackupLog "Warte $waitTime Sekunden vor nächstem Versuch..." -Level Warning
                        Start-Sleep -Seconds $waitTime
                    }
                }
                catch [System.UnauthorizedAccessException] {
                    Write-BackupLog "Zugriff verweigert: $($_.Exception.Message)" -Level Error
                    throw  # Keine Retry bei Berechtigungsproblemen
                }
                catch [System.OutOfMemoryException] {
                    Write-BackupLog "Nicht genügend Speicher für Backup!" -Level Error
                    throw  # Keine Retry bei Speicherproblemen
                }
            }
            
            if (-not $success) {
                throw $lastError
            }
            
            # Erfolg
            $duration = (Get-Date) - $startTime
            Write-BackupLog "Backup erfolgreich abgeschlossen in $($duration.TotalSeconds.ToString('0.00')) Sekunden"
            
            return [PSCustomObject]@{
                Success = $true
                SourcePath = $SourcePath
                DestinationPath = $zipPath
                OriginalSize = "$totalSizeMB MB"
                BackupSize = "$zipSizeMB MB"
                Duration = $duration.ToString("hh\:mm\:ss")
                Timestamp = Get-Date
            }
        }
        catch {
            Write-BackupLog "Backup fehlgeschlagen: $($_.Exception.Message)" -Level Error
            
            return [PSCustomObject]@{
                Success = $false
                SourcePath = $SourcePath
                DestinationPath = $DestinationPath
                Error = $_.Exception.Message
                Timestamp = Get-Date
            }
        }
        finally {
            # Cleanup temporärer Dateien bei Fehler
            if (-not $success) {
                foreach ($temp in $tempFiles) {
                    if ((Test-Path $temp) -and $temp -match '\.tmp$') {
                        Write-BackupLog "Lösche temporäre Datei: $temp"
                        Remove-Item $temp -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            
            Write-BackupLog "Backup-Operation abgeschlossen"
        }
    }
}

# Test
Write-Host "`n=== Übung 3: Invoke-BackupOperation ===" -ForegroundColor Green

# Test-Verzeichnis erstellen
$testSource = "$env:TEMP\BackupTest"
$testDest = "$env:TEMP\BackupDest"

New-Item -Path $testSource -ItemType Directory -Force | Out-Null
"Test1" | Out-File "$testSource\file1.txt"
"Test2" | Out-File "$testSource\file2.txt"

Write-Host "Test: Backup durchführen" -ForegroundColor Yellow
$result = Invoke-BackupOperation -SourcePath $testSource -DestinationPath $testDest -Verbose
$result | Format-List

# Cleanup
Remove-Item $testSource -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $testDest -Recurse -Force -ErrorAction SilentlyContinue

#endregion

#region Übung 4 (Bonus): Error Records analysieren

function Get-ErrorAnalysis {
    <#
    .SYNOPSIS
        Analysiert Error Records detailliert.
    
    .DESCRIPTION
        Extrahiert und formatiert alle relevanten Informationen aus
        einem PowerShell Error Record.
    
    .EXAMPLE
        $Error[0] | Get-ErrorAnalysis -IncludeStackTrace
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter()]
        [switch]$IncludeStackTrace
    )
    
    process {
        $width = 60
        
        Write-Host ("═" * $width) -ForegroundColor Red
        Write-Host " ERROR ANALYSIS" -ForegroundColor Red
        Write-Host ("═" * $width) -ForegroundColor Red
        Write-Host ""
        
        # Exception-Details
        Write-Host "Exception:" -ForegroundColor Cyan
        Write-Host "  Type:    $($ErrorRecord.Exception.GetType().Name)"
        Write-Host "  Message: $($ErrorRecord.Exception.Message)"
        Write-Host ""
        
        # Category
        Write-Host "Category:" -ForegroundColor Cyan
        Write-Host "  Category: $($ErrorRecord.CategoryInfo.Category)"
        Write-Host "  Activity: $($ErrorRecord.CategoryInfo.Activity)"
        Write-Host "  Reason:   $($ErrorRecord.CategoryInfo.Reason)"
        Write-Host ""
        
        # Target
        if ($ErrorRecord.TargetObject) {
            Write-Host "Target:" -ForegroundColor Cyan
            Write-Host "  Object: $($ErrorRecord.TargetObject)"
            Write-Host "  Type:   $($ErrorRecord.TargetObject.GetType().Name)"
            Write-Host ""
        }
        
        # Position
        Write-Host "Position:" -ForegroundColor Cyan
        $invInfo = $ErrorRecord.InvocationInfo
        Write-Host "  Script:  $(if ($invInfo.ScriptName) { $invInfo.ScriptName } else { 'Interactive' })"
        Write-Host "  Line:    $($invInfo.ScriptLineNumber)"
        Write-Host "  Command: $($invInfo.MyCommand)"
        if ($invInfo.Line) {
            Write-Host "  Code:    $($invInfo.Line.Trim())"
        }
        Write-Host ""
        
        # Empfehlungen basierend auf Error-Typ
        Write-Host "Recommendation:" -ForegroundColor Cyan
        
        $recommendation = switch -Regex ($ErrorRecord.Exception.GetType().Name) {
            'ItemNotFoundException' {
                "  ► Prüfen Sie, ob der Pfad existiert mit Test-Path`n  ► Stellen Sie sicher, dass der Pfad korrekt geschrieben ist"
            }
            'UnauthorizedAccessException' {
                "  ► Prüfen Sie die Berechtigungen für die Ressource`n  ► Führen Sie PowerShell als Administrator aus"
            }
            'ArgumentException|ArgumentNullException' {
                "  ► Prüfen Sie die übergebenen Parameter`n  ► Lesen Sie die Hilfe: Get-Help <Command> -Parameter *"
            }
            'IOException' {
                "  ► Prüfen Sie, ob die Datei von einem anderen Prozess verwendet wird`n  ► Schließen Sie Programme, die auf die Datei zugreifen"
            }
            'TimeoutException' {
                "  ► Erhöhen Sie den Timeout-Wert`n  ► Prüfen Sie die Netzwerkverbindung"
            }
            'WebException|HttpRequestException' {
                "  ► Prüfen Sie die Netzwerkverbindung`n  ► Verifizieren Sie die URL`n  ► Prüfen Sie Firewall-Einstellungen"
            }
            default {
                "  ► Prüfen Sie die Exception-Message für Details`n  ► Suchen Sie online nach dem Fehlercode"
            }
        }
        
        Write-Host $recommendation -ForegroundColor Yellow
        Write-Host ""
        
        # Stack Trace
        if ($IncludeStackTrace -and $ErrorRecord.Exception.StackTrace) {
            Write-Host "Stack Trace:" -ForegroundColor Cyan
            $ErrorRecord.Exception.StackTrace -split "`n" | ForEach-Object {
                Write-Host "  $_" -ForegroundColor DarkGray
            }
            Write-Host ""
        }
        
        # Error Record als Objekt zurückgeben
        [PSCustomObject]@{
            ExceptionType = $ErrorRecord.Exception.GetType().Name
            Message = $ErrorRecord.Exception.Message
            Category = $ErrorRecord.CategoryInfo.Category.ToString()
            TargetObject = $ErrorRecord.TargetObject
            ScriptName = $invInfo.ScriptName
            LineNumber = $invInfo.ScriptLineNumber
            Command = $invInfo.MyCommand
            StackTrace = $ErrorRecord.Exception.StackTrace
        }
    }
}

# Test
Write-Host "`n=== Übung 4 (Bonus): Get-ErrorAnalysis ===" -ForegroundColor Green

# Fehler produzieren
try {
    Get-Item "C:\NichtExistierender\Pfad\Datei.txt" -ErrorAction Stop
}
catch {
    $testError = $_
}

Write-Host "Analyse eines Error Records:" -ForegroundColor Yellow
$analysis = $testError | Get-ErrorAnalysis -IncludeStackTrace

#endregion

#region Zusammenfassung
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALLE LÖSUNGEN GELADEN" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

Verfügbare Funktionen:
  - Get-ConfigurationFile (Übung 1)
  - Test-ServerConnectivity (Übung 2)
  - Invoke-BackupOperation (Übung 3)
  - Get-ErrorAnalysis (Bonus)

Tipp: Nutzen Sie -Verbose für detaillierte Ausgaben!

"@ -ForegroundColor White
#endregion
