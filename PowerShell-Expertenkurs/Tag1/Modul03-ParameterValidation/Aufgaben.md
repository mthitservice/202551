# Modul 03: Parameter-Attribute und Input Validation - Übungsaufgaben

## Übersicht
**Dauer:** ca. 60 Minuten  
**Schwierigkeit:** Fortgeschritten

---

## Aufgabe 1: Basis-Validierung (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `New-ServerConfig` mit folgenden validierten Parametern:

1. **-ServerName** (Pflicht)
   - Muss 3-15 Zeichen lang sein
   - Nur Buchstaben, Zahlen und Bindestriche erlaubt (Regex)
   - Darf nicht mit Bindestrich beginnen oder enden

2. **-Environment** (Pflicht)
   - Nur erlaubt: 'Development', 'Test', 'Staging', 'Production'
   - Tab-Completion soll funktionieren

3. **-Port** (Optional, Standard: 443)
   - Wertebereich: 1-65535
   - Muss eine Ganzzahl sein

4. **-IPAddress** (Optional)
   - Muss gültiges IPv4-Format haben (Regex)

5. **-Tags** (Optional)
   - String-Array mit 0-10 Einträgen

### Erwartete Nutzung
```powershell
New-ServerConfig -ServerName "web-server-01" -Environment Production -Port 8080
New-ServerConfig -ServerName "db01" -Environment Test -IPAddress "192.168.1.100"
```

### Erwartete Fehler
```powershell
# Diese sollten Fehler werfen:
New-ServerConfig -ServerName "ab" -Environment Production  # Zu kurz
New-ServerConfig -ServerName "-invalid" -Environment Test  # Beginnt mit -
New-ServerConfig -ServerName "server" -Environment "Live"  # Ungültige Umgebung
New-ServerConfig -ServerName "server" -Environment Test -Port 70000  # Port zu hoch
```

---

## Aufgabe 2: ValidateScript für komplexe Validierung (20 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Backup-Database` mit komplexer Validierung:

1. **-DatabasePath** (Pflicht)
   - Datei muss existieren
   - Muss Endung .mdf oder .bak haben
   - Dateigröße muss unter 10GB sein

2. **-BackupFolder** (Pflicht)
   - Ordner muss existieren
   - Mindestens 5GB freier Speicherplatz erforderlich
   - Schreibrechte müssen vorhanden sein

3. **-RetentionDays** (Optional, Standard: 30)
   - Bereich: 7-365
   - Muss durch 7 teilbar sein (für wöchentliche Rotation)

4. **-CompressionLevel** (Optional)
   - Erlaubte Werte: 'None', 'Fast', 'Normal', 'Maximum'
   - Standard: 'Normal'

5. **-NotifyEmail** (Optional)
   - Muss gültiges E-Mail-Format haben
   - Wenn angegeben, muss auch -SmtpServer angegeben werden

6. **-SmtpServer** (Optional)
   - Muss erreichbar sein (Test-Connection)

### Erwartete Nutzung
```powershell
Backup-Database -DatabasePath "C:\Data\mydb.mdf" -BackupFolder "D:\Backups" -RetentionDays 28
Backup-Database -DatabasePath "C:\Data\mydb.bak" -BackupFolder "D:\Backups" -NotifyEmail "admin@company.com" -SmtpServer "mail.company.com"
```

---

## Aufgabe 3: Parameter Sets (15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-AuditLog` mit drei sich gegenseitig ausschließenden Suchoptionen:

**ParameterSet 'ByTimeRange':** (Standard)
- `-StartDate` (Pflicht) - DateTime
- `-EndDate` (Pflicht) - DateTime, muss nach StartDate liegen

**ParameterSet 'ByEventId':**
- `-EventId` (Pflicht) - Integer-Array, 1-20 Einträge

**ParameterSet 'ByUser':**
- `-UserName` (Pflicht) - String
- `-IncludeSystemEvents` (Optional) - Switch

