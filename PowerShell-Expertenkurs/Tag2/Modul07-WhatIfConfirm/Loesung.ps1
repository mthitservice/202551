#############################################################################
# Modul 07 - WhatIf und Confirm Support
# LÖSUNGEN
#############################################################################

#region Übung 1: Remove-TempUserFiles

function Remove-TempUserFiles {
    <#
    .SYNOPSIS
        Löscht temporäre Benutzerdateien mit WhatIf/Confirm-Unterstützung.
    
    .DESCRIPTION
        Entfernt temporäre Dateien aus dem Benutzer-Temp-Verzeichnis
        basierend auf Dateityp und Alter.
    
    .EXAMPLE
        Remove-TempUserFiles -UserName "TestUser" -WhatIf
    
    .EXAMPLE
        Remove-TempUserFiles -UserName "TestUser" -OlderThanDays 30 -Confirm
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter()]
        [string[]]$FileTypes = @('*.tmp', '*.temp', '*.cache'),
        
        [Parameter()]
        [int]$OlderThanDays = 7
    )
    
    begin {
        $tempPath = "C:\Users\$UserName\AppData\Local\Temp"
        $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
        
        Write-Verbose "Suche in: $tempPath"
        Write-Verbose "Dateitypen: $($FileTypes -join ', ')"
        Write-Verbose "Älter als: $cutoffDate"
        
        # Prüfen ob Pfad existiert
        if (-not (Test-Path $tempPath)) {
            Write-Warning "Temp-Pfad nicht gefunden: $tempPath"
            return
        }
        
        $totalSize = 0
        $fileCount = 0
    }
    
    process {
        # Dateien sammeln
        $filesToDelete = @()
        
        foreach ($pattern in $FileTypes) {
            $files = Get-ChildItem -Path $tempPath -Filter $pattern -File -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $cutoffDate }
            $filesToDelete += $files
        }
        
        if ($filesToDelete.Count -eq 0) {
            Write-Host "Keine Dateien zum Löschen gefunden." -ForegroundColor Yellow
            return
        }
        
        Write-Host "Gefunden: $($filesToDelete.Count) Dateien zum Löschen" -ForegroundColor Cyan
        
        # Jede Datei einzeln verarbeiten
        foreach ($file in $filesToDelete) {
            $sizeKB = [math]::Round($file.Length / 1KB, 2)
            $action = "Delete file ($sizeKB KB, Last modified: $($file.LastWriteTime.ToString('yyyy-MM-dd')))"
            
            if ($PSCmdlet.ShouldProcess($file.FullName, $action)) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $totalSize += $file.Length
                    $fileCount++
                    Write-Verbose "Gelöscht: $($file.Name)"
                }
                catch {
                    Write-Warning "Fehler beim Löschen von $($file.Name): $_"
                }
            }
        }
    }
    
    end {
        if ($fileCount -gt 0) {
            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-Host "Zusammenfassung: $fileCount Dateien gelöscht ($sizeMB MB)" -ForegroundColor Green
        }
    }
}

# Demo/Test
Write-Host "=== Übung 1: Remove-TempUserFiles ===" -ForegroundColor Green
Write-Host "Funktion erstellt. Testen Sie mit:" -ForegroundColor Yellow
Write-Host "  Remove-TempUserFiles -UserName `$env:USERNAME -WhatIf"
Write-Host "  Remove-TempUserFiles -UserName `$env:USERNAME -Confirm"

#endregion

#region Übung 2: Funktionen mit verschiedenen ConfirmImpact-Levels

# === Low Impact ===
function Update-UserPreferences {
    <#
    .SYNOPSIS
        Aktualisiert Benutzereinstellungen (Low Impact).
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter()]
        [ValidateSet('Light', 'Dark', 'System')]
        [string]$Theme = 'System',
        
        [Parameter()]
        [ValidateSet('de-DE', 'en-US', 'en-GB', 'fr-FR')]
        [string]$Language = 'de-DE'
    )
    
    if ($PSCmdlet.ShouldProcess($UserName, "Update preferences (Theme: $Theme, Language: $Language)")) {
        [PSCustomObject]@{
            UserName = $UserName
            Theme = $Theme
            Language = $Language
            UpdatedAt = Get-Date
            Status = 'Success'
        }
        Write-Verbose "Einstellungen für $UserName aktualisiert"
    }
}

# === Medium Impact ===
function Restart-ApplicationService {
    <#
    .SYNOPSIS
        Startet einen Anwendungsdienst neu (Medium Impact).
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter()]
        [int]$GracePeriodSeconds = 30
    )
    
    $action = "Restart service (Grace period: $GracePeriodSeconds seconds)"
    
    if ($PSCmdlet.ShouldProcess($ServiceName, $action)) {
        Write-Host "Stoppe Dienst: $ServiceName" -ForegroundColor Yellow
        Write-Host "Warte $GracePeriodSeconds Sekunden..." -ForegroundColor Yellow
        # Start-Sleep -Seconds $GracePeriodSeconds
        Write-Host "Starte Dienst: $ServiceName" -ForegroundColor Green
        
        [PSCustomObject]@{
            ServiceName = $ServiceName
            GracePeriod = $GracePeriodSeconds
            RestartedAt = Get-Date
            Status = 'Running'
        }
    }
}

