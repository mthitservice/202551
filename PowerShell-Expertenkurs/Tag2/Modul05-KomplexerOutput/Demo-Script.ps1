#############################################################################
# Modul 05: Komplexer Funktions-Output
# PowerShell Expertenkurs - Tag 2
#############################################################################

<#
LERNZIELE:
- Custom Objects erstellen und verwenden
- PSTypeName für typisierte Objekte
- Format-Dateien (.ps1xml) erstellen
- Verschachtelte Objekte und Collections
- Output-Formatierung kontrollieren

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: PSCustomObject Grundlagen
#############################################################################

Write-Host "=== TEIL 1: PSCustomObject Grundlagen ===" -ForegroundColor Cyan

# === DEMO 1.1: Verschiedene Wege zur Object-Erstellung ===

# Methode 1: Hashtable-Casting (empfohlen)
$obj1 = [PSCustomObject]@{
    Name = "Server01"
    Status = "Online"
    LastCheck = Get-Date
}

# Methode 2: New-Object mit Add-Member
$obj2 = New-Object PSObject
$obj2 | Add-Member -NotePropertyName "Name" -NotePropertyValue "Server02"
$obj2 | Add-Member -NotePropertyName "Status" -NotePropertyValue "Offline"

# Methode 3: Select-Object mit berechneten Properties
$obj3 = "" | Select-Object @{N='Name';E={'Server03'}}, @{N='Status';E={'Maintenance'}}

Write-Host "Methode 1 (Empfohlen):" -ForegroundColor Yellow
$obj1 | Format-Table

Write-Host "Performance-Vergleich:" -ForegroundColor Yellow
$iterations = 1000

$time1 = Measure-Command {
    1..$iterations | ForEach-Object {
        [PSCustomObject]@{ Name = "Test"; Value = $_ }
    }
}

$time2 = Measure-Command {
    1..$iterations | ForEach-Object {
        $o = New-Object PSObject
        $o | Add-Member -NotePropertyName Name -NotePropertyValue "Test"
        $o | Add-Member -NotePropertyName Value -NotePropertyValue $_
        $o
    }
}

Write-Host "  [PSCustomObject]@{}: $($time1.TotalMilliseconds) ms"
Write-Host "  New-Object + Add-Member: $($time2.TotalMilliseconds) ms"

#endregion

#region TEIL 2: Ordered Hashtables und Property-Reihenfolge
#############################################################################

Write-Host "`n=== TEIL 2: Property-Reihenfolge ===" -ForegroundColor Cyan

# Problem: Normale Hashtables haben keine garantierte Reihenfolge
$unordered = [PSCustomObject]@{
    Zebra = 1
    Apple = 2
    Mango = 3
}
Write-Host "Unordered (Reihenfolge zufällig):" -ForegroundColor Yellow
$unordered | Format-List

# Lösung: [ordered] verwenden
$ordered = [PSCustomObject][ordered]@{
    Zebra = 1
    Apple = 2
    Mango = 3
}
Write-Host "Ordered (Reihenfolge garantiert):" -ForegroundColor Yellow
$ordered | Format-List

#endregion

#region TEIL 3: PSTypeName für typisierte Objekte
#############################################################################

Write-Host "`n=== TEIL 3: PSTypeName ===" -ForegroundColor Cyan

# === DEMO 3.1: Objekt mit benutzerdefiniertem Typ ===

function Get-ServerHealth {
    [CmdletBinding()]
    [OutputType('ServerHealthReport')]  # Dokumentation des Ausgabetyps
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    # PSTypeName definiert den "virtuellen" Typ
    [PSCustomObject]@{
        PSTypeName = 'ServerHealthReport'  # Wichtig für Formatierung!
        ComputerName = $ComputerName
        Status = 'Healthy'
        UptimeDays = [math]::Round($uptime.TotalDays, 2)
        MemoryUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        LastCheck = Get-Date
    }
}

$health = Get-ServerHealth
Write-Host "Objekt-Typ:" -ForegroundColor Yellow
$health.PSObject.TypeNames | ForEach-Object { Write-Host "  $_" }

# === DEMO 3.2: Typ-spezifische Methoden hinzufügen ===

# Methode zum Typ hinzufügen
$health | Add-Member -MemberType ScriptMethod -Name "Refresh" -Value {
    Write-Host "Aktualisiere Health-Daten..."
    $this.LastCheck = Get-Date
}

