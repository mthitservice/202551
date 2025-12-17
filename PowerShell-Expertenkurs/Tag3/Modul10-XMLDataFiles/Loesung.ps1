#############################################################################
# Modul 10 - XML Data Files
# LÖSUNGEN
#############################################################################

#region Test-XML erstellen

# Produkt-Katalog XML für Übungen
$productCatalogXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<ProductCatalog>
    <Category name="Electronics">
        <Product id="E001" status="available">
            <Name>Laptop Pro X</Name>
            <Price currency="EUR">1299.99</Price>
            <Stock>45</Stock>
        </Product>
        <Product id="E002" status="available">
            <Name>Smartphone Ultra</Name>
            <Price currency="EUR">899.99</Price>
            <Stock>120</Stock>
        </Product>
        <Product id="E003" status="available">
            <Name>Tablet Mini</Name>
            <Price currency="EUR">449.99</Price>
            <Stock>75</Stock>
        </Product>
    </Category>
    <Category name="Accessories">
        <Product id="A001" status="discontinued">
            <Name>USB-C Hub</Name>
            <Price currency="EUR">49.99</Price>
            <Stock>0</Stock>
        </Product>
        <Product id="A002" status="available">
            <Name>Wireless Mouse</Name>
            <Price currency="EUR">29.99</Price>
            <Stock>200</Stock>
        </Product>
    </Category>
    <Category name="Software">
        <Product id="S001" status="available">
            <Name>Office Suite</Name>
            <Price currency="EUR">149.99</Price>
            <Stock>999</Stock>
        </Product>
    </Category>
</ProductCatalog>
"@

# Test-Datei erstellen
$testXmlPath = "$env:TEMP\ProductCatalog.xml"
$productCatalogXml | Out-File $testXmlPath -Encoding UTF8

#endregion

#region Übung 1: XML lesen und navigieren

function Get-ProductInfo {
    <#
    .SYNOPSIS
        Liest Produktinformationen aus einer XML-Katalog-Datei.
    
    .DESCRIPTION
        Navigiert durch die XML-Struktur und gibt Produkte als
        PowerShell-Objekte zurück mit optionaler Filterung.
    
    .EXAMPLE
        Get-ProductInfo -XmlPath "products.xml" -OnlyAvailable
    
    .EXAMPLE
        Get-ProductInfo -XmlPath "products.xml" -Category "Electronics"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,
        
        [Parameter()]
        [string]$Category,
        
        [Parameter()]
        [string]$ProductId,
        
        [Parameter()]
        [switch]$OnlyAvailable
    )
    
    try {
        [xml]$catalog = Get-Content $XmlPath -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        throw "Fehler beim Laden der XML-Datei: $_"
    }
    
    $results = @()
    
    foreach ($cat in $catalog.ProductCatalog.Category) {
        # Kategorie-Filter
        if ($Category -and $cat.name -ne $Category) {
            continue
        }
        
        foreach ($product in $cat.Product) {
            # Produkt-ID Filter
            if ($ProductId -and $product.id -ne $ProductId) {
                continue
            }
            
            # Verfügbarkeits-Filter
            if ($OnlyAvailable -and $product.status -ne 'available') {
                continue
            }
            
            $results += [PSCustomObject]@{
                ProductId = $product.id
                Name      = $product.Name
                Category  = $cat.name
                Price     = [decimal]$product.Price.'#text'
                Currency  = $product.Price.currency
                Stock     = [int]$product.Stock
                Status    = $product.status
            }
        }
    }
    
    return $results
}

# Tests
Write-Host "=== Übung 1: Get-ProductInfo ===" -ForegroundColor Green

Write-Host "`nAlle Produkte:" -ForegroundColor Yellow
Get-ProductInfo -XmlPath $testXmlPath | Format-Table

Write-Host "`nNur verfügbare Produkte:" -ForegroundColor Yellow
Get-ProductInfo -XmlPath $testXmlPath -OnlyAvailable | Format-Table

Write-Host "`nNur Electronics:" -ForegroundColor Yellow
Get-ProductInfo -XmlPath $testXmlPath -Category "Electronics" | Format-Table

