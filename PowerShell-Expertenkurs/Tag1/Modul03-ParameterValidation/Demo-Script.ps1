#############################################################################
# Modul 03: Parameter-Attribute und Input Validation
# PowerShell Expertenkurs - Tag 1
#############################################################################

<#
LERNZIELE:
- Parameter-Attribute verstehen und nutzen
- Verschiedene Validierungsattribute anwenden
- Eigene Validierungslogik mit ValidateScript implementieren
- Parameter Sets für komplexe Szenarien nutzen
- Dynamische Parameter erstellen

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: Grundlegende Parameter-Attribute
#############################################################################

Write-Host "=== TEIL 1: Grundlegende Parameter-Attribute ===" -ForegroundColor Cyan

# === DEMO 1.1: Das Parameter-Attribut im Detail ===

function Show-ParameterAttributes {
    [CmdletBinding()]
    param(
        # Pflichtparameter mit Position
        [Parameter(
            Mandatory = $true,           # Muss angegeben werden
            Position = 0,                # Kann ohne Namen an Position 0
            HelpMessage = "Geben Sie einen Benutzernamen ein"  # Hilfetext bei Nachfrage
        )]
        [string]$UserName,
        
        # Parameter aus Pipeline
        [Parameter(
            ValueFromPipeline = $true,   # Akzeptiert Pipeline-Input
            ValueFromPipelineByPropertyName = $true  # Auch per Property-Name
        )]
        [string]$ComputerName = $env:COMPUTERNAME,
        
        # Parameter nur in bestimmtem Parameter Set
        [Parameter(
            ParameterSetName = 'ByPath'  # Nur in diesem Set verfügbar
        )]
        [string]$Path,
        
        # Parameter mit Alias
        [Parameter()]
        [Alias('v', 'ver')]              # Kurzformen für den Parameter
        [string]$Version
    )
    
    Write-Host "UserName: $UserName"
    Write-Host "ComputerName: $ComputerName"
    Write-Host "Path: $Path"
    Write-Host "Version: $Version"
}

# Demonstration
Write-Host "`nTest mit positionellem Parameter:" -ForegroundColor Yellow
Show-ParameterAttributes "JohnDoe"

Write-Host "`nTest mit Alias:" -ForegroundColor Yellow
Show-ParameterAttributes -UserName "Jane" -v "1.0"


# === DEMO 1.2: DontShow - Versteckte Parameter ===
Write-Host "`n=== DEMO 1.2: Versteckte Parameter ===" -ForegroundColor Cyan

function Get-SecretConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigName = "Default",
        
        # Dieser Parameter wird in Tab-Completion nicht angezeigt
        [Parameter(DontShow)]
        [string]$InternalDebugMode = "Off"
    )
    
    Write-Verbose "Debug Mode: $InternalDebugMode"
    Write-Output "Config: $ConfigName"
}

Write-Host "Parameter der Funktion (InternalDebugMode ist versteckt):" -ForegroundColor Yellow
(Get-Command Get-SecretConfig).Parameters.Keys

#endregion

#region TEIL 2: Validierungsattribute
#############################################################################

Write-Host "`n=== TEIL 2: Validierungsattribute ===" -ForegroundColor Cyan

# === DEMO 2.1: ValidateSet - Feste Werteliste ===

function Set-LogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Debug', 'Info', 'Warning', 'Error', 'Critical')]
        [string]$Level
    )
    
    Write-Host "Log-Level gesetzt auf: $Level" -ForegroundColor Green
}

# Test - Tab-Completion zeigt die Optionen!
Write-Host "Test ValidateSet:" -ForegroundColor Yellow
Set-LogLevel -Level "Info"

# Ungültiger Wert würde Fehler auslösen:
# Set-LogLevel -Level "Trace"  # Fehler!


# === DEMO 2.2: ValidateRange - Wertebereich ===

function Set-RetryCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 10)]
        [int]$Count,
        
        [Parameter()]
        [ValidateRange('Positive')]  # PowerShell 6+: Positive, Negative, NonNegative, NonPositive
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "Retry Count: $Count, Timeout: $TimeoutSeconds" -ForegroundColor Green
}

