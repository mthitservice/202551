#############################################################################
# Modul 03: Parameter-Attribute und Input Validation - LÖSUNGEN
# PowerShell Expertenkurs - Tag 1
#############################################################################

#region LÖSUNG AUFGABE 1: New-ServerConfig
#############################################################################

Write-Host "=== LÖSUNG AUFGABE 1: New-ServerConfig ===" -ForegroundColor Cyan

function New-ServerConfig {
    <#
    .SYNOPSIS
        Erstellt eine neue Server-Konfiguration mit validierter Eingabe.
    .DESCRIPTION
        Diese Funktion demonstriert verschiedene Validierungsattribute
        für Parameter-Validierung in PowerShell.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        # ServerName: 3-15 Zeichen, alphanumerisch + Bindestrich, nicht am Anfang/Ende
        [Parameter(Mandatory, Position = 0)]
        [ValidateLength(3, 15)]
        [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]{1,2}$',
            ErrorMessage = "ServerName muss 3-15 Zeichen sein, nur Buchstaben/Zahlen/Bindestriche, nicht mit Bindestrich beginnen/enden")]
        [string]$ServerName,
        
        # Environment: Feste Werteliste
        [Parameter(Mandatory, Position = 1)]
        [ValidateSet('Development', 'Test', 'Staging', 'Production')]
        [string]$Environment,
        
        # Port: Bereich 1-65535
        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,
        
        # IPAddress: IPv4-Format
        [Parameter()]
        [ValidatePattern('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
            ErrorMessage = "IPAddress muss im Format x.x.x.x sein (0-255 pro Oktett)")]
        [string]$IPAddress,
        
        # Tags: 0-10 Einträge
        [Parameter()]
        [ValidateCount(0, 10)]
        [string[]]$Tags = @()
    )
    
    Write-Verbose "Erstelle Server-Konfiguration für: $ServerName"
    
    [PSCustomObject]@{
        ServerName = $ServerName
        Environment = $Environment
        Port = $Port
        IPAddress = if ($IPAddress) { $IPAddress } else { 'Auto' }
        Tags = $Tags
        CreatedAt = Get-Date
    }
}

# Tests
Write-Host "`nGültige Aufrufe:" -ForegroundColor Green
New-ServerConfig -ServerName "web-server-01" -Environment Production -Port 8080 -Verbose
New-ServerConfig -ServerName "db01" -Environment Test -IPAddress "192.168.1.100"
New-ServerConfig -ServerName "app" -Environment Development -Tags "web", "frontend"

Write-Host "`nUngültige Aufrufe (Fehler erwartet):" -ForegroundColor Red
try { New-ServerConfig -ServerName "ab" -Environment Production } 
catch { Write-Host "  Fehler: Zu kurz - $_" -ForegroundColor Yellow }

try { New-ServerConfig -ServerName "-invalid" -Environment Test }
catch { Write-Host "  Fehler: Ungültiges Format - $_" -ForegroundColor Yellow }

try { New-ServerConfig -ServerName "server" -Environment "Live" }
catch { Write-Host "  Fehler: Ungültige Umgebung - $_" -ForegroundColor Yellow }

try { New-ServerConfig -ServerName "server" -Environment Test -Port 70000 }
catch { Write-Host "  Fehler: Port außerhalb Bereich - $_" -ForegroundColor Yellow }

#endregion

#region LÖSUNG AUFGABE 2: Backup-Database
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 2: Backup-Database ===" -ForegroundColor Cyan

