#############################################################################
# Modul 05: Komplexer Funktions-Output - LÖSUNGEN
# PowerShell Expertenkurs - Tag 2
#############################################################################

#region LÖSUNG AUFGABE 1: Get-NetworkStatus
#############################################################################

Write-Host "=== LÖSUNG AUFGABE 1: Get-NetworkStatus ===" -ForegroundColor Cyan

function Get-NetworkStatus {
    <#
    .SYNOPSIS
        Gibt strukturierte Netzwerk-Informationen zurück.
    .DESCRIPTION
        Sammelt Netzwerk-Adapter-Informationen und gibt sie als
        typisierte Custom Objects zurück.
    #>
    [CmdletBinding()]
    [OutputType('NetworkStatusReport')]
    param(
        [Parameter()]
        [switch]$IncludeDisabled
    )
    
    Write-Verbose "Sammle Netzwerk-Adapter Informationen..."
    
    # Adapter abrufen
    $adapters = Get-NetAdapter
    if (-not $IncludeDisabled) {
        $adapters = $adapters | Where-Object Status -eq 'Up'
    }
    
    foreach ($adapter in $adapters) {
        Write-Verbose "Verarbeite: $($adapter.Name)"
        
        # IP-Konfiguration abrufen
        $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        $ipAddresses = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        
        [PSCustomObject][ordered]@{
            PSTypeName = 'NetworkStatusReport'
            AdapterName = $adapter.Name
            Status = $adapter.Status
            IPAddress = @($ipAddresses.IPAddress)
            SubnetMask = @($ipAddresses | ForEach-Object { 
                # CIDR zu Subnet-Maske konvertieren
                $cidr = $_.PrefixLength
                $mask = ([Math]::Pow(2, $cidr) - 1) * [Math]::Pow(2, (32 - $cidr))
                $bytes = [BitConverter]::GetBytes([UInt32]$mask)
                [Array]::Reverse($bytes)
                ($bytes | ForEach-Object { $_.ToString() }) -join '.'
            })
            Gateway = $ipConfig.IPv4DefaultGateway.NextHop
            DNSServers = @($ipConfig.DNSServer.ServerAddresses)
            SpeedMbps = [math]::Round($adapter.LinkSpeed.Replace(' Gbps','000').Replace(' Mbps','').Replace(' Kbps','') / 1, 0)
            MACAddress = $adapter.MacAddress
            IsPhysical = -not $adapter.Virtual
            InterfaceIndex = $adapter.ifIndex
            Description = $adapter.InterfaceDescription
        }
    }
}

# Tests
Write-Host "`nAktive Netzwerk-Adapter:" -ForegroundColor Yellow
Get-NetworkStatus -Verbose | Format-Table AdapterName, Status, IPAddress, SpeedMbps, IsPhysical

Write-Host "`nPhysische Adapter:" -ForegroundColor Yellow
Get-NetworkStatus | Where-Object IsPhysical | Format-List AdapterName, IPAddress, DNSServers

#endregion

#region LÖSUNG AUFGABE 2: Get-UserProfile
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 2: Get-UserProfile ===" -ForegroundColor Cyan