Write-Host "`nEinzelnes Produkt (E001):" -ForegroundColor Yellow
Get-ProductInfo -XmlPath $testXmlPath -ProductId "E001" | Format-List

#endregion

#region Übung 2: XML mit XPath abfragen

function Search-XmlData {
    <#
    .SYNOPSIS
        Führt XPath-Abfragen auf XML-Daten aus.
    
    .EXAMPLE
        Search-XmlData -Path "file.xml" -XPath "//Product"
    
    .EXAMPLE
        Search-XmlData -Xml $xmlObject -XPath "//Price" -AsText
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,
        
        [Parameter(Mandatory, ParameterSetName = 'Xml')]
        [xml]$Xml,
        
        [Parameter(Mandatory)]
        [string]$XPath,
        
        [Parameter()]
        [hashtable]$Namespace,
        
        [Parameter()]
        [switch]$AsText
    )
    
    # XML laden
    if ($Path) {
        [xml]$Xml = Get-Content $Path -Encoding UTF8
    }
    
    # Namespace Manager erstellen falls nötig
    $nsManager = $null
    if ($Namespace) {
        $nsManager = New-Object System.Xml.XmlNamespaceManager($Xml.NameTable)
        foreach ($ns in $Namespace.GetEnumerator()) {
            $nsManager.AddNamespace($ns.Key, $ns.Value)
        }
    }
    
    # Abfrage ausführen
    try {
        $nodes = if ($nsManager) {
            $Xml.SelectNodes($XPath, $nsManager)
        } else {
            $Xml.SelectNodes($XPath)
        }
        
        if ($AsText) {
            $nodes | ForEach-Object { $_.InnerText }
        } else {
            $nodes
        }
    }
    catch {
        Write-Error "XPath-Fehler: $_"
    }
}

function Get-XmlElementCount {
    <#
    .SYNOPSIS
        Zählt Elemente die einem XPath entsprechen.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$XPath
    )
    
    $nodes = Search-XmlData -Path $Path -XPath $XPath
    return $nodes.Count
}

function Get-XmlAttributeValue {
    <#
    .SYNOPSIS
        Holt den Wert eines Attributs.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$ElementXPath,
        
        [Parameter(Mandatory)]
        [string]$AttributeName
    )
    
    $node = Search-XmlData -Path $Path -XPath $ElementXPath | Select-Object -First 1
    if ($node) {
        return $node.GetAttribute($AttributeName)
    }
    return $null
}

function Get-XmlDistinctValues {
    <#
    .SYNOPSIS
        Gibt eindeutige Werte eines Elements zurück.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$XPath
    )
    
    $values = Search-XmlData -Path $Path -XPath $XPath -AsText
    return $values | Sort-Object -Unique
}

# Tests
Write-Host "`n=== Übung 2: XPath Abfragen ===" -ForegroundColor Green

Write-Host "`n1. Alle Produkte mit Preis > 500:" -ForegroundColor Yellow
$expensive = Search-XmlData -Path $testXmlPath -XPath "//Product[Price>500]"
$expensive | ForEach-Object { Write-Host "  $($_.Name): $($_.Price.'#text')€" }

Write-Host "`n2. Produkte mit Stock = 0:" -ForegroundColor Yellow
$outOfStock = Search-XmlData -Path $testXmlPath -XPath "//Product[Stock=0]"
$outOfStock | ForEach-Object { Write-Host "  $($_.Name)" }

Write-Host "`n3. Alle Kategorienamen:" -ForegroundColor Yellow
$categories = Get-XmlDistinctValues -Path $testXmlPath -XPath "//Category/@name"
$categories | ForEach-Object { Write-Host "  $_" }

Write-Host "`n4. Anzahl Produkte:" -ForegroundColor Yellow
$count = Get-XmlElementCount -Path $testXmlPath -XPath "//Product"
Write-Host "  $count Produkte im Katalog"

Write-Host "`n5. Gesamtpreis aller Produkte:" -ForegroundColor Yellow
$prices = Search-XmlData -Path $testXmlPath -XPath "//Price" -AsText
$total = ($prices | ForEach-Object { [decimal]$_ } | Measure-Object -Sum).Sum
Write-Host "  Gesamt: $total€"