Write-Host "`nTest ValidateRange:" -ForegroundColor Yellow
Set-RetryCount -Count 5 -TimeoutSeconds 60


# === DEMO 2.3: ValidateLength und ValidateCount ===

function New-UserAccount {
    [CmdletBinding()]
    param(
        # String-Länge validieren
        [Parameter(Mandatory)]
        [ValidateLength(3, 20)]  # Min 3, Max 20 Zeichen
        [string]$UserName,
        
        # Array-Größe validieren
        [Parameter()]
        [ValidateCount(1, 5)]    # Min 1, Max 5 Einträge
        [string[]]$Groups = @('Users')
    )
    
    Write-Host "User: $UserName, Groups: $($Groups -join ', ')" -ForegroundColor Green
}

Write-Host "`nTest ValidateLength/ValidateCount:" -ForegroundColor Yellow
New-UserAccount -UserName "JohnDoe" -Groups "Users", "Admins"


# === DEMO 2.4: ValidatePattern - Regex-Validierung ===

function Send-Email {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[\w\.-]+@[\w\.-]+\.\w{2,}$')]
        [string]$EmailAddress,
        
        # IP-Adresse validieren
        [Parameter()]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')]
        [string]$SmtpServer = "127.0.0.1"
    )
    
    Write-Host "Sending to: $EmailAddress via $SmtpServer" -ForegroundColor Green
}

Write-Host "`nTest ValidatePattern:" -ForegroundColor Yellow
Send-Email -EmailAddress "user@example.com"


# === DEMO 2.5: ValidateScript - Eigene Validierungslogik ===

function Copy-ToFolder {
    [CmdletBinding()]
    param(
        # Prüfen ob Datei existiert
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path $_ -PathType Leaf) { $true }
            else { throw "Die Datei '$_' existiert nicht!" }
        })]
        [string]$SourceFile,
        
        # Prüfen ob Ordner existiert UND beschreibbar ist
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Der Ordner '$_' existiert nicht!"
            }
            
            # Schreibtest
            $testFile = Join-Path $_ ([guid]::NewGuid().ToString())
            try {
                [IO.File]::Create($testFile).Close()
                Remove-Item $testFile -Force
                $true
            }
            catch {
                throw "Der Ordner '$_' ist nicht beschreibbar!"
            }
        })]
        [string]$DestinationFolder
    )
    
    Write-Host "Kopiere $SourceFile nach $DestinationFolder" -ForegroundColor Green
}

Write-Host "`nTest ValidateScript:" -ForegroundColor Yellow
# Erstellen einer Testdatei
$testFile = Join-Path $env:TEMP "testfile.txt"
"Test" | Out-File $testFile
Copy-ToFolder -SourceFile $testFile -DestinationFolder $env:TEMP
Remove-Item $testFile -Force


# === DEMO 2.6: ValidateNotNull und ValidateNotNullOrEmpty ===

function Process-Data {
    [CmdletBinding()]
    param(
        # Darf nicht $null sein (leerer String OK)
        [Parameter()]
        [ValidateNotNull()]
        [object]$Data = @{},
        
        # Darf weder $null noch leer sein
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProcessName
    )
    
    Write-Host "Processing: $ProcessName with data type $($Data.GetType().Name)" -ForegroundColor Green
}

Write-Host "`nTest ValidateNotNull/ValidateNotNullOrEmpty:" -ForegroundColor Yellow
Process-Data -ProcessName "MyProcess" -Data @{Key="Value"}

#endregion

#region TEIL 3: ArgumentCompleter - Dynamische Tab-Completion
#############################################################################

Write-Host "`n=== TEIL 3: ArgumentCompleter ===" -ForegroundColor Cyan

# === DEMO 3.1: ArgumentCompleter-Attribut ===