$health | Add-Member -MemberType ScriptProperty -Name "IsHealthy" -Value {
    $this.MemoryUsedPercent -lt 90
}

Write-Host "`nObjekt mit Methoden:" -ForegroundColor Yellow
$health | Format-List
Write-Host "IsHealthy: $($health.IsHealthy)"

#endregion

#region TEIL 4: Verschachtelte Objekte
#############################################################################

Write-Host "`n=== TEIL 4: Verschachtelte Objekte ===" -ForegroundColor Cyan

function Get-ComputerInventory {
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    # System-Info
    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    
    # CPU-Info als verschachteltes Objekt
    $cpus = Get-CimInstance Win32_Processor | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Cores = $_.NumberOfCores
            LogicalProcessors = $_.NumberOfLogicalProcessors
            MaxClockSpeedMHz = $_.MaxClockSpeed
        }
    }
    
    # Disk-Info als Array von Objekten
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        [PSCustomObject]@{
            Drive = $_.DeviceID
            Label = $_.VolumeName
            TotalGB = [math]::Round($_.Size / 1GB, 2)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
        }
    }
    
    # Network-Info
    $networks = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
        [PSCustomObject]@{
            Description = $_.Description
            IPAddresses = $_.IPAddress
            MACAddress = $_.MACAddress
            DHCPEnabled = $_.DHCPEnabled
        }
    }
    
    # Haupt-Objekt mit verschachtelten Objekten
    [PSCustomObject]@{
        PSTypeName = 'ComputerInventory'
        ComputerName = $ComputerName
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        OperatingSystem = $os.Caption
        OSVersion = $os.Version
        CPUs = $cpus           # Verschachteltes Objekt
        CPUCount = $cpus.Count
        Disks = $disks         # Array von Objekten
        DiskCount = $disks.Count
        NetworkAdapters = $networks
        CollectionTime = Get-Date
    }
}

$inventory = Get-ComputerInventory -Verbose
Write-Host "Haupt-Objekt:" -ForegroundColor Yellow
$inventory | Select-Object ComputerName, Manufacturer, Model, TotalMemoryGB | Format-List

Write-Host "`nVerschachtelte CPUs:" -ForegroundColor Yellow
$inventory.CPUs | Format-Table

Write-Host "Verschachtelte Disks:" -ForegroundColor Yellow
$inventory.Disks | Format-Table

#endregion

#region TEIL 5: Klassen für typisierte Objekte
#############################################################################

Write-Host "`n=== TEIL 5: PowerShell Klassen ===" -ForegroundColor Cyan

# === DEMO 5.1: Einfache Klasse ===

class ServerInfo {
    # Properties
    [string]$Name
    [string]$IPAddress
    [string]$Status
    [datetime]$LastCheck
    
    # Konstruktor
    ServerInfo([string]$name) {
        $this.Name = $name
        $this.Status = 'Unknown'
        $this.LastCheck = Get-Date
    }
    
    # Überladener Konstruktor
    ServerInfo([string]$name, [string]$ip) {
        $this.Name = $name
        $this.IPAddress = $ip
        $this.Status = 'Unknown'
        $this.LastCheck = Get-Date
    }
    
    # Methoden
    [void] CheckStatus() {
        # Simulierte Status-Prüfung
        $this.Status = if (Test-Connection -ComputerName $this.Name -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            'Online'
        } else {
            'Offline'
        }
        $this.LastCheck = Get-Date
    }
    
    [string] ToString() {
        return "$($this.Name) ($($this.Status))"
    }
}

# Klasse verwenden
$server = [ServerInfo]::new("localhost", "127.0.0.1")
$server.CheckStatus()
Write-Host "Server-Info (Klasse):" -ForegroundColor Yellow
$server | Format-List


# === DEMO 5.2: Klasse mit statischen Methoden ===

class ProcessReport {
    [string]$Name
    [int]$Id
    [double]$MemoryMB
    [double]$CPUSeconds
    
    ProcessReport([System.Diagnostics.Process]$process) {
        $this.Name = $process.Name
        $this.Id = $process.Id
        $this.MemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
        $this.CPUSeconds = [math]::Round($process.CPU, 2)
    }
    
    # Statische Factory-Methode
    static [ProcessReport[]] GetTopByMemory([int]$count) {
        return Get-Process | 
            Sort-Object WorkingSet64 -Descending | 
            Select-Object -First $count |
            ForEach-Object { [ProcessReport]::new($_) }
    }
    
