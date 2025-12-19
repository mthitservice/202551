Function Get-AdvancedServiceInfo {
    [CmdletBinding()] # Das macht den Unterschied
    Param(
        [Parameter(Mandatory=$True,HelpMessage='One or More computer names')]
        [Alias('HostName')]
        [ValidatePattern('ITH-\w{2,3}\d{1,2}')]
        [string]$Computername

   
    )



Write-Output "Server: $($Computername)"
}