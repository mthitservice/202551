# Modul 07 - WhatIf und Confirm Support
## Übungsaufgaben für Teilnehmer

**Zeitrahmen:** ca. 60 Minuten

---

## Übung 1: Grundlegende WhatIf/Confirm Implementierung (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Remove-TempUserFiles`, die temporäre Benutzerdateien löscht.

**Funktionsanforderungen:**
- Parameter: `UserName` (string, Pflicht)
- Parameter: `FileTypes` (string[], Standard: @('*.tmp', '*.temp', '*.cache'))
- Parameter: `OlderThanDays` (int, Standard: 7)
- Die Funktion soll alle passenden Dateien im Temp-Ordner des Benutzers finden und löschen

**WhatIf/Confirm-Anforderungen:**
1. Aktivieren Sie `SupportsShouldProcess`
2. Verwenden Sie `$PSCmdlet.ShouldProcess()` mit Target und Action
3. Zeigen Sie bei `-WhatIf` an, welche Dateien gelöscht würden
4. Bei `-Confirm` soll jede Datei einzeln bestätigt werden

### Erwartetes Ergebnis

```powershell
# Zeigt was gelöscht würde, ohne zu löschen
Remove-TempUserFiles -UserName "TestUser" -WhatIf

# Fragt für jede Datei nach Bestätigung
Remove-TempUserFiles -UserName "TestUser" -Confirm

# Löscht ohne Nachfrage (außer bei ConfirmPreference)
Remove-TempUserFiles -UserName "TestUser"
```

---

## Übung 2: ConfirmImpact richtig setzen (20 Min)

### Aufgabenstellung

Erstellen Sie drei Funktionen mit unterschiedlichen Impact-Levels:

### Funktion 1: `Update-UserPreferences` (Impact: Low)
- Parameter: `UserName`, `Theme`, `Language`
- Ändert nur Benutzereinstellungen
- Keine kritischen Auswirkungen

### Funktion 2: `Restart-ApplicationService` (Impact: Medium)
- Parameter: `ServiceName`, `GracePeriodSeconds`
- Startet einen Anwendungsdienst neu
- Kurze Unterbrechung möglich

### Funktion 3: `Remove-UserAccount` (Impact: High)
- Parameter: `UserName`, `IncludeHomeDirectory`
- Löscht ein Benutzerkonto
- Unwiderruflich!

**Testen Sie das Verhalten:**
```powershell
# Testen Sie mit verschiedenen ConfirmPreference-Werten
$ConfirmPreference = 'High'   # Standard
$ConfirmPreference = 'Medium'
$ConfirmPreference = 'Low'
$ConfirmPreference = 'None'
```

### Erwartetes Ergebnis

- Bei `$ConfirmPreference = 'High'`: Nur `Remove-UserAccount` fragt nach
- Bei `$ConfirmPreference = 'Medium'`: Auch `Restart-ApplicationService` fragt nach
- Bei `$ConfirmPreference = 'Low'`: Alle Funktionen fragen nach

---

## Übung 3: ShouldContinue für kritische Aktionen (15 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Clear-DatabaseTable`, die eine Datenbanktabelle leert.

**Funktionsanforderungen:**
- Parameter: `DatabaseName` (Pflicht)
- Parameter: `TableName` (Pflicht)
- Parameter: `Force` (Switch)
- Die Funktion muss zwei Bestätigungsebenen haben:
  1. Standard `ShouldProcess` für die grundlegende Operation
  2. `ShouldContinue` mit deutlicher Warnung

**Implementieren Sie:**
1. `SupportsShouldProcess` mit `ConfirmImpact = 'High'`
2. Erste Bestätigung: `ShouldProcess($TableName, "Clear all rows")`
3. Zweite Bestätigung: `ShouldContinue()` mit Warnung über Datenverlust
4. `-Force` soll `ShouldContinue` überspringen

### Erwartetes Ergebnis

```powershell
# Ohne Force: Zwei Bestätigungen erforderlich
Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users"

# Mit Force: Nur ShouldProcess-Bestätigung
Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users" -Force

# WhatIf zeigt geplante Aktion
Clear-DatabaseTable -DatabaseName "TestDB" -TableName "Users" -WhatIf
```

---

## Übung 4: Komplexes Szenario - Deployment Script (Bonus)

### Aufgabenstellung

Erstellen Sie eine Funktion `Publish-WebApplication`, die eine Web-Anwendung deployed.

**Funktionsanforderungen:**
- Parameter: `ApplicationName` (Pflicht)
- Parameter: `Environment` (ValidateSet: 'Development', 'Staging', 'Production')
- Parameter: `Version` (Pflicht)
- Parameter: `BackupFirst` (Switch, Standard: $true)
- Parameter: `Force` (Switch)

**Deployment-Schritte (alle mit ShouldProcess):**
1. Backup erstellen (wenn BackupFirst)
2. Anwendung stoppen
3. Dateien kopieren
4. Konfiguration anpassen
5. Anwendung starten
6. Health-Check durchführen

**Besondere Anforderungen:**
- Bei `Environment = 'Production'` zusätzliche Warnung mit ShouldContinue
- ConfirmImpact abhängig von Environment:
  - Development: Low
  - Staging: Medium
  - Production: High

### Erwartetes Ergebnis

```powershell
# Development - ohne Nachfrage
Publish-WebApplication -ApplicationName "MyApp" -Environment Development -Version "1.0"

# Production - mit doppelter Bestätigung
Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0"

# Alle Schritte anzeigen ohne Ausführung
Publish-WebApplication -ApplicationName "MyApp" -Environment Production -Version "1.0" -WhatIf
```

---

## Bewertungskriterien

| Kriterium                                    | Punkte |
| -------------------------------------------- | ------ |
| SupportsShouldProcess korrekt implementiert  | 20     |
| ConfirmImpact passend gewählt                | 20     |
| ShouldProcess mit aussagekräftigen Meldungen | 20     |
| ShouldContinue für kritische Aktionen        | 15     |
| Force-Parameter korrekt implementiert        | 15     |
| Bonus: Komplexes Szenario                    | 10     |

---

## Hilfreiche Ressourcen

```powershell
# Help zu ShouldProcess
Get-Help about_Functions_CmdletBindingAttribute -Full
Get-Help about_CommonParameters -Full

# ConfirmPreference testen
$ConfirmPreference  # Zeigt aktuellen Wert

# Debugging
$PSCmdlet | Get-Member  # Zeigt verfügbare Methoden
```

---

## Checkliste vor Abgabe

- [ ] Alle Funktionen haben [CmdletBinding(SupportsShouldProcess)]
- [ ] ConfirmImpact ist passend zum Risiko gewählt
- [ ] ShouldProcess zeigt Target und Action
- [ ] ShouldContinue wird für kritische Aktionen verwendet
- [ ] Force-Parameter überspringt ShouldContinue
- [ ] -WhatIf zeigt alle geplanten Aktionen
- [ ] -Confirm fragt für jede Aktion nach
