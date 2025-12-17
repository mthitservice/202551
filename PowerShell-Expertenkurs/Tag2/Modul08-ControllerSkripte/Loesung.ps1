#############################################################################
# Modul 08 - Controller Skripte
# LÖSUNGEN
#############################################################################

#region Übung 1: Einfaches Menüsystem - Start-FileManager.ps1

function Start-FileManager {
    <#
    .SYNOPSIS
        Einfacher Datei-Manager mit Menüsystem.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$StartPath = (Get-Location).Path
    )
    
    $currentPath = $StartPath
    
    function Show-MainMenu {
        Clear-Host
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host "  Datei-Manager v1.0" -ForegroundColor Cyan
        Write-Host "  Aktueller Pfad: $currentPath" -ForegroundColor DarkGray
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Dateien auflisten"
        Write-Host "      Zeigt alle Dateien und Ordner"
        Write-Host ""
        Write-Host "  [2] Datei suchen"
        Write-Host "      Sucht rekursiv nach Dateien"
        Write-Host ""
        Write-Host "  [3] Ordner erstellen"
        Write-Host "      Erstellt einen neuen Ordner"
        Write-Host ""
        Write-Host "  [4] Dateien kopieren"
        Write-Host "      Kopiert Dateien an anderen Ort"
        Write-Host ""
        Write-Host "  [5] Dateien löschen"
        Write-Host "      Löscht ausgewählte Dateien"
        Write-Host ""
        Write-Host "  [C] Verzeichnis wechseln"
        Write-Host ""
        Write-Host "  [0] Beenden" -ForegroundColor Yellow
        Write-Host ""
        
        return Read-Host "Auswahl"
    }
    
    function Invoke-ListFiles {
        Write-Host "`nInhalt von: $currentPath" -ForegroundColor Cyan
        Write-Host ("-" * 50)
        
        Get-ChildItem -Path $currentPath | ForEach-Object {
            $icon = if ($_.PSIsContainer) { "📁" } else { "📄" }
            $size = if ($_.PSIsContainer) { "<DIR>" } else { "{0,10:N0} KB" -f ($_.Length / 1KB) }
            Write-Host "$icon $($_.Name.PadRight(30)) $size"
        }
    }
    
    function Invoke-SearchFiles {
        $pattern = Read-Host "Suchmuster (z.B. *.txt)"
        
        if ([string]::IsNullOrEmpty($pattern)) {
            Write-Host "Kein Suchmuster angegeben." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nSuche nach '$pattern'..." -ForegroundColor Cyan
        
        $results = Get-ChildItem -Path $currentPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        
        if ($results) {
            Write-Host "Gefunden: $($results.Count) Dateien" -ForegroundColor Green
            $results | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
        }
        else {
            Write-Host "Keine Dateien gefunden." -ForegroundColor Yellow
        }
    }
    
    function Invoke-CreateFolder {
        $folderName = Read-Host "Neuer Ordnername"
        
        if ([string]::IsNullOrEmpty($folderName)) {
            Write-Host "Kein Ordnername angegeben." -ForegroundColor Yellow
            return
        }
        
        $newPath = Join-Path $currentPath $folderName
        
        if (Test-Path $newPath) {
            Write-Host "Ordner existiert bereits!" -ForegroundColor Yellow
            return
        }
        
        try {
            New-Item -Path $newPath -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "Ordner erstellt: $newPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Fehler: $_" -ForegroundColor Red
        }
    }
    
    function Invoke-CopyFiles {
        $source = Read-Host "Quelldatei (Pfad oder Name)"
        
        if (-not (Test-Path $source)) {
            # Versuche relativen Pfad
            $source = Join-Path $currentPath $source
        }
        
        if (-not (Test-Path $source)) {
            Write-Host "Quelldatei nicht gefunden!" -ForegroundColor Red
            return
        }
        
        $destination = Read-Host "Zielverzeichnis"
        
        if (-not (Test-Path $destination)) {
            $create = Read-Host "Ziel existiert nicht. Erstellen? (j/n)"
            if ($create -match '^[JjYy]') {
                New-Item -Path $destination -ItemType Directory -Force | Out-Null
            }
            else {
                return
            }
        }
        
        try {
            Copy-Item -Path $source -Destination $destination -ErrorAction Stop
            Write-Host "Kopiert: $source -> $destination" -ForegroundColor Green
        }
        catch {
            Write-Host "Fehler beim Kopieren: $_" -ForegroundColor Red
        }
    }
    
    function Invoke-DeleteFiles {
        $fileName = Read-Host "Zu löschende Datei"
        
        $filePath = Join-Path $currentPath $fileName
        
        if (-not (Test-Path $filePath)) {
            Write-Host "Datei nicht gefunden: $filePath" -ForegroundColor Red
            return
        }
        
        # Bestätigung
        Write-Host "Zu löschen: $filePath" -ForegroundColor Yellow
        $confirm = Read-Host "Wirklich löschen? (j/n)"
        
        if ($confirm -match '^[JjYy]') {
            try {
                Remove-Item -Path $filePath -Force -ErrorAction Stop
                Write-Host "Gelöscht: $filePath" -ForegroundColor Green
            }
            catch {
                Write-Host "Fehler beim Löschen: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Abgebrochen." -ForegroundColor Yellow
        }
    }
    
    function Invoke-ChangeDirectory {
        $newPath = Read-Host "Neuer Pfad (oder '..' für übergeordnet)"
        
        if ($newPath -eq '..') {
            $newPath = Split-Path $currentPath -Parent
        }
        elseif (-not [System.IO.Path]::IsPathRooted($newPath)) {
            $newPath = Join-Path $currentPath $newPath
        }
        
        if (Test-Path $newPath -PathType Container) {
            $script:currentPath = $newPath
            Write-Host "Verzeichnis gewechselt zu: $currentPath" -ForegroundColor Green
        }
        else {
            Write-Host "Pfad nicht gefunden!" -ForegroundColor Red
        }
    }
    
    # Hauptschleife
    do {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" { Invoke-ListFiles }
            "2" { Invoke-SearchFiles }
            "3" { Invoke-CreateFolder }
            "4" { Invoke-CopyFiles }
            "5" { Invoke-DeleteFiles }
            "C" { Invoke-ChangeDirectory }
            "c" { Invoke-ChangeDirectory }
            "0" { break }
            default { Write-Host "Ungültige Auswahl!" -ForegroundColor Red }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "Enter zum Fortfahren"
        }
        
    } while ($choice -ne "0")
    
    Write-Host "`nDatei-Manager beendet." -ForegroundColor Cyan
}