function Backup-Database {
    <#
    .SYNOPSIS
        Sichert eine Datenbank mit komplexer Validierung.
    .DESCRIPTION
        Demonstriert ValidateScript für komplexe Validierungslogik.
    #>
    [CmdletBinding()]
    param(
        # DatabasePath: Existiert, richtige Endung, unter 10GB
        [Parameter(Mandatory)]
        [ValidateScript({
            # Existenz prüfen
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "Die Datenbank-Datei '$_' existiert nicht!"
            }
            
            # Endung prüfen
            $extension = [System.IO.Path]::GetExtension($_).ToLower()
            if ($extension -notin @('.mdf', '.bak')) {
                throw "Die Datei muss die Endung .mdf oder .bak haben, nicht '$extension'"
            }
            
            # Größe prüfen (10GB = 10737418240 Bytes)
            $size = (Get-Item $_).Length
            $maxSize = 10GB
            if ($size -gt $maxSize) {
                $sizeGB = [math]::Round($size / 1GB, 2)
                throw "Die Datei ist $sizeGB GB groß. Maximum sind 10 GB!"
            }
            
            $true
        })]
        [string]$DatabasePath,
        
        # BackupFolder: Existiert, 5GB frei, beschreibbar
        [Parameter(Mandatory)]
        [ValidateScript({
            # Existenz prüfen
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Der Backup-Ordner '$_' existiert nicht!"
            }
            
            # Freien Speicherplatz prüfen
            $drive = (Get-Item $_).PSDrive.Name
            $freeSpace = (Get-PSDrive $drive).Free
            $minFreeSpace = 5GB
            if ($freeSpace -lt $minFreeSpace) {
                $freeGB = [math]::Round($freeSpace / 1GB, 2)
                throw "Nur $freeGB GB frei. Mindestens 5 GB erforderlich!"
            }
            
            # Schreibrechte prüfen
            $testFile = Join-Path $_ "write_test_$([guid]::NewGuid()).tmp"
            try {
                [IO.File]::Create($testFile).Close()
                Remove-Item $testFile -Force
            }
            catch {
                throw "Keine Schreibrechte auf '$_'!"
            }
            
            $true
        })]
        [string]$BackupFolder,
        
        # RetentionDays: 7-365, durch 7 teilbar
        [Parameter()]
        [ValidateRange(7, 365)]
        [ValidateScript({
            if ($_ % 7 -ne 0) {
                throw "RetentionDays muss durch 7 teilbar sein (für wöchentliche Rotation). '$_' ist nicht durch 7 teilbar!"
            }
            $true
        })]
        [int]$RetentionDays = 28,
        
        # CompressionLevel
        [Parameter()]
        [ValidateSet('None', 'Fast', 'Normal', 'Maximum')]
        [string]$CompressionLevel = 'Normal',
        
        # NotifyEmail: Gültiges Format, erfordert SmtpServer
        [Parameter()]
        [ValidateScript({
            if ($_ -notmatch '^[\w\.-]+@[\w\.-]+\.\w{2,}$') {
                throw "'$_' ist keine gültige E-Mail-Adresse!"
            }
            $true
        })]
        [string]$NotifyEmail,
        
        # SmtpServer
        [Parameter()]
        [string]$SmtpServer
    )
    
    # Abhängigkeits-Validierung: NotifyEmail erfordert SmtpServer
    if ($NotifyEmail -and -not $SmtpServer) {
        throw "Wenn -NotifyEmail angegeben ist, muss auch -SmtpServer angegeben werden!"
    }
    
    # SmtpServer-Erreichbarkeit prüfen (wenn angegeben)
    if ($SmtpServer) {
        Write-Verbose "Prüfe SMTP-Server Erreichbarkeit..."
        if (-not (Test-Connection -ComputerName $SmtpServer -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Warning "SMTP-Server '$SmtpServer' nicht erreichbar. Backup wird trotzdem durchgeführt."
        }
    }
    
    Write-Verbose "Starte Backup von: $DatabasePath"
    Write-Verbose "Ziel: $BackupFolder"
    Write-Verbose "Retention: $RetentionDays Tage"
    Write-Verbose "Kompression: $CompressionLevel"
    
    [PSCustomObject]@{
        DatabasePath = $DatabasePath
        BackupFolder = $BackupFolder
        RetentionDays = $RetentionDays
        CompressionLevel = $CompressionLevel
        NotifyEmail = $NotifyEmail
        SmtpServer = $SmtpServer
        BackupTime = Get-Date
        Status = 'Simulated'
    }
}

# Test mit simulierten Dateien
Write-Host "`nErstelle Test-Dateien..." -ForegroundColor Yellow
$testDbPath = Join-Path $env:TEMP "testdb.mdf"
"Test Database Content" | Out-File $testDbPath

Write-Host "Test gültiger Aufruf:" -ForegroundColor Green
Backup-Database -DatabasePath $testDbPath -BackupFolder $env:TEMP -RetentionDays 21 -Verbose