function Get-UserProfile {
    <#
    .SYNOPSIS
        Erstellt ein umfassendes Benutzerprofil mit verschachtelten Objekten.
    #>
    [CmdletBinding()]
    [OutputType('UserProfileReport')]
    param()
    
    Write-Verbose "Sammle Benutzerprofil-Informationen..."
    
    # Aktueller Benutzer
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Letzter Logon (aus Event Log wenn möglich)
    $lastLogon = try {
        (Get-WinEvent -FilterHashtable @{LogName='Security';ID=4624} -MaxEvents 1 -ErrorAction Stop).TimeCreated
    } catch {
        $null
    }
    
    # Environment-Objekt
    $environment = [PSCustomObject][ordered]@{
        HomeDrive = $env:HOMEDRIVE
        HomePath = $env:HOMEPATH
        TempPath = $env:TEMP
        SystemRoot = $env:SystemRoot
        PSModulePath = $env:PSModulePath -split ';'
        ComputerName = $env:COMPUTERNAME
        UserDomain = $env:USERDOMAIN
        ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
    }
    
    # Recent Files (aus Recent-Ordner)
    $recentPath = [Environment]::GetFolderPath('Recent')
    $recentFiles = Get-ChildItem $recentPath -File -ErrorAction SilentlyContinue |
        Sort-Object LastAccessTime -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            [PSCustomObject][ordered]@{
                Name = $_.Name
                FullPath = $_.FullName
                LastAccess = $_.LastAccessTime
                SizeKB = [math]::Round($_.Length / 1KB, 2)
            }
        }
    
    # Disk Quota (wenn verfügbar)
    $diskQuota = try {
        $quota = Get-WmiObject Win32_DiskQuota -ErrorAction Stop | 
            Where-Object { $_.User -like "*$env:USERNAME*" } |
            Select-Object -First 1
        
        if ($quota) {
            [PSCustomObject][ordered]@{
                QuotaLimit = [math]::Round($quota.Limit / 1GB, 2)
                QuotaUsed = [math]::Round($quota.DiskSpaceUsed / 1GB, 2)
                QuotaRemaining = [math]::Round(($quota.Limit - $quota.DiskSpaceUsed) / 1GB, 2)
                PercentUsed = [math]::Round(($quota.DiskSpaceUsed / $quota.Limit) * 100, 1)
            }
        } else {
            [PSCustomObject][ordered]@{
                QuotaLimit = 'Nicht konfiguriert'
                QuotaUsed = 'N/A'
                QuotaRemaining = 'N/A'
                PercentUsed = 'N/A'
            }
        }
    } catch {
        [PSCustomObject][ordered]@{
            QuotaLimit = 'Nicht verfügbar'
            QuotaUsed = 'N/A'
            QuotaRemaining = 'N/A'
            PercentUsed = 'N/A'
        }
    }
    
    # Gruppen des Benutzers
    $groups = $currentUser.Groups | ForEach-Object {
        try {
            $_.Translate([System.Security.Principal.NTAccount]).Value
        } catch {
            $_.Value
        }
    }
    
    # Haupt-Objekt
    [PSCustomObject][ordered]@{
        PSTypeName = 'UserProfileReport'
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        FullName = "$env:USERDOMAIN\$env:USERNAME"
        SID = $currentUser.User.Value
        ProfilePath = $env:USERPROFILE
        LastLogon = $lastLogon
        IsAdmin = $isAdmin
        IsInteractive = [Environment]::UserInteractive
        Groups = $groups
        GroupCount = $groups.Count
        Environment = $environment      # Verschachteltes Objekt
        RecentFiles = $recentFiles      # Array von Objekten
        RecentFileCount = @($recentFiles).Count
        DiskQuota = $diskQuota          # Verschachteltes Objekt
        CollectionTime = Get-Date
    }
}

# Tests
Write-Host "User Profile:" -ForegroundColor Yellow
$profile = Get-UserProfile -Verbose
$profile | Select-Object UserName, Domain, IsAdmin, ProfilePath | Format-List

Write-Host "`nEnvironment-Details:" -ForegroundColor Yellow
$profile.Environment | Format-List HomeDrive, TempPath, SystemRoot

Write-Host "`nRecent Files:" -ForegroundColor Yellow
$profile.RecentFiles | Format-Table Name, LastAccess, SizeKB

Write-Host "`nGruppen-Mitgliedschaften (erste 5):" -ForegroundColor Yellow
$profile.Groups | Select-Object -First 5

#endregion

#region LÖSUNG AUFGABE 3: ServiceMonitor Klasse
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 3: ServiceMonitor Klasse ===" -ForegroundColor Cyan

class ServiceMonitor {
    # Properties
    [string]$ServiceName
    [string]$DisplayName
    [string]$Status
    [string]$StartType
    [datetime]$LastChecked
    [System.Collections.ArrayList]$History
    
    # Konstruktor
    ServiceMonitor([string]$serviceName) {
        $this.ServiceName = $serviceName
        $this.History = [System.Collections.ArrayList]::new()
        $this.LoadServiceInfo()
    }
    
    # Private Methode zum Laden der Service-Info
    hidden [void] LoadServiceInfo() {
        $service = Get-Service -Name $this.ServiceName -ErrorAction Stop
        $this.DisplayName = $service.DisplayName
        $this.Status = $service.Status.ToString()
        $this.StartType = $service.StartType.ToString()
        $this.LastChecked = Get-Date
    }
    
