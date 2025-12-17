#############################################################################
# Modul 09: Fehlerbehandlung in Skripten
# PowerShell Expertenkurs - Tag 3
#############################################################################

<#
LERNZIELE:
- Try/Catch/Finally verstehen und einsetzen
- ErrorAction und ErrorVariable nutzen
- Terminating vs Non-Terminating Errors unterscheiden
- $Error und $? verwenden
- Eigene Fehler werfen
- Error Records analysieren

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Grundlagen - Error Types
#############################################################################

Write-Host "=== TEIL 1: Error Types ===" -ForegroundColor Cyan

Write-Host @"

ZWEI ARTEN VON FEHLERN IN POWERSHELL:
=====================================

1. NON-TERMINATING ERRORS:
   - Standardverhalten der meisten Cmdlets
   - Skript läuft weiter
   - Wird zu `$Error` hinzugefügt
   - Beispiel: Datei nicht gefunden bei Get-ChildItem

2. TERMINATING ERRORS:
   - Stoppt die Ausführung
   - Wird von Try/Catch abgefangen
   - Beispiel: Ungültige Syntax, Throw-Statement

WICHTIG: Try/Catch fängt NUR terminating errors!

"@ -ForegroundColor White

# Demo: Non-Terminating Error
Write-Host "Demo: Non-Terminating Error" -ForegroundColor Yellow
Get-ChildItem -Path "C:\NichtExistent" -ErrorAction SilentlyContinue
Write-Host "Diese Zeile wird trotz Fehler ausgeführt!" -ForegroundColor Green

