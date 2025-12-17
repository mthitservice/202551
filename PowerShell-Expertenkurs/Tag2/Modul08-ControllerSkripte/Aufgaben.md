# Modul 08 - Controller Skripte
## Übungsaufgaben für Teilnehmer

**Zeitrahmen:** ca. 60 Minuten

---

## Übung 1: Einfaches Menüsystem (20 Min)

### Aufgabenstellung

Erstellen Sie ein Controller-Skript `Start-FileManager.ps1` für ein Dateiverwaltungs-Tool.

**Menü-Struktur:**
```
================================================
  Datei-Manager v1.0
================================================

  [1] Dateien auflisten
  [2] Datei suchen
  [3] Ordner erstellen
  [4] Dateien kopieren
  [5] Dateien löschen

  [0] Beenden

Auswahl: _
```

**Anforderungen:**
1. Hauptmenü mit 5 Optionen + Beenden
2. Jede Option zeigt kurze Beschreibung
3. Nach jeder Aktion: "Enter zum Fortfahren"
4. Schleife bis Benutzer "0" wählt
5. Ungültige Eingaben abfangen

### Zu implementierende Funktionen:
- Option 1: Zeigt Dateien im aktuellen Verzeichnis
- Option 2: Fragt nach Suchmuster und sucht rekursiv
- Option 3: Fragt nach Ordnernamen und erstellt ihn
- Option 4: Fragt nach Quelle und Ziel, kopiert Datei
- Option 5: Fragt nach Dateiname, bestätigt und löscht

---

## Übung 2: Benutzerinteraktion mit Validierung (20 Min)

### Aufgabenstellung

Erstellen Sie eine `Read-ValidatedInput`-Funktion und nutzen Sie sie in einem Konfigurations-Assistenten.

**Funktion `Read-ValidatedInput`:**
- Parameter: `Prompt` (Pflicht)
- Parameter: `Type` ('String', 'Int', 'Path', 'Email', 'IPAddress')
- Parameter: `DefaultValue`
- Parameter: `Mandatory`
- Gibt validierten Wert zurück oder fragt erneut

**Konfigurations-Assistent `New-ServerConfig`:**
Sammelt folgende Informationen:
1. Servername (String, Pflicht)
2. IP-Adresse (IPAddress-Format, Pflicht)
3. Port (Int, 1-65535, Default: 443)
4. Admin-Email (Email-Format, Pflicht)
5. Backup-Pfad (Pfad, muss existieren oder erstellt werden)

**Ausgabe:** PSCustomObject mit allen Konfigurationswerten

### Erwartetes Ergebnis

```powershell
$config = New-ServerConfig

# Interaktive Eingabe:
# Servername: WebServer01
# IP-Adresse: 192.168.1.100
# Port [443]: 8443
# Admin-Email: admin@firma.de
# Backup-Pfad: C:\Backups

$config
# ServerName  : WebServer01
# IPAddress   : 192.168.1.100
# Port        : 8443
# AdminEmail  : admin@firma.de
# BackupPath  : C:\Backups
# CreatedAt   : ...
```

---

## Übung 3: Vollständiger Controller mit Logging (15 Min)

### Aufgabenstellung

Erstellen Sie einen Controller `Start-UserManager.ps1` für Benutzerverwaltung.

**Features:**
1. **Logging-System**
   - Log-Datei im Temp-Verzeichnis
   - Format: `[Timestamp] [Level] Message`
   - Levels: Info, Warning, Error

2. **Menü-Optionen:**
   - Benutzer auflisten (simuliert)
   - Neuen Benutzer erstellen (Assistent)
   - Benutzer deaktivieren
   - Passwort zurücksetzen
   - Log anzeigen

3. **Untermenü für "Neuer Benutzer":**
   - Username eingeben
   - Abteilung wählen (aus Liste)
   - Rolle wählen (User/Admin)
   - Bestätigung vor Erstellung

### Struktur-Anforderungen:
```powershell
# Header
function Write-Log { ... }
function Show-Menu { ... }
function New-UserWizard { ... }

# Simulierte Daten
$script:Users = @(...)

# Hauptprogramm
function Start-UserManager {
    # Initialisierung
    # Menü-Schleife
    # Cleanup
}

# Start
Start-UserManager
```

---

## Übung 4: Multi-Level Menü (Bonus)

### Aufgabenstellung

Erstellen Sie ein Controller-Skript mit verschachtelten Menüs für Server-Administration.

**Hauptmenü:**
```
[1] Server Management     →
[2] Netzwerk             →
[3] Sicherheit           →
[4] Berichte             →
[Q] Beenden
```

**Untermenü "Server Management":**
```
[1] Status anzeigen
[2] Dienste verwalten    →
[3] Prozesse verwalten   →
[4] Neustart planen
[0] Zurück
```

**Untermenü "Dienste verwalten":**
```
[1] Alle Dienste auflisten
[2] Laufende Dienste
[3] Gestoppte Dienste
[4] Dienst starten
[5] Dienst stoppen
[0] Zurück
```

**Anforderungen:**
- Navigation zwischen Menü-Ebenen
- "Zurück"-Option in jedem Untermenü
- Breadcrumb-Anzeige: `Server Management > Dienste`
- Konsistentes Look & Feel

---

## Bewertungskriterien

| Kriterium | Punkte |
|-----------|--------|
| Funktionierendes Menüsystem | 25 |
| Eingabevalidierung | 25 |
| Logging-Integration | 20 |
| Benutzerfreundlichkeit | 15 |
| Code-Struktur und Lesbarkeit | 15 |

---

## Hilfreiche Ressourcen

```powershell
# Bildschirm leeren
Clear-Host

# Farbige Ausgabe
Write-Host "Text" -ForegroundColor Cyan

# Eingabe lesen
$input = Read-Host "Prompt"

# Sichere Eingabe
$secure = Read-Host "Passwort" -AsSecureString

# Pause
Read-Host "Enter zum Fortfahren"
Start-Sleep -Seconds 2

# Reguläre Ausdrücke für Validierung
"test@mail.de" -match '^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$'
"192.168.1.1" -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
```

---

## Checkliste vor Abgabe

- [ ] Menü zeigt alle Optionen übersichtlich an
- [ ] Ungültige Eingaben werden abgefangen
- [ ] Benutzer erhält Feedback nach jeder Aktion
- [ ] Logging funktioniert und schreibt in Datei
- [ ] "Beenden" beendet sauber die Anwendung
- [ ] Code ist in Funktionen strukturiert
- [ ] Variablen und Funktionen sind aussagekräftig benannt