# === High Impact ===
function Remove-UserAccount {
    <#
    .SYNOPSIS
        Löscht ein Benutzerkonto (High Impact).
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter()]
        [switch]$IncludeHomeDirectory
    )
    
    $action = "DELETE user account"
    if ($IncludeHomeDirectory) {
        $action += " INCLUDING home directory"
    }
    
    if ($PSCmdlet.ShouldProcess($UserName, $action)) {
        Write-Host "WARNUNG: Lösche Benutzerkonto: $UserName" -ForegroundColor Red
        
        if ($IncludeHomeDirectory) {
            Write-Host "WARNUNG: Home-Verzeichnis wird ebenfalls gelöscht!" -ForegroundColor Red
        }
        
        [PSCustomObject]@{
            UserName = $UserName
            HomeDirectoryRemoved = $IncludeHomeDirectory
            DeletedAt = Get-Date
            Status = 'Deleted'
        }
    }
}

# Demo/Test
Write-Host "`n=== Übung 2: ConfirmImpact Level ===" -ForegroundColor Green
Write-Host @"

Funktionen erstellt:
  - Update-UserPreferences (ConfirmImpact = Low)
  - Restart-ApplicationService (ConfirmImpact = Medium)
  - Remove-UserAccount (ConfirmImpact = High)

Testen Sie mit verschiedenen ConfirmPreference-Werten:
"@ -ForegroundColor Yellow

Write-Host @"

# Standard (High)
`$ConfirmPreference = 'High'
Update-UserPreferences -UserName "Test" -Theme "Dark"           # Keine Nachfrage
Restart-ApplicationService -ServiceName "MyService"             # Keine Nachfrage
Remove-UserAccount -UserName "Test"                             # FRAGT NACH

# Medium
`$ConfirmPreference = 'Medium'
Update-UserPreferences -UserName "Test" -Theme "Dark"           # Keine Nachfrage
Restart-ApplicationService -ServiceName "MyService"             # FRAGT NACH
Remove-UserAccount -UserName "Test"                             # FRAGT NACH

# Low
`$ConfirmPreference = 'Low'
# Alle drei Funktionen fragen nach

"@ -ForegroundColor White

#endregion

#region Übung 3: Clear-DatabaseTable mit ShouldContinue

function Clear-DatabaseTable {
    <#
    .SYNOPSIS
        Leert eine Datenbanktabelle mit doppelter Bestätigung.
    
    .DESCRIPTION
        Diese Funktion demonstriert die Verwendung von ShouldProcess
        und ShouldContinue für besonders kritische Operationen.
    
    .EXAMPLE
        Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users"
    
    .EXAMPLE
        Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users" -Force
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory)]
        [string]$TableName,
        
        [Parameter()]
        [switch]$Force
    )
    
    $target = "$DatabaseName.$TableName"
    $action = "TRUNCATE TABLE (delete all rows)"
    
    # Erste Ebene: Standard ShouldProcess
    if ($PSCmdlet.ShouldProcess($target, $action)) {
        
        # Simuliere Abfrage der Zeilenanzahl
        $rowCount = 42  # Get-RowCount -Database $DatabaseName -Table $TableName
        
        # Zweite Ebene: ShouldContinue für kritische Warnung
        $warningMessage = @"
ACHTUNG: DATENVERLUST!

Tabelle: $DatabaseName.$TableName
Betroffene Zeilen: $rowCount

Diese Aktion kann NICHT rückgängig gemacht werden!
Alle Daten in dieser Tabelle werden PERMANENT gelöscht.
"@
        
        $caption = "Tabelle leeren bestätigen"
        
        if ($Force -or $PSCmdlet.ShouldContinue($warningMessage, $caption)) {
            Write-Host "Lösche alle Daten aus $target..." -ForegroundColor Red
            
            # Hier würde die eigentliche Löschung stattfinden
            # Invoke-SqlQuery -Database $DatabaseName -Query "TRUNCATE TABLE $TableName"
            
            [PSCustomObject]@{
                Database = $DatabaseName
                Table = $TableName
                RowsDeleted = $rowCount
                ExecutedAt = Get-Date
                Status = 'Success'
            }
            
            Write-Host "$rowCount Zeilen wurden gelöscht." -ForegroundColor Yellow
        }
        else {
            Write-Host "Vorgang durch Benutzer abgebrochen." -ForegroundColor Yellow
        }
    }
}

# Demo/Test
Write-Host "`n=== Übung 3: Clear-DatabaseTable ===" -ForegroundColor Green
Write-Host @"

Funktion erstellt mit doppelter Bestätigung.

Testen Sie:
  Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users" -WhatIf
  Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users"        # Zwei Bestätigungen
  Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users" -Force # Eine Bestätigung

"@ -ForegroundColor Yellow