Write-Host "`nTest ungültiger RetentionDays:" -ForegroundColor Red
try { Backup-Database -DatabasePath $testDbPath -BackupFolder $env:TEMP -RetentionDays 25 }
catch { Write-Host "  Fehler: $_" -ForegroundColor Yellow }

# Aufräumen
Remove-Item $testDbPath -Force -ErrorAction SilentlyContinue

#endregion

#region LÖSUNG AUFGABE 3: Get-AuditLog
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 3: Get-AuditLog ===" -ForegroundColor Cyan

function Get-AuditLog {
    <#
    .SYNOPSIS
        Ruft Audit-Logs mit verschiedenen Suchoptionen ab.
    .DESCRIPTION
        Demonstriert die Verwendung von Parameter Sets.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByTimeRange')]
    [OutputType([PSCustomObject])]
    param(
        # ByTimeRange Parameter Set
        [Parameter(Mandatory, ParameterSetName = 'ByTimeRange')]
        [datetime]$StartDate,
        
        [Parameter(Mandatory, ParameterSetName = 'ByTimeRange')]
        [ValidateScript({
            # $_ ist EndDate, aber wir brauchen StartDate zum Vergleich
            # In ValidateScript haben wir keinen Zugriff auf andere Parameter!
            # Deshalb Validierung im Funktionskörper
            $true
        })]
        [datetime]$EndDate,
        
        # ByEventId Parameter Set
        [Parameter(Mandatory, ParameterSetName = 'ByEventId')]
        [ValidateCount(1, 20)]
        [int[]]$EventId,
        
        # ByUser Parameter Set
        [Parameter(Mandatory, ParameterSetName = 'ByUser')]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        
        [Parameter(ParameterSetName = 'ByUser')]
        [switch]$IncludeSystemEvents,
        
        # Gemeinsame Parameter (alle Sets)
        [Parameter()]
        [ValidateSet('Security', 'Application', 'System')]
        [string]$LogName = 'Security',
        
        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$MaxResults = 100
    )
    
    # Zusätzliche Validierung für ByTimeRange
    if ($PSCmdlet.ParameterSetName -eq 'ByTimeRange') {
        if ($EndDate -le $StartDate) {
            throw "EndDate ($EndDate) muss nach StartDate ($StartDate) liegen!"
        }
        
        $daysDiff = ($EndDate - $StartDate).Days
        if ($daysDiff -gt 365) {
            throw "Zeitraum darf maximal 365 Tage betragen (aktuell: $daysDiff Tage)"
        }
    }
    
    Write-Verbose "Parameter Set: $($PSCmdlet.ParameterSetName)"
    Write-Verbose "Log: $LogName, MaxResults: $MaxResults"
    
    # Simulierte Abfrage basierend auf ParameterSet
    $query = switch ($PSCmdlet.ParameterSetName) {
        'ByTimeRange' {
            Write-Verbose "Suche von $StartDate bis $EndDate"
            @{
                Type = 'TimeRange'
                StartDate = $StartDate
                EndDate = $EndDate
            }
        }
        'ByEventId' {
            Write-Verbose "Suche Event IDs: $($EventId -join ', ')"
            @{
                Type = 'EventId'
                EventIds = $EventId
            }
        }
        'ByUser' {
            Write-Verbose "Suche User: $UserName (IncludeSystem: $IncludeSystemEvents)"
            @{
                Type = 'User'
                UserName = $UserName
                IncludeSystemEvents = $IncludeSystemEvents.IsPresent
            }
        }
    }
    
    # Simulierte Ergebnisse
    [PSCustomObject]@{
        ParameterSet = $PSCmdlet.ParameterSetName
        LogName = $LogName
        MaxResults = $MaxResults
        Query = $query
        ExecutedAt = Get-Date
        ResultCount = (Get-Random -Minimum 1 -Maximum $MaxResults)
    }
}

Write-Host "Syntax der Funktion:" -ForegroundColor Yellow
Get-Command Get-AuditLog -Syntax

Write-Host "`nTest ByTimeRange:" -ForegroundColor Green
Get-AuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -LogName Security -Verbose

Write-Host "`nTest ByEventId:" -ForegroundColor Green
Get-AuditLog -EventId 4624, 4625, 4634 -MaxResults 500 -Verbose