function Get-ServiceByStatus {
    [CmdletBinding()]
    param(
        # Dynamische Completion basierend auf echten Service-Namen
        [Parameter(Mandatory)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            Get-Service | 
                Where-Object Name -like "$wordToComplete*" |
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new(
                        $_.Name,                    # CompletionText
                        $_.Name,                    # ListItemText
                        'ParameterValue',           # ResultType
                        $_.DisplayName              # ToolTip
                    )
                }
        })]
        [string]$ServiceName,
        
        [Parameter()]
        [ValidateSet('Running', 'Stopped')]
        [string]$Status
    )
    
    $svc = Get-Service -Name $ServiceName
    if ($Status) {
        if ($svc.Status -eq $Status) {
            $svc
        } else {
            Write-Warning "Service $ServiceName ist nicht im Status $Status"
        }
    } else {
        $svc
    }
}

Write-Host "Funktion mit ArgumentCompleter erstellt." -ForegroundColor Yellow
Write-Host "Tippen Sie: Get-ServiceByStatus -ServiceName Sp<TAB>" -ForegroundColor Yellow


# === DEMO 3.2: Register-ArgumentCompleter (Global) ===

# Completion für alle -ComputerName Parameter registrieren
Register-ArgumentCompleter -ParameterName ComputerName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Beispiel: Computer aus einer Datei/AD laden
    @('Server01', 'Server02', 'DC01', 'DC02', 'WebServer', 'DBServer') |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Write-Host "`nGlobaler ArgumentCompleter für -ComputerName registriert" -ForegroundColor Yellow

#endregion

#region TEIL 4: Parameter Sets
#############################################################################

Write-Host "`n=== TEIL 4: Parameter Sets ===" -ForegroundColor Cyan

# === DEMO 4.1: Einfache Parameter Sets ===

function Get-UserInfo {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string]$Name,
        
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [int]$Id,
        
        [Parameter(Mandatory, ParameterSetName = 'ByEmail')]
        [ValidatePattern('^[\w\.-]+@[\w\.-]+\.\w{2,}$')]
        [string]$Email,
        
        # Dieser Parameter ist in allen Sets verfügbar
        [Parameter()]
        [switch]$Detailed
    )
    
    Write-Host "Verwendetes ParameterSet: $($PSCmdlet.ParameterSetName)" -ForegroundColor Green
    Write-Host "Detailed: $Detailed" -ForegroundColor Green
    
    switch ($PSCmdlet.ParameterSetName) {
        'ByName'  { Write-Host "Suche User mit Namen: $Name" }
        'ById'    { Write-Host "Suche User mit ID: $Id" }
        'ByEmail' { Write-Host "Suche User mit Email: $Email" }
    }
}

Write-Host "Syntax der Funktion:" -ForegroundColor Yellow
Get-Command Get-UserInfo -Syntax

Write-Host "`nTest Parameter Sets:" -ForegroundColor Yellow
Get-UserInfo -Name "John"
Get-UserInfo -Id 42 -Detailed
Get-UserInfo -Email "john@example.com"


# === DEMO 4.2: Parameter in mehreren Sets ===

function Export-Report {
    [CmdletBinding(DefaultParameterSetName = 'ToFile')]
    param(
        [Parameter(Mandatory)]
        [string]$ReportName,
        
        # In beiden Sets, aber mit unterschiedlichen Eigenschaften
        [Parameter(Mandatory, ParameterSetName = 'ToFile')]
        [Parameter(ParameterSetName = 'ToEmail')]  # Optional in Email
        [string]$Path,
        
        [Parameter(Mandatory, ParameterSetName = 'ToEmail')]
        [string]$EmailTo,
        
        [Parameter(ParameterSetName = 'ToEmail')]
        [string]$Subject = "Report: $ReportName"
    )
    
    Write-Host "ParameterSet: $($PSCmdlet.ParameterSetName)" -ForegroundColor Green
    
    switch ($PSCmdlet.ParameterSetName) {
        'ToFile' {
            Write-Host "Exportiere '$ReportName' nach: $Path"
        }
        'ToEmail' {
            Write-Host "Sende '$ReportName' an: $EmailTo"
            if ($Path) { Write-Host "Mit Anhang: $Path" }
        }
    }
}