#endregion

#region Übung 4 (Bonus): Publish-WebApplication

function Publish-WebApplication {
    <#
    .SYNOPSIS
        Deployt eine Web-Anwendung mit umfassender WhatIf/Confirm-Unterstützung.
    
    .DESCRIPTION
        Vollständiges Deployment-Skript mit:
        - Unterschiedlichen ConfirmImpact-Levels je nach Environment
        - Zusätzlicher Bestätigung für Production
        - Force-Parameter für automatisierte Deployments
    
    .EXAMPLE
        Publish-WebApplication -ApplicationName "MyApp" -Environment Development -Version "1.0"
    
    .EXAMPLE
        Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0" -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ApplicationName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Development', 'Staging', 'Production')]
        [string]$Environment,
        
        [Parameter(Mandatory)]
        [string]$Version,
        
        [Parameter()]
        [switch]$BackupFirst = $true,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # ConfirmImpact dynamisch setzen (Workaround, da nicht im param-Block möglich)
        $confirmImpact = switch ($Environment) {
            'Development' { 'Low' }
            'Staging'     { 'Medium' }
            'Production'  { 'High' }
        }
        
        Write-Host @"

================================================================================
DEPLOYMENT: $ApplicationName v$Version
Environment: $Environment
ConfirmImpact: $confirmImpact
================================================================================
"@ -ForegroundColor Cyan
        
        # Deployment-Schritte definieren
        $steps = @(
            @{ Name = "Backup erstellen"; Skip = (-not $BackupFirst) }
            @{ Name = "Anwendung stoppen"; Skip = $false }
            @{ Name = "Dateien kopieren"; Skip = $false }
            @{ Name = "Konfiguration anpassen"; Skip = $false }
            @{ Name = "Anwendung starten"; Skip = $false }
            @{ Name = "Health-Check durchführen"; Skip = $false }
        )
    }
    
    process {
        # Production: Zusätzliche Warnung
        if ($Environment -eq 'Production') {
            $productionWarning = @"
⚠️ PRODUCTION DEPLOYMENT ⚠️

Sie sind dabei, auf die PRODUKTIONSUMGEBUNG zu deployen!

Anwendung: $ApplicationName
Version: $Version
Zeit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Dies kann Auswirkungen auf Live-Benutzer haben!
"@
            
            if (-not $Force -and -not $PSCmdlet.ShouldContinue($productionWarning, "Production Deployment bestätigen")) {
                Write-Host "Deployment abgebrochen." -ForegroundColor Yellow
                return
            }
        }
        
        $results = @()
        $stepNumber = 0
        
        foreach ($step in $steps) {
            if ($step.Skip) {
                Write-Verbose "Überspringe: $($step.Name)"
                continue
            }
            
            $stepNumber++
            $target = "$ApplicationName ($Environment)"
            $action = "Step $stepNumber : $($step.Name)"
            
            if ($PSCmdlet.ShouldProcess($target, $action)) {
                Write-Host "[$stepNumber/6] $($step.Name)..." -ForegroundColor Yellow
                
                # Simulierte Ausführung
                Start-Sleep -Milliseconds 500
                
                $results += [PSCustomObject]@{
                    Step = $stepNumber
                    Name = $step.Name
                    Status = 'Success'
                    Duration = "0.5s"
                }
                
                Write-Host "      ✓ Abgeschlossen" -ForegroundColor Green
            }
        }
        
        # Zusammenfassung
        if ($results.Count -gt 0) {
            Write-Host @"

================================================================================
DEPLOYMENT ABGESCHLOSSEN
================================================================================
Anwendung: $ApplicationName v$Version
Environment: $Environment
Schritte: $($results.Count) erfolgreich
Zeit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================
"@ -ForegroundColor Green
        }
        
        $results
    }
}

# Demo/Test
Write-Host "`n=== Übung 4 (Bonus): Publish-WebApplication ===" -ForegroundColor Green
Write-Host @"

Deployment-Funktion erstellt.

Testen Sie:
  # Development (Low Impact)
  Publish-WebApplication -ApplicationName "MyApp" -Environment Development -Version "1.0"

  # Staging (Medium Impact)
  Publish-WebApplication -ApplicationName "MyApp" -Environment Staging -Version "1.0"

  # Production (High Impact + ShouldContinue)
  Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0"

  # WhatIf für alle Schritte
  Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0" -WhatIf

  # Force für automatisierte Pipelines
  Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0" -Force

"@ -ForegroundColor Yellow

#endregion

#region Zusammenfassung
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALLE LÖSUNGEN GELADEN" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

Verfügbare Funktionen:
  - Remove-TempUserFiles (Übung 1)
  - Update-UserPreferences (Übung 2 - Low)
  - Restart-ApplicationService (Übung 2 - Medium)
  - Remove-UserAccount (Übung 2 - High)
  - Clear-DatabaseTable (Übung 3)
  - Publish-WebApplication (Bonus)

Alle Funktionen unterstützen -WhatIf und -Confirm!

"@ -ForegroundColor White
#endregion