Write-Host "=== Übung 1: Start-FileManager ===" -ForegroundColor Green
Write-Host "Starten Sie mit: Start-FileManager" -ForegroundColor Yellow

#endregion

#region Übung 2: Benutzerinteraktion mit Validierung

function Read-ValidatedInput {
    <#
    .SYNOPSIS
        Liest und validiert Benutzereingaben.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        
        [Parameter()]
        [ValidateSet('String', 'Int', 'Path', 'Email', 'IPAddress')]
        [string]$Type = 'String',
        
        [Parameter()]
        [object]$DefaultValue,
        
        [Parameter()]
        [switch]$Mandatory,
        
        [Parameter()]
        [int]$MinValue,
        
        [Parameter()]
        [int]$MaxValue
    )
    
    $promptText = $Prompt
    if ($DefaultValue) {
        $promptText += " [$DefaultValue]"
    }
    
    do {
        $rawInput = Read-Host $promptText
        
        # Default-Wert anwenden
        if ([string]::IsNullOrEmpty($rawInput) -and $DefaultValue) {
            $rawInput = $DefaultValue.ToString()
        }
        
        # Pflichtfeld prüfen
        if ($Mandatory -and [string]::IsNullOrEmpty($rawInput)) {
            Write-Host "  ✗ Eingabe ist erforderlich!" -ForegroundColor Red
            continue
        }
        
        # Leere optionale Eingabe erlauben
        if ([string]::IsNullOrEmpty($rawInput) -and -not $Mandatory) {
            return $null
        }
        
        # Typ-Validierung
        $isValid = $true
        $errorMsg = ""
        
        switch ($Type) {
            'String' {
                # Strings sind immer gültig
            }
            'Int' {
                if ($rawInput -match '^\d+$') {
                    $intValue = [int]$rawInput
                    if ($MinValue -and $intValue -lt $MinValue) {
                        $isValid = $false
                        $errorMsg = "Wert muss mindestens $MinValue sein"
                    }
                    elseif ($MaxValue -and $intValue -gt $MaxValue) {
                        $isValid = $false
                        $errorMsg = "Wert darf maximal $MaxValue sein"
                    }
                }
                else {
                    $isValid = $false
                    $errorMsg = "Keine gültige Zahl"
                }
            }
            'Path' {
                if (-not (Test-Path $rawInput -IsValid)) {
                    $isValid = $false
                    $errorMsg = "Ungültiger Pfad"
                }
            }
            'Email' {
                if ($rawInput -notmatch '^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$') {
                    $isValid = $false
                    $errorMsg = "Ungültiges E-Mail-Format (name@domain.tld)"
                }
            }
            'IPAddress' {
                if ($rawInput -notmatch '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$') {
                    $isValid = $false
                    $errorMsg = "Ungültige IP-Adresse (z.B. 192.168.1.100)"
                }
            }
        }
        
        if (-not $isValid) {
            Write-Host "  ✗ $errorMsg" -ForegroundColor Red
        }
        else {
            # Rückgabe mit korrektem Typ
            return switch ($Type) {
                'Int' { [int]$rawInput }
                default { $rawInput }
            }
        }
        
    } while ($true)
}

