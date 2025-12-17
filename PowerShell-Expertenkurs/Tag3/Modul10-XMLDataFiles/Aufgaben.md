# Modul 10 - XML Data Files
## Übungsaufgaben für Teilnehmer

**Zeitrahmen:** ca. 60 Minuten

---

## Übung 1: XML lesen und navigieren (15 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Get-ProductInfo`, die Produktinformationen aus einer XML-Datei liest.

**Gegeben ist folgende XML-Struktur:**
```xml
<?xml version="1.0"?>
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
    </Category>
    <Category name="Accessories">
        <Product id="A001" status="discontinued">
            <Name>USB-C Hub</Name>
            <Price currency="EUR">49.99</Price>
            <Stock>0</Stock>
        </Product>
    </Category>
</ProductCatalog>
```

**Funktion soll unterstützen:**
- Parameter: `XmlPath` (Pfad zur XML-Datei)
- Parameter: `Category` (optional, filtert nach Kategorie)
- Parameter: `ProductId` (optional, einzelnes Produkt)
- Parameter: `OnlyAvailable` (Switch, nur verfügbare Produkte)

**Ausgabe als PSCustomObject mit:**
- ProductId, Name, Category, Price, Currency, Stock, Status

### Erwartetes Ergebnis

```powershell
Get-ProductInfo -XmlPath "products.xml" -OnlyAvailable
# Zeigt nur Produkte mit status="available"

Get-ProductInfo -XmlPath "products.xml" -Category "Electronics"
# Zeigt nur Elektronik-Produkte

Get-ProductInfo -XmlPath "products.xml" -ProductId "E001"
# Zeigt nur das Produkt mit ID E001
```

---

## Übung 2: XML mit XPath abfragen (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Search-XmlData`, die XPath-Abfragen auf XML-Dateien ermöglicht.

**Anforderungen:**
- Parameter: `Path` oder `Xml` (Datei oder XML-Objekt)
- Parameter: `XPath` (die XPath-Abfrage)
- Parameter: `Namespace` (hashtable, optional für NS)
- Parameter: `AsText` (Switch, gibt nur InnerText zurück)

**Zusätzlich: Erstellen Sie vordefinierte Abfragen:**
- `Get-XmlElementCount` - Zählt Elemente
- `Get-XmlAttributeValue` - Holt Attributwert
- `Get-XmlDistinctValues` - Eindeutige Werte eines Elements

### Zu implementierende XPath-Abfragen:
1. Alle Produkte mit Preis > 500
2. Produkte mit Stock = 0
3. Alle Kategorienamen (distinct)
4. Summe aller Preise (über PowerShell berechnen)
5. Produkte sortiert nach Preis

---

## Übung 3: XML erstellen und modifizieren (20 Min)

### Aufgabenstellung

Erstellen Sie ein Modul für Server-Inventarisierung mit XML-Backend.

**Funktionen:**
1. `New-ServerInventory` - Erstellt neue XML-Inventardatei
2. `Add-ServerToInventory` - Fügt Server hinzu
3. `Update-ServerStatus` - Aktualisiert Server-Status
4. `Remove-ServerFromInventory` - Entfernt Server
5. `Get-ServerInventory` - Liest Inventar

**XML-Struktur:**
```xml
<?xml version="1.0"?>
<ServerInventory created="2024-01-15" lastModified="2024-01-20">
    <Server id="SRV001" environment="Production">
        <Hostname>webserver01</Hostname>
        <IPAddress>192.168.1.10</IPAddress>
        <OS>Windows Server 2022</OS>
        <Roles>
            <Role>WebServer</Role>
            <Role>FileServer</Role>
        </Roles>
        <Status>Active</Status>
        <LastSeen>2024-01-20T10:30:00</LastSeen>
    </Server>
</ServerInventory>
```

### Anforderungen:
- Jede Modifikation aktualisiert `lastModified`
- IDs werden automatisch generiert
- Validierung der IP-Adresse
- Backup vor Änderungen erstellen

---

## Übung 4: XML-Transformation (Bonus)

### Aufgabenstellung

Erstellen Sie Funktionen zur XML-Transformation.

**1. `Convert-XmlToHtml`**
- Transformiert XML zu HTML-Tabelle
- Unterstützt CSS-Styling

**2. `Convert-XmlToJson`**
- Konvertiert XML zu JSON
- Behandelt Attribute und Elemente korrekt

**3. `Merge-XmlDocuments`**
- Führt zwei XML-Dateien zusammen
- Parameter für Merge-Strategie (Replace, Append, Skip)

### Beispiel Convert-XmlToHtml:

```powershell
$xml = @"
<Products>
    <Product><Name>Item1</Name><Price>100</Price></Product>
    <Product><Name>Item2</Name><Price>200</Price></Product>
</Products>
"@

Convert-XmlToHtml -Xml $xml -Title "Produktliste" | Out-File "products.html"

# Erzeugt HTML-Tabelle mit Styling
```

---

## Bewertungskriterien

| Kriterium | Punkte |
|-----------|--------|
| XML korrekt geladen und navigiert | 20 |
| XPath-Abfragen funktionieren | 25 |
| XML erstellen und modifizieren | 25 |
| Fehlerbehandlung bei XML-Operationen | 15 |
| Bonus: XML-Transformation | 15 |

---

## Hilfreiche Ressourcen

```powershell
# XML laden
[xml]$xml = Get-Content "file.xml"
[xml]$xml = $xmlString

# XPath
Select-Xml -Xml $xml -XPath "//Element"
$xml.SelectSingleNode("//Element")
$xml.SelectNodes("//Element[@attr='value']")

# Element erstellen
$newElement = $xml.CreateElement("Name")
$newElement.InnerText = "Wert"
$parent.AppendChild($newElement)

# Attribute
$element.GetAttribute("name")
$element.SetAttribute("name", "value")

# Speichern
$xml.Save("file.xml")
```

### XPath Cheat Sheet:

| XPath | Beschreibung |
|-------|-------------|
| `//Element` | Alle Elements überall |
| `/Root/Child` | Absoluter Pfad |
| `//Element[@attr='value']` | Element mit Attribut-Wert |
| `//Element[Child='value']` | Element mit Kind-Wert |
| `//Element[position()=1]` | Erstes Element |
| `//Element[last()]` | Letztes Element |
| `//Element[Price>100]` | Numerischer Vergleich |
| `//Element/text()` | Textinhalt |
| `//@attribute` | Alle Attribute |

---

## Checkliste vor Abgabe

- [ ] XML-Dateien werden mit [xml] geladen
- [ ] XPath-Abfragen liefern korrekte Ergebnisse
- [ ] XML-Modifikationen werden gespeichert
- [ ] Fehlerbehandlung für ungültiges XML
- [ ] Encoding wird berücksichtigt (UTF-8)
- [ ] Namespaces werden korrekt behandelt (falls vorhanden)