Write-Host "`nTest Export-Report:" -ForegroundColor Yellow
Export-Report -ReportName "Monatsbericht" -Path "C:\Reports\report.csv"
Export-Report -ReportName "Alert" -EmailTo "admin@company.com"

#endregion

#region TEIL 5: Fortgeschrittene Validierung
#############################################################################

Write-Host "`n=== TEIL 5: Fortgeschrittene Validierung ===" -ForegroundColor Cyan

# === DEMO 5.1: Eigene Validierungsklasse ===

class ValidateFileExtensionAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string[]]$AllowedExtensions
    
    ValidateFileExtensionAttribute([string[]]$extensions) {
        $this.AllowedExtensions = $extensions
    }
    
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $path = $arguments -as [string]
        $extension = [System.IO.Path]::GetExtension($path)
        
        if ($extension -notin $this.AllowedExtensions) {
            throw "Die Dateiendung '$extension' ist nicht erlaubt. Erlaubt sind: $($this.AllowedExtensions -join ', ')"
        }
    }
}

function Import-DataFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateFileExtension('.csv', '.json', '.xml')]
        [string]$FilePath
    )
    
    Write-Host "Importiere: $FilePath" -ForegroundColor Green
}

Write-Host "Test eigene Validierungsklasse:" -ForegroundColor Yellow
Import-DataFile -FilePath "data.csv"
# Import-DataFile -FilePath "data.txt"  # Würde Fehler werfen


# === DEMO 5.2: Kombinierte Validierung ===

function New-SecurePassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateLength(12, 128)]
        [ValidateScript({
            $hasUpper = $_ -cmatch '[A-Z]'
            $hasLower = $_ -cmatch '[a-z]'
            $hasDigit = $_ -match '\d'
            $hasSpecial = $_ -match '[!@#$%^&*()_+{}|:<>?]'
            
            if (-not ($hasUpper -and $hasLower -and $hasDigit -and $hasSpecial)) {
                throw @"
Passwort muss enthalten:
- Mindestens einen Großbuchstaben
- Mindestens einen Kleinbuchstaben  
- Mindestens eine Ziffer
- Mindestens ein Sonderzeichen (!@#$%^&*()_+{}|:<>?)
"@
            }
            $true
        })]
        [string]$Password
    )
    
    # In der Praxis würde hier SecureString verwendet
    Write-Host "Passwort validiert und akzeptiert!" -ForegroundColor Green
}

Write-Host "`nTest kombinierte Validierung:" -ForegroundColor Yellow
New-SecurePassword -Password "MySecure123!Pass"

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 03" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. PARAMETER-ATTRIBUT:
   [Parameter(
       Mandatory,
       Position = 0,
       ValueFromPipeline,
       ValueFromPipelineByPropertyName,
       ParameterSetName = 'SetName',
       HelpMessage = "Hilfetext"
   )]

2. VALIDIERUNGSATTRIBUTE:
   - [ValidateSet('A', 'B', 'C')]     - Feste Werteliste
   - [ValidateRange(1, 100)]          - Zahlenbereich
   - [ValidateLength(3, 20)]          - String-Länge
   - [ValidateCount(1, 5)]            - Array-Größe
   - [ValidatePattern('regex')]        - Regex-Muster
   - [ValidateScript({ ... })]        - Eigene Logik
   - [ValidateNotNull()]              - Nicht null
   - [ValidateNotNullOrEmpty()]       - Nicht null/leer

3. TAB-COMPLETION:
   - [ArgumentCompleter({ ... })]     - Pro Parameter
   - Register-ArgumentCompleter       - Global

4. PARAMETER SETS:
   - DefaultParameterSetName definieren
   - `$PSCmdlet.ParameterSetName abfragen
   - Parameter können in mehreren Sets sein

5. BEST PRACTICES:
   - Immer validieren wo möglich
   - Aussagekräftige Fehlermeldungen
   - ArgumentCompleter für UX
   - Sinnvolle Default-Werte

"@ -ForegroundColor White

#endregion
