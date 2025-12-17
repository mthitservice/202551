# Modul 01: Erweiterte Funktionen - Übungsaufgaben

## Übersicht
**Dauer:** ca. 60 Minuten  
**Schwierigkeit:** Mittel bis Fortgeschritten

---

## Aufgabe 1: Einfache zu erweiterter Funktion (15 Minuten)

### Ausgangslage
Sie haben folgenden Einzeiler, der Informationen über laufende Prozesse anzeigt:

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 } | Select-Object Name, Id, CPU, WorkingSet64 | Sort-Object CPU -Descending
```

### Ihre Aufgabe
1. Konvertieren Sie diesen Befehl in eine erweiterte Funktion namens `Get-HighCpuProcess`
2. Fügen Sie einen Parameter `-MinimumCPU` hinzu (Standard: 10)
3. Fügen Sie einen Parameter `-Top` hinzu, der die Anzahl der Ergebnisse begrenzt (Standard: 10)
4. Nutzen Sie `Write-Verbose` für Statusmeldungen
5. Die Funktion soll das Working Set in MB anzeigen (nicht Bytes)

### Erwartete Nutzung
```powershell
Get-HighCpuProcess -MinimumCPU 5 -Top 5 -Verbose
```

---

## Aufgabe 2: Service-Management Funktion (20 Minuten)

### Ihre Aufgabe
Erstellen Sie eine erweiterte Funktion `Get-ServiceHealthReport`, die:

1. **Parameter:**
   - `-ComputerName` (Standard: lokaler Computer)
   - `-Status` mit ValidateSet für 'Running', 'Stopped', 'All' (Standard: 'All')
   - `-StartType` mit ValidateSet für 'Automatic', 'Manual', 'Disabled', 'All' (Standard: 'All')

2. **Anforderungen:**
   - Nutzt `[CmdletBinding()]`
   - Gibt ein Custom Object mit folgenden Eigenschaften zurück:
     - ServiceName
     - DisplayName
     - Status
     - StartType
     - IsHealthy (Boolean: True wenn Running bei Automatic StartType)
   - Verwendet `Write-Verbose` für Logging
   - Zählt am Ende die Anzahl der gefundenen Services

### Erwartete Nutzung
```powershell
Get-ServiceHealthReport -Status Running -StartType Automatic -Verbose
Get-ServiceHealthReport -Status Stopped | Where-Object { -not $_.IsHealthy }
```

---

## Aufgabe 3: Dateisystem-Analyse Funktion (25 Minuten)

### Ihre Aufgabe
Erstellen Sie eine erweiterte Funktion `Get-FolderSizeReport`, die:

1. **Parameter:**
   - `-Path` (Pflichtparameter) - Der zu analysierende Pfad
   - `-MinimumSizeMB` (Standard: 0) - Nur Ordner über dieser Größe anzeigen
   - `-Depth` (Standard: 1) - Wie tief rekursiv gesucht wird
   - `-IncludeFiles` (Switch) - Auch einzelne große Dateien anzeigen

2. **CmdletBinding Konfiguration:**
   - Nutzen Sie `DefaultParameterSetName`
   - Definieren Sie `[OutputType()]`

3. **Output:**
   - Name (Ordner- oder Dateiname)
   - FullPath
   - Type ('Folder' oder 'File')
   - SizeMB (gerundet auf 2 Nachkommastellen)
   - ItemCount (Anzahl Dateien im Ordner, oder $null bei Dateien)

4. **Zusatzanforderungen:**
   - Fehlerbehandlung mit try/catch für Zugriffsfehler
   - Verbose-Ausgabe bei jedem analysierten Ordner
   - Sortierung nach Größe (absteigend)

### Erwartete Nutzung
```powershell
Get-FolderSizeReport -Path "C:\Windows" -Depth 1 -MinimumSizeMB 100 -Verbose
Get-FolderSizeReport -Path "C:\Users" -IncludeFiles -MinimumSizeMB 50
```

---

## Bonusaufgabe: Parameter Sets (Optional, +15 Minuten)

### Ihre Aufgabe
Erweitern Sie eine der obigen Funktionen um **Parameter Sets**:

Beispiel für `Get-FolderSizeReport`:
- **ParameterSet 'ByPath'**: Nutzt `-Path` Parameter
- **ParameterSet 'ByDrive'**: Nutzt `-DriveLetter` Parameter (z.B. 'C', 'D')

Die Parameter `-Path` und `-DriveLetter` sollen sich gegenseitig ausschließen.

### Erwartete Nutzung
```powershell
# ParameterSet ByPath
Get-FolderSizeReport -Path "C:\Users"

# ParameterSet ByDrive  
Get-FolderSizeReport -DriveLetter C -Depth 2
```

---

## Abgabe-Checkliste

- [ ] Alle Funktionen haben `[CmdletBinding()]`
- [ ] Parameter sind typisiert (z.B. `[string]`, `[int]`)
- [ ] `Write-Verbose` wird für Logging verwendet
- [ ] Funktionen funktionieren mit `-Verbose` Parameter
- [ ] Output sind Custom Objects `[PSCustomObject]`
- [ ] Code ist sauber formatiert und lesbar

---

## Hinweise

1. Testen Sie Ihre Funktionen nach jeder Änderung
2. Nutzen Sie `Get-Command IhreFunktion -Syntax` um die Syntax zu prüfen
3. Nutzen Sie `(Get-Command IhreFunktion).Parameters` um die Parameter anzuzeigen
4. Bei Problemen: Vereinfachen Sie zuerst, dann schrittweise erweitern