    # Status aktualisieren
    [void] Refresh() {
        $oldStatus = $this.Status
        $this.LoadServiceInfo()
        
        # Zur History hinzufügen wenn sich Status geändert hat
        if ($oldStatus -ne $this.Status) {
            $null = $this.History.Add([PSCustomObject]@{
                Timestamp = Get-Date
                OldStatus = $oldStatus
                NewStatus = $this.Status
            })
        }
    }
    
    # Prüfen ob Service läuft
    [bool] IsRunning() {
        $this.Refresh()
        return $this.Status -eq 'Running'
    }
    
    # Service starten
    [void] Start() {
        if ($this.Status -ne 'Running') {
            Write-Verbose "Starte Service: $($this.ServiceName)"
            Start-Service -Name $this.ServiceName
            $this.Refresh()
        } else {
            Write-Verbose "Service läuft bereits: $($this.ServiceName)"
        }
    }
    
    # Service stoppen
    [void] Stop() {
        if ($this.Status -eq 'Running') {
            Write-Verbose "Stoppe Service: $($this.ServiceName)"
            Stop-Service -Name $this.ServiceName -Force
            $this.Refresh()
        } else {
            Write-Verbose "Service läuft nicht: $($this.ServiceName)"
        }
    }
    
    # Neustart
    [void] Restart() {
        Write-Verbose "Starte Service neu: $($this.ServiceName)"
        Restart-Service -Name $this.ServiceName -Force
        $this.Refresh()
    }
    
    # ToString für formatierte Ausgabe
    [string] ToString() {
        return "[{0}] {1} ({2}) - {3}" -f $this.Status, $this.ServiceName, $this.DisplayName, $this.StartType
    }
    
    # Statische Methode: Kritische Services finden
    static [ServiceMonitor[]] GetCritical() {
        $criticalServices = Get-Service | 
            Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
        
        $result = @()
        foreach ($svc in $criticalServices) {
            try {
                $result += [ServiceMonitor]::new($svc.Name)
            } catch {
                # Service kann möglicherweise nicht abgefragt werden
            }
        }
        return $result
    }
    
    # Statische Methode: Alle Services eines Typs
    static [ServiceMonitor[]] GetByStartType([string]$startType) {
        $services = Get-Service | Where-Object StartType -eq $startType
        
        $result = @()
        foreach ($svc in $services) {
            try {
                $result += [ServiceMonitor]::new($svc.Name)
            } catch {
                # Ignoriere Fehler
            }
        }
        return $result
    }
}

# Tests
Write-Host "ServiceMonitor für Spooler:" -ForegroundColor Yellow
$svc = [ServiceMonitor]::new("Spooler")
Write-Host $svc.ToString()

Write-Host "`nService-Properties:" -ForegroundColor Yellow
$svc | Format-List ServiceName, DisplayName, Status, StartType, LastChecked

Write-Host "`nMethoden-Test:" -ForegroundColor Yellow
Write-Host "IsRunning: $($svc.IsRunning())"

Write-Host "`nKritische Services (Automatic aber nicht Running):" -ForegroundColor Yellow
$critical = [ServiceMonitor]::GetCritical()
if ($critical.Count -gt 0) {
    $critical | Select-Object ServiceName, Status, StartType -First 5 | Format-Table
} else {
    Write-Host "  Keine kritischen Services gefunden (gut!)" -ForegroundColor Green
}

#endregion

#region LÖSUNG AUFGABE 4: Format-Datei
#############################################################################

Write-Host "`n=== LÖSUNG AUFGABE 4: Format-Datei ===" -ForegroundColor Cyan

$formatXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <ViewDefinitions>
        <!-- Table View für NetworkStatusReport -->
        <View>
            <Name>NetworkStatusReport.TableView</Name>
            <ViewSelectedBy>
                <TypeName>NetworkStatusReport</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Label>Adapter</Label>
                        <Width>25</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Status</Label>
                        <Width>8</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>IP Address</Label>
                        <Width>16</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Speed</Label>
                        <Width>12</Width>
                        <Alignment>Right</Alignment>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Physical</Label>
                        <Width>8</Width>
                        <Alignment>Center</Alignment>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>AdapterName</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Status</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>if ($_.IPAddress) { $_.IPAddress[0] } else { 'N/A' }</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>"{0} Mbps" -f $_.SpeedMbps</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>if ($_.IsPhysical) { 'Yes' } else { 'No' }</ScriptBlock>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
        
        <!-- List View für NetworkStatusReport -->
        <View>
            <Name>NetworkStatusReport.ListView</Name>
            <ViewSelectedBy>
                <TypeName>NetworkStatusReport</TypeName>
            </ViewSelectedBy>
            <ListControl>
                <ListEntries>
                    <ListEntry>
                        <ListItems>
                            <ListItem>
                                <Label>Network Adapter</Label>
                                <PropertyName>AdapterName</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>Description</Label>
                                <PropertyName>Description</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>Connection Status</Label>
                                <PropertyName>Status</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>IP Address(es)</Label>
                                <ScriptBlock>($_.IPAddress -join ', ')</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Subnet Mask</Label>
                                <ScriptBlock>($_.SubnetMask -join ', ')</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Default Gateway</Label>
                                <ScriptBlock>if ($_.Gateway) { $_.Gateway } else { 'Not configured' }</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>DNS Servers</Label>
                                <ScriptBlock>if ($_.DNSServers) { $_.DNSServers -join ', ' } else { 'Not configured' }</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Link Speed</Label>
                                <ScriptBlock>"{0} Mbps" -f $_.SpeedMbps</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>MAC Address</Label>
                                <ScriptBlock>$_.MACAddress -replace '-',':'</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Physical Adapter</Label>
                                <ScriptBlock>if ($_.IsPhysical) { 'Yes (Hardware)' } else { 'No (Virtual)' }</ScriptBlock>
                            </ListItem>
                        </ListItems>
                    </ListEntry>
                </ListEntries>
            </ListControl>
        </View>
        
        <!-- Wide View für NetworkStatusReport -->
        <View>
            <Name>NetworkStatusReport.WideView</Name>
            <ViewSelectedBy>
                <TypeName>NetworkStatusReport</TypeName>
            </ViewSelectedBy>
            <WideControl>
                <WideEntries>
                    <WideEntry>
                        <WideItem>
                            <ScriptBlock>"{0} ({1})" -f $_.AdapterName, $_.Status</ScriptBlock>
                        </WideItem>
                    </WideEntry>
                </WideEntries>
                <ColumnNumber>3</ColumnNumber>
            </WideControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

# Format-Datei speichern
$formatPath = Join-Path $env:TEMP "NetworkStatusReport.Format.ps1xml"
$formatXml | Out-File $formatPath -Encoding UTF8
Write-Host "Format-Datei erstellt: $formatPath" -ForegroundColor Green

# Format-Datei laden
Update-FormatData -PrependPath $formatPath

# Tests
Write-Host "`nFormat-Table Test:" -ForegroundColor Yellow
Get-NetworkStatus | Format-Table

Write-Host "`nFormat-List Test:" -ForegroundColor Yellow
Get-NetworkStatus | Select-Object -First 1 | Format-List

Write-Host "`nFormat-Wide Test:" -ForegroundColor Yellow
Get-NetworkStatus | Format-Wide

#endregion

#region LÖSUNG BONUSAUFGABE: Type Extension
#############################################################################

Write-Host "`n=== LÖSUNG BONUSAUFGABE: Type Extension ===" -ForegroundColor Cyan

# Da Types.ps1xml komplexer ist, zeigen wir die Alternative mit Update-TypeData

# ScriptMethod: GetDependencies
Update-TypeData -TypeName 'ServiceMonitor' -MemberType ScriptMethod -MemberName 'GetDependencies' -Value {
    $service = Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        return $service.DependentServices | ForEach-Object {
            [PSCustomObject]@{
                ServiceName = $_.Name
                DisplayName = $_.DisplayName
                Status = $_.Status
            }
        }
    }
    return @()
} -Force

