# Komplexer Output

<#
Lernziel:
- Custom Objects
- PSTypeName
- Formatdateien .ps1xml
- verschachtelte Objekte
- Outpuformatierung
#>

Write-Host "------ Teil 1: PSCustomObject --------" -ForegroundColor Cyan

# Methode1 Hashtable Casting  (empfohlen)
$obj1 = [PSCustomObject]@{
    Name="Server01"
    Status="Online"
    LastCheck=Get-Date # implizite Konvertierung in DateTime
}

# Methode 2 Objekt erstellen mit Add Member
$obj2 = New-Object psobject
$obj2 | Add-Member -NotePropertyName "Name" -NotePropertyValue "Server02"
$obj2 | Add-Member -NotePropertyName "Status" -NotePropertyValue "Offline"

# Methode 3 mit berechneten Eigenschaften (Berechnete Spalten)
$obj3 ="" | Select-Object  @{N='Name';E={'Server03'}},@{N='Status';E={'Maintenance'}}

Write-Host "Methode 1 " -ForegroundColor Yellow
$obj1 | ft

Write-Host "Performance Vergleich:" -ForegroundColor Yellow
$i=1000
$time=Measure-Command {
    1..$i | ForEach-Object {
        [PSCustomObject]@{
            Name = 'Test'; Value=$_
        }
    }
}

$time2=Measure-Command {
    1..$i | ForEach-Object {
        $o = New-Object psobject
        $o| Add-Member -NotePropertyName "Name" -NotePropertyValue "Test"
        $o | Add-Member -NotePropertyName "Value" -NotePropertyValue $_     
    }
}

# Auswertung
Write-Host " [PSCustomObject]@():$($time.TotalMilliseconds) ms"
Write-Host " New-Object + Add- Member:$($time2.TotalMilliseconds) ms"

# Sortierbare Hashtables
$unordered=[PSCustomObject]@{
    Zebra=1
    Apple=2
    Mango=3
}

$unordered | FL
# Die Anweisung Ordered sorgt für atomare Reihenfolge

$ordered=[PSCustomObject][ordered]@{
    Zebra=1
    Apple=2
    Mango=3
}

$ordered | FL


# PSTYPEName für Typisierte Objekte


function Get-ServerHealth {
    [CmdletBinding()]
    [OutputType('ServerHealthReport')]
    param (
        [Parameter()]
        [string]
        $ComputerName =$env:COMPUTERNAME
    )

    $os=Get-CimInstance Win32_OperatingSystem
    $uptime=(Get-Date)-$os.LastBootUpTime
    $NetAdapter=Get-NetAdapter | Select-Object InterfaceIndex,Name,MacAddress,InterfaceDescription

    
    [PSCustomObject]@{
        PSTypeName='ServerHealthReport' 
        ComputerName=$ComputerName
        Status='Healthy'
        UpTimeDays=$uptime.totalDays
        LastCheck=Get-Date
        MemoryUsedPercent =[Math]::Round((($os.TotalVisibleMemorySize-$os.FreePhysicalMemory) /$os.TotalVisibleMemorySize)*100,1)
        NetworkAdapter=$NetAdapter

        }
    
    }
    $health=Get-ServerHealth
    $health.PSObject.TypeNames | ForEach-Object {Write-Host " $_"}
    $health

    # Typspezifische Methode hinzufügen

$health | Add-Member -MemberType ScriptMethod -Name "Refresh" -Value {
    write-Host "Aktualisiere Health Daten ..."
    $this.LastCheck=Get-Date

}

$health.Refresh()
$health

## Einfache Klasse
class  ServerInfo {

    # Properties
    [string] $Name
    [string] $IPAddress
    [string] $Status
    [datetime] $LastCheck

    # Kunstruktor
        ServerInfo([string]$Name){
                $this.Name=$Name
                $this.Status="unknown"
                $this.LastCheck=Get-Date
        }


        ServerInfo([string]$Name,[string]$ip){
                $this.Name=$Name
                $this.IPAddress=$ip
                $this.Status="unknown"
                $this.LastCheck=Get-Date
        }

    # Methoden
    [void]CheckStatus(){
        # Simulierte Statusprüfung
        $this.Status=if(Test-Connection -ComputerName $this.Name -Count 1 -Quiet -ErrorAction SilentlyContinue){
            'Online'
        } else {
            'Offline'
        }
        $this.LastCheck=Get-Date

    }
# Statische Methode
static [ServerInfo]CheckStaicStatus(){
        # Simulierte Statusprüfung
        $server=[ServerInfo]::new("localhost","127.0.0.1")

         return $server

    }   






    [string]ToString() {

        return "$($this.Name) ($($this.Status))"
    }


}
# Aufruf einer statischen Funktion einer Klasse

[ServerInfo]::CheckStaicStatus()


# Instanziieren der eigene Klasse
$server=[ServerInfo]::new("localhost","127.0.0.1")
$server.CheckStatus()

$server | fl