Write-Host "`nTest ByUser:" -ForegroundColor Green
Get-AuditLog -UserName "DOMAIN\jdoe" -IncludeSystemEvents -Verbose

Write-Host "`nTest ungültiger Zeitraum:" -ForegroundColor Red
try { Get-AuditLog -StartDate (Get-Date) -EndDate (Get-Date).AddDays(-7) }
catch { Write-Host "  Fehler: $_" -ForegroundColor Yellow }

#endregion

#region LÖSUNG AUFGABE 4: Get-ProcessDetails mit ArgumentCompleter
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 4: Get-ProcessDetails ===" -ForegroundColor Cyan

function Get-ProcessDetails {
    <#
    .SYNOPSIS
        Zeigt Prozessdetails mit dynamischer Tab-Completion.
    .DESCRIPTION
        Demonstriert ArgumentCompleter für verbesserte Benutzerfreundlichkeit.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            # Prozesse abrufen, sortiert nach Speicher
            Get-Process | 
                Where-Object Name -like "$wordToComplete*" |
                Sort-Object WorkingSet64 -Descending |
                Select-Object -First 20 |
                ForEach-Object {
                    $memoryMB = [math]::Round($_.WorkingSet64 / 1MB, 0)
                    $tooltip = "PID: $($_.Id) | Memory: $memoryMB MB | CPU: $([math]::Round($_.CPU, 1))s"
                    
                    [System.Management.Automation.CompletionResult]::new(
                        $_.Name,           # CompletionText
                        $_.Name,           # ListItemText  
                        'ParameterValue',  # ResultType
                        $tooltip           # ToolTip
                    )
                }
        })]
        [string]$ProcessName,
        
        [Parameter()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            # Alle Properties von Process-Objekten
            $properties = [System.Diagnostics.Process].GetProperties() | 
                Select-Object -ExpandProperty Name |
                Where-Object { $_ -like "$wordToComplete*" } |
                Sort-Object
            
            foreach ($prop in $properties) {
                [System.Management.Automation.CompletionResult]::new(
                    $prop,
                    $prop,
                    'ParameterValue',
                    "Property: $prop"
                )
            }
        })]
        [string[]]$Property = @('Name', 'Id', 'CPU', 'WorkingSet64')
    )
    
    Write-Verbose "Suche Prozess: $ProcessName"
    Write-Verbose "Eigenschaften: $($Property -join ', ')"
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if (-not $processes) {
        Write-Warning "Kein Prozess mit Namen '$ProcessName' gefunden"
        return
    }
    
    $processes | ForEach-Object {
        $proc = $_
        $result = [ordered]@{}
        
        foreach ($prop in $Property) {
            try {
                $value = $proc.$prop
                
                # Spezielle Formatierung für bekannte Properties
                $result[$prop] = switch ($prop) {
                    'WorkingSet64' { "$([math]::Round($value / 1MB, 2)) MB" }
                    'CPU' { "$([math]::Round($value, 2)) Sekunden" }
                    'VirtualMemorySize64' { "$([math]::Round($value / 1GB, 2)) GB" }
                    default { $value }
                }
            }
            catch {
                $result[$prop] = 'N/A'
            }
        }
        
        [PSCustomObject]$result
    }
}

Write-Host "Test Get-ProcessDetails:" -ForegroundColor Green
Write-Host "Hinweis: Tab-Completion funktioniert in interaktiver Shell" -ForegroundColor Yellow

Get-ProcessDetails -ProcessName "pwsh" -Verbose | Format-List
Get-ProcessDetails -ProcessName "pwsh" -Property Name, Id, StartTime, HandleCount -Verbose

#endregion

#region LÖSUNG BONUSAUFGABE: Eigene Validierungsklasse
#############################################################################

Write-Host "`n=== LÖSUNG BONUSAUFGABE: ValidateIPRangeAttribute ===" -ForegroundColor Cyan

class ValidateIPRangeAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string[]]$AllowedRanges
    
    ValidateIPRangeAttribute([string[]]$ranges) {
        $this.AllowedRanges = $ranges
    }
    
    [void] Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $ipAddress = $arguments -as [string]
        
        # IP-Adresse validieren
        $ip = $null
        if (-not [System.Net.IPAddress]::TryParse($ipAddress, [ref]$ip)) {
            throw "'$ipAddress' ist keine gültige IP-Adresse"
        }
        
        # Prüfen ob IP in einem der erlaubten Bereiche liegt
        $isInRange = $false
        
        foreach ($range in $this.AllowedRanges) {
            if ($range -match '^(.+)/(\d+)$') {
                $networkAddress = $Matches[1]
                $cidr = [int]$Matches[2]
                
                if ($this.IsIPInRange($ipAddress, $networkAddress, $cidr)) {
                    $isInRange = $true
                    break
                }
            }
        }
        
        if (-not $isInRange) {
            throw "Die IP-Adresse '$ipAddress' liegt nicht in den erlaubten Bereichen: $($this.AllowedRanges -join ', ')"
        }
    }
    
    hidden [bool] IsIPInRange([string]$ipAddress, [string]$networkAddress, [int]$cidr) {
        try {
            $ip = [System.Net.IPAddress]::Parse($ipAddress)
            $network = [System.Net.IPAddress]::Parse($networkAddress)
            
            $ipBytes = $ip.GetAddressBytes()
            $networkBytes = $network.GetAddressBytes()
            
            # Subnet-Maske berechnen
            $maskBytes = [byte[]]::new(4)
            for ($i = 0; $i -lt 4; $i++) {
                $bitsForOctet = [Math]::Min(8, [Math]::Max(0, $cidr - ($i * 8)))
                $maskBytes[$i] = [byte](256 - [Math]::Pow(2, 8 - $bitsForOctet))
            }
            
            # Vergleichen
            for ($i = 0; $i -lt 4; $i++) {
                if (($ipBytes[$i] -band $maskBytes[$i]) -ne ($networkBytes[$i] -band $maskBytes[$i])) {
                    return $false
                }
            }
            
            return $true
        }
        catch {
            return $false
        }
    }
}

function Set-ServerIP {
    <#
    .SYNOPSIS
        Setzt eine Server-IP mit CIDR-Bereichsvalidierung.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateIPRange("192.168.0.0/16", "10.0.0.0/8", "172.16.0.0/12")]
        [string]$IPAddress,
        
        [Parameter()]
        [string]$ServerName = $env:COMPUTERNAME
    )
    
    Write-Host "Setze IP $IPAddress für Server $ServerName" -ForegroundColor Green
    
    [PSCustomObject]@{
        ServerName = $ServerName
        IPAddress = $IPAddress
        ConfiguredAt = Get-Date
    }
}

Write-Host "Test ValidateIPRangeAttribute:" -ForegroundColor Green
Set-ServerIP -IPAddress "192.168.1.100"
Set-ServerIP -IPAddress "10.0.5.25"
Set-ServerIP -IPAddress "172.16.50.1"

Write-Host "`nTest mit ungültiger IP (außerhalb Bereich):" -ForegroundColor Red
try { Set-ServerIP -IPAddress "8.8.8.8" }
catch { Write-Host "  Fehler: $_" -ForegroundColor Yellow }

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ALLE LÖSUNGEN ERFOLGREICH DEMONSTRIERT" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

WICHTIGE LERNPUNKTE:

1. AUFGABE 1 - Basis-Validierung:
   - Kombinieren mehrerer Validierungsattribute
   - ValidatePattern mit ErrorMessage
   - ValidateLength + ValidatePattern zusammen

2. AUFGABE 2 - ValidateScript:
   - Komplexe Logik in ValidateScript
   - Aussagekräftige throw-Nachrichten
   - Abhängigkeiten zwischen Parametern im Funktionskörper prüfen

3. AUFGABE 3 - Parameter Sets:
   - DefaultParameterSetName wichtig
   - Gemeinsame Parameter ohne ParameterSetName
   - Zusätzliche Validierung im Funktionskörper möglich

4. AUFGABE 4 - ArgumentCompleter:
   - [System.Management.Automation.CompletionResult] für reiche Completion
   - Tooltips für zusätzliche Informationen
   - Dynamische Werte zur Laufzeit

5. BONUS - Eigene Validierungsklasse:
   - Von ValidateArgumentsAttribute ableiten
   - Validate() Methode überschreiben
   - Komplexe Validierungslogik kapseln

"@ -ForegroundColor White

#endregion
