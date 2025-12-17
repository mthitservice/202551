#############################################################################
# Modul 10: XML Data Files
# PowerShell Expertenkurs - Tag 3
#############################################################################

<#
LERNZIELE:
- XML-Dateien lesen und verstehen
- [xml] Type Accelerator nutzen
- Select-Xml mit XPath
- XML erstellen und modifizieren
- Namespaces verstehen
- XML für Konfigurationsdateien nutzen

DEMO-DAUER: ca. 45-60 Minuten
#>

#region TEIL 1: XML Grundlagen
#############################################################################

Write-Host "=== TEIL 1: XML Grundlagen ===" -ForegroundColor Cyan

# === DEMO 1.1: XML mit [xml] Type Accelerator laden ===
Write-Host "Demo: XML laden" -ForegroundColor Yellow

$xmlString = @"
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <Application name="MyApp" version="1.0">
        <Settings>
            <Setting name="Debug" value="true" />
            <Setting name="LogLevel" value="Info" />
            <Setting name="MaxConnections" value="100" />
        </Settings>
        <Database>
            <Server>localhost</Server>
            <Port>1433</Port>
            <Name>AppDB</Name>
        </Database>
    </Application>
</Configuration>
"@

# XML parsen
[xml]$config = $xmlString

# Zugriff auf Elemente
Write-Host "`nZugriff auf XML-Elemente:" -ForegroundColor Yellow
Write-Host "App Name: $($config.Configuration.Application.name)"
Write-Host "Version: $($config.Configuration.Application.version)"
Write-Host "Server: $($config.Configuration.Application.Database.Server)"
Write-Host "Port: $($config.Configuration.Application.Database.Port)"

# Settings durchlaufen
Write-Host "`nAlle Settings:" -ForegroundColor Yellow
$config.Configuration.Application.Settings.Setting | ForEach-Object {
    Write-Host "  $($_.name) = $($_.value)"
}

#endregion

#region TEIL 2: XML-Dateien lesen und schreiben
#############################################################################

Write-Host "`n=== TEIL 2: XML-Dateien ===" -ForegroundColor Cyan

# XML-Datei erstellen
$xmlFilePath = "$env:TEMP\demo-config.xml"
$xmlString | Out-File $xmlFilePath -Encoding UTF8

# Datei lesen
Write-Host "Demo: XML aus Datei laden" -ForegroundColor Yellow

[xml]$fileConfig = Get-Content $xmlFilePath -Encoding UTF8

Write-Host "Geladen aus: $xmlFilePath"
Write-Host "Root-Element: $($fileConfig.DocumentElement.Name)"

# XML modifizieren und speichern
Write-Host "`nDemo: XML modifizieren" -ForegroundColor Yellow

# Wert ändern
$fileConfig.Configuration.Application.Database.Port = "3306"

# Neues Element hinzufügen
$newSetting = $fileConfig.CreateElement("Setting")
$newSetting.SetAttribute("name", "Timeout")
$newSetting.SetAttribute("value", "30")
$fileConfig.Configuration.Application.Settings.AppendChild($newSetting) | Out-Null

# Speichern
$fileConfig.Save($xmlFilePath)
Write-Host "XML gespeichert mit neuen Werten"

# Verifizieren
[xml]$verifyConfig = Get-Content $xmlFilePath
Write-Host "Neuer Port: $($verifyConfig.Configuration.Application.Database.Port)"
Write-Host "Settings Count: $($verifyConfig.Configuration.Application.Settings.Setting.Count)"

#endregion

#region TEIL 3: Select-Xml und XPath
#############################################################################

Write-Host "`n=== TEIL 3: Select-Xml mit XPath ===" -ForegroundColor Cyan