function New-ServerConfig {
    <#
    .SYNOPSIS
        Konfigurations-Assistent für neue Server.
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Server-Konfigurations-Assistent" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Eingaben sammeln
    $serverName = Read-ValidatedInput -Prompt "Servername" -Type String -Mandatory
    
    $ipAddress = Read-ValidatedInput -Prompt "IP-Adresse" -Type IPAddress -Mandatory
    
    $port = Read-ValidatedInput -Prompt "Port" -Type Int -DefaultValue 443 -MinValue 1 -MaxValue 65535
    
    $adminEmail = Read-ValidatedInput -Prompt "Admin-Email" -Type Email -Mandatory
    
    $backupPath = Read-ValidatedInput -Prompt "Backup-Pfad" -Type Path -Mandatory
    
    # Pfad erstellen wenn nötig
    if (-not (Test-Path $backupPath)) {
        $create = Read-Host "Pfad existiert nicht. Erstellen? (j/n)"
        if ($create -match '^[JjYy]') {
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
            Write-Host "  ✓ Pfad erstellt" -ForegroundColor Green
        }
    }
    
    # Zusammenfassung
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Konfiguration:" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    $config = [PSCustomObject]@{
        ServerName = $serverName
        IPAddress  = $ipAddress
        Port       = $port
        AdminEmail = $adminEmail
        BackupPath = $backupPath
        CreatedAt  = Get-Date
    }
    
    $config | Format-List
    
    $confirm = Read-Host "Konfiguration speichern? (j/n)"
    
    if ($confirm -match '^[JjYy]') {
        Write-Host "✓ Konfiguration gespeichert!" -ForegroundColor Green
        return $config
    }
    else {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        return $null
    }
}

Write-Host "`n=== Übung 2: New-ServerConfig ===" -ForegroundColor Green
Write-Host "Starten Sie mit: New-ServerConfig" -ForegroundColor Yellow

#endregion

#region Übung 3: Vollständiger Controller mit Logging

# Logging-System
$script:UserManagerLogPath = "$env:TEMP\UserManager.log"

function Write-UserManagerLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Gray' }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $script:UserManagerLogPath -Value $logEntry -ErrorAction SilentlyContinue
}

# Simulierte Benutzerdaten
$script:Users = @(
    [PSCustomObject]@{ Username = "admin"; FullName = "Administrator"; Department = "IT"; Role = "Admin"; Status = "Active" }
    [PSCustomObject]@{ Username = "mmustermann"; FullName = "Max Mustermann"; Department = "Sales"; Role = "User"; Status = "Active" }
    [PSCustomObject]@{ Username = "ebeispiel"; FullName = "Eva Beispiel"; Department = "HR"; Role = "User"; Status = "Active" }
)

function Show-UserManagerMenu {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Benutzer-Verwaltung" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Benutzer auflisten"
    Write-Host "  [2] Neuen Benutzer erstellen"
    Write-Host "  [3] Benutzer deaktivieren"
    Write-Host "  [4] Passwort zurücksetzen"
    Write-Host "  [5] Log anzeigen"
    Write-Host ""
    Write-Host "  [0] Beenden" -ForegroundColor Yellow
    Write-Host ""
    
    return Read-Host "Auswahl"
}