#endregion

#region Übung 3: XML erstellen und modifizieren

$script:InventoryPath = "$env:TEMP\ServerInventory.xml"

function New-ServerInventory {
    <#
    .SYNOPSIS
        Erstellt eine neue Server-Inventar XML-Datei.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = $script:InventoryPath
    )
    
    if (Test-Path $Path) {
        $confirm = Read-Host "Datei existiert. Überschreiben? (j/n)"
        if ($confirm -notmatch '^[JjYy]') {
            Write-Host "Abgebrochen." -ForegroundColor Yellow
            return
        }
    }
    
    $xml = New-Object System.Xml.XmlDocument
    
    # XML-Deklaration
    $declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", $null)
    $xml.AppendChild($declaration) | Out-Null
    
    # Root-Element
    $root = $xml.CreateElement("ServerInventory")
    $root.SetAttribute("created", (Get-Date -Format "yyyy-MM-dd"))
    $root.SetAttribute("lastModified", (Get-Date -Format "yyyy-MM-dd"))
    $xml.AppendChild($root) | Out-Null
    
    $xml.Save($Path)
    Write-Host "Inventar erstellt: $Path" -ForegroundColor Green
    
    return $xml
}

function Add-ServerToInventory {
    <#
    .SYNOPSIS
        Fügt einen Server zum Inventar hinzu.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Hostname,
        
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')]
        [string]$IPAddress,
        
        [Parameter()]
        [string]$OS = "Windows Server 2022",
        
        [Parameter()]
        [ValidateSet('Production', 'Staging', 'Development', 'Test')]
        [string]$Environment = "Production",
        
        [Parameter()]
        [string[]]$Roles = @(),
        
        [Parameter()]
        [string]$Path = $script:InventoryPath
    )
    
    if (-not (Test-Path $Path)) {
        throw "Inventar-Datei nicht gefunden: $Path"
    }
    
    # Backup erstellen
    $backupPath = "$Path.bak"
    Copy-Item $Path $backupPath -Force
    
    [xml]$inventory = Get-Content $Path -Encoding UTF8
    
    # Neue ID generieren
    $existingIds = $inventory.SelectNodes("//Server/@id") | ForEach-Object { $_.Value }
    $maxId = ($existingIds | ForEach-Object { [int]($_ -replace '\D', '') } | Measure-Object -Maximum).Maximum
    $newId = "SRV{0:D3}" -f (($maxId + 1), 1 | Measure-Object -Maximum).Maximum
    
    # Server-Element erstellen
    $server = $inventory.CreateElement("Server")
    $server.SetAttribute("id", $newId)
    $server.SetAttribute("environment", $Environment)
    
    # Kind-Elemente
    $hostnameEl = $inventory.CreateElement("Hostname")
    $hostnameEl.InnerText = $Hostname
    $server.AppendChild($hostnameEl) | Out-Null
    
    $ipEl = $inventory.CreateElement("IPAddress")
    $ipEl.InnerText = $IPAddress
    $server.AppendChild($ipEl) | Out-Null
    
    $osEl = $inventory.CreateElement("OS")
    $osEl.InnerText = $OS
    $server.AppendChild($osEl) | Out-Null
    
    # Rollen
    if ($Roles.Count -gt 0) {
        $rolesEl = $inventory.CreateElement("Roles")
        foreach ($role in $Roles) {
            $roleEl = $inventory.CreateElement("Role")
            $roleEl.InnerText = $role
            $rolesEl.AppendChild($roleEl) | Out-Null
        }
        $server.AppendChild($rolesEl) | Out-Null
    }
    
    $statusEl = $inventory.CreateElement("Status")
    $statusEl.InnerText = "Active"
    $server.AppendChild($statusEl) | Out-Null
    
    $lastSeenEl = $inventory.CreateElement("LastSeen")
    $lastSeenEl.InnerText = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $server.AppendChild($lastSeenEl) | Out-Null
    
    # Zum Inventar hinzufügen
    $inventory.DocumentElement.AppendChild($server) | Out-Null
    
    # lastModified aktualisieren
    $inventory.DocumentElement.SetAttribute("lastModified", (Get-Date -Format "yyyy-MM-dd"))
    
    $inventory.Save($Path)
    Write-Host "Server hinzugefügt: $newId ($Hostname)" -ForegroundColor Green
    
    return $newId
}

