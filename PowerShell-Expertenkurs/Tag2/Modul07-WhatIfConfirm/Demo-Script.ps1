#############################################################################
# Modul 07: WhatIf und Confirm Support
# PowerShell Expertenkurs - Tag 2
#############################################################################

<#
LERNZIELE:
- SupportsShouldProcess verstehen und implementieren
- ConfirmImpact-Level korrekt setzen
- $PSCmdlet.ShouldProcess() richtig verwenden
- ShouldContinue für zusätzliche Bestätigung
- Force-Parameter implementieren

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Grundlagen SupportsShouldProcess
#############################################################################

Write-Host "=== TEIL 1: SupportsShouldProcess Grundlagen ===" -ForegroundColor Cyan

# === DEMO 1.1: Einfache Funktion mit WhatIf/Confirm ===

function Remove-OldLogFiles {
    <#
    .SYNOPSIS
        Löscht alte Log-Dateien basierend auf Alter.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [int]$DaysOld = 30
    )
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $files = Get-ChildItem -Path $Path -Filter "*.log" -File | 
        Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    foreach ($file in $files) {
        # ShouldProcess gibt Benutzer die Kontrolle
        if ($PSCmdlet.ShouldProcess($file.FullName, "Delete log file")) {
            Remove-Item -Path $file.FullName -Force
            Write-Verbose "Gelöscht: $($file.Name)"
        }
    }
}

Write-Host "Funktion Remove-OldLogFiles erstellt" -ForegroundColor Green
Write-Host "Verfügbare Parameter durch SupportsShouldProcess:" -ForegroundColor Yellow
(Get-Command Remove-OldLogFiles).Parameters.Keys | Where-Object { $_ -match 'WhatIf|Confirm' }

# Demonstration (ohne echte Ausführung)
Write-Host "`nDemo mit -WhatIf:" -ForegroundColor Yellow
Write-Host 'Remove-OldLogFiles -Path "C:\Logs" -WhatIf'
Write-Host '  Output: What if: Performing the operation "Delete log file" on target "C:\Logs\old.log"'

#endregion

#region TEIL 2: ShouldProcess mit verschiedenen Signaturen
#############################################################################

Write-Host "`n=== TEIL 2: ShouldProcess Signaturen ===" -ForegroundColor Cyan

function Set-ServerConfiguration {
    <#
    .SYNOPSIS
        Demonstriert verschiedene ShouldProcess-Aufrufvarianten.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,
        
        [Parameter()]
        [string]$Setting = "MaxConnections",
        
        [Parameter()]
        [int]$Value = 100
    )
    
    # Variante 1: Einfachste Form - nur Target
    # Output: "Performing the operation "Set-ServerConfiguration" on target "Server01""
    if ($PSCmdlet.ShouldProcess($ServerName)) {
        Write-Host "Variante 1 würde ausgeführt: $ServerName" -ForegroundColor DarkGray
    }
    
    # Variante 2: Target und Action
    # Output: "Performing the operation "Set MaxConnections=100" on target "Server01""
    if ($PSCmdlet.ShouldProcess($ServerName, "Set $Setting=$Value")) {
        Write-Host "Variante 2 würde ausgeführt: Set $Setting=$Value on $ServerName" -ForegroundColor DarkGray
    }
    
    # Variante 3: Vollständige Kontrolle (Target, Action, Warning)
    # Zeigt zusätzliche Warnung bei -Confirm
    $verboseDescription = "Setze $Setting auf $Value für Server $ServerName"
    $verboseWarning = "Dies ändert die Server-Konfiguration!"
    $caption = "Server-Konfiguration ändern"
    
    if ($PSCmdlet.ShouldProcess($verboseDescription, $verboseWarning, $caption)) {
        Write-Host "Variante 3 würde ausgeführt" -ForegroundColor DarkGray
    }
}

Write-Host "ShouldProcess Signaturen:" -ForegroundColor Yellow
Write-Host @"

1. ShouldProcess(target)
   - Einfachste Form
   - Nutzt Funktionsname als Aktion
   