function Show-UserList {
    Write-Host "`nBenutzer:" -ForegroundColor Cyan
    $script:Users | Format-Table -AutoSize
    Write-UserManagerLog "Benutzerliste angezeigt ($($script:Users.Count) Benutzer)"
}

function New-UserWizard {
    Write-Host "`n=== Neuen Benutzer erstellen ===" -ForegroundColor Cyan
    
    # Username
    $username = Read-ValidatedInput -Prompt "Username" -Type String -Mandatory
    
    if ($script:Users.Username -contains $username) {
        Write-Host "Benutzer existiert bereits!" -ForegroundColor Red
        Write-UserManagerLog "Benutzer '$username' existiert bereits" -Level Warning
        return
    }
    
    # Vollständiger Name
    $fullName = Read-ValidatedInput -Prompt "Vollständiger Name" -Type String -Mandatory
    
    # Abteilung
    $departments = @('IT', 'HR', 'Sales', 'Marketing', 'Finance')
    Write-Host "Abteilungen: $($departments -join ', ')"
    do {
        $department = Read-Host "Abteilung"
    } while ($department -notin $departments)
    
    # Rolle
    $role = Read-Host "Rolle (User/Admin) [User]"
    if ([string]::IsNullOrEmpty($role)) { $role = "User" }
    
    # Zusammenfassung
    Write-Host "`nNeuer Benutzer:" -ForegroundColor Yellow
    Write-Host "  Username: $username"
    Write-Host "  Name: $fullName"
    Write-Host "  Abteilung: $department"
    Write-Host "  Rolle: $role"
    
    $confirm = Read-Host "`nErstellen? (j/n)"
    
    if ($confirm -match '^[JjYy]') {
        $newUser = [PSCustomObject]@{
            Username = $username
            FullName = $fullName
            Department = $department
            Role = $role
            Status = "Active"
        }
        
        $script:Users += $newUser
        Write-Host "✓ Benutzer erstellt!" -ForegroundColor Green
        Write-UserManagerLog "Benutzer '$username' erstellt (Abteilung: $department, Rolle: $role)"
    }
    else {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        Write-UserManagerLog "Benutzererstellung abgebrochen" -Level Warning
    }
}

function Disable-User {
    Show-UserList
    
    $username = Read-Host "Username zum Deaktivieren"
    $user = $script:Users | Where-Object Username -eq $username
    
    if (-not $user) {
        Write-Host "Benutzer nicht gefunden!" -ForegroundColor Red
        return
    }
    
    if ($user.Status -eq "Inactive") {
        Write-Host "Benutzer ist bereits deaktiviert." -ForegroundColor Yellow
        return
    }
    
    $confirm = Read-Host "Benutzer '$username' wirklich deaktivieren? (j/n)"
    
    if ($confirm -match '^[JjYy]') {
        $user.Status = "Inactive"
        Write-Host "✓ Benutzer deaktiviert!" -ForegroundColor Green
        Write-UserManagerLog "Benutzer '$username' deaktiviert"
    }
}

function Reset-UserPassword {
    Show-UserList
    
    $username = Read-Host "Username für Passwort-Reset"
    $user = $script:Users | Where-Object Username -eq $username
    
    if (-not $user) {
        Write-Host "Benutzer nicht gefunden!" -ForegroundColor Red
        return
    }
    
    # Simuliertes neues Passwort generieren
    $newPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    
    Write-Host "Neues Passwort: $newPassword" -ForegroundColor Green
    Write-Host "(In Produktion: Passwort per Email senden)"
    Write-UserManagerLog "Passwort für '$username' zurückgesetzt"
}

function Show-Log {
    Write-Host "`n=== Log-Einträge ===" -ForegroundColor Cyan
    
    if (Test-Path $script:UserManagerLogPath) {
        Get-Content $script:UserManagerLogPath -Tail 20
    }
    else {
        Write-Host "Keine Log-Einträge vorhanden."
    }
}