function Update-ServerStatus {
    <#
    .SYNOPSIS
        Aktualisiert den Status eines Servers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServerId,
        
        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Inactive', 'Maintenance', 'Decommissioned')]
        [string]$Status,
        
        [Parameter()]
        [string]$Path = $script:InventoryPath
    )
    
    if (-not (Test-Path $Path)) {
        throw "Inventar-Datei nicht gefunden: $Path"
    }
    
    # Backup
    Copy-Item $Path "$Path.bak" -Force
    
    [xml]$inventory = Get-Content $Path -Encoding UTF8
    
    $server = $inventory.SelectSingleNode("//Server[@id='$ServerId']")
    
    if (-not $server) {
        throw "Server nicht gefunden: $ServerId"
    }
    
    $server.Status = $Status
    $server.LastSeen = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $inventory.DocumentElement.SetAttribute("lastModified", (Get-Date -Format "yyyy-MM-dd"))
    
    $inventory.Save($Path)
    Write-Host "Status aktualisiert: $ServerId -> $Status" -ForegroundColor Green
}

function Remove-ServerFromInventory {
    <#
    .SYNOPSIS
        Entfernt einen Server aus dem Inventar.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ServerId,
        
        [Parameter()]
        [string]$Path = $script:InventoryPath
    )
    
    if (-not (Test-Path $Path)) {
        throw "Inventar-Datei nicht gefunden: $Path"
    }
    
    [xml]$inventory = Get-Content $Path -Encoding UTF8
    
    $server = $inventory.SelectSingleNode("//Server[@id='$ServerId']")
    
    if (-not $server) {
        throw "Server nicht gefunden: $ServerId"
    }
    
    $hostname = $server.Hostname
    
    if ($PSCmdlet.ShouldProcess("$ServerId ($hostname)", "Remove from inventory")) {
        # Backup
        Copy-Item $Path "$Path.bak" -Force
        
        $server.ParentNode.RemoveChild($server) | Out-Null
        $inventory.DocumentElement.SetAttribute("lastModified", (Get-Date -Format "yyyy-MM-dd"))
        
        $inventory.Save($Path)
        Write-Host "Server entfernt: $ServerId ($hostname)" -ForegroundColor Yellow
    }
}

function Get-ServerInventory {
    <#
    .SYNOPSIS
        Liest das Server-Inventar.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ServerId,
        
        [Parameter()]
        [ValidateSet('Production', 'Staging', 'Development', 'Test')]
        [string]$Environment,
        
        [Parameter()]
        [ValidateSet('Active', 'Inactive', 'Maintenance', 'Decommissioned')]
        [string]$Status,
        
        [Parameter()]
        [string]$Path = $script:InventoryPath
    )
    
    if (-not (Test-Path $Path)) {
        throw "Inventar-Datei nicht gefunden: $Path"
    }
    
    [xml]$inventory = Get-Content $Path -Encoding UTF8
    
    # XPath aufbauen
    $xpath = "//Server"
    $conditions = @()
    
    if ($ServerId) { $conditions += "@id='$ServerId'" }
    if ($Environment) { $conditions += "@environment='$Environment'" }
    if ($Status) { $conditions += "Status='$Status'" }
    
    if ($conditions.Count -gt 0) {
        $xpath += "[" + ($conditions -join " and ") + "]"
    }
    
    $servers = $inventory.SelectNodes($xpath)
    
    $servers | ForEach-Object {
        [PSCustomObject]@{
            ServerId    = $_.id
            Hostname    = $_.Hostname
            IPAddress   = $_.IPAddress
            OS          = $_.OS
            Environment = $_.GetAttribute("environment")
            Roles       = ($_.Roles.Role | ForEach-Object { $_ }) -join ", "
            Status      = $_.Status
            LastSeen    = [datetime]$_.LastSeen
        }
    }
}