# Komplexeres XML
$employeesXml = @"
<?xml version="1.0"?>
<Company name="TechCorp">
    <Departments>
        <Department id="IT" budget="500000">
            <Manager>Max Mustermann</Manager>
            <Employees>
                <Employee id="1" status="active">
                    <Name>Anna Schmidt</Name>
                    <Position>Developer</Position>
                    <Salary>65000</Salary>
                </Employee>
                <Employee id="2" status="active">
                    <Name>Tom Müller</Name>
                    <Position>Senior Developer</Position>
                    <Salary>80000</Salary>
                </Employee>
                <Employee id="3" status="inactive">
                    <Name>Lisa Weber</Name>
                    <Position>Developer</Position>
                    <Salary>60000</Salary>
                </Employee>
            </Employees>
        </Department>
        <Department id="HR" budget="200000">
            <Manager>Eva Beispiel</Manager>
            <Employees>
                <Employee id="4" status="active">
                    <Name>Peter Groß</Name>
                    <Position>HR Specialist</Position>
                    <Salary>55000</Salary>
                </Employee>
            </Employees>
        </Department>
    </Departments>
</Company>
"@

[xml]$company = $employeesXml

Write-Host "XPath Beispiele:" -ForegroundColor Yellow

# Alle Mitarbeiter
Write-Host "`n1. Alle Mitarbeiter (//Employee):" -ForegroundColor Cyan
$allEmployees = Select-Xml -Xml $company -XPath "//Employee"
$allEmployees | ForEach-Object { 
    Write-Host "  $($_.Node.Name.InnerText) - $($_.Node.Position)" 
}

# Nur aktive Mitarbeiter
Write-Host "`n2. Nur aktive Mitarbeiter (//Employee[@status='active']):" -ForegroundColor Cyan
$activeEmployees = Select-Xml -Xml $company -XPath "//Employee[@status='active']"
$activeEmployees | ForEach-Object { 
    Write-Host "  $($_.Node.Name.InnerText)" 
}

# Mitarbeiter mit Gehalt > 60000
Write-Host "`n3. Gehalt > 60000 (//Employee[Salary>60000]):" -ForegroundColor Cyan
$highEarners = Select-Xml -Xml $company -XPath "//Employee[Salary>60000]"
$highEarners | ForEach-Object { 
    Write-Host "  $($_.Node.Name.InnerText): $($_.Node.Salary)€" 
}

# Department Manager
Write-Host "`n4. Alle Manager (//Department/Manager):" -ForegroundColor Cyan
$managers = Select-Xml -Xml $company -XPath "//Department/Manager"
$managers | ForEach-Object { 
    $deptId = $_.Node.ParentNode.GetAttribute("id")
    Write-Host "  $deptId : $($_.Node.InnerText)" 
}

# Attribute abfragen
Write-Host "`n5. Department-Budgets (//@budget):" -ForegroundColor Cyan
$budgets = Select-Xml -Xml $company -XPath "//Department/@budget"
$budgets | ForEach-Object {
    $dept = $_.Node.OwnerElement.GetAttribute("id")
    Write-Host "  $dept : $($_.Node.Value)€"
}

#endregion

#region TEIL 4: XML erstellen
#############################################################################

Write-Host "`n=== TEIL 4: XML programmatisch erstellen ===" -ForegroundColor Cyan

function New-XmlDocument {
    <#
    .SYNOPSIS
        Erstellt ein neues XML-Dokument programmatisch.
    #>
    param(
        [string]$RootElement = "Root"
    )
    
    $xml = New-Object System.Xml.XmlDocument
    
    # XML-Deklaration
    $declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", $null)
    $xml.AppendChild($declaration) | Out-Null
    
    # Root-Element
    $root = $xml.CreateElement($RootElement)
    $xml.AppendChild($root) | Out-Null
    
    return $xml
}

function Add-XmlElement {
    <#
    .SYNOPSIS
        Fügt ein Element zu einem XML-Parent hinzu.
    #>
    param(
        [System.Xml.XmlDocument]$Xml,
        [System.Xml.XmlElement]$Parent,
        [string]$Name,
        [string]$Value,
        [hashtable]$Attributes
    )
    
    $element = $Xml.CreateElement($Name)
    
    if ($Value) {
        $element.InnerText = $Value
    }
    
    if ($Attributes) {
        foreach ($attr in $Attributes.GetEnumerator()) {
            $element.SetAttribute($attr.Key, $attr.Value)
        }
    }
    
    $Parent.AppendChild($element) | Out-Null
    return $element
}