# ScriptMethod: GetUptime
Update-TypeData -TypeName 'ServiceMonitor' -MemberType ScriptMethod -MemberName 'GetUptime' -Value {
    if ($this.Status -eq 'Running') {
        # Versuche Process-Startzeit zu ermitteln
        try {
            $process = Get-CimInstance Win32_Service -Filter "Name='$($this.ServiceName)'" |
                Select-Object ProcessId
            if ($process.ProcessId -and $process.ProcessId -ne 0) {
                $proc = Get-Process -Id $process.ProcessId -ErrorAction Stop
                $uptime = (Get-Date) - $proc.StartTime
                return [PSCustomObject]@{
                    Days = $uptime.Days
                    Hours = $uptime.Hours
                    Minutes = $uptime.Minutes
                    TotalHours = [math]::Round($uptime.TotalHours, 2)
                    StartTime = $proc.StartTime
                }
            }
        } catch {
            # Fallback
        }
    }
    return [PSCustomObject]@{
        Days = 0
        Hours = 0
        Minutes = 0
        TotalHours = 0
        StartTime = $null
        Note = 'Service nicht aktiv oder Uptime nicht ermittelbar'
    }
} -Force

# ScriptProperty: DependencyCount
Update-TypeData -TypeName 'ServiceMonitor' -MemberType ScriptProperty -MemberName 'DependencyCount' -Value {
    $service = Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        return $service.DependentServices.Count
    }
    return 0
} -Force

# ScriptProperty: IsAutoStart
Update-TypeData -TypeName 'ServiceMonitor' -MemberType ScriptProperty -MemberName 'IsAutoStart' -Value {
    return $this.StartType -eq 'Automatic'
} -Force

# AliasProperty: Name -> ServiceName
Update-TypeData -TypeName 'ServiceMonitor' -MemberType AliasProperty -MemberName 'Name' -Value 'ServiceName' -Force

Write-Host "Type Extensions hinzugefügt!" -ForegroundColor Green

# Tests
Write-Host "`nTest der Type Extensions:" -ForegroundColor Yellow
$svc = [ServiceMonitor]::new("Spooler")

Write-Host "`nAlias 'Name':" -ForegroundColor Yellow
Write-Host "  ServiceName: $($svc.ServiceName)"
Write-Host "  Name (Alias): $($svc.Name)"

Write-Host "`nScriptProperty 'IsAutoStart':" -ForegroundColor Yellow
Write-Host "  StartType: $($svc.StartType)"
Write-Host "  IsAutoStart: $($svc.IsAutoStart)"

Write-Host "`nScriptProperty 'DependencyCount':" -ForegroundColor Yellow
Write-Host "  DependencyCount: $($svc.DependencyCount)"

Write-Host "`nScriptMethod 'GetUptime':" -ForegroundColor Yellow
$svc.GetUptime() | Format-List

Write-Host "`nScriptMethod 'GetDependencies':" -ForegroundColor Yellow
$deps = $svc.GetDependencies()
if ($deps) {
    $deps | Format-Table
} else {
    Write-Host "  Keine abhängigen Services"
}

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ALLE LÖSUNGEN ERFOLGREICH DEMONSTRIERT" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

WICHTIGE LERNPUNKTE:

1. AUFGABE 1 - Custom Objects:
   - [ordered]@{} für konsistente Property-Reihenfolge
   - PSTypeName für Typ-Identifikation
   - [OutputType()] für Dokumentation

2. AUFGABE 2 - Verschachtelte Objekte:
   - Properties können selbst Objekte sein
   - Arrays von Objekten als Properties
   - Zugriff mit Punkt-Notation: `$obj.SubObj.Property

3. AUFGABE 3 - PowerShell Klassen:
   - class Keyword für Klassendefiniton
   - Konstruktoren mit ClassName([params]) { }
   - [static] für statische Methoden/Properties
   - [hidden] für private Members

4. AUFGABE 4 - Format-Dateien:
   - TableControl, ListControl, WideControl
   - ScriptBlock für berechnete Werte
   - Update-FormatData zum Laden

5. BONUS - Type Extensions:
   - Update-TypeData für dynamische Erweiterung
   - ScriptMethod, ScriptProperty, AliasProperty
   - Alternative zu Types.ps1xml Dateien

"@ -ForegroundColor White

#endregion