# Tests
Write-Host "`n=== Übung 3: Server-Inventar ===" -ForegroundColor Green

Write-Host "`nErstelle neues Inventar:" -ForegroundColor Yellow
New-ServerInventory -Path $script:InventoryPath | Out-Null

Write-Host "`nFüge Server hinzu:" -ForegroundColor Yellow
Add-ServerToInventory -Hostname "webserver01" -IPAddress "192.168.1.10" -Roles @("WebServer", "FileServer")
Add-ServerToInventory -Hostname "dbserver01" -IPAddress "192.168.1.20" -Environment "Production" -Roles @("Database")
Add-ServerToInventory -Hostname "devserver01" -IPAddress "192.168.1.100" -Environment "Development"

Write-Host "`nInventar anzeigen:" -ForegroundColor Yellow
Get-ServerInventory | Format-Table

Write-Host "`nStatus aktualisieren:" -ForegroundColor Yellow
Update-ServerStatus -ServerId "SRV002" -Status "Maintenance"

Write-Host "`nNur Production-Server:" -ForegroundColor Yellow
Get-ServerInventory -Environment Production | Format-Table

#endregion

#region Übung 4 (Bonus): XML-Transformation

function Convert-XmlToHtml {
    <#
    .SYNOPSIS
        Konvertiert XML zu einer HTML-Tabelle.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [xml]$Xml,
        
        [Parameter()]
        [string]$Title = "XML Data",
        
        [Parameter()]
        [string]$RootElement,
        
        [Parameter()]
        [string]$CssStyle = @"
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; }
tr:nth-child(even) { background-color: #f2f2f2; }
tr:hover { background-color: #ddd; }
"@
    )
    
    # Root-Element finden
    $root = if ($RootElement) {
        $Xml.SelectSingleNode("//$RootElement")
    } else {
        $Xml.DocumentElement
    }
    
    if (-not $root) {
        throw "Root-Element nicht gefunden"
    }
    
    # Kinder sammeln (erste Ebene unter Root)
    $items = $root.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }
    
    if ($items.Count -eq 0) {
        throw "Keine Elemente zum Konvertieren gefunden"
    }
    
    # Spalten aus erstem Element ermitteln
    $columns = @()
    $firstItem = $items[0]
    
    # Attribute
    foreach ($attr in $firstItem.Attributes) {
        $columns += @{ Name = "@$($attr.Name)"; Type = 'Attribute' }
    }
    
    # Kind-Elemente
    foreach ($child in $firstItem.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }) {
        $columns += @{ Name = $child.Name; Type = 'Element' }
    }
    
    # HTML generieren
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>$CssStyle</style>
</head>
<body>
    <h1>$Title</h1>
    <table>
        <thead>
            <tr>
"@
    
    foreach ($col in $columns) {
        $html += "                <th>$($col.Name)</th>`n"
    }
    
    $html += @"
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($item in $items) {
        $html += "            <tr>`n"
        
        foreach ($col in $columns) {
            $value = if ($col.Type -eq 'Attribute') {
                $attrName = $col.Name -replace '^@', ''
                $item.GetAttribute($attrName)
            } else {
                $item.SelectSingleNode($col.Name).InnerText
            }
            $html += "                <td>$([System.Web.HttpUtility]::HtmlEncode($value))</td>`n"
        }
        
        $html += "            </tr>`n"
    }
    
    $html += @"
        </tbody>
    </table>
    <p><small>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</small></p>
</body>
</html>
"@
    
    return $html
}