function Start-UserManager {
    <#
    .SYNOPSIS
        Hauptcontroller für Benutzer-Verwaltung.
    #>
    [CmdletBinding()]
    param()
    
    Write-UserManagerLog "User Manager gestartet"
    
    do {
        $choice = Show-UserManagerMenu
        
        switch ($choice) {
            "1" { Show-UserList }
            "2" { New-UserWizard }
            "3" { Disable-User }
            "4" { Reset-UserPassword }
            "5" { Show-Log }
            "0" { break }
            default { Write-Host "Ungültige Auswahl!" -ForegroundColor Red }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "Enter zum Fortfahren"
        }
        
    } while ($choice -ne "0")
    
    Write-UserManagerLog "User Manager beendet"
    Write-Host "`nUser Manager beendet." -ForegroundColor Cyan
}

Write-Host "`n=== Übung 3: Start-UserManager ===" -ForegroundColor Green
Write-Host "Starten Sie mit: Start-UserManager" -ForegroundColor Yellow

#endregion

#region Übung 4 (Bonus): Multi-Level Menü

function Start-ServerAdminConsole {
    <#
    .SYNOPSIS
        Multi-Level Menü für Server-Administration.
    #>
    [CmdletBinding()]
    param()
    
    function Show-Breadcrumb {
        param([string[]]$Path)
        
        if ($Path.Count -gt 0) {
            Write-Host "Navigation: $($Path -join ' > ')" -ForegroundColor DarkGray
        }
    }
    
    function Show-Menu {
        param(
            [string]$Title,
            [hashtable[]]$Items,
            [string[]]$Breadcrumb
        )
        
        Clear-Host
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host "  Server Administration Console" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Cyan
        Show-Breadcrumb -Path $Breadcrumb
        Write-Host ""
        Write-Host "  $Title" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($item in $Items) {
            $arrow = if ($item.SubMenu) { " →" } else { "" }
            Write-Host "  [$($item.Key)] $($item.Name)$arrow"
        }
        
        Write-Host ""
        if ($Breadcrumb.Count -gt 0) {
            Write-Host "  [0] Zurück" -ForegroundColor Yellow
        }
        else {
            Write-Host "  [Q] Beenden" -ForegroundColor Yellow
        }
        Write-Host ""
        
        return (Read-Host "Auswahl").ToUpper()
    }
    
    # Menü-Struktur
    $serviceMenu = @(
        @{ Key = "1"; Name = "Alle Dienste auflisten"; Action = { Get-Service | Select-Object -First 20 | Format-Table Name, Status } }
        @{ Key = "2"; Name = "Laufende Dienste"; Action = { Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 15 | Format-Table } }
        @{ Key = "3"; Name = "Gestoppte Dienste"; Action = { Get-Service | Where-Object Status -eq 'Stopped' | Select-Object -First 15 | Format-Table } }
        @{ Key = "4"; Name = "Dienst starten"; Action = { 
            $svc = Read-Host "Dienstname"
            Write-Host "Würde starten: $svc" -ForegroundColor Yellow
        }}
        @{ Key = "5"; Name = "Dienst stoppen"; Action = {
            $svc = Read-Host "Dienstname"
            Write-Host "Würde stoppen: $svc" -ForegroundColor Yellow
        }}
    )
    
    $processMenu = @(
        @{ Key = "1"; Name = "Top Prozesse (CPU)"; Action = { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table Name, CPU, WorkingSet } }
        @{ Key = "2"; Name = "Top Prozesse (RAM)"; Action = { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | Format-Table Name, @{N='RAM_MB';E={[math]::Round($_.WorkingSet/1MB,1)}} } }
        @{ Key = "3"; Name = "Prozess beenden"; Action = {
            $proc = Read-Host "Prozessname"
            Write-Host "Würde beenden: $proc" -ForegroundColor Yellow
        }}
    )
    
    $serverMenu = @(
        @{ Key = "1"; Name = "Status anzeigen"; Action = { 
            $os = Get-CimInstance Win32_OperatingSystem
            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                OS = $os.Caption
                Uptime = (New-TimeSpan -Start $os.LastBootUpTime).ToString("d\.hh\:mm")
            } | Format-List
        }}
        @{ Key = "2"; Name = "Dienste verwalten"; SubMenu = $serviceMenu }
        @{ Key = "3"; Name = "Prozesse verwalten"; SubMenu = $processMenu }
        @{ Key = "4"; Name = "Neustart planen"; Action = {
            Write-Host "Neustart-Planung (Simulation)" -ForegroundColor Yellow
        }}
    )
    
    $networkMenu = @(
        @{ Key = "1"; Name = "IP-Konfiguration"; Action = { Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength } }
        @{ Key = "2"; Name = "DNS-Server"; Action = { Get-DnsClientServerAddress | Format-Table InterfaceAlias, ServerAddresses } }
        @{ Key = "3"; Name = "Offene Ports"; Action = { Get-NetTCPConnection -State Listen | Select-Object -First 10 | Format-Table LocalAddress, LocalPort, State } }
    )
    
    $securityMenu = @(
        @{ Key = "1"; Name = "Firewall-Status"; Action = { Get-NetFirewallProfile | Format-Table Name, Enabled } }
        @{ Key = "2"; Name = "Windows Defender Status"; Action = { Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled | Format-List } }
        @{ Key = "3"; Name = "Letzte Sicherheitsereignisse"; Action = { Get-EventLog -LogName Security -Newest 10 -ErrorAction SilentlyContinue | Format-Table TimeGenerated, EntryType, Message -Wrap } }
    )
    
    $reportMenu = @(
        @{ Key = "1"; Name = "System-Übersicht"; Action = { Get-ComputerInfo | Select-Object CsName, WindowsVersion, OsTotalVisibleMemorySize | Format-List } }
        @{ Key = "2"; Name = "Festplatten-Bericht"; Action = { Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3 | Format-Table DeviceID, @{N='Size_GB';E={[math]::Round($_.Size/1GB)}}, @{N='Free_GB';E={[math]::Round($_.FreeSpace/1GB)}} } }
        @{ Key = "3"; Name = "Bericht exportieren"; Action = {
            $path = "$env:TEMP\ServerReport_$(Get-Date -Format 'yyyyMMdd').html"
            Write-Host "Bericht würde gespeichert unter: $path" -ForegroundColor Yellow
        }}
    )
    
    $mainMenu = @(
        @{ Key = "1"; Name = "Server Management"; SubMenu = $serverMenu }
        @{ Key = "2"; Name = "Netzwerk"; SubMenu = $networkMenu }
        @{ Key = "3"; Name = "Sicherheit"; SubMenu = $securityMenu }
        @{ Key = "4"; Name = "Berichte"; SubMenu = $reportMenu }
    )
    
    # Menü-Navigation
    function Invoke-MenuLevel {
        param(
            [hashtable[]]$Menu,
            [string]$Title,
            [string[]]$Breadcrumb = @()
        )
        
        do {
            $choice = Show-Menu -Title $Title -Items $Menu -Breadcrumb $Breadcrumb
            
            if ($choice -eq 'Q' -and $Breadcrumb.Count -eq 0) {
                return 'EXIT'
            }
            
            if ($choice -eq '0' -and $Breadcrumb.Count -gt 0) {
                return 'BACK'
            }
            
            $selected = $Menu | Where-Object { $_.Key -eq $choice }
            
            if ($selected) {
                if ($selected.SubMenu) {
                    $newBreadcrumb = $Breadcrumb + $selected.Name
                    $result = Invoke-MenuLevel -Menu $selected.SubMenu -Title $selected.Name -Breadcrumb $newBreadcrumb
                    
                    if ($result -eq 'EXIT') {
                        return 'EXIT'
                    }
                }
                elseif ($selected.Action) {
                    & $selected.Action
                    Read-Host "`nEnter zum Fortfahren"
                }
            }
            
        } while ($true)
    }
    
    # Start
    $result = Invoke-MenuLevel -Menu $mainMenu -Title "Hauptmenü"
    Write-Host "`nServer Admin Console beendet." -ForegroundColor Cyan
}

Write-Host "`n=== Übung 4 (Bonus): Start-ServerAdminConsole ===" -ForegroundColor Green
Write-Host "Starten Sie mit: Start-ServerAdminConsole" -ForegroundColor Yellow

#endregion

#region Zusammenfassung
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALLE LÖSUNGEN GELADEN" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

Verfügbare Controller:
  - Start-FileManager (Übung 1)
  - New-ServerConfig (Übung 2)
  - Start-UserManager (Übung 3)
  - Start-ServerAdminConsole (Bonus)

Hilfsfunktionen:
  - Read-ValidatedInput
  - Write-UserManagerLog

"@ -ForegroundColor White
#endregion
