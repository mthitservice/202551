# Basic Function
Function Get-SimpleFunction {

    Param(
        [string]$Computername

    )
 Write-Host $Computername   

 get-service 

}
# Advanced Function
Function Get-CorpOpsInfo {
    [CmdletBinding()] # Das macht den Unterschied
    Param(
        [string]$Computername

    )
 Write-Host $Computername   
 Write-Verbose "Insight Info"
 get-adUser -Filter *

}
Function Get-AdvancedServiceInfo {
    [CmdletBinding()] # Das macht den Unterschied
    Param(
        [Parameter()]
        [string]$ServiceName
    )
Write-Verbose "Suche Service: $ServiceName"
 $service=Get-Service -Name $ServiceName
Write-Verbose "Service gefunden: $($service.DisplayName)"
Write-Output "Server: $($service.Name) -Status:$($service.Status)"
}

Get-AdvancedServiceInfo -ServiceName "Spooler" -Verbose
Get-SimpleFunction -Computername "jhh"
# Get-CorpOpsInfo -Computername "Test" -Verbose