# Beispiel: Server-Inventar erstellen
Write-Host "Demo: XML programmatisch erstellen" -ForegroundColor Yellow

$inventory = New-XmlDocument -RootElement "ServerInventory"
$root = $inventory.DocumentElement

# Attribut zum Root
$root.SetAttribute("created", (Get-Date -Format "yyyy-MM-dd"))
$root.SetAttribute("version", "1.0")

# Server hinzufügen
$servers = @(
    @{ Name = "WebServer01"; IP = "192.168.1.10"; OS = "Windows Server 2022"; Role = "Web" }
    @{ Name = "DBServer01"; IP = "192.168.1.20"; OS = "Windows Server 2022"; Role = "Database" }
    @{ Name = "AppServer01"; IP = "192.168.1.30"; OS = "Windows Server 2019"; Role = "Application" }
)

foreach ($server in $servers) {
    $serverElement = Add-XmlElement -Xml $inventory -Parent $root -Name "Server" `
        -Attributes @{ name = $server.Name; role = $server.Role }
    
    Add-XmlElement -Xml $inventory -Parent $serverElement -Name "IPAddress" -Value $server.IP | Out-Null
    Add-XmlElement -Xml $inventory -Parent $serverElement -Name "OperatingSystem" -Value $server.OS | Out-Null
    Add-XmlElement -Xml $inventory -Parent $serverElement -Name "Status" -Value "Active" | Out-Null
}

# Anzeigen
$sw = New-Object System.IO.StringWriter
$writer = New-Object System.Xml.XmlTextWriter($sw)
$writer.Formatting = [System.Xml.Formatting]::Indented
$inventory.WriteContentTo($writer)
Write-Host $sw.ToString()

#endregion

#region TEIL 5: XML Namespaces
#############################################################################

Write-Host "`n=== TEIL 5: XML Namespaces ===" -ForegroundColor Cyan

# XML mit Namespace
$xmlWithNs = @"
<?xml version="1.0"?>
<root xmlns:app="http://example.com/app" xmlns:db="http://example.com/db">
    <app:Configuration>
        <app:Setting name="Debug">true</app:Setting>
        <app:Setting name="Version">1.0</app:Setting>
    </app:Configuration>
    <db:Connection>
        <db:Server>localhost</db:Server>
        <db:Database>MyDB</db:Database>
    </db:Connection>
</root>
"@

[xml]$nsXml = $xmlWithNs

Write-Host "Arbeiten mit Namespaces:" -ForegroundColor Yellow

# Namespace Manager erstellen
$nsManager = New-Object System.Xml.XmlNamespaceManager($nsXml.NameTable)
$nsManager.AddNamespace("app", "http://example.com/app")
$nsManager.AddNamespace("db", "http://example.com/db")

# Mit Namespace selektieren
Write-Host "`nApp-Settings:" -ForegroundColor Cyan
$appSettings = $nsXml.SelectNodes("//app:Setting", $nsManager)
foreach ($setting in $appSettings) {
    Write-Host "  $($setting.GetAttribute('name')): $($setting.InnerText)"
}

Write-Host "`nDB-Verbindung:" -ForegroundColor Cyan
$dbServer = $nsXml.SelectSingleNode("//db:Server", $nsManager)
$dbName = $nsXml.SelectSingleNode("//db:Database", $nsManager)
Write-Host "  Server: $($dbServer.InnerText)"
Write-Host "  Database: $($dbName.InnerText)"

#endregion

#region TEIL 6: Praxis - Konfigurationsdatei-Modul
#############################################################################

Write-Host "`n=== TEIL 6: Praxis-Beispiel ===" -ForegroundColor Cyan

function Get-XmlConfig {
    <#
    .SYNOPSIS
        Liest Konfigurationswerte aus einer XML-Datei.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [string]$Section,
        
        [Parameter()]
        [string]$Key
    )
    
    if (-not (Test-Path $Path)) {
        throw "Konfigurationsdatei nicht gefunden: $Path"
    }
    
    [xml]$config = Get-Content $Path -Encoding UTF8
    
    if ($Section -and $Key) {
        # Spezifischer Wert
        $xpath = "//$Section/$Key"
        $node = $config.SelectSingleNode($xpath)
        return $node.InnerText
    }
    elseif ($Section) {
        # Ganze Section
        $xpath = "//$Section/*"
        $nodes = $config.SelectNodes($xpath)
        
        $result = @{}
        foreach ($node in $nodes) {
            $result[$node.Name] = $node.InnerText
        }
        return [PSCustomObject]$result
    }
    else {
        # Gesamte Konfiguration als Objekt
        return $config
    }
}