2. ShouldProcess(target, action)
   - Definiert eigene Aktion
   - Bessere Beschreibung für Benutzer
   
3. ShouldProcess(verboseDescription, verboseWarning, caption)
   - Vollständige Kontrolle
   - Eigene Warnung bei -Confirm

"@ -ForegroundColor White

#endregion

#region TEIL 3: ConfirmImpact-Level
#############################################################################

Write-Host "=== TEIL 3: ConfirmImpact Level ===" -ForegroundColor Cyan

Write-Host @"

CONFIRMIMPACT LEVEL:
====================

| Level  | Beschreibung                | Confirm-Dialog wenn...        |
|--------|-----------------------------|------------------------------ |
| None   | Keine Auswirkung            | Nie (außer -Confirm)         |
| Low    | Geringe Auswirkung          | ConfirmPreference = Low      |
| Medium | Mittlere Auswirkung         | ConfirmPreference <= Medium  |
| High   | Große Auswirkung            | ConfirmPreference <= High    |

Standard ConfirmPreference: High
Das heißt: Nur bei ConfirmImpact='High' erscheint automatisch Dialog

"@ -ForegroundColor White

# === DEMO 3.1: Low Impact ===
function Update-LogLevel {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param([string]$Level = 'Info')
    
    if ($PSCmdlet.ShouldProcess("Log-Level", "Setze auf $Level")) {
        Write-Host "Log-Level gesetzt auf: $Level"
    }
}

# === DEMO 3.2: Medium Impact ===
function Restart-ApplicationPool {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([string]$PoolName)
    
    if ($PSCmdlet.ShouldProcess($PoolName, "Restart application pool")) {
        Write-Host "AppPool '$PoolName' neu gestartet"
    }
}

# === DEMO 3.3: High Impact ===
function Remove-Database {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$DatabaseName
    )
    
    if ($PSCmdlet.ShouldProcess($DatabaseName, "DELETE DATABASE PERMANENTLY")) {
        Write-Host "WARNUNG: Datenbank '$DatabaseName' wurde gelöscht!" -ForegroundColor Red
    }
}

Write-Host "Beispiel mit ConfirmImpact='High':" -ForegroundColor Yellow
Write-Host 'Remove-Database -DatabaseName "Production"'
Write-Host '  -> Zeigt automatisch Bestätigungsdialog!' -ForegroundColor Yellow

#endregion

#region TEIL 4: ShouldContinue für zusätzliche Bestätigung
#############################################################################

Write-Host "`n=== TEIL 4: ShouldContinue ===" -ForegroundColor Cyan

function Clear-AllUserData {
    <#
    .SYNOPSIS
        Löscht alle Benutzerdaten - mit doppelter Bestätigung.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter()]
        [switch]$Force
    )
    
    # Erste Ebene: Standard ShouldProcess
    if ($PSCmdlet.ShouldProcess($UserName, "Clear all user data")) {
        
        # Zweite Ebene: Zusätzliche Bestätigung für destruktive Aktion
        # ShouldContinue fragt IMMER (außer mit -Force)
        if ($Force -or $PSCmdlet.ShouldContinue(
            "Dies löscht ALLE Daten für Benutzer '$UserName' unwiderruflich!",
            "Sind Sie absolut sicher?"
        )) {
            Write-Host "Alle Daten für $UserName wurden gelöscht!" -ForegroundColor Red
        }
        else {
            Write-Host "Vorgang abgebrochen durch Benutzer" -ForegroundColor Yellow
        }
    }
}

Write-Host "ShouldContinue vs ShouldProcess:" -ForegroundColor Yellow
Write-Host @"

ShouldProcess:
  - Respektiert -WhatIf und -Confirm
  - Kann durch ConfirmPreference gesteuert werden
  - Standard für die meisten Operationen

ShouldContinue:
  - Fragt IMMER nach (außer mit -Force)
  - Für besonders kritische Operationen
  - Ignoriert ConfirmPreference
  - Sollte sparsam eingesetzt werden

