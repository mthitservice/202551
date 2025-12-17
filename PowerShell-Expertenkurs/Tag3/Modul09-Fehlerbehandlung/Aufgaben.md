# Modul 09 - Fehlerbehandlung in Skripten
## Übungsaufgaben für Teilnehmer

**Zeitrahmen:** ca. 60 Minuten

---

## Übung 1: Try/Catch/Finally Grundlagen (15 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Get-ConfigurationFile`, die eine Konfigurationsdatei sicher liest.

**Anforderungen:**
- Parameter: `Path` (Pflicht), `Format` ('JSON', 'XML', 'INI')
- Verwendet Try/Catch/Finally
- Fängt verschiedene Fehlertypen ab:
  - `FileNotFoundException` → "Datei nicht gefunden"
  - `UnauthorizedAccessException` → "Zugriff verweigert"
  - `JsonException` / XML-Fehler → "Ungültiges Format"
  - Allgemeiner Catch → "Unbekannter Fehler"
- Finally: Gibt aus "Vorgang abgeschlossen für: $Path"
- Gibt geparste Daten zurück oder `$null` bei Fehler

### Erwartetes Ergebnis

```powershell
# Erfolgreicher Aufruf
Get-ConfigurationFile -Path "C:\config.json" -Format JSON

# Fehler: Datei nicht gefunden
Get-ConfigurationFile -Path "C:\nicht_da.json" -Format JSON
# WARNING: Datei nicht gefunden: C:\nicht_da.json
# Vorgang abgeschlossen für: C:\nicht_da.json

# Fehler: Ungültiges JSON
Get-ConfigurationFile -Path "C:\invalid.json" -Format JSON
# WARNING: Ungültiges JSON-Format in: C:\invalid.json
```

---

## Übung 2: ErrorAction und ErrorVariable (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Test-ServerConnectivity`, die mehrere Server parallel auf Erreichbarkeit prüft.

**Anforderungen:**
- Parameter: `ComputerName` (string[], akzeptiert Pipeline)
- Parameter: `Port` (int, Standard: 80)
- Parameter: `TimeoutSeconds` (int, Standard: 3)
- Verwendet `-ErrorAction SilentlyContinue` mit `-ErrorVariable`
- Sammelt alle Fehler und gibt Zusammenfassung aus
- Ausgabe pro Server: Status, ResponseTime, Error (falls vorhanden)

**Implementieren Sie:**
1. Test-NetConnection für jeden Server
2. Fehler in Variable sammeln
3. Am Ende: Zusammenfassung der Fehler anzeigen
4. Rückgabe: Array mit Ergebnissen

### Erwartetes Ergebnis

```powershell
$servers = @("google.com", "nicht.existiert.xyz", "localhost")
$results = Test-ServerConnectivity -ComputerName $servers -Port 443

# Output:
# ComputerName             Port Status   ResponseTime Error
# ------------             ---- ------   ------------ -----
# google.com               443  Online   45 ms
# nicht.existiert.xyz      443  Offline               DNS lookup failed
# localhost                443  Offline               Connection refused

# Zusammenfassung: 2 von 3 Servern nicht erreichbar
```

---

## Übung 3: Professionelle Fehlerbehandlung (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Invoke-BackupOperation`, die Dateien sichert mit umfassender Fehlerbehandlung.

**Funktionsanforderungen:**
- Parameter: `SourcePath` (Pflicht)
- Parameter: `DestinationPath` (Pflicht)
- Parameter: `CompressionLevel` ('Optimal', 'Fastest', 'NoCompression')
- Parameter: `MaxRetries` (int, Standard: 3)

**Fehlerbehandlung:**
1. Validierung: Source muss existieren
2. Validierung: Destination-Ordner erstellen wenn nötig
3. Retry-Logik bei transienten Fehlern
4. Spezifische Catches für:
   - `IOException` (Datei in Verwendung)
   - `UnauthorizedAccessException` (Keine Berechtigung)
   - `OutOfMemoryException` (Zu wenig Speicher)
5. Logging aller Fehler mit Timestamp
6. Finally: Temporäre Dateien aufräumen

**Retry-Pattern implementieren:**
```powershell
for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    try {
        # Operation
        break  # Erfolg -> Schleife verlassen
    }
    catch [TransientError] {
        if ($attempt -eq $MaxRetries) { throw }
        Start-Sleep -Seconds (2 * $attempt)  # Exponential backoff
    }
}
```

### Erwartetes Ergebnis

```powershell
Invoke-BackupOperation -SourcePath "C:\Data" -DestinationPath "D:\Backup" -Verbose

# VERBOSE: Starte Backup: C:\Data -> D:\Backup
# VERBOSE: Versuch 1 von 3...
# VERBOSE: Backup erfolgreich: 150 MB in 12 Sekunden
```

---

## Übung 4: Error Records analysieren (Bonus)

### Aufgabenstellung

Erstellen Sie eine Funktion `Get-ErrorAnalysis`, die Error Records detailliert analysiert.

**Funktionsanforderungen:**
- Parameter: `ErrorRecord` (akzeptiert Pipeline)
- Parameter: `IncludeStackTrace` (Switch)
- Gibt strukturierte Analyse aus

**Zu extrahierende Informationen:**
- Exception Type
- Message
- Error Category
- Target Object
- Position (Datei, Zeile)
- Recommendations (basierend auf Error-Typ)

### Erwartetes Ergebnis

```powershell
# Fehler produzieren
try { Get-Item "C:\NichtDa" -ErrorAction Stop }
catch { $myError = $_ }

# Analysieren
$myError | Get-ErrorAnalysis -IncludeStackTrace

# Output:
# ═══════════════════════════════════════════════════════
# ERROR ANALYSIS
# ═══════════════════════════════════════════════════════
# 
# Type:     ItemNotFoundException
# Message:  Cannot find path 'C:\NichtDa' because it does not exist.
# Category: ObjectNotFound
# Target:   C:\NichtDa
# 
# Position:
#   Script: Interactive
#   Line:   1
#   Command: Get-Item
# 
# Recommendation:
#   Prüfen Sie, ob der Pfad existiert mit Test-Path
#   
# Stack Trace:
#   at <ScriptBlock>, <No file>: line 1
```

---

## Bewertungskriterien

| Kriterium | Punkte |
|-----------|--------|
| Try/Catch/Finally korrekt verwendet | 20 |
| Spezifische Exception-Typen gefangen | 20 |
| ErrorAction/ErrorVariable eingesetzt | 20 |
| Retry-Logik implementiert | 20 |
| Error Records analysiert (Bonus) | 20 |

---

## Hilfreiche Ressourcen

```powershell
# Exception-Typen finden
[System.IO.FileNotFoundException].FullName
[System.UnauthorizedAccessException].FullName
[System.Management.Automation.ItemNotFoundException].FullName

# Error Record Eigenschaften
$Error[0] | Get-Member
$Error[0].Exception | Get-Member
$Error[0].InvocationInfo | Get-Member

# ErrorAction Werte
[System.Management.Automation.ActionPreference].GetEnumNames()
```

---

## Checkliste vor Abgabe

- [ ] Alle Try-Blöcke haben mindestens einen Catch
- [ ] -ErrorAction Stop bei Cmdlets in Try-Blöcken
- [ ] Finally für Cleanup verwendet
- [ ] Spezifische Exceptions vor allgemeinem Catch
- [ ] ErrorVariable für Fehlersammlung genutzt
- [ ] Aussagekräftige Fehlermeldungen
- [ ] Retry-Logik für transiente Fehler