function Set-XmlConfig {
    <#
    .SYNOPSIS
        Setzt einen Konfigurationswert in einer XML-Datei.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Section,
        
        [Parameter(Mandatory)]
        [string]$Key,
        
        [Parameter(Mandatory)]
        [string]$Value
    )
    
    if (-not (Test-Path $Path)) {
        throw "Konfigurationsdatei nicht gefunden: $Path"
    }
    
    [xml]$config = Get-Content $Path -Encoding UTF8
    
    $xpath = "//$Section/$Key"
    $node = $config.SelectSingleNode($xpath)
    
    if ($node) {
        if ($PSCmdlet.ShouldProcess("$Section/$Key", "Set value to '$Value'")) {
            $node.InnerText = $Value
            $config.Save($Path)
            Write-Verbose "Gesetzt: $Section/$Key = $Value"
        }
    }
    else {
        # Element erstellen wenn nicht vorhanden
        $sectionNode = $config.SelectSingleNode("//$Section")
        
        if (-not $sectionNode) {
            throw "Section nicht gefunden: $Section"
        }
        
        if ($PSCmdlet.ShouldProcess("$Section/$Key", "Create with value '$Value'")) {
            $newNode = $config.CreateElement($Key)
            $newNode.InnerText = $Value
            $sectionNode.AppendChild($newNode) | Out-Null
            $config.Save($Path)
            Write-Verbose "Erstellt: $Section/$Key = $Value"
        }
    }
}

# Demo
Write-Host "Config-Funktionen erstellt: Get-XmlConfig, Set-XmlConfig" -ForegroundColor Green

#endregion

#region ZUSAMMENFASSUNG
#############################################################################

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG - Modul 10" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

KERNPUNKTE:

1. XML LADEN:
   [xml]`$xml = Get-Content "file.xml"
   [xml]`$xml = `$xmlString

2. ELEMENTE ZUGREIFEN:
   `$xml.Root.Child.Grandchild
   `$xml.Root.Child.GetAttribute("name")

3. SELECT-XML MIT XPATH:
   Select-Xml -Xml `$xml -XPath "//Element"
   Select-Xml -Path "file.xml" -XPath "//Element[@attr='value']"

4. XML MODIFIZIEREN:
   `$node.InnerText = "neuer Wert"
   `$node.SetAttribute("name", "value")
   `$parent.AppendChild(`$newNode)

5. XML SPEICHERN:
   `$xml.Save("pfad.xml")

6. WICHTIGE XPATH SYNTAX:
   //Element     - Alle Elements überall
   /Root/Child   - Absoluter Pfad
   @attribute    - Attribut
   [condition]   - Filter
   text()        - Textinhalt

7. NAMESPACES:
   `$nsManager.AddNamespace("ns", "uri")
   `$xml.SelectNodes("//ns:Element", `$nsManager)

"@ -ForegroundColor White

# Cleanup
Remove-Item $xmlFilePath -ErrorAction SilentlyContinue

#endregion