# Demo: $ErrorActionPreference
Write-Host "`nErrorActionPreference Werte:" -ForegroundColor Yellow
Write-Host @"
  Continue     - Fehler anzeigen, weitermachen (Standard)
  Stop         - In Terminating Error umwandeln
  SilentlyContinue - Fehler unterdrücken, weitermachen
  Ignore       - Komplett ignorieren (nicht mal in `$Error)
  Inquire      - Benutzer fragen
  Suspend      - Nur in Workflows
"@

#endregion

#region TEIL 2: Try/Catch/Finally
#############################################################################

Write-Host "`n=== TEIL 2: Try/Catch/Finally ===" -ForegroundColor Cyan

# === DEMO 2.1: Einfaches Try/Catch ===
Write-Host "`nDemo: Einfaches Try/Catch" -ForegroundColor Yellow

function Get-FileContentSafe {
    param([string]$Path)
    
    try {
        # ErrorAction Stop macht Non-Terminating zu Terminating
        $content = Get-Content -Path $Path -ErrorAction Stop
        return $content
    }
    catch {
        Write-Warning "Datei konnte nicht gelesen werden: $Path"
        Write-Warning "Fehler: $($_.Exception.Message)"
        return $null
    }
}

Get-FileContentSafe -Path "C:\NichtExistent.txt"

# === DEMO 2.2: Catch mit Fehlertypen ===
Write-Host "`nDemo: Catch mit spezifischen Fehlertypen" -ForegroundColor Yellow

function Test-ErrorTypes {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FileNotFound', 'InvalidOperation', 'Generic')]
        [string]$ErrorType
    )
    
    try {
        switch ($ErrorType) {
            'FileNotFound' {
                Get-Item "C:\NichtExistent\Datei.txt" -ErrorAction Stop
            }
            'InvalidOperation' {
                throw [System.InvalidOperationException]::new("Ungültige Operation!")
            }
            'Generic' {
                throw "Allgemeiner Fehler"
            }
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host "CATCH: Datei/Pfad nicht gefunden" -ForegroundColor Yellow
    }
    catch [System.InvalidOperationException] {
        Write-Host "CATCH: Ungültige Operation" -ForegroundColor Red
    }
    catch {
        Write-Host "CATCH: Allgemeiner Fehler: $($_.Exception.Message)" -ForegroundColor Magenta
    }
    finally {
        Write-Host "FINALLY: Wird immer ausgeführt!" -ForegroundColor Cyan
    }
}

Test-ErrorTypes -ErrorType FileNotFound
Test-ErrorTypes -ErrorType InvalidOperation
Test-ErrorTypes -ErrorType Generic

#endregion

#region TEIL 3: ErrorAction und ErrorVariable
#############################################################################

Write-Host "`n=== TEIL 3: ErrorAction und ErrorVariable ===" -ForegroundColor Cyan

# === DEMO 3.1: ErrorAction Parameter ===
Write-Host "`nDemo: ErrorAction Parameter" -ForegroundColor Yellow

function Process-MultipleFiles {
    param([string[]]$Paths)
    
    $results = @()
    
    foreach ($path in $Paths) {
        # Mit -ErrorAction Continue: Zeigt Fehler, macht weiter
        # Mit -ErrorAction SilentlyContinue: Keine Fehlermeldung
        # Mit -ErrorAction Stop: Wirft Exception
        
        $content = Get-Content -Path $path -ErrorAction SilentlyContinue -ErrorVariable fileError
        
        if ($fileError) {
            Write-Warning "Problem mit $path"
            $results += [PSCustomObject]@{
                Path = $path
                Status = "Error"
                Error = $fileError[0].Exception.Message
            }
        }
        else {
            $results += [PSCustomObject]@{
                Path = $path
                Status = "OK"
                Lines = $content.Count
            }
        }
    }
    
    return $results
}

# === DEMO 3.2: ErrorVariable ===
Write-Host "`nDemo: ErrorVariable" -ForegroundColor Yellow

$testPaths = @(
    "$env:WINDIR\System32\drivers\etc\hosts",
    "C:\NichtExistent.txt",
    "$env:WINDIR\System32\config\SAM"  # Zugriff verweigert
)

$results = Process-MultipleFiles -Paths $testPaths
$results | Format-Table

#endregion

#region TEIL 4: $Error Variable und Error Records
#############################################################################

Write-Host "`n=== TEIL 4: `$Error und Error Records ===" -ForegroundColor Cyan

# $Error leeren für Demo
$Error.Clear()

# Einige Fehler produzieren
Get-Item "C:\Nicht1.txt" -ErrorAction SilentlyContinue
Get-Item "C:\Nicht2.txt" -ErrorAction SilentlyContinue
Get-Service "NichtExistierenderDienst" -ErrorAction SilentlyContinue

Write-Host "Fehler in `$Error: $($Error.Count)" -ForegroundColor Yellow

# Error Record analysieren
if ($Error.Count -gt 0) {
    $lastError = $Error[0]
    
    Write-Host "`nLetzter Fehler analysiert:" -ForegroundColor Yellow
    Write-Host @"
    
    Exception Type: $($lastError.Exception.GetType().FullName)
    Message:        $($lastError.Exception.Message)
    
    Target Object:  $($lastError.TargetObject)
    Category:       $($lastError.CategoryInfo.Category)
    Activity:       $($lastError.CategoryInfo.Activity)
    
    Script:         $($lastError.InvocationInfo.ScriptName)
    Line:           $($lastError.InvocationInfo.ScriptLineNumber)
    Command:        $($lastError.InvocationInfo.MyCommand)
"@
}

# $? (Letzter Befehl erfolgreich?)
Write-Host "`n`$? Variable:" -ForegroundColor Yellow
Get-Process "explorer" | Out-Null
Write-Host "Nach Get-Process explorer: `$? = $?"

Get-Process "NichtExistent" -ErrorAction SilentlyContinue
Write-Host "Nach Get-Process NichtExistent: `$? = $?"

#endregion

#region TEIL 5: Eigene Fehler werfen
#############################################################################

Write-Host "`n=== TEIL 5: Eigene Fehler werfen ===" -ForegroundColor Cyan

# === DEMO 5.1: throw Statement ===
Write-Host "`nDemo: throw Statement" -ForegroundColor Yellow

function Test-ThrowMethods {
    param([int]$Method)
    
    try {
        switch ($Method) {
            1 {
                # Einfaches throw
                throw "Ein einfacher Fehler"
            }
            2 {
                # throw mit Exception-Objekt
                throw [System.ArgumentException]::new("Ungültiges Argument", "Method")
            }
            3 {
                # Write-Error mit -ErrorAction Stop
                Write-Error "Fehler via Write-Error" -ErrorAction Stop
            }
            4 {
                # $PSCmdlet.ThrowTerminatingError()
                $exception = [System.InvalidOperationException]::new("Kritischer Fehler!")
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    "CustomErrorId",
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                throw $errorRecord
            }
        }
    }
    catch {
        Write-Host "Gefangen: $($_.Exception.GetType().Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

1..4 | ForEach-Object { 
    Write-Host "Method $_:" -ForegroundColor Yellow
    Test-ThrowMethods -Method $_
}

# === DEMO 5.2: Professionelle Fehlerbehandlung in Funktionen ===
Write-Host "`nDemo: Professionelle Fehlerbehandlung" -ForegroundColor Yellow

function Get-ServerStatus {
    <#
    .SYNOPSIS
        Ruft Server-Status ab mit professioneller Fehlerbehandlung.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ComputerName,
        
        [Parameter()]
        [int]$TimeoutSeconds = 5
    )
    
    begin {
        $results = @()
    }
    
    process {
        Write-Verbose "Prüfe Server: $ComputerName"
        
        try {
            # Validierung
            if ([string]::IsNullOrWhiteSpace($ComputerName)) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new("ComputerName darf nicht leer sein"),
                        "EmptyComputerName",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $ComputerName
                    )
                )
            }
            
            # Ping-Test
            $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop
            
            $results += [PSCustomObject]@{
                ComputerName = $ComputerName
                Status = "Online"
                ResponseTime = $pingResult.Latency
                Timestamp = Get-Date
            }
        }
        catch [System.Net.NetworkInformation.PingException] {
            # Spezifischer Catch für Netzwerkfehler
            Write-Warning "Netzwerkfehler für $ComputerName : Host nicht erreichbar"
            
            $results += [PSCustomObject]@{
                ComputerName = $ComputerName
                Status = "Offline"
                ResponseTime = $null
                Timestamp = Get-Date
            }
        }
        catch [System.ArgumentException] {
            # Re-throw von Validierungsfehlern
            throw
        }
        catch {
            # Allgemeiner Catch
            Write-Warning "Unbekannter Fehler für $ComputerName : $_"
            
            $results += [PSCustomObject]@{
                ComputerName = $ComputerName
                Status = "Error"
                ResponseTime = $null
                Timestamp = Get-Date
            }
        }
    }
    
    end {
        return $results
    }
}

