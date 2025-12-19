
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

# Format Datei Laden
$FormatPath= Join-Path $env:TEMP "ServerHealthReport.Format.ps1xml"
Update-FormatData -PrependPath $FormatPath


$health=Get-ServerHealth

$health |ft

$health |fl