**Gemeinsame Parameter (in allen Sets):**
- `-LogName` (Optional) - ValidateSet: 'Security', 'Application', 'System'
- `-MaxResults` (Optional, Standard: 100) - Bereich 1-10000

### Erwartete Nutzung
```powershell
# ByTimeRange (Standard)
Get-AuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -LogName Security

# ByEventId
Get-AuditLog -EventId 4624, 4625, 4634 -MaxResults 500

# ByUser
Get-AuditLog -UserName "DOMAIN\jdoe" -IncludeSystemEvents -LogName Security
```

---

## Aufgabe 4: ArgumentCompleter (10 Minuten)

### Ihre Aufgabe
Erstellen Sie eine Funktion `Get-ProcessDetails` mit dynamischer Tab-Completion:

1. **-ProcessName** (Pflicht)
   - ArgumentCompleter der echte laufende Prozesse vorschlägt
   - Tooltip soll PID und Memory anzeigen
   - Sortiert nach Speicherverbrauch (höchster zuerst)

2. **-Property** (Optional, mehrere Werte)
   - ArgumentCompleter der alle Properties von System.Diagnostics.Process vorschlägt
   - Standard: Name, Id, CPU, WorkingSet64

### Erwartete Nutzung
```powershell
# Tab-Completion bei -ProcessName zeigt laufende Prozesse
Get-ProcessDetails -ProcessName chr<TAB>

# Tab-Completion bei -Property zeigt verfügbare Properties
Get-ProcessDetails -ProcessName "chrome" -Property <TAB>
```

---

## Bonusaufgabe: Eigene Validierungsklasse (Optional, +15 Minuten)

### Ihre Aufgabe
Erstellen Sie eine eigene Validierungsklasse `ValidateIPRangeAttribute`:

1. Akzeptiert IP-Adressen nur aus bestimmten Bereichen
2. Konfigurierbar mit erlaubten Netzwerk-Bereichen
3. Gibt aussagekräftige Fehlermeldung

### Beispiel
```powershell
class ValidateIPRangeAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [string[]]$AllowedRanges  # z.B. "192.168.1.0/24", "10.0.0.0/8"
    
    # Implementieren Sie die Validate-Methode
}

function Set-ServerIP {
    [CmdletBinding()]
    param(
        [ValidateIPRange("192.168.0.0/16", "10.0.0.0/8")]
        [string]$IPAddress
    )
}
```

---

## Abgabe-Checkliste

### Aufgabe 1
- [ ] Alle 5 Parameter implementiert
- [ ] ValidateLength funktioniert
- [ ] ValidatePattern für ServerName funktioniert
- [ ] ValidateSet für Environment funktioniert
- [ ] ValidateRange für Port funktioniert
- [ ] Alle Fehlerfälle werden korrekt abgefangen

### Aufgabe 2
- [ ] ValidateScript für DatabasePath implementiert
- [ ] Speicherplatz-Prüfung funktioniert
- [ ] Abhängigkeit NotifyEmail/SmtpServer funktioniert
- [ ] Teilbarkeit durch 7 wird geprüft

### Aufgabe 3
- [ ] Drei Parameter Sets definiert
- [ ] DefaultParameterSetName gesetzt
- [ ] EndDate > StartDate Validierung
- [ ] Gemeinsame Parameter in allen Sets verfügbar

### Aufgabe 4
- [ ] ArgumentCompleter für ProcessName funktioniert
- [ ] Tooltips werden angezeigt
- [ ] ArgumentCompleter für Property funktioniert

---

## Tipps

1. **Regex testen:** Nutzen Sie `"text" -match 'pattern'` zum Testen
2. **ValidateScript Debugging:** 
   ```powershell
   [ValidateScript({
       Write-Verbose "Validiere: $_" -Verbose
       # Ihre Logik
   })]
   ```
3. **Parameter Sets prüfen:**
   ```powershell
   Get-Command IhreFunktion -Syntax
   ```
4. **ArgumentCompleter testen:** 
   - Funktion definieren, dann Tab-Taste drücken
   - Bei Problemen: ISE oder VS Code neu starten