Kombination:
  1. ShouldProcess für normale Bestätigung
  2. ShouldContinue für "Sind Sie wirklich sicher?"

"@ -ForegroundColor White

#endregion

#region TEIL 5: Force-Parameter richtig implementieren
#############################################################################

Write-Host "=== TEIL 5: Force-Parameter ===" -ForegroundColor Cyan

function Remove-LockedFile {
    <#
    .SYNOPSIS
        Löscht Dateien, auch wenn sie gesperrt sind.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        $file = Get-Item -Path $Path -ErrorAction SilentlyContinue
        
        if (-not $file) {
            Write-Warning "Datei nicht gefunden: $Path"
            return
        }
        
        # Prüfen ob Datei gesperrt ist
        $isLocked = $false
        try {
            $stream = [System.IO.File]::Open($Path, 'Open', 'ReadWrite', 'None')
            $stream.Close()
        }
        catch {
            $isLocked = $true
        }
        
        if ($isLocked -and -not $Force) {
            Write-Warning "Datei '$Path' ist gesperrt. Verwenden Sie -Force zum Erzwingen."
            return
        }
        
        if ($PSCmdlet.ShouldProcess($Path, "Delete file$(if ($isLocked) {' (FORCED)'})")) {
            if ($isLocked -and $Force) {
                # Prozess beenden der die Datei sperrt (vereinfacht)
                Write-Verbose "Erzwinge Löschung der gesperrten Datei..."
            }
            
            Remove-Item -Path $Path -Force -ErrorAction Stop
            Write-Verbose "Gelöscht: $Path"
        }
    }
}

Write-Host "Force-Parameter Patterns:" -ForegroundColor Yellow
Write-Host @"

1. ÜBERSCHREIBEN EXISTIERENDER DATEN:
   if (Test-Path `$Path) {
       if (-not `$Force) {
           Write-Warning "Datei existiert. -Force zum Überschreiben"
           return
       }
   }

2. UMGEHEN VON SICHERHEITSPRÜFUNGEN:
   if (`$isLocked -and -not `$Force) {
       Write-Warning "Gesperrt. -Force zum Erzwingen"
       return
   }

3. ÜBERSPRINGEN VON SHOULDCONTINUE:
   if (`$Force -or `$PSCmdlet.ShouldContinue(`$msg, `$caption)) {
       # Aktion ausführen
   }

