# Modul 04: Multiple Objects und Pipeline Input - Übungsaufgaben

## Übersicht
**Dauer:** ca. 60 Minuten  
**Schwierigkeit:** Fortgeschritten

---

## Aufgabe 1: Basis Pipeline-Funktion (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-FileInfo` die Datei-Informationen sammelt:

1. **Parameter:**
   - `-Path` (Pflicht)
     - Akzeptiert einzelnen Pfad oder Array
     - Akzeptiert Pipeline-Input (sowohl String als auch FileInfo-Objekte)
     - Alias: 'FilePath', 'FullName'

2. **Anforderungen:**
   - Verwendet `[CmdletBinding()]`
   - Nutzt `process {}` Block
   - Gibt für jede Datei ein PSCustomObject zurück mit:
     - Name
     - FullPath
     - SizeMB (gerundet auf 2 Stellen)
     - Extension
     - LastModified
     - IsReadOnly

3. **Fehlerbehandlung:**
   - Ungültige Pfade werden mit `Write-Warning` gemeldet
   - Verarbeitung geht weiter mit nächster Datei

### Erwartete Nutzung
```powershell
# Als Parameter
Get-FileInfo -Path "C:\Windows\notepad.exe", "C:\Windows\regedit.exe"

# Per Pipeline (Strings)
"C:\Windows\notepad.exe", "C:\Windows\regedit.exe" | Get-FileInfo

# Per Pipeline (FileInfo)
Get-ChildItem C:\Windows\*.exe | Get-FileInfo | Sort-Object SizeMB -Descending
```

---

## Aufgabe 2: Begin/Process/End mit Statistiken (20 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Measure-FolderContents` die Ordnerinhalte analysiert:

1. **Parameter:**
   - `-FolderPath` (Pipeline-fähig)
   - `-IncludeSubfolders` (Switch)
   - `-MinSizeKB` (Standard: 0)

2. **Begin-Block:**
   - Initialisiere Zähler für: TotalFiles, TotalFolders, TotalSizeBytes
   - Initialisiere Hash-Tabelle für Extension-Statistik
   - Startzeit speichern

3. **Process-Block:**
   - Für jeden Ordner: Dateien zählen und aufsummieren
   - Extension-Statistik aktualisieren
   - Einzelergebnisse per Streaming ausgeben

4. **End-Block:**
   - Zusammenfassung ausgeben:
     - Gesamtzahl Dateien/Ordner
     - Gesamtgröße in MB/GB
     - Top 5 Extensions nach Anzahl
     - Verarbeitungsdauer

### Erwartete Nutzung
```powershell
# Einzelner Ordner
Measure-FolderContents -FolderPath "C:\Windows\Temp"

# Mehrere Ordner per Pipeline
"C:\Windows\Temp", "C:\Users\Public" | Measure-FolderContents -IncludeSubfolders
```

---

## Aufgabe 3: Multi-Computer Pipeline (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-RemoteSystemInfo` für Systemabfragen:

1. **Parameter:**
   - `-ComputerName` (Pipeline-fähig, ValueFromPipelineByPropertyName)
     - Aliase: 'CN', 'Server', 'Hostname', 'Name'
   - `-IncludeDisks` (Switch)
   - `-Credential` (Optional, für echte Remote-Abfragen)

2. **Verhalten:**
   - Akzeptiert Computer-Namen per Pipeline
   - Sammelt: OS-Info, Uptime, Memory, optional Disk-Info
   - Simuliert Remote-Abfrage (nutzt lokale Daten für Demo)

3. **Output pro Computer:**
   - ComputerName
   - OperatingSystem
   - OSVersion
   - UptimeDays
   - TotalMemoryGB
   - FreeMemoryGB
   - MemoryUsedPercent
   - (Optional) Disks als verschachtelte Objekte

### Erwartete Nutzung
```powershell
# Einfach
Get-RemoteSystemInfo -ComputerName "Server01", "Server02"

# Per Pipeline
"Server01", "Server02" | Get-RemoteSystemInfo -IncludeDisks

# Von CSV
Import-Csv servers.csv | Get-RemoteSystemInfo | Export-Csv report.csv
```

---

## Aufgabe 4: Streaming-Verarbeitung (10 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `ConvertTo-HashedObject` für große Datenmengen:

1. **Parameter:**
   - `-InputObject` (Pipeline-fähig, akzeptiert jedes Objekt)
   - `-Property` (String-Array) - Eigenschaften die gehasht werden
   - `-Algorithm` (ValidateSet: MD5, SHA1, SHA256, Standard: SHA256)

2. **Anforderungen:**
   - MUSS per Streaming arbeiten (keine Sammlung)
   - Fügt Hash-Werte als neue Properties hinzu
   - Original-Objekt bleibt erhalten

3. **Beispiel Output:**
   ```
   Name     Email              Email_SHA256
   ----     -----              ------------
   John     john@test.com      a1b2c3d4...
   ```

### Erwartete Nutzung
```powershell
# User-Daten anonymisieren
Import-Csv users.csv | 
    ConvertTo-HashedObject -Property Email, Phone -Algorithm SHA256 |
    Export-Csv users_anonymized.csv
```

---

## Bonusaufgabe: Pipeline-Abbruch erkennen (Optional, +15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Find-LargeFile` mit intelligenter Pipeline-Behandlung:

1. **Funktion soll:**
   - Dateien durchsuchen und große Dateien finden
   - Bei `Select-Object -First X` effizient abbrechen
   - Cleanup in end{} durchführen auch bei Abbruch

2. **Nutzen Sie:**
   - `$PSCmdlet.StopProcessing` für Abbruch-Erkennung
   - try/finally für garantiertes Cleanup

3. **Demo des Verhaltens:**
   ```powershell
   # Sollte nach 3 Dateien aufhören zu suchen
   Get-ChildItem C:\ -Recurse | Find-LargeFile -MinSizeMB 100 | Select-Object -First 3
   ```

---

## Abgabe-Checkliste

### Aufgabe 1
- [ ] ValueFromPipeline funktioniert
- [ ] ValueFromPipelineByPropertyName funktioniert
- [ ] Alias funktioniert
- [ ] Fehlerbehandlung implementiert
- [ ] process{} Block verwendet

### Aufgabe 2
- [ ] Begin-Block initialisiert Variablen
- [ ] Process-Block sammelt Statistiken
- [ ] End-Block gibt Zusammenfassung aus
- [ ] Streaming funktioniert

### Aufgabe 3
- [ ] Multiple Aliase funktionieren
- [ ] Computer-Objekte per Pipeline akzeptiert
- [ ] Verschachtelter Output für Disks

### Aufgabe 4
- [ ] Echtes Streaming (keine Sammlung)
- [ ] Hash-Werte korrekt berechnet
- [ ] Original-Objekt erhalten

---

## Tipps

1. **Pipeline-Debugging:**
   ```powershell
   1..3 | ForEach-Object { Write-Verbose "Verarbeite $_" -Verbose; $_ }
   ```

2. **Prüfen ob Pipeline verwendet wird:**
   ```powershell
   $PSCmdlet.MyInvocation.ExpectingInput
   ```

3. **Hash berechnen:**
   ```powershell
   [System.Security.Cryptography.SHA256]::Create().ComputeHash(
       [System.Text.Encoding]::UTF8.GetBytes("text")
   )
   ```

4. **Typische Fehler:**
   - Vergessen von `process {}` = nur letztes Objekt
   - `$input` statt benanntem Parameter
   - Sammeln statt Streaming bei großen Daten
