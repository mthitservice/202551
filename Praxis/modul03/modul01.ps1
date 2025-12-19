    # Controller
function Show-SimpleMenu {
    <#
        .SYNOPSIS
            Zeigt ein einfaches Textmenü an  
    
    
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string[]]$options
    )

    Clear-Host
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""

    for ($i=0;$i -lt $options.Count; $i++)
    {
        Write-Host " [$($i+1)] $($options[$i])"

    }
   Write-Host ""
    Write-Host " [0] Beenden" -ForegroundColor Yellow
    Write-Host ""
    $selection =Read-Host "Auswahl"
    return $selection
    
}

Write-Host "Einfaches Menü :"
#Write-host @'
    $menuOptions=@(
    "System- Info anzeigen"
    "Dienste verwalten"
    "Logs analysieren"
    "Einstellungen"
    )

    do {
    
        $ch=Show-SimpleMenu -Title "Server Management" -Options $menuOptions 
        switch($ch){
        
            "1" { Get-ComputerInfo | Select-Object -property CsName,OsName | out-host}
            "2" { Get-Service | Out-GridView}
            "3" { Get-EventLog -LogName System -Newest 10}
            "4" { Write-Host "Einstellungen ..."}
            "0" { break}
        }

        if ($ch -ne "0") { Read-Host "Enter zum Fortfahren"}
    
    
    } while ($ch -ne "0")


# '@


Show-SimpleMenu