4. UNTERDRÜCKEN VON WARNUNGEN:
   if (-not `$Force) {
       Write-Warning "Aktion könnte Probleme verursachen"
   }

"@ -ForegroundColor White

#endregion

#region TEIL 6: Praxisbeispiel - Komplette Implementierung
#############################################################################

Write-Host "`n=== TEIL 6: Praxisbeispiel ===" -ForegroundColor Cyan

function Invoke-ServerMaintenance {
    <#
    .SYNOPSIS
        Führt Wartungsarbeiten auf einem Server durch.
    
    .DESCRIPTION
        Diese Funktion demonstriert eine vollständige Implementierung
        von WhatIf, Confirm und Force für komplexe Operationen.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,
        
        [Parameter()]
        [ValidateSet('Quick', 'Standard', 'Full')]
        [string]$MaintenanceType = 'Standard',
        
        [Parameter()]
        [switch]$IncludeReboot,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Definiere Wartungsschritte
        $steps = switch ($MaintenanceType) {
            'Quick' {
                @(
                    @{ Name = "Temp-Dateien löschen"; Impact = "Low"; Action = { Write-Host "  Temp gelöscht" } }
                    @{ Name = "Log-Rotation"; Impact = "Low"; Action = { Write-Host "  Logs rotiert" } }
                )
            }
            'Standard' {
                @(
                    @{ Name = "Temp-Dateien löschen"; Impact = "Low"; Action = { Write-Host "  Temp gelöscht" } }
                    @{ Name = "Log-Rotation"; Impact = "Low"; Action = { Write-Host "  Logs rotiert" } }
                    @{ Name = "Windows-Updates prüfen"; Impact = "Medium"; Action = { Write-Host "  Updates geprüft" } }
                    @{ Name = "Dienste optimieren"; Impact = "Medium"; Action = { Write-Host "  Dienste optimiert" } }
                )
            }
            'Full' {
                @(
                    @{ Name = "Temp-Dateien löschen"; Impact = "Low"; Action = { Write-Host "  Temp gelöscht" } }
                    @{ Name = "Log-Rotation"; Impact = "Low"; Action = { Write-Host "  Logs rotiert" } }
                    @{ Name = "Windows-Updates installieren"; Impact = "High"; Action = { Write-Host "  Updates installiert" } }
                    @{ Name = "Defragmentierung"; Impact = "Medium"; Action = { Write-Host "  Defragmentiert" } }
                    @{ Name = "System-Bereinigung"; Impact = "Medium"; Action = { Write-Host "  System bereinigt" } }
                )
            }
        }
    }
    
    process {
        Write-Host "Starte Wartung für: $ServerName ($MaintenanceType)" -ForegroundColor Cyan
        
        foreach ($step in $steps) {
            # ShouldProcess für jeden Schritt
            if ($PSCmdlet.ShouldProcess("$ServerName", $step.Name)) {
                Write-Host "► $($step.Name)..." -ForegroundColor Yellow
                & $step.Action
            }
        }
        
        # Reboot mit zusätzlicher Bestätigung
        if ($IncludeReboot) {
            if ($PSCmdlet.ShouldProcess($ServerName, "REBOOT SERVER")) {
                # ShouldContinue für doppelte Bestätigung
                $continueMsg = "Server '$ServerName' wird NEU GESTARTET!`nAlle Verbindungen werden getrennt."
                
                if ($Force -or $PSCmdlet.ShouldContinue($continueMsg, "Reboot bestätigen")) {
                    Write-Host "► Server wird neu gestartet..." -ForegroundColor Red
                    # Restart-Computer -ComputerName $ServerName -Force
                }
                else {
                    Write-Host "Reboot abgebrochen" -ForegroundColor Yellow
                }
            }
        }
    }
    
    end {
        Write-Host "Wartung abgeschlossen für: $ServerName" -ForegroundColor Green
    }
}

Write-Host "Demo-Aufrufe:" -ForegroundColor Yellow
Write-Host @"

# WhatIf - Zeigt was passieren würde
Invoke-ServerMaintenance -ServerName "Server01" -MaintenanceType Full -WhatIf

# Confirm - Fragt bei jedem Schritt
Invoke-ServerMaintenance -ServerName "Server01" -MaintenanceType Standard -Confirm

# Mit Reboot und Force
Invoke-ServerMaintenance -ServerName "Server01" -IncludeReboot -Force

"@ -ForegroundColor White

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 07" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. SUPPORTSSHOULDPROCESS:
   [CmdletBinding(SupportsShouldProcess)]
   - Aktiviert -WhatIf und -Confirm Parameter
   - Standardverhalten für destruktive Funktionen

2. SHOULDPROCESS VERWENDEN:
   if (`$PSCmdlet.ShouldProcess(`$target, `$action)) {
       # Aktion ausführen
   }

3. CONFIRMIMPACT LEVEL:
   - None: Keine automatische Nachfrage
   - Low: Nachfrage bei ConfirmPreference=Low
   - Medium: Nachfrage bei ConfirmPreference≤Medium
   - High: Nachfrage bei Standard-Einstellungen

4. SHOULDCONTINUE:
   - Für kritische Aktionen mit doppelter Bestätigung
   - Fragt immer (außer mit -Force)

5. FORCE-PARAMETER:
   - Überspringt ShouldContinue
   - Erzwingt Aktionen trotz Warnungen
   - Sollte dokumentiert werden

6. BEST PRACTICES:
   - Jede destruktive Funktion: SupportsShouldProcess
   - Impact-Level passend wählen
   - Aussagekräftige Beschreibungen
   - Force nur wenn sinnvoll

"@ -ForegroundColor White

#endregion