# Test
@("localhost", "192.168.1.254", "server01.domain.local") | Get-ServerStatus | Format-Table

#endregion

#region TEIL 6: Best Practices
#############################################################################

Write-Host "`n=== TEIL 6: Best Practices ===" -ForegroundColor Cyan

Write-Host @"

BEST PRACTICES FÜR FEHLERBEHANDLUNG:
====================================

1. IMMER -ERRORACTION STOP in Try-Blöcken:
   try {
       Get-Something -ErrorAction Stop
   }

2. SPEZIFISCHE EXCEPTIONS ZUERST FANGEN:
   catch [FileNotFoundException] { }
   catch [UnauthorizedAccessException] { }
   catch { }  # Allgemeiner Catch zuletzt

3. FINALLY FÜR CLEANUP:
   try { Open-Resource }
   finally { Close-Resource }

4. FEHLER LOGGEN:
   catch {
       Write-Log -Level Error -Message `$_.Exception.Message
       throw  # Re-throw wenn nötig
   }

5. AUSSAGEKRÄFTIGE FEHLERMELDUNGEN:
   throw "Konfigurationsdatei nicht gefunden: `$configPath"

6. `$ERRORACTIONPREFERENCE FÜR SKRIPTE:
   `$ErrorActionPreference = 'Stop'  # Am Skript-Anfang

7. VALIDIERUNG VOR AKTIONEN:
   if (-not (Test-Path `$path)) {
       throw "Pfad existiert nicht: `$path"
   }

8. TRANSAKTIONALE OPERATIONEN:
   try {
       Start-Transaction
       # Mehrere Operationen
       Complete-Transaction
   }
   catch {
       Undo-Transaction
       throw
   }

"@ -ForegroundColor White

# Beispiel: Robuste Funktion
function Invoke-RobustOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Skript-weite Fehlerbehandlung
    $originalErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    
    try {
        # Validierung
        if (-not (Test-Path $InputPath)) {
            throw "Input-Datei nicht gefunden: $InputPath"
        }
        
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Hauptoperation
        $data = Get-Content -Path $InputPath
        $processed = $data | ForEach-Object { $_.ToUpper() }
        $processed | Set-Content -Path $OutputPath
        
        Write-Verbose "Erfolgreich: $InputPath -> $OutputPath"
        return $true
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Zugriff verweigert: $_"
        return $false
    }
    catch {
        Write-Error "Unerwarteter Fehler: $_"
        return $false
    }
    finally {
        $ErrorActionPreference = $originalErrorAction
        Write-Verbose "Cleanup abgeschlossen"
    }
}

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 09" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. ERROR TYPES:
   - Non-Terminating: Läuft weiter
   - Terminating: Stoppt Ausführung
   - -ErrorAction Stop konvertiert

2. TRY/CATCH/FINALLY:
   try { Risikoreicher Code }
   catch [SpecificException] { Spezifisch }
   catch { Allgemein }
   finally { Cleanup }

3. ERRORACTION WERTE:
   Continue, Stop, SilentlyContinue,
   Ignore, Inquire

4. `$ERROR VARIABLE:
   - Array aller Fehler
   - `$Error[0] = letzter Fehler
   - `$Error.Clear() zum Leeren

5. EIGENE FEHLER:
   throw "Message"
   throw [ExceptionType]::new("Message")
   `$PSCmdlet.ThrowTerminatingError()

6. `$? VARIABLE:
   - `$true wenn letzter Befehl OK
   - `$false bei Fehler

"@ -ForegroundColor White

#endregion
