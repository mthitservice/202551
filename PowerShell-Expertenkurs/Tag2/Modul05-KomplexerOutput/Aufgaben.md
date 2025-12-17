# Modul 05: Komplexer Funktions-Output - Übungsaufgaben

## Übersicht
**Dauer:** ca. 60 Minuten  
**Schwierigkeit:** Fortgeschritten

---

## Aufgabe 1: Custom Objects erstellen (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-NetworkStatus` die Netzwerk-Informationen als strukturierte Objekte zurückgibt:

1. **Output-Struktur (PSCustomObject):**
   - AdapterName
   - Status (Up/Down)
   - IPAddress (kann Array sein)
   - SubnetMask
   - Gateway
   - DNSServers (Array)
   - SpeedMbps
   - MACAddress
   - IsPhysical (Boolean)

2. **Anforderungen:**
   - Nutzen Sie `[ordered]@{}` für konsistente Reihenfolge
   - Setzen Sie `PSTypeName = 'NetworkStatusReport'`
   - Fügen Sie `[OutputType('NetworkStatusReport')]` hinzu
   - Nur aktive Adapter (Status = 'Up')

### Erwartete Nutzung
```powershell
Get-NetworkStatus | Format-Table
Get-NetworkStatus | Where-Object IsPhysical | Format-List
```

---

## Aufgabe 2: Verschachtelte Objekte (20 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-UserProfile` die ein umfassendes Benutzerprofil erstellt:

1. **Haupt-Objekt:**
   - UserName
   - Domain
   - SID
   - ProfilePath
   - LastLogon
   - IsAdmin (Boolean)

2. **Verschachteltes Objekt "Environment":**
   - HomeDrive
   - TempPath
   - SystemRoot
   - PSModulePath (als Array)

3. **Verschachteltes Array "RecentFiles" (letzte 5):**
   - Pro Datei: Name, FullPath, LastAccess, SizeKB

4. **Verschachteltes Objekt "DiskQuota" (wenn verfügbar):**
   - QuotaLimit
   - QuotaUsed
   - QuotaRemaining
   - PercentUsed

### Erwartete Nutzung
```powershell
$profile = Get-UserProfile
$profile.Environment | Format-List
$profile.RecentFiles | Format-Table
```

---

## Aufgabe 3: PowerShell Klasse (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Klasse `ServiceMonitor` zur Überwachung von Windows-Diensten:

1. **Properties:**
   - ServiceName [string]
   - DisplayName [string]
   - Status [string]
   - StartType [string]
   - LastChecked [datetime]
   - History [array] - Statusänderungen

2. **Konstruktor:**
   - Akzeptiert ServiceName
   - Lädt aktuelle Service-Infos

3. **Methoden:**
   - `[void] Refresh()` - Aktualisiert Status, fügt zu History hinzu
   - `[bool] IsRunning()` - Gibt true zurück wenn Running
   - `[void] Start()` - Startet den Service (mit ShouldProcess-Logik)
   - `[void] Stop()` - Stoppt den Service
   - `[string] ToString()` - Formatierte Ausgabe

4. **Statische Methode:**
   - `[ServiceMonitor[]] GetCritical()` - Gibt alle Automatic-Services zurück die nicht laufen

### Erwartete Nutzung
```powershell
$svc = [ServiceMonitor]::new("Spooler")
$svc.Refresh()
$svc.IsRunning()
$svc.History

[ServiceMonitor]::GetCritical() | Format-Table
```

---

## Aufgabe 4: Format-Datei erstellen (10 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Format-Datei `NetworkStatusReport.Format.ps1xml`:

1. **Table View:**
   - Spalten: Adapter (20), Status (8), IP Address (15), Speed (10), Physical (8)
   - Speed formatiert als "X Mbps"
   - Physical als "Yes/No" statt True/False
   - Status farblich (wenn möglich via ScriptBlock)

2. **List View:**
   - Alle Properties mit benutzerfreundlichen Labels
   - DNS-Server als komma-separierte Liste
   - MAC-Adresse formatiert (XX:XX:XX:XX:XX:XX)

3. **Wide View:**
   - Nur AdapterName
   - 3 Spalten

### Testen
```powershell
Update-FormatData -PrependPath .\NetworkStatusReport.Format.ps1xml
Get-NetworkStatus | Format-Table
Get-NetworkStatus | Format-List
Get-NetworkStatus | Format-Wide
```

---

## Bonusaufgabe: Type Extension (Optional, +15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Types-Datei `ServiceMonitor.Types.ps1xml`:

1. **ScriptMethods:**
   - `GetDependencies()` - Gibt abhängige Services zurück
   - `GetUptime()` - Berechnet wie lange Service läuft

2. **ScriptProperties:**
   - `DependencyCount` - Anzahl abhängiger Services
   - `IsAutoStart` - True wenn StartType = Automatic

3. **AliasProperties:**
   - `Name` als Alias für `ServiceName`

### Anwendung
```powershell
Update-TypeData -PrependPath .\ServiceMonitor.Types.ps1xml

$svc = [ServiceMonitor]::new("Spooler")
$svc.Name  # Alias
$svc.IsAutoStart  # ScriptProperty
$svc.GetDependencies()  # ScriptMethod
```

---

## Abgabe-Checkliste

### Aufgabe 1
- [ ] [ordered]@{} verwendet
- [ ] PSTypeName gesetzt
- [ ] [OutputType()] deklariert
- [ ] Nur aktive Adapter

### Aufgabe 2
- [ ] Haupt-Objekt mit allen Properties
- [ ] Environment als verschachteltes Objekt
- [ ] RecentFiles als Array
- [ ] Zugriff auf verschachtelte Daten funktioniert

### Aufgabe 3
- [ ] Klasse mit allen Properties
- [ ] Konstruktor funktioniert
- [ ] Alle Methoden implementiert
- [ ] Statische Methode funktioniert
- [ ] History wird geführt

### Aufgabe 4
- [ ] Format-Datei ist gültiges XML
- [ ] Table View funktioniert
- [ ] List View funktioniert
- [ ] Wide View funktioniert

---

## Tipps

1. **Verschachtelte Objekte erstellen:**
   ```powershell
   [PSCustomObject]@{
       Main = "Value"
       Nested = [PSCustomObject]@{
           Sub1 = "A"
           Sub2 = "B"
       }
   }
   ```

2. **Klassen-Syntax:**
   ```powershell
   class MyClass {
       [string]$Property
       
       MyClass([string]$value) {
           $this.Property = $value
       }
       
       [string] MyMethod() {
           return $this.Property
       }
   }
   ```

3. **Format-XML validieren:**
   ```powershell
   [xml]$xml = Get-Content .\MyFormat.ps1xml
   ```

4. **TypeNames prüfen:**
   ```powershell
   $obj.PSObject.TypeNames
   ```