    static [ProcessReport[]] GetByName([string]$name) {
        return Get-Process -Name $name -ErrorAction SilentlyContinue |
            ForEach-Object { [ProcessReport]::new($_) }
    }
}

Write-Host "`nTop 5 Prozesse (statische Methode):" -ForegroundColor Yellow
[ProcessReport]::GetTopByMemory(5) | Format-Table

#endregion

#region TEIL 6: Format-Dateien für benutzerdefinierte Ausgabe
#############################################################################

Write-Host "`n=== TEIL 6: Format-Dateien ===" -ForegroundColor Cyan

# Format-Datei erstellen
$formatXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <ViewDefinitions>
        <!-- Table View für ServerHealthReport -->
        <View>
            <Name>ServerHealthReport.TableView</Name>
            <ViewSelectedBy>
                <TypeName>ServerHealthReport</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Label>Computer</Label>
                        <Width>20</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Status</Label>
                        <Width>10</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Uptime</Label>
                        <Width>12</Width>
                        <Alignment>Right</Alignment>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Memory%</Label>
                        <Width>10</Width>
                        <Alignment>Right</Alignment>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>ComputerName</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Status</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>"{0:N1} days" -f $_.UptimeDays</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>"{0:N1}%" -f $_.MemoryUsedPercent</ScriptBlock>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
        
        <!-- List View für ServerHealthReport -->
        <View>
            <Name>ServerHealthReport.ListView</Name>
            <ViewSelectedBy>
                <TypeName>ServerHealthReport</TypeName>
            </ViewSelectedBy>
            <ListControl>
                <ListEntries>
                    <ListEntry>
                        <ListItems>
                            <ListItem>
                                <Label>Server</Label>
                                <PropertyName>ComputerName</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>Health Status</Label>
                                <PropertyName>Status</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>System Uptime</Label>
                                <ScriptBlock>"{0:N2} days ({1:N0} hours)" -f $_.UptimeDays, ($_.UptimeDays * 24)</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Memory Usage</Label>
                                <ScriptBlock>"{0:N1}% used" -f $_.MemoryUsedPercent</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Last Checked</Label>
                                <ScriptBlock>$_.LastCheck.ToString("yyyy-MM-dd HH:mm:ss")</ScriptBlock>
                            </ListItem>
                        </ListItems>
                    </ListEntry>
                </ListEntries>
            </ListControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

# Format-Datei speichern
$formatPath = Join-Path $env:TEMP "ServerHealthReport.Format.ps1xml"
$formatXml | Out-File $formatPath -Encoding UTF8
Write-Host "Format-Datei erstellt: $formatPath" -ForegroundColor Green

# Format-Datei laden
Update-FormatData -PrependPath $formatPath

Write-Host "`nObjekt mit benutzerdefinierter Formatierung:" -ForegroundColor Yellow
$health = Get-ServerHealth

Write-Host "`nFormat-Table (Custom):" -ForegroundColor Yellow
$health | Format-Table

Write-Host "Format-List (Custom):" -ForegroundColor Yellow
$health | Format-List

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 05" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. PSCUSTOMOBJECT:
   - [PSCustomObject]@{} ist schnellste Methode
   - [ordered]@{} für garantierte Property-Reihenfolge
   - Add-Member für dynamische Properties

2. PSTYPENAME:
   - PSTypeName = 'MeinTyp' in Hashtable
   - Ermöglicht typ-spezifische Formatierung
   - [OutputType()] für Dokumentation

3. VERSCHACHTELTE OBJEKTE:
   - Properties können Arrays/Objekte sein
   - Ermöglicht komplexe Datenstrukturen
   - Zugriff: `$obj.SubObject.Property

4. POWERSHELL KLASSEN:
   - class ClassName { }
   - Konstruktoren, Methoden, Properties
   - Statische Methoden mit [static]

5. FORMAT-DATEIEN (.ps1xml):
   - Benutzerdefinierte Table/List Views
   - ScriptBlock für berechnete Werte
   - Update-FormatData zum Laden

BEST PRACTICES:
- Immer [ordered] für vorhersagbare Reihenfolge
- PSTypeName für wiederverwendbare Objekte
- Klassen für komplexe Logik

"@ -ForegroundColor White

#endregion