function Convert-XmlToJson {
    <#
    .SYNOPSIS
        Konvertiert XML zu JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [xml]$Xml,
        
        [Parameter()]
        [int]$Depth = 10
    )
    
    function ConvertNode {
        param([System.Xml.XmlNode]$Node)
        
        $result = @{}
        
        # Attribute
        if ($Node.Attributes) {
            foreach ($attr in $Node.Attributes) {
                $result["@$($attr.Name)"] = $attr.Value
            }
        }
        
        # Kinder
        $children = $Node.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }
        
        if ($children.Count -eq 0) {
            # Nur Text
            if ($Node.InnerText) {
                if ($result.Count -eq 0) {
                    return $Node.InnerText
                }
                $result['#text'] = $Node.InnerText
            }
        }
        else {
            # Kind-Elemente gruppieren
            $grouped = $children | Group-Object -Property Name
            
            foreach ($group in $grouped) {
                if ($group.Count -eq 1) {
                    $result[$group.Name] = ConvertNode $group.Group[0]
                }
                else {
                    $result[$group.Name] = @($group.Group | ForEach-Object { ConvertNode $_ })
                }
            }
        }
        
        return $result
    }
    
    $converted = @{
        $Xml.DocumentElement.Name = ConvertNode $Xml.DocumentElement
    }
    
    return $converted | ConvertTo-Json -Depth $Depth
}

function Merge-XmlDocuments {
    <#
    .SYNOPSIS
        Führt zwei XML-Dokumente zusammen.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [xml]$TargetXml,
        
        [Parameter(Mandatory)]
        [xml]$SourceXml,
        
        [Parameter()]
        [ValidateSet('Replace', 'Append', 'Skip')]
        [string]$Strategy = 'Append',
        
        [Parameter()]
        [string]$KeyAttribute = 'id'
    )
    
    $sourceItems = $SourceXml.DocumentElement.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }
    
    foreach ($sourceItem in $sourceItems) {
        $key = $sourceItem.GetAttribute($KeyAttribute)
        $existingItem = $TargetXml.SelectSingleNode("//$($sourceItem.Name)[@$KeyAttribute='$key']")
        
        if ($existingItem) {
            switch ($Strategy) {
                'Replace' {
                    $imported = $TargetXml.ImportNode($sourceItem, $true)
                    $existingItem.ParentNode.ReplaceChild($imported, $existingItem) | Out-Null
                    Write-Verbose "Replaced: $key"
                }
                'Skip' {
                    Write-Verbose "Skipped: $key (exists)"
                }
                'Append' {
                    # Bei Append: Duplikate erlauben
                    $imported = $TargetXml.ImportNode($sourceItem, $true)
                    $TargetXml.DocumentElement.AppendChild($imported) | Out-Null
                    Write-Verbose "Appended: $key (duplicate)"
                }
            }
        }
        else {
            $imported = $TargetXml.ImportNode($sourceItem, $true)
            $TargetXml.DocumentElement.AppendChild($imported) | Out-Null
            Write-Verbose "Added: $key"
        }
    }
    
    return $TargetXml
}

# Tests
Write-Host "`n=== Übung 4 (Bonus): XML-Transformation ===" -ForegroundColor Green

Write-Host "`nConvert-XmlToHtml Demo:" -ForegroundColor Yellow
[xml]$testXml = Get-Content $testXmlPath
$html = Convert-XmlToHtml -Xml $testXml -Title "Produkt-Katalog" -RootElement "Category"
$htmlPath = "$env:TEMP\products.html"
$html | Out-File $htmlPath -Encoding UTF8
Write-Host "HTML gespeichert: $htmlPath"

Write-Host "`nConvert-XmlToJson Demo:" -ForegroundColor Yellow
$json = Convert-XmlToJson -Xml $testXml
Write-Host $json.Substring(0, [Math]::Min(500, $json.Length)) "..."

#endregion

#region Zusammenfassung
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALLE LÖSUNGEN GELADEN" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host @"

Verfügbare Funktionen:

Übung 1 - XML lesen:
  - Get-ProductInfo

Übung 2 - XPath:
  - Search-XmlData
  - Get-XmlElementCount
  - Get-XmlAttributeValue
  - Get-XmlDistinctValues

Übung 3 - Server-Inventar:
  - New-ServerInventory
  - Add-ServerToInventory
  - Update-ServerStatus
  - Remove-ServerFromInventory
  - Get-ServerInventory

Bonus - Transformation:
  - Convert-XmlToHtml
  - Convert-XmlToJson
  - Merge-XmlDocuments

Test-Dateien:
  $testXmlPath
  $script:InventoryPath

"@ -ForegroundColor White

#endregion
