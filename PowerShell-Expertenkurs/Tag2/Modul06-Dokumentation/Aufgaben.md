# Modul 06 - Dokumentation mit Comment-Based Help
## Übungsaufgaben für Teilnehmer

**Zeitrahmen:** ca. 60 Minuten

---

## Übung 1: Vollständig dokumentierte Funktion (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Get-DiskSpaceReport`, die einen Festplatten-Bericht erstellt.

**Funktionsanforderungen:**
- Parameter: `ComputerName` (string[], mit Pipeline-Support)
- Parameter: `DriveType` (ValidateSet: 'All', 'Local', 'Network')
- Parameter: `ThresholdPercent` (1-100, Warnung wenn freier Speicher darunter)
- Gibt Objekte mit Laufwerk, Größe, Frei, Prozent zurück

**Dokumentations-Anforderungen (vollständig):**
1. `.SYNOPSIS` - Kurze Beschreibung
2. `.DESCRIPTION` - Mindestens 3 Sätze ausführliche Beschreibung
3. `.PARAMETER` - Für jeden Parameter mit Typ und Einschränkungen
4. `.INPUTS` - Pipeline-Input dokumentieren
5. `.OUTPUTS` - Rückgabe-Typ dokumentieren
6. `.EXAMPLE` - Mindestens 4 Beispiele (einfach bis komplex)
7. `.NOTES` - Autor, Version, Datum
8. `.LINK` - Link zu Get-CimInstance

### Erwartetes Ergebnis

```powershell
Get-Help Get-DiskSpaceReport -Full   # Zeigt vollständige Dokumentation
Get-Help Get-DiskSpaceReport -Examples  # Zeigt alle 4 Beispiele
```

---

## Übung 2: Parameter-Dokumentation mit Formatierung (20 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `New-UserAccount` mit detaillierter Parameter-Dokumentation.

**Funktionsanforderungen:**
- Parameter: `Username` (Pflicht, alphanumerisch)
- Parameter: `Email` (Pflicht, E-Mail-Format)
- Parameter: `Department` (ValidateSet)
- Parameter: `Role` (ValidateSet: 'User', 'PowerUser', 'Admin')
- Parameter: `ExpirationDate` (DateTime, optional)
- Parameter: `Groups` (string[], Gruppenmitgliedschaften)

**Dokumentieren Sie jeden Parameter mit:**
- Beschreibung der Verwendung
- Gültige Werte / Einschränkungen
- Standardwert (falls vorhanden)
- Formatierte Tabelle für Rollen mit Berechtigungen

**Beispiel für Tabelle in Dokumentation:**
```
| Rolle     | Lesen | Schreiben | Admin |
|-----------|-------|-----------|-------|
| User      | Ja    | Nein      | Nein  |
| PowerUser | Ja    | Ja        | Nein  |
| Admin     | Ja    | Ja        | Ja    |
```

### Erwartetes Ergebnis

```powershell
Get-Help New-UserAccount -Parameter Role
# Zeigt formatierte Tabelle in Parameterbeschreibung
```

---

## Übung 3: Beispiel-Bibliothek erstellen (15 Min)

### Aufgabenstellung

Erstellen Sie eine Funktion `Send-AlertNotification` mit besonders guten Beispielen.

**Funktionsanforderungen:**
- Parameter: `Message` (Pflicht)
- Parameter: `Severity` ('Info', 'Warning', 'Error', 'Critical')
- Parameter: `Channel` ('Email', 'Teams', 'Slack', 'All')
- Parameter: `Recipients` (string[])
- Parameter: `Attachments` (string[], Dateipfade)

**Erstellen Sie diese 6 Beispiele:**

1. **Einfachstes Beispiel** - Nur Pflichtparameter
2. **Typisches Beispiel** - Mit Severity und Recipients
3. **Multi-Channel** - An alle Kanäle senden
4. **Mit Attachments** - Dateien anhängen
5. **Pipeline-Beispiel** - Integration mit anderen Cmdlets
6. **Produktions-Beispiel** - Komplettes Skript mit Fehlerbehandlung

Jedes Beispiel soll einen erklärenden Kommentar haben!

### Erwartetes Ergebnis

```powershell
Get-Help Send-AlertNotification -Examples
# Zeigt 6 gut dokumentierte, aufeinander aufbauende Beispiele
```

---

## Übung 4: About-Topic für Modul (Bonus)

### Aufgabenstellung

Erstellen Sie ein About-Topic `about_AlertingSystem.help.txt`.

**Struktur:**
```
TOPIC
    about_AlertingSystem

SHORT DESCRIPTION
    [Kurzbeschreibung]

LONG DESCRIPTION
    [Ausführliche Beschreibung mit Abschnitten]

    FUNKTIONEN
    ----------
    [Liste aller Funktionen mit Kurzbeschreibung]

    KONFIGURATION
    -------------
    [Wie wird das Modul konfiguriert?]

    BEST PRACTICES
    --------------
    [Empfehlungen zur Nutzung]

EXAMPLES
    [Mehrere Nutzungsbeispiele]

SEE ALSO
    [Verwandte Themen]

KEYWORDS
    [Schlüsselwörter für Suche]
```

### Erwartetes Ergebnis

Die Datei sollte in `en-US/` oder `de-DE/` Ordner liegen und per `Get-Help about_AlertingSystem` auffindbar sein.

---

## Bewertungskriterien

| Kriterium | Punkte |
|-----------|--------|
| Vollständige Help-Keywords verwendet | 25 |
| Beispiele sind praxisnah und progressiv | 25 |
| Parameter detailliert dokumentiert | 20 |
| Formatierung und Lesbarkeit | 15 |
| About-Topic (Bonus) | 15 |

---

## Hilfreiche Ressourcen

```powershell
# Help-System erkunden
Get-Help about_Comment_Based_Help -Full
Get-Help Get-Help -Full

# Beispiele aus eingebauten Cmdlets
Get-Help Get-Process -Full
Get-Help Get-Service -Examples

# Ihre Dokumentation testen
Get-Help IhreFunktion -ShowWindow   # GUI-Anzeige
```

---

## Checkliste vor Abgabe

- [ ] Jede Funktion hat mindestens SYNOPSIS und DESCRIPTION
- [ ] Alle Parameter sind dokumentiert
- [ ] Mindestens 3-4 Beispiele pro Funktion
- [ ] INPUTS und OUTPUTS sind angegeben
- [ ] NOTES enthält Autor und Version
- [ ] Beispiele bauen aufeinander auf (einfach → komplex)
- [ ] Get-Help zeigt keine Fehler oder "No help